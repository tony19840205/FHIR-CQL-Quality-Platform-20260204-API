"""
生成3位流感病人資料
專為增加流感病例數而設計，從30人增加到33人
"""

import json
import random
from datetime import datetime, timedelta

# 流感相關 ICD-10 診斷碼
INFLUENZA_CODES = ['J09', 'J10.0', 'J10.1', 'J10.8', 'J11.0', 'J11.1']
INFLUENZA_DISPLAY = [
    'Influenza due to identified novel influenza A virus',
    'Influenza due to other identified influenza virus with pneumonia',
    'Influenza due to other identified influenza virus with other respiratory manifestations',
    'Influenza due to other identified influenza virus with other manifestations',
    'Influenza due to unidentified influenza virus with pneumonia',
    'Influenza due to unidentified influenza virus with other respiratory manifestations'
]

# 流感疫苗 CVX 代碼
INFLUENZA_VACCINES = [
    {'code': '141', 'display': 'Influenza vaccine, seasonal'},
    {'code': '150', 'display': 'Influenza vaccine, injectable, quadrivalent'},
    {'code': '161', 'display': 'Influenza vaccine, injectable, trivalent'},
    {'code': '185', 'display': 'Influenza vaccine, seasonal, quadrivalent'}
]

# 台灣常見姓名
SURNAMES = ['陳', '林', '黃', '張', '李', '王', '吳', '劉', '蔡', '楊']
GIVEN_NAMES_MALE = ['志明', '建宏', '家豪', '俊傑', '冠廷']
GIVEN_NAMES_FEMALE = ['淑芬', '雅婷', '怡君', '佳穎', '詩涵']
CITIES = ['台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市']

def generate_patient(patient_number: int) -> dict:
    """生成病人資源"""
    patient_id = f"TW{10030 + patient_number}"
    gender = random.choice(['male', 'female'])
    surname = random.choice(SURNAMES)
    given_name = random.choice(GIVEN_NAMES_MALE if gender == 'male' else GIVEN_NAMES_FEMALE)
    
    # 年齡範圍 30-70歲
    age = random.randint(30, 70)
    birth_year = 2026 - age
    birth_date = f"{birth_year}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}"
    
    return {
        "resourceType": "Patient",
        "id": patient_id,
        "identifier": [{
            "system": "urn:oid:2.16.886.101.20003.20001",
            "value": f"A{random.randint(100000000, 199999999)}"
        }],
        "name": [{
            "family": surname,
            "given": [given_name],
            "text": f"{surname}{given_name}"
        }],
        "gender": gender,
        "birthDate": birth_date,
        "address": [{
            "city": random.choice(CITIES),
            "country": "TW"
        }]
    }

def generate_encounter(patient_id: str, encounter_date: str) -> dict:
    """生成就診資源"""
    encounter_id = f"{patient_id}-influenza-enc-001"
    
    return {
        "resourceType": "Encounter",
        "id": encounter_id,
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "AMB",
            "display": "ambulatory"
        },
        "type": [{
            "coding": [{
                "system": "http://snomed.info/sct",
                "code": "185345009",
                "display": "Encounter for symptom"
            }]
        }],
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "period": {
            "start": f"{encounter_date}T09:30:00+08:00",
            "end": f"{encounter_date}T10:15:00+08:00"
        }
    }

