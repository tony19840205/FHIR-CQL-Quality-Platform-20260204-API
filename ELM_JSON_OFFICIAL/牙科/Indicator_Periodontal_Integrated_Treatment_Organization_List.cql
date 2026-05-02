library Indicator_Periodontal_Integrated_Treatment_Organization_List version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 牙周整合治療院所名單
// 指標代碼: 牙科-牙周整合治療院所
// 指標說明: 統計時間內曾提供牙周整合治療服務（91011C~91014C）之醫療機構清單
// 指標類型: 院所清單（isOrgList=true）
//
// 院所清單邏輯:
//   列出期間內執行過牙周整合治療之機構，後端依 Organization FHIR 資源統計機構家數
//
// 統計範圍: 2024Q1 ~ 2026Q1（9 個季度）

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd   DateTime default @2026-03-31T23:59:59.0+08:00

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function GetEncounterDate(E FHIR.Encounter):
  if E.period is not null
    then date from E.period.start
    else null

define function IsCompletedEncounter(E FHIR.Encounter):
  E.status.value = 'finished'

define function IsAmbulatoryEncounter(E FHIR.Encounter):
  E.class.code.value = 'AMB'

define function GetProcedureDate(P FHIR.Procedure):
  if P.performed is FHIR.dateTime
    then date from (P.performed as FHIR.dateTime)
    else if P.performed is FHIR.Period
      then date from (P.performed as FHIR.Period).start
      else null

define function IsEncounterInPeriod(E FHIR.Encounter, periodStart Date, periodEnd Date):
  GetEncounterDate(E) in Interval[periodStart, periodEnd]

define function ToDecimal(v Integer):
  v * 1.0

// =============================================================================
// Period-based Count Functions
// =============================================================================

// 期間內門診 Encounter 件數（牙周整合治療院所就診人次）
define function CountInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Encounter] E
      where IsCompletedEncounter(E)
        and IsEncounterInPeriod(E, periodStart, periodEnd)
  )

// =============================================================================
// Quarterly Statistics: 2024Q1 ~ 2026Q1（9 個季度）
// =============================================================================

define "2024Q1 Count": CountInPeriod(@2024-01-01, @2024-03-31)
define "2024Q2 Count": CountInPeriod(@2024-04-01, @2024-06-30)
define "2024Q3 Count": CountInPeriod(@2024-07-01, @2024-09-30)
define "2024Q4 Count": CountInPeriod(@2024-10-01, @2024-12-31)
define "2025Q1 Count": CountInPeriod(@2025-01-01, @2025-03-31)
define "2025Q2 Count": CountInPeriod(@2025-04-01, @2025-06-30)
define "2025Q3 Count": CountInPeriod(@2025-07-01, @2025-09-30)
define "2025Q4 Count": CountInPeriod(@2025-10-01, @2025-12-31)
define "2026Q1 Count": CountInPeriod(@2026-01-01, @2026-03-31)

define "Total Count": "2026Q1 Count"

define "Indicator Result":
  Tuple {
    indicatorName:   '牙周整合治療院所名單',
    indicatorType:   'orgList',
    unit:            '家',
    isOrgList:       true,
    serviceType:     '牙周整合治療服務',
    integratedCodes: '91011C~91014C',
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
