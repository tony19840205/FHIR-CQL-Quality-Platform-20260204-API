/**
 * Library: COVID-19 Vaccination Coverage (COVID-19 疫苗施打率)
 * 
 * 用途：計算 COVID-19 疫苗接種涵蓋率
 * 
 * 資料來源：
 * - Immunization（疫苗接種紀錄，每一劑為 1 筆紀錄）
 * - Patient（病人資訊）
 * - Encounter（就醫紀錄，選用）
 * 
 * 國際標準參考：
 * - WHO COVID-19 Vaccine Coverage Indicators
 * - ECDC COVID-19 Vaccination Guidelines
 * - CDC COVID-19 Vaccination Metrics
 * - 國家疫苗儀表板標準
 * - HL7 FHIR R4: Immunization / Patient / Encounter
 * 
 * 擷取時間：無限大
 * 測量期間：每年 1/1–12/31
 */

library COVID19VaccinationCoverage version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ========================================
// 參數定義
// ========================================

/**
 * 測量期間（可自訂）
 * 預設：當年度 1/1 至 12/31
 */
parameter "Measurement Period" Interval<DateTime> default Interval[@2025-01-01T00:00:00.0, @2025-12-31T23:59:59.999]

// ========================================
// ValueSet 定義
// ========================================

/**
 * ValueSet: COVID-19 疫苗代碼（所有類型）
 * 
 * SNOMED CT 代碼：
 *   - 840539006: COVID-19 vaccine
 *   - 840534001: SARS-CoV-2 (COVID-19) vaccine
 *   - 1119305005: SARS-CoV-2 antigen vaccine
 *   - 1119349007: SARS-CoV-2 mRNA vaccine
 * 
 * CVX 代碼（CDC）：
 *   - 207: Moderna COVID-19 Vaccine (mRNA-1273)
 *   - 208: Pfizer-BioNTech COVID-19 Vaccine (BNT162b2)
 *   - 210: AstraZeneca COVID-19 Vaccine (ChAdOx1-S)
 *   - 211: Novavax COVID-19 Vaccine (NVX-CoV2373)
 *   - 212: Janssen (J&J) COVID-19 Vaccine (Ad26.COV2.S)
 *   - 213: SARS-COV-2 (COVID-19) vaccine, UNSPECIFIED
 *   - 217: Pfizer-BioNTech COVID-19 Vaccine (Bivalent)
 *   - 218: Moderna COVID-19 Vaccine (Bivalent)
 *   - 219: Novavax COVID-19 Vaccine (Adjuvanted)
 * 
 * 包含：CVX COVID-19、SNOMED CT、ATC J07BX*、台灣 NHI 疫苗代碼
 */
valueset "COVID19 Vaccines All": 'http://example.org/fhir/ValueSet/covid19-vaccines-all'

/**
 * ValueSet: COVID-19 基礎劑量疫苗
 * CVX: 207, 208, 210, 211, 212
 */
valueset "COVID19 Primary Series": 'http://example.org/fhir/ValueSet/covid19-primary-series'

/**
 * ValueSet: COVID-19 加強劑
 * CVX: 217, 218, 219
 */
valueset "COVID19 Booster": 'http://example.org/fhir/ValueSet/covid19-booster'

/**
 * CodeSystem: SNOMED CT
 */
codesystem "SNOMED": 'http://snomed.info/sct'

/**
 * CodeSystem: CVX (Vaccine Administered)
 */
codesystem "CVX": 'http://hl7.org/fhir/sid/cvx'

/**
 * Code: COVID-19 vaccine (SNOMED)
 */
code "COVID-19 vaccine SNOMED": '840539006' from "SNOMED" display 'COVID-19 vaccine'
code "SARS-CoV-2 vaccine SNOMED": '840534001' from "SNOMED" display 'SARS-CoV-2 (COVID-19) vaccine'
code "COVID-19 antigen vaccine": '1119305005' from "SNOMED" display 'SARS-CoV-2 antigen vaccine'
code "COVID-19 mRNA vaccine": '1119349007' from "SNOMED" display 'SARS-CoV-2 mRNA vaccine'

/**
 * Code: COVID-19 vaccines (CVX)
 */
