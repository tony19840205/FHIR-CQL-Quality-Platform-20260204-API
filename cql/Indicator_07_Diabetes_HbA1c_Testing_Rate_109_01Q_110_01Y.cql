library Indicator_07_Diabetes_HbA1c_Testing_Rate_109_01Q_110_01Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白執行率
// 指標代碼: 109.01 (季度), 110.01 (年度)
// 製作日期：2026-01-09
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署
//
// 【資料時間範圍】
// 查詢期間: 2024-01-01 ~ 2099-12-31 (無限制)
// 統計單位: 每季 (2024Q1-Q4, 2025Q1-Q4, 2026Q1)
// ============================================
//
// 【公式說明】
// 分子: 分母ID中，在統計期間於門診有執行醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)檢驗人數
// 分母: 統計累計日當年度1月至當期門診主次診斷為糖尿病且使用糖尿病用藥之病人數
//
// (1)糖尿病: 任一主、次診斷之ICD-10-CM前三碼為E08-E13之門診案件
// (2)糖尿病用藥: 指ATC前三碼為A10
// (3)醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)案件: 申報號分代碼前五碼為09006或09139之案件
// (4)計算符合分母條件之ID時，主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件
// (5)統計期間: 計算符合分子之ID時，從分母的ID繼續觀察，只要該ID於統計期間有執行醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)檢驗即成立
//
// 排除條件:
// 1.排除代辦案件
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "LOINC": 'http://loinc.org'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "ObservationStatus": 'http://hl7.org/fhir/observation-status'

valueset "Diabetes Diagnoses": 'http://nhi.gov.tw/fhir/ValueSet/diabetes-diagnoses'
valueset "Diabetes Medications": 'http://nhi.gov.tw/fhir/ValueSet/diabetes-medications'
valueset "HbA1c Tests": 'http://nhi.gov.tw/fhir/ValueSet/hba1c-tests'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'
code "Final": 'final' from "ObservationStatus" display 'Final'

// 糖尿病診斷代碼 (ICD-10-CM E08-E13)
code "Diabetes E08": 'E08' from "ICD10CM" display 'Diabetes mellitus due to underlying condition - 其他特定的糖尿病'
code "Diabetes E09": 'E09' from "ICD10CM" display 'Drug or chemical induced diabetes mellitus - 藥物或化學物質引起的糖尿病'
code "Diabetes E10": 'E10' from "ICD10CM" display 'Type 1 diabetes mellitus - 第1型糖尿病'
code "Diabetes E11": 'E11' from "ICD10CM" display 'Type 2 diabetes mellitus - 第2型糖尿病'
code "Diabetes E12": 'E12' from "ICD10CM" display 'Malnutrition-related diabetes mellitus - 營養不良相關糖尿病'
code "Diabetes E13": 'E13' from "ICD10CM" display 'Other specified diabetes mellitus - 其他特定的糖尿病'

// 糖尿病 SNOMED CT 代碼
code "Diabetes SNOMED": '73211009' from "SNOMEDCT" display 'Diabetes mellitus - 糖尿病'
code "Type 1 Diabetes SNOMED": '46635009' from "SNOMEDCT" display 'Type 1 diabetes mellitus - 第1型糖尿病'
code "Type 2 Diabetes SNOMED": '44054006' from "SNOMEDCT" display 'Type 2 diabetes mellitus - 第2型糖尿病'

// 糖尿病用藥 ATC代碼 (A10系列)
code "Diabetes Medication A10": 'A10' from "ATC" display 'Drugs used in diabetes - 糖尿病用藥'
code "Insulin A10A": 'A10A' from "ATC" display 'Insulins and analogues - 胰島素及其類似物'
code "Oral Hypoglycemic A10B": 'A10B' from "ATC" display 'Blood glucose lowering drugs, excl. insulins - 降血糖藥(不含胰島素)'

