"""
生成指标05：处方10种以上药品率测试资料
分子：药品品项数≥10项的案件
分母：门诊给药案件
"""

import json
from datetime import datetime

timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

# 10码药品代码列表（台湾健保药品代码）
DRUG_CODES = [
    "AB47092100",  # 降血压药
    "BC22777100",  # 降血脂药
    "AC23773100",  # 降血糖药
    "NC05116100",  # 安眠药
    "AC56108100",  # 胃药
    "BC01640100",  # 抗凝血药
    "AC44199100",  # 消炎药
    "AB48300100",  # 心脏病药
    "AC24029100",  # 糖尿病药
    "NC03625100",  # 抗焦虑药
    "BC24739100",  # 利尿剂
    "AC22760100",  # 降尿酸药
    "NC01331100",  # 止痛药
    "AC25200100",  # 肝脏保护药
    "BC05501100",  # 抗血栓药
]

def generate_patient(patient_id, drug_count):
    """生成一个患者的完整资料"""
    patient_uid = f'poly-{timestamp}-{patient_id}'
    org_id = 'org-hospital-poly'
    
    entries = []
    
    # Organization (只添加一次)
    entries.append({
        'fullUrl': f'urn:uuid:{org_id}',
        'resource': {
            'resourceType': 'Organization',
            'identifier': [{
                'system': 'http://www.mohw.gov.tw/hospital',
                'value': 'POLY-HOSP-001'
            }],
            'name': '多重用药测试医院'
        },
        'request': {
            'method': 'POST',
            'url': 'Organization',
            'ifNoneExist': 'identifier=POLY-HOSP-001'
        }
    })
    
    # Patient
    entries.append({
        'fullUrl': f'urn:uuid:patient-{patient_uid}',
        'resource': {
            'resourceType': 'Patient',
            'identifier': [{
                'system': 'http://www.mohw.gov.tw/patient',
                'value': patient_uid
            }],
            'name': [{
                'family': '测试',
                'given': [f'多药{patient_id}']
            }],
            'gender': 'male',
            'birthDate': '1950-05-15'
        },
        'request': {
            'method': 'POST',
            'url': 'Patient'
        }
    })
    
    # Encounter
    entries.append({
        'fullUrl': f'urn:uuid:encounter-{patient_uid}',
        'resource': {
            'resourceType': 'Encounter',
            'status': 'finished',
            'class': {
                'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
                'code': 'AMB',
                'display': 'ambulatory'
            },
            'subject': {
                'reference': f'urn:uuid:patient-{patient_uid}'
            },
            'serviceProvider': {
                'reference': f'urn:uuid:{org_id}'
            },
            'period': {
                'start': '2026-01-03T10:00:00Z',
                'end': '2026-01-03T10:30:00Z'
            }
        },
        'request': {
            'method': 'POST',
            'url': 'Encounter'
        }
    })
    
    # 生成多个MedicationRequest（根据drug_count）
    for i in range(drug_count):
        drug_code = DRUG_CODES[i % len(DRUG_CODES)]
        
        entries.append({
            'fullUrl': f'urn:uuid:med-{patient_uid}-{i+1}',
            'resource': {
                'resourceType': 'MedicationRequest',
                'status': 'completed',
                'intent': 'order',
                'medicationCodeableConcept': {
                    'coding': [{
                        'system': 'http://www.nhi.gov.tw/drugs',
                        'code': drug_code,
                        'display': f'药品{i+1}'
                    }]
                },
                'subject': {
                    'reference': f'urn:uuid:patient-{patient_uid}'
                },
                'encounter': {
                    'reference': f'urn:uuid:encounter-{patient_uid}'
                },
                'authoredOn': '2026-01-03T10:15:00Z',
                'dispenseRequest': {
                    'validityPeriod': {
                        'start': '2026-01-03',
                        'end': '2026-02-02'
                    },
                    'quantity': {
                        'value': 30,
                        'unit': 'tablets'
                    },
                    'expectedSupplyDuration': {
                        'value': 30,
                        'unit': 'days'
                    }
                }
            },
            'request': {
                'method': 'POST',
                'url': 'MedicationRequest'
            }
        })
    
    return entries

# 生成测试资料
# 12位患者：7位有≥10种药品（分子），5位<10种药品（不符合分子）
patients_config = [
    (1, 12),   # 12种药
    (2, 11),   # 11种药
    (3, 10),   # 10种药（刚好符合）
    (4, 13),   # 13种药
    (5, 10),   # 10种药
    (6, 11),   # 11种药
    (7, 14),   # 14种药
    (8, 5),    # 5种药（不符合）
    (9, 7),    # 7种药（不符合）
    (10, 8),   # 8种药（不符合）
    (11, 6),   # 6种药（不符合）
    (12, 9),   # 9种药（不符合）
]

all_entries = []
for patient_id, drug_count in patients_config:
    patient_entries = generate_patient(patient_id, drug_count)
    all_entries.extend(patient_entries)

bundle = {
    'resourceType': 'Bundle',
    'type': 'transaction',
    'entry': all_entries
}

output_file = 'test_data_05_prescription_10drugs_2026Q1.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成测试资料：{output_file}")
print(f"   总病患数：12人")
print(f"   ≥10种药品：7人 (58.33%)")
print(f"   <10种药品：5人 (41.67%)")
print(f"   timestamp={timestamp}")
