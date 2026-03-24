library Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-降血糖(口服及注射)
// 指標代碼: 1715
// 製作日期：2026-01-09
// 製表日期: 114/05/13
// 製表單位: 衛生福利部 中央健康保險署
// 
// 【重點差異】
// 1. 與指標5(同院門診)不同，本指標計算「跨醫院」的用藥重疊
// 2. 與指標1714(降血脂-口服)不同，本指標「不分口服及注射」
// 即：同一病患在不同醫院就診時的降血糖藥物重疊情況（包含所有劑型）
//
// 【資料範圍】
// (1)醫院總額之門診處方降血糖藥物(不分口服及注射)案件
// (2)排除代辦案件
//
// 【公式說明】(依健保指標代碼 1715)
// 跨醫院門診同藥理用藥日數重疊率-降血糖藥物 = 
//     分子: 全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數(允許遞延早拿藥)
//     分母: 各案件之「給藥日數」總和
// 
// (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
// (2)降血糖藥物: ATC前3碼為A10，不分口服及注射
// 
// 排除條件:
//   1.排除代辦案件
//   2.包含口服及注射劑型（不限制劑型）
// ============================================

// Code Systems
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

// Value Sets
valueset "Antidiabetic ATC Codes": 'http://nhi.gov.tw/fhir/ValueSet/antidiabetic-atc-codes'

// Codes - Encounter Types
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'

// Codes - Medication Request Status
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// Codes - Encounter Status
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// Codes - ATC Codes (降血糖藥物 - A10系列)
// A10A: Insulins and analogues (胰島素及其類似物)
code "A10A": 'A10A' from "ATC" display 'Insulins and analogues - 胰島素及其類似物'
code "A10AA": 'A10AA' from "ATC" display 'Insulins, fast-acting - 速效胰島素'
code "A10AB": 'A10AB' from "ATC" display 'Insulins, intermediate-acting - 中效胰島素'
code "A10AC": 'A10AC' from "ATC" display 'Insulins, intermediate or long-acting combined with fast-acting - 混合型胰島素'
code "A10AD": 'A10AD' from "ATC" display 'Insulins, long-acting - 長效胰島素'
code "A10AE": 'A10AE' from "ATC" display 'Insulins for inhalation - 吸入型胰島素'

// A10B: Blood glucose lowering drugs, excl. insulins (降血糖藥物，不含胰島素)
code "A10B": 'A10B' from "ATC" display 'Blood glucose lowering drugs, excl. insulins - 降血糖藥物(不含胰島素)'
code "A10BA": 'A10BA' from "ATC" display 'Biguanides - 雙胍類'
code "A10BB": 'A10BB' from "ATC" display 'Sulfonylureas - 磺醯尿素類'
code "A10BC": 'A10BC' from "ATC" display 'Sulfonamides (heterocyclic) - 磺胺類'
code "A10BD": 'A10BD' from "ATC" display 'Combinations of oral blood glucose lowering drugs - 口服降血糖藥物複方'
code "A10BE": 'A10BE' from "ATC" display 'Combinations of oral drugs and insulin - 口服藥物與胰島素複方'
code "A10BF": 'A10BF' from "ATC" display 'Alpha glucosidase inhibitors - α-葡萄糖苷酶抑制劑'
code "A10BG": 'A10BG' from "ATC" display 'Thiazolidinediones - 噻唑烷二酮類(TZD)'
code "A10BH": 'A10BH' from "ATC" display 'Dipeptidyl peptidase 4 (DPP-4) inhibitors - DPP-4抑制劑'
code "A10BJ": 'A10BJ' from "ATC" display 'Glucagon-like peptide-1 (GLP-1) analogues - GLP-1類似物'
code "A10BK": 'A10BK' from "ATC" display 'Sodium-glucose co-transporter 2 (SGLT2) inhibitors - SGLT2抑制劑'
code "A10BX": 'A10BX' from "ATC" display 'Other blood glucose lowering drugs - 其他降血糖藥物'

// Codes - Dosage Forms (不限制劑型)
code "Oral": '385268001' from "SNOMEDCT" display 'Oral dose form - 口服劑型'
code "Injection": '385219001' from "SNOMEDCT" display 'Injection - 注射劑型'

