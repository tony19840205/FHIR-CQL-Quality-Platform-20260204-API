#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"

print("測試 Procedure 查詢參數")
print("=" * 60)

# 測試 1: 使用 date 參數
print("\n1. 使用 date 參數:")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={'status': 'completed', 'date': ['ge2025-10-01', 'le2025-12-31'], '_count': 5},
    verify=False
)
print(f"   狀態碼: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    print(f"   找到: {len(result.get('entry', []))} 筆")

# 測試 2: 使用 performed 參數  
print("\n2. 使用 performed 參數:")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={'status': 'completed', 'performed': ['ge2025-10-01', 'le2025-12-31'], '_count': 5},
    verify=False
)
print(f"   狀態碼: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    print(f"   找到: {len(result.get('entry', []))} 筆")

# 測試 3: 不使用日期參數
print("\n3. 不使用日期參數 (只用 status):")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={'status': 'completed', '_count': 5},
    verify=False
)
print(f"   狀態碼: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    print(f"   找到: {len(result.get('entry', []))} 筆")
    if result.get('entry'):
        proc = result['entry'][0]['resource']
        print(f"   範例: {proc['id']}, performedDateTime: {proc.get('performedDateTime')}")

print("=" * 60)
