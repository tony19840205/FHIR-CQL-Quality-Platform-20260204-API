#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
调查 Indicator_02 数据问题
"""

import requests
import json
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

print("🔍 调查数据问题...")
print()

# 获取一些 Encounter 样本
print("=" * 60)
print("门诊 Encounter 样本:")
print("=" * 60)
response = requests.get(
    f"{FHIR_SERVER}/Encounter",
    params={"class": "AMB", "status": "finished", "_count": "3"},
    verify=False
)

if response.status_code == 200:
    bundle = response.json()
    if bundle.get("entry"):
        for i, entry in enumerate(bundle["entry"][:3], 1):
            enc = entry["resource"]
            print(f"\n{i}. Encounter ID: {enc.get('id')}")
            print(f"   Class: {enc.get('class', {}).get('code')}")
            print(f"   Status: {enc.get('status')}")
            print(f"   Period: {enc.get('period')}")

# 获取一些 MedicationRequest 样本
print("\n" + "=" * 60)
print("MedicationRequest 样本:")
print("=" * 60)
response = requests.get(
    f"{FHIR_SERVER}/MedicationRequest",
    params={"status": "completed", "_count": "3"},
    verify=False
)

if response.status_code == 200:
    bundle = response.json()
    if bundle.get("entry"):
        for i, entry in enumerate(bundle["entry"][:3], 1):
            mr = entry["resource"]
            print(f"\n{i}. MedicationRequest ID: {mr.get('id')}")
            print(f"   Status: {mr.get('status')}")
            print(f"   Encounter: {mr.get('encounter')}")
            
            # 检查药物代码
            medication = mr.get("medicationCodeableConcept", {})
            codings = medication.get("coding", [])
            print(f"   Medication Codings:")
            for coding in codings:
                system = coding.get("system", "N/A")
                code = coding.get("code", "N/A")
                display = coding.get("display", "N/A")
                print(f"     - System: {system}")
                print(f"       Code: {code}")
                print(f"       Display: {display}")

# 查找抗生素样本
print("\n" + "=" * 60)
print("查找抗生素样本:")
print("=" * 60)
response = requests.get(
    f"{FHIR_SERVER}/MedicationRequest",
    params={"_count": "1000"},
    verify=False
)

if response.status_code == 200:
    bundle = response.json()
    if bundle.get("entry"):
        antibiotic_count = 0
        for entry in bundle["entry"]:
            mr = entry["resource"]
            medication = mr.get("medicationCodeableConcept", {})
            codings = medication.get("coding", [])
            
            for coding in codings:
                system = coding.get("system", "")
                code = coding.get("code", "")
                
                if system == "http://www.whocc.no/atc" and code.startswith("J01"):
                    antibiotic_count += 1
                    if antibiotic_count <= 3:
                        print(f"\n抗生素 #{antibiotic_count}:")
                        print(f"  MedicationRequest ID: {mr.get('id')}")
                        print(f"  ATC Code: {code}")
                        print(f"  Display: {coding.get('display')}")
                        print(f"  Encounter: {mr.get('encounter')}")
                    break
        
        print(f"\n总共找到 {antibiotic_count} 个抗生素")

print("\n" + "=" * 60)
print("完成调查")
print("=" * 60)
