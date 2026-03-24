/**
 * 指標名稱: 中醫門診者處方用藥日數重疊二日以上之比率
 * 指標類別: 中醫照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 按分區別及病人代號歸戶，計算每個代號的重複給藥日份加總，
 *       排除給藥日份重複為 1 日之重複日數
 * 分母: 給藥案件之給藥日份加總
 * 
 * 指標定義: 每季所有屬中醫總額之門診給藥案件
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_TCM_Medication_Overlap_2_Days_Or_More_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 中醫門診案件類型碼
define "TCM Outpatient Case Type": 
  Code { code: '05', system: 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type', display: '中醫門診' }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.MedicationRequest, url String):
  (
    singleton from (
      element.extension E where E.url.value = url
    ).value.value
  ) as String

// 取得Extension整數值
define function GetExtensionInteger(element FHIR.MedicationRequest, url String):
  (
    singleton from (
      element.extension E where E.url.value = url
    ).value.value
  ) as Integer

// 取得MedicationRequest的醫療機構
define function GetOrganization(medRequest MedicationRequest):
  if medRequest.requester is not null
  then medRequest.requester.reference.value
  else GetExtensionString(medRequest, 'organizationReference')

// 取得Patient Reference
define function GetPatientReference(medRequest MedicationRequest):
  medRequest.subject.reference.value

// 取得處方開立日期
define function GetPrescriptionDate(medRequest MedicationRequest):
  date from medRequest.authoredOn

// 取得給藥日數
define function GetDaysSupply(medRequest MedicationRequest):
  if medRequest.dispenseRequest is not null 
  and medRequest.dispenseRequest.expectedSupplyDuration is not null
  then medRequest.dispenseRequest.expectedSupplyDuration.value
  else GetExtensionInteger(medRequest, 'daysSupply')

// 計算處方用藥期間
define function GetMedicationPeriod(prescriptionDate Date, daysSupply Integer):
  if prescriptionDate is not null and daysSupply is not null
  then Interval[prescriptionDate, prescriptionDate]
  else null

// 計算兩個期間的重疊天數
define function CalculateOverlapDays(period1 Interval<Date>, period2 Interval<Date>):
  if (period1 intersect period2) is not null 
  then ToDecimal(days between start of (period1 intersect period2) and end of (period1 intersect period2)) + 1.0
  else 0.0


// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 觀察期間的所有MedicationRequest
define "Medication Requests During Measurement Period":
  [MedicationRequest] M
  where M.authoredOn during "Measurement Period"
  and M.status.value = 'active'

// 中醫門診給藥案件
define "TCM Outpatient Medication Cases":
  "Medication Requests During Measurement Period" M
  let encounter: singleton from ([Encounter] E 
                 where 'Encounter/' + E.id = M.encounter.reference.value),
      caseType: if encounter is not null 
                then encounter.class.code.value 
                else null,
      daysSupply: GetDaysSupply(M),
      prescriptionDate: GetPrescriptionDate(M)
  where caseType = '05'  // 中醫門診
  and daysSupply is not null
  and daysSupply > 0
  return {
    medicationRequestId: 'MedicationRequest/' + M.id,
    patient: GetPatientReference(M),
    organization: GetOrganization(M),
    prescriptionDate: prescriptionDate,
    daysSupply: daysSupply,
    medicationPeriod: GetMedicationPeriod(prescriptionDate, daysSupply)
  }

// 分母: 給藥案件之給藥日份加總
define "Denominator Total Days":
  Sum("TCM Outpatient Medication Cases" M return M.daysSupply)

// 按分區別及病人代號歸戶的處方
define "Prescriptions By Region And Patient":
  "TCM Outpatient Medication Cases" M
  return {
    patient: M.patient,
    medicationRequestId: M.medicationRequestId,
    prescriptionDate: M.prescriptionDate,
    daysSupply: M.daysSupply,
    medicationPeriod: M.medicationPeriod
  }

// 計算每個病人的處方重疊情況
define "Patient Medication Overlap Analysis":
  distinct (
    "Prescriptions By Region And Patient" P
    return P.patient
  ) PatientId
  let patientPrescriptions: "Prescriptions By Region And Patient" P
                            where P.patient = PatientId,
      totalOverlapDays: Sum(
        distinct (
          flatten (
            patientPrescriptions P1
            return (
              patientPrescriptions P2
              where P2.medicationRequestId > P1.medicationRequestId
              and P2.medicationPeriod overlaps P1.medicationPeriod
              return CalculateOverlapDays(P1.medicationPeriod, P2.medicationPeriod)
            )
          )
        )
      )
  
  return {
    patient: PatientId,
    totalPrescriptions: Count(patientPrescriptions),
    totalOverlapDays: totalOverlapDays,
    hasOverlapOf2OrMore: totalOverlapDays >= 2.0
  }

// 分子: 重複給藥日份加總（排除重複為 1 日的情況）
define "Numerator Total Overlap Days":
  Sum(
    "Patient Medication Overlap Analysis" Analysis
    where Analysis.totalOverlapDays >= 2
    return Analysis.totalOverlapDays
  )

// ========================================================================================
// 指標計算
// ========================================================================================

// 重疊二日以上之比率
define "Overlap Rate":
  if "Denominator Total Days" > 0 
  then Round(("Numerator Total Overlap Days" / "Denominator Total Days") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層
define "Results By Organization":
  distinct (
    "TCM Outpatient Medication Cases" M return M.organization
  ) Org
  let orgCases: "TCM Outpatient Medication Cases" M where M.organization = Org,
      orgTotalDays: Sum(orgCases M return M.daysSupply),
      orgPatients: distinct (orgCases M return M.patient),
      orgPatientAnalysis: "Patient Medication Overlap Analysis" A
                          where exists(orgCases M where M.patient = A.patient),
      orgOverlapDays: Sum(
        orgPatientAnalysis A 
        where A.totalOverlapDays >= 2 
        return A.totalOverlapDays
      ),
      orgOverlapRate: if orgTotalDays > 0
                      then Round((orgOverlapDays / orgTotalDays) * 100.0, 2)
                      else null
  return {
    organization: Org,
    totalDaysSupply: orgTotalDays,
    totalOverlapDays: orgOverlapDays,
    totalPatients: Count(orgPatients),
    patientsWithOverlap: Count(orgPatientAnalysis A where A.hasOverlapOf2OrMore),
    overlapRate: orgOverlapRate
  }

// 依重疊天數分層
define "Results By Overlap Days":
  "Patient Medication Overlap Analysis" A
  where A.totalOverlapDays >= 2
  return {
    patient: A.patient,
    totalOverlapDays: A.totalOverlapDays,
    overlapCategory: 
      if A.totalOverlapDays <= 3 then '2-3天'
      else if A.totalOverlapDays <= 7 then '4-7天'
      else if A.totalOverlapDays <= 14 then '8-14天'
      else if A.totalOverlapDays <= 30 then '15-30天'
      else '30天以上',
    patient: A.patient,
    totalOverlapDays: A.totalOverlapDays
  }

// 依患者年齡分層
define "Results By Patient Age":
  "Patient Medication Overlap Analysis" A
  return {
    patient: A.patient,
    totalOverlapDays: A.totalOverlapDays
  }

// 依性別分層
define "Results By Gender":
  "Patient Medication Overlap Analysis" A
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = A.patient),
      gender: patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    hasOverlapOf2OrMore: A.hasOverlapOf2OrMore,
    totalOverlapDays: A.totalOverlapDays
  }

// 無重疊的患者
define "Patients Without Overlap":
  "Patient Medication Overlap Analysis" A
  where not A.hasOverlapOf2OrMore
  return {
    patient: A.patient,
    totalPrescriptions: A.totalPrescriptions,
    totalOverlapDays: A.totalOverlapDays
  }

// 月度趨勢分析
define "Results By Month":
  "TCM Outpatient Medication Cases" M
  return {
    prescriptionDate: M.prescriptionDate,
    daysSupply: M.daysSupply
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '中醫門診者處方用藥日數重疊二日以上之比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Total Overlap Days",
    numeratorDefinition: '重複給藥日份加總（按分區別及病人代號歸戶，排除重複為 1 日之重複日數）',
    denominator: "Denominator Total Days",
    denominatorDefinition: '給藥案件之給藥日份加總',
    inclusionCriteria: '屬中醫總額之門診給藥案件',
    overlapRate: "Overlap Rate",
    totalCases: Count("TCM Outpatient Medication Cases"),
    totalPatients: Count(distinct ("TCM Outpatient Medication Cases" M return M.patient)),
    patientsWithOverlapOf2OrMore: Count("Patient Medication Overlap Analysis" A where A.hasOverlapOf2OrMore),
    patientsWithoutOverlap: Count("Patients Without Overlap"),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
