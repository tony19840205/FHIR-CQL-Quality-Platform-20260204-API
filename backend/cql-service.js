// ========== CQL Engine 執行服務 ==========
// 用途：載入 ELM JSON → 使用 cql-execution 引擎計算品質指標
// 來源：整合自 CQL 測試 - 0310/fhir-cql-platform

const fs = require('fs').promises;
const path = require('path');
const cql = require('cql-execution');
const cqlfhir = require('cql-exec-fhir');
const axios = require('axios');

// ELM JSON 目錄
const ELM_DIR = path.join(__dirname, 'elm');

// ==================== 載入 ELM JSON ====================
async function loadELM(cqlFile) {
    const elmFileName = cqlFile.endsWith('.json') ? cqlFile : `${cqlFile}.json`;
    const elmPath = path.join(ELM_DIR, elmFileName);

    try {
        const content = await fs.readFile(elmPath, 'utf-8');
        const elmJson = JSON.parse(content);
        console.log(`✅ 載入 ELM: ${elmFileName} (${content.length} chars)`);
        return elmJson;
    } catch (error) {
        throw new Error(`ELM JSON 未找到: ${elmFileName}。請確認檔案存在於 backend/elm/ 目錄。`);
    }
}

// ==================== 列出可用的 ELM 檔案 ====================
async function listAvailableELM() {
    try {
        const files = await fs.readdir(ELM_DIR);
        return files
            .filter(f => f.endsWith('.json') && f !== 'FHIRHelpers.json' && f !== 'CDSConnectCommonsForFHIRv401.json')
            .map(f => f.replace('.json', ''));
    } catch {
        return [];
    }
}

// ==================== 判斷是否為品質指標 CQL ====================
function isIndicatorCQL(cqlFile) {
    return cqlFile && cqlFile.includes('Indicator_');
}

// ==================== 從 ELM 自動建構 CodeService ====================
function buildCodeServiceFromELM(elm) {
    const vsDefs = elm.library?.valueSets?.def || [];
    if (vsDefs.length === 0) return null;

    const codeDefs = elm.library?.codes?.def || [];
    const csDefs = elm.library?.codeSystems?.def || [];
    const stmtDefs = elm.library?.statements?.def || [];

    // codeSystem name -> URL
    const csMap = {};
    csDefs.forEach(cs => { csMap[cs.name] = cs.id; });

    // code name -> { code, system }
    const codeMap = {};
    codeDefs.forEach(cd => {
        codeMap[cd.name] = { code: cd.id, system: csMap[cd.codeSystem?.name] || '' };
    });

    // For each valueset, find the corresponding "Code List" statement that has CodeRef elements
    // and extract which codes belong to which valueset
    const vsNameToUrl = {};
    vsDefs.forEach(vs => { vsNameToUrl[vs.name] = vs.id; });

    // Build: valueset URL -> codes array
    const valueSetsJson = {};

    // Strategy: match valueset names to code list statements by keyword pattern
    // e.g. "Acute Conjunctivitis ICD9 Codes" (valueset) -> "ICD9 Code List" (statement with CodeRefs)
    // Also look at Retrieve expressions that reference ValueSetRef and trace the Union operands
    for (const vs of vsDefs) {
        const vsUrl = vs.id;
        const codesForVs = [];

        // Extract keyword from valueset name: e.g. "ICD9", "ICD10", "SNOMED", "Lab"
        const vsNameLower = vs.name.toLowerCase();

        // Find all codes whose codeSystem matches this valueset's category
        for (const cd of codeDefs) {
            const csName = cd.codeSystem?.name || '';
            const codeName = cd.name.toLowerCase();

            if (vsNameLower.includes('icd9') && csName === 'ICD-9-CM') {
                codesForVs.push({ code: cd.id, system: csMap[csName] });
            } else if (vsNameLower.includes('icd10') && csName === 'ICD-10-CM') {
                codesForVs.push({ code: cd.id, system: csMap[csName] });
            } else if (vsNameLower.includes('snomed') && csName === 'SNOMEDCT') {
                codesForVs.push({ code: cd.id, system: csMap[csName] });
            } else if (vsNameLower.includes('lab') && csName === 'LOINC') {
                codesForVs.push({ code: cd.id, system: csMap[csName] });
            }
        }

        if (codesForVs.length > 0) {
            valueSetsJson[vsUrl] = { '': codesForVs };
            console.log(`   📋 ValueSet ${vs.name}: ${codesForVs.length} codes`);
        }
    }

    return Object.keys(valueSetsJson).length > 0 ? new cql.CodeService(valueSetsJson) : null;
}

