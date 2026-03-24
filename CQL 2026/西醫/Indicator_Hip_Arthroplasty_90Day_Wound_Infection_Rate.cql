library Indicator_Hip_Arthroplasty_90Day_Wound_Infection_Rate version '1.0.0'

/*
人工髖關節置換手術後九十日以內傷口感染率
Hip Arthroplasty 90-Day Wound Infection Rate

計算說明:
- 分子：分母案件中，人工髖關節置換後3個月(90天)內發生手術傷口感染的案件數
- 分母：統計期間內醫院人工髖關節置換術執行案件數
- 資料範圍：醫院住院資料
- 計算頻率：季、年

備註:
1. 人工髖關節置換執行案件數：醫令代碼為64162B且醫令類別為2的住院案件
2. 手術傷口感染：((1) or (2)) and (3)：
   - 西醫醫院及西醫基層之門、住案件，(1)有執行48004C、48005C、48006C或(2)任一診斷碼為T8579XA、T85730A、T85731A、T85732A、T85733A、T85734A、T85735A、T85738A、T8450(第7位碼為"A")、T846-T847(第7位碼為"A")、T8572-T8579(第7位碼為"A")、T868421、T868422、T868423、T868429、T8140XA、T8141XA、T8142XA、T8143XA、T8144XA、T8149XA、M869、M4620-M4628、M0005、M0015、M0025、M0085、M0006、M0016、M0026、M0086、M0008、M0018、M0028、M0088、M009
   - 且(3)於術後7日後有使用抗生素藥品者
3. 術後7日後有使用抗生素藥品：抗生素醫令迄日(取最大的迄日)- 手術醫令起日 >= 7
4. 抗生素藥品：ATC7分類碼為J01CA12、J01CF01、J01CF02、J01CA04、J04CA05、J01DA11、J01DA24、J01EA01、J01EC01、J01XA01、J01XA02、J01DD02、J01DE01、A07AA09的藥品
5. 勾稽90天內是否有發生手術傷口感染時，以實施人工髖關節置換的案件裡，自最早的醫令起日往後勾稽90天。若勾稽到本身住院案件也需列入分子。
6. 臨床意義：監測人工髖關節置換手術後傷口感染率，以評估手術品質和感染控制措施的有效性
7. 計算範圍：2026年(115年)資料

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

// 術後抗生素使用最短間隔（7天）
parameter "Minimum Antibiotic Interval Days" Integer default 7

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "LOINC": 'http://loinc.org'

// 人工髖關節置換手術codes (NHI 64162B)
code "64162B": '64162B' from "TWProcedure" display '人工髖關節置換術'

// 傷口處理手術codes (48004C, 48005C, 48006C)
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

// 感染診斷codes - M系列 (關節感染)
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

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// Encounter類型編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
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

// 取得Procedure執行日期
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

// 取得病人所有人工髖關節置換手術
define "Hip Arthroplasty Procedures":
  "All Procedures" P
    where "IsHipArthroplastyProcedure"(P)

// ===== 傷口感染判斷 =====

// 判斷Procedure是否為傷口處理手術 (48004C, 48005C, 48006C)
define function "IsWoundDebridementProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            C.code = '48004C'
            or C.code = '48005C'
            or C.code = '48006C'
          )
    )

// 判斷Condition是否為感染相關診斷
define function "IsInfectionDiagnosis"(condition Condition):
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

// 取得MedicationRequest的結束日期
define function "GetMedicationEndDate"(medication MedicationRequest):
  Coalesce(
    end of (medication.dosageInstruction[0].timing.repeat.bounds as Period),
    medication.authoredOn
  )

// 判斷術後是否有使用抗生素（術後7日後）
define function "HasPostoperativeAntibioticAfter7Days"(surgeryDate DateTime):
  exists(
    "All Medication Requests" M
      where "IsAntibioticMedication"(M)
        and "GetMedicationEndDate"(M) is not null
        and days between surgeryDate and "GetMedicationEndDate"(M) >= "Minimum Antibiotic Interval Days"
  )

// 計算90天監測期間
define function "Get90DayMonitoringPeriod"(surgeryDate DateTime):
  Interval[surgeryDate, surgeryDate + "Monitoring Period Days" days]

// 判斷90天內是否有傷口感染
define function "HasWoundInfectionWithin90Days"(surgeryDate DateTime):
  let monitoringPeriod: "Get90DayMonitoringPeriod"(surgeryDate),
      // 條件1：有傷口處理手術
      hasWoundDebridement: exists(
        "All Procedures" P
          where "IsWoundDebridementProcedure"(P)
            and "GetProcedureDate"(P) during monitoringPeriod
      ),
      // 條件2：有感染診斷
      hasInfectionDiagnosis: exists(
        "All Conditions" C
          where "IsInfectionDiagnosis"(C)
            and (
              exists(
                "All Inpatient Encounters" union "All Outpatient Encounters" E
                  where C.encounter.reference = 'Encounter/' + E.id
                    and start of E.period during monitoringPeriod
              )
            )
      ),
      // 條件3：術後7日後有抗生素使用
      hasPostopAntibiotic: "HasPostoperativeAntibioticAfter7Days"(surgeryDate)
  return
    (hasWoundDebridement or hasInfectionDiagnosis)
      and hasPostopAntibiotic

// ===== 分母定義（依期間）=====

// 取得期間內的人工髖關節置換手術
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

// 判斷是否有傷口感染（針對特定期間）
define function "HasWoundInfectionInPeriod"(period Interval<DateTime>):
  exists(
    "GetHipArthroplastyInPeriod"(period) P
      where "HasWoundInfectionWithin90Days"("GetProcedureDate"(P))
  )

// 分子（全年）
define "Numerator":
  if "HasWoundInfectionInPeriod"("Measurement Period") then 1 else 0

// 分子（季度）
define "Numerator Quarterly":
  "Quarterly Periods" P
    return if "HasWoundInfectionInPeriod"(P) then 1 else 0

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
        numer: if "HasWoundInfectionInPeriod"(P) then 1 else 0
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
    total_outpatient_encounters: Count("All Outpatient Encounters" E where start of E.period during "Measurement Period"),
    total_hip_arthroplasty_procedures: Count(hipSurgeries),
    patients_with_wound_infection: "Numerator",
    patients_without_wound_infection: "Denominator" - "Numerator"
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

// 傷口感染統計
define "Wound Infection Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      infectionsWithDebridement: hipSurgeries P 
        where "HasWoundInfectionWithin90Days"("GetProcedureDate"(P))
          and exists(
            "All Procedures" Proc
              where "IsWoundDebridementProcedure"(Proc)
                and "GetProcedureDate"(Proc) during "Get90DayMonitoringPeriod"("GetProcedureDate"(P))
          ),
      infectionsWithDiagnosis: hipSurgeries P
        where "HasWoundInfectionWithin90Days"("GetProcedureDate"(P))
          and exists(
            "All Conditions" C
              where "IsInfectionDiagnosis"(C)
          )
  return Tuple {
    total_wound_infections: "Numerator",
    infections_with_wound_debridement: Count(infectionsWithDebridement),
    infections_with_infection_diagnosis: Count(infectionsWithDiagnosis),
    infection_rate_percent: "Indicator Rate"
  }

// 抗生素使用統計
define "Antibiotic Usage Statistics":
  let hipSurgeries: "GetHipArthroplastyInPeriod"("Measurement Period"),
      surgeriesWithAntibiotics: hipSurgeries P
        where "HasPostoperativeAntibioticAfter7Days"("GetProcedureDate"(P))
  return Tuple {
    total_procedures_with_postop_antibiotics: Count(surgeriesWithAntibiotics),
    antibiotic_usage_rate: 
      if Count(hipSurgeries) > 0
        then Round(Count(surgeriesWithAntibiotics) / Count(hipSurgeries) * 100, 2)
        else null
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
    indicator_name: '人工髖關節置換手術後九十日以內傷口感染率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測人工髖關節置換手術後傷口感染率，以評估手術品質和感染控制措施的有效性',
    
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
    
    // 傷口感染統計
    wound_infection_statistics: "Wound Infection Statistics",
    
    // 抗生素使用統計
    antibiotic_usage_statistics: "Antibiotic Usage Statistics",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
