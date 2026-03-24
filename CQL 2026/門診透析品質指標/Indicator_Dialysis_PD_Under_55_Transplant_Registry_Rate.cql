/**
 * 指標名稱: 五十五歲以下腹膜透析病人移植登錄率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每年
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 55歲以下腹膜透析病患移植登錄人數
 * 分母: 55歲以下腹膜透析病患人數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dialysis_PD_Under_55_Transplant_Registry_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-12-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

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

// 腎臟移植等待登錄狀態代碼
define "Kidney Transplant Waiting List Codes":
  { Code { code: '707147002', system: 'http://snomed.info/sct', display: 'On waiting list for kidney transplant' },
    Code { code: '438924007', system: 'http://snomed.info/sct', display: 'Awaiting organ transplant' }
  }

// 腎臟移植候選者狀態代碼
define "Transplant Candidate Status Codes":
  { Code { code: 'Z76.82', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Awaiting organ transplant status' }
  }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Extension布林值
define function GetExtensionBoolean(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.boolean

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

// 檢查病人是否已登錄移植等待名單
define function IsOnTransplantWaitingList(patient Patient):
  exists (
    [Condition] C
    where C.subject.reference.value = 'Patient/' + patient.id
    and C.clinicalStatus.coding[0].code.value = 'active'
    and exists (
      C.code.coding CC
      where CC in "Kidney Transplant Waiting List Codes" or CC in "Transplant Candidate Status Codes"
    )
  )

// 取得移植登錄日期
define function GetTransplantRegistrationDate(patient Patient):
  let conditions: [Condition] C
                  where C.subject.reference.value = 'Patient/' + patient.id
                  and exists (
                    C.code.coding CC
                    where CC in "Kidney Transplant Waiting List Codes" or CC in "Transplant Candidate Status Codes"
                  )
                  sort by onset as FHIR.dateTime
  return if Count(conditions) > 0
         then First(conditions).onset as FHIR.dateTime
         else null

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間（年度）
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

// 55歲以下的腹膜透析病人
define "Under 55 Peritoneal Dialysis Patients":
  "Peritoneal Dialysis Patients" P
  let age: GetPatientAge(P)
  where age < 55
  return {
    patientId: 'Patient/' + P.id,
    age: age,
    gender: GetPatientGender(P),
    birthDate: P.birthDate
  }

// 分母: 55歲以下腹膜透析病患人數
define "Denominator Count":
  Count("Under 55 Peritoneal Dialysis Patients")

// 55歲以下且已登錄移植等待名單的腹膜透析病人
define "Under 55 PD Patients On Transplant Waiting List":
  "Under 55 Peritoneal Dialysis Patients" U
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = U.patientId),
      isRegistered: IsOnTransplantWaitingList(patient),
      registrationDate: GetTransplantRegistrationDate(patient)
  where isRegistered
  return {
    patientId: U.patientId,
    age: U.age,
    gender: U.gender,
    registrationDate: registrationDate,
    daysSinceRegistration: if registrationDate is not null
                           then days between registrationDate and Today()
                           else null
  }

// 分子: 55歲以下腹膜透析病患移植登錄人數
define "Numerator Count":
  Count("Under 55 PD Patients On Transplant Waiting List")

// ========================================================================================
// 指標計算
// ========================================================================================

// 五十五歲以下腹膜透析病人移植登錄率
define "Under 55 PD Transplant Registry Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析（55歲以下細分）
define "Registered Patients By Age Group":
  "Under 55 PD Patients On Transplant Waiting List" R
  let ageGroup: if R.age < 18 then '<18歲'
                else if R.age >= 18 and R.age < 30 then '18-29歲'
                else if R.age >= 30 and R.age < 40 then '30-39歲'
                else if R.age >= 40 and R.age < 50 then '40-49歲'
                else '50-54歲'
  return {
    ageGroup: ageGroup,
    patientId: R.patientId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Registered Patients By Age Group" R return R.ageGroup
  ) AgeGroup
  let groupRegistered: Count("Registered Patients By Age Group" R where R.ageGroup = AgeGroup),
      groupTotal: Count(
        "Under 55 Peritoneal Dialysis Patients" U
        let patientAgeGroup: if U.age < 18 then '<18歲'
                             else if U.age >= 18 and U.age < 30 then '18-29歲'
                             else if U.age >= 30 and U.age < 40 then '30-39歲'
                             else if U.age >= 40 and U.age < 50 then '40-49歲'
                             else '50-54歲'
        where patientAgeGroup = AgeGroup
        return U
      )
  return {
    ageGroup: AgeGroup,
    registeredCount: groupRegistered,
    totalPatientsInGroup: groupTotal,
    registryRate: if groupTotal > 0
                  then Round((groupRegistered / groupTotal) * 100.0, 2)
                  else null
  }
  sort by 
    case when ageGroup = '<18歲' then 1
         when ageGroup = '18-29歲' then 2
         when ageGroup = '30-39歲' then 3
         when ageGroup = '40-49歲' then 4
         else 5
    end

// 依性別分析
define "Registered Patients By Gender":
  "Under 55 PD Patients On Transplant Waiting List" R
  let gender: if R.gender = 'male' then '男性'
              else if R.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    patientId: R.patientId
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Registered Patients By Gender" R return R.gender
  ) Gender
  let genderRegistered: Count("Registered Patients By Gender" R where R.gender = Gender),
      genderTotal: Count(
        "Under 55 Peritoneal Dialysis Patients" U
        let patientGender: if U.gender = 'male' then '男性'
                           else if U.gender = 'female' then '女性'
                           else '其他'
        where patientGender = Gender
        return U
      )
  return {
    gender: Gender,
    registeredCount: genderRegistered,
    totalPatientsInGroup: genderTotal,
    registryRate: if genderTotal > 0
                  then Round((genderRegistered / genderTotal) * 100.0, 2)
                  else null
  }

// 依醫療機構分析
define "Registered Patients By Organization":
  "Under 55 PD Patients On Transplant Waiting List" R
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = R.patientId),
      encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = R.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    patientId: R.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Registered Patients By Organization" R return R.organizationId
  ) OrgId
  let orgRegistered: Count("Registered Patients By Organization" R where R.organizationId = OrgId),
      orgTotal: Count(
        "Under 55 Peritoneal Dialysis Patients" U
        let encounters: "Dialysis Encounters During Period" E
                        where GetPatientReference(E.subject) = U.patientId,
            patientOrg: if Count(encounters) > 0
                        then GetEncounterOrganization(Last(encounters E sort by E.period.start))
                        else null
        where patientOrg = OrgId
        return U
      )
  return {
    organizationId: OrgId,
    registeredCount: orgRegistered,
    totalPatients: orgTotal,
    registryRate: if orgTotal > 0
                  then Round((orgRegistered / orgTotal) * 100.0, 2)
                  else null
  }
  sort by registryRate desc

// 等待時間分析（已登錄病人的等待天數分布）
define "Waiting Time Analysis":
  "Under 55 PD Patients On Transplant Waiting List" R
  let timeRange: if R.daysSinceRegistration is null then '未知'
                 else if R.daysSinceRegistration < 180 then '<6個月'
                 else if R.daysSinceRegistration >= 180 and R.daysSinceRegistration < 365 then '6個月-1年'
                 else if R.daysSinceRegistration >= 365 and R.daysSinceRegistration < 730 then '1-2年'
                 else if R.daysSinceRegistration >= 730 and R.daysSinceRegistration < 1095 then '2-3年'
                 else '≥3年'
  return {
    timeRange: timeRange,
    patientId: R.patientId,
    daysSinceRegistration: R.daysSinceRegistration
  }

// 等待時間統計
define "Waiting Time Statistics":
  distinct (
    "Waiting Time Analysis" T return T.timeRange
  ) TimeRange
  let rangeCount: Count("Waiting Time Analysis" T where T.timeRange = TimeRange),
      avgDays: Avg("Waiting Time Analysis" T where T.timeRange = TimeRange return T.daysSinceRegistration)
  return {
    timeRange: TimeRange,
    patientCount: rangeCount,
    percentage: if "Numerator Count" > 0
                then Round((rangeCount / "Numerator Count") * 100.0, 2)
                else null,
    averageDays: if avgDays is not null then Round(avgDays, 0) else null
  }
  sort by 
    case when timeRange = '<6個月' then 1
         when timeRange = '6個月-1年' then 2
         when timeRange = '1-2年' then 3
         when timeRange = '2-3年' then 4
         when timeRange = '≥3年' then 5
         else 6
    end

// 已登錄病人詳細名單
define "Registered Patient Details":
  "Under 55 PD Patients On Transplant Waiting List" R
  return {
    patientId: R.patientId,
    age: R.age,
    gender: R.gender,
    registrationDate: R.registrationDate,
    daysSinceRegistration: R.daysSinceRegistration,
    yearsOnWaitingList: if R.daysSinceRegistration is not null
                        then Round(R.daysSinceRegistration / 365.25, 1)
                        else null
  }
  sort by registrationDate

// 未登錄病人（55歲以下但未登錄移植等待名單）
define "Unregistered Under 55 PD Patients":
  "Under 55 Peritoneal Dialysis Patients" U
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = U.patientId),
      isRegistered: IsOnTransplantWaitingList(patient)
  where not isRegistered
  return {
    patientId: U.patientId,
    age: U.age,
    gender: U.gender
  }

// 未登錄病人統計
define "Unregistered Patient Statistics":
  let totalUnregistered: Count("Unregistered Under 55 PD Patients"),
      unregisteredRate: if "Denominator Count" > 0
                        then Round((totalUnregistered / "Denominator Count") * 100.0, 2)
                        else null
  return {
    unregisteredCount: totalUnregistered,
    unregisteredRate: unregisteredRate,
    note: '這些病人符合年齡條件但尚未登錄移植等待名單'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '五十五歲以下腹膜透析病人移植登錄率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每年',
    numerator: "Numerator Count",
    numeratorDefinition: '55歲以下腹膜透析病患移植登錄人數',
    denominator: "Denominator Count",
    denominatorDefinition: '55歲以下腹膜透析病患人數',
    registryRate: "Under 55 PD Transplant Registry Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    waitingTimeDistribution: "Waiting Time Statistics",
    registeredPatientDetails: "Registered Patient Details",
    unregisteredPatientStatistics: "Unregistered Patient Statistics",
    unregisteredPatientList: "Unregistered Under 55 PD Patients",
    unit: '%',
    formula: '(分子/分母) x 100%',
    note: '較高的登錄率表示醫療機構積極協助適合的腹膜透析病人登錄腎臟移植等待名單，為正向品質指標。腹膜透析病人同樣具備接受腎臟移植的資格，移植是慢性腎病的最佳治療選擇。'
  }
