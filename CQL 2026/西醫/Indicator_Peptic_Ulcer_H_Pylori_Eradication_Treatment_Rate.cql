/**
 * 指標名稱: 消化性潰瘍新病人執行幽門桿菌清除治療比率
 * 指標類別: 基層常見疾病照護指標
 * 計算頻率: 每季
 * 計算公式: (分子/分母) x 100%
 * 
 * 分子: 消化性潰瘍新病患中，合併使用消化性潰瘍用藥(註2)及1種以上抗生素，持續使用7天以上之人數
 * 分母: 消化性潰瘍新病患(註1)人數
 * 
 * 註1: 消化性潰瘍新病人定義
 * 在觀察期間，同時符合下列二項條件者，視為消化性潰瘍新病人：
 * 1. 前一年沒有因消化性潰瘍(主、次診斷前三碼為K25-K28)或重大傷病身分(申報部分負擔代碼001)而就醫(門診、急診或住院)者
 * 2. 初次使用消化性潰瘍用藥且前4個月內有在基層診所執行上消化道泛內視鏡檢查28016C或33006B上消化道攝影之門診個案
 * 
 * 註2: 消化性潰瘍用藥
 * 1. 制酸懸浮劑: 藥理分類代碼為560400或560499且藥品代碼最後二碼不為00或G0，再排除下列成分代碼56040001500、9600065500、
 *    4008000700(僅排除單方劑型)、56040002500(僅排除單方劑型)、5604002501(僅排除單方劑型)、5604002900(僅排除單方劑型)、
 *    5604001200(僅排除單方劑型)、5612001300(僅排除單方劑型)
 * 2. 組織胺受器拮抗劑(H2RA): 藥理分類代碼為560500之藥品品項
 * 3. 氫離子幫浦抑制劑(PPI): 藥理分類代碼為560900之藥品品項
 * 4. 細胞保護劑及其他消化性潰瘍用藥: 藥理分類代碼為560700之藥品
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_Peptic_Ulcer_H_Pylori_Eradication_Treatment_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/case-type-tw'
codesystem "TWMajorIllnessCode": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/major-illness-code-tw'
codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 消化性潰瘍診斷碼 (K25-K28)
define "Peptic Ulcer Diagnosis Codes": {
  Code { code: 'K25', system: "ICD10CM", display: 'Gastric ulcer' },
  Code { code: 'K25.0', system: "ICD10CM", display: 'Gastric ulcer, acute with hemorrhage' },
  Code { code: 'K25.1', system: "ICD10CM", display: 'Gastric ulcer, acute with perforation' },
  Code { code: 'K25.2', system: "ICD10CM", display: 'Gastric ulcer, acute with both hemorrhage and perforation' },
  Code { code: 'K25.3', system: "ICD10CM", display: 'Gastric ulcer, acute without hemorrhage or perforation' },
  Code { code: 'K25.4', system: "ICD10CM", display: 'Gastric ulcer, chronic with hemorrhage' },
  Code { code: 'K25.5', system: "ICD10CM", display: 'Gastric ulcer, chronic with perforation' },
  Code { code: 'K25.6', system: "ICD10CM", display: 'Gastric ulcer, chronic with both hemorrhage and perforation' },
  Code { code: 'K25.7', system: "ICD10CM", display: 'Gastric ulcer, chronic without hemorrhage or perforation' },
  Code { code: 'K25.9', system: "ICD10CM", display: 'Gastric ulcer, unspecified as acute or chronic' },
  Code { code: 'K26', system: "ICD10CM", display: 'Duodenal ulcer' },
  Code { code: 'K26.0', system: "ICD10CM", display: 'Duodenal ulcer, acute with hemorrhage' },
  Code { code: 'K26.1', system: "ICD10CM", display: 'Duodenal ulcer, acute with perforation' },
  Code { code: 'K26.2', system: "ICD10CM", display: 'Duodenal ulcer, acute with both hemorrhage and perforation' },
  Code { code: 'K26.3', system: "ICD10CM", display: 'Duodenal ulcer, acute without hemorrhage or perforation' },
  Code { code: 'K26.4', system: "ICD10CM", display: 'Duodenal ulcer, chronic with hemorrhage' },
  Code { code: 'K26.5', system: "ICD10CM", display: 'Duodenal ulcer, chronic with perforation' },
  Code { code: 'K26.6', system: "ICD10CM", display: 'Duodenal ulcer, chronic with both hemorrhage and perforation' },
  Code { code: 'K26.7', system: "ICD10CM", display: 'Duodenal ulcer, chronic without hemorrhage or perforation' },
  Code { code: 'K26.9', system: "ICD10CM", display: 'Duodenal ulcer, unspecified as acute or chronic' },
  Code { code: 'K27', system: "ICD10CM", display: 'Peptic ulcer, site unspecified' },
  Code { code: 'K27.0', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, acute with hemorrhage' },
  Code { code: 'K27.1', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, acute with perforation' },
  Code { code: 'K27.2', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, acute with both hemorrhage and perforation' },
  Code { code: 'K27.3', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, acute without hemorrhage or perforation' },
  Code { code: 'K27.4', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, chronic with hemorrhage' },
  Code { code: 'K27.5', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, chronic with perforation' },
  Code { code: 'K27.6', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, chronic with both hemorrhage and perforation' },
  Code { code: 'K27.7', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, chronic without hemorrhage or perforation' },
  Code { code: 'K27.9', system: "ICD10CM", display: 'Peptic ulcer, site unspecified, unspecified as acute or chronic' },
  Code { code: 'K28', system: "ICD10CM", display: 'Gastrojejunal ulcer' },
  Code { code: 'K28.0', system: "ICD10CM", display: 'Gastrojejunal ulcer, acute with hemorrhage' },
  Code { code: 'K28.1', system: "ICD10CM", display: 'Gastrojejunal ulcer, acute with perforation' },
  Code { code: 'K28.2', system: "ICD10CM", display: 'Gastrojejunal ulcer, acute with both hemorrhage and perforation' },
  Code { code: 'K28.3', system: "ICD10CM", display: 'Gastrojejunal ulcer, acute without hemorrhage or perforation' },
  Code { code: 'K28.4', system: "ICD10CM", display: 'Gastrojejunal ulcer, chronic with hemorrhage' },
  Code { code: 'K28.5', system: "ICD10CM", display: 'Gastrojejunal ulcer, chronic with perforation' },
  Code { code: 'K28.6', system: "ICD10CM", display: 'Gastrojejunal ulcer, chronic with both hemorrhage and perforation' },
  Code { code: 'K28.7', system: "ICD10CM", display: 'Gastrojejunal ulcer, chronic without hemorrhage or perforation' },
  Code { code: 'K28.9', system: "ICD10CM", display: 'Gastrojejunal ulcer, unspecified as acute or chronic' }
}

// 上消化道內視鏡檢查
define "Upper GI Endoscopy Procedure Code": 
  Code { code: '28016C', system: "TWProcedure", display: '上消化道泛內視鏡檢查' }

// 上消化道攝影
define "Upper GI Imaging Procedure Code": 
  Code { code: '33006B', system: "TWProcedure", display: '上消化道攝影' }

// 重大傷病代碼001
define "Major Illness Code 001": 
  Code { code: '001', system: "TWMajorIllnessCode", display: '需積極或長期治療之癌症' }

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

// 取得MedicationRequest的藥品代碼
define function GetMedicationCode(medReq MedicationRequest):
  if medReq.medication is FHIR.CodeableConcept
  then (medReq.medication as FHIR.CodeableConcept).coding[0].code.value
  else null

// 取得MedicationRequest的藥理分類代碼
define function GetPharmacologicalClassCode(medReq MedicationRequest):
  GetExtensionString(medReq, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/medication-pharmacological-class')

// 取得MedicationRequest的成分代碼
define function GetIngredientCode(medReq MedicationRequest):
  GetExtensionString(medReq, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/medication-ingredient-code')

// 取得Encounter的就醫類別
define function GetEncounterCaseType(encounter Encounter):
  GetExtensionString(encounter, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/encounter-case-type')

// 取得Encounter的機構層級
define function GetOrganizationLevel(encounter Encounter):
  GetExtensionString(encounter, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/organization-level')

// 檢查是否為消化性潰瘍診斷
define function IsPepticUlcerDiagnosis(condition Condition):
  GetConditionCode(condition) in { 'K25', 'K26', 'K27', 'K28' }
  or GetConditionCode(condition) ~ 'K25.'
  or GetConditionCode(condition) ~ 'K26.'
  or GetConditionCode(condition) ~ 'K27.'
  or GetConditionCode(condition) ~ 'K28.'

// 檢查是否為制酸懸浮劑
define function IsAntacid(medReq MedicationRequest):
  let pharmacologicalClass: GetPharmacologicalClassCode(medReq),
      medicationCode: GetMedicationCode(medReq),
      ingredientCode: GetIngredientCode(medReq),
      lastTwoDigits: if medicationCode is not null and Length(medicationCode) >= 2 
                     then Substring(medicationCode, Length(medicationCode) - 2, 2)
                     else null
  return 
    (pharmacologicalClass in { '560400', '560499' })
    and lastTwoDigits not in { '00', 'G0' }
    and ingredientCode not in { 
      '56040001500', '9600065500', 
      '4008000700', // 僅排除單方劑型
      '56040002500', // 僅排除單方劑型
      '5604002501', // 僅排除單方劑型
      '5604002900', // 僅排除單方劑型
      '5604001200', // 僅排除單方劑型
      '5612001300'  // 僅排除單方劑型
    }

// 檢查是否為H2RA
define function IsH2RA(medReq MedicationRequest):
  GetPharmacologicalClassCode(medReq) = '560500'

// 檢查是否為PPI
define function IsPPI(medReq MedicationRequest):
  GetPharmacologicalClassCode(medReq) = '560900'

// 檢查是否為細胞保護劑
define function IsCytoprotective(medReq MedicationRequest):
  GetPharmacologicalClassCode(medReq) = '560700'

// 檢查是否為消化性潰瘍用藥
define function IsPepticUlcerMedication(medReq MedicationRequest):
  IsAntacid(medReq) or IsH2RA(medReq) or IsPPI(medReq) or IsCytoprotective(medReq)

// 檢查是否為抗生素 (常用於幽門桿菌清除治療)
// 常見方案: Clarithromycin, Amoxicillin, Metronidazole, Tetracycline, Levofloxacin
define function IsAntibioticForHPylori(medReq MedicationRequest):
  let atcCode: GetExtensionString(medReq, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/medication-atc-code')
  return 
    atcCode in { 
      'J01FA09', // Clarithromycin
      'J01CA04', // Amoxicillin
      'J01XD01', // Metronidazole
      'J01AA07', // Tetracycline
      'J01MA02', // Levofloxacin
      'J01MA12'  // Levofloxacin
    }
    or atcCode ~ 'J01FA09' // Clarithromycin系列
    or atcCode ~ 'J01CA04' // Amoxicillin系列
    or atcCode ~ 'J01XD01' // Metronidazole系列
    or atcCode ~ 'J01AA07' // Tetracycline系列
    or atcCode ~ 'J01MA'   // Fluoroquinolones

// 計算用藥持續天數
define function GetMedicationDurationDays(medReq MedicationRequest):
  if medReq.dispenseRequest is not null 
     and medReq.dispenseRequest.expectedSupplyDuration is not null
  then 
    medReq.dispenseRequest.expectedSupplyDuration.value.value
  else 
    null

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 前一年期間
define "Prior Year Period":
  Interval[
    MeasurementPeriodStart - 1 year,
    MeasurementPeriodStart - 1 day
  ]

// 前4個月期間
define "Prior 4 Months Period":
  Interval[
    MeasurementPeriodStart - 4 months,
    MeasurementPeriodEnd
  ]

// 所有病患
define "All Patients":
  [Patient]

// 觀察期間的Encounter
define "Encounters During Measurement Period":
  [Encounter] E
  where E.period.start during "Measurement Period"

// 前一年的Encounter
define "Encounters During Prior Year":
  [Encounter] E
  where E.period.start during "Prior Year Period"

// 觀察期間的Condition
define "Conditions During Measurement Period":
  [Condition] C
  where C.recordedDate during "Measurement Period"

// 前一年的Condition
define "Conditions During Prior Year":
  [Condition] C
  where C.recordedDate during "Prior Year Period"

// 觀察期間的MedicationRequest
define "MedicationRequests During Measurement Period":
  [MedicationRequest] M
  where M.authoredOn during "Measurement Period"

// 前一年的MedicationRequest
define "MedicationRequests During Prior Year":
  [MedicationRequest] M
  where M.authoredOn during "Prior Year Period"

// 前4個月的Procedure
define "Procedures During Prior 4 Months":
  [Procedure] P
  where P.performed during "Prior 4 Months Period"

// 前一年有消化性潰瘍診斷的病患
define "Patients With Prior Year Peptic Ulcer Diagnosis":
  distinct (
    "Conditions During Prior Year" C
    where IsPepticUlcerDiagnosis(C)
    return C.subject.reference.value
  )

// 前一年有重大傷病001的病患
define "Patients With Prior Year Major Illness 001":
  distinct (
    "Encounters During Prior Year" E
    where GetExtensionString(E, 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/major-illness-code') = '001'
    return E.subject.reference.value
  )

// 前4個月有上消化道檢查的病患 (基層診所)
define "Patients With Upper GI Exam In Prior 4 Months At Primary Care":
  distinct (
    "Procedures During Prior 4 Months" P
    let encounter: singleton from ([Encounter] E where 'Encounter/' + E.id = P.encounter.reference)
    where (
      P.code.coding[0].code ~ "Upper GI Endoscopy Procedure Code".code
      or P.code.coding[0].code ~ "Upper GI Imaging Procedure Code".code
    )
    and GetOrganizationLevel(encounter) = '基層'
    and GetEncounterCaseType(encounter) = '04' // 門診
    return P.subject.reference.value
  )

// 觀察期間首次使用消化性潰瘍用藥的病患
define "Patients With First Peptic Ulcer Medication":
  distinct (
    "MedicationRequests During Measurement Period" M
    let priorMeds: "MedicationRequests During Prior Year" PM 
                   where PM.subject.reference = M.subject.reference
                   and IsPepticUlcerMedication(PM)
    where IsPepticUlcerMedication(M)
    and not exists(priorMeds)
    return M.subject.reference.value
  )

// 分母: 消化性潰瘍新病患
define "Denominator":
  "All Patients" P
  let patientRef: 'Patient/' + P.id
  where patientRef not in "Patients With Prior Year Peptic Ulcer Diagnosis"
  and patientRef not in "Patients With Prior Year Major Illness 001"
  and patientRef in "Patients With First Peptic Ulcer Medication"
  and patientRef in "Patients With Upper GI Exam In Prior 4 Months At Primary Care"

// 觀察期間使用消化性潰瘍用藥的MedicationRequest
define "Peptic Ulcer Medications During Measurement Period":
  "MedicationRequests During Measurement Period" M
  where IsPepticUlcerMedication(M)

// 觀察期間使用抗生素且持續≥7天的MedicationRequest
define "Antibiotics For H Pylori During Measurement Period":
  "MedicationRequests During Measurement Period" M
  where IsAntibioticForHPylori(M)
  and GetMedicationDurationDays(M) >= 7

// 分子: 新病患中合併使用消化性潰瘍用藥及抗生素≥7天的病患
define "Numerator":
  "Denominator" P
  let patientRef: 'Patient/' + P.id,
      pepticUlcerMeds: "Peptic Ulcer Medications During Measurement Period" M 
                       where M.subject.reference.value = patientRef,
      antibiotics: "Antibiotics For H Pylori During Measurement Period" M 
                   where M.subject.reference.value = patientRef
  where exists(pepticUlcerMeds)
  and exists(antibiotics)

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

// 依年齡分層
define "Results By Age":
  "Denominator" P
  let birthDate: P.birthDate.value,
      age: AgeInYearsAt(birthDate, MeasurementPeriodStart)
  return {
    ageGroup: 
      if age < 40 then '<40'
      else if age < 50 then '40-49'
      else if age < 60 then '50-59'
      else if age < 70 then '60-69'
      else '>=70',
    inNumerator: P in "Numerator"
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '消化性潰瘍新病人執行幽門桿菌清除治療比率',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    numerator: "Numerator Count",
    denominator: "Denominator Count",
    result: "Indicator Result",
    unit: '%'
  }
