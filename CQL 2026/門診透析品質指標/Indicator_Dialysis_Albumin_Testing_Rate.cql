/**
 * 指標名稱: 血液透析血清白蛋白(Albumin)檢查比率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 執行「血清白蛋白(Albumin)檢查」之人數
 * 分母: 血液透析人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 * 
 * 說明: 此為正向品質指標，檢查比率越高代表營養狀況監測越完善
 */

library Indicator_Dialysis_Albumin_Testing_Rate version '1.0.0'

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

// 血液透析處置代碼
define "Hemodialysis Procedure Codes":
  { Code { code: '108241001', system: 'http://snomed.info/sct', display: 'Hemodialysis procedure' },
    Code { code: '302497006', system: 'http://snomed.info/sct', display: 'Hemodialysis' },
    Code { code: '427053002', system: 'http://snomed.info/sct', display: 'Extracorporeal hemodialysis' }
  }

// 白蛋白(Albumin)檢驗代碼
define "Albumin Laboratory Codes":
  { Code { code: '1751-7', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma' },
    Code { code: '2862-1', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum or Plasma by Bromocresol green (BCG) method' },
    Code { code: '61151-7', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum, Plasma or Blood by Bromocresol green (BCG) dye binding method' },
    Code { code: '61152-5', system: 'http://loinc.org', display: 'Albumin [Mass/volume] in Serum, Plasma or Blood by Bromocresol purple (BCP) dye binding method' }
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

// 血液透析病人（有血液透析處置記錄的病人）
define "Hemodialysis Patients":
  distinct (
    "Hemodialysis Procedures During Period" P
    return singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.subject.reference.value)
  )

// 分母: 血液透析人數
define "Denominator Count":
  Count("Hemodialysis Patients")

// 觀察期間內的白蛋白檢驗
define "Albumin Observations During Period":
  [Observation] O
  where O.effective during "Measurement Period"
  and O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "Albumin Laboratory Codes"
  )
  and GetObservationValue(O) is not null

// 有白蛋白檢查的血液透析病人
define "Patients With Albumin Testing":
  "Hemodialysis Patients" P
  let patientId: 'Patient/' + P.id,
      patientAlbuminTests: "Albumin Observations During Period" O
                           where O.subject.reference.value = patientId,
      hasAlbuminTest: exists(patientAlbuminTests)
  where hasAlbuminTest
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    testCount: Count(patientAlbuminTests),
    latestAlbumin: Last(
      patientAlbuminTests O
      let value: GetObservationValue(O),
          testDate: O.effective as FHIR.dateTime
      where value is not null
      sort by testDate
      return { value: value, date: testDate }
    )
  }

// 分子: 執行「血清白蛋白(Albumin)檢查」之人數
define "Numerator Count":
  Count("Patients With Albumin Testing")

// ========================================================================================
// 指標計算
// ========================================================================================

// 白蛋白檢查比率
define "Albumin Testing Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Albumin Testing By Age Group":
  "Patients With Albumin Testing" T
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
    "Albumin Testing By Age Group" T return T.ageGroup
  ) AgeGroup
  let groupTested: Count("Albumin Testing By Age Group" T where T.ageGroup = AgeGroup),
      groupTotal: Count(
        "Hemodialysis Patients" P
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
define "Albumin Testing By Gender":
  "Patients With Albumin Testing" T
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
    "Albumin Testing By Gender" T return T.gender
  ) Gender
  let genderTested: Count("Albumin Testing By Gender" T where T.gender = Gender),
      genderTotal: Count(
        "Hemodialysis Patients" P
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
define "Albumin Testing By Organization":
  "Patients With Albumin Testing" T
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
    "Albumin Testing By Organization" T return T.organizationId
  ) OrgId
  let orgTested: Count("Albumin Testing By Organization" T where T.organizationId = OrgId),
      orgTotal: Count(
        "Hemodialysis Patients" P
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

// 檢查頻率分析（每位病人的白蛋白檢查次數）
define "Albumin Testing Frequency Analysis":
  "Patients With Albumin Testing" T
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
    "Albumin Testing Frequency Analysis" F return F.frequencyRange
  ) FreqRange
  let rangeCount: Count("Albumin Testing Frequency Analysis" F where F.frequencyRange = FreqRange),
      avgTests: Avg("Albumin Testing Frequency Analysis" F where F.frequencyRange = FreqRange return F.testCount)
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

