/**
 * 指標名稱: 脫離率 (腎移植率)
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 因接受腎臟移植手術，而不須再透析的人數總和
 * 分母: 透析醫療院所照護的血液透析病人數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dialysis_Kidney_Transplant_Rate version '1.0.0'

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

// 腎臟移植手術代碼
define "Kidney Transplant Procedure Codes":
  { Code { code: '70536003', system: 'http://snomed.info/sct', display: 'Transplant of kidney' },
    Code { code: '313030004', system: 'http://snomed.info/sct', display: 'Kidney transplant with donor nephrectomy' },
    Code { code: '175899003', system: 'http://snomed.info/sct', display: 'Autotransplantation of kidney' },
    Code { code: '6471000179103', system: 'http://snomed.info/sct', display: 'Transplantation of kidney from beating heart cadaver' },
    Code { code: '52213001', system: 'http://snomed.info/sct', display: 'Renal homotransplantation' }
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

// 移植腎功能良好狀態代碼
define "Functioning Kidney Transplant Codes":
  { Code { code: 'Z94.0', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Kidney transplant status' },
    Code { code: '236578006', system: 'http://snomed.info/sct', display: 'Functioning renal transplant' }
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

// 檢查病人在移植後是否仍有透析記錄
define function HasDialysisAfterTransplant(patient Patient, transplantDate DateTime):
  exists (
    [Procedure] P
    where P.subject.reference.value = 'Patient/' + patient.id
    and P.performed as FHIR.dateTime > transplantDate
    and P.status.value = 'completed'
    and exists (
      P.code.coding C
      where C in "Hemodialysis Procedure Codes"
    )
  )

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

// 分母: 透析醫療院所照護的血液透析病人數
define "Denominator Count":
  Count("Hemodialysis Patients")

// 觀察期間內的腎臟移植手術
define "Kidney Transplant Procedures During Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "Kidney Transplant Procedure Codes"
  )

// 接受腎移植且不再需要透析的病人
define "Patients With Successful Kidney Transplant":
  "Kidney Transplant Procedures During Period" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.subject.reference.value),
      transplantDate: P.performed as FHIR.dateTime,
      wasOnDialysis: patient in "Hemodialysis Patients",
      noDialysisAfterTransplant: not HasDialysisAfterTransplant(patient, transplantDate),
      // 檢查是否有移植腎功能良好的診斷記錄
      hasFunctioningTransplant: exists (
        [Condition] C
        where C.subject.reference.value = 'Patient/' + patient.id
        and exists (
          C.code.coding CC
          where CC in "Functioning Kidney Transplant Codes"
        )
        and C.onset as FHIR.dateTime >= transplantDate
      )
  where wasOnDialysis
  and (noDialysisAfterTransplant or hasFunctioningTransplant)
  return {
    patientId: 'Patient/' + patient.id,
    transplantProcedureId: 'Procedure/' + P.id,
    transplantDate: transplantDate,
    age: GetPatientAge(patient),
    gender: GetPatientGender(patient),
    noDialysisAfterTransplant: noDialysisAfterTransplant,
    hasFunctioningTransplant: hasFunctioningTransplant
  }

// 分子: 因接受腎臟移植手術而不須再透析的人數
define "Numerator Count":
  Count("Patients With Successful Kidney Transplant")

// ========================================================================================
// 指標計算
// ========================================================================================

// 脫離率 (腎移植率)
define "Kidney Transplant Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Transplant Patients By Age Group":
  "Patients With Successful Kidney Transplant" T
  let ageGroup: if T.age < 18 then '<18歲'
                else if T.age >= 18 and T.age < 30 then '18-29歲'
                else if T.age >= 30 and T.age < 40 then '30-39歲'
                else if T.age >= 40 and T.age < 50 then '40-49歲'
                else if T.age >= 50 and T.age < 60 then '50-59歲'
                else if T.age >= 60 and T.age < 70 then '60-69歲'
                else '≥70歲'
  return {
    ageGroup: ageGroup,
    patientId: T.patientId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Transplant Patients By Age Group" T return T.ageGroup
  ) AgeGroup
  let groupCount: Count("Transplant Patients By Age Group" T where T.ageGroup = AgeGroup),
      groupTotalPatients: Count(
        "Hemodialysis Patients" P
        let age: GetPatientAge(P),
            patientAgeGroup: if age < 18 then '<18歲'
                             else if age >= 18 and age < 30 then '18-29歲'
                             else if age >= 30 and age < 40 then '30-39歲'
                             else if age >= 40 and age < 50 then '40-49歲'
                             else if age >= 50 and age < 60 then '50-59歲'
                             else if age >= 60 and age < 70 then '60-69歲'
                             else '≥70歲'
        where patientAgeGroup = AgeGroup
        return P
      )
  return {
    ageGroup: AgeGroup,
    transplantCount: groupCount,
    totalPatientsInGroup: groupTotalPatients,
    transplantRate: if groupTotalPatients > 0
                    then Round((groupCount / groupTotalPatients) * 100.0, 2)
                    else null
  }
  sort by 
    case when ageGroup = '<18歲' then 1
         when ageGroup = '18-29歲' then 2
         when ageGroup = '30-39歲' then 3
         when ageGroup = '40-49歲' then 4
         when ageGroup = '50-59歲' then 5
         when ageGroup = '60-69歲' then 6
         else 7
    end

// 依性別分析
define "Transplant Patients By Gender":
  "Patients With Successful Kidney Transplant" T
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
    "Transplant Patients By Gender" T return T.gender
  ) Gender
  let genderCount: Count("Transplant Patients By Gender" T where T.gender = Gender),
      genderTotalPatients: Count(
        "Hemodialysis Patients" P
        let patientGender: if GetPatientGender(P) = 'male' then '男性'
                           else if GetPatientGender(P) = 'female' then '女性'
                           else '其他'
        where patientGender = Gender
        return P
      )
  return {
    gender: Gender,
    transplantCount: genderCount,
    totalPatientsInGroup: genderTotalPatients,
    transplantRate: if genderTotalPatients > 0
                    then Round((genderCount / genderTotalPatients) * 100.0, 2)
                    else null
  }

// 依醫療機構分析
define "Transplant Patients By Organization":
  "Patients With Successful Kidney Transplant" T
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = T.patientId),
      encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = T.patientId
                  and E.period.start < T.transplantDate,
      lastDialysisEncounter: Last(encounters E sort by E.period.start),
      organization: if lastDialysisEncounter is not null
                    then GetEncounterOrganization(lastDialysisEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    patientId: T.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Transplant Patients By Organization" T return T.organizationId
  ) OrgId
  let orgTransplants: Count("Transplant Patients By Organization" T where T.organizationId = OrgId),
      orgTotalPatients: Count(
        distinct (
          "Dialysis Encounters During Period" E
          where GetEncounterOrganization(E) = OrgId
          return GetPatientReference(E.subject)
        )
      )
  return {
    organizationId: OrgId,
    transplantCount: orgTransplants,
    totalPatients: orgTotalPatients,
    transplantRate: if orgTotalPatients > 0
                    then Round((orgTransplants / orgTotalPatients) * 100.0, 2)
                    else null
  }
  sort by transplantRate desc

// 月度趨勢分析
define "Monthly Trend Analysis":
  "Patients With Successful Kidney Transplant" T
  let month: ToString(year from T.transplantDate) + '-' + 
             ToString(month from T.transplantDate)
  return {
    month: month,
    patientId: T.patientId
  }

// 月度統計
define "Monthly Statistics":
  distinct (
    "Monthly Trend Analysis" T return T.month
  ) Month
  let monthTransplants: Count("Monthly Trend Analysis" T where T.month = Month)
  return {
    month: Month,
    transplantCount: monthTransplants
  }
  sort by month

// 移植病人詳細名單
define "Transplant Patient Details":
  "Patients With Successful Kidney Transplant" T
  return {
    patientId: T.patientId,
    transplantDate: T.transplantDate,
    age: T.age,
    gender: T.gender,
    daysSinceTransplant: days between T.transplantDate and Today(),
    noDialysisAfterTransplant: T.noDialysisAfterTransplant,
    hasFunctioningTransplant: T.hasFunctioningTransplant
  }
  sort by transplantDate desc

// 透析時間分析（移植前透析持續時間）
define "Dialysis Duration Before Transplant":
  "Patients With Successful Kidney Transplant" T
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = T.patientId),
      dialysisProcedures: [Procedure] P
                          where P.subject.reference.value = T.patientId
                          and P.performed as FHIR.dateTime < T.transplantDate
                          and P.status.value = 'completed'
                          and exists (
                            P.code.coding C
                            where C in "Hemodialysis Procedure Codes"
                          )
                          sort by P.performed as FHIR.dateTime,
      firstDialysis: First(dialysisProcedures),
      lastDialysisBeforeTransplant: Last(dialysisProcedures),
      dialysisDuration: if firstDialysis is not null and lastDialysisBeforeTransplant is not null
                        then months between (firstDialysis.performed as FHIR.dateTime) and T.transplantDate
                        else null
  where dialysisDuration is not null
  return {
    patientId: T.patientId,
    dialysisDurationMonths: dialysisDuration,
    firstDialysisDate: firstDialysis.performed as FHIR.dateTime,
    lastDialysisBeforeTransplant: lastDialysisBeforeTransplant.performed as FHIR.dateTime,
    transplantDate: T.transplantDate
  }

// 透析時間統計
define "Dialysis Duration Statistics":
  let avgDuration: Avg("Dialysis Duration Before Transplant" D return D.dialysisDurationMonths),
      minDuration: Min("Dialysis Duration Before Transplant" D return D.dialysisDurationMonths),
      maxDuration: Max("Dialysis Duration Before Transplant" D return D.dialysisDurationMonths)
  return {
    averageDurationMonths: Round(avgDuration, 1),
    minimumDurationMonths: minDuration,
    maximumDurationMonths: maxDuration,
    patientCount: Count("Dialysis Duration Before Transplant")
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '脫離率 (腎移植率)',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '因接受腎臟移植手術，而不須再透析的人數總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的血液透析病人數',
    transplantRate: "Kidney Transplant Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    monthlyTrend: "Monthly Statistics",
    transplantPatientDetails: "Transplant Patient Details",
    dialysisDurationStatistics: "Dialysis Duration Statistics",
    unit: '%',
    formula: '(分子/分母) x 100%',
    note: '較高的腎移植率表示更多病人成功脫離透析，為正向品質指標'
  }
