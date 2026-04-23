/**
 * ???迂: ??曄??批?箸?蔭?瑁???
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * 閮??砍?: (??/??) x 100%
 * 
 * ??: ?思?璈??典僑?喳??曄??批?箸?蔭?犖??
 * ??: ?思?璈??典僑?喳?典???單??支犖??
 * 
 * ??璇辣: ??曄??批?箸?蔭?乩?隞?Ⅳ??91014C??1114C
 * ??璇辣: ?典???單??文靽誨蝣潛 91004C??1104C
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Periodontal_Disease_Control_Basic_Treatment_Rate version '1.0.0'

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