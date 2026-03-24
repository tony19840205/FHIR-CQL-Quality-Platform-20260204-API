import json
from datetime import datetime, timedelta

# 生成6个全膝置换术患者（TW10001-TW10006），2个有感染
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

# 患者数据
patients_data = [
    {"id": "TW10001", "identifier": "TW10001", "gender": "male", "birthDate": "1955-03-15", "hasInfection": True, "surgeryDate": "2026-01-05", "infectionDays": 45},
    {"id": "TW10002", "identifier": "TW10002", "gender": "female", "birthDate": "1960-06-20", "hasInfection": False, "surgeryDate": "2026-01-08"},
    {"id": "TW10003", "identifier": "TW10003", "gender": "male", "birthDate": "1958-09-10", "hasInfection": True, "surgeryDate": "2026-01-12", "infectionDays": 60},
    {"id": "TW10004", "identifier": "TW10004", "gender": "female", "birthDate": "1962-11-25", "hasInfection": False, "surgeryDate": "2026-01-15"},
    {"id": "TW10005", "identifier": "TW10005", "gender": "male", "birthDate": "1957-04-08", "hasInfection": False, "surgeryDate": "2026-01-18"},
    {"id": "TW10006", "identifier": "TW10006", "gender": "female", "birthDate": "1963-07-14", "hasInfection": False, "surgeryDate": "2026-01-22"},
]

for idx, p in enumerate(patients_data, 1):
    # Patient资源 (不需要identifier，只用Patient.id)
    patient_id = f"total-knee-patient-{idx:03d}"
    bundle["entry"].append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "gender": p["gender"],
            "birthDate": p["birthDate"]
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/{patient_id}"
        }
    })
    
    # 手术Encounter
    surgery_date = datetime.strptime(p["surgeryDate"], "%Y-%m-%d")
    bundle["entry"].append({
        "resource": {
            "resourceType": "Encounter",
            "id": f"tka-enc-{idx:03d}",
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "IMP"
            },
            "subject": {
                "reference": f"Patient/{p['id']}"
            },
            "period": {
                "start": f"{p['surgeryDate']}T08:00:00+08:00",
                "end": f"{p['surgeryDate']}T20:00:00+08:00"
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/tka-enc-{idx:03d}"
        }
    })
    
    # 全膝置换术Procedure (使用NHI代码64164B)
    bundle["entry"].append({
        "resource": {
            "resourceType": "Procedure",
            "id": f"tka-proc-{idx:03d}",
            "status": "completed",
            "code": {
                "coding": [{
                    "system": "urn:oid:2.16.886.101.20003.20014",
                    "code": "64164B",
                    "display": "全人工膝關節置換術"
                }]
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "encounter": {
                "reference": f"Encounter/tka-enc-{idx:03d}"
            },
            "performedDateTime": f"{p['surgeryDate']}T10:00:00+08:00"
        },
        "request": {
            "method": "PUT",
            "url": f"Procedure/tka-proc-{idx:03d}"
        }
    })
    
    # 如果有感染，添加感染相关资源
    if p["hasInfection"]:
        infection_date = surgery_date + timedelta(days=p["infectionDays"])
        infection_date_str = infection_date.strftime("%Y-%m-%d")
        
        # 感染Encounter
        bundle["entry"].append({
            "resource": {
                "resourceType": "Encounter",
                "id": f"tka-inf-enc-{idx:03d}",
                "status": "finished",
                "class": {
                    "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                    "code": "IMP"
                },
                "subject": {
                    "reference": f"Patient/{p['id']}"
                },
                "period": {
                    "start": f"{infection_date_str}T09:00:00+08:00",
                    "end": f"{infection_date_str}T18:00:00+08:00"
                }
            },
            "request": {
                "method": "PUT",
                "url": f"Encounter/tka-inf-enc-{idx:03d}"
            }
        })
        
        # 深部感染处理Procedure (使用NHI代码64053B)
        bundle["entry"].append({
            "resource": {
                "resourceType": "Procedure",
                "id": f"tka-inf-proc-{idx:03d}",
                "status": "completed",
                "code": {
                    "coding": [{
                        "system": "urn:oid:2.16.886.101.20003.20014",
                        "code": "64053B",
                        "display": "膝關節置換物深部感染處理"
                    }]
                },
                "subject": {
                    "reference": f"Patient/{patient_id}"
                },
                "encounter": {
                    "reference": f"Encounter/tka-inf-enc-{idx:03d}"
                },
                "performedDateTime": f"{infection_date_str}T11:00:00+08:00"
            },
            "request": {
                "method": "PUT",
                "url": f"Procedure/tka-inf-proc-{idx:03d}"
            }
        })

# 保存文件
with open('test_data_15_2_tw10001_06_2026Q1.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

print(f"✓ 已生成 {len(bundle['entry'])} 个资源")
print(f"✓ 6个患者 (total-knee-patient-001 to 006)")
print(f"✓ 2个有感染 (001在手术后45天, 003在手术后60天)")
print(f"✓ 预期感染率: 2/6 = 33.33%")
