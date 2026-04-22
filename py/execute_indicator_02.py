#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
执行 Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01
从 FHIR 服务器获取数据并计算门诊抗生素使用率
"""

import requests
import json
import urllib3
from datetime import datetime
from collections import defaultdict

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# FHIR 服务器
FHIR_SERVER = "https://thas.mohw.gov.tw/v/r4/fhir"

print("=" * 80)
print("Indicator 02: 门诊抗生素使用率 (Outpatient Antibiotic Usage Rate)")
print("=" * 80)
print()

# 测量期间
MEASUREMENT_START = "2024-01-01"
MEASUREMENT_END = "2099-12-31"

print(f"📅 测量期间: {MEASUREMENT_START} 至 {MEASUREMENT_END}")
print()

# =============================================================================
# 1. 获取所有门诊 Encounter (AMB - Ambulatory)
# =============================================================================
print("🔍 步骤 1: 获取所有门诊 Encounter...")
encounters_response = requests.get(
    f"{FHIR_SERVER}/Encounter",
    params={
        "class": "AMB",
        "status": "finished",
        "_count": "1000"
    },
    verify=False
)

all_encounters = []
if encounters_response.status_code == 200:
    bundle = encounters_response.json()
    if bundle.get("entry"):
        all_encounters = [entry["resource"] for entry in bundle["entry"]]
        print(f"   ✅ 找到 {len(all_encounters)} 个门诊 Encounter")
    else:
        print("   ⚠️  未找到门诊 Encounter")
else:
    print(f"   ❌ 获取失败: {encounters_response.status_code}")

# =============================================================================
# 2. 获取所有 MedicationRequest
# =============================================================================
print("\n🔍 步骤 2: 获取所有 MedicationRequest...")
med_requests_response = requests.get(
    f"{FHIR_SERVER}/MedicationRequest",
    params={
        "status": "completed",
        "_count": "1000"
    },
    verify=False
)

all_med_requests = []
if med_requests_response.status_code == 200:
    bundle = med_requests_response.json()
    if bundle.get("entry"):
        all_med_requests = [entry["resource"] for entry in bundle["entry"]]
        print(f"   ✅ 找到 {len(all_med_requests)} 个 MedicationRequest")
    else:
        print("   ⚠️  未找到 MedicationRequest")
else:
    print(f"   ❌ 获取失败: {med_requests_response.status_code}")

# =============================================================================
# 3. 检查哪些 MedicationRequest 有 dosageInstruction
# =============================================================================
print("\n🔍 步骤 3: 筛选有 dosageInstruction 的 MedicationRequest...")
valid_med_requests = []
for mr in all_med_requests:
    if mr.get("dosageInstruction"):
        valid_med_requests.append(mr)

print(f"   ✅ 有 dosageInstruction 的: {len(valid_med_requests)} 个")

# =============================================================================
# 4. 识别抗生素 (ATC code 以 J01 开头)
# =============================================================================
print("\n🔍 步骤 4: 识别抗生素 MedicationRequest (ATC code J01*)...")
antibiotic_med_requests = []

for mr in valid_med_requests:
    medication = mr.get("medicationCodeableConcept", {})
    codings = medication.get("coding", [])
    
    for coding in codings:
        system = coding.get("system", "")
        code = coding.get("code", "")
        
        if system == "http://www.whocc.no/atc" and code.startswith("J01"):
            antibiotic_med_requests.append(mr)
            break

print(f"   ✅ 抗生素 MedicationRequest: {len(antibiotic_med_requests)} 个")

# =============================================================================
# 5. 关联 Encounter 和 MedicationRequest
# =============================================================================
print("\n🔍 步骤 5: 关联 Encounter 和 MedicationRequest...")

# 门诊用药的 Encounter (有任何 MedicationRequest)
outpatient_drug_encounters = set()
encounter_to_meds = defaultdict(list)

for mr in valid_med_requests:
    encounter_ref = mr.get("encounter", {}).get("reference", "")
    if encounter_ref:
        # 提取 Encounter ID (可能是 "Encounter/123" 或 "Encounter/TW123-enc")
        enc_id = encounter_ref.replace("Encounter/", "")
        encounter_to_meds[enc_id].append(mr)

# 只统计存在于门诊 Encounter 中的
for enc in all_encounters:
    enc_id = enc.get("id")
    if enc_id in encounter_to_meds:
        outpatient_drug_encounters.add(enc_id)

print(f"   ✅ 门诊用药的 Encounter: {len(outpatient_drug_encounters)} 个")

# 门诊抗生素的 Encounter
outpatient_antibiotic_encounters = set()
encounter_to_antibiotics = defaultdict(list)

for mr in antibiotic_med_requests:
    encounter_ref = mr.get("encounter", {}).get("reference", "")
    if encounter_ref:
        enc_id = encounter_ref.replace("Encounter/", "")
        encounter_to_antibiotics[enc_id].append(mr)

for enc in all_encounters:
    enc_id = enc.get("id")
    if enc_id in encounter_to_antibiotics:
        outpatient_antibiotic_encounters.add(enc_id)

print(f"   ✅ 门诊抗生素的 Encounter: {len(outpatient_antibiotic_encounters)} 个")

# =============================================================================
# 6. 计算指标
# =============================================================================
print("\n" + "=" * 80)
print("📊 计算结果")
print("=" * 80)

denominator = len(outpatient_drug_encounters)
numerator = len(outpatient_antibiotic_encounters)

print(f"分母 (Denominator): {denominator} 个门诊用药就诊")
print(f"分子 (Numerator):   {numerator} 个门诊抗生素就诊")
print()

if denominator > 0:
    rate = (numerator / denominator) * 100
    print(f"🎯 门诊抗生素使用率 = {rate:.2f}%")
else:
    print("⚠️  分母为 0，无法计算")

# =============================================================================
# 7. 详细列表 (前 10 个)
# =============================================================================
print("\n" + "=" * 80)
print("📋 详细列表 (前 10 个门诊抗生素就诊)")
print("=" * 80)

count = 0
for enc in all_encounters:
    enc_id = enc.get("id")
    if enc_id in outpatient_antibiotic_encounters and count < 10:
        count += 1
        period = enc.get("period", {})
        start = period.get("start", "N/A")
        
        # 找到关联的抗生素
        antibiotics = []
        if enc_id in encounter_to_antibiotics:
            for mr in encounter_to_antibiotics[enc_id]:
                medication = mr.get("medicationCodeableConcept", {})
                codings = medication.get("coding", [])
                for coding in codings:
                    if coding.get("system") == "http://www.whocc.no/atc":
                        code = coding.get("code", "Unknown")
                        display = coding.get("display", code)
                        antibiotics.append(f"{code} ({display})")
        
        print(f"\n{count}. Encounter: {enc_id}")
        print(f"   时间: {start}")
        print(f"   抗生素: {', '.join(antibiotics)}")

print("\n" + "=" * 80)
print("✅ 执行完成")
print("=" * 80)
