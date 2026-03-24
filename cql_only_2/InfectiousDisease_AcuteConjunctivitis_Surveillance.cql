library InfectiousDisease_AcuteConjunctivitis_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 紅眼症監測系統
// 功能：追蹤急性結膜炎（紅眼症）案例，支援 Episode 邏輯（30天內合併為一次）

parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

context Patient

// ICD-9-CM 結膜炎代碼列表
define "ICD9 Conjunctivitis Codes": {
  '077', '077.0', '077.1', '077.2', '077.3', '077.4', '077.8', '077.9',
  '370.4', '370.40',
  '372', '372.0', '372.00', '372.01', '372.02', '372.03', '372.04', '372.05', '372.06', '372.71', '372.72'
}

// ICD-10-CM 結膜炎代碼列表
define "ICD10 Conjunctivitis Codes": {
  'B30', 'B30.0', 'B30.1', 'B30.2', 'B30.3', 'B30.8', 'B30.9',
  'H10', 'H10.0', 'H10.1', 'H10.2', 'H10.3', 'H10.4', 'H10.5', 'H10.8', 'H10.9',
  'H11.3'
}

// SNOMED CT 結膜炎代碼列表
define "SNOMED Conjunctivitis Codes": {
  '9826008', '51264003', '193889007', '231977004', '246683000', '232008001',
  '27901008', '410692000', '428562003', '56905009', '37415000', '46965007',
  '266928009', '21007005', '246938007', '246777003', '23318009', '70461003'
}

// LOINC 實驗室檢驗代碼列表
define "LOINC Lab Codes": {
  '626-2', '88891-7', '6309-8', '21613-5', '21415-5', '5017-9',
  '625-4', '664-3', '85827-4', '548-8', '6345-2', '85613-8', '75756-7', '47527-7'
}

// 所有紅眼症診斷條件
define "Acute Conjunctivitis Diagnosis Conditions":
  [Condition] C
    where exists (
      C.code.coding CD
        where (
          (CD.system.value = 'http://hl7.org/fhir/sid/icd-9-cm' and CD.code.value in "ICD9 Conjunctivitis Codes")
          or (CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm' and CD.code.value in "ICD10 Conjunctivitis Codes")
          or (CD.system.value = 'http://snomed.info/sct' and CD.code.value in "SNOMED Conjunctivitis Codes")
        )
    )

// 所有紅眼症實驗室檢驗
define "Acute Conjunctivitis Lab Results":
  [Observation] Lab
    where Lab.status.value in {'final', 'amended', 'corrected'}
      and Lab.value is not null
      and exists (
        Lab.code.coding LC
          where LC.system.value = 'http://loinc.org'
          and LC.code.value in "LOINC Lab Codes"
      )

// 所有就醫記錄
define "All Encounters":
  [Encounter] E
    where E.status.value = 'finished'

// 合併所有紅眼症相關事件
define "All Acute Conjunctivitis Events":
  (
    "Acute Conjunctivitis Diagnosis Conditions" C
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
    "Acute Conjunctivitis Lab Results" L
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
define "Sorted Acute Conjunctivitis Events":
  "All Acute Conjunctivitis Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次
define "Unique Acute Conjunctivitis Episodes":
  "Sorted Acute Conjunctivitis Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent.encounterId),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      priorEventsInSameEpisode: 
        "Sorted Acute Conjunctivitis Events" PriorEvent
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
  if encounter is null then '未知'
  else
    case
      when encounter.class.code.value = 'IMP' then '住院'
      when encounter.class.code.value = 'EMER' then '急診'
      when encounter.class.code.value = 'AMB' then '門診'
      else '其他'
    end

// 判斷病毒種類
define function "DetermineVirusType"(codeDisplay String):
  if codeDisplay is null then 'Unknown'
  else
    case
      when PositionOf('adenovirus', codeDisplay) >= 0 or PositionOf('Adenovirus', codeDisplay) >= 0 then 'Adenovirus'
      when PositionOf('SARS', codeDisplay) >= 0 or PositionOf('COVID', codeDisplay) >= 0 then 'SARS-CoV-2'
      when PositionOf('influenza', codeDisplay) >= 0 or PositionOf('Influenza', codeDisplay) >= 0 then 'Influenza'
      when PositionOf('enterovirus', codeDisplay) >= 0 or PositionOf('Enterovirus', codeDisplay) >= 0 then 'Enterovirus'
      else codeDisplay
    end

// 最終輸出結果
define "Acute Conjunctivitis Surveillance Results":
  "Unique Acute Conjunctivitis Episodes" Episode
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
  Count("Unique Acute Conjunctivitis Episodes")

define "Episode Count By Gender":
  {
    male: Count("Unique Acute Conjunctivitis Episodes" E where "Patient Gender" = 'male'),
    female: Count("Unique Acute Conjunctivitis Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    outpatient: Count("Unique Acute Conjunctivitis Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    emergency: Count("Unique Acute Conjunctivitis Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    inpatient: Count("Unique Acute Conjunctivitis Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }
