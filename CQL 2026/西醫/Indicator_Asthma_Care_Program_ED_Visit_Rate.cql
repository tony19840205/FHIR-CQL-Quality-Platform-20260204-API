library Indicator_Asthma_Care_Program_ED_Visit_Rate version '1.0.0'

/*
指標名稱: 參加「全民健康保險氣喘醫療給付改善方案」之病人因氣喘發作而至急診就醫之比率
指標編號: [待確認]
適用期間: 2026年 (民國115年)
條件依據：參加「全民健康保險氣喘醫療給付改善方案」之病人因氣喘發作而至急診就醫之比率

指標說明：
============================================================

參加「全民健康保險氣喘醫療給付改善方案」之病人因氣喘發作而至急診就醫之比率 = 
    分子: 因氣喘發作至急診就醫的人數，加入照護計畫的病人，在統計期間，
         有1次(含)以上因氣喘(主診斷碼ICD-10-CM前三碼為J45者)至急診就醫的人數。
    分母: 加入照護計畫人數，指院所將其照護的氣喘病人收案進入「氣喘醫療給付改善方案」的人數。
         （有申報P1612C、P1613C、P1614B、P1615C任一計畫醫令者）

備註：
------------------------------------------------------------
(1)氣喘病人定義：在觀察期間，符合下列A、B、C任一項條件者視為氣喘病人：
   A：有1次(含)以上急診就醫且主診斷ICD-10-CM前三碼為J45。
   B：有1次(含)以上住院且主診斷ICD-10-CM前三碼為J45。
   C：全年有4次(含)以上的主診斷ICD-10-CM前三碼為J45的門診就醫，
      且有2次(含)有使用藥理分類：R03AC02、R03AC03、R03AC04、R03AC06、
      R03AC16、R03AC12、R03AC13、R03AC18、R03BA01、R03BA02、R03BA05、
      R03BA08、R03AK06、R03AK07、H02AB06、H02AB07、R03DC03、R03DC01、
      R03DA05、R03AK08、R03AK10中任一項氣喘用藥者。

(2)氣喘醫療給付改善方案計畫醫令代碼：P1612C、P1613C、P1614B、P1615C

(3)計算單位：人數（非人次）

(4)急診定義：主診斷ICD-10-CM前三碼為J45的急診案件

------------------------------------------------------------

FHIR Resource 對應：
  分子：Encounter (急診), Condition (氣喘診斷), CarePlan/Procedure (照護計畫)
  分母：Patient, CarePlan/Procedure (氣喘照護計畫)

品質計算：
  - 統計期間：年度統計
  - 計算週期：每年
  - 跨院勾稽：是
  - 計算單位：人數
============================================================
*/

using FHIR version '4.0.1'

// ============================================================
// 參數定義
// ============================================================
parameter MeasurementPeriod Interval<DateTime> default Interval[@2026-01-01T00:00:00.0, @2027-01-01T00:00:00.0)

// ============================================================
// Codesystem 定義
// ============================================================
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHI-Procedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/health-insurance-treatment-code-tw'
codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED-CT": 'http://snomed.info/sct'

// ============================================================
// ValueSet 定義
// ============================================================

// 氣喘診斷代碼 (ICD-10-CM J45)
valueset "Asthma Diagnosis Codes": 'Asthma-Diagnosis-Codes'
  
// 氣喘用藥 ATC 代碼
valueset "Asthma Medication ATC Codes": 'Asthma-Medication-ATC-Codes'

// 氣喘醫療給付改善方案計畫代碼
valueset "Asthma Care Program Procedure Codes": 'Asthma-Care-Program-Procedure-Codes'

