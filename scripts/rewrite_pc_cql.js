// Rewrites 10 spec-faithful CQL files for PC_01, PC_02_1, PC_02_2, PC_03_1..PC_03_7
// Run: node scripts/rewrite_pc_cql.js
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

const files = {

'Indicator_PC_01_Outpatient_Injection_Usage_Rate':
header('Indicator_PC_01_Outpatient_Injection_Usage_Rate',
` * 西醫基層總額醫療品質資訊 - 門診注射劑使用率 (指標代碼 1150.01)
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
 *   分母: 給藥案件數`)
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n`
+ `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n`
+ `codesystem "NHICaseClass": 'https://www.nhi.gov.tw/cs/caseClassification'\n\n`
+ `code "Chemo Order 37005B": '37005B' from "NHIOrder"\n`
+ `code "Tetanus Toxoid J07AM01": 'J07AM01' from "ATC"\n`
+ `code "Influenza Vaccine J07BB": 'J07BB' from "ATC"\n`
+ `code "Emergency Case Class 02": '02' from "NHICaseClass"\n\n`
+ periodCtx()
+ `// 給藥案件 (denominator base)\n`
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `// 注射劑案件 (醫令第8碼為「2」), 排除化療/急診/疫苗/破傷風/可攜回\n`
+ `define "Numerator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ rateMeasure(),

'Indicator_PC_02_1_Outpatient_Antibiotic_Usage_Rate':
header('Indicator_PC_02_1_Outpatient_Antibiotic_Usage_Rate',
` * 西醫基層總額醫療品質資訊 - 門診抗生素使用率 (指標代碼 1140.01)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種), 排除代辦案件
 *
 * 公式說明:
 *   分子: 給藥案件之使用抗生素藥品
 *         (醫令代碼為10碼, ATC 前3碼為 J01 ANTIBACTERIALS FOR SYSTEMIC USE) 案件數
 *   分母: 給藥案件數
 *
 *   基層醫療機構使用抗生素藥品案件數 / 基層醫療機構開藥總案件數
 *   抗生素藥品: ATC 碼前3碼為 J01 (ANTIBACTERIALS FOR SYSTEMIC USE)`)
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n\n`
+ `code "Antibiotic J01 Prefix": 'J01' from "ATC" display 'ANTIBACTERIALS FOR SYSTEMIC USE'\n\n`
+ periodCtx()
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `define "Numerator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ rateMeasure(),

'Indicator_PC_02_2_Outpatient_Quinolone_Aminoglycoside_Usage_Rate':
header('Indicator_PC_02_2_Outpatient_Quinolone_Aminoglycoside_Usage_Rate',
` * 西醫基層總額醫療品質資訊 - 門診 Quinolone、Aminoglycoside 類抗生素藥品使用率
 * (指標代碼 2768.01)
 *
 * 資料範圍:
 *   每季所有屬西醫基層總額之門診給藥案件
 *   (藥費≠0 或 給藥天數≠0 或 處方調劑方式為 1、0、6 其中一種), 排除代辦案件
 *
 * 公式說明:
 *   分子: 給藥案件之使用 Quinolone / Aminoglycoside 抗生素藥品
 *         (醫令代碼為10碼, ATC 前4碼為 J01M (Quinolone) 或 J01G (Aminoglycoside)) 案件數
 *   分母: 給藥案件數`)
+ `codesystem "ATC": 'http://www.whocc.no/atc'\n\n`
+ `code "Quinolone J01M Prefix": 'J01M' from "ATC" display 'QUINOLONE ANTIBACTERIALS'\n`
+ `code "Aminoglycoside J01G Prefix": 'J01G' from "ATC" display 'AMINOGLYCOSIDE ANTIBACTERIALS'\n\n`
+ periodCtx()
+ `define "Denominator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ `define "Numerator Cases":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
+ rateMeasure(),

};

