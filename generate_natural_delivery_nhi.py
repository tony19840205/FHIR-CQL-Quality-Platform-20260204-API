import json
from datetime import datetime, timedelta

# 生成20个自然产案例（用NHI码80401C）
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

for i in range(1, 21):
    patient_id = f"natural-nhi-{i:03d}"
    enc_id = f"natural-nhi-enc-{i:03d}"
    cond_id = f"natural-nhi-cond-{i:03d}"
    proc_id = f"natural-nhi-proc-{i:03d}"
    
    # Patient
    year = 1990 + (i % 10)
    month = ((i % 12) + 1)
    bundle["entry"].append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "gender": "female",
            "birthDate": f"{year}-{month:02d}-15"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/{patient_id}"
        }
    })
    
    # Encounter
    bundle["entry"].append({
        "resource": {
            "resourceType": "Encounter",
            "id": enc_id,
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "IMP"
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "period": {
                "start": f"2026-01-0{(i%5)+1}T08:00:00Z",
                "end": f"2026-01-0{(i%5)+1}T16:00:00Z"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/{enc_id}"
        }
    })
    
    # Condition - O80自然产
    bundle["entry"].append({
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
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{enc_id}"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Condition/{cond_id}"
        }
    })
    
    # Procedure - NHI码80401C
    bundle["entry"].append({
        "resource": {
            "resourceType": "Procedure",
            "id": proc_id,
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "urn:oid:2.16.886.101.20003.20014",
                    "code": "80401C",
                    "display": "自然生產"
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{enc_id}"
            },
            "performedDateTime": f"2026-01-0{(i%5)+1}T12:00:00Z"
        },
        "request": {
            "method": "PUT",
            "url": f"Procedure/{proc_id}"
        }
    })

# 保存
with open('test_data_natural_delivery_nhi.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

print(f"✅ 生成 {len(bundle['entry'])} 个资源（20个自然产患者）")
print(f"预期11-2 = 11 / (11 + 20) = 35.48%")
