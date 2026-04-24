/**
 * 西醫基層總額醫療品質資訊 - 門診注射劑使用率 (指標代碼 1150.01)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
 *   排除代辦案件
 *
 * 公式說明:
 *   分子: 給藥案件之針劑藥品 (醫令代碼為10碼, 且第8碼為「2」) 案件數
 *         排除以下:
 *           (a) 門診化療注射劑: 醫令 37005B、37031B-37041B 或癌症用藥
 *               (ATC 前3碼 L01、L02 或 H01AB01、L03AB01、L03AB04、L03AB05、
 *                L03AB15、L03AC01、L03AX03、L03AX16、L04AX01、M05BA02、
 *                M05BA03、M05BA06、M05BA08(且規格量 4.00 MG)、M05BX04、V10XX03,
 *                且醫令代碼為10碼且第8碼為2)
 *           (b) 急診注射劑: 案件分類代碼為 02
 *           (c) 流感疫苗注射劑: 藥品成分 ATC 前5碼 J07BB
 *           (d) 外傷緊急處置使用之破傷風類毒素注射劑: ATC J07AM01
 *           (e) 經醫師指導後得攜回之注射藥品 (依全民健康保險藥品給付規定通則)
 *   分母: 給藥案件數
 */
library Indicator_PC_01_Outpatient_Injection_Usage_Rate version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'
codesystem "NHICaseClass": 'https://www.nhi.gov.tw/cs/caseClassification'

code "Chemo Order 37005B": '37005B' from "NHIOrder"
code "Tetanus Toxoid J07AM01": 'J07AM01' from "ATC"
code "Influenza Vaccine J07BB": 'J07BB' from "ATC"
code "Emergency Case Class 02": '02' from "NHICaseClass"

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 給藥案件 (denominator base)
define "Denominator Cases":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

// 注射劑案件 (醫令第8碼為「2」), 排除化療/急診/疫苗/破傷風/可攜回
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
