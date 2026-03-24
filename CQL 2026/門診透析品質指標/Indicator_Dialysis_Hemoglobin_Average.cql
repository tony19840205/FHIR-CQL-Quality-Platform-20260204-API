/**
 * 指標名稱: 血紅素(Hemoglobin(Hb))平均值
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: 分子/分母
 * 
 * 分子: 分母病人的血紅素 (Hb) 數值總和
 * 分母: 透析醫療院所照護的血液透析病人數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dialysis_Hemoglobin_Average version '1.0.0'

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

// 血紅素檢驗LOINC代碼
define "Hemoglobin Laboratory Codes":
  { Code { code: '718-7', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood' },
    Code { code: '30350-3', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Venous blood' },
    Code { code: '30351-1', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Mixed venous blood' },
    Code { code: '20509-6', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood by calculation' },
    Code { code: '55782-7', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood by Oximetry' }
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

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Observation的數值
define function GetObservationValue(obs Observation):
  if obs.value is FHIR.Quantity
  then (obs.value as FHIR.Quantity).value.value
  else null

// 取得Observation的單位
define function GetObservationUnit(obs Observation):
  if obs.value is FHIR.Quantity
  then (obs.value as FHIR.Quantity).unit.value
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

// 血液透析病人的血紅素檢驗
define "Hemoglobin Observations For Hemodialysis Patients":
  "Hemoglobin Observations During Period" O
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = O.subject.reference.value)
  where patient in "Hemodialysis Patients"
  return {
    observationId: 'Observation/' + O.id,
    patientId: 'Patient/' + patient.id,
    value: GetObservationValue(O),
    unit: GetObservationUnit(O),
    effectiveDateTime: O.effective as FHIR.dateTime,
    status: O.status.value
  }

// 每位病人的最新血紅素值
define "Latest Hemoglobin Per Patient":
  "Hemodialysis Patients" P
  let patientHemoglobins: "Hemoglobin Observations For Hemodialysis Patients" O
                          where O.patientId = 'Patient/' + P.id
                          sort by effectiveDateTime desc,
      latestHemoglobin: First(patientHemoglobins)
  where latestHemoglobin is not null
  return {
    patientId: 'Patient/' + P.id,
    hemoglobinValue: latestHemoglobin.value,
    unit: latestHemoglobin.unit,
    observationDate: latestHemoglobin.effectiveDateTime,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 透析醫療院所照護的血液透析病人數（有血紅素檢驗值的病人）
define "Denominator Count":
  Count("Latest Hemoglobin Per Patient")

// 分子: 分母病人的血紅素數值總和
define "Numerator Sum":
  Sum("Latest Hemoglobin Per Patient" H return H.hemoglobinValue)

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

// 依血紅素值範圍分層
define "Patients By Hemoglobin Range":
  "Latest Hemoglobin Per Patient" H
  let range: if H.hemoglobinValue < 10.0 then '<10.0 g/dL (嚴重貧血)'
             else if H.hemoglobinValue >= 10.0 and H.hemoglobinValue < 11.0 then '10.0-10.9 g/dL (中度貧血)'
             else if H.hemoglobinValue >= 11.0 and H.hemoglobinValue < 12.0 then '11.0-11.9 g/dL (輕度貧血)'
             else if H.hemoglobinValue >= 12.0 and H.hemoglobinValue < 13.0 then '12.0-12.9 g/dL (接近正常)'
             else if H.hemoglobinValue >= 13.0 and H.hemoglobinValue < 14.0 then '13.0-13.9 g/dL (正常)'
             else if H.hemoglobinValue >= 14.0 and H.hemoglobinValue < 16.0 then '14.0-15.9 g/dL (正常)'
             else '≥16.0 g/dL (偏高)'
  return {
    range: range,
    patientId: H.patientId,
    hemoglobinValue: H.hemoglobinValue,
    gender: H.gender
  }

// 血紅素值範圍統計
define "Hemoglobin Range Statistics":
  distinct (
    "Patients By Hemoglobin Range" P return P.range
  ) Range
  let rangeCount: Count("Patients By Hemoglobin Range" P where P.range = Range),
      rangeAvg: Avg("Patients By Hemoglobin Range" P where P.range = Range return P.hemoglobinValue)
  return {
    hemoglobinRange: Range,
    patientCount: rangeCount,
    percentage: if "Denominator Count" > 0
                then Round((rangeCount / "Denominator Count") * 100.0, 2)
                else null,
    averageValue: Round(rangeAvg, 2)
  }
  sort by 
    case when hemoglobinRange = '<10.0 g/dL (嚴重貧血)' then 1
         when hemoglobinRange = '10.0-10.9 g/dL (中度貧血)' then 2
         when hemoglobinRange = '11.0-11.9 g/dL (輕度貧血)' then 3
         when hemoglobinRange = '12.0-12.9 g/dL (接近正常)' then 4
         when hemoglobinRange = '13.0-13.9 g/dL (正常)' then 5
         when hemoglobinRange = '14.0-15.9 g/dL (正常)' then 6
         else 7
    end

// 依年齡層分析
define "Results By Age Group":
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
    hemoglobinValue: H.hemoglobinValue
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Results By Age Group" R return R.ageGroup
  ) AgeGroup
  let groupCount: Count("Results By Age Group" R where R.ageGroup = AgeGroup),
      groupAvg: Avg("Results By Age Group" R where R.ageGroup = AgeGroup return R.hemoglobinValue)
  return {
    ageGroup: AgeGroup,
    patientCount: groupCount,
    averageHemoglobin: Round(groupAvg, 2),
    percentage: if "Denominator Count" > 0
                then Round((groupCount / "Denominator Count") * 100.0, 2)
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
define "Results By Gender":
  "Latest Hemoglobin Per Patient" H
  let gender: if H.gender = 'male' then '男性'
              else if H.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    hemoglobinValue: H.hemoglobinValue
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Results By Gender" R return R.gender
  ) Gender
  let genderCount: Count("Results By Gender" R where R.gender = Gender),
      genderAvg: Avg("Results By Gender" R where R.gender = Gender return R.hemoglobinValue),
      genderMin: Min("Results By Gender" R where R.gender = Gender return R.hemoglobinValue),
      genderMax: Max("Results By Gender" R where R.gender = Gender return R.hemoglobinValue)
  return {
    gender: Gender,
    patientCount: genderCount,
    averageHemoglobin: Round(genderAvg, 2),
    minHemoglobin: Round(genderMin, 2),
    maxHemoglobin: Round(genderMax, 2),
    percentage: if "Denominator Count" > 0
                then Round((genderCount / "Denominator Count") * 100.0, 2)
                else null
  }

// 依醫療機構分析
define "Results By Organization":
  "Latest Hemoglobin Per Patient" LH
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = LH.patientId),
      encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = LH.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    hemoglobinValue: LH.hemoglobinValue,
    patientId: LH.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Results By Organization" R return R.organizationId
  ) OrgId
  let orgCount: Count("Results By Organization" R where R.organizationId = OrgId),
      orgAvg: Avg("Results By Organization" R where R.organizationId = OrgId return R.hemoglobinValue),
      orgMin: Min("Results By Organization" R where R.organizationId = OrgId return R.hemoglobinValue),
      orgMax: Max("Results By Organization" R where R.organizationId = OrgId return R.hemoglobinValue),
      orgPatients: Count(
        distinct (
          "Results By Organization" R where R.organizationId = OrgId return R.patientId
        )
      )
  return {
    organizationId: OrgId,
    patientCount: orgPatients,
    observationCount: orgCount,
    averageHemoglobin: Round(orgAvg, 2),
    minHemoglobin: Round(orgMin, 2),
    maxHemoglobin: Round(orgMax, 2)
  }
  sort by averageHemoglobin desc

// 貧血病人名單（<11.0 g/dL）
define "Anemic Patients":
  "Latest Hemoglobin Per Patient" H
  where H.hemoglobinValue < 11.0
  return {
    patientId: H.patientId,
    hemoglobinValue: H.hemoglobinValue,
    unit: H.unit,
    observationDate: H.observationDate,
    age: H.age,
    gender: H.gender,
    severity: if H.hemoglobinValue < 10.0 then '嚴重貧血'
              else '中度貧血'
  }
  sort by hemoglobinValue

// 達標病人統計（透析病人建議血紅素 ≥10.0 g/dL）
define "Target Achievement Statistics":
  let targetAchieved: Count("Latest Hemoglobin Per Patient" H where H.hemoglobinValue >= 10.0),
      targetNotAchieved: Count("Latest Hemoglobin Per Patient" H where H.hemoglobinValue < 10.0)
  return {
    totalPatients: "Denominator Count",
    targetAchieved: targetAchieved,
    targetNotAchieved: targetNotAchieved,
    achievementRate: if "Denominator Count" > 0
                     then Round((targetAchieved / "Denominator Count") * 100.0, 2)
                     else null,
    targetThreshold: '≥10.0 g/dL'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '血紅素(Hemoglobin(Hb))平均值',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Sum",
    numeratorDefinition: '分母病人的血紅素 (Hb) 數值總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的血液透析病人數（有血紅素檢驗值）',
    hemoglobinAverage: "Hemoglobin Average",
    hemoglobinRangeDistribution: "Hemoglobin Range Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    anemicPatients: "Anemic Patients",
    anemicCount: Count("Anemic Patients"),
    targetAchievement: "Target Achievement Statistics",
    unit: 'g/dL',
    formula: '分子/分母',
    referenceRange: '男性 13-18 g/dL, 女性 12-16 g/dL',
    dialysisTarget: '透析病人建議 ≥10.0 g/dL'
  }