// ============================================================
// Code 定義 - 氣喘診斷
// ============================================================
define "Asthma Diagnosis Code List":
  {
    Code { code: 'J45', system: "ICD10CM", display: '氣喘' },
    Code { code: 'J450', system: "ICD10CM", display: '以過敏為主的氣喘' },
    Code { code: 'J451', system: "ICD10CM", display: '非過敏性氣喘' },
    Code { code: 'J452', system: "ICD10CM", display: '混合型氣喘' },
    Code { code: 'J453', system: "ICD10CM", display: '輕度間歇性氣喘' },
    Code { code: 'J454', system: "ICD10CM", display: '輕度持續性氣喘' },
    Code { code: 'J455', system: "ICD10CM", display: '中度持續性氣喘' },
    Code { code: 'J458', system: "ICD10CM", display: '其他及混合型氣喘' },
    Code { code: 'J459', system: "ICD10CM", display: '氣喘，未明示' }
  }

// ============================================================
// Code 定義 - 氣喘用藥 ATC 代碼
// ============================================================
define "Asthma Medication ATC Code List":
  {
    // β2 腎上腺素受體致效劑
    Code { code: 'R03AC02', system: "ATC", display: 'salbutamol (短效β2致效劑)' },
    Code { code: 'R03AC03', system: "ATC", display: 'terbutaline (短效β2致效劑)' },
    Code { code: 'R03AC04', system: "ATC", display: 'fenoterol (短效β2致效劑)' },
    Code { code: 'R03AC06', system: "ATC", display: 'hexoprenaline (短效β2致效劑)' },
    Code { code: 'R03AC12', system: "ATC", display: 'salmeterol (長效β2致效劑)' },
    Code { code: 'R03AC13', system: "ATC", display: 'formoterol (長效β2致效劑)' },
    Code { code: 'R03AC16', system: "ATC", display: 'procaterol (短效β2致效劑)' },
    Code { code: 'R03AC18', system: "ATC", display: 'indacaterol (長效β2致效劑)' },
    
    // 糖皮質激素 (吸入型)
    Code { code: 'R03BA01', system: "ATC", display: 'beclometasone (吸入型皮質類固醇)' },
    Code { code: 'R03BA02', system: "ATC", display: 'budesonide (吸入型皮質類固醇)' },
    Code { code: 'R03BA05', system: "ATC", display: 'fluticasone (吸入型皮質類固醇)' },
    Code { code: 'R03BA08', system: "ATC", display: 'ciclesonide (吸入型皮質類固醇)' },
    
    // 複方製劑 (β2致效劑+皮質類固醇)
    Code { code: 'R03AK06', system: "ATC", display: 'salmeterol + fluticasone (複方吸入劑)' },
    Code { code: 'R03AK07', system: "ATC", display: 'formoterol + budesonide (複方吸入劑)' },
    Code { code: 'R03AK08', system: "ATC", display: 'formoterol + beclometasone (複方吸入劑)' },
    Code { code: 'R03AK10', system: "ATC", display: 'vilanterol + fluticasone (複方吸入劑)' },
    
    // 白三烯受體拮抗劑
    Code { code: 'R03DC01', system: "ATC", display: 'zafirlukast (白三烯受體拮抗劑)' },
    Code { code: 'R03DC03', system: "ATC", display: 'montelukast (白三烯受體拮抗劑)' },
    
    // 甲基黃嘌呤類支氣管擴張劑
    Code { code: 'R03DA05', system: "ATC", display: 'aminophylline (甲基黃嘌呤)' },
    
    // 全身性皮質類固醇
    Code { code: 'H02AB06', system: "ATC", display: 'prednisolone (口服皮質類固醇)' },
    Code { code: 'H02AB07', system: "ATC", display: 'prednisone (口服皮質類固醇)' }
  }

// ============================================================
// Code 定義 - 氣喘照護計畫代碼
// ============================================================
define "Asthma Care Program Code List":
  {
    Code { code: 'P1612C', system: "NHI-Procedure", display: '氣喘醫療給付改善方案-初次收案' },
    Code { code: 'P1613C', system: "NHI-Procedure", display: '氣喘醫療給付改善方案-第一次追蹤' },
    Code { code: 'P1614B', system: "NHI-Procedure", display: '氣喘醫療給付改善方案-第二次以後追蹤' },
    Code { code: 'P1615C', system: "NHI-Procedure", display: '氣喘醫療給付改善方案-年度評估' }
  }

