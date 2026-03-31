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
        fhirData = await fetchFHIRData(fhirServerUrl, { startDate, endDate, maxRecords, cqlFile });
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

    // 步驟 8: 提取 Patient 地址資料 (供前端地區分佈統計)
    const regionStats = extractPatientAddresses(fhirData);

    const formattedResults = formatCQLResults(results, cqlFile);
    return { _data: formattedResults, _regionStats: regionStats };
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
// ==================== 疾病代碼對照表 ====================
const DISEASE_CODE_MAP = {
    'covid19': {
        textTerms: ['COVID-19', 'COVID', 'SARS-CoV-2'],
        icd10: ['U07.1', 'U07.2'],
        snomed: ['840539006', '840544004', '882784691000119100', '1240581000000104', '1240751000000100', '870588003', '1119302008'],
        labLoinc: ['94500-6', '94559-2', '94845-3', '97097-0', '94558-4', '94563-4', '94564-2', '94762-2', '94533-7', '94640-0', '94645-9', '94315-9', '94531-1', '94764-8', '94745-7']
    },
    'influenza': {
        textTerms: ['Influenza', '流感'],
        icd10: ['J09', 'J10', 'J10.0', 'J10.1', 'J10.8', 'J11', 'J11.0', 'J11.1'],
        snomed: ['6142004', '24662006', '442696006'],
        labLoinc: ['76080-1', '80382-5', '80383-3', '92141-1', '92142-9']
    },
    'conjunctivitis': {
        textTerms: ['Conjunctivitis', '結膜炎'],
        icd10: ['H10', 'H10.0', 'H10.1', 'H10.2', 'H10.3', 'B30'],
        snomed: ['9826008', '231857006'],
        labLoinc: []
    },
    'enterovirus': {
        textTerms: ['Enterovirus', '腸病毒'],
        icd10: ['B97.1', 'B08.4', 'B08.5', 'A08.3'],
        snomed: ['243615000', '186659004'],
        labLoinc: []
    },
    'diarrhea': {
        textTerms: ['Diarrhea', '腹瀉'],
        icd10: ['A09', 'K52', 'K52.9', 'A09.0', 'A09.9'],
        snomed: ['62315008', '409966000'],
        labLoinc: []
    }
};

function detectDiseaseType(cqlFile) {
    if (!cqlFile) return null;
    const lower = cqlFile.toLowerCase();
    if (lower.includes('covid')) return 'covid19';
    if (lower.includes('influenza') || lower.includes('flu')) return 'influenza';
    if (lower.includes('conjunctivitis')) return 'conjunctivitis';
    if (lower.includes('enterovirus')) return 'enterovirus';
    if (lower.includes('diarrhea')) return 'diarrhea';
    return null;
}