// HbA1c檢驗 LOINC代碼
code "HbA1c LOINC": '4548-4' from "LOINC" display 'Hemoglobin A1c/Hemoglobin.total in Blood - 醣化血紅素'
code "HbA1c HPLC": '17856-6' from "LOINC" display 'Hemoglobin A1c/Hemoglobin.total in Blood by HPLC'
code "HbA1c IFCC": '59261-8' from "LOINC" display 'Hemoglobin A1c/Hemoglobin.total in Blood by IFCC protocol'

// Glycated Albumin檢驗 LOINC代碼
code "Glycated Albumin LOINC": '62388-4' from "LOINC" display 'Glycated albumin/Albumin.total in Serum or Plasma - 糖化白蛋白'

// 健保檢驗代碼
code "HbA1c NHI": '09006' from "NHI_PROCEDURE" display 'HbA1c - 醣化血紅素檢驗'
code "Glycated Albumin NHI": '09139' from "NHI_PROCEDURE" display 'Glycated Albumin - 糖化白蛋白檢驗'

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

define function IsDiabetesCode(code String):
  Substring(code, 0, 3) in {'E08', 'E09', 'E10', 'E11', 'E12', 'E13'}

define function IsDiabetesMedication(atcCode String):
  Substring(atcCode, 0, 3) = 'A10'

define function IsHbA1cOrGlycatedAlbuminTest(testCode String):
  Substring(testCode, 0, 5) in {'09006', '09139'}

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
        where exists (D.use.coding C where C.code.value = 'primary')
        return First(
          [Condition: id in GetId(D.condition.reference)]
        ).code.coding[0].code.value
    ),
    ''
  )

define function GetSecondaryDiagnoses(encounter FHIR.Encounter):
  encounter.diagnosis D
    where exists (D.use.coding C where C.code.value = 'secondary')
    return First(
      [Condition: id in GetId(D.condition.reference)]
    ).code.coding[0].code.value

define function HasDiabetesDiagnosis(encounter FHIR.Encounter):
  IsDiabetesCode(GetPrimaryDiagnosis(encounter))
    or exists (
      GetSecondaryDiagnoses(encounter) SD
        where IsDiabetesCode(SD)
    )

define function HasDiabetesMedicationInEncounter(encounter FHIR.Encounter):
  exists (
    [MedicationRequest] MR
      where GetId(MR.encounter.reference) = GetId(encounter)
        and exists (
          MR.medicationCodeableConcept.coding MC
            where IsDiabetesMedication(MC.code.value)
        )
        and MR.status.value = 'completed'
  )

define function GetEncounterDate(encounter FHIR.Encounter):
  start of encounter.period

define function YearStart(quarterEnd Date):
  Date(year from quarterEnd, 1, 1)

// ============================================
// Data Retrieval
// ============================================

context Patient

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and start of E.period in "Measurement Period"
      and not IsAgencyCase(E)

define "Diabetes Encounters":
  "Outpatient Encounters" E
    where HasDiabetesDiagnosis(E)

define "Diabetes Encounters With Medication":
  "Diabetes Encounters" E
    where HasDiabetesMedicationInEncounter(E)

define "HbA1c Or Glycated Albumin Observations":
  [Observation] O
    where O.status.value in {'final', 'amended', 'corrected'}
      and (
        exists (
          O.code.coding C
            where C.code.value in {'4548-4', '17856-6', '59261-8', '62388-4'}
        )
        or exists (
          O.extension E
            where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/lab-code'
              and (E.value as FHIR.Coding).code.value in {'09006', '09139'}
        )
      )
      and start of O.effective in "Measurement Period"

// ============================================
// 分母: 門診主次診斷為糖尿病且使用糖尿病用藥之病人
// ============================================

define function DiabetesPatientsInPeriod(periodStart Date, periodEnd Date):
  "Diabetes Encounters With Medication" E
    where GetEncounterDate(E) in Interval[YearStart(periodEnd), periodEnd]

define function DiabetesPatientsCountInPeriod(periodStart Date, periodEnd Date):
  Count(
    distinct (
      DiabetesPatientsInPeriod(periodStart, periodEnd) E
        return GetId([Patient])
    )
  )

// ============================================
// 分子: 有執行HbA1c或Glycated Albumin檢驗的糖尿病病人
// ============================================

