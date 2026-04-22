#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Execute Antibiotic_Utilization ELM
Comprehensive antibiotic usage analysis from FHIR server
"""

import requests
import json
import urllib3
from datetime import datetime
from collections import defaultdict

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 80)
print("ESG Antibiotic Utilization Report")
print("=" * 80)
print()

# Measurement Period: 1900-01-01 to 2100-12-31 (all data)
MEASUREMENT_START = "1900-01-01"
MEASUREMENT_END = "2100-12-31"

print(f"Measurement Period: {MEASUREMENT_START} to {MEASUREMENT_END}")
print()

# =============================================================================
# 1. Get MedicationRequest (Antibiotic Orders)
# =============================================================================
print("Step 1: Fetching MedicationRequest (Antibiotic Orders)...")
med_requests_response = requests.get(
    f"{FHIR_SERVER}/MedicationRequest",
    params={"_count": "1000"},
    verify=False
)

all_med_requests = []
if med_requests_response.status_code == 200:
    bundle = med_requests_response.json()
    if bundle.get("entry"):
        all_med_requests = [entry["resource"] for entry in bundle["entry"]]
        print(f"   Found {len(all_med_requests)} MedicationRequest")
    else:
        print("   No MedicationRequest found")
else:
    print(f"   Failed: {med_requests_response.status_code}")

# Filter for antibiotic orders (ATC J01*)
antibiotic_orders = []
for mr in all_med_requests:
    medication = mr.get("medicationCodeableConcept", {})
    codings = medication.get("coding", [])
    
    for coding in codings:
        system = coding.get("system", "")
        code = coding.get("code", "")
        
        if system == "http://www.whocc.no/atc" and code.startswith("J01"):
            antibiotic_orders.append(mr)
            break

print(f"   --> Antibiotic Orders (ATC J01*): {len(antibiotic_orders)}")

# =============================================================================
# 2. Get MedicationAdministration (Actual antibiotic given)
# =============================================================================
print("\nStep 2: Fetching MedicationAdministration...")
med_admin_response = requests.get(
    f"{FHIR_SERVER}/MedicationAdministration",
    params={"_count": "1000"},
    verify=False
)

all_med_admin = []
if med_admin_response.status_code == 200:
    bundle = med_admin_response.json()
    if bundle.get("entry"):
        all_med_admin = [entry["resource"] for entry in bundle["entry"]]
        print(f"   Found {len(all_med_admin)} MedicationAdministration")
    else:
        print("   No MedicationAdministration found")
else:
    print(f"   Failed: {med_admin_response.status_code}")

# Filter for antibiotic administrations
antibiotic_admin = []
for ma in all_med_admin:
    medication = ma.get("medicationCodeableConcept", {})
    codings = medication.get("coding", [])
    
    for coding in codings:
        system = coding.get("system", "")
        code = coding.get("code", "")
        
        if system == "http://www.whocc.no/atc" and code.startswith("J01"):
            antibiotic_admin.append(ma)
            break

print(f"   --> Antibiotic Administrations: {len(antibiotic_admin)}")

# =============================================================================
# 3. Get MedicationDispense
# =============================================================================
print("\nStep 3: Fetching MedicationDispense...")
med_dispense_response = requests.get(
    f"{FHIR_SERVER}/MedicationDispense",
    params={"_count": "1000"},
    verify=False
)

all_med_dispense = []
if med_dispense_response.status_code == 200:
    bundle = med_dispense_response.json()
    if bundle.get("entry"):
        all_med_dispense = [entry["resource"] for entry in bundle["entry"]]
        print(f"   Found {len(all_med_dispense)} MedicationDispense")
    else:
        print("   No MedicationDispense found")
else:
    print(f"   Failed: {med_dispense_response.status_code}")

# =============================================================================
# 4. Get Encounters (Inpatient & Outpatient)
# =============================================================================
print("\nStep 4: Fetching Encounters...")
encounters_response = requests.get(
    f"{FHIR_SERVER}/Encounter",
    params={"_count": "1000"},
    verify=False
)

all_encounters = []
if encounters_response.status_code == 200:
    bundle = encounters_response.json()
    if bundle.get("entry"):
        all_encounters = [entry["resource"] for entry in bundle["entry"]]
        print(f"   Found {len(all_encounters)} Encounters")
    else:
        print("   No Encounters found")
else:
    print(f"   Failed: {encounters_response.status_code}")

# Classify encounters
inpatient_encounters = []
outpatient_encounters = []

for enc in all_encounters:
    enc_class = enc.get("class", {}).get("code", "")
    if enc_class in ["IMP", "ACUTE", "NONAC"]:
        inpatient_encounters.append(enc)
    elif enc_class in ["AMB", "EMER"]:
        outpatient_encounters.append(enc)

print(f"   --> Inpatient Encounters: {len(inpatient_encounters)}")
print(f"   --> Outpatient Encounters: {len(outpatient_encounters)}")

# =============================================================================
# 5. Calculate Key Metrics
# =============================================================================
print("\n" + "=" * 80)
print("KEY METRICS")
print("=" * 80)

# Total counts
total_antibiotic_orders = len(antibiotic_orders)
total_antibiotic_admin = len(antibiotic_admin)

print(f"\n1. Antibiotic Orders:")
print(f"   Total: {total_antibiotic_orders}")

print(f"\n2. Antibiotic Administrations:")
print(f"   Total: {total_antibiotic_admin}")

# Calculate DOT (Days of Therapy)
# DOT = distinct patient-date combinations
dot_set = set()
for ma in antibiotic_admin:
    patient_ref = ma.get("subject", {}).get("reference", "")
    effective = ma.get("effectiveDateTime", "")
    if patient_ref and effective:
        date_part = effective.split("T")[0]
        dot_set.add((patient_ref, date_part))

total_dot = len(dot_set)
print(f"\n3. Days of Therapy (DOT):")
print(f"   Total: {total_dot} patient-days")

# Calculate bed days (from inpatient encounters)
total_bed_days = 0
for enc in inpatient_encounters:
    period = enc.get("period", {})
    start = period.get("start")
    end = period.get("end")
    if start and end:
        try:
            start_dt = datetime.fromisoformat(start.replace("Z", "+00:00"))
            end_dt = datetime.fromisoformat(end.replace("Z", "+00:00"))
            days = max(1, (end_dt - start_dt).days)
            total_bed_days += days
        except:
            pass

print(f"\n4. Bed Days:")
print(f"   Total: {total_bed_days}")

# Calculate patient days (all encounters)
total_patient_days = 0
for enc in all_encounters:
    period = enc.get("period", {})
    start = period.get("start")
    end = period.get("end")
    if start and end:
        try:
            start_dt = datetime.fromisoformat(start.replace("Z", "+00:00"))
            end_dt = datetime.fromisoformat(end.replace("Z", "+00:00"))
            days = max(1, (end_dt - start_dt).days)
            total_patient_days += days
        except:
            pass

print(f"\n5. Patient Days:")
print(f"   Total: {total_patient_days}")

# Calculate rates
if total_patient_days > 0:
    dot_per_1000 = (total_dot / total_patient_days) * 1000
    print(f"\n6. DOT per 1000 Patient Days:")
    print(f"   {dot_per_1000:.2f}")
else:
    print(f"\n6. DOT per 1000 Patient Days: Cannot calculate (no patient days)")

# =============================================================================
# 7. Antibiotic Usage Details (Top 10)
# =============================================================================
print("\n" + "=" * 80)
print("TOP 10 ANTIBIOTIC ADMINISTRATIONS")
print("=" * 80)

antibiotic_counts = defaultdict(int)
antibiotic_names = {}

for ma in antibiotic_admin[:50]:  # Check first 50
    medication = ma.get("medicationCodeableConcept", {})
    codings = medication.get("coding", [])
    
    for coding in codings:
        if coding.get("system") == "http://www.whocc.no/atc":
            code = coding.get("code", "Unknown")
            display = coding.get("display", code)
            antibiotic_counts[code] += 1
            antibiotic_names[code] = display
            break

# Sort by count
top_antibiotics = sorted(antibiotic_counts.items(), key=lambda x: x[1], reverse=True)[:10]

if top_antibiotics:
    for i, (code, count) in enumerate(top_antibiotics, 1):
        name = antibiotic_names.get(code, "Unknown")
        print(f"{i:2}. {code:12} - {name:40} (n={count})")
else:
    print("   No antibiotic data available")

# =============================================================================
# 8. Data Completeness Check
# =============================================================================
print("\n" + "=" * 80)
print("DATA COMPLETENESS CHECK")
print("=" * 80)

has_med_request = len(all_med_requests) > 0
has_med_admin = len(all_med_admin) > 0
has_med_dispense = len(all_med_dispense) > 0
has_encounters = len(all_encounters) > 0
has_inpatient = len(inpatient_encounters) > 0

print(f"Has MedicationRequest: {'YES' if has_med_request else 'NO'} ({len(all_med_requests)})")
print(f"Has MedicationAdministration: {'YES' if has_med_admin else 'NO'} ({len(all_med_admin)})")
print(f"Has MedicationDispense: {'YES' if has_med_dispense else 'NO'} ({len(all_med_dispense)})")
print(f"Has Encounters: {'YES' if has_encounters else 'NO'} ({len(all_encounters)})")
print(f"Has Inpatient Data: {'YES' if has_inpatient else 'NO'} ({len(inpatient_encounters)})")

# =============================================================================
# 9. Summary Report
# =============================================================================
print("\n" + "=" * 80)
print("SUMMARY REPORT")
print("=" * 80)

if has_med_admin and has_encounters:
    print("\nStatus: PARTIAL DATA AVAILABLE")
    print(f"- Found {len(antibiotic_admin)} antibiotic administrations")
    print(f"- Found {len(all_encounters)} encounters")
    print(f"- Calculated {total_dot} days of therapy")
    
    if total_patient_days > 0:
        print(f"- DOT rate: {dot_per_1000:.2f} per 1000 patient days")
    
    print("\nLimitations:")
    print("- May lack complete patient linkage data")
    print("- DDD calculations require dosage information")
    print("- WHO AWaRe classification requires ValueSets")
else:
    print("\nStatus: INSUFFICIENT DATA")
    print("Need MedicationAdministration and Encounter data for full analysis")

print("\n" + "=" * 80)
print("EXECUTION COMPLETE")
print("=" * 80)