code "Moderna COVID-19": '207' from "CVX" display 'Moderna COVID-19 Vaccine'
code "Pfizer COVID-19": '208' from "CVX" display 'Pfizer-BioNTech COVID-19 Vaccine'
code "AstraZeneca COVID-19": '210' from "CVX" display 'AstraZeneca COVID-19 Vaccine'
code "Novavax COVID-19": '211' from "CVX" display 'Novavax COVID-19 Vaccine'
code "Janssen COVID-19": '212' from "CVX" display 'Janssen COVID-19 Vaccine'
code "COVID-19 Unspecified": '213' from "CVX" display 'SARS-COV-2 (COVID-19) vaccine, UNSPECIFIED'
code "Pfizer Bivalent COVID-19": '217' from "CVX" display 'Pfizer-BioNTech COVID-19 Vaccine (Bivalent)'
code "Moderna Bivalent COVID-19": '218' from "CVX" display 'Moderna COVID-19 Vaccine (Bivalent)'
code "Novavax Adjuvanted COVID-19": '219' from "CVX" display 'Novavax COVID-19 Vaccine (Adjuvanted)'

// ========================================
// 一、資料擷取：Immunization（疫苗接種紀錄）
// ========================================

/**
 * 所有 COVID-19 疫苗接種紀錄（已完成）
 * 支援代碼：CVX COVID-19、ATC J07BX 系列、台灣 NHI 疫苗代碼
 */
define "COVID19 Immunizations":
  [Immunization] I
    where I.status = 'completed'
      and I.vaccineCode in "COVID19 Vaccines All"
      and I.occurrence during "Measurement Period"

/**
 * 檢查：是否有 COVID-19 疫苗接種資料
 */
define "Has Immunization Data":
  exists([Immunization])

/**
 * COVID-19 疫苗接種資料狀態訊息
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
// 三、族群定義（分母）
// ========================================

/**
 * 目標族群：12 歲以上（建議接種對象）
 * 適用於：所有三項指標
 */
define "Target Population 12+":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 12

/**
 * 目標族群：18 歲以上（成人）
 */
define "Target Population 18+":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 18

/**
 * 目標族群：65 歲以上（高風險族群）
 */
define "Target Population 65+":
  "All Patients" P
    where CalculateAgeInYearsAt(FHIRHelpers.ToDate(P.birthDate), start of "Measurement Period") >= 65

/**
 * 目標族群：全人口
 */
define "Target Population All":
  "All Patients"

// ========================================
// 四、接種者定義（分子）
// ========================================

/**
 * 輔助函數：計算每位病人的 COVID-19 疫苗劑數
 */
define function GetCOVID19DoseCount(patient Patient):
  Count(
    "COVID19 Immunizations" I 
      where I.patient.reference = 'Patient/' + patient.id.value
  )

/**
 * C19_COV_1PLUS：至少接種 1 劑者（12+ 歲）
 * WHO/ECDC/CDC 標準：至少一劑涵蓋率
 */
define "Vaccinated 1+ Dose 12+":
  "Target Population 12+" P
    where exists(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    )

/**
 * 至少接種 1 劑者（18+ 歲）
 */
define "Vaccinated 1+ Dose 18+":
  "Target Population 18+" P
    where exists(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    )

/**
 * 至少接種 1 劑者（65+ 歲）
 */
define "Vaccinated 1+ Dose 65+":
  "Target Population 65+" P
    where exists(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    )

/**
 * 至少接種 1 劑者（全人口）
 */
define "Vaccinated 1+ Dose All":
  "Target Population All" P
    where exists(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    )

/**
 * C19_COV_PRIMARY：完成基礎劑量者（≥2 劑，12+ 歲）
 * WHO/ECDC/CDC 標準：Primary Series Completion
 */
define "Primary Series Completed 12+":
  "Target Population 12+" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 2

/**
 * 完成基礎劑量者（18+ 歲）
 */
define "Primary Series Completed 18+":
  "Target Population 18+" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 2

/**
 * 完成基礎劑量者（65+ 歲）
 */
define "Primary Series Completed 65+":
  "Target Population 65+" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 2

/**
 * 完成基礎劑量者（全人口）
 */
define "Primary Series Completed All":
  "Target Population All" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 2

/**
 * C19_COV_BOOSTER：接種至少 1 劑加強劑者（≥3 劑，12+ 歲）
 * WHO/ECDC/CDC 標準：Booster Coverage
 */
define "Booster Completed 12+":
  "Target Population 12+" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 3

/**
 * 接種至少 1 劑加強劑者（18+ 歲）
 */
