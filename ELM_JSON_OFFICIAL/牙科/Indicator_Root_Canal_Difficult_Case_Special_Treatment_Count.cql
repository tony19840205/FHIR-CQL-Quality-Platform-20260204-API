library Indicator_Root_Canal_Difficult_Case_Special_Treatment_Count version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 根管治療困難病例特殊治療件數
// 指標代碼: 牙科-根管困難病例
// 指標說明: 統計時間內根管治療困難病例特殊治療（90019C/90020C/90021C）之件數
// 指標類型: 件數統計（isCount=true，unit='次'）
//
// 適用療程代碼:
//   90019C: 根管治療困難病例特殊治療（第一次）
//   90020C: 根管治療困難病例特殊治療（第二次）
//   90021C: 根管治療困難病例特殊治療（其他）
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

// 困難病例特殊治療（90019C/90020C/90021C）
define function IsDifficultRootCanalProcedure(P FHIR.Procedure):
  GetProcedureCode(P) in { '90019C', '90020C', '90021C' }

define function ToDecimal(v Integer):
  v * 1.0

// =============================================================================
// Period-based Count Functions
// =============================================================================

define function CountInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsDifficultRootCanalProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )

// =============================================================================
// Quarterly Statistics: 2024Q1 ~ 2026Q1（9 個季度）
// =============================================================================

define "2024Q1 Count": CountInPeriod(@2024-01-01, @2024-03-31)
define "2024Q2 Count": CountInPeriod(@2024-04-01, @2024-06-30)
define "2024Q3 Count": CountInPeriod(@2024-07-01, @2024-09-30)
define "2024Q4 Count": CountInPeriod(@2024-10-01, @2024-12-31)
define "2025Q1 Count": CountInPeriod(@2025-01-01, @2025-03-31)
define "2025Q2 Count": CountInPeriod(@2025-04-01, @2025-06-30)
define "2025Q3 Count": CountInPeriod(@2025-07-01, @2025-09-30)
define "2025Q4 Count": CountInPeriod(@2025-10-01, @2025-12-31)
define "2026Q1 Count": CountInPeriod(@2026-01-01, @2026-03-31)

define "Total Count": "2026Q1 Count"

define "Indicator Result":
  Tuple {
    indicatorName:    '根管治療困難病例特殊治療件數',
    indicatorCode:    '牙科-根管困難病例',
    unit:             '次',
    isCount:          true,
    difficultCodes:   '90019C/90020C/90021C',
    totalCount:       "Total Count",
    quarters: List{
      Tuple { quarter: '2024Q1', count: "2024Q1 Count" },
      Tuple { quarter: '2024Q2', count: "2024Q2 Count" },
      Tuple { quarter: '2024Q3', count: "2024Q3 Count" },
      Tuple { quarter: '2024Q4', count: "2024Q4 Count" },
      Tuple { quarter: '2025Q1', count: "2025Q1 Count" },
      Tuple { quarter: '2025Q2', count: "2025Q2 Count" },
      Tuple { quarter: '2025Q3', count: "2025Q3 Count" },
      Tuple { quarter: '2025Q4', count: "2025Q4 Count" },
      Tuple { quarter: '2026Q1', count: "2026Q1 Count" }
    }
  }
