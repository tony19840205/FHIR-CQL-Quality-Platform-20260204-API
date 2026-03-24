library Indicator_Asthma_Readmission_Within_14Days_Rate version '1.0.0'

/*
指標名稱: 氣喘病人出院後十四日以內因同一疾病再入院比率
指標編號: [待確認]
適用期間: 2026年 (民國115年)
條件依據：氣喘病人出院後十四日以內因同一疾病再入院比率

指標說明：
============================================================

氣喘病人出院後十四日以內因同一疾病再入院比率 = 
    分子: 14天内再入院人次，指氣喘病患出院人次中，於出院後14天内又再(因氣喘診斷)入院的人次。
    分母: 氣喘出院人次，指氣喘病患(註)因氣喘住院(主診斷ICD-10-CM前三碼為J45)人次中，
         在統計期間出院的人次。

備註：
------------------------------------------------------------
(1)氣喘病患定義：在觀察期間，符合下列A、B、C任一項條件者視為氣喘病患：
   A：有1次(含)以上急診就醫且主診斷ICD-10-CM前三碼為J45。
   B：有1次(含)以上住院且主診斷ICD-10-CM前三碼為J45。
   C：全年有4次(含)以上的主診斷ICD-10-CM前三碼為J45的門診就醫，
      且有2次(含)有使用藥理分類：R03AC02、R03AC03、R03AC04、R03AC06、
      R03AC16、R03AC12、R03AC13、R03AC18、R03BA01、R03BA02、R03BA05、
      R03BA08、R03AK06、R03AK07、H02AB06、H02AB07、R03DC03、R03DC01、
      R03DA05、R03AK08、R03AK10中任一項氣喘用藥者。

(2)14天计算：出院日期（不含當日）+ 14天
   例：1/1出院，再入院日期需 <= 1/15

(3)跨院勾稽：需追蹤不同醫療機構的再入院情形

------------------------------------------------------------

FHIR Resource 對應：
  分子：Encounter (再入院), Condition (氣喘診斷)
  分母：Patient, Encounter (住院出院), Condition (氣喘診斷), 
        MedicationRequest (氣喘用藥)

品質計算：
  - 統計期間：年度統計
  - 計算週期：每年
  - 跨院勾稽：是
  - 計算單位：人次
============================================================
*/

using FHIR version '4.0.1'

// ============================================================
// 參數定義
// ============================================================
parameter MeasurementPeriod Interval<DateTime> default Interval[@2026-01-01T00:00:00.0, @2027-01-01T00:00:00.0)

// 擴展觀察期間（用於追蹤再入院）
parameter ExtendedObservationPeriod Interval<DateTime> default Interval[@2026-01-01T00:00:00.0, @2027-01-15T00:00:00.0)

// ============================================================
// Codesystem 定義
// ============================================================
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED-CT": 'http://snomed.info/sct'

// ============================================================
// ValueSet 定義
// ============================================================

// 氣喘診斷代碼 (ICD-10-CM J45)
valueset "Asthma Diagnosis Codes": 'Asthma-Diagnosis-Codes'
  
// 氣喘用藥 ATC 代碼
valueset "Asthma Medication ATC Codes": 'Asthma-Medication-ATC-Codes'

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
    // β2 腎上腺素受體致效劑 (短效)
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
// 輔助函數：取得 Encounter 的日期
// ============================================================
define function GetEncounterStartDate(encounter Encounter):
  Coalesce(
    start of encounter.period,
    encounter.period.start
  )

define function GetEncounterEndDate(encounter Encounter):
  Coalesce(
    end of encounter.period,
    encounter.period.end
  )

define function GetDischargeDate(encounter Encounter):
  if encounter.hospitalization is not null 
    and encounter.hospitalization.dischargeDisposition is not null
  then GetEncounterEndDate(encounter)
  else GetEncounterEndDate(encounter)

define function GetAdmissionDate(encounter Encounter):
  GetEncounterStartDate(encounter)

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
// 氣喘病患定義 - 條件 A：急診氣喘病人
// ============================================================
define "Emergency Asthma Encounters":
  [Encounter] E
    where GetEncounterStartDate(E) during MeasurementPeriod
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

// ============================================================
// 氣喘病患定義 - 條件 B：住院氣喘病人
// ============================================================
define "Inpatient Asthma Encounters":
  [Encounter] E
    where GetEncounterStartDate(E) during MeasurementPeriod
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

// ============================================================
// 氣喘病患定義 - 條件 C：門診氣喘病人 (4次以上門診 + 2次以上用藥)
// ============================================================
define "Outpatient Asthma Encounters":
  [Encounter] E
    where GetEncounterStartDate(E) during MeasurementPeriod
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

