library Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-抗憂鬱症(口服)
// 指標代碼: 1730
// 製作日期：2026-01-09

// 時間區間定義
define "2024Q1 Start": @2024-01-01
define "2024Q1 End": @2024-03-31
define "2024Q2 Start": @2024-04-01
define "2024Q2 End": @2024-06-30
define "2024Q3 Start": @2024-07-01
define "2024Q3 End": @2024-09-30
define "2024Q4 Start": @2024-10-01
define "2024Q4 End": @2024-12-31
define "2025Q1 Start": @2025-01-01
define "2025Q1 End": @2025-03-31
define "2025Q2 Start": @2025-04-01
define "2025Q2 End": @2025-06-30
define "2025Q3 Start": @2025-07-01
define "2025Q3 End": @2025-09-30
define "2025Q4 Start": @2025-10-01
define "2025Q4 End": @2025-12-31
define "2026Q1 Start": @2026-01-01
define "2026Q1 End": @2026-03-31

define "Measurement Period Start": @2024-01-01
define "Measurement Period End": @2099-12-31
define "Measurement Period": Interval["Measurement Period Start", "Measurement Period End"]

context Patient

// ATC代碼列表
define "Antidepressant ATC Prefixes": { 'N06AA', 'N06AB', 'N06AG' }
define "Excluded ATC Codes": { 'N06AA02', 'N06AA12' }

// Helper Functions
define function "GetId"(reference Reference):
  Last(Split(reference.reference.value, '/'))

define function "GetATCCodePrefix5"(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where C.system.value = 'http://www.whocc.no/atc'
        return Substring(C.code.value, 0, 5)
    )

define function "GetATCCode"(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where C.system.value = 'http://www.whocc.no/atc'
        return C.code.value
    )

define function "IsAntidepressantATC"(medication Medication):
  if medication is null then false
  else if medication.code is null or medication.code.coding is null then false
  else
    exists(
      medication.code.coding C
        where C.system.value = 'http://www.whocc.no/atc'
          and (
            (Substring(C.code.value, 0, 5) = 'N06AA' and C.code.value != 'N06AA02' and C.code.value != 'N06AA12')
            or Substring(C.code.value, 0, 5) = 'N06AB'
            or Substring(C.code.value, 0, 5) = 'N06AG'
          )
    )

define function "IsOralDosageForm"(medication Medication):
  if medication is null or medication.form is null then false
  else
    exists (
      medication.form.coding C
        where C.system.value = 'http://snomed.info/sct'
          and C.code.value = '385268001'
    ) or exists (
      medication.extension E
        where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/order-code-8th-digit'
          and E.value.value = '1'
    )

define function "GetDrugDays"(medicationRequest MedicationRequest):
  Coalesce(
    medicationRequest.dispenseRequest.expectedSupplyDuration.value.value,
    30
  )

define function "GetDrugStartDate"(medicationRequest MedicationRequest):
  Coalesce(
    medicationRequest.dispenseRequest.validityPeriod.start.value,
    medicationRequest.authoredOn.value
  )

define function "GetDrugEndDate"(medicationRequest MedicationRequest):
  "GetDrugStartDate"(medicationRequest) + ("GetDrugDays"(medicationRequest) * 1 day) - 1 day

