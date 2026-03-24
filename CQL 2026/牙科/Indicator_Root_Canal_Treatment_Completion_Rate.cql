/**
 * 指標名稱: 根管治療完成率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 各醫事機構在前追溯一年，門診申報牙齒根管治療的數量
 * 分母: 同時期各醫事機構申報牙齒「根管開擴及清創」的數量
 * 
 * 分子條件: 根管治療健保代碼 90001C到90003C、90016C、90018C到90020C
 * 分母條件: 根管開擴及清創健保代碼為 90015C
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Root_Canal_Treatment_Completion_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 根管治療健保代碼 (90001C-90003C, 90016C, 90018C-90020C)
define "Root Canal Treatment Procedure Codes": {
  Code { code: '90001C', system: "TWProcedure", display: '根管治療-單根管' },
  Code { code: '90002C', system: "TWProcedure", display: '根管治療-雙根管' },
  Code { code: '90003C', system: "TWProcedure", display: '根管治療-三根管以上' },
  Code { code: '90016C', system: "TWProcedure", display: '根管治療-特殊處理' },
  Code { code: '90018C', system: "TWProcedure", display: '根管治療-前牙' },
  Code { code: '90019C', system: "TWProcedure", display: '根管治療-小臼齒' },
  Code { code: '90020C', system: "TWProcedure", display: '根管治療-大臼齒' }
}

// 根管開擴及清創健保代碼 (90015C)
define "Root Canal Opening And Cleaning Procedure Code":
  Code { code: '90015C', system: "TWProcedure", display: '根管開擴及清創' }

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

// 取得牙位資訊 (tooth number/position)
define function GetToothNumber(procedure Procedure):
  GetExtensionString(procedure, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/procedure-tooth-number')

// 取得Procedure的醫療機構
define function GetOrganization(procedure Procedure):
  if procedure.performer is not null and Count(procedure.performer) > 0
  then (procedure.performer[0].actor.reference.value)
  else null

// 取得Patient Reference
define function GetPatientReference(procedure Procedure):
  procedure.subject.reference.value

// 取得Encounter的就醫類別
define function GetEncounterCaseType(encounter Encounter):
  GetExtensionString(encounter, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/encounter-case-type')

// 檢查是否為根管治療處置
define function IsRootCanalTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in {
    '90001C', '90002C', '90003C',
    '90016C', '90018C', '90019C', '90020C'
  }

// 檢查是否為根管開擴及清創
define function IsRootCanalOpeningCleaning(procedure Procedure):
  GetProcedureCode(procedure) = '90015C'

// 檢查是否為門診案件
define function IsOutpatient(encounter Encounter):
  GetEncounterCaseType(encounter) = '04'

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 一年前期間起點
define "One Year Prior Start":
  MeasurementPeriodStart - 1 year

// 一年追蹤期間 (前追溯一年)
define "One Year Tracking Period":
  Interval["One Year Prior Start", MeasurementPeriodEnd]

// 一年追蹤期間的所有Procedure
define "Procedures During Tracking Period":
  [Procedure] P
  where P.performed during "One Year Tracking Period"
  and P.status.value = 'completed'

// 一年追蹤期間的所有Encounter
define "Encounters During Tracking Period":
  [Encounter] E
  where E.period.start during "One Year Tracking Period"

// 一年追蹤期間的門診根管治療 (分子)
define "Root Canal Treatments":
  "Procedures During Tracking Period" P
  let encounter: singleton from (
    "Encounters During Tracking Period" E 
    where 'Encounter/' + E.id = P.encounter.reference
  )
  where IsRootCanalTreatment(P)
  and GetToothNumber(P) is not null
  and IsOutpatient(encounter)

// 一年追蹤期間的門診根管開擴及清創 (分母)
define "Root Canal Opening Cleanings":
  "Procedures During Tracking Period" P
  let encounter: singleton from (
    "Encounters During Tracking Period" E 
    where 'Encounter/' + E.id = P.encounter.reference
  )
  where IsRootCanalOpeningCleaning(P)
  and GetToothNumber(P) is not null
  and IsOutpatient(encounter)

// 分子: 門診申報根管治療的數量
define "Numerator":
  "Root Canal Treatments" P
  return {
    organization: GetOrganization(P),
    patient: GetPatientReference(P),
    toothNumber: GetToothNumber(P),
    procedureDate: P.performed as FHIR.dateTime,
    procedureCode: GetProcedureCode(P),
    procedure: P
  }

// 分母: 門診申報根管開擴及清創的數量
define "Denominator":
  "Root Canal Opening Cleanings" P
  return {
    organization: GetOrganization(P),
    patient: GetPatientReference(P),
    toothNumber: GetToothNumber(P),
    procedureDate: P.performed as FHIR.dateTime,
    procedureCode: GetProcedureCode(P),
    procedure: P
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母總數
define "Denominator Count":
  Count("Denominator")

// 分子總數
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

// 依根管治療類型分層 (僅分子)
define "Results By Treatment Type":
  "Numerator" N
  let procedureCode: N.procedureCode,
      treatmentType: 
        if procedureCode = '90001C' then '單根管'
        else if procedureCode = '90002C' then '雙根管'
        else if procedureCode = '90003C' then '三根管以上'
        else if procedureCode = '90016C' then '特殊處理'
        else if procedureCode = '90018C' then '前牙'
        else if procedureCode = '90019C' then '小臼齒'
        else if procedureCode = '90020C' then '大臼齒'
        else '其他'
  return {
    treatmentType: treatmentType,
    organization: N.organization
  }

// 依牙位類型分層
define "Results By Tooth Type":
  "Denominator" D
  let toothNumber: D.toothNumber,
      toothType: 
        // 牙位編號通常: 11-18, 21-28 (上顎), 31-38, 41-48 (下顎)
        // 1x, 2x = 前牙區, 3x-5x = 前臼齒, 6x-8x = 後臼齒
        if toothNumber is not null and Length(toothNumber) >= 2
        then 
          let lastDigit: Substring(toothNumber, Length(toothNumber) - 1, 1)
          return 
            if lastDigit in { '1', '2', '3' } then '前牙'
            else if lastDigit in { '4', '5' } then '小臼齒'
            else if lastDigit in { '6', '7', '8' } then '大臼齒'
            else '其他'
        else '未知',
      hasCompletion: D in ("Numerator" N 
                           where N.organization = D.organization
                           and N.patient = D.patient
                           and N.toothNumber = D.toothNumber)
  return {
    toothType: toothType,
    hasCompletion: hasCompletion
  }

// 完成時間分布 (從開擴到完成治療的時間)
define "Completion Time Distribution":
  "Denominator" D
  let openingDate: D.procedureDate,
      // 找出同一牙位的根管治療
      completions: "Numerator" N
                   where N.organization = D.organization
                   and N.patient = D.patient
                   and N.toothNumber = D.toothNumber
                   and N.procedureDate >= openingDate,
      firstCompletion: First(completions C sort by C.procedureDate),
      completionDate: firstCompletion.procedureDate,
      daysToCompletion: if completionDate is not null
                        then days between openingDate and completionDate
                        else null
  where daysToCompletion is not null
  return {
    organization: D.organization,
    patient: D.patient,
    toothNumber: D.toothNumber,
    daysToCompletion: daysToCompletion,
    weeksToCompletion: Round(daysToCompletion / 7.0, 1),
    timeCategory: 
      if daysToCompletion <= 7 then '1週內'
      else if daysToCompletion <= 14 then '1-2週'
      else if daysToCompletion <= 30 then '2週-1個月'
      else if daysToCompletion <= 90 then '1-3個月'
      else '3個月以上'
  }

// 未完成治療的案例
define "Incomplete Treatments":
  "Denominator" D
  let openingDate: D.procedureDate,
      // 檢查是否有完成治療
      hasCompletion: exists(
        "Numerator" N
        where N.organization = D.organization
        and N.patient = D.patient
        and N.toothNumber = D.toothNumber
        and N.procedureDate >= openingDate
      )
  where not hasCompletion
  return {
    organization: D.organization,
    patient: D.patient,
    toothNumber: D.toothNumber,
    openingDate: D.procedureDate,
    daysSinceOpening: days between D.procedureDate and MeasurementPeriodEnd
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, D.procedureDate),
      ageGroup: 
        if age < 20 then '<20歲'
        else if age < 40 then '20-39歲'
        else if age < 60 then '40-59歲'
        else '>=60歲',
      hasCompletion: D in ("Numerator" N 
                           where N.organization = D.organization
                           and N.patient = D.patient
                           and N.toothNumber = D.toothNumber)
  return {
    ageGroup: ageGroup,
    hasCompletion: hasCompletion
  }

// 依性別分層
define "Results By Gender":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      gender: patient.gender.value,
      hasCompletion: D in ("Numerator" N 
                           where N.organization = D.organization
                           and N.patient = D.patient
                           and N.toothNumber = D.toothNumber)
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    hasCompletion: hasCompletion
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '根管治療完成率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    trackingPeriod: '前追溯一年',
    numerator: "Numerator Count",
    numeratorDefinition: '門診申報根管治療的數量',
    numeratorCodes: '90001C-90003C, 90016C, 90018C-90020C',
    denominator: "Denominator Count",
    denominatorDefinition: '門診申報根管開擴及清創的數量',
    denominatorCode: '90015C',
    completionRate: "Completion Rate",
    incompleteCount: Count("Incomplete Treatments"),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
