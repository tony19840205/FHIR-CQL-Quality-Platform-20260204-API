const fs = require('fs');
const path = require('path');
const { Client } = require('cql-translation-service-client');

async function convert5Files() {
    // Create translation service client
    const client = new Client('https://cql.dataphoria.org/cql/translator');
    
    // Files to convert
    const filesToConvert = [
        'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
        'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
        'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
        'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql',
        'Waste.cql'
    ];
    
    // Setup paths
    const tempFolder = path.join(__dirname, 'cql_5files_temp');
    const fhirHelpersPath = path.join(__dirname, 'CQL 2026', 'FHIRHelpers', 'FHIRHelpers-4.0.1.cql');
    const outputFolder = path.join(__dirname, 'ELM_JSON_OFFICIAL', '舊50');
    
    // Create output directory
    if (!fs.existsSync(outputFolder)) {
        fs.mkdirSync(outputFolder, { recursive: true });
    }
    
    // Read FHIRHelpers
    let fhirHelpersContent = '';
    if (fs.existsSync(fhirHelpersPath)) {
        fhirHelpersContent = fs.readFileSync(fhirHelpersPath, 'utf8');
        console.log('[OK] Loaded FHIRHelpers-4.0.1.cql');
    } else {
        console.log('[WARN] FHIRHelpers not found, proceeding without it');
    }
    
    console.log(`\n=== 批量轉換5個CQL文件到官方ELM JSON ===\n`);
    console.log('='.repeat(60));
    
    let successCount = 0;
    let failCount = 0;
    
    // Convert each file
    for (const fileName of filesToConvert) {
        const cqlFilePath = path.join(tempFolder, fileName);
        const outputPath = path.join(outputFolder, fileName.replace('.cql', '.json'));
        
        try {
            console.log(`\n處理: ${fileName}`);
            
            // Check if file exists
            if (!fs.existsSync(cqlFilePath)) {
                console.log(`  [FAIL] 文件不存在`);
                failCount++;
                continue;
            }
            
            // Read CQL content
            const cqlContent = fs.readFileSync(cqlFilePath, 'utf8');
            
            // Prepare CQL libraries object
            const cqlLibraries = {
                [fileName]: { cql: cqlContent }
            };
            
            // Add FHIRHelpers if available
            if (fhirHelpersContent) {
                cqlLibraries['FHIRHelpers-4.0.1.cql'] = { cql: fhirHelpersContent };
            }
            
            // Convert using official translation service
            console.log('  發送到官方CQL轉換服務...');
            const result = await client.convertCQL(cqlLibraries);
            
            // Check if result is an error
            if (result.isAxiosError) {
                console.log(`  [失敗] 網路錯誤: ${result.code || result.message}`);
                if (result.response) {
                    console.log(`  狀態: ${result.response.status} ${result.response.statusText}`);
                }
                failCount++;
                continue;
            }
            
            // Get the ELM output
            const libraryName = fileName.replace('.cql', '');
            const elm = result[libraryName] || result[fileName];
            
            if (elm) {
                // Save official ELM JSON
                fs.writeFileSync(
                    outputPath,
                    JSON.stringify(elm, null, 2),
                    'utf8'
                );
                
                const size = (fs.statSync(outputPath).size / 1024).toFixed(2);
                console.log(`  ✓ 轉換成功: ${size} KB`);
                successCount++;
            } else {
                console.log(`  [失敗] 無ELM輸出`);
                console.log(`  可用的libraries: ${Object.keys(result).join(', ')}`);
                failCount++;
            }
            
        } catch (error) {
            console.log(`  ✗ 錯誤: ${error.message}`);
            failCount++;
        }
    }
    
    console.log('\n' + '='.repeat(60));
    console.log(`\n轉換結果:`);
    console.log(`  成功: ${successCount}/${filesToConvert.length}`);
    console.log(`  失敗: ${failCount}/${filesToConvert.length}`);
    console.log(`\n輸出目錄: ${outputFolder}`);
    
    // Clean up temp directory
    if (fs.existsSync(tempFolder)) {
        console.log(`\n清理臨時目錄: ${tempFolder}`);
        fs.rmSync(tempFolder, { recursive: true, force: true });
    }
}

// Run conversion
convert5Files().catch(error => {
    console.error('嚴重錯誤:', error);
    process.exit(1);
});
