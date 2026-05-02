library Indicator_Dental_Outpatient_Patient_Count_Age_50_Plus version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 2510 (季)、2511 (年)
// 指標名稱: 牙醫門診50歲以上(含)就醫人數
// 計算公式: 牙醫門診50歲以上(含)就醫人數（純計數，無分母）
//
// 年齡計算: 費用年月 - 出生年月，取統計期間之最大值 >= 600個月（50年）
// 統計單位: 人數（每位病患 1 或 0）
// 資料來源: 醫療給付檔案分析系統，指標代碼：2510 (季)、2511 (年)
// 資料範圍: 牙醫門診50歲以上(含)就醫人數
// 製表日期: 114/10/28

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

// 取得 Encounter 就醫日期
define function GetEncounterDate(E FHIR.Encounter):
  date from E.period.start

// 年齡計算（月數）: 費用年月 - 出生年月
define function AgeInMonthsAt(visitDate Date):
  months between Patient.birthDate and visitDate

// 取統計期間內所有就醫的最大年齡月數（依官方規格：取統計期間之最大值）
define function MaxAgeInMonthsInPeriod(periodStart Date, periodEnd Date):
  Max(
    ( [Encounter] E
        where E.status.value = 'finished'
          and GetEncounterDate(E) in Interval[periodStart, periodEnd]
        return AgeInMonthsAt(GetEncounterDate(E))
    )
  )

// 判斷病患於期間內是否為50歲以上（最大年齡月數 >= 600個月）
define function IsAge50PlusInPeriod(periodStart Date, periodEnd Date):
  MaxAgeInMonthsInPeriod(periodStart, periodEnd) >= 600

// 是否於期間內有牙醫門診就醫
define function HasDentalEncounterInPeriod(periodStart Date, periodEnd Date):
  exists(
    [Encounter] E
      where E.status.value = 'finished'
        and GetEncounterDate(E) in Interval[periodStart, periodEnd]
  )

// =============================================================================
// Period-based Count Function (人數: 1 or 0)
// =============================================================================

// 牙醫門診50歲以上就醫人數（1 = 符合，0 = 不符合）
define function PatientCountInPeriod(periodStart Date, periodEnd Date):
  if HasDentalEncounterInPeriod(periodStart, periodEnd)
    and IsAge50PlusInPeriod(periodStart, periodEnd)
  then 1
  else 0

// =============================================================================
// Quarterly Statistics (2024Q1 ~ 2026Q1, 9 quarters)
// =============================================================================

define "2024Q1 Patient Count": PatientCountInPeriod(@2024-01-01, @2024-03-31)
define "2024Q2 Patient Count": PatientCountInPeriod(@2024-04-01, @2024-06-30)
define "2024Q3 Patient Count": PatientCountInPeriod(@2024-07-01, @2024-09-30)
define "2024Q4 Patient Count": PatientCountInPeriod(@2024-10-01, @2024-12-31)
define "2025Q1 Patient Count": PatientCountInPeriod(@2025-01-01, @2025-03-31)
define "2025Q2 Patient Count": PatientCountInPeriod(@2025-04-01, @2025-06-30)
define "2025Q3 Patient Count": PatientCountInPeriod(@2025-07-01, @2025-09-30)
define "2025Q4 Patient Count": PatientCountInPeriod(@2025-10-01, @2025-12-31)
define "2026Q1 Patient Count": PatientCountInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Overall Patient Count": "2026Q1 Patient Count"

define "Indicator Result":
  Tuple {
    indicatorCode: '2510',
    indicatorCodeYear: '2511',
    indicatorName: '牙醫門診50歲以上(含)就醫人數',
    indicatorType: 'count',
    unit: '人',
    ageCriteria: '費用年月-出生年月取統計期間最大值>=600個月(50歲)',
    ageThresholdMonths: 600,
    quarters: List{
      Tuple { quarter: '2024Q1', patientCount: "2024Q1 Patient Count" },
      Tuple { quarter: '2024Q2', patientCount: "2024Q2 Patient Count" },
      Tuple { quarter: '2024Q3', patientCount: "2024Q3 Patient Count" },
      Tuple { quarter: '2024Q4', patientCount: "2024Q4 Patient Count" },
      Tuple { quarter: '2025Q1', patientCount: "2025Q1 Patient Count" },
      Tuple { quarter: '2025Q2', patientCount: "2025Q2 Patient Count" },
      Tuple { quarter: '2025Q3', patientCount: "2025Q3 Patient Count" },
      Tuple { quarter: '2025Q4', patientCount: "2025Q4 Patient Count" },
      Tuple { quarter: '2026Q1', patientCount: "2026Q1 Patient Count" }
    }
  }