// ============================================
// 時間區間定義 (Measurement Periods)
// ============================================

// 2024 Quarters
define "2024Q1 Start": @2024-01-01
define "2024Q1 End": @2024-03-31

define "2024Q2 Start": @2024-04-01
define "2024Q2 End": @2024-06-30

define "2024Q3 Start": @2024-07-01
define "2024Q3 End": @2024-09-30

define "2024Q4 Start": @2024-10-01
define "2024Q4 End": @2024-12-31

// 2025 Quarters
define "2025Q1 Start": @2025-01-01
define "2025Q1 End": @2025-03-31

define "2025Q2 Start": @2025-04-01
define "2025Q2 End": @2025-06-30

define "2025Q3 Start": @2025-07-01
define "2025Q3 End": @2025-09-30

define "2025Q4 Start": @2025-10-01
define "2025Q4 End": @2025-12-31

// 2026 Quarters
define "2026Q1 Start": @2026-01-01
define "2026Q1 End": @2026-03-31

// Overall Measurement Period
define "Measurement Period Start": @2024-01-01
define "Measurement Period End": @2099-12-31
define "Measurement Period": 
  Interval["Measurement Period Start", "Measurement Period End"]

// ============================================
// Helper Functions
// ============================================

define function GetId(reference Reference):
  Last(Split(reference.reference, '/'))

define function GetATCCodePrefix3(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where ToString(C.system) = 'http://www.whocc.no/atc'
        return Substring(ToString(C.code), 0, 3)
    )

define function GetATCCodePrefix4(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where ToString(C.system) = 'http://www.whocc.no/atc'
        return Substring(ToString(C.code), 0, 4)
    )

define function GetATCCode(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where ToString(C.system) = 'http://www.whocc.no/atc'
        return ToString(C.code)
    )

define function IsAntidiabeticATC(medication Medication):
  let atc3: GetATCCodePrefix3(medication)
  in
    atc3 = 'A10'

define function GetDrugDays(medicationRequest MedicationRequest):
  Coalesce(
    medicationRequest.dispenseRequest.expectedSupplyDuration.value,
    First(
      medicationRequest.dosageInstruction DI
        return DI.timing.repeat.boundsDuration.value
    ),
    30
  )

define function GetDrugStartDate(medicationRequest MedicationRequest):
  Coalesce(
    start of medicationRequest.dispenseRequest.validityPeriod,
    medicationRequest.authoredOn
  )

define function GetDrugEndDate(medicationRequest MedicationRequest):
  GetDrugStartDate(medicationRequest) + GetDrugDays(medicationRequest) days - 1 day

define function CalculateOverlapDays(start1 Date, end1 Date, start2 Date, end2 Date):
  if start1 is null or end1 is null or start2 is null or end2 is null then 0
  else
    if start1 > end2 or start2 > end1 then 0
    else
      days between Maximum({ start1, start2 }) and Minimum({ end1, end2 }) + 1

define function HasOverlap(start1 Date, end1 Date, start2 Date, end2 Date):
  start1 <= end2 and start2 <= end1

define function GetQuarter(date DateTime):
  case 
    when date during Interval["2024Q1 Start", "2024Q1 End"] then '2024Q1'
    when date during Interval["2024Q2 Start", "2024Q2 End"] then '2024Q2'
    when date during Interval["2024Q3 Start", "2024Q3 End"] then '2024Q3'
    when date during Interval["2024Q4 Start", "2024Q4 End"] then '2024Q4'
    when date during Interval["2025Q1 Start", "2025Q1 End"] then '2025Q1'
    when date during Interval["2025Q2 Start", "2025Q2 End"] then '2025Q2'
    when date during Interval["2025Q3 Start", "2025Q3 End"] then '2025Q3'
    when date during Interval["2025Q4 Start", "2025Q4 End"] then '2025Q4'
    when date during Interval["2026Q1 Start", "2026Q1 End"] then '2026Q1'
    else null
  end

