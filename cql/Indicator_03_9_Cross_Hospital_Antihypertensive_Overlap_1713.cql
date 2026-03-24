library Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-降血壓(口服)
// 指標代碼: 1713
// 製作日期: 2026-01-09
// 製表日期: 114/05/13
// 製表單位: 衛生福利部 中央健康保險署
// ============================================
//
// 【重點差異】
// 與指標1710(同院門診)不同，本指標計算「跨醫院」的用藥重疊
// 即：同一病患在不同醫院就診時的降血壓藥物重疊情況
// 【重點差異】
// 與指標1710(同院門診)不同，本指標計算「跨醫院」的用藥重疊
// 即：同一病患在不同醫院就診時的降血壓藥物重疊情況
//
// 【資料範圍】
// (1)醫院總額之門診處方降血壓藥物(口服)案件
// (2)排除代辦案件
//
// 【公式說明】(依健保指標代碼 1713)
// 跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服) = 
//     分子: 全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
//     分母: 各案件之「給藥日數」總和
// 
// (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
// (2)降血壓藥物(口服): ATC前3碼為C07(排除C07AA05)或ATC前5碼為C02CA、C02DB、C02DC、C02DD、C03AA、C03BA、C03CA、C03DA、C08CA(排除C08CA06)、C08DA、C08DB、C09AA、C09CA，且醫令代碼第8碼為1
// 
// 排除條件:
//   1.排除特定ATC代碼: C07AA05、C08CA06
//   2.排除代辦案件
//   3.僅包含口服劑型(醫令代碼第8碼為1)
// ============================================

// Code Systems
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

// Value Sets
valueset "Antihypertensive ATC Codes": 'http://nhi.gov.tw/fhir/ValueSet/antihypertensive-atc-codes'

// Codes - Encounter Types
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'

// Codes - Medication Request Status
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// Codes - Encounter Status
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// Codes - ATC Codes (降血壓藥物 - 14類)
// C02: Antihypertensives
code "C02CA": 'C02CA' from "ATC" display 'Alpha-adrenoreceptor antagonists - α受體阻斷劑'
code "C02DB": 'C02DB' from "ATC" display 'Hydrazinophthalazine derivatives - 肼屈嗪類'
code "C02DC": 'C02DC' from "ATC" display 'Pyrimidine derivatives - 嘧啶類'
code "C02DD": 'C02DD' from "ATC" display 'Nitroferricyanide derivatives - 硝普鹽類'

// C03: Diuretics
code "C03AA": 'C03AA' from "ATC" display 'Thiazides, plain - 噻嗪類利尿劑'
code "C03BA": 'C03BA' from "ATC" display 'Sulfonamides, plain - 磺胺類利尿劑'
code "C03CA": 'C03CA' from "ATC" display 'Sulfonamides, plain - 磺胺類'
code "C03DA": 'C03DA' from "ATC" display 'Aldosterone antagonists - 醛固酮拮抗劑'

// C07: Beta blocking agents (使用前3碼)
code "C07": 'C07' from "ATC" display 'Beta blocking agents - β阻斷劑'

// C08: Calcium channel blockers
code "C08CA": 'C08CA' from "ATC" display 'Dihydropyridine derivatives - 二氫吡啶類'
code "C08DA": 'C08DA' from "ATC" display 'Phenylalkylamine derivatives - 苯烷基胺類'
code "C08DB": 'C08DB' from "ATC" display 'Benzothiazepine derivatives - 苯並硫氮䓬類'

// C09: Agents acting on the renin-angiotensin system
code "C09AA": 'C09AA' from "ATC" display 'ACE inhibitors, plain - 血管張力素轉化酶抑制劑'
code "C09CA": 'C09CA' from "ATC" display 'Angiotensin II receptor blockers (ARBs), plain - 血管張力素II受體阻斷劑'

// Excluded ATC Codes
code "C07AA05": 'C07AA05' from "ATC" display 'Propranolol - 應排除'
code "C08CA06": 'C08CA06' from "ATC" display 'Nimodipine - 應排除'

// Codes - Dosage Form
code "Oral": '385268001' from "SNOMEDCT" display 'Oral dose form - 口服劑型'

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

define function GetATCCodePrefix5(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where ToString(C.system) = 'http://www.whocc.no/atc'
        return Substring(ToString(C.code), 0, 5)
    )

define function GetATCCode(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where ToString(C.system) = 'http://www.whocc.no/atc'
        return ToString(C.code)
    )

define function IsAntihypertensiveATC(medication Medication):
  let atc3: GetATCCodePrefix3(medication),
      atc5: GetATCCodePrefix5(medication),
      atcFull: GetATCCode(medication)
  in
    (atc3 = 'C07' and atcFull != 'C07AA05')
    or atc5 in { 'C02CA', 'C02DB', 'C02DC', 'C02DD', 'C03AA', 'C03BA', 'C03CA', 'C03DA', 'C08DA', 'C08DB', 'C09AA', 'C09CA' }
    or (atc5 = 'C08CA' and atcFull != 'C08CA06')

