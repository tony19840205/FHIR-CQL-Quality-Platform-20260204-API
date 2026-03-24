/**
 * 指標名稱: 執行口腔癌篩檢之案件數
 * 指標類別: 牙科照護品質指標 - 統計數量型指標
 * 計算頻率: 每季
 * 指標定義: 醫事機構該季實施口腔癌篩檢(案件分類為A3且就醫序號為IC95)之案件數
 * 
 * 指標類型: 統計數量型指標（無分子分母，統計符合條件的案件總數）
 * 
 * 篩檢條件:
 * - 案件分類: A3
 * - 就醫序號: IC95
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Oral_Cancer_Screening_Case_Count version '1.0.0'

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

// 口腔癌篩檢案件分類碼
define "Oral Cancer Screening Case Type": 
  Code { code: 'A3', system: "TWCaseType", display: '口腔癌篩檢' }

// 口腔癌篩檢就醫序號
define "Oral Cancer Screening Service Code": 
  Code { code: 'IC95', system: "TWProcedure", display: '口腔癌篩檢' }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Encounter的案件類型
define function GetEncounterCaseType(encounter Encounter):
  if encounter.type is not null and Count(encounter.type) > 0
  then (
    singleton from (
      encounter.type[0].coding C 
      where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
    )
  ).code.value
  else null

// 取得就醫序號 (從Encounter的identifier或extension)
define function GetServiceSequenceNumber(encounter Encounter):
  GetExtensionString(encounter, 'serviceSequenceNumber')

// 取得Encounter的醫療機構
define function GetEncounterOrganization(encounter Encounter):
  if encounter.serviceProvider is not null
  then encounter.serviceProvider.reference.value
  else GetExtensionString(encounter, 'organizationReference')

// 取得Patient Reference
define function GetPatientReference(encounter Encounter):
  encounter.subject.reference.value

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

// 口腔癌篩檢案件
define "Oral Cancer Screening Cases":
  "Encounters During Measurement Period" E
  let caseType: GetEncounterCaseType(E),
      serviceSeq: GetServiceSequenceNumber(E)
  where caseType = 'A3'
  and serviceSeq = 'IC95'
  return {
    encounterId: 'Encounter/' + E.id,
    patient: GetPatientReference(E),
    organization: GetEncounterOrganization(E),
    encounterDate: E.period.start,
    caseType: caseType,
    serviceSequenceNumber: serviceSeq
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 總案件數
define "Total Screening Cases":
  Count("Oral Cancer Screening Cases")

// 總服務人數 (去重複)
define "Total Patients Screened":
  Count(
    distinct (
      "Oral Cancer Screening Cases" C return C.patient
    )
  )

// 總服務機構數
define "Total Organizations":
  Count(
    distinct (
      "Oral Cancer Screening Cases" C return C.organization
    )
  )

// 平均每人篩檢次數
define "Average Screenings Per Patient":
  if "Total Patients Screened" > 0
  then Round("Total Screening Cases" / "Total Patients Screened", 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層
define "Results By Organization":
  distinct (
    "Oral Cancer Screening Cases" C return C.organization
  ) Org
  let orgCases: "Oral Cancer Screening Cases" C where C.organization = Org,
      orgCaseCount: Count(orgCases),
      orgPatientCount: Count(distinct (orgCases C return C.patient)),
      orgAvgPerPatient: if orgPatientCount > 0
                        then Round(orgCaseCount / orgPatientCount, 2)
                        else null
  return {
    organization: Org,
    totalCases: orgCaseCount,
    totalPatients: orgPatientCount,
    avgScreeningsPerPatient: orgAvgPerPatient
  }
  sort by totalCases desc

// 依患者年齡分層
define "Results By Patient Age":
  "Oral Cancer Screening Cases" C
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = C.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, C.encounterDate),
      ageGroup: 
        if age < 30 then '<30歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
        else if age < 70 then '60-69歲'
        else '>=70歲'
  return {
    ageGroup: ageGroup,
    age: age,
    patient: C.patient
  }

// 依性別分層
define "Results By Gender":
  "Oral Cancer Screening Cases" C
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = C.patient),
      gender: patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    patient: C.patient
  }

// 月度趨勢分析
define "Results By Month":
  "Oral Cancer Screening Cases" C
  let month: ToString(month from C.encounterDate) + '月'
  return {
    month: month,
    encounterId: C.encounterId
  }

// 患者篩檢頻率分析
define "Patient Screening Frequency":
  distinct (
    "Oral Cancer Screening Cases" C return C.patient
  ) PatientRef
  let screeningCases: "Oral Cancer Screening Cases" C where C.patient = PatientRef,
      screeningCount: Count(screeningCases),
      firstScreeningDate: First(screeningCases C sort by encounterDate).encounterDate,
      lastScreeningDate: Last(screeningCases C sort by encounterDate).encounterDate,
      daysInterval: if screeningCount > 1
                    then days between firstScreeningDate and lastScreeningDate
                    else null,
      frequencyCategory: 
        if screeningCount = 1 then '單次篩檢'
        else if screeningCount = 2 then '2次篩檢'
        else if screeningCount = 3 then '3次篩檢'
        else '4次以上篩檢'
  return {
    patient: PatientRef,
    screeningCount: screeningCount,
    frequencyCategory: frequencyCategory,
    firstScreeningDate: firstScreeningDate,
    lastScreeningDate: lastScreeningDate,
    daysInterval: daysInterval
  }

// 重複篩檢間隔分析
define "Repeat Screening Interval Analysis":
  "Patient Screening Frequency" Freq
  where Freq.screeningCount > 1
  and Freq.daysInterval is not null
  let intervalCategory: 
    if Freq.daysInterval <= 30 then '1個月內'
    else if Freq.daysInterval <= 90 then '1-3個月'
    else if Freq.daysInterval <= 180 then '3-6個月'
    else '6個月以上'
  return {
    patient: Freq.patient,
    screeningCount: Freq.screeningCount,
    daysInterval: Freq.daysInterval,
    intervalCategory: intervalCategory
  }

// 機構服務規模分類
define "Organization Service Scale":
  "Results By Organization" OrgStats
  let scale: 
    if OrgStats.totalCases >= 100 then '大規模 (>=100案件)'
    else if OrgStats.totalCases >= 50 then '中規模 (50-99案件)'
    else if OrgStats.totalCases >= 20 then '小規模 (20-49案件)'
    else '微規模 (<20案件)'
  return {
    organization: OrgStats.organization,
    totalCases: OrgStats.totalCases,
    scale: scale
  }

// 週別分布分析
define "Results By Week":
  "Oral Cancer Screening Cases" C
  let weekOfYear: ToString(weeks between @2026-01-01 and C.encounterDate) + '週'
  return {
    week: weekOfYear,
    encounterId: C.encounterId
  }

// 患者人口學特徵綜合分析
define "Patient Demographics Analysis":
  distinct (
    "Oral Cancer Screening Cases" C return C.patient
  ) PatientRef
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = PatientRef),
      firstScreening: First("Oral Cancer Screening Cases" C 
                           where C.patient = PatientRef 
                           sort by encounterDate),
      age: AgeInYearsAt(patient.birthDate.value, firstScreening.encounterDate),
      gender: patient.gender.value,
      screeningCount: Count("Oral Cancer Screening Cases" C where C.patient = PatientRef)
  return {
    patient: PatientRef,
    age: age,
    gender: if gender = 'male' then '男性'
            else if gender = 'female' then '女性'
            else '其他',
    screeningCount: screeningCount,
    organization: firstScreening.organization
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '執行口腔癌篩檢之案件數',
    indicatorType: '統計數量型指標',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    definition: '醫事機構該季實施口腔癌篩檢(案件分類為A3且就醫序號為IC95)之案件數',
    criteria: '案件分類為A3且就醫序號為IC95',
    
    // 主要統計數據
    totalScreeningCases: "Total Screening Cases",
    totalPatientsScreened: "Total Patients Screened",
    totalOrganizations: "Total Organizations",
    averageScreeningsPerPatient: "Average Screenings Per Patient",
    
    // 分層分析結果
    organizationStatistics: "Results By Organization",
    ageDistribution: "Results By Patient Age",
    genderDistribution: "Results By Gender",
    monthlyTrend: "Results By Month",
    patientScreeningFrequency: "Patient Screening Frequency",
    organizationServiceScale: "Organization Service Scale",
    
    // 額外分析
    patientsWithMultipleScreenings: Count("Patient Screening Frequency" F where F.screeningCount > 1),
    repeatScreeningIntervalAnalysis: "Repeat Screening Interval Analysis"
  }
