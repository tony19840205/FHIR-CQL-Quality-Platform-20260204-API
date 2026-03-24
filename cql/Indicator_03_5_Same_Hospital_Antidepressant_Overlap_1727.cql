library Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 同醫院門診同藥理用藥日數重疊率-抗憂鬱症(口服)
// 指標代碼: 1727
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
// (1)醫院總額之門診處方抗憂鬱症藥物案件
// (2)排除代辦案件
//
// 【公式說明】(依健保指標代碼 1727)
// 同醫院門診同藥理用藥日數重疊率-抗憂鬱症 = 
//     分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)
//     分母: 各案件之「給藥日數」總和
// 
// (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
// (2)抗憂鬱症藥物: ATC前5碼為N06AA(排除N06AA02、N06AA12)、N06AB、N06AG
// 
// 排除條件:
//   1.排除特定ATC代碼: N06AA02、N06AA12
//   2.排除代辦案件
// ============================================

// Code Systems
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

// Value Sets
valueset "Antidepressant ATC Codes": 'http://nhi.gov.tw/fhir/ValueSet/antidepressant-atc-codes'

// Codes - Encounter Types
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'

// Codes - Medication Request Status
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// Codes - Encounter Status
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// Antidepressant ATC Code Prefixes (N06A)
code "N06AA": 'N06AA' from "ATC" display 'Non-selective monoamine reuptake inhibitors - 非選擇性單胺再回收抑制劑(三環抗憂鬱劑)'
code "N06AB": 'N06AB' from "ATC" display 'Selective serotonin reuptake inhibitors (SSRIs) - 選擇性血清素再回收抑制劑'
code "N06AG": 'N06AG' from "ATC" display 'Monoamine oxidase A inhibitors - 單胺氧化酶A抑制劑'

// Excluded ATC Codes
code "N06AA02": 'N06AA02' from "ATC" display 'Imipramine - 應排除'
code "N06AA12": 'N06AA12' from "ATC" display 'Doxepin - 應排除'

// Dosage Forms
code "Oral": '385268001' from "SNOMEDCT" display 'Oral dose form - 口服劑型'
code "Injection": '385219001' from "SNOMEDCT" display 'Injection - 注射劑'

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
define "Measurement Period End": Today()
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

// Check if ATC code is antidepressant (N06A family, excluding specific codes)
define function "IsAntidepressantATC"(atcPrefix String):
  atcPrefix in {
    'N06AA', 'N06AB', 'N06AG'
  }

// Check if medication has excluded ATC codes
define function "IsExcludedATC"(medication FHIR.Medication):
  if medication is null or medication.code is null then false
  else
    exists (
      medication.code.coding C
        where C.system = 'http://www.whocc.no/atc'
          and C.code in {'N06AA02', 'N06AA12'}
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
    when 'N06AA' then 'N06AA - Non-selective monoamine reuptake inhibitors (三環抗憂鬱劑)'
    when 'N06AB' then 'N06AB - Selective serotonin reuptake inhibitors (SSRIs)'
    when 'N06AG' then 'N06AG - Monoamine oxidase A inhibitors (MAO-A抑制劑)'
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
// 抗憂鬱藥物處方篩選 (Antidepressant Medication Requests)
// ============================================

define "All Medication Requests":
  [MedicationRequest] MR
    where MR.status in {'active', 'completed'}
      and MR.intent = 'order'
      and MR.authoredOn during "Measurement Period"

define "Antidepressant Medication Requests":
  "All Medication Requests" MR
    let medication: singleton from ([Medication: id in "GetId"(MR.medication)])
    where "IsAntidepressantATC"("GetATCCodePrefix"(medication))
      and not "IsExcludedATC"(medication)
      and exists (MR.dosageInstruction)
      and "GetDrugDays"(MR) > 0

// ============================================
// 門診抗憂鬱藥物處方 (Outpatient Antidepressant Prescriptions)
// ============================================

define "Outpatient Antidepressant Prescriptions":
  from
    "Outpatient Encounters" E,
    "Antidepressant Medication Requests" MR
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
    "Outpatient Antidepressant Prescriptions" P1,
    "Outpatient Antidepressant Prescriptions" P2
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
    "Outpatient Antidepressant Prescriptions" P
      return P.drugDays
  )

define "Drug Days by Quarter":
  ("Outpatient Antidepressant Prescriptions") P
    return {
      quarter: P.quarter,
      drugDays: P.drugDays
    }

define "Drug Days by Organization":
  ("Outpatient Antidepressant Prescriptions") P
    return {
      organizationId: P.organizationId,
      quarter: P.quarter,
      drugDays: P.drugDays
    }

// ============================================
// 統計數據 (Statistics)
// ============================================

define "Total Prescriptions":
  Count("Outpatient Antidepressant Prescriptions")

define "Total Patients":
  Count(
    distinct "Outpatient Antidepressant Prescriptions" P
      return P.patientId
  )

define "Total Encounters":
  Count(
    distinct "Outpatient Antidepressant Prescriptions" P
      return P.encounterId
  )

define "Total Organizations":
  Count(
    distinct "Outpatient Antidepressant Prescriptions" P
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
  "Outpatient Antidepressant Prescriptions" P
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
  "Outpatient Antidepressant Prescriptions" P
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
    indicatorCode: '1727',
    indicatorName: '同醫院門診同藥理用藥日數重疊率-抗憂鬱症',
    indicatorNameEn: 'Same Hospital Outpatient Antidepressant Drug Overlap Rate',
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
// 1. 資料來源: 醫療給付檔案分析系統，指標代碼: 1727
//
// 2. 資料範圍: 醫院總額之門診處方抗憂鬱症藥物案件，排除代辦案件。
//
// 3. 公式說明:
//    分子: 同院同ID不同處方之間給用藥日期與結束用藥日期間有重疊之給藥日數(允許零提早拿藥)。
//    分母: 各案件之「給藥日數」總和。
//    (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
//    (2)抗憂鬱症藥物: ATC前5碼為N06AA(排除N06AA02、N06AA12)、N06AB、N06AG。
//
// 4. 製表日期: 114/05/13
//
// 5. 製表單位: 衛生福利部 中央健康保險署
//
// ============================================
// FHIR Resource Queries (FHIR資源查詢範例)
// ============================================
//
// 1. MedicationRequest (抗憂鬱藥品處方)
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
// 3. Medication (藥品資訊 - 抗憂鬱藥物)
//    GET [base]/Medication?
//        code:text=antidepressant
//        &code=http://www.whocc.no/atc|N06A
//
// 4. Patient (病人資訊)
//    GET [base]/Patient?_id={patient_id}
//
// 5. Organization (醫療機構)
//    GET [base]/Organization?type=prov
//
// ============================================
