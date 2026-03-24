library Indicator_AMI_Post_Discharge_ADP_Antagonist_3Months_Rate version '1.0.0'

/*
急性心肌梗塞(AMI)病人出院後三個月以內給藥比率 - 胰嘌呤二磷酸受體拮抗劑(ADP受體拮抗劑)
Acute Myocardial Infarction (AMI) Post-Discharge 3-Month ADP Receptor Antagonist Prescription Rate

計算說明:
- 分子：分母案件出院後3個月內再至同院門診領有ADP受體拮抗劑的案件數
- 分母：已出院的AMI案件
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21、I22、I5A
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除
2. 出院日：按【院所, ID, 生日, 住院日】歸戶，因同一次住院，會有串該多筆住院醫費用的情形，
   可能有多個出院日，以最晚之出院日的那一筆為代表案件
3. ADP受體拮抗劑：ATC藥品分類前7碼為B01AC04(clopidogrel)、B01AC05(ticlopidine)、
   B01AC22(prasugrel)、B01AC24(ticagrelor)
4. 門診領藥：出院後3個月內，在同一院所的門診領取ADP受體拮抗劑
5. 計算範圍：2026年(115年)資料

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

// 出院後追蹤期間（3個月 = 90天）
parameter "Post Discharge Follow Up Days" Integer default 90

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

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// 門診Encounter編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
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

// 取得院所識別碼
define function GetOrganizationId(encounter Encounter):
  Last(Split(encounter.serviceProvider.reference, '/'))

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

// 判斷Encounter是否已出院
define function IsDischargedEncounter(encounter Encounter):
  encounter.status = 'finished'
    and GetDischargeDate(encounter) is not null

// 取得最晚出院日（同一住院案件可能有多筆記錄）
define function GetLatestDischargeDate(encounter Encounter):
  GetDischargeDate(encounter)

// 取得出院後3個月追蹤期間
define function GetPostDischargeFollowUpPeriod(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Post Discharge Follow Up Days" days]

// 判斷出院後3個月內，是否在同院門診領有ADP受體拮抗劑
define function HasADPAntagonistInOutpatientWithin3Months(inpatientEncounter Encounter):
  exists(
    "All Outpatient Encounters" outpatientEnc
      let dischargeDate: GetLatestDischargeDate(inpatientEncounter),
          followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate),
          inpatientOrgId: GetOrganizationId(inpatientEncounter),
          outpatientOrgId: GetOrganizationId(outpatientEnc)
      where outpatientEnc.period.start during followUpPeriod
        and inpatientOrgId = outpatientOrgId  // 同一院所
        and exists(
          "ADP Receptor Antagonist Medications" M
            where M.authoredOn during outpatientEnc.period
              or M.authoredOn same day as start of outpatientEnc.period
        )
  )

// ===== 分母定義 (已出院的AMI案件，排除NSTEMI) =====

// 步驟1: 所有AMI住院案件（已出院）
define "AMI Inpatient Cases With Discharge":
  "All Inpatient Encounters" E
    where HasPrimaryAMIDiagnosis(E)
      and IsDischargedEncounter(E)

// 步驟2: 排除NSTEMI主診斷案件（最終分母）
define "Denominator":
  "AMI Inpatient Cases With Discharge" E
    where not HasPrimaryNSTEMIDiagnosis(E)

// ===== 分子定義 =====

// 分母案件中，出院後3個月內在同院門診領有ADP受體拮抗劑的案件
define "Numerator":
  "Denominator" E
    where HasADPAntagonistInOutpatientWithin3Months(E)

// ===== 半年度分母分子 =====

// 第1期分母 (1-6月) - 依出院日期判定
define "Denominator Period 1":
  "Denominator" E
    where GetLatestDischargeDate(E) during "Period 1"

// 第1期分子
define "Numerator Period 1":
  "Denominator Period 1" E
    where HasADPAntagonistInOutpatientWithin3Months(E)

// 第2期分母 (7-12月) - 依出院日期判定
define "Denominator Period 2":
  "Denominator" E
    where GetLatestDischargeDate(E) during "Period 2"

// 第2期分子
define "Numerator Period 2":
  "Denominator Period 2" E
    where HasADPAntagonistInOutpatientWithin3Months(E)

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
    After_NSTEMI_Exclusion: Count("Denominator")
  }

// ADP受體拮抗劑用藥統計
define "ADP Antagonist Usage Statistics":
  {
    Clopidogrel_Cases: Count("Numerator" E 
      where exists("All Outpatient Encounters" outpatientEnc
        let dischargeDate: GetLatestDischargeDate(E),
            followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate)
        where outpatientEnc.period.start during followUpPeriod
          and GetOrganizationId(outpatientEnc) = GetOrganizationId(E)
          and exists("ADP Receptor Antagonist Medications" M 
            where M.authoredOn during outpatientEnc.period
              and exists(M.medication.coding Coding 
                where Coding.code.startsWith('B01AC04'))))),
    Ticlopidine_Cases: Count("Numerator" E 
      where exists("All Outpatient Encounters" outpatientEnc
        let dischargeDate: GetLatestDischargeDate(E),
            followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate)
        where outpatientEnc.period.start during followUpPeriod
          and GetOrganizationId(outpatientEnc) = GetOrganizationId(E)
          and exists("ADP Receptor Antagonist Medications" M 
            where M.authoredOn during outpatientEnc.period
              and exists(M.medication.coding Coding 
                where Coding.code.startsWith('B01AC05'))))),
    Prasugrel_Cases: Count("Numerator" E 
      where exists("All Outpatient Encounters" outpatientEnc
        let dischargeDate: GetLatestDischargeDate(E),
            followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate)
        where outpatientEnc.period.start during followUpPeriod
          and GetOrganizationId(outpatientEnc) = GetOrganizationId(E)
          and exists("ADP Receptor Antagonist Medications" M 
            where M.authoredOn during outpatientEnc.period
              and exists(M.medication.coding Coding 
                where Coding.code.startsWith('B01AC22'))))),
    Ticagrelor_Cases: Count("Numerator" E 
      where exists("All Outpatient Encounters" outpatientEnc
        let dischargeDate: GetLatestDischargeDate(E),
            followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate)
        where outpatientEnc.period.start during followUpPeriod
          and GetOrganizationId(outpatientEnc) = GetOrganizationId(E)
          and exists("ADP Receptor Antagonist Medications" M 
            where M.authoredOn during outpatientEnc.period
              and exists(M.medication.coding Coding 
                where Coding.code.startsWith('B01AC24')))))
  }

// 出院後門診追蹤統計
define "Post Discharge Follow Up Statistics":
  {
    Total_Cases_With_Follow_Up: Count("Numerator"),
    Cases_Without_Follow_Up: Count("Denominator") - Count("Numerator"),
    Follow_Up_Rate: if Count("Denominator") > 0 
      then (Count("Numerator") * 100.0) / Count("Denominator") 
      else null
  }

// 門診領藥時機分析
define "Outpatient ADP Antagonist Timing Analysis":
  "Numerator" E
    let dischargeDate: GetLatestDischargeDate(E),
        followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate),
        inpatientOrgId: GetOrganizationId(E),
        outpatientVisits: "All Outpatient Encounters" outpatientEnc
          where outpatientEnc.period.start during followUpPeriod
            and GetOrganizationId(outpatientEnc) = inpatientOrgId
            and exists("ADP Receptor Antagonist Medications" M
              where M.authoredOn during outpatientEnc.period),
        firstVisit: First(outpatientVisits V sort by start of V.period),
        daysToFirstVisit: days between dischargeDate and start of firstVisit.period
    return {
      encounter_id: E.id,
      discharge_date: dischargeDate,
      first_outpatient_visit_date: start of firstVisit.period,
      days_to_first_visit: daysToFirstVisit,
      total_outpatient_visits_with_adp: Count(outpatientVisits),
      follow_up_period_end: end of followUpPeriod
    }

// 住院天數統計
define "Length of Stay Statistics":
  "Denominator" E
    let los: days between GetAdmissionDate(E) and GetLatestDischargeDate(E)
    return {
      encounter_id: E.id,
      admission_date: GetAdmissionDate(E),
      discharge_date: GetLatestDischargeDate(E),
      length_of_stay: los,
      has_post_discharge_adp_antagonist: HasADPAntagonistInOutpatientWithin3Months(E)
    }

// ===== 品質指標總結 =====

define "Quality Indicator Summary":
  {
    indicator_name: '急性心肌梗塞(AMI)病人出院後三個月以內給藥比率 - 胰嘌呤二磷酸受體拮抗劑(ADP受體拮抗劑)',
    measurement_period: "Measurement Period",
    follow_up_period_days: "Post Discharge Follow Up Days",
    
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
    nstemi_excluded_cases: Count("AMI Inpatient Cases With Discharge") - Count("Denominator"),
    
    // 診斷分布
    ami_diagnosis_distribution: "AMI Diagnosis Distribution",
    
    // 排除詳情
    nstemi_exclusion_details: "NSTEMI Exclusion Statistics",
    
    // 用藥統計
    adp_antagonist_usage: "ADP Antagonist Usage Statistics",
    
    // 追蹤統計
    post_discharge_follow_up: "Post Discharge Follow Up Statistics",
    
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
