const fs = require('fs');
const path = require('path');
const cql = require('cql-execution');

// CQL to ELM conversion using official library
function convertCqlToElm(cqlFilePath, outputDir) {
    try {
        console.log(`Converting: ${path.basename(cqlFilePath)}`);
        
        // Read CQL file
        const cqlContent = fs.readFileSync(cqlFilePath, 'utf8');
        
        // Note: cql-execution library requires pre-compiled ELM
        // We need the cql-to-elm library instead
        console.log('ERROR: cql-execution requires pre-compiled ELM');
        console.log('We need to use cql-to-elm translator library');
        
        return false;
    } catch (error) {
        console.error(`Error converting ${cqlFilePath}:`, error.message);
        return false;
    }
}

// Get all CQL files from 中醫 folder
const cqlFolder = path.join(__dirname, 'CQL 2026', '中醫');
const outputFolder = path.join(__dirname, 'ELM_JSON_OFFICIAL', '中醫');

// Create output directory
if (!fs.existsSync(outputFolder)) {
    fs.mkdirSync(outputFolder, { recursive: true });
}

// Get all .cql files
const cqlFiles = fs.readdirSync(cqlFolder)
    .filter(f => f.endsWith('.cql'))
    .map(f => path.join(cqlFolder, f));

console.log(`Found ${cqlFiles.length} CQL files to convert\n`);

// Convert each file
let successCount = 0;
cqlFiles.forEach(file => {
    if (convertCqlToElm(file, outputFolder)) {
        successCount++;
    }
});

console.log(`\nConversion complete: ${successCount}/${cqlFiles.length} files`);
