/**
 * 手写ELM实战：完整8个中医指标
 * 
 * 学习步骤：
 * 1. 看示例1（已完成）理解结构
 * 2. 解除示例2-8的注释
 * 3. 根据CQL文件补充逻辑
 * 4. 运行并验证
 */

const { ELMGenerator, indicators } = require('./generate_all_tcm_indicators.js');

console.log('='.repeat(70));
console.log(' 手写8个中医指标ELM - 实战版');
console.log('='.repeat(70));

// ============================================================================
// 示例1：同日重复就诊率 ✅ 已完成
// ============================================================================
console.log('\n✅ 指标1: 同日重复就诊率（已生成）\n');

// ============================================================================
// 示例2：每月就诊8次以上比率 - 你来完成！
// ============================================================================
console.log('📝 指标2: 每月就诊8次以上比率');
console.log('   任务：添加 > 8 的条件');

/*
const gen2 = new ELMGenerator(indicators[1]);

gen2
    .addDateTimeParameter('MeasurementPeriodStart', '@2026-01-01T00:00:00.0+08:00')
    .addDateTimeParameter('MeasurementPeriodEnd', '@2026-12-31T23:59:59.0+08:00')
    .addMeasurementPeriod();

// 步骤1: 查询所有encounter
const encounterWhere2 = gen2.createAndCondition(
    gen2.createDuringCondition('period', 'Measurement Period'),
    gen2.createEqualCondition('status', 'finished')
);

gen2.addEncounterQuery('All Encounters', encounterWhere2);

// 步骤2: 计数
gen2.addCount('Encounter Count', 'All Encounters');

// 步骤3: 添加 > 8 的条件（这里需要你补充）
// 提示：使用 Greater 表达式
gen2.elm.library.statements.def.push({
    name: "Has 8 Or More Visits",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        type: "GreaterOrEqual",  // >= 8
        operand: [
            {
                name: "Encounter Count",
                type: "ExpressionRef"
            },
            {
                valueType: "{urn:hl7-org:elm-types:r1}Integer",
                value: "8",
                type: "Literal"
            }
        ]
    }
});

const file2 = gen2.save('Indicator_TCM_Monthly_Visit_8_Or_More_Times_Rate.json');
console.log(`✓ 已保存: ${file2}`);
*/

console.log('   👆 解除注释并运行');

// ============================================================================
// 示例3：重复用药2天以上比率 - 复杂示例
// ============================================================================
console.log('\n📝 指标3: 重复用药2天以上比率');
console.log('   任务：检查MedicationRequest重叠');

/*
const gen3 = new ELMGenerator(indicators[2]);

gen3
    .addDateTimeParameter('MeasurementPeriodStart', '@2026-01-01T00:00:00.0+08:00')
    .addDateTimeParameter('MeasurementPeriodEnd', '@2026-03-31T23:59:59.0+08:00')
    .addMeasurementPeriod();

// 查询MedicationRequest
gen3.elm.library.statements.def.push({
    name: "All Medication Requests",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        type: "Query",
        source: [
            {
                alias: "M",
                expression: {
                    dataType: "{http://hl7.org/fhir}MedicationRequest",
                    type: "Retrieve"
                }
            }
        ],
        relationship: [],
        where: {
            type: "IncludedIn",
            operand: [
                {
                    // 这里需要获取MedicationRequest的日期范围
                    // 提示：查看FHIR MedicationRequest.dispenseRequest.validityPeriod
                    path: "dispenseRequest",
                    scope: "M",
                    type: "Property"
                },
                {
                    name: "Measurement Period",
                    type: "ExpressionRef"
                }
            ]
        }
    }
});

const file3 = gen3.save('Indicator_TCM_Medication_Overlap_2_Days_Or_More_Rate.json');
console.log(`✓ 已保存: ${file3}`);
*/

console.log('   👆 需要补充日期重叠逻辑');

