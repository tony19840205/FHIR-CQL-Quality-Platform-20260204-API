/**
 * Library: Hypertension Active Cases (高血壓確診)
 * 
 * 用途：計算高血壓活動個案數與盛行率
 * 
 * 資料來源：
 * - Condition（高血壓診斷，主要來源）
 * - Observation（血壓值，輔助判斷）
 * - MedicationRequest / MedicationStatement（降壓藥，選用）
 * 
 * 診斷基準：
 * - WHO 標準：收縮壓 ≥ 140 mmHg 或 舒張壓 ≥ 90 mmHg，或由醫師診斷
 * - 電子病歷品質指標：Condition.clinicalStatus = active
 * - eCQM (CMS165)：18-85 歲，評估期前年已有高血壓診斷
 * 
 * 國際標準參考：
 * - WHO Hypertension Definition and Prevalence Standards
 * - eCQM CMS165 (Controlling High Blood Pressure)
 * - 電子病歷品質指標通用邏輯
 * - HL7 FHIR R4: Condition / Observation / MedicationRequest
 * 
 * 擷取時間：無限大
 */

library HypertensionActiveCases version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ========================================
// 參數定義
// ========================================

/**
 * 測量期間（可自訂）
 * 預設：當年度
 */
parameter "Measurement Period" Interval<DateTime> default Interval[@2025-01-01T00:00:00.0, @2025-12-31T23:59:59.999]

// ========================================
// ValueSet 定義
// ========================================

/**
 * ValueSet: 高血壓診斷碼
 * 包含：ICD-10 I10–I15、SNOMED 59621000 (Essential hypertension)
 */
valueset "Hypertension Diagnoses": 'http://example.org/fhir/ValueSet/hypertension-diagnoses'

/**
 * ValueSet: 收縮壓觀察值
 * LOINC 8480-6 (Systolic blood pressure)
 */
valueset "Systolic Blood Pressure": 'http://example.org/fhir/ValueSet/systolic-blood-pressure'

/**
 * ValueSet: 舒張壓觀察值
 * LOINC 8462-4 (Diastolic blood pressure)
 */
valueset "Diastolic Blood Pressure": 'http://example.org/fhir/ValueSet/diastolic-blood-pressure'

/**
 * ValueSet: 降壓藥物代碼
 * ATC C02 / C03 / C07 / C08 / C09
 */
valueset "Antihypertensive Medications": 'http://example.org/fhir/ValueSet/antihypertensive-medications'

// ========================================
// 一、資料擷取：Condition（高血壓診斷）
// ========================================

/**
 * 所有高血壓診斷紀錄（活動狀態、已確認）
 * 支援代碼：ICD-10 I10–I15、SNOMED 59621000
 */
define "Hypertension Conditions":
  [Condition] C
    where C.code in "Hypertension Diagnoses"
      and exists(C.clinicalStatus.coding Coding 
        where Coding.system.value = 'http://terminology.hl7.org/CodeSystem/condition-clinical'
          and Coding.code.value = 'active')
      and (exists(C.verificationStatus.coding Coding 
        where Coding.system.value = 'http://terminology.hl7.org/CodeSystem/condition-ver-status'
          and Coding.code.value = 'confirmed')
        or C.verificationStatus is null)

/**
 * 所有高血壓診斷（不限狀態，用於檢查資料存在）
 */
define "All Hypertension Conditions":
  [Condition] C
    where C.code in "Hypertension Diagnoses"

/**
 * 檢查：是否有高血壓診斷資料
 */
define "Has Condition Data":
  exists([Condition])

/**
 * 高血壓診斷資料狀態訊息
 */
define "Condition Data Status":
  if "Has Condition Data" then 
    '已找到 Condition 資料'
  else 
    'FHIR 無資料記載 - Condition'

// ========================================
// 1-1. 高血壓異常血壓觀察值（支援標準2）
// ========================================

/**
 * 高血壓異常血壓觀察值
 * 標準：收縮壓 >= 140 mmHg 或 舒張壓 >= 90 mmHg
 */
