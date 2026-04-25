// Rewrites 9 spec-faithful CQL files: PC_05, PC_06_1/2/3, PC_07, PC_08, PC_09_1/2/3
// Run: node scripts/rewrite_pc_cql_part3.js
const fs = require('fs');
const path = require('path');

const DIR = path.join(__dirname, '..', 'ELM_JSON_OFFICIAL', '西醫基層');

function header(libName, comment) {
  return `/**\n${comment}\n */\nlibrary ${libName} version '1.0.0'\n\nusing FHIR version '4.0.1'\ninclude FHIRHelpers version '4.0.1' called FHIRHelpers\n\n`;
}

function periodCtx() {
  return `parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0\nparameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0\n\ncontext Patient\n\ndefine "Measurement Period":\n    Interval[MeasurementPeriodStart, MeasurementPeriodEnd]\n\n`;
}

function rateMeasure() {
  return `define "Denominator":\n    Count("Denominator Cases")\n\ndefine "Numerator":\n    Count("Numerator Cases")\n\ndefine "Measure Score":\n    if "Denominator" > 0\n        then ("Numerator" * 100.0) / "Denominator"\n        else 0.0\n`;
}

function avgMeasure() {
  return `define "Denominator":\n    Count("Denominator Cases")\n\ndefine "Numerator":\n    Sum("Numerator Drug Days")\n\ndefine "Measure Score":\n    if "Denominator" > 0\n        then ("Numerator" * 1.0) / "Denominator"\n        else 0.0\n`;
}

const files = {};

// ===== PC_05 處方10種以上藥品比率 (1749) =====
files['Indicator_PC_05_Prescription_10_Plus_Drugs_Rate'] =
  header('Indicator_PC_05_Prescription_10_Plus_Drugs_Rate',
` * 西醫基層總額醫療品質資訊 - 門診每張處方箋開藥品項數大於等於十項之案件比率
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
 *            同院同處方下同醫令代碼歸戶為一項。`)
+ `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n\n`
+ periodCtx()
+ `// 給藥案件 (每張處方箋一筆)\n`
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `// 處方藥品項數 >=10 之處方箋\n`
+ `define "Numerator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ rateMeasure();

// ===== PC_06_1 慢性病平均給藥日數-糖尿病 (1169) =====
function p06(lib, code, diseaseName, diseaseDesc, atcDesc, icdComment) {
return header(lib,
` * 西醫基層總額醫療品質資訊 - 門診平均每張慢性病處方箋開藥日數 - ${diseaseName}
 * (指標代碼 ${code})
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
 *   疾病別: ${diseaseDesc}
 *   慢性病用藥 ATC 範圍: ${atcDesc}
 *
 *   分母慢性病處方箋: 案件分類=04 或 08, 排除給藥日份 < 3。
${icdComment ? ' *\n * ' + icdComment + '\n' : ''}`)
+ `codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'\n`
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n`
+ `codesystem "NHICaseClass": 'https://www.nhi.gov.tw/cs/caseClassification'\n\n`
+ `code "Chronic Case Class 04": '04' from "NHICaseClass"\n`
+ `code "Chronic Case Class 08": '08' from "NHICaseClass"\n\n`
+ periodCtx()
+ `// 慢性病處方箋 (案件分類=04/08, 給藥日份>=3, 主診斷符合疾病別)\n`
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `// 各案件給藥日份\n`
+ `define "Numerator Drug Days":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n        return Coalesce(M.dispenseRequest.expectedSupplyDuration.value, 0)\n\n`
+ avgMeasure();
}

files['Indicator_PC_06_1_Chronic_Prescription_Days_Diabetes'] = p06(
  'Indicator_PC_06_1_Chronic_Prescription_Days_Diabetes', '1169', '糖尿病',
  '主診斷為糖尿病 (ICD-10-CM 前3碼 E08-E13) 之案件',
  'A10 (Drugs used in diabetes)',
  '次診斷亦屬慢性病並且處方該慢性病藥物之出現次數一併納入統計 (依據跨院所門診同藥理用藥日數重疊率之 ATC 定義, 不分口服及注射)。');

files['Indicator_PC_06_2_Chronic_Prescription_Days_Hypertension'] = p06(
  'Indicator_PC_06_2_Chronic_Prescription_Days_Hypertension', '1170', '高血壓',
  '主診斷為高血壓 (ICD-10-CM 前3碼 I10-I13) 之案件',
  'C07 (排 C07AA05) 或 C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、'
  + 'C03DA、C08CA(排 C08CA06)、C08DA、C08DB、C09AA、C09CA',
  '次診斷亦屬慢性病並且處方該慢性病藥物之出現次數一併納入統計。');

files['Indicator_PC_06_3_Chronic_Prescription_Days_Hyperlipidemia'] = p06(
  'Indicator_PC_06_3_Chronic_Prescription_Days_Hyperlipidemia', '1171', '高血脂',
  '主診斷為高血脂 (ICD-10-CM 前3碼 E78) 之案件',
  'C10AA、C10AB、C10AC、C10AD、C10AX',
  '次診斷亦屬慢性病並且處方該慢性病藥物之出現次數一併納入統計。');

