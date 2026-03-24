import json

# 创建3个AMI死亡患者，identifier在TW20006-TW20008范围
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

for i in range(6, 9):  # TW20006, TW20007, TW20008
    patient_id = f"ami-death-{i:03d}"
    enc_id = f"ami-death-enc-{i:03d}"
    cond_id = f"ami-death-cond-{i:03d}"
    
    # Patient (死亡)
    bundle["entry"].append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "identifier": [{
                "system": "http://www.moi.gov.tw/",
                "value": f"TW200{i:02d}"
            }],
            "gender": "male" if i % 2 == 0 else "female",
            "birthDate": f"195{i-5}-05-{i+10}",
            "deceasedDateTime": f"2026-01-0{i-2}T14:45:00+08:00"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/{patient_id}"
        }
    })
    
    # Encounter (死亡)
    bundle["entry"].append({
        "resource": {
            "resourceType": "Encounter",
            "id": enc_id,
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "IMP",
                "display": "inpatient encounter"
            },
            "subject": {
                "reference": f"Patient/{patient_id}"
            },
            "period": {
                "start": f"2026-01-0{i-2}T08:30:00+08:00",
                "end": f"2026-01-0{i-2}T14:45:00+08:00"
            },
            "extension": [{
                "url": "http://www.nhi.gov.tw/fhir/StructureDefinition/tran-code",
                "valueString": "4"  # 转归代码4=死亡
            }],
            "hospitalization": {
                "dischargeDisposition": {
                    "coding": [{
                        "system": "http://terminology.hl7.org/CodeSystem/discharge-disposition",
                        "code": "exp",
                        "display": "Expired"
                    }],
                    "text": "死亡"
                }
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/{enc_id}"
        }
    })
    
    # Condition (AMI)
    bundle["entry"].append({
        "resource": {
            "resourceType": "Condition",
            "id": cond_id,
            "clinicalStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                    "code": "active"
                }]
            },
            "verificationStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                    "code": "confirmed"
                }]
            },
            "code": {
                "coding": [{
                    "system": "http://hl7.org/fhir/sid/icd-10-cm",
                    "code": "I21.9",
                    "display": "Acute myocardial infarction, unspecified"
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

with open('test_data_ami_deaths_fixed.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

print(f"✅ 生成 {len(bundle['entry'])} 个资源")
print(f"  - 3个AMI死亡患者 (TW20006-TW20008)")
print(f"  总共: 3死亡 + 5存活 = 8个")
print(f"  预期死亡率 = 3/8 = 37.50%")
