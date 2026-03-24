/**
 * 使用Alphora Cloud CQL Translator轉換Indicator_03_1到官方ELM
 * API: https://cloud.alphora.com/cql-translator/translate
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const API_URL = 'https://cql.dataphoria.org/cql/translator';
const CQL_FILE = 'cql/Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql';
const OUTPUT_DIR = 'ELM_JSON_OFFICIAL/舊50';

console.log('='.repeat(70));
console.log(' Alphora Cloud CQL Translator - 官方ELM轉換');
console.log(' Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710');
console.log('='.repeat(70));

// 讀取CQL
const cqlContent = fs.readFileSync(CQL_FILE, 'utf-8');
console.log(`\n✓ 讀取: ${CQL_FILE}`);
console.log(`  大小: ${(cqlContent.length / 1024).toFixed(2)} KB`);

// 準備請求 - 使用與官方translator 3.10.0相同的選項
const postData = JSON.stringify({
    cql: cqlContent,
    annotations: true,
    locators: true,
    resultTypes: true,
    disableListDemotion: true,
    disableListPromotion: true,
    signatureLevel: 'Overloads'
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
console.log('轉換選項:');
console.log('  - annotations: true');
console.log('  - disableListDemotion: true');
console.log('  - disableListPromotion: true');
console.log('  - signatureLevel: Overloads');

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
                    
                    // 檢查annotation
                    if (result.library.annotation) {
                        const anno = result.library.annotation[0];
                        console.log(`Translator版本: ${anno.translatorVersion}`);
                        console.log(`選項: ${anno.translatorOptions}`);
                        console.log(`簽名級別: ${anno.signatureLevel}`);
                    }
                    
                    if (result.library.statements) {
                        const stmtCount = result.library.statements.def.length;
                        console.log(`定義語句: ${stmtCount}個`);
                    }
                    
                    if (result.library.codeSystems) {
                        const csCount = result.library.codeSystems.def.length;
                        console.log(`代碼系統: ${csCount}個`);
                    }
                    
                    if (result.library.codes) {
                        const codeCount = result.library.codes.def.length;
                        console.log(`代碼定義: ${codeCount}個`);
                    }
                    
                    // 保存ELM
                    if (!fs.existsSync(OUTPUT_DIR)) {
                        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
                    }
                    
                    const outputFile = path.join(OUTPUT_DIR, 'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.json');
                    fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');
                    
                    const fileStats = fs.statSync(outputFile);
                    const fileSizeKB = (fileStats.size / 1024).toFixed(2);
                    const lineCount = fs.readFileSync(outputFile, 'utf-8').split('\n').length;
                    
                    console.log(`\n✓ 已保存官方ELM:`);
                    console.log(`  ${outputFile}`);
                    console.log(`  大小: ${fileSizeKB} KB`);
                    console.log(`  行數: ${lineCount} 行`);
                    
                    // 與參考文件比較
                    console.log('\n質量比較:');
                    console.log('  參考: Indicator_01 (60.52 KB, 1435行)');
                    console.log(`  本次: Indicator_03_1 (${fileSizeKB} KB, ${lineCount}行)`);
                    
                    if (parseFloat(fileSizeKB) < 50) {
                        console.log('\n⚠ 警告: 文件大小可能偏小，請檢查CQL是否完整');
                    } else {
                        console.log('\n✓ 文件大小正常');
                    }
                    
                } else if (result.error) {
                    console.error('\n✗ 轉換錯誤:', result.error);
                } else {
                    console.log('\n原始響應:');
                    console.log(JSON.stringify(result, null, 2).substring(0, 500) + '...');
                }
                
            } catch (e) {
                console.error('\n✗ 解析響應失敗:', e.message);
                console.log('原始數據前500字符:', data.substring(0, 500));
            }
        } else {
            console.error(`\n✗ HTTP錯誤: ${res.statusCode}`);
            console.log('響應:', data);
        }
    });
});

req.on('error', (e) => {
    console.error('\n✗ 請求失敗:', e.message);
    console.log('\n可能的解決方案:');
    console.log('1. 檢查網路連接');
    console.log('2. 確認API服務可用: https://cloud.alphora.com/cql-translator/');
    console.log('3. 嘗試使用VPN或代理');
});

req.on('timeout', () => {
    req.destroy();
    console.error('\n✗ 請求超時（30秒）');
});

req.write(postData);
req.end();

console.log('\n正在等待API響應...');
