library Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1712
// 條件依據：同醫院門診同藥理用藥日數重疊率-降血糖(不分口服及注射)
// 製作日期：2025-11-20

// 【公式說明】
// 分子: 同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數
// 分母: 各案件之「給藥日數」總和
// 降血糖藥(不分口服及注射): ATC前5碼=A10AB、A10AC、A10AD、A10AE、A10BA、A10BB、A10BF、A10BG、A10BX、A10BH、A10BJ、A10BK

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'

// Helper function: 檢查是否為降血糖藥(不分口服及注射)
define function IsAntidiabeticDrug(atcCode String):
  Substring(atcCode, 0, 5) in {
    'A10AB', 'A10AC', 'A10AD', 'A10AE', 
    'A10BA', 'A10BB', 'A10BF', 'A10BG', 'A10BX',
    'A10BH', 'A10BJ', 'A10BK'
  }

// Helper function: 取兩個日期中較大者
define function MaxDateTime(d1 DateTime, d2 DateTime):
  if d1 is null then d2
  else if d2 is null then d1
  else if d1 > d2 then d1
  else d2

// Helper function: 取兩個日期中較小者
define function MinDateTime(d1 DateTime, d2 DateTime):
  if d1 is null then d2
  else if d2 is null then d1
  else if d1 < d2 then d1
  else d2

// Helper function: 計算兩個日期區間的重疊天數
define function CalculateOverlapDays(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then
    0
  else if MaxDateTime(start1, start2) <= MinDateTime(end1, end2) then
    days between MaxDateTime(start1, start2) and MinDateTime(end1, end2) + 1
  else
    0

// 1. 同醫院門診降血糖藥品處方
define "Antidiabetic Prescriptions":
  [MedicationRequest] MR
    let medCodings: (MR.medication as FHIR.CodeableConcept).coding
    where MR.status.value = 'completed'
    and exists (
      medCodings MC
        where MC.system.value = 'http://www.whocc.no/atc'
        and IsAntidiabeticDrug(MC.code.value)
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(MR.encounter.reference.value, '/'))
        and E.class.code.value = 'AMB'
        and E.status.value = 'finished'
        and not exists (E.type T where exists (T.coding C where C.code.value = 'AGENCY'))
    )

// 2. 計算同院同病人的藥品重疊日數
define "Drug Overlap Days":
  flatten (
    "Antidiabetic Prescriptions" P1
      return
        "Antidiabetic Prescriptions" P2
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

// 3. 分母：降血糖藥品總給藥日數
define "Total Drug Days":
  Sum(
    "Antidiabetic Prescriptions" P
      return days between P.dispenseRequest.validityPeriod."start".value 
                     and P.dispenseRequest.validityPeriod."end".value + 1
  )

// 4. 分子：重疊給藥日數
define "Overlap Drug Days":
  Sum("Drug Overlap Days" D return D.overlapDays) / 2

// 5. 指標計算結果：用藥日數重疊率
define "Drug Overlap Rate":
  if "Total Drug Days" > 0 then
    ("Overlap Drug Days" / "Total Drug Days") * 100
  else
    null
