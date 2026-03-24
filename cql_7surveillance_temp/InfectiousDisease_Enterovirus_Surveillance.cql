library InfectiousDisease_Enterovirus_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD-10-CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD-9-CM": 'http://hl7.org/fhir/sid/icd-9-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// 參數定義
parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

// ============================================
// 腸病毒相關代碼定義 (圖一 & 圖二)
// ============================================

// ICD-9-CM 代碼
code "ICD9 Enterovirus infection 008.67": '008.67' from "ICD-9-CM" display 'Enterovirus infection'
code "ICD9 Intestinal infection enterovirus 047": '047' from "ICD-9-CM" display 'Intestinal infection due to enterovirus'
code "ICD9 Hand foot mouth disease 074.0": '074.0' from "ICD-9-CM" display 'Hand, foot, and mouth disease'
code "ICD9 Herpangina 074.0": '074.0' from "ICD-9-CM" display 'Herpangina'
code "ICD9 Acute epidemic hemorrhagic conjunctivitis 074.1": '074.1' from "ICD-9-CM" display 'Epidemic hemorrhagic conjunctivitis'
code "ICD9 Coxsackie carditis 074.2": '074.2' from "ICD-9-CM" display 'Coxsackie carditis'
code "ICD9 Coxsackie pericarditis 074.21": '074.21' from "ICD-9-CM" display 'Coxsackie pericarditis'
code "ICD9 Coxsackie endocarditis 074.22": '074.22' from "ICD-9-CM" display 'Coxsackie endocarditis'
code "ICD9 Coxsackie myocarditis 074.23": '074.23' from "ICD-9-CM" display 'Coxsackie myocarditis'
code "ICD9 Hand foot mouth disease 074.3": '074.3' from "ICD-9-CM" display 'Hand, foot, and mouth disease'
code "ICD9 Herpangina 074.8": '074.8' from "ICD-9-CM" display 'Other specified diseases due to Coxsackie virus'
code "ICD9 Adenovirus infection 079.1": '079.1' from "ICD-9-CM" display 'Adenovirus infection'
code "ICD9 Coxsackie virus infection 079.2": '079.2' from "ICD-9-CM" display 'Coxsackie virus infection'

// ICD-10-CM 代碼 (腸病毒)
code "ICD10 Enteroviral infection unspecified B08.4": 'B08.4' from "ICD-10-CM" display 'Enteroviral vesicular stomatitis with exanthem'
code "ICD10 Enteroviral vesicular pharyngitis B08.5": 'B08.5' from "ICD-10-CM" display 'Enteroviral vesicular pharyngitis'
code "ICD10 Herpangina 074.0": '074.0' from "ICD-10-CM" display 'Herpangina'
code "ICD10 Hand foot mouth disease 074.3": '074.3' from "ICD-10-CM" display 'Hand, foot, and mouth disease'

// SNOMED CT 代碼
code "SNOMED Enterovirus infection": '23822004' from "SNOMEDCT" display 'Enterovirus infection'
code "SNOMED Hand foot mouth disease": '52320007' from "SNOMEDCT" display 'Hand, foot and mouth disease'
code "SNOMED Herpangina": '420967008' from "SNOMEDCT" display 'Herpangina'
code "SNOMED Coxsackie virus infection": '186522001' from "SNOMEDCT" display 'Coxsackie virus infection'
code "SNOMED Echovirus infection": '186531003' from "SNOMEDCT" display 'Echovirus infection'
code "SNOMED Enteroviral meningitis": '192678001' from "SNOMEDCT" display 'Enteroviral meningitis'
code "SNOMED Enteroviral encephalitis": '192653009' from "SNOMEDCT" display 'Enteroviral encephalitis'
code "SNOMED Enteroviral carditis": '49168009' from "SNOMEDCT" display 'Enteroviral carditis'
code "SNOMED Enterovirus 71 infection": '426904006' from "SNOMEDCT" display 'Infection caused by Human enterovirus 71'

// LOINC 實驗室檢驗代碼
code "LOINC Enterovirus RNA PCR": '29505-3' from "LOINC" display 'Enterovirus RNA [Presence] in Specimen by NAA with probe detection'
code "LOINC Enterovirus 71 RNA": '31712-0' from "LOINC" display 'Enterovirus 71 RNA [Presence] in Specimen by NAA with probe detection'
code "LOINC Enterovirus Ab": '22239-8' from "LOINC" display 'Enterovirus Ab [Presence] in Serum'
code "LOINC Enterovirus culture": '548-8' from "LOINC" display 'Enterovirus [Presence] in Specimen by Organism specific culture'
code "LOINC Coxsackie virus Ab": '22242-2' from "LOINC" display 'Coxsackie virus Ab [Presence] in Serum'
code "LOINC Coxsackie A virus": '16308-3' from "LOINC" display 'Coxsackie virus A Ab [Presence] in Serum'
code "LOINC Coxsackie B virus": '16309-1' from "LOINC" display 'Coxsackie virus B Ab [Presence] in Serum'
code "LOINC Echovirus Ab": '22258-8' from "LOINC" display 'Echovirus Ab [Presence] in Serum'

