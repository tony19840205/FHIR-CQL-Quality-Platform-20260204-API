"""
生成指标04：慢性病连续处方使用率测试资料
"""

import json
from datetime import datetime

# 使用时间戳确保每次生成不同ID
timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

def generate_patient(patient_id, has_continuous=True):
    """生成一个慢性病患者的完整资料"""
    entries = []
    
    # 1. Organization (医院)
    entries.append({
        "fullUrl": f"urn:uuid:org-hospital-cgmh",
        "resource": {
            "resourceType": "Organization",
            "id": "org-hospital-cgmh",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/hospital",
                "value": "CGMH-001"
            }],
            "name": "长庚纪念医院"
        },
        "request": {
            "method": "POST",
            "url": "Organization",
            "ifNoneExist": "identifier=CGMH-001"
        }
    })
    
    # 2. Patient
    entries.append({
        "fullUrl": f"urn:uuid:patient-chronic-{timestamp}-{patient_id}",
        "resource": {
            "resourceType": "Patient",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/patient",
                "value": f"CHRONIC-{timestamp}-{patient_id}"
            }],
            "name": [{
                "family": "测试",
                "given": [f"慢性{patient_id}"]
            }],
            "gender": "male",
            "birthDate": "1955-06-20"
        },
        "request": {
            "method": "POST",
            "url": "Patient"
        }
    })
    
    # 3. Encounter
    entries.append({
        "fullUrl": f"urn:uuid:encounter-chronic-{timestamp}-{patient_id}",
        "resource": {
            "resourceType": "Encounter",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "subject": {
                "reference": f"urn:uuid:patient-chronic-{timestamp}-{patient_id}"
            },
            "serviceProvider": {
                "reference": "urn:uuid:org-hospital-cgmh"
            },
            "period": {
                "start": "2026-01-05T09:00:00Z",
                "end": "2026-01-05T09:30:00Z"
            }
        },
        "request": {
            "method": "POST",
            "url": "Encounter"
        }
    })
    
    # 4. Condition - 慢性病诊断（高血压）
    entries.append({
        "fullUrl": f"urn:uuid:condition-chronic-{patient_id}",
        "resource": {
            "resourceType": "Condition",
            "id": f"condition-chronic-{patient_id}",
            "clinicalStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                    "code": "active",
                    "display": "Active"
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
                    "code": "problem-list-item",
                    "display": "Problem List Item"
                }]
            }],
            "code": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "38341003",
                    "display": "Hypertensive disorder (高血压)"
                }]
            },
            "subject": {
                "reference": f"urn:uuid:patient-chronic-{timestamp}-{patient_id}"
            },
            "encounter": {
                "reference": f"urn:uuid:encounter-chronic-{timestamp}-{patient_id}"
            },
            "onsetDateTime": "2024-01-15"
        },
        "request": {
            "method": "POST",
            "url": "Condition"
        }
    })
    
    # 4.5 Procedure - 慢性病诊察（健保155A代码）
    entries.append({
        "fullUrl": f"urn:uuid:procedure-chronic-{patient_id}",
        "resource": {
            "resourceType": "Procedure",
            "id": f"procedure-chronic-{patient_id}",
            "status": "completed",
            "code": {
                "coding": [
                    {
                        "system": "NHI",
                        "code": "00155A",
                        "display": "慢性病诊察(155A)"
                    },
                    {
                        "system": "http://snomed.info/sct",
                        "code": "185349003",
                        "display": "Encounter for chronic disease"
                    }
                ]
            },
            "subject": {
                "reference": f"urn:uuid:patient-chronic-{timestamp}-{patient_id}"
            },
            "encounter": {
                "reference": f"urn:uuid:encounter-chronic-{timestamp}-{patient_id}"
            },
            "performedDateTime": "2026-01-05T09:15:00Z"
        },
        "request": {
            "method": "POST",
            "url": "Procedure"
        }
    })
    
    # 5. MedicationRequest
    if has_continuous:
        # 连续处方 - 使用健保CLAIM_TYPE = E1标记
        entries.append({
            "fullUrl": f"urn:uuid:med-chronic-{patient_id}",
            "resource": {
                "resourceType": "MedicationRequest",
                "id": f"med-chronic-{patient_id}",
                "identifier": [{
                    "system": "http://www.nhi.gov.tw/prescription",
                    "value": f"CONT-RX-{patient_id}",
                    "type": {
                        "coding": [{
                            "system": "NHI_CLAIM_TYPE",
                            "code": "E1",
                            "display": "慢性病连续处方"
                        }]
                    }
                }],
                "status": "completed",
                "intent": "order",
                "category": [{
                    "coding": [{
                        "system": "NHI_CLAIM_TYPE",
                        "code": "E1",
                        "display": "chronic-continuous-rx"
                    }]
                }],
                "medicationCodeableConcept": {
                    "coding": [{
                        "system": "http://www.whocc.no/atc",
                        "code": "C09AA01",
                        "display": "Captopril"
                    }]
                },
                "subject": {
                    "reference": f"Patient/patient-chronic-{patient_id}"
                },
                "encounter": {
                    "reference": f"Encounter/encounter-chronic-{patient_id}"
                },
                "reasonReference": [{
                    "reference": f"Condition/condition-chronic-{patient_id}"
                }],
                "authoredOn": "2026-01-05T09:15:00Z",
                "dosageInstruction": [{
                    "timing": {
                        "repeat": {
                            "boundsPeriod": {
                                "start": "2026-01-05",
                                "end": "2026-04-05"
                            }
                        }
                    }
                }],
                "dispenseRequest": {
                    "validityPeriod": {
                        "start": "2026-01-05",
                        "end": "2026-04-05"
                    },
                    "quantity": {
                        "value": 90,
                        "unit": "tablets"
                    },
                    "expectedSupplyDuration": {
                        "value": 90,
                        "unit": "days",
                        "system": "http://unitsofmeasure.org",
                        "code": "d"
                    },
                    "numberOfRepeatsAllowed": 2,
                    "extension": [{
                        "url": "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drug-days-per-dispense",
                        "valueQuantity": {
                            "value": 30,
                            "unit": "days",
                            "system": "http://unitsofmeasure.org",
                            "code": "d"
                        }
                    }]
                },
                "extension": [{
                    "url": "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/prescription-total-days",
                    "valueQuantity": {
                        "value": 90,
                        "unit": "days",
                        "system": "http://unitsofmeasure.org",
                        "code": "d"
                    }
                }]
            },
            "request": {
                "method": "POST",
                "url": "MedicationRequest"
            }
        })
    else:
        # 一般rx
        entries.append({
            "fullUrl": f"urn:uuid:med-chronic-{timestamp}-{patient_id}",
            "resource": {
                "resourceType": "MedicationRequest",
                "status": "completed",
                "intent": "order",
                "category": [{
                    "coding": [{
                        "system": "http://terminology.hl7.org/CodeSystem/medicationrequest-category",
                        "code": "community",
                        "display": "Community"
                    }]
                }],
                "medicationCodeableConcept": {
                    "coding": [{
                        "system": "http://www.whocc.no/atc",
                        "code": "C09AA01",
                        "display": "Captopril (降血压药)"
                    }]
                },
                "subject": {
                    "reference": f"Patient/patient-chronic-{patient_id}"
                },
                "encounter": {
                    "reference": f"Encounter/encounter-chronic-{patient_id}"
                },
                "authoredOn": "2026-01-05T09:15:00Z",
                "dosageInstruction": [{
                    "timing": {
                        "repeat": {
                            "boundsPeriod": {
                                "start": "2026-01-05",
                                "end": "2026-02-03"  # 30天一般处方
                            }
                        }
                    }
                }],
                "dispenseRequest": {
                    "validityPeriod": {
                        "start": "2026-01-05",
                        "end": "2026-02-03"
                    },
                    "quantity": {
                        "value": 30,
                        "unit": "tablets"
                    }
                }
            },
            "request": {
                "method": "PUT",
                "url": f"MedicationRequest/med-chronic-{patient_id}"
            }
        })
    
    return entries

# 生成测试资料
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

org_added = False

# 生成18个患者：11个使用连续处方，7个使用一般处方 (61%)
for i in range(1, 19):
    patient_entries = generate_patient(f"{i:03d}", has_continuous=(i <= 11))
    
    if not org_added:
        bundle["entry"].extend(patient_entries)
        org_added = True
    else:
        bundle["entry"].extend(patient_entries[1:])  # 跳过Organization

# 储存
output_file = "test_data_04_chronic_prescription_2026Q1.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成测试资料：{output_file}")
print(f"   总病患数：18人")
print(f"   使用连续处方：11人 (61%)")
print(f"   使用一般处方：7人 (39%)")
print(f"   总资源数：{len(bundle['entry'])}")
