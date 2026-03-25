// ========== 醫療品質指標後端 API ==========
// 用途：計算分子分母，減輕前端負擔；匯出去識別化數據至民眾網頁
// 使用方法：node server.js

const express = require('express');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// 提供靜態前端檔案（HTML/CSS/JS）
app.use(express.static(path.join(__dirname, '..')));

// 允許跨域（前端才能呼叫）
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
});

// 解析JSON
app.use(express.json());

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

// ========== 匯出去識別化數據至民眾網頁 ==========
app.post('/api/export-public-data', (req, res) => {
    try {
        const data = req.body;
        if (!data || typeof data !== 'object') {
            return res.status(400).json({ error: '無效的數據格式' });
        }

        // 目標路徑：public-health-dashboard/public/data/dashboard-data.json
        const publicSitePath = path.resolve(__dirname, '..', '..', 'public-health-dashboard', 'public', 'data');

        // 確保目錄存在
        fs.mkdirSync(publicSitePath, { recursive: true });

        const filePath = path.join(publicSitePath, 'dashboard-data.json');
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');

        console.log(`✅ 去識別化數據已匯出至: ${filePath}`);
        console.log(`   匯出時間: ${data.exportedAt}`);
        console.log(`   來源頁面: ${data.source}`);

        res.json({
            success: true,
            message: '數據已匯出至民眾網頁',
            path: filePath,
            exportedAt: data.exportedAt,
        });
    } catch (error) {
        console.error('❌ 匯出失敗:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ========== 啟動伺服器 ==========
app.listen(PORT, () => {
    console.log('');
    console.log('╔════════════════════════════════════════════════════╗');
    console.log('║   醫療品質指標後端 API - 已啟動                   ║');
    console.log('╠════════════════════════════════════════════════════╣');
    console.log(`║   🌐 網址: http://localhost:${PORT}                  ║`);
    console.log('║   📊 計算API: POST /api/calculate                 ║');
    console.log('║   💚 健康檢查: GET /health                        ║');
    console.log('║   📁 靜態檔案: /* (專案根目錄)                     ║');
    console.log('╚════════════════════════════════════════════════════╝');
    console.log('');
    console.log('✅ 後端運作中，按 Ctrl+C 停止');
    console.log('');
});
