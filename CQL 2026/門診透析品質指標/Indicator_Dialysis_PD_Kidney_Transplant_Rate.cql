/**
 * 指標名稱: 脫離率 (腎移植率) - 腹膜透析
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 因接受腎臟移植手術，而不須再透析的人數總和
 * 分母: 透析醫療院所照護的腹膜透析病人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 */

library Indicator_Dialysis_PD_Kidney_Transplant_Rate version '1.0.0'

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
    Code { code: '238316008', system: 'http://snomed.info/sct', display: 'Continuous ambulatory peritoneal dialysis' },
    Code { code: '238317004', system: 'http://snomed.info/sct', display: 'Continuous cycling peritoneal dialysis' },
    Code { code: '238318009', system: 'http://snomed.info/sct', display: 'Automated peritoneal dialysis' }
  }

// 腎臟移植手術代碼
define "Kidney Transplant Procedure Codes":
  { Code { code: '70536003', system: 'http://snomed.info/sct', display: 'Transplant of kidney' },
    Code { code: '313030004', system: 'http://snomed.info/sct', display: 'Kidney transplant with donor nephrectomy' },
    Code { code: '175899003', system: 'http://snomed.info/sct', display: 'Autotransplantation of kidney' },
    Code { code: '52213001', system: 'http://snomed.info/sct', display: 'Homotransplantation of kidney' },
    Code { code: '6471000179103', system: 'http://snomed.info/sct', display: 'Transplantation of kidney from beating heart cadaver' }
  }

// 慢性腎臟病診斷代碼
define "Chronic Kidney Disease Codes":
  { Code { code: '585', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic kidney disease' },
    Code { code: 'N18', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Chronic kidney disease' },
    Code { code: 'N18.6', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'End stage renal disease' }
  }

// 腎移植狀態診斷代碼
define "Kidney Transplant Status Codes":
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

// 分母: 透析醫療院所照護的腹膜透析病人數
define "Denominator Count":
  Count("Peritoneal Dialysis Patients")

// 所有腎臟移植手術（不限時間）
define "All Kidney Transplant Procedures":
  [Procedure] P
  where P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "Kidney Transplant Procedure Codes"
  )

// 移植後的透析處置（檢查移植是否成功）
define "Dialysis After Transplant":
  "All Kidney Transplant Procedures" T
  return {
    transplantId: 'Procedure/' + T.id,
    patientId: T.subject.reference.value,
    transplantDate: T.performed as FHIR.dateTime,
    dialysisAfter: exists (
      [Procedure] P
      where P.subject.reference.value = T.subject.reference.value
      and P.status.value = 'completed'
      and (P.performed as FHIR.dateTime) > (T.performed as FHIR.dateTime)
      and exists (
        P.code.coding C
        where C in "Peritoneal Dialysis Procedure Codes"
      )
    )
  }

// 有功能的腎移植診斷
define "Functioning Transplant Diagnosis":
  [Condition] C
  where C.clinicalStatus.coding[0].code.value = 'active'
  and exists (
    C.code.coding CC
    where CC in "Kidney Transplant Status Codes"
  )

// 成功移植病人（有移植手術且移植後不再需要透析）
define "Patients With Successful Kidney Transplant":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      transplants: "All Kidney Transplant Procedures" T
                   where T.subject.reference.value = patientId,
      latestTransplant: Last(transplants T sort by T.performed as FHIR.dateTime),
      dialysisAfterTransplant: if latestTransplant is not null
                               then exists (
                                 "Dialysis After Transplant" D
                                 where D.transplantId = 'Procedure/' + latestTransplant.id
                                 and D.dialysisAfter = true
                               )
                               else null,
      hasFunctioningTransplant: exists (
        "Functioning Transplant Diagnosis" FT
        where FT.subject.reference.value = patientId
      )
  where latestTransplant is not null
  and (dialysisAfterTransplant = false or hasFunctioningTransplant = true)
  return {
    patientId: patientId,
    transplantDate: latestTransplant.performed as FHIR.dateTime,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    hasFunctioningTransplant: hasFunctioningTransplant
  }

// 分子: 因接受腎臟移植手術，而不須再透析的人數總和
define "Numerator Count":
  Count("Patients With Successful Kidney Transplant")

// ========================================================================================
// 指標計算
// ========================================================================================

// 脫離率（腎移植率）
define "Kidney Transplant Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Transplant By Age Group":
  "Patients With Successful Kidney Transplant" T
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
    "Transplant By Age Group" T return T.ageGroup
  ) AgeGroup
  let groupTransplants: Count("Transplant By Age Group" T where T.ageGroup = AgeGroup),
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
    transplantCount: groupTransplants,
    totalPatients: groupTotal,
    transplantRate: if groupTotal > 0
                    then Round((groupTransplants / groupTotal) * 100.0, 2)
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
define "Transplant By Gender":
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
    "Transplant By Gender" T return T.gender
  ) Gender
  let genderTransplants: Count("Transplant By Gender" T where T.gender = Gender),
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
    transplantCount: genderTransplants,
    totalPatients: genderTotal,
    transplantRate: if genderTotal > 0
                    then Round((genderTransplants / genderTotal) * 100.0, 2)
                    else null
  }

