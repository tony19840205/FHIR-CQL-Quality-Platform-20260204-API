"""
重新生成指标11-3数据
只使用CQL认可的诊断码：O82.0-O82.2（有适应症）和O82.8（无适应症）
目标：30%的有适应症剖腹产率
"""
import json

entries = []

# 1. 生成6个有适应症的剖腹产（O82.0, O82.1, O82.2）
indication_codes = [
    ("O82.0", "Emergency cesarean delivery"),
    ("O82.1", "Elective cesarean delivery"),  
    ("O82.2", "Cesarean hysterectomy"),
]

for i in range(1, 7):
    patient_id = f"cs-indication-{i:03d}"
    enc_id = f"cs-ind-enc-{i:03d}"
    cond_id = f"cs-ind-cond-{i:03d}"
    proc_id = f"cs-ind-proc-{i:03d}"
    
    dx_code, dx_display = indication_codes[(i-1) % 3]
    
    # Patient
    entries.append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "gender": "female",
            "birthDate": "1988-03-15"
        },
        "request": {"method": "PUT", "url": f"Patient/{patient_id}"}
    })
    
    # Encounter
    entries.append({
        "resource": {
            "resourceType": "Encounter",
            "id": enc_id,
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP"},
            "subject": {"reference": f"Patient/{patient_id}"},
            "period": {
                "start": f"2026-01-0{(i % 9) + 1}T09:00:00Z",
                "end": f"2026-01-0{(i % 9) + 1}T16:00:00Z"
            }
        },
        "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}
    })
    
    # Condition
    entries.append({
        "resource": {
            "resourceType": "Condition",
            "id": cond_id,
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-cm",
                    "code": dx_code,
                    "display": dx_display
                }]
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"}
        },
        "request": {"method": "PUT", "url": f"Condition/{cond_id}"}
    })
    
    # Procedure
    entries.append({
        "resource": {
            "resourceType": "Procedure",
            "id": proc_id,
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "urn:oid:2.16.886.101.20003.20014",
                    "code": "80402C",
                    "display": "剖腹生产"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"},
            "performedDateTime": f"2026-01-0{(i % 9) + 1}T12:30:00Z"
        },
        "request": {"method": "PUT", "url": f"Procedure/{proc_id}"}
    })

# 2. 生成14个无适应症的剖腹产（O82.8）
for i in range(1, 15):
    patient_id = f"cs-no-ind-{i:03d}"
    enc_id = f"cs-no-ind-enc-{i:03d}"
    cond_id = f"cs-no-ind-cond-{i:03d}"
    proc_id = f"cs-no-ind-proc-{i:03d}"
    
    # Patient
    entries.append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "gender": "female",
            "birthDate": "1990-08-10"
        },
        "request": {"method": "PUT", "url": f"Patient/{patient_id}"}
    })
    
    # Encounter
    entries.append({
        "resource": {
            "resourceType": "Encounter",
            "id": enc_id,
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP"},
            "subject": {"reference": f"Patient/{patient_id}"},
            "period": {
                "start": f"2026-01-0{(i % 9) + 1}T10:00:00Z",
                "end": f"2026-01-0{(i % 9) + 1}T17:00:00Z"
            }
        },
        "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}
    })
    
    # Condition（O82.8 = 其他剖腹产，无适应症）
    entries.append({
        "resource": {
            "resourceType": "Condition",
            "id": cond_id,
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-cm",
                    "code": "O82.8",
                    "display": "Other cesarean delivery"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"}
        },
        "request": {"method": "PUT", "url": f"Condition/{cond_id}"}
    })
    
    # Procedure
    entries.append({
        "resource": {
            "resourceType": "Procedure",
            "id": proc_id,
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "urn:oid:2.16.886.101.20003.20014",
                    "code": "80402C",
                    "display": "剖腹生产"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"},
            "performedDateTime": f"2026-01-0{(i % 9) + 1}T13:00:00Z"
        },
        "request": {"method": "PUT", "url": f"Procedure/{proc_id}"}
    })

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": entries
}

with open('test_data_11_3_final.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f'✅ 已重新生成指标11-3数据')
print(f'')
print(f'数据结构：')
print(f'  有适应症剖腹产（O82.0-O82.2）：6人')
print(f'  无适应症剖腹产（O82.8）：14人')
print(f'  剖腹产总数：20人')
print(f'  预期比率：6/20 = 30.00%')
