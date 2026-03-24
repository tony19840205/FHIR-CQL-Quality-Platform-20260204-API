#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
演示：健保代号 + FHIR代号 OR搜索
适用于台湾医疗系统的混合编码查询
"""

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 80)
print("健保代号 + FHIR代号 混合搜索示例")
print("=" * 80)

# 常见的台湾健保/FHIR混合编码场景
examples = {
    "COVID-19诊断": {
        "健保代号": ["A0991"],  # 假设的健保代号
        "ICD-10": ["U07.1", "U07.2"],
        "SNOMED": ["840539006"]
    },
    "糖尿病": {
        "健保代号": ["A181"],
        "ICD-10": ["E11.9"],
        "SNOMED": ["44054006"]
    },
    "高血压": {
        "健保代号": ["A269"],
        "ICD-10": ["I10"],
        "SNOMED": ["38341003"]
    }
}

print("\n【策略1】FHIR Condition的多编码系统设计\n")
print("一个Condition资源可以包含多个coding系统：")
print("""
{
  "resourceType": "Condition",
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/icd-10-cm-2021-tw",
        "code": "U07.1",
        "display": "COVID-19確診"
      },
      {
        "system": "http://snomed.info/sct",
        "code": "840539006", 
        "display": "Disease caused by SARS-CoV-2"
      },
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
        "code": "A0991",
        "display": "COVID-19(健保代号)"
      }
    ]
  }
}

✓ 只要匹配到任何一个coding，就算找到该Condition
""")

print("\n【策略2】FHIR查询的OR逻辑\n")

# 示例1: 使用code参数的逗号分隔（OR逻辑）
print("方式A: 多个code值用逗号分隔（标准FHIR OR查询）")
print("""
GET /Condition?code=U07.1,U07.2,840539006,A0991

含义：code = 'U07.1' OR code = 'U07.2' OR code = '840539006' OR code = 'A0991'
""")

# 示例2: 使用system|code格式（推荐）
print("方式B: 使用system|code格式（更精确）")
print("""
GET /Condition?code=http://hl7.org/fhir/sid/icd-10|U07.1,
                   http://snomed.info/sct|840539006,
                   https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code|A0991

优点：
- 明确指定编码系统，避免歧义
- 不同系统可能有相同的code值
""")

# 实际测试：查询高血压
print("\n【实际测试】查询高血压相关Condition\n")

test_queries = [
    ("ICD-10代号", {"code": "I10"}),
    ("SNOMED代号", {"code": "38341003"}),
    ("多代号OR查询", {"code": "I10,38341003"}),
    ("文本搜索", {"code:text": "Hypertension"}),
]

for name, params in test_queries:
    try:
        response = requests.get(
            f"{FHIR_BASE_URL}/Condition",
            params=params,
            verify=False,
            timeout=10
        )
        if response.status_code == 200:
            count = len(response.json().get('entry', []))
            print(f"  {name:20s}: {count:3d} 条记录")
        else:
            print(f"  {name:20s}: 查询失败 ({response.status_code})")
    except Exception as e:
        print(f"  {name:20s}: 错误 - {e}")

print("\n【策略3】CQL/ELM中的OR逻辑写法\n")
print("""
在CQL中定义多个代码系统：

define "NHI COVID Codes": {'A0991'}
define "ICD10 COVID Codes": {'U07.1', 'U07.2'} 
define "SNOMED COVID Codes": {'840539006'}

define "COVID19 Conditions":
  [Condition] C
  where exists (
    C.code.coding Coding
    where (
      Coding.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
        and Coding.code in "NHI COVID Codes"
    )
    or (
      Coding.system = 'http://hl7.org/fhir/sid/icd-10'
        and Coding.code in "ICD10 COVID Codes"
    )
    or (
      Coding.system = 'http://snomed.info/sct'
        and Coding.code in "SNOMED COVID Codes"
    )
  )

✓ 这样可以同时支持健保代号、ICD-10、SNOMED
✓ 符合任何一个系统的代号都会被匹配
""")

print("\n" + "=" * 80)
print("总结")
print("=" * 80)
print("""
1. ✓ 可以同时使用健保代号 + FHIR代号
   - FHIR设计就是支持多编码系统并存
   - 使用OR逻辑：符合任何一个就算

2. 查询方式：
   - 简单: code=A0991,U07.1,840539006
   - 精确: code=system1|code1,system2|code2
   - 文本: code:text=关键词

3. 优势：
   - 兼容性好：既支持传统健保系统，又符合国际FHIR标准
   - 灵活性高：医院可以逐步从健保代号迁移到ICD-10/SNOMED
   - 查全率高：不会因为编码系统不同而漏掉数据

4. 建议：
   - 在Condition资源中同时记录多个编码系统
   - CQL查询时使用OR逻辑覆盖所有可能的代号
   - 优先使用国际标准(ICD-10/SNOMED)，健保代号作为补充
""")
