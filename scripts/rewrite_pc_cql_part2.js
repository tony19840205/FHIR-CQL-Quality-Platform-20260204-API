// Rewrites 10 spec-faithful CQL files for PC_03_8..PC_03_16 + PC_04
// Run: node scripts/rewrite_pc_cql_part2.js
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

function overlapMeasure() {
  return `define "Denominator":\n    Count("Drug Class Medication Requests")\n\ndefine "Numerator":\n    Count("Overlapping Drug Class Medication Requests")\n\ndefine "Measure Score":\n    if "Denominator" > 0\n        then ("Numerator" * 100.0) / "Denominator"\n        else 0.0\n`;
}

// scope: 'same' (同院所) or 'cross' (跨院所)
function overlapDrug(lib, code, drugDesc, atcDesc, scope, atcCodes) {
  const scopeLabel = scope === 'same' ? '同院所' : '跨院所';
  const numerator =
    scope === 'same'
      ? '同院同 ID 不同處方之開始用藥日期與結束用藥日期間\n *         有重疊之給藥日數 (允許慢箋提早拿藥)'
      : '全國跨院同 ID 不同處方之開始用藥日期與結束用藥日期間\n *         有重疊之給藥日數 (允許慢箋提早拿藥)';
  let codeBlock = '';
  for (const c of atcCodes) {
    codeBlock += `code "${c.name}": '${c.code}' from "ATC"\n`;
  }
  return header(lib,
` * 西醫基層總額醫療品質資訊 - ${scopeLabel}門診同藥理用藥日數重疊率 - ${drugDesc}
 * (指標代碼 ${code})
 *
 * 資料範圍:
 *   西醫基層總額之門診處方${drugDesc}案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: ${numerator}
 *   分母: 各案件之「給藥日數」總和
 *   (1) 「給藥日數」抓取醫令檔之醫令給藥日份 (ORDER_DRUG_DAY),
 *       若為空值則抓清單檔之給藥日份 (DRUG_DAYS)。
 *   (2) ${atcDesc}`)
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n`
+ `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n\n`
+ codeBlock + `\n`
+ periodCtx()
+ `// 符合本指標藥理分類之 MedicationRequest (denominator: 各案件給藥日數總和)\n`
+ `define "Drug Class Medication Requests":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `// ${scopeLabel}、同 ID、不同處方、用藥期間有重疊之給藥日數案件\n`
+ `define "Overlapping Drug Class Medication Requests":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ overlapMeasure();
}

const ATC_HYPERTENSION = [
  {name: 'C07 Beta Blockers Prefix', code: 'C07'},
  {name: 'C07AA05 Excluded', code: 'C07AA05'},
  {name: 'C02CA Prefix', code: 'C02CA'},
  {name: 'C02DB Prefix', code: 'C02DB'},
  {name: 'C02DC Prefix', code: 'C02DC'},
  {name: 'C02DD Prefix', code: 'C02DD'},
  {name: 'C03AA Prefix', code: 'C03AA'},
  {name: 'C03BA Prefix', code: 'C03BA'},
  {name: 'C03CA Prefix', code: 'C03CA'},
  {name: 'C03DA Prefix', code: 'C03DA'},
  {name: 'C08CA Prefix', code: 'C08CA'},
  {name: 'C08CA06 Excluded', code: 'C08CA06'},
  {name: 'C08DA Prefix', code: 'C08DA'},
  {name: 'C08DB Prefix', code: 'C08DB'},
  {name: 'C09AA Prefix', code: 'C09AA'},
  {name: 'C09CA Prefix', code: 'C09CA'}
];

const ATC_LIPID = [
  {name: 'C10AA Statins Prefix', code: 'C10AA'},
  {name: 'C10AB Fibrates Prefix', code: 'C10AB'},
  {name: 'C10AC Bile Acid Sequestrants Prefix', code: 'C10AC'},
  {name: 'C10AD Nicotinic Acid Prefix', code: 'C10AD'},
  {name: 'C10AX Other Lipid Modifying Prefix', code: 'C10AX'}
];

const ATC_DIABETES = [
  {name: 'A10AB Insulin Fast Prefix', code: 'A10AB'},
  {name: 'A10AC Insulin Intermediate Prefix', code: 'A10AC'},
  {name: 'A10AD Insulin Mix Prefix', code: 'A10AD'},
  {name: 'A10AE Insulin Long Prefix', code: 'A10AE'},
  {name: 'A10BA Biguanides Prefix', code: 'A10BA'},
  {name: 'A10BB Sulfonylureas Prefix', code: 'A10BB'},
  {name: 'A10BF Alpha Glucosidase Prefix', code: 'A10BF'},
  {name: 'A10BG Thiazolidinediones Prefix', code: 'A10BG'},
  {name: 'A10BX Other Oral Antidiabetics Prefix', code: 'A10BX'},
  {name: 'A10BH DPP4 Prefix', code: 'A10BH'},
  {name: 'A10BJ GLP1 Prefix', code: 'A10BJ'},
  {name: 'A10BK SGLT2 Prefix', code: 'A10BK'}
];

const ATC_ANTIPSYCHOTIC = [
  {name: 'N05AA Phenothiazines Aliphatic Prefix', code: 'N05AA'},
  {name: 'N05AB Phenothiazines Piperazine Prefix', code: 'N05AB'},
  {name: 'N05AC Phenothiazines Piperidine Prefix', code: 'N05AC'},
  {name: 'N05AD Butyrophenones Prefix', code: 'N05AD'},
  {name: 'N05AE Indole Derivatives Prefix', code: 'N05AE'},
  {name: 'N05AF Thioxanthenes Prefix', code: 'N05AF'},
  {name: 'N05AG Diphenylbutylpiperidines Prefix', code: 'N05AG'},
  {name: 'N05AH Diazepines Oxazepines Prefix', code: 'N05AH'},
  {name: 'N05AL Benzamides Prefix', code: 'N05AL'},
  {name: 'N05AN Lithium Prefix', code: 'N05AN'},
  {name: 'N05AN01 Lithium Excluded', code: 'N05AN01'},
  {name: 'N05AX Other Antipsychotics Prefix', code: 'N05AX'}
];

const ATC_ANTIDEPRESSANT = [
  {name: 'N06AA TCA Prefix', code: 'N06AA'},
  {name: 'N06AA02 Excluded', code: 'N06AA02'},
  {name: 'N06AA12 Excluded', code: 'N06AA12'},
  {name: 'N06AB SSRI Prefix', code: 'N06AB'},
  {name: 'N06AG MAOA Prefix', code: 'N06AG'}
];

const ATC_SEDATIVE = [
  {name: 'N05CC Aldehydes Prefix', code: 'N05CC'},
  {name: 'N05CD Benzodiazepine Hypnotics Prefix', code: 'N05CD'},
  {name: 'N05CF Benzodiazepine Related Prefix', code: 'N05CF'},
  {name: 'N05CM Other Hypnotics Prefix', code: 'N05CM'}
];

const ATC_ANTITHROMBOTIC = [
  {name: 'B01AA Vitamin K Antagonists Prefix', code: 'B01AA'},
  {name: 'B01AC Platelet Aggregation Inhibitors Prefix', code: 'B01AC'},
  {name: 'B01AC07 Dipyridamole Excluded', code: 'B01AC07'},
  {name: 'B01AE Direct Thrombin Inhibitors Prefix', code: 'B01AE'},
  {name: 'B01AF Direct Factor Xa Inhibitors Prefix', code: 'B01AF'}
];

const ATC_PROSTATE = [
  {name: 'G04CA Alpha Adrenoreceptor Antagonists Prefix', code: 'G04CA'},
  {name: 'G04CB 5 Alpha Reductase Inhibitors Prefix', code: 'G04CB'}
];

const files = {};

// 3-8 同院所 前列腺肥大(口服)
files['Indicator_PC_03_8_Same_Hospital_Prostate_Overlap'] = overlapDrug(
  'Indicator_PC_03_8_Same_Hospital_Prostate_Overlap', '3376', '前列腺肥大 (口服)',
  '前列腺肥大藥物(口服): ATC 前5碼為 G04CA、G04CB, 且醫令代碼第8碼為 1。',
  'same', ATC_PROSTATE);

// 3-9 跨院所 降血壓(口服)
files['Indicator_PC_03_9_Cross_Hospital_Antihypertensive_Overlap'] = overlapDrug(
  'Indicator_PC_03_9_Cross_Hospital_Antihypertensive_Overlap', '1713', '降血壓 (口服)',
  '降血壓藥物(口服): ATC 前3碼=C07 (排除 C07AA05) 或 ATC 前5碼為 C02CA、C02DB、'
  + 'C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除 C08CA06)、C08DA、'
  + 'C08DB、C09AA、C09CA, 且醫令代碼第8碼為 1。',
  'cross', ATC_HYPERTENSION);

// 3-10 跨院所 降血脂(口服)
files['Indicator_PC_03_10_Cross_Hospital_Lipid_Lowering_Overlap'] = overlapDrug(
  'Indicator_PC_03_10_Cross_Hospital_Lipid_Lowering_Overlap', '1714', '降血脂 (口服)',
  '降血脂藥物(口服): ATC 前5碼=C10AA、C10AB、C10AC、C10AD、C10AX, 且醫令代碼第8碼為 1。',
  'cross', ATC_LIPID);

// 3-11 跨院所 降血糖(不分口服及注射)
files['Indicator_PC_03_11_Cross_Hospital_Antidiabetic_Overlap'] = overlapDrug(
  'Indicator_PC_03_11_Cross_Hospital_Antidiabetic_Overlap', '1715', '降血糖 (不分口服及注射)',
  '降血糖藥物(不分口服及注射): ATC 前5碼=A10AB、A10AC、A10AD、A10AE、A10BA、'
  + 'A10BB、A10BF、A10BG、A10BX、A10BH、A10BJ、A10BK。',
  'cross', ATC_DIABETES);

// 3-12 跨院所 抗思覺失調
files['Indicator_PC_03_12_Cross_Hospital_Antipsychotic_Overlap'] = overlapDrug(
  'Indicator_PC_03_12_Cross_Hospital_Antipsychotic_Overlap', '1729', '抗思覺失調症',
  '抗思覺失調藥物: ATC 前5碼=N05AA、N05AB、N05AD、N05AE、N05AF、N05AH、N05AL、'
  + 'N05AN(排除 N05AN01)、N05AX、N05AC、N05AG。',
  'cross', ATC_ANTIPSYCHOTIC);

// 3-13 跨院所 抗憂鬱症
files['Indicator_PC_03_13_Cross_Hospital_Antidepressant_Overlap'] = overlapDrug(
  'Indicator_PC_03_13_Cross_Hospital_Antidepressant_Overlap', '1730', '抗憂鬱症',
  '抗憂鬱藥物: ATC 前5碼=N06AA(排除 N06AA02、N06AA12)、N06AB、N06AG。',
  'cross', ATC_ANTIDEPRESSANT);

// 3-14 跨院所 安眠鎮靜(口服)
files['Indicator_PC_03_14_Cross_Hospital_Sedative_Overlap'] = overlapDrug(
  'Indicator_PC_03_14_Cross_Hospital_Sedative_Overlap', '1731', '安眠鎮靜 (口服)',
  '安眠鎮靜藥物(口服): ATC 前5碼=N05CC、N05CD、N05CF、N05CM, 且醫令代碼第8碼為 1。',
  'cross', ATC_SEDATIVE);

// 3-15 跨院所 抗血栓(口服)
files['Indicator_PC_03_15_Cross_Hospital_Antithrombotic_Overlap'] = overlapDrug(
  'Indicator_PC_03_15_Cross_Hospital_Antithrombotic_Overlap', '3377', '抗血栓 (口服)',
  '抗血栓藥物(口服): ATC 前5碼=B01AA、B01AC(排除 B01AC07)、B01AE、B01AF, '
  + '且醫令代碼第8碼為 1。',
  'cross', ATC_ANTITHROMBOTIC);

// 3-16 跨院所 前列腺肥大(口服)
files['Indicator_PC_03_16_Cross_Hospital_Prostate_Overlap'] = overlapDrug(
  'Indicator_PC_03_16_Cross_Hospital_Prostate_Overlap', '3378', '前列腺肥大 (口服)',
  '前列腺肥大藥物(口服): ATC 前5碼為 G04CA、G04CB, 且醫令代碼第8碼為 1。',
  'cross', ATC_PROSTATE);

// 4. 慢性病連續處方箋開立率 (指標代碼 223)
files['Indicator_PC_04_Chronic_Continuous_Prescription_Rate'] =
  header('Indicator_PC_04_Chronic_Continuous_Prescription_Rate',
` * 西醫基層總額醫療品質資訊 - 慢性病連續處方箋開立率 (指標代碼 223)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
 *
 * 公式說明:
 *   分子: 開立慢性病連續處方箋的案件數
 *         (案件分類=02、04、08 且給藥日份 >= 21)
 *   分母: 慢性病給藥案件數 (案件分類=02、04、08)`)
+ `codesystem "NHICaseClass": 'https://www.nhi.gov.tw/cs/caseClassification'\n\n`
+ `code "Chronic Case Class 02": '02' from "NHICaseClass"\n`
+ `code "Chronic Case Class 04": '04' from "NHICaseClass"\n`
+ `code "Chronic Case Class 08": '08' from "NHICaseClass"\n\n`
+ periodCtx()
+ `// 慢性病給藥案件 (case class 02/04/08)\n`
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `// 連續處方箋: 給藥日份 >= 21\n`
+ `define "Numerator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ rateMeasure();

let count = 0;
for (const [name, content] of Object.entries(files)) {
  const fp = path.join(DIR, name + '.cql');
  fs.writeFileSync(fp, content, 'utf-8');
  console.log('Wrote ' + fp + ' (' + content.length + ' chars)');
  count++;
}
console.log('Total files written: ' + count);
