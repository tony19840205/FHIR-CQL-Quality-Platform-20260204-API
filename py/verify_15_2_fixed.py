import json

with open('test_data_15_2_FIXED_with_identifier.json', encoding='utf-8') as f:
    data = json.load(f)

print("=== 資源統計 ===")
resource_types = {}
for e in data['entry']:
    rt = e['resource']['resourceType']
    resource_types[rt] = resource_types.get(rt, 0) + 1

for rt, count in resource_types.items():
    print(f"{rt}: {count}")

print("\n=== Patient檢查（必須有identifier）===")
for e in data['entry']:
    if e['resource']['resourceType'] == 'Patient':
        res = e['resource']
        print(f"\nPatient ID: {res['id']}")
        if 'identifier' in res:
            for ident in res['identifier']:
                print(f"  ✓ identifier.value = {ident['value']}")
        else:
            print(f"  ✗ 缺少identifier")

print("\n=== TKA Procedure檢查 ===")
tka_procs = []
for e in data['entry']:
    if e['resource']['resourceType'] == 'Procedure':
        res = e['resource']
        code = res['code']['coding'][0]['code']
        if code == '64164B':
            tka_procs.append(res)
            print(f"{res['id']}: {res['subject']['reference']} - {res.get('performedDateTime')}")

print(f"\n總計TKA手術: {len(tka_procs)}")

print("\n=== 感染Procedure檢查 ===")
inf_procs = []
for e in data['entry']:
    if e['resource']['resourceType'] == 'Procedure':
        res = e['resource']
        code = res['code']['coding'][0]['code']
        if code == '64053B':
            inf_procs.append(res)
            print(f"{res['id']}: {res['subject']['reference']} - {res.get('performedDateTime')}")

print(f"\n總計感染手術: {len(inf_procs)}")

print("\n=== CQL匹配檢查 ===")
from datetime import datetime

for inf in inf_procs:
    subj = inf['subject']['reference']
    matching_tka = [t for t in tka_procs if t['subject']['reference'] == subj]
    
    if matching_tka:
        tka = matching_tka[0]
        tka_date = datetime.fromisoformat(tka['performedDateTime'].replace('+08:00', ''))
        inf_date = datetime.fromisoformat(inf['performedDateTime'].replace('+08:00', ''))
        days = (inf_date - tka_date).days
        
        print(f"\n{subj}:")
        print(f"  TKA: {tka['performedDateTime']}")
        print(f"  感染: {inf['performedDateTime']}")
        print(f"  間隔: {days}天")
        print(f"  {'✓ 應計入分子' if days <= 90 else '✗ 超過90天'}")
