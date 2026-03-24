library Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 同醫院門診同藥理用藥日數重疊率-抗血栓(口服)
// 指標代碼: 3375
// 製作日期: 2025-11-20
// 製表日期: 114/05/13
// 製表單位: 衛生福利部 中央健康保險署
// ============================================
//
// 【資料時間範圍】
// 查詢期間: 2024-01-01 ~ 2026-01-09 (今天)
// 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
//
// 【資料範圍】
// (1)醫院總額之門診處方抗血栓藥物(口服)案件
// (2)排除代辦案件
//
// 【公式說明】(依健保指標代碼 3375)
// 同醫院門診同藥理用藥日數重疊率-抗血栓藥物(口服) = 
//     分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
//     分母: 各案件之「給藥日數」總和
// 
// (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
// (2)抗血栓藥物(口服): ATC前5碼為B01AA、B01AC(排除B01AC07)、B01AE、B01AF，且醫令代碼第8碼為1
// 
// 排除條件:
//   1.排除特定ATC代碼: B01AC07
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
valueset "Antithrombotic ATC Codes": 'http://nhi.gov.tw/fhir/ValueSet/antithrombotic-atc-codes'

// Codes - Encounter Types
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'

// Codes - Medication Request Status
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// Codes - Encounter Status
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// Antithrombotic ATC Code Prefixes (B01A)
code "B01AA": 'B01AA' from "ATC" display 'Vitamin K antagonists - 維生素K拮抗劑'
code "B01AC": 'B01AC' from "ATC" display 'Platelet aggregation inhibitors excl. heparin - 抗血小板藥物(不含肝素)'
code "B01AE": 'B01AE' from "ATC" display 'Direct thrombin inhibitors - 直接凝血酶抑制劑'
code "B01AF": 'B01AF' from "ATC" display 'Direct factor Xa inhibitors - 直接第十因子抑制劑'

// Excluded ATC Code
code "B01AC07": 'B01AC07' from "ATC" display 'Dipyridamole - 應排除'

// Dosage Forms
code "Oral": '385268001' from "SNOMEDCT" display 'Oral dose form - 口服劑型'

// Contexts
context Patient

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

// Extract ID from FHIR Reference
define function "GetId"(reference FHIR.Reference):
  Last(Split(reference.reference, '/'))

// Get ATC Code Prefix (first 5 characters)
define function "GetATCCodePrefix"(medication FHIR.Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where C.system = 'http://www.whocc.no/atc'
        return Substring(C.code, 0, 5)
    )

// Get full ATC Code
define function "GetATCCode"(medication FHIR.Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where C.system = 'http://www.whocc.no/atc'
        return C.code
    )

// Check if ATC code is antithrombotic (B01A family)
define function "IsAntithromboticATC"(atcPrefix String):
  atcPrefix in {
    'B01AA', 'B01AC', 'B01AE', 'B01AF'
  }

// Check if medication has excluded ATC code
define function "IsExcludedATC"(medication FHIR.Medication):
  "GetATCCode"(medication) = 'B01AC07'

// Check if medication is oral dosage form (醫令代碼第8碼為1)
// This is a NHI-specific requirement that would be in extension data
define function "IsOralDosageForm"(medication FHIR.Medication):
  if medication is null or medication.form is null then false
  else
    exists (
      medication.form.coding C
        where C.system = 'http://snomed.info/sct'
          and C.code = '385268001'
    )
    or exists (
      medication.extension E
        where E.url = 'http://nhi.gov.tw/fhir/StructureDefinition/order-code-8th-digit'
          and E.value = '1'
    )

// Get drug supply days (給藥日數)
// Priority: expectedSupplyDuration > boundsDuration > default 30 days
define function "GetDrugDays"(medicationRequest FHIR.MedicationRequest):
  Coalesce(
    medicationRequest.dispenseRequest.expectedSupplyDuration.value,
    First(
      medicationRequest.dosageInstruction DI
        return DI.timing.repeat.boundsDuration.value
    ),
    30
  )

