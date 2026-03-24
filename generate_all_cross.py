import json

def gen_cross(indicator, patient_prefix, med1_code, med1_name, med2_code, med2_name, total, overlap):
    bundle = {"resourceType": "Bundle", "type": "transaction", "entry": []}
    
    # 兩家醫院
    bundle["entry"].extend([
        {"fullUrl": "urn:uuid:org-hospital-a", "resource": {"resourceType": "Organization", "id": "org-hospital-a", "identifier": [{"system": "http://www.mohw.gov.tw/hospital", "value": "HOSP-A-001"}], "name": "甲醫院"}, "request": {"method": "PUT", "url": "Organization/org-hospital-a"}},
        {"fullUrl": "urn:uuid:org-hospital-b", "resource": {"resourceType": "Organization", "id": "org-hospital-b", "identifier": [{"system": "http://www.mohw.gov.tw/hospital", "value": "HOSP-B-002"}], "name": "乙醫院"}, "request": {"method": "PUT", "url": "Organization/org-hospital-b"}}
    ])
    
    for i in range(1, total + 1):
        has_overlap = (i <= overlap)
        pid = f"{patient_prefix}-{i:03d}"
        
        # Patient
        bundle["entry"].append({"fullUrl": f"urn:uuid:{pid}", "resource": {"resourceType": "Patient", "id": pid, "identifier": [{"system": "http://www.mohw.gov.tw/patient", "value": pid}], "name": [{"family": "測試", "given": [f"{indicator}-{i}"]}], "gender": "male", "birthDate": "1960-01-01"}, "request": {"method": "PUT", "url": f"Patient/{pid}"}})
        
        # Encounter 1 - Hospital A
        bundle["entry"].append({"fullUrl": f"urn:uuid:enc-{pid}-1", "resource": {"resourceType": "Encounter", "id": f"enc-{pid}-1", "status": "finished", "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"}, "subject": {"reference": f"Patient/{pid}"}, "serviceProvider": {"reference": "Organization/org-hospital-a"}, "period": {"start": "2026-01-05T09:00:00Z", "end": "2026-01-05T09:30:00Z"}}, "request": {"method": "PUT", "url": f"Encounter/enc-{pid}-1"}})
        
        # Med 1
        bundle["entry"].append({"fullUrl": f"urn:uuid:med-{pid}-1", "resource": {"resourceType": "MedicationRequest", "id": f"med-{pid}-1", "status": "completed", "intent": "order", "medicationCodeableConcept": {"coding": [{"system": "http://www.whocc.no/atc", "code": med1_code, "display": med1_name}]}, "subject": {"reference": f"Patient/{pid}"}, "encounter": {"reference": f"Encounter/enc-{pid}-1"}, "authoredOn": "2026-01-05T09:15:00Z", "dosageInstruction": [{"timing": {"repeat": {"boundsPeriod": {"start": "2026-01-05", "end": "2026-02-03"}}}}], "dispenseRequest": {"validityPeriod": {"start": "2026-01-05", "end": "2026-02-03"}, "quantity": {"value": 30, "unit": "tablets"}}}, "request": {"method": "PUT", "url": f"MedicationRequest/med-{pid}-1"}})
        
        # Encounter 2 - Hospital B (跨院)
        enc2_date = "2026-01-20" if has_overlap else "2026-02-10"
        med2_end = "2026-02-18" if has_overlap else "2026-03-11"
        
        bundle["entry"].append({"fullUrl": f"urn:uuid:enc-{pid}-2", "resource": {"resourceType": "Encounter", "id": f"enc-{pid}-2", "status": "finished", "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB", "display": "ambulatory"}, "subject": {"reference": f"Patient/{pid}"}, "serviceProvider": {"reference": "Organization/org-hospital-b"}, "period": {"start": f"{enc2_date}T14:00:00Z", "end": f"{enc2_date}T14:30:00Z"}}, "request": {"method": "PUT", "url": f"Encounter/enc-{pid}-2"}})
        
        # Med 2
        bundle["entry"].append({"fullUrl": f"urn:uuid:med-{pid}-2", "resource": {"resourceType": "MedicationRequest", "id": f"med-{pid}-2", "status": "completed", "intent": "order", "medicationCodeableConcept": {"coding": [{"system": "http://www.whocc.no/atc", "code": med2_code, "display": med2_name}]}, "subject": {"reference": f"Patient/{pid}"}, "encounter": {"reference": f"Encounter/enc-{pid}-2"}, "authoredOn": f"{enc2_date}T14:15:00Z", "dosageInstruction": [{"timing": {"repeat": {"boundsPeriod": {"start": enc2_date, "end": med2_end}}}}], "dispenseRequest": {"validityPeriod": {"start": enc2_date, "end": med2_end}, "quantity": {"value": 30, "unit": "tablets"}}}, "request": {"method": "PUT", "url": f"MedicationRequest/med-{pid}-2"}})
    
    return bundle

# 生成6個指標
indicators = [
    {"id": "03-11", "prefix": "cross-diab", "med1": ("A10BA02", "Metformin"), "med2": ("A10BB01", "Glibenclamide"), "total": 16, "overlap": 6},
    {"id": "03-12", "prefix": "cross-psych", "med1": ("N05AH04", "Quetiapine"), "med2": ("N05AH03", "Olanzapine"), "total": 11, "overlap": 4},
    {"id": "03-13", "prefix": "cross-antidep", "med1": ("N06AB03", "Fluoxetine"), "med2": ("N06AB04", "Sertraline"), "total": 13, "overlap": 7},
    {"id": "03-14", "prefix": "cross-sedat", "med1": ("N05CD02", "Nitrazepam"), "med2": ("N05CF01", "Zopiclone"), "total": 17, "overlap": 5},
    {"id": "03-15", "prefix": "cross-antithromb", "med1": ("B01AC06", "Aspirin"), "med2": ("B01AA03", "Warfarin"), "total": 14, "overlap": 9},
    {"id": "03-16", "prefix": "cross-prostate", "med1": ("G04CA02", "Tamsulosin"), "med2": ("G04CA03", "Alfuzosin"), "total": 12, "overlap": 5}
]

for ind in indicators:
    bundle = gen_cross(ind["id"], ind["prefix"], ind["med1"][0], ind["med1"][1], ind["med2"][0], ind["med2"][1], ind["total"], ind["overlap"])
    filename = f'test_data_{ind["id"].replace("-", "_")}_cross_hospital_2026Q1.json'
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, indent=2, ensure_ascii=False)
    pct = int(ind["overlap"] / ind["total"] * 100)
    print(f' {ind["id"]}: {ind["total"]}人，{ind["overlap"]}個重疊 ({pct}%)')
