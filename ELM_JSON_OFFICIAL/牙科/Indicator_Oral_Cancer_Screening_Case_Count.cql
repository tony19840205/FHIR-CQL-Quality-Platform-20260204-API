/**
 * ???迂: ?瑁?????祟瑼Ｖ?獢辣??
 * ??憿: ???扯風?釭?? - 蝯梯??賊???璅?
 * 閮??餌?: 瘥迤
 * ??摰儔: ?思?璈?閰脣迤撖行????祟瑼?獢辣???態3銝停?怠??IC95)銋?隞嗆
 * 
 * ??憿?: 蝯梯??賊???璅??∪?摮?瘥?蝯梯?蝚血?璇辣??隞嗥蜇?賂?
 * 
 * 蝭拇炎璇辣:
 * - 獢辣??: A3
 * - 撠梢摨?: IC95
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Oral_Cancer_Screening_Case_Count version '1.0.0'

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