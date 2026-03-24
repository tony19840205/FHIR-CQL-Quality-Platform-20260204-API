library InfectiousDisease_Enterovirus_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 腸病毒監測系統
// 功能：追蹤腸病毒案例，支援 Episode 邏輯（30天內合併為一次）

parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

context Patient

// ICD-9-CM 腸病毒代碼列表
define "ICD9 Enterovirus Codes": {
  '008.67', '047', '074.0', '074.1', '074.2', '074.21', '074.22', '074.23',
  '074.3', '074.8', '079.1', '079.2'
}

// ICD-10-CM 腸病毒代碼列表
define "ICD10 Enterovirus Codes": {
  'B08.4', 'B08.5', '074.0', '074.3'
}

// SNOMED CT 腸病毒代碼列表
define "SNOMED Enterovirus Codes": {
  '23822004', '52320007', '420967008', '186522001', '186531003',
  '192678001', '192653009', '49168009', '426904006'
}

// LOINC 實驗室檢驗代碼列表
define "LOINC Enterovirus Lab Codes": {
  '29505-3', '31712-0', '22239-8', '548-8',
  '22242-2', '16308-3', '16309-1', '22258-8'
}

// 所有腸病毒診斷條件
define "Enterovirus Diagnosis Conditions":
  [Condition] C
    where exists (
      C.code.coding CD
        where (
          (CD.system.value = 'http://hl7.org/fhir/sid/icd-9-cm' and CD.code.value in "ICD9 Enterovirus Codes")
          or (CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm' and CD.code.value in "ICD10 Enterovirus Codes")
          or (CD.system.value = 'http://snomed.info/sct' and CD.code.value in "SNOMED Enterovirus Codes")
        )
    )

// 所有腸病毒實驗室檢驗
define "Enterovirus Lab Results":
  [Observation] Lab
    where Lab.status.value in {'final', 'amended', 'corrected'}
      and Lab.value is not null
      and exists (
        Lab.code.coding LC
          where LC.system.value = 'http://loinc.org'
          and LC.code.value in "LOINC Enterovirus Lab Codes"
      )

// 所有就醫記錄
define "All Encounters":
  [Encounter] E
    where E.status.value = 'finished'

// 合併所有腸病毒相關事件
define "All Enterovirus Events":
  (
    "Enterovirus Diagnosis Conditions" C
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
    "Enterovirus Lab Results" L
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
define "Sorted Enterovirus Events":
  "All Enterovirus Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次
define "Unique Enterovirus Episodes":
  "Sorted Enterovirus Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent.encounterId),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      priorEventsInSameEpisode: 
        "Sorted Enterovirus Events" PriorEvent
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

// 判斷病毒種類
define function "DetermineVirusType"(codeDisplay String):
  if codeDisplay is null then 'Unknown'
  else
    case
      when PositionOf('enterovirus', codeDisplay) >= 0 or PositionOf('Enterovirus', codeDisplay) >= 0 then 'Enterovirus'
      when PositionOf('coxsackie', codeDisplay) >= 0 or PositionOf('Coxsackie', codeDisplay) >= 0 then 'Coxsackie'
      when PositionOf('echovirus', codeDisplay) >= 0 or PositionOf('Echovirus', codeDisplay) >= 0 then 'Echovirus'
      when PositionOf('hand', codeDisplay) >= 0 and PositionOf('foot', codeDisplay) >= 0 then 'HFMD'
      when PositionOf('herpangina', codeDisplay) >= 0 or PositionOf('Herpangina', codeDisplay) >= 0 then 'Herpangina'
      when PositionOf('adenovirus', codeDisplay) >= 0 or PositionOf('Adenovirus', codeDisplay) >= 0 then 'Adenovirus'
      else codeDisplay
    end

// 最終輸出結果
define "Enterovirus Surveillance Results":
  "Unique Enterovirus Episodes" Episode
    return {
      patientID: Patient.id.value,
      eventDate: ToString(Episode.episodeStartDate),
      episodeEndDate: ToString(Episode.episodeEndDate),
      age: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      gender: "Patient Gender",
      encounterType: "GetEncounterType"(Episode.encounter),
      virusType: "DetermineVirusType"(Episode.codeDisplay),
      eventType: Episode.eventType,
      diagnosisCode: Episode.codeValue,
      diagnosisName: Episode.codeDisplay
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique Enterovirus Episodes")

define "Episode Count By Gender":
  {
    male: Count("Unique Enterovirus Episodes" E where "Patient Gender" = 'male'),
    female: Count("Unique Enterovirus Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    outpatient: Count("Unique Enterovirus Episodes" E where "GetEncounterType"(E.encounter) = 'Outpatient'),
    emergency: Count("Unique Enterovirus Episodes" E where "GetEncounterType"(E.encounter) = 'Emergency'),
    inpatient: Count("Unique Enterovirus Episodes" E where "GetEncounterType"(E.encounter) = 'Inpatient')
  }
