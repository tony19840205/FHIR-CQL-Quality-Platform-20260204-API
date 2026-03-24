library Indicator_Triage_Level_1_ED_To_Ward_Within_8Hours_Rate version '1.0.0'

/*
檢傷一級急診病人轉入病房小於八小時之比率
Triage Level 1 Emergency Department to Ward Transfer Within 8 Hours Rate

計算說明:
- 分子：檢傷一級病人轉入病房小於八小時之人次
- 分母：檢傷一級病人住院人次
- 計算公式：(分子/分母) × 100%
- 計算頻率：每季

備註:
1. 檢傷一級：使用台灣急診檢傷分類系統（Taiwan Triage System）或CTAS，Level 1為緊急/危急（Resuscitation）
2. 分子條件：分母案件中，(急診治療迄日 - 急診治療起日) < 8小時之件數總計
3. 分母條件：當次門診及住院中檢傷有早急診診療起日、迄日，且急診後有轉住院（限同院）之案件數總計
   - 以急診診療費實習或住院診察費實習令（急診轉住院未申報急診診療費者）判斷其檢傷分類
   - 判斷後只留檢傷分類一級的案件為分母
4. 轉入病房時間：從急診開始時間到住院開始時間的時間差
5. 同一醫院：急診和住院的Organization必須相同
6. 計算範圍：2026年(115年)資料
7. 此指標越高表示檢傷一級病人能越快得到住院治療，急診處置效率越好

檢傷分類定義（Taiwan Triage System / CTAS）:
- Level 1：緊急/危急（Resuscitation）- 需立即處理，生命危險
- Level 2：危急（Emergent）- 10分鐘內處理
- Level 3：緊急（Urgent）- 30分鐘內處理
- Level 4：次緊急（Less Urgent）- 1小時內處理
- Level 5：非緊急（Non-Urgent）- 2小時內處理

臨床意義:
- 檢傷一級病人為最危急病人，應優先處理並盡快轉入病房
- 8小時內轉入病房表示急診處置流程順暢
- 高比率表示醫院對危急病人的處置能力良好

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

// 8小時門檻（轉入病房時間限制）
parameter "Transfer Time Threshold Hours" Integer default 8

// 轉住院時間窗（急診結束到住院開始的最大間隔，以小時為單位）
parameter "Transfer Window Hours" Integer default 24

// ===== 編碼系統定義 =====

// 台灣健保案件分類代碼系統
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// FHIR Encounter Type
codesystem "EncounterType": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// 台灣急診檢傷分類系統
codesystem "TWTriageSystem": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/triage-level-tw'

// LOINC (用於檢傷分類observation)
codesystem "LOINC": 'http://loinc.org'

// ===== 代碼定義 =====

// 急診案件分類
code "Emergency_Case": '02' from "TWCaseType" display '西醫急診'

// 住院案件分類
code "Inpatient_Case": '03' from "TWCaseType" display '西醫住院'

// 檢傷分類一級（最危急）
code "Triage_Level_1": '1' from "TWTriageSystem" display '第一級-緊急/危急(Resuscitation)'

// LOINC檢傷分類代碼
code "Emergency_Triage_Code": '54094-8' from "LOINC" display 'Emergency department triage'

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

// 從Encounter Extension或Observation中取得檢傷分類
define function "GetTriageLevel"(encounter Encounter):
  Coalesce(
    // 方法1: 從Encounter Extension取得
    (singleton from (
      encounter.extension E
        where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/triage-level'
    )).value as CodeableConcept,
    // 方法2: 從Observation取得
    (singleton from (
      [Observation: code in "Emergency Triage Code"] O
        where O.encounter.reference = 'Encounter/' + encounter.id
          and O.status = 'final'
    )).value as CodeableConcept
  )

// 判斷是否為檢傷一級
define function "IsTriageLevel1"(encounter Encounter):
  exists(
    "GetTriageLevel"(encounter).coding C
      where (C.code = '1' or C.code = 'Level1' or C.code = 'Resuscitation')
  )

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

// ===== 計算轉入病房時間函數 =====

// 計算從急診開始到住院開始的時間（以小時為單位）
define function "CalculateEDToWardHours"(edEncounter Encounter, inpatientEncounter Encounter):
  duration in hours between edEncounter.period.start and inpatientEncounter.period.start

// 判斷是否為同一醫院
define function "IsSameHospital"(edEncounter Encounter, inpatientEncounter Encounter):
  "GetOrganizationId"(edEncounter) = "GetOrganizationId"(inpatientEncounter)

// 判斷是否為合理的轉住院時間窗（住院開始時間在急診結束後24小時內）
define function "IsValidTransferWindow"(edEncounter Encounter, inpatientEncounter Encounter):
  inpatientEncounter.period.start during Interval[edEncounter.period.end, edEncounter.period.end + "Transfer Window Hours" hours]

// ===== 檢傷一級急診轉住院案件識別 =====

// 識別檢傷一級急診轉住院案件（按期間）
define function "GetTriageLevel1EDToInpatientTransfers"(period Interval<DateTime>):
  "All Emergency Encounters" ED
    where ED.period.start during period
      and "IsTriageLevel1"(ED)
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
      patient_id: "GetPatientId"(ED),
      ed_encounter_id: ED.id,
      ed_start: ED.period.start,
      ed_end: ED.period.end,
      inpatient_encounter_id: InpatientEncounter.id,
      inpatient_start: InpatientEncounter.period.start,
      organization_id: "GetOrganizationId"(ED),
      triage_level: "GetTriageLevel"(ED),
      transfer_hours: "CalculateEDToWardHours"(ED, InpatientEncounter)
    }

// ===== 分母計算（檢傷一級病人住院人次） =====

// 分母：檢傷一級急診轉住院之案件數（按期間）
define function "DenominatorForPeriod"(period Interval<DateTime>):
  "GetTriageLevel1EDToInpatientTransfers"(period)

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

// ===== 分子計算（檢傷一級病人轉入病房<8小時之人次） =====

// 分子：分母案件中轉入病房<8小時之案件數（按期間）
define function "NumeratorForPeriod"(period Interval<DateTime>):
  "GetTriageLevel1EDToInpatientTransfers"(period) Transfer
    where Transfer.transfer_hours < "Transfer Time Threshold Hours"

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

// 計算平均轉入病房時間（以小時為單位）
define function "CalculateAverageTransferHours"(transfers List<Any>):
  if Count(transfers) = 0 then
    null
  else
    Round(
      Sum(transfers T return T.transfer_hours as Decimal) / Count(transfers) as Decimal,
      1
    )

// 計算中位數轉入病房時間
define function "CalculateMedianTransferHours"(transfers List<Any>):
  if Count(transfers) = 0 then
    null
  else
    let sortedHours: (transfers T return T.transfer_hours) sort asc,
        count: Count(sortedHours),
        midpoint: count div 2
    in
      if count mod 2 = 1 then
        sortedHours[midpoint]
      else
        Round(((sortedHours[midpoint - 1] + sortedHours[midpoint]) as Decimal / 2.0), 1)

// 年度統計
define "Annual Average Transfer Hours":
  "CalculateAverageTransferHours"("Denominator Annual")

define "Annual Median Transfer Hours":
  "CalculateMedianTransferHours"("Denominator Annual")

define "Annual Max Transfer Hours":
  if Count("Denominator Annual") > 0 then
    Max("Denominator Annual" T return T.transfer_hours)
  else
    null

define "Annual Min Transfer Hours":
  if Count("Denominator Annual") > 0 then
    Min("Denominator Annual" T return T.transfer_hours)
  else
    null

// 各季度平均轉入病房時間
define "Q1 Average Transfer Hours":
  "CalculateAverageTransferHours"("Denominator Q1")

define "Q2 Average Transfer Hours":
  "CalculateAverageTransferHours"("Denominator Q2")

define "Q3 Average Transfer Hours":
  "CalculateAverageTransferHours"("Denominator Q3")

define "Q4 Average Transfer Hours":
  "CalculateAverageTransferHours"("Denominator Q4")

// 轉入病房時間分布統計
define "Transfer Time Distribution":
  {
    within_2_hours: Count("Denominator Annual" T where T.transfer_hours <= 2),
    between_2_4_hours: Count("Denominator Annual" T where T.transfer_hours > 2 and T.transfer_hours <= 4),
    between_4_8_hours: Count("Denominator Annual" T where T.transfer_hours > 4 and T.transfer_hours <= 8),
    between_8_12_hours: Count("Denominator Annual" T where T.transfer_hours > 8 and T.transfer_hours <= 12),
    over_12_hours: Count("Denominator Annual" T where T.transfer_hours > 12)
  }

// 計算達標案件數（<8小時）與未達標案件數（≥8小時）
define "Annual Compliance Statistics":
  {
    compliant_cases: Count("Numerator Annual"),
    non_compliant_cases: Count("Denominator Annual") - Count("Numerator Annual"),
    compliant_percentage: "Rate Annual",
    non_compliant_percentage: if Count("Denominator Annual") > 0 then
      Round(100.0 - "Rate Annual", 1)
    else
      null
  }

// ===== 按醫院統計 =====

// 年度各醫院統計
define "Annual Statistics By Hospital":
  distinct (
    "Denominator Annual" T return T.organization_id
  ) OrgId
  let HospitalTransfers: "Denominator Annual" T where T.organization_id = OrgId,
      HospitalWithin8Hours: "Numerator Annual" N where N.organization_id = OrgId
  return {
    organization_id: OrgId,
    total_triage_level_1_transfers: Count(HospitalTransfers),
    transfers_within_8_hours: Count(HospitalWithin8Hours),
    rate: "CalculateRate"(HospitalWithin8Hours, HospitalTransfers),
    average_transfer_hours: "CalculateAverageTransferHours"(HospitalTransfers),
    median_transfer_hours: "CalculateMedianTransferHours"(HospitalTransfers)
  }

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '檢傷一級急診病人轉入病房小於八小時之比率',
    measurement_period: '2026年(115年)',
    calculation_formula: '(檢傷一級病人轉入病房<8小時之人次 / 檢傷一級病人住院人次) × 100%',
    threshold: '8小時',
    triage_level: 'Level 1 - 緊急/危急 (Resuscitation)',
    
    // 年度整體指標
    annual_rate: "Rate Annual",
    annual_numerator: Count("Numerator Annual"),
    annual_denominator: Count("Denominator Annual"),
    annual_average_transfer_hours: "Annual Average Transfer Hours",
    annual_median_transfer_hours: "Annual Median Transfer Hours",
    annual_max_transfer_hours: "Annual Max Transfer Hours",
    annual_min_transfer_hours: "Annual Min Transfer Hours",
    annual_compliance_statistics: "Annual Compliance Statistics",
    
    // 季度指標
    q1_rate: "Rate Q1",
    q1_numerator: Count("Numerator Q1"),
    q1_denominator: Count("Denominator Q1"),
    q1_average_transfer_hours: "Q1 Average Transfer Hours",
    
    q2_rate: "Rate Q2",
    q2_numerator: Count("Numerator Q2"),
    q2_denominator: Count("Denominator Q2"),
    q2_average_transfer_hours: "Q2 Average Transfer Hours",
    
    q3_rate: "Rate Q3",
    q3_numerator: Count("Numerator Q3"),
    q3_denominator: Count("Denominator Q3"),
    q3_average_transfer_hours: "Q3 Average Transfer Hours",
    
    q4_rate: "Rate Q4",
    q4_numerator: Count("Numerator Q4"),
    q4_denominator: Count("Denominator Q4"),
    q4_average_transfer_hours: "Q4 Average Transfer Hours",
    
    // 轉入病房時間分布
    transfer_time_distribution: "Transfer Time Distribution",
    
    // 按醫院統計
    statistics_by_hospital: "Annual Statistics By Hospital",
    
    // 說明
    notes: {
      definition: '檢傷一級（Level 1）為最危急病人，需立即處理，生命危險',
      numerator_explanation: '檢傷一級病人從急診開始到住院開始時間<8小時的案件數',
      denominator_explanation: '檢傷一級病人急診後轉住院（同一醫院）的案件數',
      transfer_time_calculation: '轉入病房時間 = 住院開始時間 - 急診開始時間',
      interpretation: '此指標越高表示檢傷一級病人能越快得到住院治療，急診處置效率越好',
      clinical_significance: '檢傷一級病人為最危急病人，應優先處理並盡快轉入病房，8小時內轉入表示處置流程順暢',
      quality_target: '建議目標：> 80%（檢傷一級病人8小時內轉入病房比率應高於80%）'
    }
  }
