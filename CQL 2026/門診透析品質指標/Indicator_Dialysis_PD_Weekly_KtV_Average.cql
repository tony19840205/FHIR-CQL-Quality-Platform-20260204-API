/**
 * 指標名稱: 尿素氮週透析效率(Weekly Kt/V)平均值 - 腹膜透析
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: 分子/分母
 * 
 * 分子: 分母病人的尿素氮透析效率(Kt/V)數值總和
 * 分母: 透析醫療院所照護的腹膜透析病人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 * 
 * Kt/V說明:
 * K = 尿素清除率 (L/hr)
 * t = 透析時間 (hours)
 * V = 尿素分佈容積 (approximately total body water in L)
 * Weekly Kt/V = 每週透析效率
 * 建議目標值: ≥1.7 (腹膜透析每週Kt/V目標)
 */

library Indicator_Dialysis_PD_Weekly_KtV_Average version '1.0.0'

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

// Kt/V檢驗代碼
define "KtV Laboratory Codes":
  { Code { code: '23155-1', system: 'http://loinc.org', display: 'Kt/V Dialysis clearance/Patient volume in Peritoneal dialysate' },
    Code { code: '58872-7', system: 'http://loinc.org', display: 'Kt/V (urea) in Serum or Plasma' },
    Code { code: '90245-6', system: 'http://loinc.org', display: 'Weekly Kt/V in Peritoneal dialysate' },
    Code { code: '23156-9', system: 'http://loinc.org', display: 'Weekly Kt/V Dialysis clearance/Patient volume' }
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

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Observation的數值結果
define function GetObservationValue(obs Observation):
  case
    when obs.value is FHIR.Quantity then (obs.value as FHIR.Quantity).value.value
    else null
  end

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

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

// 觀察期間內的Kt/V檢驗
define "KtV Observations During Period":
  [Observation] O
  where O.effective during "Measurement Period"
  and O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "KtV Laboratory Codes"
  )
  and GetObservationValue(O) is not null

// 每位病人的最新Kt/V檢驗值
define "Latest KtV Per Patient":
  "Peritoneal Dialysis Patients" P
  let patientKtVs: "KtV Observations During Period" O
                   where O.subject.reference.value = 'Patient/' + P.id
                   sort by effective as FHIR.dateTime desc,
      latestKtV: First(patientKtVs)
  where latestKtV is not null
  return {
    patientId: 'Patient/' + P.id,
    ktv: GetObservationValue(latestKtV),
    testDate: latestKtV.effective as FHIR.dateTime,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 透析醫療院所照護的腹膜透析病人數（有Kt/V檢驗值的病人）
define "Denominator Count":
  Count("Latest KtV Per Patient")

// 分子: 分母病人的尿素氮透析效率(Kt/V)數值總和
define "Numerator Sum":
  Sum("Latest KtV Per Patient" K return K.ktv)

// ========================================================================================
// 指標計算
// ========================================================================================

// Weekly Kt/V平均值
define "Weekly KtV Average":
  if "Denominator Count" > 0 
  then Round("Numerator Sum" / "Denominator Count", 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// Kt/V數值範圍統計
define "KtV Range Statistics":
  let ranges: { 
    { range: '<1.5 (不足)', min: 0.0, max: 1.49 },
    { range: '1.5-1.69 (接近目標)', min: 1.5, max: 1.69 },
    { range: '1.7-1.99 (達標)', min: 1.7, max: 1.99 },
    { range: '2.0-2.49 (良好)', min: 2.0, max: 2.49 },
    { range: '≥2.5 (優良)', min: 2.5, max: 999.0 }
  }
  return ranges R
  let patientsInRange: "Latest KtV Per Patient" K
                       where K.ktv >= R.min and K.ktv <= R.max
  return {
    range: R.range,
    patientCount: Count(patientsInRange),
    percentage: if "Denominator Count" > 0 
                then Round((Count(patientsInRange) / "Denominator Count") * 100.0, 2)
                else null,
    averageInRange: if Count(patientsInRange) > 0
                    then Round(Avg(patientsInRange K return K.ktv), 2)
                    else null
  }

// 達標率統計（腹膜透析Weekly Kt/V ≥ 1.7）
define "Target Achievement Statistics":
  let targetPatients: "Latest KtV Per Patient" K where K.ktv >= 1.7,
      belowTargetPatients: "Latest KtV Per Patient" K where K.ktv < 1.7,
      optimalPatients: "Latest KtV Per Patient" K where K.ktv >= 2.0
  return {
    targetCount: Count(targetPatients),
    belowTargetCount: Count(belowTargetPatients),
    optimalCount: Count(optimalPatients),
    targetAchievementRate: if "Denominator Count" > 0
                           then Round((Count(targetPatients) / "Denominator Count") * 100.0, 2)
                           else null,
    optimalAchievementRate: if "Denominator Count" > 0
                            then Round((Count(optimalPatients) / "Denominator Count") * 100.0, 2)
                            else null,
    averageKtVInTarget: if Count(targetPatients) > 0
                        then Round(Avg(targetPatients K return K.ktv), 2)
                        else null,
    averageKtVBelowTarget: if Count(belowTargetPatients) > 0
                           then Round(Avg(belowTargetPatients K return K.ktv), 2)
                           else null
  }

// 依年齡層分析
define "KtV By Age Group":
  "Latest KtV Per Patient" K
  let ageGroup: if K.age < 18 then '<18歲'
                else if K.age >= 18 and K.age < 40 then '18-39歲'
                else if K.age >= 40 and K.age < 50 then '40-49歲'
                else if K.age >= 50 and K.age < 60 then '50-59歲'
                else if K.age >= 60 and K.age < 70 then '60-69歲'
                else if K.age >= 70 and K.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    ktv: K.ktv
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "KtV By Age Group" K return K.ageGroup
  ) AgeGroup
  let groupKtVs: "KtV By Age Group" K where K.ageGroup = AgeGroup
  return {
    ageGroup: AgeGroup,
    patientCount: Count(groupKtVs),
    averageKtV: Round(Avg(groupKtVs G return G.ktv), 2),
    minKtV: Round(Min(groupKtVs G return G.ktv), 2),
    maxKtV: Round(Max(groupKtVs G return G.ktv), 2),
    targetAchievementRate: if Count(groupKtVs) > 0
                           then Round((Count(groupKtVs G where G.ktv >= 1.7) / Count(groupKtVs)) * 100.0, 2)
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
define "KtV By Gender":
  "Latest KtV Per Patient" K
  let gender: if K.gender = 'male' then '男性'
              else if K.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    ktv: K.ktv
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "KtV By Gender" K return K.gender
  ) Gender
  let genderKtVs: "KtV By Gender" K where K.gender = Gender
  return {
    gender: Gender,
    patientCount: Count(genderKtVs),
    averageKtV: Round(Avg(genderKtVs G return G.ktv), 2),
    minKtV: Round(Min(genderKtVs G return G.ktv), 2),
    maxKtV: Round(Max(genderKtVs G return G.ktv), 2),
    targetAchievementRate: if Count(genderKtVs) > 0
                           then Round((Count(genderKtVs G where G.ktv >= 1.7) / Count(genderKtVs)) * 100.0, 2)
                           else null
  }

// 依醫療機構分析
define "KtV By Organization":
  "Latest KtV Per Patient" K
  let encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = K.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    ktv: K.ktv
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "KtV By Organization" K return K.organizationId
  ) OrgId
  let orgKtVs: "KtV By Organization" K where K.organizationId = OrgId
  return {
    organizationId: OrgId,
    patientCount: Count(orgKtVs),
    averageKtV: Round(Avg(orgKtVs O return O.ktv), 2),
    minKtV: Round(Min(orgKtVs O return O.ktv), 2),
    maxKtV: Round(Max(orgKtVs O return O.ktv), 2),
    targetAchievementRate: if Count(orgKtVs) > 0
                           then Round((Count(orgKtVs O where O.ktv >= 1.7) / Count(orgKtVs)) * 100.0, 2)
                           else null
  }
  sort by averageKtV desc

