/**
 * 指標名稱: 牙周疾病控制基本處置執行率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 醫事機構全年申報牙周疾病控制基本處置的人數
 * 分母: 醫事機構全年申報全口牙結石清除人數
 * 
 * 分子條件: 牙周疾病控制基本處置健保代碼為 91014C、91114C
 * 分母條件: 全口牙結石清除健保代碼為 91004C、91104C
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Periodontal_Disease_Control_Basic_Treatment_Rate version '1.0.0'

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

// 牙周疾病控制基本處置代碼 (91014C、91114C)
define "Periodontal Disease Control Basic Treatment Codes": {
  Code { code: '91014C', system: "TWProcedure", display: '牙周疾病控制基本處置' },
  Code { code: '91114C', system: "TWProcedure", display: '牙周疾病控制基本處置-特殊' }
}

// 全口牙結石清除代碼 (91004C、91104C)
define "Full Mouth Calculus Removal Codes": {
  Code { code: '91004C', system: "TWProcedure", display: '全口牙結石清除' },
  Code { code: '91104C', system: "TWProcedure", display: '全口牙結石清除-特殊' }
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

// 檢查是否為牙周疾病控制基本處置
define function IsPeriodontalDiseaseControlBasicTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '91014C', '91114C' }

// 檢查是否為全口牙結石清除
define function IsFullMouthCalculusRemoval(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '91004C', '91104C' }

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

// 全口牙結石清除案件
define "Full Mouth Calculus Removal Procedures":
  "Procedures During Measurement Period" P
  where IsFullMouthCalculusRemoval(P)

// 牙周疾病控制基本處置案件
define "Periodontal Disease Control Basic Treatment Procedures":
  "Procedures During Measurement Period" P
  where IsPeriodontalDiseaseControlBasicTreatment(P)

// 分母: 全年申報全口牙結石清除的人數
define "Denominator":
  distinct (
    "Full Mouth Calculus Removal Procedures" P
    return {
      patient: GetPatientReference(P),
      organization: GetOrganization(P)
    }
  )

// 分子: 全年申報牙周疾病控制基本處置的人數
define "Numerator":
  distinct (
    "Periodontal Disease Control Basic Treatment Procedures" P
    return {
      patient: GetPatientReference(P),
      organization: GetOrganization(P)
    }
  )

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母人數
define "Denominator Count":
  Count(
    distinct (
      "Denominator" D return D.patient
    )
  )

// 分子人數
define "Numerator Count":
  Count(
    distinct (
      "Numerator" N return N.patient
    )
  )

// 執行率 (分子/分母)
define "Treatment Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層
define "Results By Organization":
  distinct (
    "Denominator" D return D.organization
  ) Org
  let orgDenominator: "Denominator" D where D.organization = Org,
      orgNumerator: "Numerator" N where N.organization = Org,
      orgDenominatorCount: Count(distinct (orgDenominator D return D.patient)),
      orgNumeratorCount: Count(distinct (orgNumerator N return N.patient)),
      orgTreatmentRate: if orgDenominatorCount > 0 
                        then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
                        else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    treatmentRate: orgTreatmentRate
  }

// 依處置類型分層 (分子)
define "Results By Treatment Type":
  "Periodontal Disease Control Basic Treatment Procedures" P
  let procedureCode: GetProcedureCode(P),
      treatmentType: 
        if procedureCode = '91014C' then '牙周疾病控制基本處置'
        else if procedureCode = '91114C' then '牙周疾病控制基本處置-特殊'
        else '未知'
  return {
    treatmentType: treatmentType,
    procedureCode: procedureCode
  }

// 依清除類型分層 (分母)
define "Results By Removal Type":
  "Full Mouth Calculus Removal Procedures" P
  let procedureCode: GetProcedureCode(P),
      removalType: 
        if procedureCode = '91004C' then '全口牙結石清除'
        else if procedureCode = '91104C' then '全口牙結石清除-特殊'
        else '未知'
  return {
    removalType: removalType,
    procedureCode: procedureCode
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, MeasurementPeriodStart),
      ageGroup: 
        if age < 20 then '<20歲'
        else if age < 30 then '20-29歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
        else if age < 70 then '60-69歲'
        else '>=70歲',
      inNumerator: D in ("Numerator" N where N.patient = D.patient)
  return {
    ageGroup: ageGroup,
    inNumerator: inNumerator
  }

// 依性別分層
define "Results By Gender":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      gender: patient.gender.value,
      inNumerator: D in ("Numerator" N where N.patient = D.patient)
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    inNumerator: inNumerator
  }

// 月度趨勢分析
define "Results By Month":
  "Denominator" D
  let procedures: "Full Mouth Calculus Removal Procedures" P
                  where GetPatientReference(P) = D.patient,
      firstProcedure: First(procedures P sort by (performed as FHIR.dateTime)),
      procedureDate: firstProcedure.performed as FHIR.dateTime,
      month: 
        if procedureDate is not null
        then ToString(month from procedureDate) + '月'
        else '未知',
      inNumerator: D in ("Numerator" N where N.patient = D.patient)
  return {
    month: month,
    inNumerator: inNumerator
  }

// 治療時間間隔分析 (從全口牙結石清除到牙周疾病控制基本處置的時間)
define "Treatment Time Interval Analysis":
  "Numerator" N
  let patient: N.patient,
      removalProcedures: "Full Mouth Calculus Removal Procedures" P
                         where GetPatientReference(P) = patient,
      controlProcedures: "Periodontal Disease Control Basic Treatment Procedures" P
                         where GetPatientReference(P) = patient,
      firstRemoval: First(removalProcedures P sort by (performed as FHIR.dateTime)),
      firstControl: First(controlProcedures P sort by (performed as FHIR.dateTime)),
      removalDate: firstRemoval.performed as FHIR.dateTime,
      controlDate: firstControl.performed as FHIR.dateTime,
      daysInterval: if removalDate is not null and controlDate is not null
                    then days between removalDate and controlDate
                    else null
  where daysInterval is not null
  return {
    patient: patient,
    daysInterval: daysInterval,
    weeksInterval: Round(daysInterval / 7.0, 1),
    intervalCategory: 
      if daysInterval <= 7 then '1週內'
      else if daysInterval <= 14 then '1-2週'
      else if daysInterval <= 30 then '2週-1個月'
      else if daysInterval <= 90 then '1-3個月'
      else '3個月以上'
  }

// 未執行牙周疾病控制基本處置的患者
define "Patients Without Control Treatment":
  "Denominator" D
  where not exists(
    "Numerator" N where N.patient = D.patient
  )
  return {
    patient: D.patient,
    organization: D.organization
  }

// 治療完整度分析 (是否兩種處置都有執行)
define "Treatment Completeness":
  distinct (
    "Denominator" D return D.patient
  ) PatientRef
  let removalCount: Count(
        "Full Mouth Calculus Removal Procedures" P
        where GetPatientReference(P) = PatientRef
      ),
      controlCount: Count(
        "Periodontal Disease Control Basic Treatment Procedures" P
        where GetPatientReference(P) = PatientRef
      ),
      hasControl: controlCount > 0
  return {
    patient: PatientRef,
    removalCount: removalCount,
    controlCount: controlCount,
    completeness: 
      if hasControl and removalCount > 0 then '完整治療'
      else '僅清除未控制'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '牙周疾病控制基本處置執行率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '全年申報牙周疾病控制基本處置的人數',
    numeratorCodes: '91014C, 91114C',
    denominator: "Denominator Count",
    denominatorDefinition: '全年申報全口牙結石清除人數',
    denominatorCodes: '91004C, 91104C',
    treatmentRate: "Treatment Rate",
    patientsWithoutControlTreatment: Count("Patients Without Control Treatment"),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
