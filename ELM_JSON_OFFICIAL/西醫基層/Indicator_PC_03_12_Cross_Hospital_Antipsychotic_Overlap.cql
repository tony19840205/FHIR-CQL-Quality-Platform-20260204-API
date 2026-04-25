/**
 * 西醫基層總額醫療品質資訊 - 跨院所門診同藥理用藥日數重疊率 - 抗思覺失調症
 * (指標代碼 1729)
 *
 * 資料範圍:
 *   西醫基層總額之門診處方抗思覺失調症案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: 全國跨院同 ID 不同處方之開始用藥日期與結束用藥日期間
 *         有重疊之給藥日數 (允許慢箋提早拿藥)
 *   分母: 各案件之「給藥日數」總和
 *   (1) 「給藥日數」抓取醫令檔之醫令給藥日份 (ORDER_DRUG_DAY),
 *       若為空值則抓清單檔之給藥日份 (DRUG_DAYS)。
 *   (2) 抗思覺失調藥物: ATC 前5碼=N05AA、N05AB、N05AD、N05AE、N05AF、N05AH、N05AL、N05AN(排除 N05AN01)、N05AX、N05AC、N05AG。
 */
library Indicator_PC_03_12_Cross_Hospital_Antipsychotic_Overlap version '1.0.0'

using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'

code "N05AA Phenothiazines Aliphatic Prefix": 'N05AA' from "ATC"
code "N05AB Phenothiazines Piperazine Prefix": 'N05AB' from "ATC"
code "N05AC Phenothiazines Piperidine Prefix": 'N05AC' from "ATC"
code "N05AD Butyrophenones Prefix": 'N05AD' from "ATC"
code "N05AE Indole Derivatives Prefix": 'N05AE' from "ATC"
code "N05AF Thioxanthenes Prefix": 'N05AF' from "ATC"
code "N05AG Diphenylbutylpiperidines Prefix": 'N05AG' from "ATC"
code "N05AH Diazepines Oxazepines Prefix": 'N05AH' from "ATC"
code "N05AL Benzamides Prefix": 'N05AL' from "ATC"
code "N05AN Lithium Prefix": 'N05AN' from "ATC"
code "N05AN01 Lithium Excluded": 'N05AN01' from "ATC"
code "N05AX Other Antipsychotics Prefix": 'N05AX' from "ATC"

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
