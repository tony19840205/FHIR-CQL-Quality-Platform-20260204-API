/**
 * 指標名稱: 各院所新增透析病人之腹膜透析人數及占率
 * 指標類別: 門診透析品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 追蹤期間首次接受植管且於當季開始換液之長期慢性腹膜透析新病患人數
 *       (需透析超過1個月以上之慢性透析新病患才納入)
 * 分母: 追蹤期間當季第一次接受透析(血液透析或腹膜透析)治療且透析超過1個月以上之長期慢性透析新病患人數
 * 
 * 計算期間: 2026年第一季(民國115年第一季)
 * 
 * 說明: 此指標反映各醫療機構推廣腹膜透析的成效，較高的占率表示機構積極推動腹膜透析選項
 */

library Indicator_Dialysis_New_PD_Patient_Rate version '1.0.0'

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

// 血液透析處置代碼
define "Hemodialysis Procedure Codes":
  { Code { code: '108241001', system: 'http://snomed.info/sct', display: 'Hemodialysis procedure' },
    Code { code: '302497006', system: 'http://snomed.info/sct', display: 'Hemodialysis' },
    Code { code: '427053002', system: 'http://snomed.info/sct', display: 'Extracorporeal hemodialysis' }
  }

// 腹膜透析導管植入手術代碼
define "PD Catheter Insertion Codes":
  { Code { code: '233575001', system: 'http://snomed.info/sct', display: 'Insertion of catheter into peritoneal cavity' },
    Code { code: '67194008', system: 'http://snomed.info/sct', display: 'Insertion of peritoneal dialysis catheter' },
    Code { code: '426340003', system: 'http://snomed.info/sct', display: 'Placement of peritoneal dialysis catheter' }
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

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間（每季）
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 一個月後的期間結束時間（用於驗證透析持續超過1個月）
define "One Month After Period End":
  MeasurementPeriodEnd + 1 month

// 所有透析處置（血液透析和腹膜透析，不限時間）
define "All Dialysis Procedures":
  [Procedure] P
  where P.status.value = 'completed'
  and (
    exists (P.code.coding C where C in "Hemodialysis Procedure Codes")
    or exists (P.code.coding C where C in "Peritoneal Dialysis Procedure Codes")
  )

// 觀察期間內的透析處置
define "Dialysis Procedures During Period":
  "All Dialysis Procedures" P
  where P.performed during "Measurement Period"

// 新透析病人（觀察期間內第一次接受透析）
define "New Dialysis Patients During Period":
  distinct (
    "Dialysis Procedures During Period" P
    let patientId: P.subject.reference.value,
        firstDialysisProcedure: First(
          "All Dialysis Procedures" AllP
          where AllP.subject.reference.value = patientId
          sort by performed as FHIR.dateTime
        ),
        firstDialysisDate: firstDialysisProcedure.performed as FHIR.dateTime,
        isFirstDialysisDuringPeriod: firstDialysisDate during "Measurement Period"
    where isFirstDialysisDuringPeriod
    return singleton from ([Patient] Pt where 'Patient/' + Pt.id = patientId)
  )

// 驗證病人透析持續超過1個月
define "Patients With Chronic Dialysis Over 1 Month":
  "New Dialysis Patients During Period" P
  let patientId: 'Patient/' + P.id,
      firstDialysis: First(
        "All Dialysis Procedures" AllP
        where AllP.subject.reference.value = patientId
        sort by performed as FHIR.dateTime
      ),
      firstDialysisDate: firstDialysis.performed as FHIR.dateTime,
      dialysisProceduresAfterFirst: "All Dialysis Procedures" AllP
                                    where AllP.subject.reference.value = patientId
                                    and (AllP.performed as FHIR.dateTime) > firstDialysisDate
                                    and (AllP.performed as FHIR.dateTime) <= "One Month After Period End",
      lastDialysisWithin1Month: Last(
        dialysisProceduresAfterFirst
        sort by performed as FHIR.dateTime
      ),
      lastDialysisDate: if lastDialysisWithin1Month is not null
                        then lastDialysisWithin1Month.performed as FHIR.dateTime
                        else null,
      dialysisDurationDays: if lastDialysisDate is not null
                            then days between firstDialysisDate and lastDialysisDate
                            else 0,
      isChronicDialysis: dialysisDurationDays > 30
  where isChronicDialysis
  return {
    patientId: patientId,
    patient: P,
    firstDialysisDate: firstDialysisDate,
    dialysisDurationDays: dialysisDurationDays,
    age: GetPatientAge(P),
    gender: GetPatientGender(P)
  }

// 分母: 新增長期慢性透析病人數（透析超過1個月）
define "Denominator New Chronic Dialysis Patients":
  Count("Patients With Chronic Dialysis Over 1 Month")

// 腹膜透析導管植入手術（不限時間）
define "All PD Catheter Insertions":
  [Procedure] P
  where P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "PD Catheter Insertion Codes"
  )