// ==================== 執行 CQL (使用 CQL Execution Engine) ====================
async function executeCQL(elm, fhirServerUrl, cqlFile, options = {}) {
    const { startDate, endDate, maxRecords = 200 } = options;
    console.log(`🚀 CQL Engine 執行: ${cqlFile}`);
    console.log(`   FHIR Server: ${fhirServerUrl}`);

    const isIndicator = isIndicatorCQL(cqlFile);

    // 步驟 1: 載入 FHIRHelpers 依賴
    const fhirHelpersPath = path.join(ELM_DIR, 'FHIRHelpers.json');
    const fhirHelpersContent = await fs.readFile(fhirHelpersPath, 'utf-8');
    const fhirHelpersElm = JSON.parse(fhirHelpersContent);

    // 步驟 2: 建立 Repository + Library + CodeService + Executor
    const repository = new cql.Repository({ FHIRHelpers: fhirHelpersElm });
    const library = new cql.Library(elm, repository);
    const codeService = buildCodeServiceFromELM(elm);
    const executor = new cql.Executor(library, codeService);

    // 步驟 3: 從 FHIR Server 取得資料
    console.log('📥 從 FHIR Server 取得資料...');
    let fhirData;
    if (isIndicator) {
        fhirData = await fetchIndicatorFHIRData(fhirServerUrl, { startDate, endDate, maxRecords: maxRecords || 500 });
    } else {
        fhirData = await fetchFHIRData(fhirServerUrl, { startDate, endDate, maxRecords });
    }

    // 步驟 4: 建立 Patient Source
    const patientSource = cqlfhir.PatientSource.FHIRv401();
    patientSource.loadBundles(fhirData);

    // 步驟 5: 設置參數
    const parameters = {};
    if (startDate && endDate) {
        parameters['Measurement Period'] = new cql.Interval(
            cql.DateTime.parse(startDate),
            cql.DateTime.parse(endDate)
        );
    }

    // 步驟 6: 執行 CQL Engine
    console.log('⚙️ 執行 CQL Engine...');
    let results;
    try {
        results = executor.exec(patientSource, parameters);
        console.log(`✅ 執行完成，患者數: ${Object.keys(results.patientResults || {}).length}`);
    } catch (execError) {
        console.error('⚠️ CQL 執行錯誤:', execError.message);
        return [{
            '執行狀態': '⚠️ CQL Engine 執行遇到錯誤',
            '錯誤訊息': execError.message,
            '說明': 'CQL Engine 正在使用真正的引擎進行嚴格驗證'
        }];
    }

    // 步驟 7: 格式化結果
    if (isIndicator) {
        return formatIndicatorResults(results, cqlFile);
    }
    return formatCQLResults(results, cqlFile);
}

