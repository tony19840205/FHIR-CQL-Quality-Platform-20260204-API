library Indicator_Asthma_SABA_ICS_Control_Rate version '1.0.0'

/*
指標名稱: 氣喘病人使用短效乙型作用劑或類固醇藥物吸入劑累積控制比率
指標編號: [待確認]
適用期間: 2026年 (民國115年)
條件依據：氣喘病人使用短效乙型作用劑或類固醇藥物吸入劑累積控制比率

指標說明：
============================================================

氣喘病人使用短效乙型作用劑或類固醇藥物吸入劑累積控制比率 = 
    分子: 使用短效乙型作用劑或類固醇藥物吸入劑人數，
         指氣喘病人，於門診有開立短效乙型作用劑或類固醇藥物吸入劑的人數。
    分母: 氣喘人數（詳備註）。

備註：
------------------------------------------------------------
(1)短效乙型作用劑或類固醇藥物吸入劑之藥理分類為：
   R03AC02、R03AC03、R03AC04、R03AC06、R03AC16 (短效β2作用劑)
   R03BA01、R03BA02、R03BA05、R03BA08 (吸入型皮質類固醇)
   R03AK06、R03AK07、R03AK08、R03AK10 (複方吸入劑-含類固醇)

(2)氣喘病人定義：在觀察期間，符合下列A、B、C任一項條件者視為氣喘病人：
   A：有1次(含)以上急診就醫且主診斷ICD-10-CM前三碼為J45。
   B：有1次(含)以上住院且主診斷ICD-10-CM前三碼為J45。
   C：全年有4次(含)以上的主診斷ICD-10-CM前三碼為J45的門診就醫，
      且有2次(含)有使用藥理分類：R03AC02、R03AC03、R03AC04、R03AC06、
      R03AC16、R03AC12、R03AC13、R03AC18、R03BA01、R03BA02、R03BA05、
      R03BA08、R03AK06、R03AK07、H02AB06、H02AB07、R03DC03、R03DC01、
      R03DA05、R03AK08、R03AK10中任一項氣喘用藥者。

(3)計算單位：人數（非人次）

------------------------------------------------------------

FHIR Resource 對應：
  分子：MedicationRequest (短效β2作用劑或類固醇吸入劑)
  分母：Patient, Encounter (急診/住院/門診), Condition (氣喘診斷), 
        MedicationRequest (氣喘用藥)

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
codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED-CT": 'http://snomed.info/sct'

// ============================================================
// ValueSet 定義
// ============================================================

// 氣喘診斷代碼 (ICD-10-CM J45)
valueset "Asthma Diagnosis Codes": 'Asthma-Diagnosis-Codes'
  
// 所有氣喘用藥 ATC 代碼（用於分母條件C）
valueset "All Asthma Medication ATC Codes": 'All-Asthma-Medication-ATC-Codes'

// 短效β2作用劑或類固醇吸入劑 ATC 代碼（用於分子）
valueset "SABA and ICS ATC Codes": 'SABA-ICS-ATC-Codes'

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
// Code 定義 - 所有氣喘用藥 ATC 代碼（用於分母條件C）
// ============================================================
define "All Asthma Medication ATC Code List":
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
// Code 定義 - 短效β2作用劑或類固醇吸入劑（用於分子）
// ============================================================
define "SABA and ICS ATC Code List":
  {
    // 短效β2腎上腺素受體致效劑 (SABA)
    Code { code: 'R03AC02', system: "ATC", display: 'salbutamol (短效β2致效劑)' },
    Code { code: 'R03AC03', system: "ATC", display: 'terbutaline (短效β2致效劑)' },
    Code { code: 'R03AC04', system: "ATC", display: 'fenoterol (短效β2致效劑)' },
    Code { code: 'R03AC06', system: "ATC", display: 'hexoprenaline (短效β2致效劑)' },
    Code { code: 'R03AC16', system: "ATC", display: 'procaterol (短效β2致效劑)' },
    
    // 吸入型皮質類固醇 (ICS)
    Code { code: 'R03BA01', system: "ATC", display: 'beclometasone (吸入型皮質類固醇)' },
    Code { code: 'R03BA02', system: "ATC", display: 'budesonide (吸入型皮質類固醇)' },
    Code { code: 'R03BA05', system: "ATC", display: 'fluticasone (吸入型皮質類固醇)' },
    Code { code: 'R03BA08', system: "ATC", display: 'ciclesonide (吸入型皮質類固醇)' },
    
    // 複方吸入劑 (含類固醇)
    Code { code: 'R03AK06', system: "ATC", display: 'salmeterol + fluticasone (複方吸入劑)' },
    Code { code: 'R03AK07', system: "ATC", display: 'formoterol + budesonide (複方吸入劑)' },
    Code { code: 'R03AK08', system: "ATC", display: 'formoterol + beclometasone (複方吸入劑)' },
    Code { code: 'R03AK10', system: "ATC", display: 'vilanterol + fluticasone (複方吸入劑)' }
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

define function HasAllAsthmaATCCode(medication MedicationRequest):
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

define function HasSABAorICSATCCode(medication MedicationRequest):
  exists(
    GetMedicationATCCode(medication) atcCode
      where atcCode in {
        'R03AC02', 'R03AC03', 'R03AC04', 'R03AC06', 'R03AC16',
        'R03BA01', 'R03BA02', 'R03BA05', 'R03BA08',
        'R03AK06', 'R03AK07', 'R03AK08', 'R03AK10'
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
// 分母條件 A：急診氣喘病人
// ============================================================
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

// ============================================================
// 分母條件 B：住院氣喘病人
// ============================================================
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

// ============================================================
// 分母條件 C：門診氣喘病人 (4次以上門診 + 2次以上用藥)
// ============================================================
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

define "All Asthma Medications in Measurement Period":
  [MedicationRequest] M
    where GetMedicationDate(M) during MeasurementPeriod
      and HasAllAsthmaATCCode(M)
      and M.status in { 'active', 'completed' }

define "Outpatient Encounters with Asthma Medication":
  "Outpatient Asthma Encounters" E
    where exists(
      "All Asthma Medications in Measurement Period" M
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
// 分母：氣喘病人 (符合 A 或 B 或 C)
// ============================================================
define "Denominator":
  "Patients with Emergency Asthma"
    union "Patients with Inpatient Asthma"
    union "Patients with Outpatient Asthma and Medication"

// ============================================================
// 分子：氣喘病人於門診開立短效β2作用劑或類固醇吸入劑
// ============================================================
define "Outpatient Encounters in Measurement Period":
  [Encounter] E
    where GetEncounterDate(E) during MeasurementPeriod
      and IsOutpatientEncounter(E)

define "SABA or ICS Medications in Outpatient":
  [MedicationRequest] M
    where GetMedicationDate(M) during MeasurementPeriod
      and HasSABAorICSATCCode(M)
      and M.status in { 'active', 'completed' }
      and exists(
        "Outpatient Encounters in Measurement Period" E
          where M.encounter.reference = 'Encounter/' + E.id
      )

define "Patients with SABA or ICS Medication":
  "Denominator" P
    where exists(
      "SABA or ICS Medications in Outpatient" M
        where M.subject.reference = 'Patient/' + P.id
    )

define "Numerator":
  "Patients with SABA or ICS Medication"

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

// 分母細項統計
define "Denominator Breakdown":
  Tuple {
    emergencyPatients: Count("Patients with Emergency Asthma"),
    inpatientPatients: Count("Patients with Inpatient Asthma"),
    outpatientPatients: Count("Patients with Outpatient Asthma and Medication"),
    totalDenominator: Count("Final Denominator")
  }

// SABA/ICS 藥品使用分析
define "SABA ICS Medication Type Analysis":
  "SABA or ICS Medications in Outpatient" M
    let atcCode: GetMedicationATCCode(M)[0],
        medicationType: case atcCode
          when 'R03AC02' then 'SABA-短效β2作用劑'
          when 'R03AC03' then 'SABA-短效β2作用劑'
          when 'R03AC04' then 'SABA-短效β2作用劑'
          when 'R03AC06' then 'SABA-短效β2作用劑'
          when 'R03AC16' then 'SABA-短效β2作用劑'
          when 'R03BA01' then 'ICS-吸入型皮質類固醇'
          when 'R03BA02' then 'ICS-吸入型皮質類固醇'
          when 'R03BA05' then 'ICS-吸入型皮質類固醇'
          when 'R03BA08' then 'ICS-吸入型皮質類固醇'
          when 'R03AK06' then 'Combination-複方吸入劑(含類固醇)'
          when 'R03AK07' then 'Combination-複方吸入劑(含類固醇)'
          when 'R03AK08' then 'Combination-複方吸入劑(含類固醇)'
          when 'R03AK10' then 'Combination-複方吸入劑(含類固醇)'
          else 'Unknown'
        end,
        drugName: case atcCode
          when 'R03AC02' then 'salbutamol'
          when 'R03AC03' then 'terbutaline'
          when 'R03AC04' then 'fenoterol'
          when 'R03AC06' then 'hexoprenaline'
          when 'R03AC16' then 'procaterol'
          when 'R03BA01' then 'beclometasone'
          when 'R03BA02' then 'budesonide'
          when 'R03BA05' then 'fluticasone'
          when 'R03BA08' then 'ciclesonide'
          when 'R03AK06' then 'salmeterol+fluticasone'
          when 'R03AK07' then 'formoterol+budesonide'
          when 'R03AK08' then 'formoterol+beclometasone'
          when 'R03AK10' then 'vilanterol+fluticasone'
          else 'Unknown'
        end
    return Tuple {
      atcCode: atcCode,
      medicationType: medicationType,
      drugName: drugName,
      patientId: M.subject.reference,
      prescriptionDate: GetMedicationDate(M)
    }

// 藥品類型分布統計
define "Medication Category Distribution":
  Tuple {
    sabaOnly: Count(
      "SABA ICS Medication Type Analysis" M 
        where M.medicationType = 'SABA-短效β2作用劑'
    ),
    icsOnly: Count(
      "SABA ICS Medication Type Analysis" M 
        where M.medicationType = 'ICS-吸入型皮質類固醇'
    ),
    combination: Count(
      "SABA ICS Medication Type Analysis" M 
        where M.medicationType = 'Combination-複方吸入劑(含類固醇)'
    ),
    totalPrescriptions: Count("SABA or ICS Medications in Outpatient")
  }

// 病人用藥模式分析
define "Patient Medication Pattern":
  "Final Numerator" P
    let patientMedications: 
      "SABA ICS Medication Type Analysis" M
        where M.patientId = 'Patient/' + P.id,
    hasSABA: exists(
      patientMedications M where M.medicationType = 'SABA-短效β2作用劑'
    ),
    hasICS: exists(
      patientMedications M where M.medicationType = 'ICS-吸入型皮質類固醇'
    ),
    hasCombination: exists(
      patientMedications M where M.medicationType = 'Combination-複方吸入劑(含類固醇)'
    )
    return Tuple {
      patientId: P.id,
      totalPrescriptions: Count(patientMedications),
      hasSABA: hasSABA,
      hasICS: hasICS,
      hasCombination: hasCombination,
      medicationPattern: case
        when hasSABA and hasICS and hasCombination then '全部類型'
        when hasSABA and hasICS then 'SABA+ICS'
        when hasSABA and hasCombination then 'SABA+複方'
        when hasICS and hasCombination then 'ICS+複方'
        when hasSABA then '僅SABA'
        when hasICS then '僅ICS'
        when hasCombination then '僅複方'
        else '無'
      end
    }

// 門診就診次數與用藥關係
define "Outpatient Visit and Medication Stats":
  "Final Numerator" P
    let outpatientVisits: 
      "Outpatient Encounters in Measurement Period" E
        where E.subject.reference = 'Patient/' + P.id,
    visitsWithSABAorICS:
      outpatientVisits E
        where exists(
          "SABA or ICS Medications in Outpatient" M
            where M.encounter.reference = 'Encounter/' + E.id
        )
    return Tuple {
      patientId: P.id,
      totalOutpatientVisits: Count(outpatientVisits),
      visitsWithMedication: Count(visitsWithSABAorICS),
      medicationRate: 
        if Count(outpatientVisits) > 0
        then Round((Count(visitsWithSABAorICS) / Count(outpatientVisits)) * 100, 2)
        else 0
    }

// ============================================================
// 品質檢核
// ============================================================
define "Quality Checks":
  {
    Tuple {
      checkName: '分母人數檢核',
      description: '確認分母人數（氣喘病人數）> 0',
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
      checkName: '氣喘病患分類檢核',
      description: '確認氣喘病患符合至少一種定義',
      passed: Count("Patients with Emergency Asthma") > 0
              or Count("Patients with Inpatient Asthma") > 0
              or Count("Patients with Outpatient Asthma and Medication") > 0,
      breakdown: "Denominator Breakdown"
    },
    Tuple {
      checkName: 'SABA/ICS 藥品檢核',
      description: '確認分子病人都有開立SABA或ICS藥品',
      passed: Count("SABA or ICS Medications in Outpatient") > 0,
      totalMedications: Count("SABA or ICS Medications in Outpatient"),
      uniquePatients: Count("Final Numerator")
    },
    Tuple {
      checkName: '門診處方檢核',
      description: '確認所有SABA/ICS處方都在門診開立',
      passed: not exists(
        "SABA or ICS Medications in Outpatient" M
          where not exists(
            "Outpatient Encounters in Measurement Period" E
              where M.encounter.reference = 'Encounter/' + E.id
          )
      ),
      totalPrescriptions: Count("SABA or ICS Medications in Outpatient")
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
    indicatorName: '氣喘病人使用短效乙型作用劑或類固醇藥物吸入劑累積控制比率',
    measurementPeriod: MeasurementPeriod,
    denominator: Count("Final Denominator"),
    numerator: Count("Final Numerator"),
    exclusions: Count("Exclusions"),
    indicatorScore: "Indicator Score",
    denominatorBreakdown: "Denominator Breakdown",
    medicationStats: Tuple {
      totalPrescriptions: Count("SABA or ICS Medications in Outpatient"),
      uniquePatients: Count("Final Numerator"),
      categoryDistribution: "Medication Category Distribution",
      averagePrescriptionsPerPatient: 
        if Count("Final Numerator") > 0
        then Round(Count("SABA or ICS Medications in Outpatient") / Count("Final Numerator"), 2)
        else 0
    },
    qualityChecks: "Quality Checks"
  }
