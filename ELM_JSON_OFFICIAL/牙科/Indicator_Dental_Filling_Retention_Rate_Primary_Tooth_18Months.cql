library Indicator_Dental_Filling_Retention_Rate_Primary_Tooth_18Months version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 乳牙牙體復形18個月保存率
// 指標說明: 乳牙填補後追蹤18個月內未重補之牙位比率（保存率）
// 計算公式: [1 - (分子/分母)] × 100%  等價於  (未重補牙位數/總牙位數) × 100%
//
// 分母: 同院所同保險對象同一乳牙牙位，統計執行牙體復形之牙位數
//       若同案件同牙位執行 2 筆以上，該牙位仍視為 1
// 分子（保存）: 分母牙位中，自填補日起 18 個月（540 天）內
//              未於不同就醫日期重覆執行牙體復形醫令之牙位數
//
// 牙體復形醫令代碼:
//   89001C, 89002C, 89003C, 89004C, 89005C,
//   89008C, 89009C, 89010C, 89011C, 89012C, 89014C, 89015C
//
// 排除代碼（全民健保牙醫門診總額特殊計畫/化療/放療患者）:
//   89101C~89105C, 89108C~89112C, 89114C, 89115C
//   ← 僅使用上列有效代碼，排除代碼不納入 IsPrimaryFillingProcedure
//
// 乳牙 FDI 牙位範圍: 51-55, 61-65, 71-75, 81-85（共 20 顆）
//
// 統計範圍: 2024Q1 ~ 2026Q1（9 個季度）

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd   DateTime default @2026-03-31T23:59:59.0+08:00

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

// 整數轉 Decimal，用於除法避免整數截斷
define function ToDecimal(v Integer):
  v * 1.0

// 取得 Procedure 執行日期（支援 dateTime 與 Period 兩種格式）
define function GetProcedureDate(P FHIR.Procedure):
  case
    when P.performed is FHIR.dateTime then date from (P.performed as FHIR.dateTime)
    when P.performed is FHIR.Period   then date from (P.performed as FHIR.Period).start
    else null
  end

// 判斷 Procedure 狀態為 completed
define function IsCompletedProcedure(P FHIR.Procedure):
  P.status.value = 'completed'

// 牙體復形醫令判斷（89001C~89015C 有效範圍；排除代碼 89101C+ 不納入）
define function IsPrimaryFillingProcedure(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value in {
        '89001C', '89002C', '89003C', '89004C', '89005C',
        '89008C', '89009C', '89010C', '89011C', '89012C',
        '89014C', '89015C'
      }
  )

// 取得 FDI 牙位代碼（來自 Procedure.bodySite.coding.code）
define function GetBodySiteCode(P FHIR.Procedure):
  Coalesce(
    First(flatten(P.bodySite BS return (BS.coding C return C.code.value))),
    ''
  )

// 乳牙 FDI 牙位範圍: 51-55, 61-65, 71-75, 81-85
define function IsPrimaryTooth(toothCode String):
  toothCode in {
    '51', '52', '53', '54', '55',
    '61', '62', '63', '64', '65',
    '71', '72', '73', '74', '75',
    '81', '82', '83', '84', '85'
  }

// 判斷特定乳牙牙位於填補日 fillDate 之後 18 個月內是否有重補
// 重補定義：不同就醫日期（fillDate 之後至 fillDate + 18 months）再次執行牙體復形
define function HasRefillWithin18Months(toothCode String, fillDate Date):
  exists(
    [Procedure] P2
      where IsCompletedProcedure(P2)
        and IsPrimaryFillingProcedure(P2)
        and GetBodySiteCode(P2) = toothCode
        and GetProcedureDate(P2) in Interval[fillDate, fillDate + 18 months]
        and GetProcedureDate(P2) != fillDate
  )

// =============================================================================
// Period-based Count Functions
// =============================================================================

