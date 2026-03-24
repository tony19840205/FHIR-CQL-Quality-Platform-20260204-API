"""
生成指標03-3：同院降血糖藥重疊率測試資料
"""

import json

def generate_patient(patient_id, has_overlap=True):
    """生成一個病患的完整資料"""
    entries = []
    
    # 1. Organization (醫院)
    entries.append({
        "fullUrl": f"urn:uuid:org-hospital-cgmh",
        "resource": {
            "resourceType": "Organization",
            "id": "org-hospital-cgmh",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/hospital",
                "value": "CGMH-001"
            }],
            "name": "長庚紀念醫院"
        },
        "request": {
            "method": "PUT",
            "url": "Organization/org-hospital-cgmh"
        }
    })
    
    # 2. Patient
    entries.append({
        "fullUrl": f"urn:uuid:patient-diab-{patient_id}",
        "resource": {
            "resourceType": "Patient",
            "id": f"patient-diab-{patient_id}",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/patient",
                "value": f"DIAB-{patient_id}"
            }],
            "name": [{
                "family": "測試",
                "given": [f"降糖{patient_id}"]
            }],
            "gender": "male",
            "birthDate": "1955-04-20"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/patient-diab-{patient_id}"
        }
    })
    
    # 3. 第一次就診
    entries.append({
        "fullUrl": f"urn:uuid:encounter-diab-{patient_id}-1",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-diab-{patient_id}-1",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "subject": {
                "reference": f"Patient/patient-diab-{patient_id}"
            },
            "serviceProvider": {
                "reference": "Organization/org-hospital-cgmh"
            },
            "period": {
                "start": "2026-01-07T09:00:00Z",
                "end": "2026-01-07T09:30:00Z"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/encounter-diab-{patient_id}-1"
        }
    })
    
    # 4. 第一次降血糖藥處方
    entries.append({
        "fullUrl": f"urn:uuid:med-diab-{patient_id}-1",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-diab-{patient_id}-1",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{
                    "system": "http://www.whocc.no/atc",
                    "code": "A10BA02",
                    "display": "Metformin (降血糖藥)"
                }]
            },
            "subject": {
                "reference": f"Patient/patient-diab-{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/encounter-diab-{patient_id}-1"
            },
            "authoredOn": "2026-01-07T09:15:00Z",
            "dosageInstruction": [{
                "timing": {
                    "repeat": {
                        "boundsPeriod": {
                            "start": "2026-01-07",
                            "end": "2026-02-05"
                        }
                    }
                }
            }],
            "dispenseRequest": {
                "validityPeriod": {
                    "start": "2026-01-07",
                    "end": "2026-02-05"
                },
                "quantity": {
                    "value": 30,
                    "unit": "tablets"
                }
            }
        },
        "request": {
            "method": "PUT",
            "url": f"MedicationRequest/med-diab-{patient_id}-1"
        }
    })
    
    # 5. 第二次就診
    if has_overlap:
        enc2_date = "2026-01-23"
        med2_start = "2026-01-23"
        med2_end = "2026-02-21"
    else:
        enc2_date = "2026-02-10"
        med2_start = "2026-02-10"
        med2_end = "2026-03-11"
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-diab-{patient_id}-2",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-diab-{patient_id}-2",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "subject": {
                "reference": f"Patient/patient-diab-{patient_id}"
            },
            "serviceProvider": {
                "reference": "Organization/org-hospital-cgmh"
            },
            "period": {
                "start": f"{enc2_date}T14:00:00Z",
                "end": f"{enc2_date}T14:30:00Z"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/encounter-diab-{patient_id}-2"
        }
    })
    
    # 6. 第二次降血糖藥處方
    entries.append({
        "fullUrl": f"urn:uuid:med-diab-{patient_id}-2",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-diab-{patient_id}-2",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{
                    "system": "http://www.whocc.no/atc",
                    "code": "A10BB01",
                    "display": "Glibenclamide (降血糖藥)"
                }]
            },
            "subject": {
                "reference": f"Patient/patient-diab-{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/encounter-diab-{patient_id}-2"
            },
            "authoredOn": f"{enc2_date}T14:15:00Z",
            "dosageInstruction": [{
                "timing": {
                    "repeat": {
                        "boundsPeriod": {
                            "start": med2_start,
                            "end": med2_end
                        }
                    }
                }
            }],
            "dispenseRequest": {
                "validityPeriod": {
                    "start": med2_start,
                    "end": med2_end
                },
                "quantity": {
                    "value": 30,
                    "unit": "tablets"
                }
            }
        },
        "request": {
            "method": "PUT",
            "url": f"MedicationRequest/med-diab-{patient_id}-2"
        }
    })
    
    return entries

# 生成測試資料
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

org_added = False

# 生成20個病患：9個有重疊，11個沒重疊 (45%)
for i in range(1, 21):
    patient_entries = generate_patient(f"{i:03d}", has_overlap=(i <= 9))
    
    if not org_added:
        bundle["entry"].extend(patient_entries)
        org_added = True
    else:
        bundle["entry"].extend(patient_entries[1:])

# 儲存
output_file = "test_data_03_3_same_hospital_2026Q1.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成測試資料：{output_file}")
print(f"   總病患數：20人")
print(f"   有重疊：9人 (45%)")
print(f"   無重疊：11人 (55%)")
print(f"   總資源數：{len(bundle['entry'])}")