define function GetATCClassName(medication Medication):
  let atc3: GetATCCodePrefix3(medication),
      atc4: GetATCCodePrefix4(medication)
  in
    case 
      when atc3 = 'A10' and atc4 in { 'A10A', 'A10AA', 'A10AB', 'A10AC', 'A10AD', 'A10AE' } 
        then 'Insulins and analogues - 胰島素及其類似物'
      when atc4 = 'A10BA' then 'Biguanides - 雙胍類'
      when atc4 = 'A10BB' then 'Sulfonylureas - 磺醯尿素類'
      when atc4 = 'A10BC' then 'Sulfonamides - 磺胺類'
      when atc4 = 'A10BD' then 'Combinations of oral drugs - 口服複方'
      when atc4 = 'A10BE' then 'Combinations with insulin - 含胰島素複方'
      when atc4 = 'A10BF' then 'Alpha glucosidase inhibitors - α-葡萄糖苷酶抑制劑'
      when atc4 = 'A10BG' then 'Thiazolidinediones - TZD'
      when atc4 = 'A10BH' then 'DPP-4 inhibitors - DPP-4抑制劑'
      when atc4 = 'A10BJ' then 'GLP-1 analogues - GLP-1類似物'
      when atc4 = 'A10BK' then 'SGLT2 inhibitors - SGLT2抑制劑'
      when atc4 = 'A10BX' then 'Other antidiabetics - 其他降血糖藥'
      else 'Unknown'
    end

define function GetDosageFormType(medication Medication):
  if medication is null or medication.form is null then 'Unknown'
  else
    if exists (
      medication.form.coding C
        where ToString(C.system) = 'http://snomed.info/sct'
          and ToString(C.code) = '385268001'
    ) or exists (
      medication.extension E
        where ToString(E.url) = 'http://nhi.gov.tw/fhir/StructureDefinition/order-code-8th-digit'
          and E.value = '1'
    ) then 'Oral'
    else if exists (
      medication.form.coding C
        where ToString(C.system) = 'http://snomed.info/sct'
          and ToString(C.code) = '385219001'
    ) or exists (
      medication.extension E
        where ToString(E.url) = 'http://nhi.gov.tw/fhir/StructureDefinition/order-code-8th-digit'
          and E.value = '2'
    ) then 'Injection'
    else 'Other'

// ============================================
// Main Queries
// ============================================

// 門診就診記錄 (排除代辦案件)
define "Outpatient Encounters":
  [Encounter: class in "Ambulatory"] E
    where ToString(E.status) = 'finished'
      and start of E.period during "Measurement Period"
      and not exists (
        E.extension EX
          where ToString(EX.url) = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
            and EX.value = true
      )

// 所有用藥請求
define "All Medication Requests":
  [MedicationRequest] MR
    where ToString(MR.status) in { 'active', 'completed' }
      and ToString(MR.intent) = 'order'
      and MR.authoredOn during "Measurement Period"

// 降血糖藥物(不分口服及注射)請求
define "Antidiabetic Medication Requests":
  "All Medication Requests" MR
    let medication: singleton from [Medication: id in GetId(MR.medication)]
    where IsAntidiabeticATC(medication)
      and exists(MR.dosageInstruction)
      and GetDrugDays(MR) > 0

// 門診降血糖藥物(不分口服及注射)處方 (關聯到門診就診)
define "Outpatient Antidiabetic Prescriptions":
  "Antidiabetic Medication Requests" MR
    with "Outpatient Encounters" E
      such that GetId(MR.encounter) = E.id
    return {
      medicationRequestId: MR.id,
      encounterId: E.id,
      patientId: GetId(MR.subject),
      organizationId: GetId(E.serviceProvider),
      authoredOn: MR.authoredOn,
      medication: singleton from [Medication: id in GetId(MR.medication)],
      drugDays: GetDrugDays(MR),
      startDate: GetDrugStartDate(MR),
      endDate: GetDrugEndDate(MR),
      quarter: GetQuarter(MR.authoredOn),
      dosageFormType: GetDosageFormType(singleton from [Medication: id in GetId(MR.medication)])
    }