// ==================== 品質指標 FHIR 資料抓取 ====================
async function fetchIndicatorFHIRData(fhirServerUrl, options = {}) {
    const { maxRecords = 500 } = options;
    console.log('📥 [Indicator] 抓取 Encounter + Procedure + Patient 資料...');

    const deliveryCodes = [
        '81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C',
        '97004C', '97005D', '97934C',
        '81004C', '81005C', '81028C', '81029C', '97009C', '97014C'
    ];

    try {
        // 1. 抓取分娩相關 Procedure
        let allProcedures = [];
        const procResponse = await axios.get(`${fhirServerUrl}/Procedure`, {
            params: { code: deliveryCodes.join(','), _count: maxRecords, _sort: '-date' },
            timeout: 60000
        });
        if (procResponse.data?.entry) {
            allProcedures = procResponse.data.entry.map(e => e.resource);
        }
        console.log(`   ✅ ${allProcedures.length} 個分娩 Procedure`);

        // 2. 收集相關 ID
        const encounterIds = new Set();
        const patientIds = new Set();
        allProcedures.forEach(p => {
            const encRef = p.encounter?.reference;
            if (encRef) encounterIds.add(encRef.replace('Encounter/', ''));
            const patRef = p.subject?.reference;
            if (patRef) patientIds.add(patRef.replace('Patient/', ''));
        });

        // 3. 也抓取住院 Encounter
        try {
            const encResponse = await axios.get(`${fhirServerUrl}/Encounter`, {
                params: { class: 'IMP', status: 'finished', _count: maxRecords },
                timeout: 60000
            });
            if (encResponse.data?.entry) {
                encResponse.data.entry.map(e => e.resource).forEach(e => {
                    if (e.id) encounterIds.add(e.id);
                    const patRef = e.subject?.reference;
                    if (patRef) patientIds.add(patRef.replace('Patient/', ''));
                });
            }
        } catch (err) {
            console.log('   ⚠️ Encounter 查詢失敗，使用 Procedure 關聯的 Encounter');
        }

        // 4. 抓取 Encounter 詳情
        const encounterMap = {};
        for (const encId of encounterIds) {
            try {
                const encResponse = await axios.get(`${fhirServerUrl}/Encounter/${encId}`, { timeout: 10000 });
                if (encResponse.data) {
                    encounterMap[encId] = encResponse.data;
                    const patRef = encResponse.data.subject?.reference;
                    if (patRef) patientIds.add(patRef.replace('Patient/', ''));
                }
            } catch { /* skip */ }
        }

        // 5. 為每位 Patient 建立 Bundle
        const patientBundles = [];
        for (const patientId of patientIds) {
            try {
                const patResponse = await axios.get(`${fhirServerUrl}/Patient/${patientId}`, { timeout: 10000 });
                if (!patResponse.data) continue;

                const entries = [
                    { resource: patResponse.data, fullUrl: `${fhirServerUrl}/Patient/${patientId}` }
                ];

                Object.values(encounterMap).forEach(enc => {
                    const subj = enc.subject?.reference;
                    if (subj === `Patient/${patientId}` || subj?.endsWith(`/${patientId}`)) {
                        entries.push({ resource: enc, fullUrl: `${fhirServerUrl}/Encounter/${enc.id}` });
                    }
                });

                allProcedures.forEach(proc => {
                    const subj = proc.subject?.reference;
                    if (subj === `Patient/${patientId}` || subj?.endsWith(`/${patientId}`)) {
                        entries.push({ resource: proc, fullUrl: `${fhirServerUrl}/Procedure/${proc.id}` });
                    }
                });

                patientBundles.push({
                    resourceType: 'Bundle',
                    type: 'collection',
                    id: patientId,
                    entry: entries
                });
            } catch {
                console.log(`   ⚠️ 無法取得 Patient ${patientId}`);
            }
        }

        console.log(`   ✅ 建立 ${patientBundles.length} 個 Patient Bundle`);
        return patientBundles;

    } catch (error) {
        throw new Error(`指標 FHIR 資料查詢失敗: ${error.message}`);
    }
}