// 透析效率不足病人名單 (Kt/V < 1.7 需要關注)
define "Inadequate KtV Patients":
  "Latest KtV Per Patient" K
  where K.ktv < 1.7
  return {
    patientId: K.patientId,
    ktv: K.ktv,
    testDate: K.testDate,
    age: K.age,
    gender: K.gender,
    severity: if K.ktv < 1.5 then '嚴重不足'
              else '接近目標'
  }
  sort by ktv asc

// 透析效率不足統計
define "Inadequate KtV Statistics":
  let totalInadequate: Count("Inadequate KtV Patients"),
      severeInadequate: Count("Inadequate KtV Patients" I where I.ktv < 1.5),
      mildInadequate: Count("Inadequate KtV Patients" I where I.ktv >= 1.5 and I.ktv < 1.7)
  return {
    totalInadequatePatients: totalInadequate,
    severeInadequate: severeInadequate,
    mildInadequate: mildInadequate,
    percentageOfTotal: if "Denominator Count" > 0
                       then Round((totalInadequate / "Denominator Count") * 100.0, 2)
                       else null,
    note: 'Kt/V < 1.7表示透析效率不足，需要增加透析劑量或調整透析處方'
  }

// 優良透析效率病人（Kt/V ≥ 2.0）
define "Optimal KtV Patients":
  "Latest KtV Per Patient" K
  where K.ktv >= 2.0
  return {
    patientId: K.patientId,
    ktv: K.ktv,
    testDate: K.testDate,
    age: K.age,
    gender: K.gender
  }
  sort by ktv desc

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '尿素氮週透析效率(Weekly Kt/V)平均值 - 腹膜透析',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Sum",
    numeratorDefinition: '分母病人的尿素氮透析效率(Kt/V)數值總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的腹膜透析病人數',
    weeklyKtVAverage: "Weekly KtV Average",
    ktvRangeDistribution: "KtV Range Statistics",
    targetAchievementAnalysis: "Target Achievement Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    inadequateKtVStatistics: "Inadequate KtV Statistics",
    inadequateKtVPatientList: "Inadequate KtV Patients",
    optimalKtVPatientList: "Optimal KtV Patients",
    unit: 'dimensionless',
    formula: '分子/分母',
    targetValue: '≥1.7 (腹膜透析每週Kt/V目標值)',
    optimalValue: '≥2.0 (優良透析效率)',
    note: 'Weekly Kt/V是評估腹膜透析充分性的關鍵指標。K=尿素清除率, t=時間, V=尿素分佈容積。目標值≥1.7，平均值越高表示透析效率越好。'
  }
