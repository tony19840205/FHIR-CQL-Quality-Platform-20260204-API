// ========== 醫療品質指標後端 API ==========
// 用途：計算分子分母，減輕前端負擔；匯出去識別化數據至民眾網頁
// 使用方法：node server.js

const express = require('express');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const cqlService = require('./cql-service');
const gradleConverter = require('./gradle-converter');
const app = express();
const PORT = process.env.PORT || 3000;

// 首頁：使用 "index - API.html" 作為入口
app.get('/', (req, res) => {
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.sendFile(path.join(__dirname, '..', 'index - API.html'));
});

// 提供靜態前端檔案（HTML/CSS/JS）— 禁止CDN快取JS/HTML以確保更新即時生效
app.use(express.static(path.join(__dirname, '..'), {
    setHeaders: (res, filePath) => {
        if (filePath.endsWith('.js') || filePath.endsWith('.html')) {
            res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
            res.setHeader('Pragma', 'no-cache');
            res.setHeader('Expires', '0');
        }
    }
}));

// 允許跨域（前端才能呼叫）
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
});

// 解析JSON（提高 limit 以容納完整儀表板資料）
app.use(express.json({ limit: '20mb' }));

// 記憶體快取：最近一次上傳的儀表板資料
let _dashboardCache = null;

// ========== 健康檢查（測試用） ==========
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: '後端運作中',
        time: new Date().toISOString() 
    });
});

