"""
生成指標03-8：同院前列腺藥重疊率測試資料
"""

import json

def generate_patient(patient_id, has_overlap=True):
    entries = []
    
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
        "request": {"method": "PUT", "url": "Organization/org-hospital-cgmh"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:patient-prostate-{patient_id}",
        "resource": {
            "resourceType": "Patient",
            "id": f"patient-prostate-{patient_id}",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/patient",
                "value": f"PROSTATE-{patient_id}"
            }],
            "name": [{"family": "測試", "given": [f"前列{patient_id}"]}],
            "gender": "male",
            "birthDate": "1948-07-22"
        },
        "request": {"method": "PUT", "url": f"Patient/patient-prostate-{patient_id}"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-prostate-{patient_id}-1",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-prostate-{patient_id}-1",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"},
            "subject": {"reference": f"Patient/patient-prostate-{patient_id}"},
            "serviceProvider": {"reference": "Organization/org-hospital-cgmh"},
            "period": {"start": "2026-01-12T09:00:00Z", "end": "2026-01-12T09:30:00Z"}
        },
        "request": {"method": "PUT", "url": f"Encounter/encounter-prostate-{patient_id}-1"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:med-prostate-{patient_id}-1",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-prostate-{patient_id}-1",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.whocc.no/atc", "code": "G04CA02", "display": "Tamsulosin (前列腺藥)"}]
            },
            "subject": {"reference": f"Patient/patient-prostate-{patient_id}"},
            "encounter": {"reference": f"Encounter/encounter-prostate-{patient_id}-1"},
            "authoredOn": "2026-01-12T09:15:00Z",
            "dosageInstruction": [{
                "timing": {"repeat": {"boundsPeriod": {"start": "2026-01-12", "end": "2026-02-10"}}}
            }],
            "dispenseRequest": {
                "validityPeriod": {"start": "2026-01-12", "end": "2026-02-10"},
                "quantity": {"value": 30, "unit": "tablets"}
            }
        },
        "request": {"method": "PUT", "url": f"MedicationRequest/med-prostate-{patient_id}-1"}
    })
    
    if has_overlap:
        enc2_date = "2026-01-28"
        med2_start = "2026-01-28"
        med2_end = "2026-02-26"
    else:
        enc2_date = "2026-02-13"
        med2_start = "2026-02-13"
        med2_end = "2026-03-14"
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-prostate-{patient_id}-2",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-prostate-{patient_id}-2",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"},
            "subject": {"reference": f"Patient/patient-prostate-{patient_id}"},
            "serviceProvider": {"reference": "Organization/org-hospital-cgmh"},
            "period": {"start": f"{enc2_date}T15:00:00Z", "end": f"{enc2_date}T15:30:00Z"}
        },
        "request": {"method": "PUT", "url": f"Encounter/encounter-prostate-{patient_id}-2"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:med-prostate-{patient_id}-2",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-prostate-{patient_id}-2",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.whocc.no/atc", "code": "G04CA03", "display": "Alfuzosin (前列腺藥)"}]
            },
            "subject": {"reference": f"Patient/patient-prostate-{patient_id}"},
            "encounter": {"reference": f"Encounter/encounter-prostate-{patient_id}-2"},
            "authoredOn": f"{enc2_date}T15:15:00Z",
            "dosageInstruction": [{
                "timing": {"repeat": {"boundsPeriod": {"start": med2_start, "end": med2_end}}}
            }],
            "dispenseRequest": {
                "validityPeriod": {"start": med2_start, "end": med2_end},
                "quantity": {"value": 30, "unit": "tablets"}
            }
        },
        "request": {"method": "PUT", "url": f"MedicationRequest/med-prostate-{patient_id}-2"}
    })
    
    return entries

bundle = {"resourceType": "Bundle", "type": "transaction", "entry": []}
org_added = False

# 10人，3個重疊 = 30%
for i in range(1, 11):
    patient_entries = generate_patient(f"{i:03d}", has_overlap=(i <= 3))
    if not org_added:
        bundle["entry"].extend(patient_entries)
        org_added = True
    else:
        bundle["entry"].extend(patient_entries[1:])

output_file = "test_data_03_8_same_hospital_2026Q1.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成測試資料：{output_file}")
print(f"   總病患數：10人")
print(f"   有重疊：3人 (30%)")
print(f"   無重疊：7人 (70%)")
print(f"   總資源數：{len(bundle['entry'])}")
