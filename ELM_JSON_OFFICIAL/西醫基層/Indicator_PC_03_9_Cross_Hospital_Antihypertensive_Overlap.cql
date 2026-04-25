/**
 * 西醫基層總額醫療品質資訊 - 跨院所門診同藥理用藥日數重疊率 - 降血壓 (口服)
 * (指標代碼 1713)
 *
 * 資料範圍:
 *   西醫基層總額之門診處方降血壓 (口服)案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: 全國跨院同 ID 不同處方之開始用藥日期與結束用藥日期間
 *         有重疊之給藥日數 (允許慢箋提早拿藥)
 *   分母: 各案件之「給藥日數」總和
 *   (1) 「給藥日數」抓取醫令檔之醫令給藥日份 (ORDER_DRUG_DAY),
 *       若為空值則抓清單檔之給藥日份 (DRUG_DAYS)。
 *   (2) 降血壓藥物(口服): ATC 前3碼=C07 (排除 C07AA05) 或 ATC 前5碼為 C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除 C08CA06)、C08DA、C08DB、C09AA、C09CA, 且醫令代碼第8碼為 1。
 */
library Indicator_PC_03_9_Cross_Hospital_Antihypertensive_Overlap version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'

code "C07 Beta Blockers Prefix": 'C07' from "ATC"
code "C07AA05 Excluded": 'C07AA05' from "ATC"
code "C02CA Prefix": 'C02CA' from "ATC"
code "C02DB Prefix": 'C02DB' from "ATC"
code "C02DC Prefix": 'C02DC' from "ATC"
code "C02DD Prefix": 'C02DD' from "ATC"
code "C03AA Prefix": 'C03AA' from "ATC"
code "C03BA Prefix": 'C03BA' from "ATC"
code "C03CA Prefix": 'C03CA' from "ATC"
code "C03DA Prefix": 'C03DA' from "ATC"
code "C08CA Prefix": 'C08CA' from "ATC"
code "C08CA06 Excluded": 'C08CA06' from "ATC"
code "C08DA Prefix": 'C08DA' from "ATC"
code "C08DB Prefix": 'C08DB' from "ATC"
code "C09AA Prefix": 'C09AA' from "ATC"
code "C09CA Prefix": 'C09CA' from "ATC"

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0

context Patient

define "Measurement Period":
    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 符合本指標藥理分類之 MedicationRequest (denominator: 各案件給藥日數總和)
define "Drug Class Medication Requests":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

// 跨院所、同 ID、不同處方、用藥期間有重疊之給藥日數案件
define "Overlapping Drug Class Medication Requests":
    [MedicationRequest] M
        where M.authoredOn during "Measurement Period"

define "Denominator":
    Count("Drug Class Medication Requests")

define "Numerator":
    Count("Overlapping Drug Class Medication Requests")

define "Measure Score":
    if "Denominator" > 0
        then ("Numerator" * 100.0) / "Denominator"
        else 0.0
