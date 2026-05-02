library Indicator_Root_Canal_Treatment_Retention_Rate_Primary_Tooth_3Months version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 根管治療保存率（乳牙 3 個月）
// 指標代碼: 牙科-根管乳牙3月保存率
// 指標說明: 乳牙（FDI 51-85）根管治療後，3 個月內未再次根管治療的比率
//
// 分母: 期間內乳牙根管治療（充填完成）件數
// 分子: 分母中，根管充填後 3 個月內未重新根管治療者
// 公式: (分子/分母) × 100%
//
// 乳牙 FDI 牙位: 51-55, 61-65, 71-75, 81-85
// 根管充填（完成）代碼: 90005C
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

// 乳牙（FDI 51-85）
define function IsPrimaryTooth(toothCode String):
  toothCode in {
    '51','52','53','54','55',
    '61','62','63','64','65',
    '71','72','73','74','75',
    '81','82','83','84','85'
  }

define function ToDecimal(v Integer):
  v * 1.0

// 乳牙根管充填後 3 個月內是否再次根管治療
define function HasRetreatedWithin3Months(toothCode String, fillDate Date):
  exists(
    [Procedure] P2
      where IsCompletedProcedure(P2)
        and IsRootCanalProcedure(P2)
        and GetBodySiteCode(P2) = toothCode
        and GetProcedureDate(P2) in Interval[fillDate, fillDate + 3 months]
        and GetProcedureDate(P2) != fillDate
  )

// =============================================================================
// Period-based Rate Functions
// =============================================================================

// 分子: 乳牙根管充填後 3 個月內未再次治療者
define function RetentionNumerInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsRootCanalFillProcedure(P)
        and IsPrimaryTooth(GetBodySiteCode(P))
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and not HasRetreatedWithin3Months(GetBodySiteCode(P), GetProcedureDate(P))
  )

// 分母: 期間內乳牙根管充填件數
define function RetentionDenomInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsRootCanalFillProcedure(P)
        and IsPrimaryTooth(GetBodySiteCode(P))
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
    indicatorName:  '根管治療保存率（乳牙3個月）',
    indicatorCode:  '牙科-根管乳牙3月保存率',
    unit:           '%',
    toothType:      '乳牙 FDI 51-85',
    trackingWindow: '3 個月',
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
