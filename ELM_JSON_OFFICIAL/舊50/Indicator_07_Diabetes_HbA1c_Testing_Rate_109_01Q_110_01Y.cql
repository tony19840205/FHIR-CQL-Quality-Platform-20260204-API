library Indicator_07_Diabetes_HbA1c_Testing_Rate_109_01Q_110_01Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白執行率
// 指標代碼: 109.01 (季度), 110.01 (年度)
// 糖尿病: ICD-10-CM E08-E13
// 糖尿病用藥: ATC A10
// HbA1c/Glycated Albumin: 09006, 09139

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "LOINC": 'http://loinc.org'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// ============================================
// Helper Functions
// ============================================

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

define function GetEncounterDate(E FHIR.Encounter):
  date from start of E.period

define function YearStart(quarterEnd Date):
  Date(year from quarterEnd, 1, 1)

define function ToDecimal(v Integer):
  v * 1.0

// ============================================
// Data Retrieval
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and not IsAgencyCase(E)

define "Diabetes Encounters":
  "Outpatient Encounters" E
    where HasDiabetesDiagnosis(E)

define "Diabetes Encounters With Medication":
  "Diabetes Encounters" E
    where HasDiabetesMedicationInEncounter(E)

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
            where C.code.value in {'09006', '09139'}
        )
      )

// ============================================
// Denominator & Numerator Functions
// ============================================

define function DiabetesPatientsInPeriod(periodStart Date, periodEnd Date):
  "Diabetes Encounters With Medication" E
    where GetEncounterDate(E) in Interval[YearStart(periodEnd), periodEnd]

define function HasDiabetesInPeriod(periodStart Date, periodEnd Date):
  exists(DiabetesPatientsInPeriod(periodStart, periodEnd))

define function HasTestInPeriod(periodStart Date, periodEnd Date):
  exists(
    "HbA1c Or Glycated Albumin Observations" O
      where date from (O.effective as FHIR.dateTime).value in Interval[periodStart, periodEnd]
  )

define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  if HasDiabetesInPeriod(periodStart, periodEnd) and HasTestInPeriod(periodStart, periodEnd) then 1 else 0

define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  if HasDiabetesInPeriod(periodStart, periodEnd) then 1 else 0

// ============================================
// Quarterly Date Ranges
// ============================================

define "2024Q1 Start": DateTime(2024, 1, 1, 0, 0, 0, 0)
define "2024Q1 End": DateTime(2024, 3, 31, 23, 59, 59, 999)
define "2024Q2 Start": DateTime(2024, 4, 1, 0, 0, 0, 0)
define "2024Q2 End": DateTime(2024, 6, 30, 23, 59, 59, 999)
define "2024Q3 Start": DateTime(2024, 7, 1, 0, 0, 0, 0)
define "2024Q3 End": DateTime(2024, 9, 30, 23, 59, 59, 999)
define "2024Q4 Start": DateTime(2024, 10, 1, 0, 0, 0, 0)
define "2024Q4 End": DateTime(2024, 12, 31, 23, 59, 59, 999)
define "2025Q1 Start": DateTime(2025, 1, 1, 0, 0, 0, 0)
define "2025Q1 End": DateTime(2025, 3, 31, 23, 59, 59, 999)
define "2025Q2 Start": DateTime(2025, 4, 1, 0, 0, 0, 0)
define "2025Q2 End": DateTime(2025, 6, 30, 23, 59, 59, 999)
define "2025Q3 Start": DateTime(2025, 7, 1, 0, 0, 0, 0)
define "2025Q3 End": DateTime(2025, 9, 30, 23, 59, 59, 999)
define "2025Q4 Start": DateTime(2025, 10, 1, 0, 0, 0, 0)
define "2025Q4 End": DateTime(2025, 12, 31, 23, 59, 59, 999)
define "2026Q1 Start": DateTime(2026, 1, 1, 0, 0, 0, 0)
define "2026Q1 End": DateTime(2026, 3, 31, 23, 59, 59, 999)

// ============================================
// Quarterly Statistics
// ============================================

define "2024Q1 Denominator": DenominatorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Numerator": NumeratorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": DenominatorInPeriod(@2024-01-01, @2024-06-30)
define "2024Q2 Numerator": NumeratorInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": DenominatorInPeriod(@2024-01-01, @2024-09-30)
define "2024Q3 Numerator": NumeratorInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": DenominatorInPeriod(@2024-01-01, @2024-12-31)
define "2024Q4 Numerator": NumeratorInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": DenominatorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Numerator": NumeratorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": DenominatorInPeriod(@2025-01-01, @2025-06-30)
define "2025Q2 Numerator": NumeratorInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": DenominatorInPeriod(@2025-01-01, @2025-09-30)
define "2025Q3 Numerator": NumeratorInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": DenominatorInPeriod(@2025-01-01, @2025-12-31)
define "2025Q4 Numerator": NumeratorInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": DenominatorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Numerator": NumeratorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCodeQuarterly: '109.01',
    indicatorCodeAnnual: '110.01',
    indicatorName: '糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白執行率',
    diabetesCriteria: 'ICD-10-CM E08-E13',
    medicationCriteria: 'ATC A10',
    testCriteria: '09006(HbA1c), 09139(Glycated Albumin)',
    keyRequirement: '診斷與用藥需發生在同一處方案件',
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
