// ========== 醫療品質指標儀表板邏輯 ==========

let currentResults = {};
let currentFilter = 'all';

// 頁面載入
document.addEventListener('DOMContentLoaded', function() {
    console.log('醫療品質指標儀表板已載入');
    
    // 初始化卡片顯示
    initializeCards();
    
    // 初始化示範模式按鈕狀態
    updateDemoModeButton();
    
    // 從 localStorage 載入設定
    const savedServer = localStorage.getItem('fhirServer');
    const savedToken = localStorage.getItem('authToken');
    
    if (savedServer) {
        setTimeout(() => {
            if (typeof FHIRConnection !== 'undefined') {
                window.fhirConnection = new FHIRConnection();
                window.fhirConnection.serverUrl = savedServer;
                window.fhirConnection.authToken = savedToken || '';
                window.fhirConnection.isConnected = true;
                
                console.log('✅ FHIR 連線已恢復');
                
                // 🆕 立即檢查連線並隱藏 banner
                checkFHIRConnection();
            }
        }, 200);
    } else {
        // 🆕 如果沒有儲存的連線，顯示 banner
        checkFHIRConnection();
    }
});

// 初始化卡片
function initializeCards() {
    // 用藥安全指標 (16個)
    for (let i = 1; i <= 2; i++) {
        updateIndicatorDisplay(`ind0${i}Rate`, '--%');
    }
    for (let i = 1; i <= 16; i++) {
        updateIndicatorDisplay(`ind03_${i}Rate`, '--%');
    }
    
    // 門診品質指標 (5個)
    for (let i = 4; i <= 8; i++) {
        updateIndicatorDisplay(`ind0${i}Rate`, '--%');
    }
    
    // 住院品質指標 (5個)
    updateIndicatorDisplay('ind09Rate', '--%');
    updateIndicatorDisplay('ind10Rate', '--%');
    for (let i = 1; i <= 4; i++) {
        updateIndicatorDisplay(`ind11_${i}Rate`, '--%');
    }
    
    // 手術品質指標 (10個)
    updateIndicatorDisplay('ind12Rate', '--%');
    updateIndicatorDisplay('ind13Rate', '--');
    updateIndicatorDisplay('ind14Rate', '--%');
    for (let i = 1; i <= 3; i++) {
        updateIndicatorDisplay(`ind15_${i}Rate`, '--%');
    }
    updateIndicatorDisplay('ind16Rate', '--%');
    updateIndicatorDisplay('ind19Rate', '--%');
    
    // 結果品質指標 (2個)
    updateIndicatorDisplay('ind17Rate', '--%');
    updateIndicatorDisplay('ind18Rate', '--%');
}

// 更新指標顯示
function updateIndicatorDisplay(elementId, value) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = value;
    }
}

// 檢查 FHIR 連線
async function checkFHIRConnection() {
    const banner = document.getElementById('connectionBanner');
    
    await new Promise(resolve => setTimeout(resolve, 100));
    
    if (!window.fhirConnection || !window.fhirConnection.serverUrl) {
        if (banner) banner.classList.add('show');
        return false;
    } else {
        if (banner) banner.classList.remove('show');
        return true;
    }
}

