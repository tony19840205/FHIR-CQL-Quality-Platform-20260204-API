library Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-降血壓(口服)
// 指標代碼: 1713
// 製作日期: 2026-01-09
// ============================================
// 分子: 全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數
// 分母: 各案件之「給藥日數」總和
// 降血壓藥物(口服): ATC前3碼為C07(排除C07AA05),
//   或ATC前5碼為C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、
//   C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA
// 排除: C07AA05、C08CA06、代辦案件

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'

context Patient

// ============================================
// Helper Functions
// ============================================

define function IsAntihypertensiveATC(atcCode String):
  if atcCode is null then false
  else
    (Substring(atcCode, 0, 3) = 'C07' and atcCode != 'C07AA05')
    or Substring(atcCode, 0, 5) in { 'C02CA', 'C02DB', 'C02DC', 'C02DD', 'C03AA', 'C03BA', 'C03CA', 'C03DA', 'C08DA', 'C08DB', 'C09AA', 'C09CA' }
    or (Substring(atcCode, 0, 5) = 'C08CA' and atcCode != 'C08CA06')

define function MaxDateTime(d1 DateTime, d2 DateTime):
  if d1 is null then d2
  else if d2 is null then d1
  else if d1 > d2 then d1
  else d2

define function MinDateTime(d1 DateTime, d2 DateTime):
  if d1 is null then d2
  else if d2 is null then d1
  else if d1 < d2 then d1
  else d2

define function CalculateOverlapDays(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then
    0
  else if MaxDateTime(start1, start2) <= MinDateTime(end1, end2) then
    days between MaxDateTime(start1, start2) and MinDateTime(end1, end2) + 1
  else
    0

// ============================================
// 門診降血壓藥品處方(口服) - 跨醫院分析
// ============================================

define "Antihypertensive Prescriptions":
  [MedicationRequest] MR
    let medCodings: (MR.medication as FHIR.CodeableConcept).coding
    where MR.status.value in { 'active', 'completed' }
    and exists (
      medCodings MC
        where MC.system.value = 'http://www.whocc.no/atc'
        and IsAntihypertensiveATC(MC.code.value)
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(MR.encounter.reference.value, '/'))
        and E.class.code.value = 'AMB'
        and E.status.value = 'finished'
        and not exists (E.type T where exists (T.coding C where C.code.value = 'AGENCY'))
    )
    and MR.dispenseRequest.validityPeriod."start" is not null
    and MR.dispenseRequest.validityPeriod."end" is not null

// ============================================
// 取得處方的醫院組織ID
// ============================================

define function GetOrganizationId(encRef String):
  First(
    [Encounter] E
      where E.id.value = Last(Split(encRef, '/'))
      return Last(Split(E.serviceProvider.reference.value, '/'))
  )

// ============================================
// 跨醫院同病人不同處方重疊分析
// 關鍵: P1的醫院 != P2的醫院
// ============================================

define "Drug Overlap Days":
  flatten (
    "Antihypertensive Prescriptions" P1
      return
        "Antihypertensive Prescriptions" P2
          where P2.subject.reference.value = P1.subject.reference.value
          and P2.id.value != P1.id.value
          and GetOrganizationId(P1.encounter.reference.value) is not null
          and GetOrganizationId(P2.encounter.reference.value) is not null
          and GetOrganizationId(P1.encounter.reference.value) != GetOrganizationId(P2.encounter.reference.value)
          and CalculateOverlapDays(
                P1.dispenseRequest.validityPeriod."start".value,
                P1.dispenseRequest.validityPeriod."end".value,
                P2.dispenseRequest.validityPeriod."start".value,
                P2.dispenseRequest.validityPeriod."end".value
              ) > 0
          return {
            prescription1: P1.id.value,
            prescription2: P2.id.value,
            organization1: GetOrganizationId(P1.encounter.reference.value),
            organization2: GetOrganizationId(P2.encounter.reference.value),
            overlapDays: CalculateOverlapDays(
              P1.dispenseRequest.validityPeriod."start".value,
              P1.dispenseRequest.validityPeriod."end".value,
              P2.dispenseRequest.validityPeriod."start".value,
              P2.dispenseRequest.validityPeriod."end".value
            )
          }
  )

// ============================================
// 分母: 總給藥日數
// ============================================

define "Total Drug Days":
  Sum(
    "Antihypertensive Prescriptions" P
      return days between P.dispenseRequest.validityPeriod."start".value
                     and P.dispenseRequest.validityPeriod."end".value + 1
  )

// ============================================
// 分子: 重疊給藥日數 (除以2避免重複計算)
// ============================================

define "Overlap Drug Days":
  Sum("Drug Overlap Days" D return D.overlapDays) / 2

// ============================================
// 統計數據
// ============================================

define "Total Prescriptions":
  Count("Antihypertensive Prescriptions")

define "Total Overlapping Pairs":
  Count("Drug Overlap Days")

// ============================================
// 重疊率計算
// ============================================

define "Drug Overlap Rate":
  if "Total Drug Days" > 0 then
    ("Overlap Drug Days" / "Total Drug Days") * 100
  else
    null

// ============================================
// 指標結果
// ============================================

define "Indicator Result":
  {
    indicatorCode: '1713',
    indicatorName: '跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服)',
    totalDrugDays: "Total Drug Days",
    totalOverlapDays: "Overlap Drug Days",
    overlapRate: "Drug Overlap Rate",
    totalPrescriptions: "Total Prescriptions",
    totalOverlappingPairs: "Total Overlapping Pairs",
    keyFeature: '跨醫院用藥重疊分析'
  }
