#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
上傳指標01的2026 Q1測試資料
"""

import requests
import json
import time

FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"
BUNDLE_FILE = "2026Q1_Medical_Quality_Test_Data/CGMH_test_data_quality_50_bundle_2026Q1.json"

def upload_bundle():
    print("=" * 50)
    print("上傳指標01 - 2026 Q1測試資料")
    print("=" * 50)
    
    # 讀取Bundle
    with open(BUNDLE_FILE, 'r', encoding='utf-8-sig') as f:
        bundle = json.load(f)
    
    print(f"\n檔案: {BUNDLE_FILE}")
    print(f"資源數: {len(bundle['entry'])}")
    
    # 驗證日期
    encounters = [e for e in bundle['entry'] if e['resource']['resourceType'] == 'Encounter']
    if encounters:
        sample_date = encounters[0]['resource']['period']['start']
        print(f"日期樣本: {sample_date}")
        
        if '2026-01' in sample_date:
            print("✅ 確認為2026年1月資料")
        else:
            print("❌ 警告：不是2026年資料！")
            return
    
    # 上傳Bundle
    print(f"\n上傳到: {FHIR_SERVER}")
    
    headers = {
        'Content-Type': 'application/fhir+json; charset=utf-8'
    }
    
    try:
        response = requests.post(
            FHIR_SERVER,
            json=bundle,
            headers=headers,
            timeout=300
        )
        
        if response.status_code in [200, 201]:
            print(f"\n✅ 上傳成功！")
            print(f"狀態碼: {response.status_code}")
            
            result = response.json()
            print(f"回應類型: {result.get('resourceType')}")
            print(f"Bundle類型: {result.get('type')}")
            
            # 驗證上傳
            print("\n驗證上傳結果...")
            time.sleep(2)
            
            verify_url = f"{FHIR_SERVER}/Encounter?subject=TW00259&_sort=-date&_count=3"
            verify_resp = requests.get(verify_url)
            
            if verify_resp.status_code == 200:
                verify_data = verify_resp.json()
                print(f"病患TW00259的Encounter數: {verify_data.get('total', 0)}")
                
                if verify_data.get('entry'):
                    print("\n最新3筆資料:")
                    for entry in verify_data['entry'][:3]:
                        enc_date = entry['resource']['period']['start']
                        print(f"  - {entry['resource']['id']}: {enc_date}")
                        
                        if '2026-01' in enc_date:
                            print("    ✅ 2026年資料確認")
                        else:
                            print("    ⚠️  仍是舊資料")
        else:
            print(f"\n❌ 上傳失敗")
            print(f"狀態碼: {response.status_code}")
            print(f"錯誤: {response.text[:500]}")
            
    except Exception as e:
        print(f"\n❌ 錯誤: {e}")

if __name__ == "__main__":
    upload_bundle()