// ===== PC_07 糖尿病 HbA1c/glycated albumin 執行率 (3691) =====
files['Indicator_PC_07_Diabetes_HbA1c_Glycated_Albumin_Rate'] =
  header('Indicator_PC_07_Diabetes_HbA1c_Glycated_Albumin_Rate',
` * 西醫基層總額醫療品質資訊 - 糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin) 執行率
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
 *   修訂指標操作型定義, 統計範圍為當年度1月累計至當期。`)
+ `codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'\n`
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n`
+ `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n\n`
+ `code "HbA1c Order 09006 Prefix": '09006' from "NHIOrder" display 'HbA1c'\n`
+ `code "Glycated Albumin Order 09139 Prefix": '09139' from "NHIOrder" display 'Glycated Albumin'\n`
+ `code "Diabetes Drug A10 Prefix": 'A10' from "ATC" display 'Drugs used in diabetes'\n\n`
+ periodCtx()
+ `// 糖尿病使用糖尿病用藥之病人 (denominator)\n`
+ `define "Denominator Cases":\n    [Patient] P\n\n`
+ `// 於統計期間有執行 HbA1c 或 glycated albumin 檢驗之糖尿病病人 (numerator)\n`
+ `define "Numerator Cases":\n    [Patient] P\n\n`
+ rateMeasure();

// ===== PC_08 同日同院再就診率 (1321) =====
files['Indicator_PC_08_Same_Day_Same_Hospital_Revisit_Rate'] =
  header('Indicator_PC_08_Same_Day_Same_Hospital_Revisit_Rate',
` * 西醫基層總額醫療品質資訊 - 就診後同日於同院所再次就診率
 * (指標代碼 1321)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: 同一費用年月、同一就醫日期、同一院所、同一人(身分證號)
 *         就診 2 次(含)以上, 按身分證號歸戶之門診人數
 *   分母: 同一費用年月、同一院所, 身分證號歸戶之門診人數`)
+ periodCtx()
+ `// 全部門診人次 (按月+院所+ID 歸戶後的人數)\n`
+ `define "Denominator Cases":\n    [Encounter] E\n        where E.period during "Measurement Period"\n\n`
+ `// 同月同院同日同人就診 >=2 次之歸戶人數\n`
+ `define "Numerator Cases":\n    [Encounter] E\n        where E.period during "Measurement Period"\n\n`
+ rateMeasure();

// ===== PC_09_x 剖腹產率 =====
function p09(lib, code, title, comment) {
return header(lib,
` * 西醫基層總額醫療品質資訊 - 剖腹產率 - ${title}
 * (指標代碼 ${code})
 *
 * 資料範圍:
 *   西醫基層總額住院生產案件, 排除代辦案件
 *
 * 公式說明:
${comment}
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
 *       不宜逕予判斷院所生產照護品質。`)
+ `codesystem "TWDRG": 'https://www.nhi.gov.tw/cs/twdrg'\n`
+ `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n\n`
+ periodCtx()
+ `// 生產案件 (denominator: 自然產 + 剖腹產)\n`
+ `define "Denominator Cases":\n    [Procedure] P\n        where P.performed during "Measurement Period"\n\n`
+ `// 剖腹產 / 自行要求剖腹產 / 具適應症剖腹產 案件 (依指標而定)\n`
+ `define "Numerator Cases":\n    [Procedure] P\n        where P.performed during "Measurement Period"\n\n`
+ rateMeasure();
}

files['Indicator_PC_09_1_Cesarean_Section_Rate_Overall'] = p09(
  'Indicator_PC_09_1_Cesarean_Section_Rate_Overall', '1136.01', '整體',
  ` *   分子: 剖腹產案件數\n *   分母: 生產案件數 (自然產案件 + 剖腹產案件)`);

files['Indicator_PC_09_2_Cesarean_Section_Rate_Patient_Requested'] = p09(
  'Indicator_PC_09_2_Cesarean_Section_Rate_Patient_Requested', '1137.01', '自行要求',
  ` *   分子: 不具適應症之剖腹產案件 (自行要求剖腹產), 符合下列任一條件:\n` +
  ` *         (1) TW-DRG 前3碼 = 513\n` +
  ` *         (2) DRG_CODE = 0373B\n` +
  ` *         (3) 醫令代碼 = 97014C\n` +
  ` *   分母: 生產案件數 (自然產案件 + 剖腹產案件)`);

files['Indicator_PC_09_3_Cesarean_Section_Rate_With_Indication'] = p09(
  'Indicator_PC_09_3_Cesarean_Section_Rate_With_Indication', '1138.01', '具適應症',
  ` *   分子: 具適應症之剖腹產案件 (= 全部剖腹產 - 不具適應症之剖腹產)\n` +
  ` *   分母: 生產案件數 (自然產案件 + 剖腹產案件)`);

let count = 0;
for (const [name, content] of Object.entries(files)) {
  const fp = path.join(DIR, name + '.cql');
  fs.writeFileSync(fp, content, 'utf-8');
  console.log('Wrote ' + fp + ' (' + content.length + ' chars)');
  count++;
}
console.log('Total files written: ' + count);
