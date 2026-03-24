#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查FHIR服务器上的代码分布
"""

import requests
import json
from collections import defaultdict
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

def fetch_resources(resource_type, count=100):
    """获取资源"""
    url = f"{FHIR_BASE_URL}/{resource_type}"
    try:
        response = requests.get(url, params={'_count': count}, verify=False, timeout=30)
        response.raise_for_status()
        bundle = response.json()
        if bundle.get('entry'):
            return [entry['resource'] for entry in bundle['entry']]
    except Exception as e:
        print(f"Error: {e}")
    return []

print("=" * 80)
print("FHIR服务器代码分布检查")
print("=" * 80)

# 检查Condition
print("\n[1] 检查前100个Condition资源的代码...")
conditions = fetch_resources('Condition', 100)
print(f"获取到 {len(conditions)} 个Condition")

condition_codes = defaultdict(int)
condition_systems = defaultdict(int)
for c in conditions:
    if c.get('code') and c['code'].get('coding'):
        for coding in c['code']['coding']:
            system = coding.get('system', 'unknown')
            code = coding.get('code', 'unknown')
            display = coding.get('display', 'N/A')
            
            condition_systems[system] += 1
            condition_codes[f"{system}|{code}|{display}"] += 1

print("\n  系统分布:")
for system, count in sorted(condition_systems.items(), key=lambda x: x[1], reverse=True)[:10]:
    print(f"    {system}: {count}")

print("\n  前20个最常见的代码:")
for code_info, count in sorted(condition_codes.items(), key=lambda x: x[1], reverse=True)[:20]:
    parts = code_info.split('|')
    system = parts[0][-40:] if len(parts[0]) > 40 else parts[0]
    print(f"    [{count:3d}] {system} | {parts[1]} | {parts[2][:40]}")

# 检查是否有COVID相关代码
print("\n  COVID相关代码检查:")
covid_keywords = ['covid', 'coronavirus', 'sars', 'u07', '840539006']
covid_found = False
for code_info in condition_codes.keys():
    code_lower = code_info.lower()
    if any(kw in code_lower for kw in covid_keywords):
        print(f"    ✓ 找到: {code_info}")
        covid_found = True
if not covid_found:
    print("    ✗ 未找到COVID相关代码")

# 检查Observation
print("\n[2] 检查前100个Observation资源的代码...")
observations = fetch_resources('Observation', 100)
print(f"获取到 {len(observations)} 个Observation")

obs_codes = defaultdict(int)
obs_systems = defaultdict(int)
obs_status = defaultdict(int)
for o in observations:
    # 统计status
    status = o.get('status', 'unknown')
    obs_status[status] += 1
    
    if o.get('code') and o['code'].get('coding'):
        for coding in o['code']['coding']:
            system = coding.get('system', 'unknown')
            code = coding.get('code', 'unknown')
            display = coding.get('display', 'N/A')
            
            obs_systems[system] += 1
            obs_codes[f"{system}|{code}|{display}"] += 1

print("\n  Status分布:")
for status, count in sorted(obs_status.items(), key=lambda x: x[1], reverse=True):
    print(f"    {status}: {count}")

print("\n  系统分布:")
for system, count in sorted(obs_systems.items(), key=lambda x: x[1], reverse=True)[:10]:
    print(f"    {system}: {count}")

print("\n  前20个最常见的代码:")
for code_info, count in sorted(obs_codes.items(), key=lambda x: x[1], reverse=True)[:20]:
    parts = code_info.split('|')
    system = parts[0][-40:] if len(parts[0]) > 40 else parts[0]
    print(f"    [{count:3d}] {system} | {parts[1]} | {parts[2][:40]}")

# 检查是否有COVID相关代码
print("\n  COVID相关代码检查:")
covid_keywords = ['covid', 'coronavirus', 'sars', '94500', 'rna']
covid_found = False
for code_info in obs_codes.keys():
    code_lower = code_info.lower()
    if any(kw in code_lower for kw in covid_keywords):
        print(f"    ✓ 找到: {code_info}")
        covid_found = True
if not covid_found:
    print("    ✗ 未找到COVID相关代码")

print("\n" + "=" * 80)
print("检查完成")
print("=" * 80)
