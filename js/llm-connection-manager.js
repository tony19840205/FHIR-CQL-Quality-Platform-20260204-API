/**
 * LLM 連線控制台 - 四節點連接管理器
 * 控制 FHIR → 控制網頁 → 民眾網頁 → LLM 的連接狀態與動畫
 */

class LLMConnectionManager {
    constructor() {
        this.state = 'normal'; // normal, transitioning
        this.nodes = {};
        this.lines = {};
        this.messageElement = null;
        this.uiButton = null;
        this.llmButton = null;
        
        // 連線狀態
        this.uiConnected = false;
        this.llmConnected = false;
        
        // 計費相關
        this.billingActive = false;
        this.billingStartTime = null;
        this.billingInterval = null;
        this.queryCount = 0;
        this.inputTokens = 0;
        this.outputTokens = 0;
        this.dataTransfer = 0;
    }

    /**
     * 初始化連接管理器
     */
    init() {
        // 獲取所有節點元素
        this.nodes.fhir = document.querySelector('.node-fhir');
        this.nodes.control = document.querySelector('.node-control');
        this.nodes.public = document.querySelector('.node-public');
        this.nodes.llm = document.querySelector('.node-llm');

        // 獲取所有連接線元素
        this.lines.fhirToControl = document.querySelector('.line-fhir-control');
        this.lines.controlToPublic = document.querySelector('.line-control-public');
        this.lines.publicToLLM = document.querySelector('.line-public-llm');

        // 獲取訊息元素和按鈕
        this.messageElement = document.getElementById('llmConnectionMessage');
        this.uiButton = document.getElementById('uiConnectBtn');
        this.llmButton = document.getElementById('llmConnectBtn');

        // 設置初始狀態
        this.setNormalState();

        console.log('✅ LLMConnectionManager initialized');
    }

    /**
     * 設置正常狀態（FHIR ↔ 控制網頁，民眾網頁 → LLM）
     */
    setNormalState() {
        this.state = 'normal';
        this.uiConnected = false;
        this.llmConnected = true; // LLM 預設已連線
        
        // FHIR → 控制網頁：已連接
        this.setLineState('fhirToControl', 'connected');
        this.setNodeState('fhir', 'active');
        this.setNodeState('control', 'active');
        
        // 控制網頁 → 民眾網頁：斷開
        this.setLineState('controlToPublic', 'disconnected');
        this.setNodeState('public', 'active'); // 民眾網頁啟動
        
        // 民眾網頁 ↔ LLM：已連接並雙向傳輸
        this.setLineState('publicToLLM', 'transferring'); // 持續傳輸
        this.setNodeState('llm', 'active');
        this.addDataParticles('publicToLLM', true); // 添加雙向傳輸動畫
        
        // 啟動計費
        this.startBilling();
        
        // 更新按鈕狀態
        this.updateLLMButtonState('active');

        this.showMessage('🔄 LLM 服務運行中 | 💰 計費已啟動', 'success');
    }