define "Abnormal Blood Pressure Observations":
  (
    [Observation: "Systolic Blood Pressure"] O
      where O.status in { 'final', 'amended', 'corrected' }
        and (O.value as Quantity) >= 140 'mm[Hg]'
  )
  union
  (
    [Observation: "Diastolic Blood Pressure"] O
      where O.status in { 'final', 'amended', 'corrected' }
        and (O.value as Quantity) >= 90 'mm[Hg]'
  )

// ========================================
// 1-2. 降壓藥物處方（支援標準3）
// ========================================

/**
 * 活動中的降壓藥處方
 */
define "Active Antihypertensive Medications":
  [MedicationRequest] M
    where (M.medication as CodeableConcept) in "Antihypertensive Medications"
      and M.status in { 'active', 'completed' }
      and M.intent = 'order'

// ========================================
// 二、國際標準：高血壓確診邏輯（完全去重）
// ========================================

/**
 * 標準1：至少兩次不同日期的高血壓診斷（ICD-10 I10-I15）
 * 國際標準：每個病人只計算一次
 */
define "Patients with Multiple Hypertension Diagnoses":
  distinct(
    (from "Hypertension Conditions" C1,
          "Hypertension Conditions" C2
     where C1.subject.reference = C2.subject.reference
       and C1.id != C2.id
       and date from C1.recordedDate != date from C2.recordedDate
     return C1.subject.reference)
  )

/**
 * 標準2：1次診斷 + 至少2次不同日期的高血壓異常血壓
 * 國際標準：每個病人只計算一次
 */
define "Patients with Diagnosis and Abnormal BP":
  distinct(
    (from "Hypertension Conditions" C,
          "Abnormal Blood Pressure Observations" BP1,
          "Abnormal Blood Pressure Observations" BP2
     where C.subject.reference = BP1.subject.reference
       and BP1.subject.reference = BP2.subject.reference
       and BP1.id != BP2.id
       and date from (BP1.effective as dateTime) != date from (BP2.effective as dateTime)
     return C.subject.reference)
  )

/**
 * 標準3：長期服用降壓藥（處方 >= 90天或持續處方）
 * 國際標準：每個病人只計算一次
 */
define "Patients with Long Term Antihypertensive Use":
  distinct(
    "Active Antihypertensive Medications" M
      where M.dispenseRequest.numberOfRepeatsAllowed >= 2
      return M.subject.reference
  )

/**
 * 確診高血壓病人（符合任一標準，完全去重）
 * 國際標準：
 *   - 至少2次不同日期診斷（ICD-10 I10-I15）
 *   - 或 1次診斷 + 2次不同日期的異常血壓
 *   - 或 長期服用降壓藥
 * 每個病人只計算一次（使用 distinct）
 */
define "Confirmed Hypertension Patients":
  distinct(
    "Patients with Multiple Hypertension Diagnoses"
    union "Patients with Diagnosis and Abnormal BP"
    union "Patients with Long Term Antihypertensive Use"
  )

// ========================================
// 二、資料擷取：Patient（病人資訊）
// ========================================

/**
 * 所有病人資料
 */
define "All Patients":
  [Patient]

/**
 * 檢查：是否有病人資料
 */
define "Has Patient Data":
  exists([Patient])

/**
 * 病人資料狀態訊息
 */
define "Patient Data Status":
  if "Has Patient Data" then 
    '已找到 Patient 資料'
  else 
    'FHIR 無資料記載 - Patient'

// ========================================
// 三、資料擷取：Observation（血壓值，輔助）
// ========================================

/**
 * 收縮壓觀察值（測量期間內）
 * LOINC 8480-6
 */
define "Systolic BP Observations":
  [Observation] O
    where O.code in "Systolic Blood Pressure"
      and O.status in {'final', 'amended', 'corrected'}
      and O.effective during "Measurement Period"

/**
 * 舒張壓觀察值（測量期間內）
 * LOINC 8462-4
 */
define "Diastolic BP Observations":
  [Observation] O
    where O.code in "Diastolic Blood Pressure"
      and O.status in {'final', 'amended', 'corrected'}
      and O.effective during "Measurement Period"

/**
 * 高血壓值觀察（WHO 標準：收縮壓 ≥ 140 或 舒張壓 ≥ 90）
 */