// ============================================================================
// 示例4：中医伤科占率 - Code检查示例
// ============================================================================
console.log('\n📝 指标4: 中医伤科占率');
console.log('   任务：检查Procedure代码 E01-E12, F01-F68');

/*
const gen4 = new ELMGenerator(indicators[3]);

gen4
    .addDateTimeParameter('MeasurementPeriodStart', '@2026-01-01T00:00:00.0+08:00')
    .addDateTimeParameter('MeasurementPeriodEnd', '@2026-03-31T23:59:59.0+08:00')
    .addMeasurementPeriod();

// 查询Procedure
gen4.elm.library.statements.def.push({
    name: "Traumatology Procedures",
    context: "Patient",
    accessLevel: "Public",
    expression: {
        type: "Query",
        source: [
            {
                alias: "P",
                expression: {
                    dataType: "{http://hl7.org/fhir}Procedure",
                    type: "Retrieve"
                }
            }
        ],
        relationship: [],
        where: {
            type: "And",
            operand: [
                // 条件1: 时间范围
                {
                    type: "IncludedIn",
                    operand: [
                        {
                            path: "performed",
                            scope: "P",
                            type: "Property"
                        },
                        {
                            name: "Measurement Period",
                            type: "ExpressionRef"
                        }
                    ]
                },
                // 条件2: Code检查（需要你补充）
                // 提示：使用InValueSet或多个Equal组合
                {
                    type: "InValueSet",
                    code: {
                        path: "code",
                        scope: "P",
                        type: "Property"
                    },
                    valueset: {
                        name: "Traumatology Codes",  // 需要先定义ValueSet
                        type: "ValueSetRef"
                    }
                }
            ]
        }
    }
});

const file4 = gen4.save('Indicator_TCM_Traumatology_Rate.json');
console.log(`✓ 已保存: ${file4}`);
*/

console.log('   👆 需要补充Code ValueSet定义');

// ============================================================================
// 示例5-8：Program Organization List - 结构类似
// ============================================================================
console.log('\n📝 指标5-8: Program Organization List');
console.log('   任务：查询Organization资源并过滤');

/*
// 这4个指标结构类似，主要是过滤条件不同
for (let i = 4; i < 8; i++) {
    const gen = new ELMGenerator(indicators[i]);
    
    gen.addDateTimeParameter('MeasurementPeriodStart', '@2026-01-01T00:00:00.0+08:00')
       .addDateTimeParameter('MeasurementPeriodEnd', '@2026-12-31T23:59:59.0+08:00')
       .addMeasurementPeriod();
    
    // 查询Organization
    gen.elm.library.statements.def.push({
        name: "Organizations",
        context: "Patient",
        accessLevel: "Public",
        expression: {
            dataType: "{http://hl7.org/fhir}Organization",
            type: "Retrieve"
            // 提示：可能需要添加CodeFilter
        }
    });
    
    const filename = `${indicators[i].id}.json`;
    const file = gen.save(filename);
    console.log(`✓ 已保存: ${file}`);
}
*/

console.log('   👆 解除注释批量生成');

// ============================================================================
// 验证所有生成的文件
// ============================================================================
console.log('\n' + '='.repeat(70));
console.log(' 验证步骤');
console.log('='.repeat(70));

console.log('\n1. 解除注释需要的代码块');
console.log('2. 补充缺失的逻辑');
console.log('3. 运行: node elm_hands_on.js');
console.log('4. 验证每个文件:');
console.log('   node verify_elm_quality.js "ELM_JSON_OFFICIAL/中醫/[文件名].json"');

console.log('\n提示：');
console.log('- 简单指标（5-8）：主要是Retrieve + 简单过滤');
console.log('- 中等指标（1, 2）：需要Count和比较');
console.log('- 复杂指标（3, 4）：需要日期计算或Code检查');

console.log('\n需要帮助？查看：');
console.log('- elm_tutorial.js - 基础教学');
console.log('- CQL_vs_JSON对比示例.md - 语法对照');
console.log('- 常用表达式类型速查表（上面已显示）');