define "Booster Completed 18+":
  "Target Population 18+" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 3

/**
 * 接種至少 1 劑加強劑者（65+ 歲）
 */
define "Booster Completed 65+":
  "Target Population 65+" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 3

/**
 * 接種至少 1 劑加強劑者（全人口）
 */
define "Booster Completed All":
  "Target Population All" P
    where Count(
      "COVID19 Immunizations" I 
        where I.patient.reference = 'Patient/' + P.id.value
    ) >= 3

// ========================================
// 五、接種率計算（Coverage）
// ========================================

/**
 * 計算公式：WHO / ECDC / CDC 標準
 * Coverage = (接種人數 / 目標族群人數) × 100%
 */

// -------------------- 12+ 歲族群 --------------------

/**
 * C19_COV_1PLUS：至少一劑涵蓋率（12+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage 1+ Dose 12+":
  if Count("Target Population 12+") > 0 then
    Round((Count("Vaccinated 1+ Dose 12+") * 100.0) / Count("Target Population 12+"), 2)
  else
    null

/**
 * C19_COV_PRIMARY：基礎劑量完成率（12+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Primary Series 12+":
  if Count("Target Population 12+") > 0 then
    Round((Count("Primary Series Completed 12+") * 100.0) / Count("Target Population 12+"), 2)
  else
    null

/**
 * C19_COV_BOOSTER：加強劑涵蓋率（12+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Booster 12+":
  if Count("Target Population 12+") > 0 then
    Round((Count("Booster Completed 12+") * 100.0) / Count("Target Population 12+"), 2)
  else
    null

// -------------------- 18+ 歲族群 --------------------

/**
 * 至少一劑涵蓋率（18+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage 1+ Dose 18+":
  if Count("Target Population 18+") > 0 then
    Round((Count("Vaccinated 1+ Dose 18+") * 100.0) / Count("Target Population 18+"), 2)
  else
    null

/**
 * 基礎劑量完成率（18+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Primary Series 18+":
  if Count("Target Population 18+") > 0 then
    Round((Count("Primary Series Completed 18+") * 100.0) / Count("Target Population 18+"), 2)
  else
    null

/**
 * 加強劑涵蓋率（18+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Booster 18+":
  if Count("Target Population 18+") > 0 then
    Round((Count("Booster Completed 18+") * 100.0) / Count("Target Population 18+"), 2)
  else
    null

// -------------------- 65+ 歲族群 --------------------

/**
 * 至少一劑涵蓋率（65+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage 1+ Dose 65+":
  if Count("Target Population 65+") > 0 then
    Round((Count("Vaccinated 1+ Dose 65+") * 100.0) / Count("Target Population 65+"), 2)
  else
    null

/**
 * 基礎劑量完成率（65+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Primary Series 65+":
  if Count("Target Population 65+") > 0 then
    Round((Count("Primary Series Completed 65+") * 100.0) / Count("Target Population 65+"), 2)
  else
    null

/**
 * 加強劑涵蓋率（65+ 歲）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Booster 65+":
  if Count("Target Population 65+") > 0 then
    Round((Count("Booster Completed 65+") * 100.0) / Count("Target Population 65+"), 2)
  else
    null

// -------------------- 全人口 --------------------

/**
 * 至少一劑涵蓋率（全人口）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage 1+ Dose All":
  if Count("Target Population All") > 0 then
    Round((Count("Vaccinated 1+ Dose All") * 100.0) / Count("Target Population All"), 2)
  else
    null

/**
 * 基礎劑量完成率（全人口）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Primary Series All":
  if Count("Target Population All") > 0 then
    Round((Count("Primary Series Completed All") * 100.0) / Count("Target Population All"), 2)
  else
    null

/**
 * 加強劑涵蓋率（全人口）
 * 單位：百分比 (%)
 */
define "COVID19 Vaccination Coverage Booster All":
  if Count("Target Population All") > 0 then
    Round((Count("Booster Completed All") * 100.0) / Count("Target Population All"), 2)
  else
    null

// ========================================
// 六、詳細統計資訊
// ========================================

/**
 * 12+ 歲族群統計（主要指標）
 */
