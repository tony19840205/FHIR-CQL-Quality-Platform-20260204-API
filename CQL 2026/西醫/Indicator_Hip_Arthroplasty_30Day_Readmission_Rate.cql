library Indicator_Hip_Arthroplasty_30Day_Readmission_Rate version '1.0.0'

/*
實施人工髖關節置換術出院後三十日以內因相關問題再住院率
Hip Arthroplasty 30-Day Related Readmission Rate

計算說明:
- 分子：分母案件中，出院後30天內再住院，且再住院案件有備註之任一情形者
- 分母：統計期間內醫院人工髖關節置換術執行案件數
- 資料範圍：醫院住院資料
- 計算頻率：季、年

備註:
1. 分子之包含條件如下：
   (1) 執行64052B、64004C、64198B、48004C、48005C、48006C任一醫令且日有使用抗生素藥品者
   (2) 任一次診斷碼為T8579XA、T85730A、T85731A、T85732A、T85733A、T85734A、T85735A、T85738A、T8450(第7位碼為"A")、T846-T847(第7位碼為"A")、T8572-T8579(第7位碼為"A")、T868421、T868422、T868423、T868429、T8140XA、T8141XA、T8142XA、T8143XA、T8144XA、T8149XA、M869、M4620-M4628、M0005、M0015、M0025、M0085、M0006、M0016、M0026、M0086、M0008、M0018、M0028、M0088、M009且有使用抗生素藥品者
2. 人工髖關節置換執行案件數：醫令代碼為64162B且醫令類別為2的住院案件
3. 抗生素藥品：ATC7分類碼為J01CA12、J01CF01、J01CF02、J01CA04、J04CA05、J01DA11、J01DA24、J01EA01、J01EC01、J01XA01、J01XA02、J01DD02、J01DE01、A07AA09的藥品
4. 臨床意義：監測人工髖關節置換術後30天內因相關併發症（感染、置換物問題等）再住院的情況，評估術後照護品質和併發症管理
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

// 監測期間（30天）
parameter "Monitoring Period Days" Integer default 30

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "LOINC": 'http://loinc.org'

// 人工髖關節置換手術code (NHI 64162B)
code "64162B": '64162B' from "TWProcedure" display '人工髖關節置換術'

// 相關併發症手術codes
code "64052B": '64052B' from "TWProcedure" display '人工髖關節感染清創術'
code "64004C": '64004C' from "TWProcedure" display '人工髖關節置換物移除術'
code "64198B": '64198B' from "TWProcedure" display '人工關節置換物移除術'
code "48004C": '48004C' from "TWProcedure" display '傷口清創術'
code "48005C": '48005C' from "TWProcedure" display '傷口清創術'
code "48006C": '48006C' from "TWProcedure" display '傷口清創術'

// 感染診斷codes - T85系列
code "T8579XA": 'T8579XA' from "ICD10CM" display 'Infection and inflammatory reaction due to other internal prosthetic devices, implants and grafts, initial encounter'
code "T85730A": 'T85730A' from "ICD10CM" display 'Infection and inflammatory reaction due to ventricular intracranial (communicating) shunt, initial encounter'
code "T85731A": 'T85731A' from "ICD10CM" display 'Infection and inflammatory reaction due to implanted electronic neurostimulator of brain, initial encounter'
code "T85732A": 'T85732A' from "ICD10CM" display 'Infection and inflammatory reaction due to implanted electronic neurostimulator of peripheral nerve, initial encounter'
code "T85733A": 'T85733A' from "ICD10CM" display 'Infection and inflammatory reaction due to implanted electronic neurostimulator of spinal cord, initial encounter'
code "T85734A": 'T85734A' from "ICD10CM" display 'Infection and inflammatory reaction due to implanted electronic neurostimulator, generator, initial encounter'
code "T85735A": 'T85735A' from "ICD10CM" display 'Infection and inflammatory reaction due to cranial or spinal infusion catheter, initial encounter'
code "T85738A": 'T85738A' from "ICD10CM" display 'Infection and inflammatory reaction due to other nervous system device, implant or graft, initial encounter'

// 感染診斷codes - T84系列 (T8140XA-T8149XA)
code "T8140XA": 'T8140XA' from "ICD10CM" display 'Infection and inflammatory reaction due to unspecified internal joint prosthesis, initial encounter'
code "T8141XA": 'T8141XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal right hip prosthesis, initial encounter'
code "T8142XA": 'T8142XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal left hip prosthesis, initial encounter'
code "T8143XA": 'T8143XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal right knee prosthesis, initial encounter'
code "T8144XA": 'T8144XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal left knee prosthesis, initial encounter'
code "T8149XA": 'T8149XA' from "ICD10CM" display 'Infection and inflammatory reaction due to other internal joint prosthesis, initial encounter'

// 感染診斷codes - T868系列
code "T868421": 'T868421' from "ICD10CM" display 'Infection and inflammatory reaction due to breast prosthesis and implant, right breast'
code "T868422": 'T868422' from "ICD10CM" display 'Infection and inflammatory reaction due to breast prosthesis and implant, left breast'
code "T868423": 'T868423' from "ICD10CM" display 'Infection and inflammatory reaction due to breast prosthesis and implant, bilateral'
code "T868429": 'T868429' from "ICD10CM" display 'Infection and inflammatory reaction due to breast prosthesis and implant, unspecified breast'

// 感染診斷codes - M系列
code "M869": 'M869' from "ICD10CM" display 'Osteomyelitis, unspecified'
code "M0005": 'M0005' from "ICD10CM" display 'Staphylococcal arthritis, hip'
code "M0015": 'M0015' from "ICD10CM" display 'Pneumococcal arthritis, hip'
code "M0025": 'M0025' from "ICD10CM" display 'Other streptococcal arthritis, hip'
code "M0085": 'M0085' from "ICD10CM" display 'Arthritis due to other bacteria, hip'
code "M0006": 'M0006' from "ICD10CM" display 'Staphylococcal arthritis, knee'
code "M0016": 'M0016' from "ICD10CM" display 'Pneumococcal arthritis, knee'
code "M0026": 'M0026' from "ICD10CM" display 'Other streptococcal arthritis, knee'
code "M0086": 'M0086' from "ICD10CM" display 'Arthritis due to other bacteria, knee'
code "M0008": 'M0008' from "ICD10CM" display 'Staphylococcal arthritis, other specified site'
code "M0018": 'M0018' from "ICD10CM" display 'Pneumococcal arthritis, other specified site'
code "M0028": 'M0028' from "ICD10CM" display 'Other streptococcal arthritis, other specified site'
code "M0088": 'M0088' from "ICD10CM" display 'Arthritis due to other bacteria, other specified site'
code "M009": 'M009' from "ICD10CM" display 'Pyogenic arthritis, unspecified'

// M4620-M4628系列
code "M4620": 'M4620' from "ICD10CM" display 'Osteomyelitis of vertebra, site unspecified'
code "M4621": 'M4621' from "ICD10CM" display 'Osteomyelitis of vertebra, occipito-atlanto-axial region'
code "M4622": 'M4622' from "ICD10CM" display 'Osteomyelitis of vertebra, cervical region'
code "M4623": 'M4623' from "ICD10CM" display 'Osteomyelitis of vertebra, cervicothoracic region'
code "M4624": 'M4624' from "ICD10CM" display 'Osteomyelitis of vertebra, thoracic region'
code "M4625": 'M4625' from "ICD10CM" display 'Osteomyelitis of vertebra, thoracolumbar region'
code "M4626": 'M4626' from "ICD10CM" display 'Osteomyelitis of vertebra, lumbar region'
code "M4627": 'M4627' from "ICD10CM" display 'Osteomyelitis of vertebra, lumbosacral region'
code "M4628": 'M4628' from "ICD10CM" display 'Osteomyelitis of vertebra, sacral and sacrococcygeal region'

// 抗生素藥品ATC codes
code "J01CA12": 'J01CA12' from "ATC" display 'Piperacillin'
code "J01CF01": 'J01CF01' from "ATC" display 'Dicloxacillin'
code "J01CF02": 'J01CF02' from "ATC" display 'Cloxacillin'
code "J01CA04": 'J01CA04' from "ATC" display 'Amoxicillin'
code "J04CA05": 'J04CA05' from "ATC" display 'Ofloxacin'
code "J01DA11": 'J01DA11' from "ATC" display 'Cefazolin'
code "J01DA24": 'J01DA24' from "ATC" display 'Cefalotin'
code "J01EA01": 'J01EA01' from "ATC" display 'Trimethoprim'
code "J01EC01": 'J01EC01' from "ATC" display 'Sulfamethoxazole and trimethoprim'
code "J01XA01": 'J01XA01' from "ATC" display 'Vancomycin'
code "J01XA02": 'J01XA02' from "ATC" display 'Teicoplanin'
code "J01DD02": 'J01DD02' from "ATC" display 'Ceftazidime'
code "J01DE01": 'J01DE01' from "ATC" display 'Cefepime'
code "A07AA09": 'A07AA09' from "ATC" display 'Vancomycin'

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

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// ===== 人工髖關節置換手術判斷 =====

// 判斷Procedure是否為人工髖關節置換手術 (64162B)
define function "IsHipArthroplastyProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and C.code = '64162B'
    )

// 取得Procedure執行的Encounter
define function "GetProcedureEncounter"(procedure Procedure):
  singleton from (
    "All Inpatient Encounters" E
      where E.id = Last(Split(procedure.encounter.reference, '/'))
  )

// 取得Encounter出院日期
define function "GetDischargeDate"(encounter Encounter):
  end of encounter.period

// 取得病人所有人工髖關節置換手術
define "Hip Arthroplasty Procedures":
  "All Procedures" P
    where "IsHipArthroplastyProcedure"(P)

// ===== 再住院相關判斷 =====

// 計算30天再住院監測期間
define function "Get30DayReadmissionPeriod"(dischargeDate DateTime):
  Interval[dischargeDate, dischargeDate + "Monitoring Period Days" days]

// 取得30天內的再住院Encounter
define function "GetReadmissionsWithin30Days"(dischargeDate DateTime):
  let readmissionPeriod: "Get30DayReadmissionPeriod"(dischargeDate)
  return
    "All Inpatient Encounters" E
      where start of E.period during readmissionPeriod

// ===== 相關併發症手術判斷 =====

// 判斷Procedure是否為相關併發症手術 (64052B, 64004C, 64198B, 48004C, 48005C, 48006C)
define function "IsRelatedComplicationProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '64052B'
            or C.code = '64004C'
            or C.code = '64198B'
            or C.code = '48004C'
            or C.code = '48005C'
            or C.code = '48006C'
          )
    )

// 判斷Encounter中是否有相關併發症手術
define function "HasRelatedComplicationProcedure"(encounter Encounter):
  exists(
    "All Procedures" P
      where "IsRelatedComplicationProcedure"(P)
        and P.encounter.reference = 'Encounter/' + encounter.id
  )

// ===== 相關診斷判斷 =====

// 判斷Condition是否為相關感染診斷
define function "IsRelatedInfectionDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          // T85系列
          C.code = 'T8579XA'
          or C.code = 'T85730A'
          or C.code = 'T85731A'
          or C.code = 'T85732A'
          or C.code = 'T85733A'
          or C.code = 'T85734A'
          or C.code = 'T85735A'
          or C.code = 'T85738A'
          // T8450第7位碼為"A"
          or (StartsWith(C.code, 'T8450') and EndsWith(C.code, 'A'))
          // T846-T847第7位碼為"A"
          or (StartsWith(C.code, 'T846') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T847') and EndsWith(C.code, 'A'))
          // T8572-T8579第7位碼為"A"
          or (StartsWith(C.code, 'T8572') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T8573') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T8574') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T8575') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T8576') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T8577') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T8578') and EndsWith(C.code, 'A'))
          or (StartsWith(C.code, 'T8579') and EndsWith(C.code, 'A'))
          // T868系列
          or C.code = 'T868421'
          or C.code = 'T868422'
          or C.code = 'T868423'
          or C.code = 'T868429'
          // T814X系列
          or C.code = 'T8140XA'
          or C.code = 'T8141XA'
          or C.code = 'T8142XA'
          or C.code = 'T8143XA'
          or C.code = 'T8144XA'
          or C.code = 'T8149XA'
          // M系列
          or C.code = 'M869'
          or StartsWith(C.code, 'M4620')
          or StartsWith(C.code, 'M4621')
          or StartsWith(C.code, 'M4622')
          or StartsWith(C.code, 'M4623')
          or StartsWith(C.code, 'M4624')
          or StartsWith(C.code, 'M4625')
          or StartsWith(C.code, 'M4626')
          or StartsWith(C.code, 'M4627')
          or StartsWith(C.code, 'M4628')
          or C.code = 'M0005'
          or C.code = 'M0015'
          or C.code = 'M0025'
          or C.code = 'M0085'
          or C.code = 'M0006'
          or C.code = 'M0016'
          or C.code = 'M0026'
          or C.code = 'M0086'
          or C.code = 'M0008'
          or C.code = 'M0018'
          or C.code = 'M0028'
          or C.code = 'M0088'
          or StartsWith(C.code, 'M009')
        )
  )

// 判斷Encounter中是否有相關感染診斷
define function "HasRelatedInfectionDiagnosis"(encounter Encounter):
  exists(
    "All Conditions" C
      where "IsRelatedInfectionDiagnosis"(C)
        and C.encounter.reference = 'Encounter/' + encounter.id
  )

// ===== 抗生素使用判斷 =====

// 判斷MedicationRequest是否為抗生素
define function "IsAntibioticMedication"(medication MedicationRequest):
  exists(
    medication.medication.coding C
      where C.system = 'http://www.whocc.no/atc'
        and (
          C.code = 'J01CA12'
          or C.code = 'J01CF01'
          or C.code = 'J01CF02'
          or C.code = 'J01CA04'
          or C.code = 'J04CA05'
          or C.code = 'J01DA11'
          or C.code = 'J01DA24'
          or C.code = 'J01EA01'
          or C.code = 'J01EC01'
          or C.code = 'J01XA01'
          or C.code = 'J01XA02'
          or C.code = 'J01DD02'
          or C.code = 'J01DE01'
          or C.code = 'A07AA09'
        )
  )

// 判斷Encounter中是否有使用抗生素
define function "HasAntibioticUse"(encounter Encounter):
  exists(
    "All Medication Requests" M
      where "IsAntibioticMedication"(M)
        and M.encounter.reference = 'Encounter/' + encounter.id
  )

// ===== 相關再住院判斷 =====

// 判斷再住院是否符合相關條件（條件1：手術+抗生素）
define function "IsRelatedReadmissionCondition1"(encounter Encounter):
  "HasRelatedComplicationProcedure"(encounter)
    and "HasAntibioticUse"(encounter)

// 判斷再住院是否符合相關條件（條件2：診斷+抗生素）
define function "IsRelatedReadmissionCondition2"(encounter Encounter):
  "HasRelatedInfectionDiagnosis"(encounter)
    and "HasAntibioticUse"(encounter)

// 判斷再住院是否為相關再住院
define function "IsRelatedReadmission"(encounter Encounter):
  "IsRelatedReadmissionCondition1"(encounter)
    or "IsRelatedReadmissionCondition2"(encounter)

// 判斷30天內是否有相關再住院
define function "HasRelatedReadmissionWithin30Days"(dischargeDate DateTime):
  exists(
    "GetReadmissionsWithin30Days"(dischargeDate) E
      where "IsRelatedReadmission"(E)
  )

// ===== 分母定義（依期間）=====

// 取得期間內的人工髖關節置換手術（住院案件）
define function "GetHipArthroplastyInPeriod"(period Interval<DateTime>):
  "Hip Arthroplasty Procedures" P
    let encounter: "GetProcedureEncounter"(P),
        dischargeDate: if encounter is not null then "GetDischargeDate"(encounter) else null
    where dischargeDate during period
      and encounter.type in "Inpatient Encounter Codes"
    return encounter

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

// 判斷是否有相關再住院（針對特定期間）
define function "HasRelatedReadmissionInPeriod"(period Interval<DateTime>):
  exists(
    "GetHipArthroplastyInPeriod"(period) E
      let dischargeDate: "GetDischargeDate"(E)
      where "HasRelatedReadmissionWithin30Days"(dischargeDate)
  )

// 分子（全年）
define "Numerator":
  if "HasRelatedReadmissionInPeriod"("Measurement Period") then 1 else 0

// 分子（季度）
define "Numerator Quarterly":
  "Quarterly Periods" P
    return if "HasRelatedReadmissionInPeriod"(P) then 1 else 0

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
        numer: if "HasRelatedReadmissionInPeriod"(P) then 1 else 0
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
    total_hip_arthroplasty_encounters: Count(hipSurgeries),
    patients_with_related_readmission: "Numerator",
    patients_without_related_readmission: "Denominator" - "Numerator"
  }

// 手術統計
define "Hip Arthroplasty Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      dischargeDates: hipSurgeries E return "GetDischargeDate"(E)
  return Tuple {
    total_hip_arthroplasty_encounters: Count(hipSurgeries),
    first_discharge_date: if exists(dischargeDates) then ToString(First(dischargeDates D sort ascending)) else null,
    last_discharge_date: if exists(dischargeDates) then ToString(Last(dischargeDates D sort ascending)) else null
  }

// 再住院統計
define "Readmission Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      readmissionsCondition1: hipSurgeries E
        where exists(
          "GetReadmissionsWithin30Days"("GetDischargeDate"(E)) R
            where "IsRelatedReadmissionCondition1"(R)
        ),
      readmissionsCondition2: hipSurgeries E
        where exists(
          "GetReadmissionsWithin30Days"("GetDischargeDate"(E)) R
            where "IsRelatedReadmissionCondition2"(R)
        )
  return Tuple {
    total_related_readmissions: "Numerator",
    readmissions_with_procedure_and_antibiotic: Count(readmissionsCondition1),
    readmissions_with_diagnosis_and_antibiotic: Count(readmissionsCondition2),
    readmission_rate_percent: "Indicator Rate"
  }

// 再住院時間統計
define "Readmission Timing Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      readmissionIntervals: hipSurgeries E
        let dischargeDate: "GetDischargeDate"(E),
            relatedReadmissions: "GetReadmissionsWithin30Days"(dischargeDate) R
              where "IsRelatedReadmission"(R),
            firstReadmissionDate: if exists(relatedReadmissions)
              then start of First(relatedReadmissions R return R.period sort by start of R.period ascending)
              else null,
            daysToReadmission: if firstReadmissionDate is not null
              then days between dischargeDate and firstReadmissionDate
              else null
        where daysToReadmission is not null
        return daysToReadmission,
      avgDays: if exists(readmissionIntervals)
        then Round(Sum(readmissionIntervals) / Count(readmissionIntervals), 1)
        else null
  return Tuple {
    average_days_to_readmission: avgDays,
    min_days_to_readmission: if exists(readmissionIntervals) then First(readmissionIntervals I sort ascending) else null,
    max_days_to_readmission: if exists(readmissionIntervals) then Last(readmissionIntervals I sort ascending) else null
  }

// 再住院原因統計
define "Readmission Reason Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      allRelatedReadmissions: flatten(
        hipSurgeries E
          return "GetReadmissionsWithin30Days"("GetDischargeDate"(E)) R
            where "IsRelatedReadmission"(R)
      )
  return Tuple {
    total_readmissions: Count(allRelatedReadmissions),
    readmissions_with_64052B: Count(
      allRelatedReadmissions R
        where exists("All Procedures" P where P.encounter.reference = 'Encounter/' + R.id and exists(P.code.coding C where C.code = '64052B'))
    ),
    readmissions_with_64004C: Count(
      allRelatedReadmissions R
        where exists("All Procedures" P where P.encounter.reference = 'Encounter/' + R.id and exists(P.code.coding C where C.code = '64004C'))
    ),
    readmissions_with_64198B: Count(
      allRelatedReadmissions R
        where exists("All Procedures" P where P.encounter.reference = 'Encounter/' + R.id and exists(P.code.coding C where C.code = '64198B'))
    ),
    readmissions_with_48004C_48005C_48006C: Count(
      allRelatedReadmissions R
        where exists("All Procedures" P where P.encounter.reference = 'Encounter/' + R.id and exists(P.code.coding C where (C.code = '48004C' or C.code = '48005C' or C.code = '48006C')))
    ),
    readmissions_with_infection_diagnosis: Count(
      allRelatedReadmissions R
        where "HasRelatedInfectionDiagnosis"(R)
    )
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
    indicator_name: '實施人工髖關節置換術出院後三十日以內因相關問題再住院率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測人工髖關節置換術後30天內因相關併發症（感染、置換物問題等）再住院的情況，評估術後照護品質和併發症管理',
    
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
    
    // 再住院統計
    readmission_statistics: "Readmission Statistics",
    
    // 再住院時間統計
    readmission_timing_statistics: "Readmission Timing Statistics",
    
    // 再住院原因統計
    readmission_reason_statistics: "Readmission Reason Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
