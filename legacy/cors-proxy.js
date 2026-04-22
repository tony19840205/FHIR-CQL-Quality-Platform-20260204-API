// ========== CORS 代理解決方案 ==========

/**
 * CORS 代理配置
 * 解決 GitHub Pages 跨域請求被封鎖的問題
 */

const CORS_PROXIES = [
    {
        name: 'CORS Anywhere (Heroku)',
        url: 'https://cors-anywhere.herokuapp.com/',
        active: false, // 需要先訪問 https://cors-anywhere.herokuapp.com/corsdemo 啟用
        description: '免費但需要每天手動啟用'
    },
    {
        name: 'AllOrigins',
        url: 'https://api.allorigins.win/raw?url=',
        active: true,
        description: '免費且穩定'
    },
    {
        name: 'CORS.SH',
        url: 'https://cors.sh/',
        active: true,
        description: '免費代理服務'
    }
];

/**
 * FHIR 請求包裝器
 * 自動添加 CORS 代理
 */
class FHIRProxyClient {
    constructor(baseUrl, useProxy = true) {
        this.baseUrl = baseUrl;
        this.useProxy = useProxy;
        this.proxyIndex = 1; // 預設使用 AllOrigins (索引 1)
    }

    /**
     * 獲取完整 URL (帶代理)
     */
    getProxiedUrl(endpoint) {
        if (!this.useProxy) {
            return `${this.baseUrl}${endpoint}`;
        }

        const proxy = CORS_PROXIES[this.proxyIndex];
        const targetUrl = `${this.baseUrl}${endpoint}`;
        
        console.log(`🔄 使用 CORS 代理: ${proxy.name}`);
        console.log(`📡 目標 URL: ${targetUrl}`);
        
        return `${proxy.url}${encodeURIComponent(targetUrl)}`;
    }

    /**
     * GET 請求
     */
    async get(endpoint, options = {}) {
        const url = this.getProxiedUrl(endpoint);
        
        try {
            console.log(`🌐 GET ${url}`);
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Accept': 'application/fhir+json',
                    ...options.headers
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error(`❌ 請求失敗: ${error.message}`);
            
            // 嘗試切換到下一個代理
            if (this.proxyIndex < CORS_PROXIES.length - 1) {
                console.log('🔄 切換到備用代理...');
                this.proxyIndex++;
                return this.get(endpoint, options);
            }
            
            throw error;
        }
    }

    /**
     * POST 請求 (上傳資料)
     */
    async post(endpoint, data, options = {}) {
        const url = this.getProxiedUrl(endpoint);
        
        try {
            console.log(`🌐 POST ${url}`);
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/fhir+json',
                    'Accept': 'application/fhir+json',
                    ...options.headers
                },
                body: JSON.stringify(data)
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error(`❌ 上傳失敗: ${error.message}`);
            throw error;
        }
    }

    /**
     * 批次上傳 Bundle
     */
    async postBundle(bundleData) {
        return this.post('/', bundleData);
    }

    /**
     * 測試連線
     */
    async testConnection() {
        try {
            const metadata = await this.get('/metadata');
            console.log('✅ FHIR 伺服器連線成功！');
            console.log('📋 伺服器版本:', metadata.fhirVersion);
            return true;
        } catch (error) {
            console.error('❌ 連線失敗:', error.message);
            return false;
        }
    }

    /**
     * 切換代理
     */
    switchProxy(index) {
        if (index >= 0 && index < CORS_PROXIES.length) {
            this.proxyIndex = index;
            console.log(`🔄 已切換到代理: ${CORS_PROXIES[index].name}`);
        }
    }

    /**
     * 禁用代理 (直接連線)
     */
    disableProxy() {
        this.useProxy = false;
        console.log('⚠️ 已禁用 CORS 代理，使用直接連線');
    }

    /**
     * 啟用代理
     */
    enableProxy() {
        this.useProxy = true;
        console.log('✅ 已啟用 CORS 代理');
    }
}

// 全域變數
window.FHIRProxyClient = FHIRProxyClient;
window.CORS_PROXIES = CORS_PROXIES;

console.log('✅ CORS 代理模組已載入');
console.log('📚 使用方式:');
console.log('   const client = new FHIRProxyClient("https://thas.mohw.gov.tw/v/r4/fhir");');
console.log('   await client.testConnection();');
