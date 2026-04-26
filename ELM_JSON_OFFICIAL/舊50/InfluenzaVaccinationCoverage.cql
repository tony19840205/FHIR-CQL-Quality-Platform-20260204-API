/**
 * Library: Influenza Vaccination Coverage (流感疫苗施打率)
 * 
 * 用途：計算流感疫苗接種涵蓋率
 * 
 * 資料來源：
 * - Immunization（疫苗接種紀錄）
 * - Patient（病人資訊）
 * - Encounter（就醫紀錄，選用）
 * 
 * 國際標準參考：
 * - WHO Influenza Vaccine Coverage Indicator
 * - ECDC Seasonal Influenza Vaccination Guidelines
 * - HL7 FHIR R4: Immunization / Patient / Encounter
 * 
 * 擷取時間：無限大
 * 流感季定義：每年 1/1–12/31 打過就算一次
 */

library InfluenzaVaccinationCoverage version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ========================================
// 參數定義
// ========================================

/**
 * 測量期間（可自訂）
 * 預設：當年度 1/1 至 12/31
 */
parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2024-12-31T23:59:59.999]

// ========================================
// ValueSet 定義
// ========================================

/**
 * ValueSet: 流感疫苗代碼（所有類型）
 * 包含：CVX、ATC J07BB*、NHI 代碼
 */
valueset "Influenza Vaccines All": 'http://example.org/fhir/ValueSet/influenza-vaccines-all'

/**
 * ValueSet: 醫護人員角色代碼（選用）
 */
valueset "Healthcare Provider Roles": 'http://example.org/fhir/ValueSet/healthcare-provider-roles'

// ========================================
// 一、資料擷取：Immunization（疫苗接種紀錄）
// ========================================

/**
 * 所有流感疫苗接種紀錄（已完成）
 * 支援代碼：CVX、ATC J07BB*、NHI 代碼
 */
define "Influenza Immunizations":
  [Immunization] I
    where I.status = 'completed'
      and I.vaccineCode in "Influenza Vaccines All"
      and I.occurrence during "Measurement Period"

/**
 * 檢查：是否有流感疫苗接種資料
 */
define "Has Immunization Data":
  exists([Immunization])

/**
 * 流感疫苗接種資料狀態訊息
 */
define "Immunization Data Status":
  if "Has Immunization Data" then 
    '已找到 Immunization 資料'
  else 
    'FHIR 無資料記載 - Immunization'

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
// 三、族群定義
// ========================================

/**
 * 目標族群：65 歲以上（建議接種對象）
 * 指標代號：FLU_COV_65P
 */
define "Target Population 65+":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 65

/**
 * 目標族群：全人口
 * 指標代號：FLU_COV_ALL
 */
define "Target Population All":
  "All Patients"

/**
 * 目標族群：醫護人員（選用，需額外資料）
 * 指標代號：FLU_COV_HCP
 * 注意：此定義需要額外的 Practitioner 資料和適當的關聯邏輯
 */
define "Target Population Healthcare Providers":
  "All Patients" P
    where false  // 預設為空，需根據實際 FHIR 資料結構調整

// ========================================
// 四、接種者定義（分子）
// ========================================

/**
 * 65 歲以上接種者
 * WHO/ECDC 標準：在測量期間內有完成接種紀錄
 */
