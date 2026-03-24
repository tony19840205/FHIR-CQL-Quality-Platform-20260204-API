library Indicator_Delivery_14Day_Unplanned_Readmission_Rate version '1.0.0'

/*
同醫院生產案件出院後十四日以內非計畫性再住院率
Same Hospital Delivery 14-Day Unplanned Readmission Rate

計算說明:
- 分子：分母案件出院後14日內非計畫性再住院案件數
- 分母：同一家醫院當季生產住院案件數
- 資料範圍：醫院住院資料
- 計算頻率：每季

備註:
1. 生產出院案件：申報生產醫令之案件依ID、出生日期、住院日期歸戶
2. 分子排除新生兒未滿卡（部分負擔代碼903）
3. 生產醫令（將依支付標準修訂調整）：81004C、81005C、81024C、81025C、81026C、81028C、81029C、97006K、97007A、97008B、97009C、
   81005B、81017C、81018C、81019C、97001K、97002A、97003B、97004C、97005D、97931K、97932A、97933B、97934C、81034C
4. 範例：○○醫院在這一季中有100個生產住院個案，其中5個人於14日內再回到○○醫院住院，則○○醫院該季的「同院所生產案件14日內非計畫性再住院
   率」計算方式：(5人 / 100人)x100%=5%
5. 計算頻率：每季
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

// 出院後追蹤期間（14日）
parameter "Post Discharge Follow Up Days" Integer default 14

// 編碼系統定義
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "TWCopaymentCode": 'http://healthcare.gov.tw/copayment-code'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 生產醫令代碼定義
code "81004C": '81004C' from "TWProcedure" display '自然產-正常分娩'
code "81005C": '81005C' from "TWProcedure" display '自然產-產鉗助產'
code "81024C": '81024C' from "TWProcedure" display '自然產-真空吸引助產'
code "81025C": '81025C' from "TWProcedure" display '自然產-困難分娩'
code "81026C": '81026C' from "TWProcedure" display '自然產-臀位分娩'
code "81028C": '81028C' from "TWProcedure" display '剖腹產-初次'
code "81029C": '81029C' from "TWProcedure" display '剖腹產-重複'
code "97006K": '97006K' from "TWProcedure" display '生產-複雜'
code "97007A": '97007A' from "TWProcedure" display '生產-高危險妊娠'
code "97008B": '97008B' from "TWProcedure" display '生產-多胞胎'
code "97009C": '97009C' from "TWProcedure" display '生產-其他'
code "81005B": '81005B' from "TWProcedure" display '自然產-產後出血處理'
code "81017C": '81017C' from "TWProcedure" display '自然產-會陰裂傷修補'
code "81018C": '81018C' from "TWProcedure" display '自然產-會陰切開術'
code "81019C": '81019C' from "TWProcedure" display '自然產-產道裂傷修補'
code "97001K": '97001K' from "TWProcedure" display '生產-一般'
code "97002A": '97002A' from "TWProcedure" display '生產-早產'
code "97003B": '97003B' from "TWProcedure" display '生產-過期妊娠'
code "97004C": '97004C' from "TWProcedure" display '生產-子癇前症'
code "97005D": '97005D' from "TWProcedure" display '生產-胎盤早期剝離'
code "97931K": '97931K' from "TWProcedure" display '生產-妊娠糖尿病'
code "97932A": '97932A' from "TWProcedure" display '生產-妊娠高血壓'
code "97933B": '97933B' from "TWProcedure" display '生產-前置胎盤'
code "97934C": '97934C' from "TWProcedure" display '生產-胎位不正'
code "81034C": '81034C' from "TWProcedure" display '剖腹產-緊急'

// 部分負擔代碼-新生兒未滿卡（需排除）
code "903": '903' from "TWCopaymentCode" display '新生兒未滿卡'

// 資料來源定義
context Patient

// ===== 生產醫令代碼值集 =====

define "Delivery Procedure Codes":
  {
    '81004C', '81005C', '81024C', '81025C', '81026C', '81028C', '81029C', '97006K',
    '97007A', '97008B', '97009C', '81005B', '81017C', '81018C', '81019C', '97001K',
    '97002A', '97003B', '97004C', '97005D', '97931K', '97932A', '97933B', '97934C',
    '81034C'
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

// 所有Procedure
define "All Procedures":
  [Procedure] P

// ===== 輔助函數 =====

// 判斷Procedure是否為生產醫令
define function "IsDeliveryProcedure"(procedure Procedure):
  exists(
    procedure.code.coding C
      where C.system = 'http://healthcare.gov.tw/procedure'
        and C.code in "Delivery Procedure Codes"
  )

// 判斷Encounter是否為新生兒未滿卡（部分負擔代碼903）
define function "IsNewbornNotRegistered"(encounter Encounter):
  exists(
    encounter.extension Ext
      where Ext.url = 'http://healthcare.gov.tw/fhir/StructureDefinition/copayment-code'
        and (Ext.value as CodeableConcept).coding C
          where C.system = 'http://healthcare.gov.tw/copayment-code'
            and C.code = '903'
  )

// 取得Encounter的機構ID
define function "GetOrganizationId"(encounter Encounter):
  Last(Split(encounter.serviceProvider.reference, '/'))

// 取得出院日期
define function "GetDischargeDate"(encounter Encounter):
  end of encounter.period

// 取得住院日期
define function "GetAdmissionDate"(encounter Encounter):
  start of encounter.period

// 計算年齡
define function "CalculateAgeInYears"(birthDate Date):
  years between birthDate and Today()

// ===== 分母：同一家醫院當季生產住院案件數 =====

// 步驟1：找出所有有生產醫令的住院案件
define "Inpatient Encounters With Delivery":
  "All Inpatient Encounters" E
    where exists(
      "All Procedures" P
        where P.encounter.reference = 'Encounter/' + E.id
          and P.status = 'completed'
          and "IsDeliveryProcedure"(P)
    )

// 步驟2：按【院所、ID、住院日】歸戶，取最晚出院日的案件
define "Grouped Delivery Encounters":
  ("Inpatient Encounters With Delivery") E
    let 
      organizationId: "GetOrganizationId"(E),
      patientId: Patient.id,
      birthDate: Patient.birthDate,
      admissionDate: "GetAdmissionDate"(E),
      dischargeDate: "GetDischargeDate"(E)
    return {
      encounter: E,
      organizationId: organizationId,
      patientId: patientId,
      birthDate: birthDate,
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      groupKey: organizationId + '|' + patientId + '|' + ToString(birthDate) + '|' + ToString(admissionDate)
    }

// 取得每組中出院日最晚的案件
define "Representative Delivery Encounters":
  flatten(
    ("Grouped Delivery Encounters") G
      return distinct G.groupKey
  ) GroupKey
    let 
      encountersInGroup: "Grouped Delivery Encounters" G where G.groupKey = GroupKey,
      latestDischarge: Maximum(encountersInGroup E return E.dischargeDate)
    return 
      singleton from (
        encountersInGroup E
          where E.dischargeDate = latestDischarge
      )

// 分母：同一家醫院當季生產住院案件數
define "Denominator":
  "Representative Delivery Encounters"

define "Denominator Count":
  Count("Denominator")

// ===== 分子：出院後14日內非計畫性再住院案件數 =====

// 步驟1：對每個生產出院案件，找出14日內的再住院
define "Readmission Events":
  "Denominator" D
    let 
      dischargeDate: D.dischargeDate,
      organizationId: D.organizationId,
      patientId: D.patientId,
      followUpPeriod: Interval[dischargeDate + 1 day, dischargeDate + "Post Discharge Follow Up Days" days],
      
      // 找出同院所、14日內的再住院案件
      readmissions:
        "All Inpatient Encounters" ReadmitEnc
          where "GetOrganizationId"(ReadmitEnc) = organizationId
            and "GetAdmissionDate"(ReadmitEnc) in followUpPeriod
            and not "IsNewbornNotRegistered"(ReadmitEnc)  // 排除新生兒未滿卡（903）
    return {
      deliveryEncounter: D.encounter,
      dischargeDate: dischargeDate,
      organizationId: organizationId,
      patientId: patientId,
      readmissions: readmissions,
      hasReadmission: exists(readmissions)
    }

// 分子：有14日內再住院的生產案件
define "Numerator":
  "Readmission Events" R
    where R.hasReadmission = true

define "Numerator Count":
  Count("Numerator")

// ===== 指標計算 =====

// 整體再住院率
define "Overall Readmission Rate":
  if "Denominator Count" > 0
  then Round(("Numerator Count" / "Denominator Count") * 100, 2)
  else null

// 季度再住院率
define "Quarterly Readmission Rates":
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
      readmission_rate: rate
    }

// ===== 按醫院統計 =====

// 各醫院季度統計
define "Hospital Quarterly Statistics":
  flatten(
    "Quarterly Periods" Period
      return 
        flatten(
          ("Denominator") D
            return distinct D.organizationId
        ) OrgId
          let 
            hospitalDenominator:
              "Denominator" D
                where D.organizationId = OrgId
                  and D.dischargeDate during Period,
            hospitalNumerator:
              "Numerator" N
                where N.organizationId = OrgId
                  and N.dischargeDate during Period,
            denominatorCount: Count(hospitalDenominator),
            numeratorCount: Count(hospitalNumerator),
            rate: if denominatorCount > 0 
                  then Round((numeratorCount / denominatorCount) * 100, 2)
                  else null
          return {
            organization_id: OrgId,
            period: Period,
            period_start: start of Period,
            period_end: end of Period,
            denominator_count: denominatorCount,
            numerator_count: numeratorCount,
            readmission_rate: rate
          }
  )

// ===== 詳細統計資訊 =====

// 再住院時間分布（距離出院天數）
define "Readmission Days Distribution":
  "Numerator" N
    let 
      dischargeDate: N.dischargeDate,
      firstReadmissionDate: Minimum(N.readmissions R return "GetAdmissionDate"(R)),
      daysToReadmission: days between dischargeDate and firstReadmissionDate
    return {
      patient_id: N.patientId,
      organization_id: N.organizationId,
      discharge_date: dischargeDate,
      first_readmission_date: firstReadmissionDate,
      days_to_readmission: daysToReadmission
    }

// 平均再住院天數
define "Average Days To Readmission":
  if Count("Readmission Days Distribution") > 0
  then Round(
    Avg("Readmission Days Distribution" D return D.days_to_readmission),
    2
  )
  else null

// 未再住院案件清單
define "No Readmission Cases":
  "Readmission Events" R
    where R.hasReadmission = false
    return {
      patient_id: R.patientId,
      organization_id: R.organizationId,
      discharge_date: R.dischargeDate
    }

// 再住院次數分布
define "Readmission Count Distribution":
  "Numerator" N
    let 
      readmissionCount: Count(N.readmissions)
    return {
      patient_id: N.patientId,
      organization_id: N.organizationId,
      discharge_date: N.dischargeDate,
      readmission_count: readmissionCount
    }

// ===== 最終輸出報告 =====

define "Final Report":
  {
    indicator_code: 'DELIVERY_14DAY_READMISSION',
    indicator_name: '同醫院生產案件出院後十四日以內非計畫性再住院率',
    measurement_period: "Measurement Period",
    clinical_note: '監測生產案件出院後14日內因併發症或相關問題再次住院的情況，評估生產照護品質及產後照護完善度',
    overall_denominator: "Denominator Count",
    overall_numerator: "Numerator Count",
    overall_rate: "Overall Readmission Rate",
    quarterly_rates: "Quarterly Readmission Rates",
    hospital_quarterly_statistics: "Hospital Quarterly Statistics",
    average_days_to_readmission: "Average Days To Readmission",
    no_readmission_count: Count("No Readmission Cases"),
    calculation_frequency: 'Quarterly',
    calculation_unit: '%',
    data_source: 'Hospital Inpatient Data',
    exclusion_note: '排除新生兒未滿卡案件（部分負擔代碼903）',
    version: '1.0.0',
    last_updated: @2026-01-07
  }
