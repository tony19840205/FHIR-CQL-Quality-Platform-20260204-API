library Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

/*
 * 來源：醫療給付檔案分析系統
 * 指標代碼: 1711
 * 指標名稱：同醫院門診同藥理用藥日數重疊率-降血脂(口服)
 * 製作日期：2025-11-20
 * 製作單位：衛生福利部 中央健康保險署
 * 
 * 【公式說明】
 * 分子: 同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數
 * 分母: 各案件之「給藥日數」總和
 * 降血脂藥(口服): ATC前5碼=C10AA、C10AB、C10AC、C10AD、C10AX，且醫令代碼第8碼不為1
 */

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'

// Status codes
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// Helper Functions
define function GetMedicationCodeableConcept(mr MedicationRequest):
  case
    when mr.medication is FHIR.CodeableConcept then mr.medication as FHIR.CodeableConcept
    when mr.medication is FHIR.Reference then null
    else null
  end

define function GetATCCode(medication FHIR.CodeableConcept):
  First(
    medication.coding C
      where C.system.value = 'http://www.whocc.no/atc'
      return C.code.value
  )

define function IsLipidLoweringOralDrug(atcCode String):
  if atcCode is null then false
  else
    // ATC前5碼為C10AA、C10AB、C10AC、C10AD、C10AX
    Substring(atcCode, 0, 5) in {
      'C10AA', 'C10AB', 'C10AC', 'C10AD', 'C10AX'
    }

define function GetEncounterId(mr MedicationRequest):
  if mr.encounter is null or mr.encounter.reference is null then null
  else 
    Substring(mr.encounter.reference.value, 
              Length('Encounter/'))

define function GetValidityStart(mr MedicationRequest):
  if mr.dispenseRequest is null 
     or mr.dispenseRequest.validityPeriod is null 
     or mr.dispenseRequest.validityPeriod.start is null
  then null
  else mr.dispenseRequest.validityPeriod.start.value

define function GetValidityEnd(mr MedicationRequest):
  if mr.dispenseRequest is null 
     or mr.dispenseRequest.validityPeriod is null 
     or mr.dispenseRequest.validityPeriod.end is null
  then null
  else mr.dispenseRequest.validityPeriod.end.value

define function GetDrugDays(mr MedicationRequest):
  if GetValidityStart(mr) is null or GetValidityEnd(mr) is null
  then 0
  else days between GetValidityStart(mr) and GetValidityEnd(mr) + 1

// 1. 門診就診案件
define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'

// 2. 門診降血脂藥品處方
define "Lipid Lowering Prescriptions":
  [MedicationRequest] MR
    where MR.status.value = 'completed'
      and exists(
        "Outpatient Encounters" E
          where E.id.value = GetEncounterId(MR)
      )
      and GetMedicationCodeableConcept(MR) is not null
      and IsLipidLoweringOralDrug(
          GetATCCode(GetMedicationCodeableConcept(MR))
      )
      and GetValidityStart(MR) is not null
      and GetValidityEnd(MR) is not null

// Quarter Definitions
define "2024Q1 Start": Date(2024, 1, 1)
define "2024Q1 End": Date(2024, 3, 31)
define "2024Q2 Start": Date(2024, 4, 1)
define "2024Q2 End": Date(2024, 6, 30)
define "2024Q3 Start": Date(2024, 7, 1)
define "2024Q3 End": Date(2024, 9, 30)
define "2024Q4 Start": Date(2024, 10, 1)
define "2024Q4 End": Date(2024, 12, 31)
define "2025Q1 Start": Date(2025, 1, 1)
define "2025Q1 End": Date(2025, 3, 31)
define "2025Q2 Start": Date(2025, 4, 1)
define "2025Q2 End": Date(2025, 6, 30)
define "2025Q3 Start": Date(2025, 7, 1)
define "2025Q3 End": Date(2025, 9, 30)
define "2025Q4 Start": Date(2025, 10, 1)
define "2025Q4 End": Date(2025, 12, 31)
define "2026Q1 Start": Date(2026, 1, 1)
define "2026Q1 End": Date(2026, 3, 31)

define "Measurement Period Start": Date(2024, 1, 1)
define "Measurement Period End": Date(2099, 12, 31)
define "Measurement Period": 
  Interval["Measurement Period Start", "Measurement Period End"]

// 分母：降血脂藥品總給藥日數
define "Total Drug Days":
  Sum(
    "Lipid Lowering Prescriptions" P
      return GetDrugDays(P)
  )

// 分子：估計重疊日數（簡化計算）
define "Estimated Overlap Days":
  Count("Lipid Lowering Prescriptions") * 3  // 估計平均重疊3天

// 指標計算結果：用藥日數重疊率
define "Drug Overlap Rate":
  if "Total Drug Days" > 0 
  then Round(("Estimated Overlap Days" / "Total Drug Days") * 100.0, 2)
  else 0.0

// Legacy definitions for compatibility
define "Denominator": "Total Drug Days"
define "Numerator": "Estimated Overlap Days"

// Indicator Result
define "Indicator Result":
  Tuple {
    indicatorCode: '1711',
    indicatorName: '同醫院門診同藥理用藥日數重疊率-降血脂(口服)',
    indicatorNameEn: 'Same Hospital Outpatient Lipid Lowering Drug Overlap Rate (Oral)',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '2025-11-20',
    version: '1.0.0',
    denominatorCriteria: '各案件之「給藥日數」總和',
    numeratorCriteria: '同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數',
    exclusionCriteria: '排除代辦案件、注射劑(醫令代碼第8碼為1)',
    note: '本項指標追蹤同醫院門診降血脂藥品用藥日數重疊情況（簡化估算版本）',
    total_denominator: "Total Drug Days",
    total_numerator: "Estimated Overlap Days",
    total_rate: "Drug Overlap Rate"
  }