library Indicator_Adult_Health_Screening_Coverage_40_64 version '1.0.0'

/*
健康檢查普及率-40歲至64歲之成人
Adult Health Screening Coverage Rate - Ages 40 to 64

計算說明:
- 分子：分母之病患曾作過成人預防保健的人數
- 分母：病患於該診所就醫次數≥6次之40歲至64歲成人
- 資料範圍：門診資料
- 計算頻率：每季

備註:
1. 年齡範圍：40歲至64歲（含40歲，含64歲）
2. 就醫次數：於計算期間內在該診所就醫次數≥6次
3. 成人預防保健服務項目代碼：
   - B0101C (成人預防保健服務-40-64歲)
   - 相關健康檢查項目
4. 計算公式：(分子/分母) x 100%
5. 臨床意義：監測40-64歲成人族群預防保健服務的覆蓋率，提升疾病早期發現與預防
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

// 年齡範圍
parameter "Minimum Age" Integer default 40
parameter "Maximum Age" Integer default 64

// 最低就醫次數
parameter "Minimum Visit Count" Integer default 6

// 編碼系統定義
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 成人預防保健服務代碼
code "B0101C": 'B0101C' from "TWProcedure" display '成人預防保健服務-40-64歲'
code "B0102C": 'B0102C' from "TWProcedure" display '成人預防保健服務-一般'
code "B0103C": 'B0103C' from "TWProcedure" display '成人預防保健服務-進階'

// 健康檢查相關LOINC代碼
code "11502-2": '11502-2' from "LOINC" display 'Laboratory report'
code "55418-8": '55418-8' from "LOINC" display 'Weight and Height tracking panel'
code "85353-1": '85353-1' from "LOINC" display 'Vital signs, weight, height, head circumference, oxygen saturation and BMI panel'

// SNOMED CT - 預防保健服務
code "310123001": '310123001' from "SNOMEDCT" display 'Preventive health service'
code "410620009": '410620009' from "SNOMEDCT" display 'Well adult care'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

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

// ===== 年齡計算 =====

// 計算就醫時的年齡（年）
define function "GetAgeInYearsAtEncounter"(encounterDate DateTime):
  years between Patient.birthDate and date from encounterDate

// 判斷年齡是否在40-64歲範圍內
define function "IsAge40To64"(encounterDate DateTime):
  let ageYears: "GetAgeInYearsAtEncounter"(encounterDate)
  return
    ageYears is not null 
    and ageYears >= "Minimum Age" 
    and ageYears <= "Maximum Age"

// ===== 就醫次數計算 =====

// 計算病患在特定期間的就醫次數
define function "GetEncounterCountInPeriod"(period Interval<DateTime>):
  Count(
    "All Outpatient Encounters" E
      where E.period.start during period
        and E.subject.reference.value = 'Patient/' + Patient.id.value
  )

// ===== 成人預防保健服務判定 =====

// 成人預防保健服務Procedure代碼清單
define "Adult Health Screening Procedure Codes":
  {
    'B0101C', 'B0102C', 'B0103C'
  }

// 判斷Procedure是否為成人預防保健服務
define function "IsAdultHealthScreeningProcedure"(procedure FHIR.Procedure):
  exists (
    procedure.code.coding C
      where C.code.value in "Adult Health Screening Procedure Codes"
  )
  or exists (
    procedure.code.coding C
      where C.system.value = 'http://snomed.info/sct'
        and C.code.value in { '310123001', '410620009' }
  )

// 檢查病患是否曾接受成人預防保健服務
define function "HasAdultHealthScreeningInPeriod"(period Interval<DateTime>):
  exists (
    "All Procedures" P
      where P.status = 'completed'
        and P.subject.reference.value = 'Patient/' + Patient.id.value
        and P.performed.start during period
        and "IsAdultHealthScreeningProcedure"(P)
  )

// ===== 醫療機構（診所）定義 =====

// 獲取病患主要就醫的醫療機構
define function "GetPrimaryOrganization"(period Interval<DateTime>):
  First(
    from "All Outpatient Encounters" E
      where E.period.start during period
        and E.subject.reference.value = 'Patient/' + Patient.id.value
      return E.serviceProvider.reference.value
      sort by (
        Count(
          "All Outpatient Encounters" E2
            where E2.serviceProvider.reference.value = E.serviceProvider.reference.value
              and E2.subject.reference.value = 'Patient/' + Patient.id.value
        )
      ) desc
  )

// ===== 季度計算函數 =====

// 針對特定季度計算普及率
define function "Calculate For Quarter"(period Interval<DateTime>):
  let 
    // 40-64歲且就醫次數≥6次的病患
    age40To64Patients:
      [Patient] P
        where exists (
          "All Outpatient Encounters" E
            where E.subject.reference.value = 'Patient/' + P.id.value
              and E.period.start during period
              and "IsAge40To64"(E.period.start)
        )
        and "GetEncounterCountInPeriod"(period) >= "Minimum Visit Count",
    
    // 曾接受成人預防保健的病患
    screenedPatients:
      age40To64Patients P
        where "HasAdultHealthScreeningInPeriod"(period)
  
  return {
    period: period,
    denominator: Count(age40To64Patients),
    numerator: Count(screenedPatients),
    coverage_rate: if Count(age40To64Patients) > 0 
                   then (Count(screenedPatients) / Count(age40To64Patients)) * 100 
                   else null
  }

// ===== 分母：40-64歲且就醫次數≥6次的病患 =====

// Q1分母
define "Q1 Denominator Patients":
  [Patient] P
    where exists (
      "All Outpatient Encounters" E
        where E.subject.reference.value = 'Patient/' + P.id.value
          and E.period.start during Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]
          and "IsAge40To64"(E.period.start)
    )
    and "GetEncounterCountInPeriod"(
      Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]
    ) >= "Minimum Visit Count"

// Q2分母
define "Q2 Denominator Patients":
  [Patient] P
    where exists (
      "All Outpatient Encounters" E
        where E.subject.reference.value = 'Patient/' + P.id.value
          and E.period.start during Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]
          and "IsAge40To64"(E.period.start)
    )
    and "GetEncounterCountInPeriod"(
      Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]
    ) >= "Minimum Visit Count"

// Q3分母
define "Q3 Denominator Patients":
  [Patient] P
    where exists (
      "All Outpatient Encounters" E
        where E.subject.reference.value = 'Patient/' + P.id.value
          and E.period.start during Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]
          and "IsAge40To64"(E.period.start)
    )
    and "GetEncounterCountInPeriod"(
      Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]
    ) >= "Minimum Visit Count"

// Q4分母
define "Q4 Denominator Patients":
  [Patient] P
    where exists (
      "All Outpatient Encounters" E
        where E.subject.reference.value = 'Patient/' + P.id.value
          and E.period.start during Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
          and "IsAge40To64"(E.period.start)
    )
    and "GetEncounterCountInPeriod"(
      Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
    ) >= "Minimum Visit Count"

// ===== 分子：曾接受成人預防保健的病患 =====

// Q1分子
define "Q1 Numerator Patients":
  "Q1 Denominator Patients" P
    where "HasAdultHealthScreeningInPeriod"(
      Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]
    )

// Q2分子
define "Q2 Numerator Patients":
  "Q2 Denominator Patients" P
    where "HasAdultHealthScreeningInPeriod"(
      Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]
    )

// Q3分子
define "Q3 Numerator Patients":
  "Q3 Denominator Patients" P
    where "HasAdultHealthScreeningInPeriod"(
      Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]
    )

// Q4分子
define "Q4 Numerator Patients":
  "Q4 Denominator Patients" P
    where "HasAdultHealthScreeningInPeriod"(
      Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
    )

// ===== 季度計算結果 =====

// Q1 結果
define "Q1 Result":
  "Calculate For Quarter"(
    Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]
  )

// Q2 結果
define "Q2 Result":
  "Calculate For Quarter"(
    Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]
  )

// Q3 結果
define "Q3 Result":
  "Calculate For Quarter"(
    Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]
  )

// Q4 結果
define "Q4 Result":
  "Calculate For Quarter"(
    Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
  )

// ===== 年度彙總結果 =====

// 全年分母
define "Annual Denominator":
  Count(
    distinct (
      [Patient] P
        where exists (
          "All Outpatient Encounters" E
            where E.subject.reference.value = 'Patient/' + P.id.value
              and E.period.start during "Measurement Period"
              and "IsAge40To64"(E.period.start)
        )
        and "GetEncounterCountInPeriod"("Measurement Period") >= "Minimum Visit Count"
    )
  )

// 全年分子
define "Annual Numerator":
  Count(
    distinct (
      [Patient] P
        where exists (
          "All Outpatient Encounters" E
            where E.subject.reference.value = 'Patient/' + P.id.value
              and E.period.start during "Measurement Period"
              and "IsAge40To64"(E.period.start)
        )
        and "GetEncounterCountInPeriod"("Measurement Period") >= "Minimum Visit Count"
        and "HasAdultHealthScreeningInPeriod"("Measurement Period")
    )
  )

// 全年普及率
define "Annual Coverage Rate":
  if "Annual Denominator" > 0 then
    ("Annual Numerator" / "Annual Denominator") * 100
  else
    null

// ===== 詳細結果輸出 =====

// 所有季度結果
define "All Quarterly Results":
  {
    "Q1 Result",
    "Q2 Result",
    "Q3 Result",
    "Q4 Result"
  }

// 最終報告
define "Final Report":
  {
    indicator_name: '健康檢查普及率-40歲至64歲之成人',
    indicator_code: 'Adult_Health_Screening_Coverage_40_64',
    calculation_year: 2026,
    calculation_frequency: '每季',
    age_range: '40-64歲（含）',
    minimum_visit_count: "Minimum Visit Count",
    annual_denominator: "Annual Denominator",
    annual_numerator: "Annual Numerator",
    annual_coverage_rate: "Annual Coverage Rate",
    quarterly_results: "All Quarterly Results",
    data_source: '門診資料',
    denominator_definition: '病患於該診所就醫次數≥6次之40歲至64歲成人',
    numerator_definition: '分母之病患曾作過成人預防保健的人數',
    screening_procedure_codes: "Adult Health Screening Procedure Codes",
    clinical_significance: '監測40-64歲成人族群預防保健服務的覆蓋率，提升疾病早期發現與預防',
    formula: '(分子/分母) x 100%'
  }

// ===== 年齡分層分析 =====

// 按年齡層分組計算（5歲一組）
define function "Calculate By Age Group"(minAge Integer, maxAge Integer, period Interval<DateTime>):
  let 
    ageGroupPatients:
      [Patient] P
        where exists (
          "All Outpatient Encounters" E
            where E.subject.reference.value = 'Patient/' + P.id.value
              and E.period.start during period
              and "GetAgeInYearsAtEncounter"(E.period.start) >= minAge
              and "GetAgeInYearsAtEncounter"(E.period.start) <= maxAge
        )
        and "GetEncounterCountInPeriod"(period) >= "Minimum Visit Count",
    
    screenedPatients:
      ageGroupPatients P
        where "HasAdultHealthScreeningInPeriod"(period)
  
  return {
    age_group: ToString(minAge) + '-' + ToString(maxAge) + '歲',
    denominator: Count(ageGroupPatients),
    numerator: Count(screenedPatients),
    coverage_rate: if Count(ageGroupPatients) > 0 
                   then (Count(screenedPatients) / Count(ageGroupPatients)) * 100 
                   else null
  }

// 年度年齡分層結果（5歲一組）
define "Age Stratified Results":
  {
    "Calculate By Age Group"(40, 44, "Measurement Period"),
    "Calculate By Age Group"(45, 49, "Measurement Period"),
    "Calculate By Age Group"(50, 54, "Measurement Period"),
    "Calculate By Age Group"(55, 59, "Measurement Period"),
    "Calculate By Age Group"(60, 64, "Measurement Period")
  }

// ===== 性別分層分析 =====

// 按性別計算
define function "Calculate By Gender"(gender String, period Interval<DateTime>):
  let 
    genderPatients:
      [Patient] P
        where P.gender.value = gender
          and exists (
            "All Outpatient Encounters" E
              where E.subject.reference.value = 'Patient/' + P.id.value
                and E.period.start during period
                and "IsAge40To64"(E.period.start)
          )
          and "GetEncounterCountInPeriod"(period) >= "Minimum Visit Count",
    
    screenedPatients:
      genderPatients P
        where "HasAdultHealthScreeningInPeriod"(period)
  
  return {
    gender: gender,
    denominator: Count(genderPatients),
    numerator: Count(screenedPatients),
    coverage_rate: if Count(genderPatients) > 0 
                   then (Count(screenedPatients) / Count(genderPatients)) * 100 
                   else null
  }

// 年度性別分層結果
define "Gender Stratified Results":
  {
    "Calculate By Gender"('male', "Measurement Period"),
    "Calculate By Gender"('female', "Measurement Period")
  }
