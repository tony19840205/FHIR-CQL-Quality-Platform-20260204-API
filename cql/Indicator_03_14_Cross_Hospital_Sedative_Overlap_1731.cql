library Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 跨醫院門診同藥理用藥日數重疊率-安眠鎮靜(口服)
// 指標代碼: 1731
// 製作日期：2026-01-09
// 製表日期: 114/05/13
// 製表單位: 衛生福利部 中央健康保險署
// 
// 【資料時間範圍】
// 查詢期間: 2024-01-01 ~ 2099-12-31 (無限制)
// 統計單位: 每季 (2024Q1-Q4, 2025Q1-Q4, 2026Q1)
// ============================================
//
// 【資料範圍】
// (1)醫院總額之門診處方安眠鎮靜藥物(口服)案件
// (2)排除代辦案件
//
// 【公式說明】(依健保指標代碼 1731)
// 跨醫院門診同藥理用藥日數重疊率-安眠鎮靜藥物(口服) = 
//     分子: 全國跨院同ID不同處方之開始用藥日期與結束用藥日期間有重疊之給藥日數(允許遞延早拿藥)
//     分母: 各案件之「給藥日數」總和
// 
// (1)「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，若為空值則抓清單檔之給藥日份(DRUG_DAYS)
// (2)限制口服劑型
// (3)安眠鎮靜藥物: N05C (Hypnotics and sedatives) 和 N05B (Anxiolytics)
// 
// 排除條件:
//   1.排除代辦案件
//   2.限制口服劑型
//
// 【重點差異】
//   與指標8(同院門診)不同，本指標計算「跨醫院」的用藥重疊
//   即：同一病患在不同醫院就診時的安眠鎮靜藥物(口服)重疊情況
// ============================================

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

valueset "Sedative Hypnotic ATC Codes": 'http://nhi.gov.tw/fhir/ValueSet/sedative-hypnotic-atc-codes'

code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// ATC Codes for Sedative-Hypnotic Drugs (安眠鎮靜藥物)
// N05C: Hypnotics and sedatives (安眠藥物)
code "N05CA": 'N05CA' from "ATC" display 'Barbiturates, plain - 巴比妥類單方'
code "N05CB": 'N05CB' from "ATC" display 'Barbiturates, combinations - 巴比妥類複方'
code "N05CC": 'N05CC' from "ATC" display 'Aldehydes and derivatives - 醛類及其衍生物'
code "N05CD": 'N05CD' from "ATC" display 'Benzodiazepine derivatives - 苯二氮平類衍生物'
code "N05CF": 'N05CF' from "ATC" display 'Benzodiazepine related drugs - 苯二氮平相關藥物'
code "N05CH": 'N05CH' from "ATC" display 'Melatonin receptor agonists - 褪黑激素受體促效劑'
code "N05CM": 'N05CM' from "ATC" display 'Other hypnotics and sedatives - 其他安眠鎮靜藥物'

// N05B: Anxiolytics (抗焦慮/鎮靜藥物)
code "N05BA": 'N05BA' from "ATC" display 'Benzodiazepine derivatives - 苯二氮平類衍生物(抗焦慮)'
code "N05BB": 'N05BB' from "ATC" display 'Diphenylmethane derivatives - 二苯甲烷衍生物'
code "N05BC": 'N05BC' from "ATC" display 'Carbamates - 氨基甲酸酯類'
code "N05BD": 'N05BD' from "ATC" display 'Dibenzo-bicyclo-octadiene derivatives - 二苯並雙環辛二烯衍生物'
code "N05BE": 'N05BE' from "ATC" display 'Azaspirodecanedione derivatives - 氮雜螺癸二酮衍生物'
code "N05BX": 'N05BX' from "ATC" display 'Other anxiolytics - 其他抗焦慮藥物'

code "Oral": '385268001' from "SNOMEDCT" display 'Oral dose form - 口服劑型'

// ============================================
// Quarter Definitions (2024-2026)
// ============================================

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

// Measurement Period (無限制 - Unlimited)
define "Measurement Period Start": @2024-01-01
define "Measurement Period End": @2099-12-31
define "Measurement Period": Interval["Measurement Period Start", "Measurement Period End"]

// ============================================
// Helper Functions
// ============================================

define function GetId(resource FHIR.Resource):
  Last(Split(resource.id, '/'))

define function GetATCCodePrefix5(atcCode String):
  if Length(atcCode) >= 5 then Substring(atcCode, 0, 5)
  else atcCode

define function GetATCCode(medicationRequest FHIR.MedicationRequest):
  if medicationRequest.medication is FHIR.CodeableConcept then
    Coalesce(
      First((medicationRequest.medication as FHIR.CodeableConcept).coding C 
        where C.system = 'http://www.whocc.no/atc'
      ).code.value,
      ''
    )
  else ''

define function IsSedativeHypnoticATC(atcCode String):
  GetATCCodePrefix5(atcCode) in {
    'N05CA', 'N05CB', 'N05CC', 'N05CD', 'N05CF', 'N05CH', 'N05CM',  // Hypnotics
    'N05BA', 'N05BB', 'N05BC', 'N05BD', 'N05BE', 'N05BX'             // Anxiolytics
  }

