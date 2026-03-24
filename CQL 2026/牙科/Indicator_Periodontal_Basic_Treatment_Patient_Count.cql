/**
 * 指標名稱: 執行牙周病基礎治療之人數
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 指標類型: 統計數量指標 (非比率型)
 * 
 * 指標定義: 醫事機構該季18歲以上執行牙周病治療相關醫令的人數
 * 
 * 牙周病治療相關醫令為91006C、91007C、91008C、P4001C、P4002C、P4003C
 * 
 * 用途:
 * - 評估醫療機構牙周病基礎治療服務提供情況
 * - 了解成人牙周病患者接受治療的涵蓋率
 * - 作為口腔健康促進計畫的參考指標
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Periodontal_Basic_Treatment_Patient_Count version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 牙周病治療相關醫令代碼
define "Periodontal Treatment Procedure Codes": {
  Code { code: '91006C', system: "TWProcedure", display: '牙周病治療-牙結石清除(全口)' },
  Code { code: '91007C', system: "TWProcedure", display: '牙周病治療-牙根整平術' },
  Code { code: '91008C', system: "TWProcedure", display: '牙周病治療-牙周翻瓣手術' },
  Code { code: 'P4001C', system: "TWProcedure", display: '牙周病治療-牙周病統合照護計畫第一階段' },
  Code { code: 'P4002C', system: "TWProcedure", display: '牙周病治療-牙周病統合照護計畫第二階段' },
  Code { code: 'P4003C', system: "TWProcedure", display: '牙周病治療-牙周病統合照護計畫第三階段' }
}

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Procedure的處置代碼
define function GetProcedureCode(procedure Procedure):
  if procedure.code is not null 
  then (procedure.code.coding[0].code.value)
  else null

// 取得Procedure的醫療機構
define function GetOrganization(procedure Procedure):
  if procedure.performer is not null and Count(procedure.performer) > 0
  then (procedure.performer[0].actor.reference.value)
  else null

// 取得Patient Reference
define function GetPatientReference(procedure Procedure):
  procedure.subject.reference.value

// 檢查是否為牙周病治療
define function IsPeriodontalTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in {
    '91006C', '91007C', '91008C',
    'P4001C', 'P4002C', 'P4003C'
  }

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 觀察期間的所有Procedure
define "Procedures During Measurement Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'

// 牙周病治療案件
define "Periodontal Treatment Procedures":
  "Procedures During Measurement Period" P
  where IsPeriodontalTreatment(P)

// 18歲以上接受牙周病治療的病患
define "Adult Patients With Periodontal Treatment":
  distinct (
    "Periodontal Treatment Procedures" P
    let patientRef: GetPatientReference(P),
        patient: singleton from ([Patient] Pat where 'Patient/' + Pat.id = patientRef),
        birthDate: patient.birthDate.value,
        age: AgeInYearsAt(birthDate, P.performed as FHIR.dateTime)
    where age >= 18
    return {
      patientRef: patientRef,
      organization: GetOrganization(P),
      patient: patient
    }
  )

// ========================================================================================
// 指標計算
// ========================================================================================

// 總人數 (18歲以上執行牙周病治療的人數)
define "Total Patient Count":
  Count(
    distinct (
      "Adult Patients With Periodontal Treatment" A
      return A.patientRef
    )
  )

// 總治療次數
define "Total Treatment Count":
  Count(
    "Periodontal Treatment Procedures" P
    let patientRef: GetPatientReference(P),
        patient: singleton from ([Patient] Pat where 'Patient/' + Pat.id = patientRef),
        birthDate: patient.birthDate.value,
        age: AgeInYearsAt(birthDate, P.performed as FHIR.dateTime)
    where age >= 18
  )

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別統計
define "Count By Organization":
  distinct (
    "Adult Patients With Periodontal Treatment" A return A.organization
  ) Org
  let orgPatients: "Adult Patients With Periodontal Treatment" A 
                   where A.organization = Org,
      orgProcedures: "Periodontal Treatment Procedures" P
                     where GetOrganization(P) = Org,
      orgPatientCount: Count(distinct (orgPatients A return A.patientRef)),
      orgTreatmentCount: Count(orgProcedures)
  return {
    organization: Org,
    patientCount: orgPatientCount,
    treatmentCount: orgTreatmentCount,
    averageTreatmentsPerPatient: if orgPatientCount > 0
                                  then Round(orgTreatmentCount / orgPatientCount, 2)
                                  else null
  }

// 依治療類型統計
define "Count By Treatment Type":
  "Periodontal Treatment Procedures" P
  let patientRef: GetPatientReference(P),
      patient: singleton from ([Patient] Pat where 'Patient/' + Pat.id = patientRef),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, P.performed as FHIR.dateTime),
      procedureCode: GetProcedureCode(P),
      treatmentType: 
        if procedureCode = '91006C' then '牙結石清除(全口)'
        else if procedureCode = '91007C' then '牙根整平術'
        else if procedureCode = '91008C' then '牙周翻瓣手術'
        else if procedureCode = 'P4001C' then '牙周病統合照護-第一階段'
        else if procedureCode = 'P4002C' then '牙周病統合照護-第二階段'
        else if procedureCode = 'P4003C' then '牙周病統合照護-第三階段'
        else '未知'
  where age >= 18
  return {
    treatmentType: treatmentType,
    procedureCode: procedureCode
  }

// 依患者年齡分層
define "Count By Patient Age":
  "Adult Patients With Periodontal Treatment" A
  let birthDate: A.patient.birthDate.value,
      age: AgeInYearsAt(birthDate, MeasurementPeriodStart),
      ageGroup: 
        if age < 30 then '18-29歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
        else if age < 70 then '60-69歲'
        else '>=70歲'
  return {
    ageGroup: ageGroup,
    organization: A.organization
  }

// 依性別分層
define "Count By Gender":
  "Adult Patients With Periodontal Treatment" A
  let gender: A.patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    organization: A.organization
  }

// 治療階段完成情況 (針對牙周病統合照護計畫)
define "Integrated Care Program Progress":
  distinct (
    "Periodontal Treatment Procedures" P
    let patientRef: GetPatientReference(P)
    where GetProcedureCode(P) in { 'P4001C', 'P4002C', 'P4003C' }
    return patientRef
  ) PatientRef
  let patient: singleton from ([Patient] Pat where 'Patient/' + Pat.id = PatientRef),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, MeasurementPeriodStart),
      procedures: "Periodontal Treatment Procedures" P
                  where GetPatientReference(P) = PatientRef
                  and GetProcedureCode(P) in { 'P4001C', 'P4002C', 'P4003C' },
      hasPh1: exists(procedures P where GetProcedureCode(P) = 'P4001C'),
      hasPh2: exists(procedures P where GetProcedureCode(P) = 'P4002C'),
      hasPh3: exists(procedures P where GetProcedureCode(P) = 'P4003C')
  where age >= 18
  return {
    patient: PatientRef,
    phase1Completed: hasPh1,
    phase2Completed: hasPh2,
    phase3Completed: hasPh3,
    completionStatus: 
      if hasPh1 and hasPh2 and hasPh3 then '完成三階段'
      else if hasPh1 and hasPh2 then '完成兩階段'
      else if hasPh1 then '完成第一階段'
      else '進行中'
  }

// 月度趨勢分析
define "Count By Month":
  "Periodontal Treatment Procedures" P
  let patientRef: GetPatientReference(P),
      patient: singleton from ([Patient] Pat where 'Patient/' + Pat.id = patientRef),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, P.performed as FHIR.dateTime),
      procedureDate: P.performed as FHIR.dateTime,
      month: 
        if procedureDate is not null
        then ToString(month from procedureDate) + '月'
        else '未知'
  where age >= 18
  return {
    month: month,
    organization: GetOrganization(P)
  }

// 每位患者接受治療次數分析
define "Treatment Frequency Per Patient":
  distinct (
    "Adult Patients With Periodontal Treatment" A return A.patientRef
  ) PatientRef
  let procedures: "Periodontal Treatment Procedures" P
                  where GetPatientReference(P) = PatientRef,
      treatmentCount: Count(procedures),
      distinctTreatmentTypes: Count(distinct (procedures P return GetProcedureCode(P)))
  return {
    patient: PatientRef,
    treatmentCount: treatmentCount,
    distinctTreatmentTypes: distinctTreatmentTypes,
    frequency: 
      if treatmentCount = 1 then '單次治療'
      else if treatmentCount <= 3 then '2-3次治療'
      else if treatmentCount <= 5 then '4-5次治療'
      else '6次以上治療'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '執行牙周病基礎治療之人數',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    indicatorType: '統計數量指標',
    ageRequirement: '18歲以上',
    totalPatientCount: "Total Patient Count",
    totalTreatmentCount: "Total Treatment Count",
    averageTreatmentsPerPatient: if "Total Patient Count" > 0
                                  then Round("Total Treatment Count" / "Total Patient Count", 2)
                                  else null,
    procedureCodes: '91006C, 91007C, 91008C, P4001C, P4002C, P4003C',
    unit: '人數',
    note: '統計該季18歲以上執行牙周病治療相關醫令的人數'
  }
