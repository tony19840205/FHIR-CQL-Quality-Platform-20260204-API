"""
生成指標03-10：跨院降血脂藥重疊率測試資料
"""

import json

def generate_patient(patient_id, has_overlap=True):
    entries = []
    
    # 兩家醫院
    entries.append({
        "fullUrl": f"urn:uuid:org-hospital-a",
        "resource": {
            "resourceType": "Organization",
            "id": "org-hospital-a",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/hospital",
                "value": "HOSP-A-001"
            }],
            "name": "甲醫院"
        },
        "request": {"method": "PUT", "url": "Organization/org-hospital-a"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:org-hospital-b",
        "resource": {
            "resourceType": "Organization",
            "id": "org-hospital-b",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/hospital",
                "value": "HOSP-B-002"
            }],
            "name": "乙醫院"
        },
        "request": {"method": "PUT", "url": "Organization/org-hospital-b"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:patient-cross-lipid-{patient_id}",
        "resource": {
            "resourceType": "Patient",
            "id": f"patient-cross-lipid-{patient_id}",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/patient",
                "value": f"CROSS-LIPID-{patient_id}"
            }],
            "name": [{"family": "測試", "given": [f"跨脂{patient_id}"]}],
            "gender": "female",
            "birthDate": "1962-08-15"
        },
        "request": {"method": "PUT", "url": f"Patient/patient-cross-lipid-{patient_id}"}
    })
    
    # 第一次就診 - 甲醫院
    entries.append({
        "fullUrl": f"urn:uuid:encounter-cross-lipid-{patient_id}-1",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-cross-lipid-{patient_id}-1",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"},
            "subject": {"reference": f"Patient/patient-cross-lipid-{patient_id}"},
            "serviceProvider": {"reference": "Organization/org-hospital-a"},
            "period": {"start": "2026-01-06T10:00:00Z", "end": "2026-01-06T10:30:00Z"}
        },
        "request": {"method": "PUT", "url": f"Encounter/encounter-cross-lipid-{patient_id}-1"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:med-cross-lipid-{patient_id}-1",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-cross-lipid-{patient_id}-1",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.whocc.no/atc", "code": "C10AA05", "display": "Atorvastatin"}]
            },
            "subject": {"reference": f"Patient/patient-cross-lipid-{patient_id}"},
            "encounter": {"reference": f"Encounter/encounter-cross-lipid-{patient_id}-1"},
            "authoredOn": "2026-01-06T10:15:00Z",
            "dosageInstruction": [{
                "timing": {"repeat": {"boundsPeriod": {"start": "2026-01-06", "end": "2026-02-04"}}}
            }],
            "dispenseRequest": {
                "validityPeriod": {"start": "2026-01-06", "end": "2026-02-04"},
                "quantity": {"value": 30, "unit": "tablets"}
            }
        },
        "request": {"method": "PUT", "url": f"MedicationRequest/med-cross-lipid-{patient_id}-1"}
    })
    
    # 第二次就診 - 乙醫院（跨院）
    if has_overlap:
        enc2_date = "2026-01-22"
        med2_start = "2026-01-22"
        med2_end = "2026-02-20"
    else:
        enc2_date = "2026-02-10"
        med2_start = "2026-02-10"
        med2_end = "2026-03-11"
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-cross-lipid-{patient_id}-2",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-cross-lipid-{patient_id}-2",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"},
            "subject": {"reference": f"Patient/patient-cross-lipid-{patient_id}"},
            "serviceProvider": {"reference": "Organization/org-hospital-b"},  # 不同醫院！
            "period": {"start": f"{enc2_date}T15:00:00Z", "end": f"{enc2_date}T15:30:00Z"}
        },
        "request": {"method": "PUT", "url": f"Encounter/encounter-cross-lipid-{patient_id}-2"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:med-cross-lipid-{patient_id}-2",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-cross-lipid-{patient_id}-2",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.whocc.no/atc", "code": "C10AA01", "display": "Simvastatin"}]
            },
            "subject": {"reference": f"Patient/patient-cross-lipid-{patient_id}"},
            "encounter": {"reference": f"Encounter/encounter-cross-lipid-{patient_id}-2"},
            "authoredOn": f"{enc2_date}T15:15:00Z",
            "dosageInstruction": [{
                "timing": {"repeat": {"boundsPeriod": {"start": med2_start, "end": med2_end}}}
            }],
            "dispenseRequest": {
                "validityPeriod": {"start": med2_start, "end": med2_end},
                "quantity": {"value": 30, "unit": "tablets"}
            }
        },
        "request": {"method": "PUT", "url": f"MedicationRequest/med-cross-lipid-{patient_id}-2"}
    })
    
    return entries

bundle = {"resourceType": "Bundle", "type": "transaction", "entry": []}
org_added = False

# 14人，5個重疊 = 36%
for i in range(1, 15):
    patient_entries = generate_patient(f"{i:03d}", has_overlap=(i <= 5))
    if not org_added:
        bundle["entry"].extend(patient_entries)
        org_added = True
    else:
        bundle["entry"].extend(patient_entries[2:])  # 跳過兩個Organization

output_file = "test_data_03_10_cross_hospital_2026Q1.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成測試資料：{output_file}")
print(f"   總病患數：14人")
print(f"   有重疊：5人 (36%)")
print(f"   無重疊：9人 (64%)")
print(f"   總資源數：{len(bundle['entry'])}")
