/**
 * ESG CQL - Electronic Health Record (EHR) Adoption Rate（電子病歷採用率）
 * 基於 HIMSS EMRAM / SASB HC-DY-260a.3 標準
 * FHIR R4 對應：Patient / Encounter / DocumentReference / Observation / Procedure
 * 擷取時間：無限大
 * 生成日期：2025-11-14
 */

library EHR_Adoption_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ========== 代碼系統定義 ==========

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "DocumentType": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// ========== LOINC 代碼（臨床文件類型）==========

code "Clinical Document Code": '34133-9' from "LOINC" display 'Summarization of episode note'
code "Discharge Summary Code": '18842-5' from "LOINC" display 'Discharge summary'
code "Progress Note Code": '11506-3' from "LOINC" display 'Progress note'
code "History and Physical Code": '34117-2' from "LOINC" display 'History and physical note'
code "Consultation Note Code": '11488-4' from "LOINC" display 'Consultation note'

// ========== ValueSet 定義 ==========

// 電子病歷文件類型
valueset "EHR Document Types": 'http://esg.fhir.org/ValueSet/ehr-document-types'
valueset "Clinical Document Types": 'http://esg.fhir.org/ValueSet/clinical-document-types'

// 電子處方
valueset "Electronic Prescription": 'http://esg.fhir.org/ValueSet/electronic-prescription'

// 電子檢驗報告
valueset "Electronic Lab Results": 'http://esg.fhir.org/ValueSet/electronic-lab-results'

// 電子影像報告
valueset "Electronic Imaging Reports": 'http://esg.fhir.org/ValueSet/electronic-imaging-reports'

// ========== 參數定義 ==========

parameter MeasurementPeriod default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]

// ========== 上下文 ==========

context Patient

// ========== 基礎資料擷取 ==========

/**
 * 1. 所有病人記錄
 */
define "All Patients":
  [Patient] P
    where P.active.value = true

/**
 * 2. 所有就醫記錄（Encounter）
 */
define "All Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.period.start during MeasurementPeriod

/**
 * 3. 電子病歷文件（DocumentReference）
 */
define "EHR Documents":
  [DocumentReference] D
    where D.status.value in {'current', 'superseded'}
      and D.date during MeasurementPeriod
      and D.content is not null

/**
 * 4. 電子檢驗結果（Observation - Lab）
 */
define "Electronic Lab Observations":
  [Observation] O
    where O.status.value in {'final', 'amended', 'corrected'}
      and O.effective during MeasurementPeriod
      and O.category.coding.code.value contains 'laboratory'

/**
 * 5. 電子處方（MedicationRequest）
 */
define "Electronic Prescriptions":
  [MedicationRequest] M
    where (M.status.value = 'active' or M.status.value = 'completed')
      and M.intent.value in {'order', 'original-order'}
      and M.authoredOn during MeasurementPeriod

/**
 * 6. 電子處置記錄（Procedure）
 */
define "Electronic Procedures":
  [Procedure] P
    where P.status.value = 'completed'
      and P.performed during MeasurementPeriod

/**
 * 7. 電子影像報告（DiagnosticReport）
 */
define "Electronic Imaging Diagnostic Reports":
  [DiagnosticReport] R
    where R.status.value in {'final', 'amended', 'corrected'}
      and R.effective during MeasurementPeriod
      and R.category.coding.code.value contains 'radiology'

// ========== 病人層級 EHR 採用指標 ==========

/**
 * 有電子病歷記錄的病人
 */
define "Patients with EHR":
  distinct(
    "All Encounters" E
      where exists([DocumentReference: subject.reference = E.subject.reference] D where D.date during MeasurementPeriod)
        or exists([Observation: subject.reference = E.subject.reference] O where O.effective during MeasurementPeriod)
        or exists([MedicationRequest: subject.reference = E.subject.reference] M where M.authoredOn during MeasurementPeriod)
        or exists([Procedure: subject.reference = E.subject.reference] P where P.performed during MeasurementPeriod)
      return E.subject.reference
  )

/**
 * 總就醫病人數
 */
define "Total Patient Count":
  Count(
    distinct(
      "All Encounters" E
        return E.subject.reference
    )
  )

/**
 * 有電子病歷的病人數
 */
define "Patients with EHR Count":
  Count("Patients with EHR")

/**
 * EHR 採用率（病人層級）
 * 公式：(有電子病歷的病人數 / 總就醫病人數) × 100%
 */
define "EHR Adoption Rate - Patient Level (%)":
  if "Total Patient Count" > 0 then
    ("Patients with EHR Count" * 100.0) / "Total Patient Count"
  else
    null

// ========== 就醫次數層級 EHR 採用指標 ==========

/**
 * 有電子病歷的就醫次數
 */
define "Encounters with EHR":
  "All Encounters" E
    where exists([DocumentReference: subject.reference = E.subject.reference] D where D.date during E.period)
      or exists([Observation: subject.reference = E.subject.reference] O where O.effective during E.period)
      or exists([MedicationRequest: subject.reference = E.subject.reference] M where M.authoredOn during E.period)
      or exists([Procedure: subject.reference = E.subject.reference] P where P.performed during E.period)

