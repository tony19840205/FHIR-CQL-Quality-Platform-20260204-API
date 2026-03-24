library Indicator_DRG_Transfer_Out_Rate version '1.0.0'

/*
住院診斷關聯群支付制度(DRG)之案件轉出率
DRG Inpatient Cases Transfer-Out Rate

計算說明:
- 分子：分母案件中，轉歸代碼符合"6 轉院"案件
- 分母：住院DRG案件的案件數
- 計算公式：(分子/分母) × 100%
- 計算頻率：每季

備註:
1. DRG案件：使用台灣DRG支付制度的住院案件
2. 轉歸代碼：以encounter的hospitalization.dischargeDisposition為準
3. 轉院代碼：'06'或'6'（依照台灣健保轉歸代碼）
4. 計算範圍：2026年(115年)資料
5. 此指標反映DRG案件的醫療資源使用情形

DRG支付制度說明:
- DRG (Diagnosis Related Groups) 診斷關聯群支付制度
- 依據病人的主要診斷、次要診斷、處置、手術、年齡、性別等因素分組
- 同一組別給付相同費用，鼓勵醫院提高效率並控制成本
- CMI (Case Mix Index) 病例組合指標反映醫院收治病人的疾病嚴重度

臨床意義:
- 轉出率反映醫院對DRG案件的處理能力：
  1. 高轉出率可能表示醫院資源不足以處理該類病例
  2. 可能反映醫院專科能力限制
  3. 可能是病情需要更高層級醫療照護
  4. 可能是區域醫療網絡協作狀況
- 需考慮醫院層級與功能定位
- 需考慮CMI值，高複雜度病例較可能需要轉院

轉歸代碼說明（台灣健保）:
- 01: 治癒出院
- 02: 未癒出院
- 03: 自動出院
- 04: 死亡
- 05: 轉至其他科
- 06: 轉院（本指標追蹤項目）
- 07: 其他

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

// 台灣DRG代碼系統
codesystem "TWDRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'

// DRG代碼系統
codesystem "DRGCode": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'

// 台灣健保案件分類代碼系統
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// FHIR Encounter Type
codesystem "EncounterType": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// 台灣出院方式代碼系統
codesystem "TWDischargeDisposition": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/discharge-disposition-tw'

// ===== 案件分類代碼定義 =====

// 住院案件分類
code "Inpatient_Case": '03' from "TWCaseType" display '西醫住院'

// 轉院出院方式
code "Transfer_Out": '06' from "TWDischargeDisposition" display '轉院'

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

// 取得出院方式代碼
define function "GetDischargeDispositionCode"(encounter Encounter):
  encounter.hospitalization.dischargeDisposition.coding[0].code

// 判斷是否為轉院案件
define function "IsTransferOut"(encounter Encounter):
  "GetDischargeDispositionCode"(encounter) in {'06', '6'}

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
      discharge_disposition: E.hospitalization.dischargeDisposition,
      discharge_disposition_code: "GetDischargeDispositionCode"(E),
      is_transfer_out: "IsTransferOut"(E),
      length_of_stay: duration in days between E.period.start and E.period.end
    }

// ===== 分母計算（DRG住院案件的案件數） =====

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

// ===== 分子計算（轉歸代碼為"6 轉院"的案件數） =====

// 分子：分母案件中，轉歸代碼為"6"的案件（按期間）
define function "NumeratorForPeriod"(period Interval<DateTime>):
  "GetDRGInpatientCases"(period) DRGCase
    where DRGCase.is_transfer_out = true

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

// 計算平均住院天數
define function "CalculateAverageLOS"(cases List<Any>):
  if Count(cases) = 0 then
    null
  else
    Round(
      Sum(cases C return C.length_of_stay as Decimal) / Count(cases) as Decimal,
      1
    )

// 年度統計
define "Annual Average CMI":
  "CalculateAverageCMI"("Denominator Annual")

define "Annual Average CMI Transfer Out":
  "CalculateAverageCMI"("Numerator Annual")

define "Annual Average LOS":
  "CalculateAverageLOS"("Denominator Annual")

define "Annual Average LOS Transfer Out":
  "CalculateAverageLOS"("Numerator Annual")

// 出院方式分布（所有DRG案件）
define "Annual Discharge Disposition Distribution":
  distinct (
    "Denominator Annual" D return D.discharge_disposition_code
  ) DispositionCode
  let CasesWithDisposition: "Denominator Annual" D where D.discharge_disposition_code = DispositionCode
  return {
    disposition_code: DispositionCode,
    disposition_display: First(CasesWithDisposition).discharge_disposition.coding[0].display,
    count: Count(CasesWithDisposition),
    percentage: Round((Count(CasesWithDisposition) as Decimal / Count("Denominator Annual") as Decimal) * 100.0, 1)
  }
  sort by count desc

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
      HospitalTransferOut: "Numerator Annual" N where N.organization_id = OrgId
  return {
    organization_id: OrgId,
    total_drg_cases: Count(HospitalDRGCases),
    transfer_out_cases: Count(HospitalTransferOut),
    transfer_out_rate: "CalculateRate"(HospitalTransferOut, HospitalDRGCases),
    average_cmi: "CalculateAverageCMI"(HospitalDRGCases),
    average_cmi_transfer_out: "CalculateAverageCMI"(HospitalTransferOut),
    average_los: "CalculateAverageLOS"(HospitalDRGCases),
    average_los_transfer_out: "CalculateAverageLOS"(HospitalTransferOut)
  }

// ===== 按DRG碼統計 =====

// 年度各DRG碼統計（依轉出率排序）
define "Annual Statistics By DRG Code":
  distinct (
    "Denominator Annual" D return D.drg_code.coding[0].code
  ) DRGCodeValue
  let DRGCases: "Denominator Annual" D where D.drg_code.coding[0].code = DRGCodeValue,
      DRGTransferOut: "Numerator Annual" N where N.drg_code.coding[0].code = DRGCodeValue
  return {
    drg_code: DRGCodeValue,
    drg_display: First(DRGCases).drg_code.coding[0].display,
    total_cases: Count(DRGCases),
    transfer_out_cases: Count(DRGTransferOut),
    transfer_out_rate: "CalculateRate"(DRGTransferOut, DRGCases),
    average_cmi: "CalculateAverageCMI"(DRGCases),
    average_los: "CalculateAverageLOS"(DRGCases)
  }
  sort by transfer_out_rate desc

// ===== 轉出案件詳細分析 =====

// 轉出案件平均住院天數分布
define "Transfer Out LOS Distribution":
  {
    los_0_to_3_days: Count("Numerator Annual" N where N.length_of_stay >= 0 and N.length_of_stay <= 3),
    los_4_to_7_days: Count("Numerator Annual" N where N.length_of_stay >= 4 and N.length_of_stay <= 7),
    los_8_to_14_days: Count("Numerator Annual" N where N.length_of_stay >= 8 and N.length_of_stay <= 14),
    los_15_to_30_days: Count("Numerator Annual" N where N.length_of_stay >= 15 and N.length_of_stay <= 30),
    los_over_30_days: Count("Numerator Annual" N where N.length_of_stay > 30)
  }

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '住院診斷關聯群支付制度(DRG)之案件轉出率',
    measurement_period: '2026年(115年)',
    calculation_formula: '(轉歸代碼為「6 轉院」的DRG案件數 / 住院DRG案件的案件數) × 100%',
    
    // 年度整體指標
    annual_rate: "Rate Annual",
    annual_numerator: Count("Numerator Annual"),
    annual_denominator: Count("Denominator Annual"),
    annual_average_cmi: "Annual Average CMI",
    annual_average_cmi_transfer_out: "Annual Average CMI Transfer Out",
    annual_average_los: "Annual Average LOS",
    annual_average_los_transfer_out: "Annual Average LOS Transfer Out",
    
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
    
    // 出院方式分布
    discharge_disposition_distribution: "Annual Discharge Disposition Distribution",
    
    // 轉出案件住院天數分布
    transfer_out_los_distribution: "Transfer Out LOS Distribution",
    
    // 按醫院統計
    statistics_by_hospital: "Annual Statistics By Hospital",
    
    // 按DRG碼統計
    statistics_by_drg_code: "Annual Statistics By DRG Code",
    
    // 說明
    notes: {
      definition: 'DRG（診斷關聯群）支付制度：依據病人的主要診斷、次要診斷、處置、手術、年齡、性別等因素分組，同一組別給付相同費用',
      numerator_explanation: '轉歸代碼為「06」或「6」（轉院）的DRG住院案件數',
      denominator_explanation: '所有DRG住院案件的案件數',
      discharge_codes: {
        code_01: '治癒出院',
        code_02: '未癒出院',
        code_03: '自動出院',
        code_04: '死亡',
        code_05: '轉至其他科',
        code_06: '轉院（本指標追蹤項目）',
        code_07: '其他'
      },
      interpretation: '此指標反映DRG案件的醫療資源使用情形，高轉出率可能表示醫院資源不足或專科能力限制',
      clinical_significance: '需考慮醫院層級與功能定位，以及CMI值（高複雜度病例較可能需要轉院）',
      quality_consideration: '轉出率應在合理範圍內，過高或過低都需要進一步分析原因'
    }
  }
