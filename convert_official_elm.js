const fs = require('fs');
const path = require('path');
const { Client } = require('cql-translation-service-client');

async function convertCqlToOfficialElm() {
    // Create translation service client
    const client = new Client('https://cql.dataphoria.org/cql/translator');
    
    // Setup paths
    const cqlFolder = path.join(__dirname, 'CQL 2026', '中醫');
    const fhirHelpersPath = path.join(__dirname, 'CQL 2026', 'FHIRHelpers', 'FHIRHelpers-4.0.1.cql');
    const outputFolder = path.join(__dirname, 'ELM_JSON_OFFICIAL', '中醫');
    
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
    
    // Get all CQL files
    const cqlFiles = fs.readdirSync(cqlFolder)
        .filter(f => f.endsWith('.cql'))
        .map(f => path.join(cqlFolder, f));
    
    console.log(`\nFound ${cqlFiles.length} CQL files to convert\n`);
    console.log('='.repeat(60));
    
    let successCount = 0;
    let failCount = 0;
    
    // Convert each file
    for (const cqlFilePath of cqlFiles) {
        const fileName = path.basename(cqlFilePath);
        const outputPath = path.join(outputFolder, fileName.replace('.cql', '.json'));
        
        try {
            console.log(`\nConverting: ${fileName}`);
            
            // Read CQL content
            const cqlContent = fs.readFileSync(cqlFilePath, 'utf8');
            
            // Prepare CQL libraries object (format required by client)
            const cqlLibraries = {
                [fileName]: { cql: cqlContent }
            };
            
            // Add FHIRHelpers if available
            if (fhirHelpersContent) {
                cqlLibraries['FHIRHelpers-4.0.1.cql'] = { cql: fhirHelpersContent };
            }
            
            // Convert using official translation service
            console.log('  Sending to official CQL translation service...');
            const result = await client.convertCQL(cqlLibraries);
            
            // Check if result is an error
            if (result.isAxiosError) {
                console.log(`  [FAIL] Network error: ${result.code || result.message}`);
                if (result.response) {
                    console.log(`  Status: ${result.response.status} ${result.response.statusText}`);
                }
                failCount++;
                continue;
            }
            
            // The result should be an object with library names as keys
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
                console.log(`  [SUCCESS] Saved: ${size} KB`);
                successCount++;
            } else {
                console.log(`  [FAIL] No ELM output for this library`);
                console.log(`  Available libraries: ${Object.keys(result).join(', ')}`);
                failCount++;
            }
            
        } catch (error) {
            console.log(`  [FAIL] ${error.message}`);
            failCount++;
        }
    }
    
    console.log('\n' + '='.repeat(60));
    console.log(`\nConversion Summary:`);
    console.log(`  Success: ${successCount}/${cqlFiles.length}`);
    console.log(`  Failed:  ${failCount}/${cqlFiles.length}`);
    console.log(`\nOutput directory: ${outputFolder}`);
}

// Run conversion
convertCqlToOfficialElm().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});
