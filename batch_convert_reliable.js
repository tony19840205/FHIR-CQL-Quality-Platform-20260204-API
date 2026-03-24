const fs = require('fs');
const path = require('path');
const { Client } = require('cql-translation-service-client');

// 使用多個備用服務器
const TRANSLATION_SERVICES = [
    'https://cql-translation-service.ahrq.gov/cql/translator',
    'https://cql.dataphoria.org/cql/translator',
    'http://localhost:8080/cql/translator'  // 本地服務（如果有）
];

async function testConnection(url) {
    try {
        const client = new Client(url);
        // 簡單測試
        const testCql = {
            'test.cql': { 
                cql: 'library test version "1.0.0"\nusing FHIR version "4.0.1"' 
            }
        };
        await client.convertCQL(testCql);
        return true;
    } catch (error) {
        return false;
    }
}

async function findWorkingService() {
    console.log('正在測試CQL轉換服務連線...\n');
    
    for (const url of TRANSLATION_SERVICES) {
        process.stdout.write(`測試: ${url} ... `);
        const works = await testConnection(url);
        if (works) {
            console.log('✅ 可用');
            return url;
        } else {
            console.log('❌ 不可用');
        }
    }
    
    return null;
}

async function convertSingleFile(client, cqlFilePath, outputDir, fhirHelpersContent = '') {
    const fileName = path.basename(cqlFilePath);
    const outputPath = path.join(outputDir, fileName.replace('.cql', '.json'));
    
    try {
        // 讀取CQL內容
        const cqlContent = fs.readFileSync(cqlFilePath, 'utf8');
        
        // 準備libraries
        const cqlLibraries = {
            [fileName]: { cql: cqlContent }
        };
        
        // 加入FHIRHelpers
        if (fhirHelpersContent) {
            cqlLibraries['FHIRHelpers-4.0.1.cql'] = { cql: fhirHelpersContent };
        }
        
        // 轉換
        const result = await client.convertCQL(cqlLibraries);
        
        // 檢查錯誤
        if (result.isAxiosError || result.error) {
            throw new Error(result.message || result.code || 'Network error');
        }
        
        // 提取ELM
        const libraryName = fileName.replace('.cql', '');
        const elm = result[libraryName] || result[fileName] || result;
        
        if (!elm || typeof elm !== 'object') {
            throw new Error('Invalid ELM output');
        }
        
        // 保存
        fs.writeFileSync(outputPath, JSON.stringify(elm, null, 2), 'utf8');
        const size = (fs.statSync(outputPath).size / 1024).toFixed(2);
        
        return { success: true, size, error: null };
        
    } catch (error) {
        return { success: false, size: 0, error: error.message };
    }
}

async function batchConvert(cqlFolder, outputFolder, pattern = '*.cql') {
    console.log('\n=== CQL批量轉換為官方ELM JSON ===\n');
    
    // 測試連線
    const serviceUrl = await findWorkingService();
    
    if (!serviceUrl) {
        console.log('\n❌ 所有轉換服務都不可用');
        console.log('\n備用方案：');
        console.log('1. 下載獨立轉換工具：https://github.com/cqframework/clinical_quality_language/releases');
        console.log('2. 使用線上工具：https://cql.dataphoria.org/');
        return;
    }
    
    console.log(`\n使用服務: ${serviceUrl}\n`);
    const client = new Client(serviceUrl);
    
    // 創建輸出目錄
    if (!fs.existsSync(outputFolder)) {
        fs.mkdirSync(outputFolder, { recursive: true });
    }
    
    // 讀取FHIRHelpers
    let fhirHelpersContent = '';
    const fhirHelpersPath = path.join(__dirname, 'CQL 2026', 'FHIRHelpers', 'FHIRHelpers-4.0.1.cql');
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
        
        process.stdout.write(`[${i + 1}/${cqlFiles.length}] ${fileName} ... `);
        
        const result = await convertSingleFile(client, cqlFile, outputFolder, fhirHelpersContent);
        
        if (result.success) {
            console.log(`✅ ${result.size} KB`);
            successCount++;
        } else {
            console.log(`❌ ${result.error}`);
            failCount++;
            failed.push({ file: fileName, error: result.error });
        }
        
        // 延遲避免請求過快
        if (i < cqlFiles.length - 1) {
            await new Promise(resolve => setTimeout(resolve, 500));
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
}

// 如果直接運行此腳本
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('用法:');
        console.log('  node batch_convert_reliable.js <CQL資料夾> <輸出資料夾>');
        console.log('\n例如:');
        console.log('  node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL/舊50"');
        console.log('  node batch_convert_reliable.js "CQL 2026/中醫" "ELM_JSON_OFFICIAL/中醫"');
        process.exit(0);
    }
    
    const cqlFolder = args[0];
    const outputFolder = args[1] || 'ELM_JSON_OFFICIAL/output';
    
    if (!fs.existsSync(cqlFolder)) {
        console.log(`❌ CQL資料夾不存在: ${cqlFolder}`);
        process.exit(1);
    }
    
    batchConvert(cqlFolder, outputFolder)
        .then(() => console.log('\n✅ 轉換完成'))
        .catch(err => {
            console.error('\n❌ 錯誤:', err.message);
            process.exit(1);
        });
}

module.exports = { batchConvert, convertSingleFile, findWorkingService };