define "Hypertensive BP Observations":
  ("Systolic BP Observations" S where S.value as FHIR.Quantity >= 140 'mm[Hg]')
    union
  ("Diastolic BP Observations" D where D.value as FHIR.Quantity >= 90 'mm[Hg]')

// ========================================
// 四、高血壓病人定義（不重複計數）
// ========================================

/**
 * HTN_ACTIVE_COUNT：高血壓活動個案（所有年齡）
 * 基於 Condition 診斷紀錄（不重複計數）
 */
define "Hypertension Patients":
  "All Patients" P
    where exists(
      "Hypertension Conditions" C 
        where C.subject.reference = 'Patient/' + P.id.value
    )

/**
 * 高血壓活動個案數
 */
define "Hypertension Active Case Count":
  Count("Hypertension Patients")

/**
 * 嚴格版：≥2 次高血壓診斷者（提高特異性）
 */
define "Hypertension Patients 2+ Diagnoses":
  "All Patients" P
    where Count(
      "Hypertension Conditions" C 
        where C.subject.reference = 'Patient/' + P.id.value
    ) >= 2

/**
 * 嚴格版高血壓個案數
 */
define "Hypertension Strict Case Count":
  Count("Hypertension Patients 2+ Diagnoses")

// ========================================
// 五、族群定義（用於盛行率計算）
// ========================================

/**
 * 成人族群（≥20 歲）
 */
define "Adult Patients 20+":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 20

/**
 * 成人族群（≥18 歲，eCQM CMS165 標準）
 */
define "Adult Patients 18+":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 18

/**
 * 中老年族群（≥65 歲）
 */
define "Elderly Patients 65+":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 65

/**
 * eCQM 標準族群（18–85 歲）
 */
define "Adult Patients 18-85":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 18
      and CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") <= 85

// ========================================
// 六、高血壓病人（分族群）
// ========================================

/**
 * 成人高血壓病人（≥20 歲）
 */
define "Hypertension Adult Patients 20+":
  "Adult Patients 20+" P
    where exists(
      "Hypertension Conditions" C 
        where C.subject.reference = 'Patient/' + P.id.value
    )

/**
 * 成人高血壓病人（≥18 歲）
 */
define "Hypertension Adult Patients 18+":
  "Adult Patients 18+" P
    where exists(
      "Hypertension Conditions" C 
        where C.subject.reference = 'Patient/' + P.id.value
    )

/**
 * 中老年高血壓病人（≥65 歲）
 */
define "Hypertension Elderly Patients 65+":
  "Elderly Patients 65+" P
    where exists(
      "Hypertension Conditions" C 
        where C.subject.reference = 'Patient/' + P.id.value
    )

/**
 * eCQM 標準高血壓病人（18–85 歲）
 */
define "Hypertension Patients 18-85":
  "Adult Patients 18-85" P
    where exists(
      "Hypertension Conditions" C 
        where C.subject.reference = 'Patient/' + P.id.value
    )

// ========================================
// 七、盛行率計算（Prevalence）
// ========================================

/**
 * HTN_PREV_ADULT：成人高血壓盛行率（≥20 歲）
 * 單位：百分比 (%)
 * 公式：(高血壓病人數 / 成人總人數) × 100%
 */
define "Hypertension Prevalence Adult 20+":
  if Count("Adult Patients 20+") > 0 then
    Round((Count("Hypertension Adult Patients 20+") * 100.0) / Count("Adult Patients 20+"), 2)
  else
    null

/**
 * 成人高血壓盛行率（≥18 歲）
 * 單位：百分比 (%)
 */
define "Hypertension Prevalence Adult 18+":
  if Count("Adult Patients 18+") > 0 then
    Round((Count("Hypertension Adult Patients 18+") * 100.0) / Count("Adult Patients 18+"), 2)
  else
    null

/**
 * HTN_PREV_65P：≥65 歲高血壓盛行率
 * 單位：百分比 (%)
 */
define "Hypertension Prevalence 65+":
  if Count("Elderly Patients 65+") > 0 then
    Round((Count("Hypertension Elderly Patients 65+") * 100.0) / Count("Elderly Patients 65+"), 2)
  else
    null

