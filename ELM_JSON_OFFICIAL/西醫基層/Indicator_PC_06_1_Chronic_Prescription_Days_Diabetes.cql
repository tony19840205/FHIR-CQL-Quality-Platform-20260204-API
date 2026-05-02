library Indicator_PC_06_1_Chronic_Prescription_Days_Diabetes version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 西醫基層門診平均每張慢性病處方箋開藥日數-糖尿病
// 指標代碼: 1169
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍:
//   每季所有屬西醫基層總額之門診給藥案件
//   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
//
// 公式說明:
//   分子: 開立慢性病疾病別處方箋案件給藥日份加總
//   分母: 開立慢性病疾病別處方箋次數加總
//   結果: 分子/分母 = 平均每張慢性病處方箋開藥日數
//
//   慢性病定義 (主診斷):
//     糖尿病   ICD-10-CM 前3碼 E08、E09、E10、E11、E12、E13
//
//   分母納入條件 (以下擇一):
//     (1) 主診斷為糖尿病且有給藥
//     (2) 次診斷有糖尿病且有開立降血糖藥物(ATC A10)
//
//   慢性病處方箋: 案件分類=04 或 08，排除給藥日份 < 3
//
//   給藥日份: 取 MedicationRequest.dispenseRequest.validityPeriod
//            計算 (結束日 - 開始日 + 1) 天
//
// 製表日期: 114/10/22
// ============================================

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

// 慢性病案件：案件分類=04 或 08
define function IsChronicCase(E FHIR.Encounter):
  GetCaseClass(E) in {'04', '08'}

// 糖尿病 ICD-10-CM 前3碼 E08-E13
define function IsDiabetesICD(code String):
  Substring(code, 0, 3) in {'E08', 'E09', 'E10', 'E11', 'E12', 'E13'}

// 取得該就診的最大給藥日份 (使用 validityPeriod)
define function GetEncounterMaxDrugDays(E FHIR.Encounter):
  Coalesce(
    Max(
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
          and MR.status.value = 'completed'
          and MR.dispenseRequest.validityPeriod is not null
        return (days between
          date from MR.dispenseRequest.validityPeriod.start.value
          and date from MR.dispenseRequest.validityPeriod.end.value) + 1
    ),
    0
  )

// 有糖尿病診斷（主診斷或次診斷）via Condition resource
define function HasDiabetesDiagnosis(E FHIR.Encounter):
  exists(
    [Condition] C
      where C.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          C.code.coding Co
            where Co.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
              and IsDiabetesICD(Co.code.value)
        )
  )

// 有任何給藥（主診斷有糖尿病 + 有給藥 之判斷用）
define function HasCompletedMedication(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
  )

// 有降血糖藥物（ATC A10）
define function HasDiabetesMedication(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      let medCodings: (MR.medication as FHIR.CodeableConcept).coding
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and exists(
          medCodings AC
            where AC.system.value = 'http://www.whocc.no/atc'
              and Substring(AC.code.value, 0, 3) = 'A10'
        )
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
// Denominator: 糖尿病慢性病處方箋案件
// 案件分類=04/08 + 給藥日份>=3 + 糖尿病診斷條件
// ============================================

define "Diabetes Chronic Prescription Encounters":
  "Outpatient Encounters" E
    where IsChronicCase(E)
      and GetEncounterMaxDrugDays(E) >= 3
      and HasDiabetesDiagnosis(E)
      and (HasDiabetesMedication(E) or HasCompletedMedication(E))

// ============================================
// Total Denominator / Numerator / Average
// ============================================

define "Total Denominator":
  Count("Diabetes Chronic Prescription Encounters")

define "Total Drug Days Sum":
  Coalesce(
    Sum("Diabetes Chronic Prescription Encounters" E return GetEncounterMaxDrugDays(E)),
    0
  )

define "Average Drug Days":
  if "Total Denominator" > 0 then
    (ToDecimal("Total Drug Days Sum") / ToDecimal("Total Denominator"))
  else null

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1)
// ============================================

