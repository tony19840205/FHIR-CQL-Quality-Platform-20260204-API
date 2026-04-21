import json, urllib.request, sys

FHIR_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

meds = [
    # Antipsychotic (03-4) - 5 meds, 3 patients, 2 with overlap
    {"id":"med-psych-01","display":"Olanzapine 10mg","code":"N05AH03","patient":"sun-1234567","date":"2026-01-15T09:00:00Z"},
    {"id":"med-psych-02","display":"Risperidone 2mg","code":"N05AX08","patient":"sun-1234567","date":"2026-01-20T09:00:00Z"},
    {"id":"med-psych-03","display":"Quetiapine 25mg","code":"N05AH04","patient":"TW10001","date":"2026-02-01T09:00:00Z"},
    {"id":"med-psych-04","display":"Olanzapine 5mg","code":"N05AH03","patient":"TW10001","date":"2026-02-10T09:00:00Z"},
    {"id":"med-psych-05","display":"Aripiprazole 10mg","code":"N05AX12","patient":"TW10002","date":"2026-01-25T09:00:00Z"},
    # Antidepressant (03-5) - 6 meds, 3 patients, 2 with overlap
    {"id":"med-antidep-01","display":"Sertraline 50mg","code":"N06AB06","patient":"sun-1234567","date":"2026-01-15T10:00:00Z"},
    {"id":"med-antidep-02","display":"Escitalopram 10mg","code":"N06AB10","patient":"sun-1234567","date":"2026-01-22T10:00:00Z"},
    {"id":"med-antidep-03","display":"Fluoxetine 20mg","code":"N06AB03","patient":"TW10001","date":"2026-02-05T10:00:00Z"},
    {"id":"med-antidep-04","display":"Venlafaxine 75mg","code":"N06AX16","patient":"TW10001","date":"2026-02-12T10:00:00Z"},
    {"id":"med-antidep-05","display":"Mirtazapine 15mg","code":"N06AX11","patient":"TW10002","date":"2026-01-28T10:00:00Z"},
    {"id":"med-antidep-06","display":"Paroxetine 20mg","code":"N06AB05","patient":"TW10003","date":"2026-02-18T10:00:00Z"},
    # Sedative (03-6) - 7 meds, 4 patients, 3 with overlap
    {"id":"med-sedative-01","display":"Zolpidem 10mg","code":"N05CF02","patient":"sun-1234567","date":"2026-01-15T11:00:00Z"},
    {"id":"med-sedative-02","display":"Diazepam 5mg","code":"N05BA01","patient":"sun-1234567","date":"2026-01-20T11:00:00Z"},
    {"id":"med-sedative-03","display":"Lorazepam 1mg","code":"N05BA06","patient":"TW10001","date":"2026-02-01T11:00:00Z"},
    {"id":"med-sedative-04","display":"Alprazolam 0.5mg","code":"N05BA12","patient":"TW10001","date":"2026-02-08T11:00:00Z"},
    {"id":"med-sedative-05","display":"Midazolam 7.5mg","code":"N05CD08","patient":"TW10002","date":"2026-01-25T11:00:00Z"},
    {"id":"med-sedative-06","display":"Triazolam 0.25mg","code":"N05CD05","patient":"TW10002","date":"2026-02-03T11:00:00Z"},
    {"id":"med-sedative-07","display":"Clonazepam 0.5mg","code":"N05BA02","patient":"TW10003","date":"2026-02-15T11:00:00Z"},
]

ok = 0
fail = 0
for m in meds:
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
        "dosageInstruction": [{"text": "1 tablet daily"}]
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
        print(f"OK: {m['id']} ({m['display']})")
        ok += 1
    except Exception as e:
        print(f"FAIL: {m['id']} - {e}")
        fail += 1

print(f"\nResult: {ok} OK, {fail} FAIL")
