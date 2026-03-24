/**
 * 指標名稱: 六歲以下兒童執行口腔預防保健服務之比率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 醫療院所執行兒童牙齒預防保健服務的人數
 * 分母: 醫療院所就醫人口中6歲以下兒童人數
 * 
 * 分母條件: 年齡的計算為就醫年月 - 出生年月 ≤ 72(個月)
 * 分子條件: 兒童牙齒預防保健服務的健保卡序號欄位為「IC81」、「IC87」
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Pediatric_Under_6_Oral_Preventive_Health_Service_Rate version '1.0.0'

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

// 兒童牙齒預防保健服務健保卡序號代碼
define "Pediatric Oral Preventive Service Codes": {
  Code { code: 'IC81', system: "TWProcedure", display: '兒童牙齒預防保健服務-IC81' },
  Code { code: 'IC87', system: "TWProcedure", display: '兒童牙齒預防保健服務-IC87' }
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

// 取得Encounter Reference
define function GetEncounterReference(procedure Procedure):
  if procedure.encounter is not null
  then procedure.encounter.reference.value
  else null

// 取得Encounter的案件類型
define function GetEncounterCaseType(encounter Encounter):
  if encounter.class is not null
  then encounter.class.code.value
  else null

// 取得就醫序號 (健保卡序號)
define function GetServiceSequenceNumber(encounter Encounter):
  GetExtensionString(encounter, 'serviceSequenceNumber')

// 取得Encounter的醫療機構
define function GetEncounterOrganization(encounter Encounter):
  if encounter.serviceProvider is not null
  then encounter.serviceProvider.reference.value
  else GetExtensionString(encounter, 'organizationReference')

// 檢查是否為兒童牙齒預防保健服務
define function IsPediatricOralPreventiveService(serviceCode String):
  serviceCode in { 'IC81', 'IC87' }

// 計算年齡（月數）
define function CalculateAgeInMonths(birthDate Date, visitDate DateTime):
  months between birthDate and (visitDate as Date)

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

// 牙醫門診的所有Encounter
define "Dental Outpatient Encounters":
  "Encounters During Measurement Period" E
  where GetEncounterCaseType(E) = '04'  // 門診

// 分母: 6歲以下兒童（就醫年月 - 出生年月 ≤ 72個月）
define "Denominator":
  "Dental Outpatient Encounters" E
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = E.subject.reference.value),
      birthDate: patient.birthDate.value,
      visitDate: E.period.start,
      ageInMonths: CalculateAgeInMonths(birthDate, visitDate)
  where ageInMonths <= 72
  return {
    patient: E.subject.reference.value,
    organization: GetEncounterOrganization(E),
    ageInMonths: ageInMonths,
    visitDate: visitDate
  }

// 兒童牙齒預防保健服務案件 (健保卡序號為IC81或IC87)
define "Pediatric Oral Preventive Service Cases":
  "Dental Outpatient Encounters" E
  let serviceSeq: GetServiceSequenceNumber(E),
      patient: singleton from ([Patient] P where 'Patient/' + P.id = E.subject.reference.value),
      birthDate: patient.birthDate.value,
      visitDate: E.period.start,
      ageInMonths: CalculateAgeInMonths(birthDate, visitDate)
  where IsPediatricOralPreventiveService(serviceSeq)
  and ageInMonths <= 72
  return {
    encounterId: 'Encounter/' + E.id,
    patient: E.subject.reference.value,
    organization: GetEncounterOrganization(E),
    serviceCode: serviceSeq,
    ageInMonths: ageInMonths,
    visitDate: visitDate
  }

// 分子: 執行兒童牙齒預防保健服務的人數（去重複）
define "Numerator":
  distinct (
    "Pediatric Oral Preventive Service Cases" C
    return {
      patient: C.patient,
      organization: C.organization
    }
  )

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

// 分子人數
define "Numerator Count":
  Count(
    distinct (
      "Numerator" N return N.patient
    )
  )

// 服務執行率 (分子/分母)
define "Service Rate":
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
      orgServiceRate: if orgDenominatorCount > 0 
                      then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
                      else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    serviceRate: orgServiceRate
  }

// 依服務代碼分層 (分子)
define "Results By Service Code":
  "Pediatric Oral Preventive Service Cases" C
  return {
    serviceCode: C.serviceCode,
    patient: C.patient
  }

// 依兒童年齡分層（月齡）
define "Results By Age In Months":
  "Denominator" D
  let ageGroup: 
    if D.ageInMonths <= 6 then '0-6個月'
    else if D.ageInMonths <= 12 then '7-12個月'
    else if D.ageInMonths <= 18 then '13-18個月'
    else if D.ageInMonths <= 24 then '19-24個月'
    else if D.ageInMonths <= 36 then '25-36個月'
    else if D.ageInMonths <= 48 then '37-48個月'
    else if D.ageInMonths <= 60 then '49-60個月'
    else '61-72個月',
      hasService: exists(
        "Pediatric Oral Preventive Service Cases" C 
        where C.patient = D.patient
      )
  return {
    ageGroup: ageGroup,
    ageInMonths: D.ageInMonths,
    hasService: hasService
  }

// 依性別分層
define "Results By Gender":
  "Denominator" D
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = D.patient),
      gender: patient.gender.value,
      hasService: exists(
        "Pediatric Oral Preventive Service Cases" C 
        where C.patient = D.patient
      )
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    hasService: hasService
  }

// 月度趨勢分析
define "Results By Month":
  "Pediatric Oral Preventive Service Cases" C
  let month: ToString(month from C.visitDate) + '月'
  return {
    month: month,
    patient: C.patient
  }

// 未接受預防保健服務的兒童
define "Children Without Preventive Service":
  "Denominator" D
  where not exists(
    "Pediatric Oral Preventive Service Cases" C 
    where C.patient = D.patient
  )
  return {
    patient: D.patient,
    organization: D.organization,
    ageInMonths: D.ageInMonths
  }

// 兒童服務頻率分析
define "Child Service Frequency":
  distinct (
    "Pediatric Oral Preventive Service Cases" C return C.patient
  ) PatientRef
  let serviceCases: "Pediatric Oral Preventive Service Cases" C 
                    where C.patient = PatientRef,
      serviceCount: Count(serviceCases),
      firstServiceDate: First(serviceCases C sort by visitDate).visitDate,
      lastServiceDate: Last(serviceCases C sort by visitDate).visitDate,
      daysInterval: if serviceCount > 1
                    then days between firstServiceDate and lastServiceDate
                    else null,
      frequencyCategory: 
        if serviceCount = 1 then '單次服務'
        else if serviceCount = 2 then '2次服務'
        else if serviceCount = 3 then '3次服務'
        else '4次以上服務'
  return {
    patient: PatientRef,
    serviceCount: serviceCount,
    frequencyCategory: frequencyCategory,
    firstServiceDate: firstServiceDate,
    lastServiceDate: lastServiceDate,
    daysInterval: daysInterval
  }

// 服務間隔分析
define "Service Interval Analysis":
  "Child Service Frequency" Freq
  where Freq.serviceCount > 1
  and Freq.daysInterval is not null
  let intervalCategory: 
    if Freq.daysInterval <= 30 then '1個月內'
    else if Freq.daysInterval <= 90 then '1-3個月'
    else if Freq.daysInterval <= 180 then '3-6個月'
    else '6個月以上'
  return {
    patient: Freq.patient,
    serviceCount: Freq.serviceCount,
    daysInterval: Freq.daysInterval,
    intervalCategory: intervalCategory
  }

// 首次服務年齡分析
define "First Service Age Analysis":
  distinct (
    "Pediatric Oral Preventive Service Cases" C return C.patient
  ) PatientRef
  let firstService: First("Pediatric Oral Preventive Service Cases" C 
                         where C.patient = PatientRef 
                         sort by visitDate),
      firstServiceAge: firstService.ageInMonths,
      ageCategory: 
        if firstServiceAge <= 12 then '1歲以內'
        else if firstServiceAge <= 24 then '1-2歲'
        else if firstServiceAge <= 36 then '2-3歲'
        else if firstServiceAge <= 48 then '3-4歲'
        else if firstServiceAge <= 60 then '4-5歲'
        else '5-6歲'
  return {
    patient: PatientRef,
    firstServiceAge: firstServiceAge,
    ageCategory: ageCategory
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '六歲以下兒童執行口腔預防保健服務之比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '醫療院所執行兒童牙齒預防保健服務的人數',
    numeratorCodes: 'IC81, IC87 (健保卡序號)',
    denominator: "Denominator Count",
    denominatorDefinition: '醫療院所就醫人口中6歲以下兒童人數',
    denominatorCriteria: '就醫年月 - 出生年月 ≤ 72個月',
    serviceRate: "Service Rate",
    childrenWithoutService: Count("Children Without Preventive Service"),
    totalServiceCases: Count("Pediatric Oral Preventive Service Cases"),
    childrenWithMultipleServices: Count("Child Service Frequency" F where F.serviceCount > 1),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