// 分母: 期間內乳牙牙體復形執行牙位數（FDI 51-85）
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsPrimaryFillingProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and IsPrimaryTooth(GetBodySiteCode(P))
  )

// 分子（保存）: 期間內 18 個月未重補之乳牙牙位數
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsPrimaryFillingProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and IsPrimaryTooth(GetBodySiteCode(P))
        and not HasRefillWithin18Months(GetBodySiteCode(P), GetProcedureDate(P))
  )

// 18 個月保存率 = (未重補牙位數 / 總牙位數) × 100%
// 等價於 [1 - (重補牙位數 / 總牙位數)] × 100%
define function RateInPeriod(periodStart Date, periodEnd Date):
  if DenominatorInPeriod(periodStart, periodEnd) > 0
    then (ToDecimal(NumeratorInPeriod(periodStart, periodEnd)) / ToDecimal(DenominatorInPeriod(periodStart, periodEnd))) * 100
    else null

// =============================================================================
// Quarterly Statistics: 2024Q1 ~ 2026Q1（9 個季度）
// =============================================================================

define "2024Q1 Denominator": DenominatorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Numerator":   NumeratorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate":        RateInPeriod(@2024-01-01, @2024-03-31)

define "2024Q2 Denominator": DenominatorInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Numerator":   NumeratorInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate":        RateInPeriod(@2024-04-01, @2024-06-30)

define "2024Q3 Denominator": DenominatorInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Numerator":   NumeratorInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate":        RateInPeriod(@2024-07-01, @2024-09-30)

define "2024Q4 Denominator": DenominatorInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Numerator":   NumeratorInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate":        RateInPeriod(@2024-10-01, @2024-12-31)

define "2025Q1 Denominator": DenominatorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Numerator":   NumeratorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate":        RateInPeriod(@2025-01-01, @2025-03-31)

define "2025Q2 Denominator": DenominatorInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Numerator":   NumeratorInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate":        RateInPeriod(@2025-04-01, @2025-06-30)

define "2025Q3 Denominator": DenominatorInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Numerator":   NumeratorInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate":        RateInPeriod(@2025-07-01, @2025-09-30)

define "2025Q4 Denominator": DenominatorInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Numerator":   NumeratorInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate":        RateInPeriod(@2025-10-01, @2025-12-31)

define "2026Q1 Denominator": DenominatorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Numerator":   NumeratorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate":        RateInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Total Denominator": "2026Q1 Denominator"
define "Total Numerator":   "2026Q1 Numerator"
define "Overall Rate":      "2026Q1 Rate"

define "Indicator Result":
  Tuple {
    indicatorName:        '乳牙牙體復形18個月保存率',
    indicatorType:        'rate',
    unit:                 '%',
    trackingWindow:       '18 months',
    fillingCodes:         '89001C~89005C, 89008C~89012C, 89014C, 89015C',
    toothScope:           '乳牙 FDI 51-55, 61-65, 71-75, 81-85',
    denominatorCriteria:  '期間內乳牙牙體復形牙位數',
    numeratorCriteria:    '18 個月未重補之乳牙牙位數',
    quarters: List{
      Tuple { quarter: '2024Q1', denominator: "2024Q1 Denominator", numerator: "2024Q1 Numerator", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', denominator: "2024Q2 Denominator", numerator: "2024Q2 Numerator", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', denominator: "2024Q3 Denominator", numerator: "2024Q3 Numerator", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', denominator: "2024Q4 Denominator", numerator: "2024Q4 Numerator", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', denominator: "2025Q1 Denominator", numerator: "2025Q1 Numerator", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', denominator: "2025Q2 Denominator", numerator: "2025Q2 Numerator", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', denominator: "2025Q3 Denominator", numerator: "2025Q3 Numerator", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', denominator: "2025Q4 Denominator", numerator: "2025Q4 Numerator", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', denominator: "2026Q1 Denominator", numerator: "2026Q1 Numerator", rate: "2026Q1 Rate" }
    }
  }
