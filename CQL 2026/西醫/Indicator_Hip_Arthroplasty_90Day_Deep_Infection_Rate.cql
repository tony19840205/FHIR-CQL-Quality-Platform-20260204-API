library Indicator_Hip_Arthroplasty_90Day_Deep_Infection_Rate version '1.0.0'

/*
人工髖關節置換手術後九十日以內置換物深部感染率
Hip Arthroplasty 90-Day Deep Prosthetic Infection Rate

計算說明:
- 分子：分母案件中，人工髖關節置換後3個月(90天)內發生置換物感染的案件數
- 分母：統計期間內醫院人工髖關節置換術執行案件數
- 資料範圍：醫院住院資料
- 計算頻率：季、年

備註:
1. 人工髖關節置換執行案件數：醫令代碼為64162B且醫令類別為2的住院案件
2. 置換物感染：西醫醫院的住診跨院案件中，以手術醫令執行起日往後推算3個月(90天)，有執行64052B、64004C、64198B任一醫令之案件
3. 跨院勾稽
4. 臨床意義：監測人工髖關節置換手術後置換物深部感染率，評估手術品質和感染控制措施，深部感染通常需要再次手術處理
5. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-06)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 季度期間定義
parameter "Quarterly Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0],
    Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0],
    Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0],
    Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
  }

// 監測期間（90天）
parameter "Monitoring Period Days" Integer default 90

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "LOINC": 'http://loinc.org'

// 人工髖關節置換手術code (NHI 64162B)
code "64162B": '64162B' from "TWProcedure" display '人工髖關節置換術'

// 置換物深部感染相關手術codes (64052B, 64004C, 64198B)
code "64052B": '64052B' from "TWProcedure" display '人工髖關節感染清創術'
code "64004C": '64004C' from "TWProcedure" display '人工髖關節置換物移除術'
code "64198B": '64198B' from "TWProcedure" display '人工關節置換物移除術'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'

// Encounter類型編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

// 所有Procedure
define "All Procedures":
  [Procedure] P

// ===== 人工髖關節置換手術判斷 =====

// 判斷Procedure是否為人工髖關節置換手術 (64162B)
define function "IsHipArthroplastyProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and C.code = '64162B'
    )

// 取得Procedure執行日期（起日）
define function "GetProcedureDate"(procedure Procedure):
  Coalesce(
    start of (procedure.performed as Period),
    procedure.performed as dateTime
  )

// 取得Procedure執行的Encounter
define function "GetProcedureEncounter"(procedure Procedure):
  singleton from (
    "All Inpatient Encounters" E
      where E.id = Last(Split(procedure.encounter.reference, '/'))
  )

// 取得Procedure執行的醫療機構
define function "GetProcedureOrganization"(procedure Procedure):
  let encounter: "GetProcedureEncounter"(procedure)
  return
    if encounter is not null
      then encounter.serviceProvider.reference
      else null

// 取得病人所有人工髖關節置換手術
define "Hip Arthroplasty Procedures":
  "All Procedures" P
    where "IsHipArthroplastyProcedure"(P)

// ===== 置換物深部感染判斷 =====

// 判斷Procedure是否為置換物深部感染相關手術 (64052B, 64004C, 64198B)
define function "IsDeepInfectionProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '64052B'  // 人工髖關節感染清創術
            or C.code = '64004C'  // 人工髖關節置換物移除術
            or C.code = '64198B'  // 人工關節置換物移除術
          )
    )

// 計算90天監測期間
define function "Get90DayMonitoringPeriod"(surgeryDate DateTime):
  Interval[surgeryDate, surgeryDate + "Monitoring Period Days" days]

// 判斷90天內是否有置換物深部感染（跨院勾稽）
define function "HasDeepInfectionWithin90Days"(surgeryDate DateTime):
  let monitoringPeriod: "Get90DayMonitoringPeriod"(surgeryDate)
  return
    exists(
      "All Procedures" P
        where "IsDeepInfectionProcedure"(P)
          and "GetProcedureDate"(P) during monitoringPeriod
          and exists(
            "GetProcedureEncounter"(P) E
              where E.type in "Inpatient Encounter Codes"
          )
    )

// 取得90天內的深部感染手術
define function "GetDeepInfectionProceduresWithin90Days"(surgeryDate DateTime):
  let monitoringPeriod: "Get90DayMonitoringPeriod"(surgeryDate)
  return
    "All Procedures" P
      where "IsDeepInfectionProcedure"(P)
        and "GetProcedureDate"(P) during monitoringPeriod
        and exists(
          "GetProcedureEncounter"(P) E
            where E.type in "Inpatient Encounter Codes"
        )

// ===== 分母定義（依期間）=====

// 取得期間內的人工髖關節置換手術（住院案件）
define function "GetHipArthroplastyInPeriod"(period Interval<DateTime>):
  "Hip Arthroplasty Procedures" P
    where "GetProcedureDate"(P) during period
      and exists(
        "GetProcedureEncounter"(P) E
          where E.type in "Inpatient Encounter Codes"
      )

// 判斷是否有人工髖關節置換手術（針對特定期間）
define function "HasHipArthroplastyInPeriod"(period Interval<DateTime>):
  exists("GetHipArthroplastyInPeriod"(period))

// 分母（全年）
define "Denominator":
  if "HasHipArthroplastyInPeriod"("Measurement Period") then 1 else 0

// 分母（季度）
define "Denominator Quarterly":
  "Quarterly Periods" P
    return if "HasHipArthroplastyInPeriod"(P) then 1 else 0

// ===== 分子定義（依期間）=====

// 判斷是否有置換物深部感染（針對特定期間）
define function "HasDeepInfectionInPeriod"(period Interval<DateTime>):
  exists(
    "GetHipArthroplastyInPeriod"(period) P
      where "HasDeepInfectionWithin90Days"("GetProcedureDate"(P))
  )

// 分子（全年）
define "Numerator":
  if "HasDeepInfectionInPeriod"("Measurement Period") then 1 else 0

// 分子（季度）
define "Numerator Quarterly":
  "Quarterly Periods" P
    return if "HasDeepInfectionInPeriod"(P) then 1 else 0

// ===== 指標計算 =====

// 整體指標（全年）
define "Indicator Rate":
  if "Denominator" > 0
    then Round("Numerator" / "Denominator" * 100, 2)
    else null

// 季度指標
define "Indicator Rate Quarterly":
  "Quarterly Periods" P
    let denom: if "HasHipArthroplastyInPeriod"(P) then 1 else 0,
        numer: if "HasDeepInfectionInPeriod"(P) then 1 else 0
    return
      if denom > 0
        then Round(numer / denom * 100, 2)
        else null

// ===== 品質檢核 =====

// 資料完整性檢查（全年）
define "Data Quality Check":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period")
  return Tuple {
    total_inpatient_encounters: Count("All Inpatient Encounters" E where start of E.period during "Measurement Period"),
    total_hip_arthroplasty_procedures: Count(hipSurgeries),
    patients_with_deep_infection: "Numerator",
    patients_without_deep_infection: "Denominator" - "Numerator"
  }

// 手術統計
define "Hip Arthroplasty Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      surgeryDates: hipSurgeries P return "GetProcedureDate"(P)
  return Tuple {
    total_procedures: Count(hipSurgeries),
    first_surgery_date: if exists(surgeryDates) then ToString(First(surgeryDates D sort ascending)) else null,
    last_surgery_date: if exists(surgeryDates) then ToString(Last(surgeryDates D sort ascending)) else null
  }

// 深部感染統計
define "Deep Infection Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      infectionsWithDebridement: hipSurgeries P 
        where "HasDeepInfectionWithin90Days"("GetProcedureDate"(P))
          and exists(
            "GetDeepInfectionProceduresWithin90Days"("GetProcedureDate"(P)) Proc
              where exists(Proc.code.coding C where C.code = '64052B')
          ),
      infectionsWithRemoval: hipSurgeries P
        where "HasDeepInfectionWithin90Days"("GetProcedureDate"(P))
          and exists(
            "GetDeepInfectionProceduresWithin90Days"("GetProcedureDate"(P)) Proc
              where exists(Proc.code.coding C where (C.code = '64004C' or C.code = '64198B'))
          )
  return Tuple {
    total_deep_infections: "Numerator",
    infections_with_debridement_64052B: Count(infectionsWithDebridement),
    infections_with_removal_64004C_64198B: Count(infectionsWithRemoval),
    deep_infection_rate_percent: "Indicator Rate"
  }

// 深部感染手術明細統計
define "Deep Infection Procedure Details":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      allInfectionProcs: flatten(
        hipSurgeries P
          return "GetDeepInfectionProceduresWithin90Days"("GetProcedureDate"(P))
      )
  return Tuple {
    total_infection_procedures: Count(allInfectionProcs),
    procedures_64052B: Count(allInfectionProcs Proc where exists(Proc.code.coding C where C.code = '64052B')),
    procedures_64004C: Count(allInfectionProcs Proc where exists(Proc.code.coding C where C.code = '64004C')),
    procedures_64198B: Count(allInfectionProcs Proc where exists(Proc.code.coding C where C.code = '64198B'))
  }

// 跨院感染統計
define "Cross Hospital Infection Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      infectionsAcrossHospitals: hipSurgeries P
        where "HasDeepInfectionWithin90Days"("GetProcedureDate"(P))
          and exists(
            "GetDeepInfectionProceduresWithin90Days"("GetProcedureDate"(P)) InfProc
              where "GetProcedureOrganization"(InfProc) != "GetProcedureOrganization"(P)
          )
  return Tuple {
    total_cross_hospital_infections: Count(infectionsAcrossHospitals),
    cross_hospital_infection_rate: 
      if "Numerator" > 0
        then Round(Count(infectionsAcrossHospitals) / "Numerator" * 100, 2)
        else null
  }

// 感染發生時間統計
define "Infection Timing Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      infectionIntervals: hipSurgeries P
        let surgeryDate: "GetProcedureDate"(P),
            infectionProcs: "GetDeepInfectionProceduresWithin90Days"(surgeryDate),
            firstInfectionDate: if exists(infectionProcs) 
              then First(infectionProcs InfP return "GetProcedureDate"(InfP) sort ascending)
              else null,
            daysToInfection: if firstInfectionDate is not null
              then days between surgeryDate and firstInfectionDate
              else null
        where daysToInfection is not null
        return daysToInfection,
      avgDays: if exists(infectionIntervals) 
        then Round(Sum(infectionIntervals) / Count(infectionIntervals), 1)
        else null
  return Tuple {
    average_days_to_infection: avgDays,
    min_days_to_infection: if exists(infectionIntervals) then First(infectionIntervals I sort ascending) else null,
    max_days_to_infection: if exists(infectionIntervals) then Last(infectionIntervals I sort ascending) else null
  }

// 性別統計
define "Gender Statistics":
  Tuple {
    gender: Patient.gender,
    is_male: Patient.gender = 'male',
    is_female: Patient.gender = 'female'
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '人工髖關節置換手術後九十日以內置換物深部感染率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測人工髖關節置換手術後置換物深部感染率，評估手術品質和感染控制措施，深部感染通常需要再次手術處理',
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    
    // 季度指標
    quarterly_rates: "Indicator Rate Quarterly",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // 手術統計
    hip_arthroplasty_statistics: "Hip Arthroplasty Statistics",
    
    // 深部感染統計
    deep_infection_statistics: "Deep Infection Statistics",
    
    // 深部感染手術明細統計
    deep_infection_procedure_details: "Deep Infection Procedure Details",
    
    // 跨院感染統計
    cross_hospital_infection_statistics: "Cross Hospital Infection Statistics",
    
    // 感染發生時間統計
    infection_timing_statistics: "Infection Timing Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
