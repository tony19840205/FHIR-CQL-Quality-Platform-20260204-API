library Indicator_03_8_Same_Hospital_Prostate_Overlap_3376 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 同醫院門診同藥理用藥日數重疊率-前列腺肥大(口服)
// 指標代碼: 3376
// 製作日期: 2026-01-09
// 製表日期: 114/05/13
// 製表單位: 衛生福利部 中央健康保險署
// ============================================
//
// 【資料範圍】
// (1)醫院總額之門診處方前列腺肥大藥物(口服)案件
// (2)排除代辦案件
//
// 【公式說明】(依健保指標代碼 3376)
// 同醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服) = 
//     分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
//     分母: 各案件之「給藥日數」總和
// 
// (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
// (2)前列腺肥大藥物(口服): ATC前5碼為G04CA、G04CB，且醫令代碼第8碼為1
// 
// 排除條件:
//   1.排除代辦案件
//   2.僅包含口服劑型(醫令代碼第8碼為1)
// ============================================

// Code Systems
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

// Value Sets
valueset "Prostate BPH ATC Codes": 'http://nhi.gov.tw/fhir/ValueSet/prostate-bph-atc-codes'

// Codes - Encounter Types
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'

// Codes - Medication Request Status
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// Codes - Encounter Status
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// Codes - ATC Codes (前列腺肥大藥物)
code "G04CA": 'G04CA' from "ATC" display 'Alpha-adrenoreceptor antagonists - α-腎上腺素受體阻斷劑'
code "G04CB": 'G04CB' from "ATC" display 'Testosterone-5-alpha reductase inhibitors - 5α-還原酶抑制劑'

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

define function GetATCCodePrefix(medication Medication):
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

define function IsProstateBPHATC(atcPrefix String):
  atcPrefix in { 'G04CA', 'G04CB' }

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

define function GetATCClassName(atcPrefix String):
  case atcPrefix
    when 'G04CA' then 'Alpha-adrenoreceptor antagonists - α-腎上腺素受體阻斷劑'
    when 'G04CB' then 'Testosterone-5-alpha reductase inhibitors - 5α-還原酶抑制劑'
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

// 前列腺肥大藥物(口服)請求
define "Prostate BPH Medication Requests":
  "All Medication Requests" MR
    let medication: singleton from [Medication: id in GetId(MR.medication)]
    where IsProstateBPHATC(GetATCCodePrefix(medication))
      and IsOralDosageForm(medication)
      and exists(MR.dosageInstruction)
      and GetDrugDays(MR) > 0

// 門診前列腺肥大藥物(口服)處方 (關聯到門診就診)
define "Outpatient Prostate BPH Prescriptions":
  "Prostate BPH Medication Requests" MR
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

// 處方配對 (同醫院、同病患、不同處方、有重疊)
define "Prescription Pairs with Overlap":
  "Outpatient Prostate BPH Prescriptions" P1
    with "Outpatient Prostate BPH Prescriptions" P2
      such that P1.organizationId = P2.organizationId
        and P1.patientId = P2.patientId
        and P1.medicationRequestId < P2.medicationRequestId
        and P1.quarter = P2.quarter
        and HasOverlap(P1.startDate, P1.endDate, P2.startDate, P2.endDate)
    return {
      quarter: P1.quarter,
      organizationId: P1.organizationId,
      patientId: P1.patientId,
      prescription1: P1.medicationRequestId,
      prescription2: P2.medicationRequestId,
      atcClass1: GetATCCodePrefix(P1.medication),
      atcClass2: GetATCCodePrefix(P2.medication),
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
  Sum("Outpatient Prostate BPH Prescriptions" P return P.drugDays)

// 總重疊日數 (分子)
define "Total Overlap Days":
  Sum("Prescription Pairs with Overlap" PP return PP.overlapDays)

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
          "Outpatient Prostate BPH Prescriptions" P
            where P.quarter = Q
            return P.drugDays
        ),
        totalOverlapDays: Sum(
          "Prescription Pairs with Overlap" PP
            where PP.quarter = Q
            return PP.overlapDays
        ),
        overlapRate: 
          let denominator: Sum(
            "Outpatient Prostate BPH Prescriptions" P
              where P.quarter = Q
              return P.drugDays
          ),
          numerator: Sum(
            "Prescription Pairs with Overlap" PP
              where PP.quarter = Q
              return PP.overlapDays
          )
          in if denominator is null or denominator = 0 then null
             else (numerator / denominator) * 100
      }
  )

// 各ATC類別統計
define "Statistics by ATC":
  flatten (
    { 'G04CA', 'G04CB' } A
      return {
        atcClass: A,
        atcClassName: GetATCClassName(A),
        totalPrescriptions: Count(
          "Outpatient Prostate BPH Prescriptions" P
            where GetATCCodePrefix(P.medication) = A
        ),
        totalDrugDays: Sum(
          "Outpatient Prostate BPH Prescriptions" P
            where GetATCCodePrefix(P.medication) = A
            return P.drugDays
        ),
        totalOverlapDays: Sum(
          "Prescription Pairs with Overlap" PP
            where PP.atcClass1 = A or PP.atcClass2 = A
            return PP.overlapDays
        )
      }
  )

// ============================================
// Indicator Result (指標結果)
// ============================================

define "Indicator Result":
  {
    indicatorCode: '3376',
    indicatorName: '同醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服)',
    indicatorNameEn: 'Same Hospital Outpatient Prostate BPH Drug Overlap Rate (Oral)',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    totalDrugDays: "Total Drug Days",
    totalOverlapDays: "Total Overlap Days",
    overlapRate: "Overlap Rate",
    quarterlyStatistics: "Statistics by Quarter",
    atcStatistics: "Statistics by ATC",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/05/13',
    version: '1.0.0'
  }
