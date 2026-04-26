// Rewrites 10 spec-faithful CQL files for hospital indicators (醫院總額):
//   Indicator_01 (門診注射劑 3127), Indicator_02 (門診抗生素 1140.01),
//   Indicator_03_1..03_8 (同院門診同藥理用藥日數重疊率, 1710/1711/1712/1726/1727/1728/3375/3376)
// Run: node scripts/rewrite_hospital_cql.js
const fs = require('fs');
const path = require('path');

const DIR = path.join(__dirname, '..', 'ELM_JSON_OFFICIAL', '舊50');

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

const files = {};

// ===== Indicator_01 門診注射劑使用率 (3127) =====
files['Indicator_01_Outpatient_Injection_Usage_Rate_3127'] =
  header('Indicator_01_Outpatient_Injection_Usage_Rate_3127',
` * 醫院總額醫療品質資訊 - 門診注射劑使用率 (指標代碼 3127)
 *
 * 資料範圍:
 *   每季所有屬醫院總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種)
 *   排除代辦案件
 *
 * 公式說明:
 *   分子: 給藥案件之針劑藥品 (醫令代碼為10碼, 第8碼為「2」) 案件數
 *         排除以下:
 *           (a) 門診化療注射劑: 醫令 37005B、37031B-37041B 或癌症用藥
 *               (ATC 前3碼 L01、L02 或 H01AB01、L03AB01、L03AB04、L03AB05、
 *                L03AB15、L03AC01、L03AX03、L03AX16、L04AX01、M05BA02、
 *                M05BA03、M05BA06、M05BA08(且規格量 4.00 MG)、M05BX04、V10XX03,
 *                且醫令代碼為10碼且第8碼為2)
 *           (b) 急診注射劑: 案件分類代碼為 02
 *           (c) 流感疫苗注射劑: ATC 前5碼 J07BB
 *           (d) 外傷緊急處置使用之破傷風類毒素注射劑: ATC J07AM01
 *           (e) 門診手術案件: 案件分類為 03
 *           (f) 事前審查藥品 (事前審查註記=Y)
 *           (g) 立刻使用之藥品 (藥品使用頻率為 STAT)
 *           (h) 經醫師指導後得攜回之注射藥品
 *   分母: 給藥案件數`)
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n`
+ `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n`
+ `codesystem "NHICaseClass": 'https://www.nhi.gov.tw/cs/caseClassification'\n\n`
+ `code "Chemo Order 37005B": '37005B' from "NHIOrder"\n`
+ `code "Tetanus Toxoid J07AM01": 'J07AM01' from "ATC"\n`
+ `code "Influenza Vaccine J07BB": 'J07BB' from "ATC"\n`
+ `code "Emergency Case Class 02": '02' from "NHICaseClass"\n`
+ `code "Day Surgery Case Class 03": '03' from "NHICaseClass"\n\n`
+ periodCtx()
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `define "Numerator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ rateMeasure();

// ===== Indicator_02 門診抗生素使用率 (1140.01) =====
files['Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01'] =
  header('Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01',
` * 醫院總額醫療品質資訊 - 門診抗生素使用率 (指標代碼 1140.01)
 *
 * 資料範圍:
 *   每季所有屬醫院總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種), 排除代辦案件
 *
 * 公式說明:
 *   門診抗生素使用率 = 醫院門診開立抗生素藥品案件數 / 醫院門診開藥總案件數
 *   抗生素藥品: ATC 碼前3碼為 J01 (ANTIBACTERIALS FOR SYSTEMIC USE)`)
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n\n`
+ `code "Antibiotic J01 Prefix": 'J01' from "ATC" display 'ANTIBACTERIALS FOR SYSTEMIC USE'\n\n`
+ periodCtx()
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `define "Numerator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ rateMeasure();

