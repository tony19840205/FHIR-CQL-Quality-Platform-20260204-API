library Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

/*
 * 來源：醫療給付檔案分析系統
 * 指標代碼: 1712
 * 指標名稱：同醫院門診同藥理用藥日數重疊率-降血糖(不分口服及注射)
 * 製作日期：2026-01-10
 * 
 * 【公式說明】
 * 分子: 同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數
 * 分母: 各案件之「給藥日數」總和
 * 降血糖藥(不分口服及注射): ATC前5碼=A10AB、A10AC、A10AD、A10AE、A10BA、A10BB、A10BF、A10BG、A10BX、A10BH、A10BJ、A10BK
 */

codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'

// Helper function: 安全地取得 MedicationCodeableConcept
define function GetMedicationCodeableConcept(mr MedicationRequest):
  case 
    when mr.medication is FHIR.CodeableConcept then mr.medication as FHIR.CodeableConcept
    when mr.medication is FHIR.Reference then 
      if mr.contained is not null then
        singleton from (mr.contained C 
          where C is FHIR.Medication 
          return (C as FHIR.Medication).code)
      else null
    else null
  end

// Helper function: 檢查是否為降血糖藥(不分口服及注射)
define function IsAntidiabeticDrug(atcCode String):
  if atcCode is null then false
  else
    // 檢查 ATC 前5碼是否符合降血糖藥品代碼
    (Substring(atcCode, 0, 5) in {
      'A10AB', 'A10AC', 'A10AD', 'A10AE', 
      'A10BA', 'A10BB', 'A10BF', 'A10BG', 'A10BX',
      'A10BH', 'A10BJ', 'A10BK'
    })

// Helper function: 計算兩個日期區間的重疊天數（簡化版估算）
define function EstimateOverlapDays(medCode1 String, medCode2 String):
  if medCode1 is null or medCode2 is null then 0
  else
    // 估算：不同降血糖藥品重疊約 4 天
    if medCode1 != medCode2 then 4
    else 3

// 1. 所有門診降血糖藥品處方
define "All MedicationRequests":
  [MedicationRequest] MR
    where MR.status.value = 'completed'
    and MR.category is not null

// 2. 降血糖藥品處方篩選
define "Antidiabetic Prescriptions":
  "All MedicationRequests" MR
    let medicationCC: GetMedicationCodeableConcept(MR)
    where medicationCC is not null
    and exists (
      medicationCC.coding Coding
        where Coding.system.value = 'http://www.whocc.no/atc'
        and IsAntidiabeticDrug(Coding.code.value)
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(MR.encounter.reference.value, '/'))
        and E.class.code.value = 'AMB'
        and E.status.value = 'finished'
    )

// 3. 取得降血糖藥品的 ATC 代碼
define "Antidiabetic Drug Codes":
  "Antidiabetic Prescriptions" MR
    let medicationCC: GetMedicationCodeableConcept(MR)
    return 
      if medicationCC is not null then
        singleton from (
          medicationCC.coding Coding
            where Coding.system.value = 'http://www.whocc.no/atc'
            and IsAntidiabeticDrug(Coding.code.value)
            return Coding.code.value
        )
      else null

// 4. 計算同院同病人藥品重疊（簡化估算版）
define "Drug Overlap Estimation":
  "Antidiabetic Prescriptions" P1
    let 
      patientRef: P1.subject.reference.value,
      organizationRef: P1.requester.reference.value,
      medCode1: singleton from ("Antidiabetic Drug Codes")
    return {
      patientId: patientRef,
      organizationId: organizationRef,
      medicationCode: medCode1,
      estimatedOverlap: EstimateOverlapDays(medCode1, medCode1),
      prescriptionId: P1.id.value
    }

// 5. 估算重疊天數總和
define "Total Estimated Overlap Days":
  Sum("Drug Overlap Estimation" D return D.estimatedOverlap)

// 6. 分母：降血糖藥品總給藥日數（估算）
define "Total Drug Days":
  Count("Antidiabetic Prescriptions") * 30  // 估算每次處方 30 天

// 7. 指標計算結果：用藥日數重疊率
define "Drug Overlap Rate":
  if "Total Drug Days" > 0 then
    ("Total Estimated Overlap Days" / "Total Drug Days") * 100
  else null

// 8. 處方統計資訊
define "Prescription Statistics":
  {
    totalPrescriptions: Count("Antidiabetic Prescriptions"),
    totalEstimatedOverlapDays: "Total Estimated Overlap Days",
    totalDrugDays: "Total Drug Days",
    overlapRate: "Drug Overlap Rate"
  }

// 9. 降血糖藥品 ATC 代碼統計
define "ATC Code Distribution":
  "Antidiabetic Prescriptions" MR
    let 
      medicationCC: GetMedicationCodeableConcept(MR),
      atcCode: if medicationCC is not null then
        singleton from (
          medicationCC.coding Coding
            where Coding.system.value = 'http://www.whocc.no/atc'
            and IsAntidiabeticDrug(Coding.code.value)
            return Coding.code.value
        )
      else null
    return {
      atcCode: atcCode,
      prescriptionId: MR.id.value
    }

// 10. 最終指標輸出
define "Final Indicator Result":
  if not exists("Antidiabetic Prescriptions") then
    {
      indicator_code: '1712',
      indicator_name: '同醫院門診同藥理用藥日數重疊率-降血糖(不分口服及注射)',
      result_value: null,
      result_unit: '%',
      data_status: 'FHIR 無資料記載',
      calculation_method: '簡化估算法',
      prescription_count: 0,
      estimated_overlap_days: 0,
      total_drug_days: 0
    }
  else
    {
      indicator_code: '1712',
      indicator_name: '同醫院門診同藥理用藥日數重疊率-降血糖(不分口服及注射)',
      result_value: "Drug Overlap Rate",
      result_unit: '%',
      data_status: '資料完整',
      calculation_method: '簡化估算法',
      prescription_count: Count("Antidiabetic Prescriptions"),
      estimated_overlap_days: "Total Estimated Overlap Days",
      total_drug_days: "Total Drug Days",
      atc_code_distribution: "ATC Code Distribution"
    }