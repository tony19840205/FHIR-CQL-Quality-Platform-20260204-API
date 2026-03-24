library Indicator_Acute_Psychiatric_30Day_Outpatient_Follow_Up_Rate version '1.0.0'

/*
精神病人出院後三十日以內同醫院門診精神科追蹤率-急性
Acute Psychiatric Patients 30-Day Outpatient Psychiatry Follow-Up Rate

計算說明:
- 分子：30日內至同院所門診精神科追蹤之案件（排除案件分類02西醫急診）
- 分母：精神科急性精神病人之出院案件數（排除轉歸代碼為2(繼續住院)、4(死亡)、6(轉院)、9(自殺)、A(病危自動出院)）
- 資料範圍：醫院住院+門診資料
- 計算頻率：每季

備註:
1. 精神科已出院案件：急性精神病人出院日期在當月且就醫科別為13的案件，且用院所、ID、住院日期戶、取出院日最晚那一筆案件
2. 急性精神病人：醫令代碼為03001K、03002A、03003B、03004B、03026K、03027A、03028B、03029B、03005K、03006A、03007B、03008B、
   03030K、03031A、03032B、03033B、03014A、03015B、03025B、03037A、03038B、03039B、03055K、03056A、03057B、03061K、03062A、03063B
3. 就醫科別13：精神科
4. 門診追蹤：案件分類非02（排除急診），於同院所門診科別為精神科
5. 轉歸代碼排除：2、4、6、9、A
6. 計算範圍：2026年(115年)資料

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

// 出院後追蹤期間（30日）
parameter "Post Discharge Follow Up Days" Integer default 30

// 編碼系統定義
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "TWDepartment": 'http://healthcare.gov.tw/department'
codesystem "TWDischargeDisposition": 'http://healthcare.gov.tw/discharge-disposition'
codesystem "TWCaseType": 'http://healthcare.gov.tw/case-type'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 急性精神病醫令代碼定義
code "03001K": '03001K' from "TWProcedure" display '急性精神病房-一般病房'
code "03002A": '03002A' from "TWProcedure" display '急性精神病房-日間病房'
code "03003B": '03003B' from "TWProcedure" display '急性精神病房-社區復健'
code "03004B": '03004B' from "TWProcedure" display '急性精神病房-綜合病房'
code "03026K": '03026K' from "TWProcedure" display '急性精神病房-加護病房'
code "03027A": '03027A' from "TWProcedure" display '急性精神病房-特殊病房'
code "03028B": '03028B' from "TWProcedure" display '急性精神病房-隔離病房'
code "03029B": '03029B' from "TWProcedure" display '急性精神病房-安寧病房'
code "03005K": '03005K' from "TWProcedure" display '急性精神病房-急性期病房'
code "03006A": '03006A' from "TWProcedure" display '急性精神病房-急性後期病房'
code "03007B": '03007B' from "TWProcedure" display '急性精神病房-康復期病房'
code "03008B": '03008B' from "TWProcedure" display '急性精神病房-慢性病房'
code "03030K": '03030K' from "TWProcedure" display '急性精神病房-日間留院'
code "03031A": '03031A' from "TWProcedure" display '急性精神病房-夜間留院'
code "03032B": '03032B' from "TWProcedure" display '急性精神病房-全日住院'
code "03033B": '03033B' from "TWProcedure" display '急性精神病房-部分住院'
code "03014A": '03014A' from "TWProcedure" display '急性精神病房-精神科加護病房'
code "03015B": '03015B' from "TWProcedure" display '急性精神病房-兒童青少年精神科病房'
code "03025B": '03025B' from "TWProcedure" display '急性精神病房-老年精神科病房'
code "03037A": '03037A' from "TWProcedure" display '急性精神病房-酒藥癮治療病房'
code "03038B": '03038B' from "TWProcedure" display '急性精神病房-社區精神復健'
code "03039B": '03039B' from "TWProcedure" display '急性精神病房-居家治療'
code "03055K": '03055K' from "TWProcedure" display '急性精神病房-急性精神科'
code "03056A": '03056A' from "TWProcedure" display '急性精神病房-亞急性精神科'
code "03057B": '03057B' from "TWProcedure" display '急性精神病房-慢性精神科'
code "03061K": '03061K' from "TWProcedure" display '急性精神病房-急性精神病房A'
code "03062A": '03062A' from "TWProcedure" display '急性精神病房-急性精神病房B'
code "03063B": '03063B' from "TWProcedure" display '急性精神病房-急性精神病房C'

// 精神科科別代碼
code "DEPT_13": '13' from "TWDepartment" display '精神科'

// 排除轉歸代碼
code "DISP_2": '2' from "TWDischargeDisposition" display '繼續住院'
code "DISP_4": '4' from "TWDischargeDisposition" display '死亡'
code "DISP_6": '6' from "TWDischargeDisposition" display '轉院'
code "DISP_9": '9' from "TWDischargeDisposition" display '自殺'
code "DISP_A": 'A' from "TWDischargeDisposition" display '病危自動出院'

// 案件分類-急診（需排除）
code "CASE_TYPE_02": '02' from "TWCaseType" display '西醫急診'

// 資料來源定義
context Patient

// ===== 急性精神病醫令代碼值集 =====

define "Acute Psychiatric Procedure Codes":
  {
    '03001K', '03002A', '03003B', '03004B', '03026K', '03027A', '03028B', '03029B',
    '03005K', '03006A', '03007B', '03008B', '03030K', '03031A', '03032B', '03033B',
    '03014A', '03015B', '03025B', '03037A', '03038B', '03039B', '03055K', '03056A',
    '03057B', '03061K', '03062A', '03063B'
  }

// ===== 排除轉歸代碼值集 =====

define "Excluded Discharge Dispositions":
  {
    '2',  // 繼續住院
    '4',  // 死亡
    '6',  // 轉院
    '9',  // 自殺
    'A'   // 病危自動出院
  }

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

// 所有Procedure
define "All Procedures":
  [Procedure] P

// ===== 輔助函數 =====

// 判斷Procedure是否為急性精神病醫令
define function "IsAcutePsychiatricProcedure"(procedure Procedure):
  exists(
    procedure.code.coding C
      where C.system = 'http://healthcare.gov.tw/procedure'
        and C.code in "Acute Psychiatric Procedure Codes"
  )

// 判斷Encounter是否為精神科（科別13）
define function "IsPsychiatryDepartment"(encounter Encounter):
  exists(
    encounter.extension Ext
      where Ext.url = 'http://healthcare.gov.tw/fhir/StructureDefinition/department-code'
        and (Ext.value as CodeableConcept).coding C
          where C.system = 'http://healthcare.gov.tw/department'
            and C.code = '13'
  )

// 判斷Encounter的轉歸代碼是否為排除項目
define function "HasExcludedDischargeDisposition"(encounter Encounter):
  exists(
    encounter.hospitalization.dischargeDisposition.coding C
      where C.system = 'http://healthcare.gov.tw/discharge-disposition'
        and C.code in "Excluded Discharge Dispositions"
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

// 取得Encounter的機構ID
define function "GetOrganizationId"(encounter Encounter):
  Last(Split(encounter.serviceProvider.reference, '/'))

// 取得出院日期
define function "GetDischargeDate"(encounter Encounter):
  end of encounter.period

// 計算年齡
define function "CalculateAgeInYears"(birthDate Date):
  years between birthDate and Today()

// ===== 分母：精神科急性精神病人之出院案件 =====

// 步驟1：找出所有有急性精神病醫令的住院案件
define "Inpatient Encounters With Acute Psychiatric Procedure":
  "All Inpatient Encounters" E
    where exists(
      "All Procedures" P
        where P.encounter.reference = 'Encounter/' + E.id
          and P.status = 'completed'
          and "IsAcutePsychiatricProcedure"(P)
    )

// 步驟2：限制為精神科（科別13）
define "Psychiatric Department Encounters":
  "Inpatient Encounters With Acute Psychiatric Procedure" E
    where "IsPsychiatryDepartment"(E)

// 步驟3：排除特定轉歸代碼
define "Valid Discharge Encounters":
  "Psychiatric Department Encounters" E
    where not "HasExcludedDischargeDisposition"(E)
      and E.hospitalization.dischargeDisposition is not null

// 步驟4：按【院所、ID、住院日】歸戶，取最晚出院日的案件
define "Grouped Encounters":
  ("Valid Discharge Encounters") E
    let 
      organizationId: "GetOrganizationId"(E),
      patientId: Patient.id,
      admissionDate: start of E.period,
      dischargeDate: "GetDischargeDate"(E)
    return {
      encounter: E,
      organizationId: organizationId,
      patientId: patientId,
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      groupKey: organizationId + '|' + patientId + '|' + ToString(admissionDate)
    }

// 取得每組中出院日最晚的案件
define "Representative Discharge Encounters":
  flatten(
    ("Grouped Encounters") G
      return distinct G.groupKey
  ) GroupKey
    let 
      encountersInGroup: "Grouped Encounters" G where G.groupKey = GroupKey,
      latestDischarge: Maximum(encountersInGroup E return E.dischargeDate)
    return 
      singleton from (
        encountersInGroup E
          where E.dischargeDate = latestDischarge
      )

// 分母：精神科急性精神病人之出院案件數
define "Denominator":
  "Representative Discharge Encounters"

define "Denominator Count":
  Count("Denominator")

// ===== 分子：30日內至同院所門診精神科追蹤之案件 =====

// 步驟1：對每個分母案件，找出30日內的門診追蹤
define "Follow Up Encounters":
  "Denominator" D
    let 
      dischargeDate: D.dischargeDate,
      organizationId: D.organizationId,
      followUpPeriod: Interval[dischargeDate + 1 day, dischargeDate + "Post Discharge Follow Up Days" days],
      // 找出同院所、30日內、精神科、非急診的門診案件
      followUpVisits: 
        "All Outpatient Encounters" OutEnc
          where "GetOrganizationId"(OutEnc) = organizationId
            and start of OutEnc.period in followUpPeriod
            and "IsPsychiatryDepartment"(OutEnc)
            and not "IsEmergencyCase"(OutEnc)
    return {
      dischargeEncounter: D.encounter,
      dischargeDate: dischargeDate,
      organizationId: organizationId,
      patientId: D.patientId,
      followUpVisits: followUpVisits,
      hasFollowUp: exists(followUpVisits)
    }

// 分子：有30日內門診精神科追蹤的案件
define "Numerator":
  "Follow Up Encounters" F
    where F.hasFollowUp = true

define "Numerator Count":
  Count("Numerator")

// ===== 指標計算 =====

// 整體追蹤率
define "Overall Follow Up Rate":
  if "Denominator Count" > 0
  then Round(("Numerator Count" / "Denominator Count") * 100, 2)
  else null

// 季度追蹤率
define "Quarterly Follow Up Rates":
  "Quarterly Periods" Period
    let 
      quarterlyDenominator: 
        "Denominator" D
          where D.dischargeDate during Period,
      quarterlyNumerator:
        "Numerator" N
          where N.dischargeDate during Period,
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
      follow_up_rate: rate
    }

// ===== 詳細統計資訊 =====

// 追蹤時間分布（追蹤距離出院天數）
define "Follow Up Days Distribution":
  "Numerator" N
    let 
      dischargeDate: N.dischargeDate,
      firstFollowUpDate: Minimum(N.followUpVisits V return start of V.period),
      daysToFollowUp: days between dischargeDate and firstFollowUpDate
    return {
      patient_id: N.patientId,
      discharge_date: dischargeDate,
      first_follow_up_date: firstFollowUpDate,
      days_to_follow_up: daysToFollowUp
    }

// 平均追蹤天數
define "Average Days To Follow Up":
  if Count("Follow Up Days Distribution") > 0
  then Round(
    Avg("Follow Up Days Distribution" D return D.days_to_follow_up),
    2
  )
  else null

// 未追蹤案件清單
define "No Follow Up Cases":
  "Follow Up Encounters" F
    where F.hasFollowUp = false
    return {
      patient_id: F.patientId,
      discharge_date: F.dischargeDate,
      organization_id: F.organizationId
    }

// ===== 最終輸出報告 =====

define "Final Report":
  {
    indicator_code: 'ACUTE_PSYCH_30DAY_FOLLOW_UP',
    indicator_name: '精神病人出院後三十日以內同醫院門診精神科追蹤率-急性',
    measurement_period: "Measurement Period",
    clinical_note: '監測急性精神病患出院後是否獲得適當的門診精神科追蹤照護，確保治療連續性及預防再住院',
    overall_denominator: "Denominator Count",
    overall_numerator: "Numerator Count",
    overall_rate: "Overall Follow Up Rate",
    quarterly_rates: "Quarterly Follow Up Rates",
    average_days_to_follow_up: "Average Days To Follow Up",
    no_follow_up_count: Count("No Follow Up Cases"),
    calculation_frequency: 'Quarterly',
    calculation_unit: '%',
    data_source: 'Hospital Inpatient and Outpatient Data',
    version: '1.0.0',
    last_updated: @2026-01-07
  }
