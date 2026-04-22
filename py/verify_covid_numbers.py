#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
验证UI显示的COVID-19数字
UI显示: 30位患者, 30筆诊断记录, 0 Encounter资源, 平均每人1.0筆
"""

import requests
import json
from collections import defaultdict
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

def fetch_all_resources(resource_type, max_count=2000):
    """获取所有资源"""
    url = f"{FHIR_BASE_URL}/{resource_type}"
    all_resources = []
    
    try:
        while url and len(all_resources) < max_count:
            response = requests.get(url, params={'_count': 1000}, verify=False, timeout=30)
            response.raise_for_status()
            bundle = response.json()
            
            if bundle.get('entry'):
                all_resources.extend([entry['resource'] for entry in bundle['entry']])
            
            # 检查是否有下一页
            next_link = None
            if bundle.get('link'):
                for link in bundle['link']:
                    if link.get('relation') == 'next':
                        next_link = link.get('url')
                        break
            
            url = next_link
            
    except Exception as e:
        print(f"获取 {resource_type} 时出错: {e}")
    
    return all_resources

print("=" * 80)
print("验证COVID-19 UI显示数字")
print("=" * 80)

# 获取所有Condition
print("\n[1] 获取所有Condition资源...")
all_conditions = fetch_all_resources('Condition')
print(f"总Condition数: {len(all_conditions)}")

# 分析所有代码
print("\n[2] 分析Condition中的所有代码...")
code_distribution = defaultdict(int)
system_distribution = defaultdict(int)
patients_with_conditions = set()

for c in all_conditions:
    # 收集患者ID
    patient_ref = c.get('subject', {}).get('reference', '')
    if patient_ref:
        patient_id = patient_ref.split('/')[-1]
        patients_with_conditions.add(patient_id)
    
    # 收集代码
    if c.get('code') and c['code'].get('coding'):
        for coding in c['code']['coding']:
            system = coding.get('system', 'unknown')
            code = coding.get('code', 'unknown')
            display = coding.get('display', 'N/A')
            
            system_distribution[system] += 1
            code_key = f"{code}|{display}"
            code_distribution[code_key] += 1

print(f"\n有Condition的唯一患者数: {len(patients_with_conditions)}")

# 查找可能的COVID代码（任何包含COVID/coronavirus/SARS的）
print("\n[3] 查找可能的COVID相关代码...")
covid_related = []
covid_conditions = []

for c in all_conditions:
    if c.get('code') and c['code'].get('coding'):
        for coding in c['code']['coding']:
            code = coding.get('code', '')
            display = coding.get('display', '').lower()
            system = coding.get('system', '')
            
            # 检查是否包含COVID关键词
            if any(kw in display for kw in ['covid', 'coronavirus', 'sars-cov', 'u07']):
                covid_related.append({
                    'code': code,
                    'display': coding.get('display'),
                    'system': system,
                    'condition_id': c.get('id')
                })
                covid_conditions.append(c)

if covid_related:
    print(f"\n找到 {len(covid_related)} 个COVID相关的coding:")
    for cr in covid_related[:10]:
        print(f"  - {cr['system'][-40:]} | {cr['code']} | {cr['display']}")
    
    # 统计COVID患者
    covid_patients = set()
    for c in covid_conditions:
        patient_ref = c.get('subject', {}).get('reference', '')
        if patient_ref:
            covid_patients.add(patient_ref.split('/')[-1])
    
    print(f"\nCOVID相关统计:")
    print(f"  - COVID Condition记录数: {len(covid_conditions)}")
    print(f"  - COVID唯一患者数: {len(covid_patients)}")
    print(f"  - 平均每人: {len(covid_conditions)/len(covid_patients):.1f}" if covid_patients else "  - 平均每人: N/A")
    
    # 检查encounter引用
    conditions_with_encounter = sum(1 for c in covid_conditions if c.get('encounter'))
    print(f"  - 有Encounter引用的: {conditions_with_encounter}")
    print(f"  - 无Encounter引用的: {len(covid_conditions) - conditions_with_encounter}")
    
    # 显示样本数据
    if covid_conditions:
        print("\n样本Condition详情:")
        sample = covid_conditions[0]
        print(f"  ID: {sample.get('id')}")
        print(f"  Patient: {sample.get('subject', {}).get('reference')}")
        print(f"  Encounter: {sample.get('encounter', {}).get('reference', 'None')}")
        print(f"  RecordedDate: {sample.get('recordedDate', 'None')}")
        print(f"  ClinicalStatus: {sample.get('clinicalStatus')}")
        if sample.get('code'):
            print(f"  Codes:")
            for coding in sample['code'].get('coding', []):
                print(f"    - {coding.get('system')} | {coding.get('code')} | {coding.get('display')}")

else:
    print("✗ 未找到包含COVID关键词的代码")
    
    # 显示最常见的前30个代码
    print("\n最常见的30个Condition代码:")
    sorted_codes = sorted(code_distribution.items(), key=lambda x: x[1], reverse=True)
    for i, (code_key, count) in enumerate(sorted_codes[:30], 1):
        parts = code_key.split('|')
        print(f"  {i:2d}. [{count:3d}] {parts[0]:20s} | {parts[1][:50]}")

# 获取所有Observation
print("\n[4] 检查Observation资源...")
all_observations = fetch_all_resources('Observation')
print(f"总Observation数: {len(all_observations)}")

# 查找可能的COVID实验室检测
covid_obs = []
for o in all_observations:
    if o.get('code') and o['code'].get('coding'):
        for coding in o['code']['coding']:
            display = coding.get('display', '').lower()
            code = coding.get('code', '')
            
            if any(kw in display for kw in ['covid', 'coronavirus', 'sars-cov', '94500']):
                covid_obs.append(o)
                break

if covid_obs:
    print(f"找到 {len(covid_obs)} 个COVID相关Observation")
else:
    print("未找到COVID相关Observation")

# 获取Encounter信息
print("\n[5] 检查Encounter资源...")
all_encounters = fetch_all_resources('Encounter')
print(f"总Encounter数: {len(all_encounters)}")

# 如果找到了COVID conditions，检查它们关联的encounters
if covid_conditions:
    covid_encounter_refs = set()
    for c in covid_conditions:
        enc_ref = c.get('encounter', {}).get('reference')
        if enc_ref:
            covid_encounter_refs.add(enc_ref)
    
    print(f"COVID Conditions引用的唯一Encounter数: {len(covid_encounter_refs)}")

print("\n" + "=" * 80)
print("分析完成")
print("=" * 80)

# 生成摘要
print("\n【摘要对比UI显示】")
print(f"UI显示: 30位患者, 30筆诊断记录, 0 Encounter资源")
if covid_conditions:
    covid_patients = set()
    for c in covid_conditions:
        patient_ref = c.get('subject', {}).get('reference', '')
        if patient_ref:
            covid_patients.add(patient_ref.split('/')[-1])
    print(f"实际找到: {len(covid_patients)}位患者, {len(covid_conditions)}筆COVID诊断")
    print(f"匹配度: {'✓ 完全匹配!' if len(covid_patients)==30 and len(covid_conditions)==30 else '✗ 数字不匹配'}")
else:
    print("实际找到: 0位COVID患者")
    print("可能原因:")
    print("  1. UI使用的是特定患者群组或测试数据集")
    print("  2. UI连接到不同的FHIR endpoint")
    print("  3. UI使用的代码匹配逻辑不同（可能不依赖code.coding）")
    print("  4. 数据可能在Condition.category或其他字段中")
