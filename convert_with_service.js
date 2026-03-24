const fs = require('fs');
const path = require('path');
const http = require('http');

const cqlFilePath = path.join(__dirname, 'cql', 'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql');
const outputPath = path.join(__dirname, 'ELM_JSON_OFFICIAL', '舊50', 'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.json');

console.log('Reading CQL file...');
const cqlContent = fs.readFileSync(cqlFilePath, 'utf8');

const postData = cqlContent;

const options = {
    hostname: 'localhost',
    port: 8081,
    path: '/cql/translator',
    method: 'POST',
    headers: {
        'Content-Type': 'application/cql',
        'Content-Length': Buffer.byteLength(postData),
        'Accept': 'application/elm+json'
    }
};

console.log('Sending request to CQL translator service...');

const req = http.request(options, (res) => {
    console.log(`Status: ${res.statusCode}`);
    console.log(`Headers: ${JSON.stringify(res.headers)}`);
    
    let data = '';
    
    res.on('data', (chunk) => {
        data += chunk;
    });
    
    res.on('end', () => {
        if (res.statusCode === 200 || res.statusCode === 400) {
            try {
                // Parse and pretty-print JSON
                const jsonData = JSON.parse(data);
                const prettyJson = JSON.stringify(jsonData, null, 2);
                
                // Save to file
                fs.writeFileSync(outputPath, prettyJson, 'utf8');
                
                console.log('\n✓ SUCCESS! Conversion completed');
                console.log(`Output saved to: ${outputPath}`);
                console.log(`\nLibrary: ${jsonData.library.identifier.id}`);
                console.log(`Version: ${jsonData.library.identifier.version}`);
                
                // Show statement count
                if (jsonData.library.statements && jsonData.library.statements.def) {
                    console.log(`Statements: ${jsonData.library.statements.def.length}`);
                    console.log('\nStatements:');
                    jsonData.library.statements.def.forEach(stmt => {
                        console.log(`  - ${stmt.name}`);
                    });
                }
                
                // Check for errors
                if (jsonData.library.annotation) {
                    const errors = jsonData.library.annotation.filter(a => a.errorSeverity === 'error');
                    const warnings = jsonData.library.annotation.filter(a => a.errorSeverity === 'warning');
                    if (errors.length > 0) {
                        console.log(`\n⚠ Errors: ${errors.length}`);
                    }
                    if (warnings.length > 0) {
                        console.log(`⚠ Warnings: ${warnings.length}`);
                    }
                }
            } catch (err) {
                console.error('Error parsing JSON:', err.message);
                console.log('Raw response:', data);
                fs.writeFileSync(outputPath, data, 'utf8');
            }
        } else {
            console.error('Conversion failed');
            console.log('Response:', data);
        }
    });
});

req.on('error', (error) => {
    console.error('Request failed:', error.message);
});

req.write(postData);
req.end();
