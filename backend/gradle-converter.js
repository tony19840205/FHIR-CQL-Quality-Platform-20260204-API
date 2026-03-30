// gradle-converter.js - 使用 Gradle 8.11 + CQL-to-ELM 3.10.0 官方轉換 CQL → ELM JSON

const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

// 專案路徑設定
const PROJECT_ROOT = path.join(__dirname, '..');
const GRADLE_BIN = path.join(PROJECT_ROOT, 'gradle-8.11', 'bin', 'gradle.bat');
const CQL_DIR = path.join(PROJECT_ROOT, 'cql');
const ELM_OUTPUT_DIR = path.join(__dirname, 'elm');

/**
 * 使用 Gradle 轉換 CQL 為 ELM JSON
 * @param {Object} options - 轉換選項
 * @param {string} [options.inputDir] - CQL 輸入目錄 (預設: ./cql)
 * @param {string} [options.outputDir] - ELM 輸出目錄 (預設: ./backend/elm)
 * @param {function} [options.onProgress] - 進度回報函式
 * @returns {Promise<Object>} 轉換結果
 */
async function convertCQLWithGradle(options = {}) {
    const inputDir = options.inputDir || CQL_DIR;
    const outputDir = options.outputDir || ELM_OUTPUT_DIR;
    const onProgress = options.onProgress || (() => {});

    return new Promise(async (resolve, reject) => {
        try {
            // 檢查 Gradle 是否存在
            const gradleExists = await fs.access(GRADLE_BIN).then(() => true).catch(() => false);
            if (!gradleExists) {
                throw new Error(`Gradle 未找到: ${GRADLE_BIN}`);
            }

            onProgress('🔧 準備 Gradle 8.11 環境...');
            
            // 確保輸出目錄存在
            await fs.mkdir(outputDir, { recursive: true });
            
            // 記錄轉換前的 ELM 檔案
            const beforeFiles = await fs.readdir(outputDir).catch(() => []);
            
            onProgress(`🚀 開始 Gradle CQL→ELM 轉換...`);
            onProgress(`   輸入: ${inputDir}`);
            onProgress(`   輸出: ${outputDir}`);

            // 使用 PowerShell 執行 Gradle
            const gradleCommand = `$env:JAVA_HOME=''; Set-Location '${PROJECT_ROOT}'; & '.\\gradle-8.11\\bin\\gradle.bat' cql2elm -PcqlInput='${inputDir}' -PcqlOutput='${outputDir}' --no-daemon`;
            
            const gradleProcess = spawn('powershell.exe', ['-NoProfile', '-Command', gradleCommand], {
                windowsHide: false
            });

            let outputLog = '';
            let errorLog = '';

            gradleProcess.stdout.on('data', (data) => {
                const output = data.toString();
                outputLog += output;
                
                const lines = output.split('\n');
                lines.forEach(line => {
                    if (line.includes('Task :cql2elm')) {
                        onProgress('⚡ 執行 cql2elm 任務...');
                    } else if (line.includes('CQL-to-ELM')) {
                        onProgress(`🔧 ${line.trim()}`);
                    } else if (line.includes('BUILD SUCCESSFUL')) {
                        onProgress('✅ Gradle 轉換完成！');
                    } else if (line.trim() && !line.includes('Daemon')) {
                        onProgress(line.trim());
                    }
                });
            });

            gradleProcess.stderr.on('data', (data) => {
                const error = data.toString();
                errorLog += error;
                if (!error.includes('Daemon') && error.trim()) {
                    onProgress(`⚠️ ${error.trim()}`);
                }
            });

            gradleProcess.on('close', async (code) => {
                if (code === 0) {
                    try {
                        // 計算新增的 ELM 檔案
                        const afterFiles = await fs.readdir(outputDir).catch(() => []);
                        const newFiles = afterFiles.filter(f => f.endsWith('.json') && !beforeFiles.includes(f));
                        
                        onProgress(`📚 轉換完成！共 ${afterFiles.filter(f => f.endsWith('.json')).length} 個 ELM JSON 檔案`);

                        resolve({
                            success: true,
                            totalFiles: afterFiles.filter(f => f.endsWith('.json')).length,
                            newFiles: newFiles,
                            metadata: {
                                gradleVersion: '8.11',
                                cqlToElmVersion: '3.10.0',
                                inputDir: inputDir,
                                outputDir: outputDir
                            },
                            log: outputLog
                        });
                    } catch (error) {
                        reject(new Error(`讀取轉換結果失敗: ${error.message}`));
                    }
                } else {
                    reject(new Error(`Gradle 轉換失敗 (exit code ${code})\n${errorLog}`));
                }
            });

            gradleProcess.on('error', (error) => {
                reject(new Error(`Gradle 執行錯誤: ${error.message}`));
            });

        } catch (error) {
            reject(error);
        }
    });
}

