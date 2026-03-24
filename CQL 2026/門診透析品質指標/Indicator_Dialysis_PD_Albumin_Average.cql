/**
 * 指標名稱: 血清白蛋白(Albumin)平均值 - 腹膜透析
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: 分子/分母
 * 
 * 分子: 分母病人的血清白蛋白數值總和
 * 分母: 透析醫療院所照護的腹膜透析病人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 */

library Indicator_Dialysis_PD_Albumin_Average version '1.0.0'

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

// 血清白蛋白檢驗代碼 (包含不同檢測方法)
define "Albumin Laboratory Codes":
  { Code { code: '1751-7', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma' },
    Code { code: '2862-1', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma by Electrophoresis' },
    Code { code: '61151-7', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma by Bromocresol green (BCG) dye binding method' },
    Code { code: '61152-5', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma by Bromocresol purple (BCP) dye binding method' }
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

// 每位病人的最新白蛋白檢驗值
define "Latest Albumin Per Patient":
  "Peritoneal Dialysis Patients" P
  let patientAlbumins: "Albumin Observations During Period" O
                       where O.subject.reference.value = 'Patient/' + P.id
                       sort by effective as FHIR.dateTime desc,
      latestAlbumin: First(patientAlbumins)
  where latestAlbumin is not null
  return {
    patientId: 'Patient/' + P.id,
    albumin: GetObservationValue(latestAlbumin),
    testDate: latestAlbumin.effective as FHIR.dateTime,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 透析醫療院所照護的腹膜透析病人數（有白蛋白檢驗值的病人）
define "Denominator Count":
  Count("Latest Albumin Per Patient")

// 分子: 分母病人的血清白蛋白數值總和
define "Numerator Sum":
  Sum("Latest Albumin Per Patient" A return A.albumin)

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

// 白蛋白數值範圍統計
define "Albumin Range Statistics":
  let ranges: { 
    { range: '<3.0 g/dL (嚴重低下)', min: 0.0, max: 2.99 },
    { range: '3.0-3.4 g/dL (低下)', min: 3.0, max: 3.49 },
    { range: '3.5-3.9 g/dL (正常偏低)', min: 3.5, max: 3.99 },
    { range: '4.0-5.0 g/dL (正常)', min: 4.0, max: 5.0 },
    { range: '>5.0 g/dL (偏高)', min: 5.01, max: 999.0 }
  }
  return ranges R
  let patientsInRange: "Latest Albumin Per Patient" A
                       where A.albumin >= R.min and A.albumin <= R.max
  return {
    range: R.range,
    patientCount: Count(patientsInRange),
    percentage: if "Denominator Count" > 0 
                then Round((Count(patientsInRange) / "Denominator Count") * 100.0, 2)
                else null,
    averageInRange: if Count(patientsInRange) > 0
                    then Round(Avg(patientsInRange A return A.albumin), 2)
                    else null
  }

// 依年齡層分析
define "Albumin By Age Group":
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
    albumin: A.albumin
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Albumin By Age Group" A return A.ageGroup
  ) AgeGroup
  let groupAlbumins: "Albumin By Age Group" A where A.ageGroup = AgeGroup
  return {
    ageGroup: AgeGroup,
    patientCount: Count(groupAlbumins),
    averageAlbumin: Round(Avg(groupAlbumins G return G.albumin), 2),
    minAlbumin: Round(Min(groupAlbumins G return G.albumin), 2),
    maxAlbumin: Round(Max(groupAlbumins G return G.albumin), 2)
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
define "Albumin By Gender":
  "Latest Albumin Per Patient" A
  let gender: if A.gender = 'male' then '男性'
              else if A.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    albumin: A.albumin
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Albumin By Gender" A return A.gender
  ) Gender
  let genderAlbumins: "Albumin By Gender" A where A.gender = Gender
  return {
    gender: Gender,
    patientCount: Count(genderAlbumins),
    averageAlbumin: Round(Avg(genderAlbumins G return G.albumin), 2),
    minAlbumin: Round(Min(genderAlbumins G return G.albumin), 2),
    maxAlbumin: Round(Max(genderAlbumins G return G.albumin), 2)
  }

// 依醫療機構分析
define "Albumin By Organization":
  "Latest Albumin Per Patient" A
  let encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = A.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    albumin: A.albumin
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Albumin By Organization" A return A.organizationId
  ) OrgId
  let orgAlbumins: "Albumin By Organization" A where A.organizationId = OrgId
  return {
    organizationId: OrgId,
    patientCount: Count(orgAlbumins),
    averageAlbumin: Round(Avg(orgAlbumins O return O.albumin), 2),
    minAlbumin: Round(Min(orgAlbumins O return O.albumin), 2),
    maxAlbumin: Round(Max(orgAlbumins O return O.albumin), 2)
  }
  sort by averageAlbumin desc

// 低白蛋白病人名單 (< 3.5 g/dL 需要關注)
define "Low Albumin Patients":
  "Latest Albumin Per Patient" A
  where A.albumin < 3.5
  return {
    patientId: A.patientId,
    albumin: A.albumin,
    testDate: A.testDate,
    age: A.age,
    gender: A.gender,
    severity: if A.albumin < 3.0 then '嚴重低下'
              else '低下'
  }
  sort by albumin asc

// 低白蛋白統計
define "Low Albumin Statistics":
  let totalLowAlbumin: Count("Low Albumin Patients"),
      severeLowCount: Count("Low Albumin Patients" L where L.albumin < 3.0),
      mildLowCount: Count("Low Albumin Patients" L where L.albumin >= 3.0 and L.albumin < 3.5)
  return {
    totalLowAlbuminPatients: totalLowAlbumin,
    severeLow: severeLowCount,
    mildLow: mildLowCount,
    percentageOfTotal: if "Denominator Count" > 0
                       then Round((totalLowAlbumin / "Denominator Count") * 100.0, 2)
                       else null
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '血清白蛋白(Albumin)平均值 - 腹膜透析',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Sum",
    numeratorDefinition: '分母病人的血清白蛋白數值總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的腹膜透析病人數',
    albuminAverage: "Albumin Average",
    albuminRangeDistribution: "Albumin Range Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    lowAlbuminStatistics: "Low Albumin Statistics",
    lowAlbuminPatientList: "Low Albumin Patients",
    unit: 'g/dL',
    formula: '分子/分母',
    referenceRange: '正常範圍: 3.5-5.0 g/dL',
    note: '血清白蛋白是評估腹膜透析病人營養狀態的重要指標。平均值越高，表示整體營養狀況越好。'
  }