define function GetATCClassName(atcCode String):
  case GetATCCodePrefix5(atcCode)
    when 'N05CA' then 'Barbiturates, plain - 巴比妥類單方'
    when 'N05CB' then 'Barbiturates, combinations - 巴比妥類複方'
    when 'N05CC' then 'Aldehydes and derivatives - 醛類及其衍生物'
    when 'N05CD' then 'Benzodiazepine derivatives - 苯二氮平類衍生物'
    when 'N05CF' then 'Benzodiazepine related drugs - 苯二氮平相關藥物'
    when 'N05CH' then 'Melatonin receptor agonists - 褪黑激素受體促效劑'
    when 'N05CM' then 'Other hypnotics and sedatives - 其他安眠鎮靜藥物'
    when 'N05BA' then 'Benzodiazepine derivatives (Anxiolytic) - 苯二氮平類衍生物(抗焦慮)'
    when 'N05BB' then 'Diphenylmethane derivatives - 二苯甲烷衍生物'
    when 'N05BC' then 'Carbamates - 氨基甲酸酯類'
    when 'N05BD' then 'Dibenzo-bicyclo-octadiene derivatives - 二苯並雙環辛二烯衍生物'
    when 'N05BE' then 'Azaspirodecanedione derivatives - 氮雜螺癸二酮衍生物'
    when 'N05BX' then 'Other anxiolytics - 其他抗焦慮藥物'
    else 'Unknown'
  end

define function GetDosageFormType(medicationRequest FHIR.MedicationRequest):
  if medicationRequest.medication is FHIR.CodeableConcept then
    Coalesce(
      First((medicationRequest.medication as FHIR.CodeableConcept).coding C 
        where C.system = 'http://snomed.info/sct'
      ).code.value,
      ''
    )
  else ''

define function IsOralDosageForm(medicationRequest FHIR.MedicationRequest):
  GetDosageFormType(medicationRequest) = '385268001'

define function GetDrugDays(medicationRequest FHIR.MedicationRequest):
  Coalesce(
    medicationRequest.dispenseRequest.expectedSupplyDuration.value.value,
    medicationRequest.dispenseRequest.quantity.value.value,
    0
  )

define function GetOrganizationId(encounter FHIR.Encounter):
  if encounter.serviceProvider is not null then
    GetId(encounter.serviceProvider.reference)
  else ''

define function IsAgencyCase(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
        and E.value = true
  )

// ============================================
// Data Retrieval
// ============================================

context Patient

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and start of E.period in "Measurement Period"
      and not IsAgencyCase(E)

define "All Medication Requests":
  [MedicationRequest] MR
    where MR.status.value in {'active', 'completed'}
      and MR.intent.value = 'order'
      and MR.authoredOn in "Measurement Period"

define "Sedative Hypnotic Medication Requests":
  "All Medication Requests" MR
    where IsSedativeHypnoticATC(GetATCCode(MR))
      and IsOralDosageForm(MR)
      and GetDrugDays(MR) > 0

// ============================================
// Cross-Hospital Overlap Analysis
// ============================================

define "Cross Hospital Sedative Pairs":
  from "Sedative Hypnotic Medication Requests" MR1,
       "Sedative Hypnotic Medication Requests" MR2,
       "Outpatient Encounters" E1,
       "Outpatient Encounters" E2
    where GetId(MR1.encounter.reference) = GetId(E1)
      and GetId(MR2.encounter.reference) = GetId(E2)
      and GetOrganizationId(E1) != GetOrganizationId(E2)
      and GetId(MR1) < GetId(MR2)
    return {
      organizationId1: GetOrganizationId(E1),
      organizationId2: GetOrganizationId(E2),
      drugName1: (MR1.medication as FHIR.CodeableConcept).text.value,
      drugName2: (MR2.medication as FHIR.CodeableConcept).text.value,
      atcCode1: GetATCCode(MR1),
      atcCode2: GetATCCode(MR2),
      atcClass1: GetATCClassName(GetATCCode(MR1)),
      atcClass2: GetATCClassName(GetATCCode(MR2)),
      drugDays1: GetDrugDays(MR1),
      drugDays2: GetDrugDays(MR2),
      startDate1: MR1.authoredOn.value,
      startDate2: MR2.authoredOn.value
    }

// ============================================
// 2024Q1 Statistics
// ============================================

define "2024Q1 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2024Q1 Start", "2024Q1 End"]

define "2024Q1 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2024Q1 Start", "2024Q1 End"]
      or P.startDate2 in Interval["2024Q1 Start", "2024Q1 End"]

define "2024Q1 Total Drug Days":
  Sum("2024Q1 Sedative Requests" MR return GetDrugDays(MR))

define "2024Q1 Cross Hospital Overlap Count":
  Count("2024Q1 Cross Hospital Pairs")

