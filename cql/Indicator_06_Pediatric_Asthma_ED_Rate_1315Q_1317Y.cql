library Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 十八歲以下氣喘病人急診率
// 指標代碼: 1315 (季度), 1317 (年度)
// 製作日期：2026-01-09
// 製表日期: 114/05/13
// 製表單位: 衛生福利部 中央健康保險署
//
// 【資料時間範圍】
// 查詢期間: 2024-01-01 ~ 2099-12-31 (無限制)
// 統計單位: 每季 (2024Q1-Q4, 2025Q1-Q4, 2026Q1)
// ============================================
//
// 【公式說明】
// 分子: 分母病人中因氣喘而急診就醫者，其急診就醫日期大於(跨院勾稽)為氣喘病患之日期的人數
// 分母: 18歲以下氣喘病患人數(符合下列任一項條件者視為氣喘病患):
//
// 條件a: 有1次(含)以上因氣喘急診就醫
// 條件b: 有1次(含)以上因氣喘住院
// 條件c: 統計期間有因氣喘之門診就醫，且前一年跨院勾稽有4次(含)以上之因氣喘門診就醫，
//        且其中有2次(含)以上有使用任一項氣喘用藥者
//
// (1)氣喘: 主診斷ICD10-CM前三碼為J45
// (2)氣喘用藥: 20種ATC藥品分類碼7
// (3)前一年: 依月往前一年(含當月，若為9801則觀察9702~9801這段期間)
// (4)視為氣喘病患之日期: 符合分母定義之案件最早日期後，取第1筆資料作視為氣喘病患之日期
//
// 排除條件:
// 1.排除代辦案件
// 2.病人年齡 ≤ 18歲
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "ConditionClinicalStatus": 'http://terminology.hl7.org/CodeSystem/condition-clinical'

valueset "Asthma Diagnoses": 'http://nhi.gov.tw/fhir/ValueSet/asthma-diagnoses'
valueset "Asthma Medications": 'http://nhi.gov.tw/fhir/ValueSet/asthma-medications'

// 就醫類型代碼
code "Emergency": 'EMER' from "ActCode" display 'Emergency'
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'
code "Active": 'active' from "ConditionClinicalStatus" display 'Active'

// 氣喘診斷代碼 (ICD-10-CM J45系列)
code "Asthma J45": 'J45' from "ICD10CM" display 'Asthma - 氣喘'
code "Allergic Asthma": 'J45.0' from "ICD10CM" display 'Predominantly allergic asthma - 過敏性氣喘'
code "Nonallergic Asthma": 'J45.1' from "ICD10CM" display 'Nonallergic asthma - 非過敏性氣喘'
code "Mild Intermittent Asthma": 'J45.2' from "ICD10CM" display 'Mild intermittent asthma - 輕度間歇性氣喘'
code "Mild Persistent Asthma": 'J45.3' from "ICD10CM" display 'Mild persistent asthma - 輕度持續性氣喘'
code "Moderate Persistent Asthma": 'J45.4' from "ICD10CM" display 'Moderate persistent asthma - 中度持續性氣喘'
code "Severe Persistent Asthma": 'J45.5' from "ICD10CM" display 'Severe persistent asthma - 重度持續性氣喘'
code "Unspecified Asthma": 'J45.9' from "ICD10CM" display 'Asthma, unspecified - 未明示氣喘'

// 氣喘 SNOMED CT 代碼
code "Asthma SNOMED": '195967001' from "SNOMEDCT" display 'Asthma - 氣喘'

// 氣喘用藥 ATC代碼 (20種)
// β2激動劑 (短效)
code "Salbutamol": 'R03AC02' from "ATC" display 'Salbutamol - 沙丁胺醇'
code "Terbutaline": 'R03AC03' from "ATC" display 'Terbutaline - 特布他林'
code "Fenoterol": 'R03AC04' from "ATC" display 'Fenoterol - 芬特羅'
code "Hexoprenaline": 'R03AC06' from "ATC" display 'Hexoprenaline - 海索普林'

// β2激動劑 (長效)
code "Salmeterol": 'R03AC12' from "ATC" display 'Salmeterol - 沙美特羅'
code "Formoterol": 'R03AC13' from "ATC" display 'Formoterol - 福莫特羅'
code "Indacaterol": 'R03AC16' from "ATC" display 'Indacaterol - 茚達特羅'
code "Vilanterol": 'R03AC18' from "ATC" display 'Vilanterol - 維蘭特羅'

