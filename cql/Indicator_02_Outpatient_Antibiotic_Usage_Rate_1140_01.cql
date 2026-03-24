library Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1140.01
// 條件依據：門診抗生素使用率
// 製作日期：2026-01-08
//
// 【歷史參考基準】111年第1季 (2022Q1)
// 抗生素給藥案件數: 1,156,837
// 給藥案件數: 5,831,409
// 門診抗生素使用率: 19.84%

// 【公式說明】
// 分子: 給藥案件之抗生素藥品案件數（ATC碼前3碼為'J01'）
// 分母: 給藥案件數（藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6）
// 排除: 急診案件(02)、門診手術(03)、事前審查藥品、STAT藥品、代辦案件

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Emergency": 'EMER' from "ActCode" display 'Emergency'

// 1. 門診給藥案件（分母）
define "Outpatient Drug Encounters":
  [Encounter] E
    where E.status = 'finished'
      and E.class.code = 'AMB'
      and exists (
        [MedicationRequest] MR
          where MR.encounter.reference = 'Encounter/' + E.id
            and MR.status = 'completed'
            and exists (MR.dosageInstruction)
      )

// 2. 分母中的有效給藥請求
define "Valid Medication Requests":
  [MedicationRequest] MR
    where MR.status = 'completed'
      and exists (MR.dosageInstruction)

// 3. 抗生素給藥請求（ATC碼前3碼為J01）
define "Antibiotic Medication Requests":
  "Valid Medication Requests" MR
    let medication: MR.medication as FHIR.CodeableConcept
    where exists (
      medication.coding C
        where C.system = 'http://www.whocc.no/atc'
          and Substring(C.code, 0, 3) = 'J01'
    )

// 4. 門診抗生素案件（分子）
define "Outpatient Antibiotic Encounters":
  "Outpatient Drug Encounters" E
    where exists (
      "Antibiotic Medication Requests" MR
        where MR.encounter.reference = 'Encounter/' + E.id
    )

// 5. 分母：門診給藥案件數
define "Denominator":
  Count("Outpatient Drug Encounters")

// 6. 分子：門診抗生素案件數
define "Numerator":
  Count("Outpatient Antibiotic Encounters")

// 7. 指標計算結果：門診抗生素使用率（百分比）
define "Antibiotic Usage Rate":
  if "Denominator" > 0 then
    Round(("Numerator".toDecimal() / "Denominator".toDecimal()) * 100.0, 2)
  else
    null

// 8. 初始人口（用於測量報告）
define "Initial Population":
  "Outpatient Drug Encounters"