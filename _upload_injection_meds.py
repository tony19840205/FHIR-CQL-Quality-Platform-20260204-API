import json, urllib.request

FHIR_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

# 6 injection MedicationRequests for different patients
injection_meds = [
    {"id": "med-inj-01", "display": "Ibuprofen injection 400mg", "code": "197806", "patient": "sun-1234567", "date": "2026-01-10T08:00:00Z"},
    {"id": "med-inj-02", "display": "Ketorolac injection 30mg", "code": "834022", "patient": "TW10001", "date": "2026-01-15T09:00:00Z"},
    {"id": "med-inj-03", "display": "Ceftriaxone injection 1g", "code": "309090", "patient": "TW10002", "date": "2026-01-20T10:00:00Z"},
    {"id": "med-inj-04", "display": "Metoclopramide injection 10mg", "code": "311700", "patient": "TW10003", "date": "2026-02-01T08:30:00Z"},
    {"id": "med-inj-05", "display": "Dexamethasone injection 4mg", "code": "197577", "patient": "TW10004", "date": "2026-02-05T14:00:00Z"},
    {"id": "med-inj-06", "display": "Diclofenac injection 75mg", "code": "855636", "patient": "TW10005", "date": "2026-02-10T11:00:00Z"},
]

ok = 0
fail = 0
for m in injection_meds:
    resource = {
        "resourceType": "MedicationRequest",
        "id": m["id"],
        "status": "active",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [{"system": "http://rxnorm.info", "code": m["code"], "display": m["display"]}],
            "text": m["display"]
        },
        "subject": {"reference": f"Patient/{m['patient']}"},
        "authoredOn": m["date"],
        "dosageInstruction": [{"text": "injection once", "route": {"coding": [{"system": "http://snomed.info/sct", "code": "385219001", "display": "Injection"}], "text": "Injection"}}]
    }
    data = json.dumps(resource).encode("utf-8")
    req = urllib.request.Request(
        f"{FHIR_URL}/MedicationRequest/{m['id']}",
        data=data,
        method="PUT",
        headers={"Content-Type": "application/fhir+json"}
    )
    try:
        resp = urllib.request.urlopen(req, timeout=15)
        print(f"OK: {m['id']} ({m['display']}) -> {m['patient']}")
        ok += 1
    except Exception as e:
        print(f"FAIL: {m['id']} - {e}")
        fail += 1

print(f"\nResult: {ok} OK, {fail} FAIL")
