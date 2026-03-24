#!/usr/bin/env python3
"""
分析降血压药物编码系统使用情况
展示健保代号 + ATC代号混合使用的最佳实践
"""

import json

# 示例1: 当前ELM JSON使用的逻辑（仅ATC）
print("=" * 80)
print("【当前指标1710使用的编码方式】仅ATC代码")
print("=" * 80)

current_approach = """
CodeSystem: "ATC" = 'http://www.whocc.no/atc'

逻辑:
1. 从MedicationRequest.medicationCodeableConcept.coding中提取ATC代码
2. 判断C开头 (C0xxx = 心血管系统药物)
3. 排除C01、C02A、C03开头的特定代码

问题:
❌ 如果医院只上传健保药品代号，无法匹配
❌ 依赖医院必须提供ATC编码
❌ 健保申报系统使用的是健保代号，需要额外转换
"""
print(current_approach)

# 示例2: 理想的FHIR资源结构（健保 + ATC双编码）
print("\n" + "=" * 80)
print("【推荐做法】健保代号 + ATC代号双编码")
print("=" * 80)

medication_request_best_practice = {
    "resourceType": "MedicationRequest",
    "id": "med-req-001",
    "status": "completed",
    "intent": "order",
    "medicationCodeableConcept": {
        "coding": [
            {
                "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
                "code": "AC123456100",
                "display": "某某降血压药 5mg"
            },
            {
                "system": "http://www.whocc.no/atc",
                "code": "C09AA05",
                "display": "ramipril (ACE inhibitor)"
            }
        ],
        "text": "Ramipril 5mg"
    },
    "subject": {"reference": "Patient/TW10001"},
    "encounter": {"reference": "Encounter/enc-001"},
    "dispenseRequest": {
        "validityPeriod": {
            "start": "2024-01-15T00:00:00+08:00",
            "end": "2024-02-13T23:59:59+08:00"
        }
    }
}

print(json.dumps(medication_request_best_practice, indent=2, ensure_ascii=False))

# 示例3: 不同阶段的医院数据状况
print("\n" + "=" * 80)
print("【实际应用场景】不同医院的编码完整度")
print("=" * 80)

scenarios = """
情境A: 仅健保代号（过渡期医院）
------------------------------------------------
"coding": [
  {
    "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
    "code": "AC123456100"
  }
]

⚠️ 当前指标1710无法识别此药品（需要ATC代码）


情境B: 仅ATC代号（国际标准导向医院）
------------------------------------------------
"coding": [
  {
    "system": "http://www.whocc.no/atc",
    "code": "C09AA05"
  }
]

✅ 当前指标1710可以识别
❌ 健保申报系统需要健保代号


情境C: 双编码（最佳实践）
------------------------------------------------
"coding": [
  {
    "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
    "code": "AC123456100"
  },
  {
    "system": "http://www.whocc.no/atc",
    "code": "C09AA05"
  }
]

✅ 当前指标1710可以识别（通过ATC）
✅ 健保申报系统可以使用（通过健保代号）
✅ 国际互操作性良好
✅ 未来扩展性强
"""
print(scenarios)

# 示例4: 改进后的CQL逻辑（支持健保+ATC）
print("\n" + "=" * 80)
print("【改进方案】CQL支持健保代号 + ATC代号 OR逻辑")
print("=" * 80)

improved_cql = """
// 定义编码系统
codesystem "NHI_MED": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code'
codesystem "ATC": 'http://www.whocc.no/atc'

// 定义降血压药品（健保代号）
valueset "NHI Antihypertensive Drugs": 'http://example.org/fhir/ValueSet/nhi-antihypertensive'
// 包含: AC123456100, AC789012300, BC456789200... (健保降血压药品代号清单)

// 定义降血压药品（ATC代号）
valueset "ATC Antihypertensive Drugs": 'http://example.org/fhir/ValueSet/atc-antihypertensive'
// 包含: C02*, C03*, C07*, C08*, C09* (WHO ATC降血压药分类)

// 改进后的查询逻辑
define "Antihypertensive Medications":
  [MedicationRequest] MR
  where 
    // 方式1: 使用健保代号
    exists (
      MR.medication.coding C
      where C in "NHI Antihypertensive Drugs"
    )
    or
    // 方式2: 使用ATC代号
    exists (
      MR.medication.coding C
      where C in "ATC Antihypertensive Drugs"
    )

优势:
✅ 兼容只有健保代号的医院
✅ 兼容只有ATC代号的医院
✅ 对双编码医院效率最优
✅ OR逻辑确保最大覆盖率
"""
print(improved_cql)

