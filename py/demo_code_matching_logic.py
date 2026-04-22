#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
演示：精确代码匹配 vs 文本搜索的差异
"""

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 80)
print("代码匹配逻辑对比")
print("=" * 80)

# 方式1: 精确代码匹配（ELM JSON的逻辑）
print("\n【方式1】精确代码匹配 (ELM逻辑)")
print("查询: code=http://hl7.org/fhir/sid/icd-10|U07.1")

try:
    response = requests.get(
        f"{FHIR_BASE_URL}/Condition",
        params={'code': 'http://hl7.org/fhir/sid/icd-10|U07.1'},
        verify=False,
        timeout=10
    )
    if response.status_code == 200:
        bundle = response.json()
        count = len(bundle.get('entry', []))
        print(f"结果: 找到 {count} 条记录")
        
        if count > 0:
            print("\n样本数据:")
            sample = bundle['entry'][0]['resource']
            print(f"  Patient: {sample.get('subject', {}).get('reference')}")
            for coding in sample.get('code', {}).get('coding', []):
                print(f"  - {coding.get('code')}: {coding.get('display')}")
    else:
        print(f"查询失败: {response.status_code}")
except Exception as e:
    print(f"错误: {e}")

# 方式2: 文本搜索（UI使用的方式）
print("\n【方式2】文本搜索 (UI逻辑)")
print("查询: code:text=COVID")

try:
    response = requests.get(
        f"{FHIR_BASE_URL}/Condition",
        params={'code:text': 'COVID'},
        verify=False,
        timeout=10
    )
    if response.status_code == 200:
        bundle = response.json()
        count = len(bundle.get('entry', []))
        print(f"结果: 找到 {count} 条记录")
        
        # 统计不同的代码
        codes = {}
        for entry in bundle.get('entry', []):
            for coding in entry['resource'].get('code', {}).get('coding', []):
                code = coding.get('code')
                display = coding.get('display')
                key = f"{code}|{display}"
                codes[key] = codes.get(key, 0) + 1
        
        print("\n代码分布:")
        for code_key, cnt in codes.items():
            parts = code_key.split('|')
            print(f"  [{cnt:2d}] {parts[0]}: {parts[1]}")
    else:
        print(f"查询失败: {response.status_code}")
except Exception as e:
    print(f"错误: {e}")

# 方式3: 多个代码的OR查询
print("\n【方式3】多代码OR查询 (ELM的完整逻辑)")
print("查询: code=U07.1,U07.2 (逗号分隔=OR)")

try:
    response = requests.get(
        f"{FHIR_BASE_URL}/Condition",
        params={'code': 'U07.1,U07.2'},
        verify=False,
        timeout=10
    )
    if response.status_code == 200:
        bundle = response.json()
        count = len(bundle.get('entry', []))
        print(f"结果: 找到 {count} 条记录")
    else:
        print(f"查询失败: {response.status_code}")
except Exception as e:
    print(f"错误: {e}")

print("\n" + "=" * 80)
print("总结")
print("=" * 80)

print("""
1. ELM的逻辑：
   - code.coding数组中，只要有**任何一个**coding匹配就算
   - 相当于: (code='U07.1' OR code='U07.2' OR code='840539006' OR ...)
   - 这是标准的FHIR匹配逻辑

2. code:text搜索：
   - 搜索display字段的文本内容
   - 只要display中**包含**'COVID'就匹配
   - 更灵活，但可能匹配到不想要的（如"COVID疫苗"）

3. 为什么我的原始脚本找不到：
   - 我遍历了前1000个Condition，但COVID数据可能在后面
   - 没有使用FHIR的参数化查询
   - 应该用: code:text='COVID' 或 code='U07.1,U07.2'

4. 最佳实践：
   - 精确匹配: 使用code参数 + 多个值（逗号分隔）
   - 模糊匹配: 使用code:text参数
   - ELM执行: 让FHIR服务器处理，会自动优化查询
""")
