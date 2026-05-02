library Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 半人工膝關節置換手術後九十日以內置換物深部感染率
// 指標代碼: 3250
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍: (1)每季所有屬醫院總額之住院案件。(2)排除代辦案件。
//
// 分母: 當季內醫院半人工膝關節置換術執行案件數
//   半人工膝關節置換術: 醫令代碼 64169B 之住院案件
//
// 分子: 分母案件中，半人工膝關節置換後90天內發生置換物感染之案件數
//   置換物感染: 有執行 64053B 或 64198B 任一醫令之案件
//   排除: 64164B(全人工膝關節)同日申報64198B
//   排除: 64169B(半人工膝關節)同日申報64198B
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

// ============================================
// Helper Functions
// ============================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetProcedureDate(p FHIR.Procedure):
  case
    when p.performed is FHIR.dateTime then (p.performed as FHIR.dateTime).value
    when p.performed is FHIR.Period then (p.performed as FHIR.Period).start.value
    else null
  end

define function GetExtBoolean(E FHIR.Encounter, extUrl String):
  exists(
    E.extension Ext
      where Ext.url.value = extUrl
        and (Ext.value as FHIR.boolean).value = true
  )

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

define function IsSameDay(date1 DateTime, date2 DateTime):
  date from date1 = date from date2

// ============================================
// Inpatient Encounters (排除代辦案件)
// ============================================

define "Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and not IsAgencyCase(E)

// ============================================
// All Completed Procedures Linked to Inpatient
// ============================================

define "Inpatient Procedures":
  [Procedure] P
    where P.status.value = 'completed'
      and exists (
        "Inpatient Encounters" E
          where P.encounter.reference.value = 'Encounter/' + E.id.value
      )

// ============================================
// Partial TKA Procedures (Denominator Base)
// 半人工膝關節置換術: 醫令代碼 64169B
// ============================================

define "Partial TKA Procedures":
  "Inpatient Procedures" P
    where exists (
      P.code.coding C
        where C.code.value = '64169B'
    )
    and GetProcedureDate(P) is not null

// ============================================
// Infection Procedures (64053B or 64198B)
// ============================================

define "Infection Procedures":
  [Procedure] PI
    where PI.status.value = 'completed'
      and exists (
        PI.code.coding C
          where C.code.value in {'64053B', '64198B'}
      )
      and GetProcedureDate(PI) is not null

// ============================================
// Infection Within 90 Days After Partial TKA
// ============================================

define "Infection Within 90 Days After Partial TKA":
  "Infection Procedures" PI
    where exists (
      "Partial TKA Procedures" TKA
        where TKA.subject.reference.value = PI.subject.reference.value
          and GetProcedureDate(PI) in Interval[
            GetProcedureDate(TKA),
            GetProcedureDate(TKA) + 90 days
          ]
    )

// ============================================
// Excluded Same-Day Cases
// 排除: 64164B 或 64169B 同日申報 64198B
// ============================================

define "Excluded Same Day Cases":
  "Infection Within 90 Days After Partial TKA" PI
    where exists (
      PI.code.coding C where C.code.value = '64198B'
    )
    and exists (
      "Inpatient Procedures" TKA
        where TKA.subject.reference.value = PI.subject.reference.value
          and exists (TKA.code.coding C where C.code.value in {'64164B', '64169B'})
          and GetProcedureDate(TKA) is not null
          and IsSameDay(GetProcedureDate(TKA), GetProcedureDate(PI))
    )

// ============================================
// Valid Infection Cases (Numerator Base)
// ============================================

define "Valid Infection Cases":
  "Infection Within 90 Days After Partial TKA" PI
    where not exists (
      "Excluded Same Day Cases" EX
        where EX.id.value = PI.id.value
    )

// ============================================
// Overall Denominator / Numerator / Rate
// ============================================

define "Total Denominator":
  Count("Partial TKA Procedures")

define "Total Numerator":
  Count("Valid Infection Cases")

define "Overall Rate":
  if "Total Denominator" > 0
  then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100
  else null

// ============================================
// Quarterly Date Ranges
// ============================================

define "2024Q1 Start": DateTime(2024, 1, 1, 0, 0, 0, 0)
define "2024Q1 End":   DateTime(2024, 3, 31, 23, 59, 59, 999)
define "2024Q2 Start": DateTime(2024, 4, 1, 0, 0, 0, 0)
define "2024Q2 End":   DateTime(2024, 6, 30, 23, 59, 59, 999)
define "2024Q3 Start": DateTime(2024, 7, 1, 0, 0, 0, 0)
define "2024Q3 End":   DateTime(2024, 9, 30, 23, 59, 59, 999)
define "2024Q4 Start": DateTime(2024, 10, 1, 0, 0, 0, 0)
define "2024Q4 End":   DateTime(2024, 12, 31, 23, 59, 59, 999)
define "2025Q1 Start": DateTime(2025, 1, 1, 0, 0, 0, 0)
define "2025Q1 End":   DateTime(2025, 3, 31, 23, 59, 59, 999)
define "2025Q2 Start": DateTime(2025, 4, 1, 0, 0, 0, 0)
define "2025Q2 End":   DateTime(2025, 6, 30, 23, 59, 59, 999)
define "2025Q3 Start": DateTime(2025, 7, 1, 0, 0, 0, 0)
define "2025Q3 End":   DateTime(2025, 9, 30, 23, 59, 59, 999)
define "2025Q4 Start": DateTime(2025, 10, 1, 0, 0, 0, 0)
define "2025Q4 End":   DateTime(2025, 12, 31, 23, 59, 59, 999)
define "2026Q1 Start": DateTime(2026, 1, 1, 0, 0, 0, 0)
define "2026Q1 End":   DateTime(2026, 3, 31, 23, 59, 59, 999)

// ============================================
// Quarterly Denominator / Numerator / Rate
// ============================================

define "2024Q1 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator":
  Count("Partial TKA Procedures" P where GetProcedureDate(P) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator":
  Count("Valid Infection Cases" PI where GetProcedureDate(PI) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '3250',
    indicatorName: '半人工膝關節置換手術後九十日以內置換物深部感染率',
    partialTKACode: '64169B',
    infectionCodes: '64053B, 64198B',
    totalDenominator: "Total Denominator",
    totalNumerator: "Total Numerator",
    overallRate: "Overall Rate",
    quarters: List{
      Tuple { quarter: '2024Q1', denominator: "2024Q1 Denominator", numerator: "2024Q1 Numerator", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', denominator: "2024Q2 Denominator", numerator: "2024Q2 Numerator", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', denominator: "2024Q3 Denominator", numerator: "2024Q3 Numerator", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', denominator: "2024Q4 Denominator", numerator: "2024Q4 Numerator", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', denominator: "2025Q1 Denominator", numerator: "2025Q1 Numerator", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', denominator: "2025Q2 Denominator", numerator: "2025Q2 Numerator", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', denominator: "2025Q3 Denominator", numerator: "2025Q3 Numerator", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', denominator: "2025Q4 Denominator", numerator: "2025Q4 Numerator", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', denominator: "2026Q1 Denominator", numerator: "2026Q1 Numerator", rate: "2026Q1 Rate" }
    }
  }
