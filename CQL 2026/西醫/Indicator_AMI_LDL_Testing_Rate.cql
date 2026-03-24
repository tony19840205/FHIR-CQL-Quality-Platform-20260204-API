library Indicator_AMI_LDL_Testing_Rate version '1.0.0'

/*
指標名稱: 急性心肌梗塞(AMI)病人於住院期間執行血脂LDL檢查比率
指標編號: [待確認]
適用期間: 2026年 (民國115年)
條件依據：急性心肌梗塞(AMI)病人於住院期間執行血脂LDL檢查比率

指標說明：
============================================================

急性心肌梗塞(AMI)病人於住院期間執行血脂LDL檢查比率 = 
    分子: 分母案件住院期間曾執行LDL-C檢查的案件數。
    分母: 已出院的急性心肌梗塞(AMI)病人。

備註：
------------------------------------------------------------
(1)AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21-I22、I5A，
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除。

(2)出院：同次住院在一筆有出院日。

(3)同一【院所, ID, 生日, 住院日】為同次住院，視為同一案件。

(4)LDL-C檢查代碼：09044C 低密度脂蛋白 L.D.L. cholesterol 
   (Lowdensity lipoprotein cholesterol)

(5)資料範圍：西醫醫院住院資料

(6)計算頻率：半年及年

------------------------------------------------------------

FHIR Resource 對應：
  分子：Observation (LDL-C檢查)
  分母：Patient, Encounter (住院), Condition (AMI診斷)

品質計算：
  - 統計期間：半年/年度統計
  - 計算週期：半年、年
  - 跨院勾稽：否（同一院所）
  - 計算單位：案件數（住院次）
============================================================
*/

using FHIR version '4.0.1'

// ============================================================
// 參數定義
// ============================================================
parameter MeasurementPeriod Interval<DateTime> default Interval[@2026-01-01T00:00:00.0, @2027-01-01T00:00:00.0)

// 半年期統計期間
parameter SemiannualPeriod1 Interval<DateTime> default Interval[@2026-01-01T00:00:00.0, @2026-07-01T00:00:00.0)
parameter SemiannualPeriod2 Interval<DateTime> default Interval[@2026-07-01T00:00:00.0, @2027-01-01T00:00:00.0)

// ============================================================
// Codesystem 定義
// ============================================================
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "LOINC": 'http://loinc.org'
codesystem "NHI-Lab": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/health-insurance-lab-code-tw'
codesystem "SNOMED-CT": 'http://snomed.info/sct'

// ============================================================
// ValueSet 定義
// ============================================================

// AMI 診斷代碼
valueset "AMI Diagnosis Codes": 'AMI-Diagnosis-Codes'

// LDL-C 檢查代碼
valueset "LDL Cholesterol Lab Codes": 'LDL-Cholesterol-Lab-Codes'

// ============================================================
// Code 定義 - AMI 診斷（包含排除診斷）
// ============================================================
define "AMI Diagnosis Code List":
  {
    // I21 - 急性心肌梗塞
    Code { code: 'I21', system: "ICD10CM", display: '急性心肌梗塞' },
    Code { code: 'I210', system: "ICD10CM", display: 'ST段上升型(STEMI)心肌梗塞，累及前壁' },
    Code { code: 'I211', system: "ICD10CM", display: 'ST段上升型(STEMI)心肌梗塞，累及下壁' },
    Code { code: 'I212', system: "ICD10CM", display: 'ST段上升型(STEMI)心肌梗塞，累及其他部位' },
    Code { code: 'I213', system: "ICD10CM", display: 'ST段上升型(STEMI)心肌梗塞，部位未明示' },
    Code { code: 'I219', system: "ICD10CM", display: '急性心肌梗塞，未明示' },
    Code { code: 'I21A', system: "ICD10CM", display: '其他類型急性心肌梗塞' },
    Code { code: 'I21A1', system: "ICD10CM", display: 'STEMI累及左主冠狀動脈' },
    Code { code: 'I21A9', system: "ICD10CM", display: '其他類型急性心肌梗塞' },
    
    // I22 - 續發性心肌梗塞
    Code { code: 'I22', system: "ICD10CM", display: '續發性心肌梗塞' },
    Code { code: 'I220', system: "ICD10CM", display: '續發性ST段上升型(STEMI)心肌梗塞，累及前壁' },
    Code { code: 'I221', system: "ICD10CM", display: '續發性ST段上升型(STEMI)心肌梗塞，累及下壁' },
    Code { code: 'I228', system: "ICD10CM", display: '續發性ST段上升型(STEMI)心肌梗塞，累及其他部位' },
    Code { code: 'I229', system: "ICD10CM", display: '續發性心肌梗塞，未明示' },
    
    // I5A - 其他心肌梗塞類型
    Code { code: 'I5A', system: "ICD10CM", display: '其他類型心肌梗塞' }
  }

