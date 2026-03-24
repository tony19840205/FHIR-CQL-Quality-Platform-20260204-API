const fs = require('fs');
const path = require('path');
const http = require('http');

/**
 * 批量轉換工具 - 使用本地CQL翻譯服務
 * 連接到 http://localhost:8080
 */

const LOCAL_SERVICE = 'localhost';
const LOCAL_PORT = process.env.CQL_TRANSLATOR_PORT || 8080;

async function testLocalService() {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: LOCAL_SERVICE,
            port: LOCAL_PORT,
            path: '/cql/translator',
            method: 'GET',
            timeout: 5000
        };
        
        const req = http.request(options, (res) => {
            resolve(true);
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        req.on('timeout', () => {
            req.destroy();
            reject(new Error('Connection timeout'));
        });
        
        req.end();
    });
}

async function convertCqlToElm(cqlContent, fileName) {
    return new Promise((resolve, reject) => {
        const postData = cqlContent;
        
        const options = {
            hostname: LOCAL_SERVICE,
            port: LOCAL_PORT,
            path: '/cql/translator?annotations=true&locators=true&result-types=true&disable-list-demotion=true&disable-list-promotion=true',
            method: 'POST',
            headers: {
                'Content-Type': 'application/cql',
                'Accept': 'application/elm+json',
                'Content-Length': Buffer.byteLength(postData)
            },
            timeout: 30000
        };
        
        const req = http.request(options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                if (res.statusCode === 200) {
                    try {
                        const elm = JSON.parse(data);
                        resolve(elm);
                    } catch (e) {
                        reject(new Error(`JSON parse error: ${e.message}`));
                    }
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        req.on('timeout', () => {
            req.destroy();
            reject(new Error('Request timeout'));
        });
        
        req.write(postData);
        req.end();
    });
}

async function batchConvert(cqlFolder, outputFolder) {
    console.log('\n=== CQL批量轉換 (本地服務) ===\n');
    
    // 測試本地服務
    console.log('檢查本地CQL翻譯服務...');
    try {
        await testLocalService();
        console.log(`✅ 本地服務運行中: http://${LOCAL_SERVICE}:${LOCAL_PORT}\n`);
    } catch (error) {
        console.log(`❌ 無法連接到本地服務: ${error.message}\n`);
        console.log('請確認CQL翻譯服務已啟動:');
        console.log('  java -jar cqlTranslationServer-2.7.1.jar\n');
        console.log('或使用Docker:');
        console.log('  docker run -d -p 8080:8080 cqframework/cql-translation-service:latest\n');
        process.exit(1);
    }
    
    // 確保輸出目錄存在
    if (!fs.existsSync(outputFolder)) {
        fs.mkdirSync(outputFolder, { recursive: true });
    }
    
    // 讀取FHIRHelpers（如果存在）
    const fhirHelpersPath = path.join(__dirname, 'CQL 2026', 'FHIRHelpers', 'FHIRHelpers-4.0.1.cql');
    let fhirHelpersContent = '';
    if (fs.existsSync(fhirHelpersPath)) {
        fhirHelpersContent = fs.readFileSync(fhirHelpersPath, 'utf8');
        console.log('✅ FHIRHelpers已載入\n');
    }
    
    // 獲取所有CQL文件
    const cqlFiles = fs.readdirSync(cqlFolder)
        .filter(f => f.endsWith('.cql'))
        .map(f => path.join(cqlFolder, f));
    
    if (cqlFiles.length === 0) {
        console.log(`❌ 在 ${cqlFolder} 中沒有找到CQL文件`);
        return;
    }
    
    console.log(`找到 ${cqlFiles.length} 個CQL文件\n`);
    console.log('='.repeat(70));
    
    let successCount = 0;
    let failCount = 0;
    const failed = [];
    
    // 逐個轉換
    for (let i = 0; i < cqlFiles.length; i++) {
        const cqlFile = cqlFiles[i];
        const fileName = path.basename(cqlFile);
        const baseName = fileName.replace('.cql', '');
        
        process.stdout.write(`[${i + 1}/${cqlFiles.length}] ${fileName} ... `);
        
        try {
            // 讀取CQL內容
            const cqlContent = fs.readFileSync(cqlFile, 'utf8');
            
            // 轉換
            const elm = await convertCqlToElm(cqlContent, fileName);
            
            // 保存
            const outputFile = path.join(outputFolder, `${baseName}.json`);
            fs.writeFileSync(outputFile, JSON.stringify(elm, null, 2), 'utf8');
            
            const size = (fs.statSync(outputFile).size / 1024).toFixed(2);
            console.log(`✅ ${size} KB`);
            successCount++;
            
        } catch (error) {
            console.log(`❌ ${error.message}`);
            failCount++;
            failed.push({ file: fileName, error: error.message });
        }
        
        // 小延遲避免過載
        if (i < cqlFiles.length - 1) {
            await new Promise(resolve => setTimeout(resolve, 100));
        }
    }
    
    // 結果報告
    console.log('\n' + '='.repeat(70));
    console.log('\n轉換結果:');
    console.log(`  ✅ 成功: ${successCount}/${cqlFiles.length}`);
    console.log(`  ❌ 失敗: ${failCount}/${cqlFiles.length}`);
    
    if (failed.length > 0) {
        console.log('\n失敗文件:');
        failed.forEach(f => console.log(`  - ${f.file}: ${f.error}`));
    }
    
    console.log(`\n輸出目錄: ${outputFolder}`);
}

// 命令行參數
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('用法:');
        console.log('  node batch_convert_local.js <CQL資料夾> <輸出資料夾>');
        console.log('\n例如:');
        console.log('  node batch_convert_local.js "cql" "ELM_JSON_OFFICIAL/output"');
        console.log('\n注意:');
        console.log('  需要先啟動本地CQL翻譯服務:');
        console.log('  java -jar cqlTranslationServer-2.7.1.jar');
        process.exit(0);
    }
    
    const cqlFolder = args[0];
    const outputFolder = args[1] || 'ELM_JSON_OFFICIAL/local_output';
    
    if (!fs.existsSync(cqlFolder)) {
        console.log(`❌ CQL資料夾不存在: ${cqlFolder}`);
        process.exit(1);
    }
    
    batchConvert(cqlFolder, outputFolder)
        .then(() => console.log('\n✅ 批量轉換完成\n'))
        .catch(err => {
            console.error('\n❌ 錯誤:', err.message);
            process.exit(1);
        });
}

module.exports = { batchConvert, convertCqlToElm, testLocalService };
