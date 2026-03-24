/**
 * 指標名稱: 血清白蛋白(Albumin)平均值
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: 分子/分母
 * 
 * 分子: 分母病人的血清白蛋白數值總和
 * 分母: 透析醫療院所照護的血液透析病人數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dialysis_Albumin_Average version '1.0.0'

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

// 血清白蛋白檢驗LOINC代碼
define "Albumin Laboratory Codes":
  { Code { code: '1751-7', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma' },
    Code { code: '2862-1', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum' },
    Code { code: '61151-7', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma by Bromocresol green (BCG) dye binding method' },
    Code { code: '61152-5', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma by Bromocresol purple (BCP) dye binding method' }
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

// 觀察期間內的血清白蛋白檢驗
define "Albumin Observations During Period":
  [Observation] O
  where O.effective during "Measurement Period"
  and O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "Albumin Laboratory Codes"
  )
  and GetObservationValue(O) is not null

// 血液透析病人的血清白蛋白檢驗
define "Albumin Observations For Hemodialysis Patients":
  "Albumin Observations During Period" O
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

// 每位病人的最新血清白蛋白值
define "Latest Albumin Per Patient":
  "Hemodialysis Patients" P
  let patientAlbumins: "Albumin Observations For Hemodialysis Patients" O
                       where O.patientId = 'Patient/' + P.id
                       sort by effectiveDateTime desc,
      latestAlbumin: First(patientAlbumins)
  where latestAlbumin is not null
  return {
    patientId: 'Patient/' + P.id,
    albuminValue: latestAlbumin.value,
    unit: latestAlbumin.unit,
    observationDate: latestAlbumin.effectiveDateTime,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 透析醫療院所照護的血液透析病人數（有白蛋白檢驗值的病人）
define "Denominator Count":
  Count("Latest Albumin Per Patient")

// 分子: 分母病人的血清白蛋白數值總和
define "Numerator Sum":
  Sum("Latest Albumin Per Patient" A return A.albuminValue)

// ========================================================================================
// 指標計算
// ========================================================================================

// 血清白蛋白平均值
define "Albumin Average":
  if "Denominator Count" > 0 
  then Round("Numerator Sum" / "Denominator Count", 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依白蛋白值範圍分層
define "Patients By Albumin Range":
  "Latest Albumin Per Patient" A
  let range: if A.albuminValue < 3.0 then '<3.0 g/dL (低)'
             else if A.albuminValue >= 3.0 and A.albuminValue < 3.5 then '3.0-3.4 g/dL'
             else if A.albuminValue >= 3.5 and A.albuminValue < 4.0 then '3.5-3.9 g/dL (正常下限)'
             else if A.albuminValue >= 4.0 and A.albuminValue < 4.5 then '4.0-4.4 g/dL (正常)'
             else if A.albuminValue >= 4.5 and A.albuminValue < 5.0 then '4.5-4.9 g/dL (正常)'
             else '≥5.0 g/dL (正常上限)'
  return {
    range: range,
    patientId: A.patientId,
    albuminValue: A.albuminValue
  }

// 白蛋白值範圍統計
define "Albumin Range Statistics":
  distinct (
    "Patients By Albumin Range" P return P.range
  ) Range
  let rangeCount: Count("Patients By Albumin Range" P where P.range = Range),
      rangeAvg: Avg("Patients By Albumin Range" P where P.range = Range return P.albuminValue)
  return {
    albuminRange: Range,
    patientCount: rangeCount,
    percentage: if "Denominator Count" > 0
                then Round((rangeCount / "Denominator Count") * 100.0, 2)
                else null,
    averageValue: Round(rangeAvg, 2)
  }
  sort by 
    case when albuminRange = '<3.0 g/dL (低)' then 1
         when albuminRange = '3.0-3.4 g/dL' then 2
         when albuminRange = '3.5-3.9 g/dL (正常下限)' then 3
         when albuminRange = '4.0-4.4 g/dL (正常)' then 4
         when albuminRange = '4.5-4.9 g/dL (正常)' then 5
         else 6
    end

// 依年齡層分析
define "Results By Age Group":
  "Latest Albumin Per Patient" A
  let ageGroup: if A.age < 18 then '<18歲'
                else if A.age >= 18 and A.age < 40 then '18-39歲'
                else if A.age >= 40 and A.age < 50 then '40-49歲'
                else if A.age >= 50 and A.age < 60 then '50-59歲'
                else if A.age >= 60 and A.age < 70 then '60-69歲'
                else if A.age >= 70 and A.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    albuminValue: A.albuminValue
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Results By Age Group" R return R.ageGroup
  ) AgeGroup
  let groupCount: Count("Results By Age Group" R where R.ageGroup = AgeGroup),
      groupAvg: Avg("Results By Age Group" R where R.ageGroup = AgeGroup return R.albuminValue)
  return {
    ageGroup: AgeGroup,
    patientCount: groupCount,
    averageAlbumin: Round(groupAvg, 2),
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
  "Latest Albumin Per Patient" A
  let gender: if A.gender = 'male' then '男性'
              else if A.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    albuminValue: A.albuminValue
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Results By Gender" R return R.gender
  ) Gender
  let genderCount: Count("Results By Gender" R where R.gender = Gender),
      genderAvg: Avg("Results By Gender" R where R.gender = Gender return R.albuminValue)
  return {
    gender: Gender,
    patientCount: genderCount,
    averageAlbumin: Round(genderAvg, 2),
    percentage: if "Denominator Count" > 0
                then Round((genderCount / "Denominator Count") * 100.0, 2)
                else null
  }

// 依醫療機構分析
define "Results By Organization":
  "Latest Albumin Per Patient" LA
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = LA.patientId),
      encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = LA.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    albuminValue: LA.albuminValue,
    patientId: LA.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Results By Organization" R return R.organizationId
  ) OrgId
  let orgCount: Count("Results By Organization" R where R.organizationId = OrgId),
      orgAvg: Avg("Results By Organization" R where R.organizationId = OrgId return R.albuminValue),
      orgPatients: Count(
        distinct (
          "Results By Organization" R where R.organizationId = OrgId return R.patientId
        )
      )
  return {
    organizationId: OrgId,
    patientCount: orgPatients,
    observationCount: orgCount,
    averageAlbumin: Round(orgAvg, 2)
  }
  sort by averageAlbumin desc

// 低白蛋白病人名單（<3.5 g/dL）
define "Low Albumin Patients":
  "Latest Albumin Per Patient" A
  where A.albuminValue < 3.5
  return {
    patientId: A.patientId,
    albuminValue: A.albuminValue,
    unit: A.unit,
    observationDate: A.observationDate,
    age: A.age,
    gender: A.gender
  }
  sort by albuminValue

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '血清白蛋白(Albumin)平均值',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Sum",
    numeratorDefinition: '分母病人的血清白蛋白數值總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的血液透析病人數（有白蛋白檢驗值）',
    albuminAverage: "Albumin Average",
    albuminRangeDistribution: "Albumin Range Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    lowAlbuminPatients: "Low Albumin Patients",
    lowAlbuminCount: Count("Low Albumin Patients"),
    unit: 'g/dL',
    formula: '分子/分母',
    referenceRange: '正常範圍 3.5-5.0 g/dL'
  }
