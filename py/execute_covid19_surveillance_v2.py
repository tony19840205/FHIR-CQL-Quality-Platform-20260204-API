#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
COVID-19 监测数据分析脚本 V2
基于舊50/InfectiousDisease_COVID19_Surveillance.json ELM 逻辑
使用简化的代码匹配逻辑
"""

import requests
import json
from datetime import datetime, timedelta
from collections import defaultdict
import urllib3

# 禁用SSL警告
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# FHIR服务器配置
FHIR_BASE_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

# COVID-19 相关代码定义（基于舊50版本的简化定义）
COVID_CODES = {
    'ICD10': 'U07.1',  # COVID-19
    'SNOMED': '840539006',  # Disease caused by SARS-CoV-2
    'LOINC': '94500-6'  # SARS-CoV-2 RNA PCR
}

def fetch_fhir_resources(resource_type, params=None):
    """从FHIR服务器获取资源"""
    url = f"{FHIR_BASE_URL}/{resource_type}"
    all_resources = []
    
    try:
        while url:
            response = requests.get(url, params=params, verify=False, timeout=30)
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
            params = None  # 下一页URL已包含参数
            
            if len(all_resources) >= 1000:  # 限制最大数量
                break
                
    except Exception as e:
        print(f"获取 {resource_type} 时出错: {e}")
    
    return all_resources

def has_covid_code(coding_list, target_code, system_keyword):
    """检查coding列表中是否包含目标COVID代码"""
    if not coding_list:
        return False
    for coding in coding_list:
        code = coding.get('code')
        system = coding.get('system', '').lower()
        if code == target_code and system_keyword in system:
            return True
    return False

def is_covid_condition(condition):
    """判断是否为COVID-19诊断（简化版）"""
    if not condition.get('code') or not condition['code'].get('coding'):
        return False
    
    # 检查clinicalStatus是否存在
    if not condition.get('clinicalStatus'):
        return False
    
    coding_list = condition['code']['coding']
    
    # 检查ICD-10 U07.1或SNOMED 840539006
    return (has_covid_code(coding_list, COVID_CODES['ICD10'], 'icd-10') or 
            has_covid_code(coding_list, COVID_CODES['SNOMED'], 'snomed'))

def is_covid_lab(observation):
    """判断是否为COVID-19实验室检测（简化版 - 不检查阳性结果）"""
    if not observation.get('code') or not observation['code'].get('coding'):
        return False
    
    # 检查status是否为final或amended
    status = observation.get('status')
    if status not in ['final', 'amended']:
        return False
    
    coding_list = observation['code']['coding']
    
    # 只检查LOINC 94500-6代码
    return has_covid_code(coding_list, COVID_CODES['LOINC'], 'loinc')

def get_event_date(resource, resource_type):
    """获取事件日期"""
    if resource_type == 'Condition':
        return resource.get('recordedDate')
    elif resource_type == 'Observation':
        return resource.get('issued')
    return None

def get_encounter_reference(resource):
    """获取encounter引用"""
    encounter = resource.get('encounter', {})
    reference = encounter.get('reference')
    if reference:
        return reference  # 返回完整引用如 "Encounter/123"
    return None

def calculate_age(birth_date, event_date):
    """计算事件发生时的年龄"""
    if not birth_date or not event_date:
        return None
    try:
        birth = datetime.fromisoformat(birth_date.replace('Z', '+00:00'))
        event = datetime.fromisoformat(event_date.replace('Z', '+00:00'))
        age = event.year - birth.year
        if event.month < birth.month or (event.month == birth.month and event.day < birth.day):
            age -= 1
        return age
    except:
        return None

def get_encounter_type(encounter):
    """获取就诊类型"""
    if not encounter:
        return "Unknown"
    
    class_code = encounter.get('class', {}).get('code', '')
    
    if class_code == 'IMP':
        return "Inpatient"
    elif class_code == 'EMER':
        return "Emergency"
    elif class_code == 'AMB':
        return "Outpatient"
    else:
        return "Other"

def get_code_display(coding_list):
    """从coding列表中提取显示名称"""
    if not coding_list:
        return None
    return coding_list[0].get('display') if coding_list else None

def main():
    print("=" * 80)
    print("COVID-19 监测数据分析 V2 (简化版)")
    print("=" * 80)
    
    # 1. 获取FHIR资源
    print("\n[1] 正在获取FHIR资源...")
    
    print("  - 获取 Condition 资源...")
    conditions = fetch_fhir_resources('Condition', {'_count': 1000})
    print(f"    找到 {len(conditions)} 个 Condition 资源")
    
    print("  - 获取 Observation 资源...")
    observations = fetch_fhir_resources('Observation', {'_count': 1000})
    print(f"    找到 {len(observations)} 个 Observation 资源")
    
    print("  - 获取 Encounter 资源...")
    encounters = fetch_fhir_resources('Encounter', {'_count': 1000})
    print(f"    找到 {len(encounters)} 个 Encounter 资源")
    
    print("  - 获取 Patient 资源...")
    patients = fetch_fhir_resources('Patient', {'_count': 1000})
    print(f"    找到 {len(patients)} 个 Patient 资源")
    
    # 构建索引
    encounter_map = {}
    for e in encounters:
        # 同时支持ID和完整引用
        encounter_map[e['id']] = e
        encounter_map[f"Encounter/{e['id']}"] = e
    
    patient_map = {p['id']: p for p in patients}
    
    # 2. 识别COVID-19事件
    print("\n[2] 识别COVID-19事件...")
    print(f"  - 查找代码: ICD-10={COVID_CODES['ICD10']}, SNOMED={COVID_CODES['SNOMED']}, LOINC={COVID_CODES['LOINC']}")
    
    covid_conditions = [c for c in conditions if is_covid_condition(c)]
    print(f"  - 找到 {len(covid_conditions)} 个COVID-19诊断")
    
    # 显示前3个诊断的详细信息
    if covid_conditions:
        print("\n  前3个COVID-19诊断示例:")
        for i, c in enumerate(covid_conditions[:3]):
            codes = [f"{cd.get('system', 'N/A')[:30]}|{cd.get('code')}" 
                    for cd in c.get('code', {}).get('coding', [])]
            print(f"    {i+1}. ID={c.get('id')}, codes={codes}")
    
    covid_labs = [o for o in observations if is_covid_lab(o)]
    print(f"  - 找到 {len(covid_labs)} 个COVID-19实验室检测 (status=final/amended)")
    
    # 显示前3个实验室检测的详细信息
    if covid_labs:
        print("\n  前3个COVID-19实验室检测示例:")
        for i, lab in enumerate(covid_labs[:3]):
            codes = [f"{cd.get('system', 'N/A')[:30]}|{cd.get('code')}" 
                    for cd in lab.get('code', {}).get('coding', [])]
            status = lab.get('status')
            value = lab.get('valueCodeableConcept', {}).get('coding', [{}])[0].get('display', 'N/A')
            print(f"    {i+1}. ID={lab.get('id')}, codes={codes}, status={status}, value={value}")
    
    # 3. 合并所有COVID-19事件
    print("\n[3] 处理COVID-19事件...")
    all_events = []
    
    # 处理诊断
    for condition in covid_conditions:
        event_date = get_event_date(condition, 'Condition')
        if not event_date:
            continue
        
        patient_ref = condition.get('subject', {}).get('reference', '')
        patient_id = patient_ref.split('/')[-1] if patient_ref else None
        
        encounter_id = get_encounter_reference(condition)
        
        all_events.append({
            'eventDate': event_date,
            'patientId': patient_id,
            'encounterId': encounter_id,
            'eventType': 'Diagnosis',
            'code': condition.get('code'),
            'resource': condition
        })
    
    # 处理实验室检测
    for lab in covid_labs:
        event_date = get_event_date(lab, 'Observation')
        if not event_date:
            continue
        
        patient_ref = lab.get('subject', {}).get('reference', '')
        patient_id = patient_ref.split('/')[-1] if patient_ref else None
        
        encounter_id = get_encounter_reference(lab)
        
        all_events.append({
            'eventDate': event_date,
            'patientId': patient_id,
            'encounterId': encounter_id,
            'eventType': 'Laboratory',
            'code': lab.get('code'),
            'resource': lab
        })
    
    # 按日期排序
    all_events.sort(key=lambda x: x['eventDate'])
    print(f"  - 总共 {len(all_events)} 个COVID-19事件")
    
    # 4. 识别唯一病例（30天内的重复事件视为同一病例 - 基于舊50逻辑）
    print("\n[4] 识别唯一COVID-19病例（30天去重）...")
    
    unique_episodes = []
    processed_events = set()
    
    for i, event in enumerate(all_events):
        if i in processed_events:
            continue
        
        event_dt = datetime.fromisoformat(event['eventDate'].replace('Z', '+00:00'))
        episode_window_start = event_dt - timedelta(days=30)
        
        # 标记此事件
        processed_events.add(i)
        
        # 查找之前30天内是否有相同患者的事件
        has_prior_event = False
        for j in range(i):
            if j in processed_events:
                continue
            
            other_event = all_events[j]
            if other_event['patientId'] != event['patientId']:
                continue
                
            other_dt = datetime.fromisoformat(other_event['eventDate'].replace('Z', '+00:00'))
            
            # 如果其他事件在当前事件之前且在30天窗口内
            if other_dt < event_dt and other_dt >= episode_window_start:
                has_prior_event = True
                break
        
        # 只有没有前置事件的才算唯一病例
        if not has_prior_event:
            unique_episodes.append({
                'episodeStartDate': event['eventDate'],
                'patientId': event['patientId'],
                'encounterId': event['encounterId'],
                'eventType': event['eventType'],
                'code': event['code']
            })
    
    print(f"  - 识别出 {len(unique_episodes)} 个唯一COVID-19病例")
    
    # 5. 生成详细报告
    print("\n[5] 生成分析报告...")
    
    results = []
    gender_stats = {'male': 0, 'female': 0, 'other': 0, 'unknown': 0}
    encounter_stats = {'Inpatient': 0, 'Outpatient': 0, 'Emergency': 0, 'Other': 0, 'Unknown': 0}
    event_type_stats = {'Diagnosis': 0, 'Laboratory': 0}
    age_groups = {'0-17': 0, '18-44': 0, '45-64': 0, '65+': 0, 'Unknown': 0}
    
    for episode in unique_episodes:
        patient_id = episode['patientId']
        patient = patient_map.get(patient_id)
        
        encounter_id = episode['encounterId']
        encounter = encounter_map.get(encounter_id) if encounter_id else None
        
        # 性别
        gender = patient.get('gender') if patient else None
        if gender == 'male':
            gender_stats['male'] += 1
        elif gender == 'female':
            gender_stats['female'] += 1
        elif gender:
            gender_stats['other'] += 1
        else:
            gender_stats['unknown'] += 1
        
        # 年龄
        birth_date = patient.get('birthDate') if patient else None
        age = calculate_age(birth_date, episode['episodeStartDate'])
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
        
        # 就诊类型
        encounter_type = get_encounter_type(encounter)
        encounter_stats[encounter_type] += 1
        
        # 事件类型
        event_type = episode['eventType']
        event_type_stats[event_type] += 1
        
        # 代码显示
        code_display = get_code_display(episode['code'].get('coding', [])) if episode['code'] else 'N/A'
        
        results.append({
            'patientID': patient_id,
            'eventDate': episode['episodeStartDate'][:10],
            'age': age if age is not None else 'Unknown',
            'gender': gender if gender else 'Unknown',
            'encounterType': encounter_type,
            'eventType': event_type,
            'codeDisplay': code_display
        })
    
    # 6. 打印报告
    print("\n" + "=" * 80)
    print("COVID-19 监测分析结果")
    print("=" * 80)
    
    print(f"\n总COVID-19病例数: {len(unique_episodes)}")
    
    if len(unique_episodes) > 0:
        print("\n按性别分布:")
        for gender, count in gender_stats.items():
            if count > 0:
                pct = (count/len(unique_episodes)*100)
                print(f"  - {gender}: {count} ({pct:.1f}%)")
        
        print("\n按年龄组分布:")
        for age_group, count in age_groups.items():
            if count > 0:
                pct = (count/len(unique_episodes)*100)
                print(f"  - {age_group}: {count} ({pct:.1f}%)")
        
        print("\n按就诊类型分布:")
        for enc_type, count in encounter_stats.items():
            if count > 0:
                pct = (count/len(unique_episodes)*100)
                print(f"  - {enc_type}: {count} ({pct:.1f}%)")
        
        print("\n按事件类型分布:")
        for evt_type, count in event_type_stats.items():
            if count > 0:
                pct = (count/len(unique_episodes)*100)
                print(f"  - {evt_type}: {count} ({pct:.1f}%)")
        
        # 显示前10个病例详情
        print("\n前10个COVID-19病例详情:")
        print("-" * 100)
        print(f"{'患者ID':<15} {'日期':<12} {'年龄':<6} {'性别':<8} {'就诊类型':<12} {'事件类型':<12} {'代码名称':<30}")
        print("-" * 100)
        
        for result in results[:10]:
            print(f"{result['patientID']:<15} {result['eventDate']:<12} {str(result['age']):<6} "
                  f"{result['gender']:<8} {result['encounterType']:<12} {result['eventType']:<12} "
                  f"{result['codeDisplay'][:30]:<30}")
    
    print("\n" + "=" * 80)
    print("分析完成")
    print("=" * 80)
    
    # 保存详细结果到文件
    output_file = 'COVID19_SURVEILLANCE_V2_REPORT.md'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# COVID-19 监测执行报告 V2 (简化版)\n\n")
        f.write(f"**生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write("## ELM版本\n\n")
        f.write("- **来源**: 舊50/InfectiousDisease_COVID19_Surveillance.json\n")
        f.write("- **特点**: 简化的代码匹配逻辑，不检查实验室结果阳性/阴性\n")
        f.write("- **去重窗口**: 30天（比AHRQ_Official的60天更严格）\n\n")
        
        f.write("## 执行摘要\n\n")
        f.write(f"- **唯一COVID-19病例数**: {len(unique_episodes)}\n")
        f.write(f"- **COVID-19诊断记录**: {len(covid_conditions)}\n")
        f.write(f"- **COVID-19实验室检测**: {len(covid_labs)}\n")
        f.write(f"- **总事件数**: {len(all_events)}\n\n")
        
        f.write("## 数据来源\n\n")
        f.write(f"- **Condition资源总数**: {len(conditions)}\n")
        f.write(f"- **Observation资源总数**: {len(observations)}\n")
        f.write(f"- **Encounter资源总数**: {len(encounters)}\n")
        f.write(f"- **Patient资源总数**: {len(patients)}\n\n")
        
        if len(unique_episodes) > 0:
            f.write("## 统计分析\n\n")
            
            f.write("### 按性别分布\n\n")
            f.write("| 性别 | 病例数 | 百分比 |\n")
            f.write("|------|--------|--------|\n")
            for gender, count in gender_stats.items():
                if count > 0:
                    pct = (count/len(unique_episodes)*100)
                    f.write(f"| {gender} | {count} | {pct:.1f}% |\n")
            
            f.write("\n### 按年龄组分布\n\n")
            f.write("| 年龄组 | 病例数 | 百分比 |\n")
            f.write("|--------|--------|--------|\n")
            for age_group, count in age_groups.items():
                if count > 0:
                    pct = (count/len(unique_episodes)*100)
                    f.write(f"| {age_group} | {count} | {pct:.1f}% |\n")
            
            f.write("\n### 按就诊类型分布\n\n")
            f.write("| 就诊类型 | 病例数 | 百分比 |\n")
            f.write("|----------|--------|--------|\n")
            for enc_type, count in encounter_stats.items():
                if count > 0:
                    pct = (count/len(unique_episodes)*100)
                    f.write(f"| {enc_type} | {count} | {pct:.1f}% |\n")
            
            f.write("\n### 按事件类型分布\n\n")
            f.write("| 事件类型 | 病例数 | 百分比 |\n")
            f.write("|----------|--------|--------|\n")
            for evt_type, count in event_type_stats.items():
                if count > 0:
                    pct = (count/len(unique_episodes)*100)
                    f.write(f"| {evt_type} | {count} | {pct:.1f}% |\n")
            
            f.write("\n## 病例详情\n\n")
            f.write("| 患者ID | 日期 | 年龄 | 性别 | 就诊类型 | 事件类型 | 代码名称 |\n")
            f.write("|--------|------|------|------|----------|----------|----------|\n")
            for result in results[:50]:
                f.write(f"| {result['patientID']} | {result['eventDate']} | {result['age']} | "
                       f"{result['gender']} | {result['encounterType']} | {result['eventType']} | "
                       f"{result['codeDisplay']} |\n")
            
            if len(results) > 50:
                f.write(f"\n*... 还有 {len(results)-50} 个病例未显示*\n")
        else:
            f.write("## 诊断\n\n")
            f.write("未找到COVID-19病例。可能原因：\n\n")
            f.write("1. FHIR服务器上不存在匹配的ICD-10 U07.1或SNOMED 840539006诊断\n")
            f.write("2. FHIR服务器上不存在匹配的LOINC 94500-6实验室检测\n")
            f.write("3. Condition资源缺少clinicalStatus字段\n")
            f.write("4. Observation资源的status不是final或amended\n")
    
    print(f"\n详细报告已保存至: {output_file}")

if __name__ == '__main__':
    main()
