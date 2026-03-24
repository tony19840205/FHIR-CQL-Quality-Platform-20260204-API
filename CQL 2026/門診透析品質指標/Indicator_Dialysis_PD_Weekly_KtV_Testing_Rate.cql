/**
 * 指標名稱: 腹膜透析效率(Weekly Kt/V)檢查比率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每半年
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 執行「尿素氮週透析效率(Weekly Kt/V)」檢查之人數
 * 分母: 腹膜透析人數
 * 
 * 計算期間: 2026年上半年(民國115年上半年)
 * 
 * 說明: 此為正向品質指標，檢查比率越高代表腹膜透析效率監測越完善
 */

library Indicator_Dialysis_PD_Weekly_KtV_Testing_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-06-30T23:59:59.0+08:00

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

// Weekly Kt/V檢驗代碼
define "Weekly KtV Laboratory Codes":
  { Code { code: '23155-1', system: 'http://loinc.org', display: 'Kt/V dialysis clearance in Peritoneal dialysate' },
    Code { code: '58872-7', system: 'http://loinc.org', display: 'Kt/V Urea renal clearance in Serum or Plasma' },
    Code { code: '90245-6', system: 'http://loinc.org', display: 'Kt/V Dialysis clearance weekly in Peritoneal dialysate' },
    Code { code: '23156-9', system: 'http://loinc.org', display: 'Kt/V Urea renal clearance weekly' }
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

// 觀察期間（每半年）
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

// 觀察期間內的Weekly Kt/V檢驗
define "Weekly KtV Observations During Period":
  [Observation] O
  where O.effective during "Measurement Period"
  and O.status.value in { 'final', 'amended', 'corrected' }
  and exists (
    O.code.coding C
    where C in "Weekly KtV Laboratory Codes"
  )
  and GetObservationValue(O) is not null

// 有Weekly Kt/V檢查的腹膜透析病人
define "Patients With Weekly KtV Testing":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      patientKtVTests: "Weekly KtV Observations During Period" O
                       where O.subject.reference.value = patientId,
      hasKtVTest: exists(patientKtVTests)
  where hasKtVTest
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    testCount: Count(patientKtVTests),
    latestKtV: Last(
      patientKtVTests O
      let value: GetObservationValue(O),
          testDate: O.effective as FHIR.dateTime
      where value is not null
      sort by testDate
      return { value: value, date: testDate }
    )
  }

// 分子: 執行「尿素氮週透析效率(Weekly Kt/V)」檢查之人數
define "Numerator Count":
  Count("Patients With Weekly KtV Testing")

// ========================================================================================
// 指標計算
// ========================================================================================

// Weekly Kt/V檢查比率
define "Weekly KtV Testing Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Weekly KtV Testing By Age Group":
  "Patients With Weekly KtV Testing" T
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
    "Weekly KtV Testing By Age Group" T return T.ageGroup
  ) AgeGroup
  let groupTested: Count("Weekly KtV Testing By Age Group" T where T.ageGroup = AgeGroup),
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
define "Weekly KtV Testing By Gender":
  "Patients With Weekly KtV Testing" T
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
    "Weekly KtV Testing By Gender" T return T.gender
  ) Gender
  let genderTested: Count("Weekly KtV Testing By Gender" T where T.gender = Gender),
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
define "Weekly KtV Testing By Organization":
  "Patients With Weekly KtV Testing" T
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
    "Weekly KtV Testing By Organization" T return T.organizationId
  ) OrgId
  let orgTested: Count("Weekly KtV Testing By Organization" T where T.organizationId = OrgId),
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

// 檢查頻率分析（每位病人的Weekly Kt/V檢查次數）
define "Weekly KtV Testing Frequency Analysis":
  "Patients With Weekly KtV Testing" T
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
    "Weekly KtV Testing Frequency Analysis" F return F.frequencyRange
  ) FreqRange
  let rangeCount: Count("Weekly KtV Testing Frequency Analysis" F where F.frequencyRange = FreqRange),
      avgTests: Avg("Weekly KtV Testing Frequency Analysis" F where F.frequencyRange = FreqRange return F.testCount)
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

// 已執行Weekly Kt/V檢查病人詳細資訊
define "Tested Patient Details":
  "Patients With Weekly KtV Testing" T
  return {
    patientId: T.patientId,
    age: T.age,
    gender: T.gender,
    testCount: T.testCount,
    latestKtVValue: if T.latestKtV is not null then T.latestKtV.value else null,
    latestKtVDate: if T.latestKtV is not null then ToString(T.latestKtV.date) else null,
    adequacyStatus: if T.latestKtV is not null
                    then (
                      if T.latestKtV.value < 1.5 then '不足'
                      else if T.latestKtV.value < 1.7 then '接近目標'
                      else if T.latestKtV.value < 2.0 then '達標'
                      else if T.latestKtV.value < 2.5 then '良好'
                      else '優秀'
                    )
                    else null,
    meetStandardTarget: if T.latestKtV is not null
                        then (T.latestKtV.value >= 1.7)
                        else null,
    meetOptimalTarget: if T.latestKtV is not null
                       then (T.latestKtV.value >= 2.0)
                       else null
  }
  sort by testCount desc

