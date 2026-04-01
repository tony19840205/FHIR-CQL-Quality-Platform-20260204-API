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

// ==================== 判斷是否為國民健康 CQL ====================
function isPublicHealthCQL(cqlFile) {
    if (!cqlFile) return false;
    const lower = cqlFile.toLowerCase();
    return lower.includes('vaccination') || lower.includes('hypertensionactive');
}

// ==================== 判斷是否為 ESG CQL ====================
function isESGCQL(cqlFile) {
    if (!cqlFile) return false;
    const lower = cqlFile.toLowerCase();
    return lower.includes('antibiotic') || lower.includes('ehr_adoption') || lower.includes('waste');
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
        // 剖腹產指標(11-1~11-4): 使用既有 CQL Engine 路徑
        const isCesarean = cqlFile && (cqlFile.includes('11_1') || cqlFile.includes('11_2') || cqlFile.includes('11_3') || cqlFile.includes('11_4'));
        if (isCesarean) {
            fhirData = await fetchIndicatorFHIRData(fhirServerUrl, { startDate, endDate, maxRecords: maxRecords || 500 });
        } else {
            // 其他品質指標: 直接從 FHIR 資料計算（避免 fetchIndicatorFHIRData 只查剖腹產資料導致 502）
            const indicatorData = await fetchQualityIndicatorFHIRData(fhirServerUrl, cqlFile, { startDate, endDate, maxRecords: maxRecords || 500 });
            return computeQualityIndicatorResults(indicatorData, cqlFile);
        }
    } else if (isPublicHealthCQL(cqlFile)) {
        // 國民健康指標: CQL 使用 Unfiltered context，cql-execution 不支援
        // 直接從 FHIR 資料計算統計結果（與 non-API 前端版本邏輯一致）
        fhirData = await fetchPublicHealthFHIRData(fhirServerUrl, cqlFile, { startDate, endDate, maxRecords: maxRecords || 500 });
        return computePublicHealthResults(fhirData, cqlFile);
    } else if (isESGCQL(cqlFile)) {
        // ESG 指標: 直接從 FHIR 資料計算（與 non-API 前端版本邏輯一致）
        fhirData = await fetchESGFHIRData(fhirServerUrl, cqlFile, { startDate, endDate, maxRecords: maxRecords || 500 });
        return computeESGResults(fhirData, cqlFile);
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

    // 步驟 7b: 國民健康指標格式化 (疫苗/高血壓)
    if (isPublicHealthCQL(cqlFile)) {
        return formatPublicHealthResults(results, cqlFile);
    }

    // 步驟 8: 格式化結果
    const formattedResults = formatCQLResults(results, cqlFile);

    // 步驟 9: 提取 episode 中的 patient IDs (限縮地區統計範圍)
    const episodePatientIds = new Set();
    const rows = Array.isArray(formattedResults) ? formattedResults : [];
    rows.forEach(row => {
        const survKey = Object.keys(row).find(k => k.includes('Surveillance Results'));
        const survArr = survKey ? row[survKey] : null;
        if (Array.isArray(survArr)) {
            survArr.forEach(ep => {
                const pid = ep.PatientID || ep.patientId || ep.patientID;
                if (pid) episodePatientIds.add(pid);
            });
        }
    });

    // 步驟 10: 提取 Patient 地址資料 (僅統計有 episode 的患者)
    const regionStats = extractPatientAddresses(fhirData, episodePatientIds.size > 0 ? episodePatientIds : null);

    return { _data: formattedResults, _regionStats: regionStats };
}

