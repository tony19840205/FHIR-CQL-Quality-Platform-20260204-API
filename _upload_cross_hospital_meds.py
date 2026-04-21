import json, urllib.request

FHIR_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

# Use existing patient IDs from the FHIR server
# 03-10: 5 patients for lipid-lowering cross-hospital
# 03-11: 5 patients for antidiabetic cross-hospital
# 03-12: 5 patients for antipsychotic cross-hospital
# 03-13: 5 patients for antidepressant cross-hospital
# Each group: 4 patients with cross-hospital overlap + 1 without

# Map logical patient roles to real FHIR patient IDs
P = {
    # 03-10 lipid
    "lip1": "10155", "lip2": "10356", "lip3": "10696", "lip4": "11238", "lip5": "11400",
    # 03-11 diabetes
    "dm1": "11870", "dm2": "12147", "dm3": "12342", "dm4": "12536", "dm5": "12817",
    # 03-12 antipsychotic
    "psy1": "13365", "psy2": "13436", "psy3": "13778", "psy4": "13957", "psy5": "14125",
    # 03-13 antidepressant
    "dep1": "14208", "dep2": "14354", "dep3": "14457", "dep4": "14698", "dep5": "14846",
}

meds = [
    # === 03-10 跨院降血脂 (Lipid-lowering) ===
    {"id":"med-cross-lipid-001-1","display":"Atorvastatin 20mg","code":"259255","patient":P["lip1"],"date":"2026-01-10T09:00:00Z","org":"CGMH","period_start":"2026-01-10","period_end":"2026-02-09"},
    {"id":"med-cross-lipid-001-2","display":"Rosuvastatin 10mg","code":"861634","patient":P["lip1"],"date":"2026-01-20T14:00:00Z","org":"NTUH","period_start":"2026-01-20","period_end":"2026-02-19"},
    {"id":"med-cross-lipid-002-1","display":"Simvastatin 20mg","code":"36567","patient":P["lip2"],"date":"2026-01-15T10:00:00Z","org":"VGH","period_start":"2026-01-15","period_end":"2026-02-14"},
    {"id":"med-cross-lipid-002-2","display":"Atorvastatin 10mg","code":"259255","patient":P["lip2"],"date":"2026-01-25T11:00:00Z","org":"KMUH","period_start":"2026-01-25","period_end":"2026-02-24"},
    {"id":"med-cross-lipid-003-1","display":"Fenofibrate 160mg","code":"310429","patient":P["lip3"],"date":"2026-02-01T09:00:00Z","org":"CGMH","period_start":"2026-02-01","period_end":"2026-03-03"},
    {"id":"med-cross-lipid-003-2","display":"Ezetimibe 10mg","code":"341248","patient":P["lip3"],"date":"2026-02-10T15:00:00Z","org":"NTUH","period_start":"2026-02-10","period_end":"2026-03-12"},
    {"id":"med-cross-lipid-004-1","display":"Pravastatin 40mg","code":"36567","patient":P["lip4"],"date":"2026-01-20T09:00:00Z","org":"VGH","period_start":"2026-01-20","period_end":"2026-02-19"},
    {"id":"med-cross-lipid-005-1","display":"Fluvastatin 80mg","code":"310430","patient":P["lip5"],"date":"2026-02-05T08:00:00Z","org":"KMUH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-lipid-005-2","display":"Gemfibrozil 600mg","code":"310431","patient":P["lip5"],"date":"2026-02-15T10:00:00Z","org":"CGMH","period_start":"2026-02-15","period_end":"2026-03-17"},

    # === 03-11 跨院降血糖 (Antidiabetic) ===
    {"id":"med-cross-dm-001-1","display":"Metformin 500mg","code":"860975","patient":P["dm1"],"date":"2026-01-10T09:00:00Z","org":"CGMH","period_start":"2026-01-10","period_end":"2026-02-09"},
    {"id":"med-cross-dm-001-2","display":"Glimepiride 2mg","code":"310534","patient":P["dm1"],"date":"2026-01-22T14:00:00Z","org":"NTUH","period_start":"2026-01-22","period_end":"2026-02-21"},
    {"id":"med-cross-dm-002-1","display":"Sitagliptin 100mg","code":"665044","patient":P["dm2"],"date":"2026-01-15T10:00:00Z","org":"VGH","period_start":"2026-01-15","period_end":"2026-02-14"},
    {"id":"med-cross-dm-002-2","display":"Empagliflozin 25mg","code":"1545653","patient":P["dm2"],"date":"2026-01-28T11:00:00Z","org":"KMUH","period_start":"2026-01-28","period_end":"2026-02-27"},
    {"id":"med-cross-dm-003-1","display":"Gliclazide 60mg","code":"310535","patient":P["dm3"],"date":"2026-02-01T09:00:00Z","org":"CGMH","period_start":"2026-02-01","period_end":"2026-03-03"},
    {"id":"med-cross-dm-003-2","display":"Dapagliflozin 10mg","code":"1488564","patient":P["dm3"],"date":"2026-02-12T15:00:00Z","org":"NTUH","period_start":"2026-02-12","period_end":"2026-03-14"},
    {"id":"med-cross-dm-004-1","display":"Insulin Glargine 100U","code":"274783","patient":P["dm4"],"date":"2026-01-20T09:00:00Z","org":"CGMH","period_start":"2026-01-20","period_end":"2026-02-19"},
    {"id":"med-cross-dm-005-1","display":"Pioglitazone 30mg","code":"310536","patient":P["dm5"],"date":"2026-02-05T08:00:00Z","org":"VGH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-dm-005-2","display":"Metformin 850mg","code":"860975","patient":P["dm5"],"date":"2026-02-18T10:00:00Z","org":"KMUH","period_start":"2026-02-18","period_end":"2026-03-20"},

    # === 03-12 跨院抗思覺失調 (Antipsychotic) ===
    {"id":"med-cross-psych-new-001-1","display":"Olanzapine 10mg","code":"N05AH03","patient":P["psy1"],"date":"2026-01-12T09:00:00Z","org":"CGMH","period_start":"2026-01-12","period_end":"2026-02-11"},
    {"id":"med-cross-psych-new-001-2","display":"Risperidone 2mg","code":"N05AX08","patient":P["psy1"],"date":"2026-01-25T14:00:00Z","org":"NTUH","period_start":"2026-01-25","period_end":"2026-02-24"},
    {"id":"med-cross-psych-new-002-1","display":"Quetiapine 100mg","code":"N05AH04","patient":P["psy2"],"date":"2026-01-18T10:00:00Z","org":"VGH","period_start":"2026-01-18","period_end":"2026-02-17"},
    {"id":"med-cross-psych-new-002-2","display":"Aripiprazole 15mg","code":"N05AX12","patient":P["psy2"],"date":"2026-02-01T11:00:00Z","org":"KMUH","period_start":"2026-02-01","period_end":"2026-03-03"},
    {"id":"med-cross-psych-new-003-1","display":"Haloperidol 5mg","code":"N05AD01","patient":P["psy3"],"date":"2026-02-05T09:00:00Z","org":"CGMH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-psych-new-003-2","display":"Clozapine 25mg","code":"N05AH02","patient":P["psy3"],"date":"2026-02-15T14:00:00Z","org":"NTUH","period_start":"2026-02-15","period_end":"2026-03-17"},
    {"id":"med-cross-psych-new-004-1","display":"Paliperidone 6mg","code":"N05AX13","patient":P["psy4"],"date":"2026-01-20T09:00:00Z","org":"VGH","period_start":"2026-01-20","period_end":"2026-02-19"},
    {"id":"med-cross-psych-new-005-1","display":"Ziprasidone 40mg","code":"N05AE04","patient":P["psy5"],"date":"2026-02-10T08:00:00Z","org":"KMUH","period_start":"2026-02-10","period_end":"2026-03-12"},
    {"id":"med-cross-psych-new-005-2","display":"Olanzapine 5mg","code":"N05AH03","patient":P["psy5"],"date":"2026-02-20T10:00:00Z","org":"CGMH","period_start":"2026-02-20","period_end":"2026-03-22"},

    # === 03-13 跨院抗憂鬱 (Antidepressant) ===
    {"id":"med-cross-dep-001-1","display":"Sertraline 50mg","code":"N06AB06","patient":P["dep1"],"date":"2026-01-10T09:00:00Z","org":"CGMH","period_start":"2026-01-10","period_end":"2026-02-09"},
    {"id":"med-cross-dep-001-2","display":"Escitalopram 10mg","code":"N06AB10","patient":P["dep1"],"date":"2026-01-22T14:00:00Z","org":"NTUH","period_start":"2026-01-22","period_end":"2026-02-21"},
    {"id":"med-cross-dep-002-1","display":"Fluoxetine 20mg","code":"N06AB03","patient":P["dep2"],"date":"2026-01-15T10:00:00Z","org":"VGH","period_start":"2026-01-15","period_end":"2026-02-14"},
    {"id":"med-cross-dep-002-2","display":"Venlafaxine 75mg","code":"N06AX16","patient":P["dep2"],"date":"2026-01-28T11:00:00Z","org":"KMUH","period_start":"2026-01-28","period_end":"2026-02-27"},
    {"id":"med-cross-dep-003-1","display":"Duloxetine 30mg","code":"N06AX21","patient":P["dep3"],"date":"2026-02-01T09:00:00Z","org":"CGMH","period_start":"2026-02-01","period_end":"2026-03-03"},
    {"id":"med-cross-dep-003-2","display":"Mirtazapine 15mg","code":"N06AX11","patient":P["dep3"],"date":"2026-02-12T15:00:00Z","org":"NTUH","period_start":"2026-02-12","period_end":"2026-03-14"},
    {"id":"med-cross-dep-004-1","display":"Paroxetine 20mg","code":"N06AB05","patient":P["dep4"],"date":"2026-01-20T09:00:00Z","org":"VGH","period_start":"2026-01-20","period_end":"2026-02-19"},
    {"id":"med-cross-dep-005-1","display":"Bupropion 150mg","code":"N06AX12","patient":P["dep5"],"date":"2026-02-05T08:00:00Z","org":"KMUH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-dep-005-2","display":"Citalopram 20mg","code":"N06AB04","patient":P["dep5"],"date":"2026-02-18T10:00:00Z","org":"CGMH","period_start":"2026-02-18","period_end":"2026-03-20"},
]

ok = 0
fail = 0
for m in meds:
    resource = {
        "resourceType": "MedicationRequest",
        "id": m["id"],
        "status": "completed",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [{"system": "http://www.whocc.no/atc" if m["code"].startswith("N") else "http://rxnorm.info", "code": m["code"], "display": m["display"]}],
            "text": m["display"]
        },
        "subject": {"reference": f"Patient/{m['patient']}"},
        "authoredOn": m["date"],
        "dosageInstruction": [{"timing": {"repeat": {"boundsPeriod": {"start": m["period_start"], "end": m["period_end"]}}}}],
        "dispenseRequest": {"validityPeriod": {"start": m["period_start"], "end": m["period_end"]}, "quantity": {"value": 30, "unit": "tablets"}},
        "contained": [{"resourceType": "Organization", "id": "org1", "name": m["org"]}]
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
        print(f"OK: {m['id']} ({m['display']}) [{m['org']}]")
        ok += 1
    except Exception as e:
        print(f"FAIL: {m['id']} - {e}")
        fail += 1

print(f"\nResult: {ok} OK, {fail} FAIL")
