#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
COVID-19 监测数据分析脚本
基于 InfectiousDisease_COVID19_Surveillance.json ELM 逻辑
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

# COVID-19 相关代码定义
ICD10_COVID_CODES = ["U07.1", "U07.2"]
SNOMED_COVID_CODES = [
    "840539006",  # COVID-19
    "840544004",  # Suspected COVID-19
    "882784691000119100",  # Pneumonia caused by SARS-CoV-2
    "1240581000000104",  # COVID-19 confirmed by laboratory test
    "1240751000000100",  # COVID-19 confirmed clinically
    "870588003",  # SARS-CoV-2 detected
    "1119302008"   # Acute disease caused by SARS-CoV-2
]

LOINC_COVID_LAB_CODES = [
    "94500-6",  # SARS-CoV-2 RNA Pnl
    "94559-2",  # SARS-CoV-2 ORF1ab region
    "94845-3",  # SARS-CoV-2 RdRp gene
    "97097-0",  # SARS-CoV-2 Ag
    "94558-4",  # SARS-CoV-2 Ag Pres
    "94563-4",  # SARS-CoV-2 IgG Ab
    "94564-2",  # SARS-CoV-2 IgM Ab
    "94762-2",  # SARS-CoV-2 Ab
    "94533-7",  # SARS-CoV-2 N gene
    "94640-0",  # SARS-CoV-2 S gene
    "94645-9",  # SARS-CoV-2 RdRp gene
    "94315-9",  # SARS-CoV-2 E gene
    "94531-1",  # SARS-CoV-2 RNA panel
    "94764-8",  # SARS-CoV-2 whole genome
    "94745-7"   # SARS-CoV-2 RNA
]

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

def get_code_value(coding_list, system=None):
    """从coding列表中提取代码值"""
    if not coding_list:
        return None
    for coding in coding_list:
        if system is None or coding.get('system') == system:
            return coding.get('code')
    return coding_list[0].get('code') if coding_list else None

def get_code_display(coding_list, system=None):
    """从coding列表中提取显示名称"""
    if not coding_list:
        return None
    for coding in coding_list:
        if system is None or coding.get('system') == system:
            return coding.get('display')
    return coding_list[0].get('display') if coding_list else None

def is_covid_condition(condition):
    """判断是否为COVID-19诊断"""
    if not condition.get('code') or not condition['code'].get('coding'):
        return False
    
    for coding in condition['code']['coding']:
        code = coding.get('code')
        system = coding.get('system', '')
        
        # 检查ICD-10代码
        if 'icd-10' in system.lower() and code in ICD10_COVID_CODES:
            return True
        
        # 检查SNOMED代码
        if 'snomed' in system.lower() and code in SNOMED_COVID_CODES:
            return True
    
    return False

def is_covid_lab(observation):
    """判断是否为COVID-19实验室检测"""
    if not observation.get('code') or not observation['code'].get('coding'):
        return False
    
    # 检查是否为阳性结果
    value = observation.get('valueCodeableConcept', {})
    if value.get('coding'):
        for coding in value['coding']:
            code = coding.get('code', '').upper()
            display = coding.get('display', '').upper()
            if any(term in code or term in display for term in ['POSITIVE', 'DETECTED', 'PRESENT']):
                is_positive = True
                break
        else:
            is_positive = False
    else:
        is_positive = False
    
    if not is_positive:
        return False
    
    # 检查LOINC代码
    for coding in observation['code']['coding']:
        code = coding.get('code')
        system = coding.get('system', '')
        
        if 'loinc' in system.lower() and code in LOINC_COVID_LAB_CODES:
            return True
    
    return False

def get_event_date(resource, resource_type):
    """获取事件日期"""
    if resource_type == 'Condition':
        # 尝试多个日期字段
        for field in ['recordedDate', 'onsetDateTime', 'assertedDate']:
            if resource.get(field):
                return resource[field]
    elif resource_type == 'Observation':
        # 尝试多个日期字段
        for field in ['effectiveDateTime', 'issued']:
            if resource.get(field):
                return resource[field]
    return None

