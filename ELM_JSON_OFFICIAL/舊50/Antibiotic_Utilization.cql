/**
 * ESG CQL - Antibiotic Utilization（抗生素使用率）
 * 基於 WHO ATC/DDD 標準 + SASB HC-DY-260a.2
 * FHIR R4 對應：MedicationRequest / MedicationAdministration / MedicationDispense / Encounter
 * 擷取時間：無限大
 * 生成日期：2025-11-14
 */

library Antibiotic_Utilization version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ========== 代碼系統定義 ==========

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "RxNorm": 'http://www.nlm.nih.gov/research/umls/rxnorm'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "NHI": 'http://www.nhi.gov.tw/medication'

// ========== ValueSet 定義 ==========

// 抗生素分類（ATC J01*）
valueset "ESG Antibiotic All": 'http://esg.fhir.org/ValueSet/antibiotic-all'
valueset "ESG Antibiotic Access": 'http://esg.fhir.org/ValueSet/antibiotic-access'
valueset "ESG Antibiotic Watch": 'http://esg.fhir.org/ValueSet/antibiotic-watch'
valueset "ESG Antibiotic Reserve": 'http://esg.fhir.org/ValueSet/antibiotic-reserve'

// 醫囑與給藥
valueset "ESG Antibiotic Order": 'http://esg.fhir.org/ValueSet/antibiotic-order'
valueset "ESG Antibiotic Administration": 'http://esg.fhir.org/ValueSet/antibiotic-administration'

// 符合指引
valueset "ESG Guideline Compliant Orders": 'http://esg.fhir.org/ValueSet/guideline-compliant-orders'

// ========== 參數定義 ==========

parameter MeasurementPeriod default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]

// ========== 上下文 ==========

context Patient

// ========== 基礎資料擷取 ==========

/**
 * 1. 所有抗生素醫囑（MedicationRequest）
 */
define "All Antibiotic Orders":
  [MedicationRequest] M
    where (M.status.value = 'active' or M.status.value = 'completed')
      and M.intent.value in {'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order'}
      and M.authoredOn during MeasurementPeriod
      and (M.medication as FHIR.CodeableConcept) is not null

/**
 * 2. 抗生素給藥記錄（MedicationAdministration）
 */
define "All Antibiotic Administrations":
  [MedicationAdministration] M
    where (M.status.value = 'in-progress' or M.status.value = 'completed')
      and M.effective during MeasurementPeriod
      and (M.medication as FHIR.CodeableConcept) is not null

/**
 * 3. 抗生素領藥記錄（MedicationDispense）
 */
define "All Antibiotic Dispenses":
  [MedicationDispense] M
    where (M.status.value = 'completed' or M.status.value = 'in-progress')
      and M.whenHandedOver during MeasurementPeriod
      and (M.medication as FHIR.CodeableConcept) is not null

/**
 * 4. 住院記錄（Encounter - Inpatient）
 */
define "Inpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and E.class.code in {'IMP', 'ACUTE', 'NONAC'}
      and E.period.start during MeasurementPeriod

/**
 * 5. 門診記錄（Encounter - Outpatient）
 */
define "Outpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and E.class.code in {'AMB', 'EMER'}
      and E.period.start during MeasurementPeriod

/**
 * 6. 所有就醫記錄
 */
define "All Encounters":
  "Inpatient Encounters" union "Outpatient Encounters"

// ========== WHO AWaRe 分類 ==========

/**
 * Access 類抗生素（可廣泛使用）
 */
define "Access Antibiotic Administrations":
  "All Antibiotic Administrations" M
    where (M.medication as FHIR.CodeableConcept) in "ESG Antibiotic Access"

/**
 * Watch 類抗生素（需謹慎監測）
 */
define "Watch Antibiotic Administrations":
  "All Antibiotic Administrations" M
    where (M.medication as FHIR.CodeableConcept) in "ESG Antibiotic Watch"