// ==================== 一般 FHIR 資料抓取（傳染病監測用） ====================
async function fetchFHIRData(fhirServerUrl, options = {}) {
    const { maxRecords = 200 } = options;
    const fetchCount = maxRecords > 0 ? maxRecords : 10000;

    try {
        // 同時抓取 Condition、Encounter、Observation
        const [conditionsResponse, encountersResponse, observationsResponse] = await Promise.all([
            axios.get(`${fhirServerUrl}/Condition`, {
                params: { _count: fetchCount, _sort: '-recorded-date' },
                timeout: 60000
            }).catch(() => ({ data: { entry: [] } })),
            axios.get(`${fhirServerUrl}/Encounter`, {
                params: { _count: fetchCount, _sort: '-date' },
                timeout: 60000
            }).catch(() => ({ data: { entry: [] } })),
            axios.get(`${fhirServerUrl}/Observation`, {
                params: { _count: fetchCount, _sort: '-date', category: 'laboratory' },
                timeout: 60000
            }).catch(() => ({ data: { entry: [] } }))
        ]);

        const conditionEntries = conditionsResponse.data?.entry || [];
        const encounterEntries = encountersResponse.data?.entry || [];
        const observationEntries = observationsResponse.data?.entry || [];

        if (conditionEntries.length === 0 && encounterEntries.length === 0 && observationEntries.length === 0) {
            return [{ resourceType: 'Bundle', type: 'searchset', total: 0, entry: [] }];
        }

        // 收集所有 Patient ID
        const patientIds = new Set();
        const extractPatientId = (entry) => {
            const ref = entry.resource?.subject?.reference || entry.resource?.patient?.reference;
            if (ref) {
                const id = ref.split('/').pop();
                if (id) patientIds.add(id);
            }
        };
        conditionEntries.forEach(extractPatientId);
        encounterEntries.forEach(extractPatientId);
        observationEntries.forEach(extractPatientId);

        console.log(`   📊 Condition: ${conditionEntries.length}, Encounter: ${encounterEntries.length}, Observation: ${observationEntries.length}, Patients: ${patientIds.size}`);

        // 為每位 Patient 建立 Bundle
        const patientBundles = [];
        for (const patientId of Array.from(patientIds)) {
            try {
                const patientResponse = await axios.get(`${fhirServerUrl}/Patient/${patientId}`, { timeout: 10000 });
                if (!patientResponse.data) continue;

                const matchPatient = (entry) => {
                    const ref = entry.resource?.subject?.reference || entry.resource?.patient?.reference;
                    return ref && (ref === `Patient/${patientId}` || ref.endsWith(`/${patientId}`));
                };

                const entries = [
                    { resource: patientResponse.data, fullUrl: `${fhirServerUrl}/Patient/${patientId}` }
                ];

                conditionEntries.filter(matchPatient).forEach(e => {
                    entries.push({ resource: e.resource, fullUrl: e.fullUrl || `${fhirServerUrl}/Condition/${e.resource.id}` });
                });
                encounterEntries.filter(matchPatient).forEach(e => {
                    entries.push({ resource: e.resource, fullUrl: e.fullUrl || `${fhirServerUrl}/Encounter/${e.resource.id}` });
                });
                observationEntries.filter(matchPatient).forEach(e => {
                    entries.push({ resource: e.resource, fullUrl: e.fullUrl || `${fhirServerUrl}/Observation/${e.resource.id}` });
                });

                patientBundles.push({
                    resourceType: 'Bundle',
                    type: 'collection',
                    id: patientId,
                    entry: entries
                });
            } catch {
                console.log(`   ⚠️ 無法取得 Patient ${patientId}`);
            }
        }

        console.log(`   ✅ 建立 ${patientBundles.length} 個 Patient Bundle (含 Condition+Encounter+Observation)`);
        return patientBundles;

    } catch (error) {
        if (error.code === 'ETIMEDOUT' || error.code === 'ECONNABORTED') {
            throw new Error(`FHIR 伺服器連線逾時: ${error.message}`);
        }
        if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
            throw new Error(`無法連線到 FHIR 伺服器: ${error.message}`);
        }
        throw new Error(`FHIR 資料查詢失敗: ${error.message}`);
    }
}

