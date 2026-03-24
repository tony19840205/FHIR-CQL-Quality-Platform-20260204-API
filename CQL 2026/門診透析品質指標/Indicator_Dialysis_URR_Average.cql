/**
 * 指標名稱: 尿素氮透析效率(URR)平均值
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: 分子/分母
 * 
 * 分子: 分母病人的尿素氮透析效率(URR)數值總和
 * 分母: 透析醫療院所照護的血液透析病人數
 * 
 * URR計算公式: [(透析前BUN - 透析後BUN) / 透析前BUN] × 100%
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dialysis_URR_Average version '1.0.0'

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

// 尿素氮(BUN)檢驗LOINC代碼
define "BUN Laboratory Codes":
  { Code { code: '3094-0', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Serum or Plasma' },
    Code { code: '6299-2', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Blood' },
    Code { code: '59570-2', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Serum or Plasma --pre dialysis' },
    Code { code: '11065-0', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Serum or Plasma --post dialysis' }
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

// 取得Observation的timing（透析前/後）
define function GetObservationTiming(obs Observation):
  GetExtensionString(obs, 'dialysisTiming')

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

// 觀察期間內的BUN檢驗
define "BUN Observations During Period":
  [Observation] O
  where O.effective during "Measurement Period"
  and O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "BUN Laboratory Codes"
  )
  and GetObservationValue(O) is not null

// 血液透析病人的BUN檢驗
define "BUN Observations For Hemodialysis Patients":
  "BUN Observations During Period" O
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = O.subject.reference.value)
  where patient in "Hemodialysis Patients"
  return {
    observationId: 'Observation/' + O.id,
    patientId: 'Patient/' + patient.id,
    value: GetObservationValue(O),
    unit: GetObservationUnit(O),
    effectiveDateTime: O.effective as FHIR.dateTime,
    timing: GetObservationTiming(O),
    status: O.status.value
  }

// 透析前BUN檢驗
define "Pre Dialysis BUN Observations":
  "BUN Observations For Hemodialysis Patients" O
  where O.timing = 'pre-dialysis' or O.timing is null
  return O

// 透析後BUN檢驗
define "Post Dialysis BUN Observations":
  "BUN Observations For Hemodialysis Patients" O
  where O.timing = 'post-dialysis'
  return O

// 每位病人的URR計算（配對透析前後BUN值）
define "URR Per Patient":
  "Hemodialysis Patients" P
  let preBUNs: "Pre Dialysis BUN Observations" O
               where O.patientId = 'Patient/' + P.id
               sort by effectiveDateTime desc,
      postBUNs: "Post Dialysis BUN Observations" O
                where O.patientId = 'Patient/' + P.id
                sort by effectiveDateTime desc,
      // 取最近的配對值（透析前和透析後）
      latestPreBUN: First(preBUNs),
      matchedPostBUN: First(
        postBUNs PO
        where latestPreBUN is not null
        and PO.effectiveDateTime > latestPreBUN.effectiveDateTime
        and hours between latestPreBUN.effectiveDateTime and PO.effectiveDateTime <= 6
      ),
      // URR計算: [(透析前BUN - 透析後BUN) / 透析前BUN] × 100%
      urrValue: if latestPreBUN is not null and matchedPostBUN is not null and latestPreBUN.value > 0
                then ((latestPreBUN.value - matchedPostBUN.value) / latestPreBUN.value) * 100.0
                else null
  where urrValue is not null
  return {
    patientId: 'Patient/' + P.id,
    urrValue: urrValue,
    preBUN: latestPreBUN.value,
    postBUN: matchedPostBUN.value,
    preBUNDate: latestPreBUN.effectiveDateTime,
    postBUNDate: matchedPostBUN.effectiveDateTime,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 透析醫療院所照護的血液透析病人數（有URR計算值的病人）
define "Denominator Count":
  Count("URR Per Patient")

// 分子: 分母病人的URR數值總和
define "Numerator Sum":
  Sum("URR Per Patient" U return U.urrValue)

// ========================================================================================
// 指標計算
// ========================================================================================

// URR平均值
define "URR Average":
  if "Denominator Count" > 0 
  then Round("Numerator Sum" / "Denominator Count", 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依URR值範圍分層
define "Patients By URR Range":
  "URR Per Patient" U
  let range: if U.urrValue < 50.0 then '<50% (不足)'
             else if U.urrValue >= 50.0 and U.urrValue < 60.0 then '50-59% (偏低)'
             else if U.urrValue >= 60.0 and U.urrValue < 65.0 then '60-64% (接近達標)'
             else if U.urrValue >= 65.0 and U.urrValue < 70.0 then '65-69% (達標)'
             else if U.urrValue >= 70.0 and U.urrValue < 75.0 then '70-74% (良好)'
             else if U.urrValue >= 75.0 and U.urrValue < 80.0 then '75-79% (優良)'
             else '≥80% (優異)'
  return {
    range: range,
    patientId: U.patientId,
    urrValue: U.urrValue
  }

// URR值範圍統計
define "URR Range Statistics":
  distinct (
    "Patients By URR Range" P return P.range
  ) Range
  let rangeCount: Count("Patients By URR Range" P where P.range = Range),
      rangeAvg: Avg("Patients By URR Range" P where P.range = Range return P.urrValue)
  return {
    urrRange: Range,
    patientCount: rangeCount,
    percentage: if "Denominator Count" > 0
                then Round((rangeCount / "Denominator Count") * 100.0, 2)
                else null,
    averageValue: Round(rangeAvg, 2)
  }
  sort by 
    case when urrRange = '<50% (不足)' then 1
         when urrRange = '50-59% (偏低)' then 2
         when urrRange = '60-64% (接近達標)' then 3
         when urrRange = '65-69% (達標)' then 4
         when urrRange = '70-74% (良好)' then 5
         when urrRange = '75-79% (優良)' then 6
         else 7
    end

// 依年齡層分析
define "Results By Age Group":
  "URR Per Patient" U
  let ageGroup: if U.age < 18 then '<18歲'
                else if U.age >= 18 and U.age < 40 then '18-39歲'
                else if U.age >= 40 and U.age < 50 then '40-49歲'
                else if U.age >= 50 and U.age < 60 then '50-59歲'
                else if U.age >= 60 and U.age < 70 then '60-69歲'
                else if U.age >= 70 and U.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    urrValue: U.urrValue
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Results By Age Group" R return R.ageGroup
  ) AgeGroup
  let groupCount: Count("Results By Age Group" R where R.ageGroup = AgeGroup),
      groupAvg: Avg("Results By Age Group" R where R.ageGroup = AgeGroup return R.urrValue)
  return {
    ageGroup: AgeGroup,
    patientCount: groupCount,
    averageURR: Round(groupAvg, 2),
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
  "URR Per Patient" U
  let gender: if U.gender = 'male' then '男性'
              else if U.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    urrValue: U.urrValue
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Results By Gender" R return R.gender
  ) Gender
  let genderCount: Count("Results By Gender" R where R.gender = Gender),
      genderAvg: Avg("Results By Gender" R where R.gender = Gender return R.urrValue),
      genderMin: Min("Results By Gender" R where R.gender = Gender return R.urrValue),
      genderMax: Max("Results By Gender" R where R.gender = Gender return R.urrValue)
  return {
    gender: Gender,
    patientCount: genderCount,
    averageURR: Round(genderAvg, 2),
    minURR: Round(genderMin, 2),
    maxURR: Round(genderMax, 2),
    percentage: if "Denominator Count" > 0
                then Round((genderCount / "Denominator Count") * 100.0, 2)
                else null
  }

// 依醫療機構分析
define "Results By Organization":
  "URR Per Patient" U
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = U.patientId),
      encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = U.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    urrValue: U.urrValue,
    patientId: U.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Results By Organization" R return R.organizationId
  ) OrgId
  let orgCount: Count("Results By Organization" R where R.organizationId = OrgId),
      orgAvg: Avg("Results By Organization" R where R.organizationId = OrgId return R.urrValue),
      orgMin: Min("Results By Organization" R where R.organizationId = OrgId return R.urrValue),
      orgMax: Max("Results By Organization" R where R.organizationId = OrgId return R.urrValue),
      orgPatients: Count(
        distinct (
          "Results By Organization" R where R.organizationId = OrgId return R.patientId
        )
      )
  return {
    organizationId: OrgId,
    patientCount: orgPatients,
    observationCount: orgCount,
    averageURR: Round(orgAvg, 2),
    minURR: Round(orgMin, 2),
    maxURR: Round(orgMax, 2)
  }
  sort by averageURR desc

// URR未達標病人名單（<65%）
define "Inadequate URR Patients":
  "URR Per Patient" U
  where U.urrValue < 65.0
  return {
    patientId: U.patientId,
    urrValue: U.urrValue,
    preBUN: U.preBUN,
    postBUN: U.postBUN,
    preBUNDate: U.preBUNDate,
    postBUNDate: U.postBUNDate,
    age: U.age,
    gender: U.gender,
    status: if U.urrValue < 50.0 then '嚴重不足'
            else if U.urrValue < 60.0 then '偏低'
            else '接近達標'
  }
  sort by urrValue

// 達標統計（URR ≥65%）
define "Target Achievement Statistics":
  let targetAchieved: Count("URR Per Patient" U where U.urrValue >= 65.0),
      targetNotAchieved: Count("URR Per Patient" U where U.urrValue < 65.0),
      optimalAchieved: Count("URR Per Patient" U where U.urrValue >= 70.0)
  return {
    totalPatients: "Denominator Count",
    targetAchieved: targetAchieved,
    targetNotAchieved: targetNotAchieved,
    optimalAchieved: optimalAchieved,
    achievementRate: if "Denominator Count" > 0
                     then Round((targetAchieved / "Denominator Count") * 100.0, 2)
                     else null,
    optimalRate: if "Denominator Count" > 0
                 then Round((optimalAchieved / "Denominator Count") * 100.0, 2)
                 else null,
    targetThreshold: '≥65%',
    optimalThreshold: '≥70%'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '尿素氮透析效率(URR)平均值',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Sum",
    numeratorDefinition: '分母病人的尿素氮透析效率(URR)數值總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的血液透析病人數（有URR計算值）',
    urrAverage: "URR Average",
    urrRangeDistribution: "URR Range Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    inadequateURRPatients: "Inadequate URR Patients",
    inadequateCount: Count("Inadequate URR Patients"),
    targetAchievement: "Target Achievement Statistics",
    unit: '%',
    formula: '分子/分母',
    urrFormula: '[(透析前BUN - 透析後BUN) / 透析前BUN] × 100%',
    targetRange: 'URR ≥65% (最佳 ≥70%)',
    note: 'URR為透析效率指標，需配對透析前後BUN值計算'
  }
