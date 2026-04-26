library InfectiousDisease_COVID19_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD-10-CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// 參數定義
parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

// ============================================
// 新冠病毒相關代碼定義 (圖一 & 圖二)
// ============================================

// ICD-10-CM 代碼
code "ICD10 COVID-19": 'U07.1' from "ICD-10-CM" display 'COVID-19'
code "ICD10 COVID-19 suspected": 'U07.2' from "ICD-10-CM" display 'COVID-19, virus not identified'

// SNOMED CT 代碼
code "SNOMED COVID-19": '840539006' from "SNOMEDCT" display 'Disease caused by Severe acute respiratory syndrome coronavirus 2'
code "SNOMED SARS-CoV-2 infection": '840544004' from "SNOMEDCT" display 'Suspected disease caused by Severe acute respiratory coronavirus 2'
code "SNOMED COVID-19 pneumonia": '882784691000119100' from "SNOMEDCT" display 'Pneumonia caused by Severe acute respiratory syndrome coronavirus 2'
code "SNOMED SARS-CoV-2 detected": '1240581000000104' from "SNOMEDCT" display 'Severe acute respiratory syndrome coronavirus 2 detected'
code "SNOMED COVID-19 confirmed": '1240751000000100' from "SNOMEDCT" display 'Coronavirus disease 19 caused by Severe acute respiratory syndrome coronavirus 2 confirmed by laboratory test'
code "SNOMED COVID-19 acute respiratory distress": '870588003' from "SNOMEDCT" display 'Acute respiratory distress syndrome caused by Severe acute respiratory syndrome coronavirus 2'
code "SNOMED Post-COVID-19 condition": '1119302008' from "SNOMEDCT" display 'Acute disease caused by Severe acute respiratory syndrome coronavirus 2'
code "SNOMED Asymptomatic COVID-19": '1240751000000100' from "SNOMEDCT" display 'Asymptomatic Coronavirus disease 19'