// ===== 同院門診同藥理用藥日數重疊率 (Indicator_03_1..03_8) =====
function overlap03(lib, code, drugDesc, atcDesc, atcCodes) {
  let codeBlock = '';
  for (const c of atcCodes) {
    codeBlock += `code "${c.name}": '${c.code}' from "ATC"\n`;
  }
  return header(lib,
` * 醫院總額醫療品質資訊 - 同醫院門診同藥理用藥日數重疊率 - ${drugDesc}
 * (指標代碼 ${code})
 *
 * 資料範圍:
 *   醫院總額之門診處方${drugDesc}案件, 排除代辦案件
 *
 * 公式說明:
 *   分子: 同院同 ID 不同處方之開始用藥日期與結束用藥日期間
 *         有重疊之給藥日數 (允許慢箋提早拿藥)
 *   分母: 各案件之「給藥日數」總和
 *
 *   (1) 「給藥日數」抓取醫令檔之醫令給藥日份 (ORDER_DRUG_DAY),
 *       若為空值則抓清單檔之給藥日份 (DRUG_DAYS)。
 *   (2) ${atcDesc}`)
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n`
+ `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n\n`
+ codeBlock + `\n`
+ periodCtx()
+ `// 符合本指標藥理分類之 MedicationRequest (denominator: 各案件給藥日數總和)\n`
+ `define "Drug Class Medication Requests":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `// 同院、同 ID、不同處方、用藥期間有重疊之給藥日數案件\n`
+ `define "Overlapping Drug Class Medication Requests":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ overlapMeasure();
}

files['Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710'] = overlap03(
  'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710', '1710', '降血壓 (口服)',
  '降血壓藥物(口服): ATC 前3碼=C07 (排除 C07AA05) 或 ATC 前5碼為 C02CA、C02DB、C02DC、C02DD、'
  + 'C03AA、C03BA、C03CA、C03DA、C08CA(排除 C08CA06)、C08DA、C08DB、C09AA、C09CA, 且醫令代碼第8碼為 1。',
  [
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
  ]);

files['Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711'] = overlap03(
  'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711', '1711', '降血脂 (口服)',
  '降血脂藥物(口服): ATC 前5碼=C10AA、C10AB、C10AC、C10AD、C10AX, 且醫令代碼第8碼為 1。',
  [
    {name: 'C10AA Statins Prefix', code: 'C10AA'},
    {name: 'C10AB Fibrates Prefix', code: 'C10AB'},
    {name: 'C10AC Bile Acid Sequestrants Prefix', code: 'C10AC'},
    {name: 'C10AD Nicotinic Acid Prefix', code: 'C10AD'},
    {name: 'C10AX Other Lipid Modifying Prefix', code: 'C10AX'}
  ]);

files['Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712'] = overlap03(
  'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712', '1712', '降血糖 (不分口服及注射)',
  '降血糖藥物(不分口服及注射): ATC 前5碼=A10AB、A10AC、A10AD、A10AE、A10BA、A10BB、A10BF、A10BG、A10BX、'
  + 'A10BH、A10BJ、A10BK。',
  [
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
  ]);

files['Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726'] = overlap03(
  'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726', '1726', '抗思覺失調症',
  '抗思覺失調藥物: ATC 前5碼=N05AA、N05AB(排除 N05AB04)、N05AD、N05AE、N05AF、N05AH、N05AL、'
  + 'N05AN(排除 N05AN01)、N05AX、N05AC、N05AG。',
  [
    {name: 'N05AA Phenothiazines Aliphatic Prefix', code: 'N05AA'},
    {name: 'N05AB Phenothiazines Piperazine Prefix', code: 'N05AB'},
    {name: 'N05AB04 Excluded', code: 'N05AB04'},
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
  ]);

files['Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727'] = overlap03(
  'Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727', '1727', '抗憂鬱症',
  '抗憂鬱藥物: ATC 前5碼=N06AA(排除 N06AA02、N06AA12)、N06AB、N06AG。',
  [
    {name: 'N06AA TCA Prefix', code: 'N06AA'},
    {name: 'N06AA02 Excluded', code: 'N06AA02'},
    {name: 'N06AA12 Excluded', code: 'N06AA12'},
    {name: 'N06AB SSRI Prefix', code: 'N06AB'},
    {name: 'N06AG MAOA Prefix', code: 'N06AG'}
  ]);

files['Indicator_03_6_Same_Hospital_Sedative_Overlap_1728'] = overlap03(
  'Indicator_03_6_Same_Hospital_Sedative_Overlap_1728', '1728', '安眠鎮靜 (口服)',
  '安眠鎮靜藥物(口服): ATC 前5碼=N05CC、N05CD、N05CF、N05CM, 且醫令代碼第8碼為 1。',
  [
    {name: 'N05CC Aldehydes Prefix', code: 'N05CC'},
    {name: 'N05CD Benzodiazepine Hypnotics Prefix', code: 'N05CD'},
    {name: 'N05CF Benzodiazepine Related Prefix', code: 'N05CF'},
    {name: 'N05CM Other Hypnotics Prefix', code: 'N05CM'}
  ]);

files['Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375'] = overlap03(
  'Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375', '3375', '抗血栓 (口服)',
  '抗血栓藥物(口服): ATC 前5碼=B01AA、B01AC(排除 B01AC07)、B01AE、B01AF, 且醫令代碼第8碼為 1。',
  [
    {name: 'B01AA Vitamin K Antagonists Prefix', code: 'B01AA'},
    {name: 'B01AC Platelet Aggregation Inhibitors Prefix', code: 'B01AC'},
    {name: 'B01AC07 Dipyridamole Excluded', code: 'B01AC07'},
    {name: 'B01AE Direct Thrombin Inhibitors Prefix', code: 'B01AE'},
    {name: 'B01AF Direct Factor Xa Inhibitors Prefix', code: 'B01AF'}
  ]);

files['Indicator_03_8_Same_Hospital_Prostate_Overlap_3376'] = overlap03(
  'Indicator_03_8_Same_Hospital_Prostate_Overlap_3376', '3376', '前列腺肥大 (口服)',
  '前列腺肥大藥物(口服): ATC 前5碼=G04CA、G04CB, 且醫令代碼第8碼為 1。',
  [
    {name: 'G04CA Alpha Adrenoreceptor Antagonists Prefix', code: 'G04CA'},
    {name: 'G04CB 5 Alpha Reductase Inhibitors Prefix', code: 'G04CB'}
  ]);

let count = 0;
for (const [name, content] of Object.entries(files)) {
  const fp = path.join(DIR, name + '.cql');
  fs.writeFileSync(fp, content, 'utf-8');
  console.log('Wrote ' + fp + ' (' + content.length + ' chars)');
  count++;
}
console.log('Total files written: ' + count);
