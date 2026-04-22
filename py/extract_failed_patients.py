import json
from collections import defaultdict

print("讀取 complete_test_data_bundle_by_patient.json...")
with open('complete_test_data_bundle_by_patient.json', 'r', encoding='utf-8') as f:
    bundle = json.load(f)

all_entries = bundle['entry']
print(f"總資源數: {len(all_entries)}")

# 按病人分組
print("\n按病人ID分組資源...")
patient_groups = {}
current_patient_id = None
current_entries = []

for entry in all_entries:
    resource = entry['resource']
    patient_id = None
    
    if resource['resourceType'] == 'Patient':
        patient_id = resource['id']
    elif 'subject' in resource and resource['subject'].get('reference'):
        patient_id = resource['subject']['reference'].replace('Patient/', '')
    elif 'patient' in resource and resource['patient'].get('reference'):
        patient_id = resource['patient']['reference'].replace('Patient/', '')
    
    if patient_id and patient_id != current_patient_id:
        if current_patient_id:
            patient_groups[current_patient_id] = current_entries
        current_patient_id = patient_id
        current_entries = [entry]
    else:
        current_entries.append(entry)

if current_patient_id:
    patient_groups[current_patient_id] = current_entries

print(f"總病人數: {len(patient_groups)}")

# 識別失敗病人 (根據觀察到的模式)
print("\n識別失敗的病人...")
failed_patterns = ['-CROSS-', '-SAME-', '-OVERLAP-', 'CESAREAN-', 'CS-', 'CROSSHOSPITAL-']
failed_patient_ids = []

for patient_id in patient_groups.keys():
    for pattern in failed_patterns:
        if pattern in patient_id or patient_id.startswith('CESAREAN-') or patient_id.startswith('CS-'):
            failed_patient_ids.append(patient_id)
            break

print(f"失敗病人數: {len(failed_patient_ids)}")

# 收集失敗病人的所有資源
print("\n收集失敗病人的資源...")
failed_entries = []
for patient_id in failed_patient_ids:
    failed_entries.extend(patient_groups[patient_id])

print(f"失敗資源數: {len(failed_entries)}")

# 建立 failed patients bundle
failed_bundle = {
    "resourceType": "Bundle",
    "type": "transaction",
    "entry": failed_entries
}

# 保存
print("\n保存 failed_patients_bundle.json...")
with open('failed_patients_bundle.json', 'w', encoding='utf-8') as f:
    json.dump(failed_bundle, f, ensure_ascii=False, indent=2)

import os
file_size = os.path.getsize('failed_patients_bundle.json') / (1024 * 1024)
print(f"\n✓ 已保存 failed_patients_bundle.json")
print(f"  失敗病人數: {len(failed_patient_ids)}")
print(f"  失敗資源數: {len(failed_entries)}")
print(f"  檔案大小: {file_size:.2f} MB")

print("\n前20個失敗病人ID:")
for i, pid in enumerate(sorted(failed_patient_ids)[:20], 1):
    print(f"  {i}. {pid}")
