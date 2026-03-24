/**
 * 指標名稱: 院所牙周病統合治療方案完成率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 統計期間院所執行牙周病統合治療方案第一階段(P4001C或91021C)案件，
 *       依病人歸戶，於執行P4001C或91021C後180天內有執行牙周病統合治療方案
 *       第三階段(P4003C或91023C)的案件數
 * 分母: 統計期間院所執行牙周病統合治療方案第一階段(P4001C或91021C)案件數
 * 
 * 分子條件: 牙周病統合治療方案第三階段碼名為P4003C或91023C
 * 分母條件: 牙周病統合治療方案第一階段碼名為P4001C或91021C
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Periodontal_Integrated_Treatment_Completion_Rate version '1.0.0'

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

// 牙周病統合治療方案第一階段代碼 (P4001C或91021C)
define "Phase 1 Treatment Codes": {
  Code { code: 'P4001C', system: "TWProcedure", display: '牙周病統合治療方案第一階段' },
  Code { code: '91021C', system: "TWProcedure", display: '牙周病統合治療方案第一階段-91021C' }
}

// 牙周病統合治療方案第三階段代碼 (P4003C或91023C)
define "Phase 3 Treatment Codes": {
  Code { code: 'P4003C', system: "TWProcedure", display: '牙周病統合治療方案第三階段' },
  Code { code: '91023C', system: "TWProcedure", display: '牙周病統合治療方案第三階段-91023C' }
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

// 取得Encounter Reference
define function GetEncounterReference(procedure Procedure):
  if procedure.encounter is not null
  then procedure.encounter.reference.value
  else null

// 檢查是否為第一階段治療
define function IsPhase1Treatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { 'P4001C', '91021C' }

// 檢查是否為第三階段治療
define function IsPhase3Treatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { 'P4003C', '91023C' }

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

// 所有Procedure (包含觀察期後180天，用於追蹤完成情況)
define "All Procedures For Tracking":
  [Procedure] P
  where P.performed during Interval[MeasurementPeriodStart, MeasurementPeriodEnd + 180 days]
  and P.status.value = 'completed'

// 第一階段治療案件 (分母)
define "Phase 1 Treatment Procedures":
  "Procedures During Measurement Period" P
  where IsPhase1Treatment(P)
  return {
    procedureId: 'Procedure/' + P.id,
    encounterId: GetEncounterReference(P),
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    procedureCode: GetProcedureCode(P),
    procedureDate: P.performed as FHIR.dateTime
  }

// 第三階段治療案件
define "Phase 3 Treatment Procedures":
  "All Procedures For Tracking" P
  where IsPhase3Treatment(P)
  return {
    procedureId: 'Procedure/' + P.id,
    encounterId: GetEncounterReference(P),
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    procedureCode: GetProcedureCode(P),
    procedureDate: P.performed as FHIR.dateTime
  }

// 分母: 統計期間院所執行第一階段的案件數
define "Denominator":
  "Phase 1 Treatment Procedures"

// 分子: 第一階段後180天內有完成第三階段的案件數
define "Numerator":
  "Phase 1 Treatment Procedures" P1
  where exists(
    "Phase 3 Treatment Procedures" P3
    where P3.patient = P1.patient
    and P3.organization = P1.organization
    and P3.procedureDate >= P1.procedureDate
    and P3.procedureDate <= P1.procedureDate + 180 days
  )
  return P1

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母案件數
define "Denominator Count":
  Count("Denominator")

// 分子案件數
define "Numerator Count":
  Count("Numerator")

// 完成率 (分子/分母)
define "Completion Rate":
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
      orgCompletionRate: if orgDenominatorCount > 0 
                         then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
                         else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    completionRate: orgCompletionRate
  }

// 依第一階段處置代碼分層
define "Results By Phase 1 Code":
  "Denominator" D
  let hasCompletion: D in "Numerator"
  return {
    phase1Code: D.procedureCode,
    hasCompletion: hasCompletion
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, D.procedureDate),
      ageGroup: 
        if age < 30 then '<30歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
        else if age < 70 then '60-69歲'
        else '>=70歲',
      hasCompletion: D in "Numerator"
  return {
    ageGroup: ageGroup,
    age: age,
    hasCompletion: hasCompletion
  }

// 依性別分層
define "Results By Gender":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      gender: patient.gender.value,
      hasCompletion: D in "Numerator"
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    hasCompletion: hasCompletion
  }

// 完成時間分析 (從第一階段到第三階段的天數)
define "Completion Time Analysis":
  "Numerator" N
  let phase3Procedures: "Phase 3 Treatment Procedures" P3
                        where P3.patient = N.patient
                        and P3.organization = N.organization
                        and P3.procedureDate >= N.procedureDate
                        and P3.procedureDate <= N.procedureDate + 180 days,
      firstPhase3: First(phase3Procedures P3 sort by procedureDate),
      daysToCompletion: if firstPhase3 is not null
                        then days between N.procedureDate and firstPhase3.procedureDate
                        else null
  where daysToCompletion is not null
  return {
    patient: N.patient,
    organization: N.organization,
    phase1Date: N.procedureDate,
    phase3Date: firstPhase3.procedureDate,
    daysToCompletion: daysToCompletion,
    weeksToCompletion: Round(daysToCompletion / 7.0, 1),
    timeCategory: 
      if daysToCompletion <= 30 then '1個月內'
      else if daysToCompletion <= 60 then '1-2個月'
      else if daysToCompletion <= 90 then '2-3個月'
      else if daysToCompletion <= 120 then '3-4個月'
      else if daysToCompletion <= 150 then '4-5個月'
      else '5-6個月',
    phase3Code: firstPhase3.procedureCode
  }

// 未完成第三階段的案件
define "Incomplete Cases":
  "Denominator" D
  where not (D in "Numerator")
  return {
    procedureId: D.procedureId,
    encounterId: D.encounterId,
    patient: D.patient,
    organization: D.organization,
    phase1Code: D.procedureCode,
    phase1Date: D.procedureDate
  }

// 月度趨勢分析 (依第一階段治療月份)
define "Results By Month":
  "Denominator" D
  let month: ToString(month from D.procedureDate) + '月',
      hasCompletion: D in "Numerator"
  return {
    month: month,
    hasCompletion: hasCompletion
  }

// 患者治療歷程分析
define "Patient Treatment Journey":
  distinct (
    "Denominator" D return D.patient
  ) PatientRef
  let phase1Procedures: "Denominator" D where D.patient = PatientRef,
      phase1Count: Count(phase1Procedures),
      completedPhase1: phase1Procedures P1 where P1 in "Numerator",
      completedCount: Count(completedPhase1),
      completionRate: if phase1Count > 0
                      then Round((completedCount / phase1Count) * 100.0, 2)
                      else null,
      firstPhase1Date: First(phase1Procedures P1 sort by procedureDate).procedureDate,
      lastPhase1Date: Last(phase1Procedures P1 sort by procedureDate).procedureDate
  return {
    patient: PatientRef,
    totalPhase1Treatments: phase1Count,
    completedTreatments: completedCount,
    patientCompletionRate: completionRate,
    firstTreatmentDate: firstPhase1Date,
    lastTreatmentDate: lastPhase1Date
  }

// 治療完整度分類
define "Treatment Completeness Categories":
  "Patient Treatment Journey" Journey
  let category: 
    if Journey.patientCompletionRate = 100.0 then '完全完成'
    else if Journey.patientCompletionRate >= 50.0 then '部分完成'
    else if Journey.patientCompletionRate > 0.0 then '少部分完成'
    else '完全未完成'
  return {
    patient: Journey.patient,
    category: category,
    completionRate: Journey.patientCompletionRate
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '院所牙周病統合治療方案完成率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '第一階段後180天內完成第三階段的案件數',
    numeratorCodes: 'P4003C, 91023C (第三階段)',
    denominator: "Denominator Count",
    denominatorDefinition: '統計期間執行第一階段的案件數',
    denominatorCodes: 'P4001C, 91021C (第一階段)',
    completionRate: "Completion Rate",
    incompleteCases: Count("Incomplete Cases"),
    totalPatients: Count(distinct ("Denominator" D return D.patient)),
    averageDaysToCompletion: Round(Avg("Completion Time Analysis" C return C.daysToCompletion), 1),
    unit: '%',
    formula: '(分子/分母) x 100%',
    trackingPeriod: '180天'
  }
