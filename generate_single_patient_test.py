"""
生成单个慢性病连续处方患者用于测试
"""

import json

# 测试患者
entries = []

# Organization
entries.append({
    "fullUrl": "urn:uuid:org-hospital-test",
    "resource": {
        "resourceType": "Organization",
        "id": "org-hospital-test",
        "identifier": [{
            "system": "http://www.mohw.gov.tw/hospital",
            "value": "TEST-HOSP-001"
        }],
        "name": "测试医院"
    },
    "request": {"method": "PUT", "url": "Organization/org-hospital-test"}
})

# Patient
entries.append({
    "fullUrl": "urn:uuid:patient-test-chronic",
    "resource": {
        "resourceType": "Patient",
        "id": "patient-test-chronic",
        "identifier": [{
            "system": "http://www.mohw.gov.tw/patient",
            "value": "TEST-CHRONIC-001"
        }],
        "name": [{"family": "测试", "given": ["连续处方"]}],
        "gender": "male",
        "birthDate": "1955-06-20"
    },
    "request": {"method": "PUT", "url": "Patient/patient-test-chronic"}
})

# Encounter (添加E1 claim type extension)
entries.append({
    "fullUrl": "urn:uuid:encounter-test-chronic",
    "resource": {
        "resourceType": "Encounter",
        "id": "encounter-test-chronic",
        "status": "finished",
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "AMB",
            "display": "ambulatory"
        },
        "type": [{
            "coding": [{
                "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/claim-type-tw",
                "code": "E1",
                "display": "慢性病连续处方"
            }]
        }],
        "subject": {"reference": "Patient/patient-test-chronic"},
        "serviceProvider": {"reference": "Organization/org-hospital-test"},
        "period": {
            "start": "2026-01-05T09:00:00Z",
            "end": "2026-01-05T09:30:00Z"
        }
    },
    "request": {"method": "PUT", "url": "Encounter/encounter-test-chronic"}
})

# Condition
entries.append({
    "fullUrl": "urn:uuid:condition-test-chronic",
    "resource": {
        "resourceType": "Condition",
        "id": "condition-test-chronic",
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
                "system": "http://snomed.info/sct",
                "code": "38341003",
                "display": "Hypertensive disorder"
            }]
        },
        "subject": {"reference": "Patient/patient-test-chronic"},
        "encounter": {"reference": "Encounter/encounter-test-chronic"},
        "onsetDateTime": "2024-01-15"
    },
    "request": {"method": "PUT", "url": "Condition/condition-test-chronic"}
})

# Procedure - 慢性病诊察
entries.append({
    "fullUrl": "urn:uuid:procedure-test-chronic",
    "resource": {
        "resourceType": "Procedure",
        "id": "procedure-test-chronic",
        "status": "completed",
        "code": {
            "coding": [
                {
                    "system": "NHI",
                    "code": "00155A",
                    "display": "慢性病诊察(155A)"
                },
                {
                    "system": "http://snomed.info/sct",
                    "code": "185349003",
                    "display": "Encounter for chronic disease"
                }
            ]
        },
        "subject": {"reference": "Patient/patient-test-chronic"},
        "encounter": {"reference": "Encounter/encounter-test-chronic"},
        "performedDateTime": "2026-01-05T09:15:00Z"
    },
    "request": {"method": "PUT", "url": "Procedure/procedure-test-chronic"}
})

# MedicationRequest - 连续处方
entries.append({
    "fullUrl": "urn:uuid:med-test-chronic",
    "resource": {
        "resourceType": "MedicationRequest",
        "id": "med-test-chronic",
        "identifier": [{
            "system": "http://www.nhi.gov.tw/prescription",
            "value": "TEST-CONT-RX-001",
            "type": {
                "coding": [{
                    "system": "NHI_CLAIM_TYPE",
                    "code": "E1",
                    "display": "慢性病连续处方"
                }]
            }
        }],
        "status": "completed",
        "intent": "order",
        "category": [{
            "coding": [{
                "system": "NHI_CLAIM_TYPE",
                "code": "E1",
                "display": "chronic-continuous-rx"
            }]
        }],
        "medicationCodeableConcept": {
            "coding": [{
                "system": "http://www.whocc.no/atc",
                "code": "C09AA01",
                "display": "Captopril"
            }]
        },
        "subject": {"reference": "Patient/patient-test-chronic"},
        "encounter": {"reference": "Encounter/encounter-test-chronic"},
        "reasonReference": [{"reference": "Condition/condition-test-chronic"}],
        "authoredOn": "2026-01-05T09:15:00Z",
        "dosageInstruction": [{
            "timing": {
                "repeat": {
                    "boundsPeriod": {
                        "start": "2026-01-05",
                        "end": "2026-04-05"
                    }
                }
            }
        }],
        "dispenseRequest": {
            "validityPeriod": {
                "start": "2026-01-05",
                "end": "2026-04-05"
            },
            "quantity": {"value": 90, "unit": "tablets"},
            "expectedSupplyDuration": {
                "value": 90,
                "unit": "days",
                "system": "http://unitsofmeasure.org",
                "code": "d"
            },
            "numberOfRepeatsAllowed": 2,
            "extension": [{
                "url": "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drug-days-per-dispense",
                "valueQuantity": {
                    "value": 30,
                    "unit": "days",
                    "system": "http://unitsofmeasure.org",
                    "code": "d"
                }
            }]
        },
        "extension": [{
            "url": "https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/prescription-total-days",
            "valueQuantity": {
                "value": 90,
                "unit": "days",
                "system": "http://unitsofmeasure.org",
                "code": "d"
            }
        }]
    },
    "request": {"method": "PUT", "url": "MedicationRequest/med-test-chronic"}
})

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": entries
}

output_file = "test_single_patient_chronic.json"
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f"✅ 已生成单患者测试资料：{output_file}")
print(f"   包含：Organization + Patient + Encounter + Condition + Procedure + MedicationRequest")
print(f"   MedicationRequest.category.code = E1")
print(f"   Procedure.code = 00155A")
