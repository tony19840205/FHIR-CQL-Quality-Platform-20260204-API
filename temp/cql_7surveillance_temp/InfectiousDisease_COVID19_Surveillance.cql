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
// 值集定義
// ============================================

valueset "COVID19 ICD10 Codes": {
  "ICD10 COVID-19",
  "ICD10 COVID-19 suspected"
}

valueset "COVID19 SNOMED Codes": {
  "SNOMED COVID-19",
  "SNOMED SARS-CoV-2 infection",
  "SNOMED COVID-19 pneumonia",
  "SNOMED SARS-CoV-2 detected",
  "SNOMED COVID-19 confirmed",
  "SNOMED COVID-19 acute respiratory distress",
  "SNOMED Post-COVID-19 condition",
  "SNOMED Asymptomatic COVID-19"
}

valueset "COVID19 Lab Codes": {
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

valueset "Encounter Type Codes": {
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
  [Condition: "COVID19 ICD10 Codes"]
    union [Condition: "COVID19 SNOMED Codes"]

// 所有新冠病毒實驗室檢驗 (Observation resources)
define "COVID19 Lab Results":
  [Observation: "COVID19 Lab Codes"] Lab
    where Lab.status in {'final', 'amended', 'corrected'}
      and Lab.value is not null

// 所有就醫記錄 (無時間限制)
define "All Encounters":
  [Encounter] E
    where E.status = 'finished'

// 合併所有新冠病毒相關事件 (診斷 + 檢驗)
define "All COVID19 Events":
  (
    "COVID19 Diagnosis Conditions" C
      return Tuple {
        eventDate: Coalesce(C.onset as FHIR.dateTime, C.recordedDate),
        eventType: 'Diagnosis',
        code: C.code,
        encounterId: C.encounter.reference
      }
  )
  union
  (
    "COVID19 Lab Results" L
      return Tuple {
        eventDate: Coalesce(L.effective as FHIR.dateTime, L.issued),
        eventType: 'Laboratory',
        code: L.code,
        encounterId: L.encounter.reference
      }
  )

// 取得事件對應的就醫記錄
define function "GetEncounterForEvent"(event Tuple { eventDate DateTime, eventType String, code Concept, encounterId String }):
  First(
    "All Encounters" E
      where 'Encounter/' + E.id = event.encounterId
  )

// 取得就醫記錄的結束日期 (住院用)
define function "GetEncounterEndDate"(encounter Encounter):
  Coalesce(
    encounter.period.end,
    encounter.period.start
  )

// 判斷是否為住院
define function "IsInpatientEncounter"(encounter Encounter):
  encounter.class ~ "ActCode Inpatient"

// ============================================
// Episode 邏輯：30天內事件合併（住院延長）
// ============================================

// 計算 Episode 結束日期：確診日 + 30天，若有住院則為出院日 + 30天
define function "CalculateEpisodeEndDate"(eventDate DateTime, encounter Encounter):
  if "IsInpatientEncounter"(encounter) then
    "GetEncounterEndDate"(encounter) + 30 days
  else
    eventDate + 30 days

// 排序所有事件（按時間）
define "Sorted COVID19 Events":
  "All COVID19 Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次 (Episode Window Logic)
define "Unique COVID19 Episodes":
  "Sorted COVID19 Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      // 檢查前面是否有事件在同一 Episode 內 (Lookback)
      priorEventsInSameEpisode: 
        "Sorted COVID19 Events" PriorEvent
          where PriorEvent.eventDate < CurrentEvent.eventDate
            and PriorEvent.eventDate >= (CurrentEvent.eventDate - ("Lookback Days" days)
            and difference in days between PriorEvent.eventDate and CurrentEvent.eventDate <= 30
    // 只保留新 Episode 的首次事件
    where Count(priorEventsInSameEpisode) = 0
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

// 計算年齡（以事件發生時為準）
define function "CalculateAgeAtEvent"(eventDate DateTime):
  AgeInYearsAt(eventDate)

// 取得性別
define "Patient Gender":
  Patient.gender.value

// 判斷就醫類型（門診/急診/住院）
define function "GetEncounterType"(encounter Encounter):
  case
    when encounter.class ~ "ActCode Inpatient" then '住院'
    when encounter.class ~ "ActCode Emergency" then '急診'
    when encounter.class ~ "ActCode Outpatient" then '門診'
    else '其他'
  end

// 判斷病毒種類（標準化：會從 code 或 display 嘗試判斷常見病毒）
define function "DetermineVirusType"(code Concept):
  let firstCoding: Coalesce(code.coding[0], {})
  let display: ToLower(Coalesce(firstCoding.display.value, ''))
  let codeValue: Coalesce(firstCoding.code.value, '')
  case
    when codeValue in {
      '94500-6','94559-2','94845-3','97097-0','94558-4','94563-4','94564-2','94762-2','94533-7','94640-0','94645-9'
    } or display contains 'sars' or display contains 'covid' then 'SARS-CoV-2'
    when display contains 'influenza a' then 'Influenza A'
    when display contains 'influenza b' then 'Influenza B'
    when display contains 'influenza' then 'Influenza'
    when display contains 'rotavirus' then 'Rotavirus'
    when display contains 'norovirus' or display contains 'norwalk' then 'Norovirus'
    when display contains 'adenovirus' then 'Adenovirus'
    when display contains 'enterovirus' or display contains 'coxsackie' or display contains 'echovirus' then 'Enterovirus'
    else Coalesce(firstCoding.display.value, firstCoding.code.value)
  end

// 最終輸出結果
define "COVID19 Surveillance Results":
  "Unique COVID19 Episodes" Episode
    return Tuple {
      患者ID: Patient.id,
      事件日期: ToString(Episode.episodeStartDate),
      Episode結束日期: ToString(Episode.episodeEndDate),
      年齡: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      性別: "Patient Gender",
      就醫類型: "GetEncounterType"(Episode.encounter),
      病毒種類: "DetermineVirusType"(Episode.code),
      事件類型: Episode.eventType,
      診斷代碼: Episode.code.coding[0].code.value,
      診斷名稱: Episode.code.coding[0].display.value
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique COVID19 Episodes")

define "Episode Count By Gender":
  {
    男性: Count("Unique COVID19 Episodes" E where "Patient Gender" = 'male'),
    女性: Count("Unique COVID19 Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    門診: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    急診: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    住院: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }
