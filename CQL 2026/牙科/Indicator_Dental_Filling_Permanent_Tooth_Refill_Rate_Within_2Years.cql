/**
 * 指標名稱: 恆牙2年以內同院所再補率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 各醫事機構牙齒填補之恆牙在前追溯二年內之該醫事機構同病人同牙位，有兩次以上(含)牙齒填補之顆數
 * 分母: 該時期(該季)各醫事機構所有病患，實施牙齒填補之恆牙顆數
 * 
 * 分母條件: 牙齒填補健保代碼為 89001到89012、89014、89015 (排除乳牙專用代碼89005-89008)
 * 
 * 排除條件: 排除牙齒至「無牙齦組」服務的案件
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dental_Filling_Permanent_Tooth_Refill_Rate_Within_2Years version '1.0.0'

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

// 恆牙填補健保代碼 (排除乳牙專用代碼89005-89008)
define "Permanent Tooth Filling Procedure Codes": {
  Code { code: '89001', system: "TWProcedure", display: '牙齒填補-單面' },
  Code { code: '89002', system: "TWProcedure", display: '牙齒填補-雙面' },
  Code { code: '89003', system: "TWProcedure", display: '牙齒填補-三面' },
  Code { code: '89004', system: "TWProcedure", display: '牙齒填補-四面以上' },
  Code { code: '89009', system: "TWProcedure", display: '牙齒填補-單面(複合樹脂)' },
  Code { code: '89010', system: "TWProcedure", display: '牙齒填補-雙面(複合樹脂)' },
  Code { code: '89011', system: "TWProcedure", display: '牙齒填補-三面(複合樹脂)' },
  Code { code: '89012', system: "TWProcedure", display: '牙齒填補-四面以上(複合樹脂)' },
  Code { code: '89014', system: "TWProcedure", display: '牙齒填補-特殊材料' },
  Code { code: '89015', system: "TWProcedure", display: '牙齒填補-其他' }
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

// 檢查是否為恆牙填補處置 (排除乳牙專用代碼89005-89008)
define function IsPermanentToothFilling(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in {
    '89001', '89002', '89003', '89004',
    '89009', '89010', '89011', '89012',
    '89014', '89015'
  }

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

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 二年前期間起點
define "Two Years Prior Start":
  MeasurementPeriodStart - 2 years

// 二年追蹤期間
define "Two Year Tracking Period":
  Interval["Two Years Prior Start", MeasurementPeriodEnd]

// 觀察期間的所有Procedure
define "Procedures During Measurement Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'

// 二年追蹤期間的所有Procedure
define "Procedures During Tracking Period":
  [Procedure] P
  where P.performed during "Two Year Tracking Period"
  and P.status.value = 'completed'

// 觀察期間的恆牙填補處置 (排除「無牙齦組」服務)
define "Permanent Tooth Fillings During Measurement Period":
  "Procedures During Measurement Period" P
  where IsPermanentToothFilling(P)
  and GetToothNumber(P) is not null
  and not IsEdentulousService(P)

// 二年追蹤期間的所有牙齒填補處置
define "All Fillings During Tracking Period":
  "Procedures During Tracking Period" P
  where IsAnyDentalFilling(P)
  and GetToothNumber(P) is not null
  and not IsEdentulousService(P)

// 分母: 該時期(該季)各醫事機構所有病患實施牙齒填補之恆牙顆數
define "Denominator Fillings":
  "Permanent Tooth Fillings During Measurement Period" P
  return {
    identifier: GetFillingIdentifier(P),
    organization: GetOrganization(P),
    patient: GetPatientReference(P),
    toothNumber: GetToothNumber(P),
    procedureDate: P.performed as FHIR.dateTime,
    procedure: P
  }

// 分子: 二年內同院所同病人同顆牙有兩次以上(含)牙齒填補之顆數
define "Numerator Fillings":
  "Denominator Fillings" DF
  let identifier: DF.identifier,
      organization: DF.organization,
      patient: DF.patient,
      toothNumber: DF.toothNumber,
      firstFillingDate: DF.procedureDate,
      // 找出同一牙位在二年內的所有填補記錄
      allFillings: "All Fillings During Tracking Period" P
                   where GetOrganization(P) = organization
                   and GetPatientReference(P) = patient
                   and GetToothNumber(P) = toothNumber
                   and P.performed as FHIR.dateTime during Interval[firstFillingDate - 2 years, firstFillingDate + 2 years],
      // 計算填補次數
      fillingCount: Count(allFillings)
  where fillingCount >= 2

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母總數
define "Denominator Count":
  Count("Denominator Fillings")

// 分子總數 (重複填補的顆數)
define "Numerator Count":
  Count("Numerator Fillings")

// 再補率 (分子/分母)
define "Refill Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層
define "Results By Organization":
  distinct (
    "Denominator Fillings" DF return DF.organization
  ) Org
  let orgFillings: "Denominator Fillings" DF where DF.organization = Org,
      orgNumerator: "Numerator Fillings" NF where NF.organization = Org,
      orgDenominator: Count(orgFillings),
      orgNumeratorCount: Count(orgNumerator),
      orgRefillRate: if orgDenominator > 0 
                     then Round((orgNumeratorCount / orgDenominator) * 100.0, 2)
                     else null
  return {
    organization: Org,
    denominator: orgDenominator,
    numerator: orgNumeratorCount,
    refillRate: orgRefillRate
  }

// 依填補材料分層
define "Results By Material":
  "Denominator Fillings" DF
  let procedureCode: GetProcedureCode(DF.procedure),
      material: 
        if procedureCode in { '89009', '89010', '89011', '89012' }
        then '複合樹脂'
        else if procedureCode = '89014'
        then '特殊材料'
        else if procedureCode = '89015'
        then '其他'
        else '一般材料',
      inNumerator: DF in "Numerator Fillings"
  return {
    material: material,
    inNumerator: inNumerator
  }

// 依填補面數分層
define "Results By Surface Count":
  "Denominator Fillings" DF
  let procedureCode: GetProcedureCode(DF.procedure),
      surfaceCount: 
        if procedureCode in { '89001', '89009' }
        then '單面'
        else if procedureCode in { '89002', '89010' }
        then '雙面'
        else if procedureCode in { '89003', '89011' }
        then '三面'
        else if procedureCode in { '89004', '89012' }
        then '四面以上'
        else '其他',
      inNumerator: DF in "Numerator Fillings"
  return {
    surfaceCount: surfaceCount,
    inNumerator: inNumerator
  }

// 再補時間分布 (在多久後需要重新填補)
define "Refill Time Distribution":
  "Numerator Fillings" NF
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
      daysToRefill: if secondFillingDate is not null
                    then days between firstFillingDate and secondFillingDate
                    else null
  where daysToRefill is not null
  return {
    identifier: identifier,
    daysToRefill: daysToRefill,
    monthsToRefill: Round(daysToRefill / 30.0, 1),
    timeCategory: 
      if daysToRefill < 90 then '<3個月'
      else if daysToRefill < 180 then '3-6個月'
      else if daysToRefill < 365 then '6-12個月'
      else if daysToRefill < 548 then '12-18個月'
      else '18-24個月'
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Denominator Fillings" DF
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = DF.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, DF.procedureDate),
      ageGroup: 
        if age < 20 then '<20歲'
        else if age < 40 then '20-39歲'
        else if age < 60 then '40-59歲'
        else '>=60歲',
      inNumerator: DF in "Numerator Fillings"
  return {
    ageGroup: ageGroup,
    inNumerator: inNumerator
  }

// 依性別分層
define "Results By Gender":
  "Denominator Fillings" DF
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = DF.patient),
      gender: patient.gender.value,
      inNumerator: DF in "Numerator Fillings"
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    inNumerator: inNumerator
  }

// 再補次數分布
define "Refill Count Distribution":
  "Numerator Fillings" NF
  let identifier: NF.identifier,
      organization: NF.organization,
      patient: NF.patient,
      toothNumber: NF.toothNumber,
      firstFillingDate: NF.procedureDate,
      // 找出同一牙位的所有填補記錄
      allFillings: "All Fillings During Tracking Period" P
                   where GetOrganization(P) = organization
                   and GetPatientReference(P) = patient
                   and GetToothNumber(P) = toothNumber
                   and P.performed as FHIR.dateTime during Interval[firstFillingDate - 2 years, firstFillingDate + 2 years],
      refillCount: Count(allFillings)
  return {
    identifier: identifier,
    refillCount: refillCount,
    countCategory: 
      if refillCount = 2 then '2次'
      else if refillCount = 3 then '3次'
      else if refillCount >= 4 then '4次以上'
      else '其他'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '恆牙2年以內同院所再補率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    trackingPeriod: '2年追蹤期',
    toothType: '恆牙(排除乳牙專用代碼89005-89008)',
    numerator: "Numerator Count",
    denominator: "Denominator Count",
    refillRate: "Refill Rate",
    unit: '%',
    formula: '(分子/分母) x 100%',
    note: '排除「無牙齦組」服務案件'
  }