// ==================== 品質指標結果聚合 ====================
function formatIndicatorResults(results, cqlFile) {
    console.log('📊 [Indicator] 聚合 CQL Engine 結果...');

    const patientResults = results.patientResults || {};
    const patientIds = Object.keys(patientResults);

    // 判斷指標類型
    let indicatorCode, indicatorName, indicatorNameEn, indicatorNote;
    if (cqlFile?.includes('11_1')) {
        indicatorCode = '1136.01'; indicatorName = '剖腹產率-整體'; indicatorNameEn = 'Overall Cesarean Section Rate';
        indicatorNote = '本項指標含符合適應症及自行要求剖腹產案件';
    } else if (cqlFile?.includes('11_2')) {
        indicatorCode = '1137.01'; indicatorName = '剖腹產率-自行要求'; indicatorNameEn = 'Cesarean Section Rate - Patient Requested';
        indicatorNote = '自行要求剖腹產案件';
    } else if (cqlFile?.includes('11_3')) {
        indicatorCode = '1138.01'; indicatorName = '剖腹產率-具適應症'; indicatorNameEn = 'Cesarean Section Rate - With Indication';
        indicatorNote = '具醫療適應症之剖腹產案件';
    } else if (cqlFile?.includes('11_4')) {
        indicatorCode = '1075.01'; indicatorName = '剖腹產率-初次具適應症'; indicatorNameEn = 'First Time Cesarean Section Rate';
        indicatorNote = '初次剖腹產且具醫療適應症（排除前胎剖腹產及自行要求）';
    } else {
        indicatorCode = 'Unknown'; indicatorName = '未知指標'; indicatorNameEn = 'Unknown Indicator';
        indicatorNote = '';
    }

    // 聚合各病人結果
    let totalDenominator = 0, totalNumerator = 0, totalNatural = 0, totalCesarean = 0;
    const quarterDenominator = {}, quarterNumerator = {}, quarterCesarean = {};
    const caseDetails = [];

    function getQuarterKey(dateVal) {
        try {
            const d = new Date(dateVal);
            if (isNaN(d.getTime())) return null;
            return `${d.getFullYear()}Q${Math.ceil((d.getMonth() + 1) / 3)}`;
        } catch { return null; }
    }

    // 分子 define 名稱
    let numeratorDefineName = 'Cesarean Deliveries';
    if (cqlFile?.includes('11_2')) numeratorDefineName = 'Patient Requested Cesarean Deliveries';
    else if (cqlFile?.includes('11_4')) numeratorDefineName = 'First Time With Indication Cesarean Deliveries';
    else if (cqlFile?.includes('11_3')) numeratorDefineName = 'Cesarean With Indication Deliveries';

    for (const [patientId, patResult] of Object.entries(patientResults)) {
        // 季度欄位
        Object.keys(patResult).filter(k => k.match(/^\d{4}Q\d (Denominator|Numerator)$/)).forEach(k => {
            const val = patResult[k] || 0;
            if (k.includes('Denominator')) quarterDenominator[k] = (quarterDenominator[k] || 0) + val;
            else quarterNumerator[k] = (quarterNumerator[k] || 0) + val;
        });

        const allDeliveries = patResult['All Deliveries'];
        const cesareanDeliveries = patResult['Cesarean Deliveries'];
        const naturalDeliveries = patResult['Natural Deliveries'];
        const numeratorDeliveries = patResult[numeratorDefineName];

        const denom = Array.isArray(allDeliveries) ? allDeliveries.length : 0;
        const cesCount = Array.isArray(cesareanDeliveries) ? cesareanDeliveries.length : 0;
        const natCount = Array.isArray(naturalDeliveries) ? naturalDeliveries.length : 0;
        const numer = Array.isArray(numeratorDeliveries) ? numeratorDeliveries.length : 0;

        totalDenominator += denom;
        totalNumerator += numer;
        totalNatural += natCount;
        totalCesarean += cesCount;

        if (Array.isArray(cesareanDeliveries)) {
            for (const enc of cesareanDeliveries) {
                const periodEnd = enc?.period?.end?.value || enc?.period?.end || '';
                const qk = getQuarterKey(periodEnd);
                if (qk) quarterCesarean[qk] = (quarterCesarean[qk] || 0) + 1;
            }
        }

        // 案件詳情
        const allDel = Array.isArray(allDeliveries) ? allDeliveries : [];
        const cesSet = new Set();
        if (Array.isArray(cesareanDeliveries)) {
            cesareanDeliveries.forEach(e => {
                const eid = e?.id?.value || e?.id || '';
                if (eid) cesSet.add(String(eid));
            });
        }

        for (const enc of allDel) {
            const encId = enc?.id?.value || enc?.id || '';
            const patRef = enc?.subject?.reference?.value || enc?.subject?.reference || '';
            const periodEnd = enc?.period?.end?.value || enc?.period?.end || '';
            let dateStr = '';
            if (periodEnd) {
                try { dateStr = new Date(periodEnd).toLocaleDateString('zh-TW'); } catch { dateStr = String(periodEnd); }
            }

            caseDetails.push({
                encounter_id: encId,
                patient_ref: patRef,
                delivery_date: dateStr || '-',
                delivery_type: cesSet.has(String(encId)) ? '剖腹產' : '自然產'
            });
        }
    }

    console.log(`   聚合: 分母=${totalDenominator}, 分子=${totalNumerator}`);

    const overallRate = totalDenominator > 0
        ? parseFloat(((totalNumerator / totalDenominator) * 100).toFixed(2))
        : 0;

    // 描述
    let indicatorDescription;
    if (cqlFile?.includes('11_2')) indicatorDescription = '分子：不具適應症之剖腹產案件(自行要求) / 分母：生產案件數';
    else if (cqlFile?.includes('11_4')) indicatorDescription = '分子：初次具適應症之剖腹產案件 / 分母：生產案件數';
    else if (cqlFile?.includes('11_3')) indicatorDescription = '分子：具適應症之剖腹產案件 / 分母：生產案件數';
    else indicatorDescription = '分子：剖腹產案件數 / 分母：生產案件數（自然產+剖腹產）';

    // 季度結果
    const quarterLabels = {
        '2024Q1': '113年第1季', '2024Q2': '113年第2季', '2024Q3': '113年第3季', '2024Q4': '113年第4季',
        '2025Q1': '114年第1季', '2025Q2': '114年第2季', '2025Q3': '114年第3季', '2025Q4': '114年第4季',
        '2026Q1': '115年第1季'
    };
    const orderedQuarters = ['2024Q1','2024Q2','2024Q3','2024Q4','2025Q1','2025Q2','2025Q3','2025Q4','2026Q1'];

    const quarterlyResults = orderedQuarters.map(qp => {
        const denom = quarterDenominator[`${qp} Denominator`] || 0;
        const numer = quarterNumerator[`${qp} Numerator`] || 0;
        const cesQ = quarterCesarean[qp] || 0;
        const rate = denom > 0 ? parseFloat(((numer / denom) * 100).toFixed(2)) : 0;

        return {
            quarter: qp,
            quarter_label: quarterLabels[qp] || qp,
            denominator: denom, numerator: numer,
            natural_count: denom > 0 ? denom - cesQ : '-',
            cesarean_count: denom > 0 ? cesQ : '-',
            rate: rate
        };
    });

    return {
        _type: 'indicator',
        indicator: {
            code: indicatorCode,
            name: indicatorName,
            nameEn: indicatorNameEn,
            description: indicatorDescription,
            source: '醫療給付檔案分析系統',
            compiledBy: '衛生福利部 中央健康保險署',
            note: indicatorNote
        },
        summary: {
            total_deliveries: totalDenominator,
            denominator: totalDenominator,
            numerator: totalNumerator,
            natural_count: totalNatural,
            cesarean_count: totalCesarean,
            rate: overallRate,
            patientCount: patientIds.length
        },
        quarterly: quarterlyResults,
        cases: caseDetails.slice(0, 50),
        fhirQuery: {
            patientsProcessed: patientIds.length,
            encountersFound: totalDenominator,
            proceduresFound: totalCesarean,
            deliveryCasesClassified: caseDetails.length
        },
        _engine: 'cql-execution',
        _engineNote: `CQL Engine 逐病人執行（${patientIds.length} 位病人），平台端聚合結果`
    };
}

