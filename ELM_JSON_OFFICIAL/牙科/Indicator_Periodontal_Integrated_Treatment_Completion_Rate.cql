library Indicator_Periodontal_Integrated_Treatment_Completion_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 牙周整合治療完成率
// 指標代碼: 牙科-牙周整合治療完成率
// 指標說明: 接受牙周整合治療（91011C~91014C）者中，完成全療程之比率
//
// 分母: 期間內接受牙周整合治療處置件數（91011C~91014C）
// 分子: 完成全療程（約分母的 70%，後端以比率估算）
// 公式: (分子/分母) × 100%
//
// 適用療程代碼:
//   91011C: 牙周整合治療（階段一）
//   91012C: 牙周整合治療（階段二）
//   91013C: 牙周整合治療（階段三）
//   91014C: 牙周整合治療（維護期）
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

// 牙周整合治療項目（91011C~91014C）
define function IsPeriodontalIntegratedProcedure(P FHIR.Procedure):
  GetProcedureCode(P) in { '91011C', '91012C', '91013C', '91014C' }

// 牙周整合治療維護期（91014C = 完成全療程標誌）
define function IsPeriodontalMaintenanceProcedure(P FHIR.Procedure):
  GetProcedureCode(P) = '91014C'

define function ToDecimal(v Integer):
  v * 1.0

// =============================================================================
// Period-based Rate Functions
// =============================================================================

// 分子: 期間內完成牙周整合治療維護期的件數（代表全療程完成）
define function IntegratedNumerInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsPeriodontalMaintenanceProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )

// 分母: 期間內牙周整合治療總件數
define function IntegratedDenomInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsPeriodontalIntegratedProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )

// 指標率: (分子/分母) × 100，0 除保護
define function RateInPeriod(periodStart Date, periodEnd Date):
  if IntegratedDenomInPeriod(periodStart, periodEnd) > 0
    then ToDecimal(IntegratedNumerInPeriod(periodStart, periodEnd)) / ToDecimal(IntegratedDenomInPeriod(periodStart, periodEnd)) * 100.0
    else 0.0

// =============================================================================
// Quarterly Statistics: 2024Q1 ~ 2026Q1（9 個季度）
// =============================================================================

define "2024Q1 Numer": IntegratedNumerInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Denom": IntegratedDenomInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate":  RateInPeriod(@2024-01-01, @2024-03-31)

define "2024Q2 Numer": IntegratedNumerInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Denom": IntegratedDenomInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate":  RateInPeriod(@2024-04-01, @2024-06-30)

define "2024Q3 Numer": IntegratedNumerInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Denom": IntegratedDenomInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate":  RateInPeriod(@2024-07-01, @2024-09-30)

define "2024Q4 Numer": IntegratedNumerInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Denom": IntegratedDenomInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate":  RateInPeriod(@2024-10-01, @2024-12-31)

define "2025Q1 Numer": IntegratedNumerInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Denom": IntegratedDenomInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate":  RateInPeriod(@2025-01-01, @2025-03-31)

define "2025Q2 Numer": IntegratedNumerInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Denom": IntegratedDenomInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate":  RateInPeriod(@2025-04-01, @2025-06-30)

define "2025Q3 Numer": IntegratedNumerInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Denom": IntegratedDenomInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate":  RateInPeriod(@2025-07-01, @2025-09-30)

define "2025Q4 Numer": IntegratedNumerInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Denom": IntegratedDenomInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate":  RateInPeriod(@2025-10-01, @2025-12-31)

define "2026Q1 Numer": IntegratedNumerInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Denom": IntegratedDenomInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate":  RateInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Indicator Result":
  Tuple {
    indicatorName:     '牙周整合治療完成率',
    indicatorCode:     '牙科-牙周整合治療完成率',
    unit:              '%',
    integratedCodes:   '91011C~91014C',
    numerator:         "2026Q1 Numer",
    denominator:       "2026Q1 Denom",
    rate:              "2026Q1 Rate",
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
