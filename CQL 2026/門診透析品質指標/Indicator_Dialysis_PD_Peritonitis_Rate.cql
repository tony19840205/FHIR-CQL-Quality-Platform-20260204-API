/**
 * 指標名稱: 腹膜炎發生率 - 腹膜透析
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100
 * 
 * 分子: 分母病人於統計期間門診或住診有申報腹膜炎之次數
 * 分母: 符合慢性透析病人定義，且於統計期間於門診申報腹膜透析任一醫令之人月數
 * 
 * 分子條件: 腹膜炎定義為主、次前5個診斷碼全碼為K650、K651、K652、K653、K654、K658、K659、K67、K6811、K6819、K689，
 *          且該案件有申報針劑抗生素藥品其給藥日數大於等於7天者，且案件在院日(若為門診取就醫日)落在統計期間
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 * 
 * 說明: 此為負向品質指標，發生率越低代表腹膜透析照護品質越好
 */

library Indicator_Dialysis_PD_Peritonitis_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'

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

// 腹膜炎診斷代碼（ICD-10-CM）
define "Peritonitis Diagnosis Codes":
  { Code { code: 'K650', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Generalized (acute) peritonitis' },
    Code { code: 'K65.0', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Generalized (acute) peritonitis' },
    Code { code: 'K651', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Peritoneal abscess' },
    Code { code: 'K65.1', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Peritoneal abscess' },
    Code { code: 'K652', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Spontaneous bacterial peritonitis' },
    Code { code: 'K65.2', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Spontaneous bacterial peritonitis' },
    Code { code: 'K653', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Choleperitonitis' },
    Code { code: 'K65.3', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Choleperitonitis' },
    Code { code: 'K654', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Sclerosing mesenteritis' },
    Code { code: 'K65.4', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Sclerosing mesenteritis' },
    Code { code: 'K658', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Other peritonitis' },
    Code { code: 'K65.8', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Other peritonitis' },
    Code { code: 'K659', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Peritonitis, unspecified' },
    Code { code: 'K65.9', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Peritonitis, unspecified' },
    Code { code: 'K67', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Disorders of peritoneum in infectious diseases classified elsewhere' },
    Code { code: 'K6811', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Postprocedural peritoneal adhesions' },
    Code { code: 'K68.11', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Postprocedural peritoneal adhesions' },
    Code { code: 'K6819', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Other peritoneal adhesions' },
    Code { code: 'K68.19', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Other peritoneal adhesions' },
    Code { code: 'K689', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Other disorders of peritoneum' },
    Code { code: 'K68.9', system: 'http://hl7.org/fhir/sid/icd-10-cm', display: 'Other disorders of peritoneum' }
  }

// 針劑抗生素藥品代碼（ATC分類 J01 = 全身性抗菌藥物）
define "Parenteral Antibiotics Codes":
  { Code { code: 'J01', system: 'http://www.whocc.no/atc', display: 'Antibacterials for systemic use' }
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

// 檢查診斷碼是否為腹膜炎（前5個診斷位置）
define function HasPeritonitisInFirst5Diagnoses(encounter Encounter):
  exists (
    encounter.diagnosis D
    where D.rank.value <= 5
    and exists (
      [Condition] C
      where 'Condition/' + C.id = D.condition.reference.value
      and exists (
        C.code.coding CC
        where CC in "Peritonitis Diagnosis Codes"
      )
    )
  )

// 計算給藥日數
define function GetMedicationDuration(medRequest MedicationRequest):
  case
    when medRequest.dosageInstruction[0].timing.repeat.bounds is FHIR.Duration then
      (medRequest.dosageInstruction[0].timing.repeat.bounds as FHIR.Duration).value.value
    when medRequest.dosageInstruction[0].timing.repeat.bounds is FHIR.Period then
      days between 
        (medRequest.dosageInstruction[0].timing.repeat.bounds as FHIR.Period).start 
        and (medRequest.dosageInstruction[0].timing.repeat.bounds as FHIR.Period).end
    else null
  end

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

// 每位病人的人月數計算（從第一次到最後一次透析的月數）
define "Patient Months Calculation":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      patientEncounters: "Dialysis Encounters During Period" E
                         where GetPatientReference(E.subject) = patientId
                         sort by period.start,
      firstEncounter: First(patientEncounters),
      lastEncounter: Last(patientEncounters),
      monthsBetween: if firstEncounter is not null and lastEncounter is not null
                     then months between (firstEncounter.period.start) and (lastEncounter.period.start) + 1
                     else 1
  return {
    patientId: patientId,
    patientMonths: monthsBetween,
    firstEncounterDate: firstEncounter.period.start,
    lastEncounterDate: lastEncounter.period.start,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 人月數總和
define "Denominator Patient Months":
  Sum("Patient Months Calculation" P return P.patientMonths)

// 觀察期間內所有門診和住院（用於偵測腹膜炎）
define "All Encounters During Period":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'

// 腹膜炎事件（有腹膜炎診斷且有針劑抗生素≥7天）
define "Peritonitis Episodes":
  "All Encounters During Period" E
  let patientId: GetPatientReference(E.subject),
      hasPeritonitisInFirst5: HasPeritonitisInFirst5Diagnoses(E),
      antibioticMedications: [MedicationRequest] M
                             where M.subject.reference.value = patientId
                             and M.encounter.reference.value = 'Encounter/' + E.id
                             and M.status.value in { 'active', 'completed' }
                             and exists (
                               M.medication.coding MC
                               where MC.code.value starts with 'J01'
                             ),
      hasAntibiotics7Days: exists (
        antibioticMedications A
        where GetMedicationDuration(A) >= 7
      ),
      isPDPatient: exists (
        "Peritoneal Dialysis Patients" P
        where 'Patient/' + P.id = patientId
      )
  where isPDPatient
  and hasPeritonitisInFirst5
  and hasAntibiotics7Days
  return {
    encounterId: 'Encounter/' + E.id,
    patientId: patientId,
    encounterDate: Coalesce(
      E.period.start,
      E.period.end
    ),
    encounterType: E.class.code.value,
    antibioticDays: Max(antibioticMedications A return GetMedicationDuration(A))
  }

// 分子: 腹膜炎事件次數
define "Numerator Peritonitis Episodes":
  Count("Peritonitis Episodes")

// ========================================================================================
// 指標計算
// ========================================================================================

// 腹膜炎發生率（每100人月）
define "Peritonitis Rate Per 100 Patient Months":
  if "Denominator Patient Months" > 0 
  then Round(("Numerator Peritonitis Episodes" / "Denominator Patient Months") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "Peritonitis By Age Group":
  "Peritonitis Episodes" PE
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = PE.patientId),
      age: GetPatientAge(patient),
      ageGroup: if age < 18 then '<18歲'
                else if age >= 18 and age < 40 then '18-39歲'
                else if age >= 40 and age < 50 then '40-49歲'
                else if age >= 50 and age < 60 then '50-59歲'
                else if age >= 60 and age < 70 then '60-69歲'
                else if age >= 70 and age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    episodeId: PE.encounterId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Peritonitis By Age Group" P return P.ageGroup
  ) AgeGroup
  let groupEpisodes: Count("Peritonitis By Age Group" P where P.ageGroup = AgeGroup),
      groupPatientMonths: Sum(
        "Patient Months Calculation" PM
        let patientAgeGroup: if PM.age < 18 then '<18歲'
                             else if PM.age >= 18 and PM.age < 40 then '18-39歲'
                             else if PM.age >= 40 and PM.age < 50 then '40-49歲'
                             else if PM.age >= 50 and PM.age < 60 then '50-59歲'
                             else if PM.age >= 60 and PM.age < 70 then '60-69歲'
                             else if PM.age >= 70 and PM.age < 80 then '70-79歲'
                             else '≥80歲'
        where patientAgeGroup = AgeGroup
        return PM.patientMonths
      )
  return {
    ageGroup: AgeGroup,
    episodeCount: groupEpisodes,
    patientMonths: groupPatientMonths,
    ratePer100PatientMonths: if groupPatientMonths > 0
                             then Round((groupEpisodes / groupPatientMonths) * 100.0, 2)
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
define "Peritonitis By Gender":
  "Peritonitis Episodes" PE
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = PE.patientId),
      gender: if GetPatientGender(patient) = 'male' then '男性'
              else if GetPatientGender(patient) = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    episodeId: PE.encounterId
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Peritonitis By Gender" P return P.gender
  ) Gender
  let genderEpisodes: Count("Peritonitis By Gender" P where P.gender = Gender),
      genderPatientMonths: Sum(
        "Patient Months Calculation" PM
        let patientGender: if PM.gender = 'male' then '男性'
                           else if PM.gender = 'female' then '女性'
                           else '其他'
        where patientGender = Gender
        return PM.patientMonths
      )
  return {
    gender: Gender,
    episodeCount: genderEpisodes,
    patientMonths: genderPatientMonths,
    ratePer100PatientMonths: if genderPatientMonths > 0
                             then Round((genderEpisodes / genderPatientMonths) * 100.0, 2)
                             else null
  }

// 依醫療機構分析
define "Peritonitis By Organization":
  "Peritonitis Episodes" PE
  let encounter: singleton from ([Encounter] E where 'Encounter/' + E.id = PE.encounterId),
      organization: if encounter is not null
                    then GetEncounterOrganization(encounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    episodeId: PE.encounterId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Peritonitis By Organization" P return P.organizationId
  ) OrgId
  let orgEpisodes: Count("Peritonitis By Organization" P where P.organizationId = OrgId),
      orgPatientMonths: Sum(
        "Patient Months Calculation" PM
        let encounters: "Dialysis Encounters During Period" E
                        where GetPatientReference(E.subject) = PM.patientId,
            patientOrg: if Count(encounters) > 0
                        then GetEncounterOrganization(Last(encounters E sort by E.period.start))
                        else null
        where patientOrg = OrgId
        return PM.patientMonths
      )
  return {
    organizationId: OrgId,
    episodeCount: orgEpisodes,
    patientMonths: orgPatientMonths,
    ratePer100PatientMonths: if orgPatientMonths > 0
                             then Round((orgEpisodes / orgPatientMonths) * 100.0, 2)
                             else null
  }
  sort by ratePer100PatientMonths desc

// 依就醫類型分析（門診 vs 住院）
define "Peritonitis By Encounter Type":
  "Peritonitis Episodes" PE
  let encounterType: if PE.encounterType in { 'AMB', 'outpatient' } then '門診'
                     else if PE.encounterType in { 'IMP', 'ACUTE', 'inpatient' } then '住院'
                     else '其他'
  return {
    encounterType: encounterType,
    episodeId: PE.encounterId
  }

// 就醫類型統計
define "Encounter Type Statistics":
  distinct (
    "Peritonitis By Encounter Type" P return P.encounterType
  ) EncType
  let typeEpisodes: Count("Peritonitis By Encounter Type" P where P.encounterType = EncType)
  return {
    encounterType: EncType,
    episodeCount: typeEpisodes,
    percentage: if "Numerator Peritonitis Episodes" > 0
                then Round((typeEpisodes / "Numerator Peritonitis Episodes") * 100.0, 2)
                else null
  }

// 月份趨勢分析
define "Monthly Trend Analysis":
  let months: { 
    { month: '2026-01', start: @2026-01-01T00:00:00.0+08:00, end: @2026-01-31T23:59:59.0+08:00 },
    { month: '2026-02', start: @2026-02-01T00:00:00.0+08:00, end: @2026-02-28T23:59:59.0+08:00 },
    { month: '2026-03', start: @2026-03-01T00:00:00.0+08:00, end: @2026-03-31T23:59:59.0+08:00 }
  }
  return months M
  let monthEpisodes: Count(
        "Peritonitis Episodes" PE
        where PE.encounterDate >= M.start and PE.encounterDate <= M.end
      )
  return {
    month: M.month,
    episodeCount: monthEpisodes
  }

// 腹膜炎事件詳細資訊
define "Peritonitis Episode Details":
  "Peritonitis Episodes" PE
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = PE.patientId),
      age: GetPatientAge(patient),
      gender: GetPatientGender(patient)
  return {
    encounterId: PE.encounterId,
    patientId: PE.patientId,
    age: age,
    gender: gender,
    encounterDate: PE.encounterDate,
    encounterType: PE.encounterType,
    antibioticTreatmentDays: PE.antibioticDays
  }
  sort by encounterDate

// 復發性腹膜炎病人（期間內≥2次）
define "Recurrent Peritonitis Patients":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      patientEpisodes: "Peritonitis Episodes" PE where PE.patientId = patientId,
      episodeCount: Count(patientEpisodes)
  where episodeCount >= 2
  return {
    patientId: patientId,
    episodeCount: episodeCount,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    episodeDates: patientEpisodes PE return PE.encounterDate
  }
  sort by episodeCount desc

// 無腹膜炎病人統計
define "Patients Without Peritonitis":
  "Peritoneal Dialysis Patients" P
  let patientId: 'Patient/' + P.id,
      hasEpisode: exists (
        "Peritonitis Episodes" PE where PE.patientId = patientId
      )
  where not hasEpisode

// 無腹膜炎病人數
define "Patients Without Peritonitis Count":
  Count("Patients Without Peritonitis")

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '腹膜炎發生率 - 腹膜透析',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator Peritonitis Episodes",
    numeratorDefinition: '分母病人於統計期間門診或住診有申報腹膜炎之次數',
    denominator: "Denominator Patient Months",
    denominatorDefinition: '符合慢性透析病人定義，且於統計期間於門診申報腹膜透析任一醫令之人月數',
    peritonitisRate: "Peritonitis Rate Per 100 Patient Months",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    encounterTypeDistribution: "Encounter Type Statistics",
    monthlyTrend: "Monthly Trend Analysis",
    peritonitisEpisodeDetails: "Peritonitis Episode Details",
    recurrentPeritonitisPatients: "Recurrent Peritonitis Patients",
    patientsWithoutPeritonitisCount: "Patients Without Peritonitis Count",
    totalPatients: Count("Peritoneal Dialysis Patients"),
    unit: '每100人月',
    formula: '(分子/分母) x 100',
    peritonitisDefinition: '主、次前5個診斷碼全碼為K650、K651、K652、K653、K654、K658、K659、K67、K6811、K6819、K689，且有針劑抗生素治療≥7天',
    note: '此為負向品質指標，發生率越低代表腹膜透析照護品質越好。腹膜炎是腹膜透析最常見的併發症，可能導致技術失敗和轉換為血液透析。'
  }
