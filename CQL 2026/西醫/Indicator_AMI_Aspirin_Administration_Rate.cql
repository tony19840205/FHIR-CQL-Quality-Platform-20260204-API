library Indicator_AMI_Aspirin_Administration_Rate version '1.0.0'

/*
指標名稱: 急性心肌梗塞(AMI)病人於住院期間給藥比率 - 阿斯匹靈(Aspirin)
指標編號: [待確認]
適用期間: 2026年 (民國115年)
條件依據：急性心肌梗塞(AMI)病人於住院期間給藥比率 - 阿斯匹靈(Aspirin)

指標說明：
============================================================

急性心肌梗塞(AMI)病人於住院期間給藥比率 - 阿斯匹靈(Aspirin) = 
    分子: 分母案件住院期間曾給予Aspirin的案件數。
    分母: 已出院的AMI案件(排除上腸胃道(Upper Gastrointestinal, UGI)出血或其他出血案件)

備註：
------------------------------------------------------------
(1)AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21-I22、I5A，
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除。

(2)出院：同次住院在一筆有出院日。

(3)上腸胃道(UGI)出血或其他出血案件：同次住院任一主次診斷含出血相關診斷碼，
   該次住院資料全部排除。

(4)同一【院所, ID, 生日, 住院日】為同次住院，視為同一案件。

(5)Aspirin藥品代碼：ATC藥品分類前7碼為B01AC06 (acetylsalicylic acid)

(6)資料範圍：西醫醫院住院資料

(7)計算頻率：半年及年

------------------------------------------------------------

FHIR Resource 對應：
  分子：MedicationRequest, MedicationAdministration (Aspirin給藥)
  分母：Patient, Encounter (住院), Condition (AMI診斷、出血排除診斷)

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
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "SNOMED-CT": 'http://snomed.info/sct'

// ============================================================
// ValueSet 定義
// ============================================================

// AMI 診斷代碼
valueset "AMI Diagnosis Codes": 'AMI-Diagnosis-Codes'

// Aspirin ATC 代碼
valueset "Aspirin ATC Codes": 'Aspirin-ATC-Codes'

// 出血相關診斷代碼
valueset "Bleeding Diagnosis Codes": 'Bleeding-Diagnosis-Codes'

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

// 排除診斷代碼（AMI排除）
define "AMI Exclusion Diagnosis Code List":
  {
    Code { code: 'I214', system: "ICD10CM", display: '非ST段上升型(NSTEMI)心肌梗塞' },
    Code { code: 'I222', system: "ICD10CM", display: '續發性非ST段上升型(NSTEMI)心肌梗塞' }
  }

// 出血相關診斷代碼（主次診斷排除）
define "Bleeding Diagnosis Code List":
  {
    // 上腸胃道出血
    Code { code: 'K250', system: "ICD10CM", display: '胃潰瘍伴出血' },
    Code { code: 'K252', system: "ICD10CM", display: '胃潰瘍伴急性出血及穿孔' },
    Code { code: 'K254', system: "ICD10CM", display: '胃潰瘍伴慢性或未明示之出血' },
    Code { code: 'K256', system: "ICD10CM", display: '胃潰瘍伴慢性或未明示之出血及穿孔' },
    Code { code: 'K260', system: "ICD10CM", display: '十二指腸潰瘍伴出血' },
    Code { code: 'K262', system: "ICD10CM", display: '十二指腸潰瘍伴急性出血及穿孔' },
    Code { code: 'K264', system: "ICD10CM", display: '十二指腸潰瘍伴慢性或未明示之出血' },
    Code { code: 'K266', system: "ICD10CM", display: '十二指腸潰瘍伴慢性或未明示之出血及穿孔' },
    Code { code: 'K270', system: "ICD10CM", display: '消化性潰瘍伴出血' },
    Code { code: 'K272', system: "ICD10CM", display: '消化性潰瘍伴急性出血及穿孔' },
    Code { code: 'K274', system: "ICD10CM", display: '消化性潰瘍伴慢性或未明示之出血' },
    Code { code: 'K276', system: "ICD10CM", display: '消化性潰瘍伴慢性或未明示之出血及穿孔' },
    Code { code: 'K280', system: "ICD10CM", display: '胃空腸潰瘍伴出血' },
    Code { code: 'K282', system: "ICD10CM", display: '胃空腸潰瘍伴急性出血及穿孔' },
    Code { code: 'K284', system: "ICD10CM", display: '胃空腸潰瘍伴慢性或未明示之出血' },
    Code { code: 'K286', system: "ICD10CM", display: '胃空腸潰瘍伴慢性或未明示之出血及穿孔' },
    Code { code: 'K290', system: "ICD10CM", display: '急性出血性胃炎' },
    Code { code: 'K920', system: "ICD10CM", display: '吐血' },
    Code { code: 'K921', system: "ICD10CM", display: '糞便潛血' },
    Code { code: 'K922', system: "ICD10CM", display: '胃腸道出血，未明示' },
    
    // 其他出血
    Code { code: 'I60', system: "ICD10CM", display: '蜘蛛膜下腔出血' },
    Code { code: 'I61', system: "ICD10CM", display: '腦內出血' },
    Code { code: 'I62', system: "ICD10CM", display: '其他非創傷性顱內出血' },
    Code { code: 'R04', system: "ICD10CM", display: '呼吸道出血' },
    Code { code: 'R310', system: "ICD10CM", display: '肉眼血尿' },
    Code { code: 'R319', system: "ICD10CM", display: '血尿，未明示' },
    Code { code: 'R58', system: "ICD10CM", display: '出血，他處未歸類者' },
    Code { code: 'D62', system: "ICD10CM", display: '失血後急性貧血' },
    Code { code: 'D500', system: "ICD10CM", display: '失血性貧血' }
  }

// ============================================================
// Code 定義 - Aspirin ATC 代碼
// ============================================================
define "Aspirin ATC Code List":
  {
    Code { code: 'B01AC06', system: "ATC", display: 'acetylsalicylic acid (Aspirin)' }
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
// 輔助函數：檢查是否為AMI排除診斷 (I214, I222)
// ============================================================
define function IsAMIExclusionDiagnosis(condition Condition):
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
// 輔助函數：檢查是否為出血相關診斷
// ============================================================
define function IsBleedingDiagnosis(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          // 上腸胃道出血
          C.code starts with 'K25'
          or C.code starts with 'K26'
          or C.code starts with 'K27'
          or C.code starts with 'K28'
          or C.code starts with 'K29'
          or C.code starts with 'K92'
          // 腦出血
          or C.code starts with 'I60'
          or C.code starts with 'I61'
          or C.code starts with 'I62'
          // 其他出血
          or C.code starts with 'R04'
          or C.code starts with 'R31'
          or C.code = 'R58'
          or C.code = 'D62'
          or C.code starts with 'D500'
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
// 輔助函數：檢查Aspirin藥品
// ============================================================
define function IsAspirinMedication(medication MedicationRequest):
  exists(
    medication.medication.concept.coding C
      where C.system = 'http://www.whocc.no/atc'
        and (
          C.code = 'B01AC06'
          or C.code starts with 'B01AC06'
        )
  )

define function GetMedicationDate(medication MedicationRequest):
  Coalesce(
    medication.authoredOn,
    start of medication.dosageInstruction[0].timing.repeat.bounds as Period
  )

// ============================================================
// 分母步驟1：已出院的AMI病人（住院案件）
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

// 有AMI排除診斷(I214/I222)的住院案件（需要排除整個住院）
define "Inpatient Encounters with AMI Exclusion Diagnosis":
  "Inpatient Encounters with AMI Diagnosis" E
    where exists(
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsAMIExclusionDiagnosis(C)
          and IsPrimaryDiagnosis(C)
    )

// 排除AMI排除診斷後的案件
define "AMI Cases After AMI Exclusion":
  "Inpatient Encounters with AMI Diagnosis" E
    where E not in "Inpatient Encounters with AMI Exclusion Diagnosis"

// ============================================================
// 分母步驟2：排除出血相關診斷（主次診斷都要檢查）
// ============================================================

// 有出血相關診斷的住院案件（主診斷或次診斷）
define "Inpatient Encounters with Bleeding Diagnosis":
  "AMI Cases After AMI Exclusion" E
    where exists(
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsBleedingDiagnosis(C)
    )

// 分母：排除出血診斷後的AMI住院案件
define "Denominator Encounters":
  "AMI Cases After AMI Exclusion" E
    where E not in "Inpatient Encounters with Bleeding Diagnosis"

define "Denominator":
  "Denominator Encounters"

// ============================================================
// 分子：分母案件中住院期間有給予Aspirin
// ============================================================

// 所有Aspirin藥品處方/給藥
define "All Aspirin Medications":
  [MedicationRequest] M
    where IsAspirinMedication(M)
      and M.status in { 'active', 'completed' }
      and M.intent in { 'order', 'plan', 'original-order' }

// 住院期間給予的Aspirin
define "Aspirin During Hospitalization":
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
      hasAspirin: exists(
        "All Aspirin Medications" M
          where M.subject.reference = E.subject.reference
            and M.encounter.reference = 'Encounter/' + E.id
      )
      or exists(
        "All Aspirin Medications" M
          where M.subject.reference = E.subject.reference
            and GetMedicationDate(M) during hospitalizationPeriod
      )
    }

define "Encounters with Aspirin Administration":
  "Aspirin During Hospitalization" T
    where T.hasAspirin = true
    return T.encounter

define "Numerator":
  "Encounters with Aspirin Administration"

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

// 排除案件統計 - AMI排除
define "AMI Exclusion Cases Statistics":
  "Inpatient Encounters with AMI Exclusion Diagnosis" E
    let exclusionConditions:
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsAMIExclusionDiagnosis(C)
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
        else 'AMI其他排除原因'
      end
    }

// 排除案件統計 - 出血排除
define "Bleeding Exclusion Cases Statistics":
  "Inpatient Encounters with Bleeding Diagnosis" E
    let bleedingConditions:
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsBleedingDiagnosis(C),
    bleedingCodes:
      bleedingConditions C return GetDiagnosisCode(C)
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      bleedingDiagnosisCodes: bleedingCodes,
      bleedingCategory: case
        when exists(bleedingCodes code where code starts with 'K2') then 'UGI出血-消化性潰瘍'
        when exists(bleedingCodes code where code starts with 'K92') then 'UGI出血-胃腸道出血'
        when exists(bleedingCodes code where code starts with 'I6') then '腦出血'
        when exists(bleedingCodes code where code starts with 'R') then '其他出血'
        else '其他出血相關'
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
      hasAspirin: E in "Final Numerator"
    }

// Aspirin給藥時機分析
define "Aspirin Administration Timing Analysis":
  "Final Numerator" E
    let admissionDate: GetAdmissionDate(E),
        dischargeDate: GetDischargeDate(E),
        hospitalizationPeriod: Interval[admissionDate, dischargeDate],
        aspirinMedications:
          "All Aspirin Medications" M
            where M.subject.reference = E.subject.reference
              and (M.encounter.reference = 'Encounter/' + E.id
                   or GetMedicationDate(M) during hospitalizationPeriod),
        firstAspirinDate: Min(aspirinMedications M return GetMedicationDate(M)),
        daysFromAdmissionToAspirin: days between admissionDate and firstAspirinDate
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      admissionDate: admissionDate,
      firstAspirinDate: firstAspirinDate,
      daysFromAdmission: daysFromAdmissionToAspirin,
      administrationTimingCategory: case
        when daysFromAdmissionToAspirin <= 0 then '入院當日'
        when daysFromAdmissionToAspirin <= 1 then '入院次日'
        when daysFromAdmissionToAspirin <= 3 then '2-3天內'
        when daysFromAdmissionToAspirin <= 7 then '4-7天內'
        else '超過7天'
      end,
      totalAspirinOrders: Count(aspirinMedications)
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
      hasAspirin: E in "Final Numerator"
    }

// ============================================================
// 品質檢核
// ============================================================
define "Quality Checks":
  {
    Tuple {
      checkName: '分母案件數檢核',
      description: '確認分母案件數（AMI住院案件，排除出血）> 0',
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
      checkName: 'AMI排除診斷檢核',
      description: '確認排除I214/I222診斷的案件',
      passed: Count("Inpatient Encounters with AMI Exclusion Diagnosis") >= 0,
      excludedCases: Count("Inpatient Encounters with AMI Exclusion Diagnosis")
    },
    Tuple {
      checkName: '出血排除診斷檢核',
      description: '確認排除出血相關診斷的案件',
      passed: Count("Inpatient Encounters with Bleeding Diagnosis") >= 0,
      excludedCases: Count("Inpatient Encounters with Bleeding Diagnosis")
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
      checkName: 'Aspirin給藥檢核',
      description: '確認分子案件都有Aspirin給藥記錄',
      passed: not exists(
        "Final Numerator" E
          where not exists(
            "All Aspirin Medications" M
              where M.subject.reference = E.subject.reference
                and (M.encounter.reference = 'Encounter/' + E.id
                     or GetMedicationDate(M) during Interval[GetAdmissionDate(E), GetDischargeDate(E)])
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
    indicatorName: '急性心肌梗塞(AMI)病人於住院期間給藥比率 - 阿斯匹靈(Aspirin)',
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
      amiExcludedCases: Count("Inpatient Encounters with AMI Exclusion Diagnosis"),
      bleedingExcludedCases: Count("Inpatient Encounters with Bleeding Diagnosis"),
      finalCases: Count("Final Denominator"),
      diagnosisDistribution: "AMI Diagnosis Distribution"
    },
    aspirinStats: Tuple {
      casesWithAspirin: Count("Final Numerator"),
      casesWithoutAspirin: Count("Final Denominator") - Count("Final Numerator"),
      averageAspirinOrdersPerCase: 
        if Count("Final Numerator") > 0
        then Round(
          Sum("Aspirin Administration Timing Analysis" T return T.totalAspirinOrders) / Count("Final Numerator"), 
          2
        )
        else 0,
      averageDaysToFirstAspirin: 
        if Count("Aspirin Administration Timing Analysis") > 0
        then Round(
          Avg("Aspirin Administration Timing Analysis" T return T.daysFromAdmission),
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
    exclusionStats: Tuple {
      totalExcluded: Count("Inpatient Encounters with AMI Exclusion Diagnosis") + 
                     Count("Inpatient Encounters with Bleeding Diagnosis"),
      amiExclusionDetails: "AMI Exclusion Cases Statistics",
      bleedingExclusionDetails: "Bleeding Exclusion Cases Statistics"
    },
    qualityChecks: "Quality Checks"
  }
