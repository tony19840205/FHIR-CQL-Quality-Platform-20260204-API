library InfectiousDisease_AcuteConjunctivitis_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD-9-CM": 'http://hl7.org/fhir/sid/icd-9-cm'
codesystem "ICD-10-CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// 參數定義
parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

// ============================================
// 紅眼症相關代碼定義 (圖一 & 圖二)
// ============================================

// ICD-9-CM 代碼 - 結膜炎
code "ICD9 Conjunctivitis 077": '077' from "ICD-9-CM" display 'Diseases of conjunctiva due to viruses and Chlamydiae'
code "ICD9 Conjunctivitis 077.0": '077.0' from "ICD-9-CM" display 'Inclusion conjunctivitis'
code "ICD9 Epidemic keratoconjunctivitis 077.1": '077.1' from "ICD-9-CM" display 'Epidemic keratoconjunctivitis'
code "ICD9 Pharyngoconjunctival fever 077.2": '077.2' from "ICD-9-CM" display 'Pharyngoconjunctival fever'
code "ICD9 Other adenoviral conjunctivitis 077.3": '077.3' from "ICD-9-CM" display 'Other adenoviral conjunctivitis'
code "ICD9 Epidemic hemorrhagic conjunctivitis 077.4": '077.4' from "ICD-9-CM" display 'Epidemic hemorrhagic conjunctivitis'
code "ICD9 Newcastle conjunctivitis 077.8": '077.8' from "ICD-9-CM" display 'Other viral conjunctivitis'
code "ICD9 Viral conjunctivitis unspecified 077.9": '077.9' from "ICD-9-CM" display 'Unspecified diseases of conjunctiva due to viruses and Chlamydiae'
code "ICD9 Conjunctivitis gonococcal 370.4": '370.4' from "ICD-9-CM" display 'Other and unspecified keratoconjunctivitis'
code "ICD9 Exposure keratoconjunctivitis 370.40": '370.40' from "ICD-9-CM" display 'Keratoconjunctivitis, unspecified'
code "ICD9 Conjunctivitis 372": '372' from "ICD-9-CM" display 'Disorders of conjunctiva'
code "ICD9 Acute conjunctivitis 372.0": '372.0' from "ICD-9-CM" display 'Acute conjunctivitis'
code "ICD9 Acute follicular conjunctivitis 372.00": '372.00' from "ICD-9-CM" display 'Acute conjunctivitis, unspecified'
code "ICD9 Serous conjunctivitis 372.01": '372.01' from "ICD-9-CM" display 'Serous conjunctivitis, except viral'
code "ICD9 Acute follicular conjunctivitis 372.02": '372.02' from "ICD-9-CM" display 'Acute follicular conjunctivitis'
code "ICD9 Other mucopurulent conjunctivitis 372.03": '372.03' from "ICD-9-CM" display 'Other mucopurulent conjunctivitis'
code "ICD9 Pseudomembranous conjunctivitis 372.04": '372.04' from "ICD-9-CM" display 'Pseudomembranous conjunctivitis'
code "ICD9 Acute atopic conjunctivitis 372.05": '372.05' from "ICD-9-CM" display 'Acute atopic conjunctivitis'
code "ICD9 Acute chemical conjunctivitis 372.06": '372.06' from "ICD-9-CM" display 'Acute chemical conjunctivitis'
code "ICD9 Ligneous conjunctivitis 372.71": '372.71' from "ICD-9-CM" display 'Ligneous conjunctivitis'
code "ICD9 Conjunctivitis in other diseases 372.72": '372.72' from "ICD-9-CM" display 'Conjunctivitis in other diseases classified elsewhere'