    /**
     * 連線 UI/UX
     */
    async connectUI() {
        this.state = 'transitioning';
        this.updateUIButtonState('loading');

        try {
            // 階段 1: 停止計費並關閉 LLM
            console.log('💰 Stopping billing and disconnecting LLM...');
            this.showMessage('正在停止計費並關閉 LLM...', 'info');
            this.stopBilling();
            
            // 清除 LLM 傳輸動畫
            const llmLine = this.lines.publicToLLM;
            if (llmLine) {
                const particles = llmLine.querySelectorAll('.data-particle, .data-number');
                particles.forEach(p => p.remove());
            }
            
            this.setLineState('publicToLLM', 'disconnected');
            this.setNodeState('llm', 'inactive');
            this.llmConnected = false;
            await this.sleep(1000);

            // 階段 2: 斷開 FHIR
            console.log('🔌 Disconnecting FHIR...');
            this.showMessage('正在關閉 FHIR 連線...', 'info');
            this.setLineState('fhirToControl', 'disconnected');
            this.setNodeState('fhir', 'inactive');
            await this.sleep(1000);

            // 階段 3: 開啟控制網頁 → 民眾網頁傳輸（5-8秒）
            const transferDuration = 5000 + Math.random() * 3000;
            console.log(`📊 Transferring data to UI for ${Math.round(transferDuration)}ms...`);
            this.showMessage('🔄 正在傳輸資料至民眾網頁... 📊 數據去識別化處理中', 'transfer');
            this.setNodeState('public', 'active');
            this.setLineState('controlToPublic', 'transferring');
            this.addDataParticles('controlToPublic');

            // ★ 真實數據匯出 — 收集去識別化數據並推送至民眾網頁
            if (window.dataExporter) {
                console.log('📦 開始匯出去識別化數據...');
                this.showMessage('🔄 數據去識別化處理中... 匯出至民眾網頁', 'transfer');
                try {
                    const exportResult = await window.dataExporter.exportToPublicSite();
                    console.log('✅ 數據匯出結果:', exportResult);
                    if (exportResult.success) {
                        this.showMessage(`✅ 數據已成功推送至民眾網頁 (${exportResult.method})`, 'success');
                    } else {
                        this.showMessage('📥 數據已下載，請手動部署至民眾網頁', 'info');
                    }
                } catch (err) {
                    console.warn('⚠️ 數據匯出失敗（動畫繼續）:', err);
                    this.showMessage('⚠️ 匯出失敗，動畫繼續...', 'info');
                }
            }
            
            await this.sleep(transferDuration);

            // 階段 4: 傳輸完成，清除動畫
            console.log('✅ UI/UX transfer completed');
            this.showMessage('✅ UI/UX 傳輸完成，正在恢復連線...', 'success');
            
            // 清除傳輸動畫
            const line = this.lines.controlToPublic;
            if (line) {
                const particles = line.querySelectorAll('.data-particle, .data-number');
                particles.forEach(p => p.remove());
            }
            
            // 斷開 UI 連線
            this.setLineState('controlToPublic', 'disconnected');
            await this.sleep(500);
            
            // 階段 5: 重新連接 FHIR
            console.log('🔌 Reconnecting FHIR...');
            this.showMessage('正在重新連接 FHIR...', 'info');
            this.setLineState('fhirToControl', 'connected');
            this.setNodeState('fhir', 'active');
            await this.sleep(1000);

            // 階段 6: 重新連接 LLM 並啟動計費
            console.log('🤖 Reconnecting LLM and restarting billing...');
            this.showMessage('正在重新連接 LLM 並啟動計費...', 'info');
            this.setLineState('publicToLLM', 'transferring');
            this.setNodeState('llm', 'active');
            this.addDataParticles('publicToLLM', true); // 雙向傳輸
            
            // 啟動計費
            this.startBilling();
            this.llmConnected = true;
            await this.sleep(1000);

            this.state = 'normal';
            this.uiConnected = false;
            this.updateUIButtonState('inactive');
            this.showMessage('✅ 已恢復正常模式 | 💰 計費已啟動', 'success');
            
        } catch (error) {
            console.error('❌ Error connecting UI:', error);
            this.showMessage('UI 連線失敗', 'info');
            this.state = 'normal';
            this.updateUIButtonState('inactive');
        }
    }

    /**
     * 斷開 UI，恢復正常模式
     */
    async disconnectUI() {
        this.state = 'transitioning';
        this.updateUIButtonState('loading');

        try {
            console.log('🔌 Disconnecting UI and restoring normal mode...');
            this.showMessage('正在關閉 UI/UX...', 'info');
            
            // 斷開 UI 連線
            this.setLineState('controlToPublic', 'disconnected');
            this.setNodeState('public', 'active'); // 保持民眾網頁啟動
            await this.sleep(1000);

            // 重新連接 FHIR
            console.log('🔌 Reconnecting FHIR...');
            this.showMessage('正在重新連接 FHIR...', 'info');
            this.setLineState('fhirToControl', 'connected');
            this.setNodeState('fhir', 'active');
            this.setNodeState('control', 'active');
            await this.sleep(1000);

            // 重新連接 LLM 並啟動計費
            console.log('🤖 Reconnecting LLM and starting billing...');
            this.showMessage('正在重新連接 LLM 並啟動計費...', 'info');
            this.setLineState('publicToLLM', 'transferring');
            this.setNodeState('llm', 'active');
            this.addDataParticles('publicToLLM', true); // 雙向傳輸
            
            // 啟動計費
            this.startBilling();
            this.llmConnected = true;
            await this.sleep(1000);

            this.state = 'normal';
            this.uiConnected = false;
            this.updateUIButtonState('inactive');
            this.showMessage('✅ 已恢復正常模式 | 💰 計費已啟動', 'success');

        } catch (error) {
            console.error('❌ Error disconnecting UI:', error);
            this.state = 'normal';
        }
    }

