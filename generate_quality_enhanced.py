#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成增強版指標01+02測試資料
- 80位病患
- 注射劑使用率調整為較低比例（更真實）
"""

import json
import random
from datetime import datetime, timedelta

# 配置
START_PATIENT_ID = 259
TOTAL_PATIENTS = 80
Q1_START = datetime(2026, 1, 1)
Q1_END = datetime(2026, 1, 15)

# 台灣常見姓名
surnames = ['陳', '林', '黃', '張', '李', '王', '吳', '劉', '蔡', '楊',
            '許', '鄭', '謝', '郭', '洪', '曾', '邱', '廖', '賴', '周']
male_names = ['建國', '家豪', '志明', '俊傑', '文龍', '冠宇', '承翰', '宗翰']
female_names = ['淑芬', '雅婷', '怡君', '佳穎', '婉婷', '欣怡', '筱涵', '詩涵']

# 門診科別
departments = [
    {'code': 'IM', 'name': '內科', 'weight': 40},
    {'code': 'FM', 'name': '家醫科', 'weight': 30},
    {'code': 'SUR', 'name': '外科', 'weight': 20},
    {'code': 'ENT', 'name': '耳鼻喉科', 'weight': 10},
]

# 診斷
diagnoses = [
    {'code': 'J00', 'display': 'Acute nasopharyngitis', 'weight': 20},
    {'code': 'J06.9', 'display': 'Acute upper respiratory infection', 'weight': 20},
    {'code': 'I10', 'display': 'Essential hypertension', 'weight': 25},
    {'code': 'E11.9', 'display': 'Type 2 diabetes mellitus', 'weight': 20},
    {'code': 'M79.3', 'display': 'Myalgia', 'weight': 15},
]

# 注射劑藥物
injection_medications = [
    {'code': 'A11EA', 'name': 'Vitamin B Complex', 'display': 'B群注射', 'weight': 35},
    {'code': 'M01AB05', 'name': 'Diclofenac', 'display': '止痛針', 'weight': 30},
    {'code': 'M01AE01', 'name': 'Ibuprofen inj', 'display': '消炎針', 'weight': 20},
    {'code': 'H02AB04', 'name': 'Methylprednisolone', 'display': '類固醇針', 'weight': 15},
]

# 抗生素
antibiotic_medications = [
    {'code': 'J01CA04', 'name': 'Amoxicillin', 'display': '安莫西林', 'weight': 50},
    {'code': 'J01DB01', 'name': 'Cefalexin', 'display': '頭孢菌素', 'weight': 30},
    {'code': 'J01FA10', 'name': 'Azithromycin', 'display': '阿奇黴素', 'weight': 20},
]

def weighted_choice(items):
    total = sum(item['weight'] for item in items)
    r = random.uniform(0, total)
    current = 0
    for item in items:
        current += item['weight']
        if r <= current:
            return item
    return items[-1]

def random_date():
    delta = Q1_END - Q1_START
    random_days = random.randint(0, delta.days)
    random_hours = random.randint(0, 23)
    return Q1_START + timedelta(days=random_days, hours=random_hours)

def generate_patient(pid):
    gender = random.choice(['male', 'female'])
    surname = random.choice(surnames)
    given = random.choice(male_names if gender == 'male' else female_names)
    age = random.randint(20, 75)
    birth_year = 2026 - age
    
    return {
        "resourceType": "Patient",
        "id": pid,
        "identifier": [{
            "system": "http://hospital.example.org/patients",
            "value": pid
        }],
        "name": [{
            "family": surname,
            "given": [given],
            "text": f"{surname}{given}"
        }],
        "gender": gender,
        "birthDate": f"{birth_year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    }

def generate_encounter(pid, eid, date, dept):
    return {
        "resourceType": "Encounter",
        "id": eid,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "AMB",
            "display": "ambulatory"
        },
        "type": [{
            "coding": [{
                "system": "http://hospital.example.org/department",
                "code": dept['code'],
                "display": dept['name']
            }],
            "text": dept['name']
        }],
        "subject": {"reference": f"Patient/{pid}"},
        "period": {
            "start": date.isoformat(),
            "end": (date + timedelta(hours=1)).isoformat()
        }
    }

def generate_condition(pid, eid, cid, diag):
    return {
        "resourceType": "Condition",
        "id": cid,
        "clinicalStatus": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                "code": "active"
            }]
        },
        "code": {
            "coding": [{
                "system": "http://hl7.org/fhir/sid/icd-10",
                "code": diag['code'],
                "display": diag['display']
            }],
            "text": diag['display']
        },
        "subject": {"reference": f"Patient/{pid}"},
        "encounter": {"reference": f"Encounter/{eid}"}
    }

def generate_medication_request(pid, eid, mid, med, med_type):
    # 生成健保代碼：第8碼(index 7)決定劑型
    base_hash = hash(med['code']) % 100000
    if med_type == 'injection':
        nhi_code = f"BC{base_hash:05d}2AA"  # 第8碼='2'代表注射劑
    else:
        nhi_code = f"AC{base_hash:05d}1AA"  # 第8碼='1'代表口服
    
    return {
        "resourceType": "MedicationRequest",
        "id": mid,
        "status": "completed",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [
                {"system": "https://www.nhi.gov.tw/medication", "code": nhi_code, "display": med['display']},
                {"system": "http://www.whocc.no/atc", "code": med['code'], "display": med['display']}
            ],
            "text": med['name']
        },
        "subject": {"reference": f"Patient/{pid}"},
        "encounter": {"reference": f"Encounter/{eid}"},
        "authoredOn": datetime.now().isoformat(),
        "dosageInstruction": [{
            "text": "注射給藥" if med_type == 'injection' else "口服,每日3次",
            "route": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "385219001" if med_type == 'injection' else "26643006",
                    "display": "Injection" if med_type == 'injection' else "Oral"
                }]
            }
        }]
    }

def generate_medication_administration(pid, eid, mid, med, med_type):
    base_hash = hash(med['code']) % 100000
    nhi_code = f"BC{base_hash:05d}2AA" if med_type == 'injection' else f"AC{base_hash:05d}1AA"
    
    return {
        "resourceType": "MedicationAdministration",
        "id": mid,
        "status": "completed",
        "medicationCodeableConcept": {
            "coding": [
                {"system": "https://www.nhi.gov.tw/medication", "code": nhi_code, "display": med['display']},
                {"system": "http://www.whocc.no/atc", "code": med['code'], "display": med['display']}
            ],
            "text": med['name']
        },
        "subject": {"reference": f"Patient/{pid}"},
        "context": {"reference": f"Encounter/{eid}"},
        "effectiveDateTime": datetime.now().isoformat(),
        "dosage": {
            "route": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "385219001" if med_type == 'injection' else "26643006",
                    "display": "Injection" if med_type == 'injection' else "Oral"
                }]
            },
            "dose": {"value": 1, "unit": "dose", "system": "http://unitsofmeasure.org", "code": "{dose}"}
        }
    }

def add_entry(bundle, resource, resource_type, resource_id):
    bundle["entry"].append({
        "fullUrl": f"https://emr-smart.appx.com.tw/v/r4/fhir/{resource_type}/{resource_id}",
        "resource": resource,
        "request": {"method": "PUT", "url": f"{resource_type}/{resource_id}"}
    })

def generate_bundle():
    bundle = {"resourceType": "Bundle", "type": "transaction", "entry": []}
    
    total_encounters = 0
    injection_encounters = 0
    antibiotic_encounters = 0
    
    # 生成80位病患的基本門診
    for i in range(TOTAL_PATIENTS):
        pid = f"TW{START_PATIENT_ID + i:05d}"
        patient = generate_patient(pid)
        add_entry(bundle, patient, "Patient", pid)
        
        # 每位病患2-3次門診
        num_visits = random.randint(2, 3)
        for v in range(num_visits):
            eid = f"{pid}-enc-{v+1}"
            date = random_date()
            dept = weighted_choice(departments)
            diag = weighted_choice(diagnoses)
            
            encounter = generate_encounter(pid, eid, date, dept)
            add_entry(bundle, encounter, "Encounter", eid)
            
            condition = generate_condition(pid, eid, f"{eid}-cond", diag)
            add_entry(bundle, condition, "Condition", f"{eid}-cond")
            
            total_encounters += 1
    
    # 注射劑案例：18個（約7-8%的比例，更真實）
    injection_patients = random.sample(range(START_PATIENT_ID, START_PATIENT_ID + TOTAL_PATIENTS), 18)
    for idx, pnum in enumerate(injection_patients):
        pid = f"TW{pnum:05d}"
        eid = f"{pid}-enc-inj"
        date = random_date()
        dept = weighted_choice(departments)
        diag = weighted_choice(diagnoses)
        med = weighted_choice(injection_medications)
        
        encounter = generate_encounter(pid, eid, date, dept)
        add_entry(bundle, encounter, "Encounter", eid)
        
        condition = generate_condition(pid, eid, f"{eid}-cond", diag)
        add_entry(bundle, condition, "Condition", f"{eid}-cond")
        
        med_req = generate_medication_request(pid, eid, f"{eid}-med-req", med, 'injection')
        add_entry(bundle, med_req, "MedicationRequest", f"{eid}-med-req")
        
        med_adm = generate_medication_administration(pid, eid, f"{eid}-med-adm", med, 'injection')
        add_entry(bundle, med_adm, "MedicationAdministration", f"{eid}-med-adm")
        
        injection_encounters += 1
        total_encounters += 1
    
    # 抗生素案例：30個（保持較高比例）
    antibiotic_patients = random.sample(range(START_PATIENT_ID, START_PATIENT_ID + TOTAL_PATIENTS), 30)
    for idx, pnum in enumerate(antibiotic_patients):
        pid = f"TW{pnum:05d}"
        eid = f"{pid}-enc-abx"
        date = random_date()
        dept = weighted_choice(departments)
        diag = weighted_choice(diagnoses)
        med = weighted_choice(antibiotic_medications)
        
        encounter = generate_encounter(pid, eid, date, dept)
        add_entry(bundle, encounter, "Encounter", eid)
        
        condition = generate_condition(pid, eid, f"{eid}-cond", diag)
        add_entry(bundle, condition, "Condition", f"{eid}-cond")
        
        med_req = generate_medication_request(pid, eid, f"{eid}-med-req", med, 'antibiotic')
        add_entry(bundle, med_req, "MedicationRequest", f"{eid}-med-req")
        
        med_adm = generate_medication_administration(pid, eid, f"{eid}-med-adm", med, 'antibiotic')
        add_entry(bundle, med_adm, "MedicationAdministration", f"{eid}-med-adm")
        
        antibiotic_encounters += 1
        total_encounters += 1
    
    inj_rate = (injection_encounters / total_encounters * 100) if total_encounters > 0 else 0
    abx_rate = (antibiotic_encounters / total_encounters * 100) if total_encounters > 0 else 0
    
    print(f"\n統計數據 (2026 Q1):")
    print(f"  總病患數: {TOTAL_PATIENTS}")
    print(f"  總門診數: {total_encounters}")
    print(f"  注射劑案件: {injection_encounters} ({inj_rate:.2f}%)")
    print(f"  抗生素案件: {antibiotic_encounters} ({abx_rate:.2f}%)")
    print(f"  總資源數: {len(bundle['entry'])}")
    
    return bundle

if __name__ == "__main__":
    print("生成增強版測試資料...")
    bundle = generate_bundle()
    
    output = "CGMH_test_data_quality_enhanced_2026Q1.json"
    with open(output, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)
    
    print(f"\n已生成: {output}")
    print("病患編號: TW00259 - TW00338 (80位)")
