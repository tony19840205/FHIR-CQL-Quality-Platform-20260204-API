/**
 * 指標名稱: 就診中醫門診後同日再次就診中醫之比率
 * 指標類別: 中醫照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 以醫事機構、病人代號、就醫日期歸戶，計算就診 2 次（含）以上之病人數
 * 分母: 以醫事機構、病人身分證號、就醫日期歸戶之病人數
 * 
 * 納入條件: 每季所有中醫門診就醫日診察費>0之案件
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_TCM_Same_Day_Revisit_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

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

// 中醫門診案件類型碼
define "TCM Outpatient Case Type": 
  Code { code: '05', system: 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type', display: '中醫門診' }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Encounter, url String):
  singleton from (
    element.extension E where E.url.value = url
  ).value.value

// 取得Extension decimal值
define function GetExtensionDecimal(element FHIR.Encounter, url String):
  singleton from (
    element.extension E where E.url.value = url
  ).value.value

// 取得Encounter的案件類型
define function GetEncounterCaseType(encounter Encounter):
  if encounter.class is not null
  then encounter.class.code.value
  else null

// 取得Encounter的醫療機構
define function GetEncounterOrganization(encounter Encounter):
  if encounter.serviceProvider is not null
  then encounter.serviceProvider.reference.value
  else GetExtensionString(encounter, 'organizationReference')

// 取得Patient Reference
define function GetPatientReference(encounter Encounter):
  encounter.subject.reference.value

// 取得診察費金額
define function GetConsultationFee(encounter Encounter):
  GetExtensionDecimal(encounter, 'consultationFee')

// 取得就醫日期（僅日期部分，不含時間）
define function GetVisitDate(encounter Encounter):
  date from encounter.period.start

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

// 符合條件的中醫門診就醫（診察費>0）
define "TCM Outpatient Visits":
  "Encounters During Measurement Period" E
  let caseType: GetEncounterCaseType(E),
      consultationFee: GetConsultationFee(E)
  where caseType = '05'  // 中醫門診
  and consultationFee > 0
  return {
    encounterId: 'Encounter/' + E.id,
    patient: GetPatientReference(E),
    organization: GetEncounterOrganization(E),
    visitDate: GetVisitDate(E),
    visitDateTime: E.period.start,
    consultationFee: consultationFee
  }

// 分母: 以醫事機構、病人身分證號、就醫日期歸戶之病人數
define "Denominator":
  distinct (
    "TCM Outpatient Visits" V
    return {
      organization: V.organization,
      patient: V.patient,
      visitDate: V.visitDate
    }
  )

// 同日多次就診分析（計算每個病人每日就診次數）
define "Same Day Visit Counts":
  "Denominator" D
  let sameDayVisits: "TCM Outpatient Visits" V
                      where V.organization = D.organization
                      and V.patient = D.patient
                      and V.visitDate = D.visitDate,
      visitCount: Count(sameDayVisits)
  return {
    organization: D.organization,
    patient: D.patient,
    visitDate: D.visitDate,
    visitCount: visitCount,
    hasMultipleVisits: visitCount >= 2
  }

// 分子: 同日就診 2 次（含）以上之病人數
define "Numerator":
  "Same Day Visit Counts" C
  where C.hasMultipleVisits
  return {
    organization: C.organization,
    patient: C.patient,
    visitDate: C.visitDate,
    visitCount: C.visitCount
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母病人數
define "Denominator Count":
  Count("Denominator")

// 分子病人數（同日多次就診）
define "Numerator Count":
  Count("Numerator")

// 同日再次就診之比率 (分子/分母)
define "Same Day Revisit Rate":
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
      orgRevisitRate: if orgDenominatorCount > 0 
                      then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
                      else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    revisitRate: orgRevisitRate
  }

// 依就診次數分層
define "Results By Visit Count":
  "Numerator" N
  let visitCategory: 
    if N.visitCount = 2 then '2次就診'
    else if N.visitCount = 3 then '3次就診'
    else if N.visitCount = 4 then '4次就診'
    else '5次以上就診'
  return {
    visitCount: N.visitCount,
    visitCategory: visitCategory,
    patient: N.patient,
    organization: N.organization
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Denominator" D
  let hasMultipleVisits: exists(
        "Numerator" N 
        where N.patient = D.patient 
        and N.visitDate = D.visitDate
        and N.organization = D.organization
      )
  return {
    patient: D.patient,
    hasMultipleVisits: hasMultipleVisits
  }

// 依性別分層
define "Results By Gender":
  "Denominator" D
  let hasMultipleVisits: exists(
        "Numerator" N 
        where N.patient = D.patient 
        and N.visitDate = D.visitDate
        and N.organization = D.organization
      )
  return {
    patient: D.patient,
    hasMultipleVisits: hasMultipleVisits
  }

// 月度趨勢分析
define "Results By Month":
  "Denominator" D
  let hasMultipleVisits: exists(
        "Numerator" N 
        where N.patient = D.patient 
        and N.visitDate = D.visitDate
        and N.organization = D.organization
      )
  return {
    visitDate: D.visitDate,
    hasMultipleVisits: hasMultipleVisits
  }

// 星期分布分析
define "Results By Day Of Week":
  "Denominator" D
  let hasMultipleVisits: exists(
        "Numerator" N 
        where N.patient = D.patient 
        and N.visitDate = D.visitDate
        and N.organization = D.organization
      )
  return {
    visitDate: D.visitDate,
    hasMultipleVisits: hasMultipleVisits
  }

// 同日就診時間間隔分析
define "Same Day Visit Time Interval Analysis":
  "Numerator" N
  let visits: "TCM Outpatient Visits" V
              where V.organization = N.organization
              and V.patient = N.patient
              and V.visitDate = N.visitDate,
      sortedVisits: visits V sort by visitDateTime,
      firstVisit: First(sortedVisits),
      lastVisit: Last(sortedVisits),
      timeInterval: if Count(sortedVisits) > 1
                    then hours between firstVisit.visitDateTime and lastVisit.visitDateTime
                    else null
  where timeInterval is not null
  return {
    patient: N.patient,
    organization: N.organization,
    visitDate: N.visitDate,
    visitCount: N.visitCount,
    timeInterval: timeInterval,
    intervalCategory: 
      if timeInterval < 1 then '<1小時'
      else if timeInterval < 2 then '1-2小時'
      else if timeInterval < 4 then '2-4小時'
      else if timeInterval < 6 then '4-6小時'
      else '6小時以上'
  }

// 單次就診患者
define "Single Visit Patients":
  "Denominator" D
  where not exists(
    "Numerator" N 
    where N.patient = D.patient 
    and N.visitDate = D.visitDate
    and N.organization = D.organization
  )
  return {
    patient: D.patient,
    organization: D.organization,
    visitDate: D.visitDate
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '就診中醫門診後同日再次就診中醫之比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '同日就診 2 次（含）以上之病人數（以醫事機構、病人代號、就醫日期歸戶）',
    denominator: "Denominator Count",
    denominatorDefinition: '就診病人數（以醫事機構、病人身分證號、就醫日期歸戶）',
    inclusionCriteria: '中醫門診就醫日診察費>0之案件',
    sameDayRevisitRate: "Same Day Revisit Rate",
    singleVisitPatients: Count("Single Visit Patients"),
    totalVisits: Count("TCM Outpatient Visits"),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
