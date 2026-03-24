/**
 * 指標名稱: 腹膜透析貧血檢查(Hb)檢查比率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 執行「貧血(Hb)檢查」之人數
 * 分母: 腹膜透析人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 * 
 * 說明: 此為正向品質指標，檢查比率越高代表貧血監測越完善
 */

library Indicator_Dialysis_PD_Hemoglobin_Testing_Rate version '1.0.0'

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

// 腹膜透析處置代碼
define "Peritoneal Dialysis Procedure Codes":
  { Code { code: '71192002', system: 'http://snomed.info/sct', display: 'Peritoneal dialysis' },
    Code { code: '225230008', system: 'http://snomed.info/sct', display: 'Chronic peritoneal dialysis' },
    Code { code: '238316008', system: 'http://snomed.info/sct', display: 'Continuous ambulatory peritoneal dialysis (CAPD)' },
    Code { code: '238317004', system: 'http://snomed.info/sct', display: 'Continuous cyclical peritoneal dialysis (CCPD)' },
    Code { code: '238318009', system: 'http://snomed.info/sct', display: 'Automated peritoneal dialysis (APD)' }
  }

// 血紅素(Hemoglobin)檢驗代碼
define "Hemoglobin Laboratory Codes":
  { Code { code: '718-7', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood' },
    Code { code: '30350-3', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Venous blood' },
    Code { code: '30351-1', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Mixed venous blood' },
    Code { code: '20509-6', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood by calculation' },
    Code { code: '55782-7', system: 'http://loinc.org', display: 'Hemoglobin [Mass/volume] in Blood by Oximetry' }
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

// 分母: 腹膜透析人數
define "Denominator Count":
  Count("Peritoneal Dialysis Patients")

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

// 有血紅素檢查的腹膜透析病人
define "Patients With Hemoglobin Testing":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      patientHbTests: "Hemoglobin Observations During Period" O
                      where O.subject.reference.value = patientId,
      hasHbTest: exists(patientHbTests)
  where hasHbTest
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    testCount: Count(patientHbTests),
    latestHb: Last(
      patientHbTests O
      let value: GetObservationValue(O),
          testDate: O.effective as FHIR.dateTime
      where value is not null
      sort by testDate
      return { value: value, date: testDate }
    )
  }

// 分子: 執行「貧血(Hb)檢查」之人數
define "Numerator Count":
  Count("Patients With Hemoglobin Testing")

// ========================================================================================
// 指標計算
// ========================================================================================

// 血紅素檢查比率
define "Hemoglobin Testing Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Hemoglobin Testing By Age Group":
  "Patients With Hemoglobin Testing" T
  let ageGroup: if T.age < 18 then '<18歲'
                else if T.age >= 18 and T.age < 40 then '18-39歲'
                else if T.age >= 40 and T.age < 50 then '40-49歲'
                else if T.age >= 50 and T.age < 60 then '50-59歲'
                else if T.age >= 60 and T.age < 70 then '60-69歲'
                else if T.age >= 70 and T.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    patientId: T.patientId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Hemoglobin Testing By Age Group" T return T.ageGroup
  ) AgeGroup
  let groupTested: Count("Hemoglobin Testing By Age Group" T where T.ageGroup = AgeGroup),
      groupTotal: Count(
        "Peritoneal Dialysis Patients" P
        let patientAgeGroup: if GetPatientAge(P) < 18 then '<18歲'
                             else if GetPatientAge(P) >= 18 and GetPatientAge(P) < 40 then '18-39歲'
                             else if GetPatientAge(P) >= 40 and GetPatientAge(P) < 50 then '40-49歲'
                             else if GetPatientAge(P) >= 50 and GetPatientAge(P) < 60 then '50-59歲'
                             else if GetPatientAge(P) >= 60 and GetPatientAge(P) < 70 then '60-69歲'
                             else if GetPatientAge(P) >= 70 and GetPatientAge(P) < 80 then '70-79歲'
                             else '≥80歲'
        where patientAgeGroup = AgeGroup
        return P
      )
  return {
    ageGroup: AgeGroup,
    testedCount: groupTested,
    totalPatients: groupTotal,
    testingRate: if groupTotal > 0
                 then Round((groupTested / groupTotal) * 100.0, 2)
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
define "Hemoglobin Testing By Gender":
  "Patients With Hemoglobin Testing" T
  let gender: if T.gender = 'male' then '男性'
              else if T.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    patientId: T.patientId
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Hemoglobin Testing By Gender" T return T.gender
  ) Gender
  let genderTested: Count("Hemoglobin Testing By Gender" T where T.gender = Gender),
      genderTotal: Count(
        "Peritoneal Dialysis Patients" P
        let patientGender: if GetPatientGender(P) = 'male' then '男性'
                           else if GetPatientGender(P) = 'female' then '女性'
                           else '其他'
        where patientGender = Gender
        return P
      )
  return {
    gender: Gender,
    testedCount: genderTested,
    totalPatients: genderTotal,
    testingRate: if genderTotal > 0
                 then Round((genderTested / genderTotal) * 100.0, 2)
                 else null
  }

// 依醫療機構分析
define "Hemoglobin Testing By Organization":
  "Patients With Hemoglobin Testing" T
  let encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = T.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    patientId: T.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Hemoglobin Testing By Organization" T return T.organizationId
  ) OrgId
  let orgTested: Count("Hemoglobin Testing By Organization" T where T.organizationId = OrgId),
      orgTotal: Count(
        "Peritoneal Dialysis Patients" P
        let encounters: "Dialysis Encounters During Period" E
                        where GetPatientReference(E.subject) = 'Patient/' + P.id,
            patientOrg: if Count(encounters) > 0
                        then GetEncounterOrganization(Last(encounters E sort by E.period.start))
                        else null
        where patientOrg = OrgId
        return P
      )
  return {
    organizationId: OrgId,
    testedCount: orgTested,
    totalPatients: orgTotal,
    testingRate: if orgTotal > 0
                 then Round((orgTested / orgTotal) * 100.0, 2)
                 else null
  }
  sort by testingRate desc

// 檢查頻率分析（每位病人的血紅素檢查次數）
define "Hemoglobin Testing Frequency Analysis":
  "Patients With Hemoglobin Testing" T
  let testCount: T.testCount,
      frequencyRange: if testCount = 1 then '1次'
                      else if testCount = 2 then '2次'
                      else if testCount = 3 then '3次'
                      else if testCount >= 4 and testCount <= 6 then '4-6次'
                      else '≥7次'
  return {
    frequencyRange: frequencyRange,
    patientId: T.patientId,
    testCount: testCount
  }

// 檢查頻率統計
define "Testing Frequency Statistics":
  distinct (
    "Hemoglobin Testing Frequency Analysis" F return F.frequencyRange
  ) FreqRange
  let rangeCount: Count("Hemoglobin Testing Frequency Analysis" F where F.frequencyRange = FreqRange),
      avgTests: Avg("Hemoglobin Testing Frequency Analysis" F where F.frequencyRange = FreqRange return F.testCount)
  return {
    frequencyRange: FreqRange,
    patientCount: rangeCount,
    percentage: if "Numerator Count" > 0
                then Round((rangeCount / "Numerator Count") * 100.0, 2)
                else null,
    averageTests: if avgTests is not null then Round(avgTests, 1) else null
  }
  sort by 
    case when frequencyRange = '1次' then 1
         when frequencyRange = '2次' then 2
         when frequencyRange = '3次' then 3
         when frequencyRange = '4-6次' then 4
         else 5
    end

// 已執行血紅素檢查病人詳細資訊
define "Tested Patient Details":
  "Patients With Hemoglobin Testing" T
  return {
    patientId: T.patientId,
    age: T.age,
    gender: T.gender,
    testCount: T.testCount,
    latestHbValue: if T.latestHb is not null then T.latestHb.value else null,
    latestHbDate: if T.latestHb is not null then ToString(T.latestHb.date) else null,
    anemiaStatus: if T.latestHb is not null
                  then (
                    if T.latestHb.value < 10.0 then '嚴重貧血'
                    else if T.latestHb.value < 11.0 then '中度貧血'
                    else if T.latestHb.value < 12.0 then '輕度貧血'
                    else if T.latestHb.value >= 12.0 and T.latestHb.value < 16.0 then '正常範圍'
                    else '偏高'
                  )
                  else null,
    meetTarget: if T.latestHb is not null
                then (T.latestHb.value >= 10.0)
                else null
  }
  sort by testCount desc

// 未執行血紅素檢查病人
define "Patients Without Hemoglobin Testing":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      hasTesting: exists (
        "Patients With Hemoglobin Testing" T
        where T.patientId = patientId
      )
  where not hasTesting
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 未執行血紅素檢查病人統計
define "Untested Patient Statistics":
  let totalUntested: Count("Patients Without Hemoglobin Testing"),
      untestedRate: if "Denominator Count" > 0
                    then Round((totalUntested / "Denominator Count") * 100.0, 2)
                    else null
  return {
    untestedCount: totalUntested,
    untestedRate: untestedRate,
    note: '這些病人未執行血紅素檢查，需要加強貧血監測'
  }

// 貧血狀況分布（已檢查病人）
define "Anemia Status Distribution":
  "Tested Patient Details" T
  where T.latestHbValue is not null
  let status: T.anemiaStatus
  return {
    status: status,
    patientId: T.patientId,
    hbValue: T.latestHbValue
  }

// 貧血狀況統計
define "Anemia Status Statistics":
  distinct (
    "Anemia Status Distribution" A return A.status
  ) Status
  let statusCount: Count("Anemia Status Distribution" A where A.status = Status),
      avgHb: Avg("Anemia Status Distribution" A where A.status = Status return A.hbValue)
  return {
    anemiaStatus: Status,
    patientCount: statusCount,
    percentage: if "Numerator Count" > 0
                then Round((statusCount / "Numerator Count") * 100.0, 2)
                else null,
    averageHb: if avgHb is not null then Round(avgHb, 2) else null
  }
  sort by 
    case when anemiaStatus = '嚴重貧血' then 1
         when anemiaStatus = '中度貧血' then 2
         when anemiaStatus = '輕度貧血' then 3
         when anemiaStatus = '正常範圍' then 4
         else 5
    end

// 目標達成分析（Hb ≥ 10.0 g/dL）
define "Target Achievement Analysis":
  let testedWithValues: "Tested Patient Details" T where T.latestHbValue is not null,
      totalWithValues: Count(testedWithValues),
      meetingTarget: Count(testedWithValues T where T.meetTarget = true),
      achievementRate: if totalWithValues > 0
                       then Round((meetingTarget / totalWithValues) * 100.0, 2)
                       else null
  return {
    totalTestedPatients: totalWithValues,
    patientsMetTarget: meetingTarget,
    patientsNotMetTarget: totalWithValues - meetingTarget,
    targetAchievementRate: achievementRate,
    targetDefinition: 'Hb ≥ 10.0 g/dL（透析病人貧血治療目標）'
  }

// 透析模式分析（CAPD vs CCPD vs APD）
define "Dialysis Modality Analysis":
  "Patients With Hemoglobin Testing" T
  let patientProcedures: "Peritoneal Dialysis Procedures During Period" P
                         where P.subject.reference.value = T.patientId,
      mostRecentProcedure: Last(patientProcedures P sort by P.performed as FHIR.dateTime),
      modalityCode: if mostRecentProcedure is not null
                    then First(mostRecentProcedure.code.coding).code.value
                    else null,
      modality: if modalityCode = '238316008' then 'CAPD'
                else if modalityCode = '238317004' then 'CCPD'
                else if modalityCode = '238318009' then 'APD'
                else if modalityCode = '225230008' then '慢性腹膜透析'
                else if modalityCode = '71192002' then '腹膜透析'
                else '未分類'
  where modality is not null
  return {
    modality: modality,
    patientId: T.patientId
  }

// 透析模式統計
define "Dialysis Modality Statistics":
  distinct (
    "Dialysis Modality Analysis" D return D.modality
  ) Modality
  let modalityCount: Count("Dialysis Modality Analysis" D where D.modality = Modality)
  return {
    dialysisModality: Modality,
    patientCount: modalityCount,
    percentage: if "Numerator Count" > 0
                then Round((modalityCount / "Numerator Count") * 100.0, 2)
                else null
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '腹膜透析貧血檢查(Hb)檢查比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Count",
    numeratorDefinition: '執行「貧血(Hb)檢查」之人數',
    denominator: "Denominator Count",
    denominatorDefinition: '腹膜透析人數',
    hemoglobinTestingRate: "Hemoglobin Testing Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    testingFrequencyDistribution: "Testing Frequency Statistics",
    anemiaStatusDistribution: "Anemia Status Statistics",
    targetAchievementAnalysis: "Target Achievement Analysis",
    dialysisModalityDistribution: "Dialysis Modality Statistics",
    testedPatientDetails: "Tested Patient Details",
    untestedPatientStatistics: "Untested Patient Statistics",
    untestedPatientList: "Patients Without Hemoglobin Testing",
    unit: '%',
    formula: '(分子/分母) x 100%',
    hemoglobinReference: '透析病人目標: ≥10.0 g/dL；正常範圍: 男性13-18 g/dL, 女性12-16 g/dL',
    note: '此為正向品質指標，檢查比率越高代表貧血監測越完善。血紅素是評估腹膜透析病人貧血治療成效的重要指標，建議每月至少檢查一次。適當的貧血治療可改善透析病人生活品質並降低心血管併發症風險。腹膜透析病人保有較多殘餘腎功能，貧血狀況可能較血液透析病人輕微。'
  }