// 吸入型類固醇
code "Beclometasone": 'R03BA01' from "ATC" display 'Beclometasone - 倍氯米松'
code "Budesonide": 'R03BA02' from "ATC" display 'Budesonide - 布地奈德'
code "Fluticasone": 'R03BA05' from "ATC" display 'Fluticasone - 氟替卡松'
code "Ciclesonide": 'R03BA08' from "ATC" display 'Ciclesonide - 環索奈德'

// 複方吸入劑
code "Salmeterol Fluticasone": 'R03AK06' from "ATC" display 'Salmeterol and fluticasone - 沙美特羅+氟替卡松'
code "Formoterol Budesonide": 'R03AK07' from "ATC" display 'Formoterol and budesonide - 福莫特羅+布地奈德'
code "Formoterol Beclometasone": 'R03AK08' from "ATC" display 'Formoterol and beclometasone - 福莫特羅+倍氯米松'

// 口服類固醇
code "Prednisolone": 'H02AB06' from "ATC" display 'Prednisolone - 普賴鬆龍'
code "Prednisone": 'H02AB07' from "ATC" display 'Prednisone - 潑尼松'

// 肥大細胞穩定劑
code "Cromoglicic Acid": 'R03DC01' from "ATC" display 'Cromoglicic acid - 色甘酸鈉'
code "Nedocromil": 'R03DC03' from "ATC" display 'Nedocromil - 奈多羅米'

// 支氣管擴張劑
code "Aminophylline": 'R03DA05' from "ATC" display 'Aminophylline - 氨茶鹼'

// ============================================
// Quarter Definitions (2024-2026)
// ============================================

define "2024Q1 Start": @2024-01-01
define "2024Q1 End": @2024-03-31
define "2024Q2 Start": @2024-04-01
define "2024Q2 End": @2024-06-30
define "2024Q3 Start": @2024-07-01
define "2024Q3 End": @2024-09-30
define "2024Q4 Start": @2024-10-01
define "2024Q4 End": @2024-12-31

define "2025Q1 Start": @2025-01-01
define "2025Q1 End": @2025-03-31
define "2025Q2 Start": @2025-04-01
define "2025Q2 End": @2025-06-30
define "2025Q3 Start": @2025-07-01
define "2025Q3 End": @2025-09-30
define "2025Q4 Start": @2025-10-01
define "2025Q4 End": @2025-12-31

define "2026Q1 Start": @2026-01-01
define "2026Q1 End": @2026-03-31

// Measurement Period (無限制 - Unlimited)
define "Measurement Period Start": @2024-01-01
define "Measurement Period End": @2099-12-31
define "Measurement Period": Interval["Measurement Period Start", "Measurement Period End"]

// ============================================
// Helper Functions
// ============================================

define function GetId(resource FHIR.Resource):
  Last(Split(resource.id, '/'))

define function GetAge(patient FHIR.Patient):
  AgeInYearsAt(patient.birthDate, Today())

define function IsAsthmaCode(code String):
  Substring(code, 0, 3) = 'J45'

define function IsAsthmaMedication(atcCode String):
  atcCode in {
    'R03AC02', 'R03AC03', 'R03AC04', 'R03AC06',
    'R03AC12', 'R03AC13', 'R03AC16', 'R03AC18',
    'R03BA01', 'R03BA02', 'R03BA05', 'R03BA08',
    'R03AK06', 'R03AK07', 'R03AK08',
    'H02AB06', 'H02AB07',
    'R03DC01', 'R03DC03', 'R03DA05'
  }

define function IsAgencyCase(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
        and E.value = true
  )

define function GetPrimaryDiagnosis(encounter FHIR.Encounter):
  Coalesce(
    First(
      encounter.diagnosis D
        where D.use.coding C where C.code.value = 'primary'
        return First(
          [Condition: id in GetId(D.condition.reference)]
        ).code.coding[0].code.value
    ),
    ''
  )

define function IsEmergencyEncounter(encounter FHIR.Encounter):
  encounter.class.code.value = 'EMER'

