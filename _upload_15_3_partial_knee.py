"""
Upload test data for indicator 15-3: 部分膝置換90天深部感染率
- Partial knee arthroplasty (64169B) procedures
- Infection procedures (64053B) within 90 days for some patients
"""
import requests

FHIR_BASE = "https://thas.mohw.gov.tw/v/r4/fhir"
HEADERS = {"Content-Type": "application/fhir+json"}

def put(rt, rid, body):
    r = requests.put(f"{FHIR_BASE}/{rt}/{rid}", headers=HEADERS, json=body, timeout=30)
    print(f"  PUT {rt}/{rid} => {'OK' if r.status_code in (200,201) else f'FAIL({r.status_code})'}")
    return r.status_code in (200, 201)

success = total = 0
PATIENTS = ["2892", "4117", "4679", "4836", "4896", "4969", "6295", "6377"]

print("=== Indicator 15-3: Partial Knee (64169B) ===")

# 8 partial knee arthroplasty procedures
for i, pid in enumerate(PATIENTS):
    proc_id = f"pka-proc-{i+1}"
    date = f"2025-{(i%6)+2:02d}-{10+i:02d}"
    total += 1
    body = {
        "resourceType": "Procedure",
        "id": proc_id,
        "status": "completed",
        "code": {
            "coding": [{"system": "http://www.nhi.gov.tw/codes/procedure", "code": "64169B", "display": "半人工膝關節置換術"}],
            "text": "Partial knee arthroplasty (64169B)"
        },
        "subject": {"reference": f"Patient/{pid}"},
        "performedDateTime": f"{date}T10:00:00+08:00"
    }
    if put("Procedure", proc_id, body): success += 1

# 2 infection procedures within 90 days for first 2 patients
print("\n--- Infection procedures (64053B) ---")
infections = [
    ("2892", "2025-04-15", "pka-inf-1"),  # ~55 days after 2025-02-10
    ("4117", "2025-05-20", "pka-inf-2"),  # ~68 days after 2025-03-11
]
for pid, date, proc_id in infections:
    total += 1
    body = {
        "resourceType": "Procedure",
        "id": proc_id,
        "status": "completed",
        "code": {
            "coding": [{"system": "http://www.nhi.gov.tw/codes/procedure", "code": "64053B", "display": "後續醫療置換物感染手術"}],
            "text": "Prosthesis deep infection surgery (64053B)"
        },
        "subject": {"reference": f"Patient/{pid}"},
        "performedDateTime": f"{date}T14:00:00+08:00"
    }
    if put("Procedure", proc_id, body): success += 1

print(f"\nTotal: {total}, Success: {success}")
print(f"Expected 15-3: denominator=8, numerator=2, rate=25.00%")