def generate_condition(patient_id: str, encounter_id: str, condition_date: str) -> dict:
    """生成流感診斷資源"""
    condition_id = f"{patient_id}-influenza-cond-001"
    
    # 隨機選擇流感診斷代碼
    code_index = random.randint(0, len(INFLUENZA_CODES) - 1)
    icd_code = INFLUENZA_CODES[code_index]
    display = INFLUENZA_DISPLAY[code_index]
    
    # 嚴重度分布：70%輕症、25%中症、5%重症
    severity_choice = random.choices(['mild', 'moderate', 'severe'], weights=[0.70, 0.25, 0.05])[0]
    severity_map = {
        'mild': {'code': '255604002', 'display': 'Mild'},
        'moderate': {'code': '6736007', 'display': 'Moderate'},
        'severe': {'code': '24484000', 'display': 'Severe'}
    }
    
    return {
        "resourceType": "Condition",
        "id": condition_id,
        "clinicalStatus": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                "code": "resolved",
                "display": "Resolved"
            }]
        },
        "verificationStatus": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                "code": "confirmed",
                "display": "Confirmed"
            }]
        },
        "category": [{
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-category",
                "code": "encounter-diagnosis",
                "display": "Encounter Diagnosis"
            }]
        }],
        "severity": {
            "coding": [{
                "system": "http://snomed.info/sct",
                "code": severity_map[severity_choice]['code'],
                "display": severity_map[severity_choice]['display']
            }]
        },
        "code": {
            "coding": [{
                "system": "http://hl7.org/fhir/sid/icd-10-cm",
                "code": icd_code,
                "display": display
            }],
            "text": display
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "onsetDateTime": condition_date,
        "recordedDate": condition_date
    }

def generate_observation(patient_id: str, encounter_id: str, obs_date: str, obs_type: str, obs_index: int) -> dict:
    """生成觀察資源（體溫、檢驗結果）"""
    observation_id = f"{patient_id}-influenza-obs-{obs_index:03d}"
    
    if obs_type == 'temperature':
        return {
            "resourceType": "Observation",
            "id": observation_id,
            "status": "final",
            "category": [{
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                    "code": "vital-signs",
                    "display": "Vital Signs"
                }]
            }],
            "code": {
                "coding": [{
                    "system": "http://loinc.org",
                    "code": "8310-5",
                    "display": "Body temperature"
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{encounter_id}"
            },
            "effectiveDateTime": obs_date,
            "valueQuantity": {
                "value": round(random.uniform(38.0, 39.8), 1),
                "unit": "Cel",
                "system": "http://unitsofmeasure.org",
                "code": "Cel"
            }
        }
    elif obs_type == 'influenza_a':
        return {
            "resourceType": "Observation",
            "id": observation_id,
            "status": "final",
            "category": [{
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                    "code": "laboratory",
                    "display": "Laboratory"
                }]
            }],
            "code": {
                "coding": [{
                    "system": "http://loinc.org",
                    "code": "94558-4",
                    "display": "Influenza virus A RNA [Presence] in Respiratory specimen by NAA with probe detection"
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{encounter_id}"
            },
            "effectiveDateTime": obs_date,
            "valueString": "Positive"
        }
    else:  # influenza_b
        return {
            "resourceType": "Observation",
            "id": observation_id,
            "status": "final",
            "category": [{
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                    "code": "laboratory",
                    "display": "Laboratory"
                }]
            }],
            "code": {
                "coding": [{
                    "system": "http://loinc.org",
                    "code": "94559-2",
                    "display": "Influenza virus B RNA [Presence] in Respiratory specimen by NAA with probe detection"
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{encounter_id}"
            },
            "effectiveDateTime": obs_date,
            "valueString": random.choice(["Positive", "Negative"])
        }

def generate_immunization(patient_id: str, vacc_date: str) -> dict:
    """生成流感疫苗接種資源"""
    immunization_id = f"{patient_id}-influenza-imm-001"
    vaccine = random.choice(INFLUENZA_VACCINES)
    
    return {
        "resourceType": "Immunization",
        "id": immunization_id,
        "status": "completed",
        "vaccineCode": {
            "coding": [{
                "system": "http://hl7.org/fhir/sid/cvx",
                "code": vaccine['code'],
                "display": vaccine['display']
            }]
        },
        "patient": {
            "reference": f"Patient/{patient_id}"
        },
        "occurrenceDateTime": vacc_date,
        "recorded": vacc_date,
        "primarySource": True,
        "lotNumber": f"FLU2026{random.randint(100, 999)}",
        "expirationDate": "2027-06-30",
        "site": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActSite",
                "code": "LA",
                "display": "left arm"
            }]
        },
        "route": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/v3-RouteOfAdministration",
                "code": "IM",
                "display": "Injection, intramuscular"
            }]
        },
        "doseQuantity": {
            "value": 0.5,
            "unit": "mL",
            "system": "http://unitsofmeasure.org",
            "code": "mL"
        },
        "protocolApplied": [{
            "doseNumberPositiveInt": 1,
            "seriesDosesPositiveInt": 1
        }]
    }

