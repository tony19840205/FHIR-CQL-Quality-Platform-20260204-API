library Indicator_Oral_Cancer_Screening_Case_Count version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 口腔癌篩查件數
// 指標代碼: 牙科-口腔癌篩查
// 指標說明: 統計時間內接受口腔癌篩查（83002C/83003C/83004C）之就診人次
// 指標類型: 件數統計（isCount=true）
//
// 適用療程代碼:
//   83002C: 口腔黏膜檢查（一般）
//   83003C: 口腔黏膜檢查（高危險群）
//   83004C: 口腔黏膜病變追蹤
//
// 統計範圍: 2024Q1 ~ 2026Q1（9 個季度）

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd   DateTime default @2026-03-31T23:59:59.0+08:00

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

// 取得 Procedure 執行日期
define function GetProcedureDate(P FHIR.Procedure):
  if P.performed is FHIR.dateTime
    then date from (P.performed as FHIR.dateTime)
    else if P.performed is FHIR.Period
      then date from (P.performed as FHIR.Period).start
      else null

// 判斷 Procedure 狀態為 completed
define function IsCompletedProcedure(P FHIR.Procedure):
  P.status.value = 'completed'

// 取得 Procedure 主要療程代碼
define function GetProcedureCode(P FHIR.Procedure):
  Coalesce(First(P.code.coding C return C.code.value), '')

// 判斷是否為口腔癌篩查項目（83002C/83003C/83004C）
define function IsOralCancerScreeningProcedure(P FHIR.Procedure):
  GetProcedureCode(P) in { '83002C', '83003C', '83004C' }

// 整數轉 Decimal
define function ToDecimal(v Integer):
  v * 1.0

// =============================================================================
// Period-based Count Functions
// =============================================================================

// 期間內口腔癌篩查件數
define function CountInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsOralCancerScreeningProcedure(P)
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

// =============================================================================
// Summary
// =============================================================================

define "Total Count": "2026Q1 Count"

define "Indicator Result":
  Tuple {
    indicatorName:  '口腔癌篩查件數',
    indicatorCode:  '牙科-口腔癌篩查',
    unit:           '人次',
    isCount:        true,
    screenCodes:    '83002C/83003C/83004C',
    totalCount:     "Total Count",
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
