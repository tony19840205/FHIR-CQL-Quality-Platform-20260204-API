#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, json, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"
start_date = "2025-10-01"
end_date = "2025-12-31"

print("=" * 60)
print("測試 indicator-13 查詢邏輯")
print("=" * 60)
print()

# 查詢所有 completed Procedure
print("1. 查詢所有 completed Procedure (2025 Q4):")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={
        'status': 'completed',
        'date': [f'ge{start_date}', f'le{end_date}'],
        '_count': 2000
    },
    verify=False
)

if response.status_code == 200:
    result = response.json()
    total = len(result.get('entry', []))
    print(f"   找到 {total} 筆 Procedure")
    
    # 檢查我們的測試資料
    eswlCodes = ['80146002', '0TF00ZZ', '0TF10ZZ', '0TF20ZZ']
    eswlPatients = set()
    eswlTotalCount = 0
    found_our_data = []
    
    for entry in result.get('entry', []):
        proc = entry['resource']
        proc_id = proc['id']
        proc_code = proc.get('code', {}).get('coding', [{}])[0].get('code')
        patient_ref = proc.get('subject', {}).get('reference')
        
        if proc_id.startswith('ESWL-PROC'):
            found_our_data.append({
                'id': proc_id,
                'code': proc_code,
                'patient': patient_ref
            })
        
        if proc_code and proc_code in eswlCodes:
            eswlTotalCount += 1
            if patient_ref:
                eswlPatients.add(patient_ref)
    
    print()
    print(f"2. 找到的測試資料:")
    for item in found_our_data:
        print(f"   ✅ {item['id']}: code={item['code']}, patient={item['patient']}")
    
    if not found_our_data:
        print(f"   ❌ 沒有找到測試資料 (ESWL-PROC1, ESWL-PROC2, ESWL-PROC3)")
    
    print()
    print(f"3. ESWL 統計:")
    print(f"   總次數(分子): {eswlTotalCount}")
    print(f"   病人數(分母): {len(eswlPatients)}")
    if len(eswlPatients) > 0:
        avg = eswlTotalCount / len(eswlPatients)
        print(f"   平均次數: {avg:.2f}")
    
    print()
    print(f"4. 病人清單:")
    for patient in sorted(eswlPatients):
        print(f"   - {patient}")
else:
    print(f"   ❌ 查詢失敗: {response.status_code}")

print("=" * 60)