// ============================================================
// 初始病患群組
// ============================================================
define "Initial Patient Population":
  [Patient] P
    where P.active is true

// ============================================================
// 輔助函數：取得 Condition 的主診斷代碼
// ============================================================
define function GetPrimaryDiagnosisCode(condition Condition):
  if condition.code is not null 
  then condition.code.coding[0].code
  else null

// ============================================================
// 輔助函數：檢查診斷代碼是否為氣喘 (J45)
// ============================================================
define function IsAsthmaDiagnosis(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          C.code = 'J45'
          or C.code starts with 'J45'
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

define function IsEmergencyEncounter(encounter Encounter):
  GetEncounterClass(encounter) in { 'EMER', 'emergency' }

define function IsInpatientEncounter(encounter Encounter):
  GetEncounterClass(encounter) in { 'IMP', 'inpatient', 'acute' }

define function IsOutpatientEncounter(encounter Encounter):
  GetEncounterClass(encounter) in { 'AMB', 'outpatient', 'ambulatory' }

// ============================================================
// 輔助函數：取得 Encounter 的就醫日期
// ============================================================
define function GetEncounterDate(encounter Encounter):
  Coalesce(
    start of encounter.period,
    encounter.period.start,
    encounter.period.end
  )

// ============================================================
// 輔助函數：檢查藥品 ATC 代碼
// ============================================================
define function GetMedicationATCCode(medication MedicationRequest):
  medication.medication.concept.coding C
    where C.system = 'http://www.whocc.no/atc'
    return C.code

define function HasAsthmaATCCode(medication MedicationRequest):
  exists(
    GetMedicationATCCode(medication) atcCode
      where atcCode in {
        'R03AC02', 'R03AC03', 'R03AC04', 'R03AC06',
        'R03AC16', 'R03AC12', 'R03AC13', 'R03AC18',
        'R03BA01', 'R03BA02', 'R03BA05', 'R03BA08',
        'R03AK06', 'R03AK07', 'H02AB06', 'H02AB07',
        'R03DC03', 'R03DC01', 'R03DA05', 'R03AK08', 'R03AK10'
      }
  )

// ============================================================
// 輔助函數：取得藥品開立日期
// ============================================================
define function GetMedicationDate(medication MedicationRequest):
  Coalesce(
    medication.authoredOn,
    start of medication.dosageInstruction[0].timing.repeat.bounds as Period
  )

// ============================================================
// 氣喘病患定義（用於參考，確保分母病人也符合氣喘定義）
// ============================================================

// 條件 A：急診氣喘病人
define "Emergency Asthma Encounters":
  [Encounter] E
    where GetEncounterDate(E) during MeasurementPeriod
      and IsEmergencyEncounter(E)
      and exists(
        [Condition] C
          where C.encounter.reference = 'Encounter/' + E.id
            and IsAsthmaDiagnosis(C)
            and IsPrimaryDiagnosis(C)
      )

define "Patients with Emergency Asthma":
  "Initial Patient Population" P
    where exists(
      "Emergency Asthma Encounters" E
        where E.subject.reference = 'Patient/' + P.id
    )

// 條件 B：住院氣喘病人
define "Inpatient Asthma Encounters":
  [Encounter] E
    where GetEncounterDate(E) during MeasurementPeriod
      and IsInpatientEncounter(E)
      and exists(
        [Condition] C
          where C.encounter.reference = 'Encounter/' + E.id
            and IsAsthmaDiagnosis(C)
            and IsPrimaryDiagnosis(C)
      )

define "Patients with Inpatient Asthma":
  "Initial Patient Population" P
    where exists(
      "Inpatient Asthma Encounters" E
        where E.subject.reference = 'Patient/' + P.id
    )

// 條件 C：門診氣喘病人 (4次以上門診 + 2次以上用藥)
define "Outpatient Asthma Encounters":
  [Encounter] E
    where GetEncounterDate(E) during MeasurementPeriod
      and IsOutpatientEncounter(E)
      and exists(
        [Condition] C
          where C.encounter.reference = 'Encounter/' + E.id
            and IsAsthmaDiagnosis(C)
            and IsPrimaryDiagnosis(C)
      )

define "Asthma Medications in Measurement Period":
  [MedicationRequest] M
    where GetMedicationDate(M) during MeasurementPeriod
      and HasAsthmaATCCode(M)
      and M.status in { 'active', 'completed' }

define "Outpatient Encounters with Asthma Medication":
  "Outpatient Asthma Encounters" E
    where exists(
      "Asthma Medications in Measurement Period" M
        where M.encounter.reference = 'Encounter/' + E.id
    )

define "Patients with Outpatient Asthma and Medication":
  "Initial Patient Population" P
    let patientOutpatientEncounters: 
      "Outpatient Asthma Encounters" E
        where E.subject.reference = 'Patient/' + P.id,
    patientMedicationEncounters:
      "Outpatient Encounters with Asthma Medication" E
        where E.subject.reference = 'Patient/' + P.id
    where Count(patientOutpatientEncounters) >= 4
      and Count(patientMedicationEncounters) >= 2

// 氣喘病患：符合 A 或 B 或 C
define "Asthma Patients":
  "Patients with Emergency Asthma"
    union "Patients with Inpatient Asthma"
    union "Patients with Outpatient Asthma and Medication"

// ============================================================
// 分母：參加氣喘照護計畫的病人
// ============================================================
define "Asthma Care Program Procedures":
  [Procedure] P
    where P.performed during MeasurementPeriod
      and P.status = 'completed'
      and exists(
        P.code.coding C
          where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/health-insurance-treatment-code-tw'
            and C.code in { 'P1612C', 'P1613C', 'P1614B', 'P1615C' }
      )

define "Asthma Care Plans":
  [CarePlan] CP
    where CP.period overlaps MeasurementPeriod
      and CP.status in { 'active', 'completed' }
      and exists(
        CP.category C
          where exists(
            C.coding CD
              where CD.code in { 'P1612C', 'P1613C', 'P1614B', 'P1615C' }
          )
      )

define "Patients Enrolled in Asthma Care Program":
  "Initial Patient Population" P
    where exists(
      "Asthma Care Program Procedures" Proc
        where Proc.subject.reference = 'Patient/' + P.id
    )
    or exists(
      "Asthma Care Plans" CP
        where CP.subject.reference = 'Patient/' + P.id
    )

define "Denominator":
  "Patients Enrolled in Asthma Care Program"

// ============================================================
// 分子：參加照護計畫的病人中，因氣喘至急診就醫的人數
// ============================================================
define "Asthma ED Visits in Measurement Period":
  [Encounter] E
    where GetEncounterDate(E) during MeasurementPeriod
      and IsEmergencyEncounter(E)
      and exists(
        [Condition] C
          where C.encounter.reference = 'Encounter/' + E.id
            and IsAsthmaDiagnosis(C)
            and IsPrimaryDiagnosis(C)
      )

define "Patients in Care Program with Asthma ED Visit":
  "Denominator" P
    where exists(
      "Asthma ED Visits in Measurement Period" E
        where E.subject.reference = 'Patient/' + P.id
    )

define "Numerator":
  "Patients in Care Program with Asthma ED Visit"

// ============================================================
// 排除條件
// ============================================================
define "Exclusions":
  {} as List<Patient>

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
// 統計資訊
// ============================================================

// 照護計畫類型統計
define "Care Program Type Distribution":
  "Asthma Care Program Procedures" P
    let programCode: P.code.coding[0].code
    return Tuple {
      programType: programCode,
      programName: case programCode
        when 'P1612C' then '初次收案'
        when 'P1613C' then '第一次追蹤'
        when 'P1614B' then '第二次以後追蹤'
        when 'P1615C' then '年度評估'
        else '未知'
      end,
      patientId: P.subject.reference,
      performedDate: P.performed
    }

// 急診次數分析
define "ED Visit Frequency Analysis":
  "Final Numerator" P
    let patientEDVisits:
      "Asthma ED Visits in Measurement Period" E
        where E.subject.reference = 'Patient/' + P.id
    return Tuple {
      patientId: P.id,
      edVisitCount: Count(patientEDVisits),
      edVisitCategory: case
        when Count(patientEDVisits) = 1 then '1次'
        when Count(patientEDVisits) = 2 then '2次'
        when Count(patientEDVisits) = 3 then '3次'
        when Count(patientEDVisits) >= 4 then '4次以上'
        else '0次'
      end
    }

// 急診時間分布
define "ED Visit Month Distribution":
  "Asthma ED Visits in Measurement Period" E
    let encounterDate: GetEncounterDate(E),
        monthOfYear: month from encounterDate
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      edVisitDate: encounterDate,
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
      end
    }