// 已執行白蛋白檢查病人詳細資訊
define "Tested Patient Details":
  "Patients With Albumin Testing" T
  return {
    patientId: T.patientId,
    age: T.age,
    gender: T.gender,
    testCount: T.testCount,
    latestAlbuminValue: if T.latestAlbumin is not null then T.latestAlbumin.value else null,
    latestAlbuminDate: if T.latestAlbumin is not null then ToString(T.latestAlbumin.date) else null,
    nutritionalStatus: if T.latestAlbumin is not null
                       then (
                         if T.latestAlbumin.value < 3.0 then '嚴重營養不良'
                         else if T.latestAlbumin.value < 3.5 then '營養不良'
                         else if T.latestAlbumin.value >= 3.5 and T.latestAlbumin.value <= 5.0 then '正常'
                         else '偏高'
                       )
                       else null
  }
  sort by testCount desc

// 未執行白蛋白檢查病人
define "Patients Without Albumin Testing":
  "Hemodialysis Patients" P
  let patientId: 'Patient/' + P.id,
      hasTesting: exists (
        "Patients With Albumin Testing" T
        where T.patientId = patientId
      )
  where not hasTesting
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 未執行白蛋白檢查病人統計
define "Untested Patient Statistics":
  let totalUntested: Count("Patients Without Albumin Testing"),
      untestedRate: if "Denominator Count" > 0
                    then Round((totalUntested / "Denominator Count") * 100.0, 2)
                    else null
  return {
    untestedCount: totalUntested,
    untestedRate: untestedRate,
    note: '這些病人未執行白蛋白檢查，需要加強營養狀況監測'
  }

// 營養狀況分布（已檢查病人）
define "Nutritional Status Distribution":
  "Tested Patient Details" T
  where T.latestAlbuminValue is not null
  let status: T.nutritionalStatus
  return {
    status: status,
    patientId: T.patientId,
    albuminValue: T.latestAlbuminValue
  }

// 營養狀況統計
define "Nutritional Status Statistics":
  distinct (
    "Nutritional Status Distribution" N return N.status
  ) Status
  let statusCount: Count("Nutritional Status Distribution" N where N.status = Status),
      avgAlbumin: Avg("Nutritional Status Distribution" N where N.status = Status return N.albuminValue)
  return {
    nutritionalStatus: Status,
    patientCount: statusCount,
    percentage: if "Numerator Count" > 0
                then Round((statusCount / "Numerator Count") * 100.0, 2)
                else null,
    averageAlbumin: if avgAlbumin is not null then Round(avgAlbumin, 2) else null
  }
  sort by 
    case when nutritionalStatus = '嚴重營養不良' then 1
         when nutritionalStatus = '營養不良' then 2
         when nutritionalStatus = '正常' then 3
         else 4
    end

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '血液透析血清白蛋白(Albumin)檢查比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Count",
    numeratorDefinition: '執行「血清白蛋白(Albumin)檢查」之人數',
    denominator: "Denominator Count",
    denominatorDefinition: '血液透析人數',
    albuminTestingRate: "Albumin Testing Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    testingFrequencyDistribution: "Testing Frequency Statistics",
    nutritionalStatusDistribution: "Nutritional Status Statistics",
    testedPatientDetails: "Tested Patient Details",
    untestedPatientStatistics: "Untested Patient Statistics",
    untestedPatientList: "Patients Without Albumin Testing",
    unit: '%',
    formula: '(分子/分母) x 100%',
    albuminReference: '正常範圍: 3.5-5.0 g/dL；<3.5 g/dL 提示營養不良',
    note: '此為正向品質指標，檢查比率越高代表營養狀況監測越完善。白蛋白是評估透析病人營養狀況的重要指標，建議每月至少檢查一次。低白蛋白與透析病人死亡率顯著相關。'
  }
