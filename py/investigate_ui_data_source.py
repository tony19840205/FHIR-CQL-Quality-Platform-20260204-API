#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
尝试找出UI显示30个COVID患者的查询方式
可能性：
1. 使用特定的_filter参数
2. 查询特定的Patient Group
3. 使用category字段筛选
4. 后端计算逻辑不同
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 80)
print("尝试重现UI的30位COVID患者查询")
print("=" * 80)

# 策略1: 检查是否有特定的测试患者ID
print("\n[策略1] 检查是否有特定的测试患者...")
test_patient_ids = [f"TW{i:05d}" for i in range(10001, 10031)]  # TW10001-TW10030

conditions_found = 0
patients_found = set()

for patient_id in test_patient_ids[:5]:  # 先测试前5个
    try:
        url = f"{FHIR_BASE_URL}/Condition"
        response = requests.get(url, params={'subject': f"Patient/{patient_id}"}, 
                              verify=False, timeout=10)
        if response.status_code == 200:
            bundle = response.json()
            if bundle.get('entry'):
                print(f"  ✓ 找到患者 {patient_id} 的Condition")
                conditions_found += len(bundle['entry'])
                patients_found.add(patient_id)
    except:
        pass

if patients_found:
    print(f"\n找到 {len(patients_found)} 个测试患者, {conditions_found} 条Condition")
else:
    print("  ✗ 未找到TW开头的测试患者")

# 策略2: 检查Condition的category字段
print("\n[策略2] 检查Condition的category字段...")
try:
    url = f"{FHIR_BASE_URL}/Condition"
    response = requests.get(url, params={'_count': 100}, verify=False, timeout=10)
    if response.status_code == 200:
        bundle = response.json()
        if bundle.get('entry'):
            categories = set()
            for entry in bundle['entry']:
                c = entry['resource']
                if c.get('category'):
                    for cat in c['category']:
                        if cat.get('coding'):
                            for coding in cat['coding']:
                                categories.add(f"{coding.get('system')}|{coding.get('code')}")
            
            if categories:
                print(f"  找到 {len(categories)} 种category:")
                for cat in list(categories)[:10]:
                    print(f"    - {cat}")
            else:
                print("  ✗ Condition资源没有category字段")
except Exception as e:
    print(f"  ✗ 查询出错: {e}")

# 策略3: 检查是否有Group资源
print("\n[策略3] 检查是否有COVID患者组...")
try:
    url = f"{FHIR_BASE_URL}/Group"
    response = requests.get(url, params={'_count': 10}, verify=False, timeout=10)
    if response.status_code == 200:
        bundle = response.json()
        if bundle.get('entry'):
            print(f"  找到 {len(bundle['entry'])} 个Group资源")
            for entry in bundle['entry']:
                group = entry['resource']
                print(f"    - {group.get('id')}: {group.get('name', 'N/A')}")
        else:
            print("  ✗ 未找到Group资源")
    else:
        print(f"  ✗ Group资源查询失败: {response.status_code}")
except Exception as e:
    print(f"  ✗ 查询出错: {e}")

# 策略4: 直接查询可能的COVID测试数据文件中的患者
print("\n[策略4] 检查工作区中的COVID测试数据文件...")
import os
import glob

test_data_files = glob.glob("*covid*.json") + glob.glob("*COVID*.json")
if test_data_files:
    print(f"  找到 {len(test_data_files)} 个可能的测试数据文件:")
    for f in test_data_files[:5]:
        print(f"    - {f}")
        try:
            with open(f, 'r', encoding='utf-8') as file:
                data = json.load(file)
                if data.get('resourceType') == 'Bundle':
                    entries = data.get('entry', [])
                    patients = [e for e in entries if e.get('resource', {}).get('resourceType') == 'Patient']
                    conditions = [e for e in entries if e.get('resource', {}).get('resourceType') == 'Condition']
                    print(f"      包含: {len(patients)} 患者, {len(conditions)} Condition")
        except:
            pass
else:
    print("  ✗ 工作区未找到COVID测试数据文件")

# 策略5: 检查UI可能使用的参数化查询
print("\n[策略5] 尝试常见的参数化查询...")
query_attempts = [
    {'code': 'http://snomed.info/sct|840539006'},  # COVID-19
    {'code': '840539006'},
    {'code:text': 'COVID'},
    {'code:text': 'coronavirus'},
    {'_filter': 'code eq http://snomed.info/sct|840539006'},
]

for params in query_attempts:
    try:
        url = f"{FHIR_BASE_URL}/Condition"
        response = requests.get(url, params=params, verify=False, timeout=10)
        if response.status_code == 200:
            bundle = response.json()
            if bundle.get('entry'):
                print(f"  ✓ 查询成功: {params}")
                print(f"    找到 {len(bundle['entry'])} 条记录")
                break
    except:
        pass
else:
    print("  ✗ 所有参数化查询均未返回结果")

print("\n" + "=" * 80)
print("分析总结")
print("=" * 80)
print("""
UI显示的30位患者、30筆诊断可能来自：
1. 【最可能】特定的测试数据集（未上传到主FHIR服务器）
2. UI使用本地JSON文件或测试数据库
3. UI连接到开发环境的FHIR服务器（不同URL）
4. 后端在Condition上传后进行了额外的标记/分类

建议：
- 检查UI的网络请求，查看实际的API调用
- 查看是否有专门的COVID测试数据文件
- 确认UI和我们的脚本使用的是同一个FHIR endpoint
""")
