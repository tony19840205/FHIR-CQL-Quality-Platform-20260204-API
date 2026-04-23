/**
 * ???迂: ??甇脖誑銝?鈭箏銵???蝯皜銋???
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * 閮??砍?: (??/??) x 100%
 * 
 * ??: ?思?璈??喳??甇脖誑銝銵???蝯皜銵?鈭箸
 * ??: ?思?璈???閮箏?鈭革隞乩?蝮賜?鈭箸
 * 
 * ??璇辣: ?典???單??方??乩?隞?Ⅳ??91004C??1104C??1005C??1017C??1089C??1090C
 * ??璇辣: 撟湧翩銋?蝞撠梢撟??箇?撟氯12
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Full_Mouth_Calculus_Removal_Rate_Age_12_Plus version '1.0.0'

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