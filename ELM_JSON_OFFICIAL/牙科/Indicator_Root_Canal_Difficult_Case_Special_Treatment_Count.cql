/**
 * ???迂: ?Ｘ??瑁??蝞⊿??亥????賊?
 * ??憿: ???扯風?釭??
 * 閮??餌?: 瘥迤
 * ??憿?: 蝯梯??賊??? (????)
 * 
 * ??摰儔: ?思?璈?閰脣迤撖行?寧恣????孵??(90091C~90098C)????
 * 
 * ?券?
 * - 閰摯?怎?璈???銴??寧恣獢????
 * - 鈭圾撠?瘝餌???????
 * - 雿?怎??釭??銵偌皞???璅?
 * 
 * 閮?撟游漲: 2026撟?瘞?115撟?
 */

library Indicator_Root_Canal_Difficult_Case_Special_Treatment_Count version '1.0.0'

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