// 未執行Weekly Kt/V檢查病人
define "Patients Without Weekly KtV Testing":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      hasTesting: exists (
        "Patients With Weekly KtV Testing" T
        where T.patientId = patientId
      )
  where not hasTesting
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 未執行Weekly Kt/V檢查病人統計
define "Untested Patient Statistics":
  let totalUntested: Count("Patients Without Weekly KtV Testing"),
      untestedRate: if "Denominator Count" > 0
                    then Round((totalUntested / "Denominator Count") * 100.0, 2)
                    else null
  return {
    untestedCount: totalUntested,
    untestedRate: untestedRate,
    note: '這些病人未執行Weekly Kt/V檢查，需要加強腹膜透析效率監測'
  }

// 透析效率狀況分布（已檢查病人）
define "Adequacy Status Distribution":
  "Tested Patient Details" T
  where T.latestKtVValue is not null
  let status: T.adequacyStatus
  return {
    status: status,
    patientId: T.patientId,
    ktVValue: T.latestKtVValue
  }

// 透析效率狀況統計
define "Adequacy Status Statistics":
  distinct (
    "Adequacy Status Distribution" A return A.status
  ) Status
  let statusCount: Count("Adequacy Status Distribution" A where A.status = Status),
      avgKtV: Avg("Adequacy Status Distribution" A where A.status = Status return A.ktVValue)
  return {
    adequacyStatus: Status,
    patientCount: statusCount,
    percentage: if "Numerator Count" > 0
                then Round((statusCount / "Numerator Count") * 100.0, 2)
                else null,
    averageKtV: if avgKtV is not null then Round(avgKtV, 2) else null
  }
  sort by 
    case when adequacyStatus = '不足' then 1
         when adequacyStatus = '接近目標' then 2
         when adequacyStatus = '達標' then 3
         when adequacyStatus = '良好' then 4
         else 5
    end

// 目標達成分析
define "Target Achievement Analysis":
  let testedWithValues: "Tested Patient Details" T where T.latestKtVValue is not null,
      totalWithValues: Count(testedWithValues),
      meetingStandard: Count(testedWithValues T where T.meetStandardTarget = true),
      meetingOptimal: Count(testedWithValues T where T.meetOptimalTarget = true),
      standardRate: if totalWithValues > 0
                    then Round((meetingStandard / totalWithValues) * 100.0, 2)
                    else null,
      optimalRate: if totalWithValues > 0
                   then Round((meetingOptimal / totalWithValues) * 100.0, 2)
                   else null
  return {
    totalTestedPatients: totalWithValues,
    patientsMetStandardTarget: meetingStandard,
    patientsMetOptimalTarget: meetingOptimal,
    patientsNotMetStandardTarget: totalWithValues - meetingStandard,
    standardTargetAchievementRate: standardRate,
    optimalTargetAchievementRate: optimalRate,
    standardTargetDefinition: 'Weekly Kt/V ≥ 1.7（腹膜透析充分性標準目標）',
    optimalTargetDefinition: 'Weekly Kt/V ≥ 2.0（腹膜透析充分性最佳目標）'
  }

// 透析模式分析（CAPD vs CCPD vs APD）
define "Dialysis Modality Analysis":
  "Patients With Weekly KtV Testing" T
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
    indicatorName: '腹膜透析效率(Weekly Kt/V)檢查比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每半年',
    numerator: "Numerator Count",
    numeratorDefinition: '執行「尿素氮週透析效率(Weekly Kt/V)」檢查之人數',
    denominator: "Denominator Count",
    denominatorDefinition: '腹膜透析人數',
    weeklyKtVTestingRate: "Weekly KtV Testing Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    testingFrequencyDistribution: "Testing Frequency Statistics",
    adequacyStatusDistribution: "Adequacy Status Statistics",
    targetAchievementAnalysis: "Target Achievement Analysis",
    dialysisModalityDistribution: "Dialysis Modality Statistics",
    testedPatientDetails: "Tested Patient Details",
    untestedPatientStatistics: "Untested Patient Statistics",
    untestedPatientList: "Patients Without Weekly KtV Testing",
    unit: '%',
    formula: '(分子/分母) x 100%',
    weeklyKtVReference: '標準目標: Weekly Kt/V ≥ 1.7；最佳目標: Weekly Kt/V ≥ 2.0',
    ktVDefinition: 'Kt/V = (K × t) / V，其中K為尿素清除率(L/hr)、t為時間(hours)、V為尿素分布容積(體內總水分)',
    note: '此為正向品質指標，檢查比率越高代表腹膜透析效率監測越完善。Weekly Kt/V是評估腹膜透析充分性的重要指標，建議定期檢查（每3-6個月）。Weekly Kt/V ≥ 1.7為標準目標，≥ 2.0為最佳目標。適當的透析充分性可改善病人生活品質並降低併發症風險。'
  }
