#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Upload test data for:
- Indicator 09: 14天內非計畫再入院率 (14-day unplanned readmission rate)
- Indicator 10: 出院後3天內急診率 (3-day post-discharge ED visit rate)

Strategy:
- Use existing patients on FHIR server
- Create IMP Encounters with readmission within 14 days (for indicator 09)
- Create EMER Encounters within 3 days of IMP discharge (for indicator 10)
"""
import requests, json, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_URL = "https://thas.mohw.gov.tw/v/r4/fhir"
HEADERS = {"Content-Type": "application/fhir+json"}

# Existing patient IDs on the FHIR server
PATIENTS = ["10155", "10356", "10696", "11238", "11400", "11870"]

resources = []

# ========== Indicator 09: 14-day readmission ==========
# Patient 10155: discharged Jan 15, readmitted Jan 22 (7 days later)
# Patient 10356: discharged Feb 10, readmitted Feb 20 (10 days later)
# Patient 10696: discharged Mar 1, readmitted Mar 12 (11 days later)

readmission_data = [
    # (patient_id, enc1_start, enc1_end, enc2_start, enc2_end)
    ("10155", "2026-01-10T08:00:00+08:00", "2026-01-15T10:00:00+08:00",
              "2026-01-22T09:00:00+08:00", "2026-01-27T14:00:00+08:00"),
    ("10356", "2026-02-05T07:00:00+08:00", "2026-02-10T11:00:00+08:00",
              "2026-02-20T08:00:00+08:00", "2026-02-25T16:00:00+08:00"),
    ("10696", "2026-02-25T10:00:00+08:00", "2026-03-01T09:00:00+08:00",
              "2026-03-12T11:00:00+08:00", "2026-03-17T15:00:00+08:00"),
]

for i, (pat, s1, e1, s2, e2) in enumerate(readmission_data):
    # First admission
    resources.append({
        "resourceType": "Encounter",
        "id": f"readmit-enc-{pat}-1",
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient encounter"},
        "type": [{"coding": [{"system": "http://snomed.info/sct", "code": "32485007", "display": "Hospital admission"}], "text": "住院"}],
        "subject": {"reference": f"Patient/{pat}"},
        "period": {"start": s1, "end": e1},
        "hospitalization": {
            "dischargeDisposition": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/discharge-disposition", "code": "home", "display": "Home"}], "text": "出院返家"}
        }
    })
    # Readmission (within 14 days)
    resources.append({
        "resourceType": "Encounter",
        "id": f"readmit-enc-{pat}-2",
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient encounter"},
        "type": [{"coding": [{"system": "http://snomed.info/sct", "code": "32485007", "display": "Hospital admission"}], "text": "非計畫再入院"}],
        "subject": {"reference": f"Patient/{pat}"},
        "period": {"start": s2, "end": e2},
        "hospitalization": {
            "dischargeDisposition": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/discharge-disposition", "code": "home", "display": "Home"}], "text": "出院返家"}
        }
    })

# ========== Indicator 10: 3-day post-discharge ED visit ==========
# Patient 11238: discharged Jan 20, ED visit Jan 21 (1 day later)
# Patient 11400: discharged Feb 15, ED visit Feb 17 (2 days later)
# Patient 11870: discharged Mar 5, ED visit Mar 7 (2 days later)

ed_visit_data = [
    # (patient_id, imp_start, imp_end, emer_start, emer_end)
    ("11238", "2026-01-15T08:00:00+08:00", "2026-01-20T10:00:00+08:00",
              "2026-01-21T14:00:00+08:00", "2026-01-21T18:00:00+08:00"),
    ("11400", "2026-02-10T07:00:00+08:00", "2026-02-15T11:00:00+08:00",
              "2026-02-17T09:00:00+08:00", "2026-02-17T13:00:00+08:00"),
    ("11870", "2026-03-01T10:00:00+08:00", "2026-03-05T09:00:00+08:00",
              "2026-03-07T16:00:00+08:00", "2026-03-07T20:00:00+08:00"),
]

for pat, imp_s, imp_e, em_s, em_e in ed_visit_data:
    # IMP encounter (discharge)
    resources.append({
        "resourceType": "Encounter",
        "id": f"edvisit-imp-{pat}",
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient encounter"},
        "type": [{"coding": [{"system": "http://snomed.info/sct", "code": "32485007", "display": "Hospital admission"}], "text": "住院"}],
        "subject": {"reference": f"Patient/{pat}"},
        "period": {"start": imp_s, "end": imp_e},
        "hospitalization": {
            "dischargeDisposition": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/discharge-disposition", "code": "home", "display": "Home"}], "text": "出院返家"}
        }
    })
    # EMER encounter (within 3 days of discharge)
    resources.append({
        "resourceType": "Encounter",
        "id": f"edvisit-emer-{pat}",
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "EMER", "display": "emergency"},
        "type": [{"coding": [{"system": "http://snomed.info/sct", "code": "4525004", "display": "Emergency department patient visit"}], "text": "急診"}],
        "subject": {"reference": f"Patient/{pat}"},
        "period": {"start": em_s, "end": em_e}
    })

# Upload via individual PUT requests
print("=" * 60)
print("上傳指標 09/10 測試資料")
print("=" * 60)
print(f"Total resources to upload: {len(resources)}")
print()

ok_count = 0
fail_count = 0
for r in resources:
    url = f"{FHIR_URL}/{r['resourceType']}/{r['id']}"
    resp = requests.put(url, json=r, headers=HEADERS, verify=False, timeout=30)
    status = "OK" if resp.status_code in (200, 201) else f"FAIL({resp.status_code})"
    print(f"  {status} - {r['resourceType']}/{r['id']} ({r.get('class',{}).get('code','')}) -> Patient/{r['subject']['reference'].split('/')[-1]}")
    if resp.status_code in (200, 201):
        ok_count += 1
    else:
        fail_count += 1
        print(f"    Error: {resp.text[:200]}")

print()
print(f"Results: {ok_count} OK, {fail_count} FAIL")
print()
print("Expected results:")
print("  Indicator 09 (14-day readmission): 3 readmissions / total IMP encounters")
print("  Indicator 10 (3-day ED visit): 3 ED visits / total IMP discharges")
