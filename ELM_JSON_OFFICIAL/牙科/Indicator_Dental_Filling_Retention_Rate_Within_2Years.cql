/**
 * ???迂: ??憛怨?靽???鈭僑隞亙
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * 閮??砍?: [1 - (??/??)] x 100%
 * 
 * ??: ?思?璈?鈭僑?找?????鈭箏?憿?嚗??拇活隞乩?(????憛怨?銋??
 * ??: 閰脫????Ｘ????????嚗祕?賜?朣‵鋆??賊?
 * 
 * ??璇辣: ??憛怨??乩?隞?Ⅳ 89001 ??9012??9014??9015
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Dental_Filling_Retention_Rate_Within_2Years version '1.0.0'

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