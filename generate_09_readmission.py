"""
生成指标09：14天内非计划再入院率测试资料
分子：14天内非计划再次入院的人数
分母：所有住院出院的人数
日期：2026-01-05（与成功的指标04一致）
"""
import json
from datetime import datetime, timedelta

timestamp = datetime.now().strftime("%Y%m%d%H%M%S")

def generate_readmission_patient(patient_id, days_to_readmit=None):
    """
    生成一个住院患者的完整资料
    days_to_readmit: None=不再入院, 1-14=再入院天数
    """
    entries = []
    pid = f"readm09-{timestamp}-{patient_id}"
    
    # 第一次住院出院日期
    discharge_date = "2026-01-05"
    
    # Patient
    entries.append({
        "fullUrl": f"urn:uuid:patient-{pid}",
        "resource": {
            "resourceType": "Patient",
            "identifier": [{"system": "http://www.mohw.gov.tw/patient", "value": pid}],
            "name": [{"family": "Test", "given": [f"Patient{patient_id}"]}],
            "gender": "male" if patient_id % 2 == 0 else "female",
            "birthDate": "1975-06-15"
        },
        "request": {"method": "POST", "url": "Patient"}
    })
    
    # 第一次住院 Encounter（出院日：2026-01-05）
    entries.append({
        "fullUrl": f"urn:uuid:enc1-{pid}",
        "resource": {
            "resourceType": "Encounter",
            "status": "finished",
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient"},
            "type": [{"coding": [{"system": "http://snomed.info/sct", "code": "32485007", "display": "Hospital admission"}]}],
            "subject": {"reference": f"urn:uuid:patient-{pid}"},
            "period": {
                "start": "2026-01-02T08:00:00Z",
                "end": "2026-01-05T14:00:00Z"  # 出院
            }
        },
        "request": {"method": "POST", "url": "Encounter"}
    })
    
    # 诊断（非排除情况，如肺炎）
    entries.append({
        "fullUrl": f"urn:uuid:cond1-{pid}",
        "resource": {
            "resourceType": "Condition",
            "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
            "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-category", "code": "encounter-diagnosis"}]}],
            "code": {"coding": [{"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": "J18.9", "display": "Pneumonia"}]},
            "subject": {"reference": f"urn:uuid:patient-{pid}"},
            "encounter": {"reference": f"urn:uuid:enc1-{pid}"},
            "recordedDate": "2026-01-02"
        },
        "request": {"method": "POST", "url": "Condition"}
    })
    
    # 如果有再入院
    if days_to_readmit is not None:
        # 计算再入院日期
        discharge_dt = datetime.strptime("2026-01-05", "%Y-%m-%d")
        readmit_dt = discharge_dt + timedelta(days=days_to_readmit)
        readmit_start = readmit_dt.strftime("%Y-%m-%dT09:00:00Z")
        readmit_end = (readmit_dt + timedelta(days=2)).strftime("%Y-%m-%dT15:00:00Z")
        
        # 第二次住院 Encounter（再入院）
        entries.append({
            "fullUrl": f"urn:uuid:enc2-{pid}",
            "resource": {
                "resourceType": "Encounter",
                "status": "finished",
                "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient"},
                "type": [{"coding": [{"system": "http://snomed.info/sct", "code": "417005", "display": "Hospital readmission"}]}],
                "subject": {"reference": f"urn:uuid:patient-{pid}"},
                "period": {
                    "start": readmit_start,
                    "end": readmit_end
                }
            },
            "request": {"method": "POST", "url": "Encounter"}
        })
        
        # 再入院诊断
        entries.append({
            "fullUrl": f"urn:uuid:cond2-{pid}",
            "resource": {
                "resourceType": "Condition",
                "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
                "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-category", "code": "encounter-diagnosis"}]}],
                "code": {"coding": [{"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": "J18.9", "display": "Pneumonia"}]},
                "subject": {"reference": f"urn:uuid:patient-{pid}"},
                "encounter": {"reference": f"urn:uuid:enc2-{pid}"},
                "recordedDate": readmit_dt.strftime("%Y-%m-%d")
            },
            "request": {"method": "POST", "url": "Condition"}
        })
    
    return entries

# 生成15个患者
# - 5个在14天内再入院（分子）
# - 10个没有再入院（只计分母）
all_entries = []

# 1-5: 14天内再入院（天数分别为3, 5, 7, 10, 13天）
for i in range(1, 6):
    days = [3, 5, 7, 10, 13][i-1]
    all_entries.extend(generate_readmission_patient(i, days_to_readmit=days))

# 6-15: 没有再入院
for i in range(6, 16):
    all_entries.extend(generate_readmission_patient(i, days_to_readmit=None))

bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": all_entries
}

with open('test_data_09_readmission_2026Q1.json', 'w', encoding='utf-8') as f:
    json.dump(bundle, f, indent=2, ensure_ascii=False)

print(f'✅ 已生成指标09测试资料')
print(f'   时间戳: {timestamp}')
print(f'   日期: 2026-01-05出院（与指标04一致）')
print(f'   患者: 15人')
print(f'   - 5人在14天内再入院（3/5/7/10/13天）')
print(f'   - 10人无再入院')
print(f'   预期: 5/15 = 33.33%')
