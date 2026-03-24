/**
 * 使用Docker cqframework/cql-translation-service轉換CQL到官方ELM
 * 這是與中醫ELM相同的官方轉換方法
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const cqlFile = 'cql/Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql';
const outputDir = 'ELM_JSON_OFFICIAL/舊50';
const outputFile = 'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.json';

console.log('='.repeat(70));
console.log(' 官方CQL-to-ELM轉換 (Docker cqframework)');
console.log(' Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710');
console.log('='.repeat(70));

console.log(`\n輸入: ${cqlFile}`);
console.log(`輸出: ${path.join(outputDir, outputFile)}`);

// 確保輸出目錄存在
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(`✓ 創建輸出目錄: ${outputDir}`);
}

// 讀取CQL檔案大小
const cqlStats = fs.statSync(cqlFile);
console.log(`✓ CQL文件大小: ${(cqlStats.size / 1024).toFixed(2)} KB`);

// Docker命令 - 使用官方cqframework image
const workDir = __dirname.replace(/\\/g, '/');
const dockerCmd = `docker run --rm ` +
    `-v "${workDir}/cql:/cql" ` +
    `-v "${workDir}/${outputDir}:/output" ` +
    `cqframework/cql-translation-service:latest ` +
    `cql-to-elm ` +
    `--format=json ` +
    `--input=/cql/Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql ` +
    `--output=/output/${outputFile}`;

console.log('\n執行Docker命令...');
console.log('Docker Image: cqframework/cql-translation-service:latest');
console.log('格式: JSON');

exec(dockerCmd, { timeout: 60000 }, (error, stdout, stderr) => {
    if (error) {
        console.error('\n✗ 轉換失敗:', error.message);
        console.log('\nDocker輸出:');
        if (stdout) console.log(stdout);
        if (stderr) console.log(stderr);
        
        console.log('\n可能的解決方案:');
        console.log('1. 拉取Docker image: docker pull cqframework/cql-translation-service:latest');
        console.log('2. 檢查Docker是否運行中');
        console.log('3. 檢查CQL文件是否存在和有效');
        return;
    }
    
    // 輸出Docker日誌
    if (stdout) {
        console.log('\nDocker輸出:');
        console.log(stdout);
    }
    if (stderr && stderr.trim()) {
        console.log('\nDocker警告:');
        console.log(stderr);
    }
    
    // 檢查輸出文件
    const fullOutputPath = path.join(outputDir, outputFile);
    if (fs.existsSync(fullOutputPath)) {
        const stats = fs.statSync(fullOutputPath);
        const sizeKB = (stats.size / 1024).toFixed(2);
        const content = fs.readFileSync(fullOutputPath, 'utf-8');
        const lineCount = content.split('\n').length;
        
        console.log('\n✓✓✓ 轉換成功！✓✓✓');
        console.log(`\n輸出文件: ${fullOutputPath}`);
        console.log(`大小: ${sizeKB} KB`);
        console.log(`行數: ${lineCount} 行`);
        
        // 驗證ELM結構
        try {
            const elm = JSON.parse(content);
            if (elm.library) {
                console.log(`\n庫名: ${elm.library.identifier.id}`);
                console.log(`版本: ${elm.library.identifier.version}`);
                
                if (elm.library.annotation && elm.library.annotation[0]) {
                    const anno = elm.library.annotation[0];
                    console.log(`\nTranslator版本: ${anno.translatorVersion}`);
                    console.log(`選項: ${anno.translatorOptions}`);
                    console.log(`簽名級別: ${anno.signatureLevel}`);
                }
                
                if (elm.library.statements) {
                    console.log(`語句定義: ${elm.library.statements.def.length} 個`);
                }
                
                if (elm.library.codeSystems) {
                    console.log(`代碼系統: ${elm.library.codeSystems.def.length} 個`);
                }
                
                if (elm.library.codes) {
                    console.log(`代碼定義: ${elm.library.codes.def.length} 個`);
                }
            }
            
            // 與參考文件比較
            console.log('\n質量比較:');
            console.log('  參考: Indicator_01 (60.52 KB, 1435行)');
            console.log(`  本次: Indicator_03_1 (${sizeKB} KB, ${lineCount}行)`);
            
            if (parseFloat(sizeKB) >= 50) {
                console.log('\n✓ 文件大小符合預期（與參考文件相當）');
            } else if (parseFloat(sizeKB) >= 30) {
                console.log('\n⚠ 文件大小偏小，但可能正常（取決於CQL複雜度）');
            } else {
                console.log('\n⚠ 警告: 文件大小可能過小，請檢查');
            }
            
        } catch (e) {
            console.log('\n⚠ 無法解析ELM JSON:', e.message);
        }
        
    } else {
        console.log('\n✗ 輸出文件未創建');
        console.log(`預期位置: ${fullOutputPath}`);
    }
});

console.log('\n正在執行轉換...(最多60秒)');