    /**
     * 連線 LLM
     */
    async connectLLM() {
        this.state = 'transitioning';
        this.updateLLMButtonState('loading');

        try {
            console.log('🤖 Connecting to LLM...');
            this.showMessage('正在連線 LLM...', 'info');
            this.setLineState('publicToLLM', 'connected');
            this.setNodeState('llm', 'active');
            await this.sleep(500);

            // 開始數據傳輸到 LLM
            console.log('💰 Starting bidirectional data transfer to LLM and billing...');
            this.showMessage('🔄 正在雙向傳輸數據至 AI... 💰 計費已啟動', 'transfer');
            this.setLineState('publicToLLM', 'transferring');
            this.addDataParticles('publicToLLM', true); // 雙向傳輸
            
            // 啟動計費
            this.startBilling();
            await this.sleep(1000);

            this.state = 'normal';
            this.llmConnected = true;
            this.updateLLMButtonState('active');
            this.showMessage('✅ LLM 服務運行中 | 💰 按使用量計費', 'success');

            console.log('✅ LLM connected with billing');
        } catch (error) {
            console.error('❌ Error connecting LLM:', error);
            this.showMessage('LLM 連線失敗', 'info');
            this.state = 'normal';
            this.updateLLMButtonState('inactive');
        }
    }

    /**
     * 斷開 LLM
     */
    async disconnectLLM() {
        this.state = 'transitioning';
        this.updateLLMButtonState('loading');

        try {
            // 停止計費
            this.stopBilling();

            console.log('🔌 Disconnecting LLM and stopping billing...');
            this.showMessage('正在斷開 LLM... 💰 停止計費', 'info');
            
            // 清除 LLM 傳輸動畫
            const llmLine = this.lines.publicToLLM;
            if (llmLine) {
                const particles = llmLine.querySelectorAll('.data-particle, .data-number');
                particles.forEach(p => p.remove());
            }

            this.setLineState('publicToLLM', 'disconnected');
            this.setNodeState('llm', 'inactive');
            await this.sleep(1000);

            this.state = 'normal';
            this.llmConnected = false;
            this.updateLLMButtonState('inactive');
            this.showMessage('LLM 已斷線 | 計費已停止', 'info');

            console.log('✅ LLM disconnected, billing ended');
        } catch (error) {
            console.error('❌ Error disconnecting LLM:', error);
            this.state = 'normal';
        }
    }



    /**
     * 設置連接線狀態
     */
    setLineState(lineName, state) {
        const line = this.lines[lineName];
        if (!line) return;

        // 移除所有狀態 class
        line.classList.remove('connected', 'disconnected', 'transferring');
        
        // 添加新狀態
        if (state !== 'none') {
            line.classList.add(state);
        }
    }

    /**
     * 設置節點狀態
     */
    setNodeState(nodeName, state) {
        const node = this.nodes[nodeName];
        if (!node) return;

        node.classList.remove('active', 'inactive');
        node.classList.add(state);

        if (state === 'active') {
            // 添加激活動畫
            node.classList.add('activating');
            setTimeout(() => node.classList.remove('activating'), 600);
        }
    }

    /**
     * 添加資料粒子動畫
     */
    addDataParticles(lineName, bidirectional = false) {
        const line = this.lines[lineName];
        if (!line) return;

        // 清除舊粒子
        const oldParticles = line.querySelectorAll('.data-particle, .data-number');
        oldParticles.forEach(p => p.remove());

        if (bidirectional) {
            // 雙向傳輸：創建正向和反向粒子
            // 正向粒子（左到右）
            for (let i = 0; i < 4; i++) {
                const particle = document.createElement('div');
                particle.className = 'data-particle';
                particle.style.animationDelay = `${i * 0.4}s`;
                line.appendChild(particle);
            }
            
            // 反向粒子（右到左）
            for (let i = 0; i < 4; i++) {
                const particle = document.createElement('div');
                particle.className = 'data-particle';
                particle.style.animation = 'particleFlowReverse 2s infinite';
                particle.style.animationDelay = `${i * 0.4 + 0.2}s`;
                particle.style.background = 'linear-gradient(135deg, #60a5fa, #3b82f6)'; // 不同顏色區分方向
                line.appendChild(particle);
            }
            
            // 雙向數字動畫
            const numbers = ['123', '456', '789', '1024'];
            numbers.forEach((num, index) => {
                setTimeout(() => {
                    const number = document.createElement('div');
                    number.className = 'data-number';
                    number.textContent = num;
                    number.style.left = `${20 + index * 20}%`;
                    line.appendChild(number);
                }, index * 500);
            });
        } else {
            // 單向傳輸：創建 5 個粒子
            for (let i = 0; i < 5; i++) {
                const particle = document.createElement('div');
                particle.className = 'data-particle';
                line.appendChild(particle);
            }

            // 創建數字動畫
            const numbers = ['123', '456', '789', '1024'];
            numbers.forEach((num, index) => {
                setTimeout(() => {
                    const number = document.createElement('div');
                    number.className = 'data-number';
                    number.textContent = num;
                    number.style.left = `${20 + index * 20}%`;
                    line.appendChild(number);
                }, index * 500);
            });
        }
    }