// 急診時段分析（時辰分析）
define "ED Visit Time Analysis":
  "Asthma ED Visits in Measurement Period" E
    let encounterTime: GetEncounterDate(E),
        hourOfDay: hour from encounterTime
    return Tuple {
      encounterId: E.id,
      patientId: E.subject.reference,
      edVisitDateTime: encounterTime,
      hourOfDay: hourOfDay,
      timeCategory: case
        when hourOfDay >= 0 and hourOfDay < 6 then '凌晨(0-6時)'
        when hourOfDay >= 6 and hourOfDay < 12 then '上午(6-12時)'
        when hourOfDay >= 12 and hourOfDay < 18 then '下午(12-18時)'
        when hourOfDay >= 18 and hourOfDay < 24 then '晚上(18-24時)'
        else '未知'
      end
    }

// 照護計畫與急診關係分析
define "Care Program and ED Visit Timeline":
  "Final Numerator" P
    let patientCarePlans:
      "Asthma Care Plans" CP
        where CP.subject.reference = 'Patient/' + P.id,
    patientCareProcedures:
      "Asthma Care Program Procedures" Proc
        where Proc.subject.reference = 'Patient/' + P.id,
    patientEDVisits:
      "Asthma ED Visits in Measurement Period" E
        where E.subject.reference = 'Patient/' + P.id,
    firstCareDate: 
      Coalesce(
        Min(patientCarePlans CP return start of CP.period),
        Min(patientCareProcedures Proc return Proc.performed as DateTime)
      ),
    firstEDVisitDate:
      Min(patientEDVisits E return GetEncounterDate(E)),
    daysBetween:
      days between firstCareDate and firstEDVisitDate
    return Tuple {
      patientId: P.id,
      firstCareDate: firstCareDate,
      firstEDVisitDate: firstEDVisitDate,
      daysBetween: daysBetween,
      edVisitAfterEnrollment: daysBetween >= 0
    }

