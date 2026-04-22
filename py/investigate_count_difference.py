#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
深入调查：为什么code:text='COVID'只返回20条，但UI显示30条？
"""

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 80)
print("调查数据差异：20 vs 30")
print("=" * 80)

# 1. code:text搜索
print("\n[1] code:text='COVID' 查询")
response1 = requests.get(
    f"{FHIR_BASE_URL}/Condition",
    params={'code:text': 'COVID'},
    verify=False,
    timeout=10
)
bundle1 = response1.json()
patients1 = set()
codes1 = {}

for entry in bundle1.get('entry', []):
    c = entry['resource']
    patient_ref = c.get('subject', {}).get('reference', '')
    if patient_ref:
        patients1.add(patient_ref.split('/')[-1])
    
    for coding in c.get('code', {}).get('coding', []):
        code = coding.get('code')
        codes1[code] = codes1.get(code, 0) + 1

print(f"  找到: {len(bundle1.get('entry', []))} 条Condition")
print(f"  患者: {len(patients1)} 位")
print(f"  代码: {codes1}")

# 2. 精确代码查询 U07.1 OR U07.2
print("\n[2] code='U07.1,U07.2' 查询 (OR逻辑)")
response2 = requests.get(
    f"{FHIR_BASE_URL}/Condition",
    params={'code': 'U07.1,U07.2'},
    verify=False,
    timeout=10
)
bundle2 = response2.json()
patients2 = set()
codes2 = {}

for entry in bundle2.get('entry', []):
    c = entry['resource']
    patient_ref = c.get('subject', {}).get('reference', '')
    if patient_ref:
        patients2.add(patient_ref.split('/')[-1])
    
    for coding in c.get('code', {}).get('coding', []):
        code = coding.get('code')
        codes2[code] = codes2.get(code, 0) + 1

print(f"  找到: {len(bundle2.get('entry', []))} 条Condition")
print(f"  患者: {len(patients2)} 位")
print(f"  代码: {codes2}")

# 3. 分别查询U07.1和U07.2
print("\n[3] 分别查询 U07.1 和 U07.2")

response3a = requests.get(
    f"{FHIR_BASE_URL}/Condition",
    params={'code': 'U07.1'},
    verify=False,
    timeout=10
)
count_u071 = len(response3a.json().get('entry', []))

response3b = requests.get(
    f"{FHIR_BASE_URL}/Condition",
    params={'code': 'U07.2'},
    verify=False,
    timeout=10
)
count_u072 = len(response3b.json().get('entry', []))

print(f"  U07.1: {count_u071} 条")
print(f"  U07.2: {count_u072} 条")
print(f"  总计: {count_u071 + count_u072} 条")

# 4. 使用完整的system|code格式
print("\n[4] 使用完整system|code格式")

response4 = requests.get(
    f"{FHIR_BASE_URL}/Condition",
    params={'code': 'http://hl7.org/fhir/sid/icd-10|U07.1,http://hl7.org/fhir/sid/icd-10|U07.2'},
    verify=False,
    timeout=10
)
count4 = len(response4.json().get('entry', []))
print(f"  找到: {count4} 条")

# 5. 检查U07.2的display是否都包含COVID
print("\n[5] 检查U07.2的display字段")
response5 = requests.get(
    f"{FHIR_BASE_URL}/Condition",
    params={'code': 'U07.2', '_count': 100},
    verify=False,
    timeout=10
)
bundle5 = response5.json()

print(f"  U07.2 总数: {len(bundle5.get('entry', []))}")
if bundle5.get('entry'):
    print(f"  样本display:")
    for i, entry in enumerate(bundle5['entry'][:3], 1):
        for coding in entry['resource'].get('code', {}).get('coding', []):
            if coding.get('code') == 'U07.2':
                display = coding.get('display', 'N/A')
                print(f"    {i}. {display}")
                print(f"       包含'COVID': {'COVID' in display.upper()}")

print("\n" + "=" * 80)
print("分析结论")
print("=" * 80)

print(f"""
发现的差异：
- code:text='COVID': {len(bundle1.get('entry', []))} 条（只找到display包含'COVID'的）
- code='U07.1,U07.2': {len(bundle2.get('entry', []))} 条（精确代码匹配）
- 单独查询总和: {count_u071 + count_u072} 条

可能的原因：
1. FHIR服务器的分页限制（默认可能只返回20条）
2. U07.2的部分记录display可能不包含'COVID'文字
3. 需要使用_count参数获取更多结果

建议：
- ELM执行时使用精确代码匹配: code='U07.1' OR code='U07.2'
- 不要依赖code:text搜索（可能漏掉某些编码）
- 使用_count参数确保获取所有结果
""")

# 6. 验证：使用_count参数
print("\n[6] 验证：使用_count=100参数")
response6 = requests.get(
    f"{FHIR_BASE_URL}/Condition",
    params={'code:text': 'COVID', '_count': 100},
    verify=False,
    timeout=10
)
count6 = len(response6.json().get('entry', []))
print(f"  code:text='COVID' + _count=100: {count6} 条")

if count6 != 30:
    print(f"\n⚠ 即使加了_count参数，仍然不是30条")
    print(f"  这说明U07.2的某些记录display可能不包含'COVID'")
