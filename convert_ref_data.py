import json
import re

# 读取参考数据
with open('FHIR_測試資料_完整包_645人_2025-12-08/B_HAPI小批資料_49人/Diabetes_HbA1c_5_Patients.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 修改bundle类型
data['type'] = 'transaction'

# 为每个entry添加request并修改日期
for entry in data['entry']:
    resource = entry['resource']
    res_type = resource['resourceType']
    res_id = resource['id']
    
    # 添加request
    entry['request'] = {
        'method': 'PUT',
        'url': f'{res_type}/{res_id}'
    }
    
    # 转换日期到2026 Q1
    resource_str = json.dumps(resource)
    resource_str = resource_str.replace('2025-09-20', '2026-01-06')
    resource_str = resource_str.replace('2025-10-10', '2026-01-07')
    resource_str = resource_str.replace('2025-08-15', '2026-01-08')
    resource_str = resource_str.replace('2025-11-05', '2026-01-09')
    resource_str = resource_str.replace('2025-10-25', '2026-01-10')
    
    # recordedDate统一改为2026-01-06
    resource_str = re.sub(r'"recordedDate": "[^"]+"', '"recordedDate": "2026-01-06"', resource_str)
    
    entry['resource'] = json.loads(resource_str)

# 保存
with open('test_data_07_diabetes_hba1c_2026Q1.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f'✅ 已转换参考数据到2026 Q1')
print(f'   Bundle类型: transaction')
print(f'   患者数: 5')
print(f'   资源数: {len(data["entry"])}')
