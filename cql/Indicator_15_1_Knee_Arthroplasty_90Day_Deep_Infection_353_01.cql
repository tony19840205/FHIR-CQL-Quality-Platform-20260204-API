library Indicator_15_1_Knee_Arthroplasty_90Day_Deep_Infection_353_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 人工膝關節置換手術後九十日以內置換物深部感染率
// 指標代碼: 353.01
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 分母: 當季內醫院人工膝關節置換執行案件數
//   全人工膝關節: 64164B(類別2), 97805K, 97806A, 97807B
//   半人工膝關節: 64169B
// 分子: 分母案件中90天內發生置換物感染(64053B, 64198B)
//   排除: 64164B同日申報64198B 或 64169B同日申報64198B
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

// ============================================
// Helper Functions
// ============================================

define function GetProcedureDate(p Procedure):
  case
    when p.performed is FHIR.dateTime then (p.performed as FHIR.dateTime).value
    when p.performed is FHIR.Period then (p.performed as FHIR.Period).start.value
    else null
  end

define function IsTKAProcedure(p Procedure):
  exists (
    p.code.coding C
      where C.code.value in {
        '64164B', '97805K', '97806A', '97807B', '64169B',
        '609588000', '179344006', '265157000',
        '0SRC0JZ', '0SRD0JZ'
      }
  )

define function IsDeepInfectionProcedure(p Procedure):
  exists (
    p.code.coding C
      where C.code.value in {'64053B', '64198B'}
  )

define function IsSameDay(date1 DateTime, date2 DateTime):
  date from date1 = date from date2

// ============================================
// Main Definitions
// ============================================

// All completed procedures
define "All Completed Procedures":
  [Procedure] P
    where P.status.value = 'completed'

// Inpatient encounters
define "All Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'IMP'

// Inpatient procedures linked by encounter
define "Inpatient Procedures":
  "All Completed Procedures" P
    with "All Inpatient Encounters" E
      such that P.encounter.reference.value = 'Encounter/' + E.id.value

// All TKA Procedures (full + partial)
define "All TKA Procedures":
  "Inpatient Procedures" P
    where IsTKAProcedure(P)

// Deep infection procedures
define "Deep Infection Procedures":
  "Inpatient Procedures" PI
    where IsDeepInfectionProcedure(PI)

// Infection within 90 days after TKA
define "Deep Infection Within 90 Days After TKA":
  "Deep Infection Procedures" PI
    where exists (
      "All TKA Procedures" TKA
        where TKA.subject.reference.value = PI.subject.reference.value
        and GetProcedureDate(PI) is not null
        and GetProcedureDate(TKA) is not null
        and GetProcedureDate(PI) in Interval[
          GetProcedureDate(TKA),
          GetProcedureDate(TKA) + 90 days
        ]
    )

// Excluded same-day cases (64198B same day as 64164B or 64169B)
define "Excluded Same Day Cases":
  "Deep Infection Within 90 Days After TKA" PI
    where exists (
      "All TKA Procedures" TKA
        where TKA.subject.reference.value = PI.subject.reference.value
        and GetProcedureDate(PI) is not null
        and GetProcedureDate(TKA) is not null
        and IsSameDay(GetProcedureDate(TKA), GetProcedureDate(PI))
        and exists (PI.code.coding C where C.code.value = '64198B')
        and exists (TKA.code.coding C where C.code.value in {'64164B', '64169B'})
    )

// Valid infection cases (excluding same-day)
define "Valid Deep Infection Cases":
  "Deep Infection Within 90 Days After TKA" PI
    where not exists (
      "Excluded Same Day Cases" EX
        where EX.id.value = PI.id.value
    )

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
// Quarterly Denominator/Numerator/Rate
// ============================================

define "2024Q1 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator":
  Count("All TKA Procedures" P where GetProcedureDate(P) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator":
  Count("Valid Deep Infection Cases" PI where GetProcedureDate(PI) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Overall Totals
// ============================================

define "Total Denominator":
  Count("All TKA Procedures")

define "Total Numerator":
  Count("Valid Deep Infection Cases")

define "Overall Rate":
  if "Total Denominator" > 0
  then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100
  else null

// ============================================
// Final Report
// ============================================

define "Indicator Result":
  Tuple {
    IndicatorCode: '353.01',
    IndicatorName: '人工膝關節置換手術後九十日以內置換物深部感染率',
    TotalDenominator: "Total Denominator",
    TotalNumerator: "Total Numerator",
    OverallRate: "Overall Rate"
  }
