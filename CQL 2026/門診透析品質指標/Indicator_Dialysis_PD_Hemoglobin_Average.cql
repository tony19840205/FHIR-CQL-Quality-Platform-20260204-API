/**
 * 指標名稱: 血紅素(Hemoglobin(Hb))平均值 - 腹膜透析
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: 分子/分母
 * 
 * 分子: 分母病人的血紅素 (Hb) 數值總和
 * 分母: 透析醫療院所照護的腹膜透析病人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 */

library Indicator_Dialysis_PD_Hemoglobin_Average version '1.0.0'

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

// 血紅素檢驗代碼 (包含不同檢測方法和標本來源)
define "Hemoglobin Laboratory Codes":
  { Code { code: '718-7', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood' },
    Code { code: '30350-3', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Venous blood' },
    Code { code: '30351-1', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Mixed venous blood' },
    Code { code: '20509-6', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood by calculation' },
    Code { code: '55782-7', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood by Oximetry' }
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

// 觀察期間內的血紅素檢驗
define "Hemoglobin Observations During Period":
  [Observation] O
  where O.effective during "Measurement Period"
  and O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "Hemoglobin Laboratory Codes"
  )
  and GetObservationValue(O) is not null

// 每位病人的最新血紅素檢驗值
define "Latest Hemoglobin Per Patient":
  "Peritoneal Dialysis Patients" P
  let patientHemoglobins: "Hemoglobin Observations During Period" O
                          where O.subject.reference.value = 'Patient/' + P.id
                          sort by effective as FHIR.dateTime desc,
      latestHemoglobin: First(patientHemoglobins)
  where latestHemoglobin is not null
  return {
    patientId: 'Patient/' + P.id,
    hemoglobin: GetObservationValue(latestHemoglobin),
    testDate: latestHemoglobin.effective as FHIR.dateTime,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 透析醫療院所照護的腹膜透析病人數（有血紅素檢驗值的病人）
define "Denominator Count":
  Count("Latest Hemoglobin Per Patient")

// 分子: 分母病人的血紅素數值總和
define "Numerator Sum":
  Sum("Latest Hemoglobin Per Patient" H return H.hemoglobin)

// ========================================================================================
// 指標計算
// ========================================================================================

// 血紅素平均值
define "Hemoglobin Average":
  if "Denominator Count" > 0 
  then Round("Numerator Sum" / "Denominator Count", 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 血紅素數值範圍統計
define "Hemoglobin Range Statistics":
  let ranges: { 
    { range: '<10.0 g/dL (嚴重貧血)', min: 0.0, max: 9.99 },
    { range: '10.0-10.9 g/dL (中度貧血)', min: 10.0, max: 10.99 },
    { range: '11.0-11.9 g/dL (輕度貧血)', min: 11.0, max: 11.99 },
    { range: '12.0-15.9 g/dL (接近正常/正常)', min: 12.0, max: 15.99 },
    { range: '≥16.0 g/dL (偏高)', min: 16.0, max: 999.0 }
  }
  return ranges R
  let patientsInRange: "Latest Hemoglobin Per Patient" H
                       where H.hemoglobin >= R.min and H.hemoglobin <= R.max
  return {
    range: R.range,
    patientCount: Count(patientsInRange),
    percentage: if "Denominator Count" > 0 
                then Round((Count(patientsInRange) / "Denominator Count") * 100.0, 2)
                else null,
    averageInRange: if Count(patientsInRange) > 0
                    then Round(Avg(patientsInRange H return H.hemoglobin), 2)
                    else null
  }

// 達標率統計（透析病人Hb ≥ 10.0 g/dL）
define "Target Achievement Statistics":
  let targetPatients: "Latest Hemoglobin Per Patient" H where H.hemoglobin >= 10.0,
      belowTargetPatients: "Latest Hemoglobin Per Patient" H where H.hemoglobin < 10.0
  return {
    targetCount: Count(targetPatients),
    belowTargetCount: Count(belowTargetPatients),
    targetAchievementRate: if "Denominator Count" > 0
                           then Round((Count(targetPatients) / "Denominator Count") * 100.0, 2)
                           else null,
    averageHbInTarget: if Count(targetPatients) > 0
                       then Round(Avg(targetPatients H return H.hemoglobin), 2)
                       else null,
    averageHbBelowTarget: if Count(belowTargetPatients) > 0
                          then Round(Avg(belowTargetPatients H return H.hemoglobin), 2)
                          else null
  }

// 依年齡層分析
define "Hemoglobin By Age Group":
  "Latest Hemoglobin Per Patient" H
  let ageGroup: if H.age < 18 then '<18歲'
                else if H.age >= 18 and H.age < 40 then '18-39歲'
                else if H.age >= 40 and H.age < 50 then '40-49歲'
                else if H.age >= 50 and H.age < 60 then '50-59歲'
                else if H.age >= 60 and H.age < 70 then '60-69歲'
                else if H.age >= 70 and H.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    hemoglobin: H.hemoglobin
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Hemoglobin By Age Group" H return H.ageGroup
  ) AgeGroup
  let groupHemoglobins: "Hemoglobin By Age Group" H where H.ageGroup = AgeGroup
  return {
    ageGroup: AgeGroup,
    patientCount: Count(groupHemoglobins),
    averageHemoglobin: Round(Avg(groupHemoglobins G return G.hemoglobin), 2),
    minHemoglobin: Round(Min(groupHemoglobins G return G.hemoglobin), 2),
    maxHemoglobin: Round(Max(groupHemoglobins G return G.hemoglobin), 2)
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
define "Hemoglobin By Gender":
  "Latest Hemoglobin Per Patient" H
  let gender: if H.gender = 'male' then '男性'
              else if H.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    hemoglobin: H.hemoglobin
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Hemoglobin By Gender" H return H.gender
  ) Gender
  let genderHemoglobins: "Hemoglobin By Gender" H where H.gender = Gender
  return {
    gender: Gender,
    patientCount: Count(genderHemoglobins),
    averageHemoglobin: Round(Avg(genderHemoglobins G return G.hemoglobin), 2),
    minHemoglobin: Round(Min(genderHemoglobins G return G.hemoglobin), 2),
    maxHemoglobin: Round(Max(genderHemoglobins G return G.hemoglobin), 2)
  }

// 依醫療機構分析
define "Hemoglobin By Organization":
  "Latest Hemoglobin Per Patient" H
  let encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = H.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    hemoglobin: H.hemoglobin
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Hemoglobin By Organization" H return H.organizationId
  ) OrgId
  let orgHemoglobins: "Hemoglobin By Organization" H where H.organizationId = OrgId
  return {
    organizationId: OrgId,
    patientCount: Count(orgHemoglobins),
    averageHemoglobin: Round(Avg(orgHemoglobins O return O.hemoglobin), 2),
    minHemoglobin: Round(Min(orgHemoglobins O return O.hemoglobin), 2),
    maxHemoglobin: Round(Max(orgHemoglobins O return O.hemoglobin), 2),
    targetAchievementRate: if Count(orgHemoglobins) > 0
                           then Round((Count(orgHemoglobins O where O.hemoglobin >= 10.0) / Count(orgHemoglobins)) * 100.0, 2)
                           else null
  }
  sort by averageHemoglobin desc

// 貧血病人名單 (Hb < 11.0 g/dL 需要關注)
define "Anemic Patients":
  "Latest Hemoglobin Per Patient" H
  where H.hemoglobin < 11.0
  return {
    patientId: H.patientId,
    hemoglobin: H.hemoglobin,
    testDate: H.testDate,
    age: H.age,
    gender: H.gender,
    severity: if H.hemoglobin < 10.0 then '嚴重貧血'
              else '中度貧血'
  }
  sort by hemoglobin asc

// 貧血統計
define "Anemia Statistics":
  let totalAnemic: Count("Anemic Patients"),
      severeAnemia: Count("Anemic Patients" A where A.hemoglobin < 10.0),
      moderateAnemia: Count("Anemic Patients" A where A.hemoglobin >= 10.0 and A.hemoglobin < 11.0)
  return {
    totalAnemicPatients: totalAnemic,
    severeAnemia: severeAnemia,
    moderateAnemia: moderateAnemia,
    percentageOfTotal: if "Denominator Count" > 0
                       then Round((totalAnemic / "Denominator Count") * 100.0, 2)
                       else null
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '血紅素(Hemoglobin(Hb))平均值 - 腹膜透析',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Sum",
    numeratorDefinition: '分母病人的血紅素 (Hb) 數值總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的腹膜透析病人數',
    hemoglobinAverage: "Hemoglobin Average",
    hemoglobinRangeDistribution: "Hemoglobin Range Statistics",
    targetAchievementAnalysis: "Target Achievement Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    anemiaStatistics: "Anemia Statistics",
    anemicPatientList: "Anemic Patients",
    unit: 'g/dL',
    formula: '分子/分母',
    referenceRange: '男性: 13-18 g/dL; 女性: 12-16 g/dL; 透析病人目標: ≥10.0 g/dL',
    note: '血紅素是評估腹膜透析病人貧血控制的重要指標。平均值越高，表示整體貧血管理越好。透析病人目標值為≥10.0 g/dL。'
  }