// 【關鍵】處方配對 (跨醫院、同病患、不同處方、有重疊)
define "Cross Hospital Prescription Pairs with Overlap":
  "Outpatient Antidiabetic Prescriptions" P1
    with "Outpatient Antidiabetic Prescriptions" P2
      such that P1.organizationId != P2.organizationId  // 【關鍵】不同醫院
        and P1.patientId = P2.patientId
        and P1.medicationRequestId < P2.medicationRequestId
        and P1.quarter = P2.quarter
        and HasOverlap(P1.startDate, P1.endDate, P2.startDate, P2.endDate)
    return {
      quarter: P1.quarter,
      patientId: P1.patientId,
      organization1: P1.organizationId,
      organization2: P2.organizationId,
      prescription1: P1.medicationRequestId,
      prescription2: P2.medicationRequestId,
      atcClass1: GetATCCodePrefix4(P1.medication),
      atcClass2: GetATCCodePrefix4(P2.medication),
      dosageForm1: P1.dosageFormType,
      dosageForm2: P2.dosageFormType,
      startDate1: P1.startDate,
      endDate1: P1.endDate,
      startDate2: P2.startDate,
      endDate2: P2.endDate,
      drugDays1: P1.drugDays,
      drugDays2: P2.drugDays,
      overlapDays: CalculateOverlapDays(P1.startDate, P1.endDate, P2.startDate, P2.endDate)
    }

// ============================================
// Statistics and Results
// ============================================

// 總給藥日數 (分母)
define "Total Drug Days":
  Sum("Outpatient Antidiabetic Prescriptions" P return P.drugDays)

// 總重疊日數 (分子)
define "Total Overlap Days":
  Sum("Cross Hospital Prescription Pairs with Overlap" PP return PP.overlapDays)

// 重疊率
define "Overlap Rate":
  if "Total Drug Days" is null or "Total Drug Days" = 0 then null
  else ("Total Overlap Days" / "Total Drug Days") * 100

// 口服給藥日數
define "Oral Drug Days":
  Sum(
    "Outpatient Antidiabetic Prescriptions" P
      where P.dosageFormType = 'Oral'
      return P.drugDays
  )

// 注射給藥日數
define "Injection Drug Days":
  Sum(
    "Outpatient Antidiabetic Prescriptions" P
      where P.dosageFormType = 'Injection'
      return P.drugDays
  )

// 各季度統計
define "Statistics by Quarter":
  flatten (
    { '2024Q1', '2024Q2', '2024Q3', '2024Q4', '2025Q1', '2025Q2', '2025Q3', '2025Q4', '2026Q1' } Q
      return {
        quarter: Q,
        totalDrugDays: Sum(
          "Outpatient Antidiabetic Prescriptions" P
            where P.quarter = Q
            return P.drugDays
        ),
        oralDrugDays: Sum(
          "Outpatient Antidiabetic Prescriptions" P
            where P.quarter = Q and P.dosageFormType = 'Oral'
            return P.drugDays
        ),
        injectionDrugDays: Sum(
          "Outpatient Antidiabetic Prescriptions" P
            where P.quarter = Q and P.dosageFormType = 'Injection'
            return P.drugDays
        ),
        totalOverlapDays: Sum(
          "Cross Hospital Prescription Pairs with Overlap" PP
            where PP.quarter = Q
            return PP.overlapDays
        ),
        overlapRate: 
          let denominator: Sum(
            "Outpatient Antidiabetic Prescriptions" P
              where P.quarter = Q
              return P.drugDays
          ),
          numerator: Sum(
            "Cross Hospital Prescription Pairs with Overlap" PP
              where PP.quarter = Q
              return PP.overlapDays
          )
          in if denominator is null or denominator = 0 then null
             else (numerator / denominator) * 100
      }
  )

// ============================================
// Indicator Result (指標結果)
// ============================================

define "Indicator Result":
  {
    indicatorCode: '1715',
    indicatorName: '跨醫院門診同藥理用藥日數重疊率-降血糖藥物(口服及注射)',
    indicatorNameEn: 'Cross-Hospital Outpatient Antidiabetic Drug Overlap Rate (All Forms)',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    totalDrugDays: "Total Drug Days",
    oralDrugDays: "Oral Drug Days",
    injectionDrugDays: "Injection Drug Days",
    totalOverlapDays: "Total Overlap Days",
    overlapRate: "Overlap Rate",
    quarterlyStatistics: "Statistics by Quarter",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/05/13',
    version: '1.0.0',
    keyFeature: '跨醫院用藥重疊分析 (P1.organizationId != P2.organizationId, 不分口服及注射)'
  }
