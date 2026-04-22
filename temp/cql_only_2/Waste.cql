library Waste version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ESG CQL - Waste Management (廢棄物管理)
// 基於 GRI 306: Waste 2020 標準

parameter MeasurementPeriod default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]

context Patient

// LOINC 代碼列表
define "LOINC Waste Codes": {
  '80353-5'
}

// SNOMED 廢棄物管理代碼列表
define "SNOMED Waste Management Codes": {
  '706877002', '76938001', '257641006', '257656000', '710252007',
  '710253002', '257642004', '257643009'
}

// SNOMED 有害廢棄物代碼
define "SNOMED Hazardous Codes": {
  '710252007'
}

// SNOMED 非有害廢棄物代碼
define "SNOMED NonHazardous Codes": {
  '710253002'
}

// SNOMED 處理方式代碼
define "SNOMED Recycling Codes": {
  '257641006'
}

define "SNOMED Incineration Codes": {
  '76938001'
}

define "SNOMED Landfill Codes": {
  '257656000'
}

define "SNOMED Composting Codes": {
  '257642004'
}

define "SNOMED Energy Recovery Codes": {
  '257643009'
}

// 提取廢棄物重量（公斤）
define function "GetWasteWeight"(observation Observation):
  if observation.value is FHIR.Quantity then
    (observation.value as FHIR.Quantity).value.value
  else
    null

// 提取處理程序重量（公斤）
define function "GetProcedureWeight"(procedure Procedure):
  if procedure.outcome is not null and procedure.outcome.text is not null then
    ToDecimal(procedure.outcome.text.value)
  else
    0.0

// 計算住院天數
define function "CalculateInpatientDays"(encounter Encounter):
  if encounter.period is not null and encounter.period.start is not null and encounter.period.end is not null then
    difference in days between encounter.period.start.value and encounter.period.end.value
  else
    0

// 所有有效的廢棄物觀察記錄
define "All Waste Observations":
  [Observation] O
    where O.status.value in {'final', 'amended', 'corrected'}
      and O.effective during MeasurementPeriod
      and O.value is not null
      and exists (
        O.code.coding OC
          where OC.system.value = 'http://loinc.org'
          and OC.code.value in "LOINC Waste Codes"
      )

// 有害廢棄物記錄
define "Hazardous Waste Observations":
  "All Waste Observations" O
    where exists (
      O.code.coding OC
        where OC.system.value = 'http://snomed.info/sct'
        and OC.code.value in "SNOMED Hazardous Codes"
    )

// 非有害廢棄物記錄
define "Non-hazardous Waste Observations":
  "All Waste Observations" O
    where exists (
      O.code.coding OC
        where OC.system.value = 'http://snomed.info/sct'
        and OC.code.value in "SNOMED NonHazardous Codes"
    )

// 所有完成的廢棄物處理程序
define "Waste Disposal Procedures":
  [Procedure] P
    where P.status.value = 'completed'
      and P.performed during MeasurementPeriod
      and exists (
        P.code.coding PC
          where PC.system.value = 'http://snomed.info/sct'
          and PC.code.value in "SNOMED Waste Management Codes"
      )

// 住院記錄（用於計算床日數）
define "Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and E.period is not null
      and E.period.start during MeasurementPeriod

// GRI 306-3-a: 總廢棄物產生量（公斤）
define "Total Waste Generated":
  if exists("All Waste Observations") then
    Sum(
      "All Waste Observations" O
        return "GetWasteWeight"(O)
    )
  else
    0.0

// GRI 306-3-b: 有害廢棄物總量（公斤）
define "Hazardous Waste Total":
  if exists("Hazardous Waste Observations") then
    Sum(
      "Hazardous Waste Observations" O
        return "GetWasteWeight"(O)
    )
  else
    0.0

// GRI 306-3-c: 非有害廢棄物總量（公斤）
define "Non-hazardous Waste Total":
  if exists("Non-hazardous Waste Observations") then
    Sum(
      "Non-hazardous Waste Observations" O
        return "GetWasteWeight"(O)
    )
  else
    0.0

// 回收處理程序
define "Recycling Procedures":
  "Waste Disposal Procedures" P
    where exists (
      P.code.coding PC
        where PC.system.value = 'http://snomed.info/sct'
        and PC.code.value in "SNOMED Recycling Codes"
    )

// 焚化處理程序
define "Incineration Procedures":
  "Waste Disposal Procedures" P
    where exists (
      P.code.coding PC
        where PC.system.value = 'http://snomed.info/sct'
        and PC.code.value in "SNOMED Incineration Codes"
    )

// 掩埋處理程序
define "Landfill Procedures":
  "Waste Disposal Procedures" P
    where exists (
      P.code.coding PC
        where PC.system.value = 'http://snomed.info/sct'
        and PC.code.value in "SNOMED Landfill Codes"
    )

// 堆肥處理程序
define "Composting Procedures":
  "Waste Disposal Procedures" P
    where exists (
      P.code.coding PC
        where PC.system.value = 'http://snomed.info/sct'
        and PC.code.value in "SNOMED Composting Codes"
    )

// 能源回收處理程序
define "Energy Recovery Procedures":
  "Waste Disposal Procedures" P
    where exists (
      P.code.coding PC
        where PC.system.value = 'http://snomed.info/sct'
        and PC.code.value in "SNOMED Energy Recovery Codes"
    )

// 回收處理總量（公斤）
define "Recycled Waste Total":
  if exists("Recycling Procedures") then
    Sum("Recycling Procedures" P return "GetProcedureWeight"(P))
  else
    0.0

// 焚化處理總量（公斤）
define "Incinerated Waste Total":
  if exists("Incineration Procedures") then
    Sum("Incineration Procedures" P return "GetProcedureWeight"(P))
  else
    0.0

// 掩埋處理總量（公斤）
define "Landfilled Waste Total":
  if exists("Landfill Procedures") then
    Sum("Landfill Procedures" P return "GetProcedureWeight"(P))
  else
    0.0

// 堆肥處理總量（公斤）
define "Composted Waste Total":
  if exists("Composting Procedures") then
    Sum("Composting Procedures" P return "GetProcedureWeight"(P))
  else
    0.0

// 能源回收總量（公斤）
define "Energy Recovery Total":
  if exists("Energy Recovery Procedures") then
    Sum("Energy Recovery Procedures" P return "GetProcedureWeight"(P))
  else
    0.0

// 總住院床日數
define "Total Bed Days":
  if exists("Inpatient Encounters") then
    Sum("Inpatient Encounters" E return "CalculateInpatientDays"(E))
  else
    0

// 每床日廢棄物產生量（公斤/床日）
define "Waste per Bed Day":
  if "Total Bed Days" > 0 then
    "Total Waste Generated" / "Total Bed Days"
  else
    null

// 回收率（%）
define "Recycling Rate":
  if "Total Waste Generated" > 0 then
    ("Recycled Waste Total" / "Total Waste Generated") * 100
  else
    0.0

// 有害廢棄物佔比（%）
define "Hazardous Waste Percentage":
  if "Total Waste Generated" > 0 then
    ("Hazardous Waste Total" / "Total Waste Generated") * 100
  else
    0.0

// 轉化再利用率（%）
define "Diversion Rate":
  if "Total Waste Generated" > 0 then
    (("Recycled Waste Total" + "Composted Waste Total" + "Energy Recovery Total") / "Total Waste Generated") * 100
  else
    0.0

// 掩埋率（%）
define "Landfill Rate":
  if "Total Waste Generated" > 0 then
    ("Landfilled Waste Total" / "Total Waste Generated") * 100
  else
    0.0

// 資料完整性檢查
define "Data Completeness":
  {
    hasWasteObservations: exists("All Waste Observations"),
    hasDisposalProcedures: exists("Waste Disposal Procedures"),
    hasInpatientEncounters: exists("Inpatient Encounters"),
    wasteObservationCount: Count("All Waste Observations"),
    disposalProcedureCount: Count("Waste Disposal Procedures"),
    encounterCount: Count("Inpatient Encounters"),
    dataQualityStatus: 
      if not exists("All Waste Observations") then 'NO_DATA'
      else if not exists("Waste Disposal Procedures") then 'PARTIAL_DATA'
      else if not exists("Inpatient Encounters") then 'NO_ENCOUNTER_DATA'
      else 'COMPLETE'
  }

// GRI 306-3 廢棄物產生量報告
define "GRI 306-3 Report":
  {
    totalWasteGeneratedKg: "Total Waste Generated",
    hazardousWasteKg: "Hazardous Waste Total",
    nonHazardousWasteKg: "Non-hazardous Waste Total",
    measurementPeriod: MeasurementPeriod
  }

// GRI 306-4 廢棄物處理方式報告
define "GRI 306-4 Report":
  {
    recycledKg: "Recycled Waste Total",
    incineratedKg: "Incinerated Waste Total",
    landfilledKg: "Landfilled Waste Total",
    compostedKg: "Composted Waste Total",
    energyRecoveryKg: "Energy Recovery Total",
    measurementPeriod: MeasurementPeriod
  }

// GRI 306-5 廢棄物效率指標報告
define "GRI 306-5 Report":
  {
    recyclingRatePercent: "Recycling Rate",
    diversionRatePercent: "Diversion Rate",
    landfillRatePercent: "Landfill Rate",
    wastePerBedDayKg: "Waste per Bed Day",
    totalBedDays: "Total Bed Days",
    measurementPeriod: MeasurementPeriod
  }

// ESG 廢棄物管理綜合報告
define "ESG Waste Management Report":
  if not exists("All Waste Observations") then
    {
      status: 'NO_FHIR_DATA',
      message: 'FHIR無廢棄物資料記載',
      dataCompleteness: "Data Completeness"
    }
  else
    {
      reportMetadata: {
        reportTitle: 'ESG Waste Management Report',
        standard: 'GRI 306: Waste 2020',
        fhirVersion: 'FHIR R4 (4.0.1)',
        reportingPeriod: MeasurementPeriod
      },
      
      gri306_3WasteGeneration: "GRI 306-3 Report",
      gri306_4WasteDisposal: "GRI 306-4 Report",
      gri306_5Performance: "GRI 306-5 Report",
      
      dataCompleteness: "Data Completeness",
      
      summary: {
        totalWasteKg: "Total Waste Generated",
        hazardousWastePercent: "Hazardous Waste Percentage",
        diversionRatePercent: "Diversion Rate",
        landfillRatePercent: "Landfill Rate",
        wastePerBedDayKg: "Waste per Bed Day"
      }
    }
