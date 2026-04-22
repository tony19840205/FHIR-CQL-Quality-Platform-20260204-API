library Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// ???迂: ??ａ?閮箏??亦??刻?交???????????)
// ??隞?Ⅳ: 3375
// 鋆賭??交?: 2025-11-20
// 鋆質”?交?: 114/05/13
// 鋆質”?桐?: 銵?蝳??銝剖亢?亙熒靽蝵?
// ============================================
//
// ????????
// ?亥岷??: 2024-01-01 ~ 2026-01-09 (隞予)
// 蝯梯??桐?: 瘥迤 (2024Q1, 2024Q2, 2024Q3, 2024Q4, 2025Q1, 2025Q2, 2025Q3, 2025Q4)
//
// ??????
// (1)?恍蝮賡?銋?閮箄??寞?銵??????)獢辣
// (2)?隞?齒獢辣
//
// ?撘牧??靘靽?璅誨蝣?3375)
// ??ａ?閮箏??亦??刻?交????????????) = 
//     ??: ??D銝??銋?蝯衣?交??蝯??刻?交?????銋策?交???迂?嗆??拇??
//     ??: ??隞嗡??策?交?詻蜇??
// 
// (1)?策?交?詻??隞斗?銋隞斤策?交隞?ORDER_DRUG_DAY)嚗?箇征?澆????格?銋策?交隞?DRUG_DAYS)
// (2)????????): ATC??蝣潛B01AA?01AC(?B01AC07)?01AE?01AF嚗??思誘隞?Ⅳ蝚?蝣潛1
// 
// ?璇辣:
//   1.??孵?ATC隞?Ⅳ: B01AC07
//   2.?隞?齒獢辣
//   3.???怠?????思誘隞?Ⅳ蝚?蝣潛1)
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
code "B01AA": 'B01AA' from "ATC" display 'Vitamin K antagonists'
code "B01AC": 'B01AC' from "ATC" display 'Platelet aggregation inhibitors'
code "B01AE": 'B01AE' from "ATC" display 'Direct thrombin inhibitors'
code "B01AF": 'B01AF' from "ATC" display 'Direct factor Xa inhibitors'

// Excluded ATC Code
code "B01AC07": 'B01AC07' from "ATC" display 'Dipyridamole'

// Dosage Forms
code "Oral": '385268001' from "SNOMEDCT" display 'Oral dose form'

// Contexts
context Patient

// ============================================
// ?????蝢?(Measurement Periods)
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

// Check if medication is oral dosage form (?思誘隞?Ⅳ蝚?蝣潛1)
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

// Get drug supply days (蝯西?交)
define function "GetDrugDays"(medicationRequest FHIR.MedicationRequest):
  if medicationRequest.dispenseRequest.expectedSupplyDuration is not null then
    Truncate(medicationRequest.dispenseRequest.expectedSupplyDuration.value)
  else
    30

// Get drug start date (蝯西???交?)
define function "GetDrugStartDate"(medicationRequest FHIR.MedicationRequest):
  Coalesce(
    start of medicationRequest.dispenseRequest.validityPeriod,
    medicationRequest.authoredOn
  )

// Get drug end date (蝯西蝯??交?)
define function "GetDrugEndDate"(medicationRequest FHIR.MedicationRequest):
  "GetDrugStartDate"(medicationRequest) + System.Quantity { value: "GetDrugDays"(medicationRequest) - 1, unit: 'day' }

