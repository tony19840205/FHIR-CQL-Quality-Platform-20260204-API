library Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 同醫院門診同藥理用藥日數重疊率-抗思覺失調症(口服)
// 指標代碼: 1726
// 製作日期：2025-11-20
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署
// ============================================
//
// 【資料時間範圍】
// 查詢期間: 2024-01-01 ~ 2026-01-09 (今天)
// 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
//
// 【資料範圍】
// (1)醫院總額之門診處方抗思覺失調藥物案件
// (2)排除代辦案件
//
// 【公式說明】(依健保指標代碼 1726)
// 同醫院門診同藥理用藥日數重疊率-抗思覺失調症 = 
//     分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
//     分母: 各案件之「給藥日數」總和
// 
// (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
// (2)抗思覺失調藥物: ATC前5碼為N05AA、N05AB(排除N05AB04)、N05AD、N05AE、N05AF、N05AH、N05AL、N05AN(排除N05AN01)、N05AX、N05AC、N05AG
// 
// 排除條件:
//   1.排除特定ATC代碼: N05AB04、N05AN01
//   2.排除代辦案件
// ============================================

// Code Systems
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

// Value Sets
valueset "Antipsychotic ATC Codes": 'http://nhi.gov.tw/fhir/ValueSet/antipsychotic-atc-codes'

// Codes - Encounter Types
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'

// Codes - Medication Request Status
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// Codes - Encounter Status
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// Antipsychotic ATC Code Prefixes (N05A)
code "N05AA": 'N05AA' from "ATC" display 'Phenothiazines with aliphatic side-chain - 酚噻嗪類(脂肪族側鏈)'
code "N05AB": 'N05AB' from "ATC" display 'Phenothiazines with piperazine structure - 酚噻嗪類(哌嗪結構)'
code "N05AC": 'N05AC' from "ATC" display 'Phenothiazines with piperidine structure - 酚噻嗪類(哌啶結構)'
code "N05AD": 'N05AD' from "ATC" display 'Butyrophenone derivatives - 丁苯酮類'
code "N05AE": 'N05AE' from "ATC" display 'Indole derivatives - 吲哚類'
code "N05AF": 'N05AF' from "ATC" display 'Thioxanthene derivatives - 噻噸類'
code "N05AG": 'N05AG' from "ATC" display 'Diphenylbutylpiperidine derivatives - 二苯丁基哌啶類'
code "N05AH": 'N05AH' from "ATC" display 'Diazepines, oxazepines, thiazepines and oxepines - 二氮䓬類'
code "N05AL": 'N05AL' from "ATC" display 'Benzamides - 苯甲醯胺類'
code "N05AN": 'N05AN' from "ATC" display 'Lithium - 鋰鹽'
code "N05AX": 'N05AX' from "ATC" display 'Other antipsychotics - 其他抗精神病藥'

// Excluded ATC Codes
code "N05AB04": 'N05AB04' from "ATC" display 'Prochlorperazine - 應排除'
code "N05AN01": 'N05AN01' from "ATC" display 'Lithium - 應排除'

// Dosage Forms
code "Oral": '385268001' from "SNOMEDCT" display 'Oral dose form - 口服劑型'
code "Injection": '385219001' from "SNOMEDCT" display 'Injection - 注射劑'

// Contexts
context Patient