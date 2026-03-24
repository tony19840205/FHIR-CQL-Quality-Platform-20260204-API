library Indicator_DRG_3Day_ED_Revisit_Rate version '1.0.0'

/*
住院診斷關聯群支付制度(DRG)之案件三日內再急診率
DRG Inpatient Cases 3-Day Emergency Department Revisit Rate

計算說明:
- 分子：分母出院案件中，距離出院日0日至3日內，再次急診的案件數(跨院)
- 分母：住院DRG案件的出院案件數
- 計算公式：(分子/分母) × 100%
- 計算頻率：每季

備註:
1. DRG案件：使用台灣DRG支付制度的住院案件
2. 出院日：以encounter的period.end為準
3. 0日至3日內：出院當日(0日)到出院後第3日，共4天
4. 再次急診：包含跨院急診（不限同一醫院）
5. 本項指標已利用含醫院的病例組合指標(CMI)值，即疾病嚴重度，進行校正
6. 計算範圍：2026年(115年)資料
7. 此指標越低表示DRG住院案件品質越好，病人出院後狀況穩定

DRG支付制度說明:
- DRG (Diagnosis Related Groups) 診斷關聯群支付制度
- 依據病人的主要診斷、次要診斷、處置、手術、年齡、性別等因素分組
- 同一組別給付相同費用，鼓勵醫院提高效率並控制成本
- CMI (Case Mix Index) 病例組合指標反映醫院收治病人的疾病嚴重度

臨床意義:
- 高3日急診返診率可能表示：
  1. 出院準備不充分
  2. 病情評估不夠完整
  3. 出院後照護計劃不足
  4. DRG分組不適當導致住院時間過短
- 需考慮CMI校正，因為高複雜度病例自然有較高返診風險

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

// 出院後追蹤期間（0-3日，共4天）
parameter "Post Discharge Follow Up Days" Integer default 3

// ===== 編碼系統定義 =====

// 台灣DRG代碼系統
codesystem "TWDRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'

// DRG代碼系統
codesystem "DRGCode": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'

// 台灣健保案件分類代碼系統
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// FHIR Encounter Type
codesystem "EncounterType": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// ===== 案件分類代碼定義 =====

// 住院案件分類
code "Inpatient_Case": '03' from "TWCaseType" display '西醫住院'

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

// 從Encounter Extension中取得DRG碼
define function "GetDRGCode"(encounter Encounter):
  (singleton from (
    encounter.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code'
  )).value as CodeableConcept

// 從Encounter Extension中取得CMI值
define function "GetCMI"(encounter Encounter):
  (singleton from (
    encounter.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/cmi-value'
  )).value as Decimal

// 從Encounter Extension中取得醫院Organization ID
define function "GetOrganizationId"(encounter Encounter):
  Last(Split(encounter.serviceProvider.reference, '/'))

// 從Encounter Extension中取得病人ID
define function "GetPatientId"(encounter Encounter):
  Last(Split(encounter.subject.reference, '/'))

// 判斷encounter是否為DRG案件
define function "IsDRGCase"(encounter Encounter):
  "GetDRGCode"(encounter) is not null

// ===== 基礎Encounter定義 =====

// 所有住院Encounter（案件分類03或type為IMP）
define "All Inpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and (
        exists(E.type T where T.coding.exists(c => c.code = 'IMP'))
        or "GetCaseType"(E).coding.exists(c => c.code = '03')
      )
      and E.period.end during "Measurement Period"

// 所有急診Encounter（案件分類02或type為EMER）
define "All Emergency Encounters":
  [Encounter] E
    where E.status = 'finished'
      and (
        exists(E.type T where T.coding.exists(c => c.code = 'EMER'))
        or "GetCaseType"(E).coding.exists(c => c.code = '02')
      )

// ===== DRG住院案件識別 =====

// 取得DRG住院案件（按期間）
define function "GetDRGInpatientCases"(period Interval<DateTime>):
  "All Inpatient Encounters" E
    where E.period.end during period
      and "IsDRGCase"(E)
    return {
      encounter_id: E.id,
      patient_id: "GetPatientId"(E),
      organization_id: "GetOrganizationId"(E),
      discharge_date: E.period.end,
      drg_code: "GetDRGCode"(E),
      cmi_value: "GetCMI"(E)
    }

// ===== 出院後3日內急診就診識別 =====

// 取得出院後0-3日內的急診就診
define function "GetEDVisitsWithin3DaysAfterDischarge"(dischargeDate DateTime, patientId String):
  "All Emergency Encounters" ED
    where "GetPatientId"(ED) = patientId
      and ED.period.start during Interval[dischargeDate, dischargeDate + "Post Discharge Follow Up Days" days]
    return {
      ed_encounter_id: ED.id,
      ed_start_date: ED.period.start,
      ed_organization_id: "GetOrganizationId"(ED),
      days_after_discharge: duration in days between dischargeDate and ED.period.start
    }

// ===== 分母計算（DRG住院案件的出院案件數） =====

// 分母：DRG住院案件（按期間）
define function "DenominatorForPeriod"(period Interval<DateTime>):
  "GetDRGInpatientCases"(period)

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

// ===== 分子計算（出院後0-3日內再次急診的案件數） =====

// 分子：分母案件中，出院後0-3日內有急診的案件（按期間）
define function "NumeratorForPeriod"(period Interval<DateTime>):
  "GetDRGInpatientCases"(period) DRGCase
    let EDVisits: "GetEDVisitsWithin3DaysAfterDischarge"(DRGCase.discharge_date, DRGCase.patient_id)
    where Count(EDVisits) > 0
    return {
      encounter_id: DRGCase.encounter_id,
      patient_id: DRGCase.patient_id,
      organization_id: DRGCase.organization_id,
      discharge_date: DRGCase.discharge_date,
      drg_code: DRGCase.drg_code,
      cmi_value: DRGCase.cmi_value,
      ed_visits_count: Count(EDVisits),
      ed_visits: EDVisits,
      first_ed_days_after_discharge: First(EDVisits sort by days_after_discharge).days_after_discharge
    }

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

// 計算平均CMI值
define function "CalculateAverageCMI"(cases List<Any>):
  if Count(cases) = 0 then
    null
  else
    Round(
      Sum(cases C return C.cmi_value as Decimal) / Count(cases) as Decimal,
      2
    )

// 年度統計
define "Annual Average CMI":
  "CalculateAverageCMI"("Denominator Annual")

define "Annual Average CMI With ED Revisit":
  "CalculateAverageCMI"("Numerator Annual")

// 急診返診天數分布（0日、1日、2日、3日）
define "Annual ED Revisit Day Distribution":
  {
    day_0: Count("Numerator Annual" N where N.first_ed_days_after_discharge = 0),
    day_1: Count("Numerator Annual" N where N.first_ed_days_after_discharge = 1),
    day_2: Count("Numerator Annual" N where N.first_ed_days_after_discharge = 2),
    day_3: Count("Numerator Annual" N where N.first_ed_days_after_discharge = 3)
  }

// 急診就診次數分布（1次、2次、3次以上）
define "Annual ED Visits Count Distribution":
  {
    one_visit: Count("Numerator Annual" N where N.ed_visits_count = 1),
    two_visits: Count("Numerator Annual" N where N.ed_visits_count = 2),
    three_or_more_visits: Count("Numerator Annual" N where N.ed_visits_count >= 3)
  }

// 季度平均CMI
define "Q1 Average CMI":
  "CalculateAverageCMI"("Denominator Q1")

define "Q2 Average CMI":
  "CalculateAverageCMI"("Denominator Q2")

define "Q3 Average CMI":
  "CalculateAverageCMI"("Denominator Q3")

define "Q4 Average CMI":
  "CalculateAverageCMI"("Denominator Q4")

// ===== 按醫院統計 =====

// 年度各醫院統計
define "Annual Statistics By Hospital":
  distinct (
    "Denominator Annual" D return D.organization_id
  ) OrgId
  let HospitalDRGCases: "Denominator Annual" D where D.organization_id = OrgId,
      HospitalWithEDRevisit: "Numerator Annual" N where N.organization_id = OrgId
  return {
    organization_id: OrgId,
    total_drg_cases: Count(HospitalDRGCases),
    cases_with_3day_ed_revisit: Count(HospitalWithEDRevisit),
    rate: "CalculateRate"(HospitalWithEDRevisit, HospitalDRGCases),
    average_cmi: "CalculateAverageCMI"(HospitalDRGCases),
    average_cmi_with_ed_revisit: "CalculateAverageCMI"(HospitalWithEDRevisit)
  }

// ===== 按DRG碼統計 =====

// 年度各DRG碼統計（Top 20）
define "Annual Statistics By DRG Code":
  distinct (
    "Denominator Annual" D return D.drg_code.coding[0].code
  ) DRGCodeValue
  let DRGCases: "Denominator Annual" D where D.drg_code.coding[0].code = DRGCodeValue,
      DRGWithEDRevisit: "Numerator Annual" N where N.drg_code.coding[0].code = DRGCodeValue
  return {
    drg_code: DRGCodeValue,
    drg_display: First(DRGCases).drg_code.coding[0].display,
    total_cases: Count(DRGCases),
    cases_with_3day_ed_revisit: Count(DRGWithEDRevisit),
    rate: "CalculateRate"(DRGWithEDRevisit, DRGCases),
    average_cmi: "CalculateAverageCMI"(DRGCases)
  }
  sort by rate desc

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '住院診斷關聯群支付制度(DRG)之案件三日內再急診率',
    measurement_period: '2026年(115年)',
    calculation_formula: '(分母出院案件中距離出院日0-3日內再次急診的案件數 / 住院DRG案件的出院案件數) × 100%',
    follow_up_period: '出院當日(0日)至出院後第3日，共4天',
    
    // 年度整體指標
    annual_rate: "Rate Annual",
    annual_numerator: Count("Numerator Annual"),
    annual_denominator: Count("Denominator Annual"),
    annual_average_cmi: "Annual Average CMI",
    annual_average_cmi_with_ed_revisit: "Annual Average CMI With ED Revisit",
    
    // 季度指標
    q1_rate: "Rate Q1",
    q1_numerator: Count("Numerator Q1"),
    q1_denominator: Count("Denominator Q1"),
    q1_average_cmi: "Q1 Average CMI",
    
    q2_rate: "Rate Q2",
    q2_numerator: Count("Numerator Q2"),
    q2_denominator: Count("Denominator Q2"),
    q2_average_cmi: "Q2 Average CMI",
    
    q3_rate: "Rate Q3",
    q3_numerator: Count("Numerator Q3"),
    q3_denominator: Count("Denominator Q3"),
    q3_average_cmi: "Q3 Average CMI",
    
    q4_rate: "Rate Q4",
    q4_numerator: Count("Numerator Q4"),
    q4_denominator: Count("Denominator Q4"),
    q4_average_cmi: "Q4 Average CMI",
    
    // 急診返診天數分布
    ed_revisit_day_distribution: "Annual ED Revisit Day Distribution",
    
    // 急診就診次數分布
    ed_visits_count_distribution: "Annual ED Visits Count Distribution",
    
    // 按醫院統計
    statistics_by_hospital: "Annual Statistics By Hospital",
    
    // 按DRG碼統計
    statistics_by_drg_code: "Annual Statistics By DRG Code",
    
    // 說明
    notes: {
      definition: 'DRG（診斷關聯群）支付制度：依據病人的主要診斷、次要診斷、處置、手術、年齡、性別等因素分組，同一組別給付相同費用',
      numerator_explanation: '分母出院案件中，出院當日(0日)到出院後第3日內有急診就診的案件數（包含跨院）',
      denominator_explanation: '所有DRG住院案件的出院案件數',
      cmi_adjustment: '本指標已利用含醫院的病例組合指標(CMI)值進行校正，CMI反映醫院收治病人的疾病嚴重度',
      interpretation: '此指標越低表示DRG住院案件品質越好，病人出院後狀況穩定',
      clinical_significance: '高3日急診返診率可能表示出院準備不充分、病情評估不完整或DRG分組不適當導致住院時間過短',
      quality_target: '建議目標：< 5%（DRG案件3日內急診返診率應低於5%，需考慮CMI校正）'
    }
  }
