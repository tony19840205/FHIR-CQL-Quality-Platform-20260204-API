"""
生成指標03-2：同院降血脂藥重疊率測試資料
- 同一病患在同一家醫院
- 兩次就診開立降血脂藥
- 用藥期間有重疊
"""

import json
from datetime import datetime, timedelta

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
        "fullUrl": f"urn:uuid:patient-lipid-{patient_id}",
        "resource": {
            "resourceType": "Patient",
            "id": f"patient-lipid-{patient_id}",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/patient",
                "value": f"LIPID-{patient_id}"
            }],
            "name": [{
                "family": "測試",
                "given": [f"降脂{patient_id}"]
            }],
            "gender": "female",
            "birthDate": "1962-08-15"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/patient-lipid-{patient_id}"
        }
    })
    
    # 3. 第一次就診 - 2026-01-06
    entries.append({
        "fullUrl": f"urn:uuid:encounter-lipid-{patient_id}-1",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-lipid-{patient_id}-1",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "subject": {
                "reference": f"Patient/patient-lipid-{patient_id}"
            },
            "serviceProvider": {
                "reference": "Organization/org-hospital-cgmh"
            },
            "period": {
                "start": "2026-01-06T10:00:00Z",
                "end": "2026-01-06T10:30:00Z"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/encounter-lipid-{patient_id}-1"
        }
    })
    
    # 4. 第一次降血脂藥處方 - 給藥30天 (2026-01-06 ~ 2026-02-04)
    entries.append({
        "fullUrl": f"urn:uuid:med-lipid-{patient_id}-1",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-lipid-{patient_id}-1",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{
                    "system": "http://www.whocc.no/atc",
                    "code": "C10AA05",
                    "display": "Atorvastatin (降血脂藥-Statin)"
                }]
            },
            "subject": {
                "reference": f"Patient/patient-lipid-{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/encounter-lipid-{patient_id}-1"
            },
            "authoredOn": "2026-01-06T10:15:00Z",
            "dosageInstruction": [{
                "timing": {
                    "repeat": {
                        "boundsPeriod": {
                            "start": "2026-01-06",
                            "end": "2026-02-04"  # 30天
                        }
                    }
                }
            }],
            "dispenseRequest": {
                "validityPeriod": {
                    "start": "2026-01-06",
                    "end": "2026-02-04"
                },
                "quantity": {
                    "value": 30,
                    "unit": "tablets"
                }
            }
        },
        "request": {
            "method": "PUT",
            "url": f"MedicationRequest/med-lipid-{patient_id}-1"
        }
    })
    
    # 5. 第二次就診
    if has_overlap:
        # 重疊案例：2026-01-22就診（第一次用藥還沒結束）
        enc2_date = "2026-01-22"
        med2_start = "2026-01-22"
        med2_end = "2026-02-20"  # 30天
    else:
        # 非重疊案例：2026-02-10就診（第一次用藥已結束）
        enc2_date = "2026-02-10"
        med2_start = "2026-02-10"
        med2_end = "2026-03-11"
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-lipid-{patient_id}-2",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-lipid-{patient_id}-2",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "subject": {
                "reference": f"Patient/patient-lipid-{patient_id}"
            },
            "serviceProvider": {
                "reference": "Organization/org-hospital-cgmh"  # 同一家醫院！
            },
            "period": {
                "start": f"{enc2_date}T15:00:00Z",
                "end": f"{enc2_date}T15:30:00Z"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/encounter-lipid-{patient_id}-2"
        }
    })
    
    # 6. 第二次降血脂藥處方
    entries.append({
        "fullUrl": f"urn:uuid:med-lipid-{patient_id}-2",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-lipid-{patient_id}-2",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{
                    "system": "http://www.whocc.no/atc",
                    "code": "C10AA01",
                    "display": "Simvastatin (降血脂藥-Statin)"
                }]
            },
            "subject": {
                "reference": f"Patient/patient-lipid-{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/encounter-lipid-{patient_id}-2"
            },
            "authoredOn": f"{enc2_date}T15:15:00Z",
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
            "url": f"MedicationRequest/med-lipid-{patient_id}-2"
        }
    })
    
    return entries

# 生成測試資料
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

# 移除Organization重複（只加一次）
org_added = False

# 生成20個病患：7個有重疊，13個沒重疊 (35%)
for i in range(1, 21):
    patient_entries = generate_patient(f"{i:03d}", has_overlap=(i <= 7))
    
    # 第一個病患加Organization，其他跳過
    if not org_added:
        bundle["entry"].extend(patient_entries)
        org_added = True
    else:
        # 跳過Organization
        bundle["entry"].extend(patient_entries[1:])

# 儲存
output_file = "test_data_03_2_same_hospital_2026Q1.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成測試資料：{output_file}")
print(f"   總病患數：20人")
print(f"   有重疊：7人 (35%)")
print(f"   無重疊：13人 (65%)")
print(f"   總資源數：{len(bundle['entry'])}")