// ============================================================
// 氣喘病患：符合 A 或 B 或 C
// ============================================================
define "Asthma Patients":
  "Patients with Emergency Asthma"
    union "Patients with Inpatient Asthma"
    union "Patients with Outpatient Asthma and Medication"

// ============================================================
// 分母：氣喘病患因氣喘住院（主診斷 J45）且在統計期間出院的人次
// ============================================================
define "Asthma Inpatient Encounters with Discharge in Measurement Period":
  "Inpatient Asthma Encounters" E
    where E.subject.reference in (
      "Asthma Patients" P return 'Patient/' + P.id
    )
    and GetDischargeDate(E) during MeasurementPeriod
    and exists(
      [Condition] C
        where C.encounter.reference = 'Encounter/' + E.id
          and IsAsthmaDiagnosis(C)
          and IsPrimaryDiagnosis(C)
    )

define "Denominator":
  "Asthma Inpatient Encounters with Discharge in Measurement Period"

// ============================================================
// 分子：分母中出院後14天内又因氣喘（主診斷 J45）再次住院的人次
// ============================================================

// 查找所有可能的再入院（包括跨院）
define "All Asthma Readmissions":
  [Encounter] E
    where GetAdmissionDate(E) during ExtendedObservationPeriod
      and IsInpatientEncounter(E)
      and exists(
        [Condition] C
          where C.encounter.reference = 'Encounter/' + E.id
            and IsAsthmaDiagnosis(C)
            and IsPrimaryDiagnosis(C)
      )

// 配對初次出院與再入院
define "Index Discharges with Readmission Within 14 Days":
  "Denominator" IndexEncounter
    let dischargeDate: GetDischargeDate(IndexEncounter),
        patientRef: IndexEncounter.subject.reference,
        readmissionWindow: Interval[dischargeDate + 1 day, dischargeDate + 14 days]
    where exists(
      "All Asthma Readmissions" ReadmissionEncounter
        where ReadmissionEncounter.subject.reference = patientRef
          and ReadmissionEncounter.id != IndexEncounter.id
          and GetAdmissionDate(ReadmissionEncounter) in readmissionWindow
    )

define "Numerator":
  "Index Discharges with Readmission Within 14 Days"

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
// 統計資訊
// ============================================================

// 氣喘病患分類統計
define "Asthma Patient Classification":
  Tuple {
    emergencyOnly: Count("Patients with Emergency Asthma" except ("Patients with Inpatient Asthma" union "Patients with Outpatient Asthma and Medication")),
    inpatientOnly: Count("Patients with Inpatient Asthma" except ("Patients with Emergency Asthma" union "Patients with Outpatient Asthma and Medication")),
    outpatientOnly: Count("Patients with Outpatient Asthma and Medication" except ("Patients with Emergency Asthma" union "Patients with Inpatient Asthma")),
    multipleCategories: Count("Asthma Patients") - (
      Count("Patients with Emergency Asthma" except ("Patients with Inpatient Asthma" union "Patients with Outpatient Asthma and Medication")) +
      Count("Patients with Inpatient Asthma" except ("Patients with Emergency Asthma" union "Patients with Outpatient Asthma and Medication")) +
      Count("Patients with Outpatient Asthma and Medication" except ("Patients with Emergency Asthma" union "Patients with Inpatient Asthma"))
    )
  }

// 出院時間分布
define "Discharge Month Distribution":
  "Denominator" E
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
      end
    }

// 再入院時間間隔分析
define "Readmission Time Interval Analysis":
  "Index Discharges with Readmission Within 14 Days" IndexEncounter
    let dischargeDate: GetDischargeDate(IndexEncounter),
        patientRef: IndexEncounter.subject.reference,
        readmissionEncounters: 
          "All Asthma Readmissions" ReadmissionEncounter
            where ReadmissionEncounter.subject.reference = patientRef
              and ReadmissionEncounter.id != IndexEncounter.id
              and GetAdmissionDate(ReadmissionEncounter) in Interval[dischargeDate + 1 day, dischargeDate + 14 days],
        earliestReadmission: 
          First(
            readmissionEncounters R
              sort by GetAdmissionDate(R)
          ),
        daysToReadmission: 
          days between dischargeDate and GetAdmissionDate(earliestReadmission)
    return Tuple {
      indexEncounterId: IndexEncounter.id,
      patientId: patientRef,
      dischargeDate: dischargeDate,
      readmissionDate: GetAdmissionDate(earliestReadmission),
      daysToReadmission: daysToReadmission,
      readmissionTimeCategory: case 
        when daysToReadmission <= 3 then '0-3天'
        when daysToReadmission <= 7 then '4-7天'
        when daysToReadmission <= 14 then '8-14天'
        else '超過14天'
      end
    }

