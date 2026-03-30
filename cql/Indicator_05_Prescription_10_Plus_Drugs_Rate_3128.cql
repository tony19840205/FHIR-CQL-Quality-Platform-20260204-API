library Indicator_05_Prescription_10_Plus_Drugs_Rate_3128 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 門診每張處方箋開藥品項數大於等於十項之案件比率
// 指標代碼: 3128
// 分子: 藥品品項數>=10項之案件數 (排除重大傷病/居家醫療/整合照護/急診/門診手術/STAT/PRN)
// 分母: 給藥案件數 (藥費!=0 或 給藥天數!=0 或 處方調劑方式為1,0,6)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'

context Patient

// ============================================
// Helper Functions
// ============================================

define function GetExtCode(E FHIR.Encounter, extUrl String):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.code).value
    ),
    ''
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

define function GetExtBoolean(E FHIR.Encounter, extUrl String):
  exists(
    E.extension Ext
      where Ext.url.value = extUrl
        and (Ext.value as FHIR.boolean).value = true
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

define function GetClaimType(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/claim-type')

define function GetDispenseMethod(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/dispense-method')

define function HasCatastrophicIllness(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/catastrophic-illness') = '001'

define function HasIntegratedCare(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/integrated-care') in {'Q', 'R', 'S', 'X', 'A', 'B', 'D', 'E', 'F'}

define function IsEmergencyOrSurgery(E FHIR.Encounter):
  GetClaimType(E) in {'02', '03'}

define function ToDecimal(v Integer):
  v * 1.0

// ============================================
// Home Care Check (Procedure with EC code)
// ============================================

define function HasHomeCare(E FHIR.Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          P.code.coding C
            where C.system.value = 'http://www.nhi.gov.tw/codes/procedure'
              and C.code.value = 'EC'
        )
  )

// ============================================
// Medication Checks
// ============================================

define function HasStatOrPrnMedication(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          MR.dosageInstruction DI
            where exists(
              DI.timing.code.coding C
                where C.code.value in {'STAT', 'PRN'}
            )
        )
  )

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
// Drug Item Count (10-digit codes, order type 1/4, quantity>0)
// ============================================

define function GetMRExtCode(MR FHIR.MedicationRequest, extUrl String):
  Coalesce(
    First(
      MR.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.Coding).code.value
    ),
    ''
  )

define function GetDrugItemCount(E FHIR.Encounter):
  Count(
    distinct (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
          and MR.status.value = 'completed'
          and GetMRExtCode(MR, 'http://nhi.gov.tw/fhir/StructureDefinition/order-type') in {'1', '4'}
          and Length(First((MR.medication as FHIR.CodeableConcept).coding).code.value) = 10
        return First((MR.medication as FHIR.CodeableConcept).coding).code.value
    )
  )

// ============================================
// Numerator Exclusion
// ============================================

define function ShouldExcludeFromNumerator(E FHIR.Encounter):
  HasCatastrophicIllness(E)
    or HasHomeCare(E)
    or HasIntegratedCare(E)
    or IsEmergencyOrSurgery(E)
    or HasStatOrPrnMedication(E)

// ============================================
// Data Retrieval
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and not IsAgencyCase(E)
      and GetReportReason(E) != '2'

define "Medication Cases":
  "Outpatient Encounters" E
    where IsMedicationCase(E)

define "Cases With 10 Or More Drugs":
  "Medication Cases" E
    where GetDrugItemCount(E) >= 10
      and not ShouldExcludeFromNumerator(E)

// ============================================
// Quarterly Statistics
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

define "Total Denominator": Count("Medication Cases")
define "Total Numerator": Count("Cases With 10 Or More Drugs")
define "Total Rate": if "Total Denominator" > 0 then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '3128',
    indicatorName: '門診每張處方箋開藥品項數大於等於十項之案件比率',
    drugThreshold: 10,
    numeratorExclusions: '重大傷病001, 居家醫療EC, 整合照護Q/R/S/X/A/B/D/E/F, 急診02, 門診手術03, STAT/PRN',
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
