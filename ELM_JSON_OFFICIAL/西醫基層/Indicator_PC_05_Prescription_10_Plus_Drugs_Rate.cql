/**
 * 西醫基層總額醫療品質資訊 - 門診每張處方箋開藥品項數大於等於十項之案件比率
 * (指標代碼 1749)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
 *   排除代辦案件及「補報原因註記」為 2 之案件
 *
 * 公式說明:
 *   分子: 分母案件中藥品項數 >=10 項之案件數
 *   分母: 給藥案件數
 *
 *   藥品項數: 醫令類別 1 或 4、醫令代碼為 10 碼且醫令數量 > 0,
 *            同院同處方下同醫令代碼歸戶為一項。
 */
library Indicator_PC_05_Prescription_10_Plus_Drugs_Rate version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 給藥案件 (每張處方箋一筆)
define "Denominator Cases":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

// 處方藥品項數 >=10 之處方箋
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
