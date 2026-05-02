library Indicator_PC_06_3_Chronic_Prescription_Days_Hyperlipidemia version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 西醫基層門診平均每張慢性病處方箋開藥日數-高血脂
// 指標代碼: 1171
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
//   慢性病定義:
//     高血脂 ICD-10-CM 前3碼 E78
//
//   分母納入條件 (以下擇一):
//     (1) 主診斷有高血脂且有給藥
//     (2) 次診斷有高血脂且有開立降血脂藥物
//
//   降血脂藥物 ATC 範圍: C10AA、C10AB、C10AC、C10AD、C10AX
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

// 高血脂 ICD-10-CM 前3碼 E78
define function IsHyperlipidemiaICD(code String):
  Substring(code, 0, 3) = 'E78'

// 降血脂藥物 ATC 範圍: C10AA、C10AB、C10AC、C10AD、C10AX
define function IsHyperlipidemiaATC(atcCode String):
  Substring(atcCode, 0, 5) in {'C10AA', 'C10AB', 'C10AC', 'C10AD', 'C10AX'}

// 取得該就診的最大給藥日份
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

// 有高血脂診斷（任何診斷位置）
define function HasHyperlipidemiaDiagnosis(E FHIR.Encounter):
  exists(
    [Condition] C
      where C.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          C.code.coding Co
            where Co.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
              and IsHyperlipidemiaICD(Co.code.value)
        )
  )

// 有降血脂藥物（ATC C10AA/AB/AC/AD/AX）
define function HasHyperlipidemiaMedication(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      let medCodings: (MR.medication as FHIR.CodeableConcept).coding
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and exists(
          medCodings AC
            where AC.system.value = 'http://www.whocc.no/atc'
              and IsHyperlipidemiaATC(AC.code.value)
        )
  )

// 有任何給藥（主診斷高血脂之判斷輔助）
define function HasCompletedMedication(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
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
// Denominator: 高血脂慢性病處方箋案件
// 案件分類=04/08 + 給藥日份>=3 +
// (有高血脂診斷且有給藥) 或 (有高血脂診斷且有降血脂藥)
// ============================================

define "Hyperlipidemia Chronic Prescription Encounters":
  "Outpatient Encounters" E
    where IsChronicCase(E)
      and GetEncounterMaxDrugDays(E) >= 3
      and HasHyperlipidemiaDiagnosis(E)
      and (HasHyperlipidemiaMedication(E) or HasCompletedMedication(E))

// ============================================
// Total Denominator / Numerator / Average
// ============================================

define "Total Denominator":
  Count("Hyperlipidemia Chronic Prescription Encounters")

define "Total Drug Days Sum":
  Coalesce(
    Sum(
      "Hyperlipidemia Chronic Prescription Encounters" E
        return GetEncounterMaxDrugDays(E)
    ),
    0
  )

define "Average Drug Days":
  if "Total Denominator" > 0 then
    (ToDecimal("Total Drug Days Sum") / ToDecimal("Total Denominator"))
  else null

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1)
// ============================================

define "2024Q1 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31]
define "2024Q1 Denominator": Count("2024Q1 Encounters")
define "2024Q1 Drug Days": Coalesce(Sum("2024Q1 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q1 Average": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Drug Days") / ToDecimal("2024Q1 Denominator")) else null

define "2024Q2 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30]
define "2024Q2 Denominator": Count("2024Q2 Encounters")
define "2024Q2 Drug Days": Coalesce(Sum("2024Q2 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q2 Average": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Drug Days") / ToDecimal("2024Q2 Denominator")) else null

define "2024Q3 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30]
define "2024Q3 Denominator": Count("2024Q3 Encounters")
define "2024Q3 Drug Days": Coalesce(Sum("2024Q3 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q3 Average": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Drug Days") / ToDecimal("2024Q3 Denominator")) else null

define "2024Q4 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31]
define "2024Q4 Denominator": Count("2024Q4 Encounters")
define "2024Q4 Drug Days": Coalesce(Sum("2024Q4 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2024Q4 Average": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Drug Days") / ToDecimal("2024Q4 Denominator")) else null

define "2025Q1 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31]
define "2025Q1 Denominator": Count("2025Q1 Encounters")
define "2025Q1 Drug Days": Coalesce(Sum("2025Q1 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q1 Average": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Drug Days") / ToDecimal("2025Q1 Denominator")) else null

define "2025Q2 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30]
define "2025Q2 Denominator": Count("2025Q2 Encounters")
define "2025Q2 Drug Days": Coalesce(Sum("2025Q2 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q2 Average": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Drug Days") / ToDecimal("2025Q2 Denominator")) else null

define "2025Q3 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30]
define "2025Q3 Denominator": Count("2025Q3 Encounters")
define "2025Q3 Drug Days": Coalesce(Sum("2025Q3 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q3 Average": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Drug Days") / ToDecimal("2025Q3 Denominator")) else null

define "2025Q4 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31]
define "2025Q4 Denominator": Count("2025Q4 Encounters")
define "2025Q4 Drug Days": Coalesce(Sum("2025Q4 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2025Q4 Average": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Drug Days") / ToDecimal("2025Q4 Denominator")) else null

define "2026Q1 Encounters": "Hyperlipidemia Chronic Prescription Encounters" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31]
define "2026Q1 Denominator": Count("2026Q1 Encounters")
define "2026Q1 Drug Days": Coalesce(Sum("2026Q1 Encounters" E return GetEncounterMaxDrugDays(E)), 0)
define "2026Q1 Average": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Drug Days") / ToDecimal("2026Q1 Denominator")) else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1171',
    indicatorName: '西醫基層門診平均每張慢性病處方箋開藥日數-高血脂',
    diseaseCategory: '高血脂',
    icdCriteria: 'E78',
    atcCriteria: 'C10AA/C10AB/C10AC/C10AD/C10AX (降血脂藥)',
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