// Get drug start date (給藥開始日期)
define function "GetDrugStartDate"(medicationRequest FHIR.MedicationRequest):
  Coalesce(
    start of medicationRequest.dispenseRequest.validityPeriod,
    medicationRequest.authoredOn
  )

// Get drug end date (給藥結束日期)
define function "GetDrugEndDate"(medicationRequest FHIR.MedicationRequest):
  "GetDrugStartDate"(medicationRequest) + "GetDrugDays"(medicationRequest) days - 1 day

// Calculate overlap days between two date ranges
define function "CalculateOverlapDays"(start1 Date, end1 Date, start2 Date, end2 Date):
  if start1 > end2 or start2 > end1 then 0
  else
    days between Maximum({start1, start2}) and Minimum({end1, end2}) + 1

// Check if two date ranges overlap
define function "HasOverlap"(start1 Date, end1 Date, start2 Date, end2 Date):
  start1 <= end2 and start2 <= end1

// Determine quarter from date
define function "GetQuarter"(date DateTime):
  if date during Interval["2024Q1 Start", "2024Q1 End"] then '2024Q1'
  else if date during Interval["2024Q2 Start", "2024Q2 End"] then '2024Q2'
  else if date during Interval["2024Q3 Start", "2024Q3 End"] then '2024Q3'
  else if date during Interval["2024Q4 Start", "2024Q4 End"] then '2024Q4'
  else if date during Interval["2025Q1 Start", "2025Q1 End"] then '2025Q1'
  else if date during Interval["2025Q2 Start", "2025Q2 End"] then '2025Q2'
  else if date during Interval["2025Q3 Start", "2025Q3 End"] then '2025Q3'
  else if date during Interval["2025Q4 Start", "2025Q4 End"] then '2025Q4'
  else if date during Interval["2026Q1 Start", "2026Q1 End"] then '2026Q1'
  else null

// Get ATC class name in Chinese/English
define function "GetATCClassName"(atcPrefix String):
  case atcPrefix
    when 'B01AA' then 'B01AA - Vitamin K antagonists (維生素K拮抗劑)'
    when 'B01AC' then 'B01AC - Platelet aggregation inhibitors (抗血小板藥物)'
    when 'B01AE' then 'B01AE - Direct thrombin inhibitors (直接凝血酶抑制劑)'
    when 'B01AF' then 'B01AF - Direct factor Xa inhibitors (直接第十因子抑制劑)'
    else 'Other'
  end

// ============================================
// 門診就診記錄篩選 (Outpatient Encounters)
// ============================================

define "Outpatient Encounters":
  [Encounter: class in {"Ambulatory", "Outpatient"}] E
    where E.status = 'finished'
      and start of E.period during "Measurement Period"
      and not exists (
        E.extension EX
          where EX.url = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
            and EX.value = true
      )

// ============================================
// 抗血栓藥物處方篩選 (Antithrombotic Medication Requests)
// ============================================

define "All Medication Requests":
  [MedicationRequest] MR
    where MR.status in {'active', 'completed'}
      and MR.intent = 'order'
      and MR.authoredOn during "Measurement Period"

define "Antithrombotic Medication Requests":
  "All Medication Requests" MR
    let medication: singleton from ([Medication: id in "GetId"(MR.medication)])
    where "IsAntithromboticATC"("GetATCCodePrefix"(medication))
      and not "IsExcludedATC"(medication)
      and "IsOralDosageForm"(medication)
      and exists (MR.dosageInstruction)
      and "GetDrugDays"(MR) > 0

// ============================================
// 門診抗血栓藥物處方 (Outpatient Antithrombotic Prescriptions)
// ============================================

define "Outpatient Antithrombotic Prescriptions":
  from
    "Outpatient Encounters" E,
    "Antithrombotic Medication Requests" MR
  where "GetId"(MR.encounter) = E.id
  return {
    patientId: "GetId"(E.subject),
    encounterId: E.id,
    organizationId: "GetId"(E.serviceProvider),
    medicationRequestId: MR.id,
    medication: singleton from ([Medication: id in "GetId"(MR.medication)]),
    startDate: "GetDrugStartDate"(MR),
    endDate: "GetDrugEndDate"(MR),
    drugDays: "GetDrugDays"(MR),
    authoredOn: MR.authoredOn,
    quarter: "GetQuarter"(MR.authoredOn),
    atcPrefix: "GetATCCodePrefix"(singleton from ([Medication: id in "GetId"(MR.medication)]))
  }

