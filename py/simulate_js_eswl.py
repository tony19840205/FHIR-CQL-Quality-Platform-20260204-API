#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, urllib3, json
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 完全模擬 JavaScript 的查詢
fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"

print("完全模擬 JavaScript queryESWLAverageUtilizationTimesSample")
print("=" * 60)

# 2025 Q4
dateRange = {'start': '2025-10-01', 'end': '2025-12-31'}

print(f"\n查詢參數:")
print(f"  status: completed")
print(f"  date: ge{dateRange['start']}, le{dateRange['end']}")
print(f"  _count: 2000")

response = requests.get(
    f"{fhir_server}/Procedure",
    params={
        'status': 'completed',
        'date': [f"ge{dateRange['start']}", f"le{dateRange['end']}"],
        '_count': 2000
    },
    verify=False
)

print(f"\n狀態碼: {response.status_code}")

if response.status_code != 200:
    print(f"❌ 查詢失敗")
    exit(1)

procedures = response.json()
total = len(procedures.get('entry', []))
print(f"找到 {total} 筆 Procedure")

if total == 0:
    print("⚠️  無資料 - 這就是為什麼分子分母都是 0")
    exit(0)

# 執行計算邏輯
eswlCodes = ['80146002', '0TF00ZZ', '0TF10ZZ', '0TF20ZZ']
eswlPatients = set()
eswlTotalCount = 0

print(f"\n處理 Procedure:")
for entry in procedures.get('entry', []):
    proc = entry['resource']
    proc_id = proc['id']
    proc_code = proc.get('code', {}).get('coding', [{}])[0].get('code')
    patient_ref = proc.get('subject', {}).get('reference')
    
    if proc_code and proc_code in eswlCodes:
        eswlTotalCount += 1
        if patient_ref:
            eswlPatients.add(patient_ref)
        
        if proc_id.startswith('ESWL-'):
            print(f"  ✅ {proc_id}: code={proc_code}, patient={patient_ref}")

patientCount = len(eswlPatients)
avgTimes = (eswlTotalCount / patientCount) if patientCount > 0 else 0

print(f"\n最終結果:")
print(f"  總次數(分子): {eswlTotalCount}")
print(f"  病人數(分母): {patientCount}")
print(f"  平均次數: {avgTimes:.2f}")
print("=" * 60)
