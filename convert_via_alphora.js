/**
 * 使用Alphora Cloud CQL Translator轉換CQL到ELM
 * API: https://cloud.alphora.com/cql-translator/translate
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const API_URL = 'https://cloud.alphora.com/cql-translator/translate';
const TEST_CQL_FILE = 'CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql';
const OUTPUT_DIR = 'ELM_JSON_OFFICIAL/中醫';

console.log('='.repeat(70));
console.log(' Alphora Cloud CQL Translator - 官方ELM轉換');
console.log('='.repeat(70));

// 讀取CQL
const cqlContent = fs.readFileSync(TEST_CQL_FILE, 'utf-8');
console.log(`\n✓ 讀取: ${TEST_CQL_FILE}`);
console.log(`  大小: ${(cqlContent.length / 1024).toFixed(2)} KB`);

// 準備請求
const postData = JSON.stringify({
    cql: cqlContent,
    options: {
        format: 'json',
        'enable-annotations': true,
        'enable-locators': true,
        'disable-list-traversal': false,
        'disable-list-demotion': false,
        'disable-list-promotion': false,
        'enable-interval-demotion': false,
        'enable-interval-promotion': false,
        'disable-method-invocation': false,
        'require-from-keyword': false,
        'signed-date-range-optimization': false,
        'detailed-errors': false,
        'error-level': 'Info',
        'disable-list-traversal': false,
        'compatibility-level': '1.5'
    }
});

const urlObj = new URL(API_URL);
const options = {
    hostname: urlObj.hostname,
    port: 443,
    path: urlObj.pathname,
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'Accept': 'application/json'
    },
    timeout: 30000
};

console.log(`\n發送到: ${API_URL}`);
console.log('轉換選項: JSON格式, 啟用註釋, 啟用位置');

const req = https.request(options, (res) => {
    console.log(`\n狀態碼: ${res.statusCode}`);
    console.log(`Content-Type: ${res.headers['content-type']}`);
    
    let data = '';
    
    res.on('data', (chunk) => {
        data += chunk;
    });
    
    res.on('end', () => {
        if (res.statusCode === 200) {
            try {
                const result = JSON.parse(data);
                
                console.log('\n✓✓✓ 轉換成功！✓✓✓');
                
                // 檢查返回的ELM
                if (result.library) {
                    console.log(`\n庫名: ${result.library.identifier.id}`);
                    console.log(`版本: ${result.library.identifier.version}`);
                    
                    if (result.library.statements) {
                        const stmtCount = result.library.statements.def.length;
                        console.log(`定義語句: ${stmtCount}個`);
                    }
                    
                    // 保存ELM
                    if (!fs.existsSync(OUTPUT_DIR)) {
                        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
                    }
                    
                    const outputFile = path.join(OUTPUT_DIR, 'Indicator_TCM_Same_Day_Revisit_Rate.json');
                    fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');
                    
                    console.log(`\n✓ 已保存官方ELM:`);
                    console.log(`  ${outputFile}`);
                    console.log(`  大小: ${(fs.statSync(outputFile).size / 1024).toFixed(2)} KB`);
                    
                    console.log('\n運行驗證腳本:');
                    console.log('node verify_elm_quality.js "' + outputFile + '"');
                    
                } else if (result.error) {
                    console.error('\n✗ 轉換錯誤:', result.error);
                } else {
                    console.log('\n原始響應:');
                    console.log(JSON.stringify(result, null, 2).substring(0, 500) + '...');
                }
                
            } catch (e) {
                console.error('\n✗ 解析響應失敗:', e.message);
                console.log('原始數據:', data.substring(0, 500));
            }
        } else {
            console.error(`\n✗ HTTP錯誤: ${res.statusCode}`);
            console.log('響應:', data);
        }
    });
});

req.on('error', (e) => {
    console.error('\n✗ 請求失敗:', e.message);
});

req.on('timeout', () => {
    req.destroy();
    console.error('\n✗ 請求超時');
});

req.write(postData);
req.end();