/**
 * 轉換單一 CQL 檔案
 * @param {string} cqlFileName - CQL 檔案名稱 (不含路徑)
 * @param {function} [onProgress] - 進度回報
 */
async function convertSingleCQL(cqlFileName, onProgress = () => {}) {
    // 建立暫時目錄只放一個檔案
    const tempDir = path.join(PROJECT_ROOT, '_cql_convert_temp');
    await fs.mkdir(tempDir, { recursive: true });
    
    try {
        // 複製目標 CQL 檔案到暫時目錄
        const sourcePath = path.join(CQL_DIR, cqlFileName);
        await fs.copyFile(sourcePath, path.join(tempDir, cqlFileName));
        
        // 如果有 FHIRHelpers 也要複製（轉換依賴）
        const helpersSource = path.join(CQL_DIR, 'FHIRHelpers-4.0.1.cql');
        const helpersExists = await fs.access(helpersSource).then(() => true).catch(() => false);
        if (helpersExists) {
            await fs.copyFile(helpersSource, path.join(tempDir, 'FHIRHelpers-4.0.1.cql'));
        }
        
        const result = await convertCQLWithGradle({
            inputDir: tempDir,
            onProgress: onProgress
        });
        
        return result;
    } finally {
        // 清理暫時目錄
        await fs.rm(tempDir, { recursive: true, force: true }).catch(() => {});
    }
}

/**
 * 檢查 Gradle 環境
 */
async function checkGradleEnvironment() {
    try {
        const gradleExists = await fs.access(GRADLE_BIN).then(() => true).catch(() => false);
        const buildGradleExists = await fs.access(path.join(PROJECT_ROOT, 'build.gradle')).then(() => true).catch(() => false);
        const cqlDirExists = await fs.access(CQL_DIR).then(() => true).catch(() => false);
        
        const cqlFiles = cqlDirExists ? (await fs.readdir(CQL_DIR)).filter(f => f.endsWith('.cql')) : [];
        const elmFiles = (await fs.readdir(ELM_OUTPUT_DIR).catch(() => [])).filter(f => f.endsWith('.json'));

        if (!gradleExists) {
            return { available: false, error: `Gradle 未找到: ${GRADLE_BIN}` };
        }
        if (!buildGradleExists) {
            return { available: false, error: 'build.gradle 未找到' };
        }

        return {
            available: true,
            gradleVersion: '8.11',
            cqlToElmVersion: '3.10.0',
            cqlFiles: cqlFiles.length,
            elmFiles: elmFiles.length,
            cqlDir: CQL_DIR,
            elmDir: ELM_OUTPUT_DIR
        };
    } catch (error) {
        return { available: false, error: error.message };
    }
}

/**
 * 列出所有可用的 CQL 檔案
 */
async function listCQLFiles() {
    try {
        const files = await fs.readdir(CQL_DIR);
        return files.filter(f => f.endsWith('.cql')).sort();
    } catch {
        return [];
    }
}

module.exports = {
    convertCQLWithGradle,
    convertSingleCQL,
    checkGradleEnvironment,
    listCQLFiles,
    CQL_DIR,
    ELM_OUTPUT_DIR
};
