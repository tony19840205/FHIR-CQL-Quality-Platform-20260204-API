import json
from datetime import datetime

with open('test_data_15_2_tw10001_06_2026Q1.json', encoding='utf-8') as f:
    data = json.load(f)

# 找出所有TKA手術
tka_procs = []
infection_procs = []

for e in data['entry']:
    if e['resource']['resourceType'] == 'Procedure':
        res = e['resource']
        code = res['code']['coding'][0]['code']
        
        if code == '64164B':
            tka_procs.append({
                'id': res['id'],
                'subject': res['subject']['reference'],
                'date': res.get('performedDateTime')
            })
        elif code == '64053B':
            infection_procs.append({
                'id': res['id'],
                'subject': res['subject']['reference'],
                'date': res.get('performedDateTime')
            })

print("=== TKA手術 ===")
for p in tka_procs:
    print(f"{p['id']}: {p['subject']} - {p['date']}")

print("\n=== 感染手術 ===")
for p in infection_procs:
    print(f"{p['id']}: {p['subject']} - {p['date']}")

print("\n=== 時間關係檢查 ===")
for inf in infection_procs:
    matching_tka = [t for t in tka_procs if t['subject'] == inf['subject']]
    if matching_tka:
        tka = matching_tka[0]
        tka_date = datetime.fromisoformat(tka['date'].replace('+08:00', ''))
        inf_date = datetime.fromisoformat(inf['date'].replace('+08:00', ''))
        days_diff = (inf_date - tka_date).days
        
        print(f"\n患者: {inf['subject']}")
        print(f"  TKA手術: {tka['date']}")
        print(f"  感染手術: {inf['date']}")
        print(f"  間隔天數: {days_diff} 天")
        print(f"  在90天內: {'✓ YES' if days_diff <= 90 else '✗ NO'}")
