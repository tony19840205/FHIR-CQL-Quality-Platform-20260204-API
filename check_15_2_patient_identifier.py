import json

with open('test_data_15_2_tw10001_06_2026Q1.json', encoding='utf-8') as f:
    data = json.load(f)

print("=== Patient資源檢查 ===\n")
for e in data['entry']:
    if e['resource']['resourceType'] == 'Patient':
        res = e['resource']
        print(f"Patient ID: {res['id']}")
        if 'identifier' in res:
            for ident in res['identifier']:
                print(f"  Identifier: {ident.get('system', 'NO SYSTEM')} = {ident.get('value', 'NO VALUE')}")
        else:
            print(f"  ⚠️ 缺少 identifier 欄位！")
        print()
