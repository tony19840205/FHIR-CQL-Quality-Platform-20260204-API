library Indicator_PC_01_Outpatient_Injection_Usage_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 門診注射劑使用率
// 指標代碼: 1150.01
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
// 分子: 給藥案件之針劑藥品(醫令代碼為10碼且第8碼為「2」)案件數
//       但排除下列:
//   (a) 門診化療注射劑: 醫令37005B、37031B~37041B 或癌症用藥
//       (ATC前3碼L01/L02 或 H01AB01、L03AB01、L03AB04、L03AB05、L03AB15、
//        L03AC01、L03AX03、L03AX16、L04AX01、M05BA02、M05BA03、M05BA06、
//        M05BA08(規格量4.00MG)、M05BX04、V10XX03，且醫令為10碼第8碼=2)
//   (b) 急診注射劑: 案件分類代碼為02
//   (c) 流感疫苗注射劑: 藥品成分ATC前5碼J07BB
//   (d) 外傷緊急處置使用之破傷風類毒素注射劑: ATC J07AM01
//   (e) 經醫師指導後得攜回之注射藥品
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
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

define function GetClaimType(E FHIR.Encounter):
  GetExtCodingCode(E, 'http://nhi.gov.tw/fhir/StructureDefinition/claim-type')

define function GetExtDecimal(E FHIR.Encounter, extUrl String):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.decimal).value
    ),
    0
  )

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
// Injection Drug Code Check (10碼，第8碼='2')
// ============================================

define function IsInjectionDrugCode(drugCode String):
  Length(drugCode) = 10 and Substring(drugCode, 7, 1) = '2'

// ============================================
// Exclusion (a): 化療相關處置碼
// ============================================

define function IsExcludedChemoProcedure(procedureCode String):
  procedureCode in {
    '37005B', '37031B', '37032B', '37033B', '37034B', '37035B',
    '37036B', '37037B', '37038B', '37039B', '37040B', '37041B'
  }

// ============================================
// Exclusion (a): 化療/免疫/骨鬆 ATC 碼
// ============================================

define function IsExcludedChemotherapyATC(atcCode String):
  Substring(atcCode, 0, 3) in {'L01', 'L02'}
    or atcCode in {
      'H01AB01', 'L03AB01', 'L03AB04', 'L03AB05', 'L03AB15',
      'L03AC01', 'L03AX03', 'L03AX16', 'L04AX01',
      'M05BA02', 'M05BA03', 'M05BA06', 'M05BA08', 'M05BX04',
      'V10XX03', 'J07AM01'
    }

// ============================================
// Exclusion (c): 流感疫苗 J07BB
// ============================================

define function IsInfluenzaVaccine(atcCode String):
  Substring(atcCode, 0, 5) = 'J07BB'

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

define function HasTakeHomeInjection(MR FHIR.MedicationRequest):
  GetMRExtBoolean(MR, 'http://www.nhi.gov.tw/fhir/StructureDefinition/take-home-injection')

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
// Check if encounter has qualifying injection
// (排除化療、急診、流感疫苗、破傷風、可攜回)
// ============================================

define function HasQualifyingInjection(E FHIR.Encounter):
  exists(
    [MedicationRequest] MR
      let drugCode: Coalesce(First((MR.medication as FHIR.CodeableConcept).coding).code.value, ''),
          medCodings: (MR.medication as FHIR.CodeableConcept).coding
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and IsInjectionDrugCode(drugCode)
        and not IsExcludedChemoProcedure(drugCode)
        and not exists(medCodings AC where AC.system.value = 'http://www.whocc.no/atc' and IsExcludedChemotherapyATC(AC.code.value))
        and not exists(medCodings AC where AC.system.value = 'http://www.whocc.no/atc' and IsInfluenzaVaccine(AC.code.value))
        and not HasPriorApproval(MR)
        and not IsStatMedication(MR)
        and not HasTakeHomeInjection(MR)
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

// 分子基底: 排除急診(02)案件後有合格注射劑
define "Injection Cases":
  "Medication Cases" E
    where not (GetClaimType(E) in {'02', '03'})
      and HasQualifyingInjection(E)

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1)
// ============================================

define "2024Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2024-01-01, @2024-03-31])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2024-04-01, @2024-06-30])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2024-07-01, @2024-09-30])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2024-10-01, @2024-12-31])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2025-01-01, @2025-03-31])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2025-04-01, @2025-06-30])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2025-07-01, @2025-09-30])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2025-10-01, @2025-12-31])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": Count("Medication Cases" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Numerator":   Count("Injection Cases" E where date from start of E.period in Interval[@2026-01-01, @2026-03-31])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

define "Total Denominator": Count("Medication Cases")
define "Total Numerator":   Count("Injection Cases")
define "Total Rate": if "Total Denominator" > 0 then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1150.01',
    indicatorName: '門診注射劑使用率',
    injectionCriteria: '醫令代碼10碼且第8碼=2',
    exclusions: '化療醫令(37005B/37031B-37041B)/化療ATC(L01/L02)/流感疫苗(J07BB)/破傷風(J07AM01)/急診(02)/依指導攜回',
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