define function IsOutpatientEncounter(encounter FHIR.Encounter):
  encounter.class.code.value = 'AMB'

define function IsInpatientEncounter(encounter FHIR.Encounter):
  encounter.class.code.value = 'IMP'

define function GetEncounterDate(encounter FHIR.Encounter):
  start of encounter.period

define function OneYearBefore(date Date):
  date - 1 year

define function HasAsthmaMedicationInEncounter(encounter FHIR.Encounter):
  exists (
    [MedicationRequest] MR
      where GetId(MR.encounter.reference) = GetId(encounter)
        and exists (
          MR.medicationCodeableConcept.coding MC
            where IsAsthmaMedication(MC.code.value)
        )
  )

// ============================================
// Data Retrieval
// ============================================

context Patient

define "Patient Age":
  GetAge([Patient])

define "Is Patient Under 18":
  "Patient Age" <= 18

define "All Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and start of E.period in "Measurement Period"
      and not IsAgencyCase(E)

define "Asthma Encounters":
  "All Encounters" E
    where IsAsthmaCode(GetPrimaryDiagnosis(E))

// ============================================
// 條件a: 有1次(含)以上因氣喘急診就醫
// ============================================

define function HasAsthmaEDVisit(quarterStart Date, quarterEnd Date):
  exists (
    "Asthma Encounters" E
      where IsEmergencyEncounter(E)
        and GetEncounterDate(E) in Interval[quarterStart, quarterEnd]
  )

define function FirstAsthmaEDDate(quarterStart Date, quarterEnd Date):
  Min(
    "Asthma Encounters" E
      where IsEmergencyEncounter(E)
        and GetEncounterDate(E) in Interval[quarterStart, quarterEnd]
      return GetEncounterDate(E)
  )

// ============================================
// 條件b: 有1次(含)以上因氣喘住院
// ============================================

define function HasAsthmaInpatient(quarterStart Date, quarterEnd Date):
  exists (
    "Asthma Encounters" E
      where IsInpatientEncounter(E)
        and GetEncounterDate(E) in Interval[quarterStart, quarterEnd]
  )

define function FirstAsthmaInpatientDate(quarterStart Date, quarterEnd Date):
  Min(
    "Asthma Encounters" E
      where IsInpatientEncounter(E)
        and GetEncounterDate(E) in Interval[quarterStart, quarterEnd]
      return GetEncounterDate(E)
  )

// ============================================
// 條件c: 門診+前一年4次+其中2次有用藥
// ============================================

define function HasCurrentQuarterOutpatient(quarterStart Date, quarterEnd Date):
  exists (
    "Asthma Encounters" E
      where IsOutpatientEncounter(E)
        and GetEncounterDate(E) in Interval[quarterStart, quarterEnd]
  )

define function PriorYearOutpatientVisits(quarterStart Date, quarterEnd Date):
  "Asthma Encounters" E
    where IsOutpatientEncounter(E)
      and GetEncounterDate(E) in Interval[OneYearBefore(quarterStart), quarterEnd]

define function PriorYearOutpatientCount(quarterStart Date, quarterEnd Date):
  Count(PriorYearOutpatientVisits(quarterStart, quarterEnd))

define function PriorYearMedicationVisitCount(quarterStart Date, quarterEnd Date):
  Count(
    PriorYearOutpatientVisits(quarterStart, quarterEnd) E
      where HasAsthmaMedicationInEncounter(E)
  )

define function MeetsConditionC(quarterStart Date, quarterEnd Date):
  HasCurrentQuarterOutpatient(quarterStart, quarterEnd)
    and PriorYearOutpatientCount(quarterStart, quarterEnd) >= 4
    and PriorYearMedicationVisitCount(quarterStart, quarterEnd) >= 2

define function FirstAsthmaOutpatientDate(quarterStart Date, quarterEnd Date):
  Min(
    "Asthma Encounters" E
      where IsOutpatientEncounter(E)
        and GetEncounterDate(E) in Interval[quarterStart, quarterEnd]
      return GetEncounterDate(E)
  )

// ============================================
// 分母: 18歲以下氣喘病患 (符合a或b或c)
// ============================================

