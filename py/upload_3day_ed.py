#!/usr/bin/env python3
"""
上傳出院後3天內急診測試資料到 FHIR Server
Creates 6 patients who visited ED within 3 days after discharge
"""

import requests
import json
import urllib3

# 關閉 SSL 警告
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# FHIR Server 設定
FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

def upload_bundle(bundle_file):
    """上傳 FHIR Bundle 到伺服器"""
    
    print(f"📤 正在上傳測試資料到 {FHIR_SERVER}...")
    print(f"📄 檔案: {bundle_file}")
    
    try:
        with open(bundle_file, 'r', encoding='utf-8') as f:
            bundle = json.load(f)
    except FileNotFoundError:
        print(f"❌ 錯誤: 找不到檔案 {bundle_file}")
        return False
    except json.JSONDecodeError as e:
        print(f"❌ 錯誤: JSON 格式錯誤 - {e}")
        return False
    
    print(f"✅ 成功載入 Bundle，包含 {len(bundle['entry'])} 個資源")
    
    headers = {
        'Content-Type': 'application/fhir+json',
        'Accept': 'application/fhir+json'
    }
    
    try:
        response = requests.post(
            FHIR_SERVER,
            json=bundle,
            headers=headers,
            timeout=30,
            verify=False
        )
        
        if response.status_code in [200, 201]:
            print(f"✅ 上傳成功！狀態碼: {response.status_code}")
            
            result = response.json()
            if result.get('resourceType') == 'Bundle':
                print(f"📊 Bundle 類型: {result.get('type')}")
                if 'entry' in result:
                    print(f"📦 處理了 {len(result['entry'])} 個資源")
            
            print("\n✨ 測試資料上傳完成！")
            print("\n📋 建立的測試資料:")
            print("   患者 1: 張志明 (ED3DAY-001)")
            print("      - 住院: 2025-10-01 ~ 10-05 (出院)")
            print("      - 急診: 2025-10-07 (出院後第2天)")
            print("      ✓ 符合條件 (3天內回急診)")
            print()
            print("   患者 2: 林淑芬 (ED3DAY-002)")
            print("      - 住院: 2025-10-08 ~ 10-12 (出院)")
            print("      - 急診: 2025-10-13 (出院後第1天)")
            print("      ✓ 符合條件 (3天內回急診)")
            print()
            print("   患者 3: 黃建華 (ED3DAY-003)")
            print("      - 住院: 2025-10-15 ~ 10-18 (出院)")
            print("      - 急診: 2025-10-20 (出院後第2天)")
            print("      ✓ 符合條件 (3天內回急診)")
            print()
            print("   患者 4: 吳文玲 (ED3DAY-004)")
            print("      - 住院: 2025-10-20 ~ 10-23 (出院)")
            print("      - 急診: 2025-10-24 (出院後第1天)")
            print("      ✓ 符合條件 (3天內回急診)")
            print()
            print("   患者 5: 劉俊傑 (ED3DAY-005)")
            print("      - 住院: 2025-10-25 ~ 10-28 (出院)")
            print("      - 急診: 2025-10-29 (出院後第1天)")
            print("      ✓ 符合條件 (3天內回急診)")
            print()
            print("   患者 6: 鄭雅婷 (ED3DAY-006)")
            print("      - 住院: 2025-11-01 ~ 11-04 (出院)")
            print("      - 急診: 2025-11-06 (出院後第2天)")
            print("      ✓ 符合條件 (3天內回急診)")
            print()
            print("🎯 預期查詢結果: 分子 = 6 (6個患者出院後3天內回急診)")
            
            return True
        else:
            print(f"❌ 上傳失敗！狀態碼: {response.status_code}")
            print(f"回應內容: {response.text[:500]}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ 網路錯誤: {e}")
        return False

def main():
    """主程式"""
    print("="*70)
    print("出院後3天內急診率測試資料上傳工具 (indicator-10)")
    print("="*70)
    print()
    
    bundle_file = "test_data_3day_ed_6_patients.json"
    
    success = upload_bundle(bundle_file)
    
    if success:
        print("\n" + "="*70)
        print("✅ 上傳完成！請稍後在您的應用程式中執行查詢。")
        print("="*70)
    else:
        print("\n" + "="*70)
        print("❌ 上傳失敗，請檢查錯誤訊息。")
        print("="*70)

if __name__ == "__main__":
    main()
