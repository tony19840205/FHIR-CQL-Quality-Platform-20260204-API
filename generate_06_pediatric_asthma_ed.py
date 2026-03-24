"""
生成指标06：小儿气喘急诊率测试资料
分子：气喘病患中因气喘急诊就医者
分母：18岁以下气喘病患（符合a/b/c任一条件）
"""

import json
from datetime import datetime

timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

# 气喘用药ATC代码
ASTHMA_MEDICATIONS = [
    'R03AC02',  # Salbutamol
    'R03AC13',  # Formoterol
    'R03BA02',  # Budesonide
    'R03BA05',  # Fluticasone
    'R03AK06',  # Salmeterol+Fluticasone
]

def generate_patient(patient_id, scenario):
    """
    scenario类型：
    'ed': 有气喘急诊（符合分母a，也符合分子）
    'inpatient': 有气喘住院（符合分母b，不符合分子）
    'outpatient': 有气喘门诊+前一年多次门诊+用药（符合分母c，不符合分子）
    'no_asthma': 非气喘患者（不符合分母）
    """
    patient_uid = f'asthma-{timestamp}-{patient_id}'
    org_id = 'org-hospital-asthma'
    
    entries = []
    
    # Organization
    entries.append({
        'fullUrl': f'urn:uuid:{org_id}',
        'resource': {
            'resourceType': 'Organization',
            'identifier': [{
                'system': 'http://www.mohw.gov.tw/hospital',
                'value': 'ASTHMA-HOSP-001'
            }],
            'name': '儿童气喘专科医院'
        },
        'request': {
            'method': 'POST',
            'url': 'Organization',
            'ifNoneExist': 'identifier=ASTHMA-HOSP-001'
        }
    })
    
    # Patient (18岁以下)
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
                'given': [f'气喘{patient_id}']
            }],
            'gender': 'male',
            'birthDate': '2015-03-10'  # 10岁
        },
        'request': {
            'method': 'POST',
            'url': 'Patient'
        }
    })
    
    if scenario == 'ed':
        # 条件a: 气喘急诊
        entries.append({
            'fullUrl': f'urn:uuid:encounter-{patient_uid}-ed',
            'resource': {
                'resourceType': 'Encounter',
                'status': 'finished',
                'class': {
                    'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
                    'code': 'EMER',
                    'display': 'emergency'
                },
                'subject': {
                    'reference': f'urn:uuid:patient-{patient_uid}'
                },
                'serviceProvider': {
                    'reference': f'urn:uuid:{org_id}'
                },
                'period': {
                    'start': '2026-01-04T02:00:00Z',
                    'end': '2026-01-04T05:00:00Z'
                },
                'reasonCode': [{
                    'coding': [{
                        'system': 'http://hl7.org/fhir/sid/icd-10-cm',
                        'code': 'J45.0',
                        'display': 'Predominantly allergic asthma'
                    }]
                }]
            },
            'request': {
                'method': 'POST',
                'url': 'Encounter'
            }
        })
        
        # Condition (气喘诊断)
        entries.append({
            'fullUrl': f'urn:uuid:condition-{patient_uid}',
            'resource': {
                'resourceType': 'Condition',
                'clinicalStatus': {
                    'coding': [{
                        'system': 'http://terminology.hl7.org/CodeSystem/condition-clinical',
                        'code': 'active'
                    }]
                },
                'verificationStatus': {
                    'coding': [{
                        'system': 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                        'code': 'confirmed'
                    }]
                },
                'code': {
                    'coding': [{
                        'system': 'http://hl7.org/fhir/sid/icd-10-cm',
                        'code': 'J45.0',
                        'display': 'Predominantly allergic asthma'
                    }]
                },
                'subject': {
                    'reference': f'urn:uuid:patient-{patient_uid}'
                },
                'encounter': {
                    'reference': f'urn:uuid:encounter-{patient_uid}-ed'
                },
                'onsetDateTime': '2024-01-15'
            },
            'request': {
                'method': 'POST',
                'url': 'Condition'
            }
        })
        
    elif scenario == 'inpatient':
        # 条件b: 气喘住院
        entries.append({
            'fullUrl': f'urn:uuid:encounter-{patient_uid}-inp',
            'resource': {
                'resourceType': 'Encounter',
                'status': 'finished',
                'class': {
                    'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
                    'code': 'IMP',
                    'display': 'inpatient encounter'
                },
                'subject': {
                    'reference': f'urn:uuid:patient-{patient_uid}'
                },
                'serviceProvider': {
                    'reference': f'urn:uuid:{org_id}'
                },
                'period': {
                    'start': '2026-01-03T10:00:00Z',
                    'end': '2026-01-08T10:00:00Z'
                },
                'reasonCode': [{
                    'coding': [{
                        'system': 'http://hl7.org/fhir/sid/icd-10-cm',
                        'code': 'J45.5',
                        'display': 'Severe persistent asthma'
                    }]
                }]
            },
            'request': {
                'method': 'POST',
                'url': 'Encounter'
            }
        })
        
        entries.append({
            'fullUrl': f'urn:uuid:condition-{patient_uid}',
            'resource': {
                'resourceType': 'Condition',
                'clinicalStatus': {
                    'coding': [{
                        'system': 'http://terminology.hl7.org/CodeSystem/condition-clinical',
                        'code': 'active'
                    }]
                },
                'verificationStatus': {
                    'coding': [{
                        'system': 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                        'code': 'confirmed'
                    }]
                },
                'code': {
                    'coding': [{
                        'system': 'http://hl7.org/fhir/sid/icd-10-cm',
                        'code': 'J45.5',
                        'display': 'Severe persistent asthma'
                    }]
                },
                'subject': {
                    'reference': f'urn:uuid:patient-{patient_uid}'
                },
                'encounter': {
                    'reference': f'urn:uuid:encounter-{patient_uid}-inp'
                },
                'onsetDateTime': '2024-01-15'
            },
            'request': {
                'method': 'POST',
                'url': 'Condition'
            }
        })
        
    elif scenario == 'outpatient':
        # 条件c: 当期门诊 + 前一年4次门诊 + 2次用药
        # 当期门诊
        entries.append({
            'fullUrl': f'urn:uuid:encounter-{patient_uid}-amb-current',
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
                    'start': '2026-01-05T10:00:00Z',
                    'end': '2026-01-05T10:30:00Z'
                },
                'reasonCode': [{
                    'coding': [{
                        'system': 'http://hl7.org/fhir/sid/icd-10-cm',
                        'code': 'J45.3',
                        'display': 'Mild persistent asthma'
                    }]
                }]
            },
            'request': {
                'method': 'POST',
                'url': 'Encounter'
            }
        })
        
        entries.append({
            'fullUrl': f'urn:uuid:condition-{patient_uid}',
            'resource': {
                'resourceType': 'Condition',
                'clinicalStatus': {
                    'coding': [{
                        'system': 'http://terminology.hl7.org/CodeSystem/condition-clinical',
                        'code': 'active'
                    }]
                },
                'verificationStatus': {
                    'coding': [{
                        'system': 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                        'code': 'confirmed'
                    }]
                },
                'code': {
                    'coding': [{
                        'system': 'http://hl7.org/fhir/sid/icd-10-cm',
                        'code': 'J45.3',
                        'display': 'Mild persistent asthma'
                    }]
                },
                'subject': {
                    'reference': f'urn:uuid:patient-{patient_uid}'
                },
                'encounter': {
                    'reference': f'urn:uuid:encounter-{patient_uid}-amb-current'
                },
                'onsetDateTime': '2024-01-15'
            },
            'request': {
                'method': 'POST',
                'url': 'Condition'
            }
        })
        
        # 前一年4次门诊（2025年）
        for i in range(4):
            month = 3 + i * 2
            entries.append({
                'fullUrl': f'urn:uuid:encounter-{patient_uid}-amb-prev-{i}',
                'resource': {
                    'resourceType': 'Encounter',
                    'status': 'finished',
                    'class': {
                        'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
                        'code': 'AMB'
                    },
                    'subject': {
                        'reference': f'urn:uuid:patient-{patient_uid}'
                    },
                    'serviceProvider': {
                        'reference': f'urn:uuid:{org_id}'
                    },
                    'period': {
                        'start': f'2025-{month:02d}-15T10:00:00Z',
                        'end': f'2025-{month:02d}-15T10:30:00Z'
                    },
                    'reasonCode': [{
                        'coding': [{
                            'system': 'http://hl7.org/fhir/sid/icd-10-cm',
                            'code': 'J45.3'
                        }]
                    }]
                },
                'request': {
                    'method': 'POST',
                    'url': 'Encounter'
                }
            })
            
            # 前2次门诊有使用气喘用药
            if i < 2:
                entries.append({
                    'fullUrl': f'urn:uuid:med-{patient_uid}-prev-{i}',
                    'resource': {
                        'resourceType': 'MedicationRequest',
                        'status': 'completed',
                        'intent': 'order',
                        'medicationCodeableConcept': {
                            'coding': [{
                                'system': 'http://www.whocc.no/atc',
                                'code': ASTHMA_MEDICATIONS[i],
                                'display': 'Asthma medication'
                            }]
                        },
                        'subject': {
                            'reference': f'urn:uuid:patient-{patient_uid}'
                        },
                        'encounter': {
                            'reference': f'urn:uuid:encounter-{patient_uid}-amb-prev-{i}'
                        },
                        'authoredOn': f'2025-{month:02d}-15T10:15:00Z'
                    },
                    'request': {
                        'method': 'POST',
                        'url': 'MedicationRequest'
                    }
                })
    
    return entries