// Calculate overlap days between two date ranges
define function "CalculateOverlapDays"(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 > end2 or start2 > end1 then 0
  else
    days between (if start1 > start2 then start1 else start2) and (if end1 < end2 then end1 else end2) + 1

// Check if two date ranges overlap
define function "HasOverlap"(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
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
    when 'B01AA' then 'B01AA - Vitamin K antagonists (蝬剔?蝝?格???'
    when 'B01AC' then 'B01AC - Platelet aggregation inhibitors (??撠?亦)'
    when 'B01AE' then 'B01AE - Direct thrombin inhibitors (?湔???嗆??嗅?)'
    when 'B01AF' then 'B01AF - Direct factor Xa inhibitors (?湔蝚砍??????'
    else 'Other'
  end

// ============================================
// ?閮箏停閮箄??祟??(Outpatient Encounters)
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
// ????抵??寧祟??(Antithrombotic Medication Requests)
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
// ?閮箸?銵??抵???(Outpatient Antithrombotic Prescriptions)
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
// ??Ｗ??犖銝?????? (Prescription Overlap Analysis)
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
// ??: ??蝯西?交蝮賢? (Numerator: Total Overlap Days)
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
// ??: 蝮賜策?交??(Denominator: Total Drug Days)
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
// 蝯梯??豢? (Statistics)
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
// ????蝞?(Overlap Rate Calculation)
// ============================================

define "Overlap Rate":
  if "Total Drug Days" > 0 then
    Round(("Total Overlap Days" / "Total Drug Days") * 100, 2)
  else
    0.0

// ============================================
// 靘迤摨血?蝯絞閮?(Statistics by Quarter)
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
// 靘TC??蝯梯? (Statistics by ATC Classification)
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
// 銝餉?頛詨蝯? (Main Indicator Result)
// ============================================

define "Indicator Result":
  {
    indicatorCode: '3375',
    indicatorName: '??ａ?閮箏??亦??刻?交???????????)',
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
    dataSource: 'NHIA',
    compiledBy: 'MOHW NHIA',
    compiledDate: '114/05/13',
    version: '1.0.0'
  }

// ============================================
// ?酉 (Notes)
// ============================================
//
// 1. 鞈?靘?: ?怎?蝯虫?瑼???蝟餌絞嚗?璅誨蝣? 3375
//
// 2. 鞈?蝭?: ?恍蝮賡?銋?閮箄??寞?銵??????)獢辣嚗??支誨颲行?隞嗚?
//
// 3. ?砍?隤芣?:
//    ??: ??D銝??銋?蝯衣?交??蝯??刻?交?????銋策?交???迂?嗆??拇????
//    ??: ??隞嗡??策?交?詻蜇??
//    (1)?策?交?詻??隞斗?銋隞斤策?交隞?ORDER_DRUG_DAY)嚗?箇征?澆????格?銋策?交隞?DRUG_DAYS)??
//    (2)????????): ATC??蝣潛B01AA?01AC(?B01AC07)?01AE?01AF嚗??思誘隞?Ⅳ蝚?蝣潛1??
//
// 4. 鋆質”?交?: 114/05/13
//
// 5. 鋆質”?桐?: 銵?蝳??銝剖亢?亙熒靽蝵?
//
// 6. ATC Code Details:
//    - B01AA: Vitamin K antagonists (Warfarin蝑?
//    - B01AC: Platelet aggregation inhibitors (Aspirin, Clopidogrel蝑? - ?B01AC07
//    - B01AE: Direct thrombin inhibitors (Dabigatran蝑?
//    - B01AF: Direct factor Xa inhibitors (Rivaroxaban, Apixaban, Edoxaban蝑?
//
// ============================================
// FHIR Resource Queries (FHIR鞈??亥岷蝭?)
// ============================================
//
// 1. MedicationRequest (???????
//    GET [base]/MedicationRequest?
//        date=ge2024-01-01
//        &category=outpatient
//        &status=active,completed
//        &_include=MedicationRequest:medication
//        &_include=MedicationRequest:patient
//        &_include=MedicationRequest:encounter
//
// 2. Encounter (?閮箏停閮箄???
//    GET [base]/Encounter?
//        date=ge2024-01-01
//        &class=AMB
//        &status=finished
//        &_include=Encounter:service-provider
//
// 3. Medication (?亙?鞈? - ?????
//    GET [base]/Medication?
//        code:text=antithrombotic
//        &code=http://www.whocc.no/atc|B01A
//
// 4. Patient (?犖鞈?)
//    GET [base]/Patient?_id={patient_id}
//
// 5. Organization (?怎?璈?)
//    GET [base]/Organization?type=prov
//
