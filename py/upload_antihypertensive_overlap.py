#!/usr/bin/env python3
"""
上傳同院降血壓藥重疊測試資料到 FHIR Server
Creates 3 patients with antihypertensive medication overlap
"""

import requests
import json
from datetime import datetime
import urllib3

# 關閉 SSL 警告（僅用於測試環境）
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# FHIR Server 設定
FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

def upload_bundle(bundle_file):
    """上傳 FHIR Bundle 到伺服器"""
    
    print(f"📤 正在上傳測試資料到 {FHIR_SERVER}...")
    print(f"📄 檔案: {bundle_file}")
    
    # 讀取 Bundle JSON
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
    
    # 上傳到 FHIR Server
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
            verify=False  # 跳過 SSL 驗證（僅用於測試環境）
        )
        
        if response.status_code in [200, 201]:
            print(f"✅ 上傳成功！狀態碼: {response.status_code}")
            
            # 解析回應
            result = response.json()
            if result.get('resourceType') == 'Bundle':
                print(f"📊 Bundle 類型: {result.get('type')}")
                if 'entry' in result:
                    print(f"📦 處理了 {len(result['entry'])} 個資源")
            
            print("\n✨ 測試資料上傳完成！")
            print("\n📋 建立的測試資料:")
            print("   患者 1: 王小明 (OVERLAP-001)")
            print("      - 2025-10-01: Captopril (10/01-10/31)")
            print("      - 2025-10-15: Enalapril (10/15-11/14)")
            print("      ✓ 用藥重疊期間: 10/15-10/31 (17天)")
            print()
            print("   患者 2: 李美華 (OVERLAP-002)")
            print("      - 2025-10-05: Losartan (10/05-11/04)")
            print("      - 2025-10-20: Amlodipine (10/20-11/19)")
            print("      ✓ 用藥重疊期間: 10/20-11/04 (16天)")
            print()
            print("   患者 3: 陳建國 (OVERLAP-003)")
            print("      - 2025-10-08: Metoprolol (10/08-11/07)")
            print("      - 2025-10-25: Furosemide (10/25-11/24)")
            print("      ✓ 用藥重疊期間: 10/25-11/07 (14天)")
            print()
            print("🎯 預期查詢結果: 分子 = 3 (3個患者有降血壓藥重疊)")
            
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
    print("同院降血壓藥重疊測試資料上傳工具 (indicator-03-1)")
    print("="*70)
    print()
    
    bundle_file = "test_data_antihypertensive_overlap_3_patients.json"
    
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
