library Indicator_AMI_Post_Discharge_Aspirin_9Months_Rate version '1.0.0'

/*
急性心肌梗塞(AMI)病人出院後九個月以內給藥比率 - 阿斯匹靈(Aspirin)
Acute Myocardial Infarction (AMI) Post-Discharge 9-Month Aspirin Prescription Rate

計算說明:
- 分子：分母案件出院後9個月內再至同院門診領有Aspirin的案件數
- 分母：已出院的AMI案件（排除上腸胃道出血或其他出血案件）
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21、I22、I5A
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除
2. 出院日：按【院所, ID, 生日, 住院日】歸戶，因同一次住院，會有串該多筆住院醫費用的情形，
   可能有多個出院日，以最晚之出院日的那一筆為代表案件
3. 上腸胃道(UGI)出血或其他出血案件：同次住院有任一主次診斷含出血相關診斷碼，該次住院資料全部排除
4. Aspirin：ATC藥品分類前7碼為B01AC06（acetylsalicylic acid）
5. 門診領藥：出院後9個月內，在同一院所的門診領取Aspirin
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

// Aspirin藥品碼
code "B01AC06": 'B01AC06' from "ATC" display 'acetylsalicylic acid'

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

// 判斷Encounter是否有出血診斷 (任一主次診斷)
define function "HasBleedingDiagnosis"(encounter Encounter):
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
        and (
          // 上消化道出血 (K25-K29)
          "ConditionCodeStartsWith"(C, 'K25')
          or "ConditionCodeStartsWith"(C, 'K26')
          or "ConditionCodeStartsWith"(C, 'K27')
          or "ConditionCodeStartsWith"(C, 'K28')
          or "ConditionCodeStartsWith"(C, 'K29')
          or "ConditionCodeStartsWith"(C, 'K92')
          // 腦出血 (I60-I62)
          or "ConditionCodeStartsWith"(C, 'I60')
          or "ConditionCodeStartsWith"(C, 'I61')
          or "ConditionCodeStartsWith"(C, 'I62')
          // 其他出血
          or "ConditionCodeStartsWith"(C, 'R04')
          or "ConditionCodeStartsWith"(C, 'R31')
          or "ConditionCodeStartsWith"(C, 'R58')
          or "ConditionCodeStartsWith"(C, 'D62')
          or "ConditionCodeStartsWith"(C, 'D500')
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
    // 沒有任何Encounter有出血診斷
    and not exists(sameHospEncounters E where "HasBleedingDiagnosis"(E))

// ===== 分母定義 =====

// 所有符合條件的AMI住院案件（已排除出血）
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

// ===== 門診追蹤與Aspirin使用判斷 =====

// 計算出院後追蹤期間
define function "GetPostDischargeFollowUpPeriod"(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Post Discharge Follow Up Days" days]

// 判斷MedicationRequest是否為Aspirin
define function "IsAspirin"(medication MedicationRequest):
  exists(
    medication.medication.coding C
      where C.system = 'http://www.whocc.no/atc'
        and StartsWith(C.code, 'B01AC06')
  )

// 判斷病人在出院後9個月內的門診是否有Aspirin
define function "HasAspirinInOutpatientWithin9Months"(inpatientEncounter Encounter):
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
                and "IsAspirin"(M)
          )
    )

// ===== 分子定義 =====

// 分子案件（出院後9個月內有在同院門診領Aspirin的案件）
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasAspirinInOutpatientWithin9Months"(E)

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
    bleeding_exclusions: Count("All Inpatient Encounters" E where "HasBleedingDiagnosis"(E)),
    qualified_ami_hospitalizations: "Denominator",
    cases_with_aspirin_in_outpatient: "Numerator"
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
    cases_with_aspirin_prescription: "Numerator",
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

// Aspirin使用時機分析
define "Aspirin Timing Analysis":
  "Numerator Encounters" E
    let dischargeDate: "GetLatestDischargeDate"(E),
        followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
        inpatientOrgId: "GetOrganizationId"(E),
        firstAspirinVisit: First(
          "All Outpatient Encounters" OutpatientEnc
            where OutpatientEnc.subject.reference = E.subject.reference
              and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
              and start of OutpatientEnc.period in followUpPeriod
              and exists(
                "All Medication Requests" M
                  where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                    and "IsAspirin"(M)
              )
            sort by start of period
        )
    return Tuple {
      patient_id: Patient.id,
      discharge_date: ToString(dischargeDate),
      first_aspirin_visit_date: ToString(start of firstAspirinVisit.period),
      days_from_discharge: days between dischargeDate and start of firstAspirinVisit.period,
      total_outpatient_visits_with_aspirin: Count(
        "All Outpatient Encounters" OutpatientEnc
          where OutpatientEnc.subject.reference = E.subject.reference
            and "GetOrganizationId"(OutpatientEnc) = inpatientOrgId
            and start of OutpatientEnc.period in followUpPeriod
            and exists(
              "All Medication Requests" M
                where M.encounter.reference = 'Encounter/' + OutpatientEnc.id
                  and "IsAspirin"(M)
            )
      )
    }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '急性心肌梗塞(AMI)病人出院後九個月以內給藥比率 - 阿斯匹靈(Aspirin)',
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
    
    // 追蹤統計
    follow_up_statistics: "Outpatient Follow Up Statistics",
    
    // 使用時機分析（前10筆）
    timing_analysis_sample: "Aspirin Timing Analysis"
  }
