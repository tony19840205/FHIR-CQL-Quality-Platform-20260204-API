/**
 * 西醫基層總額醫療品質資訊 - 慢性病連續處方箋開立率 (指標代碼 223)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
 *
 * 公式說明:
 *   分子: 開立慢性病連續處方箋的案件數
 *         (案件分類=02、04、08 且給藥日份 >= 21)
 *   分母: 慢性病給藥案件數 (案件分類=02、04、08)
 */
library Indicator_PC_04_Chronic_Continuous_Prescription_Rate version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "NHICaseClass": 'https://www.nhi.gov.tw/cs/caseClassification'

code "Chronic Case Class 02": '02' from "NHICaseClass"
code "Chronic Case Class 04": '04' from "NHICaseClass"
code "Chronic Case Class 08": '08' from "NHICaseClass"

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 慢性病給藥案件 (case class 02/04/08)
define "Denominator Cases":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

// 連續處方箋: 給藥日份 >= 21
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
