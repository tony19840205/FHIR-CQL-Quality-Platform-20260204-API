"""
上傳3位流感病人資料到FHIR Server
"""

import json
import requests
from datetime import datetime

FHIR_SERVER_URL = "https://thas.mohw.gov.tw/v/r4/fhir"
BUNDLE_FILE = "add_3_influenza_patients_2026Q1.json"

def upload_bundle_to_fhir():
    """上傳Bundle到FHIR Server"""
    
    print("=" * 60)
    print("📤 上傳流感病人資料到FHIR Server")
    print("=" * 60)
    print(f"🌐 FHIR Server: {FHIR_SERVER_URL}")
    print(f"📁 Bundle檔案: {BUNDLE_FILE}")
    print()
    
    # 讀取Bundle
    try:
        with open(BUNDLE_FILE, 'r', encoding='utf-8') as f:
            bundle = json.load(f)
        print(f"✅ 成功讀取Bundle檔案")
        print(f"   資源總數: {len(bundle['entry'])}")
    except Exception as e:
        print(f"❌ 讀取Bundle失敗: {e}")
        return False
    
    # 統計資源
    resource_count = {}
    for entry in bundle['entry']:
        resource_type = entry['resource']['resourceType']
        resource_count[resource_type] = resource_count.get(resource_type, 0) + 1
    
    print(f"\n📊 資源明細:")
    for resource_type, count in sorted(resource_count.items()):
        print(f"   - {resource_type}: {count}")
    
    # 顯示病人資訊
    print(f"\n👥 病人清單:")
    for entry in bundle['entry']:
        if entry['resource']['resourceType'] == 'Patient':
            patient = entry['resource']
            patient_id = patient['id']
            name = patient['name'][0]['text']
            gender = patient['gender']
            birth_date = patient['birthDate']
            print(f"   - {patient_id}: {name} ({gender}, {birth_date})")
    
    # 詢問確認
    print(f"\n⚠️  準備上傳到: {FHIR_SERVER_URL}")
    confirm = input("確定要上傳嗎？(Y/n): ").strip().lower()
    
    if confirm not in ['y', 'yes', '']:
        print("❌ 已取消上傳")
        return False
    
    # 上傳Bundle
    print(f"\n🚀 正在上傳...")
    try:
        headers = {
            'Content-Type': 'application/fhir+json',
            'Accept': 'application/fhir+json'
        }
        
        response = requests.post(
            FHIR_SERVER_URL,
            json=bundle,
            headers=headers,
            timeout=60
        )
        
        print(f"\n📡 HTTP狀態碼: {response.status_code}")
        
        if response.status_code in [200, 201]:
            print("✅ 上傳成功！")
            
            # 解析回應
            try:
                result = response.json()
                if 'entry' in result:
                    success_count = sum(1 for e in result['entry'] if e.get('response', {}).get('status', '').startswith('2'))
                    print(f"   成功處理: {success_count}/{len(result['entry'])} 筆資源")
            except:
                pass
            
            print(f"\n🎉 流感病人數已從30人增加到33人！")
            return True
            
        else:
            print(f"❌ 上傳失敗")
            print(f"   錯誤訊息: {response.text[:500]}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ 上傳逾時（超過60秒）")
        return False
    except Exception as e:
        print(f"❌ 上傳發生錯誤: {e}")
        return False

def main():
    start_time = datetime.now()
    success = upload_bundle_to_fhir()
    end_time = datetime.now()
    
    print(f"\n{'='*60}")
    print(f"⏱️  執行時間: {(end_time - start_time).total_seconds():.2f} 秒")
    print(f"{'='*60}")
    
    if success:
        print("\n📋 後續步驟:")
        print("   1. 重新整理EHR Launch頁面")
        print("   2. 確認流感病例數是否顯示為33人")
        print("   3. 確認就診記錄數不再是0")

if __name__ == '__main__':
    main()