def main():
    print("開始生成3位流感病人資料...")
    
    entries = []
    
    # 生成3位病人（TW10031, TW10032, TW10033）
    for i in range(1, 4):
        patient_id = f"TW{10030 + i}"
        
        # 病人資源
        patient = generate_patient(i)
        entries.append({
            "resource": patient,
            "request": {
                "method": "PUT",
                "url": f"Patient/{patient_id}"
            }
        })
        
        # 就診日期：2026年1月到3月之間
        encounter_date = f"2026-0{random.randint(1, 3)}-{random.randint(1, 28):02d}"
        
        # 就診資源
        encounter = generate_encounter(patient_id, encounter_date)
        encounter_id = encounter['id']
        entries.append({
            "resource": encounter,
            "request": {
                "method": "PUT",
                "url": f"Encounter/{encounter_id}"
            }
        })
        
        # 診斷資源
        condition = generate_condition(patient_id, encounter_id, encounter_date)
        entries.append({
            "resource": condition,
            "request": {
                "method": "PUT",
                "url": f"Condition/{condition['id']}"
            }
        })
        
        # 觀察資源
        obs1 = generate_observation(patient_id, encounter_id, encounter_date, 'temperature', 1)
        entries.append({
            "resource": obs1,
            "request": {
                "method": "PUT",
                "url": f"Observation/{obs1['id']}"
            }
        })
        
        obs2 = generate_observation(patient_id, encounter_id, encounter_date, 'influenza_a', 2)
        entries.append({
            "resource": obs2,
            "request": {
                "method": "PUT",
                "url": f"Observation/{obs2['id']}"
            }
        })
        
        obs3 = generate_observation(patient_id, encounter_id, encounter_date, 'influenza_b', 3)
        entries.append({
            "resource": obs3,
            "request": {
                "method": "PUT",
                "url": f"Observation/{obs3['id']}"
            }
        })
        
        # 約60%的人有打流感疫苗（在發病前1-3個月）
        if random.random() < 0.60:
            days_before = random.randint(30, 90)
            vacc_date = (datetime.strptime(encounter_date, '%Y-%m-%d') - timedelta(days=days_before)).strftime('%Y-%m-%d')
            immunization = generate_immunization(patient_id, vacc_date)
            entries.append({
                "resource": immunization,
                "request": {
                    "method": "PUT",
                    "url": f"Immunization/{immunization['id']}"
                }
            })
        
        print(f"已生成病人 {patient_id} 的資料")
    
    # 創建Bundle
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": entries
    }
    
    # 保存到文件
    output_file = 'add_3_influenza_patients_2026Q1.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ 生成完成！")
    print(f"📁 檔案: {output_file}")
    print(f"👥 病人數: 3人 (TW10031, TW10032, TW10033)")
    print(f"📊 總資源數: {len(entries)}")
    print(f"   - Patient: 3")
    print(f"   - Encounter: 3")
    print(f"   - Condition: 3")
    print(f"   - Observation: {sum(1 for e in entries if e['resource']['resourceType'] == 'Observation')}")
    print(f"   - Immunization: {sum(1 for e in entries if e['resource']['resourceType'] == 'Immunization')}")
    print(f"\n準備上傳到 FHIR Server...")

if __name__ == '__main__':
    main()
