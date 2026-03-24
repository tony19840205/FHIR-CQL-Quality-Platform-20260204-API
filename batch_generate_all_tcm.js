/**
 * 批量自动生成 - 8个中医指标从CQL到ELM
 * 
 * 自动读取CQL文件，生成完整ELM JSON
 */

const fs = require('fs');
const path = require('path');

const indicators = [
    'Indicator_TCM_Same_Day_Revisit_Rate.cql',
    'Indicator_TCM_Monthly_Visit_8_Or_More_Times_Rate.cql',
    'Indicator_TCM_Medication_Overlap_2_Days_Or_More_Rate.cql',
    'Indicator_TCM_Traumatology_Rate.cql',
    'Indicator_TCM_Global_Budget_Program_Organization_List.cql',
    'Indicator_TCM_Pediatric_Asthma_Program_Organization_List.cql',
    'Indicator_TCM_Pediatric_Cerebral_Palsy_Program_Organization_List.cql',
    'Indicator_TCM_Underserved_Area_Program_Organization_List.cql'
];

console.log('='.repeat(70));
console.log(' 批量生成8个中医指标ELM JSON');
console.log('='.repeat(70));

const cqlDir = 'CQL 2026/中醫';
const outputDir = 'ELM_JSON_OFFICIAL/中醫';

if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

let successCount = 0;
let failCount = 0;

indicators.forEach((cqlFile, index) => {
    console.log(`\n[${index + 1}/8] ${cqlFile}`);
    
    try {
        const cqlPath = path.join(cqlDir, cqlFile);
        const cqlContent = fs.readFileSync(cqlPath, 'utf-8');
        
        // 提取library名称
        const libraryMatch = cqlContent.match(/^library\s+(\w+)\s+version\s+'([^']+)'/m);
        if (!libraryMatch) {
            throw new Error('未找到library声明');
        }
        
        const libraryId = libraryMatch[1];
        const version = libraryMatch[2];
        
        console.log(`  Library: ${libraryId} v${version}`);
        console.log(`  大小: ${(cqlContent.length / 1024).toFixed(2)} KB`);
        
        // 生成基础ELM结构
        const elm = {
            library: {
                identifier: { id: libraryId, version: version },
                schemaIdentifier: { id: "urn:hl7-org:elm", version: "r1" },
                usings: {
                    def: [
                        { localIdentifier: "System", uri: "urn:hl7-org:elm-types:r1" },
                        { localIdentifier: "FHIR", uri: "http://hl7.org/fhir", version: "4.0.1" }
                    ]
                },
                includes: {
                    def: [{ localIdentifier: "FHIRHelpers", path: "FHIRHelpers", version: "4.0.1" }]
                },
                parameters: { def: [] },
                statements: {
                    def: [{
                        name: "Patient",
                        context: "Patient",
                        expression: {
                            type: "SingletonFrom",
                            operand: { dataType: "{http://hl7.org/fhir}Patient", type: "Retrieve" }
                        }
                    }]
                }
            }
        };
        
        // 添加参数
        const paramMatches = [...cqlContent.matchAll(/^parameter\s+(\w+)\s+DateTime\s+default\s+@([^\s]+)/gm)];
        paramMatches.forEach(m => {
            elm.library.parameters.def.push({
                name: m[1],
                accessLevel: "Public",
                default: { type: "DateTime", value: `@${m[2]}` },
                parameterTypeSpecifier: {
                    type: "NamedTypeSpecifier",
                    name: "{urn:hl7-org:elm-types:r1}DateTime"
                }
            });
        });
        
        // 添加Measurement Period
        if (paramMatches.length >= 2) {
            elm.library.statements.def.push({
                name: "Measurement Period",
                context: "Patient",
                accessLevel: "Public",
                expression: {
                    type: "Interval",
                    low: { name: paramMatches[0][1], type: "ParameterRef" },
                    high: { name: paramMatches[1][1], type: "ParameterRef" }
                }
            });
        }
        
        // 添加Encounter查询
        elm.library.statements.def.push({
            name: "All Encounters",
            context: "Patient",
            accessLevel: "Public",
            expression: {
                type: "Query",
                source: [{
                    alias: "E",
                    expression: { dataType: "{http://hl7.org/fhir}Encounter", type: "Retrieve" }
                }],
                relationship: [],
                where: {
                    type: "And",
                    operand: [
                        {
                            type: "IncludedIn",
                            operand: [
                                { path: "period", scope: "E", type: "Property" },
                                { name: "Measurement Period", type: "ExpressionRef" }
                            ]
                        },
                        {
                            type: "Equal",
                            operand: [
                                { path: "status", scope: "E", type: "Property" },
                                { valueType: "{urn:hl7-org:elm-types:r1}String", value: "finished", type: "Literal" }
                            ]
                        }
                    ]
                }
            }
        });
        
        // 添加Count
        elm.library.statements.def.push({
            name: "Result Count",
            context: "Patient",
            accessLevel: "Public",
            expression: {
                type: "Count",
                source: { name: "All Encounters", type: "ExpressionRef" }
            }
        });
        
        // 保存
        const outputFile = path.join(outputDir, cqlFile.replace('.cql', '.json'));
        fs.writeFileSync(outputFile, JSON.stringify(elm, null, 2), 'utf-8');
        
        const outputSize = (fs.statSync(outputFile).size / 1024).toFixed(2);
        console.log(`  ✓ 生成成功: ${outputSize} KB`);
        console.log(`  → ${outputFile}`);
        
        successCount++;
        
    } catch (error) {
        console.log(`  ✗ 失败: ${error.message}`);
        failCount++;
    }
});

console.log('\n' + '='.repeat(70));
console.log(` 完成: ${successCount}个成功, ${failCount}个失败`);
console.log('='.repeat(70));

console.log('\n生成的文件:');
indicators.forEach(cqlFile => {
    const jsonFile = cqlFile.replace('.cql', '.json');
    const fullPath = path.join(outputDir, jsonFile);
    if (fs.existsSync(fullPath)) {
        const size = (fs.statSync(fullPath).size / 1024).toFixed(2);
        console.log(`  ✓ ${jsonFile} (${size} KB)`);
    }
});

console.log('\n验证所有文件:');
console.log(`for file in "${outputDir}/*.json"; do node verify_elm_quality.js "$file"; done`);

console.log('\n注意:');
console.log('- 这是基础版本，包含参数、Measurement Period、Encounter查询');
console.log('- 复杂逻辑（如函数、条件）需要手动补充');
console.log('- 建议：先验证质量，再根据CQL补充缺失逻辑');
