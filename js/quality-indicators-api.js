// ========== 醫療品質指標儀表板邏輯 - API版 ==========
// 透過後端 CQL Engine 執行查詢 (39項指標)
console.log('📌 quality-indicators-api.js BUILD_VERSION: 20260401a');

let currentResults = {};
window.qualityResults = currentResults;

// ========== 指標定義 ==========
const INDICATORS = {
    'indicator-01':  { cql: 'Indicator_01_Outpatient_Injection_Usage_Rate_3127', title: '門診注射劑使用率', code: '3127', metric: '使用率', category: 'medication', rateId: 'ind01Rate', suffix: '_01' },
    'indicator-02':  { cql: 'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01', title: '門診抗生素使用率', code: '1140.01', metric: '使用率', category: 'medication', rateId: 'ind02Rate', suffix: '_02' },
    'indicator-03-1':  { cql: 'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710', title: '同院降血壓藥重疊', code: '1710', metric: '重疊率', category: 'medication', rateId: 'ind03_1Rate', suffix: '_03_1' },
    'indicator-03-2':  { cql: 'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711', title: '同院降血脂藥重疊', code: '1711', metric: '重疊率', category: 'medication', rateId: 'ind03_2Rate', suffix: '_03_2' },
    'indicator-03-3':  { cql: 'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712', title: '同院降血糖藥重疊', code: '1712', metric: '重疊率', category: 'medication', rateId: 'ind03_3Rate', suffix: '_03_3' },
    'indicator-03-4':  { cql: 'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726', title: '同院抗思覺失調藥重疊', code: '1726', metric: '重疊率', category: 'medication', rateId: 'ind03_4Rate', suffix: '_03_4' },
    'indicator-03-5':  { cql: 'Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727', title: '同院抗憂鬱藥重疊', code: '1727', metric: '重疊率', category: 'medication', rateId: 'ind03_5Rate', suffix: '_03_5' },
    'indicator-03-6':  { cql: 'Indicator_03_6_Same_Hospital_Sedative_Overlap_1728', title: '同院安眠鎮靜藥重疊', code: '1728', metric: '重疊率', category: 'medication', rateId: 'ind03_6Rate', suffix: '_03_6' },
    'indicator-03-7':  { cql: 'Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375', title: '同院抗血栓藥重疊', code: '3375', metric: '重疊率', category: 'medication', rateId: 'ind03_7Rate', suffix: '_03_7' },
    'indicator-03-8':  { cql: 'Indicator_03_8_Same_Hospital_Prostate_Overlap_3376', title: '同院前列腺藥重疊', code: '3376', metric: '重疊率', category: 'medication', rateId: 'ind03_8Rate', suffix: '_03_8' },
    'indicator-03-9':  { cql: 'Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713', title: '跨院降血壓藥重疊', code: '1713', metric: '重疊率', category: 'medication', rateId: 'ind03_9Rate', suffix: '_03_9' },
    'indicator-03-10': { cql: 'Indicator_03_10_Cross_Hospital_Lipid_Lowering_Overlap_1714', title: '跨院降血脂藥重疊', code: '1714', metric: '重疊率', category: 'medication', rateId: 'ind03_10Rate', suffix: '_03_10' },
    'indicator-03-11': { cql: 'Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715', title: '跨院降血糖藥重疊', code: '1715', metric: '重疊率', category: 'medication', rateId: 'ind03_11Rate', suffix: '_03_11' },
    'indicator-03-12': { cql: 'Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729', title: '跨院抗思覺失調藥重疊', code: '1729', metric: '重疊率', category: 'medication', rateId: 'ind03_12Rate', suffix: '_03_12' },
    'indicator-03-13': { cql: 'Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730', title: '跨院抗憂鬱藥重疊', code: '1730', metric: '重疊率', category: 'medication', rateId: 'ind03_13Rate', suffix: '_03_13' },
    'indicator-03-14': { cql: 'Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731', title: '跨院安眠鎮靜藥重疊', code: '1731', metric: '重疊率', category: 'medication', rateId: 'ind03_14Rate', suffix: '_03_14' },
    'indicator-03-15': { cql: 'Indicator_03_15_Cross_Hospital_Antithrombotic_Overlap_3377', title: '跨院抗血栓藥重疊', code: '3377', metric: '重疊率', category: 'medication', rateId: 'ind03_15Rate', suffix: '_03_15' },
    'indicator-03-16': { cql: 'Indicator_03_16_Cross_Hospital_Prostate_Overlap_3378', title: '跨院前列腺藥重疊', code: '3378', metric: '重疊率', category: 'medication', rateId: 'ind03_16Rate', suffix: '_03_16' },
    'indicator-04':  { cql: 'Indicator_04_Chronic_Continuous_Prescription_Rate_1318', title: '慢性病連處籤使用率', code: '1318', metric: '使用率', category: 'outpatient', rateId: 'ind04Rate', suffix: '_04' },
    'indicator-05':  { cql: 'Indicator_05_Prescription_10_Plus_Drugs_Rate_3128', title: '處方10種以上藥品率', code: '3128', metric: '比率', category: 'outpatient', rateId: 'ind05Rate', suffix: '_05' },
    'indicator-06':  { cql: 'Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y', title: '小兒氣喘急診率', code: '1315Q/1317Y', metric: '急診率', category: 'outpatient', rateId: 'ind06Rate', suffix: '_06' },
    'indicator-07':  { cql: 'Indicator_07_Diabetes_HbA1c_Testing_Rate_109_01Q_110_01Y', title: '糖尿病HbA1c檢驗率', code: '109.01Q/110.01Y', metric: '檢驗率', category: 'outpatient', rateId: 'ind07Rate', suffix: '_07' },
    'indicator-08':  { cql: 'Indicator_08_Same_Day_Same_Disease_Revisit_Rate_1322', title: '同日同院同疾病再就診率', code: '1322', metric: '再就診率', category: 'outpatient', rateId: 'ind08Rate', suffix: '_08' },
    'indicator-09':  { cql: 'Indicator_09_Unplanned_14Day_Readmission_Rate_1077_01Q_1809Y', title: '14天內非計畫再入院率', code: '1077.01Q/1809Y', metric: '再入院率', category: 'inpatient', rateId: 'ind09Rate', suffix: '_09' },
    'indicator-10':  { cql: 'Indicator_10_Inpatient_3Day_ED_After_Discharge_108_01', title: '出院後3天內急診率', code: '108.01', metric: '急診率', category: 'inpatient', rateId: 'ind10Rate', suffix: '_10' },
    'indicator-11-1': { cql: 'Indicator_11_1_Overall_Cesarean_Section_Rate_1136_01', title: '整體剖腹產率', code: '1136.01', metric: '剖腹產率', category: 'inpatient', rateId: 'ind11_1Rate', suffix: '_11_1' },
    'indicator-11-2': { cql: 'Indicator_11_2_Cesarean_Section_Rate_Patient_Requested_1137_01', title: '產婦要求剖腹產率', code: '1137.01', metric: '剖腹產率', category: 'inpatient', rateId: 'ind11_2Rate', suffix: '_11_2' },
    'indicator-11-3': { cql: 'Indicator_11_3_Cesarean_Section_Rate_With_Indication_1138_01', title: '有適應症剖腹產率', code: '1138.01', metric: '剖腹產率', category: 'inpatient', rateId: 'ind11_3Rate', suffix: '_11_3' },
    'indicator-11-4': { cql: 'Indicator_11_4_Cesarean_Section_Rate_First_Time_1075_01', title: '初產婦剖腹產率', code: '1075.01', metric: '剖腹產率', category: 'inpatient', rateId: 'ind11_4Rate', suffix: '_11_4' },
    'indicator-12':  { cql: 'Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155', title: '清淨手術抗生素超3天率', code: '1155', metric: '使用率', category: 'surgery', rateId: 'ind12Rate', suffix: '_12' },
    'indicator-13':  { cql: 'Indicator_13_Average_ESWL_Utilization_Times_20_01Q_1804Y', title: '體外震波碎石平均利用次數', code: '20.01Q/1804Y', metric: '平均次數', category: 'surgery', rateId: 'ind13Rate', suffix: '_13' },
    'indicator-14':  { cql: 'Indicator_14_Uterine_Fibroid_Surgery_14Day_Readmission_473_01', title: '子宮肌瘤術14天再入院率', code: '473.01', metric: '再入院率', category: 'surgery', rateId: 'ind14Rate', suffix: '_14' },
    'indicator-15-1': { cql: 'Indicator_15_1_Knee_Arthroplasty_90Day_Deep_Infection_353_01', title: '膝關節置換90天深部感染率', code: '353.01', metric: '感染率', category: 'surgery', rateId: 'ind15_1Rate', suffix: '_15_1' },
    'indicator-15-2': { cql: 'Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249', title: '全膝置換90天深部感染率', code: '3249', metric: '感染率', category: 'surgery', rateId: 'ind15_2Rate', suffix: '_15_2' },
    'indicator-15-3': { cql: 'Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250', title: '部分膝置換90天深部感染率', code: '3250', metric: '感染率', category: 'surgery', rateId: 'ind15_3Rate', suffix: '_15_3' },
    'indicator-16':  { cql: 'Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y', title: '住院手術傷口感染率', code: '1658Q/1666Y', metric: '感染率', category: 'surgery', rateId: 'ind16Rate', suffix: '_16' },
    'indicator-17':  { cql: 'Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y', title: '急性心肌梗塞死亡率', code: '1662Q/1668Y', metric: '死亡率', category: 'outcome', rateId: 'ind17Rate', suffix: '_17' },
    'indicator-18':  { cql: 'Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y', title: '失智症安寧療護利用率', code: '2795Q/2796Y', metric: '利用率', category: 'outcome', rateId: 'ind18Rate', suffix: '_18' },
    'indicator-19':  { cql: 'Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y', title: '清淨手術傷口感染率', code: '2524Q/2526Y', metric: '感染率', category: 'surgery', rateId: 'ind19Rate', suffix: '_19' },
    // ========== 中醫指標 (Official ELM 3.10.0) ==========
    'indicator-tcm-1': { cql: 'Indicator_TCM_Medication_Overlap_2_Days_Or_More_Rate', title: '中醫處方用藥日數重疊2日以上比率', code: '中醫-4', metric: '重疊率', category: 'medication', rateId: 'indTcm1Rate', suffix: '_tcm_1' },
    'indicator-tcm-2': { cql: 'Indicator_TCM_Monthly_Visit_8_Or_More_Times_Rate', title: '中醫每月就診8次以上比率', code: '中醫-1', metric: '就診率', category: 'outpatient', rateId: 'indTcm2Rate', suffix: '_tcm_2' },
    'indicator-tcm-3': { cql: 'Indicator_TCM_Same_Day_Revisit_Rate', title: '中醫同日再就診率', code: '中醫-2', metric: '再就診率', category: 'outpatient', rateId: 'indTcm3Rate', suffix: '_tcm_3' },
    'indicator-tcm-4': { cql: 'Indicator_TCM_Traumatology_Rate', title: '中醫針傷科處置比率', code: '中醫-5', metric: '處置率', category: 'surgery', rateId: 'indTcm4Rate', suffix: '_tcm_4' },
    'indicator-tcm-5': { cql: 'Indicator_TCM_Global_Budget_Program_Organization_List', title: '中醫總額計畫參與院所名單', code: '中醫-6', metric: '院所數', category: 'outcome', rateId: 'indTcm5Rate', suffix: '_tcm_5' },
    'indicator-tcm-6': { cql: 'Indicator_TCM_Pediatric_Asthma_Program_Organization_List', title: '中醫小兒氣喘照護計畫院所名單', code: '中醫-7', metric: '院所數', category: 'outcome', rateId: 'indTcm6Rate', suffix: '_tcm_6' },
    'indicator-tcm-7': { cql: 'Indicator_TCM_Pediatric_Cerebral_Palsy_Program_Organization_List', title: '中醫小兒腦麻照護計畫院所名單', code: '中醫-8', metric: '院所數', category: 'outcome', rateId: 'indTcm7Rate', suffix: '_tcm_7' },
    'indicator-tcm-8': { cql: 'Indicator_TCM_Underserved_Area_Program_Organization_List', title: '中醫偏鄉醫療計畫院所名單', code: '中醫-9', metric: '院所數', category: 'outcome', rateId: 'indTcm8Rate', suffix: '_tcm_8' }
};

