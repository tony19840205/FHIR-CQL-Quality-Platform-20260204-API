import json
from datetime import datetime, timedelta

# 複製2024-08-02成功案例的結構，改成2026Q1
# 關鍵發現：Procedure的code需要包含多個coding（NHI + SNOMED + CPT）

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

# 1個感染案例，完全複製成功案例的結構
patient_data = {
    "id": "TW10001",
    "identifier": "TW10001",
    "gender": "male",
    "birthDate": "1961-03-15",
    "tka_date": "2026-01-10",
    "infection_date": "2026-03-06",  # 55天後（與成功案例相同）
}

# Patient資源
bundle["entry"].append({
    "resource": {
        "resourceType": "Patient",
        "id": patient_data["id"],
        "identifier": [
            {
                "system": "http://hospital.example.org/patients",
                "value": patient_data["identifier"]
            }
        ],
        "gender": patient_data["gender"],
        "birthDate": patient_data["birthDate"]
    },
    "request": {
        "method": "PUT",
        "url": f"Patient/{patient_data['id']}"
    }
})

# TKA Encounter
bundle["entry"].append({
    "resource": {
        "resourceType": "Encounter",
        "id": f"tka-encounter-{patient_data['id']}",
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "IMP",
            "display": "inpatient encounter"
        },
        "subject": {
            "reference": f"Patient/{patient_data['id']}"
        },
        "period": {
            "start": f"{patient_data['tka_date']}T08:00:00+08:00",
            "end": f"{patient_data['tka_date']}T14:00:00+08:00"
        }
    },
    "request": {
        "method": "PUT",
        "url": f"Encounter/tka-encounter-{patient_data['id']}"
    }
})

# TKA Procedure - 關鍵：包含3個coding
bundle["entry"].append({
    "resource": {
        "resourceType": "Procedure",
        "id": f"tka-procedure-{patient_data['id']}",
        "status": "completed",
        "code": {
            "coding": [
                {
                    "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure",
                    "code": "64164B",
                    "display": "全人工膝關節置換術"
                },
                {
                    "system": "http://snomed.info/sct",
                    "code": "609588000",
                    "display": "Total knee replacement"
                },
                {
                    "system": "http://www.ama-assn.org/go/cpt",
                    "code": "27447",
                    "display": "Total knee arthroplasty"
                }
            ]
        },
        "subject": {
            "reference": f"Patient/{patient_data['id']}"
        },
        "encounter": {
            "reference": f"Encounter/tka-encounter-{patient_data['id']}"
        },
        "performedDateTime": f"{patient_data['tka_date']}T10:00:00+08:00"
    },
    "request": {
        "method": "PUT",
        "url": f"Procedure/tka-procedure-{patient_data['id']}"
    }
})

# 感染 Encounter
bundle["entry"].append({
    "resource": {
        "resourceType": "Encounter",
        "id": f"tka-infection-encounter-{patient_data['id']}",
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "IMP",
            "display": "inpatient encounter"
        },
        "subject": {
            "reference": f"Patient/{patient_data['id']}"
        },
        "period": {
            "start": f"{patient_data['infection_date']}T08:00:00+08:00",
            "end": f"{patient_data['infection_date']}T14:00:00+08:00"
        }
    },
    "request": {
        "method": "PUT",
        "url": f"Encounter/tka-infection-encounter-{patient_data['id']}"
    }
})

# 感染處理 Procedure - 關鍵：包含2個coding
bundle["entry"].append({
    "resource": {
        "resourceType": "Procedure",
        "id": f"tka-infection-procedure-{patient_data['id']}",
        "status": "completed",
        "code": {
            "coding": [
                {
                    "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure",
                    "code": "64053B",
                    "display": "人工膝關節感染清創術"
                },
                {
                    "system": "http://snomed.info/sct",
                    "code": "77849006",
                    "display": "Debridement of knee"
                }
            ]
        },
        "subject": {
            "reference": f"Patient/{patient_data['id']}"
        },
        "encounter": {
            "reference": f"Encounter/tka-infection-encounter-{patient_data['id']}"
        },
        "performedDateTime": f"{patient_data['infection_date']}T11:00:00+08:00"
    },
    "request": {
        "method": "PUT",
        "url": f"Procedure/tka-infection-procedure-{patient_data['id']}"
    }
})

# 保存文件
with open('test_data_15_2_SUCCESS_TEMPLATE_2026Q1.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

# 計算時間差
tka_date = datetime.strptime(patient_data['tka_date'], '%Y-%m-%d')
inf_date = datetime.strptime(patient_data['infection_date'], '%Y-%m-%d')
days_diff = (inf_date - tka_date).days

print(f"✓ 已生成 {len(bundle['entry'])} 個資源")
print(f"✓ 完全複製成功案例的結構")
print(f"\n患者資訊:")
print(f"  Patient ID: {patient_data['id']}")
print(f"  Identifier: {patient_data['identifier']}")
print(f"  TKA手術: {patient_data['tka_date']}")
print(f"  感染手術: {patient_data['infection_date']}")
print(f"  間隔: {days_diff}天 (與成功案例相同)")
print(f"\n關鍵差異:")
print(f"  ✓ Procedure.code包含多個coding")
print(f"    - NHI: 64164B / 64053B")
print(f"    - SNOMED: 609588000 / 77849006")
print(f"    - CPT: 27447 (僅TKA)")
print(f"\n預期結果:")
print(f"  - 這個患者應該能被正確計入分子")
print(f"  - 2026Q1分子應從0變成1")
