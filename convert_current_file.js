const fs = require('fs');
const path = require('path');
const CqlTranslationServiceClient = require('cql-translation-service-client');

const cqlFile = 'cql/Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql';
const outputDir = 'ELM_JSON_OFFICIAL/舊50';

async function convertToElm() {
    try {
        console.log('讀取CQL文件...');
        const cqlContent = fs.readFileSync(cqlFile, 'utf-8');
        
        console.log('發送到官方CQL轉換服務...');
        const client = new CqlTranslationServiceClient('https://cql-translation-service.ahrq.gov');
        
        const result = await client.convertCQL(cqlContent, {
            format: 'json',
            'disable-list-demotion': true,
            'disable-list-promotion': true,
            'enable-annotations': true,
            'enable-locators': true,
            'error-level': 'Info'
        });

        // 確保輸出目錄存在
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        // 生成輸出文件名
        const baseName = path.basename(cqlFile, '.cql');
        const outputFile = path.join(outputDir, `${baseName}.json`);

        // 寫入JSON文件
        fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');
        
        console.log(`✅ 成功轉換: ${outputFile}`);
        console.log(`文件大小: ${(fs.statSync(outputFile).size / 1024).toFixed(2)} KB`);
        
    } catch (error) {
        console.error('❌ 轉換失敗:', error.message);
        process.exit(1);
    }
}

convertToElm();
