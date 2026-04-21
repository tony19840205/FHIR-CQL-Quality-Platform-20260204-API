import json, urllib.request

FHIR_URL = "https://thas.mohw.gov.tw/v/r4/fhir"

# Existing patient IDs from the FHIR server
# 04: chronic refill patients
# 05: polypharmacy patients (10+ drugs)
# 06: pediatric asthma ED visits

resources = []

# === Indicator 04: 慢性病連處籤使用率 ===
# Need MedicationRequests with dispenseRequest.numberOfRepeatsAllowed > 0
# Use patients: 23025, 23572, 23786, 23890, 24096, 24451, 24554
chronic_patients = ["23025", "23572", "23786", "23890", "24096", "24451", "24554"]
chronic_drugs = [
    ("Amlodipine 5mg", "329528"), ("Metformin 500mg", "860975"), ("Atorvastatin 20mg", "259255"),
    ("Losartan 50mg", "979480"), ("Lisinopril 10mg", "316151"), ("Glimepiride 2mg", "310534"),
    ("Omeprazole 20mg", "198053"),
]
for i, pid in enumerate(chronic_patients):
    drug = chronic_drugs[i % len(chronic_drugs)]
    # 5 out of 7 have refills (numberOfRepeatsAllowed > 0)
    refills = 3 if i < 5 else 0
    resources.append({
        "resourceType": "MedicationRequest",
        "id": f"med-chronic-{pid}",
        "status": "completed",
        "intent": "order",
        "medicationCodeableConcept": {
            "coding": [{"system": "http://rxnorm.info", "code": drug[1], "display": drug[0]}],
            "text": drug[0]
        },
        "subject": {"reference": f"Patient/{pid}"},
        "authoredOn": "2026-01-15T09:00:00Z",
        "dispenseRequest": {
            "numberOfRepeatsAllowed": refills,
            "validityPeriod": {"start": "2026-01-15", "end": "2026-04-15"},
            "quantity": {"value": 90 if refills > 0 else 30, "unit": "tablets"}
        }
    })

# === Indicator 05: 處方10種以上藥品率 ===
# Need patients with 10+ unique drugs
# Use patients: 25075, 25259, 25733, 25921, 26060
poly_patients = ["25075", "25259", "25733", "25921", "26060"]
all_drugs = [
    ("Amlodipine 5mg","329528"), ("Metformin 500mg","860975"), ("Atorvastatin 20mg","259255"),
    ("Losartan 50mg","979480"), ("Omeprazole 20mg","198053"), ("Aspirin 100mg","198464"),
    ("Metoprolol 50mg","866514"), ("Furosemide 40mg","197730"), ("Warfarin 5mg","855332"),
    ("Clopidogrel 75mg","309362"), ("Sitagliptin 100mg","665044"), ("Pantoprazole 40mg","261255"),
    ("Levothyroxine 50mcg","966222"), ("Prednisone 5mg","763179"),
]
for i, pid in enumerate(poly_patients):
    # First 3 patients get 12 drugs (polypharmacy), last 2 get 5 drugs
    n_drugs = 12 if i < 3 else 5
    for j in range(n_drugs):
        drug = all_drugs[j % len(all_drugs)]
        resources.append({
            "resourceType": "MedicationRequest",
            "id": f"med-poly-{pid}-{j+1}",
            "status": "completed",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://rxnorm.info", "code": drug[1], "display": drug[0]}],
                "text": drug[0]
            },
            "subject": {"reference": f"Patient/{pid}"},
            "authoredOn": f"2026-01-{10+j:02d}T09:00:00Z",
            "dispenseRequest": {
                "validityPeriod": {"start": f"2026-01-{10+j:02d}", "end": f"2026-02-{10+j:02d}"},
                "quantity": {"value": 30, "unit": "tablets"}
            }
        })

# === Indicator 06: 小兒氣喘急診率 ===
# Need Encounters with reasonCode containing asthma/氣喘/J45
# Use patients: 26236, 26521, 26667, 26860, 27051, 27147, 27429
asthma_patients = ["26236", "26521", "26667", "26860", "27051", "27147", "27429"]
for i, pid in enumerate(asthma_patients):
    # 4 out of 7 are asthma-related ED visits
    if i < 4:
        reason_code = [{"coding": [{"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": "J45.20", "display": "Mild intermittent asthma with acute exacerbation"}], "text": "小兒氣喘急性發作"}]
    else:
        reason_code = [{"coding": [{"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": "J06.9", "display": "Acute upper respiratory infection"}], "text": "上呼吸道感染"}]
    resources.append({
        "resourceType": "Encounter",
        "id": f"enc-asthma-{pid}",
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "EMER", "display": "emergency"},
        "subject": {"reference": f"Patient/{pid}"},
        "reasonCode": reason_code,
        "period": {"start": f"2026-01-{12+i*3:02d}T08:00:00Z", "end": f"2026-01-{12+i*3:02d}T16:00:00Z"}
    })
    # Also add AMB encounters for the same patients so they appear in outpatient queries
    resources.append({
        "resourceType": "Encounter",
        "id": f"enc-amb-asthma-{pid}",
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"},
        "subject": {"reference": f"Patient/{pid}"},
        "reasonCode": reason_code,
        "period": {"start": f"2026-01-{12+i*3:02d}T08:00:00Z", "end": f"2026-01-{12+i*3:02d}T16:00:00Z"}
    })

# Upload all
ok = 0
fail = 0
for r in resources:
    rt = r["resourceType"]
    rid = r["id"]
    data = json.dumps(r).encode("utf-8")
    req = urllib.request.Request(
        f"{FHIR_URL}/{rt}/{rid}",
        data=data,
        method="PUT",
        headers={"Content-Type": "application/fhir+json"}
    )
    try:
        resp = urllib.request.urlopen(req, timeout=15)
        label = r.get("medicationCodeableConcept", {}).get("text", "") or r.get("reasonCode", [{}])[0].get("text", "")
        print(f"OK: {rt}/{rid} - {label}")
        ok += 1
    except Exception as e:
        print(f"FAIL: {rt}/{rid} - {e}")
        fail += 1

print(f"\nResult: {ok} OK, {fail} FAIL")
print(f"  04 chronic refill meds: {len(chronic_patients)}")
print(f"  05 polypharmacy meds: {sum(12 if i<3 else 5 for i in range(len(poly_patients)))}")
print(f"  06 asthma encounters: {len(asthma_patients) * 2}")
