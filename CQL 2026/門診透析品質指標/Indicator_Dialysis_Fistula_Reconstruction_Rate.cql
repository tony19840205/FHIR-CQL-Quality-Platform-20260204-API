/**
 * 指標名稱: 血液透析瘻管重建率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每半年
 * 計算公式: (分子/分母) x 1000
 * 
 * 分子: 瘻管重建人次數
 * 分母: 血液透析人月數
 * 
 * 計算期間: 2026年上半年(民國115年上半年)
 * 
 * 備註:
 * - 透析人月數: 同一病患血液透析治療期間為3個月者，其透析人月數為3
 * - 瘻管重建人次數: 同一病患重建2次，則重建人次數為2
 * 
 * 說明: 此為負向品質指標，重建率越低代表血管通路照護品質越好
 */

library Indicator_Dialysis_Fistula_Reconstruction_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-06-30T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 血液透析處置代碼
define "Hemodialysis Procedure Codes":
  { Code { code: '108241001', system: 'http://snomed.info/sct', display: 'Hemodialysis procedure' },
    Code { code: '302497006', system: 'http://snomed.info/sct', display: 'Hemodialysis' },
    Code { code: '427053002', system: 'http://snomed.info/sct', display: 'Extracorporeal hemodialysis' }
  }

// 動靜脈瘻管重建處置代碼
define "Fistula Reconstruction Procedure Codes":
  { Code { code: '180277001', system: 'http://snomed.info/sct', display: 'Repair of arteriovenous fistula' },
    Code { code: '426340003', system: 'http://snomed.info/sct', display: 'Revision of arteriovenous fistula' },
    Code { code: '49640006', system: 'http://snomed.info/sct', display: 'Revision of vascular dialysis access' },
    Code { code: '288468006', system: 'http://snomed.info/sct', display: 'Revision of arteriovenous shunt' },
    Code { code: '34163007', system: 'http://snomed.info/sct', display: 'Reconstruction of arteriovenous fistula' },
    Code { code: '431523003', system: 'http://snomed.info/sct', display: 'Removal of arteriovenous shunt with creation of new arteriovenous fistula' }
  }

// 動靜脈瘻管建立處置代碼（用於辨識重建 vs 初次建立）
define "Fistula Creation Procedure Codes":
  { Code { code: '426340003', system: 'http://snomed.info/sct', display: 'Creation of arteriovenous fistula' },
    Code { code: '71148004', system: 'http://snomed.info/sct', display: 'Creation of arteriovenous fistula for hemodialysis' },
    Code { code: '34163007', system: 'http://snomed.info/sct', display: 'Creation of arteriovenous fistula by anastomosis' }
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

// 計算兩個日期之間的月數
define function MonthsBetween(startDate DateTime, endDate DateTime):
  months between startDate and endDate + 1

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間（每半年）
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

// ========================================================================================
// 分母計算: 血液透析人月數
// ========================================================================================

// 每位病人的透析人月數計算
define "Patient Months Calculation":
  "Hemodialysis Patients" P
  let patientId: 'Patient/' + P.id,
      patientEncounters: "Dialysis Encounters During Period" E
                         where GetPatientReference(E.subject) = patientId
                         sort by period.start,
      firstEncounter: First(patientEncounters),
      lastEncounter: Last(patientEncounters),
      firstDate: firstEncounter.period.start,
      lastDate: lastEncounter.period.end,
      patientMonths: if firstDate is not null and lastDate is not null
                     then MonthsBetween(firstDate, lastDate)
                     else 1
  return {
    patientId: patientId,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    firstDialysisDate: firstDate,
    lastDialysisDate: lastDate,
    patientMonths: patientMonths,
    encounterCount: Count(patientEncounters)
  }

// 分母: 血液透析人月數總和
define "Total Patient Months":
  Sum("Patient Months Calculation" PM return PM.patientMonths)

// ========================================================================================
// 分子計算: 瘻管重建人次數
// ========================================================================================

// 觀察期間內的瘻管重建處置（人次數，非人數）
define "Fistula Reconstruction Episodes":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "Fistula Reconstruction Procedure Codes"
  )

// 瘻管重建詳細資訊（每次重建為一筆）
define "Reconstruction Episode Details":
  "Fistula Reconstruction Episodes" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.subject.reference.value),
      performedDate: P.performed as FHIR.dateTime,
      encounter: singleton from ([Encounter] E where 'Encounter/' + E.id = P.encounter.reference.value)
  return {
    episodeId: P.id,
    patientId: 'Patient/' + patient.id,
    age: GetPatientAge(patient),
    gender: GetPatientGender(patient),
    reconstructionDate: performedDate,
    procedureCode: First(P.code.coding).code.value,
    procedureDisplay: First(P.code.coding).display.value,
    encounterType: if encounter is not null then encounter.class.code.value else null,
    organization: if encounter is not null then GetEncounterOrganization(encounter) else null
  }

