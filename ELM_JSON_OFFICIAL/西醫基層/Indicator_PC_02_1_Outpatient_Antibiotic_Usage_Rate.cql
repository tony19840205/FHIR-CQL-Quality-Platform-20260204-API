library Indicator_PC_02_1_Outpatient_Antibiotic_Usage_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 門診抗生素使用率
// 指標代碼: 1140.01
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍:
//   每季所有屬西醫基層總額之門診給藥案件
//   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
//   排除代辦案件
//
// 分母: 給藥案件數
//
// 分子: 給藥案件之使用抗生素藥品
//       (醫令代碼為10碼，ATC前3碼為 J01 ANTIBACTERIALS FOR SYSTEMIC USE) 案件數
//       排除: 急診(02)、預防注射(03)、STAT、預先批准
//
// 公式: 基層醫療機構使用抗生素藥品案件數 / 基層醫療機構開藥總案件數
// ============================================

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

define function GetClaimType(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/claim-type')

define function GetDispenseMethod(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/dispense-method')

define function GetDrugCost(E FHIR.Encounter):
  GetExtDecimal(E, 'http://nhi.gov.tw/fhir/StructureDefinition/drug-cost')

define function GetDrugDays(E FHIR.Encounter):
  Coalesce(
    Max(
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        return MR.dispenseRequest.expectedSupplyDuration.value.value
    ),
    0
  )

define function IsMedicationCase(E FHIR.Encounter):
  GetDrugCost(E) != 0
    or GetDrugDays(E) != 0
    or GetDispenseMethod(E) in {'0', '1', '6'}

// ============================================
// MedicationRequest Extension Helpers
// ============================================

define function GetMRExtBoolean(MR FHIR.MedicationRequest, extUrl String):
  exists(
    MR.extension Ext
      where Ext.url.value = extUrl
        and (Ext.value as FHIR.boolean).value = true
  )

define function HasPriorApproval(MR FHIR.MedicationRequest):
  GetMRExtBoolean(MR, 'http://www.nhi.gov.tw/fhir/StructureDefinition/prior-approval')

define function IsStatMedication(MR FHIR.MedicationRequest):
  exists(
    MR.dosageInstruction DI
      where (DI.asNeeded as FHIR.boolean).value = true
        or exists(
          DI.additionalInstruction AI
            where exists(AI.coding C where C.code.value = 'STAT')
        )
  )

// ============================================
// Antibiotic Check: ATC前3碼 = J01
// ============================================

define function HasAntibioticMedication(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      let medCodings: (MR.medication as FHIR.CodeableConcept).coding
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and not HasPriorApproval(MR)
        and not IsStatMedication(MR)
        and exists(
          medCodings AC
            where AC.system.value = 'http://www.whocc.no/atc'
              and Substring(AC.code.value, 0, 3) = 'J01'
        )
  )

// ============================================
// Data Retrieval
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and not IsAgencyCase(E)

define "Medication Cases":
  "Outpatient Encounters" E
    where IsMedicationCase(E)

// 分子基底: 排除急診(02)、預防注射(03)後有抗生素
define "Antibiotic Cases":
  "Medication Cases" E
    where not (GetClaimType(E) in {'02', '03'})
      and HasAntibioticMedication(E)

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1)
// ============================================

define "2024Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Numerator":   Count("Antibiotic Cases" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

define "Total Denominator": Count("Medication Cases")
define "Total Numerator":   Count("Antibiotic Cases")
define "Total Rate": if "Total Denominator" > 0 then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1140.01',
    indicatorName: '門診抗生素使用率',
    antibioticCriteria: 'ATC前3碼=J01 (ANTIBACTERIALS FOR SYSTEMIC USE)',
    exclusions: '急診(02)、預防注射(03)、STAT、預先批准',
    referenceCategory: '西醫基層總額',
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
    },
    total: Tuple { numerator: "Total Numerator", denominator: "Total Denominator", rate: "Total Rate" }
  }
