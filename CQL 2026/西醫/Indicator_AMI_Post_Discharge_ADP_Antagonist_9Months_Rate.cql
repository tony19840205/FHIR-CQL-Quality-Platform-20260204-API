library Indicator_AMI_Post_Discharge_ADP_Antagonist_9Months_Rate version '1.0.0'

/*
急性心肌梗塞(AMI)病人出院後九個月以內給藥比率 - 腺嘌呤二磷酸受體拮抗劑(ADP受體拮抗劑)
Acute Myocardial Infarction (AMI) Post-Discharge 9-Month ADP Receptor Antagonist Prescription Rate

計算說明:
- 分子：分母案件出院後9個月內再至同院門診領有ADP受體拮抗劑的案件數
- 分母：已出院的急性心肌梗塞(AMI)病人
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21、I22、I5A
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除
2. 出院日：按【院所, ID, 生日, 住院日】歸戶，因同一次住院，會有串該多筆住院醫費用的情形，
   可能有多個出院日，以最晚之出院日的那一筆為代表案件
3. ADP受體拮抗劑：ATC藥品分類前7碼為B01AC04(clopidogrel)、B01AC05(ticlopidine)、
   B01AC22(prasugrel)、B01AC24(ticagrelor)
4. 門診領藥：出院後9個月內，在同一院所的門診領取ADP受體拮抗劑
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

// 出院後追蹤期間（9個月 = 270天）
parameter "Post Discharge Follow Up Days" Integer default 270

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

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// ===== 診斷判斷函數 =====

// 判斷Condition是否符合指定的ICD-10-CM前綴碼（任意位數）
define function "ConditionCodeStartsWith"(condition Condition, prefix String):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and StartsWith(C.code, prefix)
  )

// 判斷Condition是否為完全符合指定的ICD-10-CM碼
define function "ConditionCodeEquals"(condition Condition, code String):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and C.code = code
  )

// 判斷Encounter是否有AMI主診斷 (I21, I22, I5A前三碼)
define function "HasAMIDiagnosis"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and exists(
          C.category Cat
            where exists(
              Cat.coding CatCoding
                where CatCoding.system = 'http://terminology.hl7.org/CodeSystem/condition-category'
                  and CatCoding.code = 'encounter-diagnosis'
            )
        )
        and exists(
          C.extension Ext
            where Ext.url = 'http://hl7.org/fhir/StructureDefinition/condition-dueTo'
              and exists(
                Ext.extension SubExt
                  where SubExt.url = 'role'
                    and SubExt.value as CodeableConcept in "Primary Diagnosis Codes"
              )
        )
        and (
          "ConditionCodeStartsWith"(C, 'I21')
          or "ConditionCodeStartsWith"(C, 'I22')
          or "ConditionCodeStartsWith"(C, 'I5A')
        )
  )

// 主診斷編碼
define "Primary Diagnosis Codes":
  {
    CodeableConcept {
      coding: {
        Coding {
          system: 'http://terminology.hl7.org/CodeSystem/diagnosis-role',
          code: 'AD',
          display: 'Admission diagnosis'
        }
      }
    }
  }

// 判斷Encounter是否有NSTEMI排除診斷 (I214 或 I222主診斷)
define function "HasNSTEMIExclusion"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and exists(
          C.category Cat
            where exists(
              Cat.coding CatCoding
                where CatCoding.system = 'http://terminology.hl7.org/CodeSystem/condition-category'
                  and CatCoding.code = 'encounter-diagnosis'
            )
        )
        and exists(
          C.extension Ext
            where Ext.url = 'http://hl7.org/fhir/StructureDefinition/condition-dueTo'
              and exists(
                Ext.extension SubExt
                  where SubExt.url = 'role'
                    and SubExt.value as CodeableConcept in "Primary Diagnosis Codes"
              )
        )
        and (
          "ConditionCodeEquals"(C, 'I214')
          or "ConditionCodeEquals"(C, 'I222')
        )
  )

// ===== 案件定義與群組 =====

// 住院案件定義 (按院所+ID+生日+住院日歸戶)
define "Hospitalization Key":
  Tuple {
    organizationId: GetOrganizationId(encounter),
    patientId: Patient.id,
    birthDate: Patient.birthDate,
    admissionDate: date from start of encounter.period
  }

// 取得Organization ID的函數
define function "GetOrganizationId"(encounter Encounter):
  if encounter.serviceProvider.reference is not null
    then Last(Split(encounter.serviceProvider.reference, '/'))
    else null

// 取得同一住院案件的所有Encounter
define function "GetSameHospitalizationEncounters"(encounter Encounter):
  "All Inpatient Encounters" E
    where "GetOrganizationId"(E) = "GetOrganizationId"(encounter)
      and E.subject.reference = encounter.subject.reference
      and Patient.birthDate = Patient.birthDate
      and date from start of E.period = date from start of encounter.period

// 取得最晚出院日的Encounter
define function "GetLatestDischargeEncounter"(encounter Encounter):
  Last(
    "GetSameHospitalizationEncounters"(encounter) E
      sort by end of period
  )

// 取得最晚出院日
define function "GetLatestDischargeDate"(encounter Encounter):
  end of "GetLatestDischargeEncounter"(encounter).period

// 判斷整個住院案件是否符合AMI且無排除條件
define function "IsQualifiedAMIHospitalization"(encounter Encounter):
  let sameHospEncounters: "GetSameHospitalizationEncounters"(encounter)
  return
    // 至少有一個Encounter有AMI主診斷
    exists(sameHospEncounters E where "HasAMIDiagnosis"(E))
    // 沒有任何Encounter有NSTEMI排除診斷
    and not exists(sameHospEncounters E where "HasNSTEMIExclusion"(E))

// ===== 分母定義 =====

// 所有符合條件的AMI住院案件
define "Denominator Encounters":
  "All Inpatient Encounters" E
    where "IsQualifiedAMIHospitalization"(E)
      and E = "GetLatestDischargeEncounter"(E)  // 只取最晚出院日的Encounter作為代表

// 分母（總案件數）
define "Denominator":
  Count("Denominator Encounters")

// 分母（第一期）
define "Denominator Period 1":
  Count(
    "Denominator Encounters" E
      where E.period.start during "Period 1"
  )

// 分母（第二期）
define "Denominator Period 2":
  Count(
    "Denominator Encounters" E
      where E.period.start during "Period 2"
  )

// ===== 門診追蹤與ADP受體拮抗劑使用判斷 =====

// 計算出院後追蹤期間
define function "GetPostDischargeFollowUpPeriod"(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Post Discharge Follow Up Days" days]

// 判斷MedicationRequest是否為ADP受體拮抗劑
define function "IsADPAntagonist"(medication MedicationRequest):
  exists(
    medication.medication.coding C
      where C.system = 'http://www.whocc.no/atc'
        and (
          StartsWith(C.code, 'B01AC04')
          or StartsWith(C.code, 'B01AC05')
          or StartsWith(C.code, 'B01AC22')
          or StartsWith(C.code, 'B01AC24')
        )
  )

// 判斷病人在出院後9個月內的門診是否有ADP受體拮抗劑
define function "HasADPAntagonistInOutpatientWithin9Months"(inpatientEncounter Encounter):
  let dischargeDate: "GetLatestDischargeDate"(inpatientEncounter),
      followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
      inpatientOrgId: "GetOrganizationId"(inpatientEncounter)
  return
    exists(
      "All Outpatient Encounters" OutpatientEnc
        where OutpatientEnc.subject.reference = inpatientEncounter.subject.reference
          and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId  // 同一院所
          and start of OutpatientEnc.period in followUpPeriod  // 9個月內門診
          and exists(
            "All Medication Requests" M
              where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                and "IsADPAntagonist"(M)
          )
    )

// ===== 分子定義 =====

// 分子案件（出院後9個月內有在同院門診領ADP受體拮抗劑的案件）
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasADPAntagonistInOutpatientWithin9Months"(E)

// 分子（符合條件案件數）
define "Numerator":
  Count("Numerator Encounters")

// 分子（第一期）
define "Numerator Period 1":
  Count(
    "Numerator Encounters" E
      where E.period.start during "Period 1"
  )

// 分子（第二期）
define "Numerator Period 2":
  Count(
    "Numerator Encounters" E
      where E.period.start during "Period 2"
  )

// ===== 指標計算 =====

// 整體指標（全年）
define "Indicator Rate":
  if "Denominator" > 0
    then Round("Numerator" / "Denominator" * 100, 2)
    else null

// 第一期指標
define "Indicator Rate Period 1":
  if "Denominator Period 1" > 0
    then Round("Numerator Period 1" / "Denominator Period 1" * 100, 2)
    else null

// 第二期指標
define "Indicator Rate Period 2":
  if "Denominator Period 2" > 0
    then Round("Numerator Period 2" / "Denominator Period 2" * 100, 2)
    else null

// ===== 品質檢核 =====

// 資料完整性檢查
define "Data Quality Check":
  Tuple {
    total_inpatient_encounters: Count("All Inpatient Encounters"),
    ami_encounters_with_diagnosis: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E)),
    nstemi_exclusions: Count("All Inpatient Encounters" E where "HasNSTEMIExclusion"(E)),
    qualified_ami_hospitalizations: "Denominator",
    cases_with_adp_antagonist_in_outpatient: "Numerator"
  }

// ADP受體拮抗劑使用統計
define "ADP Antagonist Usage Statistics":
  Tuple {
    total_cases: "Numerator",
    clopidogrel_cases: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            inpatientOrgId: "GetOrganizationId"(E)
        where exists(
          "All Outpatient Encounters" OutpatientEnc
            where OutpatientEnc.subject.reference = E.subject.reference
              and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
              and start of OutpatientEnc.period in followUpPeriod
              and exists(
                "All Medication Requests" M
                  where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                    and exists(
                      M.medication.coding C
                        where C.system = 'http://www.whocc.no/atc'
                          and StartsWith(C.code, 'B01AC04')
                    )
              )
        )
    ),
    ticlopidine_cases: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            inpatientOrgId: "GetOrganizationId"(E)
        where exists(
          "All Outpatient Encounters" OutpatientEnc
            where OutpatientEnc.subject.reference = E.subject.reference
              and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
              and start of OutpatientEnc.period in followUpPeriod
              and exists(
                "All Medication Requests" M
                  where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                    and exists(
                      M.medication.coding C
                        where C.system = 'http://www.whocc.no/atc'
                          and StartsWith(C.code, 'B01AC05')
                    )
              )
        )
    ),
    prasugrel_cases: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            inpatientOrgId: "GetOrganizationId"(E)
        where exists(
          "All Outpatient Encounters" OutpatientEnc
            where OutpatientEnc.subject.reference = E.subject.reference
              and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
              and start of OutpatientEnc.period in followUpPeriod
              and exists(
                "All Medication Requests" M
                  where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                    and exists(
                      M.medication.coding C
                        where C.system = 'http://www.whocc.no/atc'
                          and StartsWith(C.code, 'B01AC22')
                    )
              )
        )
    ),
    ticagrelor_cases: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            inpatientOrgId: "GetOrganizationId"(E)
        where exists(
          "All Outpatient Encounters" OutpatientEnc
            where OutpatientEnc.subject.reference = E.subject.reference
              and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
              and start of OutpatientEnc.period in followUpPeriod
              and exists(
                "All Medication Requests" M
                  where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                    and exists(
                      M.medication.coding C
                        where C.system = 'http://www.whocc.no/atc'
                          and StartsWith(C.code, 'B01AC24')
                    )
              )
        )
    )
  }

// 出院後門診追蹤統計
define "Outpatient Follow Up Statistics":
  Tuple {
    total_qualified_cases: "Denominator",
    cases_with_9month_outpatient_visit: Count(
      "Denominator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            inpatientOrgId: "GetOrganizationId"(E)
        where exists(
          "All Outpatient Encounters" OutpatientEnc
            where OutpatientEnc.subject.reference = E.subject.reference
              and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
              and start of OutpatientEnc.period in followUpPeriod
        )
    ),
    cases_with_adp_antagonist_prescription: "Numerator",
    avg_days_to_first_outpatient_visit: Avg(
      "Denominator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            inpatientOrgId: "GetOrganizationId"(E),
            firstOutpatientVisit: First(
              "All Outpatient Encounters" OutpatientEnc
                where OutpatientEnc.subject.reference = E.subject.reference
                  and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
                  and start of OutpatientEnc.period in followUpPeriod
                sort by start of period
            )
        where firstOutpatientVisit is not null
        return days between dischargeDate and start of firstOutpatientVisit.period
    )
  }

// ADP受體拮抗劑使用時機分析
define "ADP Antagonist Timing Analysis":
  "Numerator Encounters" E
    let dischargeDate: "GetLatestDischargeDate"(E),
        followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
        inpatientOrgId: "GetOrganizationId"(E),
        firstADPVisit: First(
          "All Outpatient Encounters" OutpatientEnc
            where OutpatientEnc.subject.reference = E.subject.reference
              and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
              and start of OutpatientEnc.period in followUpPeriod
              and exists(
                "All Medication Requests" M
                  where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                    and "IsADPAntagonist"(M)
              )
            sort by start of period
        )
    return Tuple {
      patient_id: Patient.id,
      discharge_date: ToString(dischargeDate),
      first_adp_antagonist_visit_date: ToString(start of firstADPVisit.period),
      days_from_discharge: days between dischargeDate and start of firstADPVisit.period,
      total_outpatient_visits_with_adp_antagonist: Count(
        "All Outpatient Encounters" OutpatientEnc
          where OutpatientEnc.subject.reference = E.subject.reference
            and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
            and start of OutpatientEnc.period in followUpPeriod
            and exists(
              "All Medication Requests" M
                where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                  and "IsADPAntagonist"(M)
            )
      )
    }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '急性心肌梗塞(AMI)病人出院後九個月以內給藥比率 - 腺嘌呤二磷酸受體拮抗劑(ADP受體拮抗劑)',
    measurement_period: ToString("Measurement Period"),
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    
    // 分期指標
    period_1_numerator: "Numerator Period 1",
    period_1_denominator: "Denominator Period 1",
    period_1_rate: "Indicator Rate Period 1",
    
    period_2_numerator: "Numerator Period 2",
    period_2_denominator: "Denominator Period 2",
    period_2_rate: "Indicator Rate Period 2",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // ADP受體拮抗劑使用統計
    adp_antagonist_usage: "ADP Antagonist Usage Statistics",
    
    // 追蹤統計
    follow_up_statistics: "Outpatient Follow Up Statistics",
    
    // 使用時機分析（前10筆）
    timing_analysis_sample: "ADP Antagonist Timing Analysis"
  }
