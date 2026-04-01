// ========== ESG 指標儀表板邏輯 - API版 ==========
// 透過後端 CQL Engine 執行查詢
// CQL文件映射:
// - 抗生素使用率: Antibiotic_Utilization
// - 電子病歷採用率: EHR_Adoption_Rate
// - 廢棄物管理: Waste
console.log('📌 esg-indicators-api.js BUILD_VERSION: 20260401a');

let currentResults = {};
window.esgResults = currentResults;

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

// 頁面載入
document.addEventListener('DOMContentLoaded', function() {
    console.log('ESG 指標儀表板(API版)已載入');
    initializeCards();
});

function initializeCards() {
    ['antibioticCount', 'antibioticRate', 'ehrCount', 'ehrRate', 'wasteCount', 'wasteRate'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.textContent = '--';
    });
}

// ========== 執行查詢 (API版：透過後端) ==========
async function executeQuery(indicatorType) {
    console.log(`🚀 API版 ESG 執行查詢: ${indicatorType}`);

    const idMap = {
        'antibiotic': 'Antibiotic',
        'ehr-adoption': 'Ehr',
        'waste': 'Waste'
    };

    const cqlFileMap = {
        'antibiotic': 'Antibiotic_Utilization',
        'ehr-adoption': 'EHR_Adoption_Rate',
        'waste': 'Waste'
    };

    const elementId = idMap[indicatorType];
    const cqlFile = cqlFileMap[indicatorType];
    const btn = document.getElementById(`btn${elementId}`);
    const statusElement = document.getElementById(`status${elementId}`);

    // 讀取日期範圍和筆數設定
    const startDateEl = document.getElementById(`startDate${elementId}`);
    const endDateEl = document.getElementById(`endDate${elementId}`);
    const maxRecordsEl = document.getElementById(`maxRecords${elementId}`);
    const startDate = startDateEl ? startDateEl.value : '';
    const endDate = endDateEl ? endDateEl.value : '';
    const maxRecords = maxRecordsEl ? parseInt(maxRecordsEl.value) : 200;

    if (btn && btn.disabled) return;

    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> CQL Engine 執行中...';
    }
    if (statusElement) {
        statusElement.innerHTML = '<span style="color: #2563eb;"><i class="fas fa-spinner fa-spin"></i> 後端引擎執行中...</span>';
    }

    try {
        const demoMode = localStorage.getItem('demoMode') === 'true';
        let results;

        if (demoMode) {
            results = generateDemoData(indicatorType);
        } else {
            results = await queryViaCQLEngine(cqlFile, indicatorType, { startDate, endDate, maxRecords });
        }

        currentResults[indicatorType] = results;
        updateESGCard(indicatorType, results);

        if (statusElement) {
            statusElement.innerHTML = '<span style="color: #10b981;"><i class="fas fa-check-circle"></i> 完成</span>';
            setTimeout(() => { statusElement.innerHTML = ''; }, 3000);
        }

        // 自動顯示詳細報告
        setTimeout(() => showDetailModal(indicatorType), 500);

    } catch (error) {
        console.error('查詢失敗:', error);
        if (statusElement) {
            statusElement.innerHTML = `<span style="color: #ef4444;"><i class="fas fa-times-circle"></i> ${error.message || '失敗'}</span>`;
        }
    } finally {
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-play"></i> 執行查詢';
        }
    }
}

// ========== 透過後端 CQL Engine 查詢 ==========
async function queryViaCQLEngine(cqlFile, indicatorType, options = {}) {
    const { startDate, endDate, maxRecords = 200 } = options;
    const backendUrl = getBackendUrl();
    const fhirServerUrl = getFHIRServerUrl();

    console.log(`   Backend: ${backendUrl}`);
    console.log(`   FHIR: ${fhirServerUrl}`);
    console.log(`   CQL: ${cqlFile}`);

    const requestBody = {
        cqlFile,
        fhirServerUrl,
        maxRecords: maxRecords || 200
    };
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
    console.log('✅ CQL Engine 回傳:', data);

    if (data.success === false) {
        throw new Error(data.error || 'CQL Engine 執行失敗');
    }

    const cqlResults = data.results || [];
    const metadata = data.executionMetadata || {};

    return parseESGResults(cqlResults, metadata, indicatorType);
}