define function IsAsthmaPatient(quarterStart Date, quarterEnd Date):
  "Is Patient Under 18"
    and (
      HasAsthmaEDVisit(quarterStart, quarterEnd)
        or HasAsthmaInpatient(quarterStart, quarterEnd)
        or MeetsConditionC(quarterStart, quarterEnd)
    )

define function AsthmaPatientDate(quarterStart Date, quarterEnd Date):
  if IsAsthmaPatient(quarterStart, quarterEnd) then
    Coalesce(
      Min({
        FirstAsthmaEDDate(quarterStart, quarterEnd),
        FirstAsthmaInpatientDate(quarterStart, quarterEnd),
        FirstAsthmaOutpatientDate(quarterStart, quarterEnd)
      }),
      quarterStart
    )
  else
    null

// ============================================
// 分子: 急診日期 > 氣喘病患日期
// ============================================

define function HasEDAfterAsthmaDate(quarterStart Date, quarterEnd Date):
  if IsAsthmaPatient(quarterStart, quarterEnd) then
    exists (
      "Asthma Encounters" E
        where IsEmergencyEncounter(E)
          and GetEncounterDate(E) > AsthmaPatientDate(quarterStart, quarterEnd)
          and GetEncounterDate(E) <= quarterEnd
    )
  else
    false

// ============================================
// 2024Q1 Statistics
// ============================================

define "2024Q1 Is Asthma Patient":
  IsAsthmaPatient("2024Q1 Start", "2024Q1 End")

define "2024Q1 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2024Q1 Start", "2024Q1 End")

// ============================================
// 2024Q2 Statistics
// ============================================

define "2024Q2 Is Asthma Patient":
  IsAsthmaPatient("2024Q2 Start", "2024Q2 End")

define "2024Q2 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2024Q2 Start", "2024Q2 End")

// ============================================
// 2024Q3 Statistics
// ============================================

define "2024Q3 Is Asthma Patient":
  IsAsthmaPatient("2024Q3 Start", "2024Q3 End")

define "2024Q3 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2024Q3 Start", "2024Q3 End")

// ============================================
// 2024Q4 Statistics
// ============================================

define "2024Q4 Is Asthma Patient":
  IsAsthmaPatient("2024Q4 Start", "2024Q4 End")

define "2024Q4 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2024Q4 Start", "2024Q4 End")

// ============================================
// 2025Q1 Statistics
// ============================================

define "2025Q1 Is Asthma Patient":
  IsAsthmaPatient("2025Q1 Start", "2025Q1 End")

define "2025Q1 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2025Q1 Start", "2025Q1 End")

// ============================================
// 2025Q2 Statistics
// ============================================

define "2025Q2 Is Asthma Patient":
  IsAsthmaPatient("2025Q2 Start", "2025Q2 End")

define "2025Q2 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2025Q2 Start", "2025Q2 End")

// ============================================
// 2025Q3 Statistics
// ============================================

define "2025Q3 Is Asthma Patient":
  IsAsthmaPatient("2025Q3 Start", "2025Q3 End")

define "2025Q3 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2025Q3 Start", "2025Q3 End")

// ============================================
// 2025Q4 Statistics
// ============================================

define "2025Q4 Is Asthma Patient":
  IsAsthmaPatient("2025Q4 Start", "2025Q4 End")

define "2025Q4 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2025Q4 Start", "2025Q4 End")

// ============================================
// 2026Q1 Statistics
// ============================================

define "2026Q1 Is Asthma Patient":
  IsAsthmaPatient("2026Q1 Start", "2026Q1 End")

define "2026Q1 Has ED After Diagnosis":
  HasEDAfterAsthmaDate("2026Q1 Start", "2026Q1 End")

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  {
    indicatorCode: '1315/1317',
    indicatorName: '十八歲以下氣喘病人急診率',
    indicatorNameEn: 'Emergency Visit Rate for Asthma Patients Under 18',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/05/13',
    version: '1.0.0',
    asthmaCriteria: 'ICD10-CM J45* (主診斷前三碼)',
    denominatorCriteria: 'a)≥1次急診 or b)≥1次住院 or c)當期門診+前一年≥4次門診+其中≥2次有用藥',
    numeratorCriteria: '分母病患中急診日期>氣喘病患日期',
    medicationCount: '20種ATC氣喘用藥',
    ageLimit: '≤18歲'
  }
