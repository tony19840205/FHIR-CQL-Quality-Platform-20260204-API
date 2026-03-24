library Indicator_AMI_Beta_Blocker_Administration_Rate version '1.0.0'

/*
急性心肌梗塞(AMI)病人於住院期間給藥比率 - 乙型阻斷劑(β-Blocker)
Acute Myocardial Infarction (AMI) Inpatient Beta-Blocker Administration Rate

計算說明:
- 分子：分母案件住院期間曾給予β-Blocker的案件數
- 分母：已出院的AMI案件（排除COPD、Asthma、Bradycardia、Hypotension）
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21、I22、I5A
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除
2. 出院：同次住院任一筆有出院日
3. COPD：同次住院有任一筆任一主次診斷前3碼為J41-J44，則該次住院全部排除
4. Asthma：同次住院有任一筆任一主次診斷前3碼為J45，則該次住院全部排除
5. Bradycardia：同次住院有任一筆任一主次診斷前5碼為R0989(Other symptoms involving cardiovascular system)
   或前4碼為I495-I498(Other specified cardiac dysrhythmias)，則該次住院全部排除
6. Hypotension：同次住院有任一筆任一主次診斷前4碼為O265或前3碼為I95，則該次住院全部排除
7. 同一【院所, ID, 生日, 住院日】為同次住院，視為同一案件
8. β-Blocker：ATC藥品分類前3碼為C07
9. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-06)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 半年度期間定義
parameter "Period 1" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-06-30T23:59:59.0]

parameter "Period 2" Interval<DateTime>
  default Interval[@2026-07-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'

// AMI診斷碼定義 (I21, I22, I5A系列)
code "I21": 'I21' from "ICD10CM" display 'Acute myocardial infarction'
code "I22": 'I22' from "ICD10CM" display 'Subsequent ST elevation (STEMI) and non-ST elevation (NSTEMI) myocardial infarction'
code "I5A": 'I5A' from "ICD10CM" display 'Non-ischemic myocardial injury (non-traumatic)'

// AMI排除診斷碼 (NSTEMI)
code "I214": 'I214' from "ICD10CM" display 'Non-ST elevation (NSTEMI) myocardial infarction'
code "I222": 'I222' from "ICD10CM" display 'Subsequent non-ST elevation (NSTEMI) myocardial infarction'

// β-Blocker禁忌症診斷碼

// COPD診斷碼 (J41-J44)
code "J41": 'J41' from "ICD10CM" display 'Simple and mucopurulent chronic bronchitis'
code "J42": 'J42' from "ICD10CM" display 'Unspecified chronic bronchitis'
code "J43": 'J43' from "ICD10CM" display 'Emphysema'
code "J44": 'J44' from "ICD10CM" display 'Other chronic obstructive pulmonary disease'

// Asthma診斷碼 (J45)
code "J45": 'J45' from "ICD10CM" display 'Asthma'

// Bradycardia診斷碼
code "R0989": 'R0989' from "ICD10CM" display 'Other symptoms involving cardiovascular system'
code "I495": 'I495' from "ICD10CM" display 'Sick sinus syndrome'
code "I496": 'I496' from "ICD10CM" display 'Cardiac arrest'
code "I498": 'I498' from "ICD10CM" display 'Other specified cardiac arrhythmias'

// Hypotension診斷碼
code "O265": 'O265' from "ICD10CM" display 'Maternal hypotension syndrome'
code "I95": 'I95' from "ICD10CM" display 'Hypotension'

// β-Blocker藥品碼
code "C07": 'C07' from "ATC" display 'Beta blocking agents'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 住院Encounter編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

// 所有AMI診斷
define "All AMI Conditions":
  [Condition] C
    where exists(
      C.code.coding Coding
        where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
          and (
            Coding.code.startsWith('I21') or
            Coding.code.startsWith('I22') or
            Coding.code.startsWith('I5A')
          )
    )

// NSTEMI排除診斷 (I214, I222)
define "NSTEMI Exclusion Conditions":
  [Condition] C
    where exists(
      C.code.coding Coding
        where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
          and (
            Coding.code.startsWith('I214') or
            Coding.code.startsWith('I222')
          )
    )

// COPD診斷條件 (J41-J44)
define "COPD Conditions":
  [Condition] C
    where exists(
      C.code.coding Coding
        where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
          and (
            Coding.code.startsWith('J41') or
            Coding.code.startsWith('J42') or
            Coding.code.startsWith('J43') or
            Coding.code.startsWith('J44')
          )
    )

// Asthma診斷條件 (J45)
define "Asthma Conditions":
  [Condition] C
    where exists(
      C.code.coding Coding
        where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
          and Coding.code.startsWith('J45')
    )

// Bradycardia診斷條件 (R0989, I495-I498)
define "Bradycardia Conditions":
  [Condition] C
    where exists(
      C.code.coding Coding
        where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
          and (
            Coding.code.startsWith('R0989') or
            Coding.code.startsWith('I495') or
            Coding.code.startsWith('I496') or
            Coding.code.startsWith('I498')
          )
    )

// Hypotension診斷條件 (O265, I95)
define "Hypotension Conditions":
  [Condition] C
    where exists(
      C.code.coding Coding
        where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
          and (
            Coding.code.startsWith('O265') or
            Coding.code.startsWith('I95')
          )
    )

// β-Blocker用藥
define "Beta Blocker Medications":
  [MedicationRequest] M
    where M.status in { 'active', 'completed' }
      and exists(
        M.medication.coding Coding
          where (Coding.system = 'http://www.whocc.no/atc')
            and Coding.code.startsWith('C07')
      )

// ===== 輔助函數定義 =====

// 判斷Condition是否為主診斷
define function IsPrimaryDiagnosis(condition Condition):
  exists(
    condition.category Category
      where exists(
        Category.coding Coding
          where Coding.code = 'primary'
      )
  )

// 取得Encounter的所有Condition
define function GetEncounterConditions(encounter Encounter):
  [Condition] C
    where C.encounter.reference = 'Encounter/' + encounter.id

// 取得主診斷
define function GetPrimaryDiagnoses(encounter Encounter):
  GetEncounterConditions(encounter) C
    where IsPrimaryDiagnosis(C)

// 取得住院日期
define function GetAdmissionDate(encounter Encounter):
  start of encounter.period

// 取得出院日期
define function GetDischargeDate(encounter Encounter):
  end of encounter.period

// 取得住院期間
define function GetHospitalizationPeriod(encounter Encounter):
  Interval[GetAdmissionDate(encounter), GetDischargeDate(encounter)]

// 判斷Encounter是否有主診斷AMI
define function HasPrimaryAMIDiagnosis(encounter Encounter):
  exists(
    GetPrimaryDiagnoses(encounter) C
      where exists(
        C.code.coding Coding
          where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
            and (
              Coding.code.startsWith('I21') or
              Coding.code.startsWith('I22') or
              Coding.code.startsWith('I5A')
            )
      )
  )

// 判斷Encounter是否有主診斷NSTEMI (排除條件)
define function HasPrimaryNSTEMIDiagnosis(encounter Encounter):
  exists(
    GetPrimaryDiagnoses(encounter) C
      where exists(
        C.code.coding Coding
          where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
            and (
              Coding.code.startsWith('I214') or
              Coding.code.startsWith('I222')
            )
      )
  )

// 判斷Encounter是否有COPD診斷 (主診斷或次診斷)
define function HasCOPDDiagnosis(encounter Encounter):
  exists(
    GetEncounterConditions(encounter) C
      where exists(
        C.code.coding Coding
          where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
            and (
              Coding.code.startsWith('J41') or
              Coding.code.startsWith('J42') or
              Coding.code.startsWith('J43') or
              Coding.code.startsWith('J44')
            )
      )
  )

// 判斷Encounter是否有Asthma診斷 (主診斷或次診斷)
define function HasAsthmaDiagnosis(encounter Encounter):
  exists(
    GetEncounterConditions(encounter) C
      where exists(
        C.code.coding Coding
          where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
            and Coding.code.startsWith('J45')
      )
  )

// 判斷Encounter是否有Bradycardia診斷 (主診斷或次診斷)
define function HasBradycardiaDiagnosis(encounter Encounter):
  exists(
    GetEncounterConditions(encounter) C
      where exists(
        C.code.coding Coding
          where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
            and (
              Coding.code.startsWith('R0989') or
              Coding.code.startsWith('I495') or
              Coding.code.startsWith('I496') or
              Coding.code.startsWith('I498')
            )
      )
  )

// 判斷Encounter是否有Hypotension診斷 (主診斷或次診斷)
define function HasHypotensionDiagnosis(encounter Encounter):
  exists(
    GetEncounterConditions(encounter) C
      where exists(
        C.code.coding Coding
          where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
            and (
              Coding.code.startsWith('O265') or
              Coding.code.startsWith('I95')
            )
      )
  )

// 判斷Encounter是否有任何β-Blocker禁忌症
define function HasBetaBlockerContraindication(encounter Encounter):
  HasCOPDDiagnosis(encounter) or
  HasAsthmaDiagnosis(encounter) or
  HasBradycardiaDiagnosis(encounter) or
  HasHypotensionDiagnosis(encounter)

// 判斷Encounter是否已出院
define function IsDischargedEncounter(encounter Encounter):
  encounter.status = 'finished'
    and GetDischargeDate(encounter) is not null

// 判斷Encounter期間是否使用β-Blocker
define function HasBetaBlockerDuringHospitalization(encounter Encounter):
  exists(
    "Beta Blocker Medications" M
      where M.authoredOn during GetHospitalizationPeriod(encounter)
        or M.authoredOn same day as GetAdmissionDate(encounter)
        or M.authoredOn same day as GetDischargeDate(encounter)
  )

// ===== 分母定義 (已排除NSTEMI和β-Blocker禁忌症) =====

// 步驟1: 所有AMI住院案件（已出院）
define "AMI Inpatient Cases With Discharge":
  "All Inpatient Encounters" E
    where HasPrimaryAMIDiagnosis(E)
      and IsDischargedEncounter(E)

// 步驟2: 排除NSTEMI主診斷案件
define "AMI Cases Excluding NSTEMI":
  "AMI Inpatient Cases With Discharge" E
    where not HasPrimaryNSTEMIDiagnosis(E)

// 步驟3: 排除β-Blocker禁忌症案件（最終分母）
define "Denominator":
  "AMI Cases Excluding NSTEMI" E
    where not HasBetaBlockerContraindication(E)

// ===== 分子定義 =====

// 分母案件中，住院期間有使用β-Blocker的案件
define "Numerator":
  "Denominator" E
    where HasBetaBlockerDuringHospitalization(E)

// ===== 半年度分母分子 =====

// 第1期分母 (1-6月)
define "Denominator Period 1":
  "Denominator" E
    where GetAdmissionDate(E) during "Period 1"

// 第1期分子
define "Numerator Period 1":
  "Denominator Period 1" E
    where HasBetaBlockerDuringHospitalization(E)

// 第2期分母 (7-12月)
define "Denominator Period 2":
  "Denominator" E
    where GetAdmissionDate(E) during "Period 2"

// 第2期分子
define "Numerator Period 2":
  "Denominator Period 2" E
    where HasBetaBlockerDuringHospitalization(E)

// ===== 指標計算 =====

// 全年度指標比率
define "Annual Rate":
  if Count("Denominator") > 0
    then (Count("Numerator") * 100.0) / Count("Denominator")
    else null

// 第1期指標比率
define "Period 1 Rate":
  if Count("Denominator Period 1") > 0
    then (Count("Numerator Period 1") * 100.0) / Count("Denominator Period 1")
    else null

// 第2期指標比率
define "Period 2 Rate":
  if Count("Denominator Period 2") > 0
    then (Count("Numerator Period 2") * 100.0) / Count("Denominator Period 2")
    else null

// ===== 統計資料 =====

// AMI診斷分布統計
define "AMI Diagnosis Distribution":
  {
    I21_Count: Count("AMI Inpatient Cases With Discharge" E 
      where exists(GetPrimaryDiagnoses(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I21')))),
    I22_Count: Count("AMI Inpatient Cases With Discharge" E 
      where exists(GetPrimaryDiagnoses(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I22')))),
    I5A_Count: Count("AMI Inpatient Cases With Discharge" E 
      where exists(GetPrimaryDiagnoses(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I5A'))))
  }

// NSTEMI排除案件統計
define "NSTEMI Exclusion Statistics":
  {
    Total_AMI_Cases: Count("AMI Inpatient Cases With Discharge"),
    I214_Excluded: Count("AMI Inpatient Cases With Discharge" E 
      where exists(GetPrimaryDiagnoses(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I214')))),
    I222_Excluded: Count("AMI Inpatient Cases With Discharge" E 
      where exists(GetPrimaryDiagnoses(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I222')))),
    After_NSTEMI_Exclusion: Count("AMI Cases Excluding NSTEMI")
  }

// β-Blocker禁忌症排除統計
define "Beta Blocker Contraindication Exclusion Statistics":
  {
    Before_Contraindication_Exclusion: Count("AMI Cases Excluding NSTEMI"),
    COPD_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where HasCOPDDiagnosis(E)),
    Asthma_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where HasAsthmaDiagnosis(E)),
    Bradycardia_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where HasBradycardiaDiagnosis(E)),
    Hypotension_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where HasHypotensionDiagnosis(E)),
    Any_Contraindication_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where HasBetaBlockerContraindication(E)),
    After_Contraindication_Exclusion: Count("Denominator")
  }

// COPD詳細統計
define "COPD Exclusion Details":
  {
    J41_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('J41')))),
    J42_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('J42')))),
    J43_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('J43')))),
    J44_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('J44'))))
  }

// Bradycardia詳細統計
define "Bradycardia Exclusion Details":
  {
    R0989_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('R0989')))),
    I495_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I495')))),
    I496_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I496')))),
    I498_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I498'))))
  }

// Hypotension詳細統計
define "Hypotension Exclusion Details":
  {
    O265_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('O265')))),
    I95_Cases: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I95'))))
  }

// β-Blocker給藥時機分析
define "Beta Blocker Timing Analysis":
  "Numerator" E
    let admissionDate: GetAdmissionDate(E),
        medications: "Beta Blocker Medications" M 
          where M.authoredOn during GetHospitalizationPeriod(E),
        firstMedication: First(medications M sort by M.authoredOn),
        daysFromAdmission: days between admissionDate and firstMedication.authoredOn
    return {
      encounter_id: E.id,
      admission_date: admissionDate,
      first_medication_date: firstMedication.authoredOn,
      days_from_admission: daysFromAdmission,
      medication_count: Count(medications)
    }

// β-Blocker用藥類型分析
define "Beta Blocker Type Analysis":
  "Numerator" E
    let medications: "Beta Blocker Medications" M 
          where M.authoredOn during GetHospitalizationPeriod(E)
    return {
      encounter_id: E.id,
      medication_codes: medications M 
        return M.medication.coding.code,
      unique_medications: Count(distinct medications.medication.coding.code)
    }

// 住院天數統計
define "Length of Stay Statistics":
  "Denominator" E
    let los: days between GetAdmissionDate(E) and GetDischargeDate(E)
    return {
      encounter_id: E.id,
      admission_date: GetAdmissionDate(E),
      discharge_date: GetDischargeDate(E),
      length_of_stay: los,
      has_beta_blocker: HasBetaBlockerDuringHospitalization(E)
    }

// ===== 品質指標總結 =====

define "Quality Indicator Summary":
  {
    indicator_name: '急性心肌梗塞(AMI)病人於住院期間給藥比率 - 乙型阻斷劑(β-Blocker)',
    measurement_period: "Measurement Period",
    
    // 全年度統計
    annual_denominator: Count("Denominator"),
    annual_numerator: Count("Numerator"),
    annual_rate: "Annual Rate",
    
    // 半年度統計
    period_1_denominator: Count("Denominator Period 1"),
    period_1_numerator: Count("Numerator Period 1"),
    period_1_rate: "Period 1 Rate",
    
    period_2_denominator: Count("Denominator Period 2"),
    period_2_numerator: Count("Numerator Period 2"),
    period_2_rate: "Period 2 Rate",
    
    // 排除統計
    total_ami_cases: Count("AMI Inpatient Cases With Discharge"),
    nstemi_excluded_cases: Count("AMI Inpatient Cases With Discharge") - Count("AMI Cases Excluding NSTEMI"),
    contraindication_excluded_cases: Count("AMI Cases Excluding NSTEMI") - Count("Denominator"),
    
    // 診斷分布
    ami_diagnosis_distribution: "AMI Diagnosis Distribution",
    
    // 排除詳情
    nstemi_exclusion_details: "NSTEMI Exclusion Statistics",
    contraindication_exclusion_summary: "Beta Blocker Contraindication Exclusion Statistics",
    copd_exclusion_details: "COPD Exclusion Details",
    bradycardia_exclusion_details: "Bradycardia Exclusion Details",
    hypotension_exclusion_details: "Hypotension Exclusion Details",
    
    // 用藥統計
    beta_blocker_usage_rate: if Count("Denominator") > 0 
      then (Count("Numerator") * 100.0) / Count("Denominator") 
      else null,
    
    // 資料品質
    data_quality: {
      encounters_with_discharge: Count("AMI Inpatient Cases With Discharge"),
      encounters_with_primary_diagnosis: Count("AMI Inpatient Cases With Discharge" E where HasPrimaryAMIDiagnosis(E)),
      complete_data_rate: if Count("AMI Inpatient Cases With Discharge") > 0
        then (Count("AMI Inpatient Cases With Discharge" E where HasPrimaryAMIDiagnosis(E)) * 100.0) / Count("AMI Inpatient Cases With Discharge")
        else null
    }
  }

// ===== 最終輸出 =====

define "Final Output":
  "Quality Indicator Summary"
