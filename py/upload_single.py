#!/usr/bin/env python3
import requests, json, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

with open('test_single_cesarean.json', 'r', encoding='utf-8') as f:
    bundle = json.load(f)

response = requests.post(
    'https://thas.mohw.gov.tw/v/r4/fhir',
    json=bundle,
    headers={'Content-Type': 'application/fhir+json'},
    verify=False
)

print(f"上傳單一測試患者")
print(f"狀態: {response.status_code}")
print(f"Patient: TEST-CS-P1")
print(f"Encounter: TEST-CS-E1 (2025-11-15 ~ 11-18)")
print(f"Procedure: TEST-CS-PR1 (97014C - 剖腹產處置費)")
print(f"預期: 分子+1")
