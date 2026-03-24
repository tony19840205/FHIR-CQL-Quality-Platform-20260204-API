library Indicator_Surgery_General_Anesthesia_3Day_Pneumonia_ED_Readmission version '1.0.0'

/*
住院手術採全身麻醉出院後三日內因肺炎急診或再住院之比率
Inpatient Surgery with General Anesthesia 3-Day Pneumonia ED Visit or Readmission Rate

計算說明:
- 分子：出院當日及出院後3日內因主、次診斷肺炎再急診或再住院人次數
- 分母：18歲(含)以上住院手術採全身麻醉且出院的人次數
- 資料範圍：醫院住院資料
- 計算頻率：月、季、年

備註:
1. 排除條件：入院前二週有肺炎診斷或入院前二週門住診有緊急手術患者
2. 18歲(含)以上：住院年月-出生年月≥216
3. 住院手術採全身麻醉：
   條同次住院有全身麻醉醫令代碼96017C、96018C、96019C、96020C、96021C、96022C，且包含96025B(麻醉恢復照護費)及96026B(麻醉前評估)且出院
4. 肺炎：ICD-10-CM前三碼為J12、J13、J14、J15、J16、J17、J18
5. 再急診：以分母出院案件為母體，勾稽距出院日0至3日內之急診案件
6. 再住院：以分母出院案件為母體，勾稽距出院日0至3日內之住院案件
7. 排除1年內分母小於30例醫院之醫院
8. 臨床意義：監測全身麻醉手術後肺炎併發症，評估術後呼吸道照護品質和麻醉恢復管理
9. 計算範圍：2026年(115年)資料

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

// 年齡限制（月數）
parameter "Minimum Age Months" Integer default 216  // 18歲 = 216個月

// 入院前回溯期間（2週）
parameter "Pre Admission Lookback Days" Integer default 14

// 再急診/再住院監測期間（3天，含出院當日）
parameter "Monitoring Days" Integer default 3

// 醫院最小案例數門檻
parameter "Minimum Hospital Cases" Integer default 30

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'

// 肺炎診斷codes (ICD-10-CM前三碼J12-J18)
code "J12": 'J12' from "ICD10CM" display '病毒性肺炎'
code "J13": 'J13' from "ICD10CM" display '肺炎鏈球菌引起的肺炎'
code "J14": 'J14' from "ICD10CM" display '嗜血桿菌引起的肺炎'
code "J15": 'J15' from "ICD10CM" display '細菌性肺炎'
code "J16": 'J16' from "ICD10CM" display '其他感染性病原體引起的肺炎'
code "J17": 'J17' from "ICD10CM" display '他處歸類之疾病引起的肺炎'
code "J18": 'J18' from "ICD10CM" display '肺炎，病原體未明示'

// 全身麻醉醫令codes
code "96017C": '96017C' from "TWProcedure" display '全身麻醉'
code "96018C": '96018C' from "TWProcedure" display '全身麻醉'
code "96019C": '96019C' from "TWProcedure" display '全身麻醉'
code "96020C": '96020C' from "TWProcedure" display '全身麻醉'
code "96021C": '96021C' from "TWProcedure" display '全身麻醉'
code "96022C": '96022C' from "TWProcedure" display '全身麻醉'

// 麻醉相關醫令codes
code "96025B": '96025B' from "TWProcedure" display '麻醉恢復照護費'
code "96026B": '96026B' from "TWProcedure" display '麻醉前評估'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'

// 所有急診Encounter
define "All ED Encounters":
  [Encounter: type in "ED Encounter Codes"] E
    where E.status = 'finished'

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// Encounter類型編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

define "ED Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'EMER', display: 'emergency' }
  }

define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有Procedure
define "All Procedures":
  [Procedure] P

// 所有Condition
define "All Conditions":
  [Condition] C

// ===== 肺炎診斷判斷 =====

// 判斷Condition是否為肺炎診斷（ICD-10-CM前三碼J12-J18）
define function "IsPneumoniaDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          StartsWith(C.code, 'J12')
          or StartsWith(C.code, 'J13')
          or StartsWith(C.code, 'J14')
          or StartsWith(C.code, 'J15')
          or StartsWith(C.code, 'J16')
          or StartsWith(C.code, 'J17')
          or StartsWith(C.code, 'J18')
        )
  )

// 判斷Encounter中是否有肺炎診斷（主診斷或次診斷）
define function "HasPneumoniaDiagnosis"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and "IsPneumoniaDiagnosis"(C)
  )

// 取得Encounter出院日期
define function "GetDischargeDate"(encounter Encounter):
  end of encounter.period

// 取得Encounter入院日期
define function "GetAdmissionDate"(encounter Encounter):
  start of encounter.period

// ===== 年齡計算 =====

// 計算住院時的年齡（月數）- 住院年月 - 出生年月
define function "GetAgeInMonthsAtAdmission"(admissionDate DateTime):
  months between Patient.birthDate and date from admissionDate

// 判斷年齡是否≥18歲（月數 ≥ 216）
define function "IsAge18Plus"(admissionDate DateTime):
  let ageMonths: "GetAgeInMonthsAtAdmission"(admissionDate)
  return
    ageMonths >= "Minimum Age Months"

// ===== 全身麻醉判斷 =====

// 判斷Procedure是否為全身麻醉（96017C-96022C）
define function "IsGeneralAnesthesiaProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '96017C'
            or C.code = '96018C'
            or C.code = '96019C'
            or C.code = '96020C'
            or C.code = '96021C'
            or C.code = '96022C'
          )
    )

// 判斷Procedure是否為麻醉恢復照護費（96025B）
define function "IsAnesthesiaRecoveryProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and C.code = '96025B'
    )

// 判斷Procedure是否為麻醉前評估（96026B）
define function "IsPreAnesthesiaAssessmentProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and C.code = '96026B'
    )

// 判斷Encounter是否有完整的全身麻醉（含麻醉、恢復照護、前評估）
define function "HasCompleteGeneralAnesthesia"(encounter Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference = 'Encounter/' + encounter.id
        and "IsGeneralAnesthesiaProcedure"(P)
  )
    and exists(
      "All Procedures" P
        where P.encounter.reference = 'Encounter/' + encounter.id
          and "IsAnesthesiaRecoveryProcedure"(P)
    )
    and exists(
      "All Procedures" P
        where P.encounter.reference = 'Encounter/' + encounter.id
          and "IsPreAnesthesiaAssessmentProcedure"(P)
    )

// ===== 排除條件判斷 =====

// 計算入院前2週期間
define function "GetPreAdmission2WeeksPeriod"(admissionDate DateTime):
  Interval[admissionDate - "Pre Admission Lookback Days" days, admissionDate]

// 判斷入院前2週是否有肺炎診斷
define function "HasPneumoniaInPrior2Weeks"(admissionDate DateTime):
  let priorPeriod: "GetPreAdmission2WeeksPeriod"(admissionDate)
  return
    exists(
      ("All Inpatient Encounters" union "All Outpatient Encounters") E
        where start of E.period during priorPeriod
          and "HasPneumoniaDiagnosis"(E)
    )

// 判斷Procedure是否為緊急手術（假設使用urgency標記）
define function "IsEmergentSurgery"(procedure Procedure):
  procedure.status = 'completed'
    and (
      procedure.category.coding[0].code = 'emergent'
      or procedure.priority.coding[0].code = 'urgent'
      or procedure.priority.coding[0].code = 'emergent'
    )

// 判斷入院前2週門住診是否有緊急手術
define function "HasEmergentSurgeryInPrior2Weeks"(admissionDate DateTime):
  let priorPeriod: "GetPreAdmission2WeeksPeriod"(admissionDate)
  return
    exists(
      "All Procedures" P
        where "IsEmergentSurgery"(P)
          and exists(
            ("All Inpatient Encounters" union "All Outpatient Encounters") E
              where P.encounter.reference = 'Encounter/' + E.id
                and start of E.period during priorPeriod
          )
    )

// 判斷是否應排除
define function "ShouldExclude"(admissionDate DateTime):
  "HasPneumoniaInPrior2Weeks"(admissionDate)
    or "HasEmergentSurgeryInPrior2Weeks"(admissionDate)

// ===== 再急診/再住院判斷 =====

// 計算3天監測期間（含出院當日，0-3天）
define function "Get3DayMonitoringPeriod"(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Monitoring Days" days]

// 取得3天內的再急診或再住院Encounter
define function "GetEDOrReadmissionsWithin3Days"(dischargeDate DateTime):
  let monitoringPeriod: "Get3DayMonitoringPeriod"(dischargeDate)
  return
    ("All ED Encounters" union "All Inpatient Encounters") E
      where "GetAdmissionDate"(E) during monitoringPeriod

// 判斷3天內是否有肺炎相關急診或再住院
define function "HasPneumoniaEDOrReadmissionWithin3Days"(dischargeDate DateTime):
  exists(
    "GetEDOrReadmissionsWithin3Days"(dischargeDate) E
      where "HasPneumoniaDiagnosis"(E)
  )

// ===== 分母定義（依期間）=====

// 取得期間內符合條件的全身麻醉手術出院案件
define function "GetQualifyingGeneralAnesthesiaDischargesInPeriod"(period Interval<DateTime>):
  "All Inpatient Encounters" E
    let dischargeDate: "GetDischargeDate"(E),
        admissionDate: "GetAdmissionDate"(E)
    where dischargeDate during period
      and "IsAge18Plus"(admissionDate)
      and "HasCompleteGeneralAnesthesia"(E)
      and not "ShouldExclude"(admissionDate)

// 計算分母（針對特定期間）
define function "GetDenominatorCountInPeriod"(period Interval<DateTime>):
  Count("GetQualifyingGeneralAnesthesiaDischargesInPeriod"(period))

// 分母（全年）
define "Denominator":
  "GetDenominatorCountInPeriod"("Measurement Period")

// 分母（月度）
define "Denominator Monthly":
  "Monthly Periods" P
    return "GetDenominatorCountInPeriod"(P)

// 分母（季度）
define "Denominator Quarterly":
  "Quarterly Periods" P
    return "GetDenominatorCountInPeriod"(P)

// ===== 分子定義（依期間）=====

// 取得期間內有3天內肺炎急診或再住院的案件
define function "GetPneumoniaEDOrReadmissionsInPeriod"(period Interval<DateTime>):
  "GetQualifyingGeneralAnesthesiaDischargesInPeriod"(period) E
    where "HasPneumoniaEDOrReadmissionWithin3Days"("GetDischargeDate"(E))

// 計算分子（針對特定期間）
define function "GetNumeratorCountInPeriod"(period Interval<DateTime>):
  Count("GetPneumoniaEDOrReadmissionsInPeriod"(period))

// 分子（全年）
define "Numerator":
  "GetNumeratorCountInPeriod"("Measurement Period")

// 分子（月度）
define "Numerator Monthly":
  "Monthly Periods" P
    return "GetNumeratorCountInPeriod"(P)

// 分子（季度）
define "Numerator Quarterly":
  "Quarterly Periods" P
    return "GetNumeratorCountInPeriod"(P)

// ===== 指標計算 =====

// 整體指標（全年）
define "Indicator Rate":
  if "Denominator" >= "Minimum Hospital Cases"
    then Round("Numerator" / "Denominator" * 100, 2)
    else null

// 月度指標
define "Indicator Rate Monthly":
  "Monthly Periods" P
    let denom: "GetDenominatorCountInPeriod"(P),
        numer: "GetNumeratorCountInPeriod"(P)
    return
      if denom > 0
        then Round(numer / denom * 100, 2)
        else null

// 季度指標
define "Indicator Rate Quarterly":
  "Quarterly Periods" P
    let denom: "GetDenominatorCountInPeriod"(P),
        numer: "GetNumeratorCountInPeriod"(P)
    return
      if denom > 0
        then Round(numer / denom * 100, 2)
        else null

// ===== 品質檢核 =====

// 資料完整性檢查（全年）
define "Data Quality Check":
  let qualifyingDischarges: "GetQualifyingGeneralAnesthesiaDischargesInPeriod"("Measurement Period"),
      allInpatientDischarges: "All Inpatient Encounters" E
        where "GetDischargeDate"(E) during "Measurement Period"
  return Tuple {
    total_inpatient_encounters: Count(allInpatientDischarges),
    age_18_plus: Count(
      allInpatientDischarges E
        where "IsAge18Plus"("GetAdmissionDate"(E))
    ),
    with_general_anesthesia: Count(
      allInpatientDischarges E
        where "HasCompleteGeneralAnesthesia"(E)
    ),
    prior_pneumonia_excluded: Count(
      allInpatientDischarges E
        where "HasPneumoniaInPrior2Weeks"("GetAdmissionDate"(E))
    ),
    prior_emergent_surgery_excluded: Count(
      allInpatientDischarges E
        where "HasEmergentSurgeryInPrior2Weeks"("GetAdmissionDate"(E))
    ),
    qualifying_general_anesthesia_discharges: Count(qualifyingDischarges),
    pneumonia_ed_or_readmissions_within_3days: "Numerator",
    meets_minimum_cases: "Denominator" >= "Minimum Hospital Cases"
  }

// 全身麻醉出院統計
define "General Anesthesia Discharge Statistics":
  let qualifyingDischarges: "GetQualifyingGeneralAnesthesiaDischargesInPeriod"("Measurement Period"),
      dischargeDates: qualifyingDischarges E return "GetDischargeDate"(E)
  return Tuple {
    total_qualifying_discharges: Count(qualifyingDischarges),
    first_discharge_date: if exists(dischargeDates) then ToString(First(dischargeDates D sort ascending)) else null,
    last_discharge_date: if exists(dischargeDates) then ToString(Last(dischargeDates D sort ascending)) else null
  }

// 肺炎急診/再住院統計
define "Pneumonia ED Readmission Statistics":
  let edOrReadmissions: "GetPneumoniaEDOrReadmissionsInPeriod"("Measurement Period"),
      allEDOrReadmissionEncounters: flatten(
        edOrReadmissions E
          return "GetEDOrReadmissionsWithin3Days"("GetDischargeDate"(E)) R
            where "HasPneumoniaDiagnosis"(R)
      )
  return Tuple {
    total_pneumonia_ed_or_readmissions: Count(edOrReadmissions),
    ed_only: Count(allEDOrReadmissionEncounters E where E.type in "ED Encounter Codes"),
    readmission_only: Count(allEDOrReadmissionEncounters E where E.type in "Inpatient Encounter Codes"),
    rate_percent: "Indicator Rate"
  }

// 事件發生時間統計
define "Event Timing Statistics":
  let edOrReadmissions: "GetPneumoniaEDOrReadmissionsInPeriod"("Measurement Period"),
      eventIntervals: edOrReadmissions E
        let dischargeDate: "GetDischargeDate"(E),
            events: "GetEDOrReadmissionsWithin3Days"(dischargeDate) R
              where "HasPneumoniaDiagnosis"(R),
            firstEventDate: if exists(events)
              then "GetAdmissionDate"(First(events R sort by "GetAdmissionDate"(R) ascending))
              else null,
            daysToEvent: if firstEventDate is not null
              then days between dischargeDate and firstEventDate
              else null
        where daysToEvent is not null
        return daysToEvent,
      avgDays: if exists(eventIntervals)
        then Round(Sum(eventIntervals) / Count(eventIntervals), 1)
        else null
  return Tuple {
    average_days_to_event: avgDays,
    min_days_to_event: if exists(eventIntervals) then First(eventIntervals I sort ascending) else null,
    max_days_to_event: if exists(eventIntervals) then Last(eventIntervals I sort ascending) else null,
    day_0_events: Count(eventIntervals I where I = 0),
    day_1_events: Count(eventIntervals I where I = 1),
    day_2_events: Count(eventIntervals I where I = 2),
    day_3_events: Count(eventIntervals I where I = 3)
  }

// 年齡分布統計
define "Age Distribution Statistics":
  let qualifyingDischarges: "GetQualifyingGeneralAnesthesiaDischargesInPeriod"("Measurement Period"),
      ageDistribution: qualifyingDischarges E
        let ageMonths: "GetAgeInMonthsAtAdmission"("GetAdmissionDate"(E)),
            ageYears: if ageMonths is not null then ageMonths / 12 else null
        return ageYears
  return Tuple {
    average_age: if exists(ageDistribution) 
      then Round(Sum(ageDistribution) / Count(ageDistribution), 1)
      else null,
    min_age: if exists(ageDistribution) then First(ageDistribution A sort ascending) else null,
    max_age: if exists(ageDistribution) then Last(ageDistribution A sort ascending) else null,
    age_18_44: Count(ageDistribution A where A >= 18 and A < 45),
    age_45_64: Count(ageDistribution A where A >= 45 and A < 65),
    age_65_plus: Count(ageDistribution A where A >= 65)
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
    indicator_name: '住院手術採全身麻醉出院後三日內因肺炎急診或再住院之比率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測全身麻醉手術後肺炎併發症，評估術後呼吸道照護品質和麻醉恢復管理',
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    meets_minimum_cases: "Denominator" >= "Minimum Hospital Cases",
    
    // 月度指標
    monthly_rates: "Indicator Rate Monthly",
    
    // 季度指標
    quarterly_rates: "Indicator Rate Quarterly",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // 全身麻醉出院統計
    general_anesthesia_discharge_statistics: "General Anesthesia Discharge Statistics",
    
    // 肺炎急診/再住院統計
    pneumonia_ed_readmission_statistics: "Pneumonia ED Readmission Statistics",
    
    // 事件發生時間統計
    event_timing_statistics: "Event Timing Statistics",
    
    // 年齡分布統計
    age_distribution_statistics: "Age Distribution Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