// 分類資訊
const CATEGORIES = {
    medication: { ids: ['indicator-01','indicator-02','indicator-03-1','indicator-03-2','indicator-03-3','indicator-03-4','indicator-03-5','indicator-03-6','indicator-03-7','indicator-03-8','indicator-03-9','indicator-03-10','indicator-03-11','indicator-03-12','indicator-03-13','indicator-03-14','indicator-03-15','indicator-03-16','indicator-tcm-1'], label: '用藥安全' },
    outpatient: { ids: ['indicator-04','indicator-05','indicator-06','indicator-07','indicator-08','indicator-tcm-2','indicator-tcm-3'], label: '門診品質' },
    inpatient:  { ids: ['indicator-09','indicator-10','indicator-11-1','indicator-11-2','indicator-11-3','indicator-11-4'], label: '住院品質' },
    surgery:    { ids: ['indicator-12','indicator-13','indicator-14','indicator-15-1','indicator-15-2','indicator-15-3','indicator-16','indicator-19','indicator-tcm-4'], label: '手術品質' },
    outcome:    { ids: ['indicator-17','indicator-18','indicator-tcm-5','indicator-tcm-6','indicator-tcm-7','indicator-tcm-8'], label: '結果品質' }
};

// ========== 輔助函數 ==========
function formatNumber(num) {
    if (num === undefined || num === null) return '0';
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function getBackendUrl() {
    const protocol = window.location.protocol;
    const hostname = window.location.hostname;
    if (protocol === 'file:') return 'https://fhir-cql-quality-platform-20260204.onrender.com';
    if (hostname.includes('onrender.com')) return window.location.origin;
    if (hostname === 'localhost' || hostname === '127.0.0.1') return 'http://localhost:3000';
    return 'https://fhir-cql-quality-platform-20260204.onrender.com';
}

function getFHIRServerUrl() {
    if (window.fhirConnection && window.fhirConnection.serverUrl) return window.fhirConnection.serverUrl;
    return localStorage.getItem('fhirServer') || 'https://thas.mohw.gov.tw/v/r4/fhir';
}

// ========== 頁面初始化 ==========
document.addEventListener('DOMContentLoaded', function() {
    console.log('醫療品質指標儀表板(API版)已載入');
    initializeDemoButton();
});

function initializeDemoButton() {
    const demoMode = localStorage.getItem('demoMode') === 'true';
    const btn = document.getElementById('demoModeBtn');
    const text = document.getElementById('demoModeText');
    if (demoMode && btn && text) {
        btn.style.background = 'linear-gradient(135deg, #10b981, #059669)';
        btn.style.color = 'white';
        text.textContent = '示範模式啟用中';
    }
}

// ========== 分類篩選 ==========
function filterCategory(category) {
    document.querySelectorAll('.filter-tab').forEach(t => t.classList.remove('active'));
    event.target.classList.add('active');
    document.querySelectorAll('.overview-section[data-category]').forEach(s => {
        s.style.display = (category === 'all' || s.dataset.category === category) ? '' : 'none';
    });
}

// ========== 執行單一查詢 (API版) ==========
async function executeQuery(indicatorId) {
    const ind = INDICATORS[indicatorId];
    if (!ind) { console.error('未知指標:', indicatorId); return; }

    const suffix = ind.suffix;
    const statusEl = document.getElementById(`status${suffix}`);
    const rateEl = document.getElementById(ind.rateId);

    // 讀取日期&筆數控制
    const startDateEl = document.getElementById(`startDate${suffix}`);
    const endDateEl = document.getElementById(`endDate${suffix}`);
    const maxRecordsEl = document.getElementById(`maxRecords${suffix}`);
    const startDate = startDateEl ? startDateEl.value : '';
    const endDate = endDateEl ? endDateEl.value : '';
    const maxRecords = maxRecordsEl ? parseInt(maxRecordsEl.value) : 200;

    // 找到查詢按鈕並變成 loading 狀態
    const card = statusEl ? statusEl.closest('.overview-card') : document.querySelector(`[onclick*="'${indicatorId}'"]`)?.closest('.overview-card');
    const btn = card ? card.querySelector('.btn-card-mini') : document.querySelector(`button[onclick*="executeQuery('${indicatorId}')"]`);
    const btnOrigHTML = btn ? btn.innerHTML : '';
    if (btn) {
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> CQL Engine 執行中...';
        btn.style.cssText = 'background:linear-gradient(135deg,#6366f1,#818cf8)!important;color:#fff!important;pointer-events:none;opacity:0.9;';
    }
    if (statusEl) statusEl.innerHTML = '<span style="color:#2563eb;"><i class="fas fa-spinner fa-spin"></i> 查詢中...</span>';
    if (rateEl) rateEl.textContent = '...';

    try {
        const demoMode = localStorage.getItem('demoMode') === 'true';
        let results;

        if (demoMode) {
            results = generateDemoData(indicatorId);
        } else {
            results = await queryViaCQLEngine(ind.cql, indicatorId, { startDate, endDate, maxRecords });
        }

        currentResults[indicatorId] = results;
        updateCard(indicatorId, results);

        if (btn) {
            btn.innerHTML = '<i class="fas fa-check-circle"></i> 查詢完成';
            btn.style.cssText = 'background:linear-gradient(135deg,#10b981,#059669)!important;color:#fff!important;';
            setTimeout(() => { btn.innerHTML = btnOrigHTML; btn.style.cssText = ''; }, 3000);
        }
        if (statusEl) {
            statusEl.innerHTML = '<span style="color:#10b981;"><i class="fas fa-check-circle"></i> 完成</span>';
            setTimeout(() => { statusEl.innerHTML = ''; }, 3000);
        }

        // 自動彈出詳細報告
        setTimeout(() => showDetailModal(indicatorId), 500);

    } catch (error) {
        console.error(`指標 ${indicatorId} 查詢失敗:`, error);
        if (btn) {
            btn.innerHTML = '<i class="fas fa-times-circle"></i> 查詢失敗';
            btn.style.cssText = 'background:linear-gradient(135deg,#ef4444,#dc2626)!important;color:#fff!important;';
            setTimeout(() => { btn.innerHTML = btnOrigHTML; btn.style.cssText = ''; }, 5000);
        }
        if (statusEl) statusEl.innerHTML = `<span style="color:#ef4444;"><i class="fas fa-times-circle"></i> ${error.message || '失敗'}</span>`;
        if (rateEl) rateEl.textContent = '--';
    }
}

// ========== 透過後端 CQL Engine 查詢 ==========
async function queryViaCQLEngine(cqlFile, indicatorId, options = {}) {
    const { startDate, endDate, maxRecords = 200 } = options;
    const backendUrl = getBackendUrl();
    const fhirServerUrl = getFHIRServerUrl();

    console.log(`🚀 API查詢 ${indicatorId}: CQL=${cqlFile}, Backend=${backendUrl}`);

    const requestBody = { cqlFile, fhirServerUrl, maxRecords: maxRecords || 200 };
    if (startDate) requestBody.startDate = startDate;
    if (endDate) requestBody.endDate = endDate;

    const response = await fetch(`${backendUrl}/api/execute-cql`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`API 錯誤 ${response.status}: ${errorText}`);
    }

    const data = await response.json();
    console.log(`✅ ${indicatorId} 回傳:`, data);

    if (data.success === false) {
        throw new Error(data.error || 'CQL Engine 執行失敗');
    }

    return parseIndicatorResults(data, indicatorId);
}