define function PatientsWithTestInPeriod(periodStart Date, periodEnd Date):
  exists (
    DiabetesPatientsInPeriod(periodStart, periodEnd)
  )
    and exists (
      "HbA1c Or Glycated Albumin Observations" O
        where start of O.effective in Interval[periodStart, periodEnd]
    )

define function PatientsWithTestCountInPeriod(periodStart Date, periodEnd Date):
  if exists (DiabetesPatientsInPeriod(periodStart, periodEnd)) then
    if exists (
      "HbA1c Or Glycated Albumin Observations" O
        where start of O.effective in Interval[periodStart, periodEnd]
    ) then 1
    else 0
  else 0

// ============================================
// 2024Q1 Statistics
// ============================================

define "2024Q1 Denominator":
  DiabetesPatientsCountInPeriod("2024Q1 Start", "2024Q1 End")

define "2024Q1 Numerator":
  PatientsWithTestCountInPeriod("2024Q1 Start", "2024Q1 End")

define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then
    ("2024Q1 Numerator" / "2024Q1 Denominator") * 100
  else null

// ============================================
// 2024Q2 Statistics
// ============================================

define "2024Q2 Denominator":
  DiabetesPatientsCountInPeriod("2024Q2 Start", "2024Q2 End")

define "2024Q2 Numerator":
  PatientsWithTestCountInPeriod("2024Q2 Start", "2024Q2 End")

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then
    ("2024Q2 Numerator" / "2024Q2 Denominator") * 100
  else null

// ============================================
// 2024Q3 Statistics
// ============================================

define "2024Q3 Denominator":
  DiabetesPatientsCountInPeriod("2024Q3 Start", "2024Q3 End")

define "2024Q3 Numerator":
  PatientsWithTestCountInPeriod("2024Q3 Start", "2024Q3 End")

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then
    ("2024Q3 Numerator" / "2024Q3 Denominator") * 100
  else null

// ============================================
// 2024Q4 Statistics
// ============================================

define "2024Q4 Denominator":
  DiabetesPatientsCountInPeriod("2024Q4 Start", "2024Q4 End")

define "2024Q4 Numerator":
  PatientsWithTestCountInPeriod("2024Q4 Start", "2024Q4 End")

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then
    ("2024Q4 Numerator" / "2024Q4 Denominator") * 100
  else null

// ============================================
// 2025Q1 Statistics
// ============================================

define "2025Q1 Denominator":
  DiabetesPatientsCountInPeriod("2025Q1 Start", "2025Q1 End")

define "2025Q1 Numerator":
  PatientsWithTestCountInPeriod("2025Q1 Start", "2025Q1 End")

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then
    ("2025Q1 Numerator" / "2025Q1 Denominator") * 100
  else null

// ============================================
// 2025Q2 Statistics
// ============================================

define "2025Q2 Denominator":
  DiabetesPatientsCountInPeriod("2025Q2 Start", "2025Q2 End")

define "2025Q2 Numerator":
  PatientsWithTestCountInPeriod("2025Q2 Start", "2025Q2 End")

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then
    ("2025Q2 Numerator" / "2025Q2 Denominator") * 100
  else null

// ============================================
// 2025Q3 Statistics
// ============================================

define "2025Q3 Denominator":
  DiabetesPatientsCountInPeriod("2025Q3 Start", "2025Q3 End")

define "2025Q3 Numerator":
  PatientsWithTestCountInPeriod("2025Q3 Start", "2025Q3 End")

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then
    ("2025Q3 Numerator" / "2025Q3 Denominator") * 100
  else null

// ============================================
// 2025Q4 Statistics
// ============================================

define "2025Q4 Denominator":
  DiabetesPatientsCountInPeriod("2025Q4 Start", "2025Q4 End")

define "2025Q4 Numerator":
  PatientsWithTestCountInPeriod("2025Q4 Start", "2025Q4 End")

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then
    ("2025Q4 Numerator" / "2025Q4 Denominator") * 100
  else null

// ============================================
// 2026Q1 Statistics
// ============================================

define "2026Q1 Denominator":
  DiabetesPatientsCountInPeriod("2026Q1 Start", "2026Q1 End")

