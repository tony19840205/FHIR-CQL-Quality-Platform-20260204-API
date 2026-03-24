library Indicator_AMI_ADP_Receptor_Antagonist_Administration_Rate version '1.0.0'

/*
急性心肌梗塞(AMI)病人於住院期間給藥比率 - 胰嘌呤二磷酸受體拮抗劑(ADP受體拮抗劑)
Acute Myocardial Infarction (AMI) Inpatient ADP Receptor Antagonist Administration Rate

計算說明:
- 分子：分母案件住院期間曾給予ADP受體拮抗劑的案件數
- 分母：已出院的AMI案件（排除NSTEMI及出血禁忌症）
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21、I22、I5A
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除
2. 出院：同次住院任一筆有出院日
3. ADP受體拮抗劑：ATC藥品分類前7碼為B01AC04(clopidogrel)、B01AC05(ticlopidine)、
   B01AC22(prasugrel)、B01AC24(ticagrelor)
4. 出血禁忌症排除：與Aspirin相同的出血診斷排除邏輯
5. 同一【院所, ID, 生日, 住院日】為同次住院，視為同一案件
6. 計算範圍：2026年(115年)資料

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

// 出血相關診斷碼 - 上消化道出血
code "K250": 'K250' from "ICD10CM" display 'Gastric ulcer, acute with hemorrhage'
code "K252": 'K252' from "ICD10CM" display 'Gastric ulcer, acute with both hemorrhage and perforation'
code "K254": 'K254' from "ICD10CM" display 'Gastric ulcer, chronic or unspecified with hemorrhage'
code "K256": 'K256' from "ICD10CM" display 'Gastric ulcer, chronic or unspecified with both hemorrhage and perforation'
code "K260": 'K260' from "ICD10CM" display 'Duodenal ulcer, acute with hemorrhage'
code "K262": 'K262' from "ICD10CM" display 'Duodenal ulcer, acute with both hemorrhage and perforation'
code "K264": 'K264' from "ICD10CM" display 'Duodenal ulcer, chronic or unspecified with hemorrhage'
code "K266": 'K266' from "ICD10CM" display 'Duodenal ulcer, chronic or unspecified with both hemorrhage and perforation'
code "K270": 'K270' from "ICD10CM" display 'Peptic ulcer, site unspecified, acute with hemorrhage'
code "K272": 'K272' from "ICD10CM" display 'Peptic ulcer, site unspecified, acute with both hemorrhage and perforation'
code "K274": 'K274' from "ICD10CM" display 'Peptic ulcer, site unspecified, chronic or unspecified with hemorrhage'
code "K276": 'K276' from "ICD10CM" display 'Peptic ulcer, site unspecified, chronic or unspecified with both hemorrhage and perforation'
code "K280": 'K280' from "ICD10CM" display 'Gastrojejunal ulcer, acute with hemorrhage'
code "K282": 'K282' from "ICD10CM" display 'Gastrojejunal ulcer, acute with both hemorrhage and perforation'
code "K284": 'K284' from "ICD10CM" display 'Gastrojejunal ulcer, chronic or unspecified with hemorrhage'
code "K286": 'K286' from "ICD10CM" display 'Gastrojejunal ulcer, chronic or unspecified with both hemorrhage and perforation'
code "K290": 'K290' from "ICD10CM" display 'Acute hemorrhagic gastritis'
code "K920": 'K920' from "ICD10CM" display 'Hematemesis'
code "K921": 'K921' from "ICD10CM" display 'Melena'
code "K922": 'K922' from "ICD10CM" display 'Gastrointestinal hemorrhage, unspecified'

// 出血相關診斷碼 - 腦出血
code "I60": 'I60' from "ICD10CM" display 'Nontraumatic subarachnoid hemorrhage'
code "I61": 'I61' from "ICD10CM" display 'Nontraumatic intracerebral hemorrhage'
code "I62": 'I62' from "ICD10CM" display 'Other and unspecified nontraumatic intracranial hemorrhage'

// 出血相關診斷碼 - 其他出血
code "R04": 'R04' from "ICD10CM" display 'Hemorrhage from respiratory passages'
code "R310": 'R310' from "ICD10CM" display 'Gross hematuria'
code "R319": 'R319' from "ICD10CM" display 'Hematuria, unspecified'
code "R58": 'R58' from "ICD10CM" display 'Hemorrhage, not elsewhere classified'
code "D62": 'D62' from "ICD10CM" display 'Acute posthemorrhagic anemia'
code "D500": 'D500' from "ICD10CM" display 'Iron deficiency anemia secondary to blood loss (chronic)'

// ADP受體拮抗劑藥品碼
code "B01AC04": 'B01AC04' from "ATC" display 'clopidogrel'
code "B01AC05": 'B01AC05' from "ATC" display 'ticlopidine'
code "B01AC22": 'B01AC22' from "ATC" display 'prasugrel'
code "B01AC24": 'B01AC24' from "ATC" display 'ticagrelor'

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

// 出血診斷條件
define "Bleeding Conditions":
  [Condition] C
    where IsBleedingDiagnosis(C)

// 判斷是否為出血診斷
define function IsBleedingDiagnosis(condition Condition):
  exists(
    condition.code.coding Coding
      where (Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm')
        and (
          // 上消化道出血
          Coding.code in { 'K250', 'K252', 'K254', 'K256',
                          'K260', 'K262', 'K264', 'K266',
                          'K270', 'K272', 'K274', 'K276',
                          'K280', 'K282', 'K284', 'K286',
                          'K290', 'K920', 'K921', 'K922' } or
          // 腦出血
          Coding.code.startsWith('I60') or
          Coding.code.startsWith('I61') or
          Coding.code.startsWith('I62') or
          // 其他出血
          Coding.code.startsWith('R04') or
          Coding.code in { 'R310', 'R319' } or
          Coding.code = 'R58' or
          Coding.code = 'D62' or
          Coding.code = 'D500'
        )
  )

// ADP受體拮抗劑用藥
define "ADP Receptor Antagonist Medications":
  [MedicationRequest] M
    where M.status in { 'active', 'completed' }
      and exists(
        M.medication.coding Coding
          where (Coding.system = 'http://www.whocc.no/atc')
            and (
              Coding.code.startsWith('B01AC04') or  // clopidogrel
              Coding.code.startsWith('B01AC05') or  // ticlopidine
              Coding.code.startsWith('B01AC22') or  // prasugrel
              Coding.code.startsWith('B01AC24')     // ticagrelor
            )
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

// 判斷Encounter是否有出血診斷 (主診斷或次診斷)
define function HasBleedingDiagnosis(encounter Encounter):
  exists(
    GetEncounterConditions(encounter) C
      where IsBleedingDiagnosis(C)
  )

// 判斷Encounter是否已出院
define function IsDischargedEncounter(encounter Encounter):
  encounter.status = 'finished'
    and GetDischargeDate(encounter) is not null

// 判斷Encounter期間是否使用ADP受體拮抗劑
define function HasADPReceptorAntagonistDuringHospitalization(encounter Encounter):
  exists(
    "ADP Receptor Antagonist Medications" M
      where M.authoredOn during GetHospitalizationPeriod(encounter)
        or M.authoredOn same day as GetAdmissionDate(encounter)
        or M.authoredOn same day as GetDischargeDate(encounter)
  )

// ===== 分母定義 (已排除NSTEMI和出血禁忌) =====

// 步驟1: 所有AMI住院案件（已出院）
define "AMI Inpatient Cases With Discharge":
  "All Inpatient Encounters" E
    where HasPrimaryAMIDiagnosis(E)
      and IsDischargedEncounter(E)

// 步驟2: 排除NSTEMI主診斷案件
define "AMI Cases Excluding NSTEMI":
  "AMI Inpatient Cases With Discharge" E
    where not HasPrimaryNSTEMIDiagnosis(E)

// 步驟3: 排除出血診斷案件（最終分母）
define "Denominator":
  "AMI Cases Excluding NSTEMI" E
    where not HasBleedingDiagnosis(E)

// ===== 分子定義 =====

// 分母案件中，住院期間有使用ADP受體拮抗劑的案件
define "Numerator":
  "Denominator" E
    where HasADPReceptorAntagonistDuringHospitalization(E)

// ===== 半年度分母分子 =====

// 第1期分母 (1-6月)
define "Denominator Period 1":
  "Denominator" E
    where GetAdmissionDate(E) during "Period 1"

// 第1期分子
define "Numerator Period 1":
  "Denominator Period 1" E
    where HasADPReceptorAntagonistDuringHospitalization(E)

// 第2期分母 (7-12月)
define "Denominator Period 2":
  "Denominator" E
    where GetAdmissionDate(E) during "Period 2"

// 第2期分子
define "Numerator Period 2":
  "Denominator Period 2" E
    where HasADPReceptorAntagonistDuringHospitalization(E)

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

// 出血診斷排除統計
define "Bleeding Exclusion Statistics":
  {
    Before_Bleeding_Exclusion: Count("AMI Cases Excluding NSTEMI"),
    Upper_GI_Bleeding_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code in { 'K250', 'K252', 'K254', 'K256',
                                'K260', 'K262', 'K264', 'K266',
                                'K270', 'K272', 'K274', 'K276',
                                'K280', 'K282', 'K284', 'K286',
                                'K290', 'K920', 'K921', 'K922' }))),
    Cerebral_Bleeding_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I60') or 
                Coding.code.startsWith('I61') or 
                Coding.code.startsWith('I62')))),
    Other_Bleeding_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('R04') or
                Coding.code in { 'R310', 'R319', 'R58', 'D62', 'D500' }))),
    After_Bleeding_Exclusion: Count("Denominator")
  }

// ADP受體拮抗劑用藥統計
define "ADP Receptor Antagonist Usage Statistics":
  {
    Clopidogrel_Cases: Count("Numerator" E 
      where exists("ADP Receptor Antagonist Medications" M 
        where M.authoredOn during GetHospitalizationPeriod(E)
          and exists(M.medication.coding Coding 
            where Coding.code.startsWith('B01AC04')))),
    Ticlopidine_Cases: Count("Numerator" E 
      where exists("ADP Receptor Antagonist Medications" M 
        where M.authoredOn during GetHospitalizationPeriod(E)
          and exists(M.medication.coding Coding 
            where Coding.code.startsWith('B01AC05')))),
    Prasugrel_Cases: Count("Numerator" E 
      where exists("ADP Receptor Antagonist Medications" M 
        where M.authoredOn during GetHospitalizationPeriod(E)
          and exists(M.medication.coding Coding 
            where Coding.code.startsWith('B01AC22')))),
    Ticagrelor_Cases: Count("Numerator" E 
      where exists("ADP Receptor Antagonist Medications" M 
        where M.authoredOn during GetHospitalizationPeriod(E)
          and exists(M.medication.coding Coding 
            where Coding.code.startsWith('B01AC24'))))
  }

// ADP受體拮抗劑給藥時機分析
define "ADP Receptor Antagonist Timing Analysis":
  "Numerator" E
    let admissionDate: GetAdmissionDate(E),
        medications: "ADP Receptor Antagonist Medications" M 
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

// 住院天數統計
define "Length of Stay Statistics":
  "Denominator" E
    let los: days between GetAdmissionDate(E) and GetDischargeDate(E)
    return {
      encounter_id: E.id,
      admission_date: GetAdmissionDate(E),
      discharge_date: GetDischargeDate(E),
      length_of_stay: los,
      has_adp_antagonist: HasADPReceptorAntagonistDuringHospitalization(E)
    }

// ===== 品質指標總結 =====

define "Quality Indicator Summary":
  {
    indicator_name: '急性心肌梗塞(AMI)病人於住院期間給藥比率 - 胰嘌呤二磷酸受體拮抗劑(ADP受體拮抗劑)',
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
    bleeding_excluded_cases: Count("AMI Cases Excluding NSTEMI") - Count("Denominator"),
    
    // 診斷分布
    ami_diagnosis_distribution: "AMI Diagnosis Distribution",
    
    // 排除詳情
    nstemi_exclusion_details: "NSTEMI Exclusion Statistics",
    bleeding_exclusion_details: "Bleeding Exclusion Statistics",
    
    // 用藥統計
    adp_antagonist_usage: "ADP Receptor Antagonist Usage Statistics",
    
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
