"""
生成指标07：糖尿病HbA1c检验率测试资料
使用2026-01-05日期（与成功的指标04一致）
"""
import json
from datetime import datetime

timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

def generate_diabetes_patient(patient_id, has_hba1c=True):
    """生成一个糖尿病患者的完整资料"""
    entries = []
    pid = f"dm07-{timestamp}-{patient_id}"
    
    # Patient
    entries.append({
        "fullUrl": f"urn:uuid:patient-{pid}",
        "resource": {
            "resourceType": "Patient",
            "identifier": [{"system": "http://www.mohw.gov.tw/patient", "value": pid}],
            "name": [{"family": "Test", "given": [f"DM{patient_id}"]}],
            "gender": "male",
            "birthDate": "1965-04-12"
        },
        "request": {"method": "POST", "url": "Patient"}
    })
    
    # Encounter - 使用2026-01-05（和指标04一样的成功日期）
    entries.append({
        "fullUrl": f"urn:uuid:enc-{pid}",
        "resource": {
            "resourceType": "Encounter",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB"},
            "type": [{"coding": [{"system": "https://www.nhi.gov.tw/Resource/CS/CodeSystem/NHI_M_D01", "code": "E1"}]}],
            "subject": {"reference": f"urn:uuid:patient-{pid}"},
            "period": {"start": "2026-01-05T10:00:00Z", "end": "2026-01-05T10:30:00Z"}
        },
        "request": {"method": "POST", "url": "Encounter"}
    })
    
    # Condition
    entries.append({
        "fullUrl": f"urn:uuid:cond-{pid}",
        "resource": {
            "resourceType": "Condition",
            "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
            "verificationStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-ver-status", "code": "confirmed"}]},
            "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-category", "code": "encounter-diagnosis"}]}],
            "code": {"coding": [{"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": "E11.9"}]},
            "subject": {"reference": f"urn:uuid:patient-{pid}"},
            "encounter": {"reference": f"urn:uuid:enc-{pid}"},
            "recordedDate": "2026-01-05"
        },
        "request": {"method": "POST", "url": "Condition"}
    })
    
    # MedicationRequest
    entries.append({
        "fullUrl": f"urn:uuid:med-{pid}",
        "resource": {
            "resourceType": "MedicationRequest",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {"coding": [{"system": "http://www.whocc.no/atc", "code": "A10BA02"}]},
            "subject": {"reference": f"urn:uuid:patient-{pid}"},
            "encounter": {"reference": f"urn:uuid:enc-{pid}"},
            "authoredOn": "2026-01-05T10:15:00Z",
            "dispenseRequest": {"expectedSupplyDuration": {"value": 30, "unit": "days", "system": "http://unitsofmeasure.org", "code": "d"}}
        },
        "request": {"method": "POST", "url": "MedicationRequest"}
    })
    
    # Observation (HbA1c)
    if has_hba1c:
        entries.append({
            "fullUrl": f"urn:uuid:obs-{pid}",
            "resource": {
                "resourceType": "Observation",
                "status": "final",
                "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "laboratory"}]}],
                "code": {"coding": [{"system": "http://loinc.org", "code": "4548-4"}]},
                "subject": {"reference": f"urn:uuid:patient-{pid}"},
                "effectiveDateTime": "2026-01-05T10:15:00Z",
                "valueQuantity": {"value": 7.2, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
            },
            "request": {"method": "POST", "url": "Observation"}
        })
    
    return entries

# 生成10个患者（7个有HbA1c，3个无）
all_entries = []
for i in range(1, 11):
    all_entries.extend(generate_diabetes_patient(i, has_hba1c=(i <= 7)))

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": all_entries
}

with open('test_data_07_diabetes_hba1c_2026Q1.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f'✅ 已生成指标07测试资料')
print(f'   时间戳: {timestamp}')
print(f'   日期: 2026-01-05（与指标04一致）')
print(f'   患者: 10人（7人有HbA1c，3人无）')
print(f'   预期: 70.00%')
