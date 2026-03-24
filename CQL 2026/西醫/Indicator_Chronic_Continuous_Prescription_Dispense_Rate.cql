library Indicator_Chronic_Continuous_Prescription_Dispense_Rate version '1.0.0'

/*
慢性病連續處方箋釋出率
Chronic Continuous Prescription Dispense Rate

計算說明:
- 分子：藥局調劑慢性病連續處方箋案件數
- 分母：醫院調劑慢性病連續處方箋案件數+藥局調劑慢性病連續處方箋案件數
- 資料範圍：門診+藥局資料
- 計算頻率：每季

備註:
1. 分子條件：藥局案件分類2的案件數
2. 分母條件：(醫院門診案件分類04、06且慢性病連續處方箋有效期間總處方日份欄位不為0的案件數+案件分類08案件數)+(藥局案件分類2的案件數)
3. 案件分類說明：
   - 案件分類2：藥局調劑
   - 案件分類04：慢性病處方
   - 案件分類06：慢性病連續處方箋
   - 案件分類08：慢性病連續處方箋調劑
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

// 編碼系統定義
codesystem "TWCaseType": 'http://healthcare.gov.tw/case-type'
codesystem "TWFacilityType": 'http://healthcare.gov.tw/facility-type'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 案件分類代碼定義
code "CASE_TYPE_2": '2' from "TWCaseType" display '藥局調劑'
code "CASE_TYPE_04": '04' from "TWCaseType" display '慢性病處方'
code "CASE_TYPE_06": '06' from "TWCaseType" display '慢性病連續處方箋'
code "CASE_TYPE_08": '08' from "TWCaseType" display '慢性病連續處方箋調劑'

// 資料來源定義
context Patient

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

// 所有MedicationDispense（藥局調劑）
define "All Medication Dispenses":
  [MedicationDispense] MD
    where MD.status = 'completed'
      and MD.whenHandedOver during "Measurement Period"

// 所有MedicationRequest（處方）
define "All Medication Requests":
  [MedicationRequest] MR

// ===== 輔助函數 =====

// 判斷Encounter的案件分類
define function "GetCaseType"(encounter Encounter):
  First(
    encounter.extension Ext
      where Ext.url = 'http://healthcare.gov.tw/fhir/StructureDefinition/case-type'
      return (Ext.value as CodeableConcept).coding C
        where C.system = 'http://healthcare.gov.tw/case-type'
        return C.code
  )

// 判斷MedicationDispense的案件分類
define function "GetDispenseCaseType"(dispense MedicationDispense):
  First(
    dispense.extension Ext
      where Ext.url = 'http://healthcare.gov.tw/fhir/StructureDefinition/case-type'
      return (Ext.value as CodeableConcept).coding C
        where C.system = 'http://healthcare.gov.tw/case-type'
        return C.code
  )

// 判斷是否為藥局
define function "IsPharmacy"(location Location):
  exists(
    location.type LType
      where exists(
        LType.coding C
          where C.system = 'http://healthcare.gov.tw/facility-type'
            and C.code = 'PHARMACY'
      )
  )

// 判斷是否為醫院門診
define function "IsHospitalOutpatient"(encounter Encounter):
  exists(
    encounter.serviceProvider.reference
  ) and not "IsPharmacy"(encounter.location[0].location as Location)

// 取得慢性病連續處方箋有效期間總處方日份
define function "GetPrescriptionValidDays"(medicationRequest MedicationRequest):
  if medicationRequest.dispenseRequest.validityPeriod is not null
  then days between start of medicationRequest.dispenseRequest.validityPeriod 
                  and end of medicationRequest.dispenseRequest.validityPeriod
  else 0

// 取得Encounter日期
define function "GetEncounterDate"(encounter Encounter):
  start of encounter.period

// 取得MedicationDispense日期
define function "GetDispenseDate"(dispense MedicationDispense):
  dispense.whenHandedOver

// ===== 分母：醫院調劑+藥局調劑 =====

// 步驟1：醫院門診案件分類04、06且慢性病連續處方箋有效期間總處方日份不為0
define "Hospital Outpatient Chronic Prescriptions":
  "All Outpatient Encounters" E
    let caseType: "GetCaseType"(E)
    where (caseType = '04' or caseType = '06')
      and "IsHospitalOutpatient"(E)
      and exists(
        "All Medication Requests" MR
          where MR.encounter.reference = 'Encounter/' + E.id
            and MR.status = 'active'
            and "GetPrescriptionValidDays"(MR) > 0
      )

// 步驟2：案件分類08案件（醫院慢性病連續處方箋調劑）
define "Hospital Chronic Continuous Dispense":
  "All Outpatient Encounters" E
    let caseType: "GetCaseType"(E)
    where caseType = '08'
      and "IsHospitalOutpatient"(E)

// 步驟3：醫院調劑慢性病連續處方箋總數
define "Hospital Dispense Cases":
  "Hospital Outpatient Chronic Prescriptions" 
  union "Hospital Chronic Continuous Dispense"

define "Hospital Dispense Count":
  Count("Hospital Dispense Cases")

// 步驟4：藥局案件分類2（藥局調劑）
define "Pharmacy Dispense Cases":
  "All Medication Dispenses" MD
    let caseType: "GetDispenseCaseType"(MD)
    where caseType = '2'

define "Pharmacy Dispense Count":
  Count("Pharmacy Dispense Cases")

// 分母：醫院調劑+藥局調劑
define "Denominator":
  "Hospital Dispense Cases"
  union
  ("Pharmacy Dispense Cases" MD
    return {
      id: MD.id,
      date: "GetDispenseDate"(MD)
    })

define "Denominator Count":
  Count("Denominator")

// ===== 分子：藥局調劑慢性病連續處方箋案件數 =====

define "Numerator":
  "Pharmacy Dispense Cases"

define "Numerator Count":
  Count("Numerator")

// ===== 指標計算 =====

// 整體釋出率
define "Overall Dispense Rate":
  if "Denominator Count" > 0
  then Round(("Numerator Count" / "Denominator Count") * 100, 2)
  else null

// 季度釋出率
define "Quarterly Dispense Rates":
  "Quarterly Periods" Period
    let 
      quarterlyHospitalCases:
        "Hospital Dispense Cases" H
          where "GetEncounterDate"(H) during Period,
      quarterlyPharmacyCases:
        "Pharmacy Dispense Cases" P
          where "GetDispenseDate"(P) during Period,
      hospitalCount: Count(quarterlyHospitalCases),
      pharmacyCount: Count(quarterlyPharmacyCases),
      denominatorCount: hospitalCount + pharmacyCount,
      numeratorCount: pharmacyCount,
      rate: if denominatorCount > 0 
            then Round((numeratorCount / denominatorCount) * 100, 2)
            else null
    return {
      period: Period,
      period_start: start of Period,
      period_end: end of Period,
      hospital_dispense_count: hospitalCount,
      pharmacy_dispense_count: pharmacyCount,
      denominator_count: denominatorCount,
      numerator_count: numeratorCount,
      dispense_rate: rate
    }

// ===== 詳細統計資訊 =====

// 醫院調劑與藥局調劑比例
define "Hospital vs Pharmacy Distribution":
  {
    hospital_count: "Hospital Dispense Count",
    pharmacy_count: "Pharmacy Dispense Count",
    total_count: "Denominator Count",
    hospital_percentage: 
      if "Denominator Count" > 0 
      then Round(("Hospital Dispense Count" / "Denominator Count") * 100, 2)
      else null,
    pharmacy_percentage:
      if "Denominator Count" > 0 
      then Round(("Pharmacy Dispense Count" / "Denominator Count") * 100, 2)
      else null
  }

// 案件分類分布統計
define "Case Type Distribution":
  {
    case_04_count: Count(
      "All Outpatient Encounters" E
        where "GetCaseType"(E) = '04'
          and "GetEncounterDate"(E) during "Measurement Period"
    ),
    case_06_count: Count(
      "All Outpatient Encounters" E
        where "GetCaseType"(E) = '06'
          and "GetEncounterDate"(E) during "Measurement Period"
    ),
    case_08_count: Count(
      "All Outpatient Encounters" E
        where "GetCaseType"(E) = '08'
          and "GetEncounterDate"(E) during "Measurement Period"
    ),
    case_2_count: Count(
      "All Medication Dispenses" MD
        where "GetDispenseCaseType"(MD) = '2'
          and "GetDispenseDate"(MD) during "Measurement Period"
    )
  }

// 月度趨勢分析
define "Monthly Trend":
  flatten(
    "Quarterly Periods" Quarter
      return 
        {1, 2, 3} Month
          let 
            monthStart: start of Quarter + ((Month - 1) * 30 days),
            monthEnd: monthStart + 30 days,
            monthPeriod: Interval[monthStart, monthEnd],
            hospitalCases:
              "Hospital Dispense Cases" H
                where "GetEncounterDate"(H) in monthPeriod,
            pharmacyCases:
              "Pharmacy Dispense Cases" P
                where "GetDispenseDate"(P) in monthPeriod,
            hospitalCount: Count(hospitalCases),
            pharmacyCount: Count(pharmacyCases),
            totalCount: hospitalCount + pharmacyCount,
            rate: if totalCount > 0
                  then Round((pharmacyCount / totalCount) * 100, 2)
                  else null
          return {
            month_start: monthStart,
            month_end: monthEnd,
            hospital_count: hospitalCount,
            pharmacy_count: pharmacyCount,
            total_count: totalCount,
            dispense_rate: rate
          }
  )

// ===== 最終輸出報告 =====

define "Final Report":
  {
    indicator_code: 'CHRONIC_CONTINUOUS_RX_DISPENSE_RATE',
    indicator_name: '慢性病連續處方箋釋出率',
    measurement_period: "Measurement Period",
    clinical_note: '監測慢性病連續處方箋由藥局調劑的比例，評估醫藥分業政策執行情況及藥局參與度',
    overall_denominator: "Denominator Count",
    overall_numerator: "Numerator Count",
    overall_rate: "Overall Dispense Rate",
    quarterly_rates: "Quarterly Dispense Rates",
    hospital_vs_pharmacy: "Hospital vs Pharmacy Distribution",
    case_type_distribution: "Case Type Distribution",
    monthly_trend: "Monthly Trend",
    calculation_frequency: 'Quarterly',
    calculation_unit: '%',
    data_source: 'Outpatient + Pharmacy Data',
    case_type_note: '案件分類04=慢性病處方, 06=慢性病連續處方箋, 08=慢性病連續處方箋調劑, 2=藥局調劑',
    version: '1.0.0',
    last_updated: @2026-01-07
  }
