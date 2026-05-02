library Indicator_Dental_Enhanced_Infection_Control_Consultation_Fee_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 813 (季)、814 (年)
// 指標名稱: 院所牙醫門診加強感染管制實施方案診察費申報率
// 計算公式: 分子/分母 × 100%
//
// 分母: 統計期間內有申報費用(申請金額>0)之總院所數
// 分子: 申報符合加強感染管制實施方案之牙科門診診察費的院所數
//   ※符合下列任一條件者計入分子院所數：
//     (1) 處方檔「診察費項目代號」in {00305C,00306C,00307C,00308C,00309C,00310C} 且診察費>0
//     (2) 醫令檔「醫令代碼」in {00305C,00306C,00307C,00308C,00309C,00310C} 且醫令金額>0
// 資料來源: 醫療給付檔案分析系統，指標代碼：813, 814
// 資料範圍: 牙醫門診有申報費用之院所
// 製表日期: 114/10/28

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetEncounterDate(E FHIR.Encounter):
  date from E.period.start

define function GetProcedureDate(P FHIR.Procedure):
  date from (P.performed as FHIR.dateTime)

// 判斷 Encounter 的 type coding 是否含有加強感染管制診察費醫令碼
define function IsInfectionControlEncounterType(E FHIR.Encounter):
  exists(
    E.type T
      where exists(
        T.coding C
          where C.code.value in { '00305C', '00306C', '00307C', '00308C', '00309C', '00310C' }
      )
  )

// 判斷 Procedure 是否含有加強感染管制醫令碼
define function IsInfectionControlProcedure(P FHIR.Procedure):
  P.status.value = 'completed'
    and exists(
      P.code.coding C
        where C.code.value in { '00305C', '00306C', '00307C', '00308C', '00309C', '00310C' }
    )

// =============================================================================
// Period-based Count Functions (院所數/人數)
// =============================================================================

// 分母: 此病患於期間內是否有牙醫門診就醫（1 或 0）
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  if exists(
    [Encounter] E
      where E.status.value = 'finished'
        and GetEncounterDate(E) in Interval[periodStart, periodEnd]
  )
  then 1
  else 0

// 分子: 此病患於期間內是否有申報加強感染管制相關醫令（1 或 0）
// 符合條件：Encounter.type 含感染管制碼，或 Procedure.code 含感染管制碼
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  if (
    exists(
      [Encounter] E
        where E.status.value = 'finished'
          and GetEncounterDate(E) in Interval[periodStart, periodEnd]
          and IsInfectionControlEncounterType(E)
    )
    or exists(
      [Procedure] P
        where IsInfectionControlProcedure(P)
          and GetProcedureDate(P) in Interval[periodStart, periodEnd]
    )
  )
  then 1
  else 0

// 申報率 = (分子/分母) × 100%
define function RateInPeriod(periodStart Date, periodEnd Date):
  if DenominatorInPeriod(periodStart, periodEnd) > 0
    then ToDecimal(NumeratorInPeriod(periodStart, periodEnd)) / ToDecimal(DenominatorInPeriod(periodStart, periodEnd)) * 100
    else null

// =============================================================================
// Quarterly Statistics (2024Q1 ~ 2026Q1, 9 quarters)
// =============================================================================

define "2024Q1 Denominator": DenominatorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Numerator": NumeratorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate": RateInPeriod(@2024-01-01, @2024-03-31)

define "2024Q2 Denominator": DenominatorInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Numerator": NumeratorInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate": RateInPeriod(@2024-04-01, @2024-06-30)

define "2024Q3 Denominator": DenominatorInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Numerator": NumeratorInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate": RateInPeriod(@2024-07-01, @2024-09-30)

define "2024Q4 Denominator": DenominatorInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Numerator": NumeratorInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate": RateInPeriod(@2024-10-01, @2024-12-31)

define "2025Q1 Denominator": DenominatorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Numerator": NumeratorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate": RateInPeriod(@2025-01-01, @2025-03-31)

define "2025Q2 Denominator": DenominatorInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Numerator": NumeratorInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate": RateInPeriod(@2025-04-01, @2025-06-30)

define "2025Q3 Denominator": DenominatorInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Numerator": NumeratorInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate": RateInPeriod(@2025-07-01, @2025-09-30)

define "2025Q4 Denominator": DenominatorInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Numerator": NumeratorInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate": RateInPeriod(@2025-10-01, @2025-12-31)

define "2026Q1 Denominator": DenominatorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Numerator": NumeratorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate": RateInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Total Denominator": "2026Q1 Denominator"
define "Total Numerator": "2026Q1 Numerator"
define "Overall Rate": "2026Q1 Rate"

define "Indicator Result":
  Tuple {
    indicatorCode: '813',
    indicatorCodeYear: '814',
    indicatorName: '院所牙醫門診加強感染管制實施方案診察費申報率',
    indicatorType: 'rate',
    unit: '%',
    denominatorCriteria: '統計期間內有申報費用(申請金額>0)之總院所數',
    numeratorCriteria: '申報加強感染管制實施方案之牙科門診診察費(00305C~00310C)之院所數',
    infectionControlCodes: '00305C, 00306C, 00307C, 00308C, 00309C, 00310C',
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
    }
  }