// 依醫療機構分析
define "Transplant By Organization":
  "Patients With Successful Kidney Transplant" T
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
    "Transplant By Organization" T return T.organizationId
  ) OrgId
  let orgTransplants: Count("Transplant By Organization" T where T.organizationId = OrgId),
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
    transplantCount: orgTransplants,
    totalPatients: orgTotal,
    transplantRate: if orgTotal > 0
                    then Round((orgTransplants / orgTotal) * 100.0, 2)
                    else null
  }
  sort by transplantRate desc

// 月份趨勢分析
define "Monthly Trend Analysis":
  let months: { 
    { month: '2026-01', start: @2026-01-01T00:00:00.0+08:00, end: @2026-01-31T23:59:59.0+08:00 },
    { month: '2026-02', start: @2026-02-01T00:00:00.0+08:00, end: @2026-02-28T23:59:59.0+08:00 },
    { month: '2026-03', start: @2026-03-01T00:00:00.0+08:00, end: @2026-03-31T23:59:59.0+08:00 }
  }
  return months M
  let monthTransplants: Count(
        "Patients With Successful Kidney Transplant" T
        where T.transplantDate >= M.start and T.transplantDate <= M.end
      )
  return {
    month: M.month,
    transplantCount: monthTransplants
  }

// 移植病人詳細資訊
define "Transplant Patient Details":
  "Patients With Successful Kidney Transplant" T
  let dialysisProcedures: "Peritoneal Dialysis Procedures During Period" P
                          where P.subject.reference.value = T.patientId
                          sort by P.performed as FHIR.dateTime,
      firstDialysis: First(dialysisProcedures),
      dialysisDuration: if firstDialysis is not null and T.transplantDate is not null
                        then months between (firstDialysis.performed as FHIR.dateTime) and T.transplantDate
                        else null
  return {
    patientId: T.patientId,
    age: T.age,
    gender: T.gender,
    transplantDate: T.transplantDate,
    dialysisDurationMonths: dialysisDuration,
    hasFunctioningTransplant: T.hasFunctioningTransplant
  }
  sort by transplantDate desc

// 透析至移植時間統計
define "Dialysis Duration Before Transplant Statistics":
  let durations: "Transplant Patient Details" T
                 where T.dialysisDurationMonths is not null
                 return T.dialysisDurationMonths,
      avgDuration: if Count(durations) > 0 then Round(Avg(durations), 1) else null,
      minDuration: if Count(durations) > 0 then Min(durations) else null,
      maxDuration: if Count(durations) > 0 then Max(durations) else null
  return {
    averageMonths: avgDuration,
    minimumMonths: minDuration,
    maximumMonths: maxDuration,
    patientCount: Count(durations)
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '脫離率 (腎移植率) - 腹膜透析',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Count",
    numeratorDefinition: '因接受腎臟移植手術，而不須再透析的人數總和',
    denominator: "Denominator Count",
    denominatorDefinition: '透析醫療院所照護的腹膜透析病人數',
    transplantRate: "Kidney Transplant Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    monthlyTrend: "Monthly Trend Analysis",
    transplantPatientDetails: "Transplant Patient Details",
    dialysisDurationStatistics: "Dialysis Duration Before Transplant Statistics",
    unit: '%',
    formula: '(分子/分母) x 100%',
    note: '脫離率（腎移植率）是正向品質指標，較高的移植率表示病人成功脫離透析，轉為腎臟移植治療，代表醫療照護品質良好。'
  }