def get_encounter_reference(resource):
    """获取encounter引用"""
    encounter = resource.get('encounter', {})
    if encounter.get('reference'):
        return encounter['reference'].split('/')[-1]
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

def determine_test_type(code_value, code_display):
    """确定检测类型"""
    if not code_display:
        return "Unknown"
    
    display_upper = code_display.upper()
    
    # PCR/RNA检测
    pcr_keywords = ['RNA', 'PCR', 'NAAT', 'NUCLEIC ACID', 'MOLECULAR']
    if any(kw in display_upper for kw in pcr_keywords):
        return "PCR/RNA"
    
    # 抗原检测
    antigen_keywords = ['ANTIGEN', 'AG']
    if any(kw in display_upper for kw in antigen_keywords):
        return "Antigen"
    
    # 抗体检测
    antibody_keywords = ['ANTIBODY', 'AB', 'IGG', 'IGM', 'SEROLOGY']
    if any(kw in display_upper for kw in antibody_keywords):
        return "Antibody"
    
    return "SARS-CoV-2"

def main():
    print("=" * 80)
    print("COVID-19 监测数据分析")
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
    encounter_map = {e['id']: e for e in encounters}
    patient_map = {p['id']: p for p in patients}
    
    # 2. 识别COVID-19事件
    print("\n[2] 识别COVID-19事件...")
    
    covid_conditions = [c for c in conditions if is_covid_condition(c)]
    print(f"  - 找到 {len(covid_conditions)} 个COVID-19诊断")
    
    covid_labs = [o for o in observations if is_covid_lab(o)]
    print(f"  - 找到 {len(covid_labs)} 个阳性COVID-19检测")
    
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
        
        code_value = get_code_value(condition.get('code', {}).get('coding', []))
        code_display = get_code_display(condition.get('code', {}).get('coding', []))
        
        all_events.append({
            'eventDate': event_date,
            'patientId': patient_id,
            'encounterId': encounter_id,
            'eventType': 'Diagnosis',
            'codeValue': code_value,
            'codeDisplay': code_display,
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
        
        code_value = get_code_value(lab.get('code', {}).get('coding', []))
        code_display = get_code_display(lab.get('code', {}).get('coding', []))
        
        all_events.append({
            'eventDate': event_date,
            'patientId': patient_id,
            'encounterId': encounter_id,
            'eventType': 'Laboratory',
            'codeValue': code_value,
            'codeDisplay': code_display,
            'resource': lab
        })
    
    # 按日期排序
    all_events.sort(key=lambda x: x['eventDate'])
    print(f"  - 总共 {len(all_events)} 个COVID-19事件")
    
    # 4. 识别唯一病例（60天内的重复事件视为同一病例）
    print("\n[4] 识别唯一COVID-19病例...")
    
    unique_episodes = []
    processed_events = set()
    
    for i, event in enumerate(all_events):
        if i in processed_events:
            continue
        
        event_dt = datetime.fromisoformat(event['eventDate'].replace('Z', '+00:00'))
        episode_end = event_dt + timedelta(days=60)
        
        # 标记此事件及60天内的相关事件
        processed_events.add(i)
        
        for j in range(i + 1, len(all_events)):
            if j in processed_events:
                continue
            
            other_event = all_events[j]
            other_dt = datetime.fromisoformat(other_event['eventDate'].replace('Z', '+00:00'))
            
            # 如果是同一患者且在60天内
            if (other_event['patientId'] == event['patientId'] and 
                other_dt <= episode_end):
                processed_events.add(j)
        
        unique_episodes.append({
            'episodeStartDate': event['eventDate'],
            'episodeEndDate': episode_end.isoformat(),
            'patientId': event['patientId'],
            'encounterId': event['encounterId'],
            'eventType': event['eventType'],
            'codeValue': event['codeValue'],
            'codeDisplay': event['codeDisplay']
        })
    
    print(f"  - 识别出 {len(unique_episodes)} 个唯一COVID-19病例")
    
    # 5. 生成详细报告
    print("\n[5] 生成分析报告...")
    
    results = []
    gender_stats = {'male': 0, 'female': 0, 'other': 0, 'unknown': 0}
    encounter_stats = {'Inpatient': 0, 'Outpatient': 0, 'Emergency': 0, 'Other': 0, 'Unknown': 0}
    event_type_stats = {'Diagnosis': 0, 'Laboratory': 0}
    test_type_stats = defaultdict(int)
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
        
        # 检测类型（仅实验室）
        if event_type == 'Laboratory':
            test_type = determine_test_type(episode['codeValue'], episode['codeDisplay'])
            test_type_stats[test_type] += 1
        
        results.append({
            'patientID': patient_id,
            'eventDate': episode['episodeStartDate'][:10],
            'episodeEndDate': episode['episodeEndDate'][:10],
            'age': age if age is not None else 'Unknown',
            'gender': gender if gender else 'Unknown',
            'encounterType': encounter_type,
            'eventType': event_type,
            'testType': determine_test_type(episode['codeValue'], episode['codeDisplay']) if event_type == 'Laboratory' else 'N/A',
            'diagnosisCode': episode['codeValue'],
            'diagnosisName': episode['codeDisplay']
        })
    
    # 6. 打印报告
    print("\n" + "=" * 80)
    print("COVID-19 监测分析结果")
    print("=" * 80)
    
    print(f"\n总COVID-19病例数: {len(unique_episodes)}")
    
    print("\n按性别分布:")
    for gender, count in gender_stats.items():
        if count > 0:
            pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
            print(f"  - {gender}: {count} ({pct:.1f}%)")
    
    print("\n按年龄组分布:")
    for age_group, count in age_groups.items():
        if count > 0:
            pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
            print(f"  - {age_group}: {count} ({pct:.1f}%)")
    
    print("\n按就诊类型分布:")
    for enc_type, count in encounter_stats.items():
        if count > 0:
            pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
            print(f"  - {enc_type}: {count} ({pct:.1f}%)")
    
    print("\n按事件类型分布:")
    for evt_type, count in event_type_stats.items():
        pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
        print(f"  - {evt_type}: {count} ({pct:.1f}%)")
    
    if test_type_stats:
        print("\n实验室检测类型分布:")
        for test_type, count in sorted(test_type_stats.items(), key=lambda x: x[1], reverse=True):
            print(f"  - {test_type}: {count}")
    
    # 显示前10个病例详情
    if results:
        print("\n前10个COVID-19病例详情:")
        print("-" * 120)
        print(f"{'患者ID':<15} {'日期':<12} {'年龄':<6} {'性别':<8} {'就诊类型':<12} {'事件类型':<12} {'诊断代码':<12} {'诊断名称':<30}")
        print("-" * 120)
        
        for result in results[:10]:
            print(f"{result['patientID']:<15} {result['eventDate']:<12} {str(result['age']):<6} "
                  f"{result['gender']:<8} {result['encounterType']:<12} {result['eventType']:<12} "
                  f"{result['diagnosisCode']:<12} {result['diagnosisName'][:30]:<30}")
    
    print("\n" + "=" * 80)
    print("分析完成")
    print("=" * 80)
    
    # 保存详细结果到文件
    output_file = 'COVID19_SURVEILLANCE_EXECUTION_REPORT.md'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# COVID-19 监测执行报告\n\n")
        f.write(f"**生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write("## 执行摘要\n\n")
        f.write(f"- **唯一COVID-19病例数**: {len(unique_episodes)}\n")
        f.write(f"- **COVID-19诊断记录**: {len(covid_conditions)}\n")
        f.write(f"- **阳性实验室检测**: {len(covid_labs)}\n")
        f.write(f"- **总事件数**: {len(all_events)}\n\n")
        
        f.write("## 数据来源\n\n")
        f.write(f"- **Condition资源总数**: {len(conditions)}\n")
        f.write(f"- **Observation资源总数**: {len(observations)}\n")
        f.write(f"- **Encounter资源总数**: {len(encounters)}\n")
        f.write(f"- **Patient资源总数**: {len(patients)}\n\n")
        
        f.write("## 统计分析\n\n")
        
        f.write("### 按性别分布\n\n")
        f.write("| 性别 | 病例数 | 百分比 |\n")
        f.write("|------|--------|--------|\n")
        for gender, count in gender_stats.items():
            if count > 0:
                pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
                f.write(f"| {gender} | {count} | {pct:.1f}% |\n")
        
        f.write("\n### 按年龄组分布\n\n")
        f.write("| 年龄组 | 病例数 | 百分比 |\n")
        f.write("|--------|--------|--------|\n")
        for age_group, count in age_groups.items():
            if count > 0:
                pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
                f.write(f"| {age_group} | {count} | {pct:.1f}% |\n")
        
        f.write("\n### 按就诊类型分布\n\n")
        f.write("| 就诊类型 | 病例数 | 百分比 |\n")
        f.write("|----------|--------|--------|\n")
        for enc_type, count in encounter_stats.items():
            if count > 0:
                pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
                f.write(f"| {enc_type} | {count} | {pct:.1f}% |\n")
        
        f.write("\n### 按事件类型分布\n\n")
        f.write("| 事件类型 | 病例数 | 百分比 |\n")
        f.write("|----------|--------|--------|\n")
        for evt_type, count in event_type_stats.items():
            pct = (count/len(unique_episodes)*100) if len(unique_episodes) > 0 else 0
            f.write(f"| {evt_type} | {count} | {pct:.1f}% |\n")
        
        if test_type_stats:
            f.write("\n### 实验室检测类型分布\n\n")
            f.write("| 检测类型 | 数量 |\n")
            f.write("|----------|------|\n")
            for test_type, count in sorted(test_type_stats.items(), key=lambda x: x[1], reverse=True):
                f.write(f"| {test_type} | {count} |\n")
        
        f.write("\n## 病例详情\n\n")
        f.write("| 患者ID | 日期 | 年龄 | 性别 | 就诊类型 | 事件类型 | 诊断代码 | 诊断名称 |\n")
        f.write("|--------|------|------|------|----------|----------|----------|----------|\n")
        for result in results[:50]:  # 显示前50个
            f.write(f"| {result['patientID']} | {result['eventDate']} | {result['age']} | "
                   f"{result['gender']} | {result['encounterType']} | {result['eventType']} | "
                   f"{result['diagnosisCode']} | {result['diagnosisName']} |\n")
        
        if len(results) > 50:
            f.write(f"\n*... 还有 {len(results)-50} 个病例未显示*\n")
        
        f.write("\n## 临床见解\n\n")
        f.write("1. **病例识别**: 采用60天病例去重逻辑，避免重复计算同一患者的多次检测\n")
        f.write("2. **数据质量**: ")
        if len(unique_episodes) > 0:
            f.write(f"成功识别 {len(unique_episodes)} 个独特COVID-19病例\n")
        else:
            f.write("未发现COVID-19病例，可能需要检查数据或代码配置\n")
        
        f.write("\n## 建议\n\n")
        if len(unique_episodes) == 0:
            f.write("- 检查FHIR服务器上是否存在COVID-19相关诊断和检测数据\n")
            f.write("- 验证ICD-10、SNOMED和LOINC代码配置是否正确\n")
            f.write("- 确认Observation资源的valueCodeableConcept是否包含阳性结果\n")
        else:
            f.write("- 数据收集成功，可进行深入的流行病学分析\n")
            f.write("- 可根据时间趋势、地理分布等维度进一步细分\n")
            f.write("- 建议定期更新监测数据以跟踪疫情变化\n")
    
    print(f"\n详细报告已保存至: {output_file}")

if __name__ == '__main__':
    main()
