/**
 * ???迂: ?剜革隞乩??咱?瑁?????靽??銋???
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * 閮??砍?: (??/??) x 100%
 * 
 * ??: ?怎??Ｘ??瑁??咱???靽???犖??
 * ??: ?怎??Ｘ?撠梢鈭箏銝?甇脖誑銝?蝡乩犖??
 * 
 * ??璇辣: 撟湧翩??蝞撠梢撟湔? - ?箇?撟湔? ??72(??)
 * ??璇辣: ?咱???靽???靽摨?甈??箝C81?C87??
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Pediatric_Under_6_Oral_Preventive_Health_Service_Rate version '1.0.0'

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