library Indicator_Children_Health_Screening_Coverage_3_To_6 version '1.0.0'

/*
健康檢查普及率-3歲至6歲之兒童
Children Health Screening Coverage Rate - Ages 3 to 6

計算說明:
- 分子：分母之病患曾作過兒童預防保健的人數
- 分母：病患於該診所就醫次數≥6次之3歲至6歲之兒童
- 資料範圍：門診資料
- 計算頻率：每季

備註:
1. 年齡範圍：3歲至6歲（含3歲，含6歲）
2. 就醫次數：於計算期間內在該診所就醫次數≥6次
3. 兒童預防保健服務項目代碼：
   - C0106C (兒童預防保健服務-第6次，2-3歲)
   - C0107C (兒童預防保健服務-第7次，3-未滿7歲)
4. 計算公式：(分子/分母) x 100%
5. 臨床意義：監測3-6歲學齡前兒童預防保健服務的覆蓋率，提升兒童健康發展與入學前健康評估
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
parameter "Minimum Age" Integer default 3
parameter "Maximum Age" Integer default 6

// 最低就醫次數
parameter "Minimum Visit Count" Integer default 6

// 編碼系統定義
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 兒童預防保健服務代碼（3-6歲適用）
code "C0106C": 'C0106C' from "TWProcedure" display '兒童預防保健服務-第6次（2-3歲）'
code "C0107C": 'C0107C' from "TWProcedure" display '兒童預防保健服務-第7次（3-未滿7歲）'

// 健康檢查相關LOINC代碼
code "55418-8": '55418-8' from "LOINC" display 'Weight and Height tracking panel'
code "85353-1": '85353-1' from "LOINC" display 'Vital signs, weight, height, head circumference, oxygen saturation and BMI panel'
code "8302-2": '8302-2' from "LOINC" display 'Body height'
code "29463-7": '29463-7' from "LOINC" display 'Body weight'
code "39156-5": '39156-5' from "LOINC" display 'Body mass index (BMI) [Ratio]'

// SNOMED CT - 兒童預防保健服務
code "410620009": '410620009' from "SNOMEDCT" display 'Well child visit'
code "170099002": '170099002' from "SNOMEDCT" display 'Child health examination'
code "390840006": '390840006' from "SNOMEDCT" display 'Preschool health examination'

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

// 判斷年齡是否在3-6歲範圍內
define function "IsAge3To6"(encounterDate DateTime):
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

// ===== 兒童預防保健服務判定 =====

// 兒童預防保健服務Procedure代碼清單（3-6歲適用）
define "Children Health Screening Procedure Codes":
  {
    'C0106C', 'C0107C'
  }

// 判斷Procedure是否為兒童預防保健服務
define function "IsChildrenHealthScreeningProcedure"(procedure FHIR.Procedure):
  exists (
    procedure.code.coding C
      where C.code.value in "Children Health Screening Procedure Codes"
  )
  or exists (
    procedure.code.coding C
      where C.system.value = 'http://snomed.info/sct'
        and C.code.value in { '410620009', '170099002', '390840006' }
  )

// 檢查病患是否曾接受兒童預防保健服務
define function "HasChildrenHealthScreeningInPeriod"(period Interval<DateTime>):
  exists (
    "All Procedures" P
      where P.status = 'completed'
        and P.subject.reference.value = 'Patient/' + Patient.id.value
        and P.performed.start during period
        and "IsChildrenHealthScreeningProcedure"(P)
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
    // 3-6歲且就醫次數≥6次的病患
    age3To6Patients:
      [Patient] P
        where exists (
          "All Outpatient Encounters" E
            where E.subject.reference.value = 'Patient/' + P.id.value
              and E.period.start during period
              and "IsAge3To6"(E.period.start)
        )
        and "GetEncounterCountInPeriod"(period) >= "Minimum Visit Count",
    
    // 曾接受兒童預防保健的病患
    screenedPatients:
      age3To6Patients P
        where "HasChildrenHealthScreeningInPeriod"(period)
  
  return {
    period: period,
    denominator: Count(age3To6Patients),
    numerator: Count(screenedPatients),
    coverage_rate: if Count(age3To6Patients) > 0 
                   then (Count(screenedPatients) / Count(age3To6Patients)) * 100 
                   else null
  }

// ===== 分母：3-6歲且就醫次數≥6次的病患 =====

// Q1分母
define "Q1 Denominator Patients":
  [Patient] P
    where exists (
      "All Outpatient Encounters" E
        where E.subject.reference.value = 'Patient/' + P.id.value
          and E.period.start during Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]
          and "IsAge3To6"(E.period.start)
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
          and "IsAge3To6"(E.period.start)
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
          and "IsAge3To6"(E.period.start)
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
          and "IsAge3To6"(E.period.start)
    )
    and "GetEncounterCountInPeriod"(
      Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
    ) >= "Minimum Visit Count"

// ===== 分子：曾接受兒童預防保健的病患 =====

// Q1分子
define "Q1 Numerator Patients":
  "Q1 Denominator Patients" P
    where "HasChildrenHealthScreeningInPeriod"(
      Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]
    )

// Q2分子
define "Q2 Numerator Patients":
  "Q2 Denominator Patients" P
    where "HasChildrenHealthScreeningInPeriod"(
      Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]
    )

// Q3分子
define "Q3 Numerator Patients":
  "Q3 Denominator Patients" P
    where "HasChildrenHealthScreeningInPeriod"(
      Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]
    )

// Q4分子
define "Q4 Numerator Patients":
  "Q4 Denominator Patients" P
    where "HasChildrenHealthScreeningInPeriod"(
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
              and "IsAge3To6"(E.period.start)
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
              and "IsAge3To6"(E.period.start)
        )
        and "GetEncounterCountInPeriod"("Measurement Period") >= "Minimum Visit Count"
        and "HasChildrenHealthScreeningInPeriod"("Measurement Period")
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
    indicator_name: '健康檢查普及率-3歲至6歲之兒童',
    indicator_code: 'Children_Health_Screening_Coverage_3_To_6',
    calculation_year: 2026,
    calculation_frequency: '每季',
    age_range: '3-6歲（含3歲、含6歲）',
    minimum_visit_count: "Minimum Visit Count",
    annual_denominator: "Annual Denominator",
    annual_numerator: "Annual Numerator",
    annual_coverage_rate: "Annual Coverage Rate",
    quarterly_results: "All Quarterly Results",
    data_source: '門診資料',
    denominator_definition: '病患於該診所就醫次數≥6次之3歲至6歲之兒童',
    numerator_definition: '分母之病患曾作過兒童預防保健的人數',
    screening_procedure_codes: "Children Health Screening Procedure Codes",
    clinical_significance: '監測3-6歲學齡前兒童預防保健服務的覆蓋率，提升兒童健康發展與入學前健康評估',
    formula: '(分子/分母) x 100%',
    note: '第7次兒童預防保健服務（3-未滿7歲）為此年齡層主要健檢項目'
  }

// ===== 年齡分層分析 =====

// 按年齡分組計算
define function "Calculate By Age Group"(age Integer, period Interval<DateTime>):
  let 
    ageGroupPatients:
      [Patient] P
        where exists (
          "All Outpatient Encounters" E
            where E.subject.reference.value = 'Patient/' + P.id.value
              and E.period.start during period
              and "GetAgeInYearsAtEncounter"(E.period.start) = age
        )
        and "GetEncounterCountInPeriod"(period) >= "Minimum Visit Count",
    
    screenedPatients:
      ageGroupPatients P
        where "HasChildrenHealthScreeningInPeriod"(period)
  
  return {
    age_group: ToString(age) + '歲',
    denominator: Count(ageGroupPatients),
    numerator: Count(screenedPatients),
    coverage_rate: if Count(ageGroupPatients) > 0 
                   then (Count(screenedPatients) / Count(ageGroupPatients)) * 100 
                   else null
  }

// 年度年齡分層結果（逐歲）
define "Age Stratified Results":
  {
    "Calculate By Age Group"(3, "Measurement Period"),
    "Calculate By Age Group"(4, "Measurement Period"),
    "Calculate By Age Group"(5, "Measurement Period"),
    "Calculate By Age Group"(6, "Measurement Period")
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
                and "IsAge3To6"(E.period.start)
          )
          and "GetEncounterCountInPeriod"(period) >= "Minimum Visit Count",
    
    screenedPatients:
      genderPatients P
        where "HasChildrenHealthScreeningInPeriod"(period)
  
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

// ===== 入學準備度分析 =====

// 定義即將入學的兒童（6歲）
define "Preschool Age Children":
  [Patient] P
    where exists (
      "All Outpatient Encounters" E
        where E.subject.reference.value = 'Patient/' + P.id.value
          and E.period.start during "Measurement Period"
          and "GetAgeInYearsAtEncounter"(E.period.start) = 6
    )
    and "GetEncounterCountInPeriod"("Measurement Period") >= "Minimum Visit Count"

// 即將入學兒童的健檢完成率
define "Preschool Screening Coverage":
  let 
    preschoolChildren: "Preschool Age Children",
    screenedPreschoolChildren:
      preschoolChildren P
        where "HasChildrenHealthScreeningInPeriod"("Measurement Period")
  
  return {
    denominator: Count(preschoolChildren),
    numerator: Count(screenedPreschoolChildren),
    coverage_rate: if Count(preschoolChildren) > 0 
                   then (Count(screenedPreschoolChildren) / Count(preschoolChildren)) * 100 
                   else null,
    note: '6歲兒童入學前健康檢查完成情況'
  }

// ===== 健檢時程遵循度分析 =====

// 計算病患接受過的兒童健檢次數
define function "GetScreeningCountInPeriod"(period Interval<DateTime>):
  Count(
    "All Procedures" P
      where P.status = 'completed'
        and P.subject.reference.value = 'Patient/' + Patient.id.value
        and P.performed.start during period
        and "IsChildrenHealthScreeningProcedure"(P)
  )

// 按是否完成健檢分組
define function "Calculate By Screening Status"(period Interval<DateTime>):
  let 
    targetPatients:
      [Patient] P
        where exists (
          "All Outpatient Encounters" E
            where E.subject.reference.value = 'Patient/' + P.id.value
              and E.period.start during period
              and "IsAge3To6"(E.period.start)
        )
        and "GetEncounterCountInPeriod"(period) >= "Minimum Visit Count",
    
    completedPatients:
      targetPatients P
        where "GetScreeningCountInPeriod"(period) >= 1,
    
    notCompletedPatients:
      targetPatients P
        where "GetScreeningCountInPeriod"(period) = 0
  
  return {
    total: Count(targetPatients),
    completed: Count(completedPatients),
    not_completed: Count(notCompletedPatients),
    completion_rate: if Count(targetPatients) > 0 
                     then (Count(completedPatients) / Count(targetPatients)) * 100 
                     else null
  }

// 年度健檢完成情況
define "Annual Screening Status":
  "Calculate By Screening Status"("Measurement Period")

// ===== 地區分析（依就醫機構） =====

// 按機構統計
define "Coverage By Organization":
  from "All Outpatient Encounters" E
    where E.period.start during "Measurement Period"
      and exists (
        [Patient] P
          where P.id.value = Last(Split(E.subject.reference.value, '/'))
            and "IsAge3To6"(E.period.start)
      )
    let org: E.serviceProvider.reference.value,
        orgPatients: 
          [Patient] P
            where exists (
              "All Outpatient Encounters" E2
                where E2.subject.reference.value = 'Patient/' + P.id.value
                  and E2.serviceProvider.reference.value = org
                  and E2.period.start during "Measurement Period"
                  and "IsAge3To6"(E2.period.start)
            )
            and "GetEncounterCountInPeriod"("Measurement Period") >= "Minimum Visit Count",
        screenedOrgPatients:
          orgPatients P
            where "HasChildrenHealthScreeningInPeriod"("Measurement Period")
    return {
      organization: org,
      denominator: Count(orgPatients),
      numerator: Count(screenedOrgPatients),
      coverage_rate: if Count(orgPatients) > 0 
                     then (Count(screenedOrgPatients) / Count(orgPatients)) * 100 
                     else null
    }
    sort by coverage_rate desc
