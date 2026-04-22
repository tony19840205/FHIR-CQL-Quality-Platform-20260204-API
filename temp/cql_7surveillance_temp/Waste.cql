/**
 * ESG CQL - Waste Management (廢棄物管理)
 * 基於 GRI 306: Waste 2020 標準
 * FHIR R4 對應: Observation, Procedure, Encounter
 * 版本: 1.0.0
 * 更新日期: 2026-01-09
 */

library Waste version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ========== CodeSystem 定義 ==========

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "UCUM": 'http://unitsofmeasure.org'
codesystem "ObservationCategory": 'http://terminology.hl7.org/CodeSystem/observation-category'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// ========== Code 定義 ==========

code "Waste Mass": '80353-5' from "LOINC" display 'Waste mass'
code "Waste Management": '706877002' from "SNOMED" display 'Waste management'
code "Incineration": '76938001' from "SNOMED" display 'Incineration'
code "Recycling": '257641006' from "SNOMED" display 'Recycling'
code "Landfill": '257656000' from "SNOMED" display 'Landfill'
code "Hazardous Waste": '710252007' from "SNOMED" display 'Hazardous waste'
code "Non-hazardous Waste": '710253002' from "SNOMED" display 'Non-hazardous waste'
code "Composting": '257642004' from "SNOMED" display 'Composting'
code "Energy Recovery": '257643009' from "SNOMED" display 'Energy recovery'
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'

// ========== ValueSet 定義 ==========

valueset "Hazardous Waste Types": 'http://esg.fhir.org/ValueSet/hazardous-waste'
valueset "Non-hazardous Waste Types": 'http://esg.fhir.org/ValueSet/non-hazardous-waste'
valueset "Incineration Methods": 'http://esg.fhir.org/ValueSet/waste-incineration'
valueset "Recycling Methods": 'http://esg.fhir.org/ValueSet/waste-recycling'
valueset "Landfill Methods": 'http://esg.fhir.org/ValueSet/waste-landfill'
valueset "Reuse Methods": 'http://esg.fhir.org/ValueSet/waste-reuse'
valueset "Composting Methods": 'http://esg.fhir.org/ValueSet/waste-composting'
valueset "Energy Recovery Methods": 'http://esg.fhir.org/ValueSet/waste-energy-recovery'
valueset "Other Disposal Methods": 'http://esg.fhir.org/ValueSet/waste-other-disposal'

// ========== Parameter 定義 ==========

parameter MeasurementPeriod default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]

// ========== Context ==========

context Patient

// ========== Helper Functions ==========

/**
 * Function: 檢查觀察記錄是否為有害廢棄物
 */
define function IsHazardousWaste(observation Observation):
  observation.code in "Hazardous Waste Types"

/**
 * Function: 檢查觀察記錄是否為非有害廢棄物
 */
define function IsNonHazardousWaste(observation Observation):
  observation.code in "Non-hazardous Waste Types"

/**
 * Function: 提取廢棄物重量（公斤）
 */
define function GetWasteWeight(observation Observation):
  if observation.value is FHIR.Quantity then
    (observation.value as FHIR.Quantity).value.value
  else
    null

/**
 * Function: 提取處理程序重量（公斤）
 */
define function GetProcedureWeight(procedure Procedure):
  if procedure.outcome is not null and procedure.outcome.text is not null then
    ToDecimal(procedure.outcome.text.value)
  else
    0.0

/**
 * Function: 計算住院天數
 */
define function CalculateInpatientDays(encounter Encounter):
  if encounter.period is not null and encounter.period.start is not null and encounter.period.end is not null then
    days between start of encounter.period and end of encounter.period
  else
    0

/**
 * Function: 檢查處理方式類型
 */
define function GetDisposalMethod(procedure Procedure):
  case
    when procedure.code in "Recycling Methods" then 'Recycling'
    when procedure.code in "Reuse Methods" then 'Reuse'
    when procedure.code in "Incineration Methods" then 'Incineration'
    when procedure.code in "Landfill Methods" then 'Landfill'
    when procedure.code in "Composting Methods" then 'Composting'
    when procedure.code in "Energy Recovery Methods" then 'Energy Recovery'
    when procedure.code in "Other Disposal Methods" then 'Other'
    else 'Unknown'
  end