/**
 * 總就醫次數
 */
define "Total Encounter Count":
  Count("All Encounters")

/**
 * 有電子病歷的就醫次數
 */
define "Encounters with EHR Count":
  Count("Encounters with EHR")

/**
 * EHR 採用率（就醫次數層級）
 * 公式：(有電子病歷的就醫次數 / 總就醫次數) × 100%
 */
define "EHR Adoption Rate - Encounter Level (%)":
  if "Total Encounter Count" > 0 then
    ("Encounters with EHR Count" * 100.0) / "Total Encounter Count"
  else
    null

// ========== 功能別 EHR 採用指標 ==========

/**
 * 電子病歷文件完整率
 * 計算有完整電子文件的就醫次數比例
 */
define "EHR Documentation Rate (%)":
  if "Total Encounter Count" > 0 then
    (Count(
      "All Encounters" E
        where exists([DocumentReference: subject.reference = E.subject.reference] D where D.date during E.period)
    ) * 100.0) / "Total Encounter Count"
  else
    null

/**
 * 電子處方使用率
 * 公式：(有電子處方的就醫次數 / 總就醫次數) × 100%
 */
define "Electronic Prescription Rate (%)":
  if "Total Encounter Count" > 0 then
    (Count(
      "All Encounters" E
        where exists([MedicationRequest: subject.reference = E.subject.reference] M 
          where M.authoredOn during E.period 
            and (M.status.value = 'active' or M.status.value = 'completed'))
    ) * 100.0) / "Total Encounter Count"
  else
    null

/**
 * 電子檢驗結果記錄率
 * 公式：(有電子檢驗結果的就醫次數 / 總就醫次數) × 100%
 */
define "Electronic Lab Results Rate (%)":
  if "Total Encounter Count" > 0 then
    (Count(
      "All Encounters" E
        where exists([Observation: subject.reference = E.subject.reference] O 
          where O.effective during E.period 
            and O.status.value in {'final', 'amended', 'corrected'}
            and O.category.coding.code.value contains 'laboratory')
    ) * 100.0) / "Total Encounter Count"
  else
    null

/**
 * 電子影像報告記錄率
 * 公式：(有電子影像報告的就醫次數 / 總就醫次數) × 100%
 */
define "Electronic Imaging Rate (%)":
  if "Total Encounter Count" > 0 then
    (Count(
      "All Encounters" E
        where exists([DiagnosticReport: subject.reference = E.subject.reference] R 
          where R.effective during E.period 
            and R.status.value in {'final', 'amended', 'corrected'}
            and R.category.coding.code.value contains 'radiology')
    ) * 100.0) / "Total Encounter Count"
  else
    null

/**
 * 電子處置記錄率
 * 公式：(有電子處置記錄的就醫次數 / 總就醫次數) × 100%
 */
define "Electronic Procedure Rate (%)":
  if "Total Encounter Count" > 0 then
    (Count(
      "All Encounters" E
        where exists([Procedure: subject.reference = E.subject.reference] P 
          where P.performed during E.period 
            and P.status.value = 'completed')
    ) * 100.0) / "Total Encounter Count"
  else
    null

// ========== 資料量統計 ==========

/**
 * 電子病歷文件總數
 */
define "Total EHR Documents":
  Count("EHR Documents")

/**
 * 電子處方總數
 */
define "Total Electronic Prescriptions":
  Count("Electronic Prescriptions")

/**
 * 電子檢驗結果總數
 */
define "Total Electronic Lab Results":
  Count("Electronic Lab Observations")

/**
 * 電子影像報告總數
 */
define "Total Electronic Imaging Reports":
  Count("Electronic Imaging Diagnostic Reports")

/**
 * 電子處置記錄總數
 */
define "Total Electronic Procedures":
  Count("Electronic Procedures")

// ========== HIMSS EMRAM 成熟度評估 ==========

/**
 * HIMSS EMRAM Level 評估（簡化版）
 * Level 0-7，依據電子化程度評分
 */
define "HIMSS EMRAM Level":
  case
    when "EHR Adoption Rate - Encounter Level (%)" >= 95.0 
      and "Electronic Prescription Rate (%)" >= 95.0
      and "Electronic Lab Results Rate (%)" >= 95.0
      and "Electronic Imaging Rate (%)" >= 90.0
      and "Electronic Procedure Rate (%)" >= 90.0
      then 7  // 完全無紙化
    when "EHR Adoption Rate - Encounter Level (%)" >= 85.0
      and "Electronic Prescription Rate (%)" >= 85.0
      and "Electronic Lab Results Rate (%)" >= 85.0
      then 6  // 醫師文件電子化
    when "EHR Adoption Rate - Encounter Level (%)" >= 70.0
      and "Electronic Prescription Rate (%)" >= 70.0
      then 5  // 閉環式給藥
    when "EHR Adoption Rate - Encounter Level (%)" >= 50.0
      then 4  // CPOE（電腦醫囑輸入）
    when "EHR Documentation Rate (%)" >= 30.0
      then 3  // 護理/臨床文件
    when "Electronic Lab Results Rate (%)" >= 20.0
      then 2  // CDR（臨床資料儲存庫）
    when exists("EHR Documents") or exists("Electronic Lab Results")
      then 1  // 部分系統安裝
    else 0    // 全紙本
  end

