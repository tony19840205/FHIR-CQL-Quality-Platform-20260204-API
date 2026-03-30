library Indicator_04_Chronic_Continuous_Prescription_Rate_1318 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 慢性病連續處方箋開立率
// 指標代碼: 1318
// 分子: 開立慢性病連續處方箋件數
// 分母: 慢性病案件數
// 慢性病案件條件: 診察費項目代碼為慢性病代碼(51個) 且 案件分類=04、E1
// 排除: 代辦案件, 婦產科專科醫院, 小兒科專科醫院, 呼吸照護病房>=80%醫院

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
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

define function GetClaimType(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/claim-type')

// ============================================
// Chronic Consultation Codes (51 codes)
// ============================================

define function IsChronicConsultationCode(codeVal String):
  codeVal in {
    '00155A', '00157A', '00170A', '00171A', '00131B', '00132B', '00172B', '00173B',
    '00135B', '00136B', '00174B', '00175B', '00137B', '00138B', '00176B', '00177B',
    '00139C', '00140C', '00158C', '00159C', '00141C', '00142C', '00160C', '00161C',
    '00143C', '00144C', '00162C', '00163C', '00145C', '00146C', '00164C', '00165C',
    '00147C', '00148C', '00166C', '00167C', '00149C', '00150C', '00168C', '00169C',
    '00178B', '00179B', '00180B', '00181B', '00182C', '00183C', '00184C', '00185C',
    '00187C', '00189C', '00190C', '00191C'
  }

// ============================================
// Chronic Consultation Check via Procedure
// ============================================

define function HasChronicConsultation(E FHIR.Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          P.code.coding C
            where C.system.value = 'http://www.nhi.gov.tw/codes/procedure'
              and IsChronicConsultationCode(C.code.value)
        )
  )

// ============================================
// Continuous Prescription Check
// E1 claim type + validityPeriod > supplyDuration
// ============================================

define function IsContinuousPrescription(E FHIR.Encounter):
  HasChronicConsultation(E)
    and GetClaimType(E) = 'E1'
    and exists(
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
          and MR.dispenseRequest.validityPeriod is not null
          and MR.dispenseRequest.expectedSupplyDuration is not null
          and MR.dispenseRequest.validityPeriod.start.value < MR.dispenseRequest.validityPeriod.end.value
    )

// ============================================
// Data Retrieval
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and not IsAgencyCase(E)

define "Chronic Disease Cases":
  "Outpatient Encounters" E
    where HasChronicConsultation(E)
      and GetClaimType(E) in {'04', 'E1'}

define "Chronic Continuous Prescription Cases":
  "Chronic Disease Cases" E
    where IsContinuousPrescription(E)

// ============================================
// Quarterly Statistics
// ============================================

define "2024Q1 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": Count("Chronic Disease Cases" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Numerator": Count("Chronic Continuous Prescription Cases" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

define "Total Denominator": Count("Chronic Disease Cases")
define "Total Numerator": Count("Chronic Continuous Prescription Cases")
define "Total Rate": if "Total Denominator" > 0 then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1318',
    indicatorName: '慢性病連續處方箋開立率',
    chronicConsultationCodes: 51,
    claimTypes: '04, E1',
    exclusions: '代辦案件, 婦產科專科醫院, 小兒科專科醫院, 呼吸照護病房>=80%醫院',
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
