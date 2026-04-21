import json, urllib.request

FHIR_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

# Use existing patient IDs from the FHIR server
P = {
    # 03-9 antihypertensive (降血壓)
    "bp1": "15165", "bp2": "15340", "bp3": "15845", "bp4": "16320", "bp5": "17025",
    # 03-14 sedative (安眠鎮靜)
    "sed1": "17580", "sed2": "18113", "sed3": "19172", "sed4": "19760", "sed5": "20151",
    # 03-15 antithrombotic (抗血栓)
    "thr1": "20354", "thr2": "20706", "thr3": "20971", "thr4": "21201", "thr5": "21731",
    # 03-16 prostate (前列腺)
    "pro1": "21834", "pro2": "22419", "pro3": "22579", "pro4": "22715", "pro5": "22839",
}

meds = [
    # === 03-9 跨院降血壓 (Antihypertensive) ===
    # Patient bp1: Amlodipine @ CGMH + Valsartan @ NTUH (跨院)
    {"id":"med-cross-bp-001-1","display":"Amlodipine 5mg","code":"329528","patient":P["bp1"],"date":"2026-01-10T09:00:00Z","org":"CGMH","period_start":"2026-01-10","period_end":"2026-02-09"},
    {"id":"med-cross-bp-001-2","display":"Valsartan 80mg","code":"349201","patient":P["bp1"],"date":"2026-01-20T14:00:00Z","org":"NTUH","period_start":"2026-01-20","period_end":"2026-02-19"},
    # Patient bp2: Losartan @ VGH + Enalapril @ KMUH (跨院)
    {"id":"med-cross-bp-002-1","display":"Losartan 50mg","code":"979480","patient":P["bp2"],"date":"2026-01-15T10:00:00Z","org":"VGH","period_start":"2026-01-15","period_end":"2026-02-14"},
    {"id":"med-cross-bp-002-2","display":"Enalapril 10mg","code":"316110","patient":P["bp2"],"date":"2026-01-25T11:00:00Z","org":"KMUH","period_start":"2026-01-25","period_end":"2026-02-24"},
    # Patient bp3: Nifedipine @ CGMH + Metoprolol @ NTUH (跨院)
    {"id":"med-cross-bp-003-1","display":"Nifedipine 30mg","code":"197765","patient":P["bp3"],"date":"2026-02-01T09:00:00Z","org":"CGMH","period_start":"2026-02-01","period_end":"2026-03-03"},
    {"id":"med-cross-bp-003-2","display":"Metoprolol 50mg","code":"866514","patient":P["bp3"],"date":"2026-02-10T15:00:00Z","org":"NTUH","period_start":"2026-02-10","period_end":"2026-03-12"},
    # Patient bp4: Atenolol @ VGH only (無跨院)
    {"id":"med-cross-bp-004-1","display":"Atenolol 50mg","code":"197361","patient":P["bp4"],"date":"2026-01-20T09:00:00Z","org":"VGH","period_start":"2026-01-20","period_end":"2026-02-19"},
    # Patient bp5: Lisinopril @ KMUH + Hydrochlorothiazide @ CGMH (跨院)
    {"id":"med-cross-bp-005-1","display":"Lisinopril 10mg","code":"316151","patient":P["bp5"],"date":"2026-02-05T08:00:00Z","org":"KMUH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-bp-005-2","display":"Hydrochlorothiazide 25mg","code":"310798","patient":P["bp5"],"date":"2026-02-15T10:00:00Z","org":"CGMH","period_start":"2026-02-15","period_end":"2026-03-17"},

    # === 03-14 跨院安眠鎮靜 (Sedative/Hypnotic) ===
    # Patient sed1: Zolpidem @ CGMH + Diazepam @ NTUH (跨院)
    {"id":"med-cross-sed-001-1","display":"Zolpidem 10mg","code":"854878","patient":P["sed1"],"date":"2026-01-12T09:00:00Z","org":"CGMH","period_start":"2026-01-12","period_end":"2026-02-11"},
    {"id":"med-cross-sed-001-2","display":"Diazepam 5mg","code":"197590","patient":P["sed1"],"date":"2026-01-25T14:00:00Z","org":"NTUH","period_start":"2026-01-25","period_end":"2026-02-24"},
    # Patient sed2: Lorazepam @ VGH + Alprazolam @ KMUH (跨院)
    {"id":"med-cross-sed-002-1","display":"Lorazepam 1mg","code":"197901","patient":P["sed2"],"date":"2026-01-18T10:00:00Z","org":"VGH","period_start":"2026-01-18","period_end":"2026-02-17"},
    {"id":"med-cross-sed-002-2","display":"Alprazolam 0.5mg","code":"308047","patient":P["sed2"],"date":"2026-02-01T11:00:00Z","org":"KMUH","period_start":"2026-02-01","period_end":"2026-03-03"},
    # Patient sed3: Clonazepam @ CGMH + Zopiclone @ NTUH (跨院)
    {"id":"med-cross-sed-003-1","display":"Clonazepam 0.5mg","code":"197527","patient":P["sed3"],"date":"2026-02-05T09:00:00Z","org":"CGMH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-sed-003-2","display":"Zopiclone 7.5mg","code":"199282","patient":P["sed3"],"date":"2026-02-15T14:00:00Z","org":"NTUH","period_start":"2026-02-15","period_end":"2026-03-17"},
    # Patient sed4: Triazolam @ VGH only (無跨院)
    {"id":"med-cross-sed-004-1","display":"Triazolam 0.25mg","code":"198321","patient":P["sed4"],"date":"2026-01-20T09:00:00Z","org":"VGH","period_start":"2026-01-20","period_end":"2026-02-19"},
    # Patient sed5: Midazolam @ KMUH + Zolpidem @ CGMH (跨院)
    {"id":"med-cross-sed-005-1","display":"Midazolam 7.5mg","code":"198050","patient":P["sed5"],"date":"2026-02-10T08:00:00Z","org":"KMUH","period_start":"2026-02-10","period_end":"2026-03-12"},
    {"id":"med-cross-sed-005-2","display":"Zolpidem 5mg","code":"854878","patient":P["sed5"],"date":"2026-02-20T10:00:00Z","org":"CGMH","period_start":"2026-02-20","period_end":"2026-03-22"},

    # === 03-15 跨院抗血栓 (Antithrombotic) ===
    # Patient thr1: Warfarin @ CGMH + Clopidogrel @ NTUH (跨院)
    {"id":"med-cross-thr-001-1","display":"Warfarin 5mg","code":"855332","patient":P["thr1"],"date":"2026-01-10T09:00:00Z","org":"CGMH","period_start":"2026-01-10","period_end":"2026-02-09"},
    {"id":"med-cross-thr-001-2","display":"Clopidogrel 75mg","code":"309362","patient":P["thr1"],"date":"2026-01-22T14:00:00Z","org":"NTUH","period_start":"2026-01-22","period_end":"2026-02-21"},
    # Patient thr2: Rivaroxaban @ VGH + Aspirin @ KMUH (跨院)
    {"id":"med-cross-thr-002-1","display":"Rivaroxaban 20mg","code":"1114195","patient":P["thr2"],"date":"2026-01-15T10:00:00Z","org":"VGH","period_start":"2026-01-15","period_end":"2026-02-14"},
    {"id":"med-cross-thr-002-2","display":"Aspirin 100mg","code":"198464","patient":P["thr2"],"date":"2026-01-28T11:00:00Z","org":"KMUH","period_start":"2026-01-28","period_end":"2026-02-27"},
    # Patient thr3: Apixaban @ CGMH + Ticagrelor @ NTUH (跨院)
    {"id":"med-cross-thr-003-1","display":"Apixaban 5mg","code":"1364430","patient":P["thr3"],"date":"2026-02-01T09:00:00Z","org":"CGMH","period_start":"2026-02-01","period_end":"2026-03-03"},
    {"id":"med-cross-thr-003-2","display":"Ticagrelor 90mg","code":"1116632","patient":P["thr3"],"date":"2026-02-12T15:00:00Z","org":"NTUH","period_start":"2026-02-12","period_end":"2026-03-14"},
    # Patient thr4: Dabigatran @ VGH only (無跨院)
    {"id":"med-cross-thr-004-1","display":"Dabigatran 150mg","code":"1037042","patient":P["thr4"],"date":"2026-01-20T09:00:00Z","org":"VGH","period_start":"2026-01-20","period_end":"2026-02-19"},
    # Patient thr5: Enoxaparin @ KMUH + Warfarin @ CGMH (跨院)
    {"id":"med-cross-thr-005-1","display":"Enoxaparin 40mg","code":"854228","patient":P["thr5"],"date":"2026-02-05T08:00:00Z","org":"KMUH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-thr-005-2","display":"Warfarin 2.5mg","code":"855332","patient":P["thr5"],"date":"2026-02-18T10:00:00Z","org":"CGMH","period_start":"2026-02-18","period_end":"2026-03-20"},

    # === 03-16 跨院前列腺 (Prostate) ===
    # Patient pro1: Tamsulosin @ CGMH + Finasteride @ NTUH (跨院)
    {"id":"med-cross-pro-001-1","display":"Tamsulosin 0.4mg","code":"866511","patient":P["pro1"],"date":"2026-01-10T09:00:00Z","org":"CGMH","period_start":"2026-01-10","period_end":"2026-02-09"},
    {"id":"med-cross-pro-001-2","display":"Finasteride 5mg","code":"310445","patient":P["pro1"],"date":"2026-01-20T14:00:00Z","org":"NTUH","period_start":"2026-01-20","period_end":"2026-02-19"},
    # Patient pro2: Alfuzosin @ VGH + Dutasteride @ KMUH (跨院)
    {"id":"med-cross-pro-002-1","display":"Alfuzosin 10mg","code":"597979","patient":P["pro2"],"date":"2026-01-15T10:00:00Z","org":"VGH","period_start":"2026-01-15","period_end":"2026-02-14"},
    {"id":"med-cross-pro-002-2","display":"Dutasteride 0.5mg","code":"597195","patient":P["pro2"],"date":"2026-01-25T11:00:00Z","org":"KMUH","period_start":"2026-01-25","period_end":"2026-02-24"},
    # Patient pro3: Doxazosin @ CGMH + Tamsulosin @ NTUH (跨院)
    {"id":"med-cross-pro-003-1","display":"Doxazosin 4mg","code":"197627","patient":P["pro3"],"date":"2026-02-01T09:00:00Z","org":"CGMH","period_start":"2026-02-01","period_end":"2026-03-03"},
    {"id":"med-cross-pro-003-2","display":"Tamsulosin 0.2mg","code":"866511","patient":P["pro3"],"date":"2026-02-10T15:00:00Z","org":"NTUH","period_start":"2026-02-10","period_end":"2026-03-12"},
    # Patient pro4: Silodosin @ VGH only (無跨院)
    {"id":"med-cross-pro-004-1","display":"Silodosin 8mg","code":"855292","patient":P["pro4"],"date":"2026-01-20T09:00:00Z","org":"VGH","period_start":"2026-01-20","period_end":"2026-02-19"},
    # Patient pro5: Finasteride @ KMUH + Alfuzosin @ CGMH (跨院)
    {"id":"med-cross-pro-005-1","display":"Finasteride 1mg","code":"310445","patient":P["pro5"],"date":"2026-02-05T08:00:00Z","org":"KMUH","period_start":"2026-02-05","period_end":"2026-03-07"},
    {"id":"med-cross-pro-005-2","display":"Alfuzosin 5mg","code":"597979","patient":P["pro5"],"date":"2026-02-15T10:00:00Z","org":"CGMH","period_start":"2026-02-15","period_end":"2026-03-17"},
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
            "coding": [{"system": "http://rxnorm.info", "code": m["code"], "display": m["display"]}],
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
