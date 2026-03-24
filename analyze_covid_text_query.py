#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
详细检查code:text='COVID'找到的数据
"""

import requests
import json
from collections import defaultdict
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 80)
print("详细分析 code:text='COVID' 查询结果")
print("=" * 80)

# 使用code:text参数查询
print("\n[1] 使用 code:text='COVID' 查询Condition...")
try:
    url = f"{FHIR_BASE_URL}/Condition"
    all_covid_conditions = []
    next_url = url
    params = {'code:text': 'COVID', '_count': 100}
    
    while next_url:
        if next_url == url:
            response = requests.get(next_url, params=params, verify=False, timeout=30)
        else:
            response = requests.get(next_url, verify=False, timeout=30)
            
        if response.status_code == 200:
            bundle = response.json()
            if bundle.get('entry'):
                all_covid_conditions.extend([e['resource'] for e in bundle['entry']])
            
            # 查找下一页
            next_url = None
            if bundle.get('link'):
                for link in bundle['link']:
                    if link.get('relation') == 'next':
                        next_url = link.get('url')
                        break
        else:
            break
    
    print(f"总共找到 {len(all_covid_conditions)} 个COVID Condition")
    
    # 统计患者
    covid_patients = set()
    for c in all_covid_conditions:
        patient_ref = c.get('subject', {}).get('reference', '')
        if patient_ref:
            covid_patients.add(patient_ref.split('/')[-1])
    
    print(f"唯一患者数: {len(covid_patients)}")
    print(f"平均每人: {len(all_covid_conditions)/len(covid_patients):.1f}筆" if covid_patients else "N/A")
    
    # 检查encounter引用
    with_encounter = sum(1 for c in all_covid_conditions if c.get('encounter'))
    print(f"有Encounter引用: {with_encounter}")
    print(f"无Encounter引用: {len(all_covid_conditions) - with_encounter}")
    
    # 显示代码详情
    print("\n[2] 代码详情:")
    code_stats = defaultdict(int)
    for c in all_covid_conditions:
        if c.get('code') and c['code'].get('coding'):
            for coding in c['code']['coding']:
                key = f"{coding.get('system', 'unknown')}|{coding.get('code')}|{coding.get('display')}"
                code_stats[key] += 1
    
    print("  代码分布:")
    for code_key, count in sorted(code_stats.items(), key=lambda x: x[1], reverse=True):
        parts = code_key.split('|')
        print(f"    [{count:2d}] {parts[2]}")
        print(f"         System: {parts[0]}")
        print(f"         Code: {parts[1]}")
    
    # 显示样本数据
    if all_covid_conditions:
        print("\n[3] 样本Condition详情:")
        for i, c in enumerate(all_covid_conditions[:3], 1):
            print(f"\n  样本 {i}:")
            print(f"    ID: {c.get('id')}")
            print(f"    Patient: {c.get('subject', {}).get('reference')}")
            print(f"    Encounter: {c.get('encounter', {}).get('reference', 'None')}")
            print(f"    RecordedDate: {c.get('recordedDate', 'None')}")
            print(f"    OnsetDateTime: {c.get('onsetDateTime', 'None')}")
            print(f"    ClinicalStatus: {c.get('clinicalStatus')}")
            
            if c.get('code'):
                print(f"    Codes:")
                for coding in c['code'].get('coding', []):
                    print(f"      - {coding.get('display')}")
                    print(f"        {coding.get('system')} | {coding.get('code')}")
    
    # 患者列表
    print(f"\n[4] COVID患者ID列表 (前30个):")
    for i, patient_id in enumerate(sorted(covid_patients)[:30], 1):
        print(f"  {i:2d}. {patient_id}")
    
    # 对比UI显示
    print("\n" + "=" * 80)
    print("对比UI显示")
    print("=" * 80)
    print(f"UI显示:")
    print(f"  - 总患者数: 30")
    print(f"  - 诊断记录: 30")
    print(f"  - 就诊记录: 0")
    print(f"  - 平均每人: 1.0")
    
    print(f"\n实际查询结果:")
    print(f"  - 总患者数: {len(covid_patients)}")
    print(f"  - 诊断记录: {len(all_covid_conditions)}")
    print(f"  - 就诊记录: {with_encounter}")
    print(f"  - 平均每人: {len(all_covid_conditions)/len(covid_patients):.1f}" if covid_patients else "N/A")
    
    if len(covid_patients) == 30 and len(all_covid_conditions) == 30:
        print("\n✓✓✓ 完全匹配！UI使用的就是 code:text='COVID' 查询！")
    elif len(covid_patients) == 30:
        print(f"\n⚠ 患者数匹配，但诊断记录数不同 ({len(all_covid_conditions)} vs 30)")
    else:
        print(f"\n⚠ 数字不完全匹配，可能UI有额外的过滤条件")
    
    # 生成JSON报告
    report = {
        'query_method': "code:text='COVID'",
        'total_conditions': len(all_covid_conditions),
        'unique_patients': len(covid_patients),
        'avg_per_patient': round(len(all_covid_conditions)/len(covid_patients), 1) if covid_patients else 0,
        'with_encounter': with_encounter,
        'without_encounter': len(all_covid_conditions) - with_encounter,
        'patient_ids': sorted(covid_patients),
        'codes_used': list(code_stats.keys())
    }
    
    with open('COVID_DATA_ANALYSIS.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n详细报告已保存至: COVID_DATA_ANALYSIS.json")

except Exception as e:
    print(f"查询出错: {e}")
    import traceback
    traceback.print_exc()