# 示例5: 实际查询FHIR服务器
print("\n" + "=" * 80)
print("【FHIR REST API查询】支持多编码系统")
print("=" * 80)

api_examples = """
查询方式1: 仅使用ATC代码（当前做法）
-----------------------------------------------
GET /MedicationRequest?code=http://www.whocc.no/atc|C09AA05

结果: 仅返回有ATC编码的记录


查询方式2: 仅使用健保代号
-----------------------------------------------
GET /MedicationRequest?code=https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code|AC123456100

结果: 仅返回有健保编码的记录


查询方式3: OR逻辑（推荐）
-----------------------------------------------
GET /MedicationRequest?code=AC123456100,C09AA05,BC456789200,C09CA01

结果: 返回任何一个代号匹配的记录（最大覆盖率）


查询方式4: 使用ValueSet（最佳实践）
-----------------------------------------------
GET /MedicationRequest?code:in=http://example.org/fhir/ValueSet/all-antihypertensive-drugs

其中ValueSet包含:
- 所有健保降血压药品代号
- 所有ATC降血压药品代号
"""
print(api_examples)

# 示例6: 降血压药物的实际编码对照表
print("\n" + "=" * 80)
print("【常见降血压药物编码对照】")
print("=" * 80)

medication_mapping = [
    {
        "药品名称": "Ramipril 5mg",
        "健保代号": "AC12345100",
        "ATC代号": "C09AA05",
        "分类": "ACE抑制剂"
    },
    {
        "药品名称": "Amlodipine 5mg",
        "健保代号": "AC23456100",
        "ATC代号": "C08CA01",
        "分类": "钙通道阻断剂"
    },
    {
        "药品名称": "Losartan 50mg",
        "健保代号": "BC34567100",
        "ATC代号": "C09CA01",
        "分类": "ARB"
    },
    {
        "药品名称": "Atenolol 50mg",
        "健保代号": "AC45678100",
        "ATC代号": "C07AB03",
        "分类": "Beta阻断剂"
    },
    {
        "药品名称": "Hydrochlorothiazide 25mg",
        "健保代号": "AC56789100",
        "ATC代号": "C03AA03",
        "分类": "利尿剂"
    }
]

print(f"{'药品名称':<25} {'健保代号':<15} {'ATC代号':<12} {'分类':<15}")
print("-" * 80)
for med in medication_mapping:
    print(f"{med['药品名称']:<25} {med['健保代号']:<15} {med['ATC代号']:<12} {med['分类']:<15}")

# 总结
print("\n" + "=" * 80)
print("【总结】")
print("=" * 80)

summary = """
问题: "所以像这一类型的都有健保代号+其他FHIR代号?"

答案: 
1. ✅ 理论上应该有（最佳实践）
   - 药品应该包含健保代号（NHI medication code）
   - 药品应该包含ATC代号（WHO标准）
   - 一个MedicationRequest.medicationCodeableConcept.coding[]数组可包含多个编码

2. ❌ 实际上不一定都有（取决于医院）
   - 有些医院只上传健保代号（满足健保申报需求即可）
   - 有些医院只上传ATC代号（国际标准导向）
   - 完整双编码需要医院投入额外资源建立对照表

3. 📊 当前指标1710的状况
   - 仅检查ATC代码
   - 假设所有医院都提供ATC编码
   - 如果医院只有健保代号，无法被计算

4. 🎯 改进建议
   - 扩展CQL逻辑支持健保代号 OR ATC代号
   - 建立健保代号<->ATC代号对照ValueSet
   - 鼓励医院提供双编码（过渡期可接受单一编码）
   - 长期目标：所有药品都应该有双编码

5. 📋 其他资源类型
   - Condition: 健保诊断代号 + ICD-10-CM + SNOMED CT
   - Procedure: 健保处置代号 + SNOMED CT + CPT
   - Observation: 健保检验代号 + LOINC
   
   所有临床资源都应遵循"健保代号 + 国际标准"双编码原则！
"""
print(summary)