define function IsOralDosageForm(medication Medication):
  if medication is null or medication.form is null then false
  else
    exists (
      medication.form.coding C
        where ToString(C.system) = 'http://snomed.info/sct'
          and ToString(C.code) = '385268001'
    )
    or exists (
      medication.extension E
        where ToString(E.url) = 'http://nhi.gov.tw/fhir/StructureDefinition/order-code-8th-digit'
          and E.value = '1'
    )

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
      atc5: GetATCCodePrefix5(medication)
  in
    case atc5
      when 'C02CA' then 'Alpha-adrenoreceptor antagonists - α受體阻斷劑'
      when 'C02DB' then 'Hydrazinophthalazine derivatives - 肼屈嗪類'
      when 'C02DC' then 'Pyrimidine derivatives - 嘧啶類'
      when 'C02DD' then 'Nitroferricyanide derivatives - 硝普鹽類'
      when 'C03AA' then 'Thiazides, plain - 噻嗪類利尿劑'
      when 'C03BA' then 'Sulfonamides, plain - 磺胺類利尿劑'
      when 'C03CA' then 'Sulfonamides, plain - 磺胺類'
      when 'C03DA' then 'Aldosterone antagonists - 醛固酮拮抗劑'
      when 'C08CA' then 'Dihydropyridine derivatives - 二氫吡啶類'
      when 'C08DA' then 'Phenylalkylamine derivatives - 苯烷基胺類'
      when 'C08DB' then 'Benzothiazepine derivatives - 苯並硫氮䓬類'
      when 'C09AA' then 'ACE inhibitors, plain - 血管張力素轉化酶抑制劑'
      when 'C09CA' then 'Angiotensin II receptor blockers (ARBs), plain - 血管張力素II受體阻斷劑'
      else if atc3 = 'C07' then 'Beta blocking agents - β阻斷劑'
           else 'Unknown'
    end

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

// 降血壓藥物(口服)請求
define "Antihypertensive Medication Requests":
  "All Medication Requests" MR
    let medication: singleton from [Medication: id in GetId(MR.medication)]
    where IsAntihypertensiveATC(medication)
      and IsOralDosageForm(medication)
      and exists(MR.dosageInstruction)
      and GetDrugDays(MR) > 0

// 門診降血壓藥物(口服)處方 (關聯到門診就診)
define "Outpatient Antihypertensive Prescriptions":
  "Antihypertensive Medication Requests" MR
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
      quarter: GetQuarter(MR.authoredOn)
    }

// 【關鍵】處方配對 (跨醫院、同病患、不同處方、有重疊)
define "Cross Hospital Prescription Pairs with Overlap":
  "Outpatient Antihypertensive Prescriptions" P1
    with "Outpatient Antihypertensive Prescriptions" P2
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
      atcClass1: GetATCCodePrefix5(P1.medication),
      atcClass2: GetATCCodePrefix5(P2.medication),
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
  Sum("Outpatient Antihypertensive Prescriptions" P return P.drugDays)

// 總重疊日數 (分子)
define "Total Overlap Days":
  Sum("Cross Hospital Prescription Pairs with Overlap" PP return PP.overlapDays)

// 重疊率
define "Overlap Rate":
  if "Total Drug Days" is null or "Total Drug Days" = 0 then null
  else ("Total Overlap Days" / "Total Drug Days") * 100

// 各季度統計
define "Statistics by Quarter":
  flatten (
    { '2024Q1', '2024Q2', '2024Q3', '2024Q4', '2025Q1', '2025Q2', '2025Q3', '2025Q4', '2026Q1' } Q
      return {
        quarter: Q,
        totalDrugDays: Sum(
          "Outpatient Antihypertensive Prescriptions" P
            where P.quarter = Q
            return P.drugDays
        ),
        totalOverlapDays: Sum(
          "Cross Hospital Prescription Pairs with Overlap" PP
            where PP.quarter = Q
            return PP.overlapDays
        ),
        overlapRate: 
          let denominator: Sum(
            "Outpatient Antihypertensive Prescriptions" P
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
    indicatorCode: '1713',
    indicatorName: '跨醫院門診同藥理用藥日數重疊率-降血壓藥物(口服)',
    indicatorNameEn: 'Cross-Hospital Outpatient Antihypertensive Drug Overlap Rate (Oral)',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    totalDrugDays: "Total Drug Days",
    totalOverlapDays: "Total Overlap Days",
    overlapRate: "Overlap Rate",
    quarterlyStatistics: "Statistics by Quarter",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/05/13',
    version: '1.0.0',
    keyFeature: '跨醫院用藥重疊分析 (P1.organizationId != P2.organizationId)'
  }
