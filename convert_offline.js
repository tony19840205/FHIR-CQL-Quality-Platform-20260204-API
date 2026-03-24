const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * 完全離線轉換方案 - 使用本地Java編譯器
 * 不依賴任何網路API
 */

console.log('\n=== CQL離線轉換工具 ===\n');

// 檢查Java
try {
    const javaVersion = execSync('java -version 2>&1').toString();
    console.log('✅ Java:', javaVersion.split('\n')[0]);
} catch (e) {
    console.log('❌ 未安裝Java');
    process.exit(1);
}

// 使用現有的cql-to-elm.jar
const jarFile = 'cql-to-elm.jar';
if (!fs.existsSync(jarFile)) {
    console.log(`❌ 找不到 ${jarFile}`);
    console.log('\n備用方案：使用線上工具手動轉換');
    console.log('https://cql.dataphoria.org/');
    process.exit(1);
}

console.log(`✅ 轉換器: ${jarFile}\n`);

const args = process.argv.slice(2);
if (args.length < 2) {
    console.log('用法: node convert_offline.js <CQL資料夾> <輸出資料夾>');
    process.exit(1);
}

const cqlFolder = args[0];
const outputFolder = args[1];

if (!fs.existsSync(cqlFolder)) {
    console.log(`❌ CQL資料夾不存在: ${cqlFolder}`);
    process.exit(1);
}

if (!fs.existsSync(outputFolder)) {
    fs.mkdirSync(outputFolder, { recursive: true });
}

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
    const baseName = fileName.replace('.cql', '');
    const outputFile = path.join(outputFolder, `${baseName}.json`);
    
    process.stdout.write(`[${i + 1}/${cqlFiles.length}] ${fileName} ... `);
    
    try {
        // 嘗試使用Java JAR轉換
        // 注意：cql-to-elm.jar可能有問題，這是嘗試性的
        const cmd = `java -jar ${jarFile} ${cqlFile} --format JSON --output ${outputFile}`;
        execSync(cmd, { stdio: 'pipe' });
        
        if (fs.existsSync(outputFile)) {
            const size = (fs.statSync(outputFile).size / 1024).toFixed(2);
            console.log(`✅ ${size} KB`);
            successCount++;
        } else {
            console.log(`❌ 無輸出文件`);
            failCount++;
        }
    } catch (error) {
        // JAR文件可能損壞，記錄並繼續
        console.log(`❌ ${error.message.split('\n')[0]}`);
        failCount++;
    }
}

console.log('\n' + '='.repeat(70));
console.log(`\n✅ 成功: ${successCount}/${cqlFiles.length}`);
console.log(`❌ 失敗: ${failCount}/${cqlFiles.length}`);

if (failCount === cqlFiles.length) {
    console.log('\n⚠️  所有文件轉換失敗');
    console.log('\n可能原因: JAR文件損壞（缺少主要資訊清單屬性）');
    console.log('\n建議替代方案:');
    console.log('1. 使用線上工具: https://cql.dataphoria.org/');
    console.log('2. 下載正確的JAR: https://github.com/cqframework/clinical_quality_language/releases');
    console.log('3. 等待網路DNS問題解決後使用batch_convert_reliable.js');
}