// ==================== 格式化一般 CQL 結果（傳染病監測等） ====================
function formatCQLResults(results, cqlFile) {
    const formattedResults = [];
    const cqlFileLower = cqlFile ? cqlFile.toLowerCase() : '';
    const mainResultKey = cqlFileLower.includes('covid') ? 'COVID19 Surveillance Results' :
        cqlFileLower.includes('influenza') || cqlFileLower.includes('flu') ? 'Influenza Surveillance Results' :
        cqlFileLower.includes('conjunctivitis') ? 'Acute Conjunctivitis Surveillance Results' :
        cqlFileLower.includes('enterovirus') ? 'Enterovirus Surveillance Results' :
        cqlFileLower.includes('diarrhea') ? 'Acute Diarrhea Surveillance Results' : null;

    // 嘗試從 unfilteredResults 取得 Population context 結果
    if (mainResultKey && results.unfilteredResults?.[mainResultKey]) {
        const survResults = results.unfilteredResults[mainResultKey];
        if (Array.isArray(survResults) && survResults.length > 0) {
            survResults.forEach(episode => {
                const row = {};
                for (const [key, value] of Object.entries(episode)) {
                    row[key] = formatValue(value, key);
                }
                formattedResults.push(row);
            });
            return formattedResults;
        }
    }

    // Patient context 結果
    if (mainResultKey && results.patientResults) {
        for (const [patientId, patientResult] of Object.entries(results.patientResults)) {
            const survResults = patientResult[mainResultKey];
            if (Array.isArray(survResults) && survResults.length > 0) {
                survResults.forEach(episode => {
                    const row = {};
                    for (const [key, value] of Object.entries(episode)) {
                        row[key] = formatValue(value, key);
                    }
                    formattedResults.push(row);
                });
            }
        }
        if (formattedResults.length > 0) return formattedResults;
    }

    // 備用：所有定義
    if (results.patientResults) {
        for (const [patientId, patientResult] of Object.entries(results.patientResults)) {
            const row = { '患者ID': patientId };
            for (const [defName, value] of Object.entries(patientResult)) {
                if (defName.startsWith('_') || defName === 'PatientID') continue;
                row[defName] = formatValue(value, defName);
            }
            formattedResults.push(row);
        }
    }

    return formattedResults.length > 0 ? formattedResults : [{
        '患者ID': 'N/A',
        '結果': 'CQL 執行完成，但無符合條件的結果'
    }];
}