// 觀察期間內的腹膜透析處置
define "PD Procedures During Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'
  and exists (
    P.code.coding C
    where C in "Peritoneal Dialysis Procedure Codes"
  )

// 新增腹膜透析病人（首次植管且當季開始換液）
define "New PD Patients With Catheter And Dialysis":
  "Patients With Chronic Dialysis Over 1 Month" CDP
  let patientId: CDP.patientId,
      catheterInsertions: "All PD Catheter Insertions" CI
                          where CI.subject.reference.value = patientId,
      firstCatheter: First(
        catheterInsertions
        sort by performed as FHIR.dateTime
      ),
      firstCatheterDate: if firstCatheter is not null
                         then firstCatheter.performed as FHIR.dateTime
                         else null,
      isCatheterDuringPeriod: firstCatheterDate during "Measurement Period",
      pdProceduresDuringPeriod: "PD Procedures During Period" PDP
                                where PDP.subject.reference.value = patientId,
      hasPDDuringPeriod: exists(pdProceduresDuringPeriod),
      firstDialysisType: First(
        "All Dialysis Procedures" AllP
        where AllP.subject.reference.value = patientId
        sort by performed as FHIR.dateTime
      ),
      isFirstDialysisPD: exists(
        firstDialysisType.code.coding C
        where C in "Peritoneal Dialysis Procedure Codes"
      )
  where isCatheterDuringPeriod
  and hasPDDuringPeriod
  return {
    patientId: patientId,
    age: CDP.age,
    gender: CDP.gender,
    firstDialysisDate: CDP.firstDialysisDate,
    catheterInsertionDate: firstCatheterDate,
    dialysisDurationDays: CDP.dialysisDurationDays
  }

// 分子: 新增腹膜透析病人數
define "Numerator New PD Patients":
  Count("New PD Patients With Catheter And Dialysis")

// ========================================================================================
// 指標計算
// ========================================================================================

