"""
Upload test data for surgery quality indicators 12, 13, 14
- Indicator 12: 清淨手術抗生素超3天率 - needs clean surgery procedures + antibiotic MedicationAdministration
- Indicator 13: ESWL平均利用次數 - needs ESWL procedures (50023A, 50024A, 50025A, 50026A)
- Indicator 14: 子宮肌瘤手術14天再入院率 - needs fibroid surgery + D25 conditions + readmission encounters
"""
import requests
import json

FHIR_BASE = "https://thas.mohw.gov.tw/v/r4/fhir"
HEADERS = {"Content-Type": "application/fhir+json"}

# Use existing patient IDs
PATIENTS = ["2892", "4117", "4679", "4836", "4896", "4969", "6295", "6377", "7241", "7530", "7616", "8133"]

def put(resource_type, resource_id, body):
    url = f"{FHIR_BASE}/{resource_type}/{resource_id}"
    r = requests.put(url, headers=HEADERS, json=body, timeout=30)
    status = "OK" if r.status_code in (200, 201) else f"FAIL({r.status_code})"
    print(f"  PUT {resource_type}/{resource_id} => {status}")
    return r.status_code in (200, 201)

success = 0
total = 0

# =========================================================
# Indicator 13: ESWL (50023A, 50024A, 50025A, 50026A)
# Need: ESWL Procedure resources for multiple patients
# Some patients get multiple ESWL to show average > 1
# =========================================================
print("=== Indicator 13: ESWL Procedures ===")

eswl_data = [
    # (patient_id, eswl_code, eswl_display, date, procedure_id_suffix)
    ("2892", "50023A", "體外乏乙術碎石術-腎臟", "2025-03-15", "eswl-1"),
    ("2892", "50023A", "體外乏乙術碎石術-腎臟", "2025-06-20", "eswl-2"),
    ("2892", "50024A", "體外乏乙術碎石術-輸尿管", "2025-09-10", "eswl-3"),
    ("4117", "50023A", "體外震波碎石術-腎臟", "2025-04-12", "eswl-4"),
    ("4117", "50024A", "體外震波碎石術-輸尿管", "2025-07-18", "eswl-5"),
    ("4679", "50025A", "體外震波碎石術-膀胱", "2025-05-22", "eswl-6"),
    ("4679", "50025A", "體外震波碎石術-膀胱", "2025-08-30", "eswl-7"),
    ("4679", "50026A", "體外震波碎石術-其他", "2025-11-15", "eswl-8"),
    ("4836", "50023A", "體外震波碎石術-腎臟", "2025-02-28", "eswl-9"),
    ("4896", "50024A", "體外震波碎石術-輸尿管", "2025-06-15", "eswl-10"),
    ("4896", "50024A", "體外震波碎石術-輸尿管", "2025-10-20", "eswl-11"),
    ("4969", "50023A", "體外震波碎石術-腎臟", "2025-07-05", "eswl-12"),
    ("6295", "50026A", "體外震波碎石術-其他", "2025-08-12", "eswl-13"),
    ("6295", "50023A", "體外震波碎石術-腎臟", "2025-11-25", "eswl-14"),
    ("6377", "50023A", "體外震波碎石術-腎臟", "2025-09-18", "eswl-15"),
]

for pid, code, display, date, proc_id in eswl_data:
    total += 1
    body = {
        "resourceType": "Procedure",
        "id": proc_id,
        "status": "completed",
        "code": {
            "coding": [{"system": "http://www.nhi.gov.tw/codes/procedure", "code": code, "display": display}],
            "text": f"ESWL 體外震波碎石術 ({code})"
        },
        "subject": {"reference": f"Patient/{pid}"},
        "performedDateTime": f"{date}T10:00:00+08:00"
    }
    if put("Procedure", proc_id, body):
        success += 1

# =========================================================
# Indicator 12: Clean Surgery + Antibiotic > 3 days
# Need: Joint repair NHI procedure + MedicationAdministration with J01 antibiotics
# CQL checks: NHI code in {75607C, 75610B, 75613C, 75614C, 75615C, 88029C}
# And antibiotic MedicationRequest with J01 code (but backend uses MedicationAdministration)
# =========================================================
print("\n=== Indicator 12: Clean Surgery + Antibiotics ===")

