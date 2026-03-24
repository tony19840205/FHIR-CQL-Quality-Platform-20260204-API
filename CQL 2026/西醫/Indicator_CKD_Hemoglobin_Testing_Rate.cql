library Indicator_CKD_Hemoglobin_Testing_Rate version '1.0.0'

/*
未期腎臟病前期病人至少每六個月檢測一次血色素的比率
Pre-ESRD (End-Stage Renal Disease) Patients with Hemoglobin Testing at Least Every 6 Months

計算說明:
- 分子：分母病患最近6個月有檢查血色素人數
- 分母：18歲以上因慢性腎臟病就醫至少3個月且從未洗腎者
- 資料範圍：西醫醫院門診及住院資料
- 計算頻率：月、季、半年、年

備註:
1. 18歲以上：統計期間內最後一個月-出生年月≥216(12個月*18)
2. 慢性腎臟病：門診二次或住診一次，主/次診斷任一碼ICD9_CM_CODE前3碼為585（105年1月起ICD10_CM_CODE全碼為：N184、N185、N186）
3. 從未洗腎：以最後一次就醫資料之實用年月跨院往前追2年從未申報以下碼令代碼的個案：
   - 腹膜透析：58002C、58009A、58009B、58010A、58010B、58011A、58011AB、58011B、58011C、58012A、58012B、58017B、58017C、58026C、58028C
   - 血液透析：58001C、58019C、58020C、58021C、58022C、58023C、58024C、58025C、58029C
   - 其他透析：58018C、58027C、58030B
4. 血色素檢查碼令代碼：08003C、08011C、08012C、08082C、08014C
5. 就醫至少3個月：統計期間內有慢性腎臟病診斷的就醫紀錄跨越至少3個月
6. 最近6個月：從統計期間結束日往前推算6個月（180天）
7. 臨床意義：血色素（Hemoglobin）監測對慢性腎臟病患者貧血管理至關重要，建議至少每6個月檢測一次
8. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-06)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 月度期間定義
parameter "Monthly Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-01-31T23:59:59.0],
    Interval[@2026-02-01T00:00:00.0, @2026-02-28T23:59:59.0],
    Interval[@2026-03-01T00:00:00.0, @2026-03-31T23:59:59.0],
    Interval[@2026-04-01T00:00:00.0, @2026-04-30T23:59:59.0],
    Interval[@2026-05-01T00:00:00.0, @2026-05-31T23:59:59.0],
    Interval[@2026-06-01T00:00:00.0, @2026-06-30T23:59:59.0],
    Interval[@2026-07-01T00:00:00.0, @2026-07-31T23:59:59.0],
    Interval[@2026-08-01T00:00:00.0, @2026-08-31T23:59:59.0],
    Interval[@2026-09-01T00:00:00.0, @2026-09-30T23:59:59.0],
    Interval[@2026-10-01T00:00:00.0, @2026-10-31T23:59:59.0],
    Interval[@2026-11-01T00:00:00.0, @2026-11-30T23:59:59.0],
    Interval[@2026-12-01T00:00:00.0, @2026-12-31T23:59:59.0]
  }

// 季度期間定義
parameter "Quarterly Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0],
    Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0],
    Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0],
    Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
  }

// 半年度期間定義
parameter "Semiannual Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-06-30T23:59:59.0],
    Interval[@2026-07-01T00:00:00.0, @2026-12-31T23:59:59.0]
  }

// 年齡限制（月數）
parameter "Minimum Age Months" Integer default 216  // 18歲 = 216個月

// CKD就醫期間（至少3個月）
parameter "CKD Monitoring Period Months" Integer default 3

// 檢測回溯期間（6個月）
parameter "Testing Lookback Days" Integer default 180

// 洗腎史回溯期間（2年）
parameter "Dialysis History Lookback Days" Integer default 730

// 編碼系統定義
codesystem "ICD9CM": 'http://hl7.org/fhir/sid/icd-9-cm'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "LOINC": 'http://loinc.org'

// 慢性腎臟病診斷碼定義（ICD-10-CM）
code "N184": 'N184' from "ICD10CM" display 'Chronic kidney disease, stage 4 (severe)'
code "N185": 'N185' from "ICD10CM" display 'Chronic kidney disease, stage 5'
code "N186": 'N186' from "ICD10CM" display 'End stage renal disease'

// 腹膜透析procedure codes
code "58002C": '58002C' from "TWProcedure" display 'Peritoneal dialysis'
code "58009A": '58009A' from "TWProcedure" display 'Peritoneal dialysis'
code "58009B": '58009B' from "TWProcedure" display 'Peritoneal dialysis'
code "58010A": '58010A' from "TWProcedure" display 'Peritoneal dialysis'
code "58010B": '58010B' from "TWProcedure" display 'Peritoneal dialysis'
code "58011A": '58011A' from "TWProcedure" display 'Peritoneal dialysis'
code "58011AB": '58011AB' from "TWProcedure" display 'Peritoneal dialysis'
code "58011B": '58011B' from "TWProcedure" display 'Peritoneal dialysis'
code "58011C": '58011C' from "TWProcedure" display 'Peritoneal dialysis'
code "58012A": '58012A' from "TWProcedure" display 'Peritoneal dialysis'
code "58012B": '58012B' from "TWProcedure" display 'Peritoneal dialysis'
code "58017B": '58017B' from "TWProcedure" display 'Peritoneal dialysis'
code "58017C": '58017C' from "TWProcedure" display 'Peritoneal dialysis'
code "58026C": '58026C' from "TWProcedure" display 'Peritoneal dialysis'
code "58028C": '58028C' from "TWProcedure" display 'Peritoneal dialysis'

// 血液透析procedure codes
code "58001C": '58001C' from "TWProcedure" display 'Hemodialysis'
code "58019C": '58019C' from "TWProcedure" display 'Hemodialysis'
code "58020C": '58020C' from "TWProcedure" display 'Hemodialysis'
code "58021C": '58021C' from "TWProcedure" display 'Hemodialysis'
code "58022C": '58022C' from "TWProcedure" display 'Hemodialysis'
code "58023C": '58023C' from "TWProcedure" display 'Hemodialysis'
code "58024C": '58024C' from "TWProcedure" display 'Hemodialysis'
code "58025C": '58025C' from "TWProcedure" display 'Hemodialysis'
code "58029C": '58029C' from "TWProcedure" display 'Hemodialysis'

// 其他透析procedure codes
code "58018C": '58018C' from "TWProcedure" display 'Other dialysis'
code "58027C": '58027C' from "TWProcedure" display 'Other dialysis'
code "58030B": '58030B' from "TWProcedure" display 'Other dialysis'

// 血色素檢查codes
code "08003C": '08003C' from "TWProcedure" display 'Hemoglobin test'
code "08011C": '08011C' from "TWProcedure" display 'Hemoglobin test'
code "08012C": '08012C' from "TWProcedure" display 'Hemoglobin test'
code "08082C": '08082C' from "TWProcedure" display 'Hemoglobin test'
code "08014C": '08014C' from "TWProcedure" display 'Hemoglobin test'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'

// Encounter類型編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有Procedure
define "All Procedures":
  [Procedure] P

// 所有Observation
define "All Observations":
  [Observation] O

// ===== 慢性腎臟病診斷判斷 =====

// 判斷Condition是否為慢性腎臟病（CKD）診斷（ICD-10: N184, N185, N186）
define function "IsCKDDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          C.code = 'N184'
          or C.code = 'N185'
          or C.code = 'N186'
        )
  )
    or exists(
      condition.code.coding C
        where C.system = 'http://hl7.org/fhir/sid/icd-9-cm'
          and StartsWith(C.code, '585')
    )

// 判斷Encounter是否有CKD診斷（主診斷或次診斷）
define function "HasCKDDiagnosis"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and "IsCKDDiagnosis"(C)
  )

// 取得所有CKD相關Encounter
define "CKD Encounters":
  ("All Outpatient Encounters" union "All Inpatient Encounters") E
    where "HasCKDDiagnosis"(E)

// ===== 年齡計算 =====

// 計算病人在統計期間結束時的年齡（月數）
define function "GetAgeInMonthsAtPeriodEnd"(periodEnd DateTime):
  months between Patient.birthDate and date from periodEnd

// 判斷病人在統計期間結束時是否≥18歲（216個月）
define function "IsAdultAtPeriodEnd"(periodEnd DateTime):
  "GetAgeInMonthsAtPeriodEnd"(periodEnd) >= "Minimum Age Months"

// ===== 透析治療判斷 =====

// 判斷Procedure是否為腹膜透析
define function "IsPeritonealDialysisProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '58002C'
            or C.code = '58009A'
            or C.code = '58009B'
            or C.code = '58010A'
            or C.code = '58010B'
            or C.code = '58011A'
            or C.code = '58011AB'
            or C.code = '58011B'
            or C.code = '58011C'
            or C.code = '58012A'
            or C.code = '58012B'
            or C.code = '58017B'
            or C.code = '58017C'
            or C.code = '58026C'
            or C.code = '58028C'
          )
    )

// 判斷Procedure是否為血液透析
define function "IsHemodialysisProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '58001C'
            or C.code = '58019C'
            or C.code = '58020C'
            or C.code = '58021C'
            or C.code = '58022C'
            or C.code = '58023C'
            or C.code = '58024C'
            or C.code = '58025C'
            or C.code = '58029C'
          )
    )

// 判斷Procedure是否為其他透析
define function "IsOtherDialysisProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '58018C'
            or C.code = '58027C'
            or C.code = '58030B'
          )
    )

// 判斷Procedure是否為任何透析
define function "IsDialysisProcedure"(procedure Procedure):
  "IsPeritonealDialysisProcedure"(procedure)
    or "IsHemodialysisProcedure"(procedure)
    or "IsOtherDialysisProcedure"(procedure)

// 取得Procedure執行日期
define function "GetProcedureDate"(procedure Procedure):
  Coalesce(
    start of (procedure.performed as Period),
    procedure.performed as dateTime
  )

// 計算透析史回溯期間（從最後一次CKD就醫往前2年）
define function "GetDialysisHistoryPeriod"(lastEncounterDate DateTime):
  Interval[lastEncounterDate - "Dialysis History Lookback Days" days, lastEncounterDate]

// 判斷病人是否有透析治療史（2年內）
define function "HasDialysisHistory"(lastEncounterDate DateTime):
  let historyPeriod: "GetDialysisHistoryPeriod"(lastEncounterDate)
  return
    exists(
      "All Procedures" P
        where "IsDialysisProcedure"(P)
          and "GetProcedureDate"(P) during historyPeriod
    )

// ===== CKD就醫期間判斷 =====

// 取得Encounter日期
define function "GetEncounterDate"(encounter Encounter):
  start of encounter.period

// 計算病人CKD就醫的時間跨度（首次到末次）
define function "GetCKDMonitoringSpan"(encounters List<Encounter>):
  let sortedDates: 
    (encounters E return "GetEncounterDate"(E)) D
      sort ascending,
      firstDate: First(sortedDates),
      lastDate: Last(sortedDates)
  return
    if firstDate is not null and lastDate is not null
      then months between firstDate and lastDate
      else 0

// 判斷病人CKD就醫是否至少3個月
define function "HasCKDMonitoringAtLeast3Months"(encounters List<Encounter>):
  "GetCKDMonitoringSpan"(encounters) >= "CKD Monitoring Period Months"

// ===== 血色素檢測判斷 =====

// 判斷Observation是否為血色素檢測
define function "IsHemoglobinTest"(observation Observation):
  observation.status in {'final', 'amended', 'corrected'}
    and exists(
      observation.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '08003C'
            or C.code = '08011C'
            or C.code = '08012C'
            or C.code = '08082C'
            or C.code = '08014C'
          )
    )

// 取得Observation執行日期
define function "GetObservationDate"(observation Observation):
  Coalesce(
    start of (observation.effective as Period),
    observation.effective as dateTime,
    observation.issued
  )

// 計算檢測回溯期間（最近6個月）
define function "GetTestingLookbackPeriod"(periodEnd DateTime):
  Interval[periodEnd - "Testing Lookback Days" days, periodEnd]

// 判斷病人在最近6個月是否有血色素檢測
define function "HasHemoglobinTestInLast6Months"(periodEnd DateTime):
  let testingPeriod: "GetTestingLookbackPeriod"(periodEnd)
  return
    exists(
      "All Observations" O
        where "IsHemoglobinTest"(O)
          and "GetObservationDate"(O) during testingPeriod
    )

// 取得病人在最近6個月的血色素檢測
define function "GetHemoglobinTestsInLast6Months"(periodEnd DateTime):
  let testingPeriod: "GetTestingLookbackPeriod"(periodEnd)
  return
    "All Observations" O
      where "IsHemoglobinTest"(O)
        and "GetObservationDate"(O) during testingPeriod

// ===== 分母定義（依期間）=====

// 判斷病人是否符合分母條件（針對特定期間）
define function "IsInDenominatorForPeriod"(period Interval<DateTime>):
  let periodEnd: end of period,
      ckdEncountersInPeriod: "CKD Encounters" E where "GetEncounterDate"(E) during period,
      lastCKDEncounter: Last(ckdEncountersInPeriod E sort by "GetEncounterDate"(E)),
      lastEncounterDate: if lastCKDEncounter is not null then "GetEncounterDate"(lastCKDEncounter) else null
  return
    "IsAdultAtPeriodEnd"(periodEnd)
      and exists(ckdEncountersInPeriod)
      and "HasCKDMonitoringAtLeast3Months"(ckdEncountersInPeriod)
      and lastEncounterDate is not null
      and not "HasDialysisHistory"(lastEncounterDate)

// 分母（全年）
define "Denominator":
  if "IsInDenominatorForPeriod"("Measurement Period") then 1 else 0

// 分母（月度）
define "Denominator Monthly":
  "Monthly Periods" P
    return if "IsInDenominatorForPeriod"(P) then 1 else 0

// 分母（季度）
define "Denominator Quarterly":
  "Quarterly Periods" P
    return if "IsInDenominatorForPeriod"(P) then 1 else 0

// 分母（半年度）
define "Denominator Semiannually":
  "Semiannual Periods" P
    return if "IsInDenominatorForPeriod"(P) then 1 else 0

// ===== 分子定義（依期間）=====

// 判斷病人是否符合分子條件（針對特定期間）
define function "IsInNumeratorForPeriod"(period Interval<DateTime>):
  let periodEnd: end of period
  return
    "IsInDenominatorForPeriod"(period)
      and "HasHemoglobinTestInLast6Months"(periodEnd)

// 分子（全年）
define "Numerator":
  if "IsInNumeratorForPeriod"("Measurement Period") then 1 else 0

// 分子（月度）
define "Numerator Monthly":
  "Monthly Periods" P
    return if "IsInNumeratorForPeriod"(P) then 1 else 0

// 分子（季度）
define "Numerator Quarterly":
  "Quarterly Periods" P
    return if "IsInNumeratorForPeriod"(P) then 1 else 0

// 分子（半年度）
define "Numerator Semiannually":
  "Semiannual Periods" P
    return if "IsInNumeratorForPeriod"(P) then 1 else 0

// ===== 指標計算 =====

// 整體指標（全年）
define "Indicator Rate":
  if "Denominator" > 0
    then Round("Numerator" / "Denominator" * 100, 2)
    else null

// 月度指標
define "Indicator Rate Monthly":
  "Monthly Periods" P
    let denom: if "IsInDenominatorForPeriod"(P) then 1 else 0,
        numer: if "IsInNumeratorForPeriod"(P) then 1 else 0
    return
      if denom > 0
        then Round(numer / denom * 100, 2)
        else null

// 季度指標
define "Indicator Rate Quarterly":
  "Quarterly Periods" P
    let denom: if "IsInDenominatorForPeriod"(P) then 1 else 0,
        numer: if "IsInNumeratorForPeriod"(P) then 1 else 0
    return
      if denom > 0
        then Round(numer / denom * 100, 2)
        else null

// 半年度指標
define "Indicator Rate Semiannually":
  "Semiannual Periods" P
    let denom: if "IsInDenominatorForPeriod"(P) then 1 else 0,
        numer: if "IsInNumeratorForPeriod"(P) then 1 else 0
    return
      if denom > 0
        then Round(numer / denom * 100, 2)
        else null

// ===== 品質檢核 =====

// 資料完整性檢查（全年）
define "Data Quality Check":
  let ckdEncounters: "CKD Encounters" E where "GetEncounterDate"(E) during "Measurement Period",
      periodEnd: end of "Measurement Period",
      lastCKDEncounter: Last(ckdEncounters E sort by "GetEncounterDate"(E)),
      lastEncounterDate: if lastCKDEncounter is not null then "GetEncounterDate"(lastCKDEncounter) else null
  return Tuple {
    total_outpatient_encounters: Count("All Outpatient Encounters" E where "GetEncounterDate"(E) during "Measurement Period"),
    total_inpatient_encounters: Count("All Inpatient Encounters" E where "GetEncounterDate"(E) during "Measurement Period"),
    ckd_encounters: Count(ckdEncounters),
    age_under_18_exclusions: 
      if not "IsAdultAtPeriodEnd"(periodEnd) then 1 else 0,
    insufficient_monitoring_exclusions:
      if exists(ckdEncounters) and not "HasCKDMonitoringAtLeast3Months"(ckdEncounters) then 1 else 0,
    dialysis_history_exclusions:
      if lastEncounterDate is not null and "HasDialysisHistory"(lastEncounterDate) then 1 else 0,
    qualified_ckd_patients: "Denominator",
    patients_with_hemoglobin_test: "Numerator"
  }

// CKD就醫模式統計
define "CKD Encounter Pattern Statistics":
  let ckdEncounters: "CKD Encounters" E where "GetEncounterDate"(E) during "Measurement Period"
  return Tuple {
    total_ckd_encounters: Count(ckdEncounters),
    outpatient_ckd_encounters: Count(ckdEncounters E where E.type in "Outpatient Encounter Codes"),
    inpatient_ckd_encounters: Count(ckdEncounters E where E.type in "Inpatient Encounter Codes"),
    monitoring_span_months: "GetCKDMonitoringSpan"(ckdEncounters),
    monitoring_at_least_3_months: "HasCKDMonitoringAtLeast3Months"(ckdEncounters)
  }

// CKD診斷分期統計
define "CKD Stage Statistics":
  let ckdEncounters: "CKD Encounters" E where "GetEncounterDate"(E) during "Measurement Period",
      allCKDConditions: "All Conditions" C 
        where exists(ckdEncounters E where C.encounter.reference = 'Encounter/' + E.id)
          and "IsCKDDiagnosis"(C)
  return Tuple {
    N184_stage4: Count(
      allCKDConditions C
        where exists(C.code.coding CD where CD.code = 'N184')
    ),
    N185_stage5: Count(
      allCKDConditions C
        where exists(C.code.coding CD where CD.code = 'N185')
    ),
    N186_ESRD: Count(
      allCKDConditions C
        where exists(C.code.coding CD where CD.code = 'N186')
    ),
    ICD9_585: Count(
      allCKDConditions C
        where exists(C.code.coding CD where StartsWith(CD.code, '585'))
    )
  }

// 透析治療統計
define "Dialysis Treatment Statistics":
  let periodEnd: end of "Measurement Period",
      ckdEncounters: "CKD Encounters" E where "GetEncounterDate"(E) during "Measurement Period",
      lastCKDEncounter: Last(ckdEncounters E sort by "GetEncounterDate"(E)),
      lastEncounterDate: if lastCKDEncounter is not null then "GetEncounterDate"(lastCKDEncounter) else null,
      historyPeriod: if lastEncounterDate is not null then "GetDialysisHistoryPeriod"(lastEncounterDate) else null as Interval<DateTime>,
      dialysisProcedures: if historyPeriod is not null 
        then ("All Procedures" P where "IsDialysisProcedure"(P) and "GetProcedureDate"(P) during historyPeriod)
        else null as List<Procedure>
  return Tuple {
    has_dialysis_history: if lastEncounterDate is not null then "HasDialysisHistory"(lastEncounterDate) else false,
    peritoneal_dialysis_count: if dialysisProcedures is not null then Count(dialysisProcedures P where "IsPeritonealDialysisProcedure"(P)) else 0,
    hemodialysis_count: if dialysisProcedures is not null then Count(dialysisProcedures P where "IsHemodialysisProcedure"(P)) else 0,
    other_dialysis_count: if dialysisProcedures is not null then Count(dialysisProcedures P where "IsOtherDialysisProcedure"(P)) else 0,
    total_dialysis_procedures: if dialysisProcedures is not null then Count(dialysisProcedures) else 0
  }

// 血色素檢測統計
define "Hemoglobin Testing Statistics":
  let periodEnd: end of "Measurement Period",
      tests: "GetHemoglobinTestsInLast6Months"(periodEnd),
      testDates: tests T return "GetObservationDate"(T)
  return Tuple {
    has_hemoglobin_test: "HasHemoglobinTestInLast6Months"(periodEnd),
    total_hemoglobin_tests: Count(tests),
    first_test_date: if exists(testDates) then ToString(First(testDates D sort ascending)) else null,
    last_test_date: if exists(testDates) then ToString(Last(testDates D sort ascending)) else null,
    testing_frequency: Count(tests),
    test_code_08003C: Count(tests T where exists(T.code.coding C where C.code = '08003C')),
    test_code_08011C: Count(tests T where exists(T.code.coding C where C.code = '08011C')),
    test_code_08012C: Count(tests T where exists(T.code.coding C where C.code = '08012C')),
    test_code_08082C: Count(tests T where exists(T.code.coding C where C.code = '08082C')),
    test_code_08014C: Count(tests T where exists(T.code.coding C where C.code = '08014C'))
  }

// 年齡統計
define "Age Statistics":
  let periodEnd: end of "Measurement Period",
      ageMonths: "GetAgeInMonthsAtPeriodEnd"(periodEnd),
      ageYears: if ageMonths is not null then ageMonths / 12 else null
  return Tuple {
    age_in_months: ageMonths,
    age_in_years: ageYears,
    is_adult: "IsAdultAtPeriodEnd"(periodEnd),
    age_group: 
      if ageYears is not null then
        if ageYears >= 18 and ageYears < 45 then '18-44'
        else if ageYears >= 45 and ageYears < 65 then '45-64'
        else if ageYears >= 65 and ageYears < 75 then '65-74'
        else if ageYears >= 75 then '75+'
        else 'under 18'
      else null
  }

// 性別統計
define "Gender Statistics":
  Tuple {
    gender: Patient.gender,
    is_male: Patient.gender = 'male',
    is_female: Patient.gender = 'female'
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '未期腎臟病前期病人至少每六個月檢測一次血色素的比率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '血色素（Hemoglobin）監測對慢性腎臟病患者貧血管理至關重要，建議至少每6個月檢測一次',
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    
    // 月度指標
    monthly_rates: "Indicator Rate Monthly",
    
    // 季度指標
    quarterly_rates: "Indicator Rate Quarterly",
    
    // 半年度指標
    semiannual_rates: "Indicator Rate Semiannually",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // CKD就醫模式統計
    ckd_encounter_pattern: "CKD Encounter Pattern Statistics",
    
    // CKD診斷分期統計
    ckd_stage_statistics: "CKD Stage Statistics",
    
    // 透析治療統計
    dialysis_treatment_statistics: "Dialysis Treatment Statistics",
    
    // 血色素檢測統計
    hemoglobin_testing_statistics: "Hemoglobin Testing Statistics",
    
    // 年齡統計
    age_statistics: "Age Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