/**
 * eCQM 標準盛行率（18–85 歲）
 * 單位：百分比 (%)
 */
define "Hypertension Prevalence 18-85":
  if Count("Adult Patients 18-85") > 0 then
    Round((Count("Hypertension Patients 18-85") * 100.0) / Count("Adult Patients 18-85"), 2)
  else
    null

/**
 * 全人口盛行率
 * 單位：百分比 (%)
 */
define "Hypertension Prevalence All":
  if Count("All Patients") > 0 then
    Round((Count("Hypertension Patients") * 100.0) / Count("All Patients"), 2)
  else
    null

// ========================================
// 八、新發個案（選用）
// ========================================

/**
 * HTN_NEW_CASES：新發高血壓個案
 * 定義：onset 或 recordedDate 在測量期間內
 */
define "New Hypertension Cases":
  "All Patients" P
    where exists(
      "Hypertension Conditions" C 
        where C.subject.reference = 'Patient/' + P.id.value
          and (
            C.onset during "Measurement Period"
            or C.recordedDate during "Measurement Period"
          )
    )

/**
 * 新發個案數
 */
define "New Hypertension Case Count":
  Count("New Hypertension Cases")

// ========================================
// 九、詳細統計資訊
// ========================================

/**
 * 活動個案統計
 */
define "Active Cases Statistics":
  Tuple {
    indicatorCode: 'HTN_ACTIVE_COUNT',
    description: '高血壓活動個案數',
    totalCases: "Hypertension Active Case Count",
    strictCases: "Hypertension Strict Case Count",
    strictDescription: '≥2 次診斷（嚴格版）',
    unit: '人'
  }

/**
 * 成人盛行率統計（≥20 歲）
 */
define "Adult Prevalence Statistics 20+":
  Tuple {
    indicatorCode: 'HTN_PREV_ADULT',
    description: '成人高血壓盛行率（≥20 歲）',
    targetPopulation: Count("Adult Patients 20+"),
    hypertensionCases: Count("Hypertension Adult Patients 20+"),
    prevalence: "Hypertension Prevalence Adult 20+",
    unit: '%'
  }

/**
 * 成人盛行率統計（≥18 歲）
 */
define "Adult Prevalence Statistics 18+":
  Tuple {
    description: '成人高血壓盛行率（≥18 歲）',
    targetPopulation: Count("Adult Patients 18+"),
    hypertensionCases: Count("Hypertension Adult Patients 18+"),
    prevalence: "Hypertension Prevalence Adult 18+",
    unit: '%'
  }

/**
 * 中老年盛行率統計（≥65 歲）
 */
define "Elderly Prevalence Statistics":
  Tuple {
    indicatorCode: 'HTN_PREV_65P',
    description: '≥65 歲高血壓盛行率',
    targetPopulation: Count("Elderly Patients 65+"),
    hypertensionCases: Count("Hypertension Elderly Patients 65+"),
    prevalence: "Hypertension Prevalence 65+",
    unit: '%'
  }

/**
 * eCQM 標準統計（18–85 歲）
 */
define "eCQM Prevalence Statistics":
  Tuple {
    description: 'eCQM 標準高血壓盛行率（18–85 歲）',
    targetPopulation: Count("Adult Patients 18-85"),
    hypertensionCases: Count("Hypertension Patients 18-85"),
    prevalence: "Hypertension Prevalence 18-85",
    unit: '%',
    standard: 'CMS165'
  }

/**
 * 全人口盛行率統計
 */
define "All Population Prevalence Statistics":
  Tuple {
    description: '全人口高血壓盛行率',
    targetPopulation: Count("All Patients"),
    hypertensionCases: Count("Hypertension Patients"),
    prevalence: "Hypertension Prevalence All",
    unit: '%'
  }

/**
 * 新發個案統計
 */
define "New Cases Statistics":
  Tuple {
    indicatorCode: 'HTN_NEW_CASES',
    description: '新發高血壓個案數',
    newCases: "New Hypertension Case Count",
    measurementPeriod: "Measurement Period",
    unit: '人'
  }

// ========================================
// 十、輔助資訊（血壓觀察值）
// ========================================