/**
 * EMRAM Level 描述
 */
define "EMRAM Level Description":
  case "HIMSS EMRAM Level"
    when 7 then '完全無紙化 EHR 環境'
    when 6 then '醫師文件電子化與CDSS'
    when 5 then '閉環式給藥管理'
    when 4 then 'CPOE 電腦醫囑輸入'
    when 3 then '護理與臨床文件電子化'
    when 2 then '臨床資料儲存庫'
    when 1 then '部分系統安裝'
    else '全紙本作業'
  end

// ========== 最終報告輸出 ==========

/**
 * ESG 電子病歷採用率綜合報告
 */
define "ESG EHR Adoption Report":
  if not exists("All Encounters") then
    '【FHIR 無資料記載】'
  else
    {
      reporting_period: MeasurementPeriod,
      
      // 基礎統計
      total_patients: "Total Patient Count",
      total_encounters: "Total Encounter Count",
      patients_with_ehr: "Patients with EHR Count",
      encounters_with_ehr: "Encounters with EHR Count",
      
      // EHR 採用率（主要指標）
      ehr_adoption_rate_patient_percent: "EHR Adoption Rate - Patient Level (%)",
      ehr_adoption_rate_encounter_percent: "EHR Adoption Rate - Encounter Level (%)",
      
      // 功能別採用率
      ehr_documentation_rate_percent: "EHR Documentation Rate (%)",
      electronic_prescription_rate_percent: "Electronic Prescription Rate (%)",
      electronic_lab_results_rate_percent: "Electronic Lab Results Rate (%)",
      electronic_imaging_rate_percent: "Electronic Imaging Rate (%)",
      electronic_procedure_rate_percent: "Electronic Procedure Rate (%)",
      
      // 資料量統計
      total_ehr_documents: "Total EHR Documents",
      total_electronic_prescriptions: "Total Electronic Prescriptions",
      total_electronic_lab_results: "Total Electronic Lab Results",
      total_electronic_imaging_reports: "Total Electronic Imaging Reports",
      total_electronic_procedures: "Total Electronic Procedures",
      
      // HIMSS EMRAM 成熟度
      himss_emram_level: "HIMSS EMRAM Level",
      emram_level_description: "EMRAM Level Description",
      
      // 資料狀態
      data_status: 
        if not exists("All Encounters") then 'FHIR 無資料記載'
        else if "Total Encounter Count" = 0 then '無就醫記錄'
        else if "EHR Adoption Rate - Encounter Level (%)" is null then 'EHR 資料不完整'
        else '資料完整',
      
      // 標準引用
      standards: {
        himss: 'HIMSS EMRAM (Electronic Medical Record Adoption Model)',
        sasb: 'SASB HC-DY-260a.3 (EHR Adoption)',
        fhir: 'HL7 FHIR R4',
        resources: 'Patient / Encounter / DocumentReference / Observation / MedicationRequest / Procedure / DiagnosticReport'
      }
    }

/**
 * 資料完整性檢查
 */
define "Data Completeness Check":
  {
    has_patient_data: exists("All Patients"),
    has_encounter_data: exists("All Encounters"),
    has_ehr_documents: exists("EHR Documents"),
    has_electronic_prescriptions: exists("Electronic Prescriptions"),
    has_electronic_lab_results: exists("Electronic Lab Results"),
    has_electronic_imaging_reports: exists("Electronic Imaging Reports"),
    has_electronic_procedures: exists("Electronic Procedures"),
    
    message: 
      if not exists("All Encounters") then 
        'FHIR 無資料記載 - 缺少就醫記錄'
      else if not exists("EHR Documents") and not exists("Electronic Lab Results") and not exists("Electronic Prescriptions") then 
        '警告 - 缺少電子病歷相關資料，無法計算採用率'
      else if "Total Encounter Count" = 0 then
        '警告 - 就醫次數為零'
      else 
        '資料完整',
    
    completeness_score: 
      if exists("All Encounters") then
        (
          (if exists("EHR Documents") then 1 else 0) +
          (if exists("Electronic Prescriptions") then 1 else 0) +
          (if exists("Electronic Lab Results") then 1 else 0) +
          (if exists("Electronic Imaging Reports") then 1 else 0) +
          (if exists("Electronic Procedures") then 1 else 0)
        ) * 20.0
      else
        0.0
  }

/**
 * EHR 採用趨勢分析（按年分）
 */
define "EHR Adoption by Year":
  if exists("All Encounters") then
    Count("All Encounters" E where year from E.period.start = year from Today())
  else
    0
