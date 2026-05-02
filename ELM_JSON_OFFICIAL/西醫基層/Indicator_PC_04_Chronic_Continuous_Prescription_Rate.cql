library Indicator_PC_04_Chronic_Continuous_Prescription_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 西醫基層慢性病連續處方箋開立率
// 指標代碼: 223
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍:
//   每季所有屬西醫基層總額之門診給藥案件
//   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
//
// 公式說明:
//   分子: 開立慢性病連續處方箋的案件數
//         (案件分類=02、04、08 且給藥日份 >= 21)
//   分母: 慢性病給藥案件數 (案件分類=02、04、08)
//
// 製表日期: 114/10/22
// ============================================

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

define function GetExtCodingCode(E FHIR.Encounter, extUrl String):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.Coding).code.value
    ),
    ''
  )

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

define function GetCaseClass(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/claim-type')

// 慢性病案件判斷：案件分類=02、04、08
define function IsChronicCase(E FHIR.Encounter):
  GetCaseClass(E) in {'02', '04', '08'}

// 慢性病連續處方箋：至少一筆MedicationRequest給藥日份>=21
// days between start and end >= 20 表示含首尾兩端共 >= 21 天
define function HasContinuousPrescription(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and MR.dispenseRequest.validityPeriod is not null
        and days between
              date from MR.dispenseRequest.validityPeriod.start.value
            and
              date from MR.dispenseRequest.validityPeriod.end.value >= 20
  )

// ============================================
// Base: Outpatient Encounters (排除代辦)
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and not IsAgencyCase(E)

// ============================================
// Denominator: 慢性病給藥案件 (案件分類=02、04、08)
// ============================================

define "Chronic Disease Encounters":
  "Outpatient Encounters" E
    where IsChronicCase(E)
      and exists(
        [MedicationRequest] MR
          where MR.encounter.reference.value = 'Encounter/' + E.id.value
            and MR.status.value = 'completed'
      )

// ============================================
// Numerator: 慢性病連續處方箋案件 (給藥日份>=21)
// ============================================

define "Chronic Continuous Prescription Encounters":
  "Chronic Disease Encounters" E
    where HasContinuousPrescription(E)

// ============================================
// Total Denominator / Numerator / Rate
// ============================================

define "Total Denominator":
  Count("Chronic Disease Encounters")

define "Total Numerator":
  Count("Chronic Continuous Prescription Encounters")

define "Total Rate":
  if "Total Denominator" > 0 then
    (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100
  else null

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1)
// ============================================

define "2024Q1 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": Count("Chronic Disease Encounters" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Numerator": Count("Chronic Continuous Prescription Encounters" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '223',
    indicatorName: '西醫基層慢性病連續處方箋開立率',
    caseClasses: '02, 04, 08',
    continuousCriteria: '給藥日份 >= 21',
    exclusions: '代辦案件',
    totalNumerator: "Total Numerator",
    totalDenominator: "Total Denominator",
    totalRate: "Total Rate",
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