# Create inpatient encounters for clean surgery patients
clean_surgery_patients = ["7241", "7530", "7616", "8133", "8461", "8599"]
clean_surgery_encounters = []

for i, pid in enumerate(clean_surgery_patients):
    enc_id = f"cs-enc-{i+1}"
    admit_date = f"2025-{(i % 6) + 3:02d}-{10 + i:02d}"
    discharge_date = f"2025-{(i % 6) + 3:02d}-{17 + i:02d}"
    total += 1
    body = {
        "resourceType": "Encounter",
        "id": enc_id,
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient encounter"},
        "subject": {"reference": f"Patient/{pid}"},
        "period": {
            "start": f"{admit_date}T08:00:00+08:00",
            "end": f"{discharge_date}T10:00:00+08:00"
        }
    }
    if put("Encounter", enc_id, body):
        success += 1
    clean_surgery_encounters.append((pid, enc_id, admit_date, discharge_date))

# Create clean surgery procedures (joint repair NHI codes)
nhi_codes = ["75607C", "75610B", "75613C", "75614C", "75615C", "88029C"]
nhi_displays = ["關節修復術-膝", "關節修復術-髖", "關節修復術-肩", "關節修復術-肘", "關節修復術-踝", "關節修復術-其他"]

for i, (pid, enc_id, admit_date, _) in enumerate(clean_surgery_encounters):
    proc_id = f"cs-proc-{i+1}"
    total += 1
    body = {
        "resourceType": "Procedure",
        "id": proc_id,
        "status": "completed",
        "code": {
            "coding": [
                {"system": "http://www.nhi.gov.tw/codes/procedure", "code": nhi_codes[i], "display": nhi_displays[i]}
            ],
            "text": f"Clean surgery - {nhi_displays[i]}"
        },
        "subject": {"reference": f"Patient/{pid}"},
        "encounter": {"reference": f"Encounter/{enc_id}"},
        "performedDateTime": f"{admit_date}T14:00:00+08:00"
    }
    if put("Procedure", proc_id, body):
        success += 1

# Create MedicationAdministration for antibiotic usage
# First 4 patients: > 3 days of antibiotics (numerator)
# Last 2 patients: <= 3 days (denominator only)
print("\n--- Antibiotic MedicationAdministration ---")

for i, (pid, enc_id, admit_date, discharge_date) in enumerate(clean_surgery_encounters):
    year, month, day = admit_date.split("-")
    base_day = int(day)
    # First 4 patients get 4-5 days of antibiotics
    if i < 4:
        num_days = 4 + (i % 2)  # 4 or 5 days
    else:
        num_days = 2 + (i % 2)  # 2 or 3 days
    
    for d in range(num_days):
        ma_id = f"cs-ma-{i+1}-d{d+1}"
        ab_date = f"{year}-{month}-{base_day + d + 1:02d}"
        total += 1
        body = {
            "resourceType": "MedicationAdministration",
            "id": ma_id,
            "status": "completed",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.whocc.no/atc", "code": "J01CR02", "display": "Amoxicillin and enzyme inhibitor"}],
                "text": "Amoxicillin/Clavulanate (Augmentin)"
            },
            "subject": {"reference": f"Patient/{pid}"},
            "context": {"reference": f"Encounter/{enc_id}"},
            "effectiveDateTime": f"{ab_date}T08:00:00+08:00"
        }
        if put("MedicationAdministration", ma_id, body):
            success += 1

# =========================================================
# Indicator 14: Uterine Fibroid Surgery 14-day Readmission
# Need: Fibroid surgery procedures (97010K etc) + D25 conditions + readmission encounters
# =========================================================
print("\n=== Indicator 14: Uterine Fibroid Surgery ===")

fibroid_patients = ["4117", "4679", "4836", "4896", "4969", "6295", "6377", "7241", "7530"]
fibroid_codes = ["97010K", "97011A", "97012B", "97013B", "80402C", "80420C", "97025K", "97026A", "97027B"]
fibroid_displays = [
    "子宮肌瘤摘除術-腹腔鏡", "子宮肌瘤摘除術-開腹", "子宮肌瘤摘除術-子宮鏡",
    "子宮肌瘤摘除術-複雜", "子宮切除術-腹腔鏡", "子宮切除術-開腹",
    "子宮肌瘤摘除術-達文西", "子宮肌瘤摘除術-微創", "子宮肌瘤摘除術-其他"
]

