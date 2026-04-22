#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import requests, json, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 讀取並修改日期
with open('UI UX/FHIR-Dashboard-App/Dementia_Hospice_19_Patients.json', 'r', encoding='utf-8') as f:
    content = f.read()

# 將所有2024年日期改為2025年
content = content.replace('2024-10-', '2025-10-')
content = content.replace('2024-11-', '2025-11-')
content = content.replace('2024-12-', '2025-12-')
content = content.replace('2022-', '2023-')  # onsetDateTime也改一下
content = content.replace('2021-', '2023-')

bundle = json.loads(content)

response = requests.post(
    'https://thas.mohw.gov.tw/v/r4/fhir',
    json=bundle,
    headers={'Content-Type': 'application/fhir+json'},
    verify=False,
    timeout=180
)

print("=" * 60)
print("失智症安寧療護測試資料上傳 - indicator 18")
print("=" * 60)
print(f"狀態碼: {response.status_code}")
print()
print("上傳的測試資料:")
print("  - 19位失智症病患 (2025-Q4)")
print("  - ICD-10-CM codes: F01, F02, F03, G30, G31")
print("  - 安寧照護代碼: 05601K, 05602A, 05603B, P4401B等")
print()
print("預期結果:")
print("  - 分子(使用安寧照護): 約10-12人")
print("  - 分母(失智症病患): 19人")
print("  - 使用率: 約50-60%")
print("=" * 60)

if response.status_code == 200:
    print("✅ 上傳成功！")
else:
    print(f"❌ 上傳失敗: {response.text}")
