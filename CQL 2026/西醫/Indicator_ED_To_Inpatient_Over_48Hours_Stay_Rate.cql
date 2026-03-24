library Indicator_ED_To_Inpatient_Over_48Hours_Stay_Rate version '1.0.0'

/*
急診轉住院暫留急診超過四十八小時案件比率
Emergency Department to Inpatient Transfer with Over 48-Hour ED Stay Rate

計算說明:
- 分子：分母案件中急診>48小時之案件數
- 分母：急診轉住院之案件數
- 計算公式：(分子/分母) × 100%
- 計算頻率：每季

備註:
1. 急診轉住院：急診encounter之後緊接著住院encounter（同一病人、同一醫院）
2. 急診停留時間：從急診encounter開始時間到住院encounter開始時間的時間差
3. 超過48小時定義：急診停留時間 > 48小時（2880分鐘）
4. 同一醫院：急診和住院的Organization必須相同
5. 時間連續性：住院encounter開始時間應在急診encounter結束後24小時內（視為轉住院）
6. 計算範圍：2026年(115年)資料
7. 此指標越低表示急診轉住院流程越順暢

定義說明:
- 案件分類02：急診（Emergency Department）
- 案件分類03：住院（Inpatient）
- 急診滯留時間計算：住院開始時間 - 急診開始時間

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

// 48小時門檻（以小時為單位）
parameter "ED Stay Threshold Hours" Integer default 48

// 轉住院時間窗（急診結束到住院開始的最大間隔，以小時為單位）
parameter "Transfer Window Hours" Integer default 24

// ===== 編碼系統定義 =====

// 台灣健保案件分類代碼系統
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// FHIR Encounter Type
codesystem "EncounterType": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// ===== 案件分類代碼定義 =====

// 急診案件分類
code "Emergency_Case": '02' from "TWCaseType" display '西醫急診'

// 住院案件分類
code "Inpatient_Case": '03' from "TWCaseType" display '西醫住院'

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

// 所有住院Encounter（案件分類03或type為IMP）
define "All Inpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and (
        exists(E.type T where T.coding.exists(c => c.code = 'IMP'))
        or "GetCaseType"(E).coding.exists(c => c.code = '03')
      )

// ===== 計算急診停留時間函數 =====

// 計算急診停留時間（以小時為單位）
define function "CalculateEDStayHours"(edEncounter Encounter, inpatientEncounter Encounter):
  duration in hours between edEncounter.period.start and inpatientEncounter.period.start

// 判斷是否為同一醫院
define function "IsSameHospital"(edEncounter Encounter, inpatientEncounter Encounter):
  "GetOrganizationId"(edEncounter) = "GetOrganizationId"(inpatientEncounter)

// 判斷是否為合理的轉住院時間窗（住院開始時間在急診結束後24小時內）
define function "IsValidTransferWindow"(edEncounter Encounter, inpatientEncounter Encounter):
  inpatientEncounter.period.start during Interval[edEncounter.period.end, edEncounter.period.end + "Transfer Window Hours" hours]

// ===== 急診轉住院案件識別 =====

// 識別急診轉住院案件（包含對應的住院encounter）
define function "GetEDToInpatientTransfers"(period Interval<DateTime>):
  "All Emergency Encounters" ED
    where ED.period.start during period
    let InpatientEncounter: 
      First(
        "All Inpatient Encounters" IP
          where IP.subject.reference = ED.subject.reference
            and "IsSameHospital"(ED, IP)
            and IP.period.start > ED.period.start
            and "IsValidTransferWindow"(ED, IP)
          sort by period.start
      )
    where InpatientEncounter is not null
    return {
      patient_id: ED.subject.reference,
      ed_encounter_id: ED.id,
      ed_start: ED.period.start,
      ed_end: ED.period.end,
      inpatient_encounter_id: InpatientEncounter.id,
      inpatient_start: InpatientEncounter.period.start,
      organization_id: "GetOrganizationId"(ED),
      ed_stay_hours: "CalculateEDStayHours"(ED, InpatientEncounter)
    }

// ===== 分母計算 =====

// 分母：急診轉住院之案件數（按期間）
define function "DenominatorForPeriod"(period Interval<DateTime>):
  "GetEDToInpatientTransfers"(period)

// 年度分母
define "Denominator Annual":
  "DenominatorForPeriod"("Measurement Period")

// 季度分母
define "Denominator Q1":
  "DenominatorForPeriod"("Q1 2026")

define "Denominator Q2":
  "DenominatorForPeriod"("Q2 2026")

define "Denominator Q3":
  "DenominatorForPeriod"("Q3 2026")

define "Denominator Q4":
  "DenominatorForPeriod"("Q4 2026")

// ===== 分子計算 =====

// 分子：分母案件中急診>48小時之案件數（按期間）
define function "NumeratorForPeriod"(period Interval<DateTime>):
  "GetEDToInpatientTransfers"(period) Transfer
    where Transfer.ed_stay_hours > "ED Stay Threshold Hours"

// 年度分子
define "Numerator Annual":
  "NumeratorForPeriod"("Measurement Period")

// 季度分子
define "Numerator Q1":
  "NumeratorForPeriod"("Q1 2026")

define "Numerator Q2":
  "NumeratorForPeriod"("Q2 2026")

define "Numerator Q3":
  "NumeratorForPeriod"("Q3 2026")

define "Numerator Q4":
  "NumeratorForPeriod"("Q4 2026")

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

// 計算平均急診停留時間（以小時為單位）
define function "CalculateAverageEDStayHours"(transfers List<Any>):
  if Count(transfers) = 0 then
    null
  else
    Round(
      Sum(transfers T return T.ed_stay_hours as Decimal) / Count(transfers) as Decimal,
      1
    )

// 計算中位數急診停留時間
define function "CalculateMedianEDStayHours"(transfers List<Any>):
  if Count(transfers) = 0 then
    null
  else
    let sortedHours: (transfers T return T.ed_stay_hours) sort asc,
        count: Count(sortedHours),
        midpoint: count div 2
    in
      if count mod 2 = 1 then
        sortedHours[midpoint]
      else
        Round(((sortedHours[midpoint - 1] + sortedHours[midpoint]) as Decimal / 2.0), 1)

// 年度統計
define "Annual Average ED Stay Hours":
  "CalculateAverageEDStayHours"("Denominator Annual")

define "Annual Median ED Stay Hours":
  "CalculateMedianEDStayHours"("Denominator Annual")

define "Annual Max ED Stay Hours":
  if Count("Denominator Annual") > 0 then
    Max("Denominator Annual" T return T.ed_stay_hours)
  else
    null

define "Annual Min ED Stay Hours":
  if Count("Denominator Annual") > 0 then
    Min("Denominator Annual" T return T.ed_stay_hours)
  else
    null

// 各季度平均急診停留時間
define "Q1 Average ED Stay Hours":
  "CalculateAverageEDStayHours"("Denominator Q1")

define "Q2 Average ED Stay Hours":
  "CalculateAverageEDStayHours"("Denominator Q2")

define "Q3 Average ED Stay Hours":
  "CalculateAverageEDStayHours"("Denominator Q3")

define "Q4 Average ED Stay Hours":
  "CalculateAverageEDStayHours"("Denominator Q4")

// 急診停留時間分布統計
define "ED Stay Duration Distribution":
  {
    under_24_hours: Count("Denominator Annual" T where T.ed_stay_hours <= 24),
    between_24_48_hours: Count("Denominator Annual" T where T.ed_stay_hours > 24 and T.ed_stay_hours <= 48),
    between_48_72_hours: Count("Denominator Annual" T where T.ed_stay_hours > 48 and T.ed_stay_hours <= 72),
    over_72_hours: Count("Denominator Annual" T where T.ed_stay_hours > 72)
  }

// ===== 按醫院統計 =====

// 年度各醫院統計
define "Annual Statistics By Hospital":
  distinct (
    "Denominator Annual" T return T.organization_id
  ) OrgId
  let HospitalTransfers: "Denominator Annual" T where T.organization_id = OrgId,
      HospitalOver48Hours: "Numerator Annual" N where N.organization_id = OrgId
  return {
    organization_id: OrgId,
    total_ed_to_inpatient_cases: Count(HospitalTransfers),
    cases_over_48_hours: Count(HospitalOver48Hours),
    rate: "CalculateRate"(HospitalOver48Hours, HospitalTransfers),
    average_ed_stay_hours: "CalculateAverageEDStayHours"(HospitalTransfers),
    median_ed_stay_hours: "CalculateMedianEDStayHours"(HospitalTransfers)
  }

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '急診轉住院暫留急診超過四十八小時案件比率',
    measurement_period: '2026年(115年)',
    calculation_formula: '(分母案件中急診>48小時之案件數 / 急診轉住院之案件數) × 100%',
    threshold: '48小時',
    
    // 年度整體指標
    annual_rate: "Rate Annual",
    annual_numerator: Count("Numerator Annual"),
    annual_denominator: Count("Denominator Annual"),
    annual_average_ed_stay_hours: "Annual Average ED Stay Hours",
    annual_median_ed_stay_hours: "Annual Median ED Stay Hours",
    annual_max_ed_stay_hours: "Annual Max ED Stay Hours",
    annual_min_ed_stay_hours: "Annual Min ED Stay Hours",
    
    // 季度指標
    q1_rate: "Rate Q1",
    q1_numerator: Count("Numerator Q1"),
    q1_denominator: Count("Denominator Q1"),
    q1_average_ed_stay_hours: "Q1 Average ED Stay Hours",
    
    q2_rate: "Rate Q2",
    q2_numerator: Count("Numerator Q2"),
    q2_denominator: Count("Denominator Q2"),
    q2_average_ed_stay_hours: "Q2 Average ED Stay Hours",
    
    q3_rate: "Rate Q3",
    q3_numerator: Count("Numerator Q3"),
    q3_denominator: Count("Denominator Q3"),
    q3_average_ed_stay_hours: "Q3 Average ED Stay Hours",
    
    q4_rate: "Rate Q4",
    q4_numerator: Count("Numerator Q4"),
    q4_denominator: Count("Denominator Q4"),
    q4_average_ed_stay_hours: "Q4 Average ED Stay Hours",
    
    // 急診停留時間分布
    ed_stay_duration_distribution: "ED Stay Duration Distribution",
    
    // 按醫院統計
    statistics_by_hospital: "Annual Statistics By Hospital",
    
    // 說明
    notes: {
      definition: '急診轉住院：急診encounter之後緊接著住院encounter（同一病人、同一醫院、住院開始時間在急診結束後24小時內）',
      calculation: '急診停留時間 = 住院開始時間 - 急診開始時間',
      threshold_definition: '超過48小時：急診停留時間 > 48小時（2880分鐘）',
      interpretation: '此指標越低表示急診轉住院流程越順暢，病人等待時間越短',
      quality_target: '建議目標：< 10%（急診轉住院案件中，超過48小時的比率應低於10%）'
    }
  }
