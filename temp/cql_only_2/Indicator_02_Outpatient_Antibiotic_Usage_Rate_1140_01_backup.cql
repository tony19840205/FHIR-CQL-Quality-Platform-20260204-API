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
//
// 【公式說明】
// 分子: 給藥案件之抗生素藥品案件數（ATC碼前3碼為'J01'）
// 分母: 給藥案件數（藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6）
// 排除: 急診案件(02)、門診手術(03)、事前審查藥品、STAT藥品、代辦案件

define "Measurement Period Start": @2024-01-01
define "Measurement Period End": @2099-12-31
define "Measurement Period": Interval["Measurement Period Start", "Measurement Period End"]

context Patient

// ========== Helper Functions ==========

define function "GetId"(reference Reference):
  Last(Split(reference.reference.value, '/'))

define function "HasAntibioticATC"(medication Medication):
  if medication is null or medication.code is null or medication.code.coding is null then false
  else
    exists(
      medication.code.coding C
        where C.system.value = 'http://www.whocc.no/atc'
          and Substring(C.code.value, 0, 3) = 'J01'
    )

// ========== 門診就診記錄 ==========

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and E.period.start.value during "Measurement Period"
      and not exists (
        E.extension EXT
          where EXT.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
            and EXT.value = true
      )
      and not exists (
        E.extension EXT2
          where EXT2.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/outpatient-surgery'
            and EXT2.value = true
      )

// ========== 有效用藥請求 ==========

define "Valid Medication Requests":
  [MedicationRequest] MR
    where MR.status.value in { 'active', 'completed' }
      and MR.intent.value = 'order'
      and MR.authoredOn.value during "Measurement Period"
      and exists(MR.dosageInstruction)

// ========== 抗生素用藥請求 ==========

define "Antibiotic Medication Requests":
  "Valid Medication Requests" MR
    where exists(
      [Medication] M
        where M.id.value = "GetId"(MR.medication)
        and "HasAntibioticATC"(M)
    )

// ========== 門診給藥案件（分母）==========

define "Outpatient Drug Encounters":
  from "Outpatient Encounters" E,
    "Valid Medication Requests" MR
  where "GetId"(MR.encounter) = E.id.value
  return E

// ========== 門診抗生素案件（分子）==========

define "Outpatient Antibiotic Encounters":
  from "Outpatient Encounters" E,
    "Antibiotic Medication Requests" MR
  where "GetId"(MR.encounter) = E.id.value
  return E

// ========== 分母：門診給藥案件數 ==========

define "Denominator":
  Count(distinct "Outpatient Drug Encounters")

// ========== 分子：門診抗生素案件數 ==========

define "Numerator":
  Count(distinct "Outpatient Antibiotic Encounters")

// ========== 指標計算結果 ==========

define "Antibiotic Usage Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100.0
  else
    null

// ========== 指標報告 ==========

define "Indicator Result":
  {
    indicatorCode: '1140.01',
    indicatorName: '門診抗生素使用率',
    indicatorNameEn: 'Outpatient Antibiotic Usage Rate',
    measurementPeriod: "Measurement Period",
    denominator: "Denominator",
    numerator: "Numerator",
    antibioticUsageRate: "Antibiotic Usage Rate",
    dataSource: '醫療給付檔案分析系統',
    version: '1.0.0',
    reference2022Q1: {
      antibioticCases: 1156837,
      totalCases: 5831409,
      rate: 19.84
    }
  }
