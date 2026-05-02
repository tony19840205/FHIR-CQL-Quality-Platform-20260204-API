// ========== Sandbox 測試：4/27 重寫的 ELM ==========
// 測試所有重寫過的指標 ELM JSON 是否能順利執行
// 顯示真實數值（包含 0），不做任何假數據

const http = require('http');

const FHIR_SERVER = 'https://thas.mohw.gov.tw/v/r4/fhir';
const START_DATE = '2026-01-01';
const END_DATE   = '2026-03-31';
const MAX_RECORDS = 200;
const BACKEND_PORT = 3000;
const REQ_TIMEOUT_MS = 120000;

// 4/27 重寫的 ELM 清單（依 backend/elm 中的檔名，不含 .json）
const TARGETS = [
  // 舊50：03_2 ~ 03_16（同院7支 + 跨院8支）
  'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711',
  'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712',
  'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726',
  'Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727',
  'Indicator_03_6_Same_Hospital_Sedative_Overlap_1728',
  'Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375',
  'Indicator_03_8_Same_Hospital_Prostate_Overlap_3376',
  'Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713',
  'Indicator_03_10_Cross_Hospital_Lipid_Lowering_Overlap_1714',
  'Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715',
  'Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729',
  'Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730',
  'Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731',
  'Indicator_03_15_Cross_Hospital_Antithrombotic_Overlap_3377',
  'Indicator_03_16_Cross_Hospital_Prostate_Overlap_3378',
  // 舊50：骨架補完
  'Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250',
  'Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y',
  'Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y',
  'Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y',
  'Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y',
  // 西醫基層 PC 系列
  'Indicator_PC_01_Outpatient_Injection_Usage_Rate',
  'Indicator_PC_02_1_Outpatient_Antibiotic_Usage_Rate',
  'Indicator_PC_02_2_Outpatient_Quinolone_Aminoglycoside_Usage_Rate',
  'Indicator_PC_03_1_Same_Hospital_Antihypertensive_Overlap',
  'Indicator_PC_03_2_Same_Hospital_Lipid_Lowering_Overlap',
  'Indicator_PC_03_3_Same_Hospital_Antidiabetic_Overlap',
  'Indicator_PC_03_4_Same_Hospital_Antipsychotic_Overlap',
  'Indicator_PC_03_5_Same_Hospital_Antidepressant_Overlap',
  'Indicator_PC_03_6_Same_Hospital_Sedative_Overlap',
  'Indicator_PC_03_7_Same_Hospital_Antithrombotic_Overlap',
  'Indicator_PC_03_8_Same_Hospital_Prostate_Overlap',
  'Indicator_PC_03_9_Cross_Hospital_Antihypertensive_Overlap',
  'Indicator_PC_03_10_Cross_Hospital_Lipid_Lowering_Overlap',
  'Indicator_PC_03_11_Cross_Hospital_Antidiabetic_Overlap',
  'Indicator_PC_03_12_Cross_Hospital_Antipsychotic_Overlap',
  'Indicator_PC_03_13_Cross_Hospital_Antidepressant_Overlap',
  'Indicator_PC_03_14_Cross_Hospital_Sedative_Overlap',
  'Indicator_PC_03_15_Cross_Hospital_Antithrombotic_Overlap',
  'Indicator_PC_03_16_Cross_Hospital_Prostate_Overlap',
  'Indicator_PC_04_Chronic_Continuous_Prescription_Rate',
  'Indicator_PC_05_Prescription_10_Plus_Drugs_Rate',
  'Indicator_PC_06_1_Chronic_Prescription_Days_Diabetes',
  'Indicator_PC_06_2_Chronic_Prescription_Days_Hypertension',
  'Indicator_PC_06_3_Chronic_Prescription_Days_Hyperlipidemia',
  'Indicator_PC_07_Diabetes_HbA1c_Glycated_Albumin_Rate',
  'Indicator_PC_08_Same_Day_Same_Hospital_Revisit_Rate',
  'Indicator_PC_09_1_Cesarean_Section_Rate_Overall',
  'Indicator_PC_09_2_Cesarean_Section_Rate_Patient_Requested',
  'Indicator_PC_09_3_Cesarean_Section_Rate_With_Indication',
  // 牙科 20 支
  'Indicator_Complex_Tooth_Extraction_Count',
  'Indicator_Dental_Enhanced_Infection_Control_Consultation_Fee_Rate',
  'Indicator_Dental_Filling_Permanent_Tooth_Refill_Rate_Within_1Year',
  'Indicator_Dental_Filling_Permanent_Tooth_Refill_Rate_Within_2Years',
  'Indicator_Dental_Filling_Retention_Rate_Primary_Tooth_18Months',
  'Indicator_Dental_Filling_Retention_Rate_Within_2Years',
  'Indicator_Dental_Medical_Fee_Reduction_Rate',
  'Indicator_Dental_Outpatient_Patient_Count_Age_50_Plus',
  'Indicator_Disabled_Patient_Dental_Service_Organization_List',
  'Indicator_Full_Mouth_Calculus_Removal_Rate_Age_12_Plus',
  'Indicator_Oral_Cancer_Screening_Case_Count',
  'Indicator_Pediatric_Under_6_Oral_Preventive_Health_Service_Rate',
  'Indicator_Periodontal_Basic_Treatment_Patient_Count',
  'Indicator_Periodontal_Disease_Case_Rate',
  'Indicator_Periodontal_Disease_Control_Basic_Treatment_Rate',
  'Indicator_Periodontal_Integrated_Treatment_Completion_Rate',
  'Indicator_Periodontal_Integrated_Treatment_Followup_Rate',
  'Indicator_Periodontal_Integrated_Treatment_Organization_List',
  'Indicator_Root_Canal_Difficult_Case_Special_Treatment_Count',
  'Indicator_Root_Canal_Treatment_Completion_Rate',
  'Indicator_Root_Canal_Treatment_Retention_Rate_Permanent_Tooth_6Months',
  'Indicator_Root_Canal_Treatment_Retention_Rate_Primary_Tooth_3Months',
  'Indicator_Root_Canal_Treatment_Retention_Rate_Within_6Months',
  'Indicator_Simple_Tooth_Extraction_Count',
  'Indicator_Simple_Tooth_Extraction_No_Postop_Special_Treatment_Rate'
];

