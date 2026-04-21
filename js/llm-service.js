// ========== LLM 服務管理系統 ==========
// 功能: 模擬 LLM 服務連接、Token 計價、獲利統計、歷史紀錄

let llmServiceActive = false;
let llmStats = {
    queryCount: 0,
    inputTokens: 0,
    outputTokens: 0,
    dataTransferKB: 0,
    totalRevenue: 0,
    history: []
};

// Token 計價標準 (USD)
const TOKEN_PRICING = {
    input: 3.00 / 1000000,   // $3.00 per 1M tokens
    output: 15.00 / 1000000  // $15.00 per 1M tokens
};

// 開啟 LLM 設定模態框
function openLLMSettingsModal() {
    document.getElementById('llmSettingsModal').style.display = 'block';
    // 初始化四節點連接管理器
    if (typeof initLLMConnectionManager === 'function') {
        initLLMConnectionManager();
    }
}

// 關閉 LLM 設定模態框
function closeLLMSettingsModal() {
    document.getElementById('llmSettingsModal').style.display = 'none';
}

// 切換 LLM 服務狀態
function toggleLLMService() {
    llmServiceActive = !llmServiceActive;
    
    const toggleBtn = document.getElementById('llmToggleBtn');
    const connection1 = document.getElementById('connection1');
    const connection2 = document.getElementById('connection2');
    const llmIcon = document.getElementById('llmIcon');
    const connectionStatus = document.getElementById('connectionStatus');
    
    if (llmServiceActive) {
        // 啟動狀態
        toggleBtn.innerHTML = '<i class="fas fa-stop"></i> Stop LLM Service';
        toggleBtn.style.background = 'linear-gradient(135deg, #ef4444, #dc2626)';
        
        // FHIR ↔ Web 變灰色 (模擬斷開,但不真的斷線)
        connection1.innerHTML = `
            <div style="height: 3px; background: #cbd5e1; width: 100%; position: relative;">
                <div style="position: absolute; left: 50%; top: -20px; transform: translateX(-50%); color: #94a3b8; font-size: 1.2rem;">✕</div>
            </div>
        `;
        
        // Web ↔ LLM 變綠色 (連接)
        connection2.innerHTML = `
            <div style="height: 3px; background: linear-gradient(90deg, #10b981, #059669); width: 100%; position: relative;">
                <div style="position: absolute; right: 0; top: 50%; transform: translateY(-50%); width: 0; height: 0; border-left: 8px solid #059669; border-top: 6px solid transparent; border-bottom: 6px solid transparent;"></div>
            </div>
        `;
        
        // LLM 圖標變亮
        llmIcon.style.background = 'linear-gradient(135deg, #8b5cf6, #7c3aed)';
        llmIcon.style.boxShadow = '0 4px 12px rgba(139, 92, 246, 0.5)';
        
        connectionStatus.innerHTML = '<i class="fas fa-check-circle" style="color: #10b981;"></i> LLM Service Active: FHIR ✕ Web | Web ↔ LLM';
        connectionStatus.style.color = '#10b981';
        
        console.log('✅ LLM 服務已啟動');
        
        // 開始模擬資料傳輸
        startSimulatingDataTransfer();
        
    } else {
        // 停止狀態
        toggleBtn.innerHTML = '<i class="fas fa-play"></i> Start LLM Service';
        toggleBtn.style.background = 'linear-gradient(135deg, #10b981, #059669)';
        
        // 恢復原始連接狀態
        connection1.innerHTML = `
            <div style="height: 3px; background: linear-gradient(90deg, #10b981, #059669); width: 100%; position: relative;">
                <div style="position: absolute; right: 0; top: 50%; transform: translateY(-50%); width: 0; height: 0; border-left: 8px solid #059669; border-top: 6px solid transparent; border-bottom: 6px solid transparent;"></div>
            </div>
        `;
        
        connection2.innerHTML = `
            <div style="height: 3px; background: #cbd5e1; width: 100%; position: relative;">
                <div style="position: absolute; left: 50%; top: -20px; transform: translateX(-50%); color: #94a3b8; font-size: 1.2rem;">✕</div>
            </div>
        `;
        
        llmIcon.style.background = 'linear-gradient(135deg, #94a3b8, #64748b)';
        llmIcon.style.boxShadow = '0 4px 12px rgba(148, 163, 184, 0.3)';
        
        connectionStatus.innerHTML = '<i class="fas fa-info-circle"></i> Default: FHIR ↔ Web | Web ✕ LLM';
        connectionStatus.style.color = '#64748b';
        
        console.log('⛔ LLM 服務已停止');
        
        // 停止模擬
        stopSimulatingDataTransfer();
    }
}

// 模擬資料傳輸定時器
let simulationInterval = null;

function startSimulatingDataTransfer() {
    // 每2秒模擬一次查詢
    simulationInterval = setInterval(() => {
        if (llmServiceActive) {
            simulateLLMQuery();
        }
    }, 2000);
}

function stopSimulatingDataTransfer() {
    if (simulationInterval) {
        clearInterval(simulationInterval);
        simulationInterval = null;
    }
}

