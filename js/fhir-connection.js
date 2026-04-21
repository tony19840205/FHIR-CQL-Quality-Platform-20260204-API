// ========== FHIR 連線管理 ==========

class FHIRConnection {
    constructor() {
        this.serverUrl = '';
        this.authToken = '';
        this.isConnected = false;
        this.loadConfig();
    }

    // 載入已儲存的配置
    loadConfig() {
        const savedServer = localStorage.getItem('fhirServer');
        const savedToken = localStorage.getItem('authToken');
        
        if (savedServer) {
            this.serverUrl = savedServer;
            // 如果有儲存的伺服器，標記為已連線
            this.isConnected = true;
            
            // 如果頁面有表單元素，更新它們
            const serverInput = document.getElementById('fhirServer');
            if (serverInput) {
                serverInput.value = savedServer;
            }
        }
        
        if (savedToken) {
            this.authToken = savedToken;
            const tokenInput = document.getElementById('authToken');
            if (tokenInput) {
                tokenInput.value = savedToken;
            }
        }
    }

    // 儲存配置
    saveConfig() {
        localStorage.setItem('fhirServer', this.serverUrl);
        if (this.authToken) {
            localStorage.setItem('authToken', this.authToken);
        }
    }

    // 測試連線
    async testConnection() {
        const serverSelect = document.getElementById('fhirServer');
        const customServerInput = document.getElementById('customServer');
        const tokenInput = document.getElementById('authToken');
        
        // 取得伺服器URL
        if (serverSelect.value === 'custom') {
            this.serverUrl = customServerInput.value.trim();
        } else {
            this.serverUrl = serverSelect.value;
        }
        
        this.authToken = tokenInput.value.trim();
        
        if (!this.serverUrl) {
            this.showStatus('Please enter FHIR server URL', 'error');
            return;
        }

        // 🚀 立即更新UI狀態（同步，不等待）
        this.showStatus('Testing connection...', 'info');
        
        // 立即顯示黃色連線中狀態
        const serverStatus = document.getElementById('serverStatus');
        const serverStatusText = document.getElementById('serverStatusText');
        serverStatus.className = 'status-icon warning';
        serverStatusText.textContent = 'Connecting';
        
        document.getElementById('dataStatusText').textContent = '--';
        document.getElementById('dataStatus').className = 'status-icon';
        document.getElementById('responseTimeText').textContent = '--';
        
        // 使用 setTimeout 確保UI立即更新
        await new Promise(resolve => setTimeout(resolve, 0));
        
        const startTime = Date.now();

        try {
            // 構建請求標頭
            const headers = {
                'Accept': 'application/fhir+json'
            };
            
            if (this.authToken) {
                headers['Authorization'] = `Bearer ${this.authToken}`;
            }

            // 測試 metadata endpoint
            const response = await fetch(`${this.serverUrl}/metadata`, {
                method: 'GET',
                headers: headers,
                mode: 'cors'
            });

            const responseTime = Date.now() - startTime;

            if (response.ok) {
                const data = await response.json();
                this.isConnected = true;
                this.saveConfig();
                
                this.showStatus(`✓ Connected! Server version: ${data.fhirVersion || 'N/A'}`, 'success');
                this.updateConnectionStatus(true, responseTime);
                
                // 測試資料可用性
                await this.checkDataAvailability();
            } else {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
        } catch (error) {
            this.isConnected = false;
            this.showStatus(`✗ Connection failed: ${error.message}`, 'error');
            this.updateConnectionStatus(false, 0);
            
            // 連線失敗時也要更新資料狀態
            document.getElementById('dataStatusText').textContent = 'Unavailable';
            document.getElementById('dataStatus').className = 'status-icon inactive';
        }
    }

    // 檢查資料可用性
    async checkDataAvailability() {
        console.log('檢查 FHIR 資料可用性...');
        
        // 立即顯示檢查中狀態（不用動畫）
        document.getElementById('dataStatusText').textContent = 'Checking...';
        document.getElementById('dataStatus').className = 'status-icon warning';
        
        try {
            const headers = {
                'Accept': 'application/fhir+json'
            };
            
            if (this.authToken) {
                headers['Authorization'] = `Bearer ${this.authToken}`;
            }

            // 檢查 Patient 資源（使用較小的查詢以加快速度）
            const response = await fetch(`${this.serverUrl}/Patient?_count=1&_summary=count`, {
                method: 'GET',
                headers: headers,
                mode: 'cors'
            });

            if (response.ok) {
                const data = await response.json();
                console.log('Patient 查詢回應:', data);
                
                // 嘗試多種方式取得資料數量
                let total = 0;
                
                if (data.total !== undefined) {
                    total = data.total;
                } else if (data.entry && Array.isArray(data.entry)) {
                    total = data.entry.length;
                    // 如果有資料，表示至少有這麼多
                    if (total > 0) {
                        total = `${total}+`;
                    }
                }
                
                console.log(`找到 ${total} patient records`);
                
                if (total > 0 || total === '0+') {
                    document.getElementById('dataStatusText').textContent = `${total} patient records`;
                    document.getElementById('dataStatus').className = 'status-icon active';
                } else {
                    document.getElementById('dataStatusText').textContent = 'Available';
                    document.getElementById('dataStatus').className = 'status-icon active';
                }
            } else {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
        } catch (error) {
            console.error('檢查資料可用性失敗:', error);
            document.getElementById('dataStatusText').textContent = 'Unavailable';
            document.getElementById('dataStatus').className = 'status-icon inactive';
        }
    }

    // 更新連線狀態顯示
    updateConnectionStatus(connected, responseTime) {
        const serverStatus = document.getElementById('serverStatus');
        const serverStatusText = document.getElementById('serverStatusText');
        const responseTimeText = document.getElementById('responseTimeText');
        
        if (connected) {
            serverStatus.className = 'status-icon active';
            serverStatusText.textContent = 'Connected';
            responseTimeText.textContent = `${responseTime} ms`;
        } else {
            serverStatus.className = 'status-icon inactive';
            serverStatusText.textContent = 'Disconnected';
            responseTimeText.textContent = '--';
        }
    }

    // 顯示狀態訊息
    showStatus(message, type) {
        const statusDiv = document.getElementById('connectionStatus');
        statusDiv.textContent = message;
        statusDiv.className = `status-message ${type}`;
        
        if (type === 'success' || type === 'error') {
            setTimeout(() => {
                statusDiv.className = 'status-message';
            }, 5000);
        }
    }

    // 執行 FHIR 查詢
    async query(resourceType, params = {}) {
        if (!this.isConnected) {
            throw new Error('Not connected to FHIR server');
        }

        // 支持數組參數(同名參數多次出現)
        const queryParts = [];
        for (const [key, value] of Object.entries(params)) {
            if (Array.isArray(value)) {
                // 數組: 每個值作為獨立參數
                value.forEach(v => queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(v)}`));
            } else {
                // 單一值
                queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
            }
        }
        const queryString = queryParts.join('&');
        const url = `${this.serverUrl}/${resourceType}${queryString ? '?' + queryString : ''}`;

        console.log(`🔍 FHIR查詢: ${url}`);

        const headers = {
            'Accept': 'application/fhir+json'
        };
        
        if (this.authToken) {
            headers['Authorization'] = `Bearer ${this.authToken}`;
        }

        const response = await fetch(url, {
            method: 'GET',
            headers: headers,
            mode: 'cors'
        });

        if (!response.ok) {
            throw new Error(`Query failed: ${response.status} ${response.statusText}`);
        }

        const data = await response.json();
        console.log(`✅ 查詢結果: ${data.entry?.length || 0} 筆資料`);
        return data;
    }

    // 執行 FHIR 請求 (別名方法，與FHIR Client兼容)
    async request(query, options = {}) {
        // 解析查詢字串 "ResourceType?param1=value1&param2=value2"
        const [resourceType, queryString] = query.split('?');
        
        // 解析查詢參數
        const params = {};
        if (queryString) {
            const urlParams = new URLSearchParams(queryString);
            for (const [key, value] of urlParams.entries()) {
                params[key] = value;
            }
        }
        
        return await this.query(resourceType, params);
    }

    // 批次查詢多個資源
    async batchQuery(queries) {
        const results = {};
        
        for (const [key, {resourceType, params}] of Object.entries(queries)) {
            try {
                results[key] = await this.query(resourceType, params);
            } catch (error) {
                console.error(`查詢 ${key} 失敗:`, error);
                results[key] = { error: error.message };
            }
        }
        
        return results;
    }

    // 取得伺服器 URL
    getServerUrl() {
        return this.serverUrl;
    }

    // 檢查連線狀態
    isServerConnected() {
        return this.isConnected;
    }
}

// 全域 FHIR 連線實例
let fhirConnection;

// 頁面載入完成後初始化
document.addEventListener('DOMContentLoaded', function() {
    fhirConnection = new FHIRConnection();
    
    // 伺服器選擇變更（僅在首頁存在這些元素時才添加監聽器）
    const serverSelect = document.getElementById('fhirServer');
    const customServerGroup = document.getElementById('customServerGroup');
    
    if (serverSelect && customServerGroup) {
        serverSelect.addEventListener('change', function() {
            if (this.value === 'custom') {
                customServerGroup.style.display = 'block';
            } else {
                customServerGroup.style.display = 'none';
            }
        });
    }
});

// 測試連線（全域函數）
async function testConnection() {
    await fhirConnection.testConnection();
}
