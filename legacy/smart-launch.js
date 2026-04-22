// ========== SMART on FHIR Launch 處理邏輯 ==========

/**
 * SMART Launch 處理類別
 * 處理 SMART on FHIR 的 OAuth 2.0 授權流程
 */
class SMARTLaunchHandler {
    constructor() {
        this.authData = null;
        this.tokenData = null;
    }

    /**
     * 初始化 SMART Launch
     * 檢查是否為 SMART Launch 啟動
     */
    async initialize() {
        const urlParams = new URLSearchParams(window.location.search);
        const smartLaunch = urlParams.get('smart_launch');
        
        if (smartLaunch === 'true') {
            console.log('✓ 檢測到 SMART Launch 啟動');
            
            // 從 localStorage 讀取授權資訊
            const authDataStr = localStorage.getItem('smart_auth');
            if (authDataStr) {
                this.authData = JSON.parse(authDataStr);
                console.log('✓ 已載入 SMART 授權資訊');
                
                // 顯示授權資訊
                this.displayAuthInfo();
                
                return true;
            }
        }
        
        return false;
    }

    /**
     * 顯示授權資訊
     */
    displayAuthInfo() {
        const banner = document.getElementById('connectionBanner');
        if (banner) {
            banner.innerHTML = `
                <div style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); 
                            color: white; padding: 15px; border-radius: 10px; margin-bottom: 20px;">
                    <strong>✓ 已透過 SMART on FHIR 授權連線</strong><br>
                    <small>FHIR Server: ${this.authData.iss}</small><br>
                    <small>授權時間: ${new Date(this.authData.timestamp).toLocaleString('zh-TW')}</small>
                </div>
            `;
            banner.classList.add('show');
        }
    }

    /**
     * 取得授權的 FHIR Server URL
     */
    getFHIRServerUrl() {
        return this.authData ? this.authData.iss : null;
    }

    /**
     * 取得存取令牌
     */
    getAccessToken() {
        return this.tokenData ? this.tokenData.access_token : null;
    }

    /**
     * 清除授權資訊
     */
    clearAuth() {
        localStorage.removeItem('smart_auth');
        localStorage.removeItem('smart_token');
        this.authData = null;
        this.tokenData = null;
        console.log('✓ 已清除 SMART 授權資訊');
    }
}

// 全域 SMART Launch Handler
window.smartLaunchHandler = new SMARTLaunchHandler();

// 頁面載入時自動初始化
document.addEventListener('DOMContentLoaded', async function() {
    const isSmartLaunch = await window.smartLaunchHandler.initialize();
    
    if (isSmartLaunch) {
        console.log('✓ SMART Launch 初始化完成');
        
        // 自動設定 FHIR 連線
        const fhirServer = window.smartLaunchHandler.getFHIRServerUrl();
        if (fhirServer && window.fhirConnection) {
            window.fhirConnection.serverUrl = fhirServer;
            window.fhirConnection.isConnected = true;
            console.log('✓ 已自動設定 FHIR Server:', fhirServer);
        }
    }
});
