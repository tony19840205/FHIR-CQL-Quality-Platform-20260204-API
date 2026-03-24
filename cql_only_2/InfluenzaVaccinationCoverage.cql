library InfluenzaVaccinationCoverage version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2024-12-31T23:59:59.999]

context Patient

define function IsInfluenzaVaccineCode(code String):
  code in {'88','141','15','16','135','140','161','166','185','186','197','205','J07BB01','J07BB02','J07BB03'}

define function HasInfluenzaVaccineCode(immunization Immunization):
  exists(immunization.vaccineCode.coding C where IsInfluenzaVaccineCode(C.code.value))

define function IsCompletedDuringPeriod(immunization Immunization):
  immunization.status.value = 'completed' and immunization.occurrence during "Measurement Period"

define "All Patients":
  [Patient]

define "Has Patient Data":
  exists([Patient])

define "Has Immunization Data":
  exists([Immunization])

define "Influenza Immunizations":
  [Immunization] I
    where IsCompletedDuringPeriod(I) and HasInfluenzaVaccineCode(I)

define "Patient Age At Start":
  AgeInYears()

define "Is Patient 65 Or Older":
  "Patient Age At Start" >= 65

define "Patient Has Flu Vaccination":
  exists("Influenza Immunizations" I where I.patient.reference.value.contains(Patient.id.value))

define "All Patients Count":
  Count("All Patients")

define "Patients 65+ Count":
  Count("All Patients" P where AgeInYears() >= 65)

define "All Vaccinated Count":
  Count("All Patients" P where exists([Immunization] I where I.patient.reference.value.contains(P.id.value) and IsCompletedDuringPeriod(I) and HasInfluenzaVaccineCode(I)))

define "Vaccinated 65+ Count":
  Count("All Patients" P where AgeInYears() >= 65 and exists([Immunization] I where I.patient.reference.value.contains(P.id.value) and IsCompletedDuringPeriod(I) and HasInfluenzaVaccineCode(I)))

define "Coverage 65+ Rate":
  if "Patients 65+ Count" > 0 then Round(("Vaccinated 65+ Count" / "Patients 65+ Count") * 100.0, 2) else 0.0

define "Coverage All Rate":
  if "All Patients Count" > 0 then Round(("All Vaccinated Count" / "All Patients Count") * 100.0, 2) else 0.0

define "Can Calculate":
  "Has Patient Data" and "Has Immunization Data"

define "Data Status Message":
  if "Can Calculate" then 'Data Complete' else if not "Has Immunization Data" and not "Has Patient Data" then 'No Data' else if not "Has Immunization Data" then 'No Immunization Data' else 'No Patient Data'

define "Indicator Result": { indicatorCode: 'FLU_COV_65P', indicatorName: 'Influenza Vaccination Coverage 65+', version: '1.0.0', canCalculate: "Can Calculate", dataStatus: "Data Status Message", coverage_65plus_numerator: "Vaccinated 65+ Count", coverage_65plus_denominator: "Patients 65+ Count", coverage_65plus_rate: "Coverage 65+ Rate", coverage_all_numerator: "All Vaccinated Count", coverage_all_denominator: "All Patients Count", coverage_all_rate: "Coverage All Rate" }