define "2024Q1 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31]
define "2024Q1 Denominator": Count("2024Q1 Encounters")
define "2024Q1 Drug Days": Coalesce(Sum("2024Q1 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q1 Average": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Drug Days") / ToDecimal("2024Q1 Denominator")) else null

define "2024Q2 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30]
define "2024Q2 Denominator": Count("2024Q2 Encounters")
define "2024Q2 Drug Days": Coalesce(Sum("2024Q2 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q2 Average": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Drug Days") / ToDecimal("2024Q2 Denominator")) else null

define "2024Q3 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30]
define "2024Q3 Denominator": Count("2024Q3 Encounters")
define "2024Q3 Drug Days": Coalesce(Sum("2024Q3 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q3 Average": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Drug Days") / ToDecimal("2024Q3 Denominator")) else null

define "2024Q4 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31]
define "2024Q4 Denominator": Count("2024Q4 Encounters")
define "2024Q4 Drug Days": Coalesce(Sum("2024Q4 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q4 Average": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Drug Days") / ToDecimal("2024Q4 Denominator")) else null

define "2025Q1 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31]
define "2025Q1 Denominator": Count("2025Q1 Encounters")
define "2025Q1 Drug Days": Coalesce(Sum("2025Q1 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q1 Average": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Drug Days") / ToDecimal("2025Q1 Denominator")) else null

define "2025Q2 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30]
define "2025Q2 Denominator": Count("2025Q2 Encounters")
define "2025Q2 Drug Days": Coalesce(Sum("2025Q2 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q2 Average": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Drug Days") / ToDecimal("2025Q2 Denominator")) else null

define "2025Q3 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30]
define "2025Q3 Denominator": Count("2025Q3 Encounters")
define "2025Q3 Drug Days": Coalesce(Sum("2025Q3 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q3 Average": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Drug Days") / ToDecimal("2025Q3 Denominator")) else null

define "2025Q4 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31]
define "2025Q4 Denominator": Count("2025Q4 Encounters")
define "2025Q4 Drug Days": Coalesce(Sum("2025Q4 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q4 Average": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Drug Days") / ToDecimal("2025Q4 Denominator")) else null

define "2026Q1 Encounters": "Diabetes Chronic Prescription Encounters" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31]
define "2026Q1 Denominator": Count("2026Q1 Encounters")
define "2026Q1 Drug Days": Coalesce(Sum("2026Q1 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2026Q1 Average": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Drug Days") / ToDecimal("2026Q1 Denominator")) else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1169',
    indicatorName: '西醫基層門診平均每張慢性病處方箋開藥日數-糖尿病',
    diseaseCategory: '糖尿病',
    icdCriteria: 'E08/E09/E10/E11/E12/E13',
    atcCriteria: 'A10 (降血糖藥)',
    caseClasses: '04, 08',
    drugDaysMinimum: 3,
    exclusions: '代辦案件, 給藥日份<3',
    totalDrugDaysSum: "Total Drug Days Sum",
    totalDenominator: "Total Denominator",
    averageDrugDays: "Average Drug Days",
    quarters: List{
      Tuple { quarter: '2024Q1', drugDaysSum: "2024Q1 Drug Days", denominator: "2024Q1 Denominator", average: "2024Q1 Average" },
      Tuple { quarter: '2024Q2', drugDaysSum: "2024Q2 Drug Days", denominator: "2024Q2 Denominator", average: "2024Q2 Average" },
      Tuple { quarter: '2024Q3', drugDaysSum: "2024Q3 Drug Days", denominator: "2024Q3 Denominator", average: "2024Q3 Average" },
      Tuple { quarter: '2024Q4', drugDaysSum: "2024Q4 Drug Days", denominator: "2024Q4 Denominator", average: "2024Q4 Average" },
      Tuple { quarter: '2025Q1', drugDaysSum: "2025Q1 Drug Days", denominator: "2025Q1 Denominator", average: "2025Q1 Average" },
      Tuple { quarter: '2025Q2', drugDaysSum: "2025Q2 Drug Days", denominator: "2025Q2 Denominator", average: "2025Q2 Average" },
      Tuple { quarter: '2025Q3', drugDaysSum: "2025Q3 Drug Days", denominator: "2025Q3 Denominator", average: "2025Q3 Average" },
      Tuple { quarter: '2025Q4', drugDaysSum: "2025Q4 Drug Days", denominator: "2025Q4 Denominator", average: "2025Q4 Average" },
      Tuple { quarter: '2026Q1', drugDaysSum: "2026Q1 Drug Days", denominator: "2026Q1 Denominator", average: "2026Q1 Average" }
    }
  }
