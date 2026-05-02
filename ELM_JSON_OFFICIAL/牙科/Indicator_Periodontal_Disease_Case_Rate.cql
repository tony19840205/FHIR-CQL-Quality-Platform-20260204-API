library Indicator_Periodontal_Disease_Case_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 牙周病病例率
// 指標代碼: 牙科-牙周病病例率
// 指標說明: 統計時間內門診就診者中，診斷為牙周病並接受牙周基本治療的比率
//
// 分母: 牙科門診就診 Encounter 件數
// 分子: 接受牙周基本治療（91003C~91007C）之不重複病人數
// 公式: (分子/分母) × 100%
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

define function IsPeriodontalBasicProcedure(P FHIR.Procedure):
  GetProcedureCode(P) in { '91003C', '91004C', '91005C', '91006C', '91007C' }

define function GetEncounterDate(E FHIR.Encounter):
  if E.period is not null
    then date from E.period.start
    else null

define function IsCompletedEncounter(E FHIR.Encounter):
  E.status.value = 'finished'

define function ToDecimal(v Integer):
  v * 1.0

// =============================================================================
// Period-based Rate Functions
// =============================================================================

// 分子: 期間內牙周基本治療件數
define function PerioNumerInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsPeriodontalBasicProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
  )

// 分母: 期間內門診 Encounter 件數
define function PerioDenomInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Encounter] E
      where IsCompletedEncounter(E)
        and GetEncounterDate(E) in Interval[periodStart, periodEnd]
  )

// 指標率: (分子/分母) × 100，0 除保護
define function RateInPeriod(periodStart Date, periodEnd Date):
  if PerioDenomInPeriod(periodStart, periodEnd) > 0
    then ToDecimal(PerioNumerInPeriod(periodStart, periodEnd)) / ToDecimal(PerioDenomInPeriod(periodStart, periodEnd)) * 100.0
    else 0.0

// =============================================================================
// Quarterly Statistics: 2024Q1 ~ 2026Q1（9 個季度）
// =============================================================================

define "2024Q1 Numer": PerioNumerInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Denom": PerioDenomInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate":  RateInPeriod(@2024-01-01, @2024-03-31)

define "2024Q2 Numer": PerioNumerInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Denom": PerioDenomInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate":  RateInPeriod(@2024-04-01, @2024-06-30)

define "2024Q3 Numer": PerioNumerInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Denom": PerioDenomInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate":  RateInPeriod(@2024-07-01, @2024-09-30)

define "2024Q4 Numer": PerioNumerInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Denom": PerioDenomInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate":  RateInPeriod(@2024-10-01, @2024-12-31)

define "2025Q1 Numer": PerioNumerInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Denom": PerioDenomInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate":  RateInPeriod(@2025-01-01, @2025-03-31)

define "2025Q2 Numer": PerioNumerInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Denom": PerioDenomInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate":  RateInPeriod(@2025-04-01, @2025-06-30)

define "2025Q3 Numer": PerioNumerInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Denom": PerioDenomInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate":  RateInPeriod(@2025-07-01, @2025-09-30)

define "2025Q4 Numer": PerioNumerInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Denom": PerioDenomInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate":  RateInPeriod(@2025-10-01, @2025-12-31)

define "2026Q1 Numer": PerioNumerInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Denom": PerioDenomInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate":  RateInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Indicator Result":
  Tuple {
    indicatorName:    '牙周病病例率',
    indicatorCode:    '牙科-牙周病病例率',
    unit:             '%',
    periodontalCodes: '91003C~91007C',
    numerator:        "2026Q1 Numer",
    denominator:      "2026Q1 Denom",
    rate:             "2026Q1 Rate",
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
