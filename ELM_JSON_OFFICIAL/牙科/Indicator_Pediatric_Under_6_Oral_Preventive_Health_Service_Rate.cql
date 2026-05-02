library Indicator_Pediatric_Under_6_Oral_Preventive_Health_Service_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 1747 (季)、1748 (年)
// 指標名稱: 6歲以下牙醫就醫兒童牙齒預防保健服務人數比率
// 計算公式: 分子/分母 × 100%
//
// 分母: 當季就醫人口中6歲以下兒童人數
// 分子: 執行兒童牙齒預防保健服務之人數
//   ※ 兒童牙齒預防保健服務為健保卡序號欄位為「IC81」、「IC87」
//
// 年齡計算: 就醫年-出生年月 ≤ 72個月
// 統計範圍: 2024Q1 ~ 2026Q1 (9 個季度)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetEncounterDate(E FHIR.Encounter):
  date from E.period.start

// 年齡計算: 就醫年月 - 出生年月 <= 72個月（依官方規格）
define function IsUnder72MonthsAt(visitDate Date):
  months between Patient.birthDate and visitDate <= 72

// 判斷 Encounter 是否包含兒童牙齒預防保健服務（IC81 或 IC87）
define function IsChildPreventiveHealthEncounter(E FHIR.Encounter):
  exists(
    E.type T
      where exists(
        T.coding C
          where C.code.value in { 'IC81', 'IC87' }
      )
  )

// 判斷病患於期間內是否有6歲以下牙醫就醫 Encounter
define function HasDentalEncounterUnder72Months(periodStart Date, periodEnd Date):
  exists(
    [Encounter] E
      where E.status.value = 'finished'
        and GetEncounterDate(E) in Interval[periodStart, periodEnd]
        and IsUnder72MonthsAt(GetEncounterDate(E))
  )

// =============================================================================
// Period-based Count Functions (人數)
// =============================================================================

// 分母: 此病患於期間內是否為6歲以下就醫兒童（1 或 0）
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  if HasDentalEncounterUnder72Months(periodStart, periodEnd)
  then 1
  else 0

// 分子: 此病患於期間內是否為執行兒童牙齒預防保健服務（IC81/IC87）之6歲以下兒童（1 或 0）
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  if exists(
    [Encounter] E
      where E.status.value = 'finished'
        and GetEncounterDate(E) in Interval[periodStart, periodEnd]
        and IsUnder72MonthsAt(GetEncounterDate(E))
        and IsChildPreventiveHealthEncounter(E)
  )
  then 1
  else 0

// 兒童牙齒預防保健服務比率 = (分子/分母) × 100%
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
    indicatorCode: '1747',
    indicatorCodeYear: '1748',
    indicatorName: '6歲以下牙醫就醫兒童牙齒預防保健服務人數比率',
    indicatorType: 'rate',
    unit: '%',
    ageGroup: '6歲以下（就醫年-出生年月≤72個月）',
    denominatorCriteria: '當季就醫人口中6歲以下兒童人數',
    numeratorCriteria: '健保卡序號IC81或IC87之兒童牙齒預防保健服務人數',
    preventiveServiceCodes: 'IC81, IC87',
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