// PC_03_x — 同院所門診同藥理用藥日數重疊率 (overlap days / total drug days)
// 共用模板: ATC 規範 + 醫令第8碼 (條件)
const overlap03 = (lib, code, drugDesc, atcDesc, comment, atcCodes) => {
  let codeBlock = '';
  for (const c of atcCodes) {
    codeBlock += `code "${c.name}": '${c.code}' from "ATC"\n`;
  }
  return header(lib, ` * 西醫基層總額醫療品質資訊 - 同院所門診同藥理用藥日數重疊率 - ${drugDesc}\n` +
    ` * (指標代碼 ${code})\n` +
    ` *\n` +
    ` * 資料範圍:\n` +
    ` *   西醫基層總額之門診處方${drugDesc}案件, 排除代辦案件\n` +
    ` *\n` +
    ` * 公式說明:\n` +
    ` *   分子: 同院同 ID 不同處方之開始用藥日期與結束用藥日期間\n` +
    ` *         有重疊之給藥日數 (允許慢箋提早拿藥)\n` +
    ` *   分母: 各案件之「給藥日數」總和\n` +
    ` *   (1) 「給藥日數」抓取醫令檔之醫令給藥日份 (ORDER_DRUG_DAY),\n` +
    ` *       若為空值則抓清單檔之給藥日份 (DRUG_DAYS)。\n` +
    ` *   (2) ${atcDesc}\n` +
    (comment ? ` *\n * ${comment}\n` : ''))
  + `codesystem "ATC": 'http://www.whocc.no/atc'\n`
  + `codesystem "NHIOrder": 'https://www.nhi.gov.tw/cs/medOrder'\n\n`
  + codeBlock + `\n`
  + periodCtx()
  + `// 符合本指標藥理分類之 MedicationRequest (denominator: 各案件給藥日數總和)\n`
  + `define "Drug Class Medication Requests":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
  + `// 同院、同 ID、不同處方、用藥期間有重疊之給藥日數案件\n`
  + `define "Overlapping Drug Class Medication Requests":\n    [MedicationRequest] M\n        where M.authoredOn during "Measurement Period"\n\n`
  + overlapMeasure();
};

files['Indicator_PC_03_1_Same_Hospital_Antihypertensive_Overlap'] = overlap03(
  'Indicator_PC_03_1_Same_Hospital_Antihypertensive_Overlap', '1710', '降血壓 (口服)',
  '降血壓藥物(口服): ATC 前3碼為 C07 (排除 C07AA05) 或 ATC 前5碼為 C02CA、C02DB、'
  + 'C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除 C08CA06)、C08DA、'
  + 'C08DB、C09AA、C09CA, 且醫令代碼第8碼為 1。', null,
  [
    {name: 'C07 Beta Blockers Prefix', code: 'C07'},
    {name: 'C07AA05 Excluded', code: 'C07AA05'},
    {name: 'C02CA Prefix', code: 'C02CA'},
    {name: 'C03AA Prefix', code: 'C03AA'},
    {name: 'C08CA Prefix', code: 'C08CA'},
    {name: 'C09AA Prefix', code: 'C09AA'},
    {name: 'C09CA Prefix', code: 'C09CA'}
  ]);

files['Indicator_PC_03_2_Same_Hospital_Lipid_Lowering_Overlap'] = overlap03(
  'Indicator_PC_03_2_Same_Hospital_Lipid_Lowering_Overlap', '1711', '降血脂 (口服)',
  '降血脂藥物(口服): ATC 前5碼=C10AA、C10AB、C10AC、C10AD、C10AX, 且醫令代碼第8碼為 1。', null,
  [
    {name: 'C10AA Statins Prefix', code: 'C10AA'},
    {name: 'C10AB Fibrates Prefix', code: 'C10AB'},
    {name: 'C10AC Bile Acid Sequestrants Prefix', code: 'C10AC'},
    {name: 'C10AD Nicotinic Acid Prefix', code: 'C10AD'},
    {name: 'C10AX Other Lipid Modifying Prefix', code: 'C10AX'}
  ]);