    /**
     * 顯示訊息
     */
    showMessage(text, type = 'info') {
        if (!this.messageElement) return;

        const icons = {
            info: 'ℹ️',
            success: '✅',
            transfer: '📊'
        };

        this.messageElement.className = `connection-status-message ${type}`;
        this.messageElement.innerHTML = `${icons[type] || 'ℹ️'} ${text}`;
    }

    /**
     * 更新 UI 按鈕狀態
     */
    updateUIButtonState(state) {
        if (!this.uiButton) return;

        this.uiButton.classList.remove('inactive', 'loading', 'active');
        this.uiButton.classList.add(state);

        const buttonContent = {
            inactive: '<i class="fas fa-upload"></i> <span>連線 UI/UX</span>',
            loading: '<i class="fas fa-spinner fa-spin"></i> <span>連線中...</span>',
            active: '<i class="fas fa-stop-circle"></i> <span>關閉 UI/UX</span>'
        };

        this.uiButton.innerHTML = buttonContent[state] || buttonContent.inactive;
    }

    /**
     * 更新 LLM 按鈕狀態
     */
    updateLLMButtonState(state) {
        if (!this.llmButton) return;

        this.llmButton.classList.remove('inactive', 'loading', 'active');
        this.llmButton.classList.add(state);

        const buttonContent = {
            inactive: '<i class="fas fa-brain"></i> <span>連線 LLM</span>',
            loading: '<i class="fas fa-spinner fa-spin"></i> <span>連線中...</span>',
            active: '<i class="fas fa-stop-circle"></i> <span>斷開 LLM</span>'
        };

        this.llmButton.innerHTML = buttonContent[state] || buttonContent.inactive;
    }

    /**
     * 切換 UI 連線
     */
    async toggleUIConnection() {
        if (this.state === 'transitioning') {
            console.warn('⚠️ Please wait for current operation to complete');
            return;
        }

        if (this.uiConnected) {
            // 斷開 UI，恢復正常模式
            await this.disconnectUI();
        } else {
            // 連線 UI
            await this.connectUI();
        }
    }

    /**
     * 切換 LLM 連線
     */
    async toggleLLMConnection() {
        if (this.state === 'transitioning') {
            console.warn('⚠️ Please wait for current operation to complete');
            return;
        }

        if (!this.uiConnected) {
            this.showMessage('⚠️ 請先連線 UI/UX', 'info');
            return;
        }

        if (this.llmConnected) {
            // 斷開 LLM
            await this.disconnectLLM();
        } else {
            // 連線 LLM
            await this.connectLLM();
        }
    }

    /**
     * 啟動計費系統
     */
    startBilling() {
        console.log('💰 Billing started');
        this.billingStartTime = Date.now();
        this.billingActive = true;
        
        // 初始化計費數據
        this.queryCount = 0;
        this.inputTokens = 0;
        this.outputTokens = 0;
        this.dataTransfer = 0;
        
        // 更新顯示
        this.updateBillingDisplay();
        
        // 模擬數據增長
        this.billingInterval = setInterval(() => {
            // 模擬查詢和 Token 使用
            this.queryCount += Math.floor(Math.random() * 3) + 1;
            this.inputTokens += Math.floor(Math.random() * 5000) + 2000;
            this.outputTokens += Math.floor(Math.random() * 3000) + 1000;
            this.dataTransfer += Math.floor(Math.random() * 50) + 20;
            
            // 更新顯示
            this.updateBillingDisplay();
            
            const elapsed = Math.floor((Date.now() - this.billingStartTime) / 1000);
            console.log(`💰 Billing: ${elapsed}s elapsed, Queries: ${this.queryCount}, Input: ${this.inputTokens}, Output: ${this.outputTokens}`);
        }, 2000); // 每 2 秒更新一次
    }