// ========== 解析 CQL 結果 ==========
function parseIndicatorResults(data, indicatorId) {
    const ind = INDICATORS[indicatorId];
    const results = data.results || [];
    const metadata = data.executionMetadata || {};

    // 後端對 unknown / 未對應類別會直接回傳單一物件 (非陣列)
    if (results && !Array.isArray(results) && typeof results === 'object' && results.totalPatients !== undefined) {
        return {
            cqlEngine: true, isRealData: results.isRealData !== false,
            totalPatients: results.totalPatients || 0,
            numerator: results.numerator || 0,
            denominator: results.denominator || results.totalPatients || 0,
            rate: results.rate || '0.00',
            noData: results.noData || false,
            metric: ind.metric,
            rawResults: [results],
            fhirServerUrl: getFHIRServerUrl()
        };
    }

    // 直接計算結果 (bypass CQL Engine): 後端回傳聚合數據
    if (results.length === 1 && results[0].totalPatients !== undefined) {
        const r = results[0];
        return {
            cqlEngine: true, isRealData: r.isRealData !== false,
            totalPatients: r.totalPatients || 0,
            numerator: r.numerator || 0,
            denominator: r.denominator || r.totalPatients || 0,
            rate: r.rate || '0.00',
            noData: r.noData || false,
            metric: ind.metric,
            rawResults: results,
            fhirServerUrl: getFHIRServerUrl()
        };
    }

    // CQL Engine 回傳格式: results 是 per-patient 結果陣列
    let totalPatients = metadata.patientCount || results.length || 0;
    let numerator = 0;
    let denominator = totalPatients;

    // 嘗試從結果中提取分子/分母
    results.forEach(r => {
        // CQL 定義通常包含 Numerator, Denominator 或 InNumerator, InDenominator
        if (r.Numerator !== undefined) numerator += (r.Numerator ? 1 : 0);
        else if (r.InNumerator !== undefined) numerator += (r.InNumerator ? 1 : 0);
        else if (r.IsPositive !== undefined) numerator += (r.IsPositive ? 1 : 0);
    });

    // 如有直接數值
    if (results.length > 0 && results[0].Rate !== undefined) {
        return {
            cqlEngine: true, isRealData: true,
            totalPatients, numerator, denominator,
            rate: results[0].Rate,
            metric: ind.metric,
            rawResults: results,
            fhirServerUrl: getFHIRServerUrl()
        };
    }

    const rate = denominator > 0 ? ((numerator / denominator) * 100).toFixed(2) : '0.00';

    return {
        cqlEngine: true, isRealData: true,
        totalPatients, numerator, denominator,
        rate,
        metric: ind.metric,
        rawResults: results,
        fhirServerUrl: getFHIRServerUrl()
    };
}