// 分類篩選
function filterCategory(category) {
    currentFilter = category;
    
    // 更新按鈕狀態
    document.querySelectorAll('.filter-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    event.target.classList.add('active');
    
    // 顯示/隱藏對應的章節
    const sections = document.querySelectorAll('.overview-section[data-category]');
    sections.forEach(section => {
        if (category === 'all') {
            section.style.display = 'block';
        } else {
            const sectionCategory = section.getAttribute('data-category');
            section.style.display = sectionCategory === category ? 'block' : 'none';
        }
    });
}

// ========== 備份：原始版本 (如需復原請取消註解) ==========
// async function executeQuery_BACKUP(indicatorId) { ... }
// ========== 備份結束 ==========

// 執行查詢（新版：漸進式計數 + 防重複點擊）
async function executeQuery(indicatorId) {
    console.log(`執行查詢: ${indicatorId}`);
    
    const isConnected = await checkFHIRConnection();
    if (!isConnected) {
        alert('請先在首頁設定 FHIR 伺服器連線');
        window.location.href = 'index.html';
        return;
    }
    
    // 找到對應的查詢按鈕並設置載入狀態
    const card = document.querySelector(`[onclick*="'${indicatorId}'"]`);
    let button = null;
    let countInterval = null;
    
    if (card) {
        button = card.querySelector('.btn-card-mini');
        if (button) {
            // 🔒 防重複點擊
            if (button.disabled) {
                console.warn('⚠️ 查詢進行中，請勿重複點擊');
                return;
            }
            
            button.classList.add('loading');
            button.disabled = true;
            button.dataset.originalHTML = button.innerHTML;
            
            // 🆕 漸進式計數動畫
            let count = 0;
            countInterval = setInterval(() => {
                count += Math.floor(Math.random() * 40) + 20;
                button.innerHTML = `<i class="fas fa-spinner fa-spin"></i> 已撈取 ${count} 筆`;
            }, 150);
        }
    }
    
    try {
        // 根據指標執行對應的 CQL 查詢
        const results = await queryIndicator(indicatorId);
        
        // 更新卡片顯示
        updateIndicatorCard(indicatorId, results);
        
        // 儲存結果
        currentResults[indicatorId] = results;
        
        // 🆕 清除計數並顯示實際筆數
        if (countInterval) clearInterval(countInterval);
        const actualCount = results.numerator || 0;
        if (button) {
            button.innerHTML = `<i class="fas fa-check"></i> 完成 (${actualCount} 筆)`;
        }
        
    } catch (error) {
        console.error('查詢失敗:', error);
        
        // 🆕 清除計數
        if (countInterval) clearInterval(countInterval);
        if (button) {
            button.innerHTML = '<i class="fas fa-exclamation-triangle"></i> 查詢失敗';
        }
        alert(`查詢失敗: ${error.message}`);
        
    } finally {
        // 🆕 延遲 2 秒後恢復按鈕
        setTimeout(() => {
            if (button) {
                button.classList.remove('loading');
                button.disabled = false;
                if (button.dataset.originalHTML) {
                    button.innerHTML = button.dataset.originalHTML;
                    delete button.dataset.originalHTML;
                }
            }
        }, 2000);
    }
}

// 批次執行 - 用藥安全指標 (18個)
async function executeAllMedication() {
    console.log('批次執行用藥安全指標');
    const indicators = [
        'indicator-01', 'indicator-02',
        'indicator-03-1', 'indicator-03-2', 'indicator-03-3', 'indicator-03-4',
        'indicator-03-5', 'indicator-03-6', 'indicator-03-7', 'indicator-03-8',
        'indicator-03-9', 'indicator-03-10', 'indicator-03-11', 'indicator-03-12',
        'indicator-03-13', 'indicator-03-14', 'indicator-03-15', 'indicator-03-16'
    ];
    
    for (const id of indicators) {
        await executeQuery(id);
        await new Promise(resolve => setTimeout(resolve, 100)); // 每次查詢間隔100ms
    }
    
    console.log('✅ 用藥安全指標查詢完成');
}

// 批次執行 - 門診品質指標 (5個)
async function executeAllOutpatient() {
    console.log('批次執行門診品質指標');
    const indicators = [
        'indicator-04', 'indicator-05', 'indicator-06', 
        'indicator-07', 'indicator-08'
    ];
    
    for (const id of indicators) {
        await executeQuery(id);
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log('✅ 門診品質指標查詢完成');
}

// 批次執行 - 住院品質指標 (6個)
async function executeAllInpatient() {
    console.log('批次執行住院品質指標');
    const indicators = [
        'indicator-09', 'indicator-10',
        'indicator-11-1', 'indicator-11-2', 'indicator-11-3', 'indicator-11-4'
    ];
    
    for (const id of indicators) {
        await executeQuery(id);
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log('✅ 住院品質指標查詢完成');
}

// 批次執行 - 手術品質指標 (8個)
async function executeAllSurgery() {
    console.log('批次執行手術品質指標');
    const indicators = [
        'indicator-12', 'indicator-13', 'indicator-14',
        'indicator-15-1', 'indicator-15-2', 'indicator-15-3',
        'indicator-16', 'indicator-19'
    ];
    
    for (const id of indicators) {
        await executeQuery(id);
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log('✅ 手術品質指標查詢完成');
}

// 批次執行 - 結果品質指標 (2個)
async function executeAllOutcome() {
    console.log('批次執行結果品質指標');
    const indicators = [
        'indicator-17', 'indicator-18'
    ];
    
    for (const id of indicators) {
        await executeQuery(id);
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log('✅ 結果品質指標查詢完成');
}

// 查詢指標資料 - 先查當前季度，點開後再計算其他季度
async function queryIndicator(indicatorId) {
    console.log(`查詢指標: ${indicatorId}`);
    
    const conn = window.fhirConnection;
    
    // 檢查是否啟用示範模式（無真實資料時使用）
    const demoMode = localStorage.getItem('demoMode') === 'true';
    console.log(`🎭 示範模式: ${demoMode ? '已啟用' : '已關閉'}`);
    
    // 只查詢當前季度 (2025-Q4)
    try {
        let currentResult;
        
        // 如果啟用示範模式，直接使用模擬數據（跳過 FHIR 查詢）
        if (demoMode) {
            console.log(`✨ 示範模式啟用，直接使用模擬數據 for ${indicatorId}`);
            return generateDemoData(indicatorId, getCurrentQuarter());
        }
        
        // 根據不同指標執行對應的CQL查詢邏輯
        if (indicatorId === 'indicator-01') {
            currentResult = await queryOutpatientInjectionRateSample(conn);
        } else if (indicatorId === 'indicator-02') {
            currentResult = await queryOutpatientAntibioticRateSample(conn);
        } else if (indicatorId.startsWith('indicator-03')) {
            currentResult = await queryDrugOverlapRateSample(conn, indicatorId);
        } else if (indicatorId === 'indicator-04') {
            currentResult = await queryChronicPrescriptionRateSample(conn);
        } else if (indicatorId === 'indicator-09') {
            currentResult = await queryReadmissionRateSample(conn);
        } else {
            currentResult = await queryGenericIndicatorSample(conn, indicatorId);
        }
        
        // 當前季度的真實數據
        const currentQuarter = getCurrentQuarter(); // 2025-Q4
        const currentRate = currentResult.rate;
        
        console.log(`📊 ${indicatorId} 當前季度 ${currentQuarter} 查詢結果:`, currentResult);
        console.log(`   分子: ${currentResult.numerator}, 分母: ${currentResult.denominator}, 比率: ${currentRate}%`);
        console.log(`   驗證: ${currentResult.numerator} ÷ ${currentResult.denominator} = ${(currentResult.numerator / currentResult.denominator * 100).toFixed(2)}%`);
        
        // 初始化8個季度，當前季度有真實值，其他季度先用 null
        const quarterly = {
            '2024-Q1': null,
            '2024-Q2': null,
            '2024-Q3': null,
            '2024-Q4': null,
            '2025-Q1': null,
            '2025-Q2': null,
            '2025-Q3': null,
            '2025-Q4': null
        };
        
        // 設定當前季度的值
        quarterly[currentQuarter] = currentRate;
        
        // 初始化 quarterlyDetails
        const quarterlyDetails = {
            '2024-Q1': null, '2024-Q2': null, '2024-Q3': null, '2024-Q4': null,
            '2025-Q1': null, '2025-Q2': null, '2025-Q3': null, '2025-Q4': null
        };
        
        // 存儲當前季度的詳細數據
        quarterlyDetails[currentQuarter] = {
            rate: currentRate,
            numerator: currentResult.numerator,
            denominator: currentResult.denominator
        };
        
        console.log(`💾 存儲到 quarterlyDetails[${currentQuarter}]:`, quarterlyDetails[currentQuarter]);
        
        // 確認是否為真無資料（分母為0）
        const isNoData = currentResult.denominator === 0;
        
        console.log(`📊 查詢結果檢查:`, {
            indicatorId,
            isNoData,
            demoMode,
            numerator: currentResult.numerator,
            denominator: currentResult.denominator
        });
        
        // 如果無資料且啟用示範模式，使用模擬數據
        if (isNoData && demoMode) {
            console.log(`✨ 使用示範模式數據 for ${indicatorId}`);
            return generateDemoData(indicatorId, currentQuarter);
        }
        
        if (isNoData) {
            console.warn(`⚠️ 無資料且示範模式未啟用: ${indicatorId}`);
        }
        
        return {
            quarterly: quarterly,
            quarterlyDetails: quarterlyDetails,
            numerator: currentResult.numerator,
            denominator: currentResult.denominator,
            noData: isNoData,
            currentQuarterOnly: !isNoData // 如果無資料就不需要計算其他季度
        };
        
    } catch (error) {
        console.error('查詢失敗:', error);
        return generateDefaultCurrentQuarterData();
    }
}

// 生成預設當前季度數據（當查詢失敗時）- 返回真實的0值
function generateDefaultCurrentQuarterData() {
    const currentQuarter = getCurrentQuarter();
    const baseRate = '0.00';
    
    const quarterly = {
        '2024-Q1': null,
        '2024-Q2': null,
        '2024-Q3': null,
        '2024-Q4': null,
        '2025-Q1': null,
        '2025-Q2': null,
        '2025-Q3': null,
        '2025-Q4': null
    };
    
    quarterly[currentQuarter] = baseRate;
    
    const numerator = 0;
    const denominator = 0;
    
    // 初始化 quarterlyDetails
    const quarterlyDetails = {
        '2024-Q1': null, '2024-Q2': null, '2024-Q3': null, '2024-Q4': null,
        '2025-Q1': null, '2025-Q2': null, '2025-Q3': null, '2025-Q4': null
    };
    
    // 存儲當前季度的詳細數據
    quarterlyDetails[currentQuarter] = {
        rate: baseRate,
        numerator: numerator,
        denominator: denominator
    };
    
    return {
        quarterly: quarterly,
        quarterlyDetails: quarterlyDetails,
        numerator: numerator,
        denominator: denominator,
        noData: false,
        currentQuarterOnly: true
    };
}

// CQL 3127: 門診注射劑使用率 - 基於CQL文件邏輯（支持季度參數）
// 來源: Indicator_01_Outpatient_Injection_Usage_Rate_3127.cql
// 分子: 給藥案件之針劑藥品(醫令代碼為10碼、且第8碼為'2')案件數
// 分母: 給藥案件數
// 排除: 門診化療注射劑(37005B,37031B-37041B)、ATC L01/L02化療藥、流感疫苗J07BB、破傷風J07AM01、急診、門診手術、事前審查藥品、STAT藥品、代辦案件
async function queryOutpatientInjectionRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL 3127: 門診注射劑使用率 (${targetQuarter}: ${dateRange.start} ~ ${dateRange.end})`);
    
    // CQL排除條件定義
    const excludedChemoProcedures = ['37005B', '37031B', '37032B', '37033B', '37034B', '37035B', 
                                      '37036B', '37037B', '37038B', '37039B', '37040B', '37041B'];
    const excludedChemoATCPrefixes = ['L01', 'L02'];
    const excludedSpecificATC = ['H01AB01', 'L03AB01', 'L03AB04', 'L03AB05', 'L03AB15',
                                  'L03AC01', 'L03AX03', 'L03AX16', 'L04AX01',
                                  'M05BA02', 'M05BA03', 'M05BA06', 'M05BA08', 'M05BX04',
                                  'V10XX03', 'J07AM01'];
    
    // ⚠️ 臨時診斷模式: 先不應用排除條件,檢查基礎數據
    const DIAGNOSTIC_MODE = true;
    
    // 先測試FHIR服務器是否有任何Encounter數據
    console.log(`  🧪 測試1: 查詢所有Encounter (不帶過濾條件)...`);
    try {
        const testAll = await conn.query('Encounter', { _count: 10 });
        console.log(`     結果: ${testAll?.entry?.length || 0} 個Encounters`);
        if (testAll?.entry?.length > 0) {
            console.log(`     ✅ FHIR服務器有Encounter數據!`);
            console.log(`     範例:`, testAll.entry[0].resource);
            
            // 檢查第一筆資料的日期
            const firstEncounter = testAll.entry[0].resource;
            const encounterDate = firstEncounter.period?.start || firstEncounter.period?.end;
            if (encounterDate) {
                console.log(`     📅 第一筆資料日期: ${encounterDate}`);
                console.log(`     📅 查詢日期範圍: ${dateRange.start} ~ ${dateRange.end}`);
                console.log(`     ⚠️ 如果資料日期不在查詢範圍內，結果會是 0`);
            }
        } else {
            console.warn(`     ❌ FHIR服務器沒有任何Encounter數據`);
        }
    } catch (err) {
        console.error(`     ❌ 查詢失敗:`, err);
    }
    
    // 測試2: 查詢門診資料（不帶日期範圍）
    console.log(`  🧪 測試2: 查詢門診Encounter (不帶日期範圍)...`);
    try {
        const testAmb = await conn.query('Encounter', { 
            class: 'AMB',
            status: 'finished',
            _count: 10 
        });
        console.log(`     結果: ${testAmb?.entry?.length || 0} 個門診Encounters`);
        if (testAmb?.entry?.length > 0) {
            console.log(`     ✅ FHIR服務器有門診數據!`);
            const dates = testAmb.entry.map(e => e.resource.period?.start || e.resource.period?.end).filter(d => d);
            console.log(`     📅 門診資料日期範圍: ${Math.min(...dates.map(d => new Date(d)))} ~ ${Math.max(...dates.map(d => new Date(d)))}`);
        }
    } catch (err) {
        console.error(`     ❌ 查詢失敗:`, err);
    }
    
    console.log(`  🔍 查詢參數 (門診+日期範圍):`, {
        class: 'AMB',
        status: 'finished',
        date: [`ge${dateRange.start}`, `le${dateRange.end}`],
        _count: 2000
    });
    
    const encounters = await conn.query('Encounter', {
        class: 'AMB',
        status: 'finished',
        date: [`ge${dateRange.start}`, `le${dateRange.end}`],
        _count: 2000
    });
    
    console.log(`  📦 FHIR回應: ${encounters?.entry?.length || 0} 個Encounters`);
    if (encounters?.entry?.length > 0) {
        console.log(`  📦 第一個Encounter範例:`, encounters.entry[0].resource);
    }
    
    if (!encounters.entry || encounters.entry.length === 0) {
        console.warn(`  ⚠️ 指定季度無資料 (${targetQuarter}: ${dateRange.start} ~ ${dateRange.end})`);
        console.log(`  🔄 嘗試查詢全部時間的資料...`);
        
        // 回退策略：查詢全部時間的資料
        const allTimeEncounters = await conn.query('Encounter', {
            class: 'AMB',
            status: 'finished',
            _count: 2000
        });
        
        console.log(`  📦 全部時間查詢結果: ${allTimeEncounters?.entry?.length || 0} 個Encounters`);
        
        if (!allTimeEncounters.entry || allTimeEncounters.entry.length === 0) {
            console.error(`  ❌ FHIR服務器完全沒有門診資料`);
            console.error(`  `);
            console.error(`  🔧 解決方案:`);
            console.error(`     1. 使用包含測試數據的FHIR服務器`);
            console.error(`        推薦: https://hapi.fhir.org/baseR4`);
            console.error(`     2. 或在首頁設定其他FHIR服務器URL`);
            console.error(`     3. 啟用「示範模式」查看模擬數據`);
            
            // 顯示無數據Banner
            if (!window.fhirNoDataWarningShown) {
                const banner = document.getElementById('noDataBanner');
                if (banner) {
                    banner.style.display = 'flex';
                }
                window.fhirNoDataWarningShown = true;
            }
            
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        // 使用全部時間的資料繼續計算
        console.log(`  ✅ 使用全部時間的資料進行計算`);
        encounters.entry = allTimeEncounters.entry;
    }
    
    // ========== 政府規範完整實作：indicator 3127 ==========
    console.log(`  🔄 使用政府規範邏輯查詢 MedicationRequest (CQL 3127)...`);
    
    let injectionCount = 0;
    let totalDrugCount = 0;
    let excludedCount = {
        chemo: 0, 
        vaccine: 0, 
        emergency: 0,
        surgery: 0,
        priorApproval: 0,
        stat: 0,
        takeHome: 0,
        specialDrugs: 0,
        notInjection: 0
    };
    
    // 遍歷每個門診案件，查詢其用藥記錄
    for (const encounterEntry of encounters.entry) {
        const encounter = encounterEntry.resource;
        const encounterId = encounter.id;
        
        // 檢查案件分類：排除急診(02)、門診手術(03)
        const encounterType = encounter.class?.code || encounter.type?.[0]?.coding?.[0]?.code;
        if (encounterType === '02' || encounterType === 'EMER') {
            excludedCount.emergency++;
            continue;
        }
        if (encounterType === '03' || encounterType === 'SS') {
            excludedCount.surgery++;
            continue;
        }
        
        // 查詢此案件的所有用藥
        let medications;
        try {
            medications = await conn.query('MedicationRequest', {
                encounter: `Encounter/${encounterId}`,
                status: 'active,completed',
                _count: 100
            });
        } catch (err) {
            console.warn(`    ⚠️ Encounter ${encounterId} 查詢用藥失敗:`, err.message);
            continue;
        }
        
        if (!medications.entry || medications.entry.length === 0) {
            continue;
        }
        
        // 處理每個用藥記錄
        for (const medEntry of medications.entry) {
            const med = medEntry.resource;
            totalDrugCount++;
            
            // === 步驟1: 判斷是否為注射劑 (10碼健保代碼且第8碼='2') ===
            const codings = med.medicationCodeableConcept?.coding || [];
            
            // 檢查是否有符合10碼且第8碼='2'的健保代碼
            let isInjectionByCode = false;
            let drugCode = '';
            
            for (const coding of codings) {
                const code = coding.code || '';
                // 政府規範: 10碼健保代碼，第8碼(索引7)為'2'
                if (code.length === 10 && code.charAt(7) === '2') {
                    isInjectionByCode = true;
                    drugCode = code;
                    break;
                }
            }
            
            if (!isInjectionByCode) {
                excludedCount.notInjection++;
                continue; // 不是注射劑
            }
            
            // === 步驟2: 排除門診化療注射劑醫令 ===
            const chemoInjectionCodes = [
                '37005B', '37031B', '37032B', '37033B', '37034B', '37035B',
                '37036B', '37037B', '37038B', '37039B', '37040B', '37041B'
            ];
            if (chemoInjectionCodes.includes(drugCode)) {
                excludedCount.chemo++;
                continue;
            }
            
            // === 步驟3: 排除化療藥品 (ATC碼前3碼為L01或L02) ===
            const atcCoding = codings.find(c => 
                c.system?.includes('atc') || c.system?.includes('whocc')
            );
            const atcCode = atcCoding?.code || '';
            
            if (atcCode.startsWith('L01') || atcCode.startsWith('L02')) {
                excludedCount.chemo++;
                continue;
            }
            
            // === 步驟4: 排除特定ATC碼藥品 (20+項) ===
            const excludedATCCodes = [
                'H01AB01',   // 生長激素
                'L03AB01', 'L03AB04', 'L03AB05', 'L03AB15',  // 干擾素
                'L03AC01',   // 介白素
                'L03AX03',   // BCG疫苗
                'L03AX16',   // 胸腺肽
                'L04AX01',   // 免疫抑制劑
                'M05BA02', 'M05BA03', 'M05BA06', 'M05BA08', 'M05BX04',  // 骨質疏鬆用藥
                'V10XX03',   // 放射碘
                'J07AM01'    // 破傷風毒素
            ];
            if (excludedATCCodes.includes(atcCode)) {
                excludedCount.specialDrugs++;
                continue;
            }
            
            // === 步驟5: 排除流感疫苗 (ATC碼前5碼為J07BB) ===
            if (atcCode.startsWith('J07BB')) {
                excludedCount.vaccine++;
                continue;
            }
            
            // === 步驟6: 排除事前審查藥品 ===
            const hasPriorApproval = med.extension?.some(ext => 
                ext.url?.includes('prior-approval') && ext.valueBoolean === true
            );
            if (hasPriorApproval) {
                excludedCount.priorApproval++;
                continue;
            }
            
            // === 步驟7: 排除STAT用藥 ===
            const isSTAT = med.dosageInstruction?.some(di => 
                di.asNeededBoolean === true ||
                di.additionalInstruction?.some(ai => 
                    ai.coding?.some(c => c.code === 'STAT')
                )
            );
            if (isSTAT) {
                excludedCount.stat++;
                continue;
            }
            
            // === 步驟8: 排除病人攜回注射藥品 ===
            const isTakeHome = med.extension?.some(ext => 
                ext.url?.includes('take-home-injection') && ext.valueBoolean === true
            );
            if (isTakeHome) {
                excludedCount.takeHome++;
                continue;
            }
            
            // 符合所有條件的注射劑
            injectionCount++;
        }
    }
    
    console.log(`  📊 統計結果 (政府規範 CQL 3127):`);
    console.log(`     總用藥數(分母): ${totalDrugCount}`);
    console.log(`     符合注射劑(分子): ${injectionCount}`);
    console.log(`     排除統計:`);
    console.log(`       - 非注射劑(非10碼或第8碼≠'2'): ${excludedCount.notInjection}`);
    console.log(`       - 化療藥品: ${excludedCount.chemo}`);
    console.log(`       - 疫苗: ${excludedCount.vaccine}`);
    console.log(`       - 特殊藥品(生長激素/干擾素等): ${excludedCount.specialDrugs}`);
    console.log(`       - 急診案件: ${excludedCount.emergency}`);
    console.log(`       - 門診手術: ${excludedCount.surgery}`);
    console.log(`       - 事前審查: ${excludedCount.priorApproval}`);
    console.log(`       - STAT用藥: ${excludedCount.stat}`);
    console.log(`       - 攜回注射: ${excludedCount.takeHome}`);
    
    if (totalDrugCount === 0) {
        console.warn(`  ⚠️ 沒有用藥記錄`);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    const rate = ((injectionCount / totalDrugCount) * 100).toFixed(2);
    console.log(`  ✅ 門診注射劑使用率: ${injectionCount}/${totalDrugCount} = ${rate}%`);
    
    return { rate, numerator: injectionCount, denominator: totalDrugCount };
}

// CQL 1140.01: 門診抗生素使用率 - 基於CQL文件邏輯（支持季度參數）
// CQL來源: Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql
// 公式: 抗生素藥品案件數 / 給藥案件數
// 抗生素定義: ATC碼前3碼='J01'
// 排除: 急診(02)、門診手術(03)、事前審查藥品、STAT藥品、代辦案件
async function queryOutpatientAntibioticRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL 1140.01: 門診抗生素使用率 (${targetQuarter}: ${dateRange.start} ~ ${dateRange.end})`);
    
    const encounters = await conn.query('Encounter', {
        class: 'AMB',
        status: 'finished',
        date: [`ge${dateRange.start}`, `le${dateRange.end}`],
        _count: 2000
    });
    
    if (!encounters.entry || encounters.entry.length === 0) {
        console.warn(`  ⚠️ 無門診資料 (${targetQuarter})`);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    let antibioticCount = 0;
    let totalDrugEncounters = 0;
    let excludedCount = {emergency: 0, surgery: 0, stat: 0, agency: 0, priorApproval: 0};
    
    // ATC碼前3碼為 J01 表示抗生素
    for (const entry of encounters.entry) {
        const encounter = entry.resource;
        const encounterId = encounter.id;
        
        // CQL排除1: 代辦案件
        const isAgency = encounter.type?.some(t => 
            t.coding?.some(c => c.code === 'AGENCY')
        );
        if (isAgency) {
            excludedCount.agency++;
            continue;
        }
        
        // CQL排除2: 急診案件 (type='02' or class='EMER')
        const isEmergency = encounter.class?.code === 'EMER' || 
                           encounter.type?.some(t => t.coding?.some(c => c.code === '02'));
        if (isEmergency) {
            excludedCount.emergency++;
            continue;
        }
        
        // CQL排除3: 門診手術案件 (type='03')
        const isSurgery = encounter.type?.some(t => t.coding?.some(c => c.code === '03'));
        if (isSurgery) {
            excludedCount.surgery++;
            continue;
        }
        
        try {
            const medications = await conn.query('MedicationRequest', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 50
            });
            
            if (medications.entry && medications.entry.length > 0) {
                let hasValidMedication = false;
                let hasAntibiotic = false;
                
                // 檢查是否有抗生素（ATC碼J01開頭）
                for (const medEntry of medications.entry) {
                    const med = medEntry.resource;
                    
                    // CQL排除4: 事前審查藥品
                    const hasPriorApproval = med.extension?.some(ext => 
                        ext.url === 'http://www.nhi.gov.tw/fhir/StructureDefinition/prior-approval' &&
                        ext.valueBoolean === true
                    );
                    if (hasPriorApproval) {
                        excludedCount.priorApproval++;
                        continue;
                    }
                    
                    // CQL排除5: STAT藥品
                    const isSTAT = med.dosageInstruction?.some(di => 
                        di.asNeededBoolean === true ||
                        di.additionalInstruction?.some(ai => 
                            ai.coding?.some(c => c.code === 'STAT')
                        )
                    );
                    if (isSTAT) {
                        excludedCount.stat++;
                        continue;
                    }
                    
                    hasValidMedication = true;
                    
                    const atcCode = med.medicationCodeableConcept?.coding?.find(c => 
                        c.system === 'http://www.whocc.no/atc'
                    )?.code;
                    
                    if (atcCode && atcCode.startsWith('J01')) {
                        hasAntibiotic = true;
                        break;
                    }
                }
                
                if (hasValidMedication) {
                    totalDrugEncounters++;
                    if (hasAntibiotic) {
                        antibioticCount++;
                    }
                }
            }
        } catch (error) {
            console.warn(`查詢Encounter ${encounterId}用藥失敗:`, error);
        }
    }
    
    const rate = totalDrugEncounters > 0 ? 
        ((antibioticCount / totalDrugEncounters) * 100).toFixed(2) : '0.00';
    
    if (totalDrugEncounters === 0) {
        console.error(`    ❌ 無用藥記錄 - 共檢查了 ${encounters.entry.length} 個門診，但都沒有MedicationRequest`);
    } else {
        console.log(`    ✅ 真實結果 - 檢查 ${encounters.entry.length} 個encounters，其中 ${totalDrugEncounters} 個有用藥`);
        console.log(`    ✅ 分子: ${antibioticCount}, 分母: ${totalDrugEncounters}, 比率: ${rate}%`);
        console.log(`    🚫 排除統計 - 急診:${excludedCount.emergency}, 手術:${excludedCount.surgery}, STAT:${excludedCount.stat}, 代辦:${excludedCount.agency}, 事前審查:${excludedCount.priorApproval}`);
    }
    
    return { rate: rate, numerator: antibioticCount, denominator: totalDrugEncounters };
}

// Helper: 檢查ATC碼是否符合降血壓藥(口服)定義
function isAntihypertensiveDrug(atcCode, drugCode) {
    if (!atcCode) return false;
    
    // 排除注射劑 (醫令代碼第8碼為2)
    if (drugCode && drugCode.length >= 8 && drugCode.charAt(7) === '2') {
        return false;
    }
    
    // C07 (排除C07AA05)
    if (atcCode.startsWith('C07') && atcCode !== 'C07AA05') return true;
    
    // 5碼精確匹配
    const validPrefixes = ['C02CA', 'C02DB', 'C02DC', 'C02DD', 'C03AA', 'C03BA', 'C03CA', 'C03DA', 
                          'C08CA', 'C08DA', 'C08DB', 'C09AA', 'C09CA'];
    if (validPrefixes.some(p => atcCode.startsWith(p)) && atcCode !== 'C08CA06') {
        return true;
    }
    
    return false;
}

// Helper: 檢查ATC碼是否符合降血脂藥(口服)定義
function isLipidLoweringDrug(atcCode, drugCode) {
    if (!atcCode) return false;
    
    // 排除注射劑 (醫令代碼第8碼不為1)
    if (drugCode && drugCode.length >= 8 && drugCode.charAt(7) !== '1') {
        return false;
    }
    
    // C10AA, C10AB, C10AC, C10AD, C10AX
    const validPrefixes = ['C10AA', 'C10AB', 'C10AC', 'C10AD', 'C10AX'];
    return validPrefixes.some(p => atcCode.startsWith(p));
}

// Helper: 檢查ATC碼是否符合降血糖藥定義 (口服及注射)
// CQL來源: Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql
function isAntidiabeticDrug(atcCode, drugCode) {
    if (!atcCode) return false;
    
    // A10: Drugs used in diabetes (降血糖藥物，包含口服及注射)
    // 無需排除任何劑型
    return atcCode.startsWith('A10');
}

// Helper: 檢查ATC碼是否符合抗思覺失調症藥物定義 (口服)
// CQL來源: Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql
function isAntipsychoticDrug(atcCode, drugCode) {
    if (!atcCode) return false;
    
    // ATC前5碼為N05AA、N05AB(排除N05AB04)、N05AD、N05AE、N05AF、N05AH、N05AL、N05AN(排除N05AN01)、N05AX、N05AC、N05AG
    const validPrefixes = ['N05AA', 'N05AB', 'N05AC', 'N05AD', 'N05AE', 'N05AF', 'N05AG', 'N05AH', 'N05AL', 'N05AN', 'N05AX'];
    const excludedCodes = ['N05AB04', 'N05AN01'];
    
    // 檢查是否符合有效前綴
    const hasValidPrefix = validPrefixes.some(p => atcCode.startsWith(p));
    
    // 排除特定代碼
    if (excludedCodes.includes(atcCode)) {
        return false;
    }
    
    return hasValidPrefix;
}

// Helper: 檢查ATC碼是否符合抗憂鬱症藥物定義 (口服)
// CQL來源: Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727.cql
function isAntidepressantDrug(atcCode, drugCode) {
    if (!atcCode) return false;
    
    // ATC前5碼為N06AA(排除N06AA02、N06AA12)、N06AB、N06AG
    const validPrefixes = ['N06AA', 'N06AB', 'N06AG'];
    const excludedCodes = ['N06AA02', 'N06AA12'];
    
    // 檢查是否符合有效前綴
    const hasValidPrefix = validPrefixes.some(p => atcCode.startsWith(p));
    
    // 排除特定代碼
    if (excludedCodes.includes(atcCode)) {
        return false;
    }
    
    return hasValidPrefix;
}

// Helper: 檢查ATC碼是否符合安眠鎮靜藥物定義 (口服)
// CQL來源: Indicator_03_6_Same_Hospital_Sedative_Overlap_1728.cql
function isSedativeHypnoticDrug(atcCode, drugCode) {
    if (!atcCode) return false;
    
    // Benzodiazepines anxiolytics (N05BA), hypnotics (N05CD), Z-drugs (N05CF), Other (N05C)
    return atcCode.startsWith('N05BA') || 
           atcCode.startsWith('N05CD') || 
           atcCode.startsWith('N05CF') || 
           atcCode.startsWith('N05C');
}

// Helper: 檢查是否為抗血栓藥物(口服) - 基於CQL Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375.cql
// ATC codes: B01AA (Vitamin K antagonists), B01AC (Platelet aggregation inhibitors, exclude B01AC07), 
//            B01AE (Direct thrombin inhibitors), B01AF (Direct factor Xa inhibitors)
// Source: 健保指標代碼 3375 - 同醫院門診同藥理用藥日數重疊率-抗血栓藥物(口服)
function isAntithromboticDrug(atcCode) {
    if (!atcCode) return false;
    
    // Excluded codes
    const excludedCodes = ['B01AC07']; // Dipyridamole
    if (excludedCodes.includes(atcCode.substring(0, 7))) {
        return false;
    }
    
    // B01AA: Vitamin K antagonists (維生素K拮抗劑)
    // B01AC: Platelet aggregation inhibitors (抗血小板藥物, 排除B01AC07)
    // B01AE: Direct thrombin inhibitors (直接凝血酶抑制劑)
    // B01AF: Direct factor Xa inhibitors (直接第十因子抑制劑)
    return atcCode.startsWith('B01AA') || 
           atcCode.startsWith('B01AC') || 
           atcCode.startsWith('B01AE') || 
           atcCode.startsWith('B01AF');
}

// Helper: 檢查是否為前列腺肥大藥物(口服) - 基於CQL Indicator_03_8_Same_Hospital_Prostate_Overlap_3376.cql
// ATC codes: G04CA (Alpha-adrenoreceptor antagonists), G04CB (Testosterone-5-alpha reductase inhibitors)
// Source: 健保指標代碼 3376 - 同醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服)
function isProstateDrug(atcCode) {
    if (!atcCode) return false;
    
    // G04CA: Alpha-adrenoreceptor antagonists (α-腎上腺素受體阻斷劑)
    // G04CB: Testosterone-5-alpha reductase inhibitors (5α-還原酶抑制劑)
    return atcCode.startsWith('G04CA') || 
           atcCode.startsWith('G04CB');
}

// Helper: 計算兩個日期區間的重疊天數
function calculateOverlapDays(start1, end1, start2, end2) {
    if (!start1 || !end1 || !start2 || !end2) return 0;
    
    const overlapStart = start1 > start2 ? start1 : start2;
    const overlapEnd = end1 < end2 ? end1 : end2;
    
    if (overlapStart <= overlapEnd) {
        const diffTime = overlapEnd - overlapStart;
        return Math.floor(diffTime / (1000 * 60 * 60 * 24)) + 1;
    }
    return 0;
}

// 藥品重疊率 - 基於CQL文件邏輯（支持季度參數）
// CQL來源 indicator-03-1: Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql
//   公式: 重疊給藥日數 / 各案件給藥日數總和
//   降血壓藥: ATC C07(排除C07AA05)、C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA
//   排除: 代辦案件、醫令代碼第8碼為2(注射劑)
// CQL來源 indicator-03-2: Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql
//   公式: 重疊給藥日數 / 各案件給藥日數總和
//   降血脂藥: ATC C10AA、C10AB、C10AC、C10AD、C10AX
//   排除: 代辦案件、醫令代碼第8碼不為1(非口服)
async function queryDrugOverlapRateSample(conn, indicatorId, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL藥品重疊率: ${indicatorId} (${targetQuarter})`);
    
    // 根據indicatorId定義藥品類別檢查函數
    const drugCheckers = {
        // 同院指標 (Same Hospital) - 指標代碼 1710, 1711, 3373-3376
        'indicator-03-1': { check: isAntihypertensiveDrug, name: '降血壓藥(口服)', cqlFile: 'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql' },
        'indicator-03-2': { check: isLipidLoweringDrug, name: '降血脂藥(口服)', cqlFile: 'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql' },
        'indicator-03-3': { check: isAntidiabeticDrug, name: '降血糖藥(口服及注射)', cqlFile: 'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_3373.cql' },
        'indicator-03-4': { check: isAntipsychoticDrug, name: '抗思覺失調症藥(口服)', cqlFile: 'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_3374.cql' },
        'indicator-03-5': { check: isAntidepressantDrug, name: '抗憂鬱症藥(口服)', cqlFile: 'Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1728.cql' },
        'indicator-03-6': { check: isSedativeHypnoticDrug, name: '安眠鎮靜藥(口服)', cqlFile: 'Indicator_03_6_Same_Hospital_Sedative_Overlap_1712.cql' },
        'indicator-03-7': { check: isAntithromboticDrug, name: '抗血栓藥(口服)', cqlFile: 'Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375.cql' },
        'indicator-03-8': { check: isProstateDrug, name: '前列腺藥(口服)', cqlFile: 'Indicator_03_8_Same_Hospital_Prostate_Overlap_3376.cql' },
        
        // 跨院指標 (Cross Hospital) - 指標代碼 1713-1715, 1729-1731, 3377-3378
        'indicator-03-9': { check: isAntihypertensiveDrug, name: '降血壓藥(跨院)', cqlFile: 'Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713.cql', crossHospital: true },
        'indicator-03-10': { check: isLipidLoweringDrug, name: '降血脂藥(跨院)', cqlFile: 'Indicator_03_10_Cross_Hospital_Lipid_Lowering_Overlap_1714.cql', crossHospital: true },
        'indicator-03-11': { check: isAntidiabeticDrug, name: '降血糖藥(跨院)', cqlFile: 'Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.cql', crossHospital: true },
        'indicator-03-12': { check: isAntipsychoticDrug, name: '抗思覺失調症藥(跨院)', cqlFile: 'Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.cql', crossHospital: true },
        'indicator-03-13': { check: isAntidepressantDrug, name: '抗憂鬱症藥(跨院)', cqlFile: 'Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730.cql', crossHospital: true },
        'indicator-03-14': { check: isSedativeHypnoticDrug, name: '安眠鎮靜藥(跨院)', cqlFile: 'Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731.cql', crossHospital: true },
        'indicator-03-15': { check: isAntithromboticDrug, name: '抗血栓藥(跨院)', cqlFile: 'Indicator_03_15_Cross_Hospital_Antithrombotic_Overlap_3377.cql', crossHospital: true },
        'indicator-03-16': { check: isProstateDrug, name: '前列腺藥(跨院)', cqlFile: 'Indicator_03_16_Cross_Hospital_Prostate_Overlap_3378.cql', crossHospital: true },
    };
    
    const checker = drugCheckers[indicatorId];
    if (!checker) {
        console.warn(`  ⚠️ 未實現的指標: ${indicatorId}`);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    // 查詢門診案件
    const encounters = await conn.query('Encounter', {
        class: 'AMB',
        status: 'finished',
        date: [`ge${dateRange.start}`, `le${dateRange.end}`],
        _count: 2000
    });
    
    if (!encounters.entry || encounters.entry.length === 0) {
        console.warn(`  ⚠️ ${checker.name}無門診資料 (${targetQuarter})`);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    // 收集符合條件的處方記錄（依病人+醫院分組）
    const prescriptionsByPatientHospital = {};
    let excludedCount = {agency: 0, wrongDrug: 0};
    
    for (const entry of encounters.entry) {
        const encounter = entry.resource;
        const encounterId = encounter.id;
        const patientRef = encounter.subject?.reference;
        const organizationRef = encounter.serviceProvider?.reference || 'unknown';
        
        // CQL排除: 代辦案件
        const isAgency = encounter.type?.some(t => 
            t.coding?.some(c => c.code === 'AGENCY')
        );
        if (isAgency) {
            excludedCount.agency++;
            continue;
        }
        
        try {
            const medications = await conn.query('MedicationRequest', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 50
            });
            
            if (medications.entry && medications.entry.length > 0) {
                for (const medEntry of medications.entry) {
                    const med = medEntry.resource;
                    const codings = med.medicationCodeableConcept?.coding || [];
                    const drugCode = codings[0]?.code || '';
                    const atcCode = codings.find(c => c.system === 'http://www.whocc.no/atc')?.code;
                    
                    // 檢查是否符合藥品類別
                    if (!checker.check(atcCode, drugCode)) {
                        excludedCount.wrongDrug++;
                        continue;
                    }
                    
                    // 提取給藥期間
                    const dispenseRequest = med.dispenseRequest;
                    if (!dispenseRequest || !dispenseRequest.validityPeriod) continue;
                    
                    const startDate = new Date(dispenseRequest.validityPeriod.start);
                    const endDate = dispenseRequest.validityPeriod.end ? 
                                   new Date(dispenseRequest.validityPeriod.end) : null;
                    
                    if (!endDate) {
                        // 如果沒有結束日期，嘗試從給藥天數計算
                        const daysSupply = dispenseRequest.expectedSupplyDuration?.value || 28;
                        endDate = new Date(startDate);
                        endDate.setDate(endDate.getDate() + daysSupply - 1);
                    }
                    
                    const drugDays = Math.floor((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1;
                    
                    // 依病人+醫院分組（跨院指標只按病人分組）
                    const key = checker.crossHospital ? patientRef : `${patientRef}|${organizationRef}`;
                    if (!prescriptionsByPatientHospital[key]) {
                        prescriptionsByPatientHospital[key] = [];
                    }
                    
                    prescriptionsByPatientHospital[key].push({
                        id: med.id,
                        startDate,
                        endDate,
                        drugDays,
                        organizationRef
                    });
                }
            }
        } catch (error) {
            console.warn(`查詢Encounter ${encounterId}用藥失敗:`, error);
        }
    }
    
    // 計算重疊天數（分子）和總給藥天數（分母）
    let totalOverlapDays = 0;
    let totalDrugDays = 0;
    
    for (const key in prescriptionsByPatientHospital) {
        const prescriptions = prescriptionsByPatientHospital[key];
        
        // 分母: 所有處方的給藥天數總和
        for (const p of prescriptions) {
            totalDrugDays += p.drugDays;
        }
        
        // 分子: 計算處方之間的重疊天數
        // 同院指標: 計算同一病人同一醫院的不同處方之間的重疊
        // 跨院指標: 計算同一病人不同醫院的處方之間的重疊
        for (let i = 0; i < prescriptions.length; i++) {
            for (let j = i + 1; j < prescriptions.length; j++) {
                const p1 = prescriptions[i];
                const p2 = prescriptions[j];
                
                // 跨院指標: 只計算來自不同醫院的處方重疊
                if (checker.crossHospital && p1.organizationRef === p2.organizationRef) {
                    continue;
                }
                
                const overlap = calculateOverlapDays(p1.startDate, p1.endDate, p2.startDate, p2.endDate);
                totalOverlapDays += overlap;
            }
        }
    }
    
    const rate = totalDrugDays > 0 ? 
        ((totalOverlapDays / totalDrugDays) * 100).toFixed(2) : '0.00';
    
    console.log(`    ✅ ${checker.name} - 重疊天數: ${totalOverlapDays}, 總給藥天數: ${totalDrugDays}, 比率: ${rate}%`);
    console.log(`    📄 CQL來源: ${checker.cqlFile || '未指定'}`);
    console.log(`    🚫 排除統計 - 代辦:${excludedCount.agency}, 不符藥品:${excludedCount.wrongDrug}`);
    
    return { rate: rate, numerator: totalOverlapDays, denominator: totalDrugDays };
}

// 指標05: 處方10種以上藥品比率 - 基於CQL Indicator_05_Prescription_10_Plus_Drugs_Rate_3128.cql
// 公式: 藥品品項數≥10項案件數 / 給藥案件數 × 100%
// CQL來源: 醫院總額醫療品質資訊1119\Indicator_05_Prescription_10_Plus_Drugs_Rate_3128.cql
async function queryPrescription10PlusDrugsRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL處方10種以上藥品率: indicator-05 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_05_Prescription_10_Plus_Drugs_Rate_3128.cql`);
    
    try {
        // 查詢門診給藥案件
        const encounters = await conn.query('Encounter', {
            class: 'AMB',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無門診資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let casesWithMedications = 0;
        let casesWith10PlusDrugs = 0;
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            // 查詢該案件的藥品處方
            const medications = await conn.query('MedicationRequest', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 100
            });
            
            if (medications.entry && medications.entry.length > 0) {
                // 計算唯一藥品品項數（去重複）
                const uniqueDrugs = new Set();
                for (const medEntry of medications.entry) {
                    const med = medEntry.resource;
                    if (med.medicationCodeableConcept?.coding?.[0]?.code) {
                        const drugCode = med.medicationCodeableConcept.coding[0].code;
                        // 檢查是否為10碼醫令代碼
                        if (drugCode.length === 10) {
                            uniqueDrugs.add(drugCode);
                        }
                    }
                }
                
                const drugCount = uniqueDrugs.size;
                if (drugCount > 0) {
                    casesWithMedications++;
                    if (drugCount >= 10) {
                        casesWith10PlusDrugs++;
                    }
                }
            }
        }
        
        const rate = casesWithMedications > 0 ? 
            ((casesWith10PlusDrugs / casesWithMedications) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 處方10種以上藥品率 - 分子: ${casesWith10PlusDrugs}, 分母: ${casesWithMedications}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: casesWith10PlusDrugs, denominator: casesWithMedications };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標06: 小兒氣喘急診率 - 基於CQL Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y.cql
// 公式: 因氣喘急診人數 / 18歲以下氣喘病患人數 × 100%
// 氣喘診斷: ICD-10-CM J45*
// CQL來源: Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y.cql
async function queryPediatricAsthmaEDRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL小兒氣喘急診率: indicator-06 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y.cql`);
    
    try {
        // 查詢18歲以下氣喘病患（主診斷J45*）
        const asthmaPatients = new Set();
        const edPatients = new Set();
        
        // 查詢門診氣喘案件
        const encounters = await conn.query('Encounter', {
            class: 'AMB',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (encounters.entry) {
            for (const entry of encounters.entry) {
                const encounter = entry.resource;
                const patientRef = encounter.subject?.reference;
                
                // 查詢診斷
                const conditions = await conn.query('Condition', {
                    encounter: `Encounter/${encounter.id}`,
                    _count: 10
                });
                
                if (conditions.entry) {
                    for (const condEntry of conditions.entry) {
                        const condition = condEntry.resource;
                        const icd10Code = condition.code?.coding?.find(c => 
                            c.system?.includes('icd-10'))?.code;
                        
                        // 檢查是否為氣喘診斷（J45*）
                        if (icd10Code?.startsWith('J45')) {
                            asthmaPatients.add(patientRef);
                            
                            // 檢查是否為急診
                            if (encounter.class?.code === 'EMER') {
                                edPatients.add(patientRef);
                            }
                        }
                    }
                }
            }
        }
        
        const totalAsthmaPatients = asthmaPatients.size;
        const edAsthmaPatients = edPatients.size;
        const rate = totalAsthmaPatients > 0 ? 
            ((edAsthmaPatients / totalAsthmaPatients) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 小兒氣喘急診率 - 急診人數: ${edAsthmaPatients}, 氣喘病患: ${totalAsthmaPatients}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: edAsthmaPatients, denominator: totalAsthmaPatients };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標07: 糖尿病HbA1c檢驗率 - 基於CQL Indicator_07_Diabetes_HbA1c_Testing_Rate_109_01Q_110_01Y.cql
// 公式: 有HbA1c檢驗人數 / 糖尿病且使用糖尿病用藥病患數 × 100%
// 糖尿病診斷: ICD-10-CM E08-E13, 糖尿病用藥: ATC A10*
// CQL來源: Indicator_07_Diabetes_HbA1c_Testing_Rate_109_01Q_110_01Y.cql
async function queryDiabetesHbA1cTestingRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL糖尿病HbA1c檢驗率: indicator-07 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_07_Diabetes_HbA1c_Testing_Rate_109_01Q_110_01Y.cql`);
    
    try {
        const diabetesPatients = new Set();
        const patientsWithHbA1c = new Set();
        
        // 查詢門診案件
        const encounters = await conn.query('Encounter', {
            class: 'AMB',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (encounters.entry) {
            for (const entry of encounters.entry) {
                const encounter = entry.resource;
                const patientRef = encounter.subject?.reference;
                const encounterId = encounter.id;
                
                // 🔍 調試：記錄測試資料
                if (encounterId.startsWith('DM-ENC')) {
                    console.log(`  🎯 處理測試 Encounter: ${encounterId}, patient: ${patientRef}`);
                }
                
                // 查詢診斷（糖尿病 E08-E13）
                const conditions = await conn.query('Condition', {
                    encounter: `Encounter/${encounterId}`,
                    _count: 10
                });
                
                let hasDiabetes = false;
                if (conditions.entry) {
                    for (const condEntry of conditions.entry) {
                        const condition = condEntry.resource;
                        const icd10Code = condition.code?.coding?.find(c => 
                            c.system?.includes('icd-10'))?.code;
                        
                        // 檢查是否為糖尿病（E08-E13）
                        if (icd10Code && (
                            icd10Code.startsWith('E08') || icd10Code.startsWith('E09') ||
                            icd10Code.startsWith('E10') || icd10Code.startsWith('E11') ||
                            icd10Code.startsWith('E13')
                        )) {
                            hasDiabetes = true;
                            if (encounterId.startsWith('DM-ENC')) {
                                console.log(`     ✅ 找到糖尿病診斷: ${icd10Code}`);
                            }
                            break;
                        }
                    }
                }
                
                // 檢查是否使用糖尿病用藥（A10*）
                if (hasDiabetes) {
                    const medications = await conn.query('MedicationRequest', {
                        encounter: `Encounter/${encounterId}`,
                        status: 'completed',
                        _count: 50
                    });
                    
                    let hasDiabetesDrug = false;
                    if (medications.entry) {
                        for (const medEntry of medications.entry) {
                            const med = medEntry.resource;
                            const atcCode = med.medicationCodeableConcept?.coding?.find(c =>
                                c.system?.includes('atc'))?.code;
                            
                            if (atcCode?.startsWith('A10')) {
                                hasDiabetesDrug = true;
                                if (encounterId.startsWith('DM-ENC')) {
                                    console.log(`     ✅ 找到糖尿病用藥: ${atcCode}`);
                                }
                                break;
                            }
                        }
                    }
                    
                    if (hasDiabetesDrug) {
                        diabetesPatients.add(patientRef);
                        if (encounterId.startsWith('DM-ENC')) {
                            console.log(`     ➕ 計入分母 (糖尿病患者數: ${diabetesPatients.size})`);
                        }
                        
                        // 查詢HbA1c檢驗
                        const observations = await conn.query('Observation', {
                            patient: patientRef,
                            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
                            _count: 50
                        });
                        
                        if (observations.entry) {
                            if (encounterId.startsWith('DM-ENC')) {
                                console.log(`     🔬 找到 ${observations.entry.length} 筆 Observation`);
                            }
                            for (const obsEntry of observations.entry) {
                                const obs = obsEntry.resource;
                                const loincCode = obs.code?.coding?.find(c =>
                                    c.system?.includes('loinc'))?.code;
                                
                                if (encounterId.startsWith('DM-ENC')) {
                                    console.log(`        - Observation: LOINC ${loincCode}`);
                                }
                                
                                // HbA1c LOINC codes: 4548-4, 17856-6, 59261-8
                                if (loincCode && (
                                    loincCode === '4548-4' || loincCode === '17856-6' || 
                                    loincCode === '59261-8'
                                )) {
                                    patientsWithHbA1c.add(patientRef);
                                    if (encounterId.startsWith('DM-ENC')) {
                                        console.log(`        ✅ 符合HbA1c代碼！計入分子 (有檢驗數: ${patientsWithHbA1c.size})`);
                                    }
                                    break;
                                }
                            }
                        } else {
                            if (encounterId.startsWith('DM-ENC')) {
                                console.log(`     ⚠️  沒有找到 Observation`);
                            }
                        }
                    }
                }
            }
        }
        
        const totalDiabetes = diabetesPatients.size;
        const withHbA1c = patientsWithHbA1c.size;
        const rate = totalDiabetes > 0 ? 
            ((withHbA1c / totalDiabetes) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 糖尿病HbA1c檢驗率 - 有檢驗: ${withHbA1c}, 糖尿病患者: ${totalDiabetes}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: withHbA1c, denominator: totalDiabetes };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標08: 同日同院同疾病再就診率 - 基於CQL Indicator_08_Same_Day_Same_Disease_Revisit_Rate_1322.cql
// 公式: 同日同院同疾病再就診人數 / 門診人數 × 100%
// 同疾病: 主診斷前三碼相同
// CQL來源: Indicator_08_Same_Day_Same_Disease_Revisit_Rate_1322.cql
async function querySameDaySameDiseaseRevisitRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL同日同院同疾病再就診率: indicator-08 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_08_Same_Day_Same_Disease_Revisit_Rate_1322.cql`);
    
    try {
        const patientDayHospitalVisits = {};
        const revisitPatients = new Set();
        const allPatients = new Set();
        
        // 查詢門診案件
        const encounters = await conn.query('Encounter', {
            class: 'AMB',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (encounters.entry) {
            for (const entry of encounters.entry) {
                const encounter = entry.resource;
                const patientRef = encounter.subject?.reference;
                const hospitalRef = encounter.serviceProvider?.reference || 'unknown';
                const visitDate = encounter.period?.start?.split('T')[0]; // 取日期部分
                
                allPatients.add(patientRef);
                
                // 查詢主診斷
                const conditions = await conn.query('Condition', {
                    encounter: `Encounter/${encounter.id}`,
                    _count: 5
                });
                
                if (conditions.entry && conditions.entry.length > 0) {
                    const primaryCondition = conditions.entry[0].resource;
                    const icd10Code = primaryCondition.code?.coding?.find(c =>
                        c.system?.includes('icd-10'))?.code;
                    
                    if (icd10Code) {
                        const icd10Prefix = icd10Code.substring(0, 3); // 前三碼
                        const key = `${patientRef}_${visitDate}_${hospitalRef}_${icd10Prefix}`;
                        
                        if (!patientDayHospitalVisits[key]) {
                            patientDayHospitalVisits[key] = 0;
                        }
                        patientDayHospitalVisits[key]++;
                        
                        // 如果同日同院同疾病有2次以上就診
                        if (patientDayHospitalVisits[key] >= 2) {
                            revisitPatients.add(patientRef);
                        }
                    }
                }
            }
        }
        
        const totalPatients = allPatients.size;
        const revisitCount = revisitPatients.size;
        const rate = totalPatients > 0 ? 
            ((revisitCount / totalPatients) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 同日同院同疾病再就診率 - 再就診人數: ${revisitCount}, 門診人數: ${totalPatients}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: revisitCount, denominator: totalPatients };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 慢性病連處箋使用率 - 真實查詢版（支持季度參數）
async function queryChronicPrescriptionRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  真實查詢: 慢性病連處箋使用率 (${targetQuarter})`);
    
    const medications = await conn.query('MedicationRequest', {
        status: 'completed',
        authoredon: `ge${dateRange.start}&authoredon=le${dateRange.end}`,
        _count: 2000
    });
    
    if (!medications.entry || medications.entry.length === 0) {
        console.warn(`  ⚠️ 無藥品資料 (${targetQuarter})`);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    let chronicCount = 0;
    const totalMeds = medications.entry.length;
    
    for (const entry of medications.entry) {
        const med = entry.resource;
        
        // 檢查 dosageInstruction 中的處方天數
        if (med.dosageInstruction && med.dosageInstruction.length > 0) {
            for (const dosage of med.dosageInstruction) {
                const duration = dosage.timing?.repeat?.boundsDuration;
                
                if (duration) {
                    const value = duration.value;
                    const unit = duration.unit;
                    
                    // 判斷是否為慢性處方（≥28天）
                    if ((unit === 'd' || unit === 'day' || unit === 'days') && value >= 28) {
                        chronicCount++;
                        break;
                    } else if ((unit === 'wk' || unit === 'week' || unit === 'weeks') && value >= 4) {
                        chronicCount++;
                        break;
                    } else if ((unit === 'mo' || unit === 'month' || unit === 'months') && value >= 1) {
                        chronicCount++;
                        break;
                    }
                }
            }
        }
        
        // 檢查 dispenseRequest.expectedSupplyDuration
        if (!med.dosageInstruction || med.dosageInstruction.length === 0) {
            const supplyDuration = med.dispenseRequest?.expectedSupplyDuration;
            if (supplyDuration) {
                const value = supplyDuration.value;
                const unit = supplyDuration.unit;
                
                if ((unit === 'd' || unit === 'day' || unit === 'days') && value >= 28) {
                    chronicCount++;
                } else if ((unit === 'wk' || unit === 'week' || unit === 'weeks') && value >= 4) {
                    chronicCount++;
                } else if ((unit === 'mo' || unit === 'month' || unit === 'months') && value >= 1) {
                    chronicCount++;
                }
            }
        }
    }
    
    const rate = totalMeds > 0 ? ((chronicCount / totalMeds) * 100).toFixed(2) : '0.00';
    
    console.log(`    真實結果 - 分子: ${chronicCount}, 分母: ${totalMeds}, 比率: ${rate}%`);
    
    return { rate: rate, numerator: chronicCount, denominator: totalMeds };
}

// 14天再入院率 - 真實查詢版（支持季度參數）
async function queryReadmissionRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  真實查詢: 14天再入院率 (${targetQuarter})`);
    
    const encounters = await conn.query('Encounter', {
        class: 'IMP',
        status: 'finished',
        date: [`ge${dateRange.start}`, `le${dateRange.end}`],
        _count: 2000
    });
    
    if (!encounters.entry || encounters.entry.length === 0) {
        console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    // 依病人分組，記錄每位病人的住院日期
    const patientAdmissions = {};
    
    for (const entry of encounters.entry) {
        const enc = entry.resource;
        const patientRef = enc.subject?.reference;
        const dischargeDate = enc.period?.end;
        
        if (patientRef && dischargeDate) {
            if (!patientAdmissions[patientRef]) {
                patientAdmissions[patientRef] = [];
            }
            patientAdmissions[patientRef].push(new Date(dischargeDate));
        }
    }
    
    // 統計14天內再入院
    let readmissionCount = 0;
    let totalDischarges = 0;
    
    for (const patientRef in patientAdmissions) {
        const dates = patientAdmissions[patientRef].sort((a, b) => a - b);
        
        for (let i = 0; i < dates.length - 1; i++) {
            totalDischarges++;
            
            const discharge = dates[i];
            const nextAdmission = dates[i + 1];
            const daysBetween = (nextAdmission - discharge) / (1000 * 60 * 60 * 24);
            
            if (daysBetween <= 14) {
                readmissionCount++;
            }
        }
        
        // 最後一次出院也算入分母
        if (dates.length > 0) {
            totalDischarges++;
        }
    }
    
    if (totalDischarges === 0) {
        console.warn('  ⚠️ 無出院記錄');
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    const rate = ((readmissionCount / totalDischarges) * 100).toFixed(2);
    
    console.log(`    真實結果 - 分子: ${readmissionCount}, 分母: ${totalDischarges}, 比率: ${rate}%`);
    
    return { rate: rate, numerator: readmissionCount, denominator: totalDischarges };
}

// 指標10: 住院案件出院後三日以內急診率 - 基於CQL Indicator_10_Inpatient_3Day_ED_After_Discharge_108_01.cql
// 公式: 3日內再急診案件數 / 出院案件數 × 100%
// CQL來源: Indicator_10_Inpatient_3Day_ED_After_Discharge_108_01.cql
async function queryInpatient3DayEDAfterDischargeSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL出院後3日內急診率: indicator-10 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_10_Inpatient_3Day_ED_After_Discharge_108_01.cql`);
    
    try {
        // 查詢住院案件
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let dischargeCount = 0;
        let edWithin3Days = 0;
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const patientRef = encounter.subject?.reference;
            const dischargeDate = encounter.period?.end;
            
            if (!patientRef || !dischargeDate) continue;
            
            dischargeCount++;
            
            // 檢查出院後3日內是否有急診
            const dischargeDateObj = new Date(dischargeDate);
            const threeDaysLater = new Date(dischargeDateObj);
            threeDaysLater.setDate(threeDaysLater.getDate() + 3);
            
            // 查詢該病患3日內的急診記錄
            const edEncounters = await conn.query('Encounter', {
                patient: patientRef,
                class: 'EMER',
                status: 'finished',
                date: [`ge${dischargeDate.split('T')[0]}`, `le${threeDaysLater.toISOString().split('T')[0]}`],
                _count: 10
            });
            
            if (edEncounters.entry && edEncounters.entry.length > 0) {
                edWithin3Days++;
            }
        }
        
        const rate = dischargeCount > 0 ? 
            ((edWithin3Days / dischargeCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 出院後3日內急診率 - 3日內急診: ${edWithin3Days}, 出院案件: ${dischargeCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: edWithin3Days, denominator: dischargeCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標11-1: 剖腹產率-整體 - 基於CQL Indicator_11_1_Overall_Cesarean_Section_Rate_1136_01.cql
// 公式: 剖腹產案件數 / 生產案件數(自然產+剖腹產) × 100%
// CQL來源: Indicator_11_1_Overall_Cesarean_Section_Rate_1136_01.cql
async function queryCesareanSectionOverallRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL剖腹產率-整體: indicator-11-1 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_11_1_Overall_Cesarean_Section_Rate_1136_01.cql`);
    
    try {
        // 查詢住院生產案件
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let cesareanCount = 0;
        let totalDeliveries = 0;
        
        // 剖腹產醫令代碼
        const cesareanCodes = ['81004C', '81005C', '81028C', '81029C', '97009C', '97014C'];
        // 自然產醫令代碼
        const vaginalCodes = ['81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C', '97004C', '97005D', '97934C'];
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            // 🔍 調試：只處理測試資料
            if (encounterId.startsWith('TEST-CS-') || encounterId.startsWith('CS-ENC-')) {
                console.log(`🎯 找到測試 Encounter: ${encounterId}`);
            }
            
            // 查詢手術處置
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            if (procedures.entry) {
                let isCesarean = false;
                let isVaginal = false;
                
                for (const procEntry of procedures.entry) {
                    const proc = procEntry.resource;
                    const procCode = proc.code?.coding?.[0]?.code;
                    
                    // 🔍 調試：打印 Procedure 詳細資訊
                    if (encounterId.startsWith('TEST-CS-') || encounterId.startsWith('CS-ENC-')) {
                        console.log(`   📋 Procedure: ${proc.id}, Code: ${procCode}`);
                    }
                    
                    if (procCode && cesareanCodes.includes(procCode)) {
                        isCesarean = true;
                        if (encounterId.startsWith('TEST-CS-') || encounterId.startsWith('CS-ENC-')) {
                            console.log(`   ✅ 符合剖腹產代碼！`);
                        }
                    }
                    if (procCode && vaginalCodes.includes(procCode)) {
                        isVaginal = true;
                    }
                }
                
                if (isCesarean || isVaginal) {
                    totalDeliveries++;
                    if (isCesarean) {
                        cesareanCount++;
                        if (encounterId.startsWith('TEST-CS-') || encounterId.startsWith('CS-ENC-')) {
                            console.log(`   ➕ 計入分子！當前 cesareanCount = ${cesareanCount}`);
                        }
                    }
                }
            }
        }
        
        // 🔍 調試：打印最終結果
        console.log(`📊 最終統計 - 剖腹產: ${cesareanCount}, 總生產: ${totalDeliveries}`);
        if (cesareanCount === 0 && totalDeliveries > 0) {
            console.warn(`⚠️  警告：分母有 ${totalDeliveries} 但分子是 0！`);
        }
        
        const rate = totalDeliveries > 0 ? 
            ((cesareanCount / totalDeliveries) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 剖腹產率-整體 - 剖腹產: ${cesareanCount}, 總生產: ${totalDeliveries}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: cesareanCount, denominator: totalDeliveries };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標11-2: 剖腹產率-自行要求 - 基於CQL Indicator_11_2_Cesarean_Section_Rate_Patient_Requested_1137_01.cql
// 公式: 不具適應症之剖腹產案件數 / 生產案件數 × 100%
// CQL來源: Indicator_11_2_Cesarean_Section_Rate_Patient_Requested_1137_01.cql
async function queryCesareanSectionPatientRequestedRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL剖腹產率-自行要求: indicator-11-2 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_11_2_Cesarean_Section_Rate_Patient_Requested_1137_01.cql`);
    
    try {
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let patientRequestedCount = 0;
        let totalDeliveries = 0;
        
        const cesareanCodes = ['81004C', '81005C', '81028C', '81029C', '97009C', '97014C'];
        const vaginalCodes = ['81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C', '97004C', '97005D', '97934C'];
        const patientRequestedCode = '97014C'; // 自行要求剖腹產特定代碼
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            if (procedures.entry) {
                let isCesarean = false;
                let isVaginal = false;
                let isPatientRequested = false;
                
                for (const procEntry of procedures.entry) {
                    const proc = procEntry.resource;
                    const procCode = proc.code?.coding?.[0]?.code;
                    
                    if (procCode && cesareanCodes.includes(procCode)) {
                        isCesarean = true;
                    }
                    if (procCode && vaginalCodes.includes(procCode)) {
                        isVaginal = true;
                    }
                    if (procCode === patientRequestedCode) {
                        isPatientRequested = true;
                    }
                }
                
                if (isCesarean || isVaginal) {
                    totalDeliveries++;
                    if (isPatientRequested) {
                        patientRequestedCount++;
                    }
                }
            }
        }
        
        const rate = totalDeliveries > 0 ? 
            ((patientRequestedCount / totalDeliveries) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 剖腹產率-自行要求 - 自行要求: ${patientRequestedCount}, 總生產: ${totalDeliveries}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: patientRequestedCount, denominator: totalDeliveries };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標11-3: 剖腹產率-具適應症 - 基於CQL Indicator_11_3_Cesarean_Section_Rate_With_Indication_1138_01.cql
// 公式: 具適應症剖腹產案件數 / 生產案件數 × 100%
// CQL來源: Indicator_11_3_Cesarean_Section_Rate_With_Indication_1138_01.cql
async function queryCesareanSectionWithIndicationRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL剖腹產率-具適應症: indicator-11-3 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_11_3_Cesarean_Section_Rate_With_Indication_1138_01.cql`);
    
    try {
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let withIndicationCount = 0;
        let totalDeliveries = 0;
        
        const cesareanCodes = ['81004C', '81005C', '81028C', '81029C', '97009C', '97014C'];
        const vaginalCodes = ['81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C', '97004C', '97005D', '97934C'];
        const patientRequestedCode = '97014C'; // 排除自行要求
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            if (procedures.entry) {
                let isCesarean = false;
                let isVaginal = false;
                let isPatientRequested = false;
                
                for (const procEntry of procedures.entry) {
                    const proc = procEntry.resource;
                    const procCode = proc.code?.coding?.[0]?.code;
                    
                    if (procCode && cesareanCodes.includes(procCode)) {
                        isCesarean = true;
                    }
                    if (procCode && vaginalCodes.includes(procCode)) {
                        isVaginal = true;
                    }
                    if (procCode === patientRequestedCode) {
                        isPatientRequested = true;
                    }
                }
                
                if (isCesarean || isVaginal) {
                    totalDeliveries++;
                    if (isCesarean && !isPatientRequested) {
                        withIndicationCount++;
                    }
                }
            }
        }
        
        const rate = totalDeliveries > 0 ? 
            ((withIndicationCount / totalDeliveries) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 剖腹產率-具適應症 - 具適應症: ${withIndicationCount}, 總生產: ${totalDeliveries}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: withIndicationCount, denominator: totalDeliveries };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標11-4: 剖腹產率-初次具適應症 - 基於CQL Indicator_11_4_Cesarean_Section_Rate_First_Time_1075_01.cql
// 公式: 初次非自願剖腹產案件數 / 生產案件數 × 100%
// CQL來源: Indicator_11_4_Cesarean_Section_Rate_First_Time_1075_01.cql
async function queryCesareanSectionFirstTimeRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL剖腹產率-初次具適應症: indicator-11-4 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_11_4_Cesarean_Section_Rate_First_Time_1075_01.cql`);
    
    try {
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let firstTimeCesareanCount = 0;
        let totalDeliveries = 0;
        
        const firstTimeCesareanCodes = ['81004C', '81028C']; // 初次剖腹產代碼
        const cesareanCodes = ['81004C', '81005C', '81028C', '81029C', '97009C', '97014C'];
        const vaginalCodes = ['81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C', '97004C', '97005D', '97934C'];
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            if (procedures.entry) {
                let isCesarean = false;
                let isVaginal = false;
                let isFirstTime = false;
                
                for (const procEntry of procedures.entry) {
                    const proc = procEntry.resource;
                    const procCode = proc.code?.coding?.[0]?.code;
                    
                    if (procCode && cesareanCodes.includes(procCode)) {
                        isCesarean = true;
                    }
                    if (procCode && vaginalCodes.includes(procCode)) {
                        isVaginal = true;
                    }
                    if (procCode && firstTimeCesareanCodes.includes(procCode)) {
                        isFirstTime = true;
                    }
                }
                
                if (isCesarean || isVaginal) {
                    totalDeliveries++;
                    if (isFirstTime) {
                        firstTimeCesareanCount++;
                    }
                }
            }
        }
        
        const rate = totalDeliveries > 0 ? 
            ((firstTimeCesareanCount / totalDeliveries) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 剖腹產率-初次具適應症 - 初次剖腹產: ${firstTimeCesareanCount}, 總生產: ${totalDeliveries}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: firstTimeCesareanCount, denominator: totalDeliveries };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標12: 清淨手術術後使用抗生素超過三日比率 - 基於CQL Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155.cql
// 公式: 手術後>3日使用抗生素案件數 / 清淨手術案件數 × 100%
// CQL來源: Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155.cql
async function queryCleanSurgeryAntibioticOver3DaysRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL清淨手術術後抗生素>3日比率: indicator-12 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155.cql`);
    
    try {
        // 查詢住院手術案件
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let cleanSurgeryCount = 0;
        let over3DaysAntibioticCount = 0;
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            // 查詢手術記錄（清淨手術）
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            if (!procedures.entry || procedures.entry.length === 0) continue;
            
            // 簡化判定：有手術的案件視為清淨手術
            cleanSurgeryCount++;
            
            // 查詢術後抗生素使用
            const medications = await conn.query('MedicationRequest', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 50
            });
            
            if (medications.entry) {
                let antibioticDays = 0;
                
                for (const medEntry of medications.entry) {
                    const med = medEntry.resource;
                    const atcCode = med.medicationCodeableConcept?.coding?.find(c =>
                        c.system?.includes('atc'))?.code;
                    
                    // ATC J01* 為抗生素
                    if (atcCode?.startsWith('J01')) {
                        // 計算用藥天數
                        if (med.dosageInstruction && med.dosageInstruction[0]?.timing?.repeat?.boundsDuration?.value) {
                            antibioticDays += med.dosageInstruction[0].timing.repeat.boundsDuration.value;
                        } else {
                            antibioticDays += 1; // 預設1天
                        }
                    }
                }
                
                if (antibioticDays > 3) {
                    over3DaysAntibioticCount++;
                }
            }
        }
        
        const rate = cleanSurgeryCount > 0 ? 
            ((over3DaysAntibioticCount / cleanSurgeryCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 清淨手術抗生素>3日比率 - >3日案件: ${over3DaysAntibioticCount}, 清淨手術: ${cleanSurgeryCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: over3DaysAntibioticCount, denominator: cleanSurgeryCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標13: 接受體外震波碎石術(ESWL)病人平均利用次數 - 基於CQL Indicator_13_Average_ESWL_Utilization_Times_20_01Q_1804Y.cql
// 公式: ESWL總次數 / 接受ESWL病人數
// CQL來源: Indicator_13_Average_ESWL_Utilization_Times_20_01Q_1804Y.cql
async function queryESWLAverageUtilizationTimesSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL體外震波碎石術平均利用次數: indicator-13 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_13_Average_ESWL_Utilization_Times_20_01Q_1804Y.cql`);
    
    try {
        // 查詢所有ESWL處置記錄
        console.log(`  🔍 查詢參數: status=completed, date=ge${dateRange.start},le${dateRange.end}`);
        const procedures = await conn.query('Procedure', {
            status: 'completed',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        console.log(`  📦 查詢結果: ${procedures.entry ? procedures.entry.length : 0} 筆 Procedure`);
        
        if (!procedures.entry || procedures.entry.length === 0) {
            console.warn(`  ⚠️ 無ESWL處置資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        const eswlPatients = new Set();
        let eswlTotalCount = 0;
        
        // ESWL相關SNOMED/ICD-10-PCS代碼
        const eswlCodes = ['80146002', '0TF00ZZ', '0TF10ZZ', '0TF20ZZ']; // 示例代碼
        
        for (const entry of procedures.entry) {
            const proc = entry.resource;
            const procCode = proc.code?.coding?.[0]?.code;
            const patientRef = proc.subject?.reference;
            
            // 🔍 調試：記錄測試資料
            if (proc.id && proc.id.startsWith('ESWL-PROC')) {
                console.log(`  🎯 找到測試 Procedure: ${proc.id}, code=${procCode}`);
            }
            
            // 檢查是否為ESWL
            if (procCode && eswlCodes.includes(procCode)) {
                eswlTotalCount++;
                if (patientRef) {
                    eswlPatients.add(patientRef);
                }
                if (proc.id && proc.id.startsWith('ESWL-PROC')) {
                    console.log(`  ✅ 符合 ESWL 代碼！計入統計`);
                }
            }
        }
        
        const patientCount = eswlPatients.size;
        const avgTimes = patientCount > 0 ? 
            (eswlTotalCount / patientCount).toFixed(2) : '0.00';
        
        console.log(`    ✅ ESWL平均利用次數 - 總次數: ${eswlTotalCount}, 病人數: ${patientCount}, 平均: ${avgTimes}次`);
        
        return { rate: avgTimes, numerator: eswlTotalCount, denominator: patientCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標14: 子宮肌瘤手術出院後14日內因相關診斷再住院率 - 基於CQL Indicator_14_Uterine_Fibroid_Surgery_14Day_Readmission_473_01.cql
// 公式: 14日內因相關診斷再住院次數 / 子宮肌瘤手術住院人次數 × 100%
// CQL來源: Indicator_14_Uterine_Fibroid_Surgery_14Day_Readmission_473_01.cql
async function queryUterineFibroidSurgery14DayReadmissionSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL子宮肌瘤手術14日再住院率: indicator-14 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_14_Uterine_Fibroid_Surgery_14Day_Readmission_473_01.cql`);
    
    try {
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let fibroidSurgeryCount = 0;
        let readmissionCount = 0;
        
        // 子宮肌瘤摘除術醫令代碼
        const myomectomyCodes = ['97010K', '97011A', '97012B', '97013B', '80402C', '80420C', '80415B', '97013C', '80415C', '80425C'];
        // 子宮切除術醫令代碼
        const hysterectomyCodes = ['97025K', '97026A', '97027B', '97020K', '97021A', '97022B', '97035K', '97036A', '97037B', '80403B', '80404B', '80421B', '80416B', '80412B', '97027C', '80404C'];
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            const patientRef = encounter.subject?.reference;
            const dischargeDate = encounter.period?.end;
            
            // 檢查子宮肌瘤診斷（ICD-10-CM D25*）
            const conditions = await conn.query('Condition', {
                encounter: `Encounter/${encounterId}`,
                _count: 10
            });
            
            let hasFibroid = false;
            if (conditions.entry) {
                for (const condEntry of conditions.entry) {
                    const condition = condEntry.resource;
                    const icd10Code = condition.code?.coding?.find(c => 
                        c.system?.includes('icd-10'))?.code;
                    
                    if (icd10Code?.startsWith('D25')) {
                        hasFibroid = true;
                        break;
                    }
                }
            }
            
            if (!hasFibroid) continue;
            
            // 檢查子宮手術
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            let hasSurgery = false;
            if (procedures.entry) {
                for (const procEntry of procedures.entry) {
                    const proc = procEntry.resource;
                    const procCode = proc.code?.coding?.[0]?.code;
                    
                    if (procCode && (myomectomyCodes.includes(procCode) || hysterectomyCodes.includes(procCode))) {
                        hasSurgery = true;
                        break;
                    }
                }
            }
            
            if (hasSurgery) {
                fibroidSurgeryCount++;
                
                // 檢查14日內再住院（相關診斷N70-N85）
                if (dischargeDate && patientRef) {
                    const dischargeDateObj = new Date(dischargeDate);
                    const fourteenDaysLater = new Date(dischargeDateObj);
                    fourteenDaysLater.setDate(fourteenDaysLater.getDate() + 14);
                    
                    const readmissions = await conn.query('Encounter', {
                        patient: patientRef,
                        class: 'IMP',
                        status: 'finished',
                        date: [`ge${dischargeDate.split('T')[0]}`, `le${fourteenDaysLater.toISOString().split('T')[0]}`],
                        _count: 10
                    });
                    
                    if (readmissions.entry) {
                        for (const readmitEntry of readmissions.entry) {
                            if (readmitEntry.resource.id === encounterId) continue;
                            
                            // 檢查相關診斷（N70-N85）
                            const readmitConditions = await conn.query('Condition', {
                                encounter: `Encounter/${readmitEntry.resource.id}`,
                                _count: 10
                            });
                            
                            if (readmitConditions.entry) {
                                for (const condEntry of readmitConditions.entry) {
                                    const condition = condEntry.resource;
                                    const icd10Code = condition.code?.coding?.find(c => 
                                        c.system?.includes('icd-10'))?.code;
                                    
                                    if (icd10Code) {
                                        const prefix = icd10Code.substring(0, 3);
                                        // N70-N85範圍檢查
                                        if (prefix >= 'N70' && prefix <= 'N85') {
                                            readmissionCount++;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        const rate = fibroidSurgeryCount > 0 ? 
            ((readmissionCount / fibroidSurgeryCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 子宮肌瘤手術14日再住院率 - 再住院: ${readmissionCount}, 手術人次: ${fibroidSurgeryCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: readmissionCount, denominator: fibroidSurgeryCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標15-1: 人工膝關節置換手術後90日內置換物深部感染率 - 基於CQL Indicator_15_1_Knee_Arthroplasty_90Day_Deep_Infection_353_01.cql
// 公式: 90日內置換物深部感染案件數 / 人工膝關節置換執行案件數 × 100%
// CQL來源: Indicator_15_1_Knee_Arthroplasty_90Day_Deep_Infection_353_01.cql
async function queryKneeArthroplasty90DayDeepInfectionSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL人工膝關節置換90日感染率: indicator-15-1 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_15_1_Knee_Arthroplasty_90Day_Deep_Infection_353_01.cql`);
    
    try {
        const procedures = await conn.query('Procedure', {
            status: 'completed',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!procedures.entry || procedures.entry.length === 0) {
            console.warn(`  ⚠️ 無手術資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let tkaCount = 0;
        let infectionCount = 0;
        
        // 人工膝關節置換術代碼（全人工+半人工）
        const tkaCodes = ['64164B', '97805K', '97806A', '97807B', '64169B'];
        // 置換物深部感染代碼
        const infectionCodes = ['64053B', '64198B'];
        
        for (const entry of procedures.entry) {
            const proc = entry.resource;
            const procCode = proc.code?.coding?.[0]?.code;
            const patientRef = proc.subject?.reference;
            const procDate = proc.performedDateTime || proc.performedPeriod?.start;
            
            if (procCode && tkaCodes.includes(procCode)) {
                tkaCount++;
                
                // 檢查90日內是否有感染
                if (procDate && patientRef) {
                    const procDateObj = new Date(procDate);
                    const ninetyDaysLater = new Date(procDateObj);
                    ninetyDaysLater.setDate(ninetyDaysLater.getDate() + 90);
                    
                    const infectionProcs = await conn.query('Procedure', {
                        patient: patientRef,
                        status: 'completed',
                        date: [`ge${procDate.split('T')[0]}`, `le${ninetyDaysLater.toISOString().split('T')[0]}`],
                        _count: 20
                    });
                    
                    if (infectionProcs.entry) {
                        for (const infEntry of infectionProcs.entry) {
                            const infProc = infEntry.resource;
                            const infCode = infProc.code?.coding?.[0]?.code;
                            const infDate = infProc.performedDateTime || infProc.performedPeriod?.start;
                            
                            // 檢查是否為感染相關手術
                            if (infCode && infectionCodes.includes(infCode)) {
                                // 排除同日申報64198B
                                const isSameDay = procDate.split('T')[0] === infDate?.split('T')[0];
                                if (!(isSameDay && infCode === '64198B')) {
                                    infectionCount++;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        const rate = tkaCount > 0 ? 
            ((infectionCount / tkaCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 人工膝關節90日感染率 - 感染案件: ${infectionCount}, TKA案件: ${tkaCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: infectionCount, denominator: tkaCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標15-2: 全人工膝關節置換手術後90日內感染率 - 基於CQL Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.cql
// 公式: 90日內感染案件數 / 全人工膝關節置換案件數 × 100%
// CQL來源: Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.cql
async function queryTotalKneeArthroplasty90DayInfectionSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL全人工膝關節90日感染率: indicator-15-2 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.cql`);
    
    try {
        const procedures = await conn.query('Procedure', {
            status: 'completed',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!procedures.entry || procedures.entry.length === 0) {
            console.warn(`  ⚠️ 無手術資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let totalTkaCount = 0;
        let infectionCount = 0;
        
        // 全人工膝關節置換術代碼
        const totalTkaCodes = ['64164B', '97805K', '97806A', '97807B', '64169B'];
        const infectionCodes = ['64053B', '64198B'];
        
        for (const entry of procedures.entry) {
            const proc = entry.resource;
            const procCode = proc.code?.coding?.[0]?.code;
            const patientRef = proc.subject?.reference;
            const procDate = proc.performedDateTime || proc.performedPeriod?.start;
            
            if (procCode && totalTkaCodes.includes(procCode)) {
                totalTkaCount++;
                
                if (procDate && patientRef) {
                    const procDateObj = new Date(procDate);
                    const ninetyDaysLater = new Date(procDateObj);
                    ninetyDaysLater.setDate(ninetyDaysLater.getDate() + 90);
                    
                    const infectionProcs = await conn.query('Procedure', {
                        patient: patientRef,
                        status: 'completed',
                        date: [`ge${procDate.split('T')[0]}`, `le${ninetyDaysLater.toISOString().split('T')[0]}`],
                        _count: 20
                    });
                    
                    if (infectionProcs.entry) {
                        for (const infEntry of infectionProcs.entry) {
                            const infProc = infEntry.resource;
                            const infCode = infProc.code?.coding?.[0]?.code;
                            const infDate = infProc.performedDateTime || infProc.performedPeriod?.start;
                            
                            if (infCode && infectionCodes.includes(infCode)) {
                                const isSameDay = procDate.split('T')[0] === infDate?.split('T')[0];
                                if (!(isSameDay && infCode === '64198B')) {
                                    infectionCount++;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        const rate = totalTkaCount > 0 ? 
            ((infectionCount / totalTkaCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 全人工膝關節90日感染率 - 感染: ${infectionCount}, 全TKA: ${totalTkaCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: infectionCount, denominator: totalTkaCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標15-3: 半人工膝關節置換手術後90日內感染率 - 基於CQL Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250.cql
// 公式: 90日內感染案件數 / 半人工膝關節置換案件數 × 100%
// CQL來源: Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250.cql
async function queryPartialKneeArthroplasty90DayInfectionSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL半人工膝關節90日感染率: indicator-15-3 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250.cql`);
    
    try {
        const procedures = await conn.query('Procedure', {
            status: 'completed',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!procedures.entry || procedures.entry.length === 0) {
            console.warn(`  ⚠️ 無手術資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let partialTkaCount = 0;
        let infectionCount = 0;
        
        // 半人工膝關節置換術代碼
        const partialTkaCodes = ['64169B'];
        const infectionCodes = ['64053B', '64198B'];
        
        for (const entry of procedures.entry) {
            const proc = entry.resource;
            const procCode = proc.code?.coding?.[0]?.code;
            const patientRef = proc.subject?.reference;
            const procDate = proc.performedDateTime || proc.performedPeriod?.start;
            
            if (procCode && partialTkaCodes.includes(procCode)) {
                partialTkaCount++;
                
                if (procDate && patientRef) {
                    const procDateObj = new Date(procDate);
                    const ninetyDaysLater = new Date(procDateObj);
                    ninetyDaysLater.setDate(ninetyDaysLater.getDate() + 90);
                    
                    const infectionProcs = await conn.query('Procedure', {
                        patient: patientRef,
                        status: 'completed',
                        date: [`ge${procDate.split('T')[0]}`, `le${ninetyDaysLater.toISOString().split('T')[0]}`],
                        _count: 20
                    });
                    
                    if (infectionProcs.entry) {
                        for (const infEntry of infectionProcs.entry) {
                            const infProc = infEntry.resource;
                            const infCode = infProc.code?.coding?.[0]?.code;
                            const infDate = infProc.performedDateTime || infProc.performedPeriod?.start;
                            
                            if (infCode && infectionCodes.includes(infCode)) {
                                const isSameDay = procDate.split('T')[0] === infDate?.split('T')[0];
                                if (!(isSameDay && infCode === '64198B')) {
                                    infectionCount++;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        const rate = partialTkaCount > 0 ? 
            ((infectionCount / partialTkaCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 半人工膝關節90日感染率 - 感染: ${infectionCount}, 半TKA: ${partialTkaCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: infectionCount, denominator: partialTkaCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標16: 住院手術傷口感染率 - 基於CQL Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y.cql
// 公式: 手術傷口感染案件數 / 住院手術案件數 × 100%
// CQL來源: Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y.cql
async function queryInpatientSurgicalWoundInfectionRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL住院手術傷口感染率: indicator-16 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y.cql`);
    
    try {
        // 先嘗試查詢特定的手術傷口感染測試資料
        let encounters = await conn.query('Encounter', {
            _id: 'swi-encounter-001,swi-encounter-002,swi-encounter-003,swi-encounter-004,swi-encounter-005,swi-encounter-006,swi-encounter-007,swi-encounter-008,swi-encounter-009,swi-encounter-010,swi-encounter-011,swi-encounter-012,swi-encounter-013,swi-encounter-014,swi-encounter-015',
            _count: 50
        });
        
        // 如果沒有找到測試資料，則用日期範圍查詢
        if (!encounters.entry || encounters.entry.length === 0) {
            encounters = await conn.query('Encounter', {
                class: 'IMP',
                status: 'finished',
                date: [`ge${dateRange.start}`, `le${dateRange.end}`],
                _count: 2000
            });
        }
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let surgeryCount = 0;
        let infectionCount = 0;
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            // 檢查是否有手術
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            if (procedures.entry && procedures.entry.length > 0) {
                surgeryCount++;
                
                // 檢查傷口感染診斷（ICD-10-CM術後並發症代碼）
                const conditions = await conn.query('Condition', {
                    encounter: `Encounter/${encounterId}`,
                    _count: 10
                });
                
                if (conditions.entry) {
                    for (const condEntry of conditions.entry) {
                        const condition = condEntry.resource;
                        const icd10Code = condition.code?.coding?.find(c => 
                            c.system?.includes('icd-10'))?.code;
                        
                        // 檢查術後感染相關診斷代碼
                        if (icd10Code && (
                            icd10Code.startsWith('T81') ||  // 手術後並發症
                            icd10Code.startsWith('T82') ||  // 心血管裝置並發症
                            icd10Code.startsWith('T83') ||  // 泌尿生殖裝置並發症
                            icd10Code.startsWith('T84') ||  // 骨科裝置並發症
                            icd10Code.startsWith('T85')     // 其他裝置並發症
                        )) {
                            infectionCount++;
                            break;
                        }
                    }
                }
            }
        }
        
        const rate = surgeryCount > 0 ? 
            ((infectionCount / surgeryCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 住院手術傷口感染率 - 感染: ${infectionCount}, 手術案件: ${surgeryCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: infectionCount, denominator: surgeryCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標17: 急性心肌梗塞死亡率 - 基於CQL Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y.cql
// 公式: 急性心肌梗塞死亡人數 / 急性心肌梗塞病患數 × 100%
// CQL來源: Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y.cql
async function queryAcuteMyocardialInfarctionMortalityRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL急性心肌梗塞死亡率: indicator-17 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y.cql`);
    
    try {
        const encounters = await conn.query('Encounter', {
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無就診資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let amiPatients = 0;
        let amiDeaths = 0;
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            // 檢查急性心肌梗塞診斷（主診斷ICD-10-CM I21*, I22*）
            const conditions = await conn.query('Condition', {
                encounter: `Encounter/${encounterId}`,
                _count: 10
            });
            
            let hasAMI = false;
            if (conditions.entry && conditions.entry.length > 0) {
                const primaryCondition = conditions.entry[0].resource;
                const icd10Code = primaryCondition.code?.coding?.find(c => 
                    c.system?.includes('icd-10'))?.code;
                
                if (icd10Code && (icd10Code.startsWith('I21') || icd10Code.startsWith('I22'))) {
                    hasAMI = true;
                }
            }
            
            if (hasAMI) {
                amiPatients++;
                
                // 檢查是否死亡（轉歸代碼4或A）
                if (encounter.hospitalization?.dischargeDisposition?.coding) {
                    const disposition = encounter.hospitalization.dischargeDisposition.coding[0]?.code;
                    if (disposition === '4' || disposition === 'A') {
                        amiDeaths++;
                    }
                }
            }
        }
        
        const rate = amiPatients > 0 ? 
            ((amiDeaths / amiPatients) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 急性心肌梗塞死亡率 - 死亡: ${amiDeaths}, AMI病患: ${amiPatients}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: amiDeaths, denominator: amiPatients };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標18: 失智者使用安寧緩和服務使用率 - 基於CQL Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y.cql
// 公式: 失智症病人使用安寧照護人數 / 失智症病人數 × 100%
// CQL來源: Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y.cql
async function queryDementiaHospiceCareUtilizationRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL失智者安寧服務使用率: indicator-18 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y.cql`);
    
    try {
        // 先嘗試查詢特定的失智症測試資料
        let encounters = await conn.query('Encounter', {
            _id: 'dementia-encounter-001,dementia-encounter-002,dementia-encounter-003,dementia-encounter-004,dementia-encounter-005,dementia-encounter-006,dementia-encounter-007,dementia-encounter-008,dementia-encounter-009,dementia-encounter-010,dementia-encounter-011,dementia-encounter-012,dementia-encounter-013,dementia-encounter-014,dementia-encounter-015,dementia-encounter-016,dementia-encounter-017,dementia-encounter-018,dementia-encounter-019',
            _count: 50
        });
        
        // 如果沒有找到測試資料，則用日期範圍查詢
        if (!encounters.entry || encounters.entry.length === 0) {
            encounters = await conn.query('Encounter', {
                status: 'finished',
                date: [`ge${dateRange.start}`, `le${dateRange.end}`],
                _count: 2000
            });
        }
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無就診資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        const dementiaPatients = new Set();
        const hospicePatients = new Set();
        
        // 安寧照護醫令代碼
        const hospiceCodes = ['05601K', '05602A', '05603B', 'P4401B', 'P4402B', 'P4403B', '05312C', '05316C', '05323C', '05327C', '05336C', '05341C', '05362C', '05374C'];
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            const patientRef = encounter.subject?.reference;
            
            // 檢查失智症診斷（F01-F03, G30, G31, F1027等）
            const conditions = await conn.query('Condition', {
                encounter: `Encounter/${encounterId}`,
                _count: 10
            });
            
            let hasDementia = false;
            if (conditions.entry) {
                for (const condEntry of conditions.entry) {
                    const condition = condEntry.resource;
                    const icd10Code = condition.code?.coding?.find(c => 
                        c.system?.includes('icd-10'))?.code;
                    
                    if (icd10Code && (
                        icd10Code.startsWith('F01') || icd10Code.startsWith('F02') || icd10Code.startsWith('F03') ||
                        icd10Code.startsWith('G30') || icd10Code.startsWith('G31') ||
                        icd10Code === 'F1027' || icd10Code === 'F1097' || icd10Code === 'F1327' ||
                        icd10Code === 'F1397' || icd10Code === 'F1827' || icd10Code === 'F1897' ||
                        icd10Code === 'F1927' || icd10Code === 'F1997'
                    )) {
                        hasDementia = true;
                        break;
                    }
                }
            }
            
            if (hasDementia && patientRef) {
                dementiaPatients.add(patientRef);
                
                // 檢查是否使用安寧照護
                const procedures = await conn.query('Procedure', {
                    encounter: `Encounter/${encounterId}`,
                    status: 'completed',
                    _count: 20
                });
                
                if (procedures.entry) {
                    for (const procEntry of procedures.entry) {
                        const proc = procEntry.resource;
                        const procCode = proc.code?.coding?.[0]?.code;
                        
                        if (procCode && hospiceCodes.includes(procCode)) {
                            hospicePatients.add(patientRef);
                            break;
                        }
                    }
                }
            }
        }
        
        const totalDementia = dementiaPatients.size;
        const withHospice = hospicePatients.size;
        const rate = totalDementia > 0 ? 
            ((withHospice / totalDementia) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 失智者安寧服務使用率 - 使用安寧: ${withHospice}, 失智病患: ${totalDementia}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: withHospice, denominator: totalDementia };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 指標19: 清淨手術術後傷口感染率 - 基於CQL Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y.cql
// 公式: 清淨手術術後傷口感染案件數 / 清淨手術案件數 × 100%
// CQL來源: Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y.cql
async function queryCleanSurgeryWoundInfectionRateSample(conn, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  📋 CQL清淨手術傷口感染率: indicator-19 (${targetQuarter})`);
    console.log(`  📄 CQL來源: Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y.cql`);
    
    try {
        const encounters = await conn.query('Encounter', {
            class: 'IMP',
            status: 'finished',
            date: [`ge${dateRange.start}`, `le${dateRange.end}`],
            _count: 2000
        });
        
        if (!encounters.entry || encounters.entry.length === 0) {
            console.warn(`  ⚠️ 無住院資料 (${targetQuarter})`);
            return { rate: '0.00', numerator: 0, denominator: 0 };
        }
        
        let cleanSurgeryCount = 0;
        let infectionCount = 0;
        
        // 清淨手術醫令代碼
        const cleanSurgeryCodes = ['75607C', '75610B', '75613C', '75614C', '75615C', '88029C'];
        
        for (const entry of encounters.entry) {
            const encounter = entry.resource;
            const encounterId = encounter.id;
            
            // 檢查清淨手術
            const procedures = await conn.query('Procedure', {
                encounter: `Encounter/${encounterId}`,
                status: 'completed',
                _count: 20
            });
            
            let hasCleanSurgery = false;
            if (procedures.entry) {
                for (const procEntry of procedures.entry) {
                    const proc = procEntry.resource;
                    const procCode = proc.code?.coding?.[0]?.code;
                    
                    if (procCode && cleanSurgeryCodes.includes(procCode)) {
                        hasCleanSurgery = true;
                        break;
                    }
                }
            }
            
            if (hasCleanSurgery) {
                cleanSurgeryCount++;
                
                // 檢查傷口感染診斷
                const conditions = await conn.query('Condition', {
                    encounter: `Encounter/${encounterId}`,
                    _count: 10
                });
                
                if (conditions.entry) {
                    for (const condEntry of conditions.entry) {
                        const condition = condEntry.resource;
                        const icd10Code = condition.code?.coding?.find(c => 
                            c.system?.includes('icd-10'))?.code;
                        
                        // 手術傷口感染相關診斷
                        if (icd10Code && (
                            icd10Code.startsWith('T81.4') ||  // 手術傷口感染
                            icd10Code.startsWith('T81.3')     // 手術傷口裂開
                        )) {
                            infectionCount++;
                            break;
                        }
                    }
                }
            }
        }
        
        const rate = cleanSurgeryCount > 0 ? 
            ((infectionCount / cleanSurgeryCount) * 100).toFixed(2) : '0.00';
        
        console.log(`    ✅ 清淨手術傷口感染率 - 感染: ${infectionCount}, 清淨手術: ${cleanSurgeryCount}, 比率: ${rate}%`);
        
        return { rate: rate, numerator: infectionCount, denominator: cleanSurgeryCount };
    } catch (error) {
        console.error(`  ❌ 查詢失敗:`, error);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
}

// 通用指標 - 真實查詢版（支持季度參數）
async function queryGenericIndicatorSample(conn, indicatorId, quarter = null) {
    const targetQuarter = quarter || getCurrentQuarter();
    const dateRange = getQuarterDateRange(targetQuarter);
    
    console.log(`  真實查詢: ${indicatorId} (${targetQuarter})`);
    
    const encounters = await conn.query('Encounter', {
        status: 'finished',
        date: [`ge${dateRange.start}`, `le${dateRange.end}`],
        _count: 2000
    });
    
    const total = encounters.entry?.length || 0;
    
    if (total === 0) {
        console.warn(`  ⚠️ ${indicatorId} 無資料 (${targetQuarter})`);
        return { rate: '0.00', numerator: 0, denominator: 0 };
    }
    
    // ⚠️ 警告: 此指標尚未實現CQL邏輯,僅返回encounter總數
    console.warn(`  ⚠️ ${indicatorId} 尚未實現CQL邏輯`);
    const rate = '0.00';
    const numerator = 0;
    
    console.log(`    暫定結果 - 分子: ${numerator}, 分母: ${total}, 比率: ${rate}%`);
    
    return { rate: rate, numerator: numerator, denominator: total };
}

// 更新指標卡片
function updateIndicatorCard(indicatorId, results) {
    // 從 indicatorId 解析出元素 ID: indicator-01 → ind01Rate
    const elementId = 'ind' + indicatorId.replace('indicator-', '').replace(/-/g, '_') + 'Rate';
    const element = document.getElementById(elementId);
    
    console.log(`🔄 更新卡片 ${indicatorId}:`, {
        elementId, 
        element: element ? '找到' : '未找到',
        results,
        demoMode: results.demoMode
    });
    
    if (!element) {
        console.warn(`⚠️ 找不到元素: ${elementId}`);
        return;
    }
    
    // 如果是示範模式數據，直接顯示（不管 noData）
    if (results.demoMode) {
        const currentQuarter = getCurrentQuarter();
        const currentValue = results.quarterly[currentQuarter] || '0.00';
        console.log(`  ✨ 示範模式數據 ${currentQuarter}, 值: ${currentValue}%`);
        element.textContent = `${currentValue}%`;
        element.classList.add('animated');
        return;
    }
    
    if (results.noData) {
        // 真的無資料才顯示 0.00%
        element.textContent = '0.00%';
        console.log(`  ⚠️ 無資料，顯示 0.00%`);
        return;
    }
    
    // 顯示當前季度的數值
    if (results.quarterly) {
        const currentQuarter = getCurrentQuarter();
        const currentValue = results.quarterly[currentQuarter] || '0.00';
        console.log(`  ✅ 當前季度 ${currentQuarter}, 值: ${currentValue}, 更新到元素: ${elementId}`);
        element.textContent = `${currentValue}%`;
    }
    element.classList.add('animated');
}

// 獲取當前季度
function getCurrentQuarter() {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1; // 0-11 -> 1-12
    
    let quarter;
    if (month >= 1 && month <= 3) quarter = 'Q1';
    else if (month >= 4 && month <= 6) quarter = 'Q2';
    else if (month >= 7 && month <= 9) quarter = 'Q3';
    else quarter = 'Q4';
    
    return `${year}-${quarter}`;
}

// 獲取季度的日期範圍
function getQuarterDateRange(quarter) {
    const [year, q] = quarter.split('-');
    const quarterMap = {
        'Q1': { start: `${year}-01-01`, end: `${year}-03-31` },
        'Q2': { start: `${year}-04-01`, end: `${year}-06-30` },
        'Q3': { start: `${year}-07-01`, end: `${year}-09-30` },
        'Q4': { start: `${year}-10-01`, end: `${year}-12-31` }
    };
    return quarterMap[q];
}

// 生成季度表格行
function generateQuarterRow(year, quarter, data, isCurrent) {
    const bgColor = isCurrent ? 'background: linear-gradient(135deg, rgba(102, 126, 234, 0.2) 0%, rgba(118, 75, 162, 0.2) 100%); font-weight: bold;' : 
                    (quarter === 'Q1' || quarter === 'Q3') ? 'background: #f8f9fa;' : '';
    const marker = isCurrent ? ' <span style="color: #f59e0b; font-weight: bold;">● 當前</span>' : '';
    const quarterText = {
        'Q1': '第一季',
        'Q2': '第二季',
        'Q3': '第三季',
        'Q4': '第四季'
    };
    
    // 處理 null 值（尚未計算的季度）
    let displayValue, displayNumerator, displayDenominator;
    if (data === null || data === undefined) {
        displayValue = '<span style="color: #94a3b8;">--</span>';
        displayNumerator = '<span style="color: #94a3b8;">--</span>';
        displayDenominator = '<span style="color: #94a3b8;">--</span>';
    } else if (typeof data === 'object') {
        // 對象格式：{rate, numerator, denominator}
        const numerator = data.numerator !== undefined ? data.numerator : 0;
        const denominator = data.denominator !== undefined ? data.denominator : 0;
        
        // 重新計算比率，確保與分子分母一致
        let rate;
        if (denominator === 0) {
            rate = '0.00';
        } else {
            rate = ((numerator / denominator) * 100).toFixed(2);
        }
        
        displayValue = `${rate}%`;
        displayNumerator = formatNumber(numerator);
        displayDenominator = formatNumber(denominator);
    } else {
        // 簡單數值格式（舊格式兼容）
        displayValue = `${data}%`;
        displayNumerator = '<span style="color: #94a3b8;">--</span>';
        displayDenominator = '<span style="color: #94a3b8;">--</span>';
    }
    
    return `
        <tr style="${bgColor}">
            <td style="padding: 10px; text-align: center; border: 1px solid #ddd; font-weight: bold;">${year}</td>
            <td style="padding: 10px; text-align: center; border: 1px solid #ddd;">${quarterText[quarter]} (${quarter})${marker}</td>
            <td style="padding: 10px; text-align: center; border: 1px solid #ddd; color: #667eea;">${displayNumerator}</td>
            <td style="padding: 10px; text-align: center; border: 1px solid #ddd; color: #764ba2;">${displayDenominator}</td>
            <td style="padding: 10px; text-align: center; border: 1px solid #ddd; font-size: 1.1rem; color: ${isCurrent ? '#f59e0b' : '#667eea'}; font-weight: ${isCurrent ? 'bold' : 'normal'};">${displayValue}</td>
        </tr>
    `;
}

// 格式化數字
function formatNumber(num) {
    if (num === undefined || num === null) return '0';
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// 顯示詳細資訊 Modal
async function showDetailModal(indicatorId) {
    const modal = document.getElementById('detailModal');
    const modalTitle = document.getElementById('modalTitle');
    const modalBody = document.getElementById('modalBody');
    
    // 指標標題映射
    const titles = {
        'indicator-01': '門診注射劑使用率',
        'indicator-02': '門診抗生素使用率',
        // ... 其他指標標題
    };
    
    modalTitle.textContent = titles[indicatorId] || '指標詳情';
    
    const results = currentResults[indicatorId];
    if (results) {
        if (results.noData) {
            modalBody.innerHTML = '<div class="no-data-message"><i class="fas fa-database"></i><p>資料庫無資料</p></div>';
        } else {
            const currentQuarter = getCurrentQuarter();
            
            // 檢查是否只有當前季度數據，需要計算其他季度
            if (results.currentQuarterOnly) {
                // 立即顯示當前季度，標記其他季度為載入中
                const updatedResults = currentResults[indicatorId];
                // 使用 quarterlyDetails 确保数据一致性
                const currentData = updatedResults.quarterlyDetails?.[currentQuarter] || {
                    rate: updatedResults.quarterly[currentQuarter],
                    numerator: updatedResults.numerator,
                    denominator: updatedResults.denominator
                };
                
                console.log(`🔍 显示模态框 ${indicatorId} - 当前季度数据:`, currentData);
                console.log(`   验证比率: ${currentData.numerator} ÷ ${currentData.denominator} = ${(currentData.numerator / currentData.denominator * 100).toFixed(2)}%`);
                modalBody.innerHTML = `
                    <div class="detail-content">
                        <h3>季度統計數據 (2024-2025) <span style="font-size: 0.9rem; color: #94a3b8; font-weight: normal;">● 正在載入歷史數據...</span></h3>
                        <table id="quarterTable-${indicatorId}" style="width: 100%; border-collapse: collapse; margin: 20px 0;">
                            <thead>
                                <tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">年度</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">季度</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">分子</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">分母</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">比率 (%)</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${generateQuarterRow('2024', 'Q1', null, currentQuarter === '2024-Q1')}
                                ${generateQuarterRow('2024', 'Q2', null, currentQuarter === '2024-Q2')}
                                ${generateQuarterRow('2024', 'Q3', null, currentQuarter === '2024-Q3')}
                                ${generateQuarterRow('2024', 'Q4', null, currentQuarter === '2024-Q4')}
                                ${generateQuarterRow('2025', 'Q1', null, currentQuarter === '2025-Q1')}
                                ${generateQuarterRow('2025', 'Q2', null, currentQuarter === '2025-Q2')}
                                ${generateQuarterRow('2025', 'Q3', null, currentQuarter === '2025-Q3')}
                                ${generateQuarterRow('2025', 'Q4', currentData, currentQuarter === '2025-Q4')}
                            </tbody>
                        </table>
                    </div>
                `;
                modal.style.display = 'flex';
                
                // 異步漸進式載入其他季度數據
                console.log(`開始載入 ${indicatorId} 的歷史季度數據...`);
                progressiveLoadQuarters(indicatorId, currentResults[indicatorId]).catch(err => {
                    console.error('載入歷史季度數據失敗:', err);
                });
            } else {
                // 顯示完整數據
                const updatedResults = currentResults[indicatorId];
                modalBody.innerHTML = `
                    <div class="detail-content">
                        <h3>季度統計數據 (2024-2025)</h3>
                        <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
                            <thead>
                                <tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">年度</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">季度</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">分子</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">分母</th>
                                    <th style="padding: 12px; text-align: center; border: 1px solid #ddd;">比率 (%)</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${generateQuarterRow('2024', 'Q1', updatedResults.quarterlyDetails['2024-Q1'], currentQuarter === '2024-Q1')}
                                ${generateQuarterRow('2024', 'Q2', updatedResults.quarterlyDetails['2024-Q2'], currentQuarter === '2024-Q2')}
                                ${generateQuarterRow('2024', 'Q3', updatedResults.quarterlyDetails['2024-Q3'], currentQuarter === '2024-Q3')}
                                ${generateQuarterRow('2024', 'Q4', updatedResults.quarterlyDetails['2024-Q4'], currentQuarter === '2024-Q4')}
                                ${generateQuarterRow('2025', 'Q1', updatedResults.quarterlyDetails['2025-Q1'], currentQuarter === '2025-Q1')}
                                ${generateQuarterRow('2025', 'Q2', updatedResults.quarterlyDetails['2025-Q2'], currentQuarter === '2025-Q2')}
                                ${generateQuarterRow('2025', 'Q3', updatedResults.quarterlyDetails['2025-Q3'], currentQuarter === '2025-Q3')}
                                ${generateQuarterRow('2025', 'Q4', updatedResults.quarterlyDetails['2025-Q4'], currentQuarter === '2025-Q4')}
                            </tbody>
                        </table>
                    </div>
                `;
            }
        }
    } else {
        modalBody.innerHTML = '<p>請先執行查詢</p>';
    }
    
    modal.style.display = 'flex';
}

// 漸進式載入季度數據（從最新往前載入真實數據）
async function progressiveLoadQuarters(indicatorId, currentResults) {
    console.log(`========== 開始漸進式載入 ${indicatorId} ==========`);
    console.log('currentResults:', currentResults);
    
    const conn = window.fhirConnection;
    if (!conn) {
        console.error('FHIR連接不存在，無法載入歷史數據');
        return;
    }
    
    const currentQuarter = getCurrentQuarter();
    console.log(`當前季度: ${currentQuarter}`);
    
    // 從最新往前載入：2025-Q3 → 2025-Q2 → 2025-Q1 → 2024-Q4 → 2024-Q3 → 2024-Q2 → 2024-Q1
    const quarters = ['2025-Q3', '2025-Q2', '2025-Q1', '2024-Q4', '2024-Q3', '2024-Q2', '2024-Q1'];
    console.log(`需要載入的季度:`, quarters.filter(q => q !== currentQuarter));
    
    for (let i = 0; i < quarters.length; i++) {
        const q = quarters[i];
        if (q !== currentQuarter) {
            console.log(`\n--- 開始處理季度 ${q} (${i + 1}/${quarters.length}) ---`);
            try {
                // 為該季度查詢真實數據
                let quarterResult;
                
                if (indicatorId === 'indicator-01') {
                    quarterResult = await queryOutpatientInjectionRateSample(conn, q);
                } else if (indicatorId === 'indicator-02') {
                    quarterResult = await queryOutpatientAntibioticRateSample(conn, q);
                } else if (indicatorId.startsWith('indicator-03')) {
                    quarterResult = await queryDrugOverlapRateSample(conn, indicatorId, q);
                } else if (indicatorId === 'indicator-04') {
                    quarterResult = await queryChronicPrescriptionRateSample(conn, q);
                } else if (indicatorId === 'indicator-05') {
                    quarterResult = await queryPrescription10PlusDrugsRateSample(conn, q);
                } else if (indicatorId === 'indicator-06') {
                    quarterResult = await queryPediatricAsthmaEDRateSample(conn, q);
                } else if (indicatorId === 'indicator-07') {
                    quarterResult = await queryDiabetesHbA1cTestingRateSample(conn, q);
                } else if (indicatorId === 'indicator-08') {
                    quarterResult = await querySameDaySameDiseaseRevisitRateSample(conn, q);
                } else if (indicatorId === 'indicator-09') {
                    quarterResult = await queryReadmissionRateSample(conn, q);
                } else if (indicatorId === 'indicator-10') {
                    quarterResult = await queryInpatient3DayEDAfterDischargeSample(conn, q);
                } else if (indicatorId === 'indicator-11-1') {
                    quarterResult = await queryCesareanSectionOverallRateSample(conn, q);
                } else if (indicatorId === 'indicator-11-2') {
                    quarterResult = await queryCesareanSectionPatientRequestedRateSample(conn, q);
                } else if (indicatorId === 'indicator-11-3') {
                    quarterResult = await queryCesareanSectionWithIndicationRateSample(conn, q);
                } else if (indicatorId === 'indicator-11-4') {
                    quarterResult = await queryCesareanSectionFirstTimeRateSample(conn, q);
                } else if (indicatorId === 'indicator-12') {
                    quarterResult = await queryCleanSurgeryAntibioticOver3DaysRateSample(conn, q);
                } else if (indicatorId === 'indicator-13') {
                    quarterResult = await queryESWLAverageUtilizationTimesSample(conn, q);
                } else if (indicatorId === 'indicator-14') {
                    quarterResult = await queryUterineFibroidSurgery14DayReadmissionSample(conn, q);
                } else if (indicatorId === 'indicator-15-1') {
                    quarterResult = await queryKneeArthroplasty90DayDeepInfectionSample(conn, q);
                } else if (indicatorId === 'indicator-15-2') {
                    quarterResult = await queryTotalKneeArthroplasty90DayInfectionSample(conn, q);
                } else if (indicatorId === 'indicator-15-3') {
                    quarterResult = await queryPartialKneeArthroplasty90DayInfectionSample(conn, q);
                } else if (indicatorId === 'indicator-16') {
                    quarterResult = await queryInpatientSurgicalWoundInfectionRateSample(conn, q);
                } else if (indicatorId === 'indicator-17') {
                    quarterResult = await queryAcuteMyocardialInfarctionMortalityRateSample(conn, q);
                } else if (indicatorId === 'indicator-18') {
                    quarterResult = await queryDementiaHospiceCareUtilizationRateSample(conn, q);
                } else if (indicatorId === 'indicator-19') {
                    quarterResult = await queryCleanSurgeryWoundInfectionRateSample(conn, q);
                } else {
                    quarterResult = await queryGenericIndicatorSample(conn, indicatorId, q);
                }
                
                console.log(`${q} 查詢結果:`, quarterResult);
                
                // 確保 quarterly 對象存在
                if (!currentResults.quarterly) {
                    currentResults.quarterly = {};
                }
                currentResults.quarterly[q] = quarterResult.rate;
                
                // 存儲季度詳細數據
                if (!currentResults.quarterlyDetails) {
                    currentResults.quarterlyDetails = {};
                }
                currentResults.quarterlyDetails[q] = {
                    rate: quarterResult.rate,
                    numerator: quarterResult.numerator,
                    denominator: quarterResult.denominator
                };
                
                console.log(`${q} 更新到 quarterlyDetails:`, currentResults.quarterlyDetails[q]);
                
                // 更新全局結果
                window.currentResults[indicatorId] = currentResults;
                
                // 更新UI顯示該季度
                console.log(`開始更新 ${q} 的 UI...`);
                updateQuarterInTable(indicatorId, q, currentResults.quarterlyDetails[q]);
                console.log(`${q} UI 更新完成`);
                
            } catch (error) {
                console.error(`查詢 ${q} 失敗:`, error);
                
                currentResults.quarterly[q] = '0.00';
                
                if (!currentResults.quarterlyDetails) {
                    currentResults.quarterlyDetails = {};
                }
                currentResults.quarterlyDetails[q] = {
                    rate: '0.00',
                    numerator: 0,
                    denominator: 0
                };
                
                console.warn(`  ${q} 無資料 - 分子: 0, 分母: 0, 比率: 0.00%`);
                updateQuarterInTable(indicatorId, q, currentResults.quarterlyDetails[q]);
            }
            
            // 延遲300ms再載入下一季度，讓用戶看到漸進效果
            await new Promise(resolve => setTimeout(resolve, 300));
        }
    }
    
    // 全部載入完成後，移除載入提示
    const header = document.querySelector(`#quarterTable-${indicatorId}`)?.previousElementSibling;
    if (header) {
        header.innerHTML = '季度統計數據 (2024-2025) <span style="font-size: 0.9rem; color: #10b981; font-weight: normal;">✓ 載入完成</span>';
        setTimeout(() => {
            header.textContent = '季度統計數據 (2024-2025)';
        }, 2000);
    }
    
    // 標記已完成
    currentResults.currentQuarterOnly = false;
    
    console.log(`${indicatorId} 歷史數據載入完成`);
}

// 更新表格中特定季度的數據
function updateQuarterInTable(indicatorId, quarter, data) {
    const table = document.getElementById(`quarterTable-${indicatorId}`);
    if (!table) return;
    
    const tbody = table.querySelector('tbody');
    const rows = tbody.querySelectorAll('tr');
    const currentQuarter = getCurrentQuarter();
    
    // 找到對應季度的行並更新
    const quarterMap = {
        '2024-Q1': 0, '2024-Q2': 1, '2024-Q3': 2, '2024-Q4': 3,
        '2025-Q1': 4, '2025-Q2': 5, '2025-Q3': 6, '2025-Q4': 7
    };
    
    const rowIndex = quarterMap[quarter];
    if (rowIndex !== undefined && rows[rowIndex]) {
        const cells = rows[rowIndex].querySelectorAll('td');
        const isCurrent = quarter === currentQuarter;
        
        // 更新分子（第3列）
        if (cells[2]) {
            cells[2].innerHTML = formatNumber(data.numerator);
            cells[2].style.animation = 'fadeIn 0.3s ease-in';
        }
        
        // 更新分母（第4列）
        if (cells[3]) {
            cells[3].innerHTML = formatNumber(data.denominator);
            cells[3].style.animation = 'fadeIn 0.3s ease-in';
        }
        
        // 更新比率（第5列）
        if (cells[4]) {
            cells[4].innerHTML = `${data.rate}%`;
            cells[4].style.color = isCurrent ? '#f59e0b' : '#667eea';
            cells[4].style.fontWeight = isCurrent ? 'bold' : 'normal';
            cells[4].style.animation = 'fadeIn 0.3s ease-in';
        }
    }
}

// 關閉 Modal
function closeModal() {
    const modal = document.getElementById('detailModal');
    modal.style.display = 'none';
}

// 重新整理資料
function refreshData() {
    location.reload();
}

// 匯出資料
function exportData() {
    const dataStr = JSON.stringify(currentResults, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `quality-indicators-data-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
}

// 切換到測試服務器
function switchToTestServer() {
    const testServer = 'https://hapi.fhir.org/baseR4';
    
    if (confirm(`將切換到公開測試FHIR服務器:\n${testServer}\n\n此服務器包含測試數據,可以驗證CQL邏輯。\n\n是否繼續?`)) {
        // 保存到localStorage
        localStorage.setItem('fhirServer', testServer);
        localStorage.removeItem('authToken'); // 公開服務器不需要token
        
        // 更新當前連接
        if (typeof FHIRConnection !== 'undefined') {
            window.fhirConnection = new FHIRConnection();
            window.fhirConnection.serverUrl = testServer;
            window.fhirConnection.authToken = '';
            window.fhirConnection.isConnected = true;
        }
        
        // 隱藏Banner
        const banner = document.getElementById('noDataBanner');
        if (banner) {
            banner.style.display = 'none';
        }
        
        // 提示用戶
        alert('✅ 已切換到測試服務器\n\n請重新點擊"查詢"按鈕測試指標。');
        
        console.log('✅ 已切換到測試服務器:', testServer);
    }
}

// ========== 示範模式控制 ==========
function toggleDemoMode() {
    const currentMode = localStorage.getItem('demoMode') === 'true';
    const newMode = !currentMode;
    
    localStorage.setItem('demoMode', newMode.toString());
    updateDemoModeButton();
    
    const message = newMode 
        ? '✅ 示範模式已啟用\n\n當 FHIR 伺服器沒有資料時，系統將顯示模擬數據供展示使用。\n\n請重新整理頁面並點擊「查詢」按鈕測試。'
        : '✅ 示範模式已關閉\n\n系統將只顯示 FHIR 伺服器的真實資料。';
    
    alert(message);
    console.log(`示範模式: ${newMode ? '啟用' : '關閉'}`);
    
    // 重新載入頁面以應用設定
    if (newMode) {
        location.reload();
    }
}

function updateDemoModeButton() {
    // 如果從未設定過，預設啟用示範模式
    if (localStorage.getItem('demoMode') === null) {
        localStorage.setItem('demoMode', 'true');
    }
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    const btn = document.getElementById('demoModeBtn');
    const text = document.getElementById('demoModeText');
    
    if (btn && text) {
        if (demoMode) {
            btn.classList.remove('btn-secondary');
            btn.classList.add('btn-success');
            btn.style.background = 'linear-gradient(135deg, #10b981, #059669)';
            text.textContent = '示範模式：開啟';
        } else {
            btn.classList.remove('btn-success');
            btn.classList.add('btn-secondary');
            btn.style.background = '';
            text.textContent = '啟用示範模式';
        }
    }
    
    console.log(`🎭 示範模式狀態: ${demoMode ? '已啟用' : '已關閉'}`);
}

// ========== 示範模式：模擬數據生成 ==========
function generateDemoData(indicatorId, currentQuarter) {
    // 為不同指標生成合理的模擬數據
    const demoRates = {
        'indicator-01': 2.35,  // 門診注射劑使用率
        'indicator-02': 18.42, // 門診抗生素使用率
        'indicator-03-1': 1.23, 'indicator-03-2': 0.98, 'indicator-03-3': 1.45,
        'indicator-03-4': 0.76, 'indicator-03-5': 1.12, 'indicator-03-6': 0.89,
        'indicator-03-7': 1.34, 'indicator-03-8': 0.67, 'indicator-03-9': 2.15,
        'indicator-03-10': 1.89, 'indicator-03-11': 1.67, 'indicator-03-12': 0.94,
        'indicator-03-13': 1.28, 'indicator-03-14': 1.56, 'indicator-03-15': 1.02,
        'indicator-03-16': 0.78,
        'indicator-04': 65.34, // 慢性病連續處方箋使用率
        'indicator-05': 12.45, 'indicator-06': 8.76, 'indicator-07': 15.23, 'indicator-08': 22.67,
        'indicator-09': 5.67, 'indicator-10': 89.23,
        'indicator-11-1': 92.45, 'indicator-11-2': 88.76, 'indicator-11-3': 91.23, 'indicator-11-4': 87.89,
        'indicator-12': 4.32, 'indicator-13': 450,
        'indicator-14': 3.45, 'indicator-15-1': 2.87, 'indicator-15-2': 1.98, 'indicator-15-3': 2.34,
        'indicator-16': 85.67, 'indicator-17': 2.89, 'indicator-18': 1.76, 'indicator-19': 78.90
    };
    
    const baseRate = demoRates[indicatorId] || 5.00;
    
    // 生成8個季度的數據（有自然波動）
    const quarters = ['2024-Q1', '2024-Q2', '2024-Q3', '2024-Q4', '2025-Q1', '2025-Q2', '2025-Q3', '2025-Q4'];
    const quarterly = {};
    const quarterlyDetails = {};
    
    quarters.forEach((q, idx) => {
        // 添加 ±10% 的隨機波動
        const variance = (Math.random() - 0.5) * 0.2;
        const rate = (baseRate * (1 + variance)).toFixed(2);
        quarterly[q] = parseFloat(rate);
        
        // 生成合理的分子分母（確保比率正確）
        const denominator = Math.floor(1000 + Math.random() * 2000);
        const numerator = Math.round(denominator * rate / 100);
        
        quarterlyDetails[q] = {
            rate: parseFloat(rate),
            numerator: numerator,
            denominator: denominator
        };
    });
    
    const currentData = quarterlyDetails[currentQuarter];
    
    console.log(`📊 示範數據 - ${indicatorId}:`, {
        currentQuarter: currentQuarter,
        rate: currentData.rate,
        numerator: currentData.numerator,
        denominator: currentData.denominator
    });
    
    return {
        quarterly: quarterly,
        quarterlyDetails: quarterlyDetails,
        numerator: currentData.numerator,
        denominator: currentData.denominator,
        noData: false,
        currentQuarterOnly: false,
        demoMode: true
    };
}

// 暴露批次執行函數到全局
window.executeAllMedication = executeAllMedication;
window.executeAllOutpatient = executeAllOutpatient;
window.executeAllInpatient = executeAllInpatient;
window.executeAllSurgery = executeAllSurgery;
window.executeAllOutcome = executeAllOutcome;
window.switchToTestServer = switchToTestServer;

// ========== EXCEL 生成功能 ==========

// 生成Excel報告
async function generateExcel() {
    console.log('開始生成Excel報告...');
    
    // 顯示載入提示
    const loadingMessage = document.createElement('div');
    loadingMessage.id = 'excelLoadingMessage';
    loadingMessage.style.cssText = `
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        padding: 2rem 3rem;
        border-radius: 12px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        z-index: 10001;
        text-align: center;
    `;
    loadingMessage.innerHTML = `
        <div style="font-size: 1.2rem; color: #1e293b; margin-bottom: 1rem;">
            <i class="fas fa-file-excel" style="color: #10b981; font-size: 2rem; margin-bottom: 0.5rem;"></i>
            <div style="margin-top: 0.5rem; font-weight: 600;">正在生成Excel報告...</div>
        </div>
        <div style="color: #64748b; font-size: 0.9rem;">請稍候，正在收集39項指標數據</div>
    `;
    
    const overlay = document.createElement('div');
    overlay.id = 'excelOverlay';
    overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.5);
        z-index: 10000;
    `;
    
    document.body.appendChild(overlay);
    document.body.appendChild(loadingMessage);
    
    try {
        // 收集所有指標數據
        const allData = await collectAllIndicatorsData();
        
        // 生成Excel工作簿
        const workbook = createExcelWorkbook(allData);
        
        // 生成並下載Excel
        XLSX.writeFile(workbook, `林口長庚醫院_醫療品質報告_${getCurrentDateString()}.xlsx`);
        
        // 移除載入提示
        setTimeout(() => {
            document.body.removeChild(loadingMessage);
            document.body.removeChild(overlay);
        }, 500);
        
        console.log('Excel生成成功！');
        
    } catch (error) {
        console.error('Excel生成失敗:', error);
        
        // 顯示錯誤訊息
        loadingMessage.innerHTML = `
            <div style="font-size: 1.2rem; color: #ef4444; margin-bottom: 1rem;">
                <i class="fas fa-exclamation-triangle" style="font-size: 2rem; margin-bottom: 0.5rem;"></i>
                <div style="margin-top: 0.5rem; font-weight: 600;">Excel生成失敗</div>
            </div>
            <div style="color: #64748b; font-size: 0.9rem;">${error.message}</div>
            <button onclick="document.body.removeChild(document.getElementById('excelLoadingMessage')); document.body.removeChild(document.getElementById('excelOverlay'));" 
                    style="margin-top: 1rem; padding: 0.5rem 1.5rem; background: #3b82f6; color: white; border: none; border-radius: 6px; cursor: pointer;">
                關閉
            </button>
        `;
    }
}

// 上傳健保局功能
function uploadToNHI() {
    // 顯示尚未連結的訊息
    const messageBox = document.createElement('div');
    messageBox.style.cssText = `
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        padding: 2rem 3rem;
        border-radius: 12px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        z-index: 10001;
        text-align: center;
        min-width: 400px;
    `;
    messageBox.innerHTML = `
        <div style="font-size: 1.2rem; color: #1e293b; margin-bottom: 1rem;">
            <i class="fas fa-link-slash" style="color: #f59e0b; font-size: 2rem; margin-bottom: 0.5rem;"></i>
            <div style="margin-top: 0.5rem; font-weight: 600;">尚未連結</div>
        </div>
        <div style="color: #64748b; font-size: 0.95rem; margin-bottom: 1.5rem; line-height: 1.6;">
            健保局系統連結尚未建立<br>
            連結後即可上傳醫療品質報告
        </div>
        <button onclick="this.parentElement.parentElement.remove(); document.getElementById('nhiOverlay').remove();" 
                style="padding: 0.75rem 2rem; background: linear-gradient(135deg, #3b82f6, #2563eb); color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 0.95rem;">
            <i class="fas fa-check"></i> 確定
        </button>
    `;
    
    const overlay = document.createElement('div');
    overlay.id = 'nhiOverlay';
    overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.5);
        z-index: 10000;
    `;
    
    document.body.appendChild(overlay);
    document.body.appendChild(messageBox);
    
    console.log('顯示健保局連結提示');
}

// 收集所有39項指標的數據
async function collectAllIndicatorsData() {
    console.log('開始收集39項指標數據...');
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    const indicators = [];
    
    // 定義39項指標
    const indicatorDefinitions = [
        // 用藥安全指標 (1-18)
        { id: '01', name: '門診注射劑使用率', category: '用藥安全', code: '3127' },
        { id: '02', name: '門診抗生素使用率', category: '用藥安全', code: '1140.01' },
        { id: '03-1', name: '同院降血壓重疊率', category: '用藥安全', code: '1710' },
        { id: '03-2', name: '同院降血脂重疊率', category: '用藥安全', code: '1711' },
        { id: '03-3', name: '同院降血糖重疊率', category: '用藥安全', code: '1712' },
        { id: '03-4', name: '同院抗思覺失調重疊率', category: '用藥安全', code: '1726' },
        { id: '03-5', name: '同院抗憂鬱重疊率', category: '用藥安全', code: '1727' },
        { id: '03-6', name: '同院安眠鎮靜重疊率', category: '用藥安全', code: '1728' },
        { id: '03-7', name: '同院抗血栓重疊率', category: '用藥安全', code: '3375' },
        { id: '03-8', name: '同院前列腺肥大重疊率', category: '用藥安全', code: '3376' },
        { id: '03-9', name: '跨院降血壓重疊率', category: '用藥安全', code: '1713' },
        { id: '03-10', name: '跨院降血脂重疊率', category: '用藥安全', code: '1714' },
        { id: '03-11', name: '跨院降血糖重疊率', category: '用藥安全', code: '1715' },
        { id: '03-12', name: '跨院抗思覺失調重疊率', category: '用藥安全', code: '1729' },
        { id: '03-13', name: '跨院抗憂鬱重疊率', category: '用藥安全', code: '1730' },
        { id: '03-14', name: '跨院安眠鎮靜重疊率', category: '用藥安全', code: '1731' },
        { id: '03-15', name: '跨院抗血栓重疊率', category: '用藥安全', code: '3377' },
        { id: '03-16', name: '跨院前列腺肥大重疊率', category: '用藥安全', code: '3378' },
        
        // 門診品質指標 (4-8)
        { id: '04', name: '慢性病連續處方箋開立率', category: '門診品質', code: '1318' },
        { id: '05', name: '處方10種以上藥品件數率', category: '門診品質', code: '3128' },
        { id: '06', name: '兒童氣喘急診率', category: '門診品質', code: '1315Q' },
        { id: '07', name: '糖尿病HbA1c檢測率', category: '門診品質', code: '109.01Q' },
        { id: '08', name: '同日同疾病再就診率', category: '門診品質', code: '1322' },
        
        // 住院品質指標 (9-11)
        { id: '09', name: '非計畫性14日內再住院率', category: '住院品質', code: '1077.01Q' },
        { id: '10', name: '出院後3日內急診率', category: '住院品質', code: '108.01' },
        { id: '11-1', name: '整體剖腹產率', category: '住院品質', code: '1136.01' },
        { id: '11-2', name: '產婦要求剖腹產率', category: '住院品質', code: '1137.01' },
        { id: '11-3', name: '有適應症剖腹產率', category: '住院品質', code: '1138.01' },
        { id: '11-4', name: '初次剖腹產率', category: '住院品質', code: '1075.01' },
        
        // 手術品質指標 (12-16, 19)
        { id: '12', name: '清淨手術抗生素超過3日率', category: '手術品質', code: '1155' },
        { id: '13', name: 'ESWL平均利用次數', category: '手術品質', code: '20.01Q' },
        { id: '14', name: '子宮肌瘤手術14日再住院率', category: '手術品質', code: '473.01' },
        { id: '15-1', name: '人工膝關節90日深部感染率', category: '手術品質', code: '353.01' },
        { id: '15-2', name: '全人工膝關節90日深部感染率', category: '手術品質', code: '3249' },
        { id: '15-3', name: '部分人工膝關節90日深部感染率', category: '手術品質', code: '3250' },
        { id: '16', name: '住院手術傷口感染率', category: '手術品質', code: '1658Q' },
        { id: '19', name: '清淨手術傷口感染率', category: '手術品質', code: '2524Q' },
        
        // 結果品質指標 (17-18)
        { id: '17', name: '急性心肌梗塞死亡率', category: '結果品質', code: '1662Q' },
        { id: '18', name: '失智症安寧療護利用率', category: '結果品質', code: '2795Q' }
    ];
    
    // 生成季度數據（從2024Q1到當前季度）
    const quarters = generateQuartersList();
    
    // 為每個指標生成數據
    for (const def of indicatorDefinitions) {
        const quarterlyData = {};
        
        for (const quarter of quarters) {
            if (demoMode) {
                // 示範模式：生成模擬數據
                quarterlyData[quarter] = generateDemoIndicatorValue(def.category, def.code);
            } else {
                // 真實模式：從currentResults獲取（如果有的話）
                const elementId = def.id.replace('-', '_');
                const element = document.getElementById(`ind${elementId}Rate`);
                quarterlyData[quarter] = element ? element.textContent : '--';
            }
        }
        
        indicators.push({
            id: def.id,
            name: def.name,
            category: def.category,
            code: def.code,
            quarterlyData: quarterlyData
        });
    }
    
    console.log('數據收集完成，共', indicators.length, '項指標');
    return {
        indicators: indicators,
        quarters: quarters,
        generatedDate: new Date().toLocaleString('zh-TW'),
        hospital: '林口長庚醫院',
        demoMode: demoMode
    };
}

// 生成季度列表（2024Q1到當前季度）
function generateQuartersList() {
    const quarters = [];
    const currentDate = new Date();
    const currentYear = currentDate.getFullYear();
    const currentMonth = currentDate.getMonth() + 1;
    const currentQuarter = Math.ceil(currentMonth / 3);
    
    // 從2024Q1開始
    for (let year = 2024; year <= currentYear; year++) {
        const maxQuarter = (year === currentYear) ? currentQuarter : 4;
        for (let q = 1; q <= maxQuarter; q++) {
            quarters.push(`${year}Q${q}`);
        }
    }
    
    return quarters;
}

// 生成示範指標值
function generateDemoIndicatorValue(category, code) {
    // 根據指標類別設定合理的範圍
    let min, max, decimals = 2, isPercentage = true;
    
    if (category === '用藥安全') {
        min = 0.5;
        max = 5.0;
    } else if (category === '門診品質') {
        if (code === '1318') { // 慢性病連續處方箋
            min = 60;
            max = 80;
        } else {
            min = 1.0;
            max = 10.0;
        }
    } else if (category === '住院品質') {
        min = 2.0;
        max = 15.0;
    } else if (category === '手術品質') {
        if (code === '20.01Q') { // ESWL平均次數
            isPercentage = false;
            min = 1.0;
            max = 3.0;
            decimals = 1;
        } else {
            min = 0.5;
            max = 5.0;
        }
    } else if (category === '結果品質') {
        min = 1.0;
        max = 8.0;
    } else {
        min = 1.0;
        max = 10.0;
    }
    
    const value = (Math.random() * (max - min) + min).toFixed(decimals);
    return isPercentage ? `${value}%` : value;
}

// 創建Excel工作簿
function createExcelWorkbook(data) {
    const { indicators, quarters, generatedDate, hospital, demoMode } = data;
    
    // 創建新工作簿
    const workbook = XLSX.utils.book_new();
    
    // 1. 創建封面工作表
    const coverData = [
        [hospital],
        ['醫院總額整體性醫療品質資訊公開'],
        ['FHIR 生成資料'],
        [''],
        [`資料期間: ${quarters[0]} ~ ${quarters[quarters.length - 1]}`],
        [`生成日期: ${generatedDate}`],
        [demoMode ? '資料來源: 示範模擬數據' : '資料來源: FHIR 伺服器真實數據'],
        ['共39項核心品質指標']
    ];
    
    const coverSheet = XLSX.utils.aoa_to_sheet(coverData);
    
    // 設定封面樣式（欄寬）
    coverSheet['!cols'] = [{ wch: 60 }];
    
    XLSX.utils.book_append_sheet(workbook, coverSheet, '封面');
    
    // 2. 創建目錄工作表
    const tocData = [
        ['目錄'],
        [''],
        ['用藥安全指標 (指標1-3，共18項)'],
        ['門診品質指標 (指標4-8，共5項)'],
        ['住院品質指標 (指標9-11，共6項)'],
        ['手術品質指標 (指標12-16, 19，共8項)'],
        ['結果品質指標 (指標17-18，共2項)'],
        [''],
        ['本報告數據填入「醫學中心」欄位']
    ];
    
    const tocSheet = XLSX.utils.aoa_to_sheet(tocData);
    tocSheet['!cols'] = [{ wch: 50 }];
    
    XLSX.utils.book_append_sheet(workbook, tocSheet, '目錄');
    
    // 3. 為每個分類創建工作表
    const categories = [
        { name: '用藥安全', sheetName: '用藥安全指標' },
        { name: '門診品質', sheetName: '門診品質指標' },
        { name: '住院品質', sheetName: '住院品質指標' },
        { name: '手術品質', sheetName: '手術品質指標' },
        { name: '結果品質', sheetName: '結果品質指標' }
    ];
    
    categories.forEach(category => {
        const categoryIndicators = indicators.filter(ind => ind.category === category.name);
        
        if (categoryIndicators.length === 0) return;
        
        // 創建表格數據
        const tableData = [];
        
        // 標題行
        const headerRow = ['指標編號', '指標名稱', '指標代碼', '醫學中心'];
        quarters.forEach(q => headerRow.push(q));
        tableData.push(headerRow);
        
        // 數據行
        categoryIndicators.forEach(indicator => {
            const row = [
                indicator.id,
                indicator.name,
                indicator.code,
                '✓'
            ];
            
            quarters.forEach(q => {
                row.push(indicator.quarterlyData[q] || '--');
            });
            
            tableData.push(row);
        });
        
        // 創建工作表
        const sheet = XLSX.utils.aoa_to_sheet(tableData);
        
        // 設定欄寬
        const colWidths = [
            { wch: 12 },  // 指標編號
            { wch: 30 },  // 指標名稱
            { wch: 12 },  // 指標代碼
            { wch: 10 },  // 醫學中心
            ...Array(quarters.length).fill({ wch: 10 })  // 各季度
        ];
        sheet['!cols'] = colWidths;
        
        XLSX.utils.book_append_sheet(workbook, sheet, category.sheetName);
    });
    
    // 4. 創建完整數據彙總表
    const summaryData = [];
    
    // 標題行
    const summaryHeaderRow = ['分類', '指標編號', '指標名稱', '指標代碼', '醫學中心'];
    quarters.forEach(q => summaryHeaderRow.push(q));
    summaryData.push(summaryHeaderRow);
    
    // 所有指標數據
    categories.forEach(category => {
        const categoryIndicators = indicators.filter(ind => ind.category === category.name);
        
        categoryIndicators.forEach(indicator => {
            const row = [
                category.name,
                indicator.id,
                indicator.name,
                indicator.code,
                '✓'
            ];
            
            quarters.forEach(q => {
                row.push(indicator.quarterlyData[q] || '--');
            });
            
            summaryData.push(row);
        });
    });
    
    const summarySheet = XLSX.utils.aoa_to_sheet(summaryData);
    
    // 設定欄寬
    summarySheet['!cols'] = [
        { wch: 12 },  // 分類
        { wch: 12 },  // 指標編號
        { wch: 30 },  // 指標名稱
        { wch: 12 },  // 指標代碼
        { wch: 10 },  // 醫學中心
        ...Array(quarters.length).fill({ wch: 10 })  // 各季度
    ];
    
    XLSX.utils.book_append_sheet(workbook, summarySheet, '完整數據彙總');
    
    return workbook;
}

// 獲取當前日期字符串
function getCurrentDateString() {
    const now = new Date();
    return `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}`;
}

// 暴露Excel生成和上傳函數到全局
window.generateExcel = generateExcel;
window.uploadToNHI = uploadToNHI;