    /**
     * 停止計費系統
     */
    stopBilling() {
        if (this.billingActive) {
            const totalTime = Math.floor((Date.now() - this.billingStartTime) / 1000);
            
            // 計算最終費用
            const inputCost = (this.inputTokens / 1000000) * 3;
            const outputCost = (this.outputTokens / 1000000) * 15;
            const totalRevenue = inputCost + outputCost;
            
            console.log(`💰 Billing stopped. Total time: ${totalTime}s`);
            console.log(`   - Queries: ${this.queryCount}`);
            console.log(`   - Input tokens: ${this.inputTokens} ($${inputCost.toFixed(2)})`);
            console.log(`   - Output tokens: ${this.outputTokens} ($${outputCost.toFixed(2)})`);
            console.log(`   - Total revenue: $${totalRevenue.toFixed(2)}`);
            
            if (this.billingInterval) {
                clearInterval(this.billingInterval);
                this.billingInterval = null;
            }
            
            this.billingActive = false;
            this.billingStartTime = null;
        }
    }

    /**
     * 更新計費顯示
     */
    updateBillingDisplay() {
        // 更新即時使用狀態
        const queryCountEl = document.getElementById('queryCount');
        const inputTokensEl = document.getElementById('inputTokens');
        const outputTokensEl = document.getElementById('outputTokens');
        const dataTransferEl = document.getElementById('dataTransfer');
        
        if (queryCountEl) queryCountEl.textContent = this.queryCount || 0;
        if (inputTokensEl) inputTokensEl.textContent = (this.inputTokens || 0).toLocaleString();
        if (outputTokensEl) outputTokensEl.textContent = (this.outputTokens || 0).toLocaleString();
        if (dataTransferEl) dataTransferEl.textContent = `${(this.dataTransfer || 0)} KB`;
        
        // 更新獲利金額表格
        const inputTokensTableEl = document.getElementById('inputTokensTable');
        const outputTokensTableEl = document.getElementById('outputTokensTable');
        const inputCostEl = document.getElementById('inputCost');
        const outputCostEl = document.getElementById('outputCost');
        const totalRevenueEl = document.getElementById('totalRevenue');
        
        if (inputTokensTableEl) inputTokensTableEl.textContent = (this.inputTokens || 0).toLocaleString();
        if (outputTokensTableEl) outputTokensTableEl.textContent = (this.outputTokens || 0).toLocaleString();
        
        // 計算費用
        const inputCost = ((this.inputTokens || 0) / 1000000) * 3;
        const outputCost = ((this.outputTokens || 0) / 1000000) * 15;
        const totalRevenue = inputCost + outputCost;
        
        if (inputCostEl) inputCostEl.textContent = `$${inputCost.toFixed(2)}`;
        if (outputCostEl) outputCostEl.textContent = `$${outputCost.toFixed(2)}`;
        if (totalRevenueEl) totalRevenueEl.textContent = `$${totalRevenue.toFixed(2)}`;
    }

    /**
     * 工具函數：延遲
     */
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * 獲取當前狀態
     */
    getState() {
        return {
            currentState: this.state,
            isExternalActive: this.isExternalServiceActive,
            billingActive: this.billingActive || false,
            connections: {
                fhirToControl: this.lines.fhirToControl?.className || '',
                controlToPublic: this.lines.controlToPublic?.className || '',
                publicToLLM: this.lines.publicToLLM?.className || ''
            }
        };
    }
}

// 全局實例
let llmConnectionManager = null;

// 初始化函數（在 LLM 彈窗開啟時調用）
function initLLMConnectionManager() {
    if (!llmConnectionManager) {
        llmConnectionManager = new LLMConnectionManager();
    }
    // 延遲初始化以確保 DOM 已載入
    setTimeout(() => {
        llmConnectionManager.init();
    }, 100);
    console.log('✅ LLM Connection management system ready');
}

// 按鈕點擊處理 - UI 連線
function toggleUIConnection() {
    if (llmConnectionManager) {
        llmConnectionManager.toggleUIConnection();
    } else {
        console.error('❌ LLMConnectionManager not initialized');
    }
}

// 按鈕點擊處理 - LLM 連線
function toggleLLMConnection() {
    if (llmConnectionManager) {
        llmConnectionManager.toggleLLMConnection();
    } else {
        console.error('❌ LLMConnectionManager not initialized');
    }
}

// 導出供外部使用
if (typeof window !== 'undefined') {
    window.LLMConnectionManager = LLMConnectionManager;
    window.initLLMConnectionManager = initLLMConnectionManager;
    window.toggleUIConnection = toggleUIConnection;
    window.toggleLLMConnection = toggleLLMConnection;
}