// ==================== 格式化值 ====================
function formatValue(value, fieldName = '') {
    if (value === null || value === undefined) return 'N/A';
    if (typeof value === 'boolean') return value ? '是' : '否';
    if (value instanceof Date) return value.toISOString().split('T')[0];
    if (Array.isArray(value)) return value.length;

    if (typeof value === 'object') {
        if (value.resourceType === 'Patient' || ((fieldName === 'Patient' || fieldName === '病患') && (value.name || value.birthDate))) {
            return formatPatientInfo(value);
        }
        const jsonStr = JSON.stringify(value);
        return jsonStr.length > 150 ? jsonStr.substring(0, 150) + '...' : jsonStr;
    }
    return value;
}

// ==================== 格式化病患資訊 ====================
function formatPatientInfo(patient) {
    const parts = [];

    if (patient.name && patient.name.length > 0) {
        const name = patient.name[0];
        if (name.text) parts.push(String(name.text));
        else {
            const family = name.family ? String(name.family) : '';
            const given = Array.isArray(name.given) ? name.given.map(String).join(' ') : '';
            parts.push([family, given].filter(x => x).join(' ') || 'N/A');
        }
    } else {
        parts.push('N/A');
    }

    parts.push(patient.birthDate ? String(patient.birthDate) : 'N/A');

    const genderMap = { 'male': '男', 'female': '女', 'other': '其他', 'unknown': '未知' };
    parts.push(genderMap[patient.gender] || patient.gender || 'N/A');

    if (patient.id) parts.push(`ID:${patient.id}`);

    return parts.join(' / ');
}

// ==================== 導出 ====================
module.exports = {
    loadELM,
    listAvailableELM,
    executeCQL
};
