library Indicator_DRG_14Day_Readmission_Rate version '1.0.0'

/*
住院診斷關聯群支付制度(DRG)之案件十四日內再住院率
DRG Inpatient Cases 14-Day Readmission Rate

計算說明:
- 分子：分母出院案件中，距離出院日0日至14日內，再次住院的案件數(跨院)
- 分母：住院DRG案件的出院案件數
- 計算公式：(分子/分母) × 100%
- 計算頻率：每季

備註:
1. DRG案件：使用台灣DRG支付制度的住院案件
2. 出院日：以encounter的period.end為準
3. 0日至14日內：出院當日(0日)到出院後第14日，共15天
4. 再次住院：包含跨院住院（不限同一醫院）
5. 本項指標已利用含醫院的病例組合指標(CMI)值，即疾病嚴重度，進行校正
6. 計算範圍：2026年(115年)資料
7. 此指標越低表示DRG住院案件品質越好，病人出院後狀況穩定

DRG支付制度說明:
- DRG (Diagnosis Related Groups) 診斷關聯群支付制度
- 依據病人的主要診斷、次要診斷、處置、手術、年齡、性別等因素分組
- 同一組別給付相同費用，鼓勵醫院提高效率並控制成本
- CMI (Case Mix Index) 病例組合指標反映醫院收治病人的疾病嚴重度

臨床意義:
- 高14日再住院率可能表示：
  1. 出院準備不充分，病人未達穩定狀態
  2. 出院後照護計劃不足或執行不良
  3. DRG分組不適當導致住院時間過短
  4. 併發症或合併症處理不完善
  5. 出院後追蹤機制不足
- 需考慮CMI校正，因為高複雜度病例自然有較高再住院風險
- 與3日急診率合併觀察，可了解整體出院後照護品質

排除條件:
- 計劃性再住院（如分階段手術、化療等）應予排除
- 但本實作未納入排除邏輯，需依實際需求調整

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

// 出院後追蹤期間（0-14日，共15天）
parameter "Post Discharge Follow Up Days" Integer default 14

// ===== 編碼系統定義 =====

// 台灣DRG代碼系統
codesystem "TWDRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'

// DRG代碼系統
codesystem "DRGCode": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'

// 台灣健保案件分類代碼系統
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// FHIR Encounter Type
codesystem "EncounterType": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// 出院方式代碼系統
codesystem "TWDischargeDisposition": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/discharge-disposition-tw'

// ===== 案件分類代碼定義 =====

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

// 判斷是否為計劃性住院（可依需求擴充）
define function "IsPlannedReadmission"(encounter Encounter):
  // 此處可依實際需求加入計劃性住院的判斷邏輯
  // 例如：特定DRG碼、特定procedure code、admission type等
  // 目前實作暫不排除任何案件
  false

// ===== 基礎Encounter定義 =====

// 所有住院Encounter（案件分類03或type為IMP）
define "All Inpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and (
        exists(E.type T where T.coding.exists(c => c.code = 'IMP'))
        or "GetCaseType"(E).coding.exists(c => c.code = '03')
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
      admission_date: E.period.start,
      discharge_date: E.period.end,
      drg_code: "GetDRGCode"(E),
      cmi_value: "GetCMI"(E),
      discharge_disposition: E.hospitalization.dischargeDisposition
    }

// ===== 出院後14日內再住院識別 =====

// 取得出院後0-14日內的再住院
define function "GetReadmissionsWithin14DaysAfterDischarge"(dischargeDate DateTime, patientId String, indexEncounterId String):
  "All Inpatient Encounters" Readmit
    where "GetPatientId"(Readmit) = patientId
      and Readmit.id != indexEncounterId  // 排除同一次住院
      and Readmit.period.start during Interval[dischargeDate, dischargeDate + "Post Discharge Follow Up Days" days]
      and not "IsPlannedReadmission"(Readmit)  // 排除計劃性再住院
    return {
      readmit_encounter_id: Readmit.id,
      readmit_admission_date: Readmit.period.start,
      readmit_organization_id: "GetOrganizationId"(Readmit),
      days_after_discharge: duration in days between dischargeDate and Readmit.period.start,
      is_same_hospital: "GetOrganizationId"(Readmit) = Last(Split(
        (singleton from (
          "All Inpatient Encounters" Original where Original.id = indexEncounterId
        )).serviceProvider.reference, '/')),
      readmit_drg_code: "GetDRGCode"(Readmit),
      readmit_cmi_value: "GetCMI"(Readmit)
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

// ===== 分子計算（出院後0-14日內再次住院的案件數） =====

// 分子：分母案件中，出院後0-14日內有再住院的案件（按期間）
define function "NumeratorForPeriod"(period Interval<DateTime>):
  "GetDRGInpatientCases"(period) DRGCase
    let Readmissions: "GetReadmissionsWithin14DaysAfterDischarge"(
      DRGCase.discharge_date, 
      DRGCase.patient_id, 
      DRGCase.encounter_id
    )
    where Count(Readmissions) > 0
    return {
      encounter_id: DRGCase.encounter_id,
      patient_id: DRGCase.patient_id,
      organization_id: DRGCase.organization_id,
      discharge_date: DRGCase.discharge_date,
      drg_code: DRGCase.drg_code,
      cmi_value: DRGCase.cmi_value,
      readmissions_count: Count(Readmissions),
      readmissions: Readmissions,
      first_readmission_days: First(Readmissions sort by days_after_discharge).days_after_discharge,
      has_same_hospital_readmission: exists(Readmissions R where R.is_same_hospital = true),
      has_cross_hospital_readmission: exists(Readmissions R where R.is_same_hospital = false)
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

define "Annual Average CMI With Readmission":
  "CalculateAverageCMI"("Numerator Annual")

// 再住院天數分布（0-3日、4-7日、8-14日）
define "Annual Readmission Day Distribution":
  {
    day_0_to_3: Count("Numerator Annual" N where N.first_readmission_days >= 0 and N.first_readmission_days <= 3),
    day_4_to_7: Count("Numerator Annual" N where N.first_readmission_days >= 4 and N.first_readmission_days <= 7),
    day_8_to_14: Count("Numerator Annual" N where N.first_readmission_days >= 8 and N.first_readmission_days <= 14)
  }

// 再住院次數分布（1次、2次、3次以上）
define "Annual Readmissions Count Distribution":
  {
    one_readmission: Count("Numerator Annual" N where N.readmissions_count = 1),
    two_readmissions: Count("Numerator Annual" N where N.readmissions_count = 2),
    three_or_more_readmissions: Count("Numerator Annual" N where N.readmissions_count >= 3)
  }

// 再住院醫院分布（同院 vs 跨院）
define "Annual Readmission Hospital Distribution":
  {
    same_hospital_only: Count("Numerator Annual" N where N.has_same_hospital_readmission = true and N.has_cross_hospital_readmission = false),
    cross_hospital_only: Count("Numerator Annual" N where N.has_same_hospital_readmission = false and N.has_cross_hospital_readmission = true),
    both_same_and_cross: Count("Numerator Annual" N where N.has_same_hospital_readmission = true and N.has_cross_hospital_readmission = true)
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
      HospitalWithReadmission: "Numerator Annual" N where N.organization_id = OrgId
  return {
    organization_id: OrgId,
    total_drg_cases: Count(HospitalDRGCases),
    cases_with_14day_readmission: Count(HospitalWithReadmission),
    rate: "CalculateRate"(HospitalWithReadmission, HospitalDRGCases),
    average_cmi: "CalculateAverageCMI"(HospitalDRGCases),
    average_cmi_with_readmission: "CalculateAverageCMI"(HospitalWithReadmission)
  }

// ===== 按DRG碼統計 =====

// 年度各DRG碼統計（Top 20）
define "Annual Statistics By DRG Code":
  distinct (
    "Denominator Annual" D return D.drg_code.coding[0].code
  ) DRGCodeValue
  let DRGCases: "Denominator Annual" D where D.drg_code.coding[0].code = DRGCodeValue,
      DRGWithReadmission: "Numerator Annual" N where N.drg_code.coding[0].code = DRGCodeValue
  return {
    drg_code: DRGCodeValue,
    drg_display: First(DRGCases).drg_code.coding[0].display,
    total_cases: Count(DRGCases),
    cases_with_14day_readmission: Count(DRGWithReadmission),
    rate: "CalculateRate"(DRGWithReadmission, DRGCases),
    average_cmi: "CalculateAverageCMI"(DRGCases)
  }
  sort by rate desc

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '住院診斷關聯群支付制度(DRG)之案件十四日內再住院率',
    measurement_period: '2026年(115年)',
    calculation_formula: '(分母出院案件中距離出院日0-14日內再次住院的案件數 / 住院DRG案件的出院案件數) × 100%',
    follow_up_period: '出院當日(0日)至出院後第14日，共15天',
    
    // 年度整體指標
    annual_rate: "Rate Annual",
    annual_numerator: Count("Numerator Annual"),
    annual_denominator: Count("Denominator Annual"),
    annual_average_cmi: "Annual Average CMI",
    annual_average_cmi_with_readmission: "Annual Average CMI With Readmission",
    
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
    
    // 再住院天數分布
    readmission_day_distribution: "Annual Readmission Day Distribution",
    
    // 再住院次數分布
    readmissions_count_distribution: "Annual Readmissions Count Distribution",
    
    // 再住院醫院分布
    readmission_hospital_distribution: "Annual Readmission Hospital Distribution",
    
    // 按醫院統計
    statistics_by_hospital: "Annual Statistics By Hospital",
    
    // 按DRG碼統計
    statistics_by_drg_code: "Annual Statistics By DRG Code",
    
    // 說明
    notes: {
      definition: 'DRG（診斷關聯群）支付制度：依據病人的主要診斷、次要診斷、處置、手術、年齡、性別等因素分組，同一組別給付相同費用',
      numerator_explanation: '分母出院案件中，出院當日(0日)到出院後第14日內有再住院的案件數（包含跨院）',
      denominator_explanation: '所有DRG住院案件的出院案件數',
      cmi_adjustment: '本指標已利用含醫院的病例組合指標(CMI)值進行校正，CMI反映醫院收治病人的疾病嚴重度',
      interpretation: '此指標越低表示DRG住院案件品質越好，病人出院後狀況穩定',
      clinical_significance: '高14日再住院率可能表示出院準備不充分、病情評估不完整、DRG分組不適當或併發症處理不完善',
      exclusion_note: '計劃性再住院（如分階段手術、化療等）應予排除，但本實作暫未納入排除邏輯',
      quality_target: '建議目標：< 10%（DRG案件14日內再住院率應低於10%，需考慮CMI校正）'
    }
  }
