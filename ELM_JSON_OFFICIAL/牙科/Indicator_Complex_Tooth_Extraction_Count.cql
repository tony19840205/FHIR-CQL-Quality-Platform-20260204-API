library Indicator_Complex_Tooth_Extraction_Count version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 複雜拔牙案件數
// 指標類型: 計件（案件數）
// 資料範圍: 牙科門診，複雜拔牙（手術拔牙）醫令案件
// 計算公式: 統計期間內執行複雜拔牙醫令之案件數（不重複）
//
// 複雜拔牙醫令代碼:
//   92016C - 手術切開拔牙（複雜拔牙）
//
// 排除: 無特別排除條件（以醫令代碼為主）
// 統計範圍: 2024Q1 ~ 2026Q1 (9 個季度)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// ============================================
// Helper Functions
// ============================================

define function GetProcedureDate(P FHIR.Procedure):
  case
    when P.performed is FHIR.dateTime then date from (P.performed as FHIR.dateTime)
    when P.performed is FHIR.Period then date from (P.performed as FHIR.Period).start
    else null
  end

define function IsComplexExtractionProcedure(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value = '92016C'
  )

define function IsCompletedProcedure(P FHIR.Procedure):
  P.status.value = 'completed'

// ============================================
// Base Resources
// ============================================

define "All Complex Extraction Procedures":
  [Procedure] P
    where IsCompletedProcedure(P)
      and IsComplexExtractionProcedure(P)

// ============================================
// Period-based Count Functions
// ============================================

define function CountInPeriod(periodStart Date, periodEnd Date):
  Count(
    "All Complex Extraction Procedures" P
      where GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1, 9 quarters)
// ============================================

define "2024Q1 Count": CountInPeriod(@2024-01-01, @2024-03-31)
define "2024Q2 Count": CountInPeriod(@2024-04-01, @2024-06-30)
define "2024Q3 Count": CountInPeriod(@2024-07-01, @2024-09-30)
define "2024Q4 Count": CountInPeriod(@2024-10-01, @2024-12-31)
define "2025Q1 Count": CountInPeriod(@2025-01-01, @2025-03-31)
define "2025Q2 Count": CountInPeriod(@2025-04-01, @2025-06-30)
define "2025Q3 Count": CountInPeriod(@2025-07-01, @2025-09-30)
define "2025Q4 Count": CountInPeriod(@2025-10-01, @2025-12-31)
define "2026Q1 Count": CountInPeriod(@2026-01-01, @2026-03-31)

// ============================================
// Summary
// ============================================

define "Total Count": "2026Q1 Count"

define "Indicator Result":
  Tuple {
    indicatorCode: '牙科-複雜拔牙',
    indicatorName: '複雜拔牙案件數',
    indicatorType: 'count',
    unit: '次',
    procedureCode: '92016C',
    procedureName: '手術切開拔牙（複雜拔牙）',
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