# Create fibroid surgery encounters + procedures + conditions
for i, pid in enumerate(fibroid_patients):
    enc_id = f"fib-enc-{i+1}"
    month = (i % 9) + 2
    admit_date = f"2025-{month:02d}-{10 + (i * 2):02d}"
    discharge_date = f"2025-{month:02d}-{15 + (i * 2):02d}"
    
    # Encounter
    total += 1
    body = {
        "resourceType": "Encounter",
        "id": enc_id,
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient encounter"},
        "subject": {"reference": f"Patient/{pid}"},
        "period": {
            "start": f"{admit_date}T08:00:00+08:00",
            "end": f"{discharge_date}T10:00:00+08:00"
        }
    }
    if put("Encounter", enc_id, body):
        success += 1

    # Fibroid Procedure
    proc_id = f"fib-proc-{i+1}"
    total += 1
    body = {
        "resourceType": "Procedure",
        "id": proc_id,
        "status": "completed",
        "code": {
            "coding": [{"system": "http://www.nhi.gov.tw/codes/procedure", "code": fibroid_codes[i], "display": fibroid_displays[i]}],
            "text": f"子宮肌瘤手術 ({fibroid_codes[i]})"
        },
        "subject": {"reference": f"Patient/{pid}"},
        "encounter": {"reference": f"Encounter/{enc_id}"},
        "performedDateTime": f"{admit_date}T14:00:00+08:00"
    }
    if put("Procedure", proc_id, body):
        success += 1
    
    # D25 Condition (uterine fibroid diagnosis)
    cond_id = f"fib-cond-{i+1}"
    d25_codes = ["D25.0", "D25.1", "D25.2", "D25.9"]
    total += 1
    body = {
        "resourceType": "Condition",
        "id": cond_id,
        "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
        "code": {
            "coding": [{"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": d25_codes[i % 4], "display": "子宮肌瘤"}],
            "text": "子宮平滑肌瘤 (Uterine leiomyoma)"
        },
        "subject": {"reference": f"Patient/{pid}"}
    }
    if put("Condition", cond_id, body):
        success += 1

# Create readmission encounters for first 3 fibroid patients (within 14 days)
print("\n--- Readmission Encounters (within 14 days) ---")
readmit_patients = [
    ("4117", "fib-enc-1", "2025-02-21", "2025-02-25"),  # readmit 6 days after discharge (02-15)
    ("4679", "fib-enc-2", "2025-03-21", "2025-03-24"),  # readmit 7 days after discharge (03-14+5=03-19 discharge → re 03-21)  
    ("4836", "fib-enc-3", "2025-04-25", "2025-04-28"),  # readmit within 14 days
]

for i, (pid, orig_enc, readmit_start, readmit_end) in enumerate(readmit_patients):
    re_enc_id = f"fib-readmit-{i+1}"
    total += 1
    body = {
        "resourceType": "Encounter",
        "id": re_enc_id,
        "status": "finished",
        "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient encounter"},
        "subject": {"reference": f"Patient/{pid}"},
        "period": {
            "start": f"{readmit_start}T08:00:00+08:00",
            "end": f"{readmit_end}T10:00:00+08:00"
        }
    }
    if put("Encounter", re_enc_id, body):
        success += 1
    
    # Add N70-N85 related condition for the readmission
    re_cond_id = f"fib-readmit-cond-{i+1}"
    related_codes = ["N73.0", "N80.0", "N83.2"]
    total += 1
    body = {
        "resourceType": "Condition",
        "id": re_cond_id,
        "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
        "code": {
            "coding": [{"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": related_codes[i], "display": "術後婦科相關診斷"}],
            "text": "子宮肌瘤術後相關併發症"
        },
        "subject": {"reference": f"Patient/{pid}"},
        "encounter": {"reference": f"Encounter/{re_enc_id}"}
    }
    if put("Condition", re_cond_id, body):
        success += 1

print(f"\n{'='*50}")
print(f"Total: {total}, Success: {success}, Failed: {total - success}")
print(f"\nExpected results:")
print(f"  Indicator 12: denominator=6, numerator=4, rate=66.67%")
print(f"  Indicator 13: 8 patients, 15 ESWL procedures, avg=1.88/patient")
print(f"  Indicator 14: denominator=9, numerator=3, rate=33.33%")