// 分子: 瘻管重建人次數（總次數）
define "Total Reconstruction Episodes":
  Count("Reconstruction Episode Details")

// ========================================================================================
// 指標計算
// ========================================================================================

// 瘻管重建率（每1000人月）
define "Fistula Reconstruction Rate":
  if "Total Patient Months" > 0 
  then Round(("Total Reconstruction Episodes" / "Total Patient Months") * 1000.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析瘻管重建
define "Reconstruction By Age Group":
  "Reconstruction Episode Details" R
  let ageGroup: if R.age < 18 then '<18歲'
                else if R.age >= 18 and R.age < 40 then '18-39歲'
                else if R.age >= 40 and R.age < 50 then '40-49歲'
                else if R.age >= 50 and R.age < 60 then '50-59歲'
                else if R.age >= 60 and R.age < 70 then '60-69歲'
                else if R.age >= 70 and R.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    episodeId: R.episodeId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Reconstruction By Age Group" R return R.ageGroup
  ) AgeGroup
  let groupEpisodes: Count("Reconstruction By Age Group" R where R.ageGroup = AgeGroup),
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
    reconstructionEpisodes: groupEpisodes,
    patientMonths: groupPatientMonths,
    reconstructionRate: if groupPatientMonths > 0
                        then Round((groupEpisodes / groupPatientMonths) * 1000.0, 2)
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

// 依性別分析瘻管重建
define "Reconstruction By Gender":
  "Reconstruction Episode Details" R
  let gender: if R.gender = 'male' then '男性'
              else if R.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    episodeId: R.episodeId
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Reconstruction By Gender" R return R.gender
  ) Gender
  let genderEpisodes: Count("Reconstruction By Gender" R where R.gender = Gender),
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
    reconstructionEpisodes: genderEpisodes,
    patientMonths: genderPatientMonths,
    reconstructionRate: if genderPatientMonths > 0
                        then Round((genderEpisodes / genderPatientMonths) * 1000.0, 2)
                        else null
  }

// 依醫療機構分析瘻管重建
define "Reconstruction By Organization":
  "Reconstruction Episode Details" R
  where R.organization is not null
  return {
    organizationId: R.organization,
    episodeId: R.episodeId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Reconstruction By Organization" R return R.organizationId
  ) OrgId
  let orgEpisodes: Count("Reconstruction By Organization" R where R.organizationId = OrgId),
      orgPatientMonths: Sum(
        "Patient Months Calculation" PM
        let patientOrg: First(
          "Dialysis Encounters During Period" E
          where GetPatientReference(E.subject) = PM.patientId
          sort by period.start desc
          return GetEncounterOrganization(E)
        )
        where patientOrg = OrgId
        return PM.patientMonths
      )
  return {
    organizationId: OrgId,
    reconstructionEpisodes: orgEpisodes,
    patientMonths: orgPatientMonths,
    reconstructionRate: if orgPatientMonths > 0
                        then Round((orgEpisodes / orgPatientMonths) * 1000.0, 2)
                        else null
  }
  sort by reconstructionRate desc

// 依就醫類別分析（門診 vs 住院）
define "Reconstruction By Encounter Type":
  "Reconstruction Episode Details" R
  where R.encounterType is not null
  let encounterCategory: if R.encounterType = 'AMB' then '門診'
                         else if R.encounterType = 'IMP' then '住院'
                         else if R.encounterType = 'EMER' then '急診'
                         else '其他'
  return {
    encounterCategory: encounterCategory,
    episodeId: R.episodeId
  }

// 就醫類別統計
define "Encounter Type Statistics":
  distinct (
    "Reconstruction By Encounter Type" R return R.encounterCategory
  ) Category
  let categoryEpisodes: Count("Reconstruction By Encounter Type" R where R.encounterCategory = Category)
  return {
    encounterType: Category,
    reconstructionEpisodes: categoryEpisodes,
    percentage: if "Total Reconstruction Episodes" > 0
                then Round((categoryEpisodes / "Total Reconstruction Episodes") * 100.0, 2)
                else null
  }

// 重建次數分析（同一病人的重建次數）
define "Reconstruction Frequency By Patient":
  "Reconstruction Episode Details" R
  return {
    patientId: R.patientId
  }

