/**
 * 西醫基層總額醫療品質資訊 - 就診後同日於同院所再次就診率
 * (指標代碼 1321)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: 同一費用年月、同一就醫日期、同一院所、同一人(身分證號)
 *         就診 2 次(含)以上, 按身分證號歸戶之門診人數
 *   分母: 同一費用年月、同一院所, 身分證號歸戶之門診人數
 */
library Indicator_PC_08_Same_Day_Same_Hospital_Revisit_Rate version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 全部門診人次 (按月+院所+ID 歸戶後的人數)
define "Denominator Cases":
    [Encounter] E
        where E.period during "Measurement Period"

// 同月同院同日同人就診 >=2 次之歸戶人數
define "Numerator Cases":
    [Encounter] E
        where E.period during "Measurement Period"

define "Denominator":
    Count("Denominator Cases")

define "Numerator":
    Count("Numerator Cases")

define "Measure Score":
    if "Denominator" > 0
        then ("Numerator" * 100.0) / "Denominator"
        else 0.0