// ========== 解析 ESG 結果 ==========
function parseESGResults(cqlResults, metadata, indicatorType) {
    console.log('📊 解析 ESG 結果:', indicatorType, JSON.stringify(cqlResults).substring(0, 500));

    // 後端 computeESGResults 回傳的直接格式
    const row = cqlResults[0] || {};

    if (indicatorType === 'antibiotic') {
        return {
            cqlEngine: true,
            totalPatients: row.totalPatients || metadata.patientCount || 0,
            antibioticPatients: row.antibioticPatients || 0,
            utilizationRate: row.utilizationRate || '0.00',
            antibioticNames: row.antibioticNames || [],
            noData: (row.totalPatients || 0) === 0,
            isRealData: true,
            fhirServerUrl: getFHIRServerUrl()
        };
    } else if (indicatorType === 'ehr-adoption') {
        return {
            cqlEngine: true,
            totalOrganizations: row.totalPatients || metadata.patientCount || 0,
            ehrAdopted: row.ehrAdopted || 0,
            adoptionRate: row.adoptionRate || '0.00',
            documentTypes: row.documentTypes || {},
            noData: (row.totalPatients || 0) === 0,
            isRealData: true,
            fhirServerUrl: getFHIRServerUrl()
        };
    } else if (indicatorType === 'waste') {
        return {
            cqlEngine: true,
            totalWaste: row.totalWaste || 0,
            infectiousWaste: row.infectiousWaste || 0,
            recycledWaste: row.recycledWaste || 0,
            generalWaste: row.generalWaste || 0,
            recycleRate: row.recycleRate || '0.00',
            noData: (row.totalWaste || 0) === 0,
            isRealData: true,
            fhirServerUrl: getFHIRServerUrl()
        };
    }

    return { noData: true };
}

// ========== 更新卡片 ==========
function updateESGCard(indicatorType, results) {
    const cardMap = {
        'antibiotic': { countId: 'antibioticCount', rateId: 'antibioticRate', dateId: 'antibioticDateRange' },
        'ehr-adoption': { countId: 'ehrCount', rateId: 'ehrRate', dateId: 'ehrDateRange' },
        'waste': { countId: 'wasteCount', rateId: 'wasteRate', dateId: 'wasteDateRange' }
    };

    const ids = cardMap[indicatorType];
    if (!ids) return;

    const countEl = document.getElementById(ids.countId);
    const rateEl = document.getElementById(ids.rateId);
    const dateEl = document.getElementById(ids.dateId);

    if (results.noData) {
        if (countEl) countEl.innerHTML = '<span style="color:#94a3b8; font-size:14px;">無資料</span>';
        if (rateEl) rateEl.textContent = '--';
        return;
    }

    if (indicatorType === 'antibiotic') {
        if (countEl) countEl.textContent = formatNumber(results.totalPatients);
        if (rateEl) rateEl.textContent = `${results.utilizationRate}%`;
    } else if (indicatorType === 'ehr-adoption') {
        if (countEl) countEl.textContent = formatNumber(results.ehrAdopted);
        if (rateEl) rateEl.textContent = `${results.adoptionRate}%`;
    } else if (indicatorType === 'waste') {
        if (countEl) countEl.textContent = `${formatNumber(results.totalWaste)} kg`;
        if (rateEl) rateEl.textContent = `${results.recycleRate}%`;
    }

    if (dateEl) {
        const src = results.isRealData ? '🔗 FHIR 真實數據' : '📊 模擬數據';
        dateEl.textContent = src;
    }
}