// ICD-10-CM 代碼 - 紅眼症
code "ICD10 Viral conjunctivitis B30": 'B30' from "ICD-10-CM" display 'Viral conjunctivitis'
code "ICD10 Mucopurulent conjunctivitis H10": 'H10' from "ICD-10-CM" display 'Conjunctivitis'
code "ICD10 Acute conjunctivitis H10.0": 'H10.0' from "ICD-10-CM" display 'Mucopurulent conjunctivitis'
code "ICD10 Acute atopic conjunctivitis H10.1": 'H10.1' from "ICD-10-CM" display 'Acute atopic conjunctivitis'
code "ICD10 Other acute conjunctivitis H10.2": 'H10.2' from "ICD-10-CM" display 'Other acute conjunctivitis'
code "ICD10 Acute conjunctivitis unspecified H10.3": 'H10.3' from "ICD-10-CM" display 'Unspecified acute conjunctivitis'
code "ICD10 Chronic conjunctivitis H10.4": 'H10.4' from "ICD-10-CM" display 'Chronic conjunctivitis'
code "ICD10 Blepharoconjunctivitis H10.5": 'H10.5' from "ICD-10-CM" display 'Blepharoconjunctivitis'
code "ICD10 Other conjunctivitis H10.8": 'H10.8' from "ICD-10-CM" display 'Other conjunctivitis'
code "ICD10 Conjunctivitis unspecified H10.9": 'H10.9' from "ICD-10-CM" display 'Unspecified conjunctivitis'
code "ICD10 Conjunctival hemorrhage H11.3": 'H11.3' from "ICD-10-CM" display 'Conjunctival hemorrhage'
code "ICD10 Epidemic keratoconjunctivitis B30.0": 'B30.0' from "ICD-10-CM" display 'Keratoconjunctivitis due to adenovirus'
code "ICD10 Conjunctivitis due to adenovirus B30.1": 'B30.1' from "ICD-10-CM" display 'Conjunctivitis due to adenovirus'
code "ICD10 Pharyngoconjunctival fever B30.2": 'B30.2' from "ICD-10-CM" display 'Viral pharyngoconjunctivitis'
code "ICD10 Acute epidemic hemorrhagic conjunctivitis B30.3": 'B30.3' from "ICD-10-CM" display 'Acute epidemic hemorrhagic conjunctivitis (enteroviral)'
code "ICD10 Other viral conjunctivitis B30.8": 'B30.8' from "ICD-10-CM" display 'Other viral conjunctivitis'
code "ICD10 Viral conjunctivitis unspecified B30.9": 'B30.9' from "ICD-10-CM" display 'Viral conjunctivitis, unspecified'

// SNOMED CT 代碼
code "SNOMED Acute conjunctivitis": '9826008' from "SNOMEDCT" display 'Conjunctivitis'
code "SNOMED Acute viral conjunctivitis": '51264003' from "SNOMEDCT" display 'Viral conjunctivitis'
code "SNOMED Acute bacterial conjunctivitis": '193889007' from "SNOMEDCT" display 'Bacterial conjunctivitis'
code "SNOMED Acute follicular conjunctivitis": '231977004' from "SNOMEDCT" display 'Acute follicular conjunctivitis'
code "SNOMED Mucopurulent conjunctivitis": '246683000' from "SNOMEDCT" display 'Mucopurulent conjunctivitis'
code "SNOMED Allergic conjunctivitis": '232008001' from "SNOMEDCT" display 'Allergic conjunctivitis'
code "SNOMED Epidemic keratoconjunctivitis": '27901008' from "SNOMEDCT" display 'Epidemic keratoconjunctivitis'
code "SNOMED Adenoviral conjunctivitis": '410692000' from "SNOMEDCT" display 'Adenoviral conjunctivitis'
code "SNOMED Hemorrhagic conjunctivitis": '428562003' from "SNOMEDCT" display 'Hemorrhagic conjunctivitis'
code "SNOMED Pharyngoconjunctival fever": '56905009' from "SNOMEDCT" display 'Pharyngoconjunctival fever'
code "SNOMED Gonococcal conjunctivitis": '37415000' from "SNOMEDCT" display 'Gonococcal conjunctivitis'
code "SNOMED Chlamydial conjunctivitis": '46965007' from "SNOMEDCT" display 'Chlamydial conjunctivitis'
code "SNOMED Inclusion conjunctivitis": '266928009' from "SNOMEDCT" display 'Paratrachoma'
code "SNOMED Chemical conjunctivitis": '21007005' from "SNOMEDCT" display 'Conjunctivitis due to chemical'
code "SNOMED Subconjunctival hemorrhage": '246938007' from "SNOMEDCT" display 'Subconjunctival hemorrhage'
code "SNOMED Red eye": '246777003' from "SNOMEDCT" display 'Red eye'
code "SNOMED Conjunctival hyperemia": '23318009' from "SNOMEDCT" display 'Hyperemia of eye'
code "SNOMED Neonatal conjunctivitis": '70461003' from "SNOMEDCT" display 'Neonatal conjunctivitis'

