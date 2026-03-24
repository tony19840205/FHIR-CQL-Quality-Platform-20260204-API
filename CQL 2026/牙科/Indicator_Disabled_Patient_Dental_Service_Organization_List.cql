/**
 * 指標名稱: 提供特定身心障礙者醫療服務之牙醫院所名單
 * 指標類別: 牙科照護品質指標 - 清單型指標
 * 計算頻率: 每季
 * 指標定義: 該醫事服務機構是否有提供特定障別身心障礙者牙醫療服務
 * 
 * 指標類型: 清單型指標（無分子分母，產出符合條件的院所清單）
 * 
 * 識別方式:
 * - 特定障別身心障礙者牙醫療服務處置代碼
 * - 案件分類為特殊身心障礙者服務
 * - 患者具有身心障礙重大傷病卡
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Disabled_Patient_Dental_Service_Organization_List version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
codesystem "TWMajorIllnessCode": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-major-illness-code'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 特定障別身心障礙者牙醫療服務處置代碼（假設代碼，需依實際健保規範調整）
define "Disabled Patient Dental Service Codes": {
  Code { code: '91301C', system: "TWProcedure", display: '身心障礙者口腔預防保健' },
  Code { code: '91302C', system: "TWProcedure", display: '身心障礙者全口牙結石清除' },
  Code { code: '91303C', system: "TWProcedure", display: '身心障礙者牙齒填補' },
  Code { code: '91304C', system: "TWProcedure", display: '身心障礙者拔牙' },
  Code { code: '91305C', system: "TWProcedure", display: '身心障礙者根管治療' },
  Code { code: '91306C', system: "TWProcedure", display: '身心障礙者特殊處置' }
}

// 身心障礙重大傷病代碼
define "Disability Major Illness Codes": {
  Code { code: '019', system: "TWMajorIllnessCode", display: '身心障礙' },
  Code { code: '020', system: "TWMajorIllnessCode", display: '智能障礙' },
  Code { code: '021', system: "TWMajorIllnessCode", display: '精神障礙' },
  Code { code: '022', system: "TWMajorIllnessCode", display: '肢體障礙' }
}

// 特殊案件類型（身心障礙者專用）
define "Special Case Type For Disabled": 
  Code { code: 'D1', system: "TWCaseType", display: '身心障礙者特殊醫療' }

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

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

// 取得Encounter的案件類型
define function GetEncounterCaseType(encounter Encounter):
  if encounter.type is not null and Count(encounter.type) > 0
  then (
    singleton from (
      encounter.type[0].coding C 
      where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
    )
  ).code.value
  else null

// 取得Encounter的醫療機構
define function GetEncounterOrganization(encounter Encounter):
  if encounter.serviceProvider is not null
  then encounter.serviceProvider.reference.value
  else GetExtensionString(encounter, 'organizationReference')

// 檢查是否為身心障礙者牙醫服務
define function IsDisabledPatientDentalService(procedureCode String):
  procedureCode in { '91301C', '91302C', '91303C', '91304C', '91305C', '91306C' }

// 檢查患者是否有身心障礙重大傷病卡
define function HasDisabilityMajorIllness(patient Patient):
  exists(
    patient.extension E
    where E.url = 'majorIllnessCode'
    and (E.value as FHIR.code).value in { '019', '020', '021', '022' }
  )

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

// 觀察期間的所有Encounter
define "Encounters During Measurement Period":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'

// 方法1: 通過特定處置代碼識別的服務
define "Services By Procedure Code":
  "Procedures During Measurement Period" P
  where IsDisabledPatientDentalService(GetProcedureCode(P))
  return {
    procedureId: 'Procedure/' + P.id,
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    procedureCode: GetProcedureCode(P),
    procedureDate: P.performed as FHIR.dateTime,
    identificationMethod: 'Procedure Code'
  }

// 方法2: 通過案件類型識別的服務
define "Services By Case Type":
  "Encounters During Measurement Period" E
  where GetEncounterCaseType(E) = 'D1'
  return {
    encounterId: 'Encounter/' + E.id,
    patient: E.subject.reference.value,
    organization: GetEncounterOrganization(E),
    encounterDate: E.period.start,
    identificationMethod: 'Case Type'
  }

// 方法3: 通過患者身心障礙重大傷病卡識別的服務
define "Services For Disabled Patients":
  "Encounters During Measurement Period" E
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = E.subject.reference.value)
  where HasDisabilityMajorIllness(patient)
  and GetEncounterCaseType(E) = '04'  // 牙醫門診
  return {
    encounterId: 'Encounter/' + E.id,
    patient: E.subject.reference.value,
    organization: GetEncounterOrganization(E),
    encounterDate: E.period.start,
    identificationMethod: 'Major Illness Card'
  }

// 綜合所有識別方法的服務
define "All Disabled Patient Dental Services":
  ("Services By Procedure Code" 
   union "Services By Case Type" 
   union "Services For Disabled Patients")

// 有提供身心障礙者牙醫服務的院所清單
define "Organizations With Service":
  distinct (
    "All Disabled Patient Dental Services" S
    return if S.organization is not null then S.organization else null
  )

// ========================================================================================
// 院所服務統計分析
// ========================================================================================

// 各院所詳細服務統計
define "Organization Service Statistics":
  "Organizations With Service" Org
  let orgServices: "All Disabled Patient Dental Services" S 
                   where S.organization = Org,
      
      // 總服務次數
      totalServices: Count(orgServices),
      
      // 服務患者數
      totalPatients: Count(distinct (orgServices S return S.patient)),
      
      // 平均每位患者服務次數
      avgServicesPerPatient: if totalPatients > 0
                             then Round(totalServices / totalPatients, 2)
                             else null,
      
      // 依識別方法分類統計
      byProcedureCode: Count(orgServices S where S.identificationMethod = 'Procedure Code'),
      byCaseType: Count(orgServices S where S.identificationMethod = 'Case Type'),
      byMajorIllness: Count(orgServices S where S.identificationMethod = 'Major Illness Card')
  
  return {
    organization: Org,
    hasService: true,
    totalServices: totalServices,
    totalPatients: totalPatients,
    avgServicesPerPatient: avgServicesPerPatient,
    identifiedByProcedureCode: byProcedureCode,
    identifiedByCaseType: byCaseType,
    identifiedByMajorIllnessCard: byMajorIllness
  }

// 處置代碼使用分布（針對方法1）
define "Procedure Code Distribution":
  "Services By Procedure Code" S
  return {
    procedureCode: S.procedureCode,
    organization: S.organization
  }

// 處置代碼使用統計
define "Procedure Code Usage Statistics":
  distinct (
    "Services By Procedure Code" S return S.procedureCode
  ) Code
  let codeServices: "Services By Procedure Code" S where S.procedureCode = Code,
      codeCount: Count(codeServices),
      codeOrgs: Count(distinct (codeServices S return S.organization))
  return {
    procedureCode: Code,
    totalUsage: codeCount,
    organizationCount: codeOrgs
  }
  sort by totalUsage desc

// 依患者年齡分層
define "Results By Patient Age":
  "All Disabled Patient Dental Services" S
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = S.patient),
      birthDate: patient.birthDate.value,
      serviceDate: if S.procedureDate is not null 
                   then S.procedureDate 
                   else S.encounterDate,
      age: AgeInYearsAt(birthDate, serviceDate),
      ageGroup: 
        if age < 12 then '<12歲'
        else if age < 18 then '12-17歲'
        else if age < 30 then '18-29歲'
        else if age < 50 then '30-49歲'
        else if age < 65 then '50-64歲'
        else '>=65歲'
  return {
    ageGroup: ageGroup,
    age: age,
    patient: S.patient
  }

// 依性別分層
define "Results By Gender":
  "All Disabled Patient Dental Services" S
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = S.patient),
      gender: patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    patient: S.patient
  }

// 月度服務趨勢
define "Monthly Service Trend":
  "All Disabled Patient Dental Services" S
  let serviceDate: if S.procedureDate is not null 
                   then S.procedureDate 
                   else S.encounterDate,
      month: ToString(month from serviceDate) + '月'
  return {
    month: month,
    organization: S.organization
  }

// 患者服務頻率分析
define "Patient Service Frequency":
  distinct (
    "All Disabled Patient Dental Services" S return S.patient
  ) PatientRef
  let patientServices: "All Disabled Patient Dental Services" S 
                       where S.patient = PatientRef,
      serviceCount: Count(patientServices),
      frequencyCategory: 
        if serviceCount = 1 then '單次服務'
        else if serviceCount <= 3 then '2-3次服務'
        else if serviceCount <= 5 then '4-5次服務'
        else '6次以上服務'
  return {
    patient: PatientRef,
    serviceCount: serviceCount,
    frequencyCategory: frequencyCategory
  }

// 服務規模分類
define "Organization Service Scale":
  "Organization Service Statistics" Stats
  let scale: 
    if Stats.totalPatients >= 50 then '大規模 (>=50人)'
    else if Stats.totalPatients >= 20 then '中規模 (20-49人)'
    else if Stats.totalPatients >= 10 then '小規模 (10-19人)'
    else '微規模 (<10人)'
  return {
    organization: Stats.organization,
    totalPatients: Stats.totalPatients,
    scale: scale
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '提供特定身心障礙者醫療服務之牙醫院所名單',
    indicatorType: '清單型指標',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    definition: '該醫事服務機構是否有提供特定障別身心障礙者牙醫療服務',
    identificationMethods: '1.特定處置代碼 2.案件類型 3.重大傷病卡',
    
    // 基本統計
    totalOrganizationsWithService: Count("Organizations With Service"),
    totalServices: Count("All Disabled Patient Dental Services"),
    totalPatients: Count(distinct ("All Disabled Patient Dental Services" S return S.patient)),
    
    // 院所清單（主要輸出）
    organizationList: "Organizations With Service",
    
    // 各類分析結果
    organizationStatistics: "Organization Service Statistics",
    procedureCodeUsage: "Procedure Code Usage Statistics",
    organizationServiceScale: "Organization Service Scale",
    
    // 患者特徵分析
    ageDistribution: "Results By Patient Age",
    genderDistribution: "Results By Gender",
    patientServiceFrequency: "Patient Service Frequency"
  }