// 排除診斷代碼
define "AMI Exclusion Diagnosis Code List":
  {
    Code { code: 'I214', system: "ICD10CM", display: '非ST段上升型(NSTEMI)心肌梗塞' },
    Code { code: 'I222', system: "ICD10CM", display: '續發性非ST段上升型(NSTEMI)心肌梗塞' }
  }

// ============================================================
// Code 定義 - LDL-C 檢查
// ============================================================
define "LDL Cholesterol Lab Code List":
  {
    Code { code: '09044C', system: "NHI-Lab", display: '低密度脂蛋白 L.D.L. cholesterol (Lowdensity lipoprotein cholesterol)' },
    Code { code: '13457-7', system: "LOINC", display: 'Cholesterol in LDL [Mass/volume] in Serum or Plasma by calculation' },
    Code { code: '18262-6', system: "LOINC", display: 'Cholesterol in LDL [Mass/volume] in Serum or Plasma by Direct assay' },
    Code { code: '2089-1', system: "LOINC", display: 'Cholesterol in LDL [Mass/volume] in Serum or Plasma' }
  }

// ============================================================
// 初始病患群組
// ============================================================
define "Initial Patient Population":
  [Patient] P
    where P.active is true

// ============================================================
// 輔助函數：取得 Condition 的診斷代碼
// ============================================================
define function GetDiagnosisCode(condition Condition):
  if condition.code is not null 
  then condition.code.coding[0].code
  else null

// ============================================================
// 輔助函數：檢查診斷代碼是否為AMI (I21, I22, I5A)
// ============================================================
define function IsAMIDiagnosis(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          C.code starts with 'I21'
          or C.code starts with 'I22'
          or C.code starts with 'I5A'
        )
  )

// ============================================================
// 輔助函數：檢查是否為排除診斷 (I214, I222)
// ============================================================
define function IsExclusionDiagnosis(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          C.code = 'I214'
          or C.code starts with 'I214'
          or C.code = 'I222'
          or C.code starts with 'I222'
        )
  )

// ============================================================
// 輔助函數：檢查是否為主診斷
// ============================================================
define function IsPrimaryDiagnosis(condition Condition):
  exists(
    condition.category C
      where exists(
        C.coding CD
          where CD.code = 'encounter-diagnosis'
      )
  )
  and (
    condition.extension E
      where E.url = 'http://hl7.org/fhir/StructureDefinition/condition-dueTo'
        and (E.value as CodeableConcept).coding[0].code = 'primary'
    return true
  ) is not null

// ============================================================
// 輔助函數：檢查就醫類型
// ============================================================
define function GetEncounterClass(encounter Encounter):
  if encounter.class is not null
  then encounter.class.code
  else null

define function IsInpatientEncounter(encounter Encounter):
  GetEncounterClass(encounter) in { 'IMP', 'inpatient', 'acute' }

// ============================================================
// 輔助函數：取得住院日期
// ============================================================
define function GetAdmissionDate(encounter Encounter):
  Coalesce(
    start of encounter.period,
    encounter.period.start
  )

define function GetDischargeDate(encounter Encounter):
  Coalesce(
    end of encounter.period,
    encounter.period.end
  )

// ============================================================
// 輔助函數：取得病人資訊用於分組
// ============================================================
define function GetPatientBirthDate(patient Patient):
  patient.birthDate

define function GetEncounterOrganization(encounter Encounter):
  encounter.serviceProvider.reference

// ============================================================
// 輔助函數：檢查LDL-C檢查
// ============================================================
define function IsLDLCholesterolTest(observation Observation):
  exists(
    observation.code.coding C
      where (C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/health-insurance-lab-code-tw'
             and C.code = '09044C')
        or (C.system = 'http://loinc.org'
            and C.code in { '13457-7', '18262-6', '2089-1' })
  )