// 腹膜透析占率
define "PD Patient Rate":
  if "Denominator New Chronic Dialysis Patients" > 0 
  then Round(("Numerator New PD Patients" / "Denominator New Chronic Dialysis Patients") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依年齡層分析
define "PD By Age Group":
  "New PD Patients With Catheter And Dialysis" P
  let ageGroup: if P.age < 18 then '<18歲'
                else if P.age >= 18 and P.age < 40 then '18-39歲'
                else if P.age >= 40 and P.age < 50 then '40-49歲'
                else if P.age >= 50 and P.age < 60 then '50-59歲'
                else if P.age >= 60 and P.age < 70 then '60-69歲'
                else if P.age >= 70 and P.age < 80 then '70-79歲'
                else '≥80歲'
  return {
    ageGroup: ageGroup,
    patientId: P.patientId
  }

// 年齡層統計
define "Age Group Statistics":
  distinct (
    "PD By Age Group" P return P.ageGroup
  ) AgeGroup
  let groupPDPatients: Count("PD By Age Group" P where P.ageGroup = AgeGroup),
      groupTotalPatients: Count(
        "Patients With Chronic Dialysis Over 1 Month" CDP
        let patientAgeGroup: if CDP.age < 18 then '<18歲'
                             else if CDP.age >= 18 and CDP.age < 40 then '18-39歲'
                             else if CDP.age >= 40 and CDP.age < 50 then '40-49歲'
                             else if CDP.age >= 50 and CDP.age < 60 then '50-59歲'
                             else if CDP.age >= 60 and CDP.age < 70 then '60-69歲'
                             else if CDP.age >= 70 and CDP.age < 80 then '70-79歲'
                             else '≥80歲'
        where patientAgeGroup = AgeGroup
        return CDP
      )
  return {
    ageGroup: AgeGroup,
    pdPatientCount: groupPDPatients,
    totalNewDialysisPatients: groupTotalPatients,
    pdRate: if groupTotalPatients > 0
            then Round((groupPDPatients / groupTotalPatients) * 100.0, 2)
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
define "PD By Gender":
  "New PD Patients With Catheter And Dialysis" P
  let gender: if P.gender = 'male' then '男性'
              else if P.gender = 'female' then '女性'
              else '其他'
  return {
    gender: gender,
    patientId: P.patientId
  }

// 性別統計
define "Gender Statistics":
  distinct (
    "PD By Gender" P return P.gender
  ) Gender
  let genderPDPatients: Count("PD By Gender" P where P.gender = Gender),
      genderTotalPatients: Count(
        "Patients With Chronic Dialysis Over 1 Month" CDP
        let patientGender: if CDP.gender = 'male' then '男性'
                           else if CDP.gender = 'female' then '女性'
                           else '其他'
        where patientGender = Gender
        return CDP
      )
  return {
    gender: Gender,
    pdPatientCount: genderPDPatients,
    totalNewDialysisPatients: genderTotalPatients,
    pdRate: if genderTotalPatients > 0
            then Round((genderPDPatients / genderTotalPatients) * 100.0, 2)
            else null
  }

// 依醫療機構分析（關鍵分析）
define "PD By Organization":
  "New PD Patients With Catheter And Dialysis" P
  let encounters: [Encounter] E
                  where GetPatientReference(E.subject) = P.patientId
                  and E.period during "Measurement Period"
                  and E.status.value = 'finished'
                  sort by E.period.start,
      firstEncounter: First(encounters),
      organization: if firstEncounter is not null
                    then GetEncounterOrganization(firstEncounter)
                    else null
  where organization is not null
  return {
    organizationId: organization,
    patientId: P.patientId
  }

// 醫療機構統計（核心輸出）
define "Organization Statistics":
  distinct (
    "PD By Organization" P return P.organizationId
  ) OrgId
  let orgPDPatients: Count("PD By Organization" P where P.organizationId = OrgId),
      orgTotalPatients: Count(
        "Patients With Chronic Dialysis Over 1 Month" CDP
        let encounters: [Encounter] E
                        where GetPatientReference(E.subject) = CDP.patientId
                        and E.period during "Measurement Period"
                        and E.status.value = 'finished'
                        sort by E.period.start,
            firstEncounter: First(encounters),
            patientOrg: if firstEncounter is not null
                        then GetEncounterOrganization(firstEncounter)
                        else null
        where patientOrg = OrgId
        return CDP
      )
  return {
    organizationId: OrgId,
    pdPatientCount: orgPDPatients,
    totalNewDialysisPatients: orgTotalPatients,
    pdRate: if orgTotalPatients > 0
            then Round((orgPDPatients / orgTotalPatients) * 100.0, 2)
            else null,
    hdPatientCount: orgTotalPatients - orgPDPatients
  }
  sort by pdRate desc

// 月份趨勢分析（依導管植入日期）
define "Monthly Trend Analysis":
  let months: { 
    { month: '2026-01', start: @2026-01-01T00:00:00.0+08:00, end: @2026-01-31T23:59:59.0+08:00 },
    { month: '2026-02', start: @2026-02-01T00:00:00.0+08:00, end: @2026-02-28T23:59:59.0+08:00 },
    { month: '2026-03', start: @2026-03-01T00:00:00.0+08:00, end: @2026-03-31T23:59:59.0+08:00 }
  }
  return months M
  let monthPDPatients: Count(
        "New PD Patients With Catheter And Dialysis" P
        where P.catheterInsertionDate >= M.start and P.catheterInsertionDate <= M.end
      )
  return {
    month: M.month,
    pdPatientCount: monthPDPatients
  }

// 新增腹膜透析病人詳細資訊
define "New PD Patient Details":
  "New PD Patients With Catheter And Dialysis" P
  return {
    patientId: P.patientId,
    age: P.age,
    gender: P.gender,
    firstDialysisDate: P.firstDialysisDate,
    catheterInsertionDate: P.catheterInsertionDate,
    dialysisDurationDays: P.dialysisDurationDays,
    daysBetweenCatheterAndDialysis: days between P.catheterInsertionDate and P.firstDialysisDate
  }
  sort by catheterInsertionDate

// 新增血液透析病人（作為對照）
define "New HD Patients":
  "Patients With Chronic Dialysis Over 1 Month" CDP
  let patientId: CDP.patientId,
      isInPDList: exists(
        "New PD Patients With Catheter And Dialysis" PDP
        where PDP.patientId = patientId
      )
  where not isInPDList
  return {
    patientId: patientId,
    age: CDP.age,
    gender: CDP.gender,
    firstDialysisDate: CDP.firstDialysisDate,
    dialysisDurationDays: CDP.dialysisDurationDays
  }

// 新增血液透析病人數
define "New HD Patient Count":
  Count("New HD Patients")

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '各院所新增透析病人之腹膜透析人數及占率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    dataFrequency: '每季',
    numerator: "Numerator New PD Patients",
    numeratorDefinition: '追蹤期間首次接受植管且於當季開始換液之長期慢性腹膜透析新病患人數(需透析超過1個月以上)',
    denominator: "Denominator New Chronic Dialysis Patients",
    denominatorDefinition: '追蹤期間當季第一次接受透析治療且透析超過1個月以上之長期慢性透析新病患人數',
    pdRate: "PD Patient Rate",
    newHDPatientCount: "New HD Patient Count",
    organizationAnalysis: "Organization Statistics",
    ageGroupAnalysis: "Age Group Statistics",
    genderAnalysis: "Gender Statistics",
    monthlyTrend: "Monthly Trend Analysis",
    newPDPatientDetails: "New PD Patient Details",
    unit: '%',
    formula: '(分子/分母) x 100%',
    note: '此指標反映各醫療機構推廣腹膜透析的成效。較高的占率表示機構積極推動腹膜透析選項，幫助病人選擇適合的透析方式。腹膜透析具有居家透析、保存殘餘腎功能等優勢。'
  }
