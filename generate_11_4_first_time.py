import json

# 生成3个初产妇案例：1个剖腹产 + 2个自然产 = 33.33%
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

# 案例1: 初产妇剖腹产
bundle["entry"].extend([
    {
        "resource": {
            "resourceType": "Patient",
            "id": "ftcs-2026-001",
            "gender": "female",
            "birthDate": "1995-03-20"
        },
        "request": {"method": "PUT", "url": "Patient/ftcs-2026-001"}
    },
    {
        "resource": {
            "resourceType": "Encounter",
            "id": "ftcs-enc-2026-001",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "IMP"
            },
            "subject": {"reference": "Patient/ftcs-2026-001"},
            "period": {
                "start": "2026-01-05T08:00:00+08:00",
                "end": "2026-01-05T18:00:00+08:00"
            }
        },
        "request": {"method": "PUT", "url": "Encounter/ftcs-enc-2026-001"}
    },
    {
        "resource": {
            "resourceType": "Condition",
            "id": "ftcs-cond-2026-001",
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-cm",
                    "code": "O82.0",
                    "display": "Elective cesarean section"
                }]
            },
            "subject": {"reference": "Patient/ftcs-2026-001"},
            "encounter": {"reference": "Encounter/ftcs-enc-2026-001"}
        },
        "request": {"method": "PUT", "url": "Condition/ftcs-cond-2026-001"}
    },
    {
        "resource": {
            "resourceType": "Procedure",
            "id": "ftcs-proc-2026-001",
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "urn:oid:2.16.886.101.20003.20014",
                    "code": "81004C",
                    "display": "剖腹產術"
                }]
            },
            "subject": {"reference": "Patient/ftcs-2026-001"},
            "encounter": {"reference": "Encounter/ftcs-enc-2026-001"},
            "performedDateTime": "2026-01-05T12:00:00+08:00"
        },
        "request": {"method": "PUT", "url": "Procedure/ftcs-proc-2026-001"}
    }
])

# 案例2-3: 初产妇自然产
for i in range(2, 4):
    patient_id = f"ftcs-2026-{i:03d}"
    enc_id = f"ftcs-enc-2026-{i:03d}"
    cond_id = f"ftcs-cond-2026-{i:03d}"
    proc_id = f"ftcs-proc-2026-{i:03d}"
    
    bundle["entry"].extend([
        {
            "resource": {
                "resourceType": "Patient",
                "id": patient_id,
                "gender": "female",
                "birthDate": f"199{i+3}-0{i+3}-15"
            },
            "request": {"method": "PUT", "url": f"Patient/{patient_id}"}
        },
        {
            "resource": {
                "resourceType": "Encounter",
                "id": enc_id,
                "status": "finished",
                "class": {
                    "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                    "code": "IMP"
                },
                "subject": {"reference": f"Patient/{patient_id}"},
                "period": {
                    "start": f"2026-01-0{i+3}T08:00:00+08:00",
                    "end": f"2026-01-0{i+3}T16:00:00+08:00"
                }
            },
            "request": {"method": "PUT", "url": f"Encounter/{enc_id}"}
        },
        {
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
        },
        {
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
                "subject": {"reference": f"Patient/{patient_id}"},
                "encounter": {"reference": f"Encounter/{enc_id}"},
                "performedDateTime": f"2026-01-0{i+3}T12:00:00+08:00"
            },
            "request": {"method": "PUT", "url": f"Procedure/{proc_id}"}
        }
    ])

with open('test_data_11_4.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

print(f"✅ 生成 {len(bundle['entry'])} 个资源（3个初产妇）")
print(f"  - 1个剖腹产（81004C）")
print(f"  - 2个自然产（80401C）")
print(f"  预期11-4 = 1/3 = 33.33%")