// LOINC 實驗室檢驗代碼
code "LOINC SARS-CoV-2 RNA PCR": '94500-6' from "LOINC" display 'SARS-CoV-2 (COVID-19) RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC SARS-CoV-2 RNA Resp": '94559-2' from "LOINC" display 'SARS-CoV-2 (COVID-19) RNA [Presence] in Respiratory specimen by Sequencing'
code "LOINC SARS-CoV-2 RNA Any": '94845-3' from "LOINC" display 'SARS-CoV-2 (COVID-19) RNA [Presence] in Unspecified specimen by NAA with probe detection'
code "LOINC SARS-CoV-2 Ag Rapid": '97097-0' from "LOINC" display 'SARS-CoV-2 (COVID-19) Ag [Presence] in Upper respiratory specimen by Rapid immunoassay'
code "LOINC SARS-CoV-2 Ag": '94558-4' from "LOINC" display 'SARS-CoV-2 (COVID-19) Ag [Presence] in Respiratory specimen by Rapid immunoassay'
code "LOINC SARS-CoV-2 Ab IgG": '94563-4' from "LOINC" display 'SARS-CoV-2 (COVID-19) IgG Ab [Presence] in Serum or Plasma by Immunoassay'
code "LOINC SARS-CoV-2 Ab IgM": '94564-2' from "LOINC" display 'SARS-CoV-2 (COVID-19) IgM Ab [Presence] in Serum or Plasma by Immunoassay'
code "LOINC SARS-CoV-2 Ab": '94762-2' from "LOINC" display 'SARS-CoV-2 (COVID-19) Ab [Presence] in Serum or Plasma by Immunoassay'
code "LOINC SARS-CoV-2 N gene": '94533-7' from "LOINC" display 'SARS-CoV-2 (COVID-19) N gene [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC SARS-CoV-2 ORF1ab": '94559-2' from "LOINC" display 'SARS-CoV-2 (COVID-19) ORF1ab region [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC SARS-CoV-2 S gene": '94640-0' from "LOINC" display 'SARS-CoV-2 (COVID-19) S gene [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC SARS-CoV-2 RdRp gene": '94645-9' from "LOINC" display 'SARS-CoV-2 (COVID-19) RdRp gene [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC SARS-CoV-2 E gene": '94315-9' from "LOINC" display 'SARS-CoV-2 (COVID-19) E gene [Presence] in Unspecified specimen by NAA with probe detection'
code "LOINC COVID-19 panel": '94531-1' from "LOINC" display 'SARS-CoV-2 (COVID-19) RNA panel - Respiratory specimen by NAA with probe detection'
code "LOINC SARS-CoV-2 culture": '94764-8' from "LOINC" display 'SARS-CoV-2 (COVID-19) whole genome [Nucleotide sequence] in Isolate by Sequencing'
code "LOINC SARS-CoV-2 Ct value": '94745-7' from "LOINC" display 'SARS-CoV-2 (COVID-19) RNA [Cycle Threshold #] in Respiratory specimen by NAA with probe detection'

// ActCode 就醫類型
code "ActCode Outpatient": 'AMB' from "ActCode" display 'Ambulatory/Outpatient'
code "ActCode Emergency": 'EMER' from "ActCode" display 'Emergency'
code "ActCode Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'

// ============================================
// 值集定義（展開式）
// ============================================

define "COVID19 ICD10 Codes":
  {
    "ICD10 COVID-19",
    "ICD10 COVID-19 suspected"
  }

define "COVID19 SNOMED Codes":
  {
    "SNOMED COVID-19",
    "SNOMED SARS-CoV-2 infection",
    "SNOMED COVID-19 pneumonia",
    "SNOMED SARS-CoV-2 detected",
    "SNOMED COVID-19 confirmed",
    "SNOMED COVID-19 acute respiratory distress",
    "SNOMED Post-COVID-19 condition",
    "SNOMED Asymptomatic COVID-19"
  }

define "COVID19 Lab Codes":
  {
    "LOINC SARS-CoV-2 RNA PCR",
    "LOINC SARS-CoV-2 RNA Resp",
    "LOINC SARS-CoV-2 RNA Any",
    "LOINC SARS-CoV-2 Ag Rapid",
    "LOINC SARS-CoV-2 Ag",
    "LOINC SARS-CoV-2 Ab IgG",
    "LOINC SARS-CoV-2 Ab IgM",
    "LOINC SARS-CoV-2 Ab",
    "LOINC SARS-CoV-2 N gene",
    "LOINC SARS-CoV-2 ORF1ab",
    "LOINC SARS-CoV-2 S gene",
    "LOINC SARS-CoV-2 RdRp gene",
    "LOINC SARS-CoV-2 E gene",
    "LOINC COVID-19 panel",
    "LOINC SARS-CoV-2 culture",
    "LOINC SARS-CoV-2 Ct value"
  }

define "Encounter Type Codes":
  {
    "ActCode Outpatient",
    "ActCode Emergency",
    "ActCode Inpatient"
  }

// ============================================
// 核心邏輯：患者與事件定義
// ============================================

context Patient

// 所有新冠病毒診斷條件 (Condition resources)
define "COVID19 Diagnosis Conditions":
  [Condition] C
    where exists (C.code.coding Coding 
      where Coding.code in { 'U07.1', 'U07.2', '840539006', '840544004', '882784691000119100', '1240581000000104', '1240751000000100', '870588003', '1119302008' })

// 所有新冠病毒實驗室檢驗 (Observation resources)
define "COVID19 Lab Results":
  [Observation] Lab
    where exists (Lab.code.coding coding where coding in "COVID19 Lab Codes")
      and Lab.status in { 'final', 'amended', 'corrected' }
      and Lab.value is not null

// 所有就醫記錄 (無時間限制)
define "All Encounters":
  [Encounter]

// 合併所有新冠病毒相關事件 (診斷 + 檢驗)
define "All COVID19 Events":
  (
    "COVID19 Diagnosis Conditions" C
      return Tuple {
        eventDate: Coalesce(FHIRHelpers.ToDateTime(C.onset as FHIR.dateTime), FHIRHelpers.ToDateTime(C.recordedDate)),
        eventType: 'Diagnosis',
        code: C.code,
        encounterId: FHIRHelpers.ToString(C.encounter.reference)
      }
  )
  union
  (
    "COVID19 Lab Results" L
      return Tuple {
        eventDate: Coalesce(FHIRHelpers.ToDateTime(L.effective as FHIR.dateTime), FHIRHelpers.ToDateTime(L.issued)),
        eventType: 'Laboratory',
        code: L.code,
        encounterId: FHIRHelpers.ToString(L.encounter.reference)
      }
  )

// 取得事件對應的就醫記錄
define function "GetEncounterForEvent"(eventParam Tuple { eventDate DateTime, eventType String, code FHIR.CodeableConcept, encounterId String }):
  if eventParam.encounterId is null then null
  else 
    First(
      [Encounter] E
        where ('Encounter/' + E.id.value) = eventParam.encounterId
    )

// 取得就醫記錄的結束日期 (住院用)
define function "GetEncounterEndDate"(encounter Encounter):
  Coalesce(
    encounter.period.end,
    encounter.period.start
  )

// 判斷是否為住院
define function "IsInpatientEncounter"(encounter Encounter):
  if encounter is null or encounter.class is null or encounter.class.code is null then false
  else encounter.class.code = 'IMP'

// ============================================
// Episode 邏輯：30天內事件合併（住院延長）
// ============================================

// 計算 Episode 結束日期：確診日 + 30天，若有住院則為出院日 + 30天
define function "CalculateEpisodeEndDate"(eventDate DateTime, encounter Encounter):
  if "IsInpatientEncounter"(encounter) then
    "GetEncounterEndDate"(encounter) + 30 day
  else
    eventDate + 30 day

// 排序所有事件（按時間）
define "Sorted COVID19 Events":
  "All COVID19 Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次 (Episode Window Logic)
define "Unique COVID19 Episodes":
  "Sorted COVID19 Events" CurrentEvent
    let encounter: "GetEncounterForEvent"(CurrentEvent),
        episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
        priorEventsInSameEpisode: 
          "Sorted COVID19 Events" PriorEvent
            where PriorEvent.eventDate < CurrentEvent.eventDate
              and difference in days between PriorEvent.eventDate and CurrentEvent.eventDate <= 30
    where not exists(priorEventsInSameEpisode)
    return Tuple {
      episodeStartDate: CurrentEvent.eventDate,
      episodeEndDate: episodeEnd,
      eventType: CurrentEvent.eventType,
      code: CurrentEvent.code,
      encounter: encounter,
      encounterId: CurrentEvent.encounterId
    }

// ============================================
// 輸出結果：年齡、性別、就醫類型
// ============================================

// 計算年齡（以事件發生時為準）- 簡化版本直接使用Patient
define function "CalculateAgeAtEvent"(eventDate DateTime):
  if Patient is null or Patient.birthDate is null or eventDate is null then null
  else years between FHIRHelpers.ToDate(Patient.birthDate) and eventDate

// 取得性別 - 簡化版本直接使用Patient
define "PatientGender":
  FHIRHelpers.ToString(Patient.gender)

// 患者ID（用於輸出）
define "PatientID":
  FHIRHelpers.ToString(Patient.id)

// 判斷就醫類型（門診/急診/住院）
define function "GetEncounterType"(encounter Encounter):
  if encounter is null or encounter.class is null then '其他'
  else if encounter.class.code = 'IMP' then '住院'
  else if encounter.class.code = 'EMER' then '急診'
  else if encounter.class.code = 'AMB' then '門診'
  else '其他'

// 判斷病毒種類（標準化：簡化版本使用第一個code）
define function "DetermineVirusType"(codeParam Concept):
  'Unknown'

// 最終輸出結果
define "COVID19 Surveillance Results":
  "Unique COVID19 Episodes" Episode
    return Tuple {
      PatientID: "PatientID",
      EventDate: ToString(Episode.episodeStartDate),
      EpisodeEndDate: ToString(Episode.episodeEndDate),
      Age: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      Gender: "PatientGender",
      EncounterType: "GetEncounterType"(Episode.encounter),
      VirusType: "DetermineVirusType"(Episode.code),
      EventType: Episode.eventType,
      DiagnosisCode: 
        if Episode.code is null then 'N/A'
        else if not exists(Episode.code.coding) then 'N/A'
        else Coalesce(First(Episode.code.coding).code, 'Unknown'),
      DiagnosisName: 
        if Episode.code is null then 'N/A'
        else if not exists(Episode.code.coding) then 'N/A'
        else Coalesce(First(Episode.code.coding).display, 'Unknown')
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique COVID19 Episodes")

define "Episode Count By Gender":
  Tuple {
    Male: Count("Unique COVID19 Episodes" E where "PatientGender" = 'male'),
    Female: Count("Unique COVID19 Episodes" E where "PatientGender" = 'female'),
    Unknown: Count("Unique COVID19 Episodes" E where "PatientGender" is null)
  }

define "Episode Count By Encounter Type":
  Tuple {
    Outpatient: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    Emergency: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    Inpatient: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }

// ============================================
// 調試輸出
// ============================================

define "Debug All Conditions Count":
  Count([Condition])

define "Debug COVID19 Conditions Count":
  Count("COVID19 Diagnosis Conditions")

define "Debug Sample Condition Codes":
  [Condition] C
    return Tuple {
      conditionId: C.id,
      codes: C.code.coding Coding return Tuple { system: Coding.system, code: Coding.code, display: Coding.display }
    }
