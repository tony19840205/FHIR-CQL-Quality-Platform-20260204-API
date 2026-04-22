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

// ========== 2024年季度統計 ==========

define "2024Q1 Period": Interval[@2024-01-01, @2024-03-31]
define "2024Q2 Period": Interval[@2024-04-01, @2024-06-30]
define "2024Q3 Period": Interval[@2024-07-01, @2024-09-30]
define "2024Q4 Period": Interval[@2024-10-01, @2024-12-31]

define "2024Q1 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q1 Period"
      return E
  ))

define "2024Q1 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q1 Period"
      return E
  ))

define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then
    Round(("2024Q1 Numerator" / "2024Q1 Denominator") * 100.0, 2)
  else
    0.0

define "2024Q2 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q2 Period"
      return E
  ))

define "2024Q2 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q2 Period"
      return E
  ))

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then
    Round(("2024Q2 Numerator" / "2024Q2 Denominator") * 100.0, 2)
  else
    0.0

define "2024Q3 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q3 Period"
      return E
  ))

define "2024Q3 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q3 Period"
      return E
  ))

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then
    Round(("2024Q3 Numerator" / "2024Q3 Denominator") * 100.0, 2)
  else
    0.0

define "2024Q4 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q4 Period"
      return E
  ))

define "2024Q4 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2024Q4 Period"
      return E
  ))

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then
    Round(("2024Q4 Numerator" / "2024Q4 Denominator") * 100.0, 2)
  else
    0.0

// ========== 2025年季度統計 ==========

define "2025Q1 Period": Interval[@2025-01-01, @2025-03-31]
define "2025Q2 Period": Interval[@2025-04-01, @2025-06-30]
define "2025Q3 Period": Interval[@2025-07-01, @2025-09-30]
define "2025Q4 Period": Interval[@2025-10-01, @2025-12-31]

define "2025Q1 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q1 Period"
      return E
  ))

define "2025Q1 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q1 Period"
      return E
  ))

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then
    Round(("2025Q1 Numerator" / "2025Q1 Denominator") * 100.0, 2)
  else
    0.0

define "2025Q2 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q2 Period"
      return E
  ))

define "2025Q2 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q2 Period"
      return E
  ))

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then
    Round(("2025Q2 Numerator" / "2025Q2 Denominator") * 100.0, 2)
  else
    0.0

define "2025Q3 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q3 Period"
      return E
  ))

define "2025Q3 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q3 Period"
      return E
  ))

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then
    Round(("2025Q3 Numerator" / "2025Q3 Denominator") * 100.0, 2)
  else
    0.0

define "2025Q4 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q4 Period"
      return E
  ))

define "2025Q4 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2025Q4 Period"
      return E
  ))

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then
    Round(("2025Q4 Numerator" / "2025Q4 Denominator") * 100.0, 2)
  else
    0.0

// ========== 2026年季度統計 ==========

define "2026Q1 Period": Interval[@2026-01-01, @2026-03-31]

define "2026Q1 Denominator":
  Count(distinct(
    from "Outpatient Encounters" E, "Valid Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2026Q1 Period"
      return E
  ))

define "2026Q1 Numerator":
  Count(distinct(
    from "Outpatient Encounters" E, "Antibiotic Medication Requests" MR
      where "GetId"(MR.encounter) = E.id.value
        and E.period.start.value during "2026Q1 Period"
      return E
  ))

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then
    Round(("2026Q1 Numerator" / "2026Q1 Denominator") * 100.0, 2)
  else
    0.0

// ========== 總計統計 ==========

define "Total Denominator": "Denominator"
define "Total Numerator": "Numerator"
define "Total Rate": "Antibiotic Usage Rate"

// ========== 指標報告 ==========

define "Indicator Result":
  {
    indicatorCode: '1140.01',
    indicatorName: '門診抗生素使用率',
    indicatorNameEn: 'Outpatient Antibiotic Usage Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '長庚紀念醫院林口醫學中心',
    compiledDate: '2026-01-08',
    version: '1.0.0',
    denominatorCriteria: '給藥案件（藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6）',
    numeratorCriteria: '給藥案件之抗生素藥品案件（ATC碼前3碼為J01）',
    exclusionCriteria: '急診案件(02)、門診手術(03)、事前審查藥品、STAT藥品、代辦案件',
    note: '歷史參考基準：門診抗生素使用率（2022Q1）=19.84%',
    q2024_1_denominator: "2024Q1 Denominator",
    q2024_1_numerator: "2024Q1 Numerator",
    q2024_1_rate: "2024Q1 Rate",
    q2024_2_denominator: "2024Q2 Denominator",
    q2024_2_numerator: "2024Q2 Numerator",
    q2024_2_rate: "2024Q2 Rate",
    q2024_3_denominator: "2024Q3 Denominator",
    q2024_3_numerator: "2024Q3 Numerator",
    q2024_3_rate: "2024Q3 Rate",
    q2024_4_denominator: "2024Q4 Denominator",
    q2024_4_numerator: "2024Q4 Numerator",
    q2024_4_rate: "2024Q4 Rate",
    q2025_1_denominator: "2025Q1 Denominator",
    q2025_1_numerator: "2025Q1 Numerator",
    q2025_1_rate: "2025Q1 Rate",
    q2025_2_denominator: "2025Q2 Denominator",
    q2025_2_numerator: "2025Q2 Numerator",
    q2025_2_rate: "2025Q2 Rate",
    q2025_3_denominator: "2025Q3 Denominator",
    q2025_3_numerator: "2025Q3 Numerator",
    q2025_3_rate: "2025Q3 Rate",
    q2025_4_denominator: "2025Q4 Denominator",
    q2025_4_numerator: "2025Q4 Numerator",
    q2025_4_rate: "2025Q4 Rate",
    q2026_1_denominator: "2026Q1 Denominator",
    q2026_1_numerator: "2026Q1 Numerator",
    q2026_1_rate: "2026Q1 Rate",
    total_denominator: "Total Denominator",
    total_numerator: "Total Numerator",
    total_rate: "Total Rate"
  }
