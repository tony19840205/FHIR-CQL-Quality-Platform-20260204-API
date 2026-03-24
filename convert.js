const fs = require('fs');
const path = require('path');
const https = require('https');

const sourceDir = './CQL 2026';
const outputDir = './ELM_JSON';

// 递归获取所有CQL文件
function getAllCqlFiles(dir, fileList = []) {
    const files = fs.readdirSync(dir);
    files.forEach(file => {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) {
            getAllCqlFiles(filePath, fileList);
        } else if (file.endsWith('.cql')) {
            fileList.push(filePath);
        }
    });
    return fileList;
}

// 转换单个CQL文件 - 使用在线服务
async function convertFile(cqlPath) {
    return new Promise((resolve) => {
        try {
            const cqlContent = fs.readFileSync(cqlPath, 'utf8');
            const relativePath = path.relative(sourceDir, cqlPath);
            
            // 准备请求数据
            const postData = JSON.stringify({ cql: cqlContent });
            
            const options = {
                hostname: 'cqlrepository.org',
                port: 443,
                path: '/cql/translator',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData),
                    'Accept': 'application/elm+json'
                },
                timeout: 30000
            };
            
            const req = https.request(options, (res) => {
                let data = '';
                
                res.on('data', (chunk) => {
                    data += chunk;
                });
                
                res.on('end', () => {
                    try {
                        const elmJson = JSON.parse(data);
                        
                        // 创建输出路径
                        const outputPath = path.join(outputDir, relativePath.replace('.cql', '.json'));
                        const outputDirPath = path.dirname(outputPath);
                        
                        // 确保输出目录存在
                        if (!fs.existsSync(outputDirPath)) {
                            fs.mkdirSync(outputDirPath, { recursive: true });
                        }
                        
                        // 保存ELM JSON
                        fs.writeFileSync(outputPath, JSON.stringify(elmJson, null, 2), 'utf8');
                        
                        resolve({ success: true, file: relativePath });
                    } catch (parseError) {
                        resolve({ success: false, file: relativePath, error: 'JSON解析失败: ' + parseError.message });
                    }
                });
            });
            
            req.on('error', (error) => {
                resolve({ success: false, file: relativePath, error: '网络错误: ' + error.message });
            });
            
            req.on('timeout', () => {
                req.destroy();
                resolve({ success: false, file: relativePath, error: '请求超时' });
            });
            
            req.write(postData);
            req.end();
            
        } catch (error) {
            resolve({ success: false, file: path.relative(sourceDir, cqlPath), error: error.message });
        }
    });
}

// 批量转换
async function batchConvert() {
    console.log('\n🚀 开始批量转换 CQL → ELM JSON (使用官方cql-translation库)\n');
    console.log('━'.repeat(70));
    
    const cqlFiles = getAllCqlFiles(sourceDir);
    const total = cqlFiles.length;
    console.log(`\n📊 找到 ${total} 个 CQL 文件\n`);
    
    let success = 0, failed = 0;
    const errors = [];
    
    for (let i = 0; i < total; i++) {
        const file = cqlFiles[i];
        const num = i + 1;
        const percent = ((num / total) * 100).toFixed(1);
        const relativePath = path.relative(sourceDir, file);
        
        process.stdout.write(`[${num}/${total}] ${percent}% - ${relativePath}`);
        
        const result = await convertFile(file);
        
        if (result.success) {
            console.log(' ✅');
            success++;
        } else {
            console.log(` ❌ ${result.error}`);
            failed++;
            errors.push({ file: result.file, error: result.error });
        }
        
        if (num % 10 === 0) {
            console.log(`\n--- 进度: 成功 ${success}, 失败 ${failed} ---\n`);
        }
    }
    
    console.log('\n' + '━'.repeat(70));
    console.log('\n📈 转换统计:');
    console.log(`   总计: ${total} 个文件`);
    console.log(`   ✅ 成功: ${success} 个`);
    console.log(`   ❌ 失败: ${failed} 个`);
    
    if (errors.length > 0) {
        console.log('\n❌ 失败文件列表:');
        errors.forEach((err, idx) => {
            console.log(`   ${idx + 1}. ${err.file}`);
            console.log(`      错误: ${err.error}`);
        });
    }
    
    console.log('\n✨ 批量转换完成！');
    console.log(`📁 输出目录: ${path.resolve(outputDir)}\n`);
}

// 执行转换
batchConvert().catch(error => {
    console.error('\n❌ 转换失败:', error);
    process.exit(1);
});
