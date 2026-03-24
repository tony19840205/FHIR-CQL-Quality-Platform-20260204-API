/**
 * 指標名稱: 牙周病統合治療方案之院所名單
 * 指標類別: 牙科照護品質指標 - 清單型指標
 * 計算頻率: 每季
 * 指標定義: 該醫事服務機構是否有牙周病統合治療方案之服務
 * 
 * 指標類型: 清單型指標（無分子分母，產出符合條件的院所清單）
 * 
 * 牙周病統合治療方案代碼:
 * - 第一階段: P4001C, 91021C
 * - 第二階段: P4002C, 91022C
 * - 第三階段: P4003C, 91023C
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Periodontal_Integrated_Treatment_Organization_List version '1.0.0'

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

// 牙周病統合治療方案所有階段代碼
define "Periodontal Integrated Treatment All Phase Codes": {
  Code { code: 'P4001C', system: "TWProcedure", display: '牙周病統合治療方案第一階段' },
  Code { code: '91021C', system: "TWProcedure", display: '牙周病統合治療方案第一階段-91021C' },
  Code { code: 'P4002C', system: "TWProcedure", display: '牙周病統合治療方案第二階段' },
  Code { code: '91022C', system: "TWProcedure", display: '牙周病統合治療方案第二階段-91022C' },
  Code { code: 'P4003C', system: "TWProcedure", display: '牙周病統合治療方案第三階段' },
  Code { code: '91023C', system: "TWProcedure", display: '牙周病統合治療方案第三階段-91023C' }
}

// 第一階段代碼
define "Phase 1 Codes": {
  Code { code: 'P4001C', system: "TWProcedure", display: '牙周病統合治療方案第一階段' },
  Code { code: '91021C', system: "TWProcedure", display: '牙周病統合治療方案第一階段-91021C' }
}

// 第二階段代碼
define "Phase 2 Codes": {
  Code { code: 'P4002C', system: "TWProcedure", display: '牙周病統合治療方案第二階段' },
  Code { code: '91022C', system: "TWProcedure", display: '牙周病統合治療方案第二階段-91022C' }
}

// 第三階段代碼
define "Phase 3 Codes": {
  Code { code: 'P4003C', system: "TWProcedure", display: '牙周病統合治療方案第三階段' },
  Code { code: '91023C', system: "TWProcedure", display: '牙周病統合治療方案第三階段-91023C' }
}

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

// 檢查是否為牙周病統合治療方案處置
define function IsPeriodontalIntegratedTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { 'P4001C', '91021C', 'P4002C', '91022C', 'P4003C', '91023C' }

// 判斷處置階段
define function GetTreatmentPhase(procedureCode String):
  if procedureCode in { 'P4001C', '91021C' } then 'Phase 1'
  else if procedureCode in { 'P4002C', '91022C' } then 'Phase 2'
  else if procedureCode in { 'P4003C', '91023C' } then 'Phase 3'
  else 'Unknown'

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

// 所有牙周病統合治療方案處置
define "Periodontal Integrated Treatment Procedures":
  "Procedures During Measurement Period" P
  where IsPeriodontalIntegratedTreatment(P)
  return {
    procedureId: 'Procedure/' + P.id,
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    procedureCode: GetProcedureCode(P),
    procedureDate: P.performed as FHIR.dateTime,
    phase: GetTreatmentPhase(GetProcedureCode(P))
  }

// 有提供牙周病統合治療方案服務的院所清單
define "Organizations With Service":
  distinct (
    "Periodontal Integrated Treatment Procedures" P
    return P.organization
  )

// ========================================================================================
// 院所服務統計分析
// ========================================================================================

// 各院所詳細服務統計
define "Organization Service Statistics":
  "Organizations With Service" Org
  let orgProcedures: "Periodontal Integrated Treatment Procedures" P 
                     where P.organization = Org,
      
      // 總案件數
      totalProcedures: Count(orgProcedures),
      
      // 服務患者數
      totalPatients: Count(distinct (orgProcedures P return P.patient)),
      
      // 第一階段統計
      phase1Procedures: orgProcedures P where P.phase = 'Phase 1',
      phase1Count: Count(phase1Procedures),
      phase1Patients: Count(distinct (phase1Procedures P return P.patient)),
      
      // 第二階段統計
      phase2Procedures: orgProcedures P where P.phase = 'Phase 2',
      phase2Count: Count(phase2Procedures),
      phase2Patients: Count(distinct (phase2Procedures P return P.patient)),
      
      // 第三階段統計
      phase3Procedures: orgProcedures P where P.phase = 'Phase 3',
      phase3Count: Count(phase3Procedures),
      phase3Patients: Count(distinct (phase3Procedures P return P.patient)),
      
      // 完成度分析（有第一階段且有第三階段的患者）
      patientsWithPhase1: distinct (phase1Procedures P return P.patient),
      patientsWithPhase3: distinct (phase3Procedures P return P.patient),
      patientsCompleted: patientsWithPhase1 intersect patientsWithPhase3,
      completionRate: if phase1Patients > 0 
                      then Round((Count(patientsCompleted) / phase1Patients) * 100.0, 2)
                      else null,
      
      // 平均每位患者的處置次數
      avgProceduresPerPatient: if totalPatients > 0
                               then Round(totalProcedures / totalPatients, 2)
                               else null
  
  return {
    organization: Org,
    hasService: true,
    totalProcedures: totalProcedures,
    totalPatients: totalPatients,
    avgProceduresPerPatient: avgProceduresPerPatient,
    phase1Count: phase1Count,
    phase1Patients: phase1Patients,
    phase2Count: phase2Count,
    phase2Patients: phase2Patients,
    phase3Count: phase3Count,
    phase3Patients: phase3Patients,
    patientsStarted: phase1Patients,
    patientsCompleted: Count(patientsCompleted),
    completionRate: completionRate
  }

// 各院所提供的服務階段類型
define "Organization Service Phases":
  "Organizations With Service" Org
  let phase1Available: exists(
        "Periodontal Integrated Treatment Procedures" P 
        where P.organization = Org and P.phase = 'Phase 1'
      ),
      phase2Available: exists(
        "Periodontal Integrated Treatment Procedures" P 
        where P.organization = Org and P.phase = 'Phase 2'
      ),
      phase3Available: exists(
        "Periodontal Integrated Treatment Procedures" P 
        where P.organization = Org and P.phase = 'Phase 3'
      ),
      serviceLevel: 
        if phase1Available and phase2Available and phase3Available then '完整三階段服務'
        else if phase1Available and phase3Available then '第一及第三階段'
        else if phase1Available and phase2Available then '第一及第二階段'
        else if phase1Available then '僅第一階段'
        else if phase2Available and phase3Available then '第二及第三階段'
        else if phase2Available then '僅第二階段'
        else if phase3Available then '僅第三階段'
        else '未分類'
  return {
    organization: Org,
    phase1Available: phase1Available,
    phase2Available: phase2Available,
    phase3Available: phase3Available,
    serviceLevel: serviceLevel
  }

// 處置代碼使用分布
define "Procedure Code Distribution By Organization":
  "Organizations With Service" Org
  let orgProcedures: "Periodontal Integrated Treatment Procedures" P 
                     where P.organization = Org,
      
      p4001c_count: Count(orgProcedures P where P.procedureCode = 'P4001C'),
      c91021c_count: Count(orgProcedures P where P.procedureCode = '91021C'),
      p4002c_count: Count(orgProcedures P where P.procedureCode = 'P4002C'),
      c91022c_count: Count(orgProcedures P where P.procedureCode = '91022C'),
      p4003c_count: Count(orgProcedures P where P.procedureCode = 'P4003C'),
      c91023c_count: Count(orgProcedures P where P.procedureCode = '91023C')
  
  return {
    organization: Org,
    P4001C: p4001c_count,
    '91021C': c91021c_count,
    P4002C: p4002c_count,
    '91022C': c91022c_count,
    P4003C: p4003c_count,
    '91023C': c91023c_count
  }

// 月度服務趨勢（各院所）
define "Monthly Service Trend By Organization":
  "Periodontal Integrated Treatment Procedures" P
  let month: ToString(month from P.procedureDate) + '月'
  return {
    organization: P.organization,
    month: month,
    phase: P.phase
  }

// 患者治療進度分析（各院所）
define "Patient Treatment Progress By Organization":
  "Organizations With Service" Org
  let orgPatients: distinct (
        "Periodontal Integrated Treatment Procedures" P 
        where P.organization = Org
        return P.patient
      )
  return {
    organization: Org,
    totalPatients: Count(orgPatients),
    patientDetails: orgPatients PatientRef
      let patientProcedures: "Periodontal Integrated Treatment Procedures" P
                             where P.patient = PatientRef
                             and P.organization = Org,
          hasPhase1: exists(patientProcedures P where P.phase = 'Phase 1'),
          hasPhase2: exists(patientProcedures P where P.phase = 'Phase 2'),
          hasPhase3: exists(patientProcedures P where P.phase = 'Phase 3'),
          progress: 
            if hasPhase1 and hasPhase2 and hasPhase3 then '完成全部三階段'
            else if hasPhase1 and hasPhase3 then '完成第一和第三階段'
            else if hasPhase1 and hasPhase2 then '完成第一和第二階段'
            else if hasPhase1 then '僅完成第一階段'
            else if hasPhase2 and hasPhase3 then '完成第二和第三階段'
            else if hasPhase2 then '僅完成第二階段'
            else if hasPhase3 then '僅完成第三階段'
            else '未分類'
      return {
        patient: PatientRef,
        progress: progress,
        totalProcedures: Count(patientProcedures)
      }
  }

// 服務規模分類
define "Organization Service Scale":
  "Organization Service Statistics" Stats
  let scale: 
    if Stats.totalPatients >= 100 then '大規模 (>=100人)'
    else if Stats.totalPatients >= 50 then '中規模 (50-99人)'
    else if Stats.totalPatients >= 20 then '小規模 (20-49人)'
    else '微規模 (<20人)'
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
    indicatorName: '牙周病統合治療方案之院所名單',
    indicatorType: '清單型指標',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    definition: '該醫事服務機構是否有牙周病統合治療方案之服務',
    serviceCodes: 'P4001C, 91021C (第一階段), P4002C, 91022C (第二階段), P4003C, 91023C (第三階段)',
    
    // 基本統計
    totalOrganizationsWithService: Count("Organizations With Service"),
    totalProcedures: Count("Periodontal Integrated Treatment Procedures"),
    totalPatients: Count(distinct ("Periodontal Integrated Treatment Procedures" P return P.patient)),
    
    // 院所清單（主要輸出）
    organizationList: "Organizations With Service",
    
    // 各類分析結果
    organizationStatistics: "Organization Service Statistics",
    organizationServicePhases: "Organization Service Phases",
    procedureCodeDistribution: "Procedure Code Distribution By Organization",
    organizationServiceScale: "Organization Service Scale"
  }
