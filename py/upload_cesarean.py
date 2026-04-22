#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
整體剖腹產率測試資料上傳工具 (indicator 11-1)
上傳 6 個剖腹產患者到 FHIR 伺服器
"""

import requests
import json
import urllib3

# 停用 SSL 警告（僅用於測試環境）
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def upload_test_data():
    """上傳測試資料到 FHIR 伺服器"""
    
    print("=" * 60)
    print("整體剖腹產率測試資料上傳工具 (indicator 11-1)")
    print("=" * 60)
    print()
    
    # FHIR 伺服器設定
    fhir_server = "https://thas.mohw.gov.tw/v/r4/fhir"
    
    # 讀取測試資料
    json_file = "test_data_cesarean_6_patients.json"
    
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
    print("📋 建立的測試資料:")
    print("   患者 1: 王美玲 (CESAREAN-001)")
    print("      - 住院生產: 2025-10-01 ~ 10-04")
    print("      - 剖腹產手術: 2025-10-02")
    print("      ✓ 符合分子條件")
    print()
    print("   患者 2: 李淑華 (CESAREAN-002)")
    print("      - 住院生產: 2025-10-05 ~ 10-08")
    print("      - 剖腹產手術: 2025-10-06")
    print("      ✓ 符合分子條件")
    print()
    print("   患者 3: 陳雅婷 (CESAREAN-003)")
    print("      - 住院生產: 2025-10-10 ~ 10-13")
    print("      - 剖腹產手術: 2025-10-11")
    print("      ✓ 符合分子條件")
    print()
    print("   患者 4: 張慧珍 (CESAREAN-004)")
    print("      - 住院生產: 2025-10-15 ~ 10-18")
    print("      - 剖腹產手術: 2025-10-16")
    print("      ✓ 符合分子條件")
    print()
    print("   患者 5: 林佳蓉 (CESAREAN-005)")
    print("      - 住院生產: 2025-10-20 ~ 10-23")
    print("      - 剖腹產手術: 2025-10-21")
    print("      ✓ 符合分子條件")
    print()
    print("   患者 6: 黃詩涵 (CESAREAN-006)")
    print("      - 住院生產: 2025-10-25 ~ 10-28")
    print("      - 剖腹產手術: 2025-10-26")
    print("      ✓ 符合分子條件")
    print()
    print("🎯 預期查詢結果: 分子 = 6 (6個剖腹產患者)")
    print()
    print("=" * 60)
    print("✅ 上傳完成！請稍後在您的應用程式中執行查詢。")
    print("=" * 60)
    
    return True

if __name__ == "__main__":
    upload_test_data()