define function "CalculateOverlapDays"(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then 0
  else
    if start1 > end2 or start2 > end1 then 0
    else
      difference in days between 
        (if start1 > start2 then start1 else start2) and 
        (if end1 < end2 then end1 else end2) + 1

define function "HasOverlap"(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  start1 <= end2 and start2 <= end1

define function "GetQuarter"(date DateTime):
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

define function "GetATCClassName"(medication Medication):
  case "GetATCCodePrefix5"(medication)
    when 'N06AA' then 'Non-selective monoamine reuptake inhibitors'
    when 'N06AB' then 'Selective serotonin reuptake inhibitors (SSRIs)'
    when 'N06AG' then 'Monoamine oxidase A inhibitors (MAOIs)'
    else 'Unknown'
  end

// 門診就診記錄 (排除代辦案件)
define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and E.period.start.value during "Measurement Period"
      and not exists (
        E.extension EX
          where EX.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
            and EX.value.value = true
      )

// 所有用藥請求
define "All Medication Requests":
  [MedicationRequest] MR
    where MR.status.value in { 'active', 'completed' }
      and MR.intent.value = 'order'
      and MR.authoredOn.value during "Measurement Period"

// 抗憂鬱症藥物請求
define "Antidepressant Medication Requests":
  "All Medication Requests" MR
    where exists(
      [Medication] M
        where M.id.value = "GetId"(MR.medication)
        and "IsAntidepressantATC"(M)
        and "IsOralDosageForm"(M)
    )
    and exists(MR.dosageInstruction)
    and "GetDrugDays"(MR) > 0

// 門診抗憂鬱症藥物處方
define "Outpatient Antidepressant Prescriptions":
  from "Antidepressant Medication Requests" MR,
    "Outpatient Encounters" E
  where "GetId"(MR.encounter) = E.id.value
  return {
    medicationRequestId: MR.id.value,
    encounterId: E.id.value,
    patientId: "GetId"(MR.subject),
    organizationId: "GetId"(E.serviceProvider),
    authoredOn: MR.authoredOn.value,
    medication: singleton from ([Medication] M where M.id.value = "GetId"(MR.medication)),
    drugDays: "GetDrugDays"(MR),
    startDate: "GetDrugStartDate"(MR),
    endDate: "GetDrugEndDate"(MR),
    quarter: "GetQuarter"(MR.authoredOn.value)
  }

// 處方配對 (跨醫院、同病患、不同處方、有重疊)
define "Cross Hospital Prescription Pairs with Overlap":
  from "Outpatient Antidepressant Prescriptions" P1,
    "Outpatient Antidepressant Prescriptions" P2
  where P1.organizationId != P2.organizationId
    and P1.patientId = P2.patientId
    and P1.medicationRequestId < P2.medicationRequestId
    and P1.quarter = P2.quarter
    and "HasOverlap"(P1.startDate, P1.endDate, P2.startDate, P2.endDate)
  return {
    quarter: P1.quarter,
    patientId: P1.patientId,
    organization1: P1.organizationId,
    organization2: P2.organizationId,
    prescription1: P1.medicationRequestId,
    prescription2: P2.medicationRequestId,
    atcClass1: "GetATCCodePrefix5"(P1.medication),
    atcClass2: "GetATCCodePrefix5"(P2.medication),
    startDate1: P1.startDate,
    endDate1: P1.endDate,
    startDate2: P2.startDate,
    endDate2: P2.endDate,
    drugDays1: P1.drugDays,
    drugDays2: P2.drugDays,
    overlapDays: "CalculateOverlapDays"(P1.startDate, P1.endDate, P2.startDate, P2.endDate)
  }

// 總給藥日數 (分母)
define "Total Drug Days":
  Sum("Outpatient Antidepressant Prescriptions" P return P.drugDays)

// 總重疊日數 (分子)
define "Total Overlap Days":
  Sum("Cross Hospital Prescription Pairs with Overlap" PP return PP.overlapDays)

// 重疊率
define "Overlap Rate":
  if "Total Drug Days" is null or "Total Drug Days" = 0 then null
  else ("Total Overlap Days" / "Total Drug Days") * 100

// 各季度統計
define "Statistics by Quarter":
  ({ '2024Q1', '2024Q2', '2024Q3', '2024Q4', '2025Q1', '2025Q2', '2025Q3', '2025Q4', '2026Q1' }) Q
    return {
      quarter: Q,
      totalDrugDays: Sum(
        "Outpatient Antidepressant Prescriptions" P
          where P.quarter = Q
          return P.drugDays
      ),
      totalOverlapDays: Sum(
        "Cross Hospital Prescription Pairs with Overlap" PP
          where PP.quarter = Q
          return PP.overlapDays
      ),
      overlapRate: 
        if Sum(
          "Outpatient Antidepressant Prescriptions" P
            where P.quarter = Q
            return P.drugDays
        ) is null or Sum(
          "Outpatient Antidepressant Prescriptions" P
            where P.quarter = Q
            return P.drugDays
        ) = 0 then null
        else (Sum(
          "Cross Hospital Prescription Pairs with Overlap" PP
            where PP.quarter = Q
            return PP.overlapDays
        ) / Sum(
          "Outpatient Antidepressant Prescriptions" P
            where P.quarter = Q
            return P.drugDays
        )) * 100
    }

// 指標結果
define "Indicator Result":
  {
    indicatorCode: '1730',
    indicatorName: 'Cross-Hospital Outpatient Antidepressant Drug Overlap Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    totalDrugDays: "Total Drug Days",
    totalOverlapDays: "Total Overlap Days",
    overlapRate: "Overlap Rate",
    quarterlyStatistics: "Statistics by Quarter",
    keyFeature: 'Cross-Hospital Analysis (organizationId != organizationId)'
  }
