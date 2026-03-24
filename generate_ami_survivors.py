import json

# 创建5个AMI存活患者（降低死亡率）
bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": []
}

for i in range(1, 6):
    patient_id = f"ami-survivor-{i:03d}"
    enc_id = f"ami-survivor-enc-{i:03d}"
    cond_id = f"ami-survivor-cond-{i:03d}"
    
    # Patient (存活，没有deceasedDateTime)
    bundle["entry"].append({
        "resource": {
            "resourceType": "Patient",
            "id": patient_id,
            "identifier": [{
                "system": "http://hospital.example.org/patients",
                "value": f"TW2000{i}"
            }],
            "gender": "male" if i % 2 == 1 else "female",
            "birthDate": f"195{i}-0{i+3}-15"
        },
        "request": {
            "method": "PUT",
            "url": f"Patient/{patient_id}"
        }
    })
    
    # Encounter (出院存活)
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
                "start": f"2026-01-0{i+2}T08:00:00+08:00",
                "end": f"2026-01-{10+i:02d}T16:00:00+08:00"
            },
            "extension": [{
                "url": "http://www.nhi.gov.tw/fhir/StructureDefinition/tran-code",
                "valueString": "1"  # 1=一般出院（存活）
            }],
            "hospitalization": {
                "dischargeDisposition": {
                    "coding": [{
                        "system": "http://terminology.hl7.org/CodeSystem/discharge-disposition",
                        "code": "home",
                        "display": "Home"
                    }],
                    "text": "出院"
                }
            }
        },
        "request": {
            "method": "PUT",
            "url": f"Encounter/{enc_id}"
        }
    })
    
    # Condition (AMI - I21系列)
    ami_codes = ["I21.0", "I21.1", "I21.2", "I21.3", "I21.9"]
    bundle["entry"].append({
        "resource": {
            "resourceType": "Condition",
            "id": cond_id,
            "clinicalStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                    "code": "resolved"
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
                    "code": ami_codes[i-1],
                    "display": "Acute myocardial infarction"
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

with open('test_data_ami_survivors.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, ensure_ascii=False, indent=2)

print(f"✅ 生成 {len(bundle['entry'])} 个资源")
print(f"  - 5个AMI存活患者")
print(f"  现在总共: 3死亡 + 5存活 = 8个AMI患者")
print(f"  预期死亡率 = 3/8 = 37.50%")
