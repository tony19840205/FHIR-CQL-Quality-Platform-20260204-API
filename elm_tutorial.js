/**
 * ELM JSON 手写教学 - 中医同日重复就诊率
 * 
 * 学习目标：
 * 1. 理解ELM JSON基本结构
 * 2. 学会写Parameter、Define、Query
 * 3. 掌握常用表达式类型
 * 4. 能独立创建其他7个指标
 */

const fs = require('fs');
const path = require('path');

console.log('='.repeat(70));
console.log(' ELM JSON 手写教学');
console.log('='.repeat(70));

// ============================================================================
// 第1课：ELM基本骨架
// ============================================================================
console.log('\n【第1课】ELM基本骨架');
console.log('-'.repeat(70));

const elm = {
    library: {
        // 1.1 标识信息（必需）
        identifier: {
            id: "Indicator_TCM_Same_Day_Revisit_Rate",  // 库名
            version: "1.0.0"                             // 版本
        },
        
        // 1.2 Schema标识（必需）
        schemaIdentifier: {
            id: "urn:hl7-org:elm",
            version: "r1"
        },
        
        // 1.3 数据模型声明（using FHIR）
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
        
        // 1.4 包含其他库（include FHIRHelpers）
        includes: {
            def: [
                {
                    localIdentifier: "FHIRHelpers",
                    path: "FHIRHelpers",
                    version: "4.0.1"
                }
            ]
        },
        
        // 1.5 参数定义（稍后添加）
        parameters: {
            def: []
        },
        
        // 1.6 语句定义（核心逻辑）
        statements: {
            def: [
                // Patient语句（必需）
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

console.log('✓ 基本骨架包含：');
console.log('  - identifier: 库名和版本');
console.log('  - schemaIdentifier: ELM标准');
console.log('  - usings: FHIR 4.0.1');
console.log('  - includes: FHIRHelpers');
console.log('  - parameters: 参数列表');
console.log('  - statements: 逻辑定义');

// ============================================================================
// 第2课：添加参数 (parameter)
// ============================================================================
console.log('\n【第2课】添加参数');
console.log('-'.repeat(70));

// 2.1 DateTime参数（带默认值）
elm.library.parameters.def.push({
    name: "MeasurementPeriodStart",
    accessLevel: "Public",
    default: {
        type: "DateTime",
        value: "@2026-01-01T00:00:00.0+08:00"
    },
    parameterTypeSpecifier: {
        type: "NamedTypeSpecifier",
        name: "{urn:hl7-org:elm-types:r1}DateTime"
    }
});

console.log('✓ 参数结构：');
console.log('  - name: 参数名称');
console.log('  - accessLevel: Public');
console.log('  - default: 默认值（可选）');
console.log('  - parameterTypeSpecifier: 类型定义');

// 2.2 第二个参数
elm.library.parameters.def.push({
    name: "MeasurementPeriodEnd",
    accessLevel: "Public",
    default: {
        type: "DateTime",
        value: "@2026-03-31T23:59:59.0+08:00"
    },
    parameterTypeSpecifier: {
        type: "NamedTypeSpecifier",
        name: "{urn:hl7-org:elm-types:r1}DateTime"
    }
});

console.log('✓ 已添加2个DateTime参数');

// ============================================================================
// 第3课：创建Interval（日期区间）
// ============================================================================
console.log('\n【第3课】创建日期区间');
console.log('-'.repeat(70));

elm.library.statements.def.push({
    name: "Measurement Period",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        type: "Interval",           // 重要：Interval类型
        low: {
            name: "MeasurementPeriodStart",
            type: "ParameterRef"    // 引用参数
        },
        high: {
            name: "MeasurementPeriodEnd",
            type: "ParameterRef"
        }
    }
});

console.log('✓ Interval表达式：');
console.log('  - type: "Interval"');
console.log('  - low: 起始值（ParameterRef）');
console.log('  - high: 结束值（ParameterRef）');

// ============================================================================
// 第4课：Retrieve（查询FHIR资源）
// ============================================================================
console.log('\n【第4课】查询FHIR资源（Retrieve）');
console.log('-'.repeat(70));

elm.library.statements.def.push({
    name: "All Encounters",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        dataType: "{http://hl7.org/fhir}Encounter",  // FHIR资源类型
        type: "Retrieve"                              // Retrieve操作
    }
});

console.log('✓ Retrieve表达式：');
console.log('  - dataType: FHIR资源类型（如Encounter）');
console.log('  - type: "Retrieve"');
console.log('  - 自动关联到当前Patient');

// ============================================================================
// 第5课：Query with Where（条件查询）
// ============================================================================
console.log('\n【第5课】带条件的查询（Query）');
console.log('-'.repeat(70));

elm.library.statements.def.push({
    name: "Encounters During Period",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        type: "Query",
        source: [
            {
                alias: "E",                          // 别名
                expression: {
                    dataType: "{http://hl7.org/fhir}Encounter",
                    type: "Retrieve"
                }
            }
        ],
        relationship: [],
        where: {
            type: "And",                             // 多个条件用And
            operand: [
                // 条件1: E.period during "Measurement Period"
                {
                    type: "IncludedIn",              // during操作符
                    operand: [
                        {
                            path: "period",          // E.period
                            scope: "E",              // 引用别名E
                            type: "Property"
                        },
                        {
                            name: "Measurement Period",
                            type: "ExpressionRef"    // 引用之前定义的表达式
                        }
                    ]
                },
                // 条件2: E.status = 'finished'
                {
                    type: "Equal",
                    operand: [
                        {
                            path: "status",
                            scope: "E",
                            type: "Property"
                        },
                        {
                            valueType: "{urn:hl7-org:elm-types:r1}String",
                            value: "finished",
                            type: "Literal"
                        }
                    ]
                }
            ]
        }
    }
});

console.log('✓ Query结构：');
console.log('  - source: 数据源（Retrieve + alias）');
console.log('  - where: 过滤条件');
console.log('    * And: 多条件组合');
console.log('    * IncludedIn: during操作');
console.log('    * Equal: 相等比较');
console.log('    * Property: 访问属性（E.period）');
console.log('    * ExpressionRef: 引用其他定义');

// ============================================================================
// 第6课：Count（计数）
// ============================================================================
console.log('\n【第6课】计数（Count）');
console.log('-'.repeat(70));

elm.library.statements.def.push({
    name: "Encounter Count",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        type: "Count",
        source: {
            name: "Encounters During Period",
            type: "ExpressionRef"
        }
    }
});

