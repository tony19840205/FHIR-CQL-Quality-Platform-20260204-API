/**
 * 指標名稱: 六歲以下兒童氣喘住院率
 * 指標類別: 基層常見疾病照護指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 6歲以下兒童因氣喘住院人數
 * 分母: 6歲以下兒童曾因氣喘至門住診就醫人數
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Pediatric_Under_6_Asthma_Hospitalization_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 氣喘診斷碼 (ICD-10-CM J45)
define "Asthma Diagnosis Codes": {
  Code { code: 'J45', system: "ICD10CM", display: 'Asthma' },
  Code { code: 'J45.0', system: "ICD10CM", display: 'Predominantly allergic asthma' },
  Code { code: 'J45.1', system: "ICD10CM", display: 'Nonallergic asthma' },
  Code { code: 'J45.2', system: "ICD10CM", display: 'Mild intermittent asthma' },
  Code { code: 'J45.20', system: "ICD10CM", display: 'Mild intermittent asthma, uncomplicated' },
  Code { code: 'J45.21', system: "ICD10CM", display: 'Mild intermittent asthma with (acute) exacerbation' },
  Code { code: 'J45.22', system: "ICD10CM", display: 'Mild intermittent asthma with status asthmaticus' },
  Code { code: 'J45.3', system: "ICD10CM", display: 'Mild persistent asthma' },
  Code { code: 'J45.30', system: "ICD10CM", display: 'Mild persistent asthma, uncomplicated' },
  Code { code: 'J45.31', system: "ICD10CM", display: 'Mild persistent asthma with (acute) exacerbation' },
  Code { code: 'J45.32', system: "ICD10CM", display: 'Mild persistent asthma with status asthmaticus' },
  Code { code: 'J45.4', system: "ICD10CM", display: 'Moderate persistent asthma' },
  Code { code: 'J45.40', system: "ICD10CM", display: 'Moderate persistent asthma, uncomplicated' },
  Code { code: 'J45.41', system: "ICD10CM", display: 'Moderate persistent asthma with (acute) exacerbation' },
  Code { code: 'J45.42', system: "ICD10CM", display: 'Moderate persistent asthma with status asthmaticus' },
  Code { code: 'J45.5', system: "ICD10CM", display: 'Severe persistent asthma' },
  Code { code: 'J45.50', system: "ICD10CM", display: 'Severe persistent asthma, uncomplicated' },
  Code { code: 'J45.51', system: "ICD10CM", display: 'Severe persistent asthma with (acute) exacerbation' },
  Code { code: 'J45.52', system: "ICD10CM", display: 'Severe persistent asthma with status asthmaticus' },
  Code { code: 'J45.9', system: "ICD10CM", display: 'Asthma, unspecified' },
  Code { code: 'J45.90', system: "ICD10CM", display: 'Unspecified asthma, uncomplicated' },
  Code { code: 'J45.901', system: "ICD10CM", display: 'Unspecified asthma with (acute) exacerbation' },
  Code { code: 'J45.902', system: "ICD10CM", display: 'Unspecified asthma with status asthmaticus' }
}

// 氣喘用藥 ATC碼 (R03系列)
define "Asthma Medication ATC Codes": {
  // Beta2-agonists, inhalants
  Code { code: 'R03AC02', system: "ATC", display: 'Salbutamol' },
  Code { code: 'R03AC03', system: "ATC", display: 'Terbutaline' },
  Code { code: 'R03AC04', system: "ATC", display: 'Fenoterol' },
  Code { code: 'R03AC06', system: "ATC", display: 'Hexoprenaline' },
  Code { code: 'R03AC12', system: "ATC", display: 'Salmeterol' },
  Code { code: 'R03AC13', system: "ATC", display: 'Formoterol' },
  Code { code: 'R03AC16', system: "ATC", display: 'Reproterol' },
  Code { code: 'R03AC18', system: "ATC", display: 'Indacaterol' },
  // Glucocorticoids, inhalants
  Code { code: 'R03BA01', system: "ATC", display: 'Beclometasone' },
  Code { code: 'R03BA02', system: "ATC", display: 'Budesonide' },
  Code { code: 'R03BA05', system: "ATC", display: 'Fluticasone' },
  Code { code: 'R03BA08', system: "ATC", display: 'Ciclesonide' },
  // Adrenergics in combination with corticosteroids or other drugs
  Code { code: 'R03AK06', system: "ATC", display: 'Salmeterol and fluticasone' },
  Code { code: 'R03AK07', system: "ATC", display: 'Formoterol and budesonide' },
  Code { code: 'R03AK08', system: "ATC", display: 'Formoterol and beclometasone' },
  // Corticosteroids, systemic (for asthma)
  Code { code: 'H02AB06', system: "ATC", display: 'Prednisolone' },
  Code { code: 'H02AB07', system: "ATC", display: 'Prednisone' },
  // Leukotriene receptor antagonists
  Code { code: 'R03DC01', system: "ATC", display: 'Zafirlukast' },
  Code { code: 'R03DC03', system: "ATC", display: 'Montelukast' },
  // Xanthines
  Code { code: 'R03DA05', system: "ATC", display: 'Aminophylline' }
}

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Element, url String):
  singleton from (
    element.extension E where E.url = url
  ).value as FHIR.string

// 取得Condition的診斷碼
define function GetConditionCode(condition Condition):
  if condition.code is not null 
  then (condition.code.coding[0].code.value)
  else null

// 取得MedicationRequest的ATC碼
define function GetMedicationATCCode(medReq MedicationRequest):
  GetExtensionString(medReq, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/medication-atc-code')

// 取得Encounter的就醫類別
define function GetEncounterCaseType(encounter Encounter):
  GetExtensionString(encounter, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/encounter-case-type')

// 檢查是否為氣喘診斷 (J45開頭)
define function IsAsthmaDiagnosis(condition Condition):
  let code: GetConditionCode(condition)
  return code = 'J45' or (code is not null and StartsWith(code, 'J45'))

// 檢查是否為氣喘用藥
define function IsAsthmaMedication(medReq MedicationRequest):
  let atcCode: GetMedicationATCCode(medReq)
  return atcCode in {
    'R03AC02', 'R03AC03', 'R03AC04', 'R03AC06', 'R03AC12', 'R03AC13', 'R03AC16', 'R03AC18',
    'R03BA01', 'R03BA02', 'R03BA05', 'R03BA08',
    'R03AK06', 'R03AK07', 'R03AK08',
    'H02AB06', 'H02AB07',
    'R03DC01', 'R03DC03',
    'R03DA05'
  }

// 檢查是否為住院 (case type 01)
define function IsInpatientEncounter(encounter Encounter):
  GetEncounterCaseType(encounter) = '01'

// 檢查是否為門診 (case type 04)
define function IsOutpatientEncounter(encounter Encounter):
  GetEncounterCaseType(encounter) = '04'

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 所有病患
define "All Patients":
  [Patient]

// 6歲以下病患
define "Patients Under 6 Years":
  "All Patients" P
  let birthDate: P.birthDate.value,
      age: AgeInYearsAt(birthDate, MeasurementPeriodEnd)
  where age < 6

// 觀察期間的Encounter
define "Encounters During Measurement Period":
  [Encounter] E
  where E.period.start during "Measurement Period"

// 觀察期間的Condition
define "Conditions During Measurement Period":
  [Condition] C
  where C.recordedDate during "Measurement Period"

// 觀察期間的MedicationRequest
define "MedicationRequests During Measurement Period":
  [MedicationRequest] M
  where M.authoredOn during "Measurement Period"

// 觀察期間有氣喘診斷的Encounter
define "Asthma Diagnosis Encounters":
  "Encounters During Measurement Period" E
  let conditions: "Conditions During Measurement Period" C 
                  where C.encounter.reference = 'Encounter/' + E.id
                  and IsAsthmaDiagnosis(C)
  where exists(conditions)

// 觀察期間有氣喘用藥的病患
define "Patients With Asthma Medication":
  distinct (
    "MedicationRequests During Measurement Period" M
    where IsAsthmaMedication(M)
    return M.subject.reference.value
  )

// 觀察期間氣喘住院的Encounter (主診斷為J45)
define "Asthma Hospitalization Encounters":
  "Asthma Diagnosis Encounters" E
  let primaryCondition: singleton from (
    "Conditions During Measurement Period" C 
    where C.encounter.reference = 'Encounter/' + E.id
    and IsAsthmaDiagnosis(C)
    and (
      GetExtensionString(C, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/condition-diagnosis-type') = '1'
      or C.category.coding[0].code.value = 'encounter-diagnosis'
    )
  )
  where IsInpatientEncounter(E)
  and primaryCondition is not null

// 觀察期間氣喘門診的Encounter
define "Asthma Outpatient Encounters":
  "Asthma Diagnosis Encounters" E
  where IsOutpatientEncounter(E)

// 分母: 6歲以下兒童曾因氣喘至門住診就醫人數
define "Denominator":
  "Patients Under 6 Years" P
  let patientRef: 'Patient/' + P.id,
      asthmaEncounters: "Asthma Diagnosis Encounters" E 
                        where E.subject.reference.value = patientRef
                        and (IsInpatientEncounter(E) or IsOutpatientEncounter(E))
  where exists(asthmaEncounters)
  or patientRef in "Patients With Asthma Medication"

// 分子: 6歲以下兒童因氣喘住院人數
define "Numerator":
  "Denominator" P
  let patientRef: 'Patient/' + P.id,
      asthmaHospitalizations: "Asthma Hospitalization Encounters" E 
                              where E.subject.reference.value = patientRef
  where exists(asthmaHospitalizations)

// ========================================================================================
// 指標計算
// ========================================================================================

// 分母人數
define "Denominator Count":
  Count("Denominator")

// 分子人數
define "Numerator Count":
  Count("Numerator")

// 指標結果 (百分比)
define "Indicator Result":
  if "Denominator Count" > 0 
  then Round(("Numerator Count" / "Denominator Count") * 100.0, 2)
  else null

// ========================================================================================
// 分層分析
// ========================================================================================

// 依機構別分層
define "Results By Organization":
  "Denominator" P
  let patientRef: 'Patient/' + P.id,
      encounters: "Encounters During Measurement Period" E where E.subject.reference.value = patientRef,
      organization: singleton from (encounters E return E.serviceProvider.reference.value)
  return {
    organization: organization,
    inNumerator: P in "Numerator"
  }

// 依性別分層
define "Results By Gender":
  "Denominator" P
  return {
    gender: P.gender.value,
    inNumerator: P in "Numerator"
  }

// 依年齡分層 (0-2歲, 3-5歲)
define "Results By Age":
  "Denominator" P
  let birthDate: P.birthDate.value,
      age: AgeInYearsAt(birthDate, MeasurementPeriodEnd)
  return {
    ageGroup: 
      if age < 3 then '0-2歲'
      else '3-5歲',
    inNumerator: P in "Numerator"
  }

// 依氣喘嚴重程度分層
define "Results By Asthma Severity":
  "Numerator" P
  let patientRef: 'Patient/' + P.id,
      asthmaConditions: "Conditions During Measurement Period" C 
                        where C.subject.reference.value = patientRef
                        and IsAsthmaDiagnosis(C),
      severityCode: singleton from (asthmaConditions C return GetConditionCode(C))
  return {
    patient: patientRef,
    severity: 
      if severityCode ~ 'J45.2' then 'Mild intermittent'
      else if severityCode ~ 'J45.3' then 'Mild persistent'
      else if severityCode ~ 'J45.4' then 'Moderate persistent'
      else if severityCode ~ 'J45.5' then 'Severe persistent'
      else 'Unspecified'
  }

// 住院次數分布
define "Hospitalization Count Distribution":
  "Numerator" P
  let patientRef: 'Patient/' + P.id,
      hospitalizations: "Asthma Hospitalization Encounters" E 
                        where E.subject.reference.value = patientRef,
      count: Count(hospitalizations)
  return {
    patient: patientRef,
    hospitalizationCount: count,
    countCategory: 
      if count = 1 then '1次'
      else if count = 2 then '2次'
      else if count >= 3 then '3次以上'
      else '0次'
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '六歲以下兒童氣喘住院率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    denominator: "Denominator Count",
    result: "Indicator Result",
    unit: '%'
  }