define "2026Q1 Numerator":
  PatientsWithTestCountInPeriod("2026Q1 Start", "2026Q1 End")

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then
    ("2026Q1 Numerator" / "2026Q1 Denominator") * 100
  else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  {
    indicatorCode: '109.01/110.01',
    indicatorName: '糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白執行率',
    indicatorNameEn: 'Performance Rate of HbA1c or Glycated Albumin Testing for Diabetes Patients',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/11/06',
    version: '1.0.0',
    diabetesCriteria: 'ICD10-CM E08-E13 (主次診斷前三碼)',
    medicationCriteria: 'ATC A10* (糖尿病用藥)',
    testCriteria: '09006(HbA1c), 09139(Glycated Albumin)',
    denominatorCriteria: '門診主次診斷為糖尿病且使用糖尿病用藥(同處方案件)',
    numeratorCriteria: '分母病患中於統計期間有執行HbA1c或Glycated Albumin檢驗',
    keyRequirement: '診斷與用藥需發生在同一處方案件'
  }
 * 
 * 公式說明:
 * 糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)執行率 = 
 *     分子: 分母ID中，在統計期間於門診有執行醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)檢驗人數
 *     分母: 門診主次診斷為糖尿病且使用糖尿病用藥之病人數
 * 
 * (1)糖尿病：任一主、次診斷之ICD-10-CM前三碼為E08-E13之門診案件。
 * (2)糖尿病用藥：指ATC前三碼為A10。
 * (3)醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)案件後指申報號分代碼前五碼為09006或09139之案件。
 * (4)計算符合分母條件之ID時，主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件。
 * (5)統計期間：計算符合分子之ID時，從分母的ID繼續觀察，只要該ID於統計期間有執行醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)檢驗即成立。
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 就醫紀錄 (門診)
 * - Condition: 診斷資料 (主次診斷，糖尿病E08-E13)
 * - MedicationRequest: 藥品處方 (糖尿病用藥A10)
 * - Observation: 檢驗數據 (HbA1c或glycated albumin)
 * - Claim: 醫療費用申報 (檢驗項目代碼09006/09139)
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 109.01 (季度)
    -- 110.01 (年度)

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- E08-E13: 糖尿病相關診斷
    -- E08: 其他特定的糖尿病
    -- E09: 藥物或化學物質引起的糖尿病
    -- E10: 第1型糖尿病
    -- E11: 第2型糖尿病
    -- E13: 其他特定的糖尿病

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 73211009: Diabetes mellitus (糖尿病)
    -- 46635009: Type 1 diabetes mellitus (第1型糖尿病)
    -- 44054006: Type 2 diabetes mellitus (第2型糖尿病)
    -- 4548001: Hemoglobin A1c (醣化血紅素)
    -- 739681000: Glycated albumin (糖化白蛋白)

codesystem "ATC": 'http://www.whocc.no/atc'
    -- 解剖治療化學分類系統 (ATC)
    -- A10: 糖尿病用藥
    -- A10A: 胰島素及其類似物
    -- A10B: 降血糖藥，不包括胰島素

codesystem "LOINC": 'http://loinc.org'
    -- 邏輯觀察識別碼命名和編碼系統 (LOINC)
    -- 4548-4: Hemoglobin A1c/Hemoglobin.total in Blood (HbA1c)
    -- 17856-6: Hemoglobin A1c/Hemoglobin.total in Blood by HPLC
    -- 59261-8: Hemoglobin A1c/Hemoglobin.total in Blood by IFCC protocol
    -- 62388-4: Glycated albumin/Albumin.total in Serum or Plasma

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode 代碼系統
    -- AMB: 門診 (Ambulatory)
    -- IMP: 住院 (Inpatient)
    -- EMER: 急診 (Emergency)

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
    -- 台灣健保局專用代碼系統
    -- 醫療服務代碼
    -- 藥品代碼
    -- 醫令代碼

codesystem "NHI_LAB_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-lab-code'
    -- 健保檢驗檢查代碼系統
    -- 09006: 醣化血紅素(HbA1c)
    -- 09139: 糖化白蛋白(glycated albumin)

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- O: 門診
    -- E: 急診
    -- I: 住院

