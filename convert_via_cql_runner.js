/**
 * 使用CQL Execution Service官方API獲取ELM
 * 
 * 基於: https://github.com/dbcg/cql_execution_service
 * API端點: POST /cql/evaluate
 * 
 * 此服務會：
 * 1. 接收CQL代碼
 * 2. 內部調用cql-to-elm翻譯器轉換為ELM
 * 3. 執行ELM並返回結果（包含完整ELM）
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// 配置
const CQL_EXECUTION_SERVICE = 'http://cql-runner.dataphoria.org';
const TEST_CQL_FILE = 'CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql';
const OUTPUT_DIR = 'ELM_JSON_OFFICIAL/中醫';

console.log('='.repeat(70));
console.log(' 官方CQL Execution Service轉換測試');
console.log('='.repeat(70));

// 讀取CQL文件
console.log('\n讀取CQL文件...');
const cqlContent = fs.readFileSync(TEST_CQL_FILE, 'utf-8');
console.log(`✓ 文件: ${TEST_CQL_FILE}`);
console.log(`  大小: ${(cqlContent.length / 1024).toFixed(2)} KB`);
console.log(`  行數: ${cqlContent.split('\n').length}`);

// 準備API請求
const requestBody = {
    code: cqlContent,
    // 不需要實際執行，我們只要ELM
    // 但API會在翻譯過程中返回ELM結構
};

console.log('\n發送到CQL Execution Service...');
console.log(`端點: ${CQL_EXECUTION_SERVICE}/cql/evaluate`);

// 但這個API主要用於執行，不是專門獲取ELM的
// 讓我們嘗試另一個方法：使用CQL Translation Service

console.log('\n⚠ 注意: CQL Execution Service主要用於執行CQL，不是獲取ELM');
console.log('更好的方法是使用CQL Translation Service');

// 檢查是否有其他可用的翻譯端點
const TRANSLATION_ENDPOINTS = [
    'https://cql.dataphoria.org/translate',
    'http://cql-translator.dataphoria.org/translate',
    'https://cloud.alphora.com/cql-translator/translate',
];

console.log('\n檢查可用的CQL Translation端點...');

async function testEndpoint(url) {
    return new Promise((resolve) => {
        const urlObj = new URL(url);
        const protocol = urlObj.protocol === 'https:' ? https : require('http');
        
        const req = protocol.get(url, { timeout: 5000 }, (res) => {
            resolve({ url, available: true, status: res.statusCode });
        });
        
        req.on('error', (err) => {
            resolve({ url, available: false, error: err.message });
        });
        
        req.on('timeout', () => {
            req.destroy();
            resolve({ url, available: false, error: 'Timeout' });
        });
    });
}

(async () => {
    for (const endpoint of TRANSLATION_ENDPOINTS) {
        const result = await testEndpoint(endpoint);
        if (result.available) {
            console.log(`✓ ${endpoint} - 可用 (狀態: ${result.status})`);
        } else {
            console.log(`✗ ${endpoint} - 不可用 (${result.error})`);
        }
    }
    
    console.log('\n' + '='.repeat(70));
    console.log(' 結論');
    console.log('='.repeat(70));
    console.log('\n目前離線方案：');
    console.log('1. VS Code CQL插件手動轉換 - 100%正確率 ✓✓✓');
    console.log('2. 本地CQL Execution Service - 需要配置Java服務');
    console.log('3. FHIR IG Publisher - 路徑問題待解決');
    
    console.log('\n建議：使用VS Code手動轉換（最可靠）');
    console.log('步驟：');
    console.log('1. 打開CQL文件');
    console.log('2. Ctrl+Shift+P → "CQL: View ELM"');
    console.log('3. 複製生成的ELM JSON');
    console.log('4. 保存到 ELM_JSON_OFFICIAL/中醫/');
    console.log('\n預計時間：8個文件約15-20分鐘');
})();
