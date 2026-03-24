/**
 * 指標名稱: 牙齒填補保存率-乳牙一年六個月以內
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: [1 - (分子/分母)] x 100%
 * 
 * 分子: 各醫事機構申報的乳牙填補案件在前追溯一年半，該醫事機構同病人同牙位，有兩次以上(含)牙齒填補之顆數
 * 分母: 各醫事機構所有病人，實施牙齒填補形之乳牙顆數
 * 
 * 分子條件: 牙齒填補健保代碼 89001 到89012、89014、89015 (僅乳牙)
 * 
 * 排除條件:
 * 1. 排除牙齒至「無牙齦組」服務的案件
 * 2. 醫事機構年填補顆數在 60 顆（含）以下，該指標不予揭露
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dental_Filling_Retention_Rate_Primary_Tooth_18Months version '1.0.0'

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

// 乳牙填補健保代碼 (89005-89008 專門針對乳牙)
define "Primary Tooth Filling Procedure Codes": {
  Code { code: '89005', system: "TWProcedure", display: '牙齒填補-單面(乳牙)' },
  Code { code: '89006', system: "TWProcedure", display: '牙齒填補-雙面(乳牙)' },
  Code { code: '89007', system: "TWProcedure", display: '牙齒填補-三面(乳牙)' },
  Code { code: '89008', system: "TWProcedure", display: '牙齒填補-四面以上(乳牙)' }
}

// 所有牙齒填補代碼 (用於檢查重複填補)
define "All Dental Filling Procedure Codes": {
  Code { code: '89001', system: "TWProcedure", display: '牙齒填補-單面' },
  Code { code: '89002', system: "TWProcedure", display: '牙齒填補-雙面' },
  Code { code: '89003', system: "TWProcedure", display: '牙齒填補-三面' },
  Code { code: '89004', system: "TWProcedure", display: '牙齒填補-四面以上' },
  Code { code: '89005', system: "TWProcedure", display: '牙齒填補-單面(乳牙)' },
  Code { code: '89006', system: "TWProcedure", display: '牙齒填補-雙面(乳牙)' },
  Code { code: '89007', system: "TWProcedure", display: '牙齒填補-三面(乳牙)' },
  Code { code: '89008', system: "TWProcedure", display: '牙齒填補-四面以上(乳牙)' },
  Code { code: '89009', system: "TWProcedure", display: '牙齒填補-單面(複合樹脂)' },
  Code { code: '89010', system: "TWProcedure", display: '牙齒填補-雙面(複合樹脂)' },
  Code { code: '89011', system: "TWProcedure", display: '牙齒填補-三面(複合樹脂)' },
  Code { code: '89012', system: "TWProcedure", display: '牙齒填補-四面以上(複合樹脂)' },
  Code { code: '89014', system: "TWProcedure", display: '牙齒填補-特殊材料' },
  Code { code: '89015', system: "TWProcedure", display: '牙齒填補-其他' }
}

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Extension布林值
define function GetExtensionBoolean(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.boolean

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

// 檢查是否為乳牙填補處置
define function IsPrimaryToothFilling(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '89005', '89006', '89007', '89008' }

// 檢查是否為任何牙齒填補處置
define function IsAnyDentalFilling(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in {
    '89001', '89002', '89003', '89004',
    '89005', '89006', '89007', '89008',
    '89009', '89010', '89011', '89012',
    '89014', '89015'
  }

// 檢查是否為「無牙齦組」服務案件 (需排除)
define function IsEdentulousService(procedure Procedure):
  GetExtensionBoolean(procedure, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/procedure-edentulous-service') = true

// 建立唯一識別碼: 機構+病患+牙位
define function GetFillingIdentifier(procedure Procedure):
  GetOrganization(procedure) + '|' + GetPatientReference(procedure) + '|' + GetToothNumber(procedure)

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 一年半(18個月)前期間起點
define "Eighteen Months Prior Start":
  MeasurementPeriodStart - 18 months

// 一年半追蹤期間
define "Eighteen Month Tracking Period":
  Interval["Eighteen Months Prior Start", MeasurementPeriodEnd]

// 年度期間 (用於計算填補顆數門檻)
define "Annual Period":
  Interval[MeasurementPeriodStart - 1 year, MeasurementPeriodEnd]

// 觀察期間的所有Procedure
define "Procedures During Measurement Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'

// 一年半追蹤期間的所有Procedure
define "Procedures During Tracking Period":
  [Procedure] P
  where P.performed during "Eighteen Month Tracking Period"
  and P.status.value = 'completed'

// 年度期間的所有Procedure
define "Procedures During Annual Period":
  [Procedure] P
  where P.performed during "Annual Period"
  and P.status.value = 'completed'

// 觀察期間的乳牙填補處置 (排除「無牙齦組」服務)
define "Primary Tooth Fillings During Measurement Period":
  "Procedures During Measurement Period" P
  where IsPrimaryToothFilling(P)
  and GetToothNumber(P) is not null
  and not IsEdentulousService(P)

// 一年半追蹤期間的所有牙齒填補處置
define "All Fillings During Tracking Period":
  "Procedures During Tracking Period" P
  where IsAnyDentalFilling(P)
  and GetToothNumber(P) is not null
  and not IsEdentulousService(P)

// 年度期間的乳牙填補處置 (用於計算填補顆數門檻)
define "Primary Tooth Fillings During Annual Period":
  "Procedures During Annual Period" P
  where IsPrimaryToothFilling(P)
  and GetToothNumber(P) is not null
  and not IsEdentulousService(P)

// 分母: 觀察期間各醫事機構所有病人實施牙齒填補之乳牙顆數
define "Denominator Fillings":
  "Primary Tooth Fillings During Measurement Period" P
  return {
    identifier: GetFillingIdentifier(P),
    organization: GetOrganization(P),
    patient: GetPatientReference(P),
    toothNumber: GetToothNumber(P),
    procedureDate: P.performed as FHIR.dateTime,
    procedure: P
  }

// 分子: 一年半內同院所同病人同顆牙有兩次以上(含)牙齒填補之顆數
define "Numerator Fillings":
  "Denominator Fillings" DF
  let identifier: DF.identifier,
      organization: DF.organization,
      patient: DF.patient,
      toothNumber: DF.toothNumber,
      firstFillingDate: DF.procedureDate,
      // 找出同一牙位在一年半內的所有填補記錄
      allFillings: "All Fillings During Tracking Period" P
                   where GetOrganization(P) = organization
                   and GetPatientReference(P) = patient
                   and GetToothNumber(P) = toothNumber
                   and P.performed as FHIR.dateTime during Interval[firstFillingDate - 18 months, firstFillingDate + 18 months],
      // 計算填補次數
      fillingCount: Count(allFillings)
  where fillingCount >= 2

// 依機構計算年度填補顆數
define "Annual Filling Count By Organization":
  distinct (
    "Primary Tooth Fillings During Annual Period" P return GetOrganization(P)
  ) Org
  let orgAnnualFillings: "Primary Tooth Fillings During Annual Period" P 
                         where GetOrganization(P) = Org,
      // 計算唯一牙位數 (機構+病患+牙位)
      uniqueTeeth: distinct (
        orgAnnualFillings P 
        return GetFillingIdentifier(P)
      ),
      annualCount: Count(uniqueTeeth)
  return {
    organization: Org,
    annualFillingCount: annualCount,
    meetsThreshold: annualCount > 60
  }

// 符合揭露門檻的機構 (年度填補顆數>60)
define "Organizations Meeting Threshold":
  "Annual Filling Count By Organization" O
  where O.meetsThreshold
  return O.organization

// 最終分母 (僅包含符合揭露門檻的機構)
define "Final Denominator":
  "Denominator Fillings" DF
  where DF.organization in "Organizations Meeting Threshold"

// 最終分子 (僅包含符合揭露門檻的機構)
define "Final Numerator":
  "Numerator Fillings" NF
  where NF.organization in "Organizations Meeting Threshold"

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母總數
define "Denominator Count":
  Count("Final Denominator")

// 分子總數 (重複填補的顆數)
define "Numerator Count":
  Count("Final Numerator")

// 失敗率 (分子/分母)
define "Failure Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// 保存率 = 1 - 失敗率
define "Retention Rate":
  if "Failure Rate" is not null
  then Round(100.0 - "Failure Rate", 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層 (僅符合揭露門檻的機構)
define "Results By Organization":
  "Organizations Meeting Threshold" Org
  let orgFillings: "Final Denominator" DF where DF.organization = Org,
      orgNumerator: "Final Numerator" NF where NF.organization = Org,
      orgDenominator: Count(orgFillings),
      orgNumeratorCount: Count(orgNumerator),
      orgFailureRate: if orgDenominator > 0 
                      then Round((orgNumeratorCount / orgDenominator) * 100.0, 2)
                      else null,
      orgRetentionRate: if orgFailureRate is not null
                        then Round(100.0 - orgFailureRate, 2)
                        else null,
      // 取得年度填補顆數
      annualInfo: singleton from ("Annual Filling Count By Organization" A where A.organization = Org)
  return {
    organization: Org,
    annualFillingCount: annualInfo.annualFillingCount,
    denominator: orgDenominator,
    numerator: orgNumeratorCount,
    failureRate: orgFailureRate,
    retentionRate: orgRetentionRate
  }

// 依填補面數分層
define "Results By Surface Count":
  "Final Denominator" DF
  let procedureCode: GetProcedureCode(DF.procedure),
      surfaceCount: 
        if procedureCode = '89005'
        then '單面'
        else if procedureCode = '89006'
        then '雙面'
        else if procedureCode = '89007'
        then '三面'
        else if procedureCode = '89008'
        then '四面以上'
        else '其他',
      inNumerator: DF in "Final Numerator"
  return {
    surfaceCount: surfaceCount,
    inNumerator: inNumerator
  }

// 失敗時間分布 (在多久後需要重新填補)
define "Failure Time Distribution":
  "Final Numerator" NF
  let identifier: NF.identifier,
      organization: NF.organization,
      patient: NF.patient,
      toothNumber: NF.toothNumber,
      firstFillingDate: NF.procedureDate,
      // 找出第二次填補
      secondFilling: First(
        "All Fillings During Tracking Period" P
        where GetOrganization(P) = organization
        and GetPatientReference(P) = patient
        and GetToothNumber(P) = toothNumber
        and P.performed as FHIR.dateTime > firstFillingDate
        sort by (performed as FHIR.dateTime)
      ),
      secondFillingDate: secondFilling.performed as FHIR.dateTime,
      daysToFailure: if secondFillingDate is not null
                     then days between firstFillingDate and secondFillingDate
                     else null
  where daysToFailure is not null
  return {
    identifier: identifier,
    daysToFailure: daysToFailure,
    monthsToFailure: Round(daysToFailure / 30.0, 1),
    timeCategory: 
      if daysToFailure < 90 then '<3個月'
      else if daysToFailure < 180 then '3-6個月'
      else if daysToFailure < 365 then '6-12個月'
      else '12-18個月'
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Final Denominator" DF
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = DF.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, DF.procedureDate),
      ageGroup: 
        if age < 2 then '<2歲'
        else if age < 4 then '2-3歲'
        else if age < 6 then '4-5歲'
        else '>=6歲',
      inNumerator: DF in "Final Numerator"
  return {
    ageGroup: ageGroup,
    inNumerator: inNumerator
  }

// 不符合揭露門檻的機構清單
define "Organizations Below Threshold":
  "Annual Filling Count By Organization" O
  where not O.meetsThreshold
  return {
    organization: O.organization,
    annualFillingCount: O.annualFillingCount,
    reason: '年度填補顆數 <= 60，不予揭露'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '牙齒填補保存率-乳牙一年六個月以內',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    trackingPeriod: '18個月追蹤期',
    disclosureThreshold: '年度填補顆數 > 60 顆',
    organizationsMeetingThreshold: Count("Organizations Meeting Threshold"),
    organizationsBelowThreshold: Count("Organizations Below Threshold"),
    numerator: "Numerator Count",
    denominator: "Denominator Count",
    failureRate: "Failure Rate",
    retentionRate: "Retention Rate",
    unit: '%',
    formula: '[1 - (分子/分母)] x 100%',
    note: '排除「無牙齦組」服務案件'
  }
