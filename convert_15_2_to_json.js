/**
 * 使用 CQL Translator 3.10.0 轉換 Indicator_15_2 到 ELM JSON
 * 指標: 3249 - 全人工膝關節置換手術後九十日以內置換物深部感染率
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// 嘗試多個 API 端點
const API_URLS = [
    'https://cql-translation-service.ahrq.gov/cql/translator',
    'https://cql.dataphoria.org/cql/translator',
    'http://localhost:8080/cql/translator'
];

let currentApiIndex = 0;
const API_URL = API_URLS[currentApiIndex];
const CQL_FILE = 'cql/Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.cql';
const OUTPUT_DIR = 'ELM_JSON';

console.log('='.repeat(80));
console.log(' CQL-to-ELM Translator 3.10.0 - Indicator 15_2 (3249)');
console.log(' 全人工膝關節置換手術後九十日以內置換物深部感染率');
console.log('='.repeat(80));

// 讀取CQL檔案
if (!fs.existsSync(CQL_FILE)) {
    console.error(`\n✗ CQL檔案不存在: ${CQL_FILE}`);
    process.exit(1);
}

const cqlContent = fs.readFileSync(CQL_FILE, 'utf-8');
console.log(`\n✓ 讀取CQL檔案: ${CQL_FILE}`);
console.log(`  大小: ${(cqlContent.length / 1024).toFixed(2)} KB`);
console.log(`  行數: ${cqlContent.split('\n').length} 行`);

// 準備轉換請求 - 使用 Translator 3.10.0 標準選項
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
    timeout: 60000  // 60秒超時（這個CQL比較大）
};

console.log(`\n發送到 API: ${API_URL}`);
console.log('轉換選項 (Translator 3.10.0 標準):');
console.log('  ✓ annotations: true');
console.log('  ✓ locators: true');
console.log('  ✓ resultTypes: true');
console.log('  ✓ disableListDemotion: true');
console.log('  ✓ disableListPromotion: true');
console.log('  ✓ signatureLevel: Overloads');

const req = https.request(options, (res) => {
    console.log(`\n狀態碼: ${res.statusCode}`);
    console.log(`Content-Type: ${res.headers['content-type']}`);
    
    let data = '';
    
    res.on('data', (chunk) => {
        data += chunk;
        // 顯示進度
        process.stdout.write('.');
    });
    
    res.on('end', () => {
        console.log('\n');
        
        if (res.statusCode === 200) {
            try {
                const result = JSON.parse(data);
                
                console.log('\n' + '='.repeat(80));
                console.log(' ✓✓✓ 轉換成功！✓✓✓');
                console.log('='.repeat(80));
                
                // 檢查返回的ELM結構
                if (result.library) {
                    const lib = result.library;
                    
                    console.log(`\n【庫資訊】`);
                    console.log(`  名稱: ${lib.identifier.id}`);
                    console.log(`  版本: ${lib.identifier.version}`);
                    
                    // 檢查 annotation (包含 translator 版本資訊)
                    if (lib.annotation && lib.annotation.length > 0) {
                        const anno = lib.annotation[0];
                        console.log(`\n【Translator 資訊】`);
                        console.log(`  版本: ${anno.translatorVersion || '未知'}`);
                        console.log(`  選項: ${anno.translatorOptions || '未知'}`);
                        console.log(`  簽名級別: ${anno.signatureLevel || '未知'}`);
                    }
                    
                    // 統計定義數量
                    console.log(`\n【內容統計】`);
                    
                    if (lib.usings && lib.usings.def) {
                        console.log(`  Using 聲明: ${lib.usings.def.length} 個`);
                    }
                    
                    if (lib.includes && lib.includes.def) {
                        console.log(`  Include 聲明: ${lib.includes.def.length} 個`);
                    }
                    
                    if (lib.codeSystems && lib.codeSystems.def) {
                        console.log(`  代碼系統: ${lib.codeSystems.def.length} 個`);
                    }
                    
                    if (lib.codes && lib.codes.def) {
                        console.log(`  代碼定義: ${lib.codes.def.length} 個`);
                    }
                    
                    if (lib.statements && lib.statements.def) {
                        const stmts = lib.statements.def;
                        console.log(`  定義語句: ${stmts.length} 個`);
                        
                        // 列出主要定義
                        console.log(`\n【主要定義】`);
                        const mainDefs = [
                            'All TKA Procedures',
                            'Valid Deep Infection Cases',
                            'Denominator',
                            'Numerator',
                            'Infection Rate',
                            'Final Report'
                        ];
                        
                        mainDefs.forEach(defName => {
                            const found = stmts.find(s => s.name === defName);
                            if (found) {
                                console.log(`  ✓ ${defName}`);
                            } else {
                                console.log(`  ✗ ${defName} (未找到)`);
                            }
                        });
                    }
                    
                    // 保存 ELM JSON
                    if (!fs.existsSync(OUTPUT_DIR)) {
                        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
                    }
                    
                    const outputFile = path.join(OUTPUT_DIR, 'Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.json');
                    fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');
                    
                    const fileStats = fs.statSync(outputFile);
                    const fileSizeKB = (fileStats.size / 1024).toFixed(2);
                    const lineCount = fs.readFileSync(outputFile, 'utf-8').split('\n').length;
                    
                    console.log(`\n【輸出檔案】`);
                    console.log(`  路徑: ${outputFile}`);
                    console.log(`  大小: ${fileSizeKB} KB`);
                    console.log(`  行數: ${lineCount.toLocaleString()} 行`);
                    
                    // 質量檢查
                    console.log(`\n【質量檢查】`);
                    const sizeOK = parseFloat(fileSizeKB) >= 50;
                    const linesOK = lineCount >= 1000;
                    
                    console.log(`  檔案大小: ${sizeOK ? '✓' : '✗'} ${fileSizeKB} KB ${sizeOK ? '>= 50 KB' : '< 50 KB (可能太小)'}`);
                    console.log(`  行數: ${linesOK ? '✓' : '✗'} ${lineCount} 行 ${linesOK ? '>= 1000 行' : '< 1000 行 (可能不完整)'}`);
                    
                    if (sizeOK && linesOK) {
                        console.log(`\n${'='.repeat(80)}`);
                        console.log(' ✓✓✓ 轉換完成且質量檢查通過！✓✓✓');
                        console.log(`${'='.repeat(80)}`);
                    } else {
                        console.log(`\n⚠ 警告: 檔案可能不完整，請檢查CQL內容`);
                    }
                    
                } else if (result.error) {
                    console.error('\n✗ 轉換錯誤:', result.error);
                    if (result.errorType) {
                        console.error('  錯誤類型:', result.errorType);
                    }
                } else {
                    console.log('\n⚠ 未知的回應格式');
                    console.log('前500字符:', JSON.stringify(result, null, 2).substring(0, 500) + '...');
                }
                
            } catch (e) {
                console.error('\n✗ 解析JSON回應失敗:', e.message);
                console.log('原始數據前1000字符:', data.substring(0, 1000));
            }
        } else {
            console.error(`\n✗ HTTP錯誤: ${res.statusCode}`);
            console.log('回應內容:', data.substring(0, 1000));
        }
    });
});

req.on('error', (e) => {
    console.error('\n✗ 請求失敗:', e.message);
    console.log('\n可能的解決方案:');
    console.log('1. 檢查網路連接');
    console.log('2. 確認API服務可用: https://cql.dataphoria.org/');
    console.log('3. 嘗試使用 VPN 或檢查防火牆設定');
    console.log('4. 稍後再試（服務可能暫時不可用）');
});

req.on('timeout', () => {
    req.destroy();
    console.error('\n✗ 請求超時（60秒）');
    console.log('   CQL檔案較大，轉換需要更長時間');
});

req.write(postData);
req.end();

console.log('\n正在等待 API 回應（這可能需要一些時間）...');