# 生成测试资料
# 10位患者：4位急诊（分子+分母），3位住院（仅分母），2位门诊（仅分母），1位非气喘
patients_config = [
    (1, 'ed'),          # 急诊（分子+分母）
    (2, 'ed'),          # 急诊
    (3, 'ed'),          # 急诊
    (4, 'ed'),          # 急诊
    (5, 'inpatient'),   # 住院（仅分母）
    (6, 'inpatient'),   # 住院
    (7, 'inpatient'),   # 住院
    (8, 'outpatient'),  # 门诊（仅分母）
    (9, 'outpatient'),  # 门诊
    (10, 'no_asthma'),  # 非气喘（不符合）
]

all_entries = []
for patient_id, scenario in patients_config:
    if scenario != 'no_asthma':
        patient_entries = generate_patient(patient_id, scenario)
        all_entries.extend(patient_entries)

bundle = {
    'resourceType': 'Bundle',
    'type': 'transaction',
    'entry': all_entries
}

output_file = 'test_data_06_pediatric_asthma_ed_2026Q1.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成测试资料：{output_file}")
print(f"   总病患数：9人（排除1位非气喘）")
print(f"   分母（气喘病患）：9人")
print(f"   - 条件a（急诊）：4人")
print(f"   - 条件b（住院）：3人")
print(f"   - 条件c（门诊+用药）：2人")
print(f"   分子（急诊就医）：4人")
print(f"   预期比率：4/9 = 44.44%")
print(f"   timestamp={timestamp}")
