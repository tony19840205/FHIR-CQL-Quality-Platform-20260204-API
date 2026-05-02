library Indicator_PC_07_Diabetes_HbA1c_Glycated_Albumin_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標編號: 3691
// 指標名稱: 西醫基層門診糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)執行率
// 分母: 統計累計自當年度1月起至統計當期，門診主次診斷為糖尿病(ICD-10-CM前3碼 E08-E13)
//       且使用糖尿病用藥(ATC前3碼 A10)之病人數（診斷與用藥須同一處方案件）
// 分子: 分母中在統計期間於門診有執行HbA1c(醫令前5碼09006)或糖化白蛋白(醫令前5碼09139)之人數
// 排除: 代辦案件
// 統計範圍: 2024Q1 ~ 2026Q1 (9個季度，分母累計自當年1月起)

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// ============================================
// Helper Functions
// ============================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetExtBoolean(E FHIR.Encounter, extUrl String):
  exists(
    E.extension Ext
      where Ext.url.value = extUrl
        and (Ext.value as FHIR.boolean).value = true
  )

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

define function IsDiabetesCode(code String):
  Substring(code, 0, 3) in {'E08', 'E09', 'E10', 'E11', 'E12', 'E13'}

define function IsDiabetesMedication(atcCode String):
  Substring(atcCode, 0, 3) = 'A10'

define function GetEncounterDate(E FHIR.Encounter):
  date from start of E.period

define function YearStart(quarterEnd Date):
  Date(year from quarterEnd, 1, 1)

// ============================================
// Base Resources
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and not IsAgencyCase(E)

define function HasDiabetesDiagnosis(E FHIR.Encounter):
  exists(
    [Condition] C
      where C.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          C.code.coding Co
            where Co.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
              and IsDiabetesCode(Co.code.value)
        )
  )

define "All Diabetes Medication Requests":
  [MedicationRequest] MR
    where MR.status.value in {'active', 'completed'}
      and IsDiabetesMedication(
        First((MR.medication as FHIR.CodeableConcept).coding).code.value
      )

define function HasDiabetesMedicationInEncounter(E FHIR.Encounter):
  exists(
    "All Diabetes Medication Requests" MR
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
  )

// HbA1c: LOINC 4548-4、17856-6、59261-8、62388-4 或 NHI 醫令前5碼 09006
// 糖化白蛋白: NHI 醫令前5碼 09139
define "HbA1c Or Glycated Albumin Observations":
  [Observation] O
    where O.status.value in {'final', 'amended', 'corrected'}
      and (
        exists(
          O.code.coding C
            where C.code.value in {'4548-4', '17856-6', '59261-8', '62388-4'}
        )
        or exists(
          O.code.coding C
            where Substring(C.code.value, 0, 5) in {'09006', '09139'}
        )
      )

// ============================================
// Denominator & Numerator Functions
// 分母: 從當年1月累計至 quarterEnd，有糖尿病診斷+用藥同一就診之病人
// 分子: 分母病人中於 testStart~testEnd 有執行HbA1c/糖化白蛋白
// ============================================

define function HasDiabetesEncounterInCumulativePeriod(quarterEnd Date):
  exists(
    "Outpatient Encounters" E
      where HasDiabetesDiagnosis(E)
        and HasDiabetesMedicationInEncounter(E)
        and GetEncounterDate(E) in Interval[YearStart(quarterEnd), quarterEnd]
  )

define function DenominatorInPeriod(quarterEnd Date):
  if HasDiabetesEncounterInCumulativePeriod(quarterEnd) then 1 else 0

define function HasTestInPeriod(testStart Date, testEnd Date):
  exists(
    "HbA1c Or Glycated Albumin Observations" O
      where date from (O.effective as FHIR.dateTime).value in Interval[testStart, testEnd]
  )

define function NumeratorInPeriod(quarterEnd Date, testStart Date, testEnd Date):
  if DenominatorInPeriod(quarterEnd) > 0 and HasTestInPeriod(testStart, testEnd) then 1 else 0

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1, 9 quarters)
// 分母: 累計從年初到季末; 分子: 統計當季內執行檢驗
// ============================================

define "2024Q1 Denominator": DenominatorInPeriod(@2024-03-31)
define "2024Q1 Numerator": NumeratorInPeriod(@2024-03-31, @2024-01-01, @2024-03-31)
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": DenominatorInPeriod(@2024-06-30)
define "2024Q2 Numerator": NumeratorInPeriod(@2024-06-30, @2024-04-01, @2024-06-30)
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": DenominatorInPeriod(@2024-09-30)
define "2024Q3 Numerator": NumeratorInPeriod(@2024-09-30, @2024-07-01, @2024-09-30)
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": DenominatorInPeriod(@2024-12-31)
define "2024Q4 Numerator": NumeratorInPeriod(@2024-12-31, @2024-10-01, @2024-12-31)
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": DenominatorInPeriod(@2025-03-31)
define "2025Q1 Numerator": NumeratorInPeriod(@2025-03-31, @2025-01-01, @2025-03-31)
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": DenominatorInPeriod(@2025-06-30)
define "2025Q2 Numerator": NumeratorInPeriod(@2025-06-30, @2025-04-01, @2025-06-30)
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": DenominatorInPeriod(@2025-09-30)
define "2025Q3 Numerator": NumeratorInPeriod(@2025-09-30, @2025-07-01, @2025-09-30)
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": DenominatorInPeriod(@2025-12-31)
define "2025Q4 Numerator": NumeratorInPeriod(@2025-12-31, @2025-10-01, @2025-12-31)
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": DenominatorInPeriod(@2026-03-31)
define "2026Q1 Numerator": NumeratorInPeriod(@2026-03-31, @2026-01-01, @2026-03-31)
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Summary
// ============================================

define "Total Denominator": "2026Q1 Denominator"
define "Total Numerator": "2026Q1 Numerator"
define "Overall Rate": "2026Q1 Rate"

define "Indicator Result":
  Tuple {
    indicatorCode: '3691',
    indicatorName: '西醫基層門診糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)執行率',
    diabetesCriteria: 'ICD-10-CM E08-E13',
    medicationCriteria: 'ATC A10',
    testCriteria: 'NHI醫令前5碼 09006(HbA1c), 09139(糖化白蛋白)',
    keyRequirement: '診斷與用藥須同一處方案件；分母累計自當年1月起',
    quarters: List{
      Tuple { quarter: '2024Q1', numerator: "2024Q1 Numerator", denominator: "2024Q1 Denominator", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', numerator: "2024Q2 Numerator", denominator: "2024Q2 Denominator", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', numerator: "2024Q3 Numerator", denominator: "2024Q3 Denominator", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', numerator: "2024Q4 Numerator", denominator: "2024Q4 Denominator", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', numerator: "2025Q1 Numerator", denominator: "2025Q1 Denominator", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', numerator: "2025Q2 Numerator", denominator: "2025Q2 Denominator", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', numerator: "2025Q3 Numerator", denominator: "2025Q3 Denominator", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', numerator: "2025Q4 Numerator", denominator: "2025Q4 Denominator", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', numerator: "2026Q1 Numerator", denominator: "2026Q1 Denominator", rate: "2026Q1 Rate" }
    }
  }