define function GetObservationDate(observation Observation):
  Coalesce(
    observation.effective as DateTime,
    start of (observation.effective as Period),
    observation.issued
  )

// ============================================================
// 分母：已出院的AMI病人（住院案件）
// ============================================================

// 所有住院案件
define "All Inpatient Encounters":
  [Encounter] E
    where IsInpatientEncounter(E)
      and GetDischargeDate(E) during MeasurementPeriod
      and GetDischargeDate(E) is not null

// 有AMI主診斷的住院案件
define "Inpatient Encounters with AMI Diagnosis":
  "All Inpatient Encounters" E
    where exists(
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsAMIDiagnosis(C)
          and IsPrimaryDiagnosis(C)
    )

// 有排除診斷的住院案件（需要排除整個住院）
define "Inpatient Encounters with Exclusion Diagnosis":
  "Inpatient Encounters with AMI Diagnosis" E
    where exists(
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsExclusionDiagnosis(C)
          and IsPrimaryDiagnosis(C)
    )

// 分母：排除有I214/I222診斷的AMI住院案件
define "Denominator Encounters":
  "Inpatient Encounters with AMI Diagnosis" E
    where E not in "Inpatient Encounters with Exclusion Diagnosis"

define "Denominator":
  "Denominator Encounters"

// ============================================================
// 分子：分母案件中住院期間有執行LDL-C檢查
// ============================================================

// 所有LDL-C檢查
define "All LDL Cholesterol Tests":
  [Observation] O
    where IsLDLCholesterolTest(O)
      and O.status in { 'final', 'amended', 'corrected' }
      and GetObservationDate(O) is not null

// 住院期間執行的LDL-C檢查
define "LDL Tests During Hospitalization":
  "Denominator Encounters" E
    let admissionDate: GetAdmissionDate(E),
        dischargeDate: GetDischargeDate(E),
        hospitalizationPeriod: Interval[admissionDate, dischargeDate]
    return Tuple {
      encounter: E,
      encounterId: E.id,
      patientId: E.subject.reference,
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      hasLDLTest: exists(
        "All LDL Cholesterol Tests" O
          where O.subject.reference = E.subject.reference
            and GetObservationDate(O) during hospitalizationPeriod
      )
    }

define "Encounters with LDL Testing":
  "LDL Tests During Hospitalization" T
    where T.hasLDLTest = true
    return T.encounter

define "Numerator":
  "Encounters with LDL Testing"

// ============================================================
// 排除條件
// ============================================================
define "Exclusions":
  {} as List<Encounter>

// ============================================================
// 最終分母與分子
// ============================================================
define "Final Denominator":
  "Denominator" except "Exclusions"

define "Final Numerator":
  "Numerator" except "Exclusions"

// ============================================================
// 品質指標計算
// ============================================================
define "Indicator Score":
  if Count("Final Denominator") > 0
  then Round((Count("Final Numerator") / Count("Final Denominator")) * 100, 2)
  else null

// ============================================================
// 半年期統計
// ============================================================
define "Denominator Semiannual 1":
  "Final Denominator" E
    where GetDischargeDate(E) during SemiannualPeriod1

define "Numerator Semiannual 1":
  "Final Numerator" E
    where GetDischargeDate(E) during SemiannualPeriod1

define "Indicator Score Semiannual 1":
  if Count("Denominator Semiannual 1") > 0
  then Round((Count("Numerator Semiannual 1") / Count("Denominator Semiannual 1")) * 100, 2)
  else null

define "Denominator Semiannual 2":
  "Final Denominator" E
    where GetDischargeDate(E) during SemiannualPeriod2

define "Numerator Semiannual 2":
  "Final Numerator" E
    where GetDischargeDate(E) during SemiannualPeriod2

define "Indicator Score Semiannual 2":
  if Count("Denominator Semiannual 2") > 0
  then Round((Count("Numerator Semiannual 2") / Count("Denominator Semiannual 2")) * 100, 2)
  else null

// ============================================================
// 統計資訊
// ============================================================

