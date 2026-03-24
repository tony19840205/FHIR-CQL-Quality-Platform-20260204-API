/**
 * 指標名稱: 根管治療保存率-六個月以內
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: [1 - (分子/分母)] x 100%
 * 
 * 分子: 醫事機構每季就醫病患根管治療後半年內再施行根管治療、乳牙根管治療的牙齒顆數或拔牙的顆數
 * 分母: 醫事機構每季根管治療顆數
 * 
 * 分子條件:
 * 1. 根管治療健保代碼為90001C~90003C、90019C、90020C
 * 2. 乳牙根管治療健保代碼為 90016C、90018C
 * 3. 拔牙健保代碼為 92013C、92014C、92015C
 * 
 * 分母條件: 根管治療顆數為健保申報 90015C及根管治療任一醫令者
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Root_Canal_Treatment_Retention_Rate_Within_6Months version '1.0.0'

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

// 根管開擴及清創
define "Root Canal Opening Code":
  Code { code: '90015C', system: "TWProcedure", display: '根管開擴及清創' }

// 根管治療代碼 (用於分母)
define "Root Canal Treatment Codes": {
  Code { code: '90001C', system: "TWProcedure", display: '根管治療-單根管' },
  Code { code: '90002C', system: "TWProcedure", display: '根管治療-雙根管' },
  Code { code: '90003C', system: "TWProcedure", display: '根管治療-三根管以上' },
  Code { code: '90016C', system: "TWProcedure", display: '乳牙根管治療' },
  Code { code: '90018C', system: "TWProcedure", display: '乳牙根管治療-特殊' },
  Code { code: '90019C', system: "TWProcedure", display: '根管治療-小臼齒' },
  Code { code: '90020C', system: "TWProcedure", display: '根管治療-大臼齒' }
}

// 恆牙根管治療代碼 (用於分子-再治療)
define "Permanent Tooth Root Canal Treatment Codes": {
  Code { code: '90001C', system: "TWProcedure", display: '根管治療-單根管' },
  Code { code: '90002C', system: "TWProcedure", display: '根管治療-雙根管' },
  Code { code: '90003C', system: "TWProcedure", display: '根管治療-三根管以上' },
  Code { code: '90019C', system: "TWProcedure", display: '根管治療-小臼齒' },
  Code { code: '90020C', system: "TWProcedure", display: '根管治療-大臼齒' }
}

// 乳牙根管治療代碼 (用於分子-再治療)
define "Primary Tooth Root Canal Treatment Codes": {
  Code { code: '90016C', system: "TWProcedure", display: '乳牙根管治療' },
  Code { code: '90018C', system: "TWProcedure", display: '乳牙根管治療-特殊' }
}

// 拔牙代碼 (用於分子-失敗)
define "Tooth Extraction Codes": {
  Code { code: '92013C', system: "TWProcedure", display: '拔牙-簡單' },
  Code { code: '92014C', system: "TWProcedure", display: '拔牙-複雜' },
  Code { code: '92015C', system: "TWProcedure", display: '拔牙-特殊' }
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

// 檢查是否為根管開擴及清創
define function IsRootCanalOpening(procedure Procedure):
  GetProcedureCode(procedure) = '90015C'

// 檢查是否為任何根管治療
define function IsAnyRootCanalTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in {
    '90001C', '90002C', '90003C',
    '90016C', '90018C', '90019C', '90020C'
  }

// 檢查是否為恆牙根管治療 (用於分子)
define function IsPermanentToothRootCanalTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '90001C', '90002C', '90003C', '90019C', '90020C' }

// 檢查是否為乳牙根管治療 (用於分子)
define function IsPrimaryToothRootCanalTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '90016C', '90018C' }

// 檢查是否為拔牙 (用於分子)
define function IsToothExtraction(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '92013C', '92014C', '92015C' }

// 建立唯一識別碼: 機構+病患+牙位
define function GetToothIdentifier(procedure Procedure):
  GetOrganization(procedure) + '|' + GetPatientReference(procedure) + '|' + GetToothNumber(procedure)

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 六個月後期間終點 (用於追蹤失敗)
define "Six Months After End":
  MeasurementPeriodEnd + 6 months

// 六個月追蹤期間 (從觀察期開始到六個月後)
define "Extended Period For Tracking":
  Interval[MeasurementPeriodStart, "Six Months After End"]

// 觀察期間的所有Procedure
define "Procedures During Measurement Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'

// 擴展期間的所有Procedure (用於追蹤失敗)
define "Procedures During Extended Period":
  [Procedure] P
  where P.performed during "Extended Period For Tracking"
  and P.status.value = 'completed'

// 分母: 觀察期間根管治療顆數 (90015C + 任一根管治療醫令)
define "Denominator Treatments":
  "Procedures During Measurement Period" P
  let patientRef: GetPatientReference(P),
      organization: GetOrganization(P),
      toothNumber: GetToothNumber(P),
      // 檢查是否有根管開擴或任一根管治療
      hasOpening: IsRootCanalOpening(P),
      hasTreatment: IsAnyRootCanalTreatment(P),
      // 檢查同一牙位是否有對應的開擴或治療記錄
      relatedProcedures: "Procedures During Measurement Period" RP
                         where GetOrganization(RP) = organization
                         and GetPatientReference(RP) = patientRef
                         and GetToothNumber(RP) = toothNumber,
      hasRelatedOpening: exists(relatedProcedures RP where IsRootCanalOpening(RP)),
      hasRelatedTreatment: exists(relatedProcedures RP where IsAnyRootCanalTreatment(RP))
  where toothNumber is not null
  and (
    (hasOpening and hasRelatedTreatment) or
    (hasTreatment and hasRelatedOpening)
  )
  return {
    identifier: GetToothIdentifier(P),
    organization: organization,
    patient: patientRef,
    toothNumber: toothNumber,
    procedureDate: P.performed as FHIR.dateTime,
    procedure: P
  }

// 去重複的分母 (以牙位為單位)
define "Unique Denominator Teeth":
  distinct (
    "Denominator Treatments" DT
    return {
      identifier: DT.identifier,
      organization: DT.organization,
      patient: DT.patient,
      toothNumber: DT.toothNumber,
      procedureDate: DT.procedureDate
    }
  )

// 分子: 半年內再施行根管治療、乳牙根管治療或拔牙的牙齒顆數
define "Numerator Failures":
  "Unique Denominator Teeth" UDT
  let identifier: UDT.identifier,
      organization: UDT.organization,
      patient: UDT.patient,
      toothNumber: UDT.toothNumber,
      treatmentDate: UDT.procedureDate,
      sixMonthsAfter: treatmentDate + 6 months,
      // 找出六個月內的後續處置
      subsequentProcedures: "Procedures During Extended Period" P
                            where GetOrganization(P) = organization
                            and GetPatientReference(P) = patient
                            and GetToothNumber(P) = toothNumber
                            and P.performed as FHIR.dateTime > treatmentDate
                            and P.performed as FHIR.dateTime <= sixMonthsAfter,
      // 檢查是否有再治療或拔牙
      hasRetreatment: exists(
        subsequentProcedures P 
        where IsPermanentToothRootCanalTreatment(P) 
        or IsPrimaryToothRootCanalTreatment(P)
      ),
      hasExtraction: exists(
        subsequentProcedures P 
        where IsToothExtraction(P)
      )
  where hasRetreatment or hasExtraction
  return {
    identifier: identifier,
    organization: organization,
    patient: patient,
    toothNumber: toothNumber,
    treatmentDate: treatmentDate,
    hasRetreatment: hasRetreatment,
    hasExtraction: hasExtraction
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母總數
define "Denominator Count":
  Count("Unique Denominator Teeth")

// 分子總數 (失敗的顆數)
define "Numerator Count":
  Count("Numerator Failures")

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
    "Unique Denominator Teeth" UDT return UDT.organization
  ) Org
  let orgDenominator: "Unique Denominator Teeth" UDT where UDT.organization = Org,
      orgNumerator: "Numerator Failures" NF where NF.organization = Org,
      orgDenominatorCount: Count(orgDenominator),
      orgNumeratorCount: Count(orgNumerator),
      orgFailureRate: if orgDenominatorCount > 0 
                      then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
                      else null,
      orgRetentionRate: if orgFailureRate is not null
                        then Round(100.0 - orgFailureRate, 2)
                        else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    failureRate: orgFailureRate,
    retentionRate: orgRetentionRate
  }

// 依失敗類型分層
define "Results By Failure Type":
  "Numerator Failures" NF
  return {
    organization: NF.organization,
    toothNumber: NF.toothNumber,
    failureType: 
      if NF.hasRetreatment and NF.hasExtraction then '再治療+拔牙'
      else if NF.hasRetreatment then '再治療'
      else if NF.hasExtraction then '拔牙'
      else '未知'
  }

// 失敗時間分布
define "Failure Time Distribution":
  "Numerator Failures" NF
  let identifier: NF.identifier,
      organization: NF.organization,
      patient: NF.patient,
      toothNumber: NF.toothNumber,
      treatmentDate: NF.treatmentDate,
      sixMonthsAfter: treatmentDate + 6 months,
      // 找出第一次失敗處置
      firstFailure: First(
        "Procedures During Extended Period" P
        where GetOrganization(P) = organization
        and GetPatientReference(P) = patient
        and GetToothNumber(P) = toothNumber
        and P.performed as FHIR.dateTime > treatmentDate
        and P.performed as FHIR.dateTime <= sixMonthsAfter
        and (
          IsPermanentToothRootCanalTreatment(P) or
          IsPrimaryToothRootCanalTreatment(P) or
          IsToothExtraction(P)
        )
        sort by (performed as FHIR.dateTime)
      ),
      failureDate: firstFailure.performed as FHIR.dateTime,
      daysToFailure: if failureDate is not null
                     then days between treatmentDate and failureDate
                     else null
  where daysToFailure is not null
  return {
    identifier: identifier,
    daysToFailure: daysToFailure,
    monthsToFailure: Round(daysToFailure / 30.0, 1),
    timeCategory: 
      if daysToFailure <= 30 then '1個月內'
      else if daysToFailure <= 60 then '1-2個月'
      else if daysToFailure <= 90 then '2-3個月'
      else if daysToFailure <= 120 then '3-4個月'
      else if daysToFailure <= 150 then '4-5個月'
      else '5-6個月'
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Unique Denominator Teeth" UDT
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = UDT.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, UDT.procedureDate),
      ageGroup: 
        if age < 12 then '<12歲(含乳牙)'
        else if age < 20 then '12-19歲'
        else if age < 40 then '20-39歲'
        else if age < 60 then '40-59歲'
        else '>=60歲',
      inNumerator: UDT in ("Numerator Failures" NF 
                           where NF.identifier = UDT.identifier)
  return {
    ageGroup: ageGroup,
    inNumerator: inNumerator
  }

// 依性別分層
define "Results By Gender":
  "Unique Denominator Teeth" UDT
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = UDT.patient),
      gender: patient.gender.value,
      inNumerator: UDT in ("Numerator Failures" NF 
                           where NF.identifier = UDT.identifier)
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    inNumerator: inNumerator
  }

// 成功保存的案例
define "Successful Treatments":
  "Unique Denominator Teeth" UDT
  where not exists(
    "Numerator Failures" NF 
    where NF.identifier = UDT.identifier
  )

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '根管治療保存率-六個月以內',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    trackingPeriod: '6個月追蹤期',
    numerator: "Numerator Count",
    numeratorDefinition: '半年內再施行根管治療、乳牙根管治療或拔牙的牙齒顆數',
    denominator: "Denominator Count",
    denominatorDefinition: '根管治療顆數(90015C及根管治療任一醫令)',
    failureRate: "Failure Rate",
    retentionRate: "Retention Rate",
    successfulTreatments: Count("Successful Treatments"),
    unit: '%',
    formula: '[1 - (分子/分母)] x 100%'
  }
