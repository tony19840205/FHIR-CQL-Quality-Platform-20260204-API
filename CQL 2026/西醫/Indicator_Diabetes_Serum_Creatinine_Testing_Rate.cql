library Indicator_Diabetes_Serum_Creatinine_Testing_Rate version '1.0.0'

/*
糖尿病病人血清肌酸酐檢查執行率
Diabetes Patients Serum Creatinine Testing Rate

計算說明:
- 分子：分母ID中，在統計期間有執行血清肌酸酐檢查的病人ID歸戶人數
- 分母：門診主次診斷為糖尿病且使用糖尿病用藥的病人數
- 資料範圍：門診資料
- 計算頻率：每半年

備註:
1. 糖尿病：任一主、次診斷之ICD-10-CM前三碼為E08-E13之門診案件
2. 糖尿病用藥：指ATC前三碼為A10
3. 血清肌酸酐檢查：LOINC代碼 2160-0 (Creatinine [Mass/volume] in Serum or Plasma)
4. 計算符合分母條件之ID時，主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件
5. 統計期間：計算符合分子之ID時，從分母的ID繼續觀察，只要該ID於統計期間有執行血清肌酸酐檢驗即成立
6. 臨床意義：監測糖尿病患者腎功能，早期發現糖尿病腎病變
7. 計算範圍：2026年(115年)資料

FHIR Resource對照:
- Patient: 病患基本資料
- Encounter: 就醫紀錄 (門診)
- Condition: 診斷資料 (主次診斷，糖尿病E08-E13)
- MedicationRequest: 藥品處方 (糖尿病用藥A10)
- Observation: 檢驗數據 (血清肌酸酐)

Version History:
- 1.0.0: Initial implementation (2026-01-07)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 半年度期間定義
parameter "Semiannual Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-06-30T23:59:59.0],  // 上半年
    Interval[@2026-07-01T00:00:00.0, @2026-12-31T23:59:59.0]   // 下半年
  }

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 糖尿病診斷碼範圍（E08-E13）
code "E08": 'E08' from "ICD10CM" display 'Diabetes mellitus due to underlying condition'
code "E09": 'E09' from "ICD10CM" display 'Drug or chemical induced diabetes mellitus'
code "E10": 'E10' from "ICD10CM" display 'Type 1 diabetes mellitus'
code "E11": 'E11' from "ICD10CM" display 'Type 2 diabetes mellitus'
code "E13": 'E13' from "ICD10CM" display 'Other specified diabetes mellitus'

// 糖尿病用藥ATC代碼（A10）
code "A10": 'A10' from "ATC" display 'Drugs used in diabetes'

// 血清肌酸酐檢查LOINC代碼
code "2160-0": '2160-0' from "LOINC" display 'Creatinine [Mass/volume] in Serum or Plasma'
code "38483-4": '38483-4' from "LOINC" display 'Creatinine [Mass/volume] in Blood'
code "14682-9": '14682-9' from "LOINC" display 'Creatinine [Moles/volume] in Serum or Plasma'

// 資料來源定義
context Patient

// ===== 糖尿病診斷碼前綴列表 =====

define "Diabetes ICD10 Prefixes":
  { 'E08', 'E09', 'E10', 'E11', 'E13' }

// ===== 基礎資料定義 =====

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 門診Encounter編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] MR

// 所有Observation
define "All Observations":
  [Observation] O

// ===== 輔助函數 =====

// 判斷Condition是否為糖尿病診斷（E08-E13前三碼）
define function "IsDiabetesDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and Substring(C.code, 0, 3) in "Diabetes ICD10 Prefixes"
  )

// 判斷MedicationRequest是否為糖尿病用藥（ATC前三碼為A10）
define function "IsDiabetesMedication"(medication MedicationRequest):
  exists(
    medication.medication.coding C
      where C.system = 'http://www.whocc.no/atc'
        and StartsWith(C.code, 'A10')
  )

// 判斷Observation是否為血清肌酸酐檢查
define function "IsSerumCreatinineTest"(observation Observation):
  exists(
    observation.code.coding C
      where C.system = 'http://loinc.org'
        and (
          C.code = '2160-0' or    // Creatinine [Mass/volume] in Serum or Plasma
          C.code = '38483-4' or   // Creatinine [Mass/volume] in Blood
          C.code = '14682-9'      // Creatinine [Moles/volume] in Serum or Plasma
        )
  )

// 取得Encounter的所有診斷
define function "GetEncounterDiagnoses"(encounter Encounter):
  "All Conditions" C
    where C.encounter.reference = 'Encounter/' + encounter.id

// 取得Encounter的所有藥品處方
define function "GetEncounterMedications"(encounter Encounter):
  "All Medication Requests" MR
    where MR.encounter.reference = 'Encounter/' + encounter.id
      and MR.status = 'active'

// 取得Patient的所有檢驗
define function "GetPatientObservations"(patientId String):
  "All Observations" O
    where O.subject.reference = 'Patient/' + patientId
      and O.status = 'final'

// 取得Encounter日期
define function "GetEncounterDate"(encounter Encounter):
  start of encounter.period

// ===== 分母：門診主次診斷為糖尿病且使用糖尿病用藥的病人數 =====

// 步驟1：找出同一Encounter中有糖尿病診斷且有糖尿病用藥的案件
define "Diabetes Encounters With Medication":
  "All Outpatient Encounters" E
    let 
      encounterDiagnoses: "GetEncounterDiagnoses"(E),
      encounterMedications: "GetEncounterMedications"(E)
    where 
      // 有糖尿病診斷（主次診斷）
      exists(
        encounterDiagnoses D
          where "IsDiabetesDiagnosis"(D)
      )
      // 且有糖尿病用藥
      and exists(
        encounterMedications M
          where "IsDiabetesMedication"(M)
      )

// 步驟2：按Patient ID歸戶
define "Diabetes Patients":
  distinct(
    "Diabetes Encounters With Medication" E
      return Patient.id
  )

// 分母：糖尿病病人數
define "Denominator":
  "Diabetes Patients"

define "Denominator Count":
  Count("Denominator")

// ===== 分子：有執行血清肌酸酐檢查的病人 =====

// 步驟1：對每個分母病人，找出是否有血清肌酸酐檢查
define "Patients With Creatinine Test":
  "Denominator" PatientId
    let 
      patientObservations: "GetPatientObservations"(PatientId),
      creatinineTests:
        patientObservations O
          where "IsSerumCreatinineTest"(O)
            and start of O.effective during "Measurement Period"
    where exists(creatinineTests)
    return PatientId

// 分子：有執行血清肌酸酐檢查的病人數
define "Numerator":
  "Patients With Creatinine Test"

define "Numerator Count":
  Count("Numerator")

// ===== 指標計算 =====

// 整體執行率
define "Overall Testing Rate":
  if "Denominator Count" > 0
  then Round(("Numerator Count" / "Denominator Count") * 100, 2)
  else null

// 半年度執行率
define "Semiannual Testing Rates":
  "Semiannual Periods" Period
    let 
      periodDenominator:
        "Diabetes Encounters With Medication" E
          where "GetEncounterDate"(E) during Period
          return Patient.id,
      distinctPeriodDenominator: distinct periodDenominator,
      periodNumerator:
        distinctPeriodDenominator PatientId
          let 
            patientObservations: "GetPatientObservations"(PatientId),
            creatinineTests:
              patientObservations O
                where "IsSerumCreatinineTest"(O)
                  and start of O.effective during Period
          where exists(creatinineTests)
          return PatientId,
      denominatorCount: Count(distinctPeriodDenominator),
      numeratorCount: Count(periodNumerator),
      rate: if denominatorCount > 0 
            then Round((numeratorCount / denominatorCount) * 100, 2)
            else null
    return {
      period: Period,
      period_start: start of Period,
      period_end: end of Period,
      period_label: 
        if start of Period < @2026-07-01 
        then '2026上半年' 
        else '2026下半年',
      denominator_count: denominatorCount,
      numerator_count: numeratorCount,
      testing_rate: rate
    }

// ===== 詳細統計資訊 =====

// 未執行檢查的病人清單
define "Patients Without Creatinine Test":
  "Denominator" PatientId
    let 
      patientObservations: "GetPatientObservations"(PatientId),
      creatinineTests:
        patientObservations O
          where "IsSerumCreatinineTest"(O)
            and start of O.effective during "Measurement Period"
    where not exists(creatinineTests)
    return {
      patient_id: PatientId
    }

define "Patients Without Test Count":
  Count("Patients Without Creatinine Test")

// 檢查次數分布
define "Test Frequency Distribution":
  "Numerator" PatientId
    let 
      patientObservations: "GetPatientObservations"(PatientId),
      creatinineTests:
        patientObservations O
          where "IsSerumCreatinineTest"(O)
            and start of O.effective during "Measurement Period",
      testCount: Count(creatinineTests)
    return {
      patient_id: PatientId,
      test_count: testCount
    }

// 平均檢查次數
define "Average Test Count":
  if Count("Test Frequency Distribution") > 0
  then Round(
    Avg("Test Frequency Distribution" D return D.test_count),
    2
  )
  else null

// 糖尿病診斷類型分布
define "Diabetes Type Distribution":
  flatten(
    "Diabetes Encounters With Medication" E
      let 
        encounterDiagnoses: "GetEncounterDiagnoses"(E)
      return 
        encounterDiagnoses D
          where "IsDiabetesDiagnosis"(D)
          return 
            D.code.coding C
              where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
              return {
                icd_code_prefix: Substring(C.code, 0, 3),
                description: C.display
              }
  )

define "Diabetes Type Counts":
  {
    E08_count: Count("Diabetes Type Distribution" D where D.icd_code_prefix = 'E08'),
    E09_count: Count("Diabetes Type Distribution" D where D.icd_code_prefix = 'E09'),
    E10_count: Count("Diabetes Type Distribution" D where D.icd_code_prefix = 'E10'),
    E11_count: Count("Diabetes Type Distribution" D where D.icd_code_prefix = 'E11'),
    E13_count: Count("Diabetes Type Distribution" D where D.icd_code_prefix = 'E13')
  }

// ===== 最終輸出報告 =====

define "Final Report":
  {
    indicator_code: 'DIABETES_SERUM_CREATININE_TEST',
    indicator_name: '糖尿病病人血清肌酸酐檢查執行率',
    measurement_period: "Measurement Period",
    clinical_note: '監測糖尿病患者腎功能檢查執行情況，早期發現糖尿病腎病變，預防腎功能惡化',
    overall_denominator: "Denominator Count",
    overall_numerator: "Numerator Count",
    overall_rate: "Overall Testing Rate",
    semiannual_rates: "Semiannual Testing Rates",
    patients_without_test_count: "Patients Without Test Count",
    average_test_count: "Average Test Count",
    diabetes_type_distribution: "Diabetes Type Counts",
    calculation_frequency: 'Semiannual',
    calculation_unit: '%',
    data_source: 'Outpatient Data',
    inclusion_criteria: '門診主次診斷為糖尿病(E08-E13)且使用糖尿病用藥(ATC:A10)',
    test_codes: 'LOINC: 2160-0, 38483-4, 14682-9',
    version: '1.0.0',
    last_updated: @2026-01-07
  }