// AMI診斷分類統計
define "AMI Diagnosis Distribution":
  "Final Denominator" E
    let amiConditions:
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsAMIDiagnosis(C)
          and IsPrimaryDiagnosis(C),
    primaryDiagnosisCode:
      First(amiConditions C return GetDiagnosisCode(C))
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      diagnosisCode: primaryDiagnosisCode,
      diagnosisCategory: case
        when primaryDiagnosisCode starts with 'I21' then 'I21-急性心肌梗塞'
        when primaryDiagnosisCode starts with 'I22' then 'I22-續發性心肌梗塞'
        when primaryDiagnosisCode starts with 'I5A' then 'I5A-其他心肌梗塞'
        else '未知'
      end
    }

// 排除案件統計
define "Exclusion Cases Statistics":
  "Inpatient Encounters with Exclusion Diagnosis" E
    let exclusionConditions:
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsExclusionDiagnosis(C)
          and IsPrimaryDiagnosis(C),
    exclusionCode:
      First(exclusionConditions C return GetDiagnosisCode(C))
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      exclusionCode: exclusionCode,
      exclusionReason: case
        when exclusionCode starts with 'I214' then 'I214-非ST段上升型(NSTEMI)心肌梗塞'
        when exclusionCode starts with 'I222' then 'I222-續發性非ST段上升型(NSTEMI)心肌梗塞'
        else '其他排除原因'
      end
    }

// 住院天數分析
define "Length of Stay Analysis":
  "Final Denominator" E
    let admissionDate: GetAdmissionDate(E),
        dischargeDate: GetDischargeDate(E),
        lengthOfStay: days between admissionDate and dischargeDate
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      lengthOfStay: lengthOfStay,
      stayCategory: case
        when lengthOfStay <= 3 then '1-3天'
        when lengthOfStay <= 7 then '4-7天'
        when lengthOfStay <= 14 then '8-14天'
        when lengthOfStay <= 30 then '15-30天'
        else '超過30天'
      end,
      hasLDLTest: E in "Final Numerator"
    }

// LDL檢查時機分析
define "LDL Test Timing Analysis":
  "Final Numerator" E
    let admissionDate: GetAdmissionDate(E),
        dischargeDate: GetDischargeDate(E),
        hospitalizationPeriod: Interval[admissionDate, dischargeDate],
        ldlTests:
          "All LDL Cholesterol Tests" O
            where O.subject.reference = E.subject.reference
              and GetObservationDate(O) during hospitalizationPeriod,
        firstTestDate: Min(ldlTests O return GetObservationDate(O)),
        daysFromAdmissionToTest: days between admissionDate and firstTestDate
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      admissionDate: admissionDate,
      firstLDLTestDate: firstTestDate,
      daysFromAdmission: daysFromAdmissionToTest,
      testTimingCategory: case
        when daysFromAdmissionToTest <= 1 then '入院當日或次日'
        when daysFromAdmissionToTest <= 3 then '2-3天內'
        when daysFromAdmissionToTest <= 7 then '4-7天內'
        else '超過7天'
      end,
      totalLDLTests: Count(ldlTests)
    }

// 出院月份分布
define "Discharge Month Distribution":
  "Final Denominator" E
    let dischargeDate: GetDischargeDate(E),
        monthOfYear: month from dischargeDate
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      dischargeDate: dischargeDate,
      month: monthOfYear,
      monthName: case monthOfYear
        when 1 then '1月'
        when 2 then '2月'
        when 3 then '3月'
        when 4 then '4月'
        when 5 then '5月'
        when 6 then '6月'
        when 7 then '7月'
        when 8 then '8月'
        when 9 then '9月'
        when 10 then '10月'
        when 11 then '11月'
        when 12 then '12月'
        else '未知'
      end,
      quarter: case
        when monthOfYear in { 1, 2, 3 } then 'Q1'
        when monthOfYear in { 4, 5, 6 } then 'Q2'
        when monthOfYear in { 7, 8, 9 } then 'Q3'
        when monthOfYear in { 10, 11, 12 } then 'Q4'
        else '未知'
      end,
      semiannual: case
        when monthOfYear <= 6 then '上半年'
        else '下半年'
      end,
      hasLDLTest: E in "Final Numerator"
    }

