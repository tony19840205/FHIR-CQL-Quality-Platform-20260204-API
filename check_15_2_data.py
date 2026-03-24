import json

# 檢查測試資料
with open('test_data_15_2_tw10001_06_2026Q1.json', encoding='utf-8') as f:
    data = json.load(f)

procs = [e for e in data['entry'] if e['resource']['resourceType']=='Procedure']
print(f'Total Procedures: {len(procs)}\n')

for p in procs:
    res = p['resource']
    code = res['code']['coding'][0]['code']
    date = res.get('performedDateTime', 'NO DATE')
    subj_ref = res['subject']['reference']
    print(f"{res['id']}: {code} - {date}")
    print(f"  Subject: {subj_ref}\n")