-- ==================== 值集定義 ====================

valueset "Diabetes Diagnosis Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-diagnosis'
    -- 糖尿病診斷代碼值集
    -- ICD-10-CM: E08*, E09*, E10*, E11*, E13*
    -- SNOMED CT: 73211009, 46635009, 44054006

valueset "Diabetes Medications": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-medications'
    -- 糖尿病用藥值集
    -- ATC: A10* (所有糖尿病用藥)

valueset "HbA1c or Glycated Albumin Tests": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hba1c-glycated-albumin-tests'
    -- HbA1c或糖化白蛋白檢驗值集
    -- LOINC: 4548-4, 17856-6, 59261-8 (HbA1c)
    -- LOINC: 62388-4 (Glycated albumin)
    -- NHI: 09006 (HbA1c), 09139 (Glycated albumin)

valueset "Outpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/outpatient-encounter-types'
    -- 門診就醫類別值集
    -- ActCode: AMB (門診)
    -- NHI: O (門診)

-- ==================== NHI指標代碼對照 ====================

define nhi_code_mapping:
    {
        '109.01': 'Quarterly HbA1c/Glycated Albumin Performance Rate for Diabetes Patients',
        '110.01': 'Annual HbA1c/Glycated Albumin Performance Rate for Diabetes Patients'
    }

-- ==================== 統計期間定義 ====================

-- 季度期間定義
define quarters:
    {
        {id: 1, year: 2024, quarter: 1, start_date: @2024-01-01, end_date: @2024-03-31, label: '113年第1季'},
        {id: 2, year: 2024, quarter: 2, start_date: @2024-04-01, end_date: @2024-06-30, label: '113年第2季'},
        {id: 3, year: 2024, quarter: 3, start_date: @2024-07-01, end_date: @2024-09-30, label: '113年第3季'},
        {id: 4, year: 2024, quarter: 4, start_date: @2024-10-01, end_date: @2024-12-31, label: '113年第4季'}
    }

-- 年度期間定義
define annual_period:
    {
        year: 2024,
        start_date: @2024-01-01,
        end_date: @2024-12-31,
        label: '113年'
    }

-- ==================== 資料篩選條件 ====================