// ============================================
// 同醫院同病人不同處方重疊分析 (Prescription Overlap Analysis)
// ============================================

define "Prescription Pairs with Overlap":
  from
    "Outpatient Antithrombotic Prescriptions" P1,
    "Outpatient Antithrombotic Prescriptions" P2
  where P1.patientId = P2.patientId
    and P1.organizationId = P2.organizationId
    and P1.medicationRequestId < P2.medicationRequestId
    and "HasOverlap"(P1.startDate, P1.endDate, P2.startDate, P2.endDate)
  return {
    patientId: P1.patientId,
    organizationId: P1.organizationId,
    quarter: P1.quarter,
    prescription1Id: P1.medicationRequestId,
    prescription2Id: P2.medicationRequestId,
    overlapDays: "CalculateOverlapDays"(P1.startDate, P1.endDate, P2.startDate, P2.endDate),
    prescription1Start: P1.startDate,
    prescription1End: P1.endDate,
    prescription2Start: P2.startDate,
    prescription2End: P2.endDate,
    drugDays1: P1.drugDays,
    drugDays2: P2.drugDays
  }

// ============================================
// 分子: 重疊給藥日數總和 (Numerator: Total Overlap Days)
// ============================================

define "Total Overlap Days":
  Sum(
    "Prescription Pairs with Overlap" P
      return P.overlapDays
  )

define "Overlap Days by Quarter":
  ("Prescription Pairs with Overlap") P
    return {
      quarter: P.quarter,
      overlapDays: P.overlapDays
    }

define "Overlap Days by Organization":
  ("Prescription Pairs with Overlap") P
    return {
      organizationId: P.organizationId,
      quarter: P.quarter,
      overlapDays: P.overlapDays
    }

// ============================================
// 分母: 總給藥日數 (Denominator: Total Drug Days)
// ============================================

define "Total Drug Days":
  Sum(
    "Outpatient Antithrombotic Prescriptions" P
      return P.drugDays
  )

define "Drug Days by Quarter":
  ("Outpatient Antithrombotic Prescriptions") P
    return {
      quarter: P.quarter,
      drugDays: P.drugDays
    }

define "Drug Days by Organization":
  ("Outpatient Antithrombotic Prescriptions") P
    return {
      organizationId: P.organizationId,
      quarter: P.quarter,
      drugDays: P.drugDays
    }

// ============================================
// 統計數據 (Statistics)
// ============================================

define "Total Prescriptions":
  Count("Outpatient Antithrombotic Prescriptions")

define "Total Patients":
  Count(
    distinct "Outpatient Antithrombotic Prescriptions" P
      return P.patientId
  )

define "Total Encounters":
  Count(
    distinct "Outpatient Antithrombotic Prescriptions" P
      return P.encounterId
  )

define "Total Organizations":
  Count(
    distinct "Outpatient Antithrombotic Prescriptions" P
      return P.organizationId
  )

define "Total Overlapping Prescription Pairs":
  Count("Prescription Pairs with Overlap")

// ============================================
// 重疊率計算 (Overlap Rate Calculation)
// ============================================

define "Overlap Rate":
  if "Total Drug Days" > 0 then
    Round(("Total Overlap Days" / "Total Drug Days") * 100, 2)
  else
    0.0

// ============================================
// 依季度分組統計 (Statistics by Quarter)
// ============================================

define "Prescriptions by Quarter":
  "Outpatient Antithrombotic Prescriptions" P
    return {
      quarter: P.quarter,
      patientId: P.patientId,
      organizationId: P.organizationId,
      medicationRequestId: P.medicationRequestId,
      startDate: P.startDate,
      endDate: P.endDate,
      drugDays: P.drugDays,
      atcPrefix: P.atcPrefix
    }

