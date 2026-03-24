"""
生成指标11-3的无适应症剖腹产案件（增加分母）
目标：有适应症剖腹产率 = 6/20 = 30%
需要增加：14个无适应症剖腹产（非产妇要求，但也无明确医疗适应症）
"""
import json

entries = []

# 生成14个无明确适应症的剖腹产
for i in range(1, 15):
    patient_id = f"cesarean-no-indication-{i:03d}"
    enc_id = f"cesarean-no-ind-enc-{i:03d}"
    cond_id = f"cesarean-no-ind-cond-{i:03d}"
    proc_id = f"cesarean-no-ind-proc-{i:03d}"
    
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
    
    # Condition（O82 其他剖腹产，无明确适应症）
    entries.append({
        "resource": {
            "resourceType": "Condition",
            "id": cond_id,
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-cm",
                    "code": "O82",
                    "display": "Other cesarean delivery"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"}
        },
        "request": {"method": "PUT", "url": f"Condition/{cond_id}"}
    })
    
    # Procedure（剖腹产）
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

with open('test_data_11_3_cesarean_no_indication.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f'✅ 已生成14个无适应症剖腹产案件')
print(f'')
print(f'指标11-3调整后：')
print(f'  有适应症剖腹产：6人')
print(f'  无适应症剖腹产：14人')
print(f'  剖腹产总数：20人')
print(f'  预期比率：6/20 = 30.00%')
