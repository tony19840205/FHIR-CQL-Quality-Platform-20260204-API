/**
 * ???迂: 蝪∪?扳??銵?銝??乩誑?找??閬?敺?亥???瘥?
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * 閮??砍?: [1-(??/??)] x 100%
 * 
 * ??: 蝪∪??敺?0憭拙??望????孵????朣???
 * ??: 蝪∪????朣???
 * 
 * 餈質馱?? ??敺?0憭拙
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Simple_Tooth_Extraction_No_Postop_Special_Treatment_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

define "Measurement Period":
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

define "All Procedures":
  [Procedure] P
  where P.performed during "Measurement Period"

define "All Encounters":
  [Encounter] E
  where E.period during "Measurement Period"

define "Total Procedure Count":
  Count("All Procedures")

define "Total Encounter Count":
  Count("All Encounters")