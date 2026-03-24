/**
 * 指標名稱: 院所執行「根管難症特別處理」之數量
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 指標類型: 統計數量指標 (非比率型)
 * 
 * 指標定義: 醫事機構該季實施根管難症特別處理(90091C~90098C)的顆數
 * 
 * 用途:
 * - 評估醫療機構處理複雜根管案例的能力
 * - 了解專科治療服務提供情況
 * - 作為醫療品質和技術水準的參考指標
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Root_Canal_Difficult_Case_Special_Treatment_Count version '1.0.0'

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

// 根管難症特別處理代碼 (90091C~90098C)
define "Root Canal Difficult Case Special Treatment Codes": {
  Code { code: '90091C', system: "TWProcedure", display: '根管難症特別處理-鈣化根管疏通' },
  Code { code: '90092C', system: "TWProcedure", display: '根管難症特別處理-彎曲根管處理' },
  Code { code: '90093C', system: "TWProcedure", display: '根管難症特別處理-根管內異物移除' },
  Code { code: '90094C', system: "TWProcedure", display: '根管難症特別處理-根尖手術' },
  Code { code: '90095C', system: "TWProcedure", display: '根管難症特別處理-再治療' },
  Code { code: '90096C', system: "TWProcedure", display: '根管難症特別處理-根管穿孔修補' },
  Code { code: '90097C', system: "TWProcedure", display: '根管難症特別處理-根管內柱心移除' },
  Code { code: '90098C', system: "TWProcedure", display: '根管難症特別處理-其他特殊處理' }
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

// 檢查是否為根管難症特別處理
define function IsRootCanalDifficultCaseSpecialTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in {
    '90091C', '90092C', '90093C', '90094C',
    '90095C', '90096C', '90097C', '90098C'
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

// 根管難症特別處理案件
define "Root Canal Difficult Case Special Treatments":
  "Procedures During Measurement Period" P
  where IsRootCanalDifficultCaseSpecialTreatment(P)
  return {
    procedureId: P.id,
    procedureCode: GetProcedureCode(P),
    organization: GetOrganization(P),
    patient: GetPatientReference(P),
    toothNumber: GetToothNumber(P),
    procedureDate: P.performed as FHIR.dateTime,
    procedure: P
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 總數量 (總顆數)
define "Total Count":
  Count("Root Canal Difficult Case Special Treatments")

// 總案件數 (依機構+病患+牙位去重)
define "Total Cases Count":
  Count(
    distinct (
      "Root Canal Difficult Case Special Treatments" T
      return T.organization + '|' + T.patient + '|' + T.toothNumber
    )
  )

// 總病患數
define "Total Patients Count":
  Count(
    distinct (
      "Root Canal Difficult Case Special Treatments" T
      return T.patient
    )
  )

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別統計
define "Count By Organization":
  distinct (
    "Root Canal Difficult Case Special Treatments" T return T.organization
  ) Org
  let orgTreatments: "Root Canal Difficult Case Special Treatments" T 
                     where T.organization = Org,
      orgCount: Count(orgTreatments),
      orgPatients: Count(distinct (orgTreatments T return T.patient)),
      orgTeeth: Count(distinct (orgTreatments T return T.organization + '|' + T.patient + '|' + T.toothNumber))
  return {
    organization: Org,
    treatmentCount: orgCount,
    patientCount: orgPatients,
    teethCount: orgTeeth
  }

// 依處理類型統計
define "Count By Treatment Type":
  distinct (
    "Root Canal Difficult Case Special Treatments" T return T.procedureCode
  ) Code
  let codeTreatments: "Root Canal Difficult Case Special Treatments" T 
                      where T.procedureCode = Code,
      codeCount: Count(codeTreatments),
      treatmentType: 
        if Code = '90091C' then '鈣化根管疏通'
        else if Code = '90092C' then '彎曲根管處理'
        else if Code = '90093C' then '根管內異物移除'
        else if Code = '90094C' then '根尖手術'
        else if Code = '90095C' then '再治療'
        else if Code = '90096C' then '根管穿孔修補'
        else if Code = '90097C' then '根管內柱心移除'
        else if Code = '90098C' then '其他特殊處理'
        else '未知'
  return {
    procedureCode: Code,
    treatmentType: treatmentType,
    count: codeCount
  }

// 依患者年齡統計
define "Count By Patient Age":
  "Root Canal Difficult Case Special Treatments" T
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = T.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, T.procedureDate),
      ageGroup: 
        if age < 20 then '<20歲'
        else if age < 30 then '20-29歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
        else '>=60歲'
  return {
    ageGroup: ageGroup,
    organization: T.organization
  }

// 依性別統計
define "Count By Gender":
  "Root Canal Difficult Case Special Treatments" T
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = T.patient),
      gender: patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    organization: T.organization
  }

// 依牙位類型統計
define "Count By Tooth Position":
  "Root Canal Difficult Case Special Treatments" T
  let toothNumber: T.toothNumber,
      toothType: 
        if toothNumber is not null and Length(toothNumber) >= 2
        then 
          let lastDigit: Substring(toothNumber, Length(toothNumber) - 1, 1)
          return 
            if lastDigit in { '1', '2', '3' } then '前牙'
            else if lastDigit in { '4', '5' } then '小臼齒'
            else if lastDigit in { '6', '7', '8' } then '大臼齒'
            else '其他'
        else '未知'
  return {
    toothType: toothType,
    procedureCode: T.procedureCode
  }

// 月度趨勢分析
define "Count By Month":
  "Root Canal Difficult Case Special Treatments" T
  let procedureDate: T.procedureDate,
      month: 
        if procedureDate is not null
        then ToString(month from procedureDate) + '月'
        else '未知'
  return {
    month: month,
    organization: T.organization
  }

// 複雜度分析 (同一牙位多次特別處理)
define "Complexity Analysis":
  distinct (
    "Root Canal Difficult Case Special Treatments" T
    return T.organization + '|' + T.patient + '|' + T.toothNumber
  ) ToothId
  let treatments: "Root Canal Difficult Case Special Treatments" T
                  where (T.organization + '|' + T.patient + '|' + T.toothNumber) = ToothId,
      treatmentCount: Count(treatments),
      treatmentTypes: distinct (treatments T return T.procedureCode)
  return {
    toothIdentifier: ToothId,
    treatmentCount: treatmentCount,
    distinctTreatmentTypes: Count(treatmentTypes),
    complexity: 
      if treatmentCount >= 3 then '高複雜度'
      else if treatmentCount = 2 then '中複雜度'
      else '低複雜度'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '院所執行「根管難症特別處理」之數量',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    indicatorType: '統計數量指標',
    totalTreatmentCount: "Total Count",
    totalCasesCount: "Total Cases Count",
    totalPatientsCount: "Total Patients Count",
    procedureCodes: '90091C~90098C',
    unit: '顆數',
    note: '統計該季實施根管難症特別處理的總顆數'
  }
