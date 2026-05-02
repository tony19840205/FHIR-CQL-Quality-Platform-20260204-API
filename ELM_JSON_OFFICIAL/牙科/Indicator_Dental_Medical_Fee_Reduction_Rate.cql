library Indicator_Dental_Medical_Fee_Reduction_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 牙醫門診醫療費用核減率 (14)
// 計算公式: 分子/分母
// 分子: 申請點數 - 核定點數
// 分母: 醫療費用點數（= 申請點數）
// 核減率 = (申請點數 - 核定點數) / 申請點數 × 100%
//
// 資料來源: 門診醫療費用統計檔，截至114/09/30止已完成核付之資料
// 資料範圍: 門診牙醫
// 製表日期: 114/10/28
// 製表單位: 衛生福利部 中央健康保險署

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function IsActiveEOB(EOB FHIR.ExplanationOfBenefit):
  EOB.status.value = 'active'

define function GetEOBDate(EOB FHIR.ExplanationOfBenefit):
  date from EOB.created

// 取得 EOB total 中指定類別（submitted/benefit）的金額
define function GetEOBAmountByCategory(EOB FHIR.ExplanationOfBenefit, catCode String):
  First(
    EOB.total T
      where exists(T.category.coding C where C.code.value = catCode)
  ).amount.value

// 申請點數（submitted）
define function GetSubmittedAmount(EOB FHIR.ExplanationOfBenefit):
  GetEOBAmountByCategory(EOB, 'submitted')

// 核定點數（benefit）
define function GetBenefitAmount(EOB FHIR.ExplanationOfBenefit):
  GetEOBAmountByCategory(EOB, 'benefit')

// =============================================================================
// Period-based Aggregation
// =============================================================================

// 申請點數合計（分母）
define function TotalSubmittedInPeriod(periodStart Date, periodEnd Date):
  Sum(
    [ExplanationOfBenefit] EOB
      where IsActiveEOB(EOB)
        and GetEOBDate(EOB) in Interval[periodStart, periodEnd]
        and GetSubmittedAmount(EOB) is not null
      return GetSubmittedAmount(EOB)
  )

// 核定點數合計
define function TotalBenefitInPeriod(periodStart Date, periodEnd Date):
  Sum(
    [ExplanationOfBenefit] EOB
      where IsActiveEOB(EOB)
        and GetEOBDate(EOB) in Interval[periodStart, periodEnd]
        and GetBenefitAmount(EOB) is not null
      return GetBenefitAmount(EOB)
  )

// 分母: 申請點數
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  TotalSubmittedInPeriod(periodStart, periodEnd)

// 分子: 申請點數 - 核定點數
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  if TotalSubmittedInPeriod(periodStart, periodEnd) is not null
    and TotalBenefitInPeriod(periodStart, periodEnd) is not null
    then TotalSubmittedInPeriod(periodStart, periodEnd) - TotalBenefitInPeriod(periodStart, periodEnd)
    else null

// 核減率 = (申請點數 - 核定點數) / 申請點數 × 100%
define function RateInPeriod(periodStart Date, periodEnd Date):
  if DenominatorInPeriod(periodStart, periodEnd) is not null
    and DenominatorInPeriod(periodStart, periodEnd) > 0
    then NumeratorInPeriod(periodStart, periodEnd) / DenominatorInPeriod(periodStart, periodEnd) * 100
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
    indicatorCode: 'DENTAL_FEE_REDUCTION',
    indicatorName: '牙醫門診醫療費用核減率',
    indicatorType: 'rate',
    unit: '%',
    denominatorCriteria: '醫療費用點數（申請點數）',
    numeratorCriteria: '申請點數-核定點數',
    formula: '(申請點數-核定點數)/申請點數×100%',
    dataSource: '門診醫療費用統計檔',
    dataRange: '門診牙醫',
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