// 病人重建次數統計
define "Patient Reconstruction Frequency":
  distinct (
    "Reconstruction Frequency By Patient" R return R.patientId
  ) PatId
  let reconstructionCount: Count("Reconstruction Frequency By Patient" R where R.patientId = PatId),
      patientInfo: singleton from ("Patient Months Calculation" PM where PM.patientId = PatId),
      frequencyCategory: if reconstructionCount = 1 then '1次'
                         else if reconstructionCount = 2 then '2次'
                         else if reconstructionCount = 3 then '3次'
                         else '≥4次'
  return {
    patientId: PatId,
    reconstructionCount: reconstructionCount,
    frequencyCategory: frequencyCategory,
    age: if patientInfo is not null then patientInfo.age else null,
    gender: if patientInfo is not null then patientInfo.gender else null
  }

// 重建次數分布統計
define "Reconstruction Frequency Distribution":
  distinct (
    "Patient Reconstruction Frequency" P return P.frequencyCategory
  ) FreqCat
  let categoryCount: Count("Patient Reconstruction Frequency" P where P.frequencyCategory = FreqCat),
      categoryEpisodes: Sum("Patient Reconstruction Frequency" P where P.frequencyCategory = FreqCat return P.reconstructionCount)
  return {
    frequencyCategory: FreqCat,
    patientCount: categoryCount,
    totalEpisodes: categoryEpisodes,
    patientPercentage: if Count("Patient Reconstruction Frequency") > 0
                       then Round((categoryCount / Count("Patient Reconstruction Frequency")) * 100.0, 2)
                       else null
  }
  sort by 
    case when frequencyCategory = '1次' then 1
         when frequencyCategory = '2次' then 2
         when frequencyCategory = '3次' then 3
         else 4
    end

// 多次重建病人詳情（≥2次）
define "Multiple Reconstruction Patients":
  "Patient Reconstruction Frequency" P
  where P.reconstructionCount >= 2
  let patientEpisodes: "Reconstruction Episode Details" R
                       where R.patientId = P.patientId
                       sort by reconstructionDate
  return {
    patientId: P.patientId,
    age: P.age,
    gender: P.gender,
    reconstructionCount: P.reconstructionCount,
    reconstructionDates: patientEpisodes R return ToString(R.reconstructionDate)
  }
  sort by reconstructionCount desc

// 月份趨勢分析
define "Monthly Trend Analysis":
  "Reconstruction Episode Details" R
  let reconstructionMonth: ToString(year from R.reconstructionDate) + '-' + 
                           ToString(month from R.reconstructionDate)
  return {
    month: reconstructionMonth,
    episodeId: R.episodeId
  }

// 月份統計
define "Monthly Statistics":
  distinct (
    "Monthly Trend Analysis" M return M.month
  ) Month
  let monthEpisodes: Count("Monthly Trend Analysis" M where M.month = Month)
  return {
    month: Month,
    reconstructionEpisodes: monthEpisodes
  }
  sort by month

// 無重建病人
define "Patients Without Reconstruction":
  "Patient Months Calculation" PM
  let hasReconstruction: exists (
    "Reconstruction Episode Details" R
    where R.patientId = PM.patientId
  )
  where not hasReconstruction
  return {
    patientId: PM.patientId,
    age: PM.age,
    gender: PM.gender,
    patientMonths: PM.patientMonths
  }

// 無重建病人統計
define "No Reconstruction Statistics":
  let totalNoReconstruction: Count("Patients Without Reconstruction"),
      totalNoReconstructionMonths: Sum("Patients Without Reconstruction" P return P.patientMonths)
  return {
    patientCount: totalNoReconstruction,
    patientMonths: totalNoReconstructionMonths,
    percentage: if Count("Patient Months Calculation") > 0
                then Round((totalNoReconstruction / Count("Patient Months Calculation")) * 100.0, 2)
                else null,
    note: '這些病人在觀察期間未接受瘻管重建，表示血管通路功能良好'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '血液透析瘻管重建率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每半年',
    numerator: "Total Reconstruction Episodes",
    numeratorDefinition: '瘻管重建人次數（同一病患重建2次，則重建人次數為2）',
    denominator: "Total Patient Months",
    denominatorDefinition: '血液透析人月數（同一病患血液透析治療期間為3個月者，其透析人月數為3）',
    fistula_reconstruction_rate: "Fistula Reconstruction Rate",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    encounterTypeDistribution: "Encounter Type Statistics",
    reconstructionFrequencyDistribution: "Reconstruction Frequency Distribution",
    multipleReconstructionPatients: "Multiple Reconstruction Patients",
    monthlyTrend: "Monthly Statistics",
    reconstructionEpisodeDetails: "Reconstruction Episode Details",
    noReconstructionStatistics: "No Reconstruction Statistics",
    patientMonthsDetails: "Patient Months Calculation",
    unit: 'per 1000 patient-months',
    formula: '(分子/分母) x 1000',
    note: '此為負向品質指標，重建率越低代表血管通路照護品質越好。瘻管重建包含修復、重建等處置。適當的血管通路照護可延長瘻管使用壽命，減少重建需求。'
  }