async function fetchFHIRData(fhirServerUrl, options = {}) {
    const { maxRecords = 200, cqlFile } = options;
    const fetchCount = maxRecords > 0 ? maxRecords : 10000;

    // 根據 CQL 檔案判斷疾病類型，加上疾病代碼過濾
    const diseaseType = detectDiseaseType(cqlFile);
    const diseaseCodes = diseaseType ? DISEASE_CODE_MAP[diseaseType] : null;

    try {
        // 構建 Condition 查詢參數
        const conditionParams = { _count: fetchCount, _sort: '-recorded-date' };
        
        if (diseaseCodes) {
            // 合併 ICD-10 + SNOMED 代碼為 code 查詢
            const allCodes = [
                ...diseaseCodes.icd10.map(c => `http://hl7.org/fhir/sid/icd-10-cm|${c}`),
                ...diseaseCodes.snomed.map(c => `http://snomed.info/sct|${c}`)
            ];
            conditionParams.code = allCodes.join(',');
            console.log(`   🎯 疾病過濾: ${diseaseType} (${diseaseCodes.icd10.length} ICD-10 + ${diseaseCodes.snomed.length} SNOMED 代碼)`);
        } else {
            console.log(`   ⚠️ 無疾病過濾 (cqlFile: ${cqlFile})`);
        }

        // 構建 Observation 查詢參數
        const obsParams = { _count: fetchCount, _sort: '-date', category: 'laboratory' };
        if (diseaseCodes && diseaseCodes.labLoinc.length > 0) {
            obsParams.code = diseaseCodes.labLoinc.map(c => `http://loinc.org|${c}`).join(',');
        }

        // 先查 Condition (有疾病過濾)
        const conditionsPromise = axios.get(`${fhirServerUrl}/Condition`, {
            params: conditionParams,
            timeout: 60000
        }).catch(() => ({ data: { entry: [] } }));

        // 也嘗試 text 搜尋 (某些 FHIR Server 不支援 code 搜尋)
        let textConditionsPromise = Promise.resolve({ data: { entry: [] } });
        if (diseaseCodes) {
            const textTerm = diseaseCodes.textTerms[0];
            textConditionsPromise = axios.get(`${fhirServerUrl}/Condition`, {
                params: { 'code:text': textTerm, _count: fetchCount, _sort: '-recorded-date' },
                timeout: 60000
            }).catch(() => ({ data: { entry: [] } }));
        }

        // Observation 查詢 (有疾病實驗室代碼過濾)
        const observationsPromise = axios.get(`${fhirServerUrl}/Observation`, {
            params: obsParams,
            timeout: 60000
        }).catch(() => ({ data: { entry: [] } }));

        const [conditionsResponse, textConditionsResponse, observationsResponse] = await Promise.all([
            conditionsPromise, textConditionsPromise, observationsPromise
        ]);

        // 合併 code 搜尋和 text 搜尋結果 (去重)
        const codeEntries = conditionsResponse.data?.entry || [];
        const textEntries = textConditionsResponse.data?.entry || [];
        const seenIds = new Set();
        const allConditionEntries = [];
        [...codeEntries, ...textEntries].forEach(e => {
            const id = e.resource?.id;
            if (id && !seenIds.has(id)) {
                seenIds.add(id);
                allConditionEntries.push(e);
            }
        });

        const observationEntries = observationsResponse.data?.entry || [];

        console.log(`   📊 Condition (code): ${codeEntries.length}, Condition (text): ${textEntries.length}, 合併去重: ${allConditionEntries.length}, Observation: ${observationEntries.length}`);

        // 從 Condition + Observation 收集 Patient IDs
        const patientIds = new Set();
        const extractPatientId = (entry) => {
            const ref = entry.resource?.subject?.reference || entry.resource?.patient?.reference;
            if (ref) {
                const id = ref.split('/').pop();
                if (id) patientIds.add(id);
            }
        };
        allConditionEntries.forEach(extractPatientId);
        observationEntries.forEach(extractPatientId);

        if (patientIds.size === 0) {
            console.log(`   ⚠️ 無符合疾病條件的 Patient`);
            return [{ resourceType: 'Bundle', type: 'searchset', total: 0, entry: [] }];
        }

        console.log(`   👥 找到 ${patientIds.size} 位相關病患，查詢完整就診資料...`);

        // 為每位 Patient 查詢其所有 Encounter
        const patientBundles = [];
        for (const patientId of Array.from(patientIds)) {
            try {
                const [patientResponse, patEncounters] = await Promise.all([
                    axios.get(`${fhirServerUrl}/Patient/${patientId}`, { timeout: 10000 }),
                    axios.get(`${fhirServerUrl}/Encounter`, {
                        params: { patient: patientId, _count: 200, _sort: '-date' },
                        timeout: 15000
                    }).catch(() => ({ data: { entry: [] } }))
                ]);

                if (!patientResponse.data) continue;

                const matchPatient = (entry) => {
                    const ref = entry.resource?.subject?.reference || entry.resource?.patient?.reference;
                    return ref && (ref === `Patient/${patientId}` || ref.endsWith(`/${patientId}`));
                };

                const entries = [
                    { resource: patientResponse.data, fullUrl: `${fhirServerUrl}/Patient/${patientId}` }
                ];

                allConditionEntries.filter(matchPatient).forEach(e => {
                    const cond = e.resource;
                    // 自動補上 encounter reference (如果 Condition 沒有關聯 Encounter)
                    if (cond && (!cond.encounter || !cond.encounter.reference) && patEncEntries.length > 0) {
                        const condDate = cond.onsetDateTime || cond.recordedDate || '';
                        const condTime = condDate ? new Date(condDate).getTime() : 0;
                        // 找最近日期的 Encounter
                        let bestEnc = null;
                        let bestDiff = Infinity;
                        patEncEntries.forEach(pe => {
                            const enc = pe.resource;
                            if (!enc || !enc.id) return;
                            const encStart = enc.period?.start || '';
                            const encTime = encStart ? new Date(encStart).getTime() : 0;
                            const diff = condTime && encTime ? Math.abs(condTime - encTime) : Infinity;
                            if (diff < bestDiff) { bestDiff = diff; bestEnc = enc; }
                        });
                        if (bestEnc) {
                            cond.encounter = { reference: `Encounter/${bestEnc.id}` };
                        }
                    }
                    entries.push({ resource: cond, fullUrl: e.fullUrl || `${fhirServerUrl}/Condition/${cond.id}` });
                });

                // 加入該病患的所有 Encounter (用於 CQL 判斷就診類型)
                const patEncEntries = patEncounters.data?.entry || [];
                patEncEntries.forEach(e => {
                    entries.push({ resource: e.resource, fullUrl: e.fullUrl || `${fhirServerUrl}/Encounter/${e.resource.id}` });
                });

                observationEntries.filter(matchPatient).forEach(e => {
                    const obs = e.resource;
                    // 自動補上 encounter reference (如果 Observation 沒有關聯 Encounter)
                    if (obs && (!obs.encounter || !obs.encounter.reference) && patEncEntries.length > 0) {
                        const obsDate = obs.effectiveDateTime || obs.issued || '';
                        const obsTime = obsDate ? new Date(obsDate).getTime() : 0;
                        let bestEnc = null;
                        let bestDiff = Infinity;
                        patEncEntries.forEach(pe => {
                            const enc = pe.resource;
                            if (!enc || !enc.id) return;
                            const encStart = enc.period?.start || '';
                            const encTime = encStart ? new Date(encStart).getTime() : 0;
                            const diff = obsTime && encTime ? Math.abs(obsTime - encTime) : Infinity;
                            if (diff < bestDiff) { bestDiff = diff; bestEnc = enc; }
                        });
                        if (bestEnc) {
                            obs.encounter = { reference: `Encounter/${bestEnc.id}` };
                        }
                    }
                    entries.push({ resource: obs, fullUrl: e.fullUrl || `${fhirServerUrl}/Observation/${obs.id}` });
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

        console.log(`   ✅ 建立 ${patientBundles.length} 個 Patient Bundle (疾病過濾: ${diseaseType || '無'})`);
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

// ==================== 提取 Patient 地址資料 ====================
function extractPatientAddresses(fhirBundles) {
    const regionCount = {};  // city -> count
    const districtCount = {}; // "city+district" -> count
    const seen = new Set();

    if (!Array.isArray(fhirBundles)) return { regions: [], districts: [] };

    fhirBundles.forEach(bundle => {
        const entries = bundle.entry || [];
        entries.forEach(e => {
            const res = e.resource;
            if (res && res.resourceType === 'Patient' && !seen.has(res.id)) {
                seen.add(res.id);
                const addr = Array.isArray(res.address) && res.address.length > 0 ? res.address[0] : null;
                if (addr) {
                    const city = addr.city || addr.state || '';
                    const district = addr.district || '';
                    if (city) {
                        regionCount[city] = (regionCount[city] || 0) + 1;
                        if (district) {
                            const key = `${city}${district}`;
                            districtCount[key] = (districtCount[key] || 0) + 1;
                        }
                    }
                }
            }
        });
    });

    const regions = Object.entries(regionCount)
        .sort((a, b) => b[1] - a[1])
        .map(([name, count]) => ({ name, count }));
    const districts = Object.entries(districtCount)
        .sort((a, b) => b[1] - a[1])
        .map(([name, count]) => ({ name, count }));

    console.log(`   📍 地區統計: ${regions.length} 個縣市, ${districts.length} 個鄉鎮區`);
    return { regions, districts };
}

// ==================== 格式化一般 CQL 結果（傳染病監測等） ====================
function formatCQLResults(results, cqlFile) {
    const formattedResults = [];
    const cqlFileLower = cqlFile ? cqlFile.toLowerCase() : '';
    const mainResultKey = cqlFileLower.includes('covid') ? 'COVID19 Surveillance Results' :
        cqlFileLower.includes('influenza') || cqlFileLower.includes('flu') ? 'Final Result' :
        cqlFileLower.includes('conjunctivitis') ? 'Acute Conjunctivitis Surveillance Results' :
        cqlFileLower.includes('enterovirus') ? 'Enterovirus Surveillance Results' :
        cqlFileLower.includes('diarrhea') ? 'Acute Diarrhea Surveillance Results' : null;

    // 統一輸出 key 名稱 (前端只認含 "Surveillance Results" 的 key)
    const outputSurvKey = cqlFileLower.includes('covid') ? 'COVID19 Surveillance Results' :
        cqlFileLower.includes('influenza') || cqlFileLower.includes('flu') ? 'Influenza Surveillance Results' :
        cqlFileLower.includes('conjunctivitis') ? 'Acute Conjunctivitis Surveillance Results' :
        cqlFileLower.includes('enterovirus') ? 'Enterovirus Surveillance Results' :
        cqlFileLower.includes('diarrhea') ? 'Acute Diarrhea Surveillance Results' : null;

    // 嘗試從 unfilteredResults 取得 Population context 結果
    if (mainResultKey && results.unfilteredResults?.[mainResultKey]) {
        const survResults = results.unfilteredResults[mainResultKey];
        if (Array.isArray(survResults) && survResults.length > 0) {
            // 建立摘要行 (含完整 Surveillance Results 陣列供前端統計)
            const summaryRow = {};
            summaryRow[outputSurvKey] = survResults.map(ep => {
                const r = {};
                for (const [k, v] of Object.entries(ep)) r[k] = formatValue(v, k);
                return r;
            });
            // 加入其他統計欄位
            for (const [key, value] of Object.entries(results.unfilteredResults)) {
                if (key === mainResultKey) continue;
                summaryRow[key] = formatValue(value, key);
            }
            formattedResults.push(summaryRow);
            return formattedResults;
        }
    }

    // Patient context 結果
    if (mainResultKey && results.patientResults) {
        const allEpisodes = [];
        const countAgg = {};  // 聚合計數欄位

        for (const [patientId, patientResult] of Object.entries(results.patientResults)) {
            const survResults = patientResult[mainResultKey];
            if (Array.isArray(survResults) && survResults.length > 0) {
                survResults.forEach(episode => {
                    const row = {};
                    for (const [key, value] of Object.entries(episode)) {
                        row[key] = formatValue(value, key);
                    }
                    allEpisodes.push(row);
                });
            }
            // 收集計數欄位 (Episode Count By Gender, etc.)
            for (const [key, value] of Object.entries(patientResult)) {
                if (key === mainResultKey || key.startsWith('_')) continue;
                if (key.includes('Episode') || key.includes('Count') || key === 'PatientGender' || key === 'Patient Gender') {
                    const fv = formatValue(value, key);
                    if (typeof fv === 'object' && !Array.isArray(fv)) {
                        // 聚合物件型統計 (如 Episode Count By Gender: {Male:5, Female:3})
                        if (!countAgg[key]) countAgg[key] = {};
                        for (const [k, v] of Object.entries(fv)) {
                            countAgg[key][k] = (countAgg[key][k] || 0) + (Number(v) || 0);
                        }
                    } else if (typeof fv === 'number') {
                        countAgg[key] = (countAgg[key] || 0) + fv;
                    }
                }
            }
        }

        if (allEpisodes.length > 0) {
            // 建立摘要行
            const summaryRow = { ...countAgg };
            summaryRow[outputSurvKey] = allEpisodes;
            formattedResults.push(summaryRow);
            return formattedResults;
        }
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

    // CQL DateTime / FHIRObject with value property → 提取為字串
    if (typeof value === 'object' && value.value !== undefined && !value.coding && !value.resourceType) {
        return formatValue(value.value, fieldName);
    }

    // 保留 Surveillance Results 陣列的完整資料供前端統計
    if (Array.isArray(value) && fieldName.includes('Surveillance Results')) {
        return value.map(item => {
            if (typeof item !== 'object') return item;
            const row = {};
            for (const [k, v] of Object.entries(item)) {
                row[k] = formatValue(v, k);
            }
            return row;
        });
    }
    if (Array.isArray(value)) return value.length;

    if (typeof value === 'object') {
        // FHIR CodeableConcept → 取出 coding[0].code (Influenza diagnosisCode 為此型態)
        if ((fieldName.includes('diagnosisCode') || fieldName.includes('DiagnosisCode')) && (value.coding || value.text)) {
            const coding = Array.isArray(value.coding) && value.coding.length > 0 ? value.coding[0] : null;
            return coding ? (coding.code || coding.display || value.text || 'N/A') : (value.text || 'N/A');
        }
        // 保留統計 Tuple 為物件（Episode Count By Gender, Episode Count By Encounter Type）
        if (fieldName.includes('Episode Count') || fieldName.includes('Count By')) {
            const obj = {};
            for (const [k, v] of Object.entries(value)) {
                if (k.startsWith('_')) continue;
                obj[k] = (typeof v === 'number' || typeof v === 'string') ? v : formatValue(v, k);
            }
            return obj;
        }
        if (value.resourceType === 'Patient' || ((fieldName === 'Patient' || fieldName === '病患') && (value.name || value.birthDate))) {
            return formatPatientInfo(value);
        }
        const jsonStr = JSON.stringify(value);
        return jsonStr.length > 150 ? jsonStr.substring(0, 150) + '...' : jsonStr;
    }
    return value;
}

// ==================== 安全取字串值 ====================
function safeStr(val) {
    if (val === null || val === undefined) return '';
    if (typeof val === 'string') return val;
    if (typeof val === 'number' || typeof val === 'boolean') return String(val);
    if (typeof val === 'object' && val.value !== undefined) return safeStr(val.value);
    try { const s = JSON.stringify(val); return s.length > 100 ? s.substring(0, 100) : s; } catch(e) { return ''; }
}

// ==================== 格式化病患資訊 ====================
function formatPatientInfo(patient) {
    const info = { name: 'N/A', birthDate: 'N/A', gender: 'N/A', id: '' };

    if (patient.name && patient.name.length > 0) {
        const name = patient.name[0];
        const text = safeStr(name.text);
        if (text) {
            info.name = text;
        } else {
            const family = safeStr(name.family);
            const given = Array.isArray(name.given) ? name.given.map(g => safeStr(g)).filter(x => x).join(' ') : '';
            info.name = [family, given].filter(x => x).join(' ') || 'N/A';
        }
    }

    info.birthDate = safeStr(patient.birthDate) || 'N/A';

    const genderMap = { 'male': '男', 'female': '女', 'other': '其他', 'unknown': '未知' };
    const genderStr = safeStr(patient.gender);
    info.gender = genderMap[genderStr] || genderStr || 'N/A';

    if (patient.id) info.id = safeStr(patient.id);

    return JSON.stringify(info);
}

// ==================== 導出 ====================
module.exports = {
    loadELM,
    listAvailableELM,
    executeCQL
};
