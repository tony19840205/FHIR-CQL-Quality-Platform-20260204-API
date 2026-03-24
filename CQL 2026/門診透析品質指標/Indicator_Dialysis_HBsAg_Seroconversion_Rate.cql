/**
 * 指標名稱: B型肝炎表面抗原(HBsAg)轉陽率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 追蹤期間HBsAg由陰性轉為陽性(新感染)之人數
 * 分母: 追蹤期間之陰性病人數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dialysis_HBsAg_Seroconversion_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// B型肝炎表面抗原(HBsAg)檢驗LOINC代碼
define "HBsAg Laboratory Codes":
  { Code { code: '5196-1', system: 'http://loinc.org', display: 'Hepatitis B virus surface Ag [Presence] in Serum' },
    Code { code: '22322-2', system: 'http://loinc.org', display: 'Hepatitis B virus surface Ag [Presence] in Serum or Plasma' },
    Code { code: '16933-4', system: 'http://loinc.org', display: 'Hepatitis B virus surface Ag [Presence] in Serum by Immunoassay' },
    Code { code: '13214-1', system: 'http://loinc.org', display: 'Hepatitis B virus surface Ag [Units/volume] in Serum' }
  }

// 血液透析處置代碼
define "Hemodialysis Procedure Codes":
  { Code { code: '108241001', system: 'http://snomed.info/sct', display: 'Hemodialysis procedure' },
    Code { code: '302497006', system: 'http://snomed.info/sct', display: 'Hemodialysis' },
    Code { code: '427053002', system: 'http://snomed.info/sct', display: 'Extracorporeal hemodialysis' }
  }

// 慢性腎臟病診斷代碼
define "Chronic Kidney Disease Codes":
  { Code { code: '585', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic kidney disease' },
    Code { code: 'N18', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic kidney disease' },
    Code { code: 'N18.6', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'End stage renal disease' }
  }

// B型肝炎診斷代碼
define "Hepatitis B Codes":
  { Code { code: 'B18.1', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic viral hepatitis B' },
    Code { code: 'B16', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Acute hepatitis B' }
  }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Observation的結果（陽性/陰性）
define function GetObservationResult(obs Observation):
  if obs.value is FHIR.CodeableConcept
  then (
    if exists ((obs.value as FHIR.CodeableConcept).coding C 
               where C.code.value in { 'POS', 'Positive', '260373001' })
    then 'Positive'
    else if exists ((obs.value as FHIR.CodeableConcept).coding C 
                    where C.code.value in { 'NEG', 'Negative', '260415000' })
    then 'Negative'
    else null
  )
  else if obs.value is FHIR.string
  then (
    if (obs.value as FHIR.string).value in { 'Positive', 'POS', '陽性', '+' }
    then 'Positive'
    else if (obs.value as FHIR.string).value in { 'Negative', 'NEG', '陰性', '-' }
    then 'Negative'
    else null
  )
  else null

// 取得Patient的年齡
define function GetPatientAge(patient Patient):
  AgeInYearsAt(patient.birthDate, Today())

// 取得Patient的性別
define function GetPatientGender(patient Patient):
  patient.gender.value

// 取得Organization參考
define function GetEncounterOrganization(encounter Encounter):
  encounter.serviceProvider.reference.value

// 取得Patient參考
define function GetPatientReference(patientRef Reference):
  patientRef.reference.value

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 追蹤期間開始前的時間點（用於確定基線HBsAg狀態）
define "Baseline Period End":
  MeasurementPeriodStart - 1 day

// 觀察期間內的血液透析處置
define "Hemodialysis Procedures During Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "Hemodialysis Procedure Codes"
  )

// 觀察期間內的透析門診
define "Dialysis Encounters During Period":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'
  and exists (
    "Hemodialysis Procedures During Period" P
    where P.encounter.reference.value = 'Encounter/' + E.id
  )

// 血液透析病人（有透析處置記錄的病人）
define "Hemodialysis Patients":
  distinct (
    "Hemodialysis Procedures During Period" P
    return singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.subject.reference.value)
  )

// 所有HBsAg檢驗記錄
define "All HBsAg Observations":
  [Observation] O
  where O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "HBsAg Laboratory Codes"
  )
  and GetObservationResult(O) is not null

// 基線期間（追蹤期開始前）的HBsAg檢驗
define "Baseline HBsAg Observations":
  "All HBsAg Observations" O
  where O.effective as FHIR.dateTime <= "Baseline Period End"

// 追蹤期間的HBsAg檢驗
define "Follow Up HBsAg Observations":
  "All HBsAg Observations" O
  where O.effective during "Measurement Period"

// 基線時HBsAg陰性的透析病人
define "Baseline HBsAg Negative Patients":
  "Hemodialysis Patients" P
  let baselineObservations: "Baseline HBsAg Observations" O
                            where O.subject.reference.value = 'Patient/' + P.id
                            sort by effective as FHIR.dateTime desc,
      latestBaseline: First(baselineObservations),
      isNegative: if latestBaseline is not null
                  then GetObservationResult(latestBaseline) = 'Negative'
                  else false
  where isNegative
  return {
    patientId: 'Patient/' + P.id,
    baselineDate: latestBaseline.effective as FHIR.dateTime,
    baselineResult: GetObservationResult(latestBaseline),
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 追蹤期間之陰性病人數
define "Denominator Count":
  Count("Baseline HBsAg Negative Patients")

// HBsAg由陰性轉為陽性的病人（新感染）
define "HBsAg Seroconversion Patients":
  "Baseline HBsAg Negative Patients" BN
  let followUpObservations: "Follow Up HBsAg Observations" O
                            where O.subject.reference.value = BN.patientId
                            sort by effective as FHIR.dateTime,
      firstPositive: First(
        followUpObservations O
        where GetObservationResult(O) = 'Positive'
      ),
      hasSeroconversion: firstPositive is not null
  where hasSeroconversion
  return {
    patientId: BN.patientId,
    baselineDate: BN.baselineDate,
    baselineResult: BN.baselineResult,
    seroconversionDate: firstPositive.effective as FHIR.dateTime,
    seroconversionResult: GetObservationResult(firstPositive),
    daysBetween: days between BN.baselineDate and (firstPositive.effective as FHIR.dateTime),
    age: BN.age,
    gender: BN.gender
  }

// 分子: HBsAg由陰性轉為陽性之人數
define "Numerator Count":
  Count("HBsAg Seroconversion Patients")

// ========================================================================================
// 指標計算
// ========================================================================================

// HBsAg轉陽率
define "HBsAg Seroconversion Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Seroconversion By Age Group":
  "HBsAg Seroconversion Patients" S
  let ageGroup: if S.age < 18 then '<18歲'
                else if S.age >= 18 and S.age < 40 then '18-39歲'
                else if S.age >= 40 and S.age < 50 then '40-49歲'
                else if S.age >= 50 and S.age < 60 then '50-59歲'
                else if S.age >= 60 and S.age < 70 then '60-69歲'
                else if S.age >= 70 and S.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    patientId: S.patientId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Seroconversion By Age Group" S return S.ageGroup
  ) AgeGroup
  let groupSeroconversions: Count("Seroconversion By Age Group" S where S.ageGroup = AgeGroup),
      groupBaseline: Count(
        "Baseline HBsAg Negative Patients" B
        let patientAgeGroup: if B.age < 18 then '<18歲'
                             else if B.age >= 18 and B.age < 40 then '18-39歲'
                             else if B.age >= 40 and B.age < 50 then '40-49歲'
                             else if B.age >= 50 and B.age < 60 then '50-59歲'
                             else if B.age >= 60 and B.age < 70 then '60-69歲'
                             else if B.age >= 70 and B.age < 80 then '70-79歲'
                             else '≥80歲'
        where patientAgeGroup = AgeGroup
        return B
      )
  return {
    ageGroup: AgeGroup,
    seroconversionCount: groupSeroconversions,
    baselineNegativeCount: groupBaseline,
    seroconversionRate: if groupBaseline > 0
                        then Round((groupSeroconversions / groupBaseline) * 100.0, 2)
                        else null
  }
  sort by 
    case when ageGroup = '<18歲' then 1
         when ageGroup = '18-39歲' then 2
         when ageGroup = '40-49歲' then 3
         when ageGroup = '50-59歲' then 4
         when ageGroup = '60-69歲' then 5
         when ageGroup = '70-79歲' then 6
         else 7
    end

// 依性別分析
define "Seroconversion By Gender":
  "HBsAg Seroconversion Patients" S
  let gender: if S.gender = 'male' then '男性'
              else if S.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    patientId: S.patientId
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Seroconversion By Gender" S return S.gender
  ) Gender
  let genderSeroconversions: Count("Seroconversion By Gender" S where S.gender = Gender),
      genderBaseline: Count(
        "Baseline HBsAg Negative Patients" B
        let patientGender: if B.gender = 'male' then '男性'
                           else if B.gender = 'female' then '女性'
                           else '其他'
        where patientGender = Gender
        return B
      )
  return {
    gender: Gender,
    seroconversionCount: genderSeroconversions,
    baselineNegativeCount: genderBaseline,
    seroconversionRate: if genderBaseline > 0
                        then Round((genderSeroconversions / genderBaseline) * 100.0, 2)
                        else null
  }

// 依醫療機構分析
define "Seroconversion By Organization":
  "HBsAg Seroconversion Patients" S
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = S.patientId),
      encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = S.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    patientId: S.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Seroconversion By Organization" S return S.organizationId
  ) OrgId
  let orgSeroconversions: Count("Seroconversion By Organization" S where S.organizationId = OrgId),
      orgBaseline: Count(
        "Baseline HBsAg Negative Patients" B
        let encounters: "Dialysis Encounters During Period" E
                        where GetPatientReference(E.subject) = B.patientId,
            patientOrg: if Count(encounters) > 0
                        then GetEncounterOrganization(Last(encounters E sort by E.period.start))
                        else null
        where patientOrg = OrgId
        return B
      )
  return {
    organizationId: OrgId,
    seroconversionCount: orgSeroconversions,
    baselineNegativeCount: orgBaseline,
    seroconversionRate: if orgBaseline > 0
                        then Round((orgSeroconversions / orgBaseline) * 100.0, 2)
                        else null
  }
  sort by seroconversionRate desc

// 轉陽時間分析（從基線到轉陽的天數）
define "Seroconversion Time Analysis":
  "HBsAg Seroconversion Patients" S
  let timeRange: if S.daysBetween < 30 then '<1個月'
                 else if S.daysBetween >= 30 and S.daysBetween < 90 then '1-3個月'
                 else if S.daysBetween >= 90 and S.daysBetween < 180 then '3-6個月'
                 else '≥6個月'
  return {
    timeRange: timeRange,
    patientId: S.patientId,
    daysBetween: S.daysBetween
  }

// 轉陽時間統計
define "Seroconversion Time Statistics":
  distinct (
    "Seroconversion Time Analysis" T return T.timeRange
  ) TimeRange
  let rangeCount: Count("Seroconversion Time Analysis" T where T.timeRange = TimeRange),
      avgDays: Avg("Seroconversion Time Analysis" T where T.timeRange = TimeRange return T.daysBetween)
  return {
    timeRange: TimeRange,
    patientCount: rangeCount,
    percentage: if "Numerator Count" > 0
                then Round((rangeCount / "Numerator Count") * 100.0, 2)
                else null,
    averageDays: Round(avgDays, 1)
  }
  sort by 
    case when timeRange = '<1個月' then 1
         when timeRange = '1-3個月' then 2
         when timeRange = '3-6個月' then 3
         else 4
    end

// 月度趨勢分析
define "Monthly Trend Analysis":
  "HBsAg Seroconversion Patients" S
  let month: ToString(year from S.seroconversionDate) + '-' + 
             ToString(month from S.seroconversionDate)
  return {
    month: month,
    patientId: S.patientId
  }

// 月度統計
define "Monthly Statistics":
  distinct (
    "Monthly Trend Analysis" T return T.month
  ) Month
  let monthCount: Count("Monthly Trend Analysis" T where T.month = Month)
  return {
    month: Month,
    seroconversionCount: monthCount
  }
  sort by month

// 轉陽病人詳細名單
define "Seroconversion Patient Details":
  "HBsAg Seroconversion Patients" S
  return {
    patientId: S.patientId,
    baselineDate: S.baselineDate,
    seroconversionDate: S.seroconversionDate,
    daysBetween: S.daysBetween,
    age: S.age,
    gender: S.gender
  }
  sort by seroconversionDate desc

// 持續陰性病人（追蹤期間檢驗仍為陰性）
define "Persistently Negative Patients":
  "Baseline HBsAg Negative Patients" BN
  let followUpObservations: "Follow Up HBsAg Observations" O
                            where O.subject.reference.value = BN.patientId,
      allNegative: forall (followUpObservations O
                           return GetObservationResult(O) = 'Negative'),
      hasFollowUp: Count(followUpObservations) > 0
  where hasFollowUp and allNegative
  return {
    patientId: BN.patientId,
    followUpTestCount: Count(followUpObservations)
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: 'B型肝炎表面抗原(HBsAg)轉陽率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '追蹤期間HBsAg由陰性轉為陽性(新感染)之人數',
    denominator: "Denominator Count",
    denominatorDefinition: '追蹤期間之陰性病人數',
    seroconversionRate: "HBsAg Seroconversion Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    seroconversionTimeDistribution: "Seroconversion Time Statistics",
    monthlyTrend: "Monthly Statistics",
    seroconversionPatientDetails: "Seroconversion Patient Details",
    persistentlyNegativeCount: Count("Persistently Negative Patients"),
    unit: '%',
    formula: '(分子/分母) x 100%',
    note: '較低的轉陽率表示感染控制措施有效，為負向品質指標（越低越好）'
  }
