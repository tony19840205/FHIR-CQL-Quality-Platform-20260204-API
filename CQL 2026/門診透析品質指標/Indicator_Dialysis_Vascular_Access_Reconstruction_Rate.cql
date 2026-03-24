/**
 * 指標名稱: 瘻管重建率(每千人月)
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 1000
 * 
 * 分子: 分母病人需重新接受動靜脈瘻管或人工血管手術之總次數
 * 分母: 透析醫療院所照護的血液透析病人月數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Dialysis_Vascular_Access_Reconstruction_Rate version '1.0.0'

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

// 動靜脈瘻管建立/重建手術代碼
define "AVF Creation and Reconstruction Procedure Codes":
  { Code { code: '288649008', system: 'http://snomed.info/sct', display: 'Creation of arteriovenous fistula' },
    Code { code: '34163007', system: 'http://snomed.info/sct', display: 'Arteriovenous anastomosis' },
    Code { code: '426340003', system: 'http://snomed.info/sct', display: 'Revision of arteriovenous fistula' },
    Code { code: '119321002', system: 'http://snomed.info/sct', display: 'Reconstruction of arteriovenous fistula' },
    Code { code: '609154003', system: 'http://snomed.info/sct', display: 'Repair of arteriovenous fistula' }
  }

// 人工血管置放/重建手術代碼
define "Graft Placement and Reconstruction Procedure Codes":
  { Code { code: '426340003', system: 'http://snomed.info/sct', display: 'Creation of arteriovenous graft' },
    Code { code: '21366005', system: 'http://snomed.info/sct', display: 'Arteriovenous shunt procedure' },
    Code { code: '232481008', system: 'http://snomed.info/sct', display: 'Revision of arteriovenous graft' },
    Code { code: '609155002', system: 'http://snomed.info/sct', display: 'Repair of arteriovenous graft' }
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

// 計算病人在觀察期間的月數
define function CalculatePatientMonths(patient Patient, encounters List<Encounter>):
  let sortedEncounters: encounters E sort by E.period.start,
      firstEncounter: First(sortedEncounters),
      lastEncounter: Last(sortedEncounters),
      startDate: Coalesce(firstEncounter.period.start, MeasurementPeriodStart),
      endDate: Coalesce(lastEncounter.period.end, MeasurementPeriodEnd),
      monthsDiff: months between startDate and endDate
  return if monthsDiff >= 0 then (monthsDiff + 1) else 0

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

// 觀察期間內的動靜脈瘻管建立/重建手術
define "AVF Reconstruction Procedures During Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "AVF Creation and Reconstruction Procedure Codes"
  )

// 觀察期間內的人工血管置放/重建手術
define "Graft Reconstruction Procedures During Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "Graft Placement and Reconstruction Procedure Codes"
  )

// 所有血管通路重建手術
define "All Vascular Access Reconstruction Procedures":
  "AVF Reconstruction Procedures During Period"
  union "Graft Reconstruction Procedures During Period"

// 血液透析病人的血管通路重建手術
define "Vascular Access Reconstruction For Hemodialysis Patients":
  "All Vascular Access Reconstruction Procedures" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.subject.reference.value)
  where patient in "Hemodialysis Patients"
  return {
    procedureId: 'Procedure/' + P.id,
    patientId: 'Patient/' + patient.id,
    procedureType: if exists (P.code.coding C where C in "AVF Creation and Reconstruction Procedure Codes")
                   then 'AVF重建'
                   else 'Graft重建',
    performedDateTime: P.performed as FHIR.dateTime,
    status: P.status.value
  }

// 每位病人的月數計算
define "Patient Months Calculation":
  "Hemodialysis Patients" P
  let patientEncounters: "Dialysis Encounters During Period" E
                         where GetPatientReference(E.subject) = 'Patient/' + P.id,
      months: CalculatePatientMonths(P, patientEncounters)
  return {
    patientId: 'Patient/' + P.id,
    months: months,
    encounterCount: Count(patientEncounters),
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分子: 血管通路重建手術總次數
define "Numerator Count":
  Count("Vascular Access Reconstruction For Hemodialysis Patients")

// 分母: 透析病人總月數
define "Denominator Total Patient Months":
  Sum("Patient Months Calculation" PM return PM.months)

// ========================================================================================
// 指標計算
// ========================================================================================

// 瘻管重建率(每千人月)
define "Vascular Access Reconstruction Rate Per 1000 Patient Months":
  if "Denominator Total Patient Months" > 0 
  then Round(("Numerator Count" / "Denominator Total Patient Months") * 1000.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依手術類型分層
define "Procedures By Type":
  "Vascular Access Reconstruction For Hemodialysis Patients" P
  return {
    procedureType: P.procedureType,
    procedureId: P.procedureId
  }

// 手術類型統計
define "Procedure Type Statistics":
  distinct (
    "Procedures By Type" P return P.procedureType
  ) PType
  let typeCount: Count("Procedures By Type" P where P.procedureType = PType)
  return {
    procedureType: PType,
    procedureCount: typeCount,
    percentage: if "Numerator Count" > 0
                then Round((typeCount / "Numerator Count") * 100.0, 2)
                else null,
    ratePerThousand: if "Denominator Total Patient Months" > 0
                     then Round((typeCount / "Denominator Total Patient Months") * 1000.0, 2)
                     else null
  }

// 依年齡層分析
define "Patients With Procedures By Age":
  "Vascular Access Reconstruction For Hemodialysis Patients" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.patientId),
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
    patientId: P.patientId,
    procedureId: P.procedureId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "Patients With Procedures By Age" P return P.ageGroup
  ) AgeGroup
  let groupProcedures: Count("Patients With Procedures By Age" P where P.ageGroup = AgeGroup),
      groupPatients: Count(
        distinct (
          "Patients With Procedures By Age" P where P.ageGroup = AgeGroup return P.patientId
        )
      ),
      groupMonths: Sum(
        "Patient Months Calculation" PM
        let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = PM.patientId),
            age: GetPatientAge(patient),
            patientAgeGroup: if age < 18 then '<18歲'
                             else if age >= 18 and age < 40 then '18-39歲'
                             else if age >= 40 and age < 50 then '40-49歲'
                             else if age >= 50 and age < 60 then '50-59歲'
                             else if age >= 60 and age < 70 then '60-69歲'
                             else if age >= 70 and age < 80 then '70-79歲'
                             else '≥80歲'
        where patientAgeGroup = AgeGroup
        return PM.months
      )
  return {
    ageGroup: AgeGroup,
    procedureCount: groupProcedures,
    patientCount: groupPatients,
    totalMonths: groupMonths,
    ratePerThousand: if groupMonths > 0
                     then Round((groupProcedures / groupMonths) * 1000.0, 2)
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
define "Patients With Procedures By Gender":
  "Vascular Access Reconstruction For Hemodialysis Patients" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.patientId),
      gender: if GetPatientGender(patient) = 'male' then '男性'
              else if GetPatientGender(patient) = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    patientId: P.patientId,
    procedureId: P.procedureId
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "Patients With Procedures By Gender" P return P.gender
  ) Gender
  let genderProcedures: Count("Patients With Procedures By Gender" P where P.gender = Gender),
      genderPatients: Count(
        distinct (
          "Patients With Procedures By Gender" P where P.gender = Gender return P.patientId
        )
      ),
      genderMonths: Sum(
        "Patient Months Calculation" PM
        let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = PM.patientId),
            patientGender: if GetPatientGender(patient) = 'male' then '男性'
                           else if GetPatientGender(patient) = 'female' then '女性'
                           else '其他'
        where patientGender = Gender
        return PM.months
      )
  return {
    gender: Gender,
    procedureCount: genderProcedures,
    patientCount: genderPatients,
    totalMonths: genderMonths,
    ratePerThousand: if genderMonths > 0
                     then Round((genderProcedures / genderMonths) * 1000.0, 2)
                     else null
  }

// 依醫療機構分析
define "Procedures By Organization":
  "Vascular Access Reconstruction For Hemodialysis Patients" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.patientId),
      encounters: "Dialysis Encounters During Period" E
                  where GetPatientReference(E.subject) = P.patientId,
      mostRecentEncounter: Last(encounters E sort by E.period.start),
      organization: if mostRecentEncounter is not null
                    then GetEncounterOrganization(mostRecentEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    procedureId: P.procedureId,
    patientId: P.patientId
  }

// 醫療機構統計
define "Organization Statistics":
  distinct (
    "Procedures By Organization" P return P.organizationId
  ) OrgId
  let orgProcedures: Count("Procedures By Organization" P where P.organizationId = OrgId),
      orgPatients: Count(
        distinct (
          "Procedures By Organization" P where P.organizationId = OrgId return P.patientId
        )
      ),
      orgMonths: Sum(
        "Patient Months Calculation" PM
        let encounters: "Dialysis Encounters During Period" E
                        where GetPatientReference(E.subject) = PM.patientId,
            patientOrg: Last(encounters E sort by E.period.start).serviceProvider.reference.value
        where patientOrg = OrgId
        return PM.months
      )
  return {
    organizationId: OrgId,
    procedureCount: orgProcedures,
    patientCount: orgPatients,
    totalMonths: orgMonths,
    ratePerThousand: if orgMonths > 0
                     then Round((orgProcedures / orgMonths) * 1000.0, 2)
                     else null
  }
  sort by ratePerThousand desc

// 月度趨勢分析
define "Monthly Trend Analysis":
  "Vascular Access Reconstruction For Hemodialysis Patients" P
  let month: ToString(year from P.performedDateTime) + '-' + 
             ToString(month from P.performedDateTime)
  return {
    month: month,
    procedureId: P.procedureId
  }

// 月度統計
define "Monthly Statistics":
  distinct (
    "Monthly Trend Analysis" T return T.month
  ) Month
  let monthProcedures: Count("Monthly Trend Analysis" T where T.month = Month)
  return {
    month: Month,
    procedureCount: monthProcedures
  }
  sort by month

// 高重建率病人（觀察期間內≥2次重建手術）
define "High Reconstruction Rate Patients":
  "Hemodialysis Patients" P
  let patientProcedures: "Vascular Access Reconstruction For Hemodialysis Patients" VP
                         where VP.patientId = 'Patient/' + P.id,
      procedureCount: Count(patientProcedures)
  where procedureCount >= 2
  return {
    patientId: 'Patient/' + P.id,
    procedureCount: procedureCount,
    age: GetPatientAge(P),
    gender: GetPatientGender(P),
    procedures: patientProcedures
  }
  sort by procedureCount desc

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '瘻管重建率(每千人月)',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '分母病人需重新接受動靜脈瘻管或人工血管手術之總次數',
    denominator: "Denominator Total Patient Months",
    denominatorDefinition: '透析醫療院所照護的血液透析病人月數',
    reconstructionRatePerThousand: "Vascular Access Reconstruction Rate Per 1000 Patient Months",
    totalPatients: Count("Hemodialysis Patients"),
    procedureTypeDistribution: "Procedure Type Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    organizationAnalysis: "Organization Statistics",
    monthlyTrend: "Monthly Statistics",
    highReconstructionRatePatients: "High Reconstruction Rate Patients",
    highRatePatientCount: Count("High Reconstruction Rate Patients"),
    unit: '每千人月',
    formula: '(分子/分母) x 1000',
    note: '較低的重建率表示血管通路維護品質較佳'
  }