// ============================================
// 2024Q2 Statistics
// ============================================

define "2024Q2 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2024Q2 Start", "2024Q2 End"]

define "2024Q2 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2024Q2 Start", "2024Q2 End"]
      or P.startDate2 in Interval["2024Q2 Start", "2024Q2 End"]

define "2024Q2 Total Drug Days":
  Sum("2024Q2 Sedative Requests" MR return GetDrugDays(MR))

define "2024Q2 Cross Hospital Overlap Count":
  Count("2024Q2 Cross Hospital Pairs")

// ============================================
// 2024Q3 Statistics
// ============================================

define "2024Q3 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2024Q3 Start", "2024Q3 End"]

define "2024Q3 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2024Q3 Start", "2024Q3 End"]
      or P.startDate2 in Interval["2024Q3 Start", "2024Q3 End"]

define "2024Q3 Total Drug Days":
  Sum("2024Q3 Sedative Requests" MR return GetDrugDays(MR))

define "2024Q3 Cross Hospital Overlap Count":
  Count("2024Q3 Cross Hospital Pairs")

// ============================================
// 2024Q4 Statistics
// ============================================

define "2024Q4 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2024Q4 Start", "2024Q4 End"]

define "2024Q4 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2024Q4 Start", "2024Q4 End"]
      or P.startDate2 in Interval["2024Q4 Start", "2024Q4 End"]

define "2024Q4 Total Drug Days":
  Sum("2024Q4 Sedative Requests" MR return GetDrugDays(MR))

define "2024Q4 Cross Hospital Overlap Count":
  Count("2024Q4 Cross Hospital Pairs")

// ============================================
// 2025Q1 Statistics
// ============================================

define "2025Q1 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2025Q1 Start", "2025Q1 End"]

define "2025Q1 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2025Q1 Start", "2025Q1 End"]
      or P.startDate2 in Interval["2025Q1 Start", "2025Q1 End"]

define "2025Q1 Total Drug Days":
  Sum("2025Q1 Sedative Requests" MR return GetDrugDays(MR))

define "2025Q1 Cross Hospital Overlap Count":
  Count("2025Q1 Cross Hospital Pairs")

// ============================================
// 2025Q2 Statistics
// ============================================

define "2025Q2 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2025Q2 Start", "2025Q2 End"]

define "2025Q2 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2025Q2 Start", "2025Q2 End"]
      or P.startDate2 in Interval["2025Q2 Start", "2025Q2 End"]

define "2025Q2 Total Drug Days":
  Sum("2025Q2 Sedative Requests" MR return GetDrugDays(MR))

define "2025Q2 Cross Hospital Overlap Count":
  Count("2025Q2 Cross Hospital Pairs")

// ============================================
// 2025Q3 Statistics
// ============================================

define "2025Q3 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2025Q3 Start", "2025Q3 End"]

define "2025Q3 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2025Q3 Start", "2025Q3 End"]
      or P.startDate2 in Interval["2025Q3 Start", "2025Q3 End"]

define "2025Q3 Total Drug Days":
  Sum("2025Q3 Sedative Requests" MR return GetDrugDays(MR))

define "2025Q3 Cross Hospital Overlap Count":
  Count("2025Q3 Cross Hospital Pairs")

// ============================================
// 2025Q4 Statistics
// ============================================

define "2025Q4 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2025Q4 Start", "2025Q4 End"]

define "2025Q4 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2025Q4 Start", "2025Q4 End"]
      or P.startDate2 in Interval["2025Q4 Start", "2025Q4 End"]

define "2025Q4 Total Drug Days":
  Sum("2025Q4 Sedative Requests" MR return GetDrugDays(MR))

define "2025Q4 Cross Hospital Overlap Count":
  Count("2025Q4 Cross Hospital Pairs")

// ============================================
// 2026Q1 Statistics
// ============================================

define "2026Q1 Sedative Requests":
  "Sedative Hypnotic Medication Requests" MR
    where MR.authoredOn.value in Interval["2026Q1 Start", "2026Q1 End"]

define "2026Q1 Cross Hospital Pairs":
  "Cross Hospital Sedative Pairs" P
    where P.startDate1 in Interval["2026Q1 Start", "2026Q1 End"]
      or P.startDate2 in Interval["2026Q1 Start", "2026Q1 End"]

define "2026Q1 Total Drug Days":
  Sum("2026Q1 Sedative Requests" MR return GetDrugDays(MR))

define "2026Q1 Cross Hospital Overlap Count":
  Count("2026Q1 Cross Hospital Pairs")

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  {
    indicatorCode: '1731',
    indicatorName: '跨醫院門診同藥理用藥日數重疊率-安眠鎮靜藥物(口服)',
    indicatorNameEn: 'Cross-Hospital Outpatient Sedative-Hypnotic Drug Overlap Rate (Oral)',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/05/13',
    version: '1.0.0',
    keyFeature: '跨醫院用藥重疊分析 (P1.organizationId != P2.organizationId, N05B+N05C共13類ATC, 口服劑型)'
  }
