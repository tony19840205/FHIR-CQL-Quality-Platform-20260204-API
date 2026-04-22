#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
模擬 JavaScript 查詢邏輯，測試 indicator-11-1
"""

import requests
import json
import urllib3
from datetime import datetime

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"

# 2024 Q4 日期範圍
start_date = "2024-10-01"
end_date = "2024-12-31"

print("=" * 60)
print("模擬 indicator-11-1 查詢邏輯")
print(f"日期範圍: {start_date} ~ {end_date}")
print("=" * 60)
print()

# 剖腹產醫令代碼
cesareanCodes = ['81004C', '81005C', '81028C', '81029C', '97009C', '97014C']
# 自然產醫令代碼
vaginalCodes = ['81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C', '97004C', '97005D', '97934C']

print("1. 查詢住院 Encounter:")
response = requests.get(
    f"{fhir_server}/Encounter",
    params={
        'class': 'IMP',
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
encounter_count = len(encounters.get('entry', []))
print(f"   找到 {encounter_count} 筆住院資料")
print()

cesareanCount = 0
totalDeliveries = 0
found_our_patients = []

print("2. 逐一檢查 Encounter 並查詢關聯的 Procedure:")
for entry in encounters.get('entry', []):
    encounter = entry['resource']
    encounter_id = encounter['id']
    
    # 只檢查我們的測試資料
    if encounter_id in ['CS-ENC-001', 'CS-ENC-002', 'CS-ENC-003']:
        print(f"   🔍 檢查 Encounter: {encounter_id}")
        
        # 查詢關聯的 Procedure
        proc_response = requests.get(
            f"{fhir_server}/Procedure",
            params={
                'encounter': f'Encounter/{encounter_id}',
                'status': 'completed',
                '_count': 20
            },
            verify=False
        )
        
        if proc_response.status_code == 200:
            procedures = proc_response.json()
            proc_count = len(procedures.get('entry', []))
            print(f"      找到 {proc_count} 筆 Procedure")
            
            if procedures.get('entry'):
                isCesarean = False
                isVaginal = False
                
                for proc_entry in procedures['entry']:
                    proc = proc_entry['resource']
                    proc_code = proc.get('code', {}).get('coding', [{}])[0].get('code')
                    
                    print(f"      - Procedure: {proc['id']}, Code: {proc_code}")
                    
                    if proc_code and proc_code in cesareanCodes:
                        isCesarean = True
                        print(f"        ✅ 符合剖腹產代碼！")
                    if proc_code and proc_code in vaginalCodes:
                        isVaginal = True
                        print(f"        ✅ 符合自然產代碼！")
                
                if isCesarean or isVaginal:
                    totalDeliveries += 1
                    if isCesarean:
                        cesareanCount += 1
                        found_our_patients.append(encounter_id)
        print()

print("=" * 60)
print("查詢結果:")
print(f"   剖腹產數: {cesareanCount}")
print(f"   總生產數: {totalDeliveries}")
if totalDeliveries > 0:
    rate = (cesareanCount / totalDeliveries) * 100
    print(f"   剖腹產率: {rate:.2f}%")
print()
print(f"   找到的測試患者: {found_our_patients}")
print("=" * 60)
