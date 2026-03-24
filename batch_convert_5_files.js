const fs = require('fs');
const path = require('path');
const https = require('https');

const filesToConvert = [
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql',
    'Waste.cql'
];

const tempDir = path.join(__dirname, 'cql_batch_temp');
const outputDir = path.join(__dirname, 'ELM_JSON_OFFICIAL', '舊50');

// 創建目錄
if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });
if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

const results = { success: [], failed: [] };

// AHRQ CQL Translation Service API
function callCqlTranslationService(cqlContent) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify({
            code: cqlContent,
            options: {
                format: 'JSON',
                annotations: true,
                locators: true,
                'disable-list-demotion': true,
                'disable-list-promotion': true,
                'disable-list-traversal': true,
                'enable-date-range-optimization': false,
                signatures: 'Overloads'
            }
        });

        const options = {
            hostname: 'cql-translation-service.ahrq.gov',
            port: 443,
            path: '/cql/translator',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(new Error(`解析回應失敗: ${e.message}`));
                }
            });
        });

        req.on('error', (e) => reject(e));
        req.write(postData);
        req.end();
    });
}

async function convertFile(fileName) {
    console.log(`\n處理: ${fileName}`);
    
    const sourcePath = path.join(__dirname, 'cql', fileName);
    const baseName = path.basename(fileName, '.cql');
    const tempPath = path.join(tempDir, fileName);
    const outputPath = path.join(outputDir, `${baseName}.json`);
    
    try {
        // 讀取CQL文件
        let content = fs.readFileSync(sourcePath, 'utf8');
        
        // 移除SQL代碼（從WITH或SELECT開始到最後）
        if (content.includes('WITH quarters AS') || content.includes('SELECT ')) {
            // 找到SQL開始的位置
            const sqlStart = content.search(/(?:^|\n)(?:--\s*)?WITH\s+quarters\s+AS/m);
            if (sqlStart !== -1) {
                content = content.substring(0, sqlStart) + '\n// SQL邏輯已移除，請使用FHIR查詢\n';
                console.log('  ✓ 已移除SQL代碼');
            }
        }
        
        // 保存修復後的CQL
        fs.writeFileSync(tempPath, content, 'utf8');
        
        // 轉換為ELM JSON
        const result = await callCqlTranslationService(content);
        
        if (result && result.library) {
            // 保存JSON
            fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), 'utf8');
            const size = fs.statSync(outputPath).size;
            console.log(`  ✓ 轉換成功: ${(size / 1024).toFixed(2)} KB`);
            results.success.push(fileName);
        } else if (result && result.errors && result.errors.length > 0) {
            console.log(`  ✗ 轉換失敗: ${result.errors[0].message}`);
            results.failed.push({ file: fileName, error: result.errors[0].message });
        } else {
            console.log('  ✗ 轉換失敗: 未知錯誤');
            results.failed.push({ file: fileName, error: '未知錯誤' });
        }
        
    } catch (error) {
        console.log(`  ✗ 錯誤: ${error.message}`);
        results.failed.push({ file: fileName, error: error.message });
    }
}

async function main() {
    console.log('\n=== 批量轉換CQL到官方ELM JSON ===');
    
    for (const file of filesToConvert) {
        await convertFile(file);
    }
    
    // 清理臨時目錄
    if (fs.existsSync(tempDir)) {
        fs.rmSync(tempDir, { recursive: true, force: true });
    }
    
    // 顯示結果
    console.log('\n=== 轉換結果 ===');
    console.log(`成功: ${results.success.length}`);
    console.log(`失敗: ${results.failed.length}`);
    
    if (results.failed.length > 0) {
        console.log('\n失敗的文件:');
        results.failed.forEach(f => {
            console.log(`  - ${f.file}: ${f.error}`);
        });
    }
    
    if (results.success.length > 0) {
        console.log('\n成功轉換的文件:');
        results.success.forEach(f => console.log(`  ✓ ${f}`));
    }
}

main().catch(console.error);
