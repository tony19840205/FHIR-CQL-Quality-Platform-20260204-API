/**
 * 指標名稱: 牙周病案件比率
 * 指標類別: 牙科照護品質指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 醫事機構申報牙周病學項目治療的總案件數
 * 分母: 醫事機構牙醫門診總案件數
 * 
 * 分子條件: 牙周病學項目治療健保代碼為 91001到91013
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Periodontal_Disease_Case_Rate version '1.0.0'

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

// 牙周病學項目治療代碼 (91001到91013)
define "Periodontal Disease Treatment Codes": {
  Code { code: '91001', system: "TWProcedure", display: '牙周病學項目治療-91001' },
  Code { code: '91002', system: "TWProcedure", display: '牙周病學項目治療-91002' },
  Code { code: '91003', system: "TWProcedure", display: '牙周病學項目治療-91003' },
  Code { code: '91004', system: "TWProcedure", display: '牙周病學項目治療-91004' },
  Code { code: '91005', system: "TWProcedure", display: '牙周病學項目治療-91005' },
  Code { code: '91006', system: "TWProcedure", display: '牙周病學項目治療-91006' },
  Code { code: '91007', system: "TWProcedure", display: '牙周病學項目治療-91007' },
  Code { code: '91008', system: "TWProcedure", display: '牙周病學項目治療-91008' },
  Code { code: '91009', system: "TWProcedure", display: '牙周病學項目治療-91009' },
  Code { code: '91010', system: "TWProcedure", display: '牙周病學項目治療-91010' },
  Code { code: '91011', system: "TWProcedure", display: '牙周病學項目治療-91011' },
  Code { code: '91012', system: "TWProcedure", display: '牙周病學項目治療-91012' },
  Code { code: '91013', system: "TWProcedure", display: '牙周病學項目治療-91013' }
}

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
  if encounter.class is not null
  then encounter.class.code.value
  else null

// 檢查是否為牙周病學項目治療
define function IsPeriodontalDiseaseTreatment(procedure Procedure):
  let code: GetProcedureCode(procedure)
  return code in { '91001', '91002', '91003', '91004', '91005', '91006', '91007', 
                   '91008', '91009', '91010', '91011', '91012', '91013' }

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

// 牙醫門診的所有Encounter
define "Dental Outpatient Encounters":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'
  and GetEncounterCaseType(E) = '04'  // 門診

// 分母: 牙醫門診總案件數
define "Denominator":
  "Dental Outpatient Encounters" E
  return {
    encounterId: 'Encounter/' + E.id,
    patient: E.subject.reference.value,
    organization: GetExtensionString(E, 'organizationReference'),
    visitDate: E.period.start
  }

// 牙周病學項目治療案件
define "Periodontal Disease Treatment Procedures":
  "Procedures During Measurement Period" P
  where IsPeriodontalDiseaseTreatment(P)

// 分子: 牙周病學項目治療的總案件數
define "Numerator":
  "Periodontal Disease Treatment Procedures" P
  let encounterRef: GetEncounterReference(P)
  where encounterRef is not null
  and exists(
    "Dental Outpatient Encounters" E
    where 'Encounter/' + E.id = encounterRef
  )
  return {
    encounterId: encounterRef,
    patient: GetPatientReference(P),
    organization: GetOrganization(P),
    procedureCode: GetProcedureCode(P),
    procedureDate: P.performed as FHIR.dateTime
  }

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母案件數
define "Denominator Count":
  Count("Denominator")

// 分子案件數
define "Numerator Count":
  Count(
    distinct (
      "Numerator" N return N.encounterId
    )
  )

// 案件比率 (分子/分母)
define "Case Rate":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層
define "Results By Organization":
  distinct (
    "Denominator" D return D.organization
  ) Org
  let orgDenominator: "Denominator" D where D.organization = Org,
      orgNumerator: "Numerator" N where N.organization = Org,
      orgDenominatorCount: Count(orgDenominator),
      orgNumeratorCount: Count(distinct (orgNumerator N return N.encounterId)),
      orgCaseRate: if orgDenominatorCount > 0 
                   then Round((orgNumeratorCount / orgDenominatorCount) * 100.0, 2)
                   else null
  return {
    organization: Org,
    denominator: orgDenominatorCount,
    numerator: orgNumeratorCount,
    caseRate: orgCaseRate
  }

// 依處置代碼分層 (分子)
define "Results By Procedure Code":
  "Numerator" N
  return {
    procedureCode: N.procedureCode,
    encounterId: N.encounterId
  }

// 處置代碼分布統計
define "Procedure Code Distribution":
  distinct (
    "Numerator" N return N.procedureCode
  ) Code
  let codeCount: Count(
        "Numerator" N where N.procedureCode = Code
      ),
      encounterCount: Count(
        distinct (
          "Numerator" N where N.procedureCode = Code
          return N.encounterId
        )
      )
  return {
    procedureCode: Code,
    totalProcedures: codeCount,
    totalEncounters: encounterCount
  }
  sort by procedureCode

// 依患者年齡分層
define "Results By Patient Age":
  "Numerator" N
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = N.patient),
      birthDate: patient.birthDate.value,
      age: AgeInYearsAt(birthDate, N.procedureDate),
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
    encounterId: N.encounterId
  }

// 依性別分層
define "Results By Gender":
  "Numerator" N
  let patient: singleton from ([Patient] P where 'Patient/' + P.id = N.patient),
      gender: patient.gender.value
  return {
    gender: 
      if gender = 'male' then '男性'
      else if gender = 'female' then '女性'
      else '其他',
    encounterId: N.encounterId
  }

// 月度趨勢分析
define "Results By Month":
  "Numerator" N
  let month: ToString(month from N.procedureDate) + '月'
  return {
    month: month,
    encounterId: N.encounterId
  }

// 每次就診的牙周病處置數量分析
define "Procedures Per Encounter Analysis":
  distinct (
    "Numerator" N return N.encounterId
  ) EncounterRef
  let procedureCount: Count(
        "Periodontal Disease Treatment Procedures" P
        where GetEncounterReference(P) = EncounterRef
      ),
      procedureCodes: distinct (
        "Periodontal Disease Treatment Procedures" P
        where GetEncounterReference(P) = EncounterRef
        return GetProcedureCode(P)
      ),
      procedureCategory: 
        if procedureCount = 1 then '單一處置'
        else if procedureCount = 2 then '2項處置'
        else if procedureCount = 3 then '3項處置'
        else '4項以上處置'
  return {
    encounterId: EncounterRef,
    procedureCount: procedureCount,
    uniqueProcedureTypes: Count(procedureCodes),
    procedureCategory: procedureCategory
  }

// 患者就診頻率分析
define "Patient Visit Frequency Analysis":
  distinct (
    "Numerator" N return N.patient
  ) PatientRef
  let encounters: distinct (
        "Numerator" N where N.patient = PatientRef
        return N.encounterId
      ),
      encounterCount: Count(encounters),
      frequencyCategory: 
        if encounterCount = 1 then '單次就診'
        else if encounterCount = 2 then '2次就診'
        else if encounterCount = 3 then '3次就診'
        else '4次以上就診'
  return {
    patient: PatientRef,
    encounterCount: encounterCount,
    frequencyCategory: frequencyCategory
  }

// 無牙周病治療的門診案件
define "Encounters Without Periodontal Treatment":
  "Denominator" D
  where not exists(
    "Numerator" N where N.encounterId = D.encounterId
  )
  return {
    encounterId: D.encounterId,
    patient: D.patient,
    organization: D.organization
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '牙周病案件比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    numeratorDefinition: '醫事機構申報牙周病學項目治療的總案件數',
    numeratorCodes: '91001到91013',
    denominator: "Denominator Count",
    denominatorDefinition: '醫事機構牙醫門診總案件數',
    caseRate: "Case Rate",
    totalProcedures: Count("Periodontal Disease Treatment Procedures"),
    totalPatients: Count(distinct ("Numerator" N return N.patient)),
    encountersWithoutTreatment: Count("Encounters Without Periodontal Treatment"),
    unit: '%',
    formula: '(分子/分母) x 100%'
  }
