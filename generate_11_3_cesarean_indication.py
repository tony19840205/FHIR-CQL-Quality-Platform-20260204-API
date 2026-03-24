"""
生成指标11-3：有适应症剖腹产率测试资料
分子：有医疗适应症的剖腹产
分母：所有剖腹产案件
与11-2相关：11-2的产妇要求剖腹产是无适应症的
"""
import json

timestamp = "20260102121500"

# 有适应症的剖腹产诊断码（ICD-10-CM O82.x系列）
indication_diagnoses = [
    ("O82.1", "Breech presentation", "臀位"),
    ("O82.2", "Previous cesarean delivery", "前次剖腹产"),
    ("O82.3", "Fetal distress", "胎儿窘迫"),
    ("O82.4", "Cephalopelvic disproportion", "头盆不称"),
    ("O32.1", "Breech presentation", "臀位"),
    ("O64.1", "Obstructed labor due to breech presentation", "臀位难产"),
]

entries = []

# 生成6个有适应症的剖腹产案件
for i in range(1, 7):
    patient_id = f"cesarean-with-indication-{i:03d}"
    enc_id = f"cesarean-indication-enc-{i:03d}"
    cond_id = f"cesarean-indication-cond-{i:03d}"
    proc_id = f"cesarean-indication-proc-{i:03d}"
    
    dx_code, dx_display_en, dx_display_zh = indication_diagnoses[(i-1) % len(indication_diagnoses)]
    
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
    
    # Encounter（住院生产）
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
    
    # Condition（有医疗适应症的剖腹产诊断）
    entries.append({
        "resource": {
            "resourceType": "Condition",
            "id": cond_id,
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-cm",
                    "code": dx_code,
                    "display": dx_display_en
                }],
                "text": dx_display_zh
            },
            "subject": {"reference": f"Patient/{patient_id}"},
            "encounter": {"reference": f"Encounter/{enc_id}"}
        },
        "request": {"method": "PUT", "url": f"Condition/{cond_id}"}
    })
    
    # Procedure（剖腹产手术）
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

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": entries
}

with open('test_data_11_3_cesarean_with_indication.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f'✅ 已生成6个有适应症剖腹产案件')
print(f'')
print(f'11系列指标关系：')
print(f'  现有数据：')
print(f'    - 产妇要求剖腹产（无适应症）：11人')
print(f'    - 有适应症剖腹产：6人')
print(f'    - 自然产：26人')
print(f'')
print(f'  指标11-1（整体剖腹产率）：')
print(f'    = (11+6) / (11+6+26) = 17/43 ≈ 39.53%')
print(f'')
print(f'  指标11-2（产妇要求剖腹产率）：')
print(f'    = 11 / (11+6+26) = 11/43 ≈ 25.58%')
print(f'')
print(f'  指标11-3（有适应症剖腹产率）：')
print(f'    = 6 / (11+6) = 6/17 ≈ 35.29%')
