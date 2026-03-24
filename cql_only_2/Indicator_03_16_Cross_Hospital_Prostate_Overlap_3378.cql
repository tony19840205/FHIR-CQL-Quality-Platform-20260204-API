library Indicator_03_16_Cross_Hospital_Prostate_Overlap_3378 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-前列腺肥大(口服)
// 指標代碼: 3378
// 製作日期：2026-01-09
// 
// 【公式說明】
// 跨醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服) = 
//     分子: 全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數
//     分母: 各案件之「給藥日數」總和
// 
// 前列腺肥大藥物ATC代碼:
//   G04CA: Alpha-adrenoreceptor antagonists (α受體阻斷劑)
//   G04CB: Testosterone-5-alpha reductase inhibitors (5α還原酶抑制劑)

// ========== 季度定義 ==========

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

// ========== Helper Functions ==========

define function "GetId"(reference Reference):
  Last(Split(reference.reference.value, '/'))

define function "GetATCCodePrefix5"(medication Medication):
  if medication is null or medication.code is null or medication.code.coding is null then ''
  else
    Coalesce(
      First(
        medication.code.coding C
          where C.system.value = 'http://www.whocc.no/atc'
          return Substring(C.code.value, 0, 5)
      ),
      ''
    )

define function "GetATCCode"(medication Medication):
  if medication is null or medication.code is null or medication.code.coding is null then ''
  else
    Coalesce(
      First(
        medication.code.coding C
          where C.system.value = 'http://www.whocc.no/atc'
          return C.code.value
      ),
      ''
    )

define function "IsBPHDrug"(medication Medication):
  if medication is null or medication.code is null or medication.code.coding is null then false
  else
    exists(
      medication.code.coding C
        where C.system.value = 'http://www.whocc.no/atc'
          and (
            Substring(C.code.value, 0, 5) = 'G04CA'
            or Substring(C.code.value, 0, 5) = 'G04CB'
          )
    )

define function "IsOralDosageForm"(medication Medication):
  if medication is null or medication.form is null then false
  else
    exists (
      medication.form.coding C
        where C.system.value = 'http://snomed.info/sct'
          and C.code.value = '385268001'
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
    else 'Unknown'
  end

define function "GetATCClassName"(medication Medication):
  case "GetATCCodePrefix5"(medication)
    when 'G04CA' then 'Alpha-adrenoreceptor antagonists'
    when 'G04CB' then 'Testosterone-5-alpha reductase inhibitors'
    else 'Unknown'
  end

// ========== 門診就診記錄 ==========

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and E.period.start.value during "Measurement Period"
      and not exists (
        E.extension EXT
          where EXT.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
            and EXT.value = true
      )

// ========== 用藥請求 ==========

define "All Medication Requests":
  [MedicationRequest] MR
    where MR.status.value in { 'active', 'completed' }
      and MR.intent.value = 'order'
      and MR.authoredOn.value during "Measurement Period"

define "BPH Medication Requests":
  "All Medication Requests" MR
    where exists(
      [Medication] M
        where M.id.value = "GetId"(MR.medication)
        and "IsBPHDrug"(M)
        and "IsOralDosageForm"(M)
    )
    and exists(MR.dosageInstruction)
    and "GetDrugDays"(MR) > 0

// ========== 門診前列腺肥大藥物處方 ==========

define "Outpatient BPH Prescriptions":
  from "BPH Medication Requests" MR,
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

// ========== 跨醫院處方配對 ==========

define "Cross Hospital Prescription Pairs with Overlap":
  from "Outpatient BPH Prescriptions" P1,
    "Outpatient BPH Prescriptions" P2
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

// ========== 總給藥日數 ==========

define "Total Drug Days":
  Sum(
    "Outpatient BPH Prescriptions" P
      return P.drugDays
  )

// ========== 總重疊日數 ==========

define "Total Overlap Days":
  Sum(
    "Cross Hospital Prescription Pairs with Overlap" PP
      return PP.overlapDays
  )

// ========== 各季度統計 ==========

define "2024Q1 Statistics":
  {
    quarter: '2024Q1',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2024Q1'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2024Q1' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q1'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q1' return PP.overlapDays)
  }

define "2024Q2 Statistics":
  {
    quarter: '2024Q2',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2024Q2'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2024Q2' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q2'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q2' return PP.overlapDays)
  }

define "2024Q3 Statistics":
  {
    quarter: '2024Q3',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2024Q3'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2024Q3' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q3'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q3' return PP.overlapDays)
  }

define "2024Q4 Statistics":
  {
    quarter: '2024Q4',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2024Q4'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2024Q4' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q4'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q4' return PP.overlapDays)
  }

define "2025Q1 Statistics":
  {
    quarter: '2025Q1',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2025Q1'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2025Q1' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q1'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q1' return PP.overlapDays)
  }

define "2025Q2 Statistics":
  {
    quarter: '2025Q2',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2025Q2'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2025Q2' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q2'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q2' return PP.overlapDays)
  }

define "2025Q3 Statistics":
  {
    quarter: '2025Q3',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2025Q3'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2025Q3' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q3'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q3' return PP.overlapDays)
  }

define "2025Q4 Statistics":
  {
    quarter: '2025Q4',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2025Q4'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2025Q4' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q4'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q4' return PP.overlapDays)
  }

define "2026Q1 Statistics":
  {
    quarter: '2026Q1',
    totalPrescriptions: Count("Outpatient BPH Prescriptions" P where P.quarter = '2026Q1'),
    totalDrugDays: Sum("Outpatient BPH Prescriptions" P where P.quarter = '2026Q1' return P.drugDays),
    crossHospitalPairs: Count("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2026Q1'),
    totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2026Q1' return PP.overlapDays)
  }

define "Quarterly Statistics":
  {
    "2024Q1 Statistics",
    "2024Q2 Statistics",
    "2024Q3 Statistics",
    "2024Q4 Statistics",
    "2025Q1 Statistics",
    "2025Q2 Statistics",
    "2025Q3 Statistics",
    "2025Q4 Statistics",
    "2026Q1 Statistics"
  }

// ========== 指標結果 ==========

define "Indicator Result":
  {
    indicatorCode: '3378',
    indicatorName: '跨醫院門診同藥理用藥日數重疊率-前列腺肥大藥物(口服)',
    indicatorNameEn: 'Cross-Hospital Outpatient BPH Drug Overlap Rate (Oral)',
    measurementPeriod: "Measurement Period",
    totalPrescriptions: Count("Outpatient BPH Prescriptions"),
    totalDrugDays: "Total Drug Days",
    totalOverlapDays: "Total Overlap Days",
    overlapRate: if "Total Drug Days" > 0 then ("Total Overlap Days" / "Total Drug Days") * 100 else null,
    quarterlyStatistics: "Quarterly Statistics",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    version: '1.0.0'
  }
