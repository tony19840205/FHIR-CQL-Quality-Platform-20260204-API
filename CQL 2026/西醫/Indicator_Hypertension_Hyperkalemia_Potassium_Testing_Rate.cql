library Indicator_Hypertension_Hyperkalemia_Potassium_Testing_Rate version '1.0.0'

/*
具高鉀血症病史之高血壓病人服用會使血鉀濃度升高之降血壓藥者有執行血鉀檢查之比率
Potassium Testing Rate for Hypertensive Patients with Hyperkalemia History on Potassium-Elevating Medications

計算說明:
- 分子：分母案件中有追蹤血鉀數值(執行血鉀檢查09022C)的人數
- 分母：有高血壓診斷且有高血壓用藥病患勻檢病史嫌，有高鉀血症病史，且有使用Potassium-sparing diuretics(保鉀型利尿劑)或Aldosterone Antagonist(醛固酮拮抗劑)的人數
- 資料範圍：醫院門診資料
- 計算頻率：季

備註:
1. 高血壓診斷：ICD-10-CM碼 I10-I15
2. 高鉀血症病史：ICD-10-CM碼 E87.5 (Hyperkalemia)
3. Potassium-sparing diuretics (保鉀型利尿劑)：
   - ATC C03DA (Potassium-sparing agents)
   - ATC C03DB (Potassium-sparing agents with other diuretics)
4. Aldosterone Antagonist (醛固酮拮抗劑)：
   - Spironolactone (ATC C03DA01)
   - Eplerenone (ATC C03DA04)
5. 血鉀檢查：檢驗碼 09022C
6. 計算公式：(分子/分母) x 100%
7. 臨床意義：監測使用保鉀藥物的高鉀血症高危險群患者是否有適當的血鉀監測，預防高鉀血症併發症
8. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-06)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 季度期間定義
parameter "Quarterly Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0],
    Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0],
    Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0],
    Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
  }

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "LOINC": 'http://loinc.org'

// 高血壓診斷codes (ICD-10-CM I10-I15)
code "I10": 'I10' from "ICD10CM" display 'Essential (primary) hypertension'
code "I11": 'I11' from "ICD10CM" display 'Hypertensive heart disease'
code "I12": 'I12' from "ICD10CM" display 'Hypertensive chronic kidney disease'
code "I13": 'I13' from "ICD10CM" display 'Hypertensive heart and chronic kidney disease'
code "I15": 'I15' from "ICD10CM" display 'Secondary hypertension'

// 高鉀血症診斷code
code "E87.5": 'E87.5' from "ICD10CM" display 'Hyperkalemia - 高鉀血症'

// 保鉀型利尿劑 ATC codes
code "C03DA": 'C03DA' from "ATC" display 'Potassium-sparing agents'
code "C03DA01": 'C03DA01' from "ATC" display 'Spironolactone'
code "C03DA04": 'C03DA04' from "ATC" display 'Eplerenone'
code "C03DB": 'C03DB' from "ATC" display 'Potassium-sparing agents with other diuretics'

// 血鉀檢查code
code "09022C": '09022C' from "TWProcedure" display '血鉀檢查'

// LOINC 血鉀檢查codes
code "2823-3": '2823-3' from "LOINC" display 'Potassium [Moles/volume] in Serum or Plasma'
code "6298-4": '6298-4' from "LOINC" display 'Potassium [Moles/volume] in Blood'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// Encounter類型編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// 所有Observation (檢驗結果)
define "All Observations":
  [Observation] O

// 所有Procedure
define "All Procedures":
  [Procedure] P

// ===== 高血壓診斷判斷 =====

// 判斷Condition是否為高血壓診斷（ICD-10-CM I10-I15）
define function "IsHypertensionDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          StartsWith(C.code, 'I10')
          or StartsWith(C.code, 'I11')
          or StartsWith(C.code, 'I12')
          or StartsWith(C.code, 'I13')
          or StartsWith(C.code, 'I15')
        )
  )

// 判斷Patient是否有高血壓診斷
define "Has Hypertension Diagnosis":
  exists(
    "All Conditions" C
      where "IsHypertensionDiagnosis"(C)
  )

// ===== 高鉀血症病史判斷 =====

// 判斷Condition是否為高鉀血症診斷（ICD-10-CM E87.5）
define function "IsHyperkalemiaDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and StartsWith(C.code, 'E87.5')
  )

// 判斷Patient是否有高鉀血症病史
define "Has Hyperkalemia History":
  exists(
    "All Conditions" C
      where "IsHyperkalemiaDiagnosis"(C)
  )

// ===== 保鉀型利尿劑/醛固酮拮抗劑判斷 =====

// 判斷MedicationRequest是否為保鉀型利尿劑或醛固酮拮抗劑
define function "IsPotassiumSparingDiuretic"(medication MedicationRequest):
  medication.status in { 'active', 'completed' }
    and exists(
      medication.medicationCodeableConcept.coding C
        where C.system = 'http://www.whocc.no/atc'
          and (
            StartsWith(C.code, 'C03DA')
            or StartsWith(C.code, 'C03DB')
            or C.code = 'C03DA01'  // Spironolactone
            or C.code = 'C03DA04'  // Eplerenone
          )
    )

// 取得期間內的保鉀型利尿劑/醛固酮拮抗劑用藥
define function "GetPotassiumSparingDiureticsInPeriod"(period Interval<DateTime>):
  "All Medication Requests" M
    where "IsPotassiumSparingDiuretic"(M)
      and (
        M.authoredOn during period
        or exists(
          M.dosageInstruction D
            where D.timing.repeat.bounds as Period overlaps period
        )
      )

// 判斷期間內是否有使用保鉀型利尿劑/醛固酮拮抗劑
define function "HasPotassiumSparingDiureticsInPeriod"(period Interval<DateTime>):
  exists("GetPotassiumSparingDiureticsInPeriod"(period))

// ===== 血鉀檢查判斷 =====

// 判斷Observation是否為血鉀檢查（LOINC）
define function "IsPotassiumObservation"(observation Observation):
  observation.status in { 'final', 'amended', 'corrected' }
    and exists(
      observation.code.coding C
        where C.system = 'http://loinc.org'
          and (
            C.code = '2823-3'  // Potassium in Serum/Plasma
            or C.code = '6298-4'  // Potassium in Blood
          )
    )

// 判斷Procedure是否為血鉀檢查（台灣檢驗碼09022C）
define function "IsPotassiumProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and C.code = '09022C'
    )

// 取得期間內的血鉀檢查（Observation）
define function "GetPotassiumObservationsInPeriod"(period Interval<DateTime>):
  "All Observations" O
    where "IsPotassiumObservation"(O)
      and O.effective as dateTime during period

// 取得期間內的血鉀檢查（Procedure）
define function "GetPotassiumProceduresInPeriod"(period Interval<DateTime>):
  "All Procedures" P
    where "IsPotassiumProcedure"(P)
      and P.performed as dateTime during period

// 判斷期間內是否有執行血鉀檢查
define function "HasPotassiumTestingInPeriod"(period Interval<DateTime>):
  exists("GetPotassiumObservationsInPeriod"(period))
    or exists("GetPotassiumProceduresInPeriod"(period))

// ===== 分母定義（依期間）=====

// 判斷Patient是否符合分母條件（在特定期間內）
define function "MeetsDenominatorCriteriaInPeriod"(period Interval<DateTime>):
  "Has Hypertension Diagnosis"
    and "Has Hyperkalemia History"
    and "HasPotassiumSparingDiureticsInPeriod"(period)

// 分母（季度）
define "Denominator Quarterly":
  "Quarterly Periods" P
    return if "MeetsDenominatorCriteriaInPeriod"(P) then 1 else 0

// 分母（全年）
define "Denominator":
  if "MeetsDenominatorCriteriaInPeriod"("Measurement Period") then 1 else 0

// ===== 分子定義（依期間）=====

// 判斷Patient是否符合分子條件（在特定期間內）
define function "MeetsNumeratorCriteriaInPeriod"(period Interval<DateTime>):
  "MeetsDenominatorCriteriaInPeriod"(period)
    and "HasPotassiumTestingInPeriod"(period)

// 分子（季度）
define "Numerator Quarterly":
  "Quarterly Periods" P
    return if "MeetsNumeratorCriteriaInPeriod"(P) then 1 else 0

// 分子（全年）
define "Numerator":
  if "MeetsNumeratorCriteriaInPeriod"("Measurement Period") then 1 else 0

// ===== 指標計算 =====

// 整體指標（全年）
define "Indicator Rate":
  if "Denominator" > 0
    then Round("Numerator" / "Denominator" * 100, 2)
    else null

// 季度指標
define "Indicator Rate Quarterly":
  "Quarterly Periods" P
    let denom: if "MeetsDenominatorCriteriaInPeriod"(P) then 1 else 0,
        numer: if "MeetsNumeratorCriteriaInPeriod"(P) then 1 else 0
    return
      if denom > 0
        then Round(numer / denom * 100, 2)
        else null

// ===== 品質檢核 =====

// 資料完整性檢查（全年）
define "Data Quality Check":
  Tuple {
    has_hypertension_diagnosis: "Has Hypertension Diagnosis",
    has_hyperkalemia_history: "Has Hyperkalemia History",
    has_potassium_sparing_diuretics: "HasPotassiumSparingDiureticsInPeriod"("Measurement Period"),
    has_potassium_testing: "HasPotassiumTestingInPeriod"("Measurement Period"),
    meets_denominator_criteria: "MeetsDenominatorCriteriaInPeriod"("Measurement Period"),
    meets_numerator_criteria: "MeetsNumeratorCriteriaInPeriod"("Measurement Period")
  }

// 診斷統計
define "Diagnosis Statistics":
  let hypertensionConditions: "All Conditions" C where "IsHypertensionDiagnosis"(C),
      hyperkalemiaConditions: "All Conditions" C where "IsHyperkalemiaDiagnosis"(C)
  return Tuple {
    total_hypertension_diagnoses: Count(hypertensionConditions),
    hypertension_diagnosis_codes: distinct (
      hypertensionConditions C
        return C.code.coding[0].code
    ),
    total_hyperkalemia_diagnoses: Count(hyperkalemiaConditions),
    hyperkalemia_diagnosis_codes: distinct (
      hyperkalemiaConditions C
        return C.code.coding[0].code
    )
  }

// 用藥統計
define "Medication Statistics":
  let potassiumSparingMeds: "GetPotassiumSparingDiureticsInPeriod"("Measurement Period")
  return Tuple {
    total_potassium_sparing_medications: Count(potassiumSparingMeds),
    medication_atc_codes: distinct (
      potassiumSparingMeds M
        return M.medicationCodeableConcept.coding[0].code
    ),
    spironolactone_count: Count(
      potassiumSparingMeds M
        where exists(
          M.medicationCodeableConcept.coding C
            where C.code = 'C03DA01'
        )
    ),
    eplerenone_count: Count(
      potassiumSparingMeds M
        where exists(
          M.medicationCodeableConcept.coding C
            where C.code = 'C03DA04'
        )
    ),
    other_potassium_sparing_count: Count(
      potassiumSparingMeds M
        where exists(
          M.medicationCodeableConcept.coding C
            where StartsWith(C.code, 'C03DA')
              and C.code != 'C03DA01'
              and C.code != 'C03DA04'
        )
    )
  }

// 血鉀檢查統計
define "Potassium Testing Statistics":
  let potassiumObservations: "GetPotassiumObservationsInPeriod"("Measurement Period"),
      potassiumProcedures: "GetPotassiumProceduresInPeriod"("Measurement Period"),
      allPotassiumTests: potassiumObservations union potassiumProcedures
  return Tuple {
    total_potassium_tests: Count(allPotassiumTests),
    observation_based_tests: Count(potassiumObservations),
    procedure_based_tests: Count(potassiumProcedures),
    test_dates: allPotassiumTests T
      return Tuple {
        test_date: ToString(
          Coalesce(
            T.effective as dateTime,
            T.performed as dateTime
          )
        ),
        test_type: if T is Observation then 'Observation' else 'Procedure'
      }
  }

// 季度統計
define "Quarterly Statistics":
  "Quarterly Periods" P
    return Tuple {
      quarter_period: ToString(P),
      has_potassium_sparing_diuretics: "HasPotassiumSparingDiureticsInPeriod"(P),
      has_potassium_testing: "HasPotassiumTestingInPeriod"(P),
      meets_denominator: "MeetsDenominatorCriteriaInPeriod"(P),
      meets_numerator: "MeetsNumeratorCriteriaInPeriod"(P),
      potassium_test_count: Count(
        "GetPotassiumObservationsInPeriod"(P)
          union "GetPotassiumProceduresInPeriod"(P)
      )
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
    indicator_name: '具高鉀血症病史之高血壓病人服用會使血鉀濃度升高之降血壓藥者有執行血鉀檢查之比率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測使用保鉀藥物的高鉀血症高危險群患者是否有適當的血鉀監測，預防高鉀血症併發症',
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    
    // 季度指標
    quarterly_numerators: "Numerator Quarterly",
    quarterly_denominators: "Denominator Quarterly",
    quarterly_rates: "Indicator Rate Quarterly",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // 診斷統計
    diagnosis_statistics: "Diagnosis Statistics",
    
    // 用藥統計
    medication_statistics: "Medication Statistics",
    
    // 血鉀檢查統計
    potassium_testing_statistics: "Potassium Testing Statistics",
    
    // 季度統計
    quarterly_statistics: "Quarterly Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
