#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, json, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"
start_date = "2025-10-01"
end_date = "2025-12-31"

print("=" * 80)
print("測試 indicator-07 查詢邏輯")
print("=" * 80)
print()

# 查詢門診 Encounter
print("1. 查詢門診 Encounter (AMB):")
response = requests.get(
    f"{fhir_server}/Encounter",
    params={
        'class': 'AMB',
        'status': 'finished',
        'date': [f'ge{start_date}', f'le{end_date}'],
        '_count': 2000
    },
    verify=False
)

if response.status_code != 200:
    print(f"   ❌ 查詢失敗: {response.status_code}")
    exit(1)

encounters = response.json()
total = len(encounters.get('entry', []))
print(f"   找到 {total} 筆門診")

# 找我們的測試資料
our_encounters = []
for entry in encounters.get('entry', []):
    enc = entry['resource']
    if enc['id'].startswith('DM-ENC'):
        our_encounters.append(enc['id'])

print(f"   其中包含測試資料: {our_encounters}")

if not our_encounters:
    print("   ⚠️  沒有找到測試 Encounter")
    exit(0)

print()
print("2. 檢查患者 DM-P1 的完整資料:")

# 檢查 Condition
print("   a. Condition:")
response = requests.get(
    f"{fhir_server}/Condition",
    params={'encounter': 'Encounter/DM-ENC1'},
    verify=False
)
if response.status_code == 200:
    result = response.json()
    if result.get('entry'):
        cond = result['entry'][0]['resource']
        code = cond.get('code', {}).get('coding', [{}])[0].get('code')
        print(f"      ✅ 找到 Condition: {code}")
    else:
        print(f"      ❌ 沒有 Condition")
else:
    print(f"      ❌ 查詢失敗: {response.status_code}")

# 檢查 MedicationRequest
print("   b. MedicationRequest:")
response = requests.get(
    f"{fhir_server}/MedicationRequest",
    params={'encounter': 'Encounter/DM-ENC1', 'status': 'completed'},
    verify=False
)
if response.status_code == 200:
    result = response.json()
    if result.get('entry'):
        med = result['entry'][0]['resource']
        code = med.get('medicationCodeableConcept', {}).get('coding', [{}])[0].get('code')
        print(f"      ✅ 找到 MedicationRequest: {code}")
    else:
        print(f"      ❌ 沒有 MedicationRequest")
else:
    print(f"      ❌ 查詢失敗: {response.status_code}")

# 檢查 Observation (HbA1c)
print("   c. Observation (HbA1c):")
response = requests.get(
    f"{fhir_server}/Observation",
    params={
        'patient': 'Patient/DM-P1',
        'date': [f'ge{start_date}', f'le{end_date}']
    },
    verify=False
)
if response.status_code == 200:
    result = response.json()
    if result.get('entry'):
        obs = result['entry'][0]['resource']
        code = obs.get('code', {}).get('coding', [{}])[0].get('code')
        value = obs.get('valueQuantity', {}).get('value')
        print(f"      ✅ 找到 Observation: LOINC {code}, value={value}%")
    else:
        print(f"      ❌ 沒有 Observation")
else:
    print(f"      ❌ 查詢失敗: {response.status_code}")

print()
print("=" * 80)
