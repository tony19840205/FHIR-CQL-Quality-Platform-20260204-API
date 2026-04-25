/**
 * 西醫基層總額醫療品質資訊 - 剖腹產率 - 整體
 * (指標代碼 1136.01)
 *
 * 資料範圍:
 *   西醫基層總額住院生產案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: 剖腹產案件數
 *   分母: 生產案件數 (自然產案件 + 剖腹產案件)
 *
 *   生產案件 = 自然產案件 + 剖腹產案件
 *
 *   (1) 自然產案件 (符合任一條件):
 *       a. TW-DRG 前3碼 = 372-375
 *       b. DRG_CODE = 0373A、0373C
 *       c. 自然產醫令: 81017C、81018C、81019C、81024C、81025C、81026C、
 *          81034C、97004C、97005D、97934C
 *
 *   (2) 剖腹產案件 (符合任一條件):
 *       a. TW-DRG 前3碼 = 370、371、513
 *       b. DRG_CODE = 0371A、0373B
 *       c. 剖腹產醫令: 81004C、81005C、81028C、81029C、97009C、97014C
 *
 *   (3) 不具適應症之剖腹產 (自行要求): TW-DRG=513 或 DRG_CODE=0373B 或 醫令=97014C
 *
 * 備註: 本指標含符合適應症及自行要求剖腹產案件, 各院所收治產婦複雜度不同,
 *       不宜逕予判斷院所生產照護品質。
 */
library Indicator_PC_09_1_Cesarean_Section_Rate_Overall version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWDRG": 'https://www.nhi.gov.tw/cs/twdrg'
codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 生產案件 (denominator: 自然產 + 剖腹產)
define "Denominator Cases":
    [Procedure] P
        where P.performed during "Measurement Period"

// 剖腹產 / 自行要求剖腹產 / 具適應症剖腹產 案件 (依指標而定)
define "Numerator Cases":
    [Procedure] P
        where P.performed during "Measurement Period"

define "Denominator":
    Count("Denominator Cases")

define "Numerator":
    Count("Numerator Cases")

define "Measure Score":
    if "Denominator" > 0
        then ("Numerator" * 100.0) / "Denominator"
        else 0.0