// LOINC 實驗室檢驗代碼
code "LOINC Conjunctival culture": '626-2' from "LOINC" display 'Bacteria identified in Conjunctiva by Culture'
code "LOINC Adenovirus Ag conjunctiva": '88891-7' from "LOINC" display 'Adenovirus Ag [Presence] in Conjunctiva'
code "LOINC Adenovirus DNA": '6309-8' from "LOINC" display 'Adenovirus DNA [Presence] in Specimen by NAA with probe detection'
code "LOINC Chlamydia trachomatis DNA": '21613-5' from "LOINC" display 'Chlamydia trachomatis DNA [Presence] in Specimen by NAA with probe detection'
code "LOINC Neisseria gonorrhoeae DNA": '21415-5' from "LOINC" display 'Neisseria gonorrhoeae DNA [Presence] in Specimen by NAA with probe detection'
code "LOINC HSV DNA": '5017-9' from "LOINC" display 'Herpes simplex virus DNA [Presence] in Specimen by NAA with probe detection'
code "LOINC Bacterial eye culture": '625-4' from "LOINC" display 'Bacteria identified in Specimen by Culture'
code "LOINC Conjunctival smear": '664-3' from "LOINC" display 'Microscopic observation [Identifier] in Specimen by Gram stain'
code "LOINC Eye pathogen panel": '85827-4' from "LOINC" display 'Carbapenem resistance bla OXA-48-like gene [Presence] by Molecular method'
code "LOINC Adenovirus culture": '548-8' from "LOINC" display 'Adenovirus [Presence] in Specimen by Organism specific culture'
code "LOINC Chlamydia culture conjunctiva": '6345-2' from "LOINC" display 'Chlamydia sp identified in Conjunctiva by Organism specific culture'
code "LOINC Viral conjunctivitis panel": '85613-8' from "LOINC" display 'Respiratory pathogens DNA and RNA panel - Respiratory specimen by NAA with probe detection'
code "LOINC Eye bacterial pathogen": '75756-7' from "LOINC" display 'Bacteria and Fungi identified in Isolate by Sequencing'
code "LOINC Conjunctival cytology": '47527-7' from "LOINC" display 'Cytology report of Tissue Cyto stain'

// ActCode 就醫類型
code "ActCode Outpatient": 'AMB' from "ActCode" display 'Ambulatory/Outpatient'
code "ActCode Emergency": 'EMER' from "ActCode" display 'Emergency'
code "ActCode Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'

// ============================================
// 值集定義
// ============================================

valueset "Acute Conjunctivitis ICD9 Codes": {
  "ICD9 Conjunctivitis 077",
  "ICD9 Conjunctivitis 077.0",
  "ICD9 Epidemic keratoconjunctivitis 077.1",
  "ICD9 Pharyngoconjunctival fever 077.2",
  "ICD9 Other adenoviral conjunctivitis 077.3",
  "ICD9 Epidemic hemorrhagic conjunctivitis 077.4",
  "ICD9 Newcastle conjunctivitis 077.8",
  "ICD9 Viral conjunctivitis unspecified 077.9",
  "ICD9 Conjunctivitis gonococcal 370.4",
  "ICD9 Exposure keratoconjunctivitis 370.40",
  "ICD9 Conjunctivitis 372",
  "ICD9 Acute conjunctivitis 372.0",
  "ICD9 Acute follicular conjunctivitis 372.00",
  "ICD9 Serous conjunctivitis 372.01",
  "ICD9 Acute follicular conjunctivitis 372.02",
  "ICD9 Other mucopurulent conjunctivitis 372.03",
  "ICD9 Pseudomembranous conjunctivitis 372.04",
  "ICD9 Acute atopic conjunctivitis 372.05",
  "ICD9 Acute chemical conjunctivitis 372.06",
  "ICD9 Ligneous conjunctivitis 372.71",
  "ICD9 Conjunctivitis in other diseases 372.72"
}

valueset "Acute Conjunctivitis ICD10 Codes": {
  "ICD10 Viral conjunctivitis B30",
  "ICD10 Mucopurulent conjunctivitis H10",
  "ICD10 Acute conjunctivitis H10.0",
  "ICD10 Acute atopic conjunctivitis H10.1",
  "ICD10 Other acute conjunctivitis H10.2",
  "ICD10 Acute conjunctivitis unspecified H10.3",
  "ICD10 Chronic conjunctivitis H10.4",
  "ICD10 Blepharoconjunctivitis H10.5",
  "ICD10 Other conjunctivitis H10.8",
  "ICD10 Conjunctivitis unspecified H10.9",
  "ICD10 Conjunctival hemorrhage H11.3",
  "ICD10 Epidemic keratoconjunctivitis B30.0",
  "ICD10 Conjunctivitis due to adenovirus B30.1",
  "ICD10 Pharyngoconjunctival fever B30.2",
  "ICD10 Acute epidemic hemorrhagic conjunctivitis B30.3",
  "ICD10 Other viral conjunctivitis B30.8",
  "ICD10 Viral conjunctivitis unspecified B30.9"
}

