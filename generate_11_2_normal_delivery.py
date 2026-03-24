"""
生成指标11-2的自然产案件（增加分母）
目标：使产妇要求剖腹产率 = 11/37 ≈ 30%
需要增加：26个自然产案件
"""
import json

timestamp = "20260102120000"
entries = []

for i in range(1, 27):  # 26个自然产
    patient_id = f"normal-delivery-{i:03d}"
    enc_id = f"normal-delivery-enc-{i:03d}"
    cond_id = f"normal-delivery-cond-{i:03d}"
    proc_id = f"normal-delivery-proc-{i:03d}"
    
    # Patient
    entries.append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "gender": "female",
            "birthDate": "1992-05-20"
        },
        "request": {"method": "PUT", "url": f"Patient/{patient_id}"}
    })
    
    # Encounter（住院生产）
    entries.append({
        "resource": {
            "resourceType": "Encounter",
            "id": enc_id,
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP"},
            "subject": {"reference": f"Patient/{patient_id}"},
            "period": {
                "start": f"2026-01-0{(i % 9) + 1}T08:00:00Z",
                "end": f"2026-01-0{(i % 9) + 1}T15:00:00Z"
            }
        },
        "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}
    })
    
    # Condition（自然产诊断 O80）
    entries.append({
        "resource": {
            "resourceType": "Condition",
            "id": cond_id,
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-cm",
                    "code": "O80",
                    "display": "Spontaneous vertex delivery"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"}
        },
        "request": {"method": "PUT", "url": f"Condition/{cond_id}"}
    })
    
    # Procedure（自然产手术）
    entries.append({
        "resource": {
            "resourceType": "Procedure",
            "id": proc_id,
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "177184002",
                    "display": "Normal delivery"
                }]
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"},
            "performedDateTime": f"2026-01-0{(i % 9) + 1}T12:00:00Z"
        },
        "request": {"method": "PUT", "url": f"Procedure/{proc_id}"}
    })

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": entries
}

with open('test_data_11_2_normal_delivery.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f'✅ 已生成26个自然产案件')
print(f'   调整后比率：11/(11+26) = 11/37 ≈ 29.73%')