// ========== 基礎資料查詢 ==========

/**
 * Query: 所有有效的廢棄物觀察記錄
 */
define "All Waste Observations":
  [Observation: "Waste Mass"] O
    where O.status in {'final', 'amended', 'corrected'}
      and O.effective during MeasurementPeriod
      and O.value is not null
      and GetWasteWeight(O) is not null

/**
 * Query: 有害廢棄物記錄
 */
define "Hazardous Waste Observations":
  "All Waste Observations" O
    where IsHazardousWaste(O)

/**
 * Query: 非有害廢棄物記錄
 */
define "Non-hazardous Waste Observations":
  "All Waste Observations" O
    where IsNonHazardousWaste(O)

/**
 * Query: 所有完成的廢棄物處理程序
 */
define "Waste Disposal Procedures":
  [Procedure: "Waste Management"] P
    where P.status = 'completed'
      and P.performed during MeasurementPeriod

/**
 * Query: 住院記錄（用於計算床日數）
 */
define "Inpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and E.class ~ "Inpatient"
      and E.period is not null
      and E.period.start during MeasurementPeriod

// ========== GRI 306-3: 廢棄物產生量計算 ==========

/**
 * GRI 306-3-a: 總廢棄物產生量（公斤）
 */
define "Total Waste Generated":
  if exists("All Waste Observations") then
    Sum(
      "All Waste Observations" O
        return GetWasteWeight(O)
    )
  else
    0.0

/**
 * GRI 306-3-b: 有害廢棄物總量（公斤）
 */
define "Hazardous Waste Total":
  if exists("Hazardous Waste Observations") then
    Sum(
      "Hazardous Waste Observations" O
        return GetWasteWeight(O)
    )
  else
    0.0

/**
 * GRI 306-3-c: 非有害廢棄物總量（公斤）
 */
define "Non-hazardous Waste Total":
  if exists("Non-hazardous Waste Observations") then
    Sum(
      "Non-hazardous Waste Observations" O
        return GetWasteWeight(O)
    )
  else
    0.0

/**
 * 廢棄物類型分布統計: 廢棄物處理方式計算 ==========

/**
 * Query: 回收處理程序
 */
define "Recycling Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Recycling Methods"

/**
 * Query: 再利用處理程序
 */
define "Reuse Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Reuse Methods"

/**
 * Query: 焚化處理程序
 */
define "Incineration Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Incineration Methods"

/**
 * Query: 掩埋處理程序
 */
define "Landfill Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Landfill Methods"

/**
 * Query: 堆肥處理程序
 */
define "Composting Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Composting Methods"

/**
 * Query: 能源回收處理程序
 */
define "Energy Recovery Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Energy Recovery Methods"

/**
 * Query: 其他處理程序
 */
define "Other Disposal Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Other Disposal Methods"

/**
 * 回收處理總量（公斤）
 */
define "Recycled Waste Total":
  if exists("Recycling Procedures") then
    Sum("Recycling Procedures" P return GetProcedureWeight(P))
  else
    0.0

/**
 * 再利用總量（公斤）
 */
define "Reused Waste Total":
  if exists("Reuse Procedures") then
    Sum("Reuse Procedures" P return GetProcedureWeight(P))
  else
    0.0

/**
 * 焚化處理總量（公斤）
 */
define "Incinerated Waste Total":
  if exists("Incineration Procedures") then
    Sum("Incineration Procedures" P return GetProcedureWeight(P))
  else
    0.0

/**
 * 掩埋處理總量（公斤）
 */
define "Landfilled Waste Total":
  if exists("Landfill Procedures") then
    Sum("Landfill Procedures" P return GetProcedureWeight(P))
  else
    0.0

/**
 * 堆肥處理總量（公斤）
 */
define "Composted Waste Total":
  if exists("Composting Procedures") then
    Sum("Composting Procedures" P return GetProcedureWeight(P))
  else
    0.0

/**
 * 能源回收總量（公斤）GRI 306-5: 效率指標與績效計算 ==========

/**
 * 總住院床日數
 */
define "Total Bed Days":
  if exists("Inpatient Encounters") then
    Sum("Inpatient Encounters" E return CalculateInpatientDays(E))
  else
    0