// ========== 更新卡片顯示 ==========
function updateCard(indicatorId, results) {
    const ind = INDICATORS[indicatorId];
    if (!ind) return;
    const rateEl = document.getElementById(ind.rateId);
    if (!rateEl) return;

    if (results.noData) {
        rateEl.innerHTML = '<span style="color:#94a3b8; font-size:12px;">無資料</span>';
        return;
    }

    if (ind.metric === '平均次數') {
        rateEl.textContent = results.rate || '--';
    } else {
        rateEl.textContent = `${results.rate}%`;
    }
}

// ========== 批次執行 ==========
async function executeAllCategory(category) {
    const cat = CATEGORIES[category];
    if (!cat) return;
    console.log(`🚀 批次執行: ${cat.label} (${cat.ids.length} 項)`);
    for (const id of cat.ids) {
        await executeQuery(id);
        await new Promise(r => setTimeout(r, 300)); // 避免後端過載
    }
}

// ========== 詳情 Modal ==========
function showDetailModal(indicatorId) {
    const modal = document.getElementById('detailModal');
    const modalTitle = document.getElementById('modalTitle');
    const modalBody = document.getElementById('modalBody');
    const ind = INDICATORS[indicatorId];

    if (!ind) return;

    modalTitle.textContent = `📊 ${ind.title} — 詳細報告`;

    const results = currentResults[indicatorId];
    if (results) {
        modalBody.innerHTML = generateDetailContent(indicatorId, results);
    } else {
        modalBody.innerHTML = '<div style="text-align:center; padding:3rem; color:#94a3b8;"><i class="fas fa-info-circle" style="font-size:2rem;"></i><p style="margin-top:1rem;">請先執行查詢</p></div>';
    }

    modal.style.display = 'flex';
}