define "Statistics by Quarter":
  distinct (
    ("Prescriptions by Quarter") P
      return P.quarter
  ) Q
    return {
      quarter: Q,
      totalPrescriptions: Count(
        "Prescriptions by Quarter" P2 where P2.quarter = Q
      ),
      totalPatients: Count(
        distinct ("Prescriptions by Quarter" P3 where P3.quarter = Q return P3.patientId)
      ),
      totalDrugDays: Sum(
        ("Drug Days by Quarter" D where D.quarter = Q return D.drugDays)
      ),
      totalOverlapDays: Sum(
        ("Overlap Days by Quarter" O where O.quarter = Q return O.overlapDays)
      )
    }

// ============================================
// 依ATC分類統計 (Statistics by ATC Classification)
// ============================================

define "Prescriptions by ATC":
  "Outpatient Antithrombotic Prescriptions" P
    return {
      atcPrefix: P.atcPrefix,
      atcName: "GetATCClassName"(P.atcPrefix),
      patientId: P.patientId,
      drugDays: P.drugDays,
      quarter: P.quarter
    }

define "Statistics by ATC":
  distinct (
    ("Prescriptions by ATC") P
      return P.atcPrefix
  ) ATC
    return {
      atcPrefix: ATC,
      atcName: "GetATCClassName"(ATC),
      totalPrescriptions: Count(
        "Prescriptions by ATC" P2 where P2.atcPrefix = ATC
      ),
      totalPatients: Count(
        distinct ("Prescriptions by ATC" P3 where P3.atcPrefix = ATC return P3.patientId)
      ),
      totalDrugDays: Sum(
        ("Prescriptions by ATC" P4 where P4.atcPrefix = ATC return P4.drugDays)
      )
    }

// ============================================
// 主要輸出結果 (Main Indicator Result)
// ============================================

define "Indicator Result":
  {
    indicatorCode: '3375',
    indicatorName: '同醫院門診同藥理用藥日數重疊率-抗血栓(口服)',
    indicatorNameEn: 'Same Hospital Outpatient Antithrombotic Drug Overlap Rate (Oral)',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    numerator: "Total Overlap Days",
    denominator: "Total Drug Days",
    overlapRate: "Overlap Rate",
    unit: '%',
    totalPrescriptions: "Total Prescriptions",
    totalPatients: "Total Patients",
    totalEncounters: "Total Encounters",
    totalOrganizations: "Total Organizations",
    totalOverlappingPairs: "Total Overlapping Prescription Pairs",
    statisticsByQuarter: "Statistics by Quarter",
    statisticsByATC: "Statistics by ATC",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/05/13',
    version: '1.0.0'
  }

// ============================================
// 備註 (Notes)
// ============================================
//
// 1. 資料來源: 醫療給付檔案分析系統，指標代碼: 3375
//
// 2. 資料範圍: 醫院總額之門診處方抗血栓藥物(口服)案件，排除代辦案件。
//
// 3. 公式說明:
//    分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)。
//    分母: 各案件之「給藥日數」總和。
//    (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
//    (2)抗血栓藥物(口服): ATC前5碼為B01AA、B01AC(排除B01AC07)、B01AE、B01AF，且醫令代碼第8碼為1。
//
// 4. 製表日期: 114/05/13
//
// 5. 製表單位: 衛生福利部 中央健康保險署
//
// 6. ATC Code Details:
//    - B01AA: Vitamin K antagonists (Warfarin等)
//    - B01AC: Platelet aggregation inhibitors (Aspirin, Clopidogrel等) - 排除B01AC07
//    - B01AE: Direct thrombin inhibitors (Dabigatran等)
//    - B01AF: Direct factor Xa inhibitors (Rivaroxaban, Apixaban, Edoxaban等)
//
// ============================================
// FHIR Resource Queries (FHIR資源查詢範例)
// ============================================
//
// 1. MedicationRequest (抗血栓藥品處方)
//    GET [base]/MedicationRequest?
//        date=ge2024-01-01
//        &category=outpatient
//        &status=active,completed
//        &_include=MedicationRequest:medication
//        &_include=MedicationRequest:patient
//        &_include=MedicationRequest:encounter
//
// 2. Encounter (門診就診記錄)
//    GET [base]/Encounter?
//        date=ge2024-01-01
//        &class=AMB
//        &status=finished
//        &_include=Encounter:service-provider
//
// 3. Medication (藥品資訊 - 抗血栓藥物)
//    GET [base]/Medication?
//        code:text=antithrombotic
//        &code=http://www.whocc.no/atc|B01A
//
// 4. Patient (病人資訊)
//    GET [base]/Patient?_id={patient_id}
//
// 5. Organization (醫療機構)
//    GET [base]/Organization?type=prov
//
// ============================================
-- 
-- 【資料時間範圍】
-- 查詢期間: 2024-01-01 ~ 2025-11-07 (今天)
-- 統計單位: 每季 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
-- ============================================

