library Indicator_Root_Canal_Treatment_Retention_Rate_Within_6Months version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 根管治療保存率（6 個月內，所有牙齒）
// 指標代碼: 牙科-根管6月保存率
// 指標說明: 根管治療充填完成後，6 個月內未再次接受根管治療的比率（含恆乳牙）
//
// 分母: 期間內根管充填完成（90005C）件數（所有牙）
// 分子: 分母中，充填後 6 個月內未重新根管治療者
// 公式: (分子/分母) × 100%
//
// 根管充填代碼: 90005C
// 任何根管治療代碼: 90001C~90020C
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

define function GetBodySiteCode(P FHIR.Procedure):
  Coalesce(First(flatten(P.bodySite BS return (BS.coding C return C.code.value))), '')

// 根管充填完成（90005C）
define function IsRootCanalFillProcedure(P FHIR.Procedure):
  GetProcedureCode(P) = '90005C'

// 任何根管治療
define function IsRootCanalProcedure(P FHIR.Procedure):
  GetProcedureCode(P) in {
    '90001C', '90002C', '90003C', '90004C', '90005C',
    '90015C', '90016C', '90017C', '90018C', '90019C', '90020C'
  }

define function ToDecimal(v Integer):
  v * 1.0

// 根管充填後 6 個月內是否再次根管治療（同牙位）
define function HasRetreatedWithin6Months(toothCode String, fillDate Date):
  exists(
    [Procedure] P2
      where IsCompletedProcedure(P2)
        and IsRootCanalProcedure(P2)
        and GetBodySiteCode(P2) = toothCode
        and GetProcedureDate(P2) in Interval[fillDate, fillDate + 6 months]
        and GetProcedureDate(P2) != fillDate
  )

// =============================================================================
// Period-based Rate Functions
// =============================================================================

// 分子: 根管充填後 6 個月內未再次治療者（所有牙）
define function RetentionNumerInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsRootCanalFillProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and not HasRetreatedWithin6Months(GetBodySiteCode(P), GetProcedureDate(P))
  )

// 分母: 期間內根管充填件數（所有牙）
define function RetentionDenomInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsRootCanalFillProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )

// 指標率: (分子/分母) × 100，0 除保護
define function RateInPeriod(periodStart Date, periodEnd Date):
  if RetentionDenomInPeriod(periodStart, periodEnd) > 0
    then ToDecimal(RetentionNumerInPeriod(periodStart, periodEnd)) / ToDecimal(RetentionDenomInPeriod(periodStart, periodEnd)) * 100.0
    else 0.0

// =============================================================================
// Quarterly Statistics: 2024Q1 ~ 2026Q1（9 個季度）
// =============================================================================

define "2024Q1 Numer": RetentionNumerInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Denom": RetentionDenomInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate":  RateInPeriod(@2024-01-01, @2024-03-31)

define "2024Q2 Numer": RetentionNumerInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Denom": RetentionDenomInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate":  RateInPeriod(@2024-04-01, @2024-06-30)

define "2024Q3 Numer": RetentionNumerInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Denom": RetentionDenomInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate":  RateInPeriod(@2024-07-01, @2024-09-30)

define "2024Q4 Numer": RetentionNumerInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Denom": RetentionDenomInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate":  RateInPeriod(@2024-10-01, @2024-12-31)

define "2025Q1 Numer": RetentionNumerInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Denom": RetentionDenomInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate":  RateInPeriod(@2025-01-01, @2025-03-31)

define "2025Q2 Numer": RetentionNumerInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Denom": RetentionDenomInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate":  RateInPeriod(@2025-04-01, @2025-06-30)

define "2025Q3 Numer": RetentionNumerInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Denom": RetentionDenomInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate":  RateInPeriod(@2025-07-01, @2025-09-30)

define "2025Q4 Numer": RetentionNumerInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Denom": RetentionDenomInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate":  RateInPeriod(@2025-10-01, @2025-12-31)

define "2026Q1 Numer": RetentionNumerInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Denom": RetentionDenomInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate":  RateInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Indicator Result":
  Tuple {
    indicatorName:  '根管治療保存率（6個月內）',
    indicatorCode:  '牙科-根管6月保存率',
    unit:           '%',
    toothType:      '所有牙齒',
    trackingWindow: '6 個月',
    numerator:      "2026Q1 Numer",
    denominator:    "2026Q1 Denom",
    rate:           "2026Q1 Rate",
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