valueset "Acute Conjunctivitis SNOMED Codes": {
  "SNOMED Acute conjunctivitis",
  "SNOMED Acute viral conjunctivitis",
  "SNOMED Acute bacterial conjunctivitis",
  "SNOMED Acute follicular conjunctivitis",
  "SNOMED Mucopurulent conjunctivitis",
  "SNOMED Allergic conjunctivitis",
  "SNOMED Epidemic keratoconjunctivitis",
  "SNOMED Adenoviral conjunctivitis",
  "SNOMED Hemorrhagic conjunctivitis",
  "SNOMED Pharyngoconjunctival fever",
  "SNOMED Gonococcal conjunctivitis",
  "SNOMED Chlamydial conjunctivitis",
  "SNOMED Inclusion conjunctivitis",
  "SNOMED Chemical conjunctivitis",
  "SNOMED Subconjunctival hemorrhage",
  "SNOMED Red eye",
  "SNOMED Conjunctival hyperemia",
  "SNOMED Neonatal conjunctivitis"
}

valueset "Acute Conjunctivitis Lab Codes": {
  "LOINC Conjunctival culture",
  "LOINC Adenovirus Ag conjunctiva",
  "LOINC Adenovirus DNA",
  "LOINC Chlamydia trachomatis DNA",
  "LOINC Neisseria gonorrhoeae DNA",
  "LOINC HSV DNA",
  "LOINC Bacterial eye culture",
  "LOINC Conjunctival smear",
  "LOINC Eye pathogen panel",
  "LOINC Adenovirus culture",
  "LOINC Chlamydia culture conjunctiva",
  "LOINC Viral conjunctivitis panel",
  "LOINC Eye bacterial pathogen",
  "LOINC Conjunctival cytology"
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

// 所有紅眼症診斷條件 (Condition resources)
define "Acute Conjunctivitis Diagnosis Conditions":
  [Condition: "Acute Conjunctivitis ICD9 Codes"]
    union [Condition: "Acute Conjunctivitis ICD10 Codes"]
    union [Condition: "Acute Conjunctivitis SNOMED Codes"]

// 所有紅眼症實驗室檢驗 (Observation resources)
define "Acute Conjunctivitis Lab Results":
  [Observation: "Acute Conjunctivitis Lab Codes"] Lab
    where Lab.status in {'final', 'amended', 'corrected'}
      and Lab.value is not null

// 所有就醫記錄 (無時間限制)
define "All Encounters":
  [Encounter] E
    where E.status = 'finished'

// 合併所有紅眼症相關事件 (診斷 + 檢驗)
define "All Acute Conjunctivitis Events":
  (
    "Acute Conjunctivitis Diagnosis Conditions" C
      return Tuple {
        eventDate: Coalesce(C.onset as FHIR.dateTime, C.recordedDate),
        eventType: 'Diagnosis',
        code: C.code,
        encounterId: C.encounter.reference
      }
  )
  union
  (
    "Acute Conjunctivitis Lab Results" L
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
define "Sorted Acute Conjunctivitis Events":
  "All Acute Conjunctivitis Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次 (Episode Window Logic)
define "Unique Acute Conjunctivitis Episodes":
  "Sorted Acute Conjunctivitis Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      // 檢查前面是否有事件在同一 Episode 內 (Lookback)
      priorEventsInSameEpisode: 
        "Sorted Acute Conjunctivitis Events" PriorEvent
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
    when display contains 'adenovirus' then 'Adenovirus'
    when display contains 'conjunctivitis' and display contains 'adenovirus' then 'Adenovirus'
    when display contains 'sars' or display contains 'covid' then 'SARS-CoV-2'
    when display contains 'influenza' then 'Influenza'
    when display contains 'enterovirus' or display contains 'coxsackie' or display contains 'echovirus' then 'Enterovirus'
    else Coalesce(firstCoding.display.value, firstCoding.code.value)
  end

// 最終輸出結果
define "Acute Conjunctivitis Surveillance Results":
  "Unique Acute Conjunctivitis Episodes" Episode
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
  Count("Unique Acute Conjunctivitis Episodes")

define "Episode Count By Gender":
  {
    男性: Count("Unique Acute Conjunctivitis Episodes" E where "Patient Gender" = 'male'),
    女性: Count("Unique Acute Conjunctivitis Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    門診: Count("Unique Acute Conjunctivitis Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    急診: Count("Unique Acute Conjunctivitis Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    住院: Count("Unique Acute Conjunctivitis Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }
