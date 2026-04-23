/**
 * ???迂: ?寧恣瘝餌?靽???銋喟?銝?隞亙
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * 閮??砍?: [1 - (??/??)] x 100%
 * 
 * ??: ?思?璈?瘥迤撠梢?犖銋喟??寧恣瘝餌?敺?0憭拙?銵像?蝞⊥祥?像???寧恣瘝餌?憿??????
 * ??: ?思?璈?瘥迤銋喟??寧恣瘝餌?憿
 * 
 * ??璇辣:
 * 1. 銋喟??寧恣瘝餌??乩?隞?Ⅳ90016C
 * 2. 銋喟?憭蝞⊥祥?靽誨蝣?0018C
 * 3. ??憿?乩?隞?Ⅳ92055C
 * 
 * ??璇辣: 銋喟??寧恣瘝餌?憿?箏靽??0015C?像?蝞⊥祥?遙銝?思誘??
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Root_Canal_Treatment_Retention_Rate_Primary_Tooth_3Months version '1.0.0'

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