/**
 * Reserve 類抗生素（最後防線）
 */
define "Reserve Antibiotic Administrations":
  "All Antibiotic Administrations" M
    where (M.medication as FHIR.CodeableConcept) in "ESG Antibiotic Reserve"

// ========== 基礎計數指標 ==========

/**
 * 抗生素醫囑總數
 */
define "Total Antibiotic Orders":
  Count("All Antibiotic Orders")

/**
 * 抗生素給藥總次數
 */
define "Total Antibiotic Administrations":
  Count("All Antibiotic Administrations")

/**
 * 使用抗生素的病人數（去重）
 */
define "Antibiotic Use Patient Count":
  Count(
    distinct(
      "All Antibiotic Administrations" M
        return M.subject.reference
    )
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

// ========== 住院日數計算（Bed-Days / Patient-Days）==========

/**
 * 總住院日數（Bed-Days）
 */
define "Total Bed Days":
  if exists("Inpatient Encounters") then
    Sum(
      "Inpatient Encounters" E
        return days between start of E.period and end of E.period
    )
  else
    null

/**
 * 總病人日數（Patient-Days）- 含住院與門診
 */
define "Total Patient Days":
  if exists("All Encounters") then
    Sum(
      "All Encounters" E
        return 
          if E.class.code in {'IMP', 'ACUTE', 'NONAC'} then
            days between start of E.period and end of E.period
          else
            1
    )
  else
    null

// ========== DOT（Days of Therapy）計算 ==========

/**
 * DOT 總數（治療天數）
 * 計算方式：每個病人每天使用抗生素視為 1 DOT
 */
define "Total DOT":
  if exists("All Antibiotic Administrations") then
    Count(
      distinct(
        "All Antibiotic Administrations" M
          return Tuple {
            patient: M.subject.reference,
            date: date from start of M.effective
          }
      )
    )
  else
    null

/**
 * DOT per 1000 Patient-Days
 * 公式：(DOT 總數 × 1000) / Patient-Days
 */
define "DOT per 1000 Patient Days":
  if "Total DOT" is not null and "Total Patient Days" is not null and "Total Patient Days" > 0 then
    ("Total DOT" * 1000.0) / "Total Patient Days"
  else
    null

// ========== DDD（Defined Daily Dose）計算 ==========

/**
 * WHO DDD 標準劑量對照表（簡化版）
 * 實際應用需完整建立 WHO ATC/DDD 對照表
 */
define function WHO_DDD(medicationCode FHIR.CodeableConcept):
  case
    when exists(medicationCode.coding C where C.code.value = 'J01CA04') then 1000.0  // Amoxicillin 1g
    when exists(medicationCode.coding C where C.code.value = 'J01CR02') then 1000.0  // Amoxicillin/Clavulanate 1g
    when exists(medicationCode.coding C where C.code.value = 'J01DD04') then 2000.0  // Ceftriaxone 2g
    when exists(medicationCode.coding C where C.code.value = 'J01MA02') then 400.0   // Ciprofloxacin 400mg
    when exists(medicationCode.coding C where C.code.value = 'J01XA01') then 2000.0  // Vancomycin 2g
    when exists(medicationCode.coding C where C.code.value = 'J01DH02') then 3000.0  // Meropenem 3g
    when exists(medicationCode.coding C where C.code.value = 'J01GB06') then 240.0   // Amikacin 240mg
    when exists(medicationCode.coding C where C.code.value = 'J01AA02') then 1000.0  // Doxycycline 1g
    else 1000.0  // 預設值 1g
  end

/**
 * 計算單次給藥的 DDD
 */
define function Calculate_DDD(admin FHIR.MedicationAdministration):
  if admin.dosage.dose is not null then
    (admin.dosage.dose as FHIR.Quantity).value.value / WHO_DDD(admin.medication as FHIR.CodeableConcept)
  else
    0.0

/**
 * 總 DDD
 */
define "Total DDD":
  if exists("All Antibiotic Administrations") then
    Sum(
      "All Antibiotic Administrations" M
        return 
          if M.dosage.dose is not null then
            (M.dosage.dose as FHIR.Quantity).value.value / WHO_DDD(M.medication as FHIR.CodeableConcept)
          else
            0.0
    )
  else
    null

/**
 * DDD per 100 Bed-Days（WHO 國際標準）
 * 公式：(所有抗生素 DDD 加總 × 100) / 總 Bed-Days
 */
define "DDD per 100 Bed Days":
  if "Total DDD" is not null and "Total Bed Days" is not null and "Total Bed Days" > 0 then
    ("Total DDD" * 100.0) / "Total Bed Days"
  else
    null

// ========== 使用率指標 ==========

/**
 * 抗生素使用率（病患層級）
 * 公式：(抗生素使用病人數 / 總就醫病人數) × 100%
 */
define "Antibiotic Use Rate (%)":
  if "Antibiotic Use Patient Count" is not null and "Total Patient Count" is not null and "Total Patient Count" > 0 then
    ("Antibiotic Use Patient Count" * 100.0) / "Total Patient Count"
  else
    null

/**
 * 住院病人抗生素使用率
 */
define "Inpatient Antibiotic Use Rate (%)":
  Count(
    distinct(
      "Inpatient Encounters" E
        return E.subject.reference
    )
  )

/**
 * 門診病人抗生素使用率
 */
define "Outpatient Antibiotic Use Rate (%)":
  Count(
    distinct(
      "Outpatient Encounters" E
        return E.subject.reference
    )
  )

// ========== SASB HC-DY-260a.2：Stewardship Compliance ==========

/**
 * 符合指引的抗生素醫囑
 */
define "Guideline Compliant Orders":
  "All Antibiotic Orders" M
    where (M.medication as FHIR.CodeableConcept) in "ESG Guideline Compliant Orders"
      or exists(M.extension E where E.url.value = 'http://esg.fhir.org/StructureDefinition/guideline-compliant' and (E.value as FHIR.boolean).value = true)

/**
 * 抗生素管理遵循率（Stewardship Compliance）
 * 公式：(符合指引醫囑數 / 抗生素醫囑總數) × 100%
 */
define "Stewardship Compliance Rate (%)":
  if "Total Antibiotic Orders" > 0 then
    (Count("Guideline Compliant Orders") * 100.0) / "Total Antibiotic Orders"
  else
    null

// ========== WHO AWaRe 分布 ==========

/**
 * Access 類抗生素使用佔比（%）
 */
define "Access Antibiotic Percentage (%)":
  if "Total Antibiotic Administrations" > 0 then
    (Count("Access Antibiotic Administrations") * 100.0) / "Total Antibiotic Administrations"
  else
    null

/**
 * Watch 類抗生素使用佔比（%）
 */
define "Watch Antibiotic Percentage (%)":
  if "Total Antibiotic Administrations" > 0 then
    (Count("Watch Antibiotic Administrations") * 100.0) / "Total Antibiotic Administrations"
  else
    null

/**
 * Reserve 類抗生素使用佔比（%）
 */
define "Reserve Antibiotic Percentage (%)":
  if "Total Antibiotic Administrations" > 0 then
    (Count("Reserve Antibiotic Administrations") * 100.0) / "Total Antibiotic Administrations"
  else
    null

// ========== 最終報告輸出 ==========

/**
 * ESG 抗生素使用綜合報告
 */
define "ESG Antibiotic Utilization Report":
  if not exists("All Antibiotic Orders") and not exists("All Antibiotic Administrations") then
    '【FHIR 無資料記載】'
  else
    {
      reporting_period: MeasurementPeriod,
      
      // 基礎計數
      total_antibiotic_orders: Coalesce("Total Antibiotic Orders", 0),
      total_antibiotic_administrations: Coalesce("Total Antibiotic Administrations", 0),
      antibiotic_use_patient_count: Coalesce("Antibiotic Use Patient Count", 0),
      total_patient_count: Coalesce("Total Patient Count", 0),
      
      // 住院日數
      total_bed_days: Coalesce("Total Bed Days", 0),
      total_patient_days: Coalesce("Total Patient Days", 0),
      
      // WHO 國際標準指標
      total_dot: Coalesce("Total DOT", 0),
      dot_per_1000_patient_days: "DOT per 1000 Patient Days",
      total_ddd: "Total DDD",
      ddd_per_100_bed_days: "DDD per 100 Bed Days",
      
      // 使用率指標
      antibiotic_use_rate_percent: "Antibiotic Use Rate (%)",
      inpatient_use_rate_percent: "Inpatient Antibiotic Use Rate (%)",
      outpatient_use_rate_percent: "Outpatient Antibiotic Use Rate (%)",
      
      // SASB 管理指標
      stewardship_compliance_percent: "Stewardship Compliance Rate (%)",
      guideline_compliant_orders: Count("Guideline Compliant Orders"),
      
      // WHO AWaRe 分布
      access_antibiotic_percent: "Access Antibiotic Percentage (%)",
      watch_antibiotic_percent: "Watch Antibiotic Percentage (%)",
      reserve_antibiotic_percent: "Reserve Antibiotic Percentage (%)",
      
      // 資料狀態
      data_status: 
        if not exists("All Antibiotic Orders") and not exists("All Antibiotic Administrations") then 'FHIR 無資料記載'
        else if "Total Antibiotic Orders" = 0 and "Total Antibiotic Administrations" = 0 then '無抗生素使用記錄'
        else '資料完整',
      
      // 標準引用
      standards: {
        who: 'WHO ATC/DDD (Defined Daily Dose)',
        sasb: 'SASB HC-DY-260a.2 (Stewardship)',
        aware: 'WHO AWaRe Classification',
        fhir: 'HL7 FHIR R4',
        terminology: 'ATC / RxNorm / NHI'
      }
    }

/**
 * 資料完整性檢查
 */
define "Data Completeness Check":
  {
    has_medication_request: exists("All Antibiotic Orders"),
    has_medication_administration: exists("All Antibiotic Administrations"),
    has_medication_dispense: exists("All Antibiotic Dispenses"),
    has_encounter_data: exists("All Encounters"),
    has_inpatient_data: exists("Inpatient Encounters"),
    
    message: 
      if not exists("All Antibiotic Orders") and not exists("All Antibiotic Administrations") then 
        'FHIR 無資料記載 - 缺少抗生素醫囑與給藥記錄'
      else if not exists("All Antibiotic Administrations") then 
        '警告 - 缺少給藥記錄，無法計算 DOT/DDD'
      else if not exists("Inpatient Encounters") then 
        '警告 - 缺少住院記錄，無法計算 DDD per 100 Bed-Days'
      else if not exists("Guideline Compliant Orders") then
        '警告 - 缺少指引遵循標記，無法計算 Stewardship Compliance'
      else 
        '資料完整'
  }

/**
 * 抗生素使用明細（前 10 筆）
 */
define "Antibiotic Usage Details":
  if exists("All Antibiotic Administrations") then
    "All Antibiotic Administrations" M
      return {
        medication_name: First((M.medication as FHIR.CodeableConcept).coding).display.value,
        medication_code: First((M.medication as FHIR.CodeableConcept).coding).code.value,
        dose: (M.dosage.dose as FHIR.Quantity).value.value,
        dose_unit: (M.dosage.dose as FHIR.Quantity).unit.value,
        administration_date: date from start of M.effective,
        patient_reference: M.subject.reference.value,
        ddd: Calculate_DDD(M)
      }
      sort by administration_date desc
  else
    null
