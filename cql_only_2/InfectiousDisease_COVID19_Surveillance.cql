library InfectiousDisease_COVID19_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 新冠病毒監測系統
// 功能：追蹤COVID-19案例，支援 Episode 邏輯（30天內合併為一次）

parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

context Patient

// ICD-10-CM COVID-19 代碼列表
define "ICD10 COVID Codes": {
  'U07.1', 'U07.2'
}

// SNOMED CT COVID-19 代碼列表
define "SNOMED COVID Codes": {
  '840539006', '840544004', '882784691000119100', '1240581000000104',
  '1240751000000100', '870588003', '1119302008'
}

// LOINC 實驗室檢驗代碼列表
define "LOINC COVID Lab Codes": {
  '94500-6', '94559-2', '94845-3', '97097-0', '94558-4',
  '94563-4', '94564-2', '94762-2', '94533-7', '94640-0',
  '94645-9', '94315-9', '94531-1', '94764-8', '94745-7'
}

// 所有COVID-19診斷條件
define "COVID19 Diagnosis Conditions":
  [Condition] C
    where exists (
      C.code.coding CD
        where (
          (CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm' and CD.code.value in "ICD10 COVID Codes")
          or (CD.system.value = 'http://snomed.info/sct' and CD.code.value in "SNOMED COVID Codes")
        )
    )

// 所有COVID-19實驗室檢驗
define "COVID19 Lab Results":
  [Observation] Lab
    where Lab.status.value in {'final', 'amended', 'corrected'}
      and Lab.value is not null
      and exists (
        Lab.code.coding LC
          where LC.system.value = 'http://loinc.org'
          and LC.code.value in "LOINC COVID Lab Codes"
      )

// 所有就醫記錄
define "All Encounters":
  [Encounter] E
    where E.status.value = 'finished'

// 合併所有COVID-19相關事件
define "All COVID19 Events":
  (
    "COVID19 Diagnosis Conditions" C
      return {
        eventDate: C.recordedDate.value,
        eventType: 'Diagnosis',
        codeValue: First(C.code.coding).code.value,
        codeDisplay: First(C.code.coding).display.value,
        encounterId: C.encounter.reference.value
      }
  )
  union
  (
    "COVID19 Lab Results" L
      return {
        eventDate: L.issued.value,
        eventType: 'Laboratory',
        codeValue: First(L.code.coding).code.value,
        codeDisplay: First(L.code.coding).display.value,
        encounterId: L.encounter.reference.value
      }
  )

// 取得事件對應的就醫記錄
define function "GetEncounterForEvent"(encounterId String):
  First(
    "All Encounters" E
      where E.id.value = Last(Split(encounterId, '/'))
  )

// 判斷是否為住院
define function "IsInpatientEncounter"(encounter Encounter):
  encounter.class.code.value = 'IMP'

// 計算 Episode 結束日期
define function "CalculateEpisodeEndDate"(eventDate DateTime, encounter Encounter):
  if encounter is not null and "IsInpatientEncounter"(encounter) then
    Coalesce(encounter.period.end.value, encounter.period.start.value) + 30 days
  else
    eventDate + 30 days

// 排序所有事件
define "Sorted COVID19 Events":
  "All COVID19 Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次
define "Unique COVID19 Episodes":
  "Sorted COVID19 Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent.encounterId),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      priorEventsInSameEpisode: 
        "Sorted COVID19 Events" PriorEvent
          where PriorEvent.eventDate < CurrentEvent.eventDate
            and PriorEvent.eventDate >= (CurrentEvent.eventDate - ("Lookback Days" * 1 day))
            and difference in days between PriorEvent.eventDate and CurrentEvent.eventDate <= 30
    where Count(priorEventsInSameEpisode) = 0
    return {
      episodeStartDate: CurrentEvent.eventDate,
      episodeEndDate: episodeEnd,
      eventType: CurrentEvent.eventType,
      codeValue: CurrentEvent.codeValue,
      codeDisplay: CurrentEvent.codeDisplay,
      encounter: encounter,
      encounterId: CurrentEvent.encounterId
    }

// 計算年齡
define function "CalculateAgeAtEvent"(eventDate DateTime):
  AgeInYearsAt(eventDate)

// 取得性別
define "Patient Gender":
  Patient.gender.value

// 判斷就醫類型
define function "GetEncounterType"(encounter Encounter):
  if encounter is null then 'Unknown'
  else
    case
      when encounter.class.code.value = 'IMP' then 'Inpatient'
      when encounter.class.code.value = 'EMER' then 'Emergency'
      when encounter.class.code.value = 'AMB' then 'Outpatient'
      else 'Other'
    end

// 判斷病毒/檢驗種類
define function "DetermineTestType"(codeValue String, codeDisplay String):
  if codeDisplay is null then 'Unknown'
  else
    case
      when codeValue in {'94500-6', '94559-2', '94845-3', '94533-7', '94640-0', '94645-9', '94315-9', '94531-1'} then 'PCR/RNA'
      when codeValue in {'97097-0', '94558-4'} then 'Antigen'
      when codeValue in {'94563-4', '94564-2', '94762-2'} then 'Antibody'
      when codeValue = '94745-7' then 'Ct Value'
      when codeValue = '94764-8' then 'Sequencing'
      when PositionOf('sars', codeDisplay) >= 0 or PositionOf('SARS', codeDisplay) >= 0 or PositionOf('covid', codeDisplay) >= 0 or PositionOf('COVID', codeDisplay) >= 0 then 'SARS-CoV-2'
      else codeDisplay
    end

// 最終輸出結果
define "COVID19 Surveillance Results":
  "Unique COVID19 Episodes" Episode
    return {
      patientID: Patient.id.value,
      eventDate: ToString(Episode.episodeStartDate),
      episodeEndDate: ToString(Episode.episodeEndDate),
      age: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      gender: "Patient Gender",
      encounterType: "GetEncounterType"(Episode.encounter),
      testType: "DetermineTestType"(Episode.codeValue, Episode.codeDisplay),
      eventType: Episode.eventType,
      diagnosisCode: Episode.codeValue,
      diagnosisName: Episode.codeDisplay
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique COVID19 Episodes")

define "Episode Count By Gender":
  {
    male: Count("Unique COVID19 Episodes" E where "Patient Gender" = 'male'),
    female: Count("Unique COVID19 Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    outpatient: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = 'Outpatient'),
    emergency: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = 'Emergency'),
    inpatient: Count("Unique COVID19 Episodes" E where "GetEncounterType"(E.encounter) = 'Inpatient')
  }