-- 【資料範圍】
-- (1)醫院總額之門診處方抗血栓藥物(口服)案件
-- (2)排除代辦案件

-- 【公式說明】(依健保指標代碼 3375)
-- 同醫院門診同藥理用藥日數重疊率-抗血栓藥物(口服) = 
--     分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
--     分母: 各案件之「給藥日數」總和
-- 
-- (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
-- (2)抗血栓藥物(口服): ATC前5碼為B01AA、B01AC(排除B01AC07)、B01AE、B01AF，且醫令代碼為8碼為1
-- 
-- 排除條件:
--   1.排除特定ATC代碼: B01AC07
--   2.排除代辦案件
--   3.僅包含口服劑型(醫令代碼第8碼為1)

-- ============================================
-- 備註:
-- 1.資料來源：醫療給付檔案分析系統，指標代碼：3375
-- 
-- 2.資料範圍：醫院總額之門診處方抗血栓藥物(口服)案件，排除代辦案件。
-- 
-- 3.公式說明：
--   分子：同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)。
--   分母：各案件之「給藥日數」總和。
--   (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
--   (2)抗血栓藥物(口服): ATC前5碼為B01AA、B01AC(排除B01AC07)、B01AE、B01AF，且醫令代碼為8碼為1。
-- 
-- 4.製表日期：114/05/13
-- 
-- 5.製表單位：衛生福利部 中央健康保險署
-- ============================================

-- CQL Code Systems Definition (依健保標準代碼對照國際標準)
codesystem "NHI_INDICATOR": 'NHI_INDICATOR'  -- 健保指標代碼：同醫院門診同藥理用藥日數重疊率-抗血栓藥物(口服)
codesystem "SNOMEDCT": 'http://snomed.info/sct'  -- 劑型代碼對照
codesystem "ATC": 'http://www.whocc.no/atc'  -- ATC藥品分類代碼
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'  -- 就醫類型代碼
codesystem "NHI": 'NHI'  -- 健保專用代碼系統
-- 
-- 註: 健保代碼與國際標準完全相容，支援 SMART on FHIR

-- FHIR Resource Mapping
-- MedicationRequest → drug_details
-- Encounter → outpatient_claims  
-- Patient → patient_master
-- Organization → hospital_master

-- 建立季度時間表
WITH quarters AS (
    SELECT '2024Q1' as quarter, '2024-01-01' as start_date, '2024-03-31' as end_date
    UNION ALL SELECT '2024Q2', '2024-04-01', '2024-06-30'
    UNION ALL SELECT '2024Q3', '2024-07-01', '2024-09-30'
    UNION ALL SELECT '2024Q4', '2024-10-01', '2024-12-31'
    UNION ALL SELECT '2025Q1', '2025-01-01', '2025-03-31'
    UNION ALL SELECT '2025Q2', '2025-04-01', '2025-06-30'
    UNION ALL SELECT '2025Q3', '2025-07-01', '2025-09-30'
    UNION ALL SELECT '2025Q4', '2025-10-01', CURRENT_DATE()  -- 計算到當前日期
),

-- 健保代碼與標準代碼系統對照表
-- 依據健保指標代碼 3375 (同醫院門診同藥理用藥日數重疊率-抗血栓藥物(口服)) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '3375', '3375', 'NHI', 'Antithrombotic Drug Overlap Rate (Oral) - 同醫院門診同藥理用藥日數重疊率-抗血栓藥物(口服)'),
        
        -- ATC碼對照 (抗血栓藥物)
        -- B01A: Antithrombotic agents (抗血栓藥物)
        ('ATC', 'B01AA', 'B01AA', 'http://www.whocc.no/atc', 'Vitamin K antagonists - 維生素K拮抗劑'),
        ('ATC', 'B01AC', 'B01AC', 'http://www.whocc.no/atc', 'Platelet aggregation inhibitors excl. heparin - 抗血小板藥物(不含肝素)'),
        ('ATC', 'B01AE', 'B01AE', 'http://www.whocc.no/atc', 'Direct thrombin inhibitors - 直接凝血酶抑制劑'),
        ('ATC', 'B01AF', 'B01AF', 'http://www.whocc.no/atc', 'Direct factor Xa inhibitors - 直接第十因子抑制劑'),
        
        -- 排除的特定ATC代碼
        ('ATC_EXCLUDE', 'B01AC07', 'B01AC07', 'http://www.whocc.no/atc', 'Dipyridamole - 應排除'),
        
        -- 劑型代碼 (SNOMED CT) - 僅口服
        ('DOSAGE_FORM', '2', '385268001', 'http://snomed.info/sct', 'Oral - 口服'),
        ('DOSAGE_FORM', 'ORAL', '385268001', 'http://snomed.info/sct', 'Oral dose form - 口服劑型'),
        ('DOSAGE_FORM', '1', '385268001', 'http://snomed.info/sct', 'Oral (order_code 8th digit = 1) - 口服(醫令代碼第8碼為1)'),
        
        -- 就醫類型代碼
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選抗血栓藥物(口服)
-- 條件: ATC前5碼為B01AA、B01AC(排除B01AC07)、B01AE、B01AF，且醫令代碼第8碼為1
antithrombotic_drugs AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        o.patient_id,
        o.claim_id,
        o.visit_date,
        d.drug_code,
        d.drug_name,
        d.atc_code,
        d.order_code,
        d.dosage_form,
        -- 給藥日數: 優先取 ORDER_DRUG_DAY，若為空則取 DRUG_DAYS
        COALESCE(d.order_drug_day, d.drug_days, 0) as drug_days,
        -- 給藥開始日期: 處方開始日期
        d.prescription_date as start_date,
        -- 給藥結束日期: 處方開始日期 + 給藥日數 - 1
        DATE_ADD(d.prescription_date, INTERVAL (COALESCE(d.order_drug_day, d.drug_days, 0) - 1) DAY) as end_date,
        SUBSTRING(d.atc_code, 1, 5) as atc_class_5,
        -- 醫令代碼第8碼
        SUBSTRING(d.order_code, 8, 1) as order_code_8th_digit,
        ncm.standard_code as atc_standard_code,
        ncm.description as atc_description
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診
    INNER JOIN drug_details d 
        ON o.claim_id = d.claim_id
    LEFT JOIN nhi_code_mapping ncm 
        ON SUBSTRING(d.atc_code, 1, 5) = ncm.nhi_code 
        AND ncm.code_type = 'ATC'
    WHERE 
        -- 條件1: 抗血栓藥物 ATC 代碼 (前5碼)
        (SUBSTRING(d.atc_code, 1, 5) IN ('B01AA', 'B01AC', 'B01AE', 'B01AF'))
        
        -- 條件2: 排除特定ATC代碼 B01AC07 (Dipyridamole)
        AND d.atc_code <> 'B01AC07'
        
        -- 條件3: 僅口服劑型 - 醫令代碼第8碼為1
        AND SUBSTRING(d.order_code, 8, 1) = '1'
        
        -- 條件4: 給藥日數 > 0
        AND COALESCE(d.order_drug_day, d.drug_days, 0) > 0
        
        -- 排除代辦案件
        AND (o.agency_case_flag IS NULL OR o.agency_case_flag <> 'Y')
),