function closeModal() {
    document.getElementById('detailModal').style.display = 'none';
}

// ========== 生成詳細內容 ==========
function generateDetailContent(indicatorId, results) {
    const ind = INDICATORS[indicatorId];
    if (!ind) return '';

    if (results.noData) {
        return `<div style="text-align:center; padding:3rem;">
            <i class="fas fa-database" style="font-size:3rem; color:#cbd5e1;"></i>
            <p style="color:#94a3b8; margin-top:1rem;">資料庫無相關資料</p>
        </div>`;
    }

    let html = '<div style="padding:20px;">';

    // 數據來源標籤
    if (results.isRealData) {
        html += `<div style="background:#dbeafe; border-left:4px solid #3b82f6; padding:12px; margin-bottom:20px; border-radius:4px;">
            <i class="fas fa-database" style="color:#3b82f6;"></i> <strong>FHIR 真實數據</strong>
            <span style="margin-left:8px; font-size:11px; background:linear-gradient(135deg,#10b981,#059669); color:white; padding:2px 8px; border-radius:8px;">CQL Engine</span>
            <p style="margin:8px 0 0 0; font-size:13px; color:#1e40af;">資料來源：${results.fhirServerUrl || getFHIRServerUrl()}</p>
        </div>`;
    } else if (results.demoMode) {
        html += `<div style="background:#fef3c7; border-left:4px solid #f59e0b; padding:12px; margin-bottom:20px; border-radius:4px;">
            <i class="fas fa-flask" style="color:#f59e0b;"></i> <strong>示範模式數據</strong>
        </div>`;
    }

    // 指標基本資訊
    html += `<div style="background:#f8fafc; border-radius:12px; padding:16px; margin-bottom:20px;">
        <div style="display:flex; align-items:center; gap:12px; margin-bottom:8px;">
            <span style="background:linear-gradient(135deg,${getCategoryColor(ind.category)}); color:white; padding:4px 12px; border-radius:16px; font-size:12px; font-weight:600;">${getCategoryLabel(ind.category)}</span>
            <span style="font-size:13px; color:#64748b;">健保局編號: <strong>${ind.code}</strong></span>
        </div>
        <h3 style="margin:0; color:#1e293b; font-size:18px;">${ind.title}</h3>
    </div>`;

    // 主要指標卡片
    const categoryColors = getCategoryGradient(ind.category);
    html += `<div class="qi-stat-grid-3">
        <div class="qi-stat-card" style="border-top:4px solid ${categoryColors.primary};">
            <div class="qi-stat-icon" style="background:${categoryColors.light}; color:${categoryColors.primary};"><i class="fas fa-users"></i></div>
            <div class="qi-stat-label">總病人數</div>
            <div class="qi-stat-value">${formatNumber(results.totalPatients)}</div>
        </div>
        <div class="qi-stat-card" style="border-top:4px solid #f59e0b;">
            <div class="qi-stat-icon" style="background:#fef3c7; color:#f59e0b;"><i class="fas fa-user-check"></i></div>
            <div class="qi-stat-label">符合條件人數</div>
            <div class="qi-stat-value">${formatNumber(results.numerator)}</div>
        </div>
        <div class="qi-stat-card" style="border-top:4px solid #ef4444;">
            <div class="qi-stat-icon" style="background:#fee2e2; color:#ef4444;"><i class="fas fa-chart-pie"></i></div>
            <div class="qi-stat-label">${ind.metric}</div>
            <div class="qi-stat-value">${ind.metric === '平均次數' ? results.rate : results.rate + '<span style="font-size:16px;">%</span>'}</div>
        </div>
    </div>`;

    // 比率進度條
    const pct = parseFloat(results.rate) || 0;
    const notPct = (100 - pct).toFixed(1);
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-chart-bar"></i> ${ind.metric}分布</h4>`;
    html += `<div class="qi-bar-container">
        <div class="qi-bar-track">
            <div class="qi-bar-fill" style="width:${Math.min(pct, 100)}%; background:linear-gradient(90deg,${categoryColors.primary},${categoryColors.secondary});"></div>
        </div>
        <div style="display:flex; justify-content:space-between; margin-top:8px; font-size:13px;">
            <span><span style="display:inline-block; width:12px; height:12px; background:${categoryColors.primary}; border-radius:2px; margin-right:4px;"></span> 符合 ${pct}% (${formatNumber(results.numerator)} 人)</span>
            <span><span style="display:inline-block; width:12px; height:12px; background:#e2e8f0; border-radius:2px; margin-right:4px;"></span> 不符合 ${notPct}% (${formatNumber(results.denominator - results.numerator)} 人)</span>
        </div>
    </div>`;

    // 品質評級
    html += generateQualityRating(ind, results);

    // CQL 原始結果（可展開）
    if (results.rawResults && results.rawResults.length > 0) {
        html += `<details style="margin-top:20px;">
            <summary style="cursor:pointer; color:#64748b; font-size:13px; padding:8px 0;">
                <i class="fas fa-code"></i> CQL Engine 原始結果 (${results.rawResults.length} 筆)
            </summary>
            <div style="max-height:300px; overflow-y:auto; background:#1e293b; color:#e2e8f0; padding:16px; border-radius:8px; margin-top:8px;">
                <pre style="margin:0; font-size:12px; white-space:pre-wrap;">${JSON.stringify(results.rawResults.slice(0, 10), null, 2)}</pre>
                ${results.rawResults.length > 10 ? '<p style="color:#94a3b8; margin:8px 0 0;">... 僅顯示前10筆</p>' : ''}
            </div>
        </details>`;
    }

    html += '</div>';
    html += getDetailStyles();
    return html;
}