define "Statistics 12+":
  Tuple {
    ageGroup: '12+ 歲',
    targetPopulation: Count("Target Population 12+"),
    oneDosePlus: Tuple {
      count: Count("Vaccinated 1+ Dose 12+"),
      coverage: "COVID19 Vaccination Coverage 1+ Dose 12+",
      unit: '%',
      indicatorCode: 'C19_COV_1PLUS'
    },
    primarySeries: Tuple {
      count: Count("Primary Series Completed 12+"),
      coverage: "COVID19 Vaccination Coverage Primary Series 12+",
      unit: '%',
      indicatorCode: 'C19_COV_PRIMARY'
    },
    booster: Tuple {
      count: Count("Booster Completed 12+"),
      coverage: "COVID19 Vaccination Coverage Booster 12+",
      unit: '%',
      indicatorCode: 'C19_COV_BOOSTER'
    }
  }

/**
 * 18+ 歲族群統計
 */
define "Statistics 18+":
  Tuple {
    ageGroup: '18+ 歲',
    targetPopulation: Count("Target Population 18+"),
    oneDosePlus: Tuple {
      count: Count("Vaccinated 1+ Dose 18+"),
      coverage: "COVID19 Vaccination Coverage 1+ Dose 18+",
      unit: '%'
    },
    primarySeries: Tuple {
      count: Count("Primary Series Completed 18+"),
      coverage: "COVID19 Vaccination Coverage Primary Series 18+",
      unit: '%'
    },
    booster: Tuple {
      count: Count("Booster Completed 18+"),
      coverage: "COVID19 Vaccination Coverage Booster 18+",
      unit: '%'
    }
  }

/**
 * 65+ 歲族群統計
 */
define "Statistics 65+":
  Tuple {
    ageGroup: '65+ 歲',
    targetPopulation: Count("Target Population 65+"),
    oneDosePlus: Tuple {
      count: Count("Vaccinated 1+ Dose 65+"),
      coverage: "COVID19 Vaccination Coverage 1+ Dose 65+",
      unit: '%'
    },
    primarySeries: Tuple {
      count: Count("Primary Series Completed 65+"),
      coverage: "COVID19 Vaccination Coverage Primary Series 65+",
      unit: '%'
    },
    booster: Tuple {
      count: Count("Booster Completed 65+"),
      coverage: "COVID19 Vaccination Coverage Booster 65+",
      unit: '%'
    }
  }

/**
 * 全人口統計
 */
define "Statistics All":
  Tuple {
    ageGroup: '全人口',
    targetPopulation: Count("Target Population All"),
    oneDosePlus: Tuple {
      count: Count("Vaccinated 1+ Dose All"),
      coverage: "COVID19 Vaccination Coverage 1+ Dose All",
      unit: '%'
    },
    primarySeries: Tuple {
      count: Count("Primary Series Completed All"),
      coverage: "COVID19 Vaccination Coverage Primary Series All",
      unit: '%'
    },
    booster: Tuple {
      count: Count("Booster Completed All"),
      coverage: "COVID19 Vaccination Coverage Booster All",
      unit: '%'
    }
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
 * 主要指標：12+ 歲族群 COVID-19 疫苗接種率（優先呈現）
 */
define "Primary Indicators":
  if "Data Availability Check".canCalculate then
    "Statistics 12+"
  else
    Tuple {
      ageGroup: '12+ 歲',
      targetPopulation: 0,
      oneDosePlus: Tuple {
        count: 0,
        coverage: null,
        unit: '%',
        indicatorCode: 'C19_COV_1PLUS',
        error: "Data Availability Check".message
      },
      primarySeries: Tuple {
        count: 0,
        coverage: null,
        unit: '%',
        indicatorCode: 'C19_COV_PRIMARY',
        error: "Data Availability Check".message
      },
      booster: Tuple {
        count: 0,
        coverage: null,
        unit: '%',
        indicatorCode: 'C19_COV_BOOSTER',
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
    age18Plus: if "Data Availability Check".canCalculate then "Statistics 18+" else null,
    age65Plus: if "Data Availability Check".canCalculate then "Statistics 65+" else null,
    allPopulation: if "Data Availability Check".canCalculate then "Statistics All" else null,
    internationalStandards: List{
      'WHO COVID-19 Vaccine Coverage Indicators',
      'ECDC COVID-19 Vaccination Guidelines',
      'CDC COVID-19 Vaccination Metrics',
      '國家疫苗儀表板標準',
      'HL7 FHIR R4: Immunization / Patient / Encounter'
    }
  }