-- 計算同院同病人不同處方之間的用藥日期重疊
-- 使用自我連接找出同院、同病人、不同處方且日期有重疊的案件
drug_overlaps AS (
    SELECT 
        a1.quarter,
        a1.hospital_id,
        a1.patient_id,
        a1.claim_id as claim_id_1,
        a2.claim_id as claim_id_2,
        a1.drug_code as drug_code_1,
        a2.drug_code as drug_code_2,
        a1.start_date as start_date_1,
        a1.end_date as end_date_1,
        a2.start_date as start_date_2,
        a2.end_date as end_date_2,
        a1.drug_days as drug_days_1,
        a2.drug_days as drug_days_2,
        -- 計算重疊日數
        -- 重疊開始日 = MAX(start_date_1, start_date_2)
        -- 重疊結束日 = MIN(end_date_1, end_date_2)
        -- 重疊日數 = 重疊結束日 - 重疊開始日 + 1 (如果 > 0)
        CASE 
            WHEN GREATEST(a1.start_date, a2.start_date) <= LEAST(a1.end_date, a2.end_date)
            THEN DATEDIFF(LEAST(a1.end_date, a2.end_date), GREATEST(a1.start_date, a2.start_date)) + 1
            ELSE 0
        END as overlap_days
    FROM antithrombotic_drugs a1
    INNER JOIN antithrombotic_drugs a2
        ON a1.quarter = a2.quarter
        AND a1.hospital_id = a2.hospital_id  -- 同醫院
        AND a1.patient_id = a2.patient_id    -- 同病人
        AND a1.claim_id < a2.claim_id        -- 不同處方 (避免重複計算)
    WHERE 
        -- 有日期重疊: start_date_1 <= end_date_2 AND start_date_2 <= end_date_1
        a1.start_date <= a2.end_date
        AND a2.start_date <= a1.end_date
),