console.log('✓ Count表达式：');
console.log('  - type: "Count"');
console.log('  - source: 要计数的表达式（ExpressionRef）');

// ============================================================================
// 第7课：保存和验证
// ============================================================================
console.log('\n【第7课】保存和验证');
console.log('-'.repeat(70));

const outputDir = 'ELM_JSON_OFFICIAL/中醫';
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

const outputFile = path.join(outputDir, 'Indicator_TCM_Same_Day_Revisit_Rate_教学版.json');
fs.writeFileSync(outputFile, JSON.stringify(elm, null, 2), 'utf-8');

console.log(`✓ 已保存: ${outputFile}`);
console.log(`  大小: ${(fs.statSync(outputFile).size / 1024).toFixed(2)} KB`);

// ============================================================================
// 总结：常用表达式类型速查表
// ============================================================================
console.log('\n' + '='.repeat(70));
console.log(' 常用表达式类型速查表');
console.log('='.repeat(70));

const expressionTypes = {
    '数据查询': {
        'Retrieve': '查询FHIR资源',
        'Query': '条件查询',
        'Property': '访问属性（E.field）'
    },
    '逻辑运算': {
        'And': '与运算',
        'Or': '或运算',
        'Not': '非运算'
    },
    '比较运算': {
        'Equal': '等于 =',
        'Greater': '大于 >',
        'GreaterOrEqual': '大于等于 >=',
        'Less': '小于 <',
        'IncludedIn': 'during（包含于）'
    },
    '聚合函数': {
        'Count': '计数',
        'Sum': '求和',
        'Avg': '平均',
        'Min': '最小',
        'Max': '最大'
    },
    '数据结构': {
        'Interval': '区间',
        'List': '列表',
        'Tuple': '元组（对象）'
    },
    '引用': {
        'ParameterRef': '引用参数',
        'ExpressionRef': '引用表达式',
        'FunctionRef': '调用函数'
    },
    '其他': {
        'Literal': '字面量',
        'SingletonFrom': '单值提取',
        'Exists': '存在性检查'
    }
};

for (const [category, types] of Object.entries(expressionTypes)) {
    console.log(`\n${category}:`);
    for (const [type, desc] of Object.entries(types)) {
        console.log(`  ${type.padEnd(20)} - ${desc}`);
    }
}

// ============================================================================
// 练习题
// ============================================================================
console.log('\n' + '='.repeat(70));
console.log(' 练习题：完成其他7个中医指标');
console.log('='.repeat(70));

console.log('\n1. Indicator_TCM_Monthly_Visit_8_Or_More_Times_Rate');
console.log('   提示：需要Count > 8的条件');

console.log('\n2. Indicator_TCM_Medication_Overlap_2_Days_Or_More_Rate');
console.log('   提示：需要日期重叠计算（Interval overlap）');

console.log('\n3. Indicator_TCM_Traumatology_Rate');
console.log('   提示：需要检查Procedure代码（E01-E12, F01-F68）');

console.log('\n4-8. 其他Program Organization List指标');
console.log('   提示：结构类似，主要是CodeSystem和条件不同');

console.log('\n验证命令:');
console.log('node verify_elm_quality.js "' + outputFile + '"');

console.log('\n下一步: 运行此脚本学习，然后修改创建其他指标');
