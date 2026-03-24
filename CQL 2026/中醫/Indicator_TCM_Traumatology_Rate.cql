/**
 * 指標名稱: 中醫傷科占率
 * 指標類別: 中醫照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 執行傷科處置次數
 * 分母: 中醫門診看診人次數
 * 
 * 分子條件: 傷科處置次數，申報傷科治療處置費的醫令數量加總，
 *           醫令代碼為 E01～E12、F01～F68
 * 
 * 分母條件: 院所看診人次，為"非廉恥案件"以件數計(21、22、24、28案件)
 *           加上"廉恥案件"以次數計(29案件)的人次
 *   (1)非廉恥案件：計算案件分類21、22、24、28的案件數
 *   (2)廉恥案件次數：亦即申報計傷科處置費令數量加總，
 *      醫令代碼為 D01～D08、E01～E12、F01～F68
 * 
 * 排除條件: 排除符合以下任一條件者
 *   1.案件分類為B6(職災案件)
 *   2.案件分類為A3(預防保健)
 *   3.案件分類為30(特定疾病門診加強照護)
 *   4.中醫專款專用
 *   5.其他部門：提供保險對象收容矯正機關者醫療服務計畫
 *   6.案件分類為C5(法定傳染病通報並住院隔離案件)
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_TCM_Traumatology_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
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

// 中醫門診案件類型碼
define "TCM Outpatient Case Type": 
  Code { code: '05', system: 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type', display: '中醫門診' }

// 非廉恥案件分類 (21, 22, 24, 28)
define "Non Shameful Case Types": { '21', '22', '24', '28' }

// 廉恥案件分類 (29)
define "Shameful Case Type": '29'

// 排除的案件分類
define "Excluded Case Types": { 'B6', 'A3', '30', '25', 'C5' }

// 傷科處置代碼 (E01~E12, F01~F68)
define "Traumatology Procedure Codes": 
  { 'E01', 'E02', 'E03', 'E04', 'E05', 'E06', 'E07', 'E08', 'E09', 'E10', 'E11', 'E12' }
  union 
  { 'F01', 'F02', 'F03', 'F04', 'F05', 'F06', 'F07', 'F08', 'F09', 'F10',
    'F11', 'F12', 'F13', 'F14', 'F15', 'F16', 'F17', 'F18', 'F19', 'F20',
    'F21', 'F22', 'F23', 'F24', 'F25', 'F26', 'F27', 'F28', 'F29', 'F30',
    'F31', 'F32', 'F33', 'F34', 'F35', 'F36', 'F37', 'F38', 'F39', 'F40',
    'F41', 'F42', 'F43', 'F44', 'F45', 'F46', 'F47', 'F48', 'F49', 'F50',
    'F51', 'F52', 'F53', 'F54', 'F55', 'F56', 'F57', 'F58', 'F59', 'F60',
    'F61', 'F62', 'F63', 'F64', 'F65', 'F66', 'F67', 'F68' }

// 廉恥案件處置代碼 (D01~D08, E01~E12, F01~F68)
define "Shameful Case Procedure Codes":
  { 'D01', 'D02', 'D03', 'D04', 'D05', 'D06', 'D07', 'D08' }
  union "Traumatology Procedure Codes"

// 中醫專款專用特定治療項目代碼
define "Special Fund Treatment Codes":
  { 'C8', 'J7', 'J9', 'JC', 'JD', 'JE', 'JF', 'JH', 'JI', 'JJ', 'JK', 'JQ', 
    'JP', 'JR', 'JT', 'JU', 'JY', 'JS', 'MA', 'MB', 'MC', 'EC', 'JA', 'JB' }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Encounter, url String):
  singleton from (
    element.extension E where E.url.value = url
  ).value.value

// 取得Encounter的案件類型
define function GetEncounterCaseType(encounter Encounter):
  if encounter.type is not null and Count(encounter.type) > 0
  and encounter.type[0].coding is not null and Count(encounter.type[0].coding) > 0
  then encounter.type[0].coding[0].code.value
  else null

// 取得特定治療項目代碼
define function GetSpecialTreatmentCodes(encounter Encounter):
  GetExtensionString(encounter, 'specialTreatmentCodes')

// 取得Procedure的處置代碼
define function GetProcedureCode(procedure Procedure):
  if procedure.code is not null 
  then (procedure.code.coding[0].code.value)
  else null

// 檢查是否為傷科處置
define function IsTraumatologyProcedure(procedureCode String):
  procedureCode in "Traumatology Procedure Codes"

// 檢查是否為廉恥案件處置
define function IsShamefulCaseProcedure(procedureCode String):
  procedureCode in "Shameful Case Procedure Codes"

// 檢查是否應排除（中醫專款專用或其他部門）
define function ShouldExcludeBySpecialFund(caseType String, treatmentCodes String):
  // 案件分類25
  (caseType = '25')
  or
  // 案件分類22且特定治療項目符合
  (caseType = '22' and treatmentCodes in { 'C8', 'J7', 'J9', 'JC', 'JD', 'JE', 'JF', 
    'JH', 'JI', 'JJ', 'JK', 'JQ', 'JP', 'JR', 'JT', 'JU', 'JY', 'JS', 'MA', 'MB', 'MC' })
  or
  // 案件分類31且特定治療項目為EC
  (caseType = '31' and treatmentCodes = 'EC')
  or
  // 其他部門：特定治療項目JA、JB
  (treatmentCodes in { 'JA', 'JB' })

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 觀察期間的所有Encounter
define "Encounters During Measurement Period":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'

// 觀察期間的所有Procedure
define "Procedures During Measurement Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'

// 符合條件的中醫門診案件（排除特定案件類型）
define "Valid TCM Outpatient Encounters":
  "Encounters During Measurement Period" E
  let caseType: GetEncounterCaseType(E),
      treatmentCodes: GetSpecialTreatmentCodes(E)
  where caseType = '05'  // 中醫門診
  // 排除特定案件分類
  and not (caseType in "Excluded Case Types")
  // 排除中醫專款專用和其他部門
  and not ShouldExcludeBySpecialFund(caseType, treatmentCodes)
  return {
    encounterId: 'Encounter/' + E.id,
    caseType: caseType,
    treatmentCodes: treatmentCodes
  }

// 分母計算
// (1) 非廉恥案件數量 (案件分類 21, 22, 24, 28)
define "Non Shameful Cases Count":
  Count(
    "Valid TCM Outpatient Encounters" E
    where E.caseType in "Non Shameful Case Types"
  )

// (2) 廉恥案件的處置次數 (案件分類 29，計算 D01~D08, E01~E12, F01~F68 處置數)
define "Shameful Cases Procedure Count":
  Count(
    "Procedures During Measurement Period" P
    let encounter: singleton from (
          "Valid TCM Outpatient Encounters" E 
          where 'Encounter/' + (singleton from ([Encounter] Enc where 'Encounter/' + Enc.id = P.encounter.reference.value)).id = E.encounterId
        ),
        procedureCode: GetProcedureCode(P)
    where encounter is not null
    and encounter.caseType = "Shameful Case Type"
    and IsShamefulCaseProcedure(procedureCode)
  )

// 分母: 非廉恥案件數 + 廉恥案件處置數
define "Denominator Count":
  "Non Shameful Cases Count" + "Shameful Cases Procedure Count"

// 分子: 傷科處置次數 (E01~E12, F01~F68)
define "Traumatology Procedures":
  "Procedures During Measurement Period" P
  let encounter: singleton from ([Encounter] E where 'Encounter/' + E.id = P.encounter.reference.value),
      validEncounter: singleton from (
        "Valid TCM Outpatient Encounters" VE 
        where VE.encounterId = 'Encounter/' + encounter.id
      ),
      procedureCode: GetProcedureCode(P)
  where validEncounter is not null
  and IsTraumatologyProcedure(procedureCode)
  return {
    procedureId: 'Procedure/' + P.id,
    procedureCode: procedureCode,
    encounterId: 'Encounter/' + encounter.id
  }

// 分子計數
define "Numerator Count":
  Count("Traumatology Procedures")

// ========================================================================================
// 指標計算
// ========================================================================================

// 中醫傷科占率
define "Traumatology Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依傷科處置代碼分層
define "Results By Procedure Code":
  "Traumatology Procedures" P
  return {
    procedureCode: P.procedureCode
  }

// 傷科處置代碼使用統計
define "Procedure Code Usage Statistics":
  distinct (
    "Traumatology Procedures" P return P.procedureCode
  ) ProcCode
  let codeCount: Count("Traumatology Procedures" P where P.procedureCode = ProcCode)
  return {
    procedureCode: ProcCode,
    usageCount: codeCount,
    percentage: if "Numerator Count" > 0
                then Round((codeCount / "Numerator Count") * 100.0, 2)
                else null
  }
  sort by usageCount desc

// E系列 vs F系列處置分布
define "Procedure Series Distribution":
  {
    eSeriesCount: Count("Traumatology Procedures" P where P.procedureCode in "Traumatology Procedure Codes" and Substring(P.procedureCode, 0, 1) = 'E'),
    fSeriesCount: Count("Traumatology Procedures" P where P.procedureCode in "Traumatology Procedure Codes" and Substring(P.procedureCode, 0, 1) = 'F'),
    eSeriesPercentage: if "Numerator Count" > 0
                       then Round((Count("Traumatology Procedures" P where Substring(P.procedureCode, 0, 1) = 'E') / "Numerator Count") * 100.0, 2)
                       else null,
    fSeriesPercentage: if "Numerator Count" > 0
                       then Round((Count("Traumatology Procedures" P where Substring(P.procedureCode, 0, 1) = 'F') / "Numerator Count") * 100.0, 2)
                       else null
  }

// 月度趨勢分析
define "Results By Month":
  "Traumatology Procedures" P
  return {
    procedureId: P.procedureId,
    encounterId: P.encounterId
  }

// 案件類型分布
define "Case Type Distribution":
  "Valid TCM Outpatient Encounters" E
  return {
    caseType: E.caseType
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '中醫傷科占率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '執行傷科處置次數（醫令代碼 E01～E12、F01～F68）',
    denominator: "Denominator Count",
    denominatorDefinition: '中醫門診看診人次數（非廉恥案件數 + 廉恥案件處置數）',
    nonShamefulCases: "Non Shameful Cases Count",
    shamefulCasesProcedures: "Shameful Cases Procedure Count",
    traumatologyRate: "Traumatology Rate",
    totalValidEncounters: Count("Valid TCM Outpatient Encounters"),
    procedureSeriesDistribution: "Procedure Series Distribution",
    topProcedureCodes: "Procedure Code Usage Statistics",
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
