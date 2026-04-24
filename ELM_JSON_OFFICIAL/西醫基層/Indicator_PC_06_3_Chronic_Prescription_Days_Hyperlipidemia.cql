/**
 * Indicator_PC_06_3_Chronic_Prescription_Days_Hyperlipidemia
 * Western Medicine Primary Care (西醫基層) Quality Indicator
 * Backend JS computes the actual numerator/denominator/rate.
 */
library Indicator_PC_06_3_Chronic_Prescription_Days_Hyperlipidemia version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

define "All Encounters":
    [Encounter] E
        where E.period during "Measurement Period"

define "All Medication Requests":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

define "All Procedures":
    [Procedure] P
        where P.performed during "Measurement Period"

define "Total Encounter Count":
    Count("All Encounters")

define "Total Medication Count":
    Count("All Medication Requests")

define "Total Procedure Count":
    Count("All Procedures")