import requests
import json

# FHIR server URL
FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

# Read test data
with open('test_data_prostate_overlap_4_patients_2025Q4.json', 'r', encoding='utf-8') as f:
    bundle = json.load(f)

# Upload to FHIR server
print(f"正在上傳前列腺肥大藥物重疊測試資料到 {FHIR_SERVER}...")
print(f"資料包含: {len(bundle['entry'])} 個資源")

response = requests.post(
    FHIR_SERVER,
    json=bundle,
    headers={'Content-Type': 'application/fhir+json'}
)

if response.status_code in [200, 201]:
    print(f"✓ 上傳成功！")
    result = response.json()
    
    # Count resources
    patients = sum(1 for e in bundle['entry'] if e['resource']['resourceType'] == 'Patient')
    encounters = sum(1 for e in bundle['entry'] if e['resource']['resourceType'] == 'Encounter')
    medications = sum(1 for e in bundle['entry'] if e['resource']['resourceType'] == 'MedicationRequest')
    
    print(f"  - {patients} 位患者 (全部為男性)")
    print(f"  - {encounters} 次門診")
    print(f"  - {medications} 筆用藥處方")
    print(f"\n藥物類別:")
    print(f"  - G04CA (α阻斷劑): Tamsulosin, Doxazosin, Terazosin")
    print(f"  - G04CB (5α還原酶抑制劑): Finasteride, Dutasteride")
    print(f"\n預期重疊率: 27 天 / 224 天 = 12.1%")
    print(f"\n重疊情況:")
    print(f"  - 患者1 (王大明): Tamsulosin × 2, 重疊 9天 (10/20-10/28)")
    print(f"  - 患者2 (李建成): Doxazosin × 2, 重疊 8天 (10/25-11/01)")
    print(f"  - 患者3 (張偉強): Finasteride + Dutasteride, 重疊 10天 (10/28-11/06)")
    print(f"  - 患者4 (陳文雄): Terazosin × 2, 不重疊 (連續給藥)")
else:
    print(f"✗ 上傳失敗！")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
