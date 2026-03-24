const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * 使用Java本地轉換CQL為ELM
 * 需要: fhir-ig-publisher.jar (已存在)
 */

function convertUsingIGPublisher(cqlFile, outputDir) {
    const fileName = path.basename(cqlFile);
    const tempDir = 'temp_ig_' + Date.now();
    
    try {
        // 1. 創建臨時IG結構
        fs.mkdirSync(path.join(tempDir, 'input', 'cql'), { recursive: true });
        
        // 2. 複製CQL文件
        fs.copyFileSync(cqlFile, path.join(tempDir, 'input', 'cql', fileName));
        
        // 3. 複製FHIRHelpers
        const fhirHelpers = path.join(__dirname, 'CQL 2026', 'FHIRHelpers', 'FHIRHelpers-4.0.1.cql');
        if (fs.existsSync(fhirHelpers)) {
            fs.copyFileSync(fhirHelpers, path.join(tempDir, 'input', 'cql', 'FHIRHelpers-4.0.1.cql'));
        }
        
        // 4. 創建ig.ini
        fs.writeFileSync(path.join(tempDir, 'ig.ini'), `[IG]\nig = fhir.example.cql\ntemplate = fhir.base.template\n`);
        
        // 5. 創建sushi-config.yaml
        const config = `id: fhir.example.cql
canonical: http://example.org/fhir/cql
name: CQLConversion
title: CQL to ELM Conversion
status: draft
version: 1.0.0
fhirVersion: 4.0.1
copyrightYear: 2026
releaseLabel: ci-build
publisher:
  name: Example Publisher
`;
        fs.writeFileSync(path.join(tempDir, 'sushi-config.yaml'), config);
        
        // 6. 運行IG Publisher
        const igPublisher = path.join(__dirname, 'fhir-ig-publisher.jar');
        execSync(`java -jar "${igPublisher}" -ig "${path.join(tempDir, 'ig.ini')}"`, {
            cwd: tempDir,
            stdio: 'pipe'
        });
        
        // 7. 查找生成的ELM JSON
        const outputPattern = path.join(tempDir, 'output', '**', '*.json');
        const elmFiles = findElmFiles(path.join(tempDir, 'output'));
        
        if (elmFiles.length > 0) {
            // 確保輸出目錄存在
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }
            
            // 複製到輸出目錄
            const baseName = fileName.replace('.cql', '.json');
            const outputPath = path.join(outputDir, baseName);
            fs.copyFileSync(elmFiles[0], outputPath);
            
            // 清理臨時目錄
            fs.rmSync(tempDir, { recursive: true, force: true });
            
            return { success: true, output: outputPath };
        } else {
            throw new Error('未找到ELM JSON輸出');
        }
        
    } catch (error) {
        // 清理臨時目錄
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
        return { success: false, error: error.message };
    }
}

function findElmFiles(dir) {
    const results = [];
    
    function search(currentDir) {
        const items = fs.readdirSync(currentDir);
        for (const item of items) {
            const fullPath = path.join(currentDir, item);
            const stat = fs.statSync(fullPath);
            
            if (stat.isDirectory()) {
                search(fullPath);
            } else if (item.endsWith('.json')) {
                // 檢查是否為ELM JSON
                try {
                    const content = fs.readFileSync(fullPath, 'utf8');
                    const json = JSON.parse(content);
                    if (json.library && json.library.identifier) {
                        results.push(fullPath);
                    }
                } catch (e) {
                    // 忽略解析錯誤
                }
            }
        }
    }
    
    search(dir);
    return results;
}

async function batchConvertWithIGPublisher(cqlFolder, outputFolder) {
    console.log('\n=== 使用IG Publisher批量轉換 ===\n');
    
    // 檢查IG Publisher
    const igPublisher = path.join(__dirname, 'fhir-ig-publisher.jar');
    if (!fs.existsSync(igPublisher)) {
        console.log('❌ 找不到fhir-ig-publisher.jar');
        return;
    }
    
    console.log('✅ IG Publisher: fhir-ig-publisher.jar\n');
    
    // 獲取所有CQL文件
    const cqlFiles = fs.readdirSync(cqlFolder)
        .filter(f => f.endsWith('.cql'))
        .map(f => path.join(cqlFolder, f));
    
    console.log(`找到 ${cqlFiles.length} 個CQL文件\n`);
    console.log('='.repeat(70));
    
    let successCount = 0;
    let failCount = 0;
    
    for (let i = 0; i < cqlFiles.length; i++) {
        const cqlFile = cqlFiles[i];
        const fileName = path.basename(cqlFile);
        
        process.stdout.write(`[${i + 1}/${cqlFiles.length}] ${fileName} ... `);
        
        const result = convertUsingIGPublisher(cqlFile, outputFolder);
        
        if (result.success) {
            const size = (fs.statSync(result.output).size / 1024).toFixed(2);
            console.log(`✅ ${size} KB`);
            successCount++;
        } else {
            console.log(`❌ ${result.error}`);
            failCount++;
        }
    }
    
    console.log('\n' + '='.repeat(70));
    console.log(`\n✅ 成功: ${successCount}/${cqlFiles.length}`);
    console.log(`❌ 失敗: ${failCount}/${cqlFiles.length}`);
}

module.exports = { convertUsingIGPublisher, batchConvertWithIGPublisher };

// 如果直接運行
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log('用法: node batch_convert_ig.js <CQL資料夾> <輸出資料夾>');
        process.exit(1);
    }
    
    batchConvertWithIGPublisher(args[0], args[1]);
}
