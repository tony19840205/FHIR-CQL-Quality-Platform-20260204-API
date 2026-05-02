library Indicator_Periodontal_Integrated_Treatment_Followup_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 2477 (季)、2478 (年)
// 指標名稱: 牙周病統合治療方案後之追蹤治療率
// 計算公式: 分子/分母 × 100%
//
// 分母: 牙周病統合治療第三階段支付91023C執行人數
// 分子: 91023C執行後追蹤一年內接受牙周病支持性治療(91018C)之人數
//
// ※往後追蹤一年定義：
//   0 ≤ (91018C就醫日期 - 91023C治療結束日(若空值則取就醫日期)) ≤ 365天
//
// 資料來源: 醫療給付檔案分析系統，指標代碼：2477 (季)、2478 (年)
// 製表日期: 114/10/28

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function ToDecimal(v Integer):
  v * 1.0

// 取得 Procedure 執行/就醫日期（開始日）
define function GetProcedureDate(P FHIR.Procedure):
  if P.performed is FHIR.dateTime
    then date from (P.performed as FHIR.dateTime)
    else if P.performed is FHIR.Period
      then date from (P.performed as FHIR.Period).start
      else null

// 取得 Procedure 治療結束日（優先取 Period.end，空值取開始日）
define function GetProcedureEndDate(P FHIR.Procedure):
  if P.performed is FHIR.Period
    then date from (P.performed as FHIR.Period).end
    else if P.performed is FHIR.dateTime
      then date from (P.performed as FHIR.dateTime)
      else null

// 判斷 Procedure 已完成
define function IsCompletedProcedure(P FHIR.Procedure):
  P.status.value = 'completed'

// 判斷 Procedure 含指定醫令碼
define function HasProcedureCode(P FHIR.Procedure, targetCode String):
  exists(
    P.code.coding C
      where C.code.value = targetCode
  )

// =============================================================================
// Period-based Count Functions (人數: 1 or 0)
// =============================================================================

// 分母: 此病患於期間內是否有執行91023C（1 或 0）
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  if exists(
    [Procedure] P
      where IsCompletedProcedure(P)
        and HasProcedureCode(P, '91023C')
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )
  then 1
  else 0

// 分子: 期間內有91023C，且往後一年內（0~365天）有91018C（1 或 0）
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  if exists(
    [Procedure] P91023
      where IsCompletedProcedure(P91023)
        and HasProcedureCode(P91023, '91023C')
        and GetProcedureDate(P91023) in Interval[periodStart, periodEnd]
        and GetProcedureEndDate(P91023) is not null
        and exists(
          [Procedure] P91018
            where IsCompletedProcedure(P91018)
              and HasProcedureCode(P91018, '91018C')
              and GetProcedureDate(P91018) is not null
              and days between GetProcedureEndDate(P91023) and GetProcedureDate(P91018) >= 0
              and days between GetProcedureEndDate(P91023) and GetProcedureDate(P91018) <= 365
        )
  )
  then 1
  else 0

// 追蹤治療率 = (分子/分母) × 100%
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
    indicatorCode: '2477',
    indicatorCodeYear: '2478',
    indicatorName: '牙周病統合治療方案後之追蹤治療率',
    indicatorType: 'rate',
    unit: '%',
    denominatorCriteria: '牙周病統合治療第三階段支付91023C執行人數',
    numeratorCriteria: '91023C後一年內(0~365天)接受牙周病支持性治療91018C之人數',
    thirdPhaseTreatmentCode: '91023C',
    supportiveTreatmentCode: '91018C',
    followupDays: 365,
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