// ========== 詳情 Modal ==========
function showDetailModal(indicatorType) {
    const modal = document.getElementById('detailModal');
    const modalTitle = document.getElementById('modalTitle');
    const modalBody = document.getElementById('modalBody');

    const titles = {
        'antibiotic': '🧪 抗生素使用率 — 詳細報告',
        'ehr-adoption': '💻 電子病歷採用率 — 詳細報告',
        'waste': '♻️ 醫療廢棄物管理 — 詳細報告'
    };

    modalTitle.textContent = titles[indicatorType] || '詳細資訊';

    const results = currentResults[indicatorType];
    if (results) {
        modalBody.innerHTML = generateDetailContent(indicatorType, results);
    } else {
        modalBody.innerHTML = '<div style="text-align:center; padding:3rem; color:#94a3b8;"><i class="fas fa-info-circle" style="font-size:2rem;"></i><p style="margin-top:1rem;">請先執行查詢</p></div>';
    }

    modal.style.display = 'flex';
}

function closeModal() {
    document.getElementById('detailModal').style.display = 'none';
}

// ========== 生成詳細內容 ==========
function generateDetailContent(indicatorType, results) {
    if (results.noData) {
        return `<div style="text-align:center; padding:3rem;">
            <i class="fas fa-database" style="font-size:3rem; color:#cbd5e1;"></i>
            <p style="color:#94a3b8; margin-top:1rem;">資料庫無資料</p>
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

    if (indicatorType === 'antibiotic') {
        html += generateAntibioticDetail(results);
    } else if (indicatorType === 'ehr-adoption') {
        html += generateEHRDetail(results);
    } else if (indicatorType === 'waste') {
        html += generateWasteDetail(results);
    }

    html += '</div>';
    html += getDetailStyles();
    return html;
}

// ========== 抗生素使用率 - 詳細報告 ==========
function generateAntibioticDetail(r) {
    const unusedPatients = r.totalPatients - r.antibioticPatients;
    const unusedPct = r.totalPatients > 0 ? ((unusedPatients / r.totalPatients) * 100).toFixed(1) : 0;
    const usedPct = r.totalPatients > 0 ? ((r.antibioticPatients / r.totalPatients) * 100).toFixed(1) : 0;

    let html = `<h3 style="margin-bottom:16px; color:#1e293b;"><i class="fas fa-pills" style="color:#f59e0b;"></i> 抗生素使用率統計</h3>`;

    // 主要統計卡
    html += `<div class="esg-stat-grid-3">
        <div class="esg-stat-card" style="border-top:4px solid #3b82f6;">
            <div class="esg-stat-icon" style="background:#dbeafe; color:#3b82f6;"><i class="fas fa-users"></i></div>
            <div class="esg-stat-label">總就醫人數</div>
            <div class="esg-stat-value">${formatNumber(r.totalPatients)}</div>
        </div>
        <div class="esg-stat-card" style="border-top:4px solid #f59e0b;">
            <div class="esg-stat-icon" style="background:#fef3c7; color:#f59e0b;"><i class="fas fa-pills"></i></div>
            <div class="esg-stat-label">使用抗生素人數</div>
            <div class="esg-stat-value">${formatNumber(r.antibioticPatients)}</div>
        </div>
        <div class="esg-stat-card" style="border-top:4px solid #ef4444;">
            <div class="esg-stat-icon" style="background:#fee2e2; color:#ef4444;"><i class="fas fa-chart-pie"></i></div>
            <div class="esg-stat-label">抗生素使用率</div>
            <div class="esg-stat-value">${r.utilizationRate}<span style="font-size:16px;">%</span></div>
        </div>
    </div>`;

    // 使用 vs 未使用 甜甜圈圖
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-chart-pie"></i> 使用分布</h4>`;
    html += `<div class="esg-bar-container">
        <div class="esg-bar-track">
            <div class="esg-bar-fill" style="width:${usedPct}%; background:linear-gradient(90deg,#f59e0b,#ef4444);"></div>
        </div>
        <div style="display:flex; justify-content:space-between; margin-top:8px; font-size:13px;">
            <span><span style="display:inline-block; width:12px; height:12px; background:#f59e0b; border-radius:2px; margin-right:4px;"></span> 使用抗生素 ${usedPct}% (${formatNumber(r.antibioticPatients)} 人)</span>
            <span><span style="display:inline-block; width:12px; height:12px; background:#e2e8f0; border-radius:2px; margin-right:4px;"></span> 未使用 ${unusedPct}% (${formatNumber(unusedPatients)} 人)</span>
        </div>
    </div>`;

    // WHO AWaRe 分類（估算）
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-shield-alt"></i> WHO AWaRe 分類 <span style="font-size:12px; color:#94a3b8; font-weight:normal;">(基於統計估算)</span></h4>`;
    html += `<div class="esg-stat-grid-3">
        <div class="esg-aware-card" style="background:linear-gradient(135deg,#d1fae5,#a7f3d0);">
            <div style="font-size:28px; font-weight:800; color:#059669;">${Math.round(r.antibioticPatients * 0.6)}</div>
            <div style="font-size:13px; color:#065f46; font-weight:600;">Access (存取級)</div>
            <div style="font-size:11px; color:#047857; margin-top:4px;">一線用藥 ~60%</div>
        </div>
        <div class="esg-aware-card" style="background:linear-gradient(135deg,#fef3c7,#fde68a);">
            <div style="font-size:28px; font-weight:800; color:#d97706;">${Math.round(r.antibioticPatients * 0.3)}</div>
            <div style="font-size:13px; color:#92400e; font-weight:600;">Watch (監視級)</div>
            <div style="font-size:11px; color:#a16207; margin-top:4px;">二線用藥 ~30%</div>
        </div>
        <div class="esg-aware-card" style="background:linear-gradient(135deg,#fee2e2,#fca5a5);">
            <div style="font-size:28px; font-weight:800; color:#dc2626;">${Math.round(r.antibioticPatients * 0.1)}</div>
            <div style="font-size:13px; color:#991b1b; font-weight:600;">Reserve (保留級)</div>
            <div style="font-size:11px; color:#b91c1c; margin-top:4px;">最後防線 ~10%</div>
        </div>
    </div>`;

    return html;
}

// ========== 電子病歷採用率 - 詳細報告 ==========
function generateEHRDetail(r) {
    const adoptedPct = parseFloat(r.adoptionRate) || 0;
    const notAdoptedPct = (100 - adoptedPct).toFixed(1);
    const notAdopted = r.totalOrganizations - r.ehrAdopted;

    let html = `<h3 style="margin-bottom:16px; color:#1e293b;"><i class="fas fa-laptop-medical" style="color:#6366f1;"></i> 電子病歷採用率統計</h3>`;

    // 主要統計卡
    html += `<div class="esg-stat-grid-3">
        <div class="esg-stat-card" style="border-top:4px solid #6366f1;">
            <div class="esg-stat-icon" style="background:#e0e7ff; color:#6366f1;"><i class="fas fa-users"></i></div>
            <div class="esg-stat-label">總病人數</div>
            <div class="esg-stat-value">${formatNumber(r.totalOrganizations)}</div>
        </div>
        <div class="esg-stat-card" style="border-top:4px solid #10b981;">
            <div class="esg-stat-icon" style="background:#d1fae5; color:#10b981;"><i class="fas fa-file-medical"></i></div>
            <div class="esg-stat-label">有電子病歷</div>
            <div class="esg-stat-value">${formatNumber(r.ehrAdopted)}</div>
        </div>
        <div class="esg-stat-card" style="border-top:4px solid #3b82f6;">
            <div class="esg-stat-icon" style="background:#dbeafe; color:#3b82f6;"><i class="fas fa-chart-line"></i></div>
            <div class="esg-stat-label">採用率</div>
            <div class="esg-stat-value">${r.adoptionRate}<span style="font-size:16px;">%</span></div>
        </div>
    </div>`;

    // 採用率進度條
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-tasks"></i> 採用概況</h4>`;
    html += `<div class="esg-bar-container">
        <div class="esg-bar-track">
            <div class="esg-bar-fill" style="width:${adoptedPct}%; background:linear-gradient(90deg,#6366f1,#8b5cf6);"></div>
        </div>
        <div style="display:flex; justify-content:space-between; margin-top:8px; font-size:13px;">
            <span><span style="display:inline-block; width:12px; height:12px; background:#6366f1; border-radius:2px; margin-right:4px;"></span> 已採用 ${adoptedPct}% (${formatNumber(r.ehrAdopted)} 人)</span>
            <span><span style="display:inline-block; width:12px; height:12px; background:#e2e8f0; border-radius:2px; margin-right:4px;"></span> 未採用 ${notAdoptedPct}% (${formatNumber(notAdopted)} 人)</span>
        </div>
    </div>`;

    // HIMSS EMRAM 成熟度（估算）
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-layer-group"></i> HIMSS EMRAM 成熟度 <span style="font-size:12px; color:#94a3b8; font-weight:normal;">(基於統計估算)</span></h4>`;
    const emramLevels = [
        { level: 'Stage 7', label: '完整 EMR', pct: 10, color: '#059669' },
        { level: 'Stage 5-6', label: '進階臨床', pct: 25, color: '#3b82f6' },
        { level: 'Stage 3-4', label: '基本臨床', pct: 35, color: '#8b5cf6' },
        { level: 'Stage 1-2', label: '初始階段', pct: 20, color: '#f59e0b' },
        { level: 'Stage 0', label: '未導入', pct: 10, color: '#ef4444' }
    ];
    html += '<div style="display:flex; flex-direction:column; gap:10px;">';
    emramLevels.forEach(l => {
        const count = Math.round(r.ehrAdopted * l.pct / 100);
        html += `<div style="display:flex; align-items:center; gap:12px;">
            <div style="min-width:100px; font-size:13px; font-weight:600; color:${l.color};">${l.level}</div>
            <div style="flex:1; background:#f1f5f9; border-radius:6px; height:24px; overflow:hidden; position:relative;">
                <div style="width:${l.pct}%; height:100%; background:${l.color}; border-radius:6px; transition:width 0.8s;"></div>
                <span style="position:absolute; right:8px; top:3px; font-size:11px; color:#64748b;">${l.pct}%</span>
            </div>
            <div style="min-width:60px; text-align:right; font-size:12px; color:#64748b;">${count} 人</div>
        </div>`;
    });
    html += '</div>';

    return html;
}

// ========== 廢棄物管理 - 詳細報告 ==========
function generateWasteDetail(r) {
    const total = r.totalWaste || 0;
    const infectious = r.infectiousWaste || 0;
    const recycled = r.recycledWaste || 0;
    const general = r.generalWaste || (total - infectious - recycled);

    const infPct = total > 0 ? ((infectious / total) * 100).toFixed(1) : 0;
    const recPct = total > 0 ? ((recycled / total) * 100).toFixed(1) : 0;
    const genPct = total > 0 ? ((general / total) * 100).toFixed(1) : 0;

    let html = `<h3 style="margin-bottom:16px; color:#1e293b;"><i class="fas fa-recycle" style="color:#10b981;"></i> 醫療廢棄物管理統計</h3>`;

    // 主要統計卡
    html += `<div class="esg-stat-grid-4">
        <div class="esg-stat-card" style="border-top:4px solid #64748b;">
            <div class="esg-stat-icon" style="background:#f1f5f9; color:#64748b;"><i class="fas fa-weight-hanging"></i></div>
            <div class="esg-stat-label">總廢棄物量</div>
            <div class="esg-stat-value">${formatNumber(total)}<span style="font-size:14px;"> kg</span></div>
        </div>
        <div class="esg-stat-card" style="border-top:4px solid #ef4444;">
            <div class="esg-stat-icon" style="background:#fee2e2; color:#ef4444;"><i class="fas fa-biohazard"></i></div>
            <div class="esg-stat-label">感染性廢棄物</div>
            <div class="esg-stat-value">${formatNumber(infectious)}<span style="font-size:14px;"> kg</span></div>
        </div>
        <div class="esg-stat-card" style="border-top:4px solid #f59e0b;">
            <div class="esg-stat-icon" style="background:#fef3c7; color:#f59e0b;"><i class="fas fa-trash"></i></div>
            <div class="esg-stat-label">一般廢棄物</div>
            <div class="esg-stat-value">${formatNumber(general)}<span style="font-size:14px;"> kg</span></div>
        </div>
        <div class="esg-stat-card" style="border-top:4px solid #10b981;">
            <div class="esg-stat-icon" style="background:#d1fae5; color:#10b981;"><i class="fas fa-recycle"></i></div>
            <div class="esg-stat-label">回收再利用</div>
            <div class="esg-stat-value">${formatNumber(recycled)}<span style="font-size:14px;"> kg</span></div>
        </div>
    </div>`;

    // 回收率儀表板
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-tachometer-alt"></i> 回收再利用率</h4>`;
    html += `<div style="text-align:center; padding:20px;">
        <div style="position:relative; display:inline-block; width:180px; height:90px; overflow:hidden;">
            <div style="position:absolute; width:180px; height:180px; border-radius:50%; background: conic-gradient(#10b981 0% ${r.recycleRate / 2}%, #e2e8f0 ${r.recycleRate / 2}% 50%, transparent 50% 100%); top:0; left:0;"></div>
            <div style="position:absolute; width:130px; height:130px; border-radius:50%; background:white; top:25px; left:25px;"></div>
            <div style="position:absolute; bottom:0; left:0; right:0; text-align:center;">
                <span style="font-size:32px; font-weight:800; color:#10b981;">${r.recycleRate}%</span>
            </div>
        </div>
    </div>`;

    // 廢棄物分布橫條圖
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-chart-bar"></i> 廢棄物組成分布</h4>`;
    html += `<div class="esg-bar-container">
        <div style="display:flex; height:36px; border-radius:8px; overflow:hidden;">
            <div style="width:${genPct}%; background:#f59e0b; display:flex; align-items:center; justify-content:center; color:white; font-size:11px; font-weight:600;">${genPct > 10 ? genPct + '%' : ''}</div>
            <div style="width:${infPct}%; background:#ef4444; display:flex; align-items:center; justify-content:center; color:white; font-size:11px; font-weight:600;">${infPct > 10 ? infPct + '%' : ''}</div>
            <div style="width:${recPct}%; background:#10b981; display:flex; align-items:center; justify-content:center; color:white; font-size:11px; font-weight:600;">${recPct > 10 ? recPct + '%' : ''}</div>
        </div>
        <div style="display:flex; gap:20px; margin-top:10px; font-size:13px; flex-wrap:wrap;">
            <span><span style="display:inline-block; width:12px; height:12px; background:#f59e0b; border-radius:2px; margin-right:4px;"></span> 一般 ${genPct}% (${formatNumber(general)} kg)</span>
            <span><span style="display:inline-block; width:12px; height:12px; background:#ef4444; border-radius:2px; margin-right:4px;"></span> 感染性 ${infPct}% (${formatNumber(infectious)} kg)</span>
            <span><span style="display:inline-block; width:12px; height:12px; background:#10b981; border-radius:2px; margin-right:4px;"></span> 回收 ${recPct}% (${formatNumber(recycled)} kg)</span>
        </div>
    </div>`;

    // GRI 306 合規
    html += `<h4 style="margin:24px 0 12px; color:#334155;"><i class="fas fa-clipboard-check"></i> GRI 306 合規指標 <span style="font-size:12px; color:#94a3b8; font-weight:normal;">(基於統計估算)</span></h4>`;
    const gri = [
        { name: 'GRI 306-3 產生量', value: `${formatNumber(total)} kg`, status: '✅', color: '#10b981' },
        { name: 'GRI 306-4 回收轉化', value: `${formatNumber(recycled)} kg`, status: total > 0 && parseFloat(r.recycleRate) > 20 ? '✅' : '⚠️', color: parseFloat(r.recycleRate) > 20 ? '#10b981' : '#f59e0b' },
        { name: 'GRI 306-5 最終處置', value: `${formatNumber(infectious + general)} kg`, status: '📋', color: '#3b82f6' }
    ];
    html += '<div style="display:flex; flex-direction:column; gap:8px;">';
    gri.forEach(g => {
        html += `<div style="display:flex; align-items:center; background:#f8fafc; border-radius:8px; padding:12px 16px; border-left:4px solid ${g.color};">
            <span style="font-size:18px; margin-right:12px;">${g.status}</span>
            <span style="flex:1; font-size:14px; font-weight:500; color:#334155;">${g.name}</span>
            <span style="font-size:14px; font-weight:700; color:${g.color};">${g.value}</span>
        </div>`;
    });
    html += '</div>';

    return html;
}

// ========== 樣式 ==========
function getDetailStyles() {
    return `<style>
    .esg-stat-grid-3 { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; margin-bottom:20px; }
    .esg-stat-grid-4 { display:grid; grid-template-columns:repeat(4,1fr); gap:14px; margin-bottom:20px; }
    .esg-stat-card { background:white; border-radius:12px; padding:20px; text-align:center; box-shadow:0 2px 8px rgba(0,0,0,0.06); transition:transform 0.2s; }
    .esg-stat-card:hover { transform:translateY(-2px); box-shadow:0 4px 12px rgba(0,0,0,0.1); }
    .esg-stat-icon { width:48px; height:48px; border-radius:12px; display:flex; align-items:center; justify-content:center; margin:0 auto 12px; font-size:20px; }
    .esg-stat-label { font-size:13px; color:#64748b; margin-bottom:6px; }
    .esg-stat-value { font-size:28px; font-weight:800; color:#1e293b; }
    .esg-bar-container { background:#f8fafc; border-radius:12px; padding:16px; }
    .esg-bar-track { background:#e2e8f0; border-radius:8px; height:28px; overflow:hidden; }
    .esg-bar-fill { height:100%; border-radius:8px; transition:width 0.8s ease; }
    .esg-aware-card { border-radius:12px; padding:16px; text-align:center; }
    @media (max-width:768px) {
        .esg-stat-grid-3 { grid-template-columns:1fr; }
        .esg-stat-grid-4 { grid-template-columns:repeat(2,1fr); }
    }
    </style>`;
}

// ========== 示範模式 ==========
function generateDemoData(indicatorType) {
    if (indicatorType === 'antibiotic') {
        return {
            demoMode: true, totalPatients: 1250, antibioticPatients: 312,
            utilizationRate: '24.96', noData: false, isRealData: false,
            fhirServerUrl: '示範模式'
        };
    } else if (indicatorType === 'ehr-adoption') {
        return {
            demoMode: true, totalOrganizations: 860, ehrAdopted: 645,
            adoptionRate: '75.00', noData: false, isRealData: false,
            fhirServerUrl: '示範模式'
        };
    } else if (indicatorType === 'waste') {
        return {
            demoMode: true, totalWaste: 5200, infectiousWaste: 1560,
            recycledWaste: 1820, generalWaste: 1820, recycleRate: '35.00',
            noData: false, isRealData: false, fhirServerUrl: '示範模式'
        };
    }
    return { noData: true };
}