// ========== 品質評級 ==========
function generateQualityRating(ind, results) {
    const rate = parseFloat(results.rate) || 0;
    let rating, ratingColor, ratingIcon, ratingText;

    // 根據指標特性判定品質等級
    // 使用率/比率類 - 較高通常表示需關注
    if (['使用率','比率','重疊率','感染率','死亡率','再入院率','再就診率','急診率','剖腹產率'].includes(ind.metric)) {
        if (rate <= 5) { rating = 'A'; ratingColor = '#10b981'; ratingIcon = 'star'; ratingText = '優良 - 低於預期標準'; }
        else if (rate <= 15) { rating = 'B'; ratingColor = '#3b82f6'; ratingIcon = 'thumbs-up'; ratingText = '良好 - 在合理範圍'; }
        else if (rate <= 30) { rating = 'C'; ratingColor = '#f59e0b'; ratingIcon = 'exclamation-triangle'; ratingText = '普通 - 需持續監測'; }
        else { rating = 'D'; ratingColor = '#ef4444'; ratingIcon = 'exclamation-circle'; ratingText = '需改善 - 超過警戒值'; }
    }
    // 利用率/檢驗率 - 較高通常是好的
    else if (['利用率','檢驗率'].includes(ind.metric)) {
        if (rate >= 80) { rating = 'A'; ratingColor = '#10b981'; ratingIcon = 'star'; ratingText = '優良 - 達成率高'; }
        else if (rate >= 60) { rating = 'B'; ratingColor = '#3b82f6'; ratingIcon = 'thumbs-up'; ratingText = '良好 - 逐步達標'; }
        else if (rate >= 40) { rating = 'C'; ratingColor = '#f59e0b'; ratingIcon = 'exclamation-triangle'; ratingText = '普通 - 仍有改善空間'; }
        else { rating = 'D'; ratingColor = '#ef4444'; ratingIcon = 'exclamation-circle'; ratingText = '需改善 - 未達標準'; }
    }
    else {
        rating = '--'; ratingColor = '#94a3b8'; ratingIcon = 'minus-circle'; ratingText = '待評估';
    }

    let html = `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-clipboard-check"></i> 品質評級</h4>`;
    html += `<div style="display:flex; align-items:center; gap:20px; background:#f8fafc; border-radius:12px; padding:20px; border-left:6px solid ${ratingColor};">
        <div style="width:80px; height:80px; border-radius:50%; background:${ratingColor}; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
            <span style="font-size:36px; font-weight:900; color:white;">${rating}</span>
        </div>
        <div>
            <div style="font-size:18px; font-weight:700; color:#1e293b; margin-bottom:4px;">
                <i class="fas fa-${ratingIcon}" style="color:${ratingColor}; margin-right:6px;"></i> ${ratingText}
            </div>
            <div style="font-size:13px; color:#64748b;">
                ${ind.metric}: ${ind.metric === '平均次數' ? results.rate : results.rate + '%'} | 
                樣本數: ${formatNumber(results.totalPatients)} | 
                健保局編號: ${ind.code}
            </div>
        </div>
    </div>`;

    return html;
}