-- 1. 門診就醫記錄 (排除代辦案件)
define outpatient_encounters AS (
    SELECT 
        e.encounter_id,
        e.patient_id,
        e.visit_date,
        e.encounter_type,
        e.primary_diagnosis,
        e.secondary_diagnoses,
        e.agency_flag
    FROM 
        encounter_details e
    WHERE 
        -- 門診案件 (O=門診 or AMB=Ambulatory)
        e.encounter_type IN ('O', 'AMB')
        
        -- 排除代辦案件
        AND (e.agency_flag IS NULL OR e.agency_flag != 'Y')
        
        -- 限定統計期間
        AND e.visit_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 2. 糖尿病診斷條件
-- ICD-10-CM前三碼為E08-E13
define diabetes_encounters AS (
    SELECT 
        oe.encounter_id,
        oe.patient_id,
        oe.visit_date,
        oe.primary_diagnosis,
        oe.secondary_diagnoses,
        CASE 
            WHEN SUBSTRING(oe.primary_diagnosis, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13') THEN oe.primary_diagnosis
            ELSE NULL
        END as diabetes_primary_diagnosis,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM UNNEST(oe.secondary_diagnoses) as sd
                WHERE SUBSTRING(sd, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
            ) THEN TRUE
            ELSE FALSE
        END as has_diabetes_secondary_diagnosis
    FROM 
        outpatient_encounters oe
    WHERE 
        -- 主診斷或次診斷有糖尿病 (E08-E13)
        (
            SUBSTRING(oe.primary_diagnosis, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
            OR 
            EXISTS (
                SELECT 1 FROM UNNEST(oe.secondary_diagnoses) as sd
                WHERE SUBSTRING(sd, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
            )
        )
)

-- 3. 糖尿病用藥條件
-- ATC前三碼為A10
define diabetes_medications AS (
    SELECT 
        d.dispense_id,
        d.encounter_id,
        d.patient_id,
        d.dispense_date,
        d.atc_code_7,
        d.medication_name,
        d.quantity,
        d.days_supply
    FROM 
        drug_dispense d
    WHERE 
        -- ATC前三碼為A10 (糖尿病用藥)
        SUBSTRING(d.atc_code_7, 1, 3) = 'A10'
        
        -- 有實際給藥
        AND d.quantity > 0
        
        -- 限定統計期間
        AND d.dispense_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 4. HbA1c或糖化白蛋白檢驗條件
-- 申報號分代碼前五碼為09006或09139
define hba1c_or_glycated_albumin_tests AS (
    SELECT 
        o.observation_id,
        o.encounter_id,
        o.patient_id,
        o.observation_date,
        o.loinc_code,
        o.nhi_lab_code,
        o.test_name,
        o.test_value,
        o.unit
    FROM 
        observation_lab o
    WHERE 
        -- 健保檢驗代碼: 09006 (HbA1c) 或 09139 (Glycated albumin)
        (
            SUBSTRING(o.nhi_lab_code, 1, 5) = '09006'  -- HbA1c
            OR 
            SUBSTRING(o.nhi_lab_code, 1, 5) = '09139'  -- Glycated albumin
        )
        
        -- 或 LOINC代碼
        OR o.loinc_code IN (
            '4548-4',    -- HbA1c
            '17856-6',   -- HbA1c by HPLC
            '59261-8',   -- HbA1c by IFCC
            '62388-4'    -- Glycated albumin
        )
        
        -- 限定統計期間
        AND o.observation_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- ==================== 分母計算 (Denominator) ====================

-- 分母: 門診主次診斷為糖尿病且使用糖尿病用藥之病人數
-- 條件4: 主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件

define diabetes_patients_with_medication_denominator AS (
    SELECT DISTINCT
        de.patient_id,
        de.encounter_id,
        de.visit_date,
        de.diabetes_primary_diagnosis,
        de.has_diabetes_secondary_diagnosis,
        dm.atc_code_7,
        dm.medication_name,
        dm.dispense_date
    FROM 
        diabetes_encounters de
    INNER JOIN 
        diabetes_medications dm 
        ON de.encounter_id = dm.encounter_id
        AND de.patient_id = dm.patient_id
        AND de.visit_date = dm.dispense_date
    WHERE 
        -- 確保同一處方案件: 同encounter_id, 同visit_date
        de.encounter_id = dm.encounter_id
        AND de.visit_date = dm.dispense_date
)

-- 計算分母唯一病患數
define denominator_unique_patients AS (
    SELECT DISTINCT
        patient_id,
        MIN(visit_date) as first_diabetes_medication_date
    FROM 
        diabetes_patients_with_medication_denominator
    GROUP BY 
        patient_id
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子: 分母ID中，在統計期間於門診有執行HbA1c或glycated albumin檢驗人數
-- 條件5: 從分母的ID繼續觀察，只要該ID於統計期間有執行檢驗即成立

define patients_with_hba1c_or_glycated_albumin_test_numerator AS (
    SELECT DISTINCT
        d.patient_id,
        d.first_diabetes_medication_date,
        t.observation_date,
        t.loinc_code,
        t.nhi_lab_code,
        t.test_name,
        t.test_value
    FROM 
        denominator_unique_patients d
    INNER JOIN 
        hba1c_or_glycated_albumin_tests t
        ON d.patient_id = t.patient_id
    WHERE 
        -- 檢驗日期在統計期間內
        t.observation_date BETWEEN annual_period.start_date AND annual_period.end_date
        
        -- 檢驗日期 >= 糖尿病用藥日期 (確保是糖尿病病患之後的檢驗)
        AND t.observation_date >= d.first_diabetes_medication_date
)

-- 計算分子唯一病患數
define numerator_unique_patients AS (
    SELECT DISTINCT
        patient_id,
        MIN(observation_date) as first_test_date,
        COUNT(DISTINCT observation_date) as total_test_count
    FROM 
        patients_with_hba1c_or_glycated_albumin_test_numerator
    GROUP BY 
        patient_id
)

-- ==================== 季度統計 ====================

define quarterly_statistics:
    quarters Q
    return {
        indicator_code: '109.01',
        year: Q.year,
        quarter: Q.quarter,
        period_label: Q.label,
        start_date: Q.start_date,
        end_date: Q.end_date,
        
        -- 分母: 該季糖尿病病患數 (有糖尿病診斷+用藥)
        denominator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM diabetes_patients_with_medication_denominator
            WHERE visit_date BETWEEN Q.start_date AND Q.end_date
        ),
        
        -- 分子: 該季有HbA1c或glycated albumin檢驗的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT n.patient_id)
            FROM patients_with_hba1c_or_glycated_albumin_test_numerator n
            INNER JOIN denominator_unique_patients d 
                ON n.patient_id = d.patient_id
            WHERE n.observation_date BETWEEN Q.start_date AND Q.end_date
                AND d.first_diabetes_medication_date <= Q.end_date
        ),
        
        -- 執行率 (%)
        performance_rate: (
            CASE 
                WHEN (SELECT COUNT(DISTINCT patient_id) 
                      FROM diabetes_patients_with_medication_denominator 
                      WHERE visit_date BETWEEN Q.start_date AND Q.end_date) > 0
                THEN 
                    ROUND(
                        (SELECT COUNT(DISTINCT n.patient_id)
                         FROM patients_with_hba1c_or_glycated_albumin_test_numerator n
                         INNER JOIN denominator_unique_patients d 
                             ON n.patient_id = d.patient_id
                         WHERE n.observation_date BETWEEN Q.start_date AND Q.end_date
                             AND d.first_diabetes_medication_date <= Q.end_date
                        ) * 100.0 / 
                        (SELECT COUNT(DISTINCT patient_id) 
                         FROM diabetes_patients_with_medication_denominator 
                         WHERE visit_date BETWEEN Q.start_date AND Q.end_date)
                    , 2)
                ELSE 0.0
            END
        )
    }

-- ==================== 年度統計 ====================

define annual_statistics:
    {
        indicator_code: '110.01',
        year: annual_period.year,
        period_label: annual_period.label,
        start_date: annual_period.start_date,
        end_date: annual_period.end_date,
        
        -- 分母: 全年糖尿病病患數 (有糖尿病診斷+用藥)
        denominator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM denominator_unique_patients
        ),
        
        -- 分子: 全年有HbA1c或glycated albumin檢驗的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM numerator_unique_patients
        ),
        
        -- 執行率 (%)
        performance_rate: (
            CASE 
                WHEN (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients) > 0
                THEN 
                    ROUND(
                        (SELECT COUNT(DISTINCT patient_id) FROM numerator_unique_patients) * 100.0 / 
                        (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
                    , 2)
                ELSE 0.0
            END
        ),
        
        -- 平均檢驗次數
        average_tests_per_patient: (
            SELECT ROUND(AVG(total_test_count), 2)
            FROM numerator_unique_patients
        )
    }

-- ==================== 主要輸出 ====================

define main_output:
    {
        metadata: {
            indicator_code_quarterly: '109.01',
            indicator_code_annual: '110.01',
            indicator_name: '糖尿病病人醣化血紅素(HbA1c)或糖化白蛋白(glycated albumin)執行率',
            indicator_name_en: 'Performance Rate of HbA1c or Glycated Albumin Testing for Diabetes Patients',
            data_source: '醫療給付檔案分析系統',
            data_scope: '醫院總額之門診案件，排除代辦案件',
            reporting_unit: '衛生福利部 中央健康保險署',
            report_date: '114/05/13',
            calculation_date: Today()
        },
        
        quarterly_results: quarterly_statistics,
        annual_result: annual_statistics,
        
        denominator_details: {
            total_diabetes_patients: (SELECT COUNT(*) FROM denominator_unique_patients),
            diabetes_encounters_count: (SELECT COUNT(*) FROM diabetes_encounters),
            diabetes_medications_count: (SELECT COUNT(*) FROM diabetes_medications),
            diabetes_patients_with_medication_count: (SELECT COUNT(*) FROM diabetes_patients_with_medication_denominator)
        },
        
        numerator_details: {
            patients_with_tests: (SELECT COUNT(*) FROM numerator_unique_patients),
            total_test_records: (SELECT COUNT(*) FROM hba1c_or_glycated_albumin_tests),
            patients_with_hba1c_or_glycated_albumin: (SELECT COUNT(*) FROM patients_with_hba1c_or_glycated_albumin_test_numerator)
        }
    }

-- ==================== 詳細案件資料 ====================

-- 分母案件明細
define denominator_case_details:
    SELECT 
        d.patient_id,
        d.encounter_id,
        d.visit_date,
        d.diabetes_primary_diagnosis,
        d.has_diabetes_secondary_diagnosis,
        d.atc_code_7,
        d.medication_name,
        d.dispense_date
    FROM 
        diabetes_patients_with_medication_denominator d
    ORDER BY 
        d.patient_id, d.visit_date

-- 分子案件明細
define numerator_case_details:
    SELECT 
        n.patient_id,
        n.first_diabetes_medication_date,
        n.observation_date,
        n.loinc_code,
        n.nhi_lab_code,
        n.test_name,
        n.test_value
    FROM 
        patients_with_hba1c_or_glycated_albumin_test_numerator n
    ORDER BY 
        n.patient_id, n.observation_date

-- ==================== 品質指標說明 ====================

/*
 * 臨床意義:
 * 
 * 1. HbA1c (醣化血紅素):
 *    - 反映過去2-3個月的平均血糖控制情況
 *    - 糖尿病診斷標準: ≥6.5%
 *    - 治療目標: 一般<7%, 嚴格<6.5%
 *    - 建議檢驗頻率: 每3-6個月一次
 * 
 * 2. Glycated Albumin (糖化白蛋白):
 *    - 反映過去2-3週的平均血糖控制情況
 *    - 對於HbA1c不適用的病患(如貧血、腎病)的替代指標
 *    - 參考值: <17% (正常), 17-25% (需注意), >25% (高風險)
 * 
 * 3. 執行率的重要性:
 *    - 定期監測血糖控制是糖尿病管理的核心
 *    - 高執行率代表良好的慢性病管理品質
 *    - 有助於早期發現血糖控制不佳，及時調整治療
 *    - 降低糖尿病併發症風險(視網膜病變、腎病變、神經病變等)
 * 
 * 4. 政策目標:
 *    - 提升糖尿病病患的定期檢驗率
 *    - 改善糖尿病照護品質
 *    - 降低糖尿病相關醫療支出
 */

-- ==================== 排除條件說明 ====================

/*
 * 排除條件:
 * 1. 代辦案件 (agency_flag = 'Y')
 * 2. 非門診案件 (encounter_type != 'O' and != 'AMB')
 * 3. 沒有糖尿病診斷的案件
 * 4. 沒有糖尿病用藥的案件
 * 5. 診斷與用藥不在同一處方案件的病患
 */

-- ==================== 資料品質檢查 ====================

define data_quality_checks:
    {
        -- 檢查是否有缺失的必要欄位
        missing_diagnosis: (
            SELECT COUNT(*) 
            FROM outpatient_encounters 
            WHERE primary_diagnosis IS NULL
        ),
        
        missing_medication: (
            SELECT COUNT(*) 
            FROM diabetes_medications 
            WHERE atc_code_7 IS NULL
        ),
        
        missing_test_code: (
            SELECT COUNT(*) 
            FROM hba1c_or_glycated_albumin_tests 
            WHERE loinc_code IS NULL AND nhi_lab_code IS NULL
        ),
        
        -- 檢查日期邏輯
        invalid_dates: (
            SELECT COUNT(*) 
            FROM diabetes_patients_with_medication_denominator d
            INNER JOIN patients_with_hba1c_or_glycated_albumin_test_numerator n
                ON d.patient_id = n.patient_id
            WHERE n.observation_date < d.visit_date
        )
    }

-- ==================== 結束 ====================
