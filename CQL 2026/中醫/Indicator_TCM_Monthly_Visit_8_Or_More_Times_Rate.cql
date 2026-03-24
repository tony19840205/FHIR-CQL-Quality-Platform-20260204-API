/**
 * 指標名稱: 同一中醫院所就診次數每月達八次以上之比率
 * 指標類別: 中醫照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 同一院所、同一患者、該月看診次數超出8次（含）以上者
 * 分母: 同一院所、該月患者看診人數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_TCM_Monthly_Visit_8_Or_More_Times_Rate version '1.0.0'

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

// 取得就醫年月 (YYYY-MM格式)
define function GetVisitYearMonth(encounter Encounter):
  ToString(year from encounter.period.start) + '-' + 
  ToString(month from encounter.period.start)

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

// 中醫門診就醫案件
define "TCM Outpatient Visits":
  "Encounters During Measurement Period" E
  where GetEncounterCaseType(E) = '05'  // 中醫門診
  return {
    encounterId: 'Encounter/' + E.id,
    patient: GetPatientReference(E),
    organization: GetEncounterOrganization(E),
    visitDateTime: E.period.start,
    visitYearMonth: GetVisitYearMonth(E)
  }

// 按院所、患者、年月歸戶的就診次數統計
define "Monthly Visit Counts By Organization And Patient":
  distinct (
    "TCM Outpatient Visits" V
    return {
      organization: V.organization,
      patient: V.patient,
      yearMonth: V.visitYearMonth
    }
  ) Group
  let monthlyVisits: "TCM Outpatient Visits" V
                     where V.organization = Group.organization
                     and V.patient = Group.patient
                     and V.visitYearMonth = Group.yearMonth,
      visitCount: Count(monthlyVisits)
  return {
    organization: Group.organization,
    patient: Group.patient,
    yearMonth: Group.yearMonth,
    visitCount: visitCount,
    has8OrMoreVisits: visitCount >= 8
  }

// 分母: 同一院所、該月患者看診人數
define "Denominator":
  "Monthly Visit Counts By Organization And Patient"

// 分子: 該月看診次數≥8次的患者
define "Numerator":
  "Monthly Visit Counts By Organization And Patient" C
  where C.has8OrMoreVisits

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母人數
define "Denominator Count":
  Count("Denominator")

// 分子人數（每月就診≥8次）
define "Numerator Count":
  Count("Numerator")

// 每月就診≥8次之比率
define "Monthly Visit 8 Or More Rate":
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
      orgRate: if orgDenominatorCount > 0 
               then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
               else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    rate: orgRate
  }

// 依年月分層
define "Results By Year Month":
  distinct (
    "Denominator" D return D.yearMonth
  ) YearMonth
  let monthDenominator: "Denominator" D where D.yearMonth = YearMonth,
      monthNumerator: "Numerator" N where N.yearMonth = YearMonth,
      monthDenominatorCount: Count(monthDenominator),
      monthNumeratorCount: Count(monthNumerator),
      monthRate: if monthDenominatorCount > 0 
                 then Round((monthNumeratorCount / monthDenominatorCount) * 100.0, 2)
                 else null
  return {
    yearMonth: YearMonth,
    denominator: monthDenominatorCount,
    numerator: monthNumeratorCount,
    rate: monthRate
  }
  sort by yearMonth

// 依就診次數分層
define "Results By Visit Count":
  "Numerator" N
  let visitCategory: 
    if N.visitCount = 8 then '8次'
    else if N.visitCount = 9 then '9次'
    else if N.visitCount = 10 then '10次'
    else if N.visitCount <= 15 then '11-15次'
    else if N.visitCount <= 20 then '16-20次'
    else '20次以上'
  return {
    visitCount: N.visitCount,
    visitCategory: visitCategory,
    patient: N.patient,
    organization: N.organization,
    yearMonth: N.yearMonth
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Denominator" D
  let has8OrMoreVisits: D.has8OrMoreVisits
  return {
    patient: D.patient,
    has8OrMoreVisits: has8OrMoreVisits,
    visitCount: D.visitCount
  }

// 依性別分層
define "Results By Gender":
  "Denominator" D
  let has8OrMoreVisits: D.has8OrMoreVisits
  return {
    patient: D.patient,
    has8OrMoreVisits: has8OrMoreVisits,
    visitCount: D.visitCount
  }

// 就診次數<8次的患者
define "Patients With Less Than 8 Visits":
  "Denominator" D
  where not D.has8OrMoreVisits
  return {
    patient: D.patient,
    organization: D.organization,
    yearMonth: D.yearMonth,
    visitCount: D.visitCount
  }

// 機構月度詳細分析
define "Organization Monthly Analysis":
  distinct (
    "Denominator" D 
    return {
      organization: D.organization,
      yearMonth: D.yearMonth
    }
  ) Group
  let monthlyPatients: "Denominator" D
                       where D.organization = Group.organization
                       and D.yearMonth = Group.yearMonth,
      totalPatients: Count(monthlyPatients),
      patientsWith8OrMore: Count(monthlyPatients D where D.has8OrMoreVisits),
      rate: if totalPatients > 0
            then Round((patientsWith8OrMore / totalPatients) * 100.0, 2)
            else null,
      avgVisitsPerPatient: Round(
        Avg(monthlyPatients D return D.visitCount), 2
      ),
      maxVisits: Max(monthlyPatients D return D.visitCount)
  return {
    organization: Group.organization,
    yearMonth: Group.yearMonth,
    totalPatients: totalPatients,
    patientsWith8OrMore: patientsWith8OrMore,
    rate: rate,
    avgVisitsPerPatient: avgVisitsPerPatient,
    maxVisits: maxVisits
  }

// 高頻就診患者詳細分析
define "High Frequency Patients Detail":
  "Numerator" N
  return {
    patient: N.patient,
    organization: N.organization,
    yearMonth: N.yearMonth,
    visitCount: N.visitCount
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '同一中醫院所就診次數每月達八次以上之比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '同一院所、同一患者、該月看診次數≥8次者',
    denominator: "Denominator Count",
    denominatorDefinition: '同一院所、該月患者看診人數',
    rate: "Monthly Visit 8 Or More Rate",
    totalVisits: Count("TCM Outpatient Visits"),
    totalPatients: Count(distinct ("TCM Outpatient Visits" V return V.patient)),
    patientsWithLessThan8Visits: Count("Patients With Less Than 8 Visits"),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
