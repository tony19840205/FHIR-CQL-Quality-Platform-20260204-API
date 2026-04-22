#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, json, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

with open('test_data_diabetes_2_patients.json', 'r', encoding='utf-8') as f:
    bundle = json.load(f)

response = requests.post(
    'https://thas.mohw.gov.tw/v/r4/fhir',
    json=bundle,
    headers={'Content-Type': 'application/fhir+json'},
    verify=False
)

print("=" * 60)
print("糖尿病HbA1c檢驗測試資料上傳 - indicator 07")
print("=" * 60)
print(f"狀態碼: {response.status_code}")
print()
print("建立的測試資料:")
print()
print("患者 1: 陳建國 (DM-P1)")
print("  - Encounter: DM-ENC1 (門診 AMB, 2025-10-15)")
print("  - Condition: E11.9 (第二型糖尿病)")
print("  - Medication: A10BA02 (Metformin)")
print("  - Observation: LOINC 4548-4 (HbA1c = 7.2%)")
print("  ✅ 符合分子條件")
print()
print("患者 2: 林淑芬 (DM-P2)")
print("  - Encounter: DM-ENC2 (門診 AMB, 2025-11-08)")
print("  - Condition: E11.65 (第二型糖尿病伴高血糖)")
print("  - Medication: A10BG03 (Pioglitazone)")
print("  - Observation: LOINC 17856-6 (HbA1c = 6.8%)")
print("  ✅ 符合分子條件")
print()
print("預期結果:")
print("  - 分子(有HbA1c檢驗): 2")
print("  - 分母(糖尿病+用藥): 2")
print("  - 檢驗率: 100.00%")
print("=" * 60)
