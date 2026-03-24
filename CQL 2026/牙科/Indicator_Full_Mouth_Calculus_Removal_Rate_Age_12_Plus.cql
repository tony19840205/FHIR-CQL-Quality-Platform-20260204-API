/**
 * 指標名稱: 十二歲以上病人執行全口牙結石清除之比率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 醫事機構申報十二歲以上執行全口牙結石清除術的人數
 * 分母: 醫事機構牙醫門診十二歲以上總病人數
 * 
 * 分子條件: 全口牙結石清除術健保代碼為 91004C、91104C、91005C、91017C、91089C、91090C
 * 分母條件: 年齡之計算為就醫年-出生年≥12
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Full_Mouth_Calculus_Removal_Rate_Age_12_Plus version '1.0.0'

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

// 全口牙結石清除術代碼
define "Full Mouth Calculus Removal Codes": {
  Code { code: '91004C', system: "TWProcedure", display: '全口牙結石清除' },
  Code { code: '91104C', system: "TWProcedure", display: '全口牙結石清除-特殊' },
  Code { code: '91005C', system: "TWProcedure", display: '全口牙結石清除-牙周' },
  Code { code: '91017C', system: "TWProcedure", display: '全口牙結石清除-兒童' },
  Code { code: '91089C', system: "TWProcedure", display: '全口牙結石清除-預防' },
  Code { code: '91090C', system: "TWProcedure", display: '全口牙結石清除-維護' }
}

// 牙醫門診案件類型碼
define "Dental Outpatient Case Type": 
  Code { code: '04', system: "TWCaseType", display: '門診' }

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

// 取得Encounter的案件類型
define function GetEncounterCaseType(encounter Encounter):
  if encounter.class is not null
  then encounter.class.code.value
  else null

// 檢查是否為全口牙結石清除術
define function IsFullMouthCalculusRemoval(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '91004C', '91104C', '91005C', '91017C', '91089C', '91090C' }

// 計算年齡 (就醫年 - 出生年)
define function CalculateAgeAtVisit(birthDate Date, visitDate DateTime):
  year from visitDate - year from birthDate

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

// 牙醫門診的所有Encounter
define "Dental Outpatient Encounters":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'
  and GetEncounterCaseType(E) = '04'  // 門診

// 分母: 牙醫門診十二歲以上總病人數
define "Denominator":
  "Dental Outpatient Encounters" E
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = E.subject.reference.value),
      birthDate: patient.birthDate.value,
      visitDate: E.period.start,
      age: CalculateAgeAtVisit(birthDate, visitDate)
  where age >= 12
  return {
    patient: E.subject.reference.value,
    organization: GetExtensionString(E, 'organizationReference'),
    age: age,
    visitDate: visitDate
  }

// 全口牙結石清除術案件
define "Full Mouth Calculus Removal Procedures":
  "Procedures During Measurement Period" P
  where IsFullMouthCalculusRemoval(P)

// 分子: 十二歲以上執行全口牙結石清除術的人數
define "Numerator":
  "Full Mouth Calculus Removal Procedures" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = GetPatientReference(P)),
      birthDate: patient.birthDate.value,
      procedureDate: P.performed as FHIR.dateTime,
      age: CalculateAgeAtVisit(birthDate, procedureDate)
  where age >= 12
  return {
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    age: age,
    procedureDate: procedureDate,
    procedureCode: GetProcedureCode(P)
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母人數 (去重複)
define "Denominator Count":
  Count(
    distinct (
      "Denominator" D return D.patient
    )
  )

// 分子人數 (去重複)
define "Numerator Count":
  Count(
    distinct (
      "Numerator" N return N.patient
    )
  )

// 執行率 (分子/分母)
define "Removal Rate":
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
      orgRemovalRate: if orgDenominatorCount > 0 
                      then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
                      else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    removalRate: orgRemovalRate
  }

// 依處置類型分層 (分子)
define "Results By Procedure Type":
  "Numerator" N
  let procedureType: 
    if N.procedureCode = '91004C' then '全口牙結石清除'
    else if N.procedureCode = '91104C' then '全口牙結石清除-特殊'
    else if N.procedureCode = '91005C' then '全口牙結石清除-牙周'
    else if N.procedureCode = '91017C' then '全口牙結石清除-兒童'
    else if N.procedureCode = '91089C' then '全口牙結石清除-預防'
    else if N.procedureCode = '91090C' then '全口牙結石清除-維護'
    else '未知'
  return {
    procedureType: procedureType,
    procedureCode: N.procedureCode,
    patient: N.patient
  }

// 依患者年齡分層 (分母)
define "Results By Patient Age Denominator":
  "Denominator" D
  let ageGroup: 
    if D.age < 18 then '12-17歲'
    else if D.age < 30 then '18-29歲'
    else if D.age < 40 then '30-39歲'
    else if D.age < 50 then '40-49歲'
    else if D.age < 60 then '50-59歲'
    else if D.age < 70 then '60-69歲'
    else '>=70歲',
      inNumerator: exists(
        "Numerator" N where N.patient = D.patient
      )
  return {
    ageGroup: ageGroup,
    age: D.age,
    inNumerator: inNumerator
  }

// 依患者年齡分層 (分子)
define "Results By Patient Age Numerator":
  "Numerator" N
  let ageGroup: 
    if N.age < 18 then '12-17歲'
    else if N.age < 30 then '18-29歲'
    else if N.age < 40 then '30-39歲'
    else if N.age < 50 then '40-49歲'
    else if N.age < 60 then '50-59歲'
    else if N.age < 70 then '60-69歲'
    else '>=70歲'
  return {
    ageGroup: ageGroup,
    age: N.age
  }

// 依性別分層 (分母)
define "Results By Gender Denominator":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      gender: patient.gender.value,
      inNumerator: exists(
        "Numerator" N where N.patient = D.patient
      )
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    inNumerator: inNumerator
  }

// 依性別分層 (分子)
define "Results By Gender Numerator":
  "Numerator" N
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = N.patient),
      gender: patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他'
  }

// 月度趨勢分析
define "Results By Month":
  "Numerator" N
  let month: ToString(month from N.procedureDate) + '月'
  return {
    month: month,
    patient: N.patient
  }

// 未執行全口牙結石清除的患者
define "Patients Without Calculus Removal":
  "Denominator" D
  where not exists(
    "Numerator" N where N.patient = D.patient
  )
  return {
    patient: D.patient,
    organization: D.organization,
    age: D.age
  }

// 多次執行全口牙結石清除的患者分析
define "Patients With Multiple Removals":
  distinct (
    "Numerator" N return N.patient
  ) PatientRef
  let removalProcedures: "Numerator" N where N.patient = PatientRef,
      removalCount: Count(removalProcedures),
      firstRemovalDate: First(removalProcedures N sort by procedureDate).procedureDate,
      lastRemovalDate: Last(removalProcedures N sort by procedureDate).procedureDate,
      daysInterval: if removalCount > 1 
                    then days between firstRemovalDate and lastRemovalDate
                    else null
  where removalCount > 1
  return {
    patient: PatientRef,
    removalCount: removalCount,
    firstRemovalDate: firstRemovalDate,
    lastRemovalDate: lastRemovalDate,
    daysInterval: daysInterval,
    intervalCategory: 
      if daysInterval is null then '單次'
      else if daysInterval <= 30 then '1個月內'
      else if daysInterval <= 90 then '1-3個月'
      else if daysInterval <= 180 then '3-6個月'
      else '6個月以上'
  }

// 執行頻率分析
define "Removal Frequency Analysis":
  distinct (
    "Numerator" N return N.patient
  ) PatientRef
  let removalCount: Count("Numerator" N where N.patient = PatientRef),
      frequencyCategory: 
        if removalCount = 1 then '單次'
        else if removalCount = 2 then '2次'
        else if removalCount = 3 then '3次'
        else if removalCount >= 4 then '4次以上'
        else '未知'
  return {
    patient: PatientRef,
    removalCount: removalCount,
    frequencyCategory: frequencyCategory
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '十二歲以上病人執行全口牙結石清除之比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '醫事機構申報十二歲以上執行全口牙結石清除術的人數',
    numeratorCodes: '91004C, 91104C, 91005C, 91017C, 91089C, 91090C',
    denominator: "Denominator Count",
    denominatorDefinition: '醫事機構牙醫門診十二歲以上總病人數',
    denominatorCriteria: '年齡之計算為就醫年-出生年≥12',
    removalRate: "Removal Rate",
    patientsWithoutRemoval: Count("Patients Without Calculus Removal"),
    patientsWithMultipleRemovals: Count("Patients With Multiple Removals"),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
