/**
 * 指標名稱: 執行複雜齒切除之數量
 * 指標類別: 牙科照護品質指標 - 統計數量型指標
 * 計算頻率: 每季
 * 指標定義: 醫事機構該季實施複雜齒切除術(92016C)的牙位數
 * 
 * 指標類型: 統計數量型指標（無分子分母，統計處置的牙位數量）
 * 
 * 處置代碼: 92016C (複雜齒切除術)
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Complex_Tooth_Extraction_Count version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
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

// 複雜齒切除術代碼
define "Complex Tooth Extraction Code": 
  Code { code: '92016C', system: "TWProcedure", display: '複雜齒切除術' }

// 牙醫門診案件類型碼
define "Dental Outpatient Case Type": 
  Code { code: '04', system: "TWCaseType", display: '門診' }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Extension整數值
define function GetExtensionInteger(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.integer

// 取得Procedure的處置代碼
define function GetProcedureCode(procedure Procedure):
  if procedure.code is not null 
  then (procedure.code.coding[0].code.value)
  else null

// 取得Procedure的醫療機構
define function GetOrganization(procedure Procedure):
  if procedure.performer is not null and Count(procedure.performer) > 0
  then (procedure.performer[0].actor.reference.value)
  else null

// 取得Patient Reference
define function GetPatientReference(procedure Procedure):
  procedure.subject.reference.value

// 取得Encounter Reference
define function GetEncounterReference(procedure Procedure):
  if procedure.encounter is not null
  then procedure.encounter.reference.value
  else null

// 取得牙位號碼（從Procedure的bodySite或extension）
define function GetToothNumber(procedure Procedure):
  if procedure.bodySite is not null and Count(procedure.bodySite) > 0
  then GetExtensionString(procedure.bodySite[0], 'toothNumber')
  else GetExtensionString(procedure, 'toothNumber')

// 檢查是否為複雜齒切除術
define function IsComplexToothExtraction(procedure Procedure):
  GetProcedureCode(procedure) = '92016C'

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間 (該季)
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 觀察期間的所有Procedure
define "Procedures During Measurement Period":
  [Procedure] P
  where P.performed during "Measurement Period"
  and P.status.value = 'completed'

// 複雜齒切除術處置
define "Complex Tooth Extraction Procedures":
  "Procedures During Measurement Period" P
  where IsComplexToothExtraction(P)
  return {
    procedureId: 'Procedure/' + P.id,
    encounterId: GetEncounterReference(P),
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    procedureDate: P.performed as FHIR.dateTime,
    toothNumber: GetToothNumber(P)
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 總牙位數（每個Procedure代表一顆牙）
define "Total Tooth Count":
  Count("Complex Tooth Extraction Procedures")

// 總案件數（去重複Encounter）
define "Total Encounters":
  Count(
    distinct (
      "Complex Tooth Extraction Procedures" P 
      where P.encounterId is not null
      return P.encounterId
    )
  )

// 總患者數（去重複Patient）
define "Total Patients":
  Count(
    distinct (
      "Complex Tooth Extraction Procedures" P return P.patient
    )
  )

// 總服務機構數
define "Total Organizations":
  Count(
    distinct (
      "Complex Tooth Extraction Procedures" P return P.organization
    )
  )

// 平均每次就診切除牙位數
define "Average Teeth Per Encounter":
  if "Total Encounters" > 0
  then Round("Total Tooth Count" / "Total Encounters", 2)
  else null

// 平均每位患者切除牙位數
define "Average Teeth Per Patient":
  if "Total Patients" > 0
  then Round("Total Tooth Count" / "Total Patients", 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層
define "Results By Organization":
  distinct (
    "Complex Tooth Extraction Procedures" P return P.organization
  ) Org
  let orgProcedures: "Complex Tooth Extraction Procedures" P where P.organization = Org,
      orgToothCount: Count(orgProcedures),
      orgEncounterCount: Count(
        distinct (orgProcedures P where P.encounterId is not null return P.encounterId)
      ),
      orgPatientCount: Count(distinct (orgProcedures P return P.patient)),
      orgAvgPerEncounter: if orgEncounterCount > 0
                          then Round(orgToothCount / orgEncounterCount, 2)
                          else null,
      orgAvgPerPatient: if orgPatientCount > 0
                        then Round(orgToothCount / orgPatientCount, 2)
                        else null
  return {
    organization: Org,
    totalTeeth: orgToothCount,
    totalEncounters: orgEncounterCount,
    totalPatients: orgPatientCount,
    avgTeethPerEncounter: orgAvgPerEncounter,
    avgTeethPerPatient: orgAvgPerPatient
  }
  sort by totalTeeth desc

// 依患者年齡分層
define "Results By Patient Age":
  "Complex Tooth Extraction Procedures" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, P.procedureDate),
      ageGroup: 
        if age < 18 then '<18歲'
        else if age < 30 then '18-29歲'
        else if age < 40 then '30-39歲'
        else if age < 50 then '40-49歲'
        else if age < 60 then '50-59歲'
        else if age < 70 then '60-69歲'
        else '>=70歲'
  return {
    ageGroup: ageGroup,
    age: age,
    procedureId: P.procedureId
  }

// 依性別分層
define "Results By Gender":
  "Complex Tooth Extraction Procedures" P
  let patient: singleton from ([Patient] Pt where 'Patient/' + Pt.id = P.patient),
      gender: patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    procedureId: P.procedureId
  }

// 月度趨勢分析
define "Results By Month":
  "Complex Tooth Extraction Procedures" P
  let month: ToString(month from P.procedureDate) + '月'
  return {
    month: month,
    procedureId: P.procedureId
  }

// 每次就診切除牙位數分析
define "Teeth Per Encounter Analysis":
  distinct (
    "Complex Tooth Extraction Procedures" P 
    where P.encounterId is not null
    return P.encounterId
  ) EncounterRef
  let extractionProcedures: "Complex Tooth Extraction Procedures" P 
                            where P.encounterId = EncounterRef,
      teethCount: Count(extractionProcedures),
      teethCategory: 
        if teethCount = 1 then '單顆拔除'
        else if teethCount = 2 then '2顆拔除'
        else if teethCount = 3 then '3顆拔除'
        else if teethCount = 4 then '4顆拔除'
        else '5顆以上拔除'
  return {
    encounterId: EncounterRef,
    teethCount: teethCount,
    teethCategory: teethCategory
  }

// 每位患者切除牙位數分析
define "Teeth Per Patient Analysis":
  distinct (
    "Complex Tooth Extraction Procedures" P return P.patient
  ) PatientRef
  let extractionProcedures: "Complex Tooth Extraction Procedures" P 
                            where P.patient = PatientRef,
      teethCount: Count(extractionProcedures),
      encounterCount: Count(
        distinct (extractionProcedures P where P.encounterId is not null return P.encounterId)
      ),
      firstExtractionDate: First(extractionProcedures P sort by procedureDate).procedureDate,
      lastExtractionDate: Last(extractionProcedures P sort by procedureDate).procedureDate,
      daysSpan: if encounterCount > 1
                then days between firstExtractionDate and lastExtractionDate
                else null,
      teethCategory: 
        if teethCount = 1 then '1顆'
        else if teethCount <= 3 then '2-3顆'
        else if teethCount <= 5 then '4-5顆'
        else if teethCount <= 10 then '6-10顆'
        else '10顆以上'
  return {
    patient: PatientRef,
    totalTeeth: teethCount,
    encounterCount: encounterCount,
    teethCategory: teethCategory,
    firstExtractionDate: firstExtractionDate,
    lastExtractionDate: lastExtractionDate,
    daysSpan: daysSpan
  }

// 牙位號碼分布分析（如果有記錄牙位資訊）
define "Tooth Number Distribution":
  "Complex Tooth Extraction Procedures" P
  where P.toothNumber is not null
  return {
    toothNumber: P.toothNumber,
    procedureId: P.procedureId
  }

// 週別分布分析
define "Results By Week":
  "Complex Tooth Extraction Procedures" P
  let weekOfYear: ToString(weeks between @2026-01-01 and P.procedureDate) + '週'
  return {
    week: weekOfYear,
    procedureId: P.procedureId
  }

// 機構服務規模分類
define "Organization Service Scale":
  "Results By Organization" OrgStats
  let scale: 
    if OrgStats.totalTeeth >= 100 then '大規模 (>=100顆)'
    else if OrgStats.totalTeeth >= 50 then '中規模 (50-99顆)'
    else if OrgStats.totalTeeth >= 20 then '小規模 (20-49顆)'
    else '微規模 (<20顆)'
  return {
    organization: OrgStats.organization,
    totalTeeth: OrgStats.totalTeeth,
    scale: scale
  }

// 單次就診多顆拔除分析
define "Multiple Extraction Per Visit":
  "Teeth Per Encounter Analysis" Analysis
  where Analysis.teethCount > 1
  return {
    encounterId: Analysis.encounterId,
    teethCount: Analysis.teethCount,
    teethCategory: Analysis.teethCategory
  }

// 複雜度指標（單次就診多顆複雜拔牙可能反映手術複雜度）
define "Complexity Analysis":
  "Teeth Per Encounter Analysis" Analysis
  let complexityLevel: 
    if Analysis.teethCount >= 5 then '高複雜度'
    else if Analysis.teethCount >= 3 then '中複雜度'
    else if Analysis.teethCount = 2 then '低複雜度'
    else '單顆'
  return {
    encounterId: Analysis.encounterId,
    teethCount: Analysis.teethCount,
    complexityLevel: complexityLevel
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '執行複雜齒切除之數量',
    indicatorType: '統計數量型指標',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    definition: '醫事機構該季實施複雜齒切除術(92016C)的牙位數',
    procedureCode: '92016C (複雜齒切除術)',
    
    // 主要統計數據
    totalToothCount: "Total Tooth Count",
    totalEncounters: "Total Encounters",
    totalPatients: "Total Patients",
    totalOrganizations: "Total Organizations",
    averageTeethPerEncounter: "Average Teeth Per Encounter",
    averageTeethPerPatient: "Average Teeth Per Patient",
    
    // 分層分析結果
    organizationStatistics: "Results By Organization",
    ageDistribution: "Results By Patient Age",
    genderDistribution: "Results By Gender",
    monthlyTrend: "Results By Month",
    teethPerEncounterAnalysis: "Teeth Per Encounter Analysis",
    teethPerPatientAnalysis: "Teeth Per Patient Analysis",
    organizationServiceScale: "Organization Service Scale",
    
    // 複雜度分析
    complexityAnalysis: "Complexity Analysis",
    multipleExtractionCases: Count("Multiple Extraction Per Visit"),
    patientsWithMultipleVisits: Count("Teeth Per Patient Analysis" A where A.encounterCount > 1),
    toothNumberDistribution: "Tooth Number Distribution"
  }