// 病人氣喘病患資格檢核
define "Patient Asthma Qualification Check":
  "Final Denominator" P
    return Tuple {
      patientId: P.id,
      isAsthmaPatient: P in "Asthma Patients",
      hasEmergencyAsthma: P in "Patients with Emergency Asthma",
      hasInpatientAsthma: P in "Patients with Inpatient Asthma",
      hasOutpatientAsthma: P in "Patients with Outpatient Asthma and Medication",
      hasEDVisit: P in "Final Numerator"
    }

// 急診與住院併發分析
define "ED and Hospitalization Co-occurrence":
  "Final Numerator" P
    let patientEDVisits:
      "Asthma ED Visits in Measurement Period" E
        where E.subject.reference = 'Patient/' + P.id,
    patientHospitalizations:
      "Inpatient Asthma Encounters" E
        where E.subject.reference = 'Patient/' + P.id
    return Tuple {
      patientId: P.id,
      totalEDVisits: Count(patientEDVisits),
      totalHospitalizations: Count(patientHospitalizations),
      hasBothEDAndHospitalization: 
        Count(patientEDVisits) > 0 and Count(patientHospitalizations) > 0,
      utilizationPattern: case
        when Count(patientEDVisits) > 0 and Count(patientHospitalizations) > 0 
          then '急診+住院'
        when Count(patientEDVisits) > 0 
          then '僅急診'
        when Count(patientHospitalizations) > 0 
          then '僅住院'
        else '無就醫'
      end
    }