// ========== 核心API：計算指標 ==========
app.post('/api/calculate', async (req, res) => {
    try {
        const { indicatorId, fhirServer, quarter } = req.body;
        
        console.log(`📊 開始計算指標: ${indicatorId}, 季度: ${quarter}`);
        
        // 根據不同指標呼叫對應的計算函數
        let result;
        
        if (indicatorId === 'indicator-01') {
            result = await calculateIndicator01(fhirServer, quarter);
        } else if (indicatorId === 'indicator-02') {
            result = await calculateIndicator02(fhirServer, quarter);
        } else {
            result = await calculateGeneric(fhirServer, quarter);
        }
        
        console.log(`✅ 計算完成:`, result);
        res.json(result);
        
    } catch (error) {
        console.error('❌ 計算失敗:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ========== 指標01：門診注射劑使用率 ==========
async function calculateIndicator01(fhirServer, quarter) {
    // 步驟1: 查詢門診資料
    const encountersUrl = `${fhirServer}/Encounter?class=AMB&status=finished&_count=2000`;
    const encountersRes = await axios.get(encountersUrl);
    const encounters = encountersRes.data.entry || [];
    
    console.log(`  📦 查到 ${encounters.length} 個門診`);
    
    // 步驟2: 查詢用藥資料
    const medsUrl = `${fhirServer}/MedicationRequest?status=completed&_count=2000`;
    const medsRes = await axios.get(medsUrl);
    const medications = medsRes.data.entry || [];
    
    console.log(`  💊 查到 ${medications.length} 個用藥`);
    
    // 步驟3: 建立有效門診ID集合
    const validEncounterIds = new Set();
    for (const encEntry of encounters) {
        const enc = encEntry.resource;
        const encounterType = enc.class?.code;
        
        // 排除急診、門診手術
        if (encounterType !== '02' && encounterType !== '03') {
            validEncounterIds.add(enc.id);
        }
    }
    
    // 步驟4: 計算分子分母
    let injectionCount = 0;  // 分子
    let totalDrugCount = 0;  // 分母
    
    for (const medEntry of medications.entry) {
        const med = medEntry.resource;
        
        // 檢查是否屬於有效門診
        const encounterRef = med.encounter?.reference;
        if (!encounterRef) continue;
        
        const encounterId = encounterRef.split('/').pop();
        if (!validEncounterIds.has(encounterId)) continue;
        
        totalDrugCount++;
        
        // 判斷是否為注射劑（10碼且第8碼='2'）
        const codings = med.medicationCodeableConcept?.coding || [];
        for (const coding of codings) {
            const code = coding.code || '';
            if (code.length === 10 && code.charAt(7) === '2') {
                injectionCount++;
                break;
            }
        }
    }
    
    // 步驟5: 計算比率
    const rate = totalDrugCount > 0 
        ? ((injectionCount / totalDrugCount) * 100).toFixed(2) 
        : '0.00';
    
    return {
        numerator: injectionCount,
        denominator: totalDrugCount,
        rate: rate,
        quarter: quarter
    };
}

// ========== 指標02：門診抗生素使用率 ==========
async function calculateIndicator02(fhirServer, quarter) {
    // 查詢門診
    const encountersUrl = `${fhirServer}/Encounter?class=AMB&status=finished&_count=2000`;
    const encountersRes = await axios.get(encountersUrl);
    const encounters = encountersRes.data.entry || [];
    
    // 查詢用藥
    const medsUrl = `${fhirServer}/MedicationRequest?status=completed&_count=2000`;
    const medsRes = await axios.get(medsUrl);
    const medications = medsRes.data.entry || [];
    
    // 建立有效門診ID
    const validEncounterIds = new Set();
    for (const encEntry of encounters) {
        const enc = encEntry.resource;
        const encounterType = enc.class?.code;
        if (encounterType !== '02' && encounterType !== '03') {
            validEncounterIds.add(enc.id);
        }
    }
    
    // 計算分子分母
    let antibioticCount = 0;  // 分子（抗生素）
    let totalDrugCount = 0;   // 分母
    
    for (const medEntry of medications.entry) {
        const med = medEntry.resource;
        
        const encounterRef = med.encounter?.reference;
        if (!encounterRef) continue;
        
        const encounterId = encounterRef.split('/').pop();
        if (!validEncounterIds.has(encounterId)) continue;
        
        totalDrugCount++;
        
        // 判斷是否為抗生素（ATC碼前3碼='J01'）
        const codings = med.medicationCodeableConcept?.coding || [];
        for (const coding of codings) {
            const atcCode = coding.code || '';
            if (atcCode.startsWith('J01')) {
                antibioticCount++;
                break;
            }
        }
    }
    
    const rate = totalDrugCount > 0 
        ? ((antibioticCount / totalDrugCount) * 100).toFixed(2) 
        : '0.00';
    
    return {
        numerator: antibioticCount,
        denominator: totalDrugCount,
        rate: rate,
        quarter: quarter
    };
}

// ========== 通用指標計算（其他39項） ==========
async function calculateGeneric(fhirServer, quarter) {
    // 簡化版：直接回傳示範資料
    return {
        numerator: 0,
        denominator: 0,
        rate: '0.00',
        quarter: quarter,
        message: '尚未實作此指標的後端運算'
    };
}

// ========== 即時看板讀取資料 ==========
// 優先順序：1) 記憶體快取  2) GitHub raw (public-health-dashboard repo)
app.get('/api/export-dashboard', async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    if (_dashboardCache) {
        return res.json(_dashboardCache);
    }
    try {
        const rawUrl = 'https://raw.githubusercontent.com/tony19840205/public-health-dashboard/main/public/data/dashboard-data.json';
        const r = await axios.get(rawUrl, { timeout: 8000 });
        if (r.data && typeof r.data === 'object') {
            _dashboardCache = r.data;
            return res.json(r.data);
        }
        return res.status(404).json({ error: 'no data' });
    } catch (e) {
        return res.status(404).json({ error: 'no data', detail: e.message });
    }
});

// ========== 匯出去識別化數據至民眾網頁 ==========
app.post('/api/export-public-data', async (req, res) => {
    try {
        const data = req.body;
        if (!data || typeof data !== 'object') {
            return res.status(400).json({ error: '無效的數據格式' });
        }

        // 是否要重置歷史累加（用 ?reset=1 或 body.reset === true）
        const resetMode = req.query.reset === '1' || req.query.reset === 'true' || data.reset === true;
        if (resetMode) {
            console.log('🔄 收到重置指令：跳過歷史累加，直接覆蓋');
        }

        // ── 累加合併：讀現有遠端資料，把本次數據加到歷史總和上 ──
        async function _fetchExistingRemote(githubToken) {
            // 優先用 GitHub API（同 token），失敗再用 raw（免 token、有快取延遲）
            try {
                const apiUrl = 'https://api.github.com/repos/tony19840205/public-health-dashboard/contents/public/data/dashboard-data.json';
                const r = await axios.get(apiUrl, {
                    headers: { 'Authorization': `token ${githubToken}`, 'Accept': 'application/vnd.github.v3+json' },
                    timeout: 8000,
                });
                const sha = r.data.sha;
                const json = JSON.parse(Buffer.from(r.data.content, 'base64').toString('utf-8'));
                return { sha, json };
            } catch (_) {
                try {
                    const raw = await axios.get('https://raw.githubusercontent.com/tony19840205/public-health-dashboard/main/public/data/dashboard-data.json', { timeout: 8000 });
                    return { sha: null, json: raw.data };
                } catch (_e) {
                    return { sha: null, json: null };
                }
            }
        }

        function _num(v) { const n = Number(v); return Number.isFinite(n) ? n : 0; }
        function _mergeArrayById(curArr, prevArr, sumFields, latestFields, recomputeRate) {
            if (!Array.isArray(prevArr) || prevArr.length === 0) return curArr;
            if (!Array.isArray(curArr)) return prevArr;
            const prevMap = {};
            for (const p of prevArr) if (p && p.id) prevMap[p.id] = p;
            return curArr.map(item => {
                const old = prevMap[item.id];
                if (!old) return item;
                const merged = { ...item };
                // 數字欄位：累加
                for (const f of sumFields) {
                    const a = _num(old[f]);
                    const b = _num(merged[f]);
                    if (a || b) merged[f] = a + b;
                }
                // 非數字 / 比率：本次有就用本次，沒有就保留舊值
                for (const f of latestFields) {
                    if (merged[f] == null && old[f] != null) merged[f] = old[f];
                }
                // cityData：逐縣市累加
                if (old.cityData && typeof old.cityData === 'object') {
                    const cd = { ...(merged.cityData || {}) };
                    for (const k of Object.keys(old.cityData)) {
                        cd[k] = _num(cd[k]) + _num(old.cityData[k]);
                    }
                    merged.cityData = cd;
                }
                // 重算比率（numerator/denominator）
                if (recomputeRate && _num(merged.denominator) > 0) {
                    merged.rate = parseFloat((_num(merged.numerator) / _num(merged.denominator) * 100).toFixed(2));
                }
                return merged;
            });
        }
        function _accumulate(current, prev) {
            if (!prev || typeof prev !== 'object') return current;
            const out = { ...current };
            out.diseaseItems      = _mergeArrayById(current.diseaseItems,      prev.diseaseItems,      ['patients', 'encounters'], [], false);
            out.healthIndicators  = _mergeArrayById(current.healthIndicators,  prev.healthIndicators,  ['count'], ['rate'], false);
            out.esgIndicators     = _mergeArrayById(current.esgIndicators,     prev.esgIndicators,     ['count'], ['rate'], false);
            out.qualityIndicators = _mergeArrayById(current.qualityIndicators, prev.qualityIndicators, ['numerator', 'denominator'], [], true);
            out.uploadCount       = _num(prev.uploadCount) + 1;
            out.firstUploadedAt   = prev.firstUploadedAt || prev.exportedAt || current.exportedAt;
            return out;
        }

        const githubToken = process.env.GITHUB_TOKEN;

        // 取出歷史資料 → 累加（reset 模式下直接覆蓋）
        let mergedData = data;
        let existingSha = null;
        if (githubToken) {
            const existing = await _fetchExistingRemote(githubToken);
            existingSha = existing.sha;
            if (resetMode) {
                mergedData = { ...data, uploadCount: 1, firstUploadedAt: data.exportedAt };
            } else if (existing.json) {
                mergedData = _accumulate(data, existing.json);
                console.log('🧮 已累加歷史數據（uploadCount=' + (mergedData.uploadCount || 1) + '）');
            } else {
                mergedData = { ..._accumulate(data, {}), uploadCount: 1, firstUploadedAt: data.exportedAt };
            }
        }

        // 寫入記憶體快取，供即時看板 GET /api/export-dashboard 立即取用
        _dashboardCache = mergedData;

        const jsonContent = JSON.stringify(mergedData, null, 2);

        // 策略一：透過 GitHub API 推送（Render 或任何有 GITHUB_TOKEN 的環境）
        if (githubToken) {
            const owner = 'tony19840205';
            const repo = 'public-health-dashboard';
            const filePath = 'public/data/dashboard-data.json';
            const apiUrl = `https://api.github.com/repos/${owner}/${repo}/contents/${filePath}`;
            const content = Buffer.from(jsonContent).toString('base64');

            const body = {
                message: `data: 控制台累加匯出（第 ${mergedData.uploadCount || 1} 次） ${new Date().toISOString().slice(0, 16)}`,
                content,
                branch: 'main',
            };
            if (existingSha) body.sha = existingSha;

            await axios.put(apiUrl, body, {
                headers: {
                    'Authorization': `token ${githubToken}`,
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json',
                },
            });

            console.log('✅ 已透過 GitHub API 推送累加後的民眾網頁資料');
            console.log(`   匯出時間: ${mergedData.exportedAt}  累計次數: ${mergedData.uploadCount || 1}`);
            return res.json({
                success: true,
                method: 'github-api',
                message: '數據已累加推送至 GitHub，民眾網頁將自動更新',
                exportedAt: mergedData.exportedAt,
                uploadCount: mergedData.uploadCount || 1,
            });
        }

        // 策略二：本地開發環境寫入
        const isLocal = ['localhost', '127.0.0.1'].includes(req.hostname);
        if (isLocal) {
            const publicSitePath = path.resolve(__dirname, '..', '..', 'public-health-dashboard', 'public', 'data');
            fs.mkdirSync(publicSitePath, { recursive: true });
            const localPath = path.join(publicSitePath, 'dashboard-data.json');
            fs.writeFileSync(localPath, jsonContent, 'utf-8');
            console.log(`✅ 去識別化數據已匯出至: ${localPath}`);
            return res.json({
                success: true,
                method: 'local-file',
                message: '數據已寫入本地民眾網頁資料夾',
                path: localPath,
                exportedAt: data.exportedAt,
            });
        }

        // 非本地且無 GITHUB_TOKEN → 回傳錯誤，讓前端改用瀏覽器端推送
        return res.status(501).json({
            error: 'GITHUB_TOKEN 未設定，請使用瀏覽器端 GitHub API 推送',
            needsClientPush: true,
        });
    } catch (error) {
        console.error('❌ 匯出失敗:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ========== CQL Engine API：列出可用 ELM 檔案 ==========
app.get('/api/cql/available', async (req, res) => {
    try {
        const available = await cqlService.listAvailableELM();
        res.json({ success: true, files: available });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ========== CQL Engine API：載入 ELM JSON ==========
app.post('/api/convert-elm', async (req, res) => {
    try {
        const { cqlFile } = req.body;
        if (!cqlFile) {
            return res.status(400).json({ success: false, error: 'Missing cqlFile parameter' });
        }
        const elm = await cqlService.loadELM(cqlFile);
        res.json({ success: true, elm: elm });
    } catch (error) {
        console.error('❌ 載入 ELM 失敗:', error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});

// ========== CQL Engine API：執行 CQL 查詢 ==========
app.post('/api/execute-cql', async (req, res) => {
    try {
        let { elm, fhirServerUrl, cqlFile, startDate, endDate, maxRecords } = req.body;
        if (!fhirServerUrl) {
            return res.status(400).json({ success: false, error: 'Missing required parameter: fhirServerUrl' });
        }
        if (!elm && !cqlFile) {
            return res.status(400).json({ success: false, error: 'Missing required parameter: elm or cqlFile' });
        }

        // 如果只提供 cqlFile，從 backend/elm/ 載入 ELM JSON
        if (!elm && cqlFile) {
            elm = await cqlService.loadELM(cqlFile);
        }

        const startTime = Date.now();
        const rawResults = await cqlService.executeCQL(elm, fhirServerUrl, cqlFile, {
            startDate, endDate, maxRecords: maxRecords || 200
        });
        const executionTime = Date.now() - startTime;

        // executeCQL 可能回傳 { _data, _regionStats } 或直接回傳陣列/物件
        let results, regionStats;
        if (rawResults && rawResults._data) {
            results = rawResults._data;
            regionStats = rawResults._regionStats || null;
        } else {
            results = rawResults;
            regionStats = null;
        }

        const isIndicator = results && results._type === 'indicator';

        const response = {
            success: true,
            results: results,
            resultType: isIndicator ? 'indicator' : 'standard',
            executionMetadata: {
                engine: 'cql-execution',
                version: '2.4.0',
                elmLibrary: elm.library?.identifier?.id || 'Unknown',
                executionTime: `${executionTime}ms`,
                fhirVersion: 'FHIR 4.0.1',
                timestamp: new Date().toISOString()
            }
        };
        if (regionStats) response.regionStats = regionStats;

        res.json(response);
    } catch (error) {
        console.error('❌ CQL 執行失敗:', error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});

// ========== Gradle CQL→ELM 轉換 API ==========

// 檢查 Gradle 環境
app.get('/api/gradle/status', async (req, res) => {
    try {
        const status = await gradleConverter.checkGradleEnvironment();
        res.json({ success: true, ...status });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 列出所有 CQL 源碼檔案
app.get('/api/cql/sources', async (req, res) => {
    try {
        const files = await gradleConverter.listCQLFiles();
        res.json({ success: true, count: files.length, files: files });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 執行 Gradle 全量轉換 (CQL→ELM)
app.post('/api/gradle/convert-all', async (req, res) => {
    try {
        const logs = [];
        const result = await gradleConverter.convertCQLWithGradle({
            onProgress: (msg) => logs.push(msg)
        });
        res.json({ success: true, ...result, logs: logs });
    } catch (error) {
        console.error('❌ Gradle 轉換失敗:', error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});

// 執行 Gradle 單檔轉換
app.post('/api/gradle/convert-single', async (req, res) => {
    try {
        const { cqlFile } = req.body;
        if (!cqlFile) {
            return res.status(400).json({ success: false, error: 'Missing cqlFile parameter' });
        }
        // 防止路徑遍歷
        if (cqlFile.includes('..') || cqlFile.includes('/') || cqlFile.includes('\\')) {
            return res.status(400).json({ success: false, error: 'Invalid file name' });
        }
        const logs = [];
        const result = await gradleConverter.convertSingleCQL(cqlFile, (msg) => logs.push(msg));
        res.json({ success: true, ...result, logs: logs });
    } catch (error) {
        console.error('❌ 單檔轉換失敗:', error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});

// ========== 啟動伺服器 ==========
app.listen(PORT, '0.0.0.0', () => {
    console.log('');
    console.log('╔════════════════════════════════════════════════════╗');
    console.log('║   醫療品質指標後端 API - 已啟動                   ║');
    console.log('╠════════════════════════════════════════════════════╣');
    console.log(`║   🌐 網址: http://localhost:${PORT}                  ║`);
    console.log('║   📊 計算API: POST /api/calculate                 ║');
    console.log('║   🧠 CQL引擎: POST /api/execute-cql              ║');
    console.log('║   📋 ELM載入: POST /api/convert-elm               ║');
    console.log('║   📁 可用ELM: GET /api/cql/available              ║');
    console.log('║   � Gradle轉換: POST /api/gradle/convert-all    ║');
    console.log('║   🔧 單檔轉換: POST /api/gradle/convert-single   ║');
    console.log('║   📂 CQL源碼: GET /api/cql/sources               ║');
    console.log('║   ⚙️  Gradle狀態: GET /api/gradle/status          ║');
    console.log('║   �💚 健康檢查: GET /health                        ║');
    console.log('║   📁 靜態檔案: /* (專案根目錄)                     ║');
    console.log('╚════════════════════════════════════════════════════╝');
    console.log('');
    console.log('✅ 後端運作中，按 Ctrl+C 停止');
    console.log('');
});
