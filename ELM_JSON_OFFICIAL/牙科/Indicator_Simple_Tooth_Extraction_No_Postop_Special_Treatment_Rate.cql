library Indicator_Simple_Tooth_Extraction_No_Postop_Special_Treatment_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 簡單拔牙術後無特殊處理率
// 指標代碼: 牙科-簡單拔牙術後無特處
// 指標說明: 簡單拔牙後，術後未需特殊處理（未出現並發症）的比率
//
// 分母: 期間內簡單拔牙（92015C）件數
// 分子: 分母中，術後 7 天內未出現並發症處置（無拔牙創傷處理代碼）的件數
// 公式: (分子/分母) × 100%
//
// 拔牙並發症處置代碼（術後特殊處理）:
//   92016C: 複雜拔牙（轉為複雜 = 有並發症）
//   90001C: 根管治療相關（拔牙後感染需根管）
//
// 術後觀察: 7 天內無並發症
//
// 統計範圍: 2024Q1 ~ 2026Q1（9 個季度）

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd   DateTime default @2026-03-31T23:59:59.0+08:00

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function GetProcedureDate(P FHIR.Procedure):
  if P.performed is FHIR.dateTime
    then date from (P.performed as FHIR.dateTime)
    else if P.performed is FHIR.Period
      then date from (P.performed as FHIR.Period).start
      else null

define function IsCompletedProcedure(P FHIR.Procedure):
  P.status.value = 'completed'

define function GetProcedureCode(P FHIR.Procedure):
  Coalesce(First(P.code.coding C return C.code.value), '')

// 簡單拔牙（92015C）
define function IsSimpleExtractionProcedure(P FHIR.Procedure):
  GetProcedureCode(P) = '92015C'

// 術後特殊處理（並發症標誌：複雜拔牙或根管治療介入）
define function IsPostopSpecialTreatment(P FHIR.Procedure):
  GetProcedureCode(P) in { '92016C', '90001C', '90002C', '90003C', '90004C' }

define function ToDecimal(v Integer):
  v * 1.0

// 拔牙後 7 天內是否需要術後特殊處理
define function HasPostopSpecialTreatmentWithin7Days(extractDate Date):
  exists(
    [Procedure] P2
      where IsCompletedProcedure(P2)
        and IsPostopSpecialTreatment(P2)
        and GetProcedureDate(P2) in Interval[extractDate, extractDate + 7 days]
        and GetProcedureDate(P2) != extractDate
  )

// =============================================================================
// Period-based Rate Functions
// =============================================================================

// 分子: 簡單拔牙術後無特殊處理件數
define function NoPostopNumerInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsSimpleExtractionProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and not HasPostopSpecialTreatmentWithin7Days(GetProcedureDate(P))
  )

// 分母: 期間內簡單拔牙總件數
define function NoPostopDenomInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsSimpleExtractionProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )

// 指標率: (分子/分母) × 100，0 除保護
define function RateInPeriod(periodStart Date, periodEnd Date):
  if NoPostopDenomInPeriod(periodStart, periodEnd) > 0
    then ToDecimal(NoPostopNumerInPeriod(periodStart, periodEnd)) / ToDecimal(NoPostopDenomInPeriod(periodStart, periodEnd)) * 100.0
    else 0.0

// =============================================================================
// Quarterly Statistics: 2024Q1 ~ 2026Q1（9 個季度）
// =============================================================================

define "2024Q1 Numer": NoPostopNumerInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Denom": NoPostopDenomInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate":  RateInPeriod(@2024-01-01, @2024-03-31)

define "2024Q2 Numer": NoPostopNumerInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Denom": NoPostopDenomInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate":  RateInPeriod(@2024-04-01, @2024-06-30)

define "2024Q3 Numer": NoPostopNumerInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Denom": NoPostopDenomInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate":  RateInPeriod(@2024-07-01, @2024-09-30)

define "2024Q4 Numer": NoPostopNumerInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Denom": NoPostopDenomInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate":  RateInPeriod(@2024-10-01, @2024-12-31)

define "2025Q1 Numer": NoPostopNumerInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Denom": NoPostopDenomInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate":  RateInPeriod(@2025-01-01, @2025-03-31)

define "2025Q2 Numer": NoPostopNumerInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Denom": NoPostopDenomInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate":  RateInPeriod(@2025-04-01, @2025-06-30)

define "2025Q3 Numer": NoPostopNumerInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Denom": NoPostopDenomInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate":  RateInPeriod(@2025-07-01, @2025-09-30)

define "2025Q4 Numer": NoPostopNumerInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Denom": NoPostopDenomInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate":  RateInPeriod(@2025-10-01, @2025-12-31)

define "2026Q1 Numer": NoPostopNumerInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Denom": NoPostopDenomInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate":  RateInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Indicator Result":
  Tuple {
    indicatorName:  '簡單拔牙術後無特殊處理率',
    indicatorCode:  '牙科-簡單拔牙術後無特處',
    unit:           '%',
    extractCode:    '92015C',
    postopWindow:   '7 天',
    numerator:      "2026Q1 Numer",
    denominator:    "2026Q1 Denom",
    rate:           "2026Q1 Rate",
    quarters: List{
      Tuple { quarter: '2024Q1', numer: "2024Q1 Numer", denom: "2024Q1 Denom", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', numer: "2024Q2 Numer", denom: "2024Q2 Denom", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', numer: "2024Q3 Numer", denom: "2024Q3 Denom", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', numer: "2024Q4 Numer", denom: "2024Q4 Denom", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', numer: "2025Q1 Numer", denom: "2025Q1 Denom", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', numer: "2025Q2 Numer", denom: "2025Q2 Denom", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', numer: "2025Q3 Numer", denom: "2025Q3 Denom", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', numer: "2025Q4 Numer", denom: "2025Q4 Denom", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', numer: "2026Q1 Numer", denom: "2026Q1 Denom", rate: "2026Q1 Rate" }
    }
  }
