library Indicator_03_6_Same_Hospital_Sedative_Overlap_1728 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 同醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服)
// 指標代碼: 1728
// 製作日期: 2025-11-20
// ============================================
// 分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數
// 分母: 各案件之「給藥日數」總和
// 安眠鎮靜藥物(口服): ATC前5碼為N05CC、N05CD、N05CF、N05CM

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'

context Patient

// ============================================
// Helper Functions
// ============================================

// 檢查是否為安眠鎮靜藥物 ATC
define function IsSedativeHypnoticATC(atcCode String):
  if atcCode is null then false
  else
    Substring(atcCode, 0, 5) in {
      'N05CC', 'N05CD', 'N05CF', 'N05CM'
    }

// 取兩個日期中較大者
define function MaxDateTime(d1 DateTime, d2 DateTime):
  if d1 is null then d2
  else if d2 is null then d1
  else if d1 > d2 then d1
  else d2

// 取兩個日期中較小者
define function MinDateTime(d1 DateTime, d2 DateTime):
  if d1 is null then d2
  else if d2 is null then d1
  else if d1 < d2 then d1
  else d2

// 計算兩個日期區間的重疊天數
define function CalculateOverlapDays(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then
    0
  else if MaxDateTime(start1, start2) <= MinDateTime(end1, end2) then
    days between MaxDateTime(start1, start2) and MinDateTime(end1, end2) + 1
  else
    0

// ============================================
// 門診安眠鎮靜藥品處方(口服)
// ============================================

define "Sedative Hypnotic Prescriptions":
  [MedicationRequest] MR
    let medCodings: (MR.medication as FHIR.CodeableConcept).coding
    where MR.status.value in { 'active', 'completed' }
    and exists (
      medCodings MC
        where MC.system.value = 'http://www.whocc.no/atc'
        and IsSedativeHypnoticATC(MC.code.value)
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
// 同院同病人不同處方重疊分析
// ============================================

define "Drug Overlap Days":
  flatten (
    "Sedative Hypnotic Prescriptions" P1
      return
        "Sedative Hypnotic Prescriptions" P2
          where P2.subject.reference.value = P1.subject.reference.value
          and P2.requester.reference.value = P1.requester.reference.value
          and P2.id.value != P1.id.value
          and CalculateOverlapDays(
                P1.dispenseRequest.validityPeriod."start".value,
                P1.dispenseRequest.validityPeriod."end".value,
                P2.dispenseRequest.validityPeriod."start".value,
                P2.dispenseRequest.validityPeriod."end".value
              ) > 0
          return {
            prescription1: P1.id.value,
            prescription2: P2.id.value,
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
    "Sedative Hypnotic Prescriptions" P
      return days between P.dispenseRequest.validityPeriod."start".value
                     and P.dispenseRequest.validityPeriod."end".value + 1
  )

// ============================================
// 分子: 重疊給藥日數
// ============================================

define "Overlap Drug Days":
  Sum("Drug Overlap Days" D return D.overlapDays) / 2

// ============================================
// 統計數據
// ============================================

define "Total Prescriptions":
  Count("Sedative Hypnotic Prescriptions")

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
