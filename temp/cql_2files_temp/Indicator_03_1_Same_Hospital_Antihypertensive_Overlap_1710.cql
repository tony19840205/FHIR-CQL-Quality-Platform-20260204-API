library Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1710
// 條件依據：同醫院門診同藥理用藥日數重疊率-降血壓(口服)
// 製作日期：2025-11-20

// 【公式說明】
// 分子: 同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數
// 分母: 各案件之「給藥日數」總和
// 降血壓藥(口服): ATC前3碼為C07(排除C07AA05)或ATC前5碼為C02CA、C02DB、C02DC、C02DD、C03AA、
//                C03BA、C03CA、C03DA、C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA，
//                且醫令代碼第8碼不為2

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'

// Helper function: 檢查是否為降血壓藥(口服)
define function IsAntihypertensiveOralDrug(atcCode String, drugCode String):
  (
    // ATC前3碼為C07(排除C07AA05)
    (Substring(atcCode, 0, 3) = 'C07' and atcCode != 'C07AA05')
    or
    // ATC前5碼為指定代碼
    Substring(atcCode, 0, 5) in {
      'C02CA', 'C02DB', 'C02DC', 'C02DD', 'C03AA', 'C03BA', 'C03CA', 'C03DA',
      'C08CA', 'C08DA', 'C08DB', 'C09AA', 'C09CA'
    }
    and
    // 排除C08CA06
    atcCode != 'C08CA06'
  )
  and
  // 醫令代碼第8碼不為2 (排除注射劑)
  (Length(drugCode) >= 8 and Substring(drugCode, 7, 1) != '2')

// Helper function: 計算兩個日期區間的重疊天數
define function CalculateOverlapDays(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then
    0
  else
    if (if start1 > start2 then start1 else start2) <= (if end1 < end2 then end1 else end2) then
      days between (if start1 > start2 then start1 else start2) and (if end1 < end2 then end1 else end2) + 1
    else
      0

// 1. 同醫院門診降血壓藥品處方
define "Antihypertensive Prescriptions":
  [MedicationRequest] MR
    let medCodings: (MR.medication as FHIR.CodeableConcept).coding
    where MR.status.value = 'completed'
    and exists (
      medCodings C
        where C.system.value = 'http://www.whocc.no/atc'
        and (
          (Substring(C.code.value, 0, 3) = 'C07' and C.code.value != 'C07AA05')
          or (Substring(C.code.value, 0, 5) in {
            'C02CA', 'C02DB', 'C02DC', 'C02DD', 'C03AA', 'C03BA', 'C03CA', 'C03DA',
            'C08CA', 'C08DA', 'C08DB', 'C09AA', 'C09CA'
          } and C.code.value != 'C08CA06')
        )
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(MR.encounter.reference.value, '/'))
        and E.class.code.value = 'AMB'
        and E.status.value = 'finished'
    )

// 2. 計算同院同病人的藥品重疊日數
define "Drug Overlap Days":
  flatten (
    "Antihypertensive Prescriptions" P1
      return
        "Antihypertensive Prescriptions" P2
          let 
            patientRef: P1.subject.reference.value,
            organizationRef: P1.requester.reference.value,
            start1: P1.dispenseRequest.validityPeriod.start.value,
            end1: P1.dispenseRequest.validityPeriod.end.value,
            start2: P2.dispenseRequest.validityPeriod.start.value,
            end2: P2.dispenseRequest.validityPeriod.end.value,
            overlap: CalculateOverlapDays(start1, end1, start2, end2)
          where P2.subject.reference.value = patientRef
          and P2.requester.reference.value = organizationRef
          and P2.id.value != P1.id.value
          and overlap > 0
          return {
            prescription1: P1.id.value,
            prescription2: P2.id.value,
            overlapDays: overlap
          }
  )

// 3. 分母：降血壓藥品總給藥日數
define "Total Drug Days":
  Sum(
    "Antihypertensive Prescriptions" P
      return days between P.dispenseRequest.validityPeriod.start.value 
                     and P.dispenseRequest.validityPeriod.end.value + 1
  )

// 4. 分子：重疊給藥日數
define "Overlap Drug Days":
  Sum("Drug Overlap Days" D return D.overlapDays) / 2  // 除以2避免重複計算

// 5. 指標計算結果：用藥日數重疊率
define "Drug Overlap Rate":
  if "Total Drug Days" > 0 then
    ("Overlap Drug Days" / "Total Drug Days") * 100
  else
    null
