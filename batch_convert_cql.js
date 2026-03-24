const fs = require('fs');
const path = require('path');
const https = require('https');

// ========================================
// CQL 批量转换为 ELM JSON (Node.js版本)
// ========================================

const CONFIG = {
    sourceDir: './CQL 2026',
    outputDir: './ELM_JSON',
    translationApi: 'https://cql.dataphoria.org/translate',
    concurrency: 5  // 并发数量
};

// 递归获取所有CQL文件
function getAllCqlFiles(dir, fileList = []) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory()) {
            getAllCqlFiles(filePath, fileList);
        } else if (file.endsWith('.cql')) {
            fileList.push(filePath);
        }
    });
    
    return fileList;
}

// 调用翻译API
function translateCql(cqlContent) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify({ cql: cqlContent });
        
        const options = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData),
                'Accept': 'application/elm+json'
            }
        };
        
        const req = https.request(CONFIG.translationApi, options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                try {
                    const elm = JSON.parse(data);
                    resolve(elm);
                } catch (error) {
                    reject(new Error('解析响应失败: ' + error.message));
                }
            });
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        req.write(postData);
        req.end();
    });
}

// 转换单个文件
async function convertFile(cqlFile) {
    try {
        const cqlContent = fs.readFileSync(cqlFile, 'utf8');
        const elm = await translateCql(cqlContent);
        
        const relativePath = path.relative(CONFIG.sourceDir, cqlFile);
        const outputPath = path.join(CONFIG.outputDir, relativePath.replace('.cql', '.json'));
        
        // 创建输出目录
        fs.mkdirSync(path.dirname(outputPath), { recursive: true });
        
        // 保存ELM JSON
        fs.writeFileSync(outputPath, JSON.stringify(elm, null, 2), 'utf8');
        
        return { success: true, file: relativePath };
    } catch (error) {
        return { success: false, file: path.relative(CONFIG.sourceDir, cqlFile), error: error.message };
    }
}

// 批量转换 (带并发控制)
async function batchConvert() {
    console.log('\n🚀 开始批量转换 CQL → ELM JSON\n');
    console.log('━'.repeat(60));
    
    const cqlFiles = getAllCqlFiles(CONFIG.sourceDir);
    console.log(`📊 找到 ${cqlFiles.length} 个 CQL 文件\n`);
    
    const results = { success: 0, failed: 0, errors: [] };
    
    // 分批处理
    for (let i = 0; i < cqlFiles.length; i += CONFIG.concurrency) {
        const batch = cqlFiles.slice(i, i + CONFIG.concurrency);
        const batchResults = await Promise.all(batch.map(convertFile));
        
        batchResults.forEach((result, index) => {
            const fileNum = i + index + 1;
            if (result.success) {
                console.log(`✅ [${fileNum}/${cqlFiles.length}] ${result.file}`);
                results.success++;
            } else {
                console.log(`❌ [${fileNum}/${cqlFiles.length}] ${result.file}`);
                console.log(`   错误: ${result.error}`);
                results.failed++;
                results.errors.push({ file: result.file, error: result.error });
            }
        });
        
        // 进度提示
        if (i + CONFIG.concurrency < cqlFiles.length) {
            const progress = ((i + CONFIG.concurrency) / cqlFiles.length * 100).toFixed(1);
            console.log(`\n⏳ 进度: ${progress}%\n`);
        }
    }
    
    console.log('\n' + '━'.repeat(60));
    console.log('\n📈 转换统计:');
    console.log(`   总计: ${cqlFiles.length} 个文件`);
    console.log(`   ✅ 成功: ${results.success} 个`);
    console.log(`   ❌ 失败: ${results.failed} 个`);
    
    if (results.errors.length > 0) {
        console.log('\n❌ 失败文件列表:');
        results.errors.forEach((err, idx) => {
            console.log(`   ${idx + 1}. ${err.file}`);
            console.log(`      ${err.error}`);
        });
    }
    
    console.log('\n✨ 批量转换完成！');
    console.log(`📁 输出目录: ${CONFIG.outputDir}\n`);
}

// 执行转换
batchConvert().catch(error => {
    console.error('批量转换失败:', error);
    process.exit(1);
});
