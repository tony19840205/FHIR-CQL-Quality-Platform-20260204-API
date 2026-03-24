library Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155 version '1.155.000'

using QDM version '5.6'

valueset "Inpatient": 'urn:oid:2.16.840.1.113883.3.666.5.307'
valueset "Surgery Procedures": 'urn:oid:2.16.840.1.113883.3.666.5.307'
valueset "Prophylactic Antibiotics": 'urn:oid:2.16.840.1.113883.3.117.1.7.1.202'

parameter "Measurement Period" Interval<DateTime>
default Interval[@2019-01-01T00:00:00.0, @2020-01-01T00:00:00.0)

context Patient

define "Qualifying Encounters":
  ["Encounter, Performed": "Inpatient"] QualifyingEncounter
  where QualifyingEncounter.relevantPeriod during "Measurement Period"

define "Surgery Cases":
  ["Procedure, Performed": "Surgery Procedures"] Surgery
  where Surgery.relevantPeriod during "Measurement Period"

define "Surgery Cases With Antibiotics":
  "Surgery Cases" SurgeryCase
  where exists(
    ["Medication, Administered": "Prophylactic Antibiotics"] Antibiotics
    where Antibiotics.relevantPeriod starts after start of SurgeryCase.relevantPeriod
  )

define "Cases Over 3 Days":
  "Surgery Cases With Antibiotics" SurgeryCase
  where exists(
    ["Medication, Administered": "Prophylactic Antibiotics"] Antibiotics
    where Antibiotics.relevantPeriod starts after start of SurgeryCase.relevantPeriod
  )

define "Numerator":
  "Cases Over 3 Days"

define "Denominator":
  "Surgery Cases With Antibiotics"

define "Initial Population":
  "Surgery Cases"

define "Antibiotic Over 3 Days Rate":
  if Count("Denominator") > 0 then
    (Count("Numerator") * 100.0) / Count("Denominator")
  else
    null