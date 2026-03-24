/**
 * 指標名稱: 根管治療保存率-恆牙六個月以內
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: [1 - (分子/分母)] x 100%
 * 
 * 分子: 醫事機構每季就醫病人恆牙根管治療後180天內再施行根管治療顆數或拔牙顆數
 * 分母: 醫事機構每季恆牙根管治療顆數（申報90015C及恆牙根管治療任一醫令者）
 * 
 * 分子條件:
 * 1. 恆牙根管治療單根顆數: 健保代碼90001C
 * 2. 恆牙根管治療雙根顆數: 健保代碼90002C
 * 3. 恆牙根管治療三根顆數: 健保代碼90003C
 * 4. 恆牙根管治療四根顆數: 健保代碼90019C
 * 5. 恆牙根管治療五根顆數: 健保代碼90020C
 * 6. 拔牙顆數: 健保代碼92013C、92014C、92015C、92016C
 * 
 * 分母條件: 申報90015C及恆牙根管治療任一醫令者
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Root_Canal_Treatment_Retention_Rate_Permanent_Tooth_6Months version '1.0.0'

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

// 恆牙根管治療代碼 (用於分母和分子)
define "Permanent Tooth Root Canal Treatment Codes": {
  Code { code: '90001C', system: "TWProcedure", display: '恆牙根管治療-單根' },
  Code { code: '90002C', system: "TWProcedure", display: '恆牙根管治療-雙根' },
  Code { code: '90003C', system: "TWProcedure", display: '恆牙根管治療-三根' },
  Code { code: '90019C', system: "TWProcedure", display: '恆牙根管治療-四根(小臼齒)' },
  Code { code: '90020C', system: "TWProcedure", display: '恆牙根管治療-五根(大臼齒)' }
}

// 拔牙代碼 (用於分子-失敗)
define "Tooth Extraction Codes": {
  Code { code: '92013C', system: "TWProcedure", display: '拔牙-簡單' },
  Code { code: '92014C', system: "TWProcedure", display: '拔牙-複雜' },
  Code { code: '92015C', system: "TWProcedure", display: '拔牙-特殊' },
  Code { code: '92016C', system: "TWProcedure", display: '拔牙-其他' }
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

// 檢查是否為恆牙根管治療
define function IsPermanentToothRootCanalTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '90001C', '90002C', '90003C', '90019C', '90020C' }

// 檢查是否為拔牙 (用於分子)
define function IsToothExtraction(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '92013C', '92014C', '92015C', '92016C' }

// 建立唯一識別碼: 機構+病患+牙位
define function GetToothIdentifier(procedure Procedure):
  GetOrganization(procedure) + '|' + GetPatientReference(procedure) + '|' + GetToothNumber(procedure)

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 六個月(180天)後期間終點
define "Six Months After End":
  MeasurementPeriodEnd + 180 days

// 擴展追蹤期間 (從觀察期開始到六個月後)
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

// 分母: 觀察期間恆牙根管治療顆數 (90015C + 恆牙根管治療醫令)
define "Denominator Treatments":
  "Procedures During Measurement Period" P
  let patientRef: GetPatientReference(P),
      organization: GetOrganization(P),
      toothNumber: GetToothNumber(P),
      // 檢查是否為根管開擴或恆牙根管治療
      hasOpening: IsRootCanalOpening(P),
      hasTreatment: IsPermanentToothRootCanalTreatment(P),
      // 檢查同一牙位是否有對應的開擴或治療記錄
      relatedProcedures: "Procedures During Measurement Period" RP
                         where GetOrganization(RP) = organization
                         and GetPatientReference(RP) = patientRef
                         and GetToothNumber(RP) = toothNumber,
      hasRelatedOpening: exists(relatedProcedures RP where IsRootCanalOpening(RP)),
      hasRelatedTreatment: exists(relatedProcedures RP where IsPermanentToothRootCanalTreatment(RP))
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

// 分子: 180天內再施行恆牙根管治療或拔牙的牙齒顆數
define "Numerator Failures":
  "Unique Denominator Teeth" UDT
  let identifier: UDT.identifier,
      organization: UDT.organization,
      patient: UDT.patient,
      toothNumber: UDT.toothNumber,
      treatmentDate: UDT.procedureDate,
      oneSixtyDaysAfter: treatmentDate + 180 days,
      // 找出180天內的後續處置
      subsequentProcedures: "Procedures During Extended Period" P
                            where GetOrganization(P) = organization
                            and GetPatientReference(P) = patient
                            and GetToothNumber(P) = toothNumber
                            and P.performed as FHIR.dateTime > treatmentDate
                            and P.performed as FHIR.dateTime <= oneSixtyDaysAfter,
      // 檢查是否有恆牙再治療或拔牙
      hasRetreatment: exists(
        subsequentProcedures P 
        where IsPermanentToothRootCanalTreatment(P)
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

// 依根管數量分層 (根據初始治療代碼)
define "Results By Root Count":
  "Unique Denominator Teeth" UDT
  let procedures: "Procedures During Measurement Period" P
                  where GetToothIdentifier(P) = UDT.identifier
                  and IsPermanentToothRootCanalTreatment(P),
      treatmentCodes: procedures P return GetProcedureCode(P),
      rootCount: 
        if exists(treatmentCodes C where C = '90001C') then '單根'
        else if exists(treatmentCodes C where C = '90002C') then '雙根'
        else if exists(treatmentCodes C where C = '90003C') then '三根'
        else if exists(treatmentCodes C where C = '90019C') then '四根(小臼齒)'
        else if exists(treatmentCodes C where C = '90020C') then '五根(大臼齒)'
        else '未知',
      inNumerator: UDT in ("Numerator Failures" NF 
                           where NF.identifier = UDT.identifier)
  return {
    rootCount: rootCount,
    inNumerator: inNumerator
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
      oneSixtyDaysAfter: treatmentDate + 180 days,
      // 找出第一次失敗處置
      firstFailure: First(
        "Procedures During Extended Period" P
        where GetOrganization(P) = organization
        and GetPatientReference(P) = patient
        and GetToothNumber(P) = toothNumber
        and P.performed as FHIR.dateTime > treatmentDate
        and P.performed as FHIR.dateTime <= oneSixtyDaysAfter
        and (
          IsPermanentToothRootCanalTreatment(P) or
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
        if age < 20 then '<20歲'
        else if age < 30 then '20-29歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
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

// 依牙位類型分層
define "Results By Tooth Position":
  "Unique Denominator Teeth" UDT
  let toothNumber: UDT.toothNumber,
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
      inNumerator: UDT in ("Numerator Failures" NF 
                           where NF.identifier = UDT.identifier)
  return {
    toothType: toothType,
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
    indicatorName: '根管治療保存率-恆牙六個月以內',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    trackingPeriod: '180天(6個月)追蹤期',
    toothType: '恆牙',
    numerator: "Numerator Count",
    numeratorDefinition: '180天內再施行恆牙根管治療或拔牙的牙齒顆數',
    numeratorCodes: '90001C-90003C, 90019C-90020C (再治療), 92013C-92016C (拔牙)',
    denominator: "Denominator Count",
    denominatorDefinition: '恆牙根管治療顆數(90015C及恆牙根管治療任一醫令)',
    denominatorCodes: '90015C + 90001C-90003C, 90019C-90020C',
    failureRate: "Failure Rate",
    retentionRate: "Retention Rate",
    successfulTreatments: Count("Successful Treatments"),
    unit: '%',
    formula: '[1 - (分子/分母)] x 100%'
  }
