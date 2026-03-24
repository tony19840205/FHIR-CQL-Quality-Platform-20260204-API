library Indicator_ED_Same_Day_Revisit_Rate_Same_Hospital version '1.0.0'

/*
急診就診後同日於同醫院急診返診比率
Emergency Department Same-Day Revisit Rate at Same Hospital

計算說明:
- 分子：兩次急診日差距 = 0天之人次
- 分母：急診人次
- 計算公式：(分子/分母) × 100%
- 計算頻率：每季

備註:
1. 同日定義：同一病人在同一天（日期相同，不考慮時間）於同一醫院有2次或以上急診就診
2. 同一醫院：Organization必須相同
3. 急診定義：案件分類02（西醫急診）或encounter type為EMER
4. 人次計算：每一次急診encounter計為一人次
5. 返診定義：如果一天內有N次急診，則有N-1次為返診（第2次之後都算返診）
6. 計算範圍：2026年(115年)資料
7. 此指標越低表示急診處置品質越好，病人不需要當天重複就診

定義說明:
- 案件分類02：急診（Emergency Department）
- 同日：以日期（Date）為準，不考慮具體時間（Time）
- 返診人次：當天第2次及之後的急診就診都計入分子

臨床意義:
- 高同日返診率可能表示：
  1. 首次急診處置不夠充分
  2. 病情評估不夠完整
  3. 出院指導不清楚
  4. 病人依從性問題
- 需排除正常的返診情況（如換藥、拆線等計劃性返診）

Version History:
- 1.0.0: Initial implementation (2026-01-07)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ===== 參數定義 =====

// 測量期間：2026年全年
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 季度期間定義
parameter "Q1 2026" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]

parameter "Q2 2026" Interval<DateTime>
  default Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]

parameter "Q3 2026" Interval<DateTime>
  default Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]

parameter "Q4 2026" Interval<DateTime>
  default Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]

// ===== 編碼系統定義 =====

// 台灣健保案件分類代碼系統
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// FHIR Encounter Type
codesystem "EncounterType": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// ===== 案件分類代碼定義 =====

// 急診案件分類
code "Emergency_Case": '02' from "TWCaseType" display '西醫急診'

// ===== 資料來源定義 =====

context Patient

// ===== Encounter Extension 函數 =====

// 從Encounter Extension中取得案件分類
define function "GetCaseType"(encounter Encounter):
  (singleton from (
    encounter.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/case-type'
  )).value as CodeableConcept

// 從Encounter Extension中取得醫院Organization ID
define function "GetOrganizationId"(encounter Encounter):
  Last(Split(encounter.serviceProvider.reference, '/'))

// 從Encounter Extension中取得病人ID
define function "GetPatientId"(encounter Encounter):
  Last(Split(encounter.subject.reference, '/'))

// 取得日期（不含時間）
define function "GetDate"(dateTime DateTime):
  DateTime(year from dateTime, month from dateTime, day from dateTime, 0, 0, 0, 0, timezone from dateTime)

// ===== 基礎Encounter定義 =====

// 所有急診Encounter（案件分類02或type為EMER）
define "All Emergency Encounters":
  [Encounter] E
    where E.status = 'finished'
      and (
        exists(E.type T where T.coding.exists(c => c.code = 'EMER'))
        or "GetCaseType"(E).coding.exists(c => c.code = '02')
      )
      and E.period.start during "Measurement Period"

// ===== 分母計算（所有急診人次） =====

// 按期間取得所有急診encounter
define function "GetEDEncountersForPeriod"(period Interval<DateTime>):
  "All Emergency Encounters" E
    where E.period.start during period

// 年度分母（急診人次）
define "Denominator Annual":
  "GetEDEncountersForPeriod"("Measurement Period")

// 季度分母
define "Denominator Q1":
  "GetEDEncountersForPeriod"("Q1 2026")

define "Denominator Q2":
  "GetEDEncountersForPeriod"("Q2 2026")

define "Denominator Q3":
  "GetEDEncountersForPeriod"("Q3 2026")

define "Denominator Q4":
  "GetEDEncountersForPeriod"("Q4 2026")

// ===== 同日返診識別 =====

// 識別同日同院返診案件（按期間）
// 邏輯：對每一次急診，檢查是否為當天同醫院的第2次及之後的就診
define function "GetSameDayRevisits"(period Interval<DateTime>):
  "GetEDEncountersForPeriod"(period) E
    let PatientId: "GetPatientId"(E),
        OrgId: "GetOrganizationId"(E),
        VisitDate: "GetDate"(E.period.start),
        // 找出同一病人、同一醫院、同一天的所有急診（含自己）
        SameDayVisits: 
          "GetEDEncountersForPeriod"(period) OtherE
            where "GetPatientId"(OtherE) = PatientId
              and "GetOrganizationId"(OtherE) = OrgId
              and "GetDate"(OtherE.period.start) = VisitDate
            sort by period.start,
        // 計算這次就診是當天的第幾次
        VisitSequence: 
          Count(
            SameDayVisits SameVisit
              where SameVisit.period.start <= E.period.start
          )
    // 只有當天第2次及之後的才算返診（分子）
    where Count(SameDayVisits) > 1
      and VisitSequence > 1
    return {
      encounter_id: E.id,
      patient_id: PatientId,
      organization_id: OrgId,
      visit_date: VisitDate,
      visit_time: E.period.start,
      visit_sequence: VisitSequence,
      total_same_day_visits: Count(SameDayVisits),
      is_same_day_revisit: true
    }

// ===== 分子計算（同日返診人次） =====

// 年度分子
define "Numerator Annual":
  "GetSameDayRevisits"("Measurement Period")

// 季度分子
define "Numerator Q1":
  "GetSameDayRevisits"("Q1 2026")

define "Numerator Q2":
  "GetSameDayRevisits"("Q2 2026")

define "Numerator Q3":
  "GetSameDayRevisits"("Q3 2026")

define "Numerator Q4":
  "GetSameDayRevisits"("Q4 2026")

// ===== 指標計算 =====

// 計算指標比率（四捨五入至小數點第一位）
define function "CalculateRate"(numerator List<Any>, denominator List<Any>):
  if Count(denominator) = 0 then
    null
  else
    Round((Count(numerator) as Decimal / Count(denominator) as Decimal) * 100.0, 1)

// 年度指標
define "Rate Annual":
  "CalculateRate"("Numerator Annual", "Denominator Annual")

// 季度指標
define "Rate Q1":
  "CalculateRate"("Numerator Q1", "Denominator Q1")

define "Rate Q2":
  "CalculateRate"("Numerator Q2", "Denominator Q2")

define "Rate Q3":
  "CalculateRate"("Numerator Q3", "Denominator Q3")

define "Rate Q4":
  "CalculateRate"("Numerator Q4", "Denominator Q4")

// ===== 統計資訊 =====

// 計算有同日返診的病人數（去重）
define function "GetUniquePatientCountWithSameDayRevisit"(revisits List<Any>):
  Count(distinct (revisits R return R.patient_id))

// 計算有同日返診的天數（去重）
define function "GetUniqueDayCountWithSameDayRevisit"(revisits List<Any>):
  Count(distinct (revisits R return R.visit_date))

// 年度統計
define "Annual Unique Patients With Same Day Revisit":
  "GetUniquePatientCountWithSameDayRevisit"("Numerator Annual")

define "Annual Unique Days With Same Day Revisit":
  "GetUniqueDayCountWithSameDayRevisit"("Numerator Annual")

// 同日返診次數分布（一天內返診1次、2次、3次等）
define "Annual Same Day Revisit Frequency Distribution":
  {
    revisit_once: Count("Numerator Annual" R where R.total_same_day_visits = 2),
    revisit_twice: Count("Numerator Annual" R where R.total_same_day_visits = 3),
    revisit_three_times: Count("Numerator Annual" R where R.total_same_day_visits = 4),
    revisit_more_than_three: Count("Numerator Annual" R where R.total_same_day_visits > 4)
  }

// 季度統計
define "Q1 Unique Patients With Same Day Revisit":
  "GetUniquePatientCountWithSameDayRevisit"("Numerator Q1")

define "Q2 Unique Patients With Same Day Revisit":
  "GetUniquePatientCountWithSameDayRevisit"("Numerator Q2")

define "Q3 Unique Patients With Same Day Revisit":
  "GetUniquePatientCountWithSameDayRevisit"("Numerator Q3")

define "Q4 Unique Patients With Same Day Revisit":
  "GetUniquePatientCountWithSameDayRevisit"("Numerator Q4")

// ===== 按醫院統計 =====

// 年度各醫院統計
define "Annual Statistics By Hospital":
  distinct (
    "Denominator Annual" E return "GetOrganizationId"(E)
  ) OrgId
  let HospitalEDVisits: "Denominator Annual" E where "GetOrganizationId"(E) = OrgId,
      HospitalRevisits: "Numerator Annual" R where R.organization_id = OrgId
  return {
    organization_id: OrgId,
    total_ed_visits: Count(HospitalEDVisits),
    same_day_revisits: Count(HospitalRevisits),
    rate: "CalculateRate"(HospitalRevisits, HospitalEDVisits),
    unique_patients_with_revisit: "GetUniquePatientCountWithSameDayRevisit"(HospitalRevisits)
  }

// ===== 時間分布分析 =====

// 分析返診的時間間隔（第一次急診到第二次急診的小時數）
define function "GetRevisitTimeGap"(revisit Any, period Interval<DateTime>):
  let AllVisitsOnSameDay: 
    "GetEDEncountersForPeriod"(period) E
      where "GetPatientId"(E) = revisit.patient_id
        and "GetOrganizationId"(E) = revisit.organization_id
        and "GetDate"(E.period.start) = revisit.visit_date
      sort by period.start,
      FirstVisitTime: First(AllVisitsOnSameDay).period.start,
      RevisitTime: revisit.visit_time
  in
    duration in hours between FirstVisitTime and RevisitTime

// 年度返診時間間隔分布
define "Annual Revisit Time Gap Distribution":
  {
    within_2_hours: Count("Numerator Annual" R where "GetRevisitTimeGap"(R, "Measurement Period") <= 2),
    between_2_4_hours: Count("Numerator Annual" R where "GetRevisitTimeGap"(R, "Measurement Period") > 2 and "GetRevisitTimeGap"(R, "Measurement Period") <= 4),
    between_4_8_hours: Count("Numerator Annual" R where "GetRevisitTimeGap"(R, "Measurement Period") > 4 and "GetRevisitTimeGap"(R, "Measurement Period") <= 8),
    between_8_12_hours: Count("Numerator Annual" R where "GetRevisitTimeGap"(R, "Measurement Period") > 8 and "GetRevisitTimeGap"(R, "Measurement Period") <= 12),
    over_12_hours: Count("Numerator Annual" R where "GetRevisitTimeGap"(R, "Measurement Period") > 12)
  }

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '急診就診後同日於同醫院急診返診比率',
    measurement_period: '2026年(115年)',
    calculation_formula: '(兩次急診日差距=0天之人次 / 急診人次) × 100%',
    
    // 年度整體指標
    annual_rate: "Rate Annual",
    annual_numerator: Count("Numerator Annual"),
    annual_denominator: Count("Denominator Annual"),
    annual_unique_patients_with_revisit: "Annual Unique Patients With Same Day Revisit",
    annual_unique_days_with_revisit: "Annual Unique Days With Same Day Revisit",
    
    // 季度指標
    q1_rate: "Rate Q1",
    q1_numerator: Count("Numerator Q1"),
    q1_denominator: Count("Denominator Q1"),
    q1_unique_patients: "Q1 Unique Patients With Same Day Revisit",
    
    q2_rate: "Rate Q2",
    q2_numerator: Count("Numerator Q2"),
    q2_denominator: Count("Denominator Q2"),
    q2_unique_patients: "Q2 Unique Patients With Same Day Revisit",
    
    q3_rate: "Rate Q3",
    q3_numerator: Count("Numerator Q3"),
    q3_denominator: Count("Denominator Q3"),
    q3_unique_patients: "Q3 Unique Patients With Same Day Revisit",
    
    q4_rate: "Rate Q4",
    q4_numerator: Count("Numerator Q4"),
    q4_denominator: Count("Denominator Q4"),
    q4_unique_patients: "Q4 Unique Patients With Same Day Revisit",
    
    // 返診頻率分布
    same_day_revisit_frequency_distribution: "Annual Same Day Revisit Frequency Distribution",
    
    // 返診時間間隔分布
    revisit_time_gap_distribution: "Annual Revisit Time Gap Distribution",
    
    // 按醫院統計
    statistics_by_hospital: "Annual Statistics By Hospital",
    
    // 說明
    notes: {
      definition: '同日返診：同一病人在同一天（日期相同）於同一醫院有2次或以上急診就診，第2次及之後都算返診',
      numerator_explanation: '如果一天內有N次急診，則有N-1次計入分子（第2次之後都算）',
      denominator_explanation: '所有急診人次（每一次encounter計為一人次）',
      interpretation: '此指標越低表示急診處置品質越好，病人不需要當天重複就診',
      clinical_significance: '高同日返診率可能表示首次急診處置不充分、病情評估不完整或出院指導不清楚',
      quality_target: '建議目標：< 5%（急診同日返診率應低於5%）'
    }
  }
