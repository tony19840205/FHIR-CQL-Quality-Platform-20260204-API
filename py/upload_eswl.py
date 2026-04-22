#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, json, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

with open('test_data_eswl_3_patients.json', 'r', encoding='utf-8') as f:
    bundle = json.load(f)

response = requests.post(
    'https://thas.mohw.gov.tw/v/r4/fhir',
    json=bundle,
    headers={'Content-Type': 'application/fhir+json'},
    verify=False
)

print("=" * 60)
print("體外震波碎石術(ESWL)測試資料上傳 - indicator 13")
print("=" * 60)
print(f"狀態碼: {response.status_code}")
print()
print("建立的測試資料:")
print("  患者 1: 張大明 (ESWL-P1)")
print("    - Procedure: ESWL-PROC1 (2025-10-15)")
print("    - Code: 80146002 (SNOMED CT)")
print()
print("  患者 2: 李小華 (ESWL-P2)")
print("    - Procedure: ESWL-PROC2 (2025-11-05)")
print("    - Code: 80146002 (SNOMED CT)")
print()
print("  患者 3: 王志強 (ESWL-P3)")
print("    - Procedure: ESWL-PROC3 (2025-11-20)")
print("    - Code: 80146002 (SNOMED CT)")
print()
print("預期結果:")
print("  - 分子(總次數): 3")
print("  - 分母(病人數): 3")
print("  - 平均次數: 1.00")
print("=" * 60)
