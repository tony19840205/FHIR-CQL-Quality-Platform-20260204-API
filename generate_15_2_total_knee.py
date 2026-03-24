import json

# 指标15-2: 全人工膝关节置换90天深部感染率
# 全人工TKA手术码: 64164B、97805K、97806A、97807B、64169B
# 深部感染手术码: 64053B、64198B

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

# 创建5个全人工TKA患者，其中2个有感染（40%）
tka_codes = ["64164B", "97805K", "97806A", "97807B", "64169B"]
infection_codes = ["64053B", "64198B"]

for i in range(1, 6):
    patient_id = f"tka-patient-{i:03d}"
    enc_id = f"tka-enc-{i:03d}"
    proc_id = f"tka-proc-{i:03d}"
    has_infection = (i <= 2)  # 前2个有感染
    
    # Patient
    bundle["entry"].append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "identifier": [{
                "system": "http://hospital.example.org/patients",
                "value": f"TW1004{i}"
            }],
            "gender": "female" if i % 2 == 0 else "male",
            "birthDate": f"196{i}-0{i+2}-15"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/{patient_id}"
        }
    })
    
    # Encounter (TKA手术)
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
                "start": f"2026-01-0{i+1}T08:00:00+08:00",
                "end": f"2026-01-0{i+1}T20:00:00+08:00"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/{enc_id}"
        }
    })
    
    # Procedure (全人工TKA)
    bundle["entry"].append({
        "resource": {
            "resourceType": "Procedure",
            "id": proc_id,
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "urn:oid:2.16.886.101.20003.20014",  # 健保手术码系统
                    "code": tka_codes[i-1],
                    "display": "全人工膝關節置換術"
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/{enc_id}"
            },
            "performedDateTime": f"2026-01-0{i+1}T10:00:00+08:00"
        },
        "request": {
            "method": "PUT",
            "url": f"Procedure/{proc_id}"
        }
    })
    
    # 如果有感染，创建90天内的感染encounter和procedure
    if has_infection:
        inf_enc_id = f"tka-inf-enc-{i:03d}"
        inf_proc_id = f"tka-inf-proc-{i:03d}"
        
        # 感染Encounter（在手术后30-60天内）
        days_after = 30 + (i * 15)
        bundle["entry"].append({
            "resource": {
                "resourceType": "Encounter",
                "id": inf_enc_id,
                "status": "finished",
                "class": {
                    "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                    "code": "IMP"
                },
                "subject": {
                    "reference": f"Patient/{patient_id}"
                },
                "period": {
                    "start": f"2026-02-{10+i:02d}T09:00:00+08:00",
                    "end": f"2026-02-{10+i:02d}T18:00:00+08:00"
                }
            },
            "request": {
                "method": "PUT",
                "url": f"Encounter/{inf_enc_id}"
            }
        })
        
        # 感染处理Procedure（深部感染处理）
        bundle["entry"].append({
            "resource": {
                "resourceType": "Procedure",
                "id": inf_proc_id,
                "status": "completed",
                "code": {
                    "coding": [{
                        "system": "urn:oid:2.16.886.101.20003.20014",
                        "code": infection_codes[i-1],
                        "display": "膝關節置換物深部感染處理"
                    }]
                },
                "subject": {
                    "reference": f"Patient/{patient_id}"
                },
                "encounter": {
                    "reference": f"Encounter/{inf_enc_id}"
                },
                "performedDateTime": f"2026-02-{10+i:02d}T11:00:00+08:00"
            },
            "request": {
                "method": "PUT",
                "url": f"Procedure/{inf_proc_id}"
            }
        })

with open('test_data_15_2_total_knee.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

print(f"✅ 生成 {len(bundle['entry'])} 个资源")
print(f"  - 5个全人工TKA患者")
print(f"  - 2个有90天内深部感染")
print(f"  预期感染率 = 2/5 = 40.00%")