// ActCode 就醫類型
code "ActCode Outpatient": 'AMB' from "ActCode" display 'Ambulatory/Outpatient'
code "ActCode Emergency": 'EMER' from "ActCode" display 'Emergency'
code "ActCode Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'

// ============================================
// 值集定義
// ============================================

valueset "Enterovirus ICD9 Codes": {
  "ICD9 Enterovirus infection 008.67",
  "ICD9 Intestinal infection enterovirus 047",
  "ICD9 Hand foot mouth disease 074.0",
  "ICD9 Herpangina 074.0",
  "ICD9 Acute epidemic hemorrhagic conjunctivitis 074.1",
  "ICD9 Coxsackie carditis 074.2",
  "ICD9 Coxsackie pericarditis 074.21",
  "ICD9 Coxsackie endocarditis 074.22",
  "ICD9 Coxsackie myocarditis 074.23",
  "ICD9 Hand foot mouth disease 074.3",
  "ICD9 Herpangina 074.8",
  "ICD9 Adenovirus infection 079.1",
  "ICD9 Coxsackie virus infection 079.2"
}

valueset "Enterovirus ICD10 Codes": {
  "ICD10 Enteroviral infection unspecified B08.4",
  "ICD10 Enteroviral vesicular pharyngitis B08.5",
  "ICD10 Herpangina 074.0",
  "ICD10 Hand foot mouth disease 074.3"
}

valueset "Enterovirus SNOMED Codes": {
  "SNOMED Enterovirus infection",
  "SNOMED Hand foot mouth disease",
  "SNOMED Herpangina",
  "SNOMED Coxsackie virus infection",
  "SNOMED Echovirus infection",
  "SNOMED Enteroviral meningitis",
  "SNOMED Enteroviral encephalitis",
  "SNOMED Enteroviral carditis",
  "SNOMED Enterovirus 71 infection"
}

valueset "Enterovirus Lab Codes": {
  "LOINC Enterovirus RNA PCR",
  "LOINC Enterovirus 71 RNA",
  "LOINC Enterovirus Ab",
  "LOINC Enterovirus culture",
  "LOINC Coxsackie virus Ab",
  "LOINC Coxsackie A virus",
  "LOINC Coxsackie B virus",
  "LOINC Echovirus Ab"
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

// 所有腸病毒診斷條件 (Condition resources)
define "Enterovirus Diagnosis Conditions":
  [Condition: "Enterovirus ICD9 Codes"]
    union [Condition: "Enterovirus ICD10 Codes"]
    union [Condition: "Enterovirus SNOMED Codes"]

// 所有腸病毒實驗室檢驗 (Observation resources)
define "Enterovirus Lab Results":
  [Observation: "Enterovirus Lab Codes"] Lab
    where Lab.status in {'final', 'amended', 'corrected'}
      and Lab.value is not null

// 所有就醫記錄 (無時間限制)
define "All Encounters":
  [Encounter] E
    where E.status = 'finished'

// 合併所有腸病毒相關事件 (診斷 + 檢驗)
define "All Enterovirus Events":
  (
    "Enterovirus Diagnosis Conditions" C
      return Tuple {
        eventDate: Coalesce(C.onset as FHIR.dateTime, C.recordedDate),
        eventType: 'Diagnosis',
        code: C.code,
        encounterId: C.encounter.reference
      }
  )
  union
  (
    "Enterovirus Lab Results" L
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
define "Sorted Enterovirus Events":
  "All Enterovirus Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次 (Episode Window Logic)
define "Unique Enterovirus Episodes":
  "Sorted Enterovirus Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      // 檢查前面是否有事件在同一 Episode 內 (Lookback)
      priorEventsInSameEpisode: 
        "Sorted Enterovirus Events" PriorEvent
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
    when display contains 'enterovirus' or display contains 'coxsackie' or display contains 'echovirus' then 'Enterovirus'
    when display contains 'hand, foot and mouth' or display contains 'hand foot mouth' then 'Enterovirus'
    when display contains 'adenovirus' then 'Adenovirus'
    when display contains 'rotavirus' then 'Rotavirus'
    when display contains 'norovirus' or display contains 'norwalk' then 'Norovirus'
    else Coalesce(firstCoding.display.value, firstCoding.code.value)
  end

// 最終輸出結果
define "Enterovirus Surveillance Results":
  "Unique Enterovirus Episodes" Episode
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
  Count("Unique Enterovirus Episodes")

define "Episode Count By Gender":
  {
    男性: Count("Unique Enterovirus Episodes" E where "Patient Gender" = 'male'),
    女性: Count("Unique Enterovirus Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    門診: Count("Unique Enterovirus Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    急診: Count("Unique Enterovirus Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    住院: Count("Unique Enterovirus Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }
