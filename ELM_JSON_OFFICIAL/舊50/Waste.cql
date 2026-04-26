/**
 * Library: Waste Management (廢棄物管理)
 * 基於 GRI 306: Waste 2020 標準
 * FHIR R4 對應: Observation, Procedure, Encounter
 * 版本: 1.0.0
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

parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]

// ========== Context ==========

context Patient

// ========== Helper Functions ==========

define function IsHazardousWaste(observation Observation):
  observation.code in "Hazardous Waste Types"

define function IsNonHazardousWaste(observation Observation):
  observation.code in "Non-hazardous Waste Types"

define function GetWasteWeight(observation Observation):
  if observation.value is FHIR.Quantity then
    (observation.value as FHIR.Quantity).value.value
  else
    null

define function GetProcedureWeight(procedure Procedure):
  if procedure.outcome is not null and procedure.outcome.text is not null then
    ToDecimal(procedure.outcome.text.value)
  else
    0.0

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

define "All Waste Observations":
  [Observation: "Waste Mass"] O
    where O.status in {'final', 'amended', 'corrected'}
      and FHIRHelpers.ToDateTime(O.effective as FHIR.dateTime) during "Measurement Period"
      and O.value is not null
      and GetWasteWeight(O) is not null

define "Hazardous Waste Observations":
  "All Waste Observations" O
    where IsHazardousWaste(O)

define "Non-hazardous Waste Observations":
  "All Waste Observations" O
    where IsNonHazardousWaste(O)

define "Waste Disposal Procedures":
  [Procedure: "Waste Management"] P
    where P.status = 'completed'
      and FHIRHelpers.ToDateTime(P.performed as FHIR.dateTime) during "Measurement Period"

define "Inpatient Encounters":
  [Encounter] E
    where E.status = 'finished'
      and E.class ~ "Inpatient"
      and E.period is not null
      and FHIRHelpers.ToDateTime(E.period.start) during "Measurement Period"

// ========== GRI 306-3: 廢棄物產生量 ==========

define "Total Waste Generated":
  if exists("All Waste Observations") then
    Sum("All Waste Observations" O return GetWasteWeight(O))
  else
    0.0

define "Hazardous Waste Total":
  if exists("Hazardous Waste Observations") then
    Sum("Hazardous Waste Observations" O return GetWasteWeight(O))
  else
    0.0

define "Non-hazardous Waste Total":
  if exists("Non-hazardous Waste Observations") then
    Sum("Non-hazardous Waste Observations" O return GetWasteWeight(O))
  else
    0.0

// ========== GRI 306-4: 廢棄物處理方式 ==========

define "Recycling Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Recycling Methods"

define "Reuse Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Reuse Methods"

define "Incineration Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Incineration Methods"

define "Landfill Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Landfill Methods"

define "Composting Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Composting Methods"

define "Energy Recovery Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Energy Recovery Methods"

define "Other Disposal Procedures":
  "Waste Disposal Procedures" P
    where P.code in "Other Disposal Methods"

define "Recycled Waste Total":
  if exists("Recycling Procedures") then
    Sum("Recycling Procedures" P return GetProcedureWeight(P))
  else
    0.0

define "Reused Waste Total":
  if exists("Reuse Procedures") then
    Sum("Reuse Procedures" P return GetProcedureWeight(P))
  else
    0.0

define "Incinerated Waste Total":
  if exists("Incineration Procedures") then
    Sum("Incineration Procedures" P return GetProcedureWeight(P))
  else
    0.0

define "Landfilled Waste Total":
  if exists("Landfill Procedures") then
    Sum("Landfill Procedures" P return GetProcedureWeight(P))
  else
    0.0

define "Composted Waste Total":
  if exists("Composting Procedures") then
    Sum("Composting Procedures" P return GetProcedureWeight(P))
  else
    0.0

define "Energy Recovery Total":
  if exists("Energy Recovery Procedures") then
    Sum("Energy Recovery Procedures" P return GetProcedureWeight(P))
  else
    0.0

define "Other Disposal Total":
  if exists("Other Disposal Procedures") then
    Sum("Other Disposal Procedures" P return GetProcedureWeight(P))
  else
    0.0

// ========== GRI 306-5: 效率指標 ==========

define "Total Bed Days":
  if exists("Inpatient Encounters") then
    Sum(
      "Inpatient Encounters" E
        return
          if E.period is not null and E.period.start is not null and E.period.end is not null then
            days between FHIRHelpers.ToDateTime(E.period.start) and FHIRHelpers.ToDateTime(E.period.end)
          else
            0
    )
  else
    0

define "Waste per Bed Day":
  if "Total Bed Days" > 0 then
    "Total Waste Generated" / ToDecimal("Total Bed Days")
  else
    null

define "Recycling Rate":
  if "Total Waste Generated" > 0 then
    ("Recycled Waste Total" / "Total Waste Generated") * 100
  else
    0.0

define "Reuse Rate":
  if "Total Waste Generated" > 0 then
    ("Reused Waste Total" / "Total Waste Generated") * 100
  else
    0.0

define "Hazardous Waste Percentage":
  if "Total Waste Generated" > 0 then
    ("Hazardous Waste Total" / "Total Waste Generated") * 100
  else
    0.0

define "Diversion Rate":
  if "Total Waste Generated" > 0 then
    (("Recycled Waste Total" + "Reused Waste Total" + "Composted Waste Total" + "Energy Recovery Total")
     / "Total Waste Generated") * 100
  else
    0.0

define "Landfill Rate":
  if "Total Waste Generated" > 0 then
    ("Landfilled Waste Total" / "Total Waste Generated") * 100
  else
    0.0

// ========== 報告輸出 ==========

define "Data Completeness":
  Tuple {
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

define "GRI 306-3 Report":
  Tuple {
    totalWasteGeneratedKg: "Total Waste Generated",
    hazardousWasteKg: "Hazardous Waste Total",
    nonHazardousWasteKg: "Non-hazardous Waste Total",
    measurementPeriod: "Measurement Period"
  }

define "GRI 306-4 Report":
  Tuple {
    recycledKg: "Recycled Waste Total",
    reusedKg: "Reused Waste Total",
    incineratedKg: "Incinerated Waste Total",
    landfilledKg: "Landfilled Waste Total",
    composedKg: "Composted Waste Total",
    energyRecoveryKg: "Energy Recovery Total",
    otherDisposalKg: "Other Disposal Total",
    measurementPeriod: "Measurement Period"
  }

define "GRI 306-5 Report":
  Tuple {
    recyclingRatePercent: "Recycling Rate",
    reuseRatePercent: "Reuse Rate",
    diversionRatePercent: "Diversion Rate",
    landfillRatePercent: "Landfill Rate",
    wastePerBedDayKg: "Waste per Bed Day",
    totalBedDays: "Total Bed Days",
    measurementPeriod: "Measurement Period"
  }

define "ESG Waste Management Report":
  Tuple {
    reportTitle: 'ESG Waste Management Report',
    standard: 'GRI 306: Waste 2020',
    fhirVersion: 'FHIR R4 (4.0.1)',
    reportingPeriod: "Measurement Period",
    gri3063WasteGeneration: "GRI 306-3 Report",
    gri3064WasteDisposal: "GRI 306-4 Report",
    gri3065Performance: "GRI 306-5 Report",
    dataCompleteness: "Data Completeness",
    totalWasteKg: "Total Waste Generated",
    hazardousWastePercent: "Hazardous Waste Percentage",
    diversionRatePercent: "Diversion Rate",
    landfillRatePercent: "Landfill Rate",
    wastePerBedDayKg: "Waste per Bed Day"
  }
