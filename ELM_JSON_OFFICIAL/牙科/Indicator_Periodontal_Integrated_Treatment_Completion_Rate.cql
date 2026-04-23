/**
 * ???迂: ?Ｘ???絞?祥?獢???
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * 閮??砍?: (??/??) x 100%
 * 
 * ??: 蝯梯????Ｘ??瑁???絞?祥?獢洵銝?挾(P4001C??1021C)獢辣嚗?
 *       靘?鈭箸飛?塚??澆銵4001C??1021C敺?80憭拙?銵??函?蝯勗?瘝餌??寞?
 *       蝚砌??挾(P4003C??1023C)??隞嗆
 * ??: 蝯梯????Ｘ??瑁???絞?祥?獢洵銝?挾(P4001C??1021C)獢辣??
 * 
 * ??璇辣: ??絞?祥?獢洵銝?畾萇Ⅳ?P4003C??1023C
 * ??璇辣: ??絞?祥?獢洵銝?挾蝣澆??摺4001C??1021C
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Periodontal_Integrated_Treatment_Completion_Rate version '1.0.0'

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