library Indicator_Outpatient_Surgery_2Day_ED_Or_Admission_Rate version '1.0.0'

/*
門診手術後二日以內急診或住院率
Outpatient Surgery 2-Day Emergency Department Visit or Admission Rate

計算說明:
- 分子：門診手術後2日(含)內因相同主診斷或手術急診或住院的人次(排除同日先急診後手術案件)
- 分母：門診手術人次
- 資料範圍：門診+急診+住院資料
- 計算頻率：每季

備註:
1. 門診手術：醫令代碼前2碼為62-88，且醫令代碼長度為6或7且排除案件分類「02」(急診)
2. 因相同主診斷或手術：再急診或住院中報與門診手術相同醫令或門診手術之主診斷相同者
3. 急診係指門診案件分類「02」，住院係指申報住院者
4. 計算頻率：每季
5. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-07)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 季度期間定義
parameter "Quarterly Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0],  // Q1
    Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0],  // Q2
    Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0],  // Q3
    Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]   // Q4
  }

// 手術後追蹤期間（2日，含當天）
parameter "Post Surgery Follow Up Days" Integer default 2

// 編碼系統定義
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "TWCaseType": 'http://healthcare.gov.tw/case-type'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 案件分類-急診（需排除於門診手術定義中）
code "CASE_TYPE_02": '02' from "TWCaseType" display '西醫急診'

// 資料來源定義
context Patient

// ===== 門診手術醫令代碼範圍 =====

// 門診手術醫令代碼前2碼範圍（62-88）
define "Outpatient Surgery Procedure Code Prefixes":
  {
    '62', '63', '64', '65', '66', '67', '68', '69',
    '70', '71', '72', '73', '74', '75', '76', '77', '78', '79',
    '80', '81', '82', '83', '84', '85', '86', '87', '88'
  }

// ===== 基礎資料定義 =====

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 門診Encounter編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有急診Encounter
define "All Emergency Encounters":
  [Encounter: type in "Emergency Encounter Codes"] E
    where E.status = 'finished'

// 急診Encounter編碼
define "Emergency Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'EMER', display: 'emergency' }
  }

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'

// 住院Encounter編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

// 所有Procedure
define "All Procedures":
  [Procedure] P

// 所有Condition
define "All Conditions":
  [Condition] C

// ===== 輔助函數 =====

// 判斷Procedure是否為門診手術醫令（前2碼為62-88，長度6或7）
define function "IsOutpatientSurgeryProcedure"(procedure Procedure):
  exists(
    procedure.code.coding C
      where C.system = 'http://healthcare.gov.tw/procedure'
        and (Length(C.code) = 6 or Length(C.code) = 7)
        and Substring(C.code, 0, 2) in "Outpatient Surgery Procedure Code Prefixes"
  )

// 判斷Encounter是否為急診案件（案件分類02）
define function "IsEmergencyCase"(encounter Encounter):
  exists(
    encounter.extension Ext
      where Ext.url = 'http://healthcare.gov.tw/fhir/StructureDefinition/case-type'
        and (Ext.value as CodeableConcept).coding C
          where C.system = 'http://healthcare.gov.tw/case-type'
            and C.code = '02'
  )

// 取得Procedure的代碼
define function "GetProcedureCode"(procedure Procedure):
  First(
    procedure.code.coding C
      where C.system = 'http://healthcare.gov.tw/procedure'
      return C.code
  )

// 取得Encounter的主診斷
define function "GetPrimaryDiagnosis"(encounter Encounter):
  First(
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
                    and (SubExt.value as CodeableConcept).coding RoleCoding
                      where RoleCoding.system = 'http://terminology.hl7.org/CodeSystem/diagnosis-role'
                        and RoleCoding.code = 'billing'
              )
        )
      return C
  )

// 取得診斷ICD碼
define function "GetDiagnosisCode"(condition Condition):
  First(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
      return C.code
  )

// 判斷兩個診斷碼是否相同
define function "IsSameDiagnosis"(code1 String, code2 String):
  code1 = code2

// 取得Encounter日期
define function "GetEncounterDate"(encounter Encounter):
  start of encounter.period

// ===== 分母：門診手術人次 =====

// 步驟1：找出所有門診案件中有手術的案件
define "Outpatient Encounters With Surgery":
  "All Outpatient Encounters" E
    where not "IsEmergencyCase"(E)  // 排除急診案件（案件分類02）
      and exists(
        "All Procedures" P
          where P.encounter.reference = 'Encounter/' + E.id
            and P.status = 'completed'
            and "IsOutpatientSurgeryProcedure"(P)
      )

// 步驟2：取得每個門診手術案件的詳細資訊
define "Outpatient Surgery Details":
  "Outpatient Encounters With Surgery" E
    let 
      surgeryDate: "GetEncounterDate"(E),
      surgeryProcedures: 
        "All Procedures" P
          where P.encounter.reference = 'Encounter/' + E.id
            and P.status = 'completed'
            and "IsOutpatientSurgeryProcedure"(P),
      primaryDiagnosis: "GetPrimaryDiagnosis"(E),
      diagnosisCode: "GetDiagnosisCode"(primaryDiagnosis)
    return {
      encounter: E,
      surgeryDate: surgeryDate,
      surgeryProcedures: surgeryProcedures,
      primaryDiagnosisCode: diagnosisCode,
      patientId: Patient.id
    }

// 分母：門診手術人次
define "Denominator":
  "Outpatient Surgery Details"

define "Denominator Count":
  Count("Denominator")

// ===== 分子：2日內因相同主診斷或手術急診或住院 =====

// 步驟1：對每個門診手術，找出2日內的急診或住院
define "Follow Up Events":
  "Denominator" D
    let 
      surgeryDate: D.surgeryDate,
      followUpPeriod: Interval[surgeryDate, surgeryDate + "Post Surgery Follow Up Days" days],
      
      // 找出2日內的急診案件
      emergencyVisits:
        "All Emergency Encounters" EmergEnc
          where "GetEncounterDate"(EmergEnc) in followUpPeriod
            and "GetEncounterDate"(EmergEnc) > surgeryDate  // 排除同日先急診的情況
            and (
              // 相同主診斷
              "IsSameDiagnosis"(
                "GetDiagnosisCode"("GetPrimaryDiagnosis"(EmergEnc)),
                D.primaryDiagnosisCode
              )
              or
              // 相同手術醫令
              exists(
                "All Procedures" P
                  where P.encounter.reference = 'Encounter/' + EmergEnc.id
                    and exists(
                      D.surgeryProcedures SurgProc
                        where "GetProcedureCode"(P) = "GetProcedureCode"(SurgProc)
                    )
              )
            ),
      
      // 找出2日內的住院案件
      inpatientAdmissions:
        "All Inpatient Encounters" InpEnc
          where "GetEncounterDate"(InpEnc) in followUpPeriod
            and "GetEncounterDate"(InpEnc) > surgeryDate  // 排除同日先急診的情況
            and (
              // 相同主診斷
              "IsSameDiagnosis"(
                "GetDiagnosisCode"("GetPrimaryDiagnosis"(InpEnc)),
                D.primaryDiagnosisCode
              )
              or
              // 相同手術醫令
              exists(
                "All Procedures" P
                  where P.encounter.reference = 'Encounter/' + InpEnc.id
                    and exists(
                      D.surgeryProcedures SurgProc
                        where "GetProcedureCode"(P) = "GetProcedureCode"(SurgProc)
                    )
              )
            )
    return {
      surgeryEncounter: D.encounter,
      surgeryDate: surgeryDate,
      patientId: D.patientId,
      primaryDiagnosisCode: D.primaryDiagnosisCode,
      emergencyVisits: emergencyVisits,
      inpatientAdmissions: inpatientAdmissions,
      hasEmergency: exists(emergencyVisits),
      hasAdmission: exists(inpatientAdmissions),
      hasFollowUpEvent: exists(emergencyVisits) or exists(inpatientAdmissions)
    }

// 分子：有2日內急診或住院的門診手術案件
define "Numerator":
  "Follow Up Events" F
    where F.hasFollowUpEvent = true

define "Numerator Count":
  Count("Numerator")

// ===== 指標計算 =====

// 整體比率
define "Overall Rate":
  if "Denominator Count" > 0
  then Round(("Numerator Count" / "Denominator Count") * 100, 2)
  else null

// 季度比率
define "Quarterly Rates":
  "Quarterly Periods" Period
    let 
      quarterlyDenominator: 
        "Denominator" D
          where D.surgeryDate during Period,
      quarterlyNumerator:
        "Numerator" N
          where N.surgeryDate during Period,
      denominatorCount: Count(quarterlyDenominator),
      numeratorCount: Count(quarterlyNumerator),
      rate: if denominatorCount > 0 
            then Round((numeratorCount / denominatorCount) * 100, 2)
            else null
    return {
      period: Period,
      period_start: start of Period,
      period_end: end of Period,
      denominator_count: denominatorCount,
      numerator_count: numeratorCount,
      rate: rate
    }

// ===== 詳細統計資訊 =====

// 僅急診案件統計
define "Emergency Only Cases":
  "Numerator" N
    where N.hasEmergency = true and N.hasAdmission = false

define "Emergency Only Count":
  Count("Emergency Only Cases")

// 僅住院案件統計
define "Admission Only Cases":
  "Numerator" N
    where N.hasAdmission = true and N.hasEmergency = false

define "Admission Only Count":
  Count("Admission Only Cases")

// 同時有急診和住院
define "Both Emergency And Admission Cases":
  "Numerator" N
    where N.hasEmergency = true and N.hasAdmission = true

define "Both Emergency And Admission Count":
  Count("Both Emergency And Admission Cases")

// 事件發生時間分布
define "Event Time Distribution":
  "Numerator" N
    let 
      surgeryDate: N.surgeryDate,
      firstEmergencyDate: Minimum(N.emergencyVisits E return "GetEncounterDate"(E)),
      firstAdmissionDate: Minimum(N.inpatientAdmissions I return "GetEncounterDate"(I)),
      firstEventDate: 
        if firstEmergencyDate is not null and firstAdmissionDate is not null
        then if firstEmergencyDate < firstAdmissionDate then firstEmergencyDate else firstAdmissionDate
        else Coalesce(firstEmergencyDate, firstAdmissionDate),
      daysToEvent: days between surgeryDate and firstEventDate
    return {
      patient_id: N.patientId,
      surgery_date: surgeryDate,
      first_event_date: firstEventDate,
      days_to_event: daysToEvent,
      event_type: 
        case
          when N.hasEmergency and not N.hasAdmission then 'Emergency Only'
          when N.hasAdmission and not N.hasEmergency then 'Admission Only'
          when N.hasEmergency and N.hasAdmission then 'Both'
          else 'None'
        end
    }

// 平均事件發生天數
define "Average Days To Event":
  if Count("Event Time Distribution") > 0
  then Round(
    Avg("Event Time Distribution" D return D.days_to_event),
    2
  )
  else null

// ===== 最終輸出報告 =====

define "Final Report":
  {
    indicator_code: 'OUTPATIENT_SURGERY_2DAY_ED_ADMISSION',
    indicator_name: '門診手術後二日以內急診或住院率',
    measurement_period: "Measurement Period",
    clinical_note: '監測門診手術後2日內因相關問題產生急診或住院的情況，評估手術安全性及術後照護品質',
    overall_denominator: "Denominator Count",
    overall_numerator: "Numerator Count",
    overall_rate: "Overall Rate",
    quarterly_rates: "Quarterly Rates",
    emergency_only_count: "Emergency Only Count",
    admission_only_count: "Admission Only Count",
    both_emergency_and_admission_count: "Both Emergency And Admission Count",
    average_days_to_event: "Average Days To Event",
    calculation_frequency: 'Quarterly',
    calculation_unit: '%',
    data_source: 'Outpatient + Emergency + Inpatient Data',
    version: '1.0.0',
    last_updated: @2026-01-07
  }