-- 分子: 計算各醫院每季的重疊給藥日數總和
numerator AS (
    SELECT 
        quarter,
        hospital_id,
        SUM(overlap_days) as total_overlap_days
    FROM drug_overlaps
    GROUP BY quarter, hospital_id
),

-- 分母: 計算各醫院每季的總給藥日數
denominator AS (
    SELECT 
        quarter,
        hospital_id,
        SUM(drug_days) as total_drug_days
    FROM antithrombotic_drugs
    GROUP BY quarter, hospital_id
),

-- 計算重疊率
overlap_rate AS (
    SELECT 
        d.quarter,
        d.hospital_id,
        h.hospital_name,
        h.hospital_level,
        h.hospital_region,
        COALESCE(n.total_overlap_days, 0) as overlap_days,
        d.total_drug_days as total_drug_days,
        CASE 
            WHEN d.total_drug_days > 0 
            THEN ROUND((COALESCE(n.total_overlap_days, 0) * 100.0 / d.total_drug_days), 4)
            ELSE 0
        END as overlap_rate_percent
    FROM denominator d
    LEFT JOIN numerator n
        ON d.quarter = n.quarter
        AND d.hospital_id = n.hospital_id
    LEFT JOIN hospital_master h
        ON d.hospital_id = h.hospital_id
)

-- ============================================
-- 輸出1: 各醫療機構抗血栓藥品(口服)重疊率
-- ============================================
SELECT 
    quarter as '季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    hospital_level as '醫院層級',
    hospital_region as '區域別',
    overlap_days as '抗血栓藥物重疊用藥日數(分子)',
    total_drug_days as '抗血栓藥物之給藥日數(分母)',
    overlap_rate_percent as '抗血栓藥物(口服)不同處方用藥日數重疊率(%)',
    CASE 
        WHEN overlap_rate_percent > 1.0 THEN '需關注'
        WHEN overlap_rate_percent > 0.5 THEN '持續監測'
        ELSE '正常範圍'
    END as '評估結果'
FROM overlap_rate
ORDER BY quarter, overlap_rate_percent DESC;

