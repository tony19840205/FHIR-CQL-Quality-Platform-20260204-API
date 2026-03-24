library Indicator_Pneumonia_3Day_Readmission_Age_18_64 version '1.0.0'

/*
肺炎出院後三日內因肺炎再住院率-18歲至64歲
Pneumonia 3-Day Readmission Rate (Age 18-64)

計算說明:
- 分子：出院後3天(含)內因主診斷肺炎再住院之人次數
- 分母：18歲至64歲住院主診斷肺炎且出院的人次數
- 資料範圍：醫院住院資料
- 計算頻率：月、季、年

備註:
1. 肺炎：ICD-10-CM前三碼為J12、J13、J14、J15、J16、J17、J18
2. 再住院：以分母出院案件為基礎，勾稽距出院日0至3日內之住院案件(含急診轉住院案件)
3. 18歲(含)以上至65歲(不含)：780 > 住院年月-出生年月 ≥ 216
4. 排除重大傷病及死亡
5. 排除1年內分母小於30例醫院之醫院
6. 臨床意義：監測肺炎患者出院後3天內再住院情況，評估出院準備、病情穩定度和照護連續性
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
parameter "Minimum Age Months" Integer default 216  // 18歲 = 216個月
parameter "Maximum Age Months" Integer default 780  // 65歲 = 780個月

// 再住院監測期間（3天，含出院當日）
parameter "Readmission Monitoring Days" Integer default 3

// 醫院最小案例數門檻
parameter "Minimum Hospital Cases" Integer default 30

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
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

// 取得Encounter的主診斷
define function "GetPrincipalDiagnosis"(encounter Encounter):
  singleton from (
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and exists(
          C.category Cat
            where exists(
              Cat.coding CC
                where CC.code = 'encounter-diagnosis'
            )
        )
        and (
          C.verificationStatus.coding[0].code = 'confirmed'
          or C.verificationStatus is null
        )
        // 假設rank=1代表主診斷，或使用其他方式識別主診斷
    sort by (
      if C.id is not null then 0 else 1
    )
  )

// 判斷Encounter的主診斷是否為肺炎
define function "HasPneumoniaPrincipalDiagnosis"(encounter Encounter):
  let principalDx: "GetPrincipalDiagnosis"(encounter)
  return
    principalDx is not null
      and "IsPneumoniaDiagnosis"(principalDx)

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

// 判斷年齡是否在18-64歲之間（216 ≤ 月數 < 780）
define function "IsAgeInRange"(admissionDate DateTime):
  let ageMonths: "GetAgeInMonthsAtAdmission"(admissionDate)
  return
    ageMonths >= "Minimum Age Months"
      and ageMonths < "Maximum Age Months"

// ===== 排除條件判斷 =====

// 判斷是否有重大傷病
define function "HasCatastrophicIllness"(encounter Encounter):
  // 假設透過Coverage或Condition的特定標記判斷重大傷病
  exists(
    [Coverage] Cov
      where Cov.beneficiary.reference = 'Patient/' + Patient.id
        and exists(
          Cov.type.coding C
            where C.code = 'catastrophic-illness'
        )
  )

// 判斷Encounter是否以死亡結束
define function "IsDischargeDeath"(encounter Encounter):
  encounter.hospitalization.dischargeDisposition.coding[0].code = 'expired'
    or encounter.hospitalization.dischargeDisposition.coding[0].display = 'Expired'

// 判斷是否應排除（重大傷病或死亡）
define function "ShouldExclude"(encounter Encounter):
  "HasCatastrophicIllness"(encounter)
    or "IsDischargeDeath"(encounter)

// ===== 再住院判斷 =====

// 計算3天再住院監測期間（含出院當日，0-3天）
define function "Get3DayReadmissionPeriod"(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Readmission Monitoring Days" days]

// 取得3天內的再住院Encounter（含急診轉住院）
define function "GetReadmissionsWithin3Days"(dischargeDate DateTime):
  let readmissionPeriod: "Get3DayReadmissionPeriod"(dischargeDate)
  return
    ("All Inpatient Encounters" union "All ED Encounters") E
      where "GetAdmissionDate"(E) during readmissionPeriod

// 判斷3天內是否有肺炎再住院
define function "HasPneumoniaReadmissionWithin3Days"(dischargeDate DateTime):
  exists(
    "GetReadmissionsWithin3Days"(dischargeDate) E
      where "HasPneumoniaPrincipalDiagnosis"(E)
  )

// ===== 分母定義（依期間）=====

// 取得期間內符合條件的肺炎出院案件
define function "GetQualifyingPneumoniaDischargesInPeriod"(period Interval<DateTime>):
  "All Inpatient Encounters" E
    let dischargeDate: "GetDischargeDate"(E),
        admissionDate: "GetAdmissionDate"(E)
    where dischargeDate during period
      and "HasPneumoniaPrincipalDiagnosis"(E)
      and "IsAgeInRange"(admissionDate)
      and not "ShouldExclude"(E)

// 計算分母（針對特定期間）
define function "GetDenominatorCountInPeriod"(period Interval<DateTime>):
  Count("GetQualifyingPneumoniaDischargesInPeriod"(period))

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

// 取得期間內有3天內肺炎再住院的案件
define function "GetPneumoniaReadmissionsInPeriod"(period Interval<DateTime>):
  "GetQualifyingPneumoniaDischargesInPeriod"(period) E
    where "HasPneumoniaReadmissionWithin3Days"("GetDischargeDate"(E))

// 計算分子（針對特定期間）
define function "GetNumeratorCountInPeriod"(period Interval<DateTime>):
  Count("GetPneumoniaReadmissionsInPeriod"(period))

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
  let qualifyingDischarges: "GetQualifyingPneumoniaDischargesInPeriod"("Measurement Period"),
      allPneumoniaDischarges: "All Inpatient Encounters" E
        where "GetDischargeDate"(E) during "Measurement Period"
          and "HasPneumoniaPrincipalDiagnosis"(E)
  return Tuple {
    total_inpatient_encounters: Count("All Inpatient Encounters" E where "GetDischargeDate"(E) during "Measurement Period"),
    total_pneumonia_discharges: Count(allPneumoniaDischarges),
    age_excluded: Count(
      allPneumoniaDischarges E
        where not "IsAgeInRange"("GetAdmissionDate"(E))
    ),
    catastrophic_illness_excluded: Count(
      allPneumoniaDischarges E
        where "HasCatastrophicIllness"(E)
    ),
    death_excluded: Count(
      allPneumoniaDischarges E
        where "IsDischargeDeath"(E)
    ),
    qualifying_pneumonia_discharges: Count(qualifyingDischarges),
    pneumonia_readmissions_within_3days: "Numerator",
    meets_minimum_cases: "Denominator" >= "Minimum Hospital Cases"
  }

// 肺炎出院統計
define "Pneumonia Discharge Statistics":
  let qualifyingDischarges: "GetQualifyingPneumoniaDischargesInPeriod"("Measurement Period"),
      dischargeDates: qualifyingDischarges E return "GetDischargeDate"(E)
  return Tuple {
    total_qualifying_discharges: Count(qualifyingDischarges),
    first_discharge_date: if exists(dischargeDates) then ToString(First(dischargeDates D sort ascending)) else null,
    last_discharge_date: if exists(dischargeDates) then ToString(Last(dischargeDates D sort ascending)) else null
  }

// 再住院統計
define "Readmission Statistics":
  let readmissions: "GetPneumoniaReadmissionsInPeriod"("Measurement Period")
  return Tuple {
    total_readmissions: Count(readmissions),
    readmission_rate_percent: "Indicator Rate",
    readmission_encounters: readmissions E
      return Tuple {
        discharge_date: ToString("GetDischargeDate"(E)),
        readmission_dates: "GetReadmissionsWithin3Days"("GetDischargeDate"(E)) R
          return ToString("GetAdmissionDate"(R))
      }
  }

// 再住院時間統計
define "Readmission Timing Statistics":
  let readmissions: "GetPneumoniaReadmissionsInPeriod"("Measurement Period"),
      readmissionIntervals: readmissions E
        let dischargeDate: "GetDischargeDate"(E),
            readmissionEncounters: "GetReadmissionsWithin3Days"(dischargeDate) R
              where "HasPneumoniaPrincipalDiagnosis"(R),
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
    day_3_readmissions: Count(readmissionIntervals I where I = 3)
  }

// 年齡分布統計
define "Age Distribution Statistics":
  let qualifyingDischarges: "GetQualifyingPneumoniaDischargesInPeriod"("Measurement Period"),
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
    age_18_24: Count(ageDistribution A where A >= 18 and A < 25),
    age_25_34: Count(ageDistribution A where A >= 25 and A < 35),
    age_35_44: Count(ageDistribution A where A >= 35 and A < 45),
    age_45_54: Count(ageDistribution A where A >= 45 and A < 55),
    age_55_64: Count(ageDistribution A where A >= 55 and A < 65)
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
    indicator_name: '肺炎出院後三日內因肺炎再住院率-18歲至64歲',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測肺炎患者(18-64歲)出院後3天內再住院情況，評估出院準備、病情穩定度和照護連續性',
    age_range: '18-64歲',
    
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
    
    // 肺炎出院統計
    pneumonia_discharge_statistics: "Pneumonia Discharge Statistics",
    
    // 再住院統計
    readmission_statistics: "Readmission Statistics",
    
    // 再住院時間統計
    readmission_timing_statistics: "Readmission Timing Statistics",
    
    // 年齡分布統計
    age_distribution_statistics: "Age Distribution Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
