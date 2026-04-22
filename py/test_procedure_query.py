#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
測試不同的 Procedure 查詢方式
"""

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 60)
print("測試 Procedure 查詢參數")
print("=" * 60)
print()

# 方法 1: 用 encounter 參數
print("1. 用 encounter 參數查詢:")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={
        'encounter': 'Encounter/CS-ENC-001',
        'status': 'completed'
    },
    verify=False
)
print(f"   狀態碼: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    count = result.get('total', len(result.get('entry', [])))
    print(f"   找到: {count} 筆")
print()

# 方法 2: 用 subject 參數
print("2. 用 subject 參數查詢:")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={
        'subject': 'Patient/CS-001',
        'status': 'completed'
    },
    verify=False
)
print(f"   狀態碼: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    count = result.get('total', len(result.get('entry', [])))
    print(f"   找到: {count} 筆")
    if result.get('entry'):
        for entry in result['entry']:
            proc = entry['resource']
            print(f"   - {proc['id']}: {proc.get('code', {}).get('coding', [{}])[0].get('code')}")
print()

# 方法 3: 用 patient 參數
print("3. 用 patient 參數查詢:")
response = requests.get(
    f"{fhir_server}/Procedure",
    params={
        'patient': 'Patient/CS-001',
        'status': 'completed'
    },
    verify=False
)
print(f"   狀態碼: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    count = result.get('total', len(result.get('entry', [])))
    print(f"   找到: {count} 筆")
print()

# 方法 4: 查詢所有 completed Procedure 並檢查 code
print("4. 查詢所有 completed Procedure (含我們的代碼):")
for code in ['81004C', '81028C', '81029C']:
    response = requests.get(
        f"{fhir_server}/Procedure",
        params={
            'code': code,
            'status': 'completed'
        },
        verify=False
    )
    print(f"   代碼 {code}: ", end='')
    if response.status_code == 200:
        result = response.json()
        count = result.get('total', len(result.get('entry', [])))
        print(f"{count} 筆")
    else:
        print(f"失敗 ({response.status_code})")

print()
print("=" * 60)