// 住院天數分析
define "Length of Stay Analysis":
  "Denominator" E
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
      end
    }

// 跨院再入院分析
define "Cross Facility Readmission Analysis":
  "Index Discharges with Readmission Within 14 Days" IndexEncounter
    let dischargeDate: GetDischargeDate(IndexEncounter),
        patientRef: IndexEncounter.subject.reference,
        indexFacility: IndexEncounter.serviceProvider.reference,
        readmissionEncounters: 
          "All Asthma Readmissions" ReadmissionEncounter
            where ReadmissionEncounter.subject.reference = patientRef
              and ReadmissionEncounter.id != IndexEncounter.id
              and GetAdmissionDate(ReadmissionEncounter) in Interval[dischargeDate + 1 day, dischargeDate + 14 days],
        earliestReadmission: 
          First(
            readmissionEncounters R
              sort by GetAdmissionDate(R)
          ),
        readmissionFacility: earliestReadmission.serviceProvider.reference,
        isCrossFacility: indexFacility != readmissionFacility
    return Tuple {
      indexEncounterId: IndexEncounter.id,
      patientId: patientRef,
      indexFacility: indexFacility,
      readmissionFacility: readmissionFacility,
      isCrossFacility: isCrossFacility,
      readmissionType: if isCrossFacility then '跨院再入院' else '同院再入院'
    }

// ============================================================
// 品質檢核
// ============================================================
define "Quality Checks":
  {
    Tuple {
      checkName: '分母人次檢核',
      description: '確認分母人次（氣喘出院人次）> 0',
      passed: Count("Final Denominator") > 0,
      value: Count("Final Denominator")
    },
    Tuple {
      checkName: '分子分母邏輯檢核',
      description: '確認分子人次 <= 分母人次',
      passed: Count("Final Numerator") <= Count("Final Denominator"),
      numerator: Count("Final Numerator"),
      denominator: Count("Final Denominator")
    },
    Tuple {
      checkName: '氣喘病患定義檢核',
      description: '確認氣喘病患人數 > 0',
      passed: Count("Asthma Patients") > 0,
      value: Count("Asthma Patients")
    },
    Tuple {
      checkName: '出院日期檢核',
      description: '確認所有分母案件的出院日期在統計期間內',
      passed: not exists(
        "Denominator" E
          where not (GetDischargeDate(E) during MeasurementPeriod)
      ),
      totalEncounters: Count("Denominator")
    },
    Tuple {
      checkName: '再入院時間檢核',
      description: '確認所有再入院案件的間隔 <= 14天',
      passed: not exists(
        "Readmission Time Interval Analysis" R
          where R.daysToReadmission > 14
      ),
      totalReadmissions: Count("Readmission Time Interval Analysis")
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
    indicatorName: '氣喘病人出院後十四日以內因同一疾病再入院比率',
    measurementPeriod: MeasurementPeriod,
    denominator: Count("Final Denominator"),
    numerator: Count("Final Numerator"),
    exclusions: Count("Exclusions"),
    indicatorScore: "Indicator Score",
    asthmaPatientStats: Tuple {
      totalAsthmaPatients: Count("Asthma Patients"),
      emergencyPatients: Count("Patients with Emergency Asthma"),
      inpatientPatients: Count("Patients with Inpatient Asthma"),
      outpatientPatients: Count("Patients with Outpatient Asthma and Medication"),
      patientClassification: "Asthma Patient Classification"
    },
    dischargeStats: Tuple {
      totalDischarges: Count("Denominator"),
      dischargesWithReadmission: Count("Numerator"),
      averageLengthOfStay: Avg(
        "Length of Stay Analysis" L return L.lengthOfStay
      )
    },
    readmissionStats: Tuple {
      totalReadmissions: Count("Index Discharges with Readmission Within 14 Days"),
      averageDaysToReadmission: Avg(
        "Readmission Time Interval Analysis" R return R.daysToReadmission
      ),
      crossFacilityReadmissions: Count(
        "Cross Facility Readmission Analysis" C where C.isCrossFacility
      ),
      sameFacilityReadmissions: Count(
        "Cross Facility Readmission Analysis" C where not C.isCrossFacility
      )
    },
    qualityChecks: "Quality Checks"
  }