// ========== 分類顏色 ==========
function getCategoryColor(category) {
    const colors = {
        medication: '#6366f1, #8b5cf6',
        outpatient: '#3b82f6, #2563eb',
        inpatient: '#10b981, #059669',
        surgery: '#f59e0b, #d97706',
        outcome: '#ef4444, #dc2626'
    };
    return colors[category] || '#64748b, #475569';
}

function getCategoryLabel(category) {
    const labels = { medication: '用藥安全', outpatient: '門診品質', inpatient: '住院品質', surgery: '手術品質', outcome: '結果品質' };
    return labels[category] || category;
}

function getCategoryGradient(category) {
    const g = {
        medication: { primary: '#6366f1', secondary: '#8b5cf6', light: '#e0e7ff' },
        outpatient: { primary: '#3b82f6', secondary: '#2563eb', light: '#dbeafe' },
        inpatient:  { primary: '#10b981', secondary: '#059669', light: '#d1fae5' },
        surgery:    { primary: '#f59e0b', secondary: '#d97706', light: '#fef3c7' },
        outcome:    { primary: '#ef4444', secondary: '#dc2626', light: '#fee2e2' }
    };
    return g[category] || { primary: '#64748b', secondary: '#475569', light: '#f1f5f9' };
}

// ========== 樣式 ==========
function getDetailStyles() {
    return `<style>
    .qi-stat-grid-3 { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; margin-bottom:20px; }
    .qi-stat-card { background:white; border-radius:12px; padding:20px; text-align:center; box-shadow:0 2px 8px rgba(0,0,0,0.06); transition:transform 0.2s; }
    .qi-stat-card:hover { transform:translateY(-2px); box-shadow:0 4px 12px rgba(0,0,0,0.1); }
    .qi-stat-icon { width:48px; height:48px; border-radius:12px; display:flex; align-items:center; justify-content:center; margin:0 auto 12px; font-size:20px; }
    .qi-stat-label { font-size:13px; color:#64748b; margin-bottom:6px; }
    .qi-stat-value { font-size:28px; font-weight:800; color:#1e293b; }
    .qi-bar-container { background:#f8fafc; border-radius:12px; padding:16px; }
    .qi-bar-track { background:#e2e8f0; border-radius:8px; height:28px; overflow:hidden; }
    .qi-bar-fill { height:100%; border-radius:8px; transition:width 0.8s ease; }
    @media (max-width:768px) {
        .qi-stat-grid-3 { grid-template-columns:1fr; }
    }
    </style>`;
}

