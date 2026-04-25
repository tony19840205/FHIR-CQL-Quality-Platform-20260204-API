/**
 * 西醫基層總額醫療品質資訊 - 門診平均每張慢性病處方箋開藥日數 - 高血壓
 * (指標代碼 1170)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
 *
 * 公式說明:
 *   分子: 開立慢性病疾病別處方箋案件給藥日份加總
 *   分母: 開立慢性病疾病別處方箋次數加總
 *
 *   慢性病定義 (主診斷):
 *     糖尿病 ICD-10-CM 前3碼 E08、E09、E10、E11、E12、E13
 *     高血壓 ICD-10-CM 前3碼 I10、I11、I12、I13
 *     高血脂 ICD-10-CM 前3碼 E78
 *
 *   疾病別: 主診斷為高血壓 (ICD-10-CM 前3碼 I10-I13) 之案件
 *   慢性病用藥 ATC 範圍: C07 (排 C07AA05) 或 C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排 C08CA06)、C08DA、C08DB、C09AA、C09CA
 *
 *   分母慢性病處方箋: 案件分類=04 或 08, 排除給藥日份 < 3。
 *
 * 次診斷亦屬慢性病並且處方該慢性病藥物之出現次數一併納入統計。

 */
library Indicator_PC_06_2_Chronic_Prescription_Days_Hypertension version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHICaseClass": 'https://www.nhi.gov.tw/cs/caseClassification'

code "Chronic Case Class 04": '04' from "NHICaseClass"
code "Chronic Case Class 08": '08' from "NHICaseClass"

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 慢性病處方箋 (案件分類=04/08, 給藥日份>=3, 主診斷符合疾病別)
define "Denominator Cases":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

// 各案件給藥日份
define "Numerator Drug Days":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"
        return Coalesce(M.dispenseRequest.expectedSupplyDuration.value, 0)

define "Denominator":
    Count("Denominator Cases")

define "Numerator":
    Sum("Numerator Drug Days")

define "Measure Score":
    if "Denominator" > 0
        then ("Numerator" * 1.0) / "Denominator"
        else 0.0
