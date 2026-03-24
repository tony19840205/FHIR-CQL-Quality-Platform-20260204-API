/**
 * ELM生成模板 - 快速创建8个中医指标
 * 
 * 使用方法：
 * 1. 复制此模板
 * 2. 修改配置对象
 * 3. 运行生成
 * 4. 验证质量
 */

const fs = require('fs');
const path = require('path');

// ============================================================================
// 配置区：修改这里来创建不同指标
// ============================================================================

const indicators = [
    {
        id: 'Indicator_TCM_Same_Day_Revisit_Rate',
        name: '同日重复就诊率',
        description: '就诊中医门诊后同日再次就诊中医之比率',
        // 自定义逻辑（稍后添加）
    },
    {
        id: 'Indicator_TCM_Monthly_Visit_8_Or_More_Times_Rate',
        name: '每月就诊8次以上比率',
        description: '每月就诊中医门诊8次以上之比率',
    },
    {
        id: 'Indicator_TCM_Medication_Overlap_2_Days_Or_More_Rate',
        name: '重复用药2天以上比率',
        description: '同成分药品重复用药2天以上之比率',
    },
    {
        id: 'Indicator_TCM_Traumatology_Rate',
        name: '中医伤科占率',
        description: '中医伤科处置占率',
    },
    {
        id: 'Indicator_TCM_Global_Budget_Program_Organization_List',
        name: '全民健康保险中医总额支付制度方案院所清单',
        description: '',
    },
    {
        id: 'Indicator_TCM_Pediatric_Asthma_Program_Organization_List',
        name: '中医小儿气喘照护计划方案院所清单',
        description: '',
    },
    {
        id: 'Indicator_TCM_Pediatric_Cerebral_Palsy_Program_Organization_List',
        name: '中医小儿脑性麻痹照护计划方案院所清单',
        description: '',
    },
    {
        id: 'Indicator_TCM_Underserved_Area_Program_Organization_List',
        name: '中医偏远地区照护计划方案院所清单',
        description: '',
    }
];

// ============================================================================
// ELM生成器类
// ============================================================================

class ELMGenerator {
    constructor(config) {
        this.config = config;
        this.elm = this.createBasicStructure();
    }

    createBasicStructure() {
        return {
            library: {
                identifier: {
                    id: this.config.id,
                    version: "1.0.0"
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

    // 添加DateTime参数
    addDateTimeParameter(name, defaultValue) {
        this.elm.library.parameters.def.push({
            name: name,
            accessLevel: "Public",
            default: {
                type: "DateTime",
                value: defaultValue
            },
            parameterTypeSpecifier: {
                type: "NamedTypeSpecifier",
                name: "{urn:hl7-org:elm-types:r1}DateTime"
            }
        });
        return this;
    }

    // 添加Interval定义
    addMeasurementPeriod() {
        this.elm.library.statements.def.push({
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
        return this;
    }

    // 添加Encounter查询
    addEncounterQuery(name, whereCondition) {
        this.elm.library.statements.def.push({
            name: name,
            context: "Patient",
            accessLevel: "Public",
            expression: {
                type: "Query",
                source: [
                    {
                        alias: "E",
                        expression: {
                            dataType: "{http://hl7.org/fhir}Encounter",
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

    // 创建during条件
    createDuringCondition(propertyPath, expressionName) {
        return {
            type: "IncludedIn",
            operand: [
                {
                    path: propertyPath,
                    scope: "E",
                    type: "Property"
                },
                {
                    name: expressionName,
                    type: "ExpressionRef"
                }
            ]
        };
    }

    // 创建等于条件
    createEqualCondition(propertyPath, value) {
        return {
            type: "Equal",
            operand: [
                {
                    path: propertyPath,
                    scope: "E",
                    type: "Property"
                },
                {
                    valueType: "{urn:hl7-org:elm-types:r1}String",
                    value: value,
                    type: "Literal"
                }
            ]
        };
    }

    // 创建And条件
    createAndCondition(...conditions) {
        return {
            type: "And",
            operand: conditions
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

    // 保存文件
    save(filename) {
        const outputDir = 'ELM_JSON_OFFICIAL/中醫';
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        
        const filepath = path.join(outputDir, filename);
        fs.writeFileSync(filepath, JSON.stringify(this.elm, null, 2), 'utf-8');
        
        return filepath;
    }
}

// ============================================================================
// 示例：生成第一个指标（同日重复就诊率）
// ============================================================================

console.log('='.repeat(70));
console.log(' 生成8个中医指标ELM');
console.log('='.repeat(70));

// 示例1：同日重复就诊率
console.log('\n生成指标1: 同日重复就诊率...');

const gen1 = new ELMGenerator(indicators[0]);

gen1
    .addDateTimeParameter('MeasurementPeriodStart', '@2026-01-01T00:00:00.0+08:00')
    .addDateTimeParameter('MeasurementPeriodEnd', '@2026-03-31T23:59:59.0+08:00')
    .addMeasurementPeriod();

// 添加Encounter查询
const encounterWhere = gen1.createAndCondition(
    gen1.createDuringCondition('period', 'Measurement Period'),
    gen1.createEqualCondition('status', 'finished')
);

gen1
    .addEncounterQuery('Encounters During Period', encounterWhere)
    .addCount('Total Encounter Count', 'Encounters During Period');

const file1 = gen1.save('Indicator_TCM_Same_Day_Revisit_Rate.json');
console.log(`✓ 已保存: ${file1}`);

// ============================================================================
// 你的任务：完成其他7个指标
// ============================================================================

console.log('\n' + '='.repeat(70));
console.log(' 你的任务：完成其他7个指标');
console.log('='.repeat(70));

console.log('\n复制上面的模式，创建：');
indicators.slice(1).forEach((ind, idx) => {
    console.log(`${idx + 2}. ${ind.name} (${ind.id})`);
});

console.log('\n提示：');
console.log('1. 复制gen1的代码块');
console.log('2. 修改变量名为gen2, gen3...');
console.log('3. 根据CQL文件调整where条件');
console.log('4. 添加特定的逻辑（如Code检查、日期计算等）');

console.log('\n验证每个生成的文件：');
console.log('node verify_elm_quality.js "ELM_JSON_OFFICIAL/中醫/[文件名].json"');

// 导出供其他脚本使用
module.exports = { ELMGenerator, indicators };
