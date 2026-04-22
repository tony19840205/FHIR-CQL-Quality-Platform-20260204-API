#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
完全模擬 quality-indicators.js 的查詢邏輯
逐步調試找出問題
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"

# 2025 Q4 日期範圍
start_date = "2025-10-01"
end_date = "2025-12-31"

# 剖腹產醫令代碼
cesareanCodes = ['81004C', '81005C', '81028C', '81029C', '97009C', '97014C']
# 自然產醫令代碼
vaginalCodes = ['81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C', '97004C', '97005D', '97934C']

print("=" * 80)
print("完全模擬 JavaScript queryCesareanSectionOverallRateSample 函數")
print("=" * 80)
print()

# Step 1: 查詢 Encounter
print("📍 Step 1: 查詢住院 Encounter")
print(f"   參數: class=IMP, status=finished, date=ge{start_date},le{end_date}")

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
total_encounters = len(encounters.get('entry', []))
print(f"   ✅ 找到 {total_encounters} 筆住院資料")
print()

# 找出我們的測試 Encounter
our_encounters = []
for entry in encounters.get('entry', []):
    enc_id = entry['resource']['id']
    if enc_id.startswith('CS-ENC-'):
        our_encounters.append(enc_id)

print(f"   🎯 其中包含我們的測試資料: {our_encounters}")
print()

if not our_encounters:
    print("   ⚠️  警告：沒有找到我們的測試 Encounter (CS-ENC-001, 002, 003)")
    print("   可能原因：")
    print("   1. 日期不在 2025-10-01 ~ 2025-12-31 範圍")
    print("   2. class 不是 IMP")
    print("   3. status 不是 finished")
    print()

# Step 2: 逐一處理每個測試 Encounter
cesareanCount = 0
totalDeliveries = 0

print("📍 Step 2: 逐一查詢 Encounter 的 Procedure")
print()

for enc_id in our_encounters:
    print(f"   🔍 處理 Encounter: {enc_id}")
    
    # 查詢 Procedure (完全按照 JS 代碼的參數)
    proc_response = requests.get(
        f"{fhir_server}/Procedure",
        params={
            'encounter': f'Encounter/{enc_id}',
            'status': 'completed',
            '_count': 20
        },
        verify=False
    )
    
    print(f"      查詢參數: encounter=Encounter/{enc_id}, status=completed")
    print(f"      狀態碼: {proc_response.status_code}")
    
    if proc_response.status_code == 200:
        procedures = proc_response.json()
        proc_count = len(procedures.get('entry', []))
        print(f"      ✅ 找到 {proc_count} 筆 Procedure")
        
        if procedures.get('entry'):
            isCesarean = False
            isVaginal = False
            
            for proc_entry in procedures['entry']:
                proc = proc_entry['resource']
                proc_id = proc['id']
                
                # 完全按照 JS 代碼取第一個 coding 的 code
                proc_code = proc.get('code', {}).get('coding', [{}])[0].get('code')
                
                print(f"         - Procedure: {proc_id}")
                print(f"           Code: {proc_code}")
                print(f"           完整 coding: {json.dumps(proc.get('code', {}).get('coding', []), ensure_ascii=False)}")
                
                # 檢查是否符合代碼
                if proc_code and proc_code in cesareanCodes:
                    isCesarean = True
                    print(f"           ✅ 符合剖腹產代碼！")
                elif proc_code and proc_code in vaginalCodes:
                    isVaginal = True
                    print(f"           ✅ 符合自然產代碼！")
                else:
                    print(f"           ❌ 不符合任何生產代碼")
            
            # 按照 JS 邏輯計算
            if isCesarean or isVaginal:
                totalDeliveries += 1
                print(f"      ➕ 計入分母 (totalDeliveries = {totalDeliveries})")
                if isCesarean:
                    cesareanCount += 1
                    print(f"      ➕ 計入分子 (cesareanCount = {cesareanCount})")
        else:
            print(f"      ⚠️  沒有 Procedure entry")
    else:
        print(f"      ❌ Procedure 查詢失敗")
    
    print()

print("=" * 80)
print("📊 最終結果:")
print(f"   剖腹產數 (分子): {cesareanCount}")
print(f"   總生產數 (分母): {totalDeliveries}")
if totalDeliveries > 0:
    rate = (cesareanCount / totalDeliveries) * 100
    print(f"   剖腹產率: {rate:.2f}%")
else:
    print(f"   剖腹產率: 0.00%")
print("=" * 80)
