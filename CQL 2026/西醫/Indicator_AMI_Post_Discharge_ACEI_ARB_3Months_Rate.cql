library Indicator_AMI_Post_Discharge_ACEI_ARB_3Months_Rate version '1.0.0'

/*
急性心肌梗塞(AMI)病人出院後三個月以內給藥比率 - 血管張力素轉化酶抑制劑(ACE inhibitor)或血管張力素II受體阻斷劑(ARB)
Acute Myocardial Infarction (AMI) Post-Discharge 3-Month ACEI/ARB Prescription Rate

計算說明:
- 分子：分母案件出院後3個月內再至同院門診領有ACEI或ARB的案件數
- 分母：已出院的AMI案件（排除Hypotension）
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21、I22、I5A
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除
2. 出院日：按【院所, ID, 生日, 住院日】歸戶，因同一次住院，會有串該多筆住院醫費用的情形，
   可能有多個出院日，以最晚之出院日的那一筆為代表案件
3. Hypotension：同次住院有任一筆任一主次診斷前4碼為O265或前3碼為I95，則該次住院全部排除
4. ACEI或ARB：ATC藥品分類前5碼為C09AA及C09CA
5. 門診領藥：出院後3個月內，在同一院所的門診領取ACEI或ARB
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

// Hypotension診斷碼
code "O265": 'O265' from "ICD10CM" display 'Maternal hypotension syndrome'
code "I95": 'I95' from "ICD10CM" display 'Hypotension'

// ACEI藥品碼 (C09AA系列)
code "C09AA": 'C09AA' from "ATC" display 'ACE inhibitors, plain'

// ARB藥品碼 (C09CA系列)
code "C09CA": 'C09CA' from "ATC" display 'Angiotensin II receptor blockers (ARBs), plain'

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

// ACEI/ARB用藥
define "ACEI ARB Medications":
  [MedicationRequest] M
    where M.status in { 'active', 'completed' }
      and exists(
        M.medication.coding Coding
          where (Coding.system = 'http://www.whocc.no/atc')
            and (
              Coding.code.startsWith('C09AA') or
              Coding.code.startsWith('C09CA')
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

// 判斷出院後3個月內，是否在同院門診領有ACEI或ARB
define function HasACEIorARBInOutpatientWithin3Months(inpatientEncounter Encounter):
  exists(
    "All Outpatient Encounters" outpatientEnc
      let dischargeDate: GetLatestDischargeDate(inpatientEncounter),
          followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate),
          inpatientOrgId: GetOrganizationId(inpatientEncounter),
          outpatientOrgId: GetOrganizationId(outpatientEnc)
      where outpatientEnc.period.start during followUpPeriod
        and inpatientOrgId = outpatientOrgId  // 同一院所
        and exists(
          "ACEI ARB Medications" M
            where M.authoredOn during outpatientEnc.period
              or M.authoredOn same day as start of outpatientEnc.period
        )
  )

// 判斷出院後3個月內門診是否使用ACEI
define function HasACEIInOutpatientWithin3Months(inpatientEncounter Encounter):
  exists(
    "All Outpatient Encounters" outpatientEnc
      let dischargeDate: GetLatestDischargeDate(inpatientEncounter),
          followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate)
      where outpatientEnc.period.start during followUpPeriod
        and GetOrganizationId(outpatientEnc) = GetOrganizationId(inpatientEncounter)
        and exists("ACEI ARB Medications" M
          where M.authoredOn during outpatientEnc.period
            and exists(M.medication.coding Coding 
              where Coding.code.startsWith('C09AA')))
  )

// 判斷出院後3個月內門診是否使用ARB
define function HasARBInOutpatientWithin3Months(inpatientEncounter Encounter):
  exists(
    "All Outpatient Encounters" outpatientEnc
      let dischargeDate: GetLatestDischargeDate(inpatientEncounter),
          followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate)
      where outpatientEnc.period.start during followUpPeriod
        and GetOrganizationId(outpatientEnc) = GetOrganizationId(inpatientEncounter)
        and exists("ACEI ARB Medications" M
          where M.authoredOn during outpatientEnc.period
            and exists(M.medication.coding Coding 
              where Coding.code.startsWith('C09CA')))
  )

// ===== 分母定義 (已排除NSTEMI和Hypotension) =====

// 步驟1: 所有AMI住院案件（已出院）
define "AMI Inpatient Cases With Discharge":
  "All Inpatient Encounters" E
    where HasPrimaryAMIDiagnosis(E)
      and IsDischargedEncounter(E)

// 步驟2: 排除NSTEMI主診斷案件
define "AMI Cases Excluding NSTEMI":
  "AMI Inpatient Cases With Discharge" E
    where not HasPrimaryNSTEMIDiagnosis(E)

// 步驟3: 排除Hypotension診斷案件（最終分母）
define "Denominator":
  "AMI Cases Excluding NSTEMI" E
    where not HasHypotensionDiagnosis(E)

// ===== 分子定義 =====

// 分母案件中，出院後3個月內在同院門診領有ACEI或ARB的案件
define "Numerator":
  "Denominator" E
    where HasACEIorARBInOutpatientWithin3Months(E)

// ===== 半年度分母分子 =====

// 第1期分母 (1-6月) - 依出院日期判定
define "Denominator Period 1":
  "Denominator" E
    where GetLatestDischargeDate(E) during "Period 1"

// 第1期分子
define "Numerator Period 1":
  "Denominator Period 1" E
    where HasACEIorARBInOutpatientWithin3Months(E)

// 第2期分母 (7-12月) - 依出院日期判定
define "Denominator Period 2":
  "Denominator" E
    where GetLatestDischargeDate(E) during "Period 2"

// 第2期分子
define "Numerator Period 2":
  "Denominator Period 2" E
    where HasACEIorARBInOutpatientWithin3Months(E)

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

// Hypotension排除統計
define "Hypotension Exclusion Statistics":
  {
    Before_Hypotension_Exclusion: Count("AMI Cases Excluding NSTEMI"),
    O265_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('O265')))),
    I95_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where exists(GetEncounterConditions(E) C 
        where exists(C.code.coding Coding 
          where Coding.code.startsWith('I95')))),
    Total_Hypotension_Excluded: Count("AMI Cases Excluding NSTEMI" E 
      where HasHypotensionDiagnosis(E)),
    After_Hypotension_Exclusion: Count("Denominator")
  }

// ACEI/ARB用藥統計
define "ACEI ARB Usage Statistics":
  {
    Total_With_ACEI_or_ARB: Count("Numerator"),
    ACEI_Only: Count("Numerator" E 
      where HasACEIInOutpatientWithin3Months(E) 
        and not HasARBInOutpatientWithin3Months(E)),
    ARB_Only: Count("Numerator" E 
      where HasARBInOutpatientWithin3Months(E) 
        and not HasACEIInOutpatientWithin3Months(E)),
    Both_ACEI_and_ARB: Count("Numerator" E 
      where HasACEIInOutpatientWithin3Months(E) 
        and HasARBInOutpatientWithin3Months(E)),
    ACEI_Cases: Count("Numerator" E 
      where HasACEIInOutpatientWithin3Months(E)),
    ARB_Cases: Count("Numerator" E 
      where HasARBInOutpatientWithin3Months(E))
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
define "Outpatient ACEI ARB Timing Analysis":
  "Numerator" E
    let dischargeDate: GetLatestDischargeDate(E),
        followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate),
        inpatientOrgId: GetOrganizationId(E),
        outpatientVisits: "All Outpatient Encounters" outpatientEnc
          where outpatientEnc.period.start during followUpPeriod
            and GetOrganizationId(outpatientEnc) = inpatientOrgId
            and exists("ACEI ARB Medications" M
              where M.authoredOn during outpatientEnc.period),
        firstVisit: First(outpatientVisits V sort by start of V.period),
        daysToFirstVisit: days between dischargeDate and start of firstVisit.period
    return {
      encounter_id: E.id,
      discharge_date: dischargeDate,
      first_outpatient_visit_date: start of firstVisit.period,
      days_to_first_visit: daysToFirstVisit,
      total_outpatient_visits_with_acei_arb: Count(outpatientVisits),
      has_acei: HasACEIInOutpatientWithin3Months(E),
      has_arb: HasARBInOutpatientWithin3Months(E),
      follow_up_period_end: end of followUpPeriod
    }

// ACEI/ARB用藥類型分析
define "ACEI ARB Type Analysis":
  "Numerator" E
    let dischargeDate: GetLatestDischargeDate(E),
        followUpPeriod: GetPostDischargeFollowUpPeriod(dischargeDate),
        acei_medications: "All Outpatient Encounters" outpatientEnc
          where outpatientEnc.period.start during followUpPeriod
            and GetOrganizationId(outpatientEnc) = GetOrganizationId(E)
            and exists("ACEI ARB Medications" M
              where M.authoredOn during outpatientEnc.period
                and exists(M.medication.coding Coding 
                  where Coding.code.startsWith('C09AA'))),
        arb_medications: "All Outpatient Encounters" outpatientEnc
          where outpatientEnc.period.start during followUpPeriod
            and GetOrganizationId(outpatientEnc) = GetOrganizationId(E)
            and exists("ACEI ARB Medications" M
              where M.authoredOn during outpatientEnc.period
                and exists(M.medication.coding Coding 
                  where Coding.code.startsWith('C09CA')))
    return {
      encounter_id: E.id,
      acei_visit_count: Count(acei_medications),
      arb_visit_count: Count(arb_medications)
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
      has_post_discharge_acei_or_arb: HasACEIorARBInOutpatientWithin3Months(E),
      has_acei: HasACEIInOutpatientWithin3Months(E),
      has_arb: HasARBInOutpatientWithin3Months(E)
    }

// ===== 品質指標總結 =====

define "Quality Indicator Summary":
  {
    indicator_name: '急性心肌梗塞(AMI)病人出院後三個月以內給藥比率 - 血管張力素轉化酶抑制劑(ACE inhibitor)或血管張力素II受體阻斷劑(ARB)',
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
    nstemi_excluded_cases: Count("AMI Inpatient Cases With Discharge") - Count("AMI Cases Excluding NSTEMI"),
    hypotension_excluded_cases: Count("AMI Cases Excluding NSTEMI") - Count("Denominator"),
    
    // 診斷分布
    ami_diagnosis_distribution: "AMI Diagnosis Distribution",
    
    // 排除詳情
    nstemi_exclusion_details: "NSTEMI Exclusion Statistics",
    hypotension_exclusion_details: "Hypotension Exclusion Statistics",
    
    // 用藥統計
    acei_arb_usage_statistics: "ACEI ARB Usage Statistics",
    
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
