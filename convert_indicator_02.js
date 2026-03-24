const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const cqlFile = path.join(__dirname, 'cql', 'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql');
const outputFile = path.join(__dirname, 'ELM_JSON_OFFICIAL', '舊50', 'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.json');

console.log('Converting CQL to ELM JSON...');
console.log('Input:', cqlFile);
console.log('Output:', outputFile);

// Using cqframework Docker container
const dockerCmd = `docker run --rm -v "${__dirname.replace(/\\/g, '/')}/cql:/cql" -v "${__dirname.replace(/\\/g, '/')}/ELM_JSON_OFFICIAL/舊50:/output" cqframework/cql-translation-service:latest cql-to-elm --format=json --input=/cql/Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql --output=/output/Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.json`;

console.log('\nExecuting Docker command...');
exec(dockerCmd, (error, stdout, stderr) => {
    if (error) {
        console.error('Error:', error.message);
        
        // Try using local cql-to-elm if available
        console.log('\nTrying alternative: cql-to-elm CLI...');
        const localCmd = `cql-to-elm --format json "${cqlFile}" > "${outputFile}"`;
        
        exec(localCmd, (err2, stdout2, stderr2) => {
            if (err2) {
                console.error('Alternative also failed:', err2.message);
                console.log('\nPlease ensure Docker or cql-to-elm is installed.');
                return;
            }
            console.log('SUCCESS! JSON file created:', outputFile);
            if (stdout2) console.log(stdout2);
        });
        return;
    }
    
    console.log('SUCCESS! Conversion completed.');
    if (stdout) console.log(stdout);
    if (stderr) console.log('Stderr:', stderr);
    
    // Verify output file
    if (fs.existsSync(outputFile)) {
        const stats = fs.statSync(outputFile);
        console.log(`\nOutput file size: ${stats.size} bytes`);
    }
});
