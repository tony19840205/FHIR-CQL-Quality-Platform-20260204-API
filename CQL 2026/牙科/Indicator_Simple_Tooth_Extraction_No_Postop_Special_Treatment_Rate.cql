/**
 * 指標名稱: 簡單性拔牙執行後三十日以內不需要術後特別處理之比率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: [1-(分子/分母)] x 100%
 * 
 * 分子: 簡單拔牙後30天內再申報拔牙後特別處理的牙齒顆數
 * 分母: 簡單拔牙的牙齒顆數
 * 
 * 追蹤期: 拔牙後30天內
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Simple_Tooth_Extraction_No_Postop_Special_Treatment_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 簡單性拔牙代碼（單純齒切除術）
define "Simple Tooth Extraction Codes": {
  Code { code: '92015C', system: "TWProcedure", display: '單純齒切除術' }
}

// 拔牙後特別處理代碼（可能包含止血、縫合、感染處理等）
define "Postoperative Special Treatment Codes": {
  Code { code: '92016C', system: "TWProcedure", display: '拔牙後特別處理' },
  Code { code: '92017C', system: "TWProcedure", display: '拔牙後止血處理' },
  Code { code: '92018C', system: "TWProcedure", display: '拔牙後縫合' },
  Code { code: '92019C', system: "TWProcedure", display: '拔牙後感染處理' },
  Code { code: '92020C', system: "TWProcedure", display: '拔牙窩特別處理' }
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

// 取得牙位號碼（從Procedure的bodySite或extension）
define function GetToothNumber(procedure Procedure):
  if procedure.bodySite is not null and Count(procedure.bodySite) > 0
  then GetExtensionString(procedure.bodySite[0], 'toothNumber')
  else GetExtensionString(procedure, 'toothNumber')

// 檢查是否為簡單拔牙
define function IsSimpleToothExtraction(procedure Procedure):
  GetProcedureCode(procedure) = '92015C'

// 檢查是否為術後特別處理
define function IsPostoperativeSpecialTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '92016C', '92017C', '92018C', '92019C', '92020C' }

// 建立唯一牙位識別碼
define function GetUniqueToothIdentifier(organization String, patient String, toothNumber String):
  organization + '|' + patient + '|' + Coalesce(toothNumber, 'unknown')

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

// 所有Procedure (包含觀察期後30天，用於追蹤術後處理)
define "All Procedures For Tracking":
  [Procedure] P
  where P.performed during Interval[MeasurementPeriodStart, MeasurementPeriodEnd + 30 days]
  and P.status.value = 'completed'

// 簡單拔牙處置 (分母)
define "Simple Tooth Extraction Procedures":
  "Procedures During Measurement Period" P
  where IsSimpleToothExtraction(P)
  return {
    procedureId: 'Procedure/' + P.id,
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    toothNumber: GetToothNumber(P),
    procedureDate: P.performed as FHIR.dateTime,
    uniqueToothId: GetUniqueToothIdentifier(
      GetOrganization(P), 
      GetPatientReference(P), 
      GetToothNumber(P)
    )
  }

// 術後特別處理案件
define "Postoperative Special Treatment Procedures":
  "All Procedures For Tracking" P
  where IsPostoperativeSpecialTreatment(P)
  return {
    procedureId: 'Procedure/' + P.id,
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    toothNumber: GetToothNumber(P),
    procedureCode: GetProcedureCode(P),
    procedureDate: P.performed as FHIR.dateTime,
    uniqueToothId: GetUniqueToothIdentifier(
      GetOrganization(P), 
      GetPatientReference(P), 
      GetToothNumber(P)
    )
  }

// 分母: 簡單拔牙的牙齒顆數
define "Denominator":
  "Simple Tooth Extraction Procedures"

// 分子: 拔牙後30天內需要術後特別處理的牙齒顆數
define "Numerator":
  "Simple Tooth Extraction Procedures" Extraction
  where exists(
    "Postoperative Special Treatment Procedures" Treatment
    where Treatment.uniqueToothId = Extraction.uniqueToothId
    and Treatment.procedureDate > Extraction.procedureDate
    and Treatment.procedureDate <= Extraction.procedureDate + 30 days
  )
  return Extraction

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母牙齒顆數
define "Denominator Count":
  Count("Denominator")

// 分子牙齒顆數（需要術後處理）
define "Numerator Count":
  Count("Numerator")

// 不需要術後特別處理的牙齒顆數
define "No Special Treatment Count":
  "Denominator Count" - "Numerator Count"

// 不需要術後特別處理之比率 [1-(分子/分母)]×100%
define "No Special Treatment Rate":
  if "Denominator Count" > 0 
  then Round((1.0 - ("Numerator Count" / "Denominator Count")) * 100.0, 2)
  else null

// 需要術後特別處理之比率
define "Special Treatment Rate":
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
      orgDenominatorCount: Count(orgDenominator),
      orgNumeratorCount: Count(orgNumerator),
      orgNoTreatmentRate: if orgDenominatorCount > 0 
                          then Round((1.0 - (orgNumeratorCount / orgDenominatorCount)) * 100.0, 2)
                          else null
  return {
    organization: Org,
    totalExtractions: orgDenominatorCount,
    needSpecialTreatment: orgNumeratorCount,
    noSpecialTreatment: orgDenominatorCount - orgNumeratorCount,
    noSpecialTreatmentRate: orgNoTreatmentRate
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, D.procedureDate),
      ageGroup: 
        if age < 18 then '<18歲'
        else if age < 30 then '18-29歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
        else if age < 70 then '60-69歲'
        else '>=70歲',
      needsSpecialTreatment: D in "Numerator"
  return {
    ageGroup: ageGroup,
    age: age,
    needsSpecialTreatment: needsSpecialTreatment
  }

// 依性別分層
define "Results By Gender":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      gender: patient.gender.value,
      needsSpecialTreatment: D in "Numerator"
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    needsSpecialTreatment: needsSpecialTreatment
  }

// 術後特別處理類型分析
define "Special Treatment Type Analysis":
  "Numerator" N
  let treatments: "Postoperative Special Treatment Procedures" T
                  where T.uniqueToothId = N.uniqueToothId
                  and T.procedureDate > N.procedureDate
                  and T.procedureDate <= N.procedureDate + 30 days,
      firstTreatment: First(treatments T sort by procedureDate),
      treatmentType: firstTreatment.procedureCode,
      daysToTreatment: days between N.procedureDate and firstTreatment.procedureDate
  return {
    extraction: N,
    treatmentType: treatmentType,
    daysToTreatment: daysToTreatment,
    timeCategory: 
      if daysToTreatment <= 3 then '3天內'
      else if daysToTreatment <= 7 then '4-7天'
      else if daysToTreatment <= 14 then '8-14天'
      else if daysToTreatment <= 21 then '15-21天'
      else '22-30天'
  }

// 術後特別處理時間分布
define "Treatment Time Distribution":
  "Special Treatment Type Analysis" Analysis
  return {
    timeCategory: Analysis.timeCategory,
    daysToTreatment: Analysis.daysToTreatment
  }

// 不需要術後處理的案例
define "No Special Treatment Cases":
  "Denominator" D
  where not (D in "Numerator")
  return {
    procedureId: D.procedureId,
    patient: D.patient,
    organization: D.organization,
    toothNumber: D.toothNumber,
    procedureDate: D.procedureDate
  }

// 月度趨勢分析
define "Results By Month":
  "Denominator" D
  let month: ToString(month from D.procedureDate) + '月',
      needsSpecialTreatment: D in "Numerator"
  return {
    month: month,
    needsSpecialTreatment: needsSpecialTreatment
  }

// 牙位號碼分析（如果有記錄）
define "Results By Tooth Number":
  "Denominator" D
  where D.toothNumber is not null
  let needsSpecialTreatment: D in "Numerator"
  return {
    toothNumber: D.toothNumber,
    needsSpecialTreatment: needsSpecialTreatment
  }

// 患者併發症頻率分析
define "Patient Complication Frequency":
  distinct (
    "Numerator" N return N.patient
  ) PatientRef
  let patientExtractions: "Denominator" D where D.patient = PatientRef,
      totalExtractions: Count(patientExtractions),
      extractionsWithComplications: patientExtractions D where D in "Numerator",
      complicationCount: Count(extractionsWithComplications),
      complicationRate: if totalExtractions > 0
                        then Round((complicationCount / totalExtractions) * 100.0, 2)
                        else null
  return {
    patient: PatientRef,
    totalExtractions: totalExtractions,
    complicationCount: complicationCount,
    complicationRate: complicationRate
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '簡單性拔牙執行後三十日以內不需要術後特別處理之比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '拔牙後30天內需要術後特別處理的牙齒顆數',
    denominator: "Denominator Count",
    denominatorDefinition: '簡單拔牙的牙齒顆數',
    denominatorCodes: '92015C (單純齒切除術)',
    numeratorCodes: '92016C, 92017C, 92018C, 92019C, 92020C (術後特別處理)',
    noSpecialTreatmentCount: "No Special Treatment Count",
    noSpecialTreatmentRate: "No Special Treatment Rate",
    specialTreatmentRate: "Special Treatment Rate",
    trackingPeriod: '30天',
    unit: '%',
    formula: '[1-(分子/分母)] x 100%'
  }