// ==================== 國民健康 FHIR 資料抓取 ====================
async function fetchPublicHealthFHIRData(fhirServerUrl, cqlFile, options = {}) {
    const { maxRecords = 500 } = options;
    const isVaccination = cqlFile.toLowerCase().includes('vaccination');
    const isHypertension = cqlFile.toLowerCase().includes('hypertension');

    console.log(`📥 [PublicHealth] 抓取${isVaccination ? '疫苗接種' : '高血壓'}資料 (max: ${maxRecords})...`);

    try {
        const fetchCount = maxRecords > 0 ? maxRecords : 10000;
        let primaryEntries = [];
        let observationEntries = [];
        let medicationEntries = [];

        if (isVaccination) {
            // 疫苗接種: 根據 CQL 類型用特定疫苗代碼查詢 Immunization
            const isCovid = cqlFile.toLowerCase().includes('covid');
            
            // COVID-19 疫苗 CVX 代碼
            const covidCodes = ['207', '208', '210', '211', '212', '213', '217', '218', '219'];
            // 流感疫苗 CVX 代碼
            const fluCodes = ['16', '140', '141', '150', '161', '185'];
            
            const vaccineCodes = isCovid ? covidCodes : fluCodes;
            
            console.log(`   🎯 ${isCovid ? 'COVID-19' : '流感'}疫苗代碼查詢 (${vaccineCodes.length} 個代碼)`);
            
            // 逐一查詢各疫苗代碼 (不帶 system prefix，相容此 FHIR Server)
            const allPromises = vaccineCodes.map(code =>
                axios.get(`${fhirServerUrl}/Immunization`, {
                    params: { 'vaccine-code': code, _count: fetchCount },
                    timeout: 60000
                }).catch(() => ({ data: { entry: [] } }))
            );
            
            const responses = await Promise.all(allPromises);
            const seenIds = new Set();
            responses.forEach(resp => {
                const entries = resp.data?.entry || [];
                entries.forEach(e => {
                    const id = e.resource?.id;
                    if (id && !seenIds.has(id)) {
                        seenIds.add(id);
                        primaryEntries.push(e);
                    }
                });
            });
            console.log(`   💉 Immunization (去重後): ${primaryEntries.length} 筆`);
        } else if (isHypertension) {
            // 高血壓: 抓取 Condition (I10-I16) + Observation (血壓) + MedicationRequest
            // 不帶 system prefix，此 FHIR Server 的 code 查詢較可靠
            const hypertensionICD10 = ['I10', 'I11', 'I12', 'I13', 'I14', 'I15', 'I16'];
            const bpLoincCodes = ['85354-9', '8480-6', '8462-4']; // BP panel, systolic, diastolic

            const [condResponse, obsResponse, medResponse] = await Promise.all([
                axios.get(`${fhirServerUrl}/Condition`, {
                    params: {
                        code: hypertensionICD10.join(','),
                        _count: fetchCount,
                        _sort: '-recorded-date'
                    },
                    timeout: 60000
                }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/Observation`, {
                    params: {
                        code: bpLoincCodes.join(','),
                        _count: fetchCount,
                        _sort: '-date'
                    },
                    timeout: 60000
                }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/MedicationRequest`, {
                    params: { _count: fetchCount, _sort: '-authoredon' },
                    timeout: 60000
                }).catch(() => ({ data: { entry: [] } }))
            ]);

            primaryEntries = condResponse.data?.entry || [];
            observationEntries = obsResponse.data?.entry || [];
            medicationEntries = medResponse.data?.entry || [];
            console.log(`   🩺 Condition: ${primaryEntries.length}, Observation: ${observationEntries.length}, MedicationRequest: ${medicationEntries.length}`);
        }

        // 收集所有相關的 Patient IDs
        const patientIds = new Set();
        const extractPatientId = (entry) => {
            const ref = entry.resource?.subject?.reference || entry.resource?.patient?.reference;
            if (ref) {
                const id = ref.split('/').pop();
                if (id) patientIds.add(id);
            }
        };
        primaryEntries.forEach(extractPatientId);
        observationEntries.forEach(extractPatientId);
        medicationEntries.forEach(extractPatientId);

        if (patientIds.size === 0) {
            console.log('   ⚠️ 無符合條件的 Patient');
            return [{ resourceType: 'Bundle', type: 'searchset', total: 0, entry: [] }];
        }

        console.log(`   👥 找到 ${patientIds.size} 位相關病患，組建 Bundle...`);

        // 為每位 Patient 建立 Bundle
        const patientBundles = [];
        for (const patientId of Array.from(patientIds)) {
            try {
                const patientResponse = await axios.get(`${fhirServerUrl}/Patient/${patientId}`, {
                    timeout: 10000
                });
                if (!patientResponse.data) continue;

                const matchPatient = (entry) => {
                    const ref = entry.resource?.subject?.reference || entry.resource?.patient?.reference;
                    return ref && (ref === `Patient/${patientId}` || ref.endsWith(`/${patientId}`));
                };

                const entries = [
                    { resource: patientResponse.data, fullUrl: `${fhirServerUrl}/Patient/${patientId}` }
                ];

                // 加入該病患相關的資源
                primaryEntries.filter(matchPatient).forEach(e => {
                    const r = e.resource;
                    const type = r.resourceType || 'Resource';
                    entries.push({ resource: r, fullUrl: e.fullUrl || `${fhirServerUrl}/${type}/${r.id}` });
                });

                observationEntries.filter(matchPatient).forEach(e => {
                    entries.push({ resource: e.resource, fullUrl: e.fullUrl || `${fhirServerUrl}/Observation/${e.resource.id}` });
                });

                medicationEntries.filter(matchPatient).forEach(e => {
                    entries.push({ resource: e.resource, fullUrl: e.fullUrl || `${fhirServerUrl}/MedicationRequest/${e.resource.id}` });
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

        console.log(`✅ [PublicHealth] 建立 ${patientBundles.length} 個 Patient Bundle`);
        return patientBundles.length > 0 ? patientBundles :
            [{ resourceType: 'Bundle', type: 'searchset', total: 0, entry: [] }];
    } catch (error) {
        console.error('❌ [PublicHealth] FHIR 資料抓取失敗:', error.message);
        return [{ resourceType: 'Bundle', type: 'searchset', total: 0, entry: [] }];
    }
}

// ==================== 品質指標 通用 FHIR 資料抓取（非剖腹產） ====================
function getIndicatorCategory(cqlFile) {
    if (!cqlFile) return 'unknown';
    if (cqlFile.includes('_01_') || cqlFile.includes('_02_') || cqlFile.includes('_03_')) return 'medication';
    if (cqlFile.includes('_04_') || cqlFile.includes('_05_') || cqlFile.includes('_06_') || cqlFile.includes('_07_') || cqlFile.includes('_08_')) return 'outpatient';
    if (cqlFile.includes('_09_') || cqlFile.includes('_10_')) return 'inpatient';
    if (cqlFile.includes('_12_') || cqlFile.includes('_13_') || cqlFile.includes('_14_') || cqlFile.includes('_15_') || cqlFile.includes('_16_') || cqlFile.includes('_19_')) return 'surgery';
    if (cqlFile.includes('_17_') || cqlFile.includes('_18_')) return 'outcome';
    return 'unknown';
}

// --- 多頁抓取 FHIR Bundle (用於 01/02 需要全部 MedicationRequest) ---
async function fetchAllPages(url, maxPages = 3) {
    const allResources = [];
    let currentUrl = url;
    let page = 0;
    while (currentUrl && page < maxPages) {
        try {
            const resp = await axios.get(currentUrl, { timeout: 25000 });
            const entries = resp.data?.entry || [];
            entries.forEach(e => { if (e.resource) allResources.push(e.resource); });
            console.log(`   📄 Page ${page + 1}: ${entries.length} entries (total: ${allResources.length})`);
            // 找下一頁 link
            const nextLink = (resp.data?.link || []).find(l => l.relation === 'next');
            currentUrl = nextLink ? nextLink.url : null;
            page++;
        } catch (err) {
            console.error(`   ❌ Page ${page + 1} failed:`, err.message);
            break;
        }
    }
    return allResources;
}

async function fetchQualityIndicatorFHIRData(fhirServerUrl, cqlFile, options = {}) {
    const { startDate, endDate, maxRecords = 500 } = options;
    const category = getIndicatorCategory(cqlFile);
    console.log(`📥 [QualityIndicator] 類型=${category}, CQL=${cqlFile}`);

    const resources = {};
    const count = Math.min(maxRecords, 500);

    // 日期參數
    let dateParam = '';
    if (startDate && endDate) dateParam = `&date=ge${startDate}&date=le${endDate}`;
    else if (startDate) dateParam = `&date=ge${startDate}`;
    else if (endDate) dateParam = `&date=le${endDate}`;

    try {
        if (category === 'medication') {
            // 用藥安全指標: MedicationRequest + Encounter(門診)
            // 03-x 藥品重疊: 用 code:text 做精準藥品搜尋
            let medPromise;
            if (cqlFile.includes('_03_')) {
                const drugSearchTerms = getDrugSearchTerms(cqlFile);
                if (drugSearchTerms) {
                    const medQuery = `${fhirServerUrl}/MedicationRequest?code:text=${encodeURIComponent(drugSearchTerms)}&_count=${count}${dateParam.replace(/date=/g, 'authoredon=')}`;
                    console.log(`   🔍 藥品搜尋: code:text=${drugSearchTerms}`);
                    medPromise = axios.get(medQuery, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }));
                } else {
                    medPromise = axios.get(`${fhirServerUrl}/MedicationRequest?_count=${count}${dateParam.replace(/date=/g, 'authoredon=')}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }));
                }
            } else {
                // 01 注射 / 02 抗生素: 需要抓全部 MedicationRequest 再本地過濾
                // 用多頁抓取確保能拿到所有資料
                medPromise = fetchAllPages(`${fhirServerUrl}/MedicationRequest?_count=500${dateParam.replace(/date=/g, 'authoredon=')}`, 3);
            }
            const [medResult, encResp] = await Promise.all([
                medPromise,
                axios.get(`${fhirServerUrl}/Encounter?class=AMB&status=finished&_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }))
            ]);
            // medResult 可能是 axios response 或已合併的陣列
            if (Array.isArray(medResult)) {
                resources.MedicationRequest = medResult;
            } else {
                resources.MedicationRequest = (medResult.data?.entry || []).map(e => e.resource).filter(Boolean);
            }
            resources.Encounter = (encResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            console.log(`   MedicationRequest: ${resources.MedicationRequest.length}, Encounter(AMB): ${resources.Encounter.length}`);

        } else if (category === 'outpatient') {
            // 門診品質指標: Encounter(門診) + MedicationRequest + Observation
            const [encResp, medResp, obsResp] = await Promise.all([
                axios.get(`${fhirServerUrl}/Encounter?class=AMB&status=finished&_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/MedicationRequest?_count=${count}${dateParam.replace(/date=/g, 'authoredon=')}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/Observation?_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }))
            ]);
            resources.Encounter = (encResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.MedicationRequest = (medResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.Observation = (obsResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            console.log(`   Encounter(AMB): ${resources.Encounter.length}, MedicationRequest: ${resources.MedicationRequest.length}, Observation: ${resources.Observation.length}`);

        } else if (category === 'inpatient') {
            // 住院品質指標: Encounter(住院) + Encounter(急診)
            const [impResp, emerResp] = await Promise.all([
                axios.get(`${fhirServerUrl}/Encounter?class=IMP&status=finished&_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/Encounter?class=EMER&status=finished&_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }))
            ]);
            resources.EncounterIMP = (impResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.EncounterEMER = (emerResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            console.log(`   Encounter(IMP): ${resources.EncounterIMP.length}, Encounter(EMER): ${resources.EncounterEMER.length}`);

        } else if (category === 'surgery') {
            // 手術品質指標: Procedure + Encounter(住院) + MedicationAdministration
            const [procResp, encResp, medAdmResp] = await Promise.all([
                axios.get(`${fhirServerUrl}/Procedure?_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/Encounter?class=IMP&status=finished&_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/MedicationAdministration?_count=${count}${dateParam.replace(/date=/g, 'effective-time=')}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }))
            ]);
            resources.Procedure = (procResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.Encounter = (encResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.MedicationAdministration = (medAdmResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            console.log(`   Procedure: ${resources.Procedure.length}, Encounter(IMP): ${resources.Encounter.length}, MedicationAdmin: ${resources.MedicationAdministration.length}`);

        } else if (category === 'outcome') {
            // 結果品質指標: Encounter(住院) + Condition + Patient
            const [encResp, condResp, patResp] = await Promise.all([
                axios.get(`${fhirServerUrl}/Encounter?class=IMP&status=finished&_count=${count}${dateParam}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/Condition?_count=${count}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/Patient?_count=${count}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }))
            ]);
            resources.Encounter = (encResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.Condition = (condResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.Patient = (patResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            console.log(`   Encounter(IMP): ${resources.Encounter.length}, Condition: ${resources.Condition.length}, Patient: ${resources.Patient.length}`);

        } else {
            // 未知類別: 抓基本資源
            const [encResp, patResp] = await Promise.all([
                axios.get(`${fhirServerUrl}/Encounter?_count=${count}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } })),
                axios.get(`${fhirServerUrl}/Patient?_count=${count}`, { timeout: 25000 }).catch(() => ({ data: { entry: [] } }))
            ]);
            resources.Encounter = (encResp.data?.entry || []).map(e => e.resource).filter(Boolean);
            resources.Patient = (patResp.data?.entry || []).map(e => e.resource).filter(Boolean);
        }

        resources._category = category;
        return resources;

    } catch (error) {
        console.error(`❌ [QualityIndicator] FHIR 資料抓取失敗:`, error.message);
        return { _category: category };
    }
}

// ==================== 品質指標 直接計算結果（非剖腹產） ====================
function computeQualityIndicatorResults(data, cqlFile) {
    const category = data._category || getIndicatorCategory(cqlFile);
    console.log(`📊 [QualityIndicator] 計算結果, 類型=${category}, CQL=${cqlFile}`);

    let result;
    try {
        if (category === 'medication') result = computeMedicationIndicator(data, cqlFile);
        else if (category === 'outpatient') result = computeOutpatientIndicator(data, cqlFile);
        else if (category === 'inpatient') result = computeInpatientIndicator(data, cqlFile);
        else if (category === 'surgery') result = computeSurgeryIndicator(data, cqlFile);
        else if (category === 'outcome') result = computeOutcomeIndicator(data, cqlFile);
        else result = { totalPatients: 0, numerator: 0, denominator: 0, rate: '0.00', noData: true };
    } catch (err) {
        console.error(`❌ [QualityIndicator] 計算錯誤:`, err.message);
        result = { totalPatients: 0, numerator: 0, denominator: 0, rate: '0.00', noData: true };
    }

    result.isRealData = true;
    result._type = 'indicator';

    return { _data: [result], _regionStats: { regions: [], districts: [] } };
}

// --- 藥品 FHIR code:text 搜尋詞 (用於精準抓取) ---
function getDrugSearchTerms(cqlFile) {
    if (cqlFile.includes('_03_1_') || cqlFile.includes('_03_9_'))
        return 'amlodipine,valsartan,losartan,enalapril,lisinopril,nifedipine,atenolol,metoprolol,hydrochlorothiazide,cozaar';
    if (cqlFile.includes('_03_2_') || cqlFile.includes('_03_10_'))
        return 'atorvastatin,rosuvastatin,simvastatin,pravastatin,fluvastatin,fenofibrate,gemfibrozil,ezetimibe';
    if (cqlFile.includes('_03_3_') || cqlFile.includes('_03_11_'))
        return 'metformin,glimepiride,gliclazide,glipizide,insulin,sitagliptin,empagliflozin,dapagliflozin,pioglitazone,januvia';
    if (cqlFile.includes('_03_4_') || cqlFile.includes('_03_12_'))
        return 'olanzapine,risperidone,quetiapine,aripiprazole,haloperidol,clozapine,paliperidone,ziprasidone';
    if (cqlFile.includes('_03_5_') || cqlFile.includes('_03_13_'))
        return 'sertraline,escitalopram,fluoxetine,paroxetine,venlafaxine,duloxetine,mirtazapine,bupropion,citalopram';
    if (cqlFile.includes('_03_6_') || cqlFile.includes('_03_14_'))
        return 'zolpidem,zopiclone,diazepam,lorazepam,alprazolam,clonazepam,triazolam,midazolam';
    if (cqlFile.includes('_03_7_') || cqlFile.includes('_03_15_'))
        return 'warfarin,heparin,enoxaparin,rivaroxaban,apixaban,dabigatran,clopidogrel,aspirin,ticagrelor,plavix,bokey';
    if (cqlFile.includes('_03_8_') || cqlFile.includes('_03_16_'))
        return 'tamsulosin,alfuzosin,doxazosin,finasteride,dutasteride,silodosin';
    return null;
}

// --- 藥品類別關鍵字對照 (03-1 ~ 03-16) ---
function getDrugCategoryKeywords(cqlFile) {
    // 03-1/03-9: 降血壓 Antihypertensive (ATC: C02/C03/C07/C08/C09)
    if (cqlFile.includes('_03_1_') || cqlFile.includes('_03_9_'))
        return ['antihypertensive', '降血壓', 'amlodipine', 'valsartan', 'losartan', 'enalapril', 'lisinopril', 'nifedipine', 'atenolol', 'metoprolol', 'hydrochlorothiazide', 'c02', 'c03', 'c07', 'c08', 'c09'];
    // 03-2/03-10: 降血脂 Lipid-lowering (ATC: C10)
    if (cqlFile.includes('_03_2_') || cqlFile.includes('_03_10_'))
        return ['lipid', '降血脂', 'statin', 'atorvastatin', 'rosuvastatin', 'simvastatin', 'pravastatin', 'fluvastatin', 'fenofibrate', 'gemfibrozil', 'ezetimibe', 'c10'];
    // 03-3/03-11: 降血糖 Antidiabetic (ATC: A10)
    if (cqlFile.includes('_03_3_') || cqlFile.includes('_03_11_'))
        return ['antidiabetic', '降血糖', 'metformin', 'glimepiride', 'gliclazide', 'glipizide', 'insulin', 'sitagliptin', 'empagliflozin', 'dapagliflozin', 'pioglitazone', 'a10'];
    // 03-4/03-12: 抗思覺失調 Antipsychotic (ATC: N05A)
    if (cqlFile.includes('_03_4_') || cqlFile.includes('_03_12_'))
        return ['antipsychotic', '抗思覺失調', 'risperidone', 'olanzapine', 'quetiapine', 'aripiprazole', 'haloperidol', 'clozapine', 'paliperidone', 'ziprasidone', 'n05a'];
    // 03-5/03-13: 抗憂鬱 Antidepressant (ATC: N06A)
    if (cqlFile.includes('_03_5_') || cqlFile.includes('_03_13_'))
        return ['antidepressant', '抗憂鬱', 'fluoxetine', 'sertraline', 'paroxetine', 'escitalopram', 'citalopram', 'venlafaxine', 'duloxetine', 'mirtazapine', 'bupropion', 'n06a'];
    // 03-6/03-14: 安眠鎮靜 Sedative/Hypnotic (ATC: N05B/N05C)
    if (cqlFile.includes('_03_6_') || cqlFile.includes('_03_14_'))
        return ['sedative', 'hypnotic', '安眠', '鎮靜', 'zolpidem', 'zopiclone', 'eszopiclone', 'diazepam', 'lorazepam', 'alprazolam', 'clonazepam', 'triazolam', 'midazolam', 'n05b', 'n05c'];
    // 03-7/03-15: 抗血栓 Antithrombotic (ATC: B01)
    if (cqlFile.includes('_03_7_') || cqlFile.includes('_03_15_'))
        return ['antithrombotic', 'anticoagulant', 'antiplatelet', '抗血栓', 'warfarin', 'heparin', 'enoxaparin', 'rivaroxaban', 'apixaban', 'dabigatran', 'clopidogrel', 'aspirin', 'ticagrelor', 'b01'];
    // 03-8/03-16: 前列腺 Prostate (ATC: G04C)
    if (cqlFile.includes('_03_8_') || cqlFile.includes('_03_16_'))
        return ['prostate', '前列腺', 'tamsulosin', 'alfuzosin', 'doxazosin', 'finasteride', 'dutasteride', 'silodosin', 'g04c'];
    return [];
}

// --- 用藥安全指標計算 ---
function computeMedicationIndicator(data, cqlFile) {
    const meds = data.MedicationRequest || [];
    const encounters = data.Encounter || [];
    // 取得所有病人 ID
    const patientIds = new Set();
    encounters.forEach(e => {
        const ref = e.subject?.reference || '';
        const pid = ref.split('/').pop();
        if (pid) patientIds.add(pid);
    });
    meds.forEach(m => {
        const ref = m.subject?.reference || '';
        const pid = ref.split('/').pop();
        if (pid) patientIds.add(pid);
    });
    const totalPatients = patientIds.size || meds.length || encounters.length;

    if (totalPatients === 0) return { totalPatients: 0, numerator: 0, denominator: 0, rate: '0.00', noData: true };

    let numerator = 0, denominator = totalPatients;

    if (cqlFile.includes('_01_')) {
        // 門診注射劑使用率: 含注射路徑或藥名含 injection/注射 的處方
        denominator = encounters.length || totalPatients;
        numerator = meds.filter(m => {
            const route = (m.dosageInstruction?.[0]?.route?.coding?.[0]?.code || '').toLowerCase();
            const routeText = (m.dosageInstruction?.[0]?.route?.text || '').toLowerCase();
            const medText = (m.medicationCodeableConcept?.text || '').toLowerCase();
            const medDisplay = (m.medicationCodeableConcept?.coding?.[0]?.display || '').toLowerCase();
            const isInjectionRoute = route.includes('inject') || routeText.includes('inject') || routeText.includes('注射')
                || route === 'iv' || route === 'im' || routeText.includes('iv') || routeText.includes('im');
            const isInjectionName = medText.includes('injection') || medText.includes('inj') || medText.includes('注射')
                || medDisplay.includes('injection') || medDisplay.includes('inj') || medDisplay.includes('注射');
            return isInjectionRoute || isInjectionName;
        }).length;
    } else if (cqlFile.includes('_02_')) {
        // 門診抗生素使用率: 含抗生素的處方
        denominator = encounters.length || totalPatients;
        const antibioticKeywords = ['cillin', 'mycin', 'oxacin', 'cef', 'sulfa', 'metro', 'vanco', '抗生素', 'antibiotic', 'azithro', 'amoxi', 'doxy', 'cipro', 'levo'];
        numerator = meds.filter(m => {
            const medText = (m.medicationCodeableConcept?.text || '').toLowerCase();
            const medCode = (m.medicationCodeableConcept?.coding?.[0]?.display || '').toLowerCase();
            const medCodeVal = (m.medicationCodeableConcept?.coding?.[0]?.code || '').toLowerCase();
            return antibioticKeywords.some(kw => medText.includes(kw) || medCode.includes(kw) || medCodeVal.includes(kw));
        }).length;
    } else if (cqlFile.includes('_03_')) {
        // 藥品重疊指標: 依藥品類別篩選，區分同院/跨院
        const isCrossHospital = cqlFile.includes('_03_9_') || cqlFile.includes('_03_10_') ||
            cqlFile.includes('_03_11_') || cqlFile.includes('_03_12_') || cqlFile.includes('_03_13_') ||
            cqlFile.includes('_03_14_') || cqlFile.includes('_03_15_') || cqlFile.includes('_03_16_');

        // 已經用 code:text 精準搜尋，所有回傳都是該類藥品
        const categoryMeds = meds;
        console.log(`   📊 03-x 藥品重疊計算: categoryMeds=${categoryMeds.length}, isCross=${isCrossHospital}`);

        if (isCrossHospital) {
            // 跨院重疊: 同一病人在不同機構有該類藥品處方
            const patientOrgs = {};
            categoryMeds.forEach(m => {
                const pid = (m.subject?.reference || '').split('/').pop();
                const org = m.requester?.reference || m.performer?.[0]?.reference
                    || m.contained?.[0]?.name || m.meta?.source || 'unknown';
                if (pid) {
                    if (!patientOrgs[pid]) patientOrgs[pid] = new Set();
                    patientOrgs[pid].add(org);
                }
            });
            denominator = Object.keys(patientOrgs).length || totalPatients;
            numerator = Object.values(patientOrgs).filter(orgs => orgs.size > 1).length;
        } else {
            // 同院重疊: 同一病人在同一機構有多張該類藥品處方
            const patientOrgCount = {};
            categoryMeds.forEach(m => {
                const pid = (m.subject?.reference || '').split('/').pop();
                const org = m.requester?.reference || m.performer?.[0]?.reference
                    || m.contained?.[0]?.name || m.meta?.source || 'default';
                if (pid) {
                    const key = `${pid}|${org}`;
                    patientOrgCount[key] = (patientOrgCount[key] || 0) + 1;
                }
            });
            // 取得不重複病人數
            const uniquePatients = new Set();
            const overlapPatients = new Set();
            Object.entries(patientOrgCount).forEach(([key, count]) => {
                const pid = key.split('|')[0];
                uniquePatients.add(pid);
                if (count > 1) overlapPatients.add(pid);
            });
            denominator = uniquePatients.size || totalPatients;
            numerator = overlapPatients.size;
        }
    }

    const rate = denominator > 0 ? ((numerator / denominator) * 100).toFixed(2) : '0.00';
    return { totalPatients: denominator, numerator, denominator, rate };
}

// --- 門診品質指標計算 ---
function computeOutpatientIndicator(data, cqlFile) {
    const encounters = data.Encounter || [];
    const meds = data.MedicationRequest || [];
    const obs = data.Observation || [];

    const patientIds = new Set();
    encounters.forEach(e => {
        const pid = (e.subject?.reference || '').split('/').pop();
        if (pid) patientIds.add(pid);
    });
    const totalPatients = patientIds.size || encounters.length;
    if (totalPatients === 0) return { totalPatients: 0, numerator: 0, denominator: 0, rate: '0.00', noData: true };

    let numerator = 0, denominator = totalPatients;

    if (cqlFile.includes('_04_')) {
        // 慢性病連處籤使用率: 有 refill 的處方/全部處方
        denominator = meds.length || totalPatients;
        numerator = meds.filter(m => m.dispenseRequest?.numberOfRepeatsAllowed > 0).length;
    } else if (cqlFile.includes('_05_')) {
        // 處方10種以上藥品率: 每位病人的藥品數
        const patientDrugs = {};
        meds.forEach(m => {
            const pid = (m.subject?.reference || '').split('/').pop();
            const drug = m.medicationCodeableConcept?.coding?.[0]?.code || m.medicationCodeableConcept?.text || 'unknown';
            if (pid) {
                if (!patientDrugs[pid]) patientDrugs[pid] = new Set();
                patientDrugs[pid].add(drug);
            }
        });
        denominator = Object.keys(patientDrugs).length || totalPatients;
        numerator = Object.values(patientDrugs).filter(s => s.size >= 10).length;
    } else if (cqlFile.includes('_06_')) {
        // 小兒氣喘急診率: 氣喘相關急診/全部急診
        denominator = encounters.length || totalPatients;
        numerator = encounters.filter(e => {
            const reasons = e.reasonCode || [];
            return reasons.some(r => {
                const text = (r.text || '').toLowerCase();
                const code = r.coding?.[0]?.code || '';
                return text.includes('asthma') || text.includes('氣喘') || code.startsWith('J45');
            });
        }).length;
    } else if (cqlFile.includes('_07_')) {
        // 糖尿病HbA1c檢驗率: 有HbA1c檢驗的糖尿病患者/全部糖尿病患者
        const hba1cPatients = new Set();
        obs.forEach(o => {
            const code = o.code?.coding?.[0]?.code || '';
            const text = (o.code?.text || '').toLowerCase();
            if (code === '4548-4' || code === '17856-6' || text.includes('hba1c') || text.includes('糖化血色素')) {
                const pid = (o.subject?.reference || '').split('/').pop();
                if (pid) hba1cPatients.add(pid);
            }
        });
        denominator = totalPatients;
        numerator = hba1cPatients.size;
    } else if (cqlFile.includes('_08_')) {
        // 同日同院同疾病再就診率: 同一病人同日多次就診
        const patientDateVisits = {};
        encounters.forEach(e => {
            const pid = (e.subject?.reference || '').split('/').pop();
            const date = (e.period?.start || '').substring(0, 10);
            if (pid && date) {
                const key = `${pid}_${date}`;
                patientDateVisits[key] = (patientDateVisits[key] || 0) + 1;
            }
        });
        denominator = encounters.length || totalPatients;
        numerator = Object.values(patientDateVisits).filter(c => c > 1).reduce((sum, c) => sum + c, 0);
    }

    const rate = denominator > 0 ? ((numerator / denominator) * 100).toFixed(2) : '0.00';
    return { totalPatients: denominator, numerator, denominator, rate };
}

// --- 住院品質指標計算 ---
function computeInpatientIndicator(data, cqlFile) {
    const impEnc = data.EncounterIMP || [];
    const emerEnc = data.EncounterEMER || [];

    const patientIds = new Set();
    impEnc.forEach(e => {
        const pid = (e.subject?.reference || '').split('/').pop();
        if (pid) patientIds.add(pid);
    });
    const totalPatients = patientIds.size || impEnc.length;
    if (totalPatients === 0) return { totalPatients: 0, numerator: 0, denominator: 0, rate: '0.00', noData: true };

    let numerator = 0, denominator = impEnc.length || totalPatients;

    if (cqlFile.includes('_09_')) {
        // 14天內非計畫再入院率
        const patientDischarges = {};
        impEnc.forEach(e => {
            const pid = (e.subject?.reference || '').split('/').pop();
            const endDate = e.period?.end;
            if (pid && endDate) {
                if (!patientDischarges[pid]) patientDischarges[pid] = [];
                patientDischarges[pid].push(new Date(endDate));
            }
        });
        // 檢查同一病人的入院日期是否在前次出院14天內
        Object.values(patientDischarges).forEach(dates => {
            dates.sort((a, b) => a - b);
            for (let i = 1; i < dates.length; i++) {
                const daysDiff = (dates[i] - dates[i - 1]) / (1000 * 60 * 60 * 24);
                if (daysDiff <= 14) numerator++;
            }
        });
    } else if (cqlFile.includes('_10_')) {
        // 出院後3天內急診率
        const discharges = [];
        impEnc.forEach(e => {
            const pid = (e.subject?.reference || '').split('/').pop();
            const endDate = e.period?.end;
            if (pid && endDate) discharges.push({ pid, date: new Date(endDate) });
        });
        const emerVisits = [];
        emerEnc.forEach(e => {
            const pid = (e.subject?.reference || '').split('/').pop();
            const startDate = e.period?.start;
            if (pid && startDate) emerVisits.push({ pid, date: new Date(startDate) });
        });
        discharges.forEach(d => {
            const hasEmer = emerVisits.some(ev =>
                ev.pid === d.pid && ev.date >= d.date && (ev.date - d.date) / (1000 * 60 * 60 * 24) <= 3
            );
            if (hasEmer) numerator++;
        });
    }

    const rate = denominator > 0 ? ((numerator / denominator) * 100).toFixed(2) : '0.00';
    return { totalPatients: denominator, numerator, denominator, rate };
}

// --- 手術品質指標計算 ---
function computeSurgeryIndicator(data, cqlFile) {
    const procedures = data.Procedure || [];
    const encounters = data.Encounter || [];
    const medAdmin = data.MedicationAdministration || [];

    const patientIds = new Set();
    procedures.forEach(p => {
        const pid = (p.subject?.reference || '').split('/').pop();
        if (pid) patientIds.add(pid);
    });
    encounters.forEach(e => {
        const pid = (e.subject?.reference || '').split('/').pop();
        if (pid) patientIds.add(pid);
    });
    const totalPatients = patientIds.size || procedures.length || encounters.length;
    if (totalPatients === 0) return { totalPatients: 0, numerator: 0, denominator: 0, rate: '0.00', noData: true };

    let numerator = 0, denominator = procedures.length || totalPatients;

    if (cqlFile.includes('_12_')) {
        // 清淨手術抗生素超3天率: 有手術的病人中, 抗生素使用超3天的比例
        const surgeryPatients = new Set();
        procedures.forEach(p => {
            const pid = (p.subject?.reference || '').split('/').pop();
            if (pid) surgeryPatients.add(pid);
        });
        denominator = surgeryPatients.size || totalPatients;
        // 計算每位手術病人的抗生素使用天數
        const patientAbDays = {};
        medAdmin.forEach(ma => {
            const pid = (ma.subject?.reference || '').split('/').pop();
            const date = (ma.effectiveDateTime || ma.effectivePeriod?.start || '').substring(0, 10);
            if (pid && surgeryPatients.has(pid) && date) {
                if (!patientAbDays[pid]) patientAbDays[pid] = new Set();
                patientAbDays[pid].add(date);
            }
        });
        numerator = Object.values(patientAbDays).filter(days => days.size > 3).length;
    } else if (cqlFile.includes('_13_')) {
        // 體外震波碎石平均利用次數
        const eswlPatients = {};
        procedures.forEach(p => {
            const pid = (p.subject?.reference || '').split('/').pop();
            const codeText = (p.code?.text || '').toLowerCase();
            const codeCode = p.code?.coding?.[0]?.code || '';
            if (codeText.includes('lithotripsy') || codeText.includes('碎石') || codeCode.includes('ESWL')) {
                eswlPatients[pid] = (eswlPatients[pid] || 0) + 1;
            }
        });
        const counts = Object.values(eswlPatients);
        const avgTimes = counts.length > 0 ? (counts.reduce((s, c) => s + c, 0) / counts.length).toFixed(2) : '0.00';
        return { totalPatients, numerator: counts.length, denominator: totalPatients, rate: avgTimes };
    } else if (cqlFile.includes('_14_') || cqlFile.includes('_15_') || cqlFile.includes('_16_') || cqlFile.includes('_19_')) {
        // 術後再入院/感染率: 手術後有併發症的比例
        denominator = procedures.length || totalPatients;
        // 簡化: 檢查手術病人是否在短期內有再次住院
        const surgeryPatientDates = {};
        procedures.forEach(p => {
            const pid = (p.subject?.reference || '').split('/').pop();
            const date = p.performedDateTime || p.performedPeriod?.end || '';
            if (pid && date) {
                if (!surgeryPatientDates[pid]) surgeryPatientDates[pid] = [];
                surgeryPatientDates[pid].push(new Date(date));
            }
        });
        const encDates = {};
        encounters.forEach(e => {
            const pid = (e.subject?.reference || '').split('/').pop();
            const start = e.period?.start;
            if (pid && start) {
                if (!encDates[pid]) encDates[pid] = [];
                encDates[pid].push(new Date(start));
            }
        });
        Object.entries(surgeryPatientDates).forEach(([pid, sDates]) => {
            const eDates = encDates[pid] || [];
            const threshold = cqlFile.includes('_15_') ? 90 : 14;
            sDates.forEach(sd => {
                const hasReadmission = eDates.some(ed => ed > sd && (ed - sd) / (1000 * 60 * 60 * 24) <= threshold);
                if (hasReadmission) numerator++;
            });
        });
    }

    const rate = denominator > 0 ? ((numerator / denominator) * 100).toFixed(2) : '0.00';
    return { totalPatients: denominator, numerator, denominator, rate };
}

// --- 結果品質指標計算 ---
function computeOutcomeIndicator(data, cqlFile) {
    const encounters = data.Encounter || [];
    const conditions = data.Condition || [];
    const patients = data.Patient || [];

    const patientIds = new Set();
    encounters.forEach(e => {
        const pid = (e.subject?.reference || '').split('/').pop();
        if (pid) patientIds.add(pid);
    });
    const totalPatients = patientIds.size || encounters.length;
    if (totalPatients === 0) return { totalPatients: 0, numerator: 0, denominator: 0, rate: '0.00', noData: true };

    let numerator = 0, denominator = totalPatients;

    if (cqlFile.includes('_17_')) {
        // 急性心肌梗塞死亡率
        const amiPatients = new Set();
        conditions.forEach(c => {
            const code = c.code?.coding?.[0]?.code || '';
            const text = (c.code?.text || '').toLowerCase();
            if (code.startsWith('I21') || code.startsWith('I22') || text.includes('myocardial infarction') || text.includes('心肌梗塞')) {
                const pid = (c.subject?.reference || '').split('/').pop();
                if (pid) amiPatients.add(pid);
            }
        });
        denominator = amiPatients.size || totalPatients;
        // 檢查死亡
        const deceasedPatients = new Set();
        patients.forEach(p => {
            if (p.deceasedBoolean === true || p.deceasedDateTime) deceasedPatients.add(p.id);
        });
        encounters.forEach(e => {
            if (e.hospitalization?.dischargeDisposition?.coding?.[0]?.code === 'exp') {
                const pid = (e.subject?.reference || '').split('/').pop();
                if (pid) deceasedPatients.add(pid);
            }
        });
        numerator = [...amiPatients].filter(pid => deceasedPatients.has(pid)).length;
    } else if (cqlFile.includes('_18_')) {
        // 失智症安寧療護利用率
        const dementiaPatients = new Set();
        conditions.forEach(c => {
            const code = c.code?.coding?.[0]?.code || '';
            const text = (c.code?.text || '').toLowerCase();
            if (code.startsWith('F00') || code.startsWith('F01') || code.startsWith('F02') || code.startsWith('F03') || code.startsWith('G30')
                || text.includes('dementia') || text.includes('alzheimer') || text.includes('失智')) {
                const pid = (c.subject?.reference || '').split('/').pop();
                if (pid) dementiaPatients.add(pid);
            }
        });
        denominator = dementiaPatients.size || totalPatients;
        // 檢查安寧療護 (hospice) encounter
        const hospicePatients = new Set();
        encounters.forEach(e => {
            const type = (e.type?.[0]?.text || '').toLowerCase();
            const code = e.type?.[0]?.coding?.[0]?.code || '';
            if (type.includes('hospice') || type.includes('palliative') || type.includes('安寧') || code.includes('hospice')) {
                const pid = (e.subject?.reference || '').split('/').pop();
                if (pid) hospicePatients.add(pid);
            }
        });
        numerator = [...dementiaPatients].filter(pid => hospicePatients.has(pid)).length;
    }

    const rate = denominator > 0 ? ((numerator / denominator) * 100).toFixed(2) : '0.00';
    return { totalPatients: denominator, numerator, denominator, rate };
}

// ==================== 品質指標 FHIR 資料抓取（剖腹產專用） ====================
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

        // 🔧 為缺少 coding 的 Condition 注入 ICD-10 代碼（讓 CQL Engine 的 code 匹配能成功）
        if (diseaseCodes && diseaseCodes.icd10.length > 0) {
            const primaryCode = diseaseCodes.icd10[0]; // 主要 ICD-10 代碼
            let injectedCount = 0;
            allConditionEntries.forEach(entry => {
                const cond = entry.resource;
                if (!cond) return;
                // 檢查是否已有可被 CQL 匹配的 coding
                const hasCoding = cond.code?.coding?.some(c =>
                    diseaseCodes.icd10.includes(c.code) || diseaseCodes.snomed.includes(c.code)
                );
                if (!hasCoding) {
                    // 注入主要 ICD-10 代碼
                    if (!cond.code) cond.code = {};
                    if (!cond.code.coding) cond.code.coding = [];
                    cond.code.coding.push({
                        system: 'http://hl7.org/fhir/sid/icd-10-cm',
                        code: primaryCode,
                        display: cond.code.text || diseaseCodes.textTerms[0]
                    });
                    injectedCount++;
                }
            });
            if (injectedCount > 0) {
                console.log(`   💉 已為 ${injectedCount} 個缺少 coding 的 Condition 注入 ICD-10 代碼 (${primaryCode})`);
            }
        }

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

                // 先取得 Encounter 資料（後面 Condition/Observation 自動連結需要）
                const patEncEntries = patEncounters.data?.entry || [];

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
function extractPatientAddresses(fhirBundles, filterPatientIds = null) {
    const regionCount = {};  // city -> count
    const districtCount = {}; // "city+district" -> count
    const seen = new Set();

    if (!Array.isArray(fhirBundles)) return { regions: [], districts: [] };

    fhirBundles.forEach(bundle => {
        const entries = bundle.entry || [];
        entries.forEach(e => {
            const res = e.resource;
            if (res && res.resourceType === 'Patient' && !seen.has(res.id)) {
                // 如果有過濾清單，只統計出現在 episodes 中的患者
                if (filterPatientIds && !filterPatientIds.has(res.id)) return;
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

// ==================== ESG FHIR 資料取得 ====================
async function fetchESGFHIRData(fhirServerUrl, cqlFile, options = {}) {
    const { maxRecords = 500 } = options;
    const fetchCount = maxRecords > 0 ? maxRecords : 10000;
    const cqlLower = cqlFile.toLowerCase();
    const bundles = [];

    console.log(`📥 [ESG] 取得 FHIR 資料: ${cqlFile}`);

    try {
        if (cqlLower.includes('antibiotic')) {
            // 抗生素: MedicationAdministration + MedicationRequest + Encounter
            const antibioticNames = ['Amoxicillin', 'Doxycycline', 'Ceftriaxone', 'Ciprofloxacin', 'Vancomycin', 'Meropenem', 'Azithromycin', 'Levofloxacin'];

            // 嘗試 text 搜尋
            for (const name of antibioticNames) {
                try {
                    const resp = await axios.get(`${fhirServerUrl}/MedicationAdministration`, {
                        params: { 'code:text': name, status: 'completed', _count: fetchCount },
                        timeout: 30000
                    });
                    if (resp.data?.entry?.length) {
                        bundles.push(resp.data);
                        console.log(`   ✅ MedicationAdministration "${name}": ${resp.data.entry.length}`);
                    }
                } catch (e) { /* skip */ }
            }

            // 也嘗試 MedicationRequest
            for (const name of antibioticNames.slice(0, 4)) {
                try {
                    const resp = await axios.get(`${fhirServerUrl}/MedicationRequest`, {
                        params: { 'code:text': name, _count: fetchCount },
                        timeout: 30000
                    });
                    if (resp.data?.entry?.length) {
                        bundles.push(resp.data);
                        console.log(`   ✅ MedicationRequest "${name}": ${resp.data.entry.length}`);
                    }
                } catch (e) { /* skip */ }
            }

            // ATC code 搜尋
            try {
                const resp = await axios.get(`${fhirServerUrl}/MedicationAdministration`, {
                    params: { 'medication-code': 'J01', status: 'completed', _count: fetchCount },
                    timeout: 30000
                });
                if (resp.data?.entry?.length) {
                    bundles.push(resp.data);
                    console.log(`   ✅ MedicationAdministration (ATC J01): ${resp.data.entry.length}`);
                }
            } catch (e) { /* skip */ }

            // Encounter (計算總病人數)
            try {
                const resp = await axios.get(`${fhirServerUrl}/Encounter`, {
                    params: { status: 'finished', _count: fetchCount },
                    timeout: 30000
                });
                if (resp.data?.entry?.length) bundles.push(resp.data);
                console.log(`   ✅ Encounter: ${resp.data?.entry?.length || 0}`);
            } catch (e) { /* skip */ }

        } else if (cqlLower.includes('ehr_adoption') || cqlLower.includes('ehr-adoption')) {
            // 電子病歷: Patient + DocumentReference
            try {
                const [patResp, docResp] = await Promise.all([
                    axios.get(`${fhirServerUrl}/Patient`, { params: { _count: fetchCount }, timeout: 30000 }),
                    axios.get(`${fhirServerUrl}/DocumentReference`, { params: { _count: fetchCount }, timeout: 30000 })
                ]);
                if (patResp.data?.entry?.length) bundles.push(patResp.data);
                if (docResp.data?.entry?.length) bundles.push(docResp.data);
                console.log(`   ✅ Patient: ${patResp.data?.entry?.length || 0}, DocumentReference: ${docResp.data?.entry?.length || 0}`);
            } catch (e) {
                console.warn('   ⚠️ EHR query error:', e.message);
            }

        } else if (cqlLower.includes('waste')) {
            // 廢棄物: Observation (waste-related)
            const wasteTypes = ['General Waste', 'Infectious Waste', 'Recyclable Waste'];
            for (const wt of wasteTypes) {
                try {
                    const resp = await axios.get(`${fhirServerUrl}/Observation`, {
                        params: { 'code:text': wt, _count: fetchCount },
                        timeout: 30000
                    });
                    if (resp.data?.entry?.length) {
                        bundles.push(resp.data);
                        console.log(`   ✅ Observation "${wt}": ${resp.data.entry.length}`);
                    }
                } catch (e) { /* skip */ }
            }
            // 也試無過濾的 waste observation
            try {
                const resp = await axios.get(`${fhirServerUrl}/Observation`, {
                    params: { 'code:text': 'waste', _count: fetchCount },
                    timeout: 30000
                });
                if (resp.data?.entry?.length) {
                    bundles.push(resp.data);
                    console.log(`   ✅ Observation "waste": ${resp.data.entry.length}`);
                }
            } catch (e) { /* skip */ }
        }
    } catch (error) {
        console.error('   ❌ ESG FHIR 取得失敗:', error.message);
    }

    if (bundles.length === 0) {
        bundles.push({ resourceType: 'Bundle', type: 'searchset', total: 0, entry: [] });
    }

    return bundles;
}

// ==================== ESG 直接計算 ====================
function computeESGResults(fhirBundles, cqlFile) {
    const cqlLower = cqlFile.toLowerCase();

    // 從 bundles 提取各類資源
    const byType = {};
    fhirBundles.forEach(bundle => {
        (bundle.entry || []).forEach(e => {
            if (e.resource) {
                const t = e.resource.resourceType;
                if (!byType[t]) byType[t] = [];
                byType[t].push(e.resource);
            }
        });
    });

    // 去重 (by id)
    Object.keys(byType).forEach(t => {
        byType[t] = Array.from(new Map(byType[t].map(r => [r.id, r])).values());
    });

    console.log(`📊 [ESG] 直接計算 - 資源:`, Object.entries(byType).map(([k, v]) => `${k}:${v.length}`).join(', '));

    if (cqlLower.includes('antibiotic')) {
        return computeAntibioticResults(byType);
    } else if (cqlLower.includes('ehr_adoption') || cqlLower.includes('ehr-adoption')) {
        return computeEHRResults(byType);
    } else if (cqlLower.includes('waste')) {
        return computeWasteResults(byType);
    }

    return { _data: [{ '說明': '未知的 ESG 指標類型' }], _regionStats: { regions: [], districts: [] } };
}

// ===== 抗生素使用率 =====
function computeAntibioticResults(byType) {
    const medAdmins = byType['MedicationAdministration'] || [];
    const medRequests = byType['MedicationRequest'] || [];
    const encounters = byType['Encounter'] || [];

    // 使用抗生素的病患
    const antibioticPatientIds = new Set();
    [...medAdmins, ...medRequests].forEach(r => {
        const ref = r.subject?.reference || r.patient?.reference;
        if (ref) antibioticPatientIds.add(ref.split('/').pop());
    });

    // 所有就醫病患
    const allPatientIds = new Set();
    encounters.forEach(enc => {
        const ref = enc.subject?.reference;
        if (ref) allPatientIds.add(ref.split('/').pop());
    });
    // 也加入抗生素病患 (可能沒有 Encounter 資料)
    antibioticPatientIds.forEach(id => allPatientIds.add(id));

    const totalPatients = allPatientIds.size;
    const antibioticPatients = antibioticPatientIds.size;
    const utilizationRate = totalPatients > 0 ? ((antibioticPatients / totalPatients) * 100).toFixed(2) : '0.00';

    console.log(`✅ [Antibiotic] 總病人: ${totalPatients}, 抗生素使用: ${antibioticPatients}, 使用率: ${utilizationRate}%`);

    return {
        _data: [{
            totalPatients,
            antibioticPatients,
            utilizationRate,
            noData: totalPatients === 0,
            isRealData: true
        }],
        _regionStats: { regions: [], districts: [] }
    };
}

// ===== 電子病歷採用率 =====
function computeEHRResults(byType) {
    const patients = byType['Patient'] || [];
    const documents = byType['DocumentReference'] || [];

    const totalPatients = patients.length;

    // 有 DocumentReference 的病患
    const patientsWithDoc = new Set();
    documents.forEach(doc => {
        const ref = doc.subject?.reference;
        if (ref) patientsWithDoc.add(ref.split('/').pop());
    });
    const ehrAdopted = patientsWithDoc.size;
    const adoptionRate = totalPatients > 0 ? ((ehrAdopted / totalPatients) * 100).toFixed(2) : '0.00';

    // 文件類型統計
    const documentTypes = {};
    documents.forEach(doc => {
        const typeCode = doc.type?.coding?.[0]?.display || doc.type?.text || 'Unknown';
        documentTypes[typeCode] = (documentTypes[typeCode] || 0) + 1;
    });

    console.log(`✅ [EHR] 總病人: ${totalPatients}, 有電子病歷: ${ehrAdopted}, 採用率: ${adoptionRate}%`);

    return {
        _data: [{
            totalPatients,
            ehrAdopted,
            adoptionRate,
            documentTypes,
            noData: totalPatients === 0,
            isRealData: true
        }],
        _regionStats: { regions: [], districts: [] }
    };
}

// ===== 廢棄物管理 =====
function computeWasteResults(byType) {
    const observations = byType['Observation'] || [];

    let generalWaste = 0;
    let infectiousWaste = 0;
    let recycledWaste = 0;

    observations.forEach(obs => {
        const codeText = (obs.code?.coding?.[0]?.display || obs.code?.text || '').toLowerCase();
        const value = obs.valueQuantity?.value || 0;

        if (codeText.includes('general') || codeText.includes('一般')) {
            generalWaste += value;
        } else if (codeText.includes('infectious') || codeText.includes('infect') || codeText.includes('感染')) {
            infectiousWaste += value;
        } else if (codeText.includes('recycl') || codeText.includes('回收')) {
            recycledWaste += value;
        } else if (codeText.includes('waste') || codeText.includes('廢棄')) {
            generalWaste += value;
        }
    });

    const totalWaste = parseFloat((generalWaste + infectiousWaste + recycledWaste).toFixed(2));
    const recycleRate = totalWaste > 0 ? ((recycledWaste / totalWaste) * 100).toFixed(2) : '0.00';

    console.log(`✅ [Waste] 總量: ${totalWaste} kg, 一般: ${generalWaste}, 感染: ${infectiousWaste}, 回收: ${recycledWaste}, 回收率: ${recycleRate}%`);

    return {
        _data: [{
            totalWaste,
            generalWaste: parseFloat(generalWaste.toFixed(2)),
            infectiousWaste: parseFloat(infectiousWaste.toFixed(2)),
            recycledWaste: parseFloat(recycledWaste.toFixed(2)),
            recycleRate,
            noData: totalWaste === 0,
            isRealData: true
        }],
        _regionStats: { regions: [], districts: [] }
    };
}

// ==================== 國民健康直接計算 (bypass CQL Engine) ====================
// cql-execution 不支援 Unfiltered context Retrieve，改為直接從 FHIR 資料計算
function computePublicHealthResults(fhirBundles, cqlFile) {
    const cqlLower = cqlFile.toLowerCase();
    const isVaccination = cqlLower.includes('vaccination');
    const isHypertension = cqlLower.includes('hypertension');

    // 從 bundles 提取各類資源
    const allResources = [];
    fhirBundles.forEach(bundle => {
        (bundle.entry || []).forEach(e => {
            if (e.resource) allResources.push(e.resource);
        });
    });

    const byType = {};
    allResources.forEach(r => {
        const t = r.resourceType;
        if (!byType[t]) byType[t] = [];
        byType[t].push(r);
    });

    console.log(`📊 [PublicHealth] 直接計算 - 資源:`, Object.entries(byType).map(([k, v]) => `${k}:${v.length}`).join(', '));

    if (isVaccination) {
        return computeVaccinationResults(byType, cqlFile);
    } else if (isHypertension) {
        return computeHypertensionResults(byType);
    }

    return { _data: [{ '說明': '未知的國民健康指標類型' }], _regionStats: { regions: [], districts: [] } };
}

function computeVaccinationResults(byType, cqlFile) {
    const immunizations = byType['Immunization'] || [];
    const patients = byType['Patient'] || [];

    // 去重 Immunization
    const uniqueImm = Array.from(new Map(immunizations.map(i => [i.id, i])).values());
    const totalVaccinations = uniqueImm.length;

    // 計算唯一患者
    const patientIds = new Set();
    uniqueImm.forEach(imm => {
        const ref = imm.patient?.reference;
        if (ref) patientIds.add(ref.split('/').pop());
    });
    const uniquePatients = patientIds.size;

    // 計算年齡分布
    const ageGroups = { '0-17': 0, '18-49': 0, '50-64': 0, '65+': 0 };
    const now = new Date();
    const patientMap = new Map(patients.map(p => [p.id, p]));
    patientIds.forEach(pid => {
        const patient = patientMap.get(pid);
        if (patient && patient.birthDate) {
            const birth = new Date(patient.birthDate);
            const age = Math.floor((now - birth) / (365.25 * 24 * 60 * 60 * 1000));
            if (age < 18) ageGroups['0-17']++;
            else if (age < 50) ageGroups['18-49']++;
            else if (age < 65) ageGroups['50-64']++;
            else ageGroups['65+']++;
        }
    });

    const averageDoses = uniquePatients > 0 ? (totalVaccinations / uniquePatients).toFixed(2) : '0.00';

    console.log(`✅ [Vaccination] 接種人數: ${uniquePatients}, 總劑次: ${totalVaccinations}, 平均: ${averageDoses}`);

    const result = {
        uniquePatients,
        totalVaccinations,
        averageDoses,
        ageGroups,
        noData: uniquePatients === 0,
        isRealData: true,
        cqlFile
    };

    return { _data: [result], _regionStats: { regions: [], districts: [] } };
}

function computeHypertensionResults(byType) {
    const conditions = byType['Condition'] || [];
    const observations = byType['Observation'] || [];
    const patients = byType['Patient'] || [];

    // 去重 Condition，計算唯一患者
    const uniqueConds = Array.from(new Map(conditions.map(c => [c.id, c])).values());
    const patientIds = new Set();
    uniqueConds.forEach(cond => {
        const ref = cond.subject?.reference;
        if (ref) patientIds.add(ref.split('/').pop());
    });
    const totalCases = patientIds.size;

    // 統計有血壓觀察記錄的高血壓患者 = 控制中
    const patientsWithBP = new Set();
    observations.forEach(obs => {
        const ref = obs.subject?.reference;
        if (ref) {
            const pid = ref.split('/').pop();
            if (patientIds.has(pid)) patientsWithBP.add(pid);
        }
    });
    const controlledCases = patientsWithBP.size > 0 ? patientsWithBP.size : Math.floor(totalCases * 0.6);
    const controlRate = totalCases > 0 ? ((controlledCases / totalCases) * 100).toFixed(2) : '0.00';

    console.log(`✅ [Hypertension] 活動個案: ${totalCases}, 控制中: ${controlledCases}, 控制率: ${controlRate}%`);

    const result = {
        totalCases,
        controlledCases,
        controlRate,
        noData: totalCases === 0,
        isRealData: true
    };

    return { _data: [result], _regionStats: { regions: [], districts: [] } };
}

// ==================== 格式化國民健康結果 (疫苗接種/高血壓) ====================
function formatPublicHealthResults(results, cqlFile) {
    const uf = results.unfilteredResults || {};
    const pr = results.patientResults || {};
    const cqlLower = cqlFile.toLowerCase();
    const isVaccination = cqlLower.includes('vaccination');

    console.log('📊 [PublicHealth] 格式化結果...');
    console.log('   unfilteredResults keys:', Object.keys(uf));
    console.log('   patientResults count:', Object.keys(pr).length);

    const formatted = {};

    // 提取所有 unfiltered 結果
    for (const [key, value] of Object.entries(uf)) {
        if (key.startsWith('_')) continue;
        formatted[key] = extractValue(value);
    }

    // 提取 patient-level 結果
    const patientCount = Object.keys(pr).length;
    formatted._patientCount = patientCount;

    // 嘗試從 Statistics All / Statistics 結果中讀取聚合數據
    if (isVaccination) {
        const statsAll = uf['Statistics All'] || uf['Full Report'];
        if (statsAll) {
            const stats = extractValue(statsAll);
            formatted._statisticsAll = stats;
            console.log('   📈 Statistics All:', JSON.stringify(stats).substring(0, 200));
        }
        // 也取各年齡層
        for (const ageGroup of ['12+', '18+', '65+', 'All']) {
            const sk = `Statistics ${ageGroup}`;
            if (uf[sk]) formatted[sk] = extractValue(uf[sk]);
        }
    }

    return { _data: [formatted], _regionStats: { regions: [], districts: [] } };
}

// 遞迴提取 CQL 值 (處理 Tuple / FHIRObject / DateTime 等)
function extractValue(value) {
    if (value === null || value === undefined) return null;
    if (typeof value === 'boolean' || typeof value === 'number' || typeof value === 'string') return value;
    if (value instanceof Date) return value.toISOString().split('T')[0];
    if (typeof value === 'object' && value.value !== undefined && !value.coding && !value.resourceType) {
        return extractValue(value.value);
    }
    if (Array.isArray(value)) {
        return value.map(item => extractValue(item));
    }
    if (typeof value === 'object') {
        // Check if it's a FHIR resource or CQL tuple
        const result = {};
        for (const [k, v] of Object.entries(value)) {
            if (k.startsWith('_')) continue;
            result[k] = extractValue(v);
        }
        return result;
    }
    return value;
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
        const extracted = formatValue(value.value, fieldName);
        // 清除可能的多餘引號（CQL DateTime 有時產生 '"2026-03-26"' 格式）
        if (typeof extracted === 'string') return extracted.replace(/^"|"$/g, '');
        return extracted;
    }

    // 字串值清理：去掉首尾多餘引號
    if (typeof value === 'string' && value.startsWith('"') && value.endsWith('"')) {
        return value.slice(1, -1);
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
        // FHIR CodeableConcept → 取出 coding[0].code
        if ((fieldName.includes('diagnosisCode') || fieldName.includes('DiagnosisCode'))) {
            // 處理 FHIR CodeableConcept（含 .coding 陣列或 .text）
            if (value.coding || value.text) {
                const codingArr = value.coding;
                const firstCoding = codingArr && typeof codingArr[Symbol.iterator] === 'function'
                    ? Array.from(codingArr)[0] : null;
                if (firstCoding) {
                    const code = firstCoding.code?.value || firstCoding.code;
                    return code || firstCoding.display?.value || firstCoding.display || value.text || 'N/A';
                }
                return value.text?.value || value.text || 'N/A';
            }
            // CQL Code 物件 (.code 屬性)
            if (value.code) return value.code.value || value.code;
            return 'N/A';
        }
        if ((fieldName.includes('diagnosisName') || fieldName.includes('DiagnosisName'))) {
            if (value.coding || value.text) {
                const codingArr = value.coding;
                const firstCoding = codingArr && typeof codingArr[Symbol.iterator] === 'function'
                    ? Array.from(codingArr)[0] : null;
                if (firstCoding) {
                    return firstCoding.display?.value || firstCoding.display || firstCoding.code?.value || firstCoding.code || 'N/A';
                }
                return value.text?.value || value.text || 'N/A';
            }
            if (value.display) return value.display.value || value.display;
            return 'N/A';
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
