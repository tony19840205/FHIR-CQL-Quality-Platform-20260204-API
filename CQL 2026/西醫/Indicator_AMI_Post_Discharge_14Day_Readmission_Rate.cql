library Indicator_AMI_Post_Discharge_14Day_Readmission_Rate version '1.0.0'

/*
急性心肌梗塞(AMI)病人出院後十四日以內因同一主診斷或相關病情之非計畫性再住院比率
Acute Myocardial Infarction (AMI) Post-Discharge 14-Day Unplanned Readmission Rate

計算說明:
- 分子：分母案件14日內因AMI或相關病情(排除計畫性住院)而再次住院(含跨院)案件
- 分母：住院主診斷為AMI（18歲以上）案件之出院案件數
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. AMI定義：同次住院有任一筆主診斷ICD-10-CM Code前三碼為I21、I22、I5A
   但若同次住院有任一筆主診斷為I214、I222，則該次住院資料全部排除
2. 18歲以上：（出院年-出生年）≥18
3. 出院日：按【院所, ID, 生日, 住院日】歸戶，因同一次住院，會有申報多筆住院醫療費用的情形，
   可能有多個出院日，以最晚之出院日的那一筆為代表案件
4. 相關病情：主診斷前3碼為I20、I24、I25（即CHD及冠狀動脈疾病）
5. 計畫性住院：會令令68023B(冠狀動脈繞道手術一條血管)、68024B(冠狀動脈繞道手術二條血管)、
   68025B(冠狀動脈繞道手術三條血管)任一項；若該次再住院(同一院所、ID、生日、住院日)
   有任一筆申報則排除該次再住院，不列入分子統計
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

// 出院後追蹤期間（14日）
parameter "Post Discharge Follow Up Days" Integer default 14

// 年齡限制
parameter "Minimum Age" Integer default 18

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'

// AMI診斷碼定義 (I21, I22, I5A系列)
code "I21": 'I21' from "ICD10CM" display 'Acute myocardial infarction'
code "I22": 'I22' from "ICD10CM" display 'Subsequent ST elevation (STEMI) and non-ST elevation (NSTEMI) myocardial infarction'
code "I5A": 'I5A' from "ICD10CM" display 'Non-ischemic myocardial injury (non-traumatic)'

// AMI排除診斷碼 (NSTEMI)
code "I214": 'I214' from "ICD10CM" display 'Non-ST elevation (NSTEMI) myocardial infarction'
code "I222": 'I222' from "ICD10CM" display 'Subsequent non-ST elevation (NSTEMI) myocardial infarction'

// 相關病情診斷碼 (CHD及冠狀動脈疾病)
code "I20": 'I20' from "ICD10CM" display 'Angina pectoris'
code "I24": 'I24' from "ICD10CM" display 'Other acute ischemic heart diseases'
code "I25": 'I25' from "ICD10CM" display 'Chronic ischemic heart disease'

// 計畫性住院手術碼（冠狀動脈繞道手術）
code "68023B": '68023B' from "TWProcedure" display 'CABG - Single vessel'
code "68024B": '68024B' from "TWProcedure" display 'CABG - Two vessels'
code "68025B": '68025B' from "TWProcedure" display 'CABG - Three vessels'

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

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有Procedure
define "All Procedures":
  [Procedure] P

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

// 判斷Encounter是否有相關病情主診斷 (I20, I24, I25前三碼)
define function "HasRelatedCardiacDiagnosis"(encounter Encounter):
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
          "ConditionCodeStartsWith"(C, 'I20')
          or "ConditionCodeStartsWith"(C, 'I24')
          or "ConditionCodeStartsWith"(C, 'I25')
        )
  )

// 判斷Encounter是否有AMI或相關病情主診斷
define function "HasAMIOrRelatedDiagnosis"(encounter Encounter):
  "HasAMIDiagnosis"(encounter) or "HasRelatedCardiacDiagnosis"(encounter)

// 判斷Encounter是否有CABG手術（計畫性住院）
define function "HasCABGProcedure"(encounter Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference = 'Encounter/' + encounter.id
        and P.status = 'completed'
        and exists(
          P.code.coding C
            where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
              and (
                C.code = '68023B'
                or C.code = '68024B'
                or C.code = '68025B'
              )
        )
  )

// ===== 案件定義與群組 =====

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

// 計算年齡
define function "GetAgeAtDischarge"(encounter Encounter):
  AgeInYearsAt(date from "GetLatestDischargeDate"(encounter))

// 判斷整個住院案件是否符合AMI且無排除條件
define function "IsQualifiedAMIHospitalization"(encounter Encounter):
  let sameHospEncounters: "GetSameHospitalizationEncounters"(encounter)
  return
    // 至少有一個Encounter有AMI主診斷
    exists(sameHospEncounters E where "HasAMIDiagnosis"(E))
    // 沒有任何Encounter有NSTEMI排除診斷
    and not exists(sameHospEncounters E where "HasNSTEMIExclusion"(E))
    // 年齡18歲以上
    and "GetAgeAtDischarge"(encounter) >= "Minimum Age"

// ===== 分母定義 =====

// 所有符合條件的AMI住院案件（18歲以上）
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

// ===== 再住院判斷 =====

// 計算出院後追蹤期間（14日內）
define function "GetPostDischargeFollowUpPeriod"(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Post Discharge Follow Up Days" days]

// 判斷病人在出院後14日內是否有AMI或相關病情的非計畫性再住院
define function "HasUnplannedReadmissionWithin14Days"(inpatientEncounter Encounter):
  let dischargeDate: "GetLatestDischargeDate"(inpatientEncounter),
      followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate)
  return
    exists(
      "All Inpatient Encounters" ReadmissionEnc
        where ReadmissionEnc.subject.reference = inpatientEncounter.subject.reference
          and start of ReadmissionEnc.period in followUpPeriod  // 14日內再住院
          and "HasAMIOrRelatedDiagnosis"(ReadmissionEnc)  // AMI或相關病情主診斷
          and not "HasCABGProcedure"(ReadmissionEnc)  // 排除計畫性住院（CABG手術）
          and ReadmissionEnc.id != inpatientEncounter.id  // 排除同一次住院
    )

// ===== 分子定義 =====

// 分子案件（出院後14日內有AMI或相關病情非計畫性再住院的案件）
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasUnplannedReadmissionWithin14Days"(E)

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
    age_under_18_exclusions: Count(
      "All Inpatient Encounters" E 
        where "HasAMIDiagnosis"(E) 
          and "GetAgeAtDischarge"(E) < "Minimum Age"
    ),
    qualified_ami_hospitalizations: "Denominator",
    cases_with_14day_readmission: "Numerator",
    planned_readmissions_excluded: Count(
      "Denominator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate)
        where exists(
          "All Inpatient Encounters" ReadmissionEnc
            where ReadmissionEnc.subject.reference = E.subject.reference
              and start of ReadmissionEnc.period in followUpPeriod
              and "HasAMIOrRelatedDiagnosis"(ReadmissionEnc)
              and "HasCABGProcedure"(ReadmissionEnc)  // 有CABG手術的計畫性住院
        )
    )
  }

// 再住院診斷分類統計
define "Readmission Diagnosis Statistics":
  Tuple {
    total_readmission_cases: "Numerator",
    ami_primary_diagnosis: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate)
        where exists(
          "All Inpatient Encounters" ReadmissionEnc
            where ReadmissionEnc.subject.reference = E.subject.reference
              and start of ReadmissionEnc.period in followUpPeriod
              and "HasAMIDiagnosis"(ReadmissionEnc)
              and not "HasCABGProcedure"(ReadmissionEnc)
        )
    ),
    related_cardiac_diagnosis: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate)
        where exists(
          "All Inpatient Encounters" ReadmissionEnc
            where ReadmissionEnc.subject.reference = E.subject.reference
              and start of ReadmissionEnc.period in followUpPeriod
              and "HasRelatedCardiacDiagnosis"(ReadmissionEnc)
              and not "HasAMIDiagnosis"(ReadmissionEnc)
              and not "HasCABGProcedure"(ReadmissionEnc)
        )
    ),
    same_hospital_readmission: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            originalOrgId: "GetOrganizationId"(E)
        where exists(
          "All Inpatient Encounters" ReadmissionEnc
            where ReadmissionEnc.subject.reference = E.subject.reference
              and start of ReadmissionEnc.period in followUpPeriod
              and "HasAMIOrRelatedDiagnosis"(ReadmissionEnc)
              and not "HasCABGProcedure"(ReadmissionEnc)
              and "GetOrganizationId"(ReadmissionEnc) = originalOrgId
        )
    ),
    cross_hospital_readmission: Count(
      "Numerator Encounters" E
        let dischargeDate: "GetLatestDischargeDate"(E),
            followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
            originalOrgId: "GetOrganizationId"(E)
        where exists(
          "All Inpatient Encounters" ReadmissionEnc
            where ReadmissionEnc.subject.reference = E.subject.reference
              and start of ReadmissionEnc.period in followUpPeriod
              and "HasAMIOrRelatedDiagnosis"(ReadmissionEnc)
              and not "HasCABGProcedure"(ReadmissionEnc)
              and "GetOrganizationId"(ReadmissionEnc) != originalOrgId
        )
    )
  }

// 再住院時機分析
define "Readmission Timing Analysis":
  "Numerator Encounters" E
    let dischargeDate: "GetLatestDischargeDate"(E),
        followUpPeriod: "GetPostDischargeFollowUpPeriod"(dischargeDate),
        firstReadmission: First(
          "All Inpatient Encounters" ReadmissionEnc
            where ReadmissionEnc.subject.reference = E.subject.reference
              and start of ReadmissionEnc.period in followUpPeriod
              and "HasAMIOrRelatedDiagnosis"(ReadmissionEnc)
              and not "HasCABGProcedure"(ReadmissionEnc)
            sort by start of period
        )
    return Tuple {
      patient_id: Patient.id,
      discharge_date: ToString(dischargeDate),
      first_readmission_date: ToString(start of firstReadmission.period),
      days_from_discharge: days between dischargeDate and start of firstReadmission.period,
      diagnosis_type: 
        if "HasAMIDiagnosis"(firstReadmission) then 'AMI'
        else if "HasRelatedCardiacDiagnosis"(firstReadmission) then 'Related Cardiac (I20/I24/I25)'
        else 'Other',
      hospital_type:
        if "GetOrganizationId"(firstReadmission) = "GetOrganizationId"(E) then 'Same Hospital'
        else 'Cross Hospital',
      total_readmissions_within_14days: Count(
        "All Inpatient Encounters" ReadmissionEnc
          where ReadmissionEnc.subject.reference = E.subject.reference
            and start of ReadmissionEnc.period in followUpPeriod
            and "HasAMIOrRelatedDiagnosis"(ReadmissionEnc)
            and not "HasCABGProcedure"(ReadmissionEnc)
      )
    }

// 年齡分組統計
define "Age Group Statistics":
  Tuple {
    age_18_44: Count("Denominator Encounters" E where "GetAgeAtDischarge"(E) >= 18 and "GetAgeAtDischarge"(E) <= 44),
    age_45_64: Count("Denominator Encounters" E where "GetAgeAtDischarge"(E) >= 45 and "GetAgeAtDischarge"(E) <= 64),
    age_65_plus: Count("Denominator Encounters" E where "GetAgeAtDischarge"(E) >= 65),
    age_18_44_readmission: Count("Numerator Encounters" E where "GetAgeAtDischarge"(E) >= 18 and "GetAgeAtDischarge"(E) <= 44),
    age_45_64_readmission: Count("Numerator Encounters" E where "GetAgeAtDischarge"(E) >= 45 and "GetAgeAtDischarge"(E) <= 64),
    age_65_plus_readmission: Count("Numerator Encounters" E where "GetAgeAtDischarge"(E) >= 65)
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '急性心肌梗塞(AMI)病人出院後十四日以內因同一主診斷或相關病情之非計畫性再住院比率',
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
    
    // 再住院診斷統計
    readmission_diagnosis_statistics: "Readmission Diagnosis Statistics",
    
    // 年齡分組統計
    age_group_statistics: "Age Group Statistics",
    
    // 再住院時機分析（前10筆）
    timing_analysis_sample: "Readmission Timing Analysis"
  }