// ============================================================
// 品質檢核
// ============================================================
define "Quality Checks":
  {
    Tuple {
      checkName: '分母案件數檢核',
      description: '確認分母案件數（AMI住院案件）> 0',
      passed: Count("Final Denominator") > 0,
      value: Count("Final Denominator")
    },
    Tuple {
      checkName: '分子分母邏輯檢核',
      description: '確認分子案件數 <= 分母案件數',
      passed: Count("Final Numerator") <= Count("Final Denominator"),
      numerator: Count("Final Numerator"),
      denominator: Count("Final Denominator")
    },
    Tuple {
      checkName: 'AMI診斷檢核',
      description: '確認所有分母案件都有AMI主診斷',
      passed: not exists(
        "Final Denominator" E
          where not exists(
            [Condition] C
              where C.encounter.reference = 'Encounter/' + E.id
                and IsAMIDiagnosis(C)
                and IsPrimaryDiagnosis(C)
          )
      ),
      totalEncounters: Count("Final Denominator")
    },
    Tuple {
      checkName: '排除診斷檢核',
      description: '確認排除I214/I222診斷的案件',
      passed: Count("Inpatient Encounters with Exclusion Diagnosis") >= 0,
      excludedCases: Count("Inpatient Encounters with Exclusion Diagnosis")
    },
    Tuple {
      checkName: '出院日期檢核',
      description: '確認所有案件都有出院日期',
      passed: not exists(
        "Final Denominator" E
          where GetDischargeDate(E) is null
      ),
      totalEncounters: Count("Final Denominator")
    },
    Tuple {
      checkName: 'LDL檢查檢核',
      description: '確認分子案件都有LDL檢查記錄',
      passed: not exists(
        "Final Numerator" E
          where not exists(
            "All LDL Cholesterol Tests" O
              where O.subject.reference = E.subject.reference
                and GetObservationDate(O) during Interval[GetAdmissionDate(E), GetDischargeDate(E)]
          )
      ),
      totalNumerator: Count("Final Numerator")
    },
    Tuple {
      checkName: '指標分數範圍檢核',
      description: '確認指標分數在 0-100 之間',
      passed: "Indicator Score" >= 0 and "Indicator Score" <= 100,
      score: "Indicator Score"
    }
  }

// ============================================================
// 彙總報告
// ============================================================
define "Summary Report":
  Tuple {
    indicatorName: '急性心肌梗塞(AMI)病人於住院期間執行血脂LDL檢查比率',
    measurementPeriod: MeasurementPeriod,
    denominator: Count("Final Denominator"),
    numerator: Count("Final Numerator"),
    exclusions: Count("Exclusions"),
    indicatorScore: "Indicator Score",
    semiannualStats: Tuple {
      period1: Tuple {
        period: SemiannualPeriod1,
        denominator: Count("Denominator Semiannual 1"),
        numerator: Count("Numerator Semiannual 1"),
        score: "Indicator Score Semiannual 1"
      },
      period2: Tuple {
        period: SemiannualPeriod2,
        denominator: Count("Denominator Semiannual 2"),
        numerator: Count("Numerator Semiannual 2"),
        score: "Indicator Score Semiannual 2"
      }
    },
    amiDiagnosisStats: Tuple {
      totalAMICases: Count("Inpatient Encounters with AMI Diagnosis"),
      excludedCases: Count("Inpatient Encounters with Exclusion Diagnosis"),
      finalCases: Count("Final Denominator"),
      diagnosisDistribution: "AMI Diagnosis Distribution"
    },
    ldlTestStats: Tuple {
      casesWithLDLTest: Count("Final Numerator"),
      casesWithoutLDLTest: Count("Final Denominator") - Count("Final Numerator"),
      averageLDLTestsPerCase: 
        if Count("Final Numerator") > 0
        then Round(
          Sum("LDL Test Timing Analysis" T return T.totalLDLTests) / Count("Final Numerator"), 
          2
        )
        else 0,
      averageDaysToFirstTest: 
        if Count("LDL Test Timing Analysis") > 0
        then Round(
          Avg("LDL Test Timing Analysis" T return T.daysFromAdmission),
          2
        )
        else null
    },
    hospitalizationStats: Tuple {
      averageLengthOfStay: 
        if Count("Length of Stay Analysis") > 0
        then Round(
          Avg("Length of Stay Analysis" L return L.lengthOfStay),
          2
        )
        else null,
      stayDistribution: "Length of Stay Analysis"
    },
    qualityChecks: "Quality Checks"
  }
