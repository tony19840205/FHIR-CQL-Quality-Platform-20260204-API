#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
整體剖腹產率測試資料上傳工具 - 簡化版 (indicator 11-1)
上傳 3 個剖腹產患者到 FHIR 伺服器（只使用健保代碼，作為第一個 coding）
"""

import requests
import json
import urllib3

# 停用 SSL 警告（僅用於測試環境）
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def upload_test_data():
    """上傳測試資料到 FHIR 伺服器"""
    
    print("=" * 60)
    print("整體剖腹產率測試資料上傳工具 - 簡化版 (indicator 11-1)")
    print("=" * 60)
    print()
    
    # FHIR 伺服器設定
    fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"
    
    # 讀取測試資料
    json_file = "test_data_cesarean_3_simple.json"
    
    print(f"📤 正在上傳測試資料到 {fhir_server}...")
    print(f"📄 檔案: {json_file}")
    
    try:
        # 讀取 JSON 檔案
        with open(json_file, 'r', encoding='utf-8') as f:
            bundle = json.load(f)
        
        print(f"✅ 成功載入 Bundle，包含 {len(bundle['entry'])} 個資源")
        
        # 上傳 Bundle
        headers = {
            'Content-Type': 'application/fhir+json',
            'Accept': 'application/fhir+json'
        }
        
        response = requests.post(
            fhir_server,
            json=bundle,
            headers=headers,
            verify=False  # 測試環境停用 SSL 驗證
        )
        
        # 檢查回應
        if response.status_code in [200, 201]:
            print(f"✅ 上傳成功！狀態碼: {response.status_code}")
            
            # 解析回應
            result = response.json()
            if result.get('resourceType') == 'Bundle':
                print(f"📊 Bundle 類型: {result.get('type')}")
                print(f"📦 處理了 {len(result.get('entry', []))} 個資源")
        else:
            print(f"❌ 上傳失敗！狀態碼: {response.status_code}")
            print(f"錯誤訊息: {response.text}")
            return False
            
    except FileNotFoundError:
        print(f"❌ 找不到檔案: {json_file}")
        return False
    except json.JSONDecodeError:
        print(f"❌ JSON 格式錯誤")
        return False
    except Exception as e:
        print(f"❌ 發生錯誤: {str(e)}")
        return False
    
    print()
    print("✨ 測試資料上傳完成！")
    print()
    print("📋 建立的測試資料（簡化版 - 只用健保代碼）:")
    print("   患者 1: 劉曉芬 (CS-001)")
    print("      - 住院: 2025-11-01 ~ 11-04")
    print("      - 剖腹產: 81004C (剖腹產術)")
    print("      - Encounter ID: CS-ENC-001")
    print("      - Procedure ID: CS-PROC-001")
    print("      ✓ 符合分子條件")
    print()
    print("   患者 2: 吳雅文 (CS-002)")
    print("      - 住院: 2025-11-05 ~ 11-08")
    print("      - 剖腹產: 81028C (選擇性剖腹產)")
    print("      - Encounter ID: CS-ENC-002")
    print("      - Procedure ID: CS-PROC-002")
    print("      ✓ 符合分子條件")
    print()
    print("   患者 3: 鄭思涵 (CS-003)")
    print("      - 住院: 2025-11-10 ~ 11-13")
    print("      - 剖腹產: 81029C (緊急剖腹產)")
    print("      - Encounter ID: CS-ENC-003")
    print("      - Procedure ID: CS-PROC-003")
    print("      ✓ 符合分子條件")
    print()
    print("🔍 關鍵改進:")
    print("   - 健保代碼作為第一個 coding（不是第二個）")
    print("   - Encounter reference 格式: Encounter/CS-ENC-00X")
    print("   - 日期在 2025 Q4 範圍內")
    print()
    print("🎯 預期查詢結果: 分子 = 3 (3個剖腹產患者)")
    print()
    print("=" * 60)
    print("✅ 上傳完成！請稍後在您的應用程式中執行查詢。")
    print("=" * 60)
    
    return True

if __name__ == "__main__":
    upload_test_data()