/**
 * 每床日廢棄物產生量（公斤/床日）
 */
define "Waste per Bed Day":
  if "Total Bed Days" > 0 then
    "Total Waste Generated" / "Total Bed Days"
  else
    null

/**
 * 回收率（%）
 */
define "Recycling Rate":
  if "Total Waste Generated" > 0 then
    ("Recycled Waste Total" / "Total Waste Generated") * 100
  else
    0.0

/**
 * 再利用率（%）
 */
define "Reuse Rate":
  if "Total Waste Generated" > 0 then
    ("Reused Waste Total" / "Total Waste Generated") * 100
  else
    0.0

/**
 * 有害廢棄物佔比（%）
 */
define "Hazardous Waste Percentage":
  if "Total Waste Generated" > 0 then
    ("Hazardous Waste Total" / "Total Waste Generated") * 100
  else
    0.0

/**
 * 轉化再利用率（%）= (回收 + 再利用 + 堆肥 + 能源回收) / 總廢棄物
 */
define "Diversion Rate":
  if "Total Waste Generated" > 0 then
    (("Recycled Waste Total" + "Reused Waste Total" + "Composted Waste Total" + "Energy Recovery Total") 
     / "Total GRI 306 綜合報告輸出 ==========

/**
 * 資料完整性檢查
 */
define "Data Completeness":
  {
    has_waste_observations: exists("All Waste Observations"),
    has_disposal_procedures: exists("Waste Disposal Procedures"),
    has_inpatient_encounters: exists("Inpatient Encounters"),
    waste_observation_count: Count("All Waste Observations"),
    disposal_procedure_count: Count("Waste Disposal Procedures"),
    encounter_count: Count("Inpatient Encounters"),
    data_quality_status: 
      if not exists("All Waste Observations") then 'NO_DATA'
      else if not exists("Waste Disposal Procedures") then 'PARTIAL_DATA'
      else if not exists("Inpatient Encounters") then 'NO_ENCOUNTER_DATA'
      else 'COMPLETE'
  }

/**
 * GRI 306-3 廢棄物產生量報告
 */
define "GRI 306-3 Report":
  {
    total_waste_generated_kg: "Total Waste Generated",
    hazardous_waste_kg: "Hazardous Waste Total",
    non_hazardous_waste_kg: "Non-hazardous Waste Total",
    waste_distribution: "Waste Distribution by Type",
    measurement_period: MeasurementPeriod
  }

/**
 * GRI 306-4 廢棄物處理方式報告
 */
define "GRI 306-4 Report":
  {
    recycled_kg: "Recycled Waste Total",
    reused_kg: "Reused Waste Total",
    incinerated_kg: "Incinerated Waste Total",
    landfilled_kg: "Landfilled Waste Total",
    composted_kg: "Composted Waste Total",
    energy_recovery_kg: "Energy Recovery Total",
    other_disposal_kg: "Other Disposal Total",
    disposal_distribution: "Waste Disposal Distribution",
    measurement_period: MeasurementPeriod
  }

/**
 * GRI 306-5 廢棄物效率指標報告
 */
define "GRI 306-5 Report":
  {
    performance_indicators: "Performance Indicators",
    recycling_rate_percent: "Recycling Rate",
    diversion_rate_percent: "Diversion Rate",
    landfill_rate_percent: "Landfill Rate",
    waste_per_bed_day_kg: "Waste per Bed Day",
    total_bed_days: "Total Bed Days",
    measurement_period: MeasurementPeriod
  }

/**
 * ESG 廢棄物管理綜合報告（完整版）
 */
define "ESG Waste Management Report":
  if not exists("All Waste Observations") then
    {
      status: 'NO_FHIR_DATA',
      message: '【FHIR 無廢棄物資料記載】',
      data_completeness: "Data Completeness"
    }
  else
    {
      report_metadata: {
        report_title: 'ESG Waste Management Report',
        standard: 'GRI 306: Waste 2020',
        fhir_version: 'FHIR R4 (4.0.1)',
        reporting_period: MeasurementPeriod,
        generated_date: Now()
      },
      
      gri_306_3_waste_generation: "GRI 306-3 Report",
      gri_306_4_waste_disposal: "GRI 306-4 Report",
      gri_306_5_performance: "GRI 306-5 Report",
      
      data_completeness: "Data Completeness",
      
      summary: {
        total_waste_kg: "Total Waste Generated",
        hazardous_waste_percent: "Hazardous Waste Percentage",
        diversion_rate_percent: "Diversion Rate",
        landfill_rate_percent: "Landfill Rate",
        waste_per_bed_day_kg: "Waste per Bed Day"
      }
   * 公式：Recycled Waste / Total Waste × 100
 */
define "Recycling Rate (%)":
  if "Recycled Waste (kg)" is not null and "Total Waste Generated (kg)" is not null and "Total Waste Generated (kg)" > 0 then
    ("Recycled Waste (kg)" / "Total Waste Generated (kg)") * 100
  else
    null

/**
 * 再利用率（%）
 */
define "Reuse Rate (%)":
  if "Reused Waste (kg)" is not null and "Total Waste Generated (kg)" is not null and "Total Waste Generated (kg)" > 0 then
    ("Reused Waste (kg)" / "Total Waste Generated (kg)") * 100
  else
    null

/**
 * 有害廢棄物佔比（%）
 */
define "Hazardous Waste Percentage (%)":
  if "Hazardous Waste Total (kg)" is not null and "Total Waste Generated (kg)" is not null and "Total Waste Generated (kg)" > 0 then
    ("Hazardous Waste Total (kg)" / "Total Waste Generated (kg)") * 100
  else
    null

// ========== 最終報告輸出 ==========

/**
 * ESG 廢棄物管理綜合報告
 */
define "ESG Waste Management Report":
  if "Total Waste Generated (kg)" is null then
    '【FHIR 無資料記載】'
  else
    {
      reporting_period: MeasurementPeriod,
      
      // GRI 306-3：廢棄物產生量
      total_waste_kg: Coalesce("Total Waste Generated (kg)", 0.0),
      hazardous_waste_kg: Coalesce("Hazardous Waste Total (kg)", 0.0),
      non_hazardous_waste_kg: Coalesce("Non-hazardous Waste Total (kg)", 0.0),
      
      // GRI 306-4：廢棄物處理方式
      recycled_kg: Coalesce("Recycled Waste (kg)", 0.0),
      reused_kg: Coalesce("Reused Waste (kg)", 0.0),
      incinerated_kg: Coalesce("Incinerated Waste (kg)", 0.0),
      landfilled_kg: Coalesce("Landfilled Waste (kg)", 0.0),
      other_disposal_kg: Coalesce("Other Disposal Waste (kg)", 0.0),
      
      // 效率指標
      total_bed_days: Coalesce("Total Bed Days", 0),
      waste_per_bed_day_kg: "Waste per Bed-Day (kg/bed-day)",
      recycling_rate_percent: "Recycling Rate (%)",
      reuse_rate_percent: "Reuse Rate (%)",
      hazardous_waste_percent: "Hazardous Waste Percentage (%)",
      
      // 資料狀態
      data_status: 
        if "Total Waste Generated (kg)" is null then 'FHIR 無資料記載'
        else if "Total Waste Generated (kg)" = 0.0 then '無廢棄物記錄'
        else '資料完整',
      
      // 標準引用
      standards: {
        gri: 'GRI 306: Waste 2021/2023',
        fhir: 'HL7 FHIR R4',
        units: 'UCUM (International Units)',
        terminology: 'SNOMED CT / LOINC'
      }
    }

/**
 * 資料完整性檢查
 */
define "Data Completeness Check":
  {
    has_waste_data: exists("All Waste Observations"),
    has_disposal_data: exists("Waste Disposal Procedures"),
    has_encounter_data: exists("Inpatient Encounters"),
    
    message: 
      if not exists("All Waste Observations") then 'FHIR 無資料記載 - 缺少廢棄物觀察記錄'
      else if not exists("Waste Disposal Procedures") then '警告 - 缺少廢棄物處理程序記錄'
      else if not exists("Inpatient Encounters") then '警告 - 缺少住院記錄，無法計算每床日廢棄物量'
      else '資料完整'
  }