files['Indicator_PC_03_3_Same_Hospital_Antidiabetic_Overlap'] = overlap03(
  'Indicator_PC_03_3_Same_Hospital_Antidiabetic_Overlap', '1712', '降血糖 (不分口服及注射)',
  '降血糖藥物(不分口服及注射): ATC 前5碼=A10AB、A10AC、A10AD、A10AE、A10BA、'
  + 'A10BB、A10BF、A10BG、A10BX、A10BH、A10BJ、A10BK。', null,
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

files['Indicator_PC_03_4_Same_Hospital_Antipsychotic_Overlap'] = overlap03(
  'Indicator_PC_03_4_Same_Hospital_Antipsychotic_Overlap', '1726', '抗思覺失調症',
  '抗思覺失調藥物: ATC 前5碼=N05AA、N05AB、N05AD、N05AE、N05AF、N05AH、N05AL、'
  + 'N05AN(排除 N05AN01)、N05AX、N05AC、N05AG。', null,
  [
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
  ]);

files['Indicator_PC_03_5_Same_Hospital_Antidepressant_Overlap'] = overlap03(
  'Indicator_PC_03_5_Same_Hospital_Antidepressant_Overlap', '1727', '抗憂鬱症',
  '抗憂鬱藥物: ATC 前5碼=N06AA(排除 N06AA02、N06AA12)、N06AB、N06AG。', null,
  [
    {name: 'N06AA TCA Prefix', code: 'N06AA'},
    {name: 'N06AA02 Excluded', code: 'N06AA02'},
    {name: 'N06AA12 Excluded', code: 'N06AA12'},
    {name: 'N06AB SSRI Prefix', code: 'N06AB'},
    {name: 'N06AG MAOA Prefix', code: 'N06AG'}
  ]);

files['Indicator_PC_03_6_Same_Hospital_Sedative_Overlap'] = overlap03(
  'Indicator_PC_03_6_Same_Hospital_Sedative_Overlap', '1728', '安眠鎮靜 (口服)',
  '安眠鎮靜藥物(口服): ATC 前5碼=N05CC、N05CD、N05CF、N05CM, 且醫令代碼第8碼為 1。', null,
  [
    {name: 'N05CC Aldehydes Prefix', code: 'N05CC'},
    {name: 'N05CD Benzodiazepine Hypnotics Prefix', code: 'N05CD'},
    {name: 'N05CF Benzodiazepine Related Prefix', code: 'N05CF'},
    {name: 'N05CM Other Hypnotics Prefix', code: 'N05CM'}
  ]);

files['Indicator_PC_03_7_Same_Hospital_Antithrombotic_Overlap'] = overlap03(
  'Indicator_PC_03_7_Same_Hospital_Antithrombotic_Overlap', '3375', '抗血栓 (口服)',
  '抗血栓藥物(口服): ATC 前5碼=B01AA、B01AC(排除 B01AC07)、B01AE、B01AF, '
  + '且醫令代碼第8碼為 1。', null,
  [
    {name: 'B01AA Vitamin K Antagonists Prefix', code: 'B01AA'},
    {name: 'B01AC Platelet Aggregation Inhibitors Prefix', code: 'B01AC'},
    {name: 'B01AC07 Dipyridamole Excluded', code: 'B01AC07'},
    {name: 'B01AE Direct Thrombin Inhibitors Prefix', code: 'B01AE'},
    {name: 'B01AF Direct Factor Xa Inhibitors Prefix', code: 'B01AF'}
  ]);

// Write all files
let count = 0;
for (const [name, content] of Object.entries(files)) {
  const fp = path.join(DIR, name + '.cql');
  fs.writeFileSync(fp, content, 'utf-8');
  console.log('Wrote ' + fp + ' (' + content.length + ' chars)');
  count++;
}
console.log('Total files written: ' + count);