// ========== 示範模式 ==========
function toggleDemoMode() {
    const current = localStorage.getItem('demoMode') === 'true';
    localStorage.setItem('demoMode', !current);
    const btn = document.getElementById('demoModeBtn');
    const text = document.getElementById('demoModeText');
    if (!current) {
        btn.style.background = 'linear-gradient(135deg, #10b981, #059669)';
        btn.style.color = 'white';
        text.textContent = '示範模式啟用中';
    } else {
        btn.style.background = '';
        btn.style.color = '';
        text.textContent = '啟用示範模式';
    }
}

function generateDemoData(indicatorId) {
    const ind = INDICATORS[indicatorId];
    if (!ind) return { noData: true };

    // 根據不同類型生成合理的模擬數據
    const demos = {
        medication: { total: 1500, rate: () => (Math.random() * 25 + 3).toFixed(2) },
        outpatient: { total: 2000, rate: () => (Math.random() * 40 + 10).toFixed(2) },
        inpatient:  { total: 800, rate: () => (Math.random() * 15 + 2).toFixed(2) },
        surgery:    { total: 500, rate: () => (Math.random() * 10 + 1).toFixed(2) },
        outcome:    { total: 300, rate: () => (Math.random() * 8 + 1).toFixed(2) }
    };

    const d = demos[ind.category] || demos.medication;
    const totalPatients = d.total + Math.floor(Math.random() * 500);
    const rate = d.rate();
    const numerator = Math.round(totalPatients * parseFloat(rate) / 100);

    return {
        demoMode: true, isRealData: false,
        totalPatients, numerator, denominator: totalPatients,
        rate, metric: ind.metric,
        rawResults: [],
        fhirServerUrl: '示範模式'
    };
}

function refreshData() {
    currentResults = {};
    window.qualityResults = currentResults;
    Object.keys(INDICATORS).forEach(id => {
        const ind = INDICATORS[id];
        const el = document.getElementById(ind.rateId);
        if (el) el.textContent = ind.metric === '平均次數' ? '--' : '--%';
    });
    document.querySelectorAll('.card-status').forEach(el => el.innerHTML = '');
    console.log('已重置所有指標');
}

// ========== EXCEL 生成功能 (API版) ==========
function generateExcel() {
    if (typeof XLSX === 'undefined') {
        alert('找不到 XLSX 套件，請重新整理頁面後再試一次。');
        return;
    }

    const resultKeys = Object.keys(currentResults || {});
    if (resultKeys.length === 0) {
        alert('目前沒有可匯出的查詢結果，請先執行至少一項指標查詢。');
        return;
    }

    try {
        const categoryLabel = {
            medication: '用藥安全',
            outpatient: '門診品質',
            inpatient: '住院品質',
            surgery: '手術品質',
            outcome: '結果品質'
        };

        const rows = Object.entries(INDICATORS)
            .filter(([indicatorId]) => currentResults[indicatorId])
            .map(([indicatorId, ind]) => {
                const r = currentResults[indicatorId] || {};
                const value = ind.metric === '平均次數'
                    ? (r.rate ?? '--')
                    : (r.rate !== undefined ? `${r.rate}%` : '--');

                return {
                    '指標ID': indicatorId,
                    '指標代碼': ind.code,
                    '指標名稱': ind.title,
                    '分類': categoryLabel[ind.category] || ind.category,
                    '衡量指標': ind.metric,
                    '數值': value,
                    '分子': r.numerator ?? '--',
                    '分母': r.denominator ?? '--',
                    '總樣本數': r.totalPatients ?? '--',
                    '資料來源': r.demoMode ? '示範資料' : 'FHIR/API資料',
                    'FHIR Server': r.fhirServerUrl || getFHIRServerUrl(),
                    '匯出時間': new Date().toLocaleString('zh-TW')
                };
            });

        const workbook = XLSX.utils.book_new();
        const ws = XLSX.utils.json_to_sheet(rows);
        ws['!cols'] = [
            { wch: 12 }, { wch: 12 }, { wch: 32 }, { wch: 12 }, { wch: 12 },
            { wch: 12 }, { wch: 10 }, { wch: 10 }, { wch: 10 }, { wch: 14 },
            { wch: 38 }, { wch: 22 }
        ];

        XLSX.utils.book_append_sheet(workbook, ws, '醫療品質指標(API)');

        const now = new Date();
        const pad = (n) => String(n).padStart(2, '0');
        const fileTag = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}`;
        XLSX.writeFile(workbook, `醫療品質指標_API版_${fileTag}.xlsx`);
    } catch (error) {
        console.error('Excel 匯出失敗:', error);
        alert(`Excel 匯出失敗：${error.message}`);
    }
}

// ========== LLM Modal (placeholder) ==========
function openLLMSettingsModal() {
    alert('LLM 設定功能在 API 版中暫不提供');
}