// ============================================================
// 品質檢核
// ============================================================
define "Quality Checks":
  {
    Tuple {
      checkName: '分母人數檢核',
      description: '確認分母人數（參加照護計畫人數）> 0',
      passed: Count("Final Denominator") > 0,
      value: Count("Final Denominator")
    },
    Tuple {
      checkName: '分子分母邏輯檢核',
      description: '確認分子人數 <= 分母人數',
      passed: Count("Final Numerator") <= Count("Final Denominator"),
      numerator: Count("Final Numerator"),
      denominator: Count("Final Denominator")
    },
    Tuple {
      checkName: '照護計畫資料檢核',
      description: '確認照護計畫（Procedure或CarePlan）資料存在',
      passed: Count("Asthma Care Program Procedures") > 0 
              or Count("Asthma Care Plans") > 0,
      procedureCount: Count("Asthma Care Program Procedures"),
      carePlanCount: Count("Asthma Care Plans")
    },
    Tuple {
      checkName: '急診資料檢核',
      description: '確認氣喘急診資料正確',
      passed: Count("Asthma ED Visits in Measurement Period") >= Count("Final Numerator"),
      edEncounters: Count("Asthma ED Visits in Measurement Period"),
      patientsWithEDVisit: Count("Final Numerator")
    },
    Tuple {
      checkName: '主診斷檢核',
      description: '確認所有急診都有主診斷為J45',
      passed: not exists(
        "Asthma ED Visits in Measurement Period" E
          where not exists(
            [Condition] C
              where C.encounter.reference = 'Encounter/' + E.id
                and IsAsthmaDiagnosis(C)
                and IsPrimaryDiagnosis(C)
          )
      ),
      totalEDVisits: Count("Asthma ED Visits in Measurement Period")
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
    indicatorName: '參加「全民健康保險氣喘醫療給付改善方案」之病人因氣喘發作而至急診就醫之比率',
    measurementPeriod: MeasurementPeriod,
    denominator: Count("Final Denominator"),
    numerator: Count("Final Numerator"),
    exclusions: Count("Exclusions"),
    indicatorScore: "Indicator Score",
    careProgramStats: Tuple {
      totalEnrolled: Count("Patients Enrolled in Asthma Care Program"),
      procedureRecords: Count("Asthma Care Program Procedures"),
      carePlanRecords: Count("Asthma Care Plans"),
      programTypeBreakdown: "Care Program Type Distribution"
    },
    edVisitStats: Tuple {
      totalEDVisits: Count("Asthma ED Visits in Measurement Period"),
      patientsWithEDVisit: Count("Final Numerator"),
      averageEDVisitsPerPatient: 
        if Count("Final Numerator") > 0
        then Round(Count("Asthma ED Visits in Measurement Period") / Count("Final Numerator"), 2)
        else 0,
      edVisitFrequencyBreakdown: "ED Visit Frequency Analysis"
    },
    asthmaPatientQualification: Tuple {
      totalAsthmaPatients: Count("Asthma Patients"),
      enrolledAsthmaPatients: Count(
        "Final Denominator" P where P in "Asthma Patients"
      ),
      enrolledNonAsthmaPatients: Count(
        "Final Denominator" P where P not in "Asthma Patients"
      )
    },
    qualityChecks: "Quality Checks"
  }
