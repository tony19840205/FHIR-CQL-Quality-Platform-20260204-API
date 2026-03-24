library Indicator_COPD_14Day_Readmission version '1.0.0'

/*
肺阻塞出院後十四日內因肺阻塞再住院率
COPD 14-Day Readmission Rate

計算說明:
- 分子：出院14天內因主診斷肺阻塞再住院人次數（含急診轉住院案件）
- 分母：40歲(含)以上住院主診斷為肺阻塞且出院的人次數
- 資料範圍：醫院住院資料
- 計算頻率：月、季、年

備註:
1. 40歲(含)以上：入院年月-出生年月≥480(40*12)
2. 肺阻塞：主診斷前三碼為J41-J44且有使用呼吸道用藥
3. 呼吸道用藥：ATC全碼符合：R03AC04、R03AC03、R03AC02、R03AC12、R03AC13、R03AC18、R03AC19、R03AK04、R03AK03、R03AK06、R03AK07；
   或ATC碼前5碼為：R03DA、R03DB、R03BA、R03BB、R03AL、R03CC
4. 14天內：0≤再住院日-出院日≤14
5. 排除1年內分母小於30例個案之醫院
6. 臨床意義：監測COPD患者出院後病情控制和照護品質，評估急性惡化預防措施的有效性
7. 計算範圍：2026年(115年)資料

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
parameter "Minimum Age Months" Integer default 480  // 40歲 = 480個月

// 再住院監測期間（14天，含出院當日）
parameter "Monitoring Days" Integer default 14

// 醫院最小案例數門檻
parameter "Minimum Hospital Cases" Integer default 30

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'

// COPD診斷codes (ICD-10-CM前三碼J41-J44)
code "J41": 'J41' from "ICD10CM" display '單純性及黏液膿性慢性支氣管炎'
code "J42": 'J42' from "ICD10CM" display '未明示的慢性支氣管炎'
code "J43": 'J43' from "ICD10CM" display '肺氣腫'
code "J44": 'J44' from "ICD10CM" display '其他慢性阻塞性肺病'

// 呼吸道用藥 - ATC全碼
code "R03AC04": 'R03AC04' from "ATC" display 'Salbutamol'
code "R03AC03": 'R03AC03' from "ATC" display 'Terbutaline'
code "R03AC02": 'R03AC02' from "ATC" display 'Orciprenaline'
code "R03AC12": 'R03AC12' from "ATC" display 'Salmeterol'
code "R03AC13": 'R03AC13' from "ATC" display 'Formoterol'
code "R03AC18": 'R03AC18' from "ATC" display 'Indacaterol'
code "R03AC19": 'R03AC19' from "ATC" display 'Olodaterol'
code "R03AK04": 'R03AK04' from "ATC" display 'Salbutamol and ipratropium bromide'
code "R03AK03": 'R03AK03' from "ATC" display 'Fenoterol and ipratropium bromide'
code "R03AK06": 'R03AK06' from "ATC" display 'Salmeterol and fluticasone'
code "R03AK07": 'R03AK07' from "ATC" display 'Formoterol and budesonide'

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

// Encounter類型編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

define "ED Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'EMER', display: 'emergency' }
  }

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// ===== COPD診斷判斷 =====

// 判斷Condition是否為COPD診斷（ICD-10-CM前三碼J41-J44）
define function "IsCOPDDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          StartsWith(C.code, 'J41')
          or StartsWith(C.code, 'J42')
          or StartsWith(C.code, 'J43')
          or StartsWith(C.code, 'J44')
        )
  )

// 取得Encounter的主診斷
define function "GetPrincipalDiagnosis"(encounter Encounter):
  singleton from (
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and exists(
          C.category category
            where exists(
              category.coding coding
                where coding.code = 'encounter-diagnosis'
            )
        )
        and (
          C.verificationStatus is null
          or C.verificationStatus.coding[0].code = 'confirmed'
        )
      sort by (clinicalStatus.coding[0].code) descending
  )

// 判斷Encounter主診斷是否為COPD
define function "HasCOPDPrincipalDiagnosis"(encounter Encounter):
  let principalDiagnosis: "GetPrincipalDiagnosis"(encounter)
  return
    principalDiagnosis is not null
      and "IsCOPDDiagnosis"(principalDiagnosis)

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

// 判斷年齡是否≥40歲（月數 ≥ 480）
define function "IsAge40Plus"(admissionDate DateTime):
  let ageMonths: "GetAgeInMonthsAtAdmission"(admissionDate)
  return
    ageMonths >= "Minimum Age Months"

// ===== 呼吸道用藥判斷 =====

// 判斷MedicationRequest是否為呼吸道用藥（ATC全碼）
define function "IsRespiratoryMedicationFullCode"(medication MedicationRequest):
  medication.status in { 'active', 'completed' }
    and exists(
      medication.medicationCodeableConcept.coding C
        where C.system = 'http://www.whocc.no/atc'
          and (
            C.code = 'R03AC04'
            or C.code = 'R03AC03'
            or C.code = 'R03AC02'
            or C.code = 'R03AC12'
            or C.code = 'R03AC13'
            or C.code = 'R03AC18'
            or C.code = 'R03AC19'
            or C.code = 'R03AK04'
            or C.code = 'R03AK03'
            or C.code = 'R03AK06'
            or C.code = 'R03AK07'
          )
    )

// 判斷MedicationRequest是否為呼吸道用藥（ATC前5碼）
define function "IsRespiratoryMedicationPrefix"(medication MedicationRequest):
  medication.status in { 'active', 'completed' }
    and exists(
      medication.medicationCodeableConcept.coding C
        where C.system = 'http://www.whocc.no/atc'
          and (
            StartsWith(C.code, 'R03DA')
            or StartsWith(C.code, 'R03DB')
            or StartsWith(C.code, 'R03BA')
            or StartsWith(C.code, 'R03BB')
            or StartsWith(C.code, 'R03AL')
            or StartsWith(C.code, 'R03CC')
          )
    )

// 判斷MedicationRequest是否為呼吸道用藥（全碼或前5碼）
define function "IsRespiratoryMedication"(medication MedicationRequest):
  "IsRespiratoryMedicationFullCode"(medication)
    or "IsRespiratoryMedicationPrefix"(medication)

// 判斷Encounter期間是否有使用呼吸道用藥
define function "HasRespiratoryMedication"(encounter Encounter):
  exists(
    "All Medication Requests" M
      where M.encounter.reference = 'Encounter/' + encounter.id
        and "IsRespiratoryMedication"(M)
  )

// ===== 再住院判斷 =====

// 計算14天監測期間（含出院當日，0-14天）
define function "Get14DayMonitoringPeriod"(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Monitoring Days" days]

// 取得14天內的再住院Encounter（包含急診轉住院）
define function "GetReadmissionsWithin14Days"(dischargeDate DateTime):
  let monitoringPeriod: "Get14DayMonitoringPeriod"(dischargeDate)
  return
    "All Inpatient Encounters" E
      where "GetAdmissionDate"(E) during monitoringPeriod

// 判斷14天內是否有COPD主診斷再住院
define function "HasCOPDReadmissionWithin14Days"(dischargeDate DateTime):
  exists(
    "GetReadmissionsWithin14Days"(dischargeDate) E
      where "HasCOPDPrincipalDiagnosis"(E)
  )

// ===== 分母定義（依期間）=====

// 取得期間內符合條件的COPD出院案件
define function "GetQualifyingCOPDDischargesInPeriod"(period Interval<DateTime>):
  "All Inpatient Encounters" E
    let dischargeDate: "GetDischargeDate"(E),
        admissionDate: "GetAdmissionDate"(E)
    where dischargeDate during period
      and "IsAge40Plus"(admissionDate)
      and "HasCOPDPrincipalDiagnosis"(E)
      and "HasRespiratoryMedication"(E)

// 計算分母（針對特定期間）
define function "GetDenominatorCountInPeriod"(period Interval<DateTime>):
  Count("GetQualifyingCOPDDischargesInPeriod"(period))

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

// 取得期間內有14天內COPD再住院的案件
define function "GetCOPDReadmissionsInPeriod"(period Interval<DateTime>):
  "GetQualifyingCOPDDischargesInPeriod"(period) E
    where "HasCOPDReadmissionWithin14Days"("GetDischargeDate"(E))

// 計算分子（針對特定期間）
define function "GetNumeratorCountInPeriod"(period Interval<DateTime>):
  Count("GetCOPDReadmissionsInPeriod"(period))

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
  let qualifyingDischarges: "GetQualifyingCOPDDischargesInPeriod"("Measurement Period"),
      allInpatientDischarges: "All Inpatient Encounters" E
        where "GetDischargeDate"(E) during "Measurement Period"
  return Tuple {
    total_inpatient_encounters: Count(allInpatientDischarges),
    total_copd_principal_diagnosis: Count(
      allInpatientDischarges E
        where "HasCOPDPrincipalDiagnosis"(E)
    ),
    age_40_plus: Count(
      allInpatientDischarges E
        where "IsAge40Plus"("GetAdmissionDate"(E))
    ),
    with_respiratory_medication: Count(
      allInpatientDischarges E
        where "HasRespiratoryMedication"(E)
    ),
    age_excluded: Count(
      allInpatientDischarges E
        where "HasCOPDPrincipalDiagnosis"(E)
          and not "IsAge40Plus"("GetAdmissionDate"(E))
    ),
    no_respiratory_medication: Count(
      allInpatientDischarges E
        where "HasCOPDPrincipalDiagnosis"(E)
          and "IsAge40Plus"("GetAdmissionDate"(E))
          and not "HasRespiratoryMedication"(E)
    ),
    qualifying_copd_discharges: Count(qualifyingDischarges),
    copd_readmissions_within_14days: "Numerator",
    meets_minimum_cases: "Denominator" >= "Minimum Hospital Cases"
  }

// COPD出院統計
define "COPD Discharge Statistics":
  let qualifyingDischarges: "GetQualifyingCOPDDischargesInPeriod"("Measurement Period"),
      dischargeDates: qualifyingDischarges E return "GetDischargeDate"(E)
  return Tuple {
    total_qualifying_discharges: Count(qualifyingDischarges),
    first_discharge_date: if exists(dischargeDates) then ToString(First(dischargeDates D sort ascending)) else null,
    last_discharge_date: if exists(dischargeDates) then ToString(Last(dischargeDates D sort ascending)) else null
  }

// COPD再住院統計
define "COPD Readmission Statistics":
  let readmissions: "GetCOPDReadmissionsInPeriod"("Measurement Period"),
      allReadmissionEncounters: flatten(
        readmissions E
          return "GetReadmissionsWithin14Days"("GetDischargeDate"(E)) R
            where "HasCOPDPrincipalDiagnosis"(R)
      )
  return Tuple {
    total_copd_readmissions: Count(readmissions),
    total_readmission_encounters: Count(allReadmissionEncounters),
    readmission_rate_percent: "Indicator Rate",
    readmission_encounter_details: readmissions E
      let dischargeDate: "GetDischargeDate"(E),
          readmissionEncounters: "GetReadmissionsWithin14Days"(dischargeDate) R
            where "HasCOPDPrincipalDiagnosis"(R)
      return Tuple {
        discharge_date: ToString(dischargeDate),
        readmission_dates: readmissionEncounters R
          return ToString("GetAdmissionDate"(R))
      }
  }

// 再住院時間統計
define "Readmission Timing Statistics":
  let readmissions: "GetCOPDReadmissionsInPeriod"("Measurement Period"),
      readmissionIntervals: readmissions E
        let dischargeDate: "GetDischargeDate"(E),
            readmissionEncounters: "GetReadmissionsWithin14Days"(dischargeDate) R
              where "HasCOPDPrincipalDiagnosis"(R),
            firstReadmissionDate: if exists(readmissionEncounters)
              then "GetAdmissionDate"(First(readmissionEncounters R sort by "GetAdmissionDate"(R) ascending))
              else null,
            daysToReadmission: if firstReadmissionDate is not null
              then days between dischargeDate and firstReadmissionDate
              else null
        where daysToReadmission is not null
        return daysToReadmission,
      avgDays: if exists(readmissionIntervals)
        then Round(Sum(readmissionIntervals) / Count(readmissionIntervals), 1)
        else null
  return Tuple {
    average_days_to_readmission: avgDays,
    min_days_to_readmission: if exists(readmissionIntervals) then First(readmissionIntervals I sort ascending) else null,
    max_days_to_readmission: if exists(readmissionIntervals) then Last(readmissionIntervals I sort ascending) else null,
    day_0_readmissions: Count(readmissionIntervals I where I = 0),
    day_1_readmissions: Count(readmissionIntervals I where I = 1),
    day_2_readmissions: Count(readmissionIntervals I where I = 2),
    day_3_readmissions: Count(readmissionIntervals I where I = 3),
    day_4_7_readmissions: Count(readmissionIntervals I where I >= 4 and I <= 7),
    day_8_14_readmissions: Count(readmissionIntervals I where I >= 8 and I <= 14)
  }

// 年齡分布統計
define "Age Distribution Statistics":
  let qualifyingDischarges: "GetQualifyingCOPDDischargesInPeriod"("Measurement Period"),
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
    age_40_49: Count(ageDistribution A where A >= 40 and A < 50),
    age_50_59: Count(ageDistribution A where A >= 50 and A < 60),
    age_60_69: Count(ageDistribution A where A >= 60 and A < 70),
    age_70_79: Count(ageDistribution A where A >= 70 and A < 80),
    age_80_plus: Count(ageDistribution A where A >= 80)
  }

// 呼吸道用藥使用統計
define "Respiratory Medication Statistics":
  let qualifyingDischarges: "GetQualifyingCOPDDischargesInPeriod"("Measurement Period"),
      allMedications: flatten(
        qualifyingDischarges E
          return "All Medication Requests" M
            where M.encounter.reference = 'Encounter/' + E.id
              and "IsRespiratoryMedication"(M)
      )
  return Tuple {
    total_respiratory_medications: Count(allMedications),
    full_code_medications: Count(
      allMedications M
        where "IsRespiratoryMedicationFullCode"(M)
    ),
    prefix_code_medications: Count(
      allMedications M
        where "IsRespiratoryMedicationPrefix"(M)
          and not "IsRespiratoryMedicationFullCode"(M)
    ),
    patients_with_medications: Count(qualifyingDischarges)
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
    indicator_name: '肺阻塞出院後十四日內因肺阻塞再住院率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測COPD患者出院後病情控制和照護品質，評估急性惡化預防措施的有效性',
    
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
    
    // COPD出院統計
    copd_discharge_statistics: "COPD Discharge Statistics",
    
    // COPD再住院統計
    copd_readmission_statistics: "COPD Readmission Statistics",
    
    // 再住院時間統計
    readmission_timing_statistics: "Readmission Timing Statistics",
    
    // 年齡分布統計
    age_distribution_statistics: "Age Distribution Statistics",
    
    // 呼吸道用藥統計
    respiratory_medication_statistics: "Respiratory Medication Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
