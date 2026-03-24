"""
生成指標03-1：同院降血壓藥重疊率測試資料
- 同一病患在同一家醫院
- 兩次就診開立降血壓藥
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
        "fullUrl": f"urn:uuid:patient-{patient_id}",
        "resource": {
            "resourceType": "Patient",
            "id": f"patient-{patient_id}",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/patient",
                "value": f"ANTIHYPER-{patient_id}"
            }],
            "name": [{
                "family": "測試",
                "given": [f"病患{patient_id}"]
            }],
            "gender": "male",
            "birthDate": "1960-05-10"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/patient-{patient_id}"
        }
    })
    
    # 3. 第一次就診 - 2026-01-05
    entries.append({
        "fullUrl": f"urn:uuid:encounter-{patient_id}-1",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-{patient_id}-1",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "subject": {
                "reference": f"Patient/patient-{patient_id}"
            },
            "serviceProvider": {
                "reference": "Organization/org-hospital-cgmh"
            },
            "period": {
                "start": "2026-01-05T09:00:00Z",
                "end": "2026-01-05T09:30:00Z"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/encounter-{patient_id}-1"
        }
    })
    
    # 4. 第一次降血壓藥處方 - 給藥30天 (2026-01-05 ~ 2026-02-03)
    entries.append({
        "fullUrl": f"urn:uuid:med-{patient_id}-1",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-{patient_id}-1",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{
                    "system": "http://www.whocc.no/atc",
                    "code": "C09AA01",
                    "display": "Captopril (降血壓藥-ACEI)"
                }]
            },
            "subject": {
                "reference": f"Patient/patient-{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/encounter-{patient_id}-1"
            },
            "authoredOn": "2026-01-05T09:15:00Z",
            "dosageInstruction": [{
                "timing": {
                    "repeat": {
                        "boundsPeriod": {
                            "start": "2026-01-05",
                            "end": "2026-02-03"  # 30天
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
            "url": f"MedicationRequest/med-{patient_id}-1"
        }
    })
    
    # 5. 第二次就診
    if has_overlap:
        # 重疊案例：2026-01-20就診（第一次用藥還沒結束）
        enc2_date = "2026-01-20"
        med2_start = "2026-01-20"
        med2_end = "2026-02-18"  # 30天
    else:
        # 非重疊案例：2026-02-10就診（第一次用藥已結束）
        enc2_date = "2026-02-10"
        med2_start = "2026-02-10"
        med2_end = "2026-03-11"
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-{patient_id}-2",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-{patient_id}-2",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "subject": {
                "reference": f"Patient/patient-{patient_id}"
            },
            "serviceProvider": {
                "reference": "Organization/org-hospital-cgmh"  # 同一家醫院！
            },
            "period": {
                "start": f"{enc2_date}T14:00:00Z",
                "end": f"{enc2_date}T14:30:00Z"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/encounter-{patient_id}-2"
        }
    })
    
    # 6. 第二次降血壓藥處方
    entries.append({
        "fullUrl": f"urn:uuid:med-{patient_id}-2",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-{patient_id}-2",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{
                    "system": "http://www.whocc.no/atc",
                    "code": "C07AB02",
                    "display": "Metoprolol (降血壓藥-Beta blocker)"
                }]
            },
            "subject": {
                "reference": f"Patient/patient-{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/encounter-{patient_id}-2"
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
            "url": f"MedicationRequest/med-{patient_id}-2"
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

# 生成50個病患：30個有重疊，20個沒重疊
for i in range(1, 51):
    patient_entries = generate_patient(f"{i:03d}", has_overlap=(i <= 30))
    
    # 第一個病患加Organization，其他跳過
    if not org_added:
        bundle["entry"].extend(patient_entries)
        org_added = True
    else:
        # 跳過Organization
        bundle["entry"].extend(patient_entries[1:])

# 儲存
output_file = "test_data_03_1_same_hospital_2026Q1.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成測試資料：{output_file}")
print(f"   總病患數：50人")
print(f"   有重疊：30人 (60%)")
print(f"   無重疊：20人 (40%)")
print(f"   總資源數：{len(bundle['entry'])}")