// 模擬一次 LLM 查詢
function simulateLLMQuery() {
    // 隨機生成 Token 數量
    const inputTokens = Math.floor(Math.random() * 5000) + 1000;   // 1000-6000
    const outputTokens = Math.floor(Math.random() * 2000) + 500;   // 500-2500
    const dataKB = Math.floor(Math.random() * 100) + 20;           // 20-120 KB
    
    // 計算費用
    const inputCost = inputTokens * TOKEN_PRICING.input;
    const outputCost = outputTokens * TOKEN_PRICING.output;
    const totalCost = inputCost + outputCost;
    
    // 更新統計
    llmStats.queryCount++;
    llmStats.inputTokens += inputTokens;
    llmStats.outputTokens += outputTokens;
    llmStats.dataTransferKB += dataKB;
    llmStats.totalRevenue += totalCost;
    
    // 記錄歷史
    const historyItem = {
        timestamp: new Date().toLocaleString('zh-TW'),
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        cost: totalCost,
        dataKB: dataKB
    };
    llmStats.history.unshift(historyItem);
    
    // 更新顯示
    updateLLMDisplay();
    addHistoryItem(historyItem);
}

// 更新 LLM 顯示
function updateLLMDisplay() {
    // 更新統計數字
    document.getElementById('queryCount').textContent = llmStats.queryCount;
    document.getElementById('inputTokens').textContent = formatNumber(llmStats.inputTokens);
    document.getElementById('outputTokens').textContent = formatNumber(llmStats.outputTokens);
    document.getElementById('dataTransfer').textContent = formatDataSize(llmStats.dataTransferKB);
    
    // 更新費用表格
    document.getElementById('inputTokensTable').textContent = formatNumber(llmStats.inputTokens);
    document.getElementById('outputTokensTable').textContent = formatNumber(llmStats.outputTokens);
    
    const inputCost = llmStats.inputTokens * TOKEN_PRICING.input;
    const outputCost = llmStats.outputTokens * TOKEN_PRICING.output;
    
    document.getElementById('inputCost').textContent = '$' + inputCost.toFixed(4);
    document.getElementById('outputCost').textContent = '$' + outputCost.toFixed(4);
    document.getElementById('totalRevenue').textContent = '$' + llmStats.totalRevenue.toFixed(4);
}

// 添加歷史記錄項目
function addHistoryItem(item) {
    const historyDiv = document.getElementById('llmHistory');
    
    // 第一次添加時清除空白提示
    if (llmStats.history.length === 1) {
        historyDiv.innerHTML = '';
    }
    
    const historyItem = document.createElement('div');
    historyItem.style.cssText = 'padding: 1rem; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; transition: background 0.3s;';
    historyItem.onmouseenter = function() { this.style.background = '#f8fafc'; };
    historyItem.onmouseleave = function() { this.style.background = 'white'; };
    
    historyItem.innerHTML = `
        <div>
            <div style="font-weight: 600; color: #1e293b; margin-bottom: 0.3rem;">
                <i class="fas fa-clock" style="color: #64748b; margin-right: 0.5rem;"></i>
                ${item.timestamp}
            </div>
            <div style="font-size: 0.85rem; color: #64748b;">
                <span style="margin-right: 1rem;">
                    <i class="fas fa-arrow-down" style="color: #10b981;"></i> ${formatNumber(item.inputTokens)}
                </span>
                <span style="margin-right: 1rem;">
                    <i class="fas fa-arrow-up" style="color: #f59e0b;"></i> ${formatNumber(item.outputTokens)}
                </span>
                <span>
                    <i class="fas fa-database" style="color: #3b82f6;"></i> ${formatDataSize(item.dataKB)}
                </span>
            </div>
        </div>
        <div style="text-align: right;">
            <div style="font-size: 1.2rem; font-weight: 700; color: #10b981;">
                $${item.cost.toFixed(4)}
            </div>
            <div style="font-size: 0.75rem; color: #64748b;">USD</div>
        </div>
    `;
    
    historyDiv.insertBefore(historyItem, historyDiv.firstChild);
    
    // 限制歷史記錄數量
    if (historyDiv.children.length > 50) {
        historyDiv.removeChild(historyDiv.lastChild);
    }
}

// 清除歷史記錄
function clearLLMHistory() {
    if (confirm('Clear all history?')) {
        llmStats.history = [];
        document.getElementById('llmHistory').innerHTML = `
            <div style="text-align: center; padding: 2rem; color: #94a3b8;">
                <i class="fas fa-inbox" style="font-size: 2rem; margin-bottom: 0.5rem;"></i>
                <div>No query history</div>
            </div>
        `;
    }
}

// 格式化數字 (加千分位)
function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(2) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
}

// 格式化資料大小
function formatDataSize(kb) {
    if (kb >= 1024) {
        return (kb / 1024).toFixed(2) + ' MB';
    }
    return kb.toFixed(0) + ' KB';
}

// 點擊模態框外部關閉
window.onclick = function(event) {
    const modal = document.getElementById('llmSettingsModal');
    if (event.target === modal) {
        closeLLMSettingsModal();
    }
};

// 暴露全局函數
window.openLLMSettingsModal = openLLMSettingsModal;
window.closeLLMSettingsModal = closeLLMSettingsModal;
window.toggleLLMService = toggleLLMService;
window.clearLLMHistory = clearLLMHistory;

console.log('✅ LLM 服務管理系統已載入');
