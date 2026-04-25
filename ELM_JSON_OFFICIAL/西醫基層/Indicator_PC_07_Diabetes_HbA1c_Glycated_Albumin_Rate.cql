/**
 * 西醫基層總額醫療品質資訊 - 糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin) 執行率
 * (指標編號 3691)
 *
 * 資料範圍:
 *   西醫基層總額之門診案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: 分母 ID 中, 在統計期間於門診有執行 HbA1c 或糖化白蛋白檢驗之人數
 *   分母: 統計累計自當年度1月起至統計當期, 門診主次診斷為糖尿病
 *         (ICD-10-CM 前3碼 E08-E13) 且使用糖尿病用藥 (ATC 前3碼 A10) 之病人數
 *
 *   HbA1c 或 glycated albumin 案件: 申報醫令代碼前5碼為 09006 或 09139。
 *   注意: 主次診斷為糖尿病且使用糖尿病用藥兩個條件須同時發生在同一處方案件。
 *
 *   依衛生福利部 114/07/07 衛部保字第 1141260306 號公告, 自 114年第1季起,
 *   修訂指標操作型定義, 統計範圍為當年度1月累計至當期。
 */
library Indicator_PC_07_Diabetes_HbA1c_Glycated_Albumin_Rate version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'

code "HbA1c Order 09006 Prefix": '09006' from "NHIOrder" display 'HbA1c'
code "Glycated Albumin Order 09139 Prefix": '09139' from "NHIOrder" display 'Glycated Albumin'
code "Diabetes Drug A10 Prefix": 'A10' from "ATC" display 'Drugs used in diabetes'

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 糖尿病使用糖尿病用藥之病人 (denominator)
define "Denominator Cases":
    [Patient] P

// 於統計期間有執行 HbA1c 或 glycated albumin 檢驗之糖尿病病人 (numerator)
define "Numerator Cases":
    [Patient] P

define "Denominator":
    Count("Denominator Cases")

define "Numerator":
    Count("Numerator Cases")

define "Measure Score":
    if "Denominator" > 0
        then ("Numerator" * 100.0) / "Denominator"
        else 0.0
