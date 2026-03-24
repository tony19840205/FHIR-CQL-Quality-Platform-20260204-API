/**
 * 指標名稱: C型肝炎抗體(Anti-HCV)轉陽率 - 腹膜透析
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 追蹤期間anti-HCV由陰性轉為陽性(新感染)之人數
 * 分母: 追蹤期間之陰性病人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 * 
 * 說明: 此為負向品質指標，轉陽率越低代表透析單位感染控制品質越好
 */

library Indicator_Dialysis_PD_Anti_HCV_Seroconversion_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// Anti-HCV檢驗代碼
define "Anti HCV Laboratory Codes":
  { Code { code: '16128-1', system: 'http://loinc.org', display: 'Hepatitis C virus Ab [Presence] in Serum' },
    Code { code: '13955-0', system: 'http://loinc.org', display: 'Hepatitis C virus Ab [Presence] in Serum or Plasma' },
    Code { code: '16129-9', system: 'http://loinc.org', display: 'Hepatitis C virus Ab [Presence] in Serum or Plasma by Immunoassay' },
    Code { code: '40726-2', system: 'http://loinc.org', display: 'Hepatitis C virus Ab [Presence] in Serum or Plasma by Immunoblot' },
    Code { code: '5198-7', system: 'http://loinc.org', display: 'Hepatitis C virus Ab [Units/volume] in Serum' }
  }

// 腹膜透析處置代碼
define "Peritoneal Dialysis Procedure Codes":
  { Code { code: '71192002', system: 'http://snomed.info/sct', display: 'Peritoneal dialysis' },
    Code { code: '225230008', system: 'http://snomed.info/sct', display: 'Chronic peritoneal dialysis' },
    Code { code: '238316008', system: 'http://snomed.info/sct', display: 'Continuous ambulatory peritoneal dialysis' },
    Code { code: '238317004', system: 'http://snomed.info/sct', display: 'Continuous cycling peritoneal dialysis' },
    Code { code: '238318009', system: 'http://snomed.info/sct', display: 'Automated peritoneal dialysis' }
  }

