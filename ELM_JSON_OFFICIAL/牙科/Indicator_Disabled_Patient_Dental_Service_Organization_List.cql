/**
 * ???迂: ???孵?頨怠??????????Ｘ??
 * ??憿: ???扯風?釭?? - 皜??璅?
 * 閮??餌?: 瘥迤
 * ??摰儔: 閰脤鈭???瑽?行????孵??頨怠??????怎???
 * 
 * ??憿?: 皜??璅??∪?摮?瘥??Ｗ蝚血?璇辣??皜嚗?
 * 
 * 霅?孵?:
 * - ?孵??頨怠??????怎????蔭隞?Ⅳ
 * - 獢辣???箇畾澈敹?蝷???
 * - ???澈敹?蝷?憭批?
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Disabled_Patient_Dental_Service_Organization_List version '1.0.0'

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