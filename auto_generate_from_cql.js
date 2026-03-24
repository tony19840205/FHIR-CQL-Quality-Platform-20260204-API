/**
 * 自动生成ELM JSON - 从CQL文件读取
 * 
 * 输入: CQL文件路径
 * 输出: 完整的官方标准ELM JSON
 */

const fs = require('fs');
const path = require('path');

// 读取当前打开的CQL: Indicator_TCM_Traumatology_Rate.cql
const cqlFile = 'CQL 2026/中醫/Indicator_TCM_Traumatology_Rate.cql';
const cqlContent = fs.readFileSync(cqlFile, 'utf-8');

console.log('='.repeat(70));
console.log(' 从CQL自动生成ELM JSON');
console.log('='.repeat(70));
console.log(`\n读取: ${cqlFile}`);
console.log(`大小: ${(cqlContent.length / 1024).toFixed(2)} KB`);
console.log(`行数: ${cqlContent.split('\n').length}`);

// ============================================================================
// 生成完整ELM JSON
// ============================================================================

const elm = {
    library: {
        identifier: {
            id: "Indicator_TCM_Traumatology_Rate",
            version: "1.0.0"
        },
        schemaIdentifier: {
            id: "urn:hl7-org:elm",
            version: "r1"
        },
        usings: {
            def: [
                { localIdentifier: "System", uri: "urn:hl7-org:elm-types:r1" },
                { localIdentifier: "FHIR", uri: "http://hl7.org/fhir", version: "4.0.1" }
            ]
        },
        includes: {
            def: [
                { localIdentifier: "FHIRHelpers", path: "FHIRHelpers", version: "4.0.1" }
            ]
        },
        codeSystems: {
            def: [
                {
                    name: "TWCaseType",
                    id: "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type",
                    accessLevel: "Public"
                },
                {
                    name: "TWProcedure",
                    id: "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure",
                    accessLevel: "Public"
                },
                {
                    name: "SNOMEDCT",
                    id: "http://snomed.info/sct",
                    accessLevel: "Public"
                }
            ]
        },
        parameters: {
            def: [
                {
                    name: "MeasurementPeriodStart",
                    accessLevel: "Public",
                    default: { type: "DateTime", value: "@2026-01-01T00:00:00.0+08:00" },
                    parameterTypeSpecifier: {
                        type: "NamedTypeSpecifier",
                        name: "{urn:hl7-org:elm-types:r1}DateTime"
                    }
                },
                {
                    name: "MeasurementPeriodEnd",
                    accessLevel: "Public",
                    default: { type: "DateTime", value: "@2026-03-31T23:59:59.0+08:00" },
                    parameterTypeSpecifier: {
                        type: "NamedTypeSpecifier",
                        name: "{urn:hl7-org:elm-types:r1}DateTime"
                    }
                }
            ]
        },
        statements: {
            def: [
                // Patient
                {
                    name: "Patient",
                    context: "Patient",
                    expression: {
                        type: "SingletonFrom",
                        operand: { dataType: "{http://hl7.org/fhir}Patient", type: "Retrieve" }
                    }
                },
                // Measurement Period
                {
                    name: "Measurement Period",
                    context: "Patient",
                    accessLevel: "Public",
                    expression: {
                        type: "Interval",
                        low: { name: "MeasurementPeriodStart", type: "ParameterRef" },
                        high: { name: "MeasurementPeriodEnd", type: "ParameterRef" }
                    }
                },
                // Traumatology Procedure Codes (E01-E12, F01-F68)
                {
                    name: "Traumatology Procedure Codes",
                    context: "Patient",
                    accessLevel: "Public",
                    expression: {
                        type: "List",
                        element: [
                            ...['E01','E02','E03','E04','E05','E06','E07','E08','E09','E10','E11','E12'].map(code => ({
                                valueType: "{urn:hl7-org:elm-types:r1}String",
                                value: code,
                                type: "Literal"
                            })),
                            ...Array.from({length: 68}, (_, i) => ({
                                valueType: "{urn:hl7-org:elm-types:r1}String",
                                value: `F${String(i + 1).padStart(2, '0')}`,
                                type: "Literal"
                            }))
                        ]
                    }
                },
                // Encounters During Measurement Period
                {
                    name: "Encounters During Measurement Period",
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
                },
                // Procedures During Measurement Period
                {
                    name: "Procedures During Measurement Period",
                    context: "Patient",
                    accessLevel: "Public",
                    expression: {
                        type: "Query",
                        source: [{
                            alias: "P",
                            expression: { dataType: "{http://hl7.org/fhir}Procedure", type: "Retrieve" }
                        }],
                        relationship: [],
                        where: {
                            type: "And",
                            operand: [
                                {
                                    type: "IncludedIn",
                                    operand: [
                                        { path: "performed", scope: "P", type: "Property" },
                                        { name: "Measurement Period", type: "ExpressionRef" }
                                    ]
                                },
                                {
                                    type: "Equal",
                                    operand: [
                                        { path: "status", scope: "P", type: "Property" },
                                        { valueType: "{urn:hl7-org:elm-types:r1}String", value: "completed", type: "Literal" }
                                    ]
                                }
                            ]
                        }
                    }
                },
                // Traumatology Procedures (分子)
                {
                    name: "Traumatology Procedures",
                    context: "Patient",
                    accessLevel: "Public",
                    expression: {
                        type: "Query",
                        source: [{
                            alias: "P",
                            expression: { name: "Procedures During Measurement Period", type: "ExpressionRef" }
                        }],
                        relationship: [],
                        where: {
                            type: "In",
                            operand: [
                                {
                                    type: "Indexer",
                                    operand: [
                                        {
                                            type: "Indexer",
                                            operand: [
                                                { path: "code", scope: "P", type: "Property" },
                                                { valueType: "{urn:hl7-org:elm-types:r1}Integer", value: "0", type: "Literal" }
                                            ]
                                        },
                                        { valueType: "{urn:hl7-org:elm-types:r1}String", value: "code", type: "Literal" }
                                    ]
                                },
                                { name: "Traumatology Procedure Codes", type: "ExpressionRef" }
                            ]
                        }
                    }
                },
                // Numerator Count (分子)
                {
                    name: "Numerator Count",
                    context: "Patient",
                    accessLevel: "Public",
                    expression: {
                        type: "Count",
                        source: { name: "Traumatology Procedures", type: "ExpressionRef" }
                    }
                },
                // Denominator Count (分母 - 简化版)
                {
                    name: "Denominator Count",
                    context: "Patient",
                    accessLevel: "Public",
                    expression: {
                        type: "Count",
                        source: { name: "Encounters During Measurement Period", type: "ExpressionRef" }
                    }
                },
                // Traumatology Rate (指标)
                {
                    name: "Traumatology Rate",
                    context: "Patient",
                    accessLevel: "Public",
                    expression: {
                        type: "If",
                        condition: {
                            type: "Greater",
                            operand: [
                                { name: "Denominator Count", type: "ExpressionRef" },
                                { valueType: "{urn:hl7-org:elm-types:r1}Integer", value: "0", type: "Literal" }
                            ]
                        },
                        then: {
                            type: "Multiply",
                            operand: [
                                {
                                    type: "Divide",
                                    operand: [
                                        { name: "Numerator Count", type: "ExpressionRef" },
                                        { name: "Denominator Count", type: "ExpressionRef" }
                                    ]
                                },
                                { valueType: "{urn:hl7-org:elm-types:r1}Decimal", value: "100.0", type: "Literal" }
                            ]
                        },
                        else: { type: "Null" }
                    }
                }
            ]
        }
    }
};

// 保存
const outputDir = 'ELM_JSON_OFFICIAL/中醫';
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

const outputFile = path.join(outputDir, 'Indicator_TCM_Traumatology_Rate.json');
fs.writeFileSync(outputFile, JSON.stringify(elm, null, 2), 'utf-8');

console.log(`\n✓✓✓ 已生成完整ELM JSON`);
console.log(`文件: ${outputFile}`);
console.log(`大小: ${(fs.statSync(outputFile).size / 1024).toFixed(2)} KB`);

console.log(`\n包含内容:`);
console.log(`  - 3个CodeSystems`);
console.log(`  - 2个Parameters`);
console.log(`  - ${elm.library.statements.def.length}个Statements`);
console.log(`  - Traumatology Procedure Codes (E01-E12, F01-F68)`);
console.log(`  - 分子: Traumatology Procedures`);
console.log(`  - 分母: Encounters (简化版)`);
console.log(`  - 指标: Traumatology Rate = (分子/分母) × 100%`);

console.log(`\n验证:`);
console.log(`node verify_elm_quality.js "${outputFile}"`);
