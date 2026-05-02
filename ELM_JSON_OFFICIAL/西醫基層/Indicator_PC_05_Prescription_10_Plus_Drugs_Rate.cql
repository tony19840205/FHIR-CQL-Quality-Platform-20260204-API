library Indicator_PC_05_Prescription_10_Plus_Drugs_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 西醫基層門診每張處方箋開藥品項數大於等於十項之案件比率
// 指標代碼: 1749
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍:
//   每季所有屬西醫基層總額之門診給藥案件
//   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
//   排除代辦案件及「補報原因註記」為 2 之案件
//
// 公式說明:
//   分子: 分母案件中藥品項數 >= 10 項之案件數
//   分母: 給藥案件數
//
//   藥品項數: 醫令類別 1 或 4、醫令代碼為 10 碼且醫令數量 > 0，
//            同院同處方下同醫令代碼歸戶為一項。
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

define function GetExtDecimal(E FHIR.Encounter, extUrl String):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.decimal).value
    ),
    0
  )

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

define function GetReportReason(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/report-reason')

define function GetDispenseMethod(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/dispense-method')

define function GetDrugCost(E FHIR.Encounter):
  GetExtDecimal(E, 'http://nhi.gov.tw/fhir/StructureDefinition/drug-cost')

// 給藥天數：取該就診最大的 expectedSupplyDuration
define function GetDrugDays(E FHIR.Encounter):
  Coalesce(
    Max(
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        return MR.dispenseRequest.expectedSupplyDuration.value.value
    ),
    0
  )

// 分母判斷：藥費≠0 或 給藥天數≠0 或 調劑方式∈{0,1,6}
define function IsMedicationCase(E FHIR.Encounter):
  GetDrugCost(E) != 0
    or GetDrugDays(E) != 0
    or GetDispenseMethod(E) in {'0', '1', '6'}

// 取 MedicationRequest 的醫令類別（order-type extension）
define function GetMRExtCodingCode(MR FHIR.MedicationRequest, extUrl String):
  Coalesce(
    First(
      MR.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.Coding).code.value
    ),
    ''
  )

// 藥品項數：醫令類別1或4、醫令代碼10碼、同處方同代碼歸戶
define function GetDrugItemCount(E FHIR.Encounter):
  Count(
    distinct (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
          and MR.status.value = 'completed'
          and GetMRExtCodingCode(MR, 'http://nhi.gov.tw/fhir/StructureDefinition/order-type') in {'1', '4'}
          and Length(First((MR.medication as FHIR.CodeableConcept).coding).code.value) = 10
        return First((MR.medication as FHIR.CodeableConcept).coding).code.value
    )
  )

// ============================================
// Base Encounters: 西醫基層門診，排除代辦及補報原因=2
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and not IsAgencyCase(E)
      and GetReportReason(E) != '2'

// ============================================
// Denominator: 給藥案件數
// ============================================

define "Medication Cases":
  "Outpatient Encounters" E
    where IsMedicationCase(E)

// ============================================
// Numerator: 藥品項數 >= 10 之案件
// ============================================

define "Cases With 10 Or More Drugs":
  "Medication Cases" E
    where GetDrugItemCount(E) >= 10

// ============================================
// Total Denominator / Numerator / Rate
// ============================================

define "Total Denominator":
  Count("Medication Cases")

define "Total Numerator":
  Count("Cases With 10 Or More Drugs")

define "Total Rate":
  if "Total Denominator" > 0 then
    (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100
  else null

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1)
// ============================================

define "2024Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Numerator": Count("Cases With 10 Or More Drugs" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1749',
    indicatorName: '西醫基層門診每張處方箋開藥品項數大於等於十項之案件比率',
    drugThreshold: 10,
    denominatorCriteria: '藥費≠0 或 給藥天數≠0 或 調劑方式∈{0,1,6}',
    exclusions: '代辦案件, 補報原因=2',
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
