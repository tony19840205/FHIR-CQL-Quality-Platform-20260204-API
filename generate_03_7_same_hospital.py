"""
生成指標03-7：同院抗血栓藥重疊率測試資料
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
        "fullUrl": f"urn:uuid:patient-antithromb-{patient_id}",
        "resource": {
            "resourceType": "Patient",
            "id": f"patient-antithromb-{patient_id}",
            "identifier": [{
                "system": "http://www.mohw.gov.tw/patient",
                "value": f"ANTITHROMB-{patient_id}"
            }],
            "name": [{"family": "測試", "given": [f"抗栓{patient_id}"]}],
            "gender": "male",
            "birthDate": "1950-02-14"
        },
        "request": {"method": "PUT", "url": f"Patient/patient-antithromb-{patient_id}"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-antithromb-{patient_id}-1",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-antithromb-{patient_id}-1",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"},
            "subject": {"reference": f"Patient/patient-antithromb-{patient_id}"},
            "serviceProvider": {"reference": "Organization/org-hospital-cgmh"},
            "period": {"start": "2026-01-11T08:00:00Z", "end": "2026-01-11T08:30:00Z"}
        },
        "request": {"method": "PUT", "url": f"Encounter/encounter-antithromb-{patient_id}-1"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:med-antithromb-{patient_id}-1",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-antithromb-{patient_id}-1",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.whocc.no/atc", "code": "B01AC06", "display": "Aspirin (抗血栓藥)"}]
            },
            "subject": {"reference": f"Patient/patient-antithromb-{patient_id}"},
            "encounter": {"reference": f"Encounter/encounter-antithromb-{patient_id}-1"},
            "authoredOn": "2026-01-11T08:15:00Z",
            "dosageInstruction": [{
                "timing": {"repeat": {"boundsPeriod": {"start": "2026-01-11", "end": "2026-02-09"}}}
            }],
            "dispenseRequest": {
                "validityPeriod": {"start": "2026-01-11", "end": "2026-02-09"},
                "quantity": {"value": 30, "unit": "tablets"}
            }
        },
        "request": {"method": "PUT", "url": f"MedicationRequest/med-antithromb-{patient_id}-1"}
    })
    
    if has_overlap:
        enc2_date = "2026-01-26"
        med2_start = "2026-01-26"
        med2_end = "2026-02-24"
    else:
        enc2_date = "2026-02-12"
        med2_start = "2026-02-12"
        med2_end = "2026-03-13"
    
    entries.append({
        "fullUrl": f"urn:uuid:encounter-antithromb-{patient_id}-2",
        "resource": {
            "resourceType": "Encounter",
            "id": f"encounter-antithromb-{patient_id}-2",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"},
            "subject": {"reference": f"Patient/patient-antithromb-{patient_id}"},
            "serviceProvider": {"reference": "Organization/org-hospital-cgmh"},
            "period": {"start": f"{enc2_date}T14:00:00Z", "end": f"{enc2_date}T14:30:00Z"}
        },
        "request": {"method": "PUT", "url": f"Encounter/encounter-antithromb-{patient_id}-2"}
    })
    
    entries.append({
        "fullUrl": f"urn:uuid:med-antithromb-{patient_id}-2",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": f"med-antithromb-{patient_id}-2",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.whocc.no/atc", "code": "B01AA03", "display": "Warfarin (抗血栓藥)"}]
            },
            "subject": {"reference": f"Patient/patient-antithromb-{patient_id}"},
            "encounter": {"reference": f"Encounter/encounter-antithromb-{patient_id}-2"},
            "authoredOn": f"{enc2_date}T14:15:00Z",
            "dosageInstruction": [{
                "timing": {"repeat": {"boundsPeriod": {"start": med2_start, "end": med2_end}}}
            }],
            "dispenseRequest": {
                "validityPeriod": {"start": med2_start, "end": med2_end},
                "quantity": {"value": 30, "unit": "tablets"}
            }
        },
        "request": {"method": "PUT", "url": f"MedicationRequest/med-antithromb-{patient_id}-2"}
    })
    
    return entries

bundle = {"resourceType": "Bundle", "type": "transaction", "entry": []}
org_added = False

# 12人，4個重疊 = 33%
for i in range(1, 13):
    patient_entries = generate_patient(f"{i:03d}", has_overlap=(i <= 4))
    if not org_added:
        bundle["entry"].extend(patient_entries)
        org_added = True
    else:
        bundle["entry"].extend(patient_entries[1:])

output_file = "test_data_03_7_same_hospital_2026Q1.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成測試資料：{output_file}")
print(f"   總病患數：12人")
print(f"   有重疊：4人 (33%)")
print(f"   無重疊：8人 (67%)")
print(f"   總資源數：{len(bundle['entry'])}")
