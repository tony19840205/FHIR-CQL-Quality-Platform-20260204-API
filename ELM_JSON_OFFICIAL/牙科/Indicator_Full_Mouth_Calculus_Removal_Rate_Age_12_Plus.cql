library Indicator_Full_Mouth_Calculus_Removal_Rate_Age_12_Plus version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 3233 (季)、3234 (年)
// 指標名稱: 12歲以上牙醫就醫病人全口牙結石清除率
// 計算公式: 分子/分母 × 100%
//
// 分母: 當季12歲(含)以上就醫人數
// 分子: 當季12歲(含)以上就醫人口中執行牙結石清除 - 全口醫令
//   (91004C、91104C、91005C、91017C、91089C、91090C) 之人數
//
// 年齡計算: 就醫年份 - 出生年 >= 12
// 統計範圍: 2024Q1 ~ 2026Q1 (9 個季度)
//
// 備註: 依據衛生福利部114年3月31日衛部保字第1140112287號公告修訂附表
//       指標分子定義修改（原代碼 91001C/91002C 改為上述 6 個代碼）

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetProcedureDate(P FHIR.Procedure):
  case
    when P.performed is FHIR.dateTime then date from (P.performed as FHIR.dateTime)
    when P.performed is FHIR.Period then date from (P.performed as FHIR.Period).start
    else null
  end

define function IsCompletedProcedure(P FHIR.Procedure):
  P.status.value = 'completed'

// 全口牙結石清除醫令（依114年3月31日修訂後版本）
define function IsCalcusRemovalProcedure(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value in {
        '91004C', '91104C', '91005C', '91017C', '91089C', '91090C'
      }
  )

// 年齡計算: 就醫年份 - 出生年 >= 12 (依官方規格)
define function IsAge12PlusInYear(visitDate Date):
  (year from visitDate - year from Patient.birthDate) >= 12

// =============================================================================
// Period-based Count Functions (人數)
// =============================================================================

// 分母: 此病患於期間內是否為12歲以上就醫人數（1 或 0）
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  if exists(
    [Encounter] E
      where E.status.value = 'finished'
        and (date from E.period.start) in Interval[periodStart, periodEnd]
        and IsAge12PlusInYear(date from E.period.start)
  )
  then 1
  else 0

// 分子: 此病患於期間內是否為執行全口牙結石清除之12歲以上人數（1 或 0）
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  if exists(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsCalcusRemovalProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and IsAge12PlusInYear(GetProcedureDate(P))
  )
  then 1
  else 0

// 牙結石清除率 = (分子/分母) x 100%
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
    indicatorCode: '3233',
    indicatorCodeYear: '3234',
    indicatorName: '12歲以上牙醫就醫病人全口牙結石清除率',
    indicatorType: 'rate',
    unit: '%',
    ageGroup: '12歲(含)以上（就醫年份-出生年>=12）',
    denominatorCriteria: '當季12歲以上就醫人數',
    numeratorCriteria: '執行全口牙結石清除(91004C/91104C/91005C/91017C/91089C/91090C)之人數',
    calculusCodes: '91004C, 91104C, 91005C, 91017C, 91089C, 91090C',
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