#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
COVID-19 监测数据分析 - 使用正确的查询方式
使用 code:text='COVID' 参数
"""

import requests
import json
from datetime import datetime, timedelta
from collections import defaultdict
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

def fetch_covid_conditions():
    """使用code:text参数获取COVID诊断"""
    url = f"{FHIR_BASE_URL}/Condition"
    all_conditions = []
    
    try:
        response = requests.get(url, params={'code:text': 'COVID', '_count': 100}, 
                              verify=False, timeout=30)
        response.raise_for_status()
        bundle = response.json()
        
        if bundle.get('entry'):
            all_conditions = [entry['resource'] for entry in bundle['entry']]
                
    except Exception as e:
        print(f"获取Condition时出错: {e}")
    
    return all_conditions

def fetch_covid_observations():
    """使用code:text参数获取COVID实验室检测"""
    url = f"{FHIR_BASE_URL}/Observation"
    all_observations = []
    
    try:
        response = requests.get(url, params={'code:text': 'COVID', '_count': 100}, 
                              verify=False, timeout=30)
        if response.status_code == 200:
            bundle = response.json()
            if bundle.get('entry'):
                all_observations = [entry['resource'] for entry in bundle['entry']]
    except:
        pass
    
    return all_observations

def get_event_date(resource):
    """获取事件日期"""
    # 优先使用onsetDateTime，然后recordedDate
    return resource.get('onsetDateTime') or resource.get('recordedDate') or resource.get('issued')

def calculate_age(birth_date, event_date):
    """计算年龄"""
    if not birth_date or not event_date:
        return None
    try:
        birth = datetime.fromisoformat(birth_date.replace('Z', '+00:00'))
        event = datetime.fromisoformat(event_date[:10])
        age = event.year - birth.year
        if event.month < birth.month or (event.month == birth.month and event.day < birth.day):
            age -= 1
        return age
    except:
        return None

print("=" * 80)
print("COVID-19 监测数据分析 (使用正确查询)")
print("=" * 80)

# 1. 获取COVID诊断
print("\n[1] 获取COVID-19诊断...")
covid_conditions = fetch_covid_conditions()
print(f"找到 {len(covid_conditions)} 个COVID-19诊断")

if covid_conditions:
    # 显示代码分布
    code_dist = defaultdict(int)
    for c in covid_conditions:
        if c.get('code') and c['code'].get('coding'):
            for coding in c['code']['coding']:
                key = f"{coding.get('code')}|{coding.get('display')}"
                code_dist[key] += 1
    
    print("\n  代码分布:")
    for code_key, count in code_dist.items():
        parts = code_key.split('|')
        print(f"    {parts[0]}: {parts[1]} ({count}筆)")

# 2. 获取COVID实验室检测
print("\n[2] 获取COVID-19实验室检测...")
covid_labs = fetch_covid_observations()
print(f"找到 {len(covid_labs)} 个COVID-19实验室检测")

# 3. 合并事件
print("\n[3] 处理COVID-19事件...")
all_events = []

for c in covid_conditions:
    event_date = get_event_date(c)
    if not event_date:
        continue
    
    patient_ref = c.get('subject', {}).get('reference', '')
    patient_id = patient_ref.split('/')[-1] if patient_ref else None
    
    all_events.append({
        'eventDate': event_date,
        'patientId': patient_id,
        'eventType': 'Diagnosis',
        'resource': c
    })

for lab in covid_labs:
    event_date = get_event_date(lab)
    if not event_date:
        continue
    
    patient_ref = lab.get('subject', {}).get('reference', '')
    patient_id = patient_ref.split('/')[-1] if patient_ref else None
    
    all_events.append({
        'eventDate': event_date,
        'patientId': patient_id,
        'eventType': 'Laboratory',
        'resource': lab
    })

all_events.sort(key=lambda x: x['eventDate'])
print(f"总共 {len(all_events)} 个COVID-19事件")

# 4. 识别唯一病例（30天去重）
print("\n[4] 识别唯一COVID-19病例（30天去重）...")

unique_episodes = []
patient_first_event = {}

for event in all_events:
    patient_id = event['patientId']
    event_dt = datetime.fromisoformat(event['eventDate'][:10])
    
    if patient_id not in patient_first_event:
        # 首次出现的患者
        patient_first_event[patient_id] = event_dt
        unique_episodes.append(event)
    else:
        # 检查是否在30天窗口外
        first_event_dt = patient_first_event[patient_id]
        days_diff = (event_dt - first_event_dt).days
        
        if days_diff > 30:
            # 新的病例
            patient_first_event[patient_id] = event_dt
            unique_episodes.append(event)
        # 否则视为同一病例，跳过

print(f"识别出 {len(unique_episodes)} 个唯一COVID-19病例")

# 5. 获取患者信息
print("\n[5] 获取患者信息...")
patient_ids = list(set([e['patientId'] for e in unique_episodes]))
patients = {}

for patient_id in patient_ids:
    try:
        url = f"{FHIR_BASE_URL}/Patient/{patient_id}"
        response = requests.get(url, verify=False, timeout=10)
        if response.status_code == 200:
            patients[patient_id] = response.json()
    except:
        pass

print(f"获取到 {len(patients)} 位患者的详细信息")

# 6. 生成统计
print("\n[6] 生成统计分析...")

results = []
gender_stats = defaultdict(int)
age_groups = defaultdict(int)
event_type_stats = defaultdict(int)

for episode in unique_episodes:
    patient_id = episode['patientId']
    patient = patients.get(patient_id)
    
    # 性别
    gender = patient.get('gender', 'unknown') if patient else 'unknown'
    gender_stats[gender] += 1
    
    # 年龄
    birth_date = patient.get('birthDate') if patient else None
    age = calculate_age(birth_date, episode['eventDate'])
    if age is not None:
        if age < 18:
            age_groups['0-17'] += 1
        elif age < 45:
            age_groups['18-44'] += 1
        elif age < 65:
            age_groups['45-64'] += 1
        else:
            age_groups['65+'] += 1
    else:
        age_groups['Unknown'] += 1
    
    # 事件类型
    event_type_stats[episode['eventType']] += 1
    
    results.append({
        'patientID': patient_id,
        'eventDate': episode['eventDate'][:10],
        'age': age if age is not None else 'Unknown',
        'gender': gender,
        'eventType': episode['eventType']
    })

# 7. 打印报告
print("\n" + "=" * 80)
print("COVID-19 监测分析结果")
print("=" * 80)

print(f"\n总COVID-19病例数: {len(unique_episodes)}")
print(f"唯一患者数: {len(patient_ids)}")
print(f"平均每人: {len(unique_episodes)/len(patient_ids):.1f}筆病例")

if len(unique_episodes) > 0:
    print("\n按性别分布:")
    for gender, count in sorted(gender_stats.items(), key=lambda x: x[1], reverse=True):
        pct = count/len(unique_episodes)*100
        print(f"  - {gender}: {count} ({pct:.1f}%)")
    
    print("\n按年龄组分布:")
    for age_group, count in sorted(age_groups.items()):
        pct = count/len(unique_episodes)*100
        print(f"  - {age_group}: {count} ({pct:.1f}%)")
    
    print("\n按事件类型分布:")
    for evt_type, count in sorted(event_type_stats.items(), key=lambda x: x[1], reverse=True):
        pct = count/len(unique_episodes)*100
        print(f"  - {evt_type}: {count} ({pct:.1f}%)")
    
    print("\n前10个COVID-19病例:")
    print("-" * 80)
    print(f"{'患者ID':<15} {'日期':<12} {'年龄':<6} {'性别':<10} {'事件类型':<12}")
    print("-" * 80)
    
    for result in results[:10]:
        print(f"{result['patientID']:<15} {result['eventDate']:<12} {str(result['age']):<6} "
              f"{result['gender']:<10} {result['eventType']:<12}")

print("\n" + "=" * 80)
print("分析完成")
print("=" * 80)

# 对比UI
print("\n【对比UI显示】")
print(f"UI显示: 30位患者, 30筆诊断, 平均1.0")
print(f"脚本结果: {len(patient_ids)}位患者, {len(unique_episodes)}筆病例, 平均{len(unique_episodes)/len(patient_ids):.1f}")
if len(patient_ids) == 30:
    print("✓✓✓ 患者数完全匹配！")
