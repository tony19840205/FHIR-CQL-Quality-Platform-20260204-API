/**
 * 西醫基層總額醫療品質資訊 - 門診抗生素使用率 (指標代碼 1140.01)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種), 排除代辦案件
 *
 * 公式說明:
 *   分子: 給藥案件之使用抗生素藥品
 *         (醫令代碼為10碼, ATC 前3碼為 J01 ANTIBACTERIALS FOR SYSTEMIC USE) 案件數
 *   分母: 給藥案件數
 *
 *   基層醫療機構使用抗生素藥品案件數 / 基層醫療機構開藥總案件數
 *   抗生素藥品: ATC 碼前3碼為 J01 (ANTIBACTERIALS FOR SYSTEMIC USE)
 */
library Indicator_PC_02_1_Outpatient_Antibiotic_Usage_Rate version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ATC": 'http://www.whocc.no/atc'

code "Antibiotic J01 Prefix": 'J01' from "ATC" display 'ANTIBACTERIALS FOR SYSTEMIC USE'

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

define "Denominator Cases":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

define "Numerator Cases":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

define "Denominator":
    Count("Denominator Cases")

define "Numerator":
    Count("Numerator Cases")

define "Measure Score":
    if "Denominator" > 0
        then ("Numerator" * 100.0) / "Denominator"
        else 0.0
