/**
 * ???迂: ?瑁???蝷祥??鈭箸
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * ??憿?: 蝯梯??賊??? (????)
 * 
 * ??摰儔: ?思?璈?閰脣迤18甇脖誑銝銵??函?瘝餌??賊??思誘?犖??
 * 
 * ??祥??隞斤91006C??1007C??1008C?4001C?4002C?4003C
 * 
 * ?券?
 * - 閰摯?怎?璈???蝷祥????靘?瘜?
 * - 鈭圾?犖????祥??瘨菔???
 * - 雿????亙熒靽脰??怎???璅?
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Periodontal_Basic_Treatment_Patient_Count version '1.0.0'

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