// 慢性腎臟病診斷代碼
define "Chronic Kidney Disease Codes":
  { Code { code: '585', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic kidney disease' },
    Code { code: 'N18', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic kidney disease' },
    Code { code: 'N18.6', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'End stage renal disease' }
  }

// C型肝炎診斷代碼
define "Hepatitis C Codes":
  { Code { code: 'B18.2', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic viral hepatitis C' },
    Code { code: 'B17.1', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Acute hepatitis C' }
  }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Observation的檢驗結果（處理多種格式）
define function GetObservationResult(obs Observation):
  case
    when obs.value is FHIR.CodeableConcept then 
      Coalesce(
        singleton from ((obs.value as FHIR.CodeableConcept).coding[0].code.value),
        singleton from ((obs.value as FHIR.CodeableConcept).coding[0].display.value),
        (obs.value as FHIR.CodeableConcept).text.value
      )
    when obs.value is FHIR.string then (obs.value as FHIR.string).value
    else null
  end

// 判斷Anti-HCV結果是否為陽性
define function IsAntiHCVPositive(result String):
  result in { 'POS', 'Positive', '陽性', '+', 'Detected', 'Reactive' }

// 判斷Anti-HCV結果是否為陰性
define function IsAntiHCVNegative(result String):
  result in { 'NEG', 'Negative', '陰性', '-', 'Not detected', 'Non-reactive', 'Nonreactive' }

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

// 觀察期間（每季）
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 基線期間（觀察期間之前，用於確定基線Anti-HCV狀態）
define "Baseline Period End":
  MeasurementPeriodStart - 1 day

// 觀察期間內的腹膜透析處置
define "Peritoneal Dialysis Procedures During Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "Peritoneal Dialysis Procedure Codes"
  )

// 觀察期間內的透析門診
define "Dialysis Encounters During Period":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'
  and exists (
    "Peritoneal Dialysis Procedures During Period" P
    where P.encounter.reference.value = 'Encounter/' + E.id
  )

// 腹膜透析病人（有腹膜透析處置記錄的病人）
define "Peritoneal Dialysis Patients":
  distinct (
    "Peritoneal Dialysis Procedures During Period" P
    return singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.subject.reference.value)
  )

// 所有Anti-HCV檢驗（不限時間）
define "All Anti HCV Observations":
  [Observation] O
  where O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "Anti HCV Laboratory Codes"
  )
  and GetObservationResult(O) is not null

// 基線Anti-HCV陰性病人（觀察期間開始前最後一次檢驗為陰性）
define "Baseline Anti HCV Negative Patients":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      baselineObservations: "All Anti HCV Observations" O
                            where O.subject.reference.value = patientId
                            and (O.effective as FHIR.dateTime) < MeasurementPeriodStart
                            sort by effective as FHIR.dateTime desc,
      lastBaselineObs: First(baselineObservations),
      lastBaselineResult: if lastBaselineObs is not null
                          then GetObservationResult(lastBaselineObs)
                          else null,
      isBaselineNegative: IsAntiHCVNegative(lastBaselineResult)
  where isBaselineNegative
  return {
    patientId: patientId,
    baselineDate: lastBaselineObs.effective as FHIR.dateTime,
    baselineResult: lastBaselineResult,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 追蹤期間之陰性病人數
define "Denominator Count":
  Count("Baseline Anti HCV Negative Patients")

// Anti-HCV轉陽病人（基線陰性，追蹤期間轉為陽性）
define "Anti HCV Seroconversion Patients":
  "Baseline Anti HCV Negative Patients" B
  let followUpObservations: "All Anti HCV Observations" O
                            where O.subject.reference.value = B.patientId
                            and (O.effective as FHIR.dateTime) during "Measurement Period"
                            sort by effective as FHIR.dateTime,
      firstPositiveObs: First(
        followUpObservations F
        where IsAntiHCVPositive(GetObservationResult(F))
      )
  where firstPositiveObs is not null
  return {
    patientId: B.patientId,
    age: B.age,
    gender: B.gender,
    baselineDate: B.baselineDate,
    baselineResult: B.baselineResult,
    seroconversionDate: firstPositiveObs.effective as FHIR.dateTime,
    seroconversionResult: GetObservationResult(firstPositiveObs),
    daysBetween: days between B.baselineDate and (firstPositiveObs.effective as FHIR.dateTime)
  }

// 分子: 追蹤期間anti-HCV由陰性轉為陽性(新感染)之人數
define "Numerator Count":
  Count("Anti HCV Seroconversion Patients")

// ========================================================================================
// 指標計算
// ========================================================================================

// Anti-HCV轉陽率
define "Anti HCV Seroconversion Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Seroconversion By Age Group":
  "Anti HCV Seroconversion Patients" S
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
        "Baseline Anti HCV Negative Patients" B
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
  "Anti HCV Seroconversion Patients" S
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
        "Baseline Anti HCV Negative Patients" B
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
  "Anti HCV Seroconversion Patients" S
  let encounters: "Dialysis Encounters During Period" E
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
        "Baseline Anti HCV Negative Patients" B
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

// 轉陽時間分析
define "Seroconversion Time Analysis":
  "Anti HCV Seroconversion Patients" S
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
define "Seroconversion Time Distribution":
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
    averageDays: if avgDays is not null then Round(avgDays, 0) else null
  }
  sort by 
    case when timeRange = '<1個月' then 1
         when timeRange = '1-3個月' then 2
         when timeRange = '3-6個月' then 3
         else 4
    end

// 月份趨勢分析
define "Monthly Trend Analysis":
  let months: { 
    { month: '2026-01', start: @2026-01-01T00:00:00.0+08:00, end: @2026-01-31T23:59:59.0+08:00 },
    { month: '2026-02', start: @2026-02-01T00:00:00.0+08:00, end: @2026-02-28T23:59:59.0+08:00 },
    { month: '2026-03', start: @2026-03-01T00:00:00.0+08:00, end: @2026-03-31T23:59:59.0+08:00 }
  }
  return months M
  let monthSeroconversions: Count(
        "Anti HCV Seroconversion Patients" S
        where S.seroconversionDate >= M.start and S.seroconversionDate <= M.end
      )
  return {
    month: M.month,
    seroconversionCount: monthSeroconversions
  }

// 轉陽病人詳細資訊
define "Seroconversion Patient Details":
  "Anti HCV Seroconversion Patients" S
  return {
    patientId: S.patientId,
    age: S.age,
    gender: S.gender,
    baselineDate: S.baselineDate,
    baselineResult: S.baselineResult,
    seroconversionDate: S.seroconversionDate,
    seroconversionResult: S.seroconversionResult,
    daysBetween: S.daysBetween,
    monthsBetween: Round(S.daysBetween / 30.44, 1)
  }
  sort by seroconversionDate

// 持續陰性病人（基線陰性且追蹤期間維持陰性）
define "Persistently Negative Patients":
  "Baseline Anti HCV Negative Patients" B
  where not exists (
    "Anti HCV Seroconversion Patients" S
    where S.patientId = B.patientId
  )

// 持續陰性統計
define "Persistently Negative Count":
  Count("Persistently Negative Patients")

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: 'C型肝炎抗體(Anti-HCV)轉陽率 - 腹膜透析',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Count",
    numeratorDefinition: '追蹤期間anti-HCV由陰性轉為陽性(新感染)之人數',
    denominator: "Denominator Count",
    denominatorDefinition: '追蹤期間之陰性病人數',
    seroconversionRate: "Anti HCV Seroconversion Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    seroconversionTimeDistribution: "Seroconversion Time Distribution",
    monthlyTrend: "Monthly Trend Analysis",
    seroconversionPatientDetails: "Seroconversion Patient Details",
    persistentlyNegativeCount: "Persistently Negative Count",
    unit: '%',
    formula: '(分子/分母) x 100%',
    note: '此為負向品質指標，轉陽率越低代表透析單位感染控制品質越好。Anti-HCV轉陽表示新發生C型肝炎感染，需要加強感染管制措施。C型肝炎目前已有治癒藥物，早期發現可及時治療。'
  }