define "Vaccinated 65+":
  "Target Population 65+" P
    where exists(
      "Influenza Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    )

/**
 * 全人口接種者
 */
define "Vaccinated All":
  "Target Population All" P
    where exists(
      "Influenza Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    )

/**
 * 醫護人員接種者
 */
define "Vaccinated Healthcare Providers":
  "Target Population Healthcare Providers" P
    where exists(
      "Influenza Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    )

// ========================================
// 五、接種率計算（Coverage）
// ========================================

/**
 * 計算公式：WHO / ECDC 標準
 * Coverage = (接種人數 / 目標族群人數) × 100%
 */

/**
 * FLU_COV_65P：65 歲以上流感疫苗接種率
 * 單位：百分比 (%)
 */
define "Influenza Vaccination Coverage 65+":
  if Count("Target Population 65+") > 0 then
    Round((Count("Vaccinated 65+") * 100.0) / Count("Target Population 65+"), 2)
  else
    null

/**
 * FLU_COV_ALL：全人口流感疫苗接種率
 * 單位：百分比 (%)
 */
define "Influenza Vaccination Coverage All":
  if Count("Target Population All") > 0 then
    Round((Count("Vaccinated All") * 100.0) / Count("Target Population All"), 2)
  else
    null

/**
 * FLU_COV_HCP：醫護人員流感疫苗接種率
 * 單位：百分比 (%)
 */
define "Influenza Vaccination Coverage Healthcare Providers":
  if Count("Target Population Healthcare Providers") > 0 then
    Round((Count("Vaccinated Healthcare Providers") * 100.0) / Count("Target Population Healthcare Providers"), 2)
  else
    null

// ========================================
// 六、詳細統計資訊
// ========================================

/**
 * 65 歲以上族群統計
 */
define "Statistics 65+":
  Tuple {
    targetPopulation: Count("Target Population 65+"),
    vaccinatedCount: Count("Vaccinated 65+"),
    coverageRate: "Influenza Vaccination Coverage 65+",
    unit: '%',
    indicatorCode: 'FLU_COV_65P'
  }

/**
 * 全人口統計
 */
define "Statistics All":
  Tuple {
    targetPopulation: Count("Target Population All"),
    vaccinatedCount: Count("Vaccinated All"),
    coverageRate: "Influenza Vaccination Coverage All",
    unit: '%',
    indicatorCode: 'FLU_COV_ALL'
  }

/**
 * 醫護人員統計
 */
define "Statistics Healthcare Providers":
  Tuple {
    targetPopulation: Count("Target Population Healthcare Providers"),
    vaccinatedCount: Count("Vaccinated Healthcare Providers"),
    coverageRate: "Influenza Vaccination Coverage Healthcare Providers",
    unit: '%',
    indicatorCode: 'FLU_COV_HCP'
  }

// ========================================
// 七、資料完整性檢查
// ========================================

/**
 * 整體資料狀態檢查
 */
define "Data Availability Check":
  Tuple {
    hasImmunizationData: "Has Immunization Data",
    hasPatientData: "Has Patient Data",
    immunizationStatus: "Immunization Data Status",
    patientStatus: "Patient Data Status",
    canCalculate: "Has Immunization Data" and "Has Patient Data",
    message: 
      if "Has Immunization Data" and "Has Patient Data" then
        '資料完整，可進行計算'
      else if not "Has Immunization Data" and not "Has Patient Data" then
        'FHIR 無資料記載 - Immunization 及 Patient'
      else if not "Has Immunization Data" then
        'FHIR 無資料記載 - Immunization'
      else
        'FHIR 無資料記載 - Patient'
  }

// ========================================
// 八、主要結果輸出
// ========================================

/**
 * 主要指標：65 歲以上流感疫苗接種率（優先呈現）
 */
define "Primary Indicator":
  if "Data Availability Check".canCalculate then
    "Statistics 65+"
  else
    Tuple {
      targetPopulation: 0,
      vaccinatedCount: 0,
      coverageRate: null,
      unit: '%',
      indicatorCode: 'FLU_COV_65P',
      error: "Data Availability Check".message
    }

/**
 * 完整報告
 */
define "Full Report":
  Tuple {
    measurementPeriod: "Measurement Period",
    dataStatus: "Data Availability Check",
    primary: "Primary Indicator",
    allPopulation: if "Data Availability Check".canCalculate then "Statistics All" else null,
    healthcareProviders: if "Data Availability Check".canCalculate then "Statistics Healthcare Providers" else null,
    internationalStandards: List{
      'WHO Influenza Vaccine Coverage Indicator',
      'ECDC Seasonal Influenza Vaccination Guidelines',
      'HL7 FHIR R4: Immunization / Patient / Encounter'
    }
  }