-- ============================================
-- 輸出2: 各季度統計摘要
-- ============================================
SELECT 
    quarter as '季度',
    COUNT(DISTINCT hospital_id) as '醫院數',
    SUM(overlap_days) as '總重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '整體重疊率(%)',
    ROUND(AVG(overlap_rate_percent), 4) as '平均重疊率(%)',
    MIN(overlap_rate_percent) as '最小重疊率(%)',
    MAX(overlap_rate_percent) as '最大重疊率(%)'
FROM overlap_rate
GROUP BY quarter
ORDER BY quarter;

-- ============================================
-- 輸出3: 依醫院層級統計
-- ============================================
SELECT 
    quarter as '季度',
    hospital_level as '醫院層級',
    COUNT(DISTINCT hospital_id) as '醫院數',
    SUM(overlap_days) as '重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '重疊率(%)'
FROM overlap_rate
GROUP BY quarter, hospital_level
ORDER BY quarter, hospital_level;

-- ============================================
-- 輸出4: 依區域統計
-- ============================================
SELECT 
    quarter as '季度',
    hospital_region as '區域',
    COUNT(DISTINCT hospital_id) as '醫院數',
    SUM(overlap_days) as '重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '重疊率(%)'
FROM overlap_rate
GROUP BY quarter, hospital_region
ORDER BY quarter, hospital_region;

-- ============================================
-- 輸出5: 依ATC碼分類統計(4類)
-- ============================================
SELECT 
    a.quarter as '季度',
    a.atc_class_5 as 'ATC代碼(前5碼)',
    a.atc_description as 'ATC說明',
    COUNT(DISTINCT a.patient_id) as '病人數',
    COUNT(DISTINCT a.claim_id) as '處方數',
    SUM(a.drug_days) as '總給藥日數'
FROM antithrombotic_drugs a
GROUP BY a.quarter, a.atc_class_5, a.atc_description
ORDER BY a.quarter, SUM(a.drug_days) DESC;

-- ============================================
-- 輸出6: 趨勢分析
-- ============================================
SELECT 
    quarter as '季度',
    SUM(overlap_days) as '重疊日數',
    SUM(total_drug_days) as '總給藥日數',
    ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) as '重疊率(%)',
    LAG(ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4)) 
        OVER (ORDER BY quarter) as '前一季重疊率(%)',
    ROUND(
        (ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4) - 
         LAG(ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4)) 
            OVER (ORDER BY quarter)) * 100.0 / 
        NULLIF(LAG(ROUND(SUM(overlap_days) * 100.0 / NULLIF(SUM(total_drug_days), 0), 4)) 
            OVER (ORDER BY quarter), 0),
        2
    ) as '變化率(%)'
FROM overlap_rate
GROUP BY quarter
ORDER BY quarter;

-- ============================================
-- 查詢結束
-- ============================================
-- 製表日期: 2025-11-07
-- 指標代碼: 3375
-- 指標名稱: 同醫院門診同藥理用藥日數重疊率-抗血栓藥物(口服)
-- 
-- FHIR Resource Mapping Summary:
-- - MedicationRequest (藥品處方) → drug_details
-- - Encounter (就醫紀錄) → outpatient_claims
-- - Patient (病人資料) → patient_master  
-- - Organization (醫療機構) → hospital_master
-- 
-- Code Systems Used:
-- - SNOMEDCT: http://snomed.info/sct (劑型代碼)
-- - ATC: http://www.whocc.no/atc (藥品分類 - B01AA, B01AC, B01AE, B01AF)
-- - ActCode: http://terminology.hl7.org/CodeSystem/v3-ActCode (就醫類型)
-- 
-- ATC Code Details:
-- - B01AA: Vitamin K antagonists (Warfarin等)
-- - B01AC: Platelet aggregation inhibitors (Aspirin, Clopidogrel等) - 排除B01AC07
-- - B01AE: Direct thrombin inhibitors (Dabigatran等)
-- - B01AF: Direct factor Xa inhibitors (Rivaroxaban, Apixaban, Edoxaban等)
-- 
-- Dosage Form Restriction:
-- - 僅口服劑型: 醫令代碼第8碼為1
-- ============================================