/**
 * 血壓觀察值統計（輔助）
 */
define "Blood Pressure Statistics":
  Tuple {
    systolicObservations: Count("Systolic BP Observations"),
    diastolicObservations: Count("Diastolic BP Observations"),
    hypertensiveBPCount: Count("Hypertensive BP Observations"),
    hypertensiveBPDescription: '符合 WHO 高血壓標準之血壓觀察值（≥140/90 mmHg）'
  }

// ========================================
// 十一、資料完整性檢查
// ========================================

/**
 * 整體資料狀態檢查
 */
define "Data Availability Check":
  Tuple {
    hasConditionData: "Has Condition Data",
    hasPatientData: "Has Patient Data",
    conditionStatus: "Condition Data Status",
    patientStatus: "Patient Data Status",
    hasHypertensionData: exists("All Hypertension Conditions"),
    hypertensionDataStatus: 
      if exists("All Hypertension Conditions") then
        '已找到高血壓診斷資料'
      else
        'FHIR 無資料記載 - 高血壓診斷',
    canCalculate: "Has Condition Data" and "Has Patient Data" and exists("All Hypertension Conditions"),
    message: 
      if "Has Condition Data" and "Has Patient Data" and exists("All Hypertension Conditions") then
        '資料完整，可進行計算'
      else if not "Has Condition Data" then
        'FHIR 無資料記載 - Condition'
      else if not "Has Patient Data" then
        'FHIR 無資料記載 - Patient'
      else
        'FHIR 無資料記載 - 高血壓診斷'
  }

// ========================================
// 十二、主要結果輸出
// ========================================

/**
 * 主要指標：高血壓活動個案與成人盛行率
 */
define "Primary Indicators":
  if "Data Availability Check".canCalculate then
    Tuple {
      activeCases: "Active Cases Statistics",
      adultPrevalence: "Adult Prevalence Statistics 20+",
      elderlyPrevalence: "Elderly Prevalence Statistics"
    }
  else
    Tuple {
      activeCases: Tuple {
        indicatorCode: 'HTN_ACTIVE_COUNT',
        description: '高血壓活動個案數',
        totalCases: 0,
        strictCases: 0,
        unit: '人',
        error: "Data Availability Check".message
      },
      adultPrevalence: Tuple {
        indicatorCode: 'HTN_PREV_ADULT',
        description: '成人高血壓盛行率（≥20 歲）',
        targetPopulation: 0,
        hypertensionCases: 0,
        prevalence: null,
        unit: '%',
        error: "Data Availability Check".message
      },
      elderlyPrevalence: Tuple {
        indicatorCode: 'HTN_PREV_65P',
        description: '≥65 歲高血壓盛行率',
        targetPopulation: 0,
        hypertensionCases: 0,
        prevalence: null,
        unit: '%',
        error: "Data Availability Check".message
      }
    }

/**
 * 完整報告
 */
define "Full Report":
  Tuple {
    measurementPeriod: "Measurement Period",
    dataStatus: "Data Availability Check",
    primary: "Primary Indicators",
    adult18Plus: if "Data Availability Check".canCalculate then "Adult Prevalence Statistics 18+" else null,
    eCQMStandard: if "Data Availability Check".canCalculate then "eCQM Prevalence Statistics" else null,
    allPopulation: if "Data Availability Check".canCalculate then "All Population Prevalence Statistics" else null,
    newCases: if "Data Availability Check".canCalculate then "New Cases Statistics" else null,
    bloodPressure: if "Data Availability Check".canCalculate then "Blood Pressure Statistics" else null,
    diagnosticCriteria: Tuple {
      whoStandard: '收縮壓 ≥ 140 mmHg 或 舒張壓 ≥ 90 mmHg，或由醫師診斷',
      conditionStatus: 'clinicalStatus = active',
      verificationStatus: 'confirmed or null'
    },
    internationalStandards: List{
      'WHO Hypertension Definition and Prevalence Standards',
      'eCQM CMS165 (Controlling High Blood Pressure)',
      '電子病歷品質指標通用邏輯',
      'HL7 FHIR R4: Condition / Observation / MedicationRequest'
    }
  }
