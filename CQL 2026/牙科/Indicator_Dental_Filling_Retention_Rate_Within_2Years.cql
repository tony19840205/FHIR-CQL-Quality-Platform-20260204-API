/**
 * 指標名稱: 牙齒填補保存率-二年以內
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: [1 - (分子/分母)] x 100%
 * 
 * 分子: 醫事機構二年內之同院所同病人同顆牙，有兩次以上(含)牙齒填補之數量
 * 分母: 該時期同院所同病患同牙位，實施牙齒填補之數量
 * 
 * 分子條件: 牙齒填補健保代碼 89001 到89012、89014、89015
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dental_Filling_Retention_Rate_Within_2Years version '1.0.0'

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

// 牙齒填補健保代碼 (89001-89012, 89014, 89015)
define "Dental Filling Procedure Codes": {
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

// 檢查是否為牙齒填補處置
define function IsDentalFilling(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in {
    '89001', '89002', '89003', '89004',
    '89005', '89006', '89007', '89008',
    '89009', '89010', '89011', '89012',
    '89014', '89015'
  }

// 建立唯一識別碼: 機構+病患+牙位
define function GetFillingIdentifier(procedure Procedure):
  GetOrganization(procedure) + '|' + GetPatientReference(procedure) + '|' + GetToothNumber(procedure)

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 二年前期間起點 (用於檢查重複填補)
define "Two Years Prior Start":
  MeasurementPeriodStart - 2 years

// 二年追蹤期間 (從二年前到觀察期結束)
define "Two Year Tracking Period":
  Interval["Two Years Prior Start", MeasurementPeriodEnd]

// 觀察期間的所有Procedure
define "Procedures During Measurement Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'

// 二年追蹤期間的所有Procedure
define "Procedures During Two Year Tracking Period":
  [Procedure] P
  where P.performed during "Two Year Tracking Period"
  and P.status.value = 'completed'

// 觀察期間的牙齒填補處置
define "Dental Fillings During Measurement Period":
  "Procedures During Measurement Period" P
  where IsDentalFilling(P)
  and GetToothNumber(P) is not null

// 二年追蹤期間的牙齒填補處置
define "Dental Fillings During Two Year Tracking Period":
  "Procedures During Two Year Tracking Period" P
  where IsDentalFilling(P)
  and GetToothNumber(P) is not null

// 分母: 觀察期間同院所同病患同牙位實施牙齒填補之數量
// 以 (機構+病患+牙位) 作為唯一識別
define "Denominator Fillings":
  "Dental Fillings During Measurement Period" P
  return {
    identifier: GetFillingIdentifier(P),
    organization: GetOrganization(P),
    patient: GetPatientReference(P),
    toothNumber: GetToothNumber(P),
    procedureDate: P.performed as FHIR.dateTime,
    procedure: P
  }

// 分子: 二年內同院所同病人同顆牙有兩次以上(含)牙齒填補之數量
// 檢查每個分母中的填補，在二年內是否有重複填補
define "Numerator Fillings":
  "Denominator Fillings" DF
  let identifier: DF.identifier,
      organization: DF.organization,
      patient: DF.patient,
      toothNumber: DF.toothNumber,
      firstFillingDate: DF.procedureDate,
      // 找出同一牙位在二年內的所有填補記錄
      allFillings: "Dental Fillings During Two Year Tracking Period" P
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

// 分子總數 (重複填補的數量)
define "Numerator Count":
  Count("Numerator Fillings")

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

// 依機構別分層
define "Results By Organization":
  distinct (
    "Denominator Fillings" DF return DF.organization
  ) Org
  let orgFillings: "Denominator Fillings" DF where DF.organization = Org,
      orgNumerator: "Numerator Fillings" NF where NF.organization = Org,
      orgDenominator: Count(orgFillings),
      orgNumeratorCount: Count(orgNumerator),
      orgFailureRate: if orgDenominator > 0 
                      then Round((orgNumeratorCount / orgDenominator) * 100.0, 2)
                      else null,
      orgRetentionRate: if orgFailureRate is not null
                        then Round(100.0 - orgFailureRate, 2)
                        else null
  return {
    organization: Org,
    denominator: orgDenominator,
    numerator: orgNumeratorCount,
    failureRate: orgFailureRate,
    retentionRate: orgRetentionRate
  }

// 依填補類型分層 (恆牙 vs 乳牙)
define "Results By Tooth Type":
  "Denominator Fillings" DF
  let procedureCode: GetProcedureCode(DF.procedure),
      toothType: 
        if procedureCode in { '89005', '89006', '89007', '89008' }
        then '乳牙'
        else '恆牙',
      inNumerator: DF in "Numerator Fillings"
  return {
    toothType: toothType,
    inNumerator: inNumerator
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
        if procedureCode in { '89001', '89005', '89009' }
        then '單面'
        else if procedureCode in { '89002', '89006', '89010' }
        then '雙面'
        else if procedureCode in { '89003', '89007', '89011' }
        then '三面'
        else if procedureCode in { '89004', '89008', '89012' }
        then '四面以上'
        else '其他',
      inNumerator: DF in "Numerator Fillings"
  return {
    surfaceCount: surfaceCount,
    inNumerator: inNumerator
  }

// 失敗時間分布 (在多久後需要重新填補)
define "Failure Time Distribution":
  "Numerator Fillings" NF
  let identifier: NF.identifier,
      organization: NF.organization,
      patient: NF.patient,
      toothNumber: NF.toothNumber,
      firstFillingDate: NF.procedureDate,
      // 找出第二次填補
      secondFilling: First(
        "Dental Fillings During Two Year Tracking Period" P
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
      else if daysToFailure < 548 then '12-18個月'
      else '18-24個月'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '牙齒填補保存率-二年以內',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    trackingPeriod: '2年追蹤期',
    numerator: "Numerator Count",
    denominator: "Denominator Count",
    failureRate: "Failure Rate",
    retentionRate: "Retention Rate",
    unit: '%',
    formula: '[1 - (分子/分母)] x 100%'
  }
