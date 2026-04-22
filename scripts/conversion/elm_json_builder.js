/**
 * ELM JSON片段生成器
 * 直接生成标准ELM JSON结构，无需CQL转换
 */

const fs = require('fs');

class ELMBuilder {
    constructor(libraryName, version = '1.0.0') {
        this.elm = {
            library: {
                identifier: {
                    id: libraryName,
                    version: version
                },
                schemaIdentifier: {
                    id: "urn:hl7-org:elm",
                    version: "r1"
                },
                usings: {
                    def: [
                        {
                            localIdentifier: "System",
                            uri: "urn:hl7-org:elm-types:r1"
                        },
                        {
                            localIdentifier: "FHIR",
                            uri: "http://hl7.org/fhir",
                            version: "4.0.1"
                        }
                    ]
                },
                includes: {
                    def: [
                        {
                            localIdentifier: "FHIRHelpers",
                            path: "FHIRHelpers",
                            version: "4.0.1"
                        }
                    ]
                },
                parameters: {
                    def: []
                },
                statements: {
                    def: [
                        {
                            name: "Patient",
                            context: "Patient",
                            expression: {
                                type: "SingletonFrom",
                                operand: {
                                    dataType: "{http://hl7.org/fhir}Patient",
                                    type: "Retrieve"
                                }
                            }
                        }
                    ]
                }
            }
        };
    }

    // 添加参数
    addParameter(name, type = 'DateTime', defaultValue = null) {
        const param = {
            name: name,
            accessLevel: "Public",
            parameterTypeSpecifier: {
                type: "NamedTypeSpecifier",
                name: `{urn:hl7-org:elm-types:r1}${type}`
            }
        };
        
        if (defaultValue) {
            param.default = {
                type: "DateTime",
                value: defaultValue
            };
        }
        
        this.elm.library.parameters.def.push(param);
        return this;
    }

    // 添加Interval参数
    addIntervalParameter(name, pointType = 'DateTime') {
        this.elm.library.parameters.def.push({
            name: name,
            accessLevel: "Public",
            parameterTypeSpecifier: {
                type: "IntervalTypeSpecifier",
                pointType: {
                    name: `{urn:hl7-org:elm-types:r1}${pointType}`,
                    type: "NamedTypeSpecifier"
                }
            }
        });
        return this;
    }

    // 添加Retrieve定义（查询FHIR资源）
    addRetrieve(name, resourceType, alias = 'R') {
        this.elm.library.statements.def.push({
            name: name,
            context: "Patient",
            accessLevel: "Public",
            expression: {
                dataType: `{http://hl7.org/fhir}${resourceType}`,
                type: "Retrieve"
            }
        });
        return this;
    }

    // 添加带Where条件的Query
    addQueryWithWhere(name, resourceType, whereCondition) {
        this.elm.library.statements.def.push({
            name: name,
            context: "Patient",
            accessLevel: "Public",
            expression: {
                type: "Query",
                source: [
                    {
                        alias: resourceType.charAt(0),
                        expression: {
                            dataType: `{http://hl7.org/fhir}${resourceType}`,
                            type: "Retrieve"
                        }
                    }
                ],
                relationship: [],
                where: whereCondition
            }
        });
        return this;
    }

    // 创建日期范围条件（during）
    createDuringCondition(propertyPath, parameterName, scope = 'E') {
        return {
            type: "IncludedIn",
            operand: [
                {
                    path: propertyPath,
                    scope: scope,
                    type: "Property"
                },
                {
                    name: parameterName,
                    type: "ParameterRef"
                }
            ]
        };
    }

    // 创建Code比较条件
    createCodeEqualsCondition(propertyPath, codeSystem, code, scope = 'E') {
        return {
            type: "Equivalent",
            operand: [
                {
                    path: propertyPath,
                    scope: scope,
                    type: "Property"
                },
                {
                    type: "Code",
                    system: {
                        name: codeSystem
                    },
                    code: code
                }
            ]
        };
    }

    // 创建And条件
    createAndCondition(left, right) {
        return {
            type: "And",
            operand: [left, right]
        };
    }

    // 创建Or条件
    createOrCondition(left, right) {
        return {
            type: "Or",
            operand: [left, right]
        };
    }

    // 添加Count定义
    addCount(name, sourceExpression) {
        this.elm.library.statements.def.push({
            name: name,
            context: "Patient",
            accessLevel: "Public",
            expression: {
                type: "Count",
                source: {
                    name: sourceExpression,
                    type: "ExpressionRef"
                }
            }
        });
        return this;
    }

    // 添加除法计算（百分比）
    addDivision(name, numerator, denominator) {
        this.elm.library.statements.def.push({
            name: name,
            context: "Patient",
            accessLevel: "Public",
            expression: {
                type: "Divide",
                operand: [
                    {
                        name: numerator,
                        type: "ExpressionRef"
                    },
                    {
                        name: denominator,
                        type: "ExpressionRef"
                    }
                ]
            }
        });
        return this;
    }

    // 生成JSON
    build() {
        return this.elm;
    }

    // 保存到文件
    save(filename) {
        fs.writeFileSync(filename, JSON.stringify(this.elm, null, 2), 'utf-8');
        console.log(`✓ ELM JSON已保存: ${filename}`);
        console.log(`  大小: ${(fs.statSync(filename).size / 1024).toFixed(2)} KB`);
        return filename;
    }
}

// ===== 示例：中医同日重复就诊率 =====
console.log('='.repeat(70));
console.log(' ELM JSON生成器示例');
console.log('='.repeat(70));

const builder = new ELMBuilder('Indicator_TCM_Same_Day_Revisit_Rate', '1.0.0');

// 添加参数
builder
    .addParameter('MeasurementPeriodStart', 'DateTime', '@2026-01-01T00:00:00.0+08:00')
    .addParameter('MeasurementPeriodEnd', 'DateTime', '@2026-03-31T23:59:59.0+08:00');

// 添加Measurement Period定义
builder.elm.library.statements.def.push({
    name: "Measurement Period",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        type: "Interval",
        low: {
            name: "MeasurementPeriodStart",
            type: "ParameterRef"
        },
        high: {
            name: "MeasurementPeriodEnd",
            type: "ParameterRef"
        }
    }
});

// 添加Encounters定义
const encounterWhere = builder.createDuringCondition('period', 'Measurement Period', 'E');
builder.addQueryWithWhere('Encounters', 'Encounter', encounterWhere);

// 添加计数
builder.addCount('Encounter Count', 'Encounters');

// 保存
const outputFile = 'ELM_JSON_OFFICIAL/中醫/Indicator_TCM_Same_Day_Revisit_Rate_手写.json';
if (!fs.existsSync('ELM_JSON_OFFICIAL/中醫')) {
    fs.mkdirSync('ELM_JSON_OFFICIAL/中醫', { recursive: true });
}
builder.save(outputFile);

console.log('\n使用方法:');
console.log('1. 修改此脚本创建你需要的逻辑');
console.log('2. 运行: node elm_json_builder.js');
console.log('3. 验证: node verify_elm_quality.js "' + outputFile + '"');

console.log('\n常用API:');
console.log('- addParameter(name, type, defaultValue)');
console.log('- addRetrieve(name, resourceType)');
console.log('- addQueryWithWhere(name, resourceType, whereCondition)');
console.log('- addCount(name, sourceExpression)');
console.log('- createDuringCondition(propertyPath, parameterName)');
console.log('- createCodeEqualsCondition(propertyPath, codeSystem, code)');

module.exports = ELMBuilder;