function postExecute(cqlFile) {
  return new Promise((resolve) => {
    const body = JSON.stringify({
      cqlFile,
      fhirServerUrl: FHIR_SERVER,
      startDate: START_DATE,
      endDate: END_DATE,
      maxRecords: MAX_RECORDS
    });
    const req = http.request({
      hostname: 'localhost', port: BACKEND_PORT, path: '/api/execute-cql',
      method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) }
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch (e) { resolve({ status: res.statusCode, body: { success:false, error:'Bad JSON: '+e.message+' raw='+data.slice(0,200) } }); }
      });
    });
    req.on('error', err => resolve({ status:0, body:{ success:false, error: err.message }}));
    req.setTimeout(REQ_TIMEOUT_MS, () => { req.destroy(new Error('timeout')); });
    req.write(body); req.end();
  });
}

// 從結果中萃取分子/分母/比率（支援 indicator 結構與一般 CQL 結果）
function extractMetrics(results) {
  if (!results || typeof results !== 'object') return { display: String(results) };
  // 後端常將 indicator 結果包成陣列 [{ ... }]
  if (Array.isArray(results)) {
    if (results.length === 0) return { array: 0 };
    if (results.length === 1 && typeof results[0] === 'object') return extractMetrics(results[0]);
    return { arrayCount: results.length, first: extractMetrics(results[0]) };
  }
  // indicator structure
  if (results._type === 'indicator' || results.numerator !== undefined || results.denominator !== undefined) {
    const n = results.numerator;
    const d = results.denominator;
    const r = results.rate ?? results.ratio;
    return { numerator: n, denominator: d, rate: r };
  }
  // try common define names
  const keys = Object.keys(results);
  const pickKey = (regex) => keys.find(k => regex.test(k));
  const nKey = pickKey(/numerator|分子|count$/i);
  const dKey = pickKey(/denominator|分母|total/i);
  const rKey = pickKey(/rate|ratio|比率|percentage/i);
  const out = {};
  if (nKey) out.numerator = results[nKey];
  if (dKey) out.denominator = results[dKey];
  if (rKey) out.rate = results[rKey];
  if (!nKey && !dKey && !rKey) {
    // show first few patient-level keys count
    out.summary = `keys=${keys.length}`;
  }
  return out;
}

(async () => {
  console.log('═'.repeat(80));
  console.log(`沙盒測試  FHIR=${FHIR_SERVER}  期間=${START_DATE}~${END_DATE}  共 ${TARGETS.length} 支`);
  console.log('═'.repeat(80));

  const summary = { ok: [], fail: [] };
  let i = 0;
  for (const cqlFile of TARGETS) {
    i++;
    const t0 = Date.now();
    process.stdout.write(`[${String(i).padStart(2,'0')}/${TARGETS.length}] ${cqlFile.padEnd(75)} ... `);
    const { status, body } = await postExecute(cqlFile);
    const elapsed = Date.now() - t0;
    if (status === 200 && body.success) {
      const m = extractMetrics(body.results);
      const metricsStr = JSON.stringify(m);
      console.log(`✅ ${elapsed}ms  ${metricsStr.slice(0,200)}`);
      summary.ok.push({ cqlFile, elapsed, metrics: m });
    } else {
      const errMsg = (body && body.error) ? body.error : `HTTP ${status}`;
      console.log(`❌ ${elapsed}ms  ${String(errMsg).slice(0,200)}`);
      summary.fail.push({ cqlFile, elapsed, error: String(errMsg).slice(0,500) });
    }
  }

  console.log('═'.repeat(80));
  console.log(`完成：✅ 成功 ${summary.ok.length} / ❌ 失敗 ${summary.fail.length} / 總計 ${TARGETS.length}`);
  console.log('═'.repeat(80));
  if (summary.fail.length > 0) {
    console.log('\n=== 失敗清單 ===');
    summary.fail.forEach(f => console.log(`  ✗ ${f.cqlFile}\n      ${f.error}`));
  }
  // 寫成 JSON 報告
  const fs = require('fs');
  const outPath = require('path').join(__dirname, 'sandbox_test_results.json');
  fs.writeFileSync(outPath, JSON.stringify({
    runAt: new Date().toISOString(),
    fhirServer: FHIR_SERVER, period: [START_DATE, END_DATE], maxRecords: MAX_RECORDS,
    total: TARGETS.length, okCount: summary.ok.length, failCount: summary.fail.length,
    ok: summary.ok, fail: summary.fail
  }, null, 2));
  console.log(`\n報告已寫入: ${outPath}`);
  process.exit(summary.fail.length > 0 ? 1 : 0);
})();
