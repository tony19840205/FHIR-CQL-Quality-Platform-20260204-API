/**
 * 指標名稱: 血液透析尿素氮透析效率(URR)檢查比率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 執行尿素氮透析效率(URR)檢查人數
 * 分母: 血液透析人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 * 
 * 說明: 此為正向品質指標，檢查比率越高代表透析品質監測越完善
 */

library Indicator_Dialysis_URR_Testing_Rate version '1.0.0'

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

// BUN (血尿素氮) 檢驗代碼
define "BUN Laboratory Codes":
  { Code { code: '3094-0', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Serum or Plasma' },
    Code { code: '6299-2', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Blood' },
    Code { code: '59570-2', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Blood pre dialysis' },
    Code { code: '11065-0', system: 'http://loinc.org', display: 'Urea nitrogen [Mass/volume] in Blood post dialysis' }
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

// 透析前BUN檢驗
define "Pre Dialysis BUN Observations":
  "BUN Observations During Period" O
  where exists (
    O.code.coding C
    where C.code.value = '59570-2'
  )
  or exists (
    O.code.coding C
    where C.code.value in { '3094-0', '6299-2' }
    and (O.effective as FHIR.dateTime).value.toString() contains 'pre'
  )

// 透析後BUN檢驗
define "Post Dialysis BUN Observations":
  "BUN Observations During Period" O
  where exists (
    O.code.coding C
    where C.code.value = '11065-0'
  )
  or exists (
    O.code.coding C
    where C.code.value in { '3094-0', '6299-2' }
    and (O.effective as FHIR.dateTime).value.toString() contains 'post'
  )

// 有URR檢查的病人（需要透析前和透析後BUN配對）
define "Patients With URR Testing":
  "Hemodialysis Patients" P
  let patientId: 'Patient/' + P.id,
      patientPreBUN: "Pre Dialysis BUN Observations" O
                     where O.subject.reference.value = patientId,
      patientPostBUN: "Post Dialysis BUN Observations" O
                      where O.subject.reference.value = patientId,
      hasPreBUN: exists(patientPreBUN),
      hasPostBUN: exists(patientPostBUN),
      hasURRPair: exists (
        patientPreBUN PreObs
        let preDate: PreObs.effective as FHIR.dateTime,
            matchingPostObs: First(
              patientPostBUN PostObs
              let postDate: PostObs.effective as FHIR.dateTime
              where hours between preDate and postDate >= 0
              and hours between preDate and postDate <= 6
              sort by effective as FHIR.dateTime
            )
        where matchingPostObs is not null
        return PreObs
      )
  where hasURRPair
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    preBUNCount: Count(patientPreBUN),
    postBUNCount: Count(patientPostBUN)
  }

// 分子: 執行尿素氮透析效率(URR)檢查人數
define "Numerator Count":
  Count("Patients With URR Testing")

// ========================================================================================
// 指標計算
// ========================================================================================

// URR檢查比率
define "URR Testing Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "URR Testing By Age Group":
  "Patients With URR Testing" T
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
    "URR Testing By Age Group" T return T.ageGroup
  ) AgeGroup
  let groupTested: Count("URR Testing By Age Group" T where T.ageGroup = AgeGroup),
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
define "URR Testing By Gender":
  "Patients With URR Testing" T
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
    "URR Testing By Gender" T return T.gender
  ) Gender
  let genderTested: Count("URR Testing By Gender" T where T.gender = Gender),
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
define "URR Testing By Organization":
  "Patients With URR Testing" T
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
    "URR Testing By Organization" T return T.organizationId
  ) OrgId
  let orgTested: Count("URR Testing By Organization" T where T.organizationId = OrgId),
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

// 檢查頻率分析（每位病人的URR檢查次數）
define "URR Testing Frequency Analysis":
  "Patients With URR Testing" T
  let testCount: T.preBUNCount,
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
    "URR Testing Frequency Analysis" F return F.frequencyRange
  ) FreqRange
  let rangeCount: Count("URR Testing Frequency Analysis" F where F.frequencyRange = FreqRange),
      avgTests: Avg("URR Testing Frequency Analysis" F where F.frequencyRange = FreqRange return F.testCount)
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

// 已執行URR檢查病人詳細資訊
define "Tested Patient Details":
  "Patients With URR Testing" T
  return {
    patientId: T.patientId,
    age: T.age,
    gender: T.gender,
    preBUNTestCount: T.preBUNCount,
    postBUNTestCount: T.postBUNCount
  }
  sort by preBUNTestCount desc

// 未執行URR檢查病人
define "Patients Without URR Testing":
  "Hemodialysis Patients" P
  let patientId: 'Patient/' + P.id,
      hasTesting: exists (
        "Patients With URR Testing" T
        where T.patientId = patientId
      )
  where not hasTesting
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 未執行URR檢查病人統計
define "Untested Patient Statistics":
  let totalUntested: Count("Patients Without URR Testing"),
      untestedRate: if "Denominator Count" > 0
                    then Round((totalUntested / "Denominator Count") * 100.0, 2)
                    else null
  return {
    untestedCount: totalUntested,
    untestedRate: untestedRate,
    note: '這些病人未執行URR檢查，需要加強透析效率監測'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '血液透析尿素氮透析效率(URR)檢查比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Count",
    numeratorDefinition: '執行尿素氮透析效率(URR)檢查人數',
    denominator: "Denominator Count",
    denominatorDefinition: '血液透析人數',
    urrTestingRate: "URR Testing Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    testingFrequencyDistribution: "Testing Frequency Statistics",
    testedPatientDetails: "Tested Patient Details",
    untestedPatientStatistics: "Untested Patient Statistics",
    untestedPatientList: "Patients Without URR Testing",
    unit: '%',
    formula: '(分子/分母) x 100%',
    urrDefinition: 'URR需要透析前和透析後BUN檢驗配對（6小時內），計算公式: [(透析前BUN - 透析後BUN) / 透析前BUN] × 100%',
    note: '此為正向品質指標，檢查比率越高代表透析品質監測越完善。URR是評估透析充分性的重要指標，建議每月至少檢查一次。'
  }
