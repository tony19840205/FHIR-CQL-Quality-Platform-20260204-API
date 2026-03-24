library InfectiousDisease_Influenza_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 流感監測系統（含RODS源呼吸道症狀）
// 功能：追蹤流感案例，支援 Episode 邏輯（30天內合併為一次）

parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

context Patient

// ICD-9-CM 流感及呼吸道疾病代碼列表（含RODS源）
define "ICD9 Influenza Codes": {
  '003.22', '010', '010.0', '010.00', '010.01', '010.02', '010.03', '010.04', '010.05', '010.06',
  '010.1', '010.10', '010.11', '010.12', '010.13',
  '011', '011.0', '011.00', '011.01', '011.02', '011.03', '011.04', '011.05', '011.06',
  '011.1', '011.10', '011.11', '011.12', '011.13', '011.14', '011.15', '011.16',
  '011.2', '011.20', '011.21', '011.22', '011.23', '011.24', '011.25', '011.26',
  '011.3', '011.30', '011.31', '011.32', '011.33', '011.34', '011.35',
  '011.4', '011.40', '011.41', '011.42', '011.43', '011.44', '011.45', '011.46',
  '011.5', '011.50', '011.51', '011.52', '011.53', '011.54', '011.55', '011.56',
  '011.6', '011.60', '011.61', '011.62', '011.63', '011.64', '011.65', '011.66',
  '011.7', '011.70', '011.71', '011.72', '011.73', '011.74', '011.75', '011.76',
  '011.8', '011.80', '011.81', '011.82', '011.83', '011.84', '011.85', '011.86',
  '011.9', '011.90', '011.91', '011.92', '011.93', '011.94', '011.95', '011.96',
  '034.0', '052.1', '055.1', '073.0', '074.1', '079.81', '079.88', '079.89',
  '481', '482', '482.2', '482.30', '482.31', '482.32', '482.39',
  '482.40', '482.41', '482.42', '482.49', '482.83', '482.84', '482.89',
  '485', '486', '487', '487.0', '487.1', '487.8', '465.9'
}

// ICD-10-CM 流感代碼列表
define "ICD10 Influenza Codes": {
  'J09', 'J10', 'J11', 'J12', 'J13', 'J14', 'J15', 'J16', 'J17', 'J18',
  'B25', 'A37', 'A22', 'B44', 'J06.9'
}

// SNOMED CT 流感代碼列表
define "SNOMED Influenza Codes": {
  '6142004', '442438000', '195878008', '442696006', '722499003',
  '95891005', '50417007', '290142005', '233604007', '53084003',
  '16814004', '70036007', '54150009'
}

// LOINC 實驗室檢驗代碼列表
define "LOINC Influenza Lab Codes": {
  '92142-9', '92141-1', '80382-5', '49661-6', '49662-4',
  '82174-6', '82175-3', '64204-7', '548-8', '85477-8',
  '85478-6', '88534-3', '5848-6', '92131-2', '60274-8', '60275-5'
}

// 所有流感診斷條件
define "Influenza Diagnosis Conditions":
  [Condition] C
    where exists (
      C.code.coding CD
        where (
          (CD.system.value = 'http://hl7.org/fhir/sid/icd-9-cm' and CD.code.value in "ICD9 Influenza Codes")
          or (CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm' and CD.code.value in "ICD10 Influenza Codes")
          or (CD.system.value = 'http://snomed.info/sct' and CD.code.value in "SNOMED Influenza Codes")
        )
    )

// 所有流感實驗室檢驗
define "Influenza Lab Results":
  [Observation] Lab
    where Lab.status.value in {'final', 'amended', 'corrected'}
      and Lab.value is not null
      and exists (
        Lab.code.coding LC
          where LC.system.value = 'http://loinc.org'
          and LC.code.value in "LOINC Influenza Lab Codes"
      )

// 所有就醫記錄
define "All Encounters":
  [Encounter] E
    where E.status.value = 'finished'

// 合併所有流感相關事件
define "All Influenza Events":
  (
    "Influenza Diagnosis Conditions" C
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
    "Influenza Lab Results" L
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
define "Sorted Influenza Events":
  "All Influenza Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次
define "Unique Influenza Episodes":
  "Sorted Influenza Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent.encounterId),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      priorEventsInSameEpisode: 
        "Sorted Influenza Events" PriorEvent
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
define function "DetermineVirusType"(codeValue String, codeDisplay String):
  if codeDisplay is null then 'Unknown'
  else
    case
      when codeValue in {'92142-9', '82174-6', '82175-3', '64204-7', '49661-6'} then 'Influenza A'
      when codeValue in {'92141-1', '49662-4'} then 'Influenza B'
      when codeValue in {'80382-5', '85477-8', '92131-2'} then 'Influenza A/B'
      when PositionOf('influenza a', codeDisplay) >= 0 or PositionOf('Influenza A', codeDisplay) >= 0 then 'Influenza A'
      when PositionOf('influenza b', codeDisplay) >= 0 or PositionOf('Influenza B', codeDisplay) >= 0 then 'Influenza B'
      when PositionOf('influenza', codeDisplay) >= 0 or PositionOf('Influenza', codeDisplay) >= 0 then 'Influenza'
      when PositionOf('pneumonia', codeDisplay) >= 0 or PositionOf('Pneumonia', codeDisplay) >= 0 then 'Pneumonia'
      when PositionOf('tuberculosis', codeDisplay) >= 0 or PositionOf('Tuberculosis', codeDisplay) >= 0 then 'Tuberculosis'
      else codeDisplay
    end

// 最終輸出結果
define "Influenza Surveillance Results":
  "Unique Influenza Episodes" Episode
    return {
      patientID: Patient.id.value,
      eventDate: ToString(Episode.episodeStartDate),
      episodeEndDate: ToString(Episode.episodeEndDate),
      age: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      gender: "Patient Gender",
      encounterType: "GetEncounterType"(Episode.encounter),
      virusType: "DetermineVirusType"(Episode.codeValue, Episode.codeDisplay),
      eventType: Episode.eventType,
      diagnosisCode: Episode.codeValue,
      diagnosisName: Episode.codeDisplay
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique Influenza Episodes")

define "Episode Count By Gender":
  {
    male: Count("Unique Influenza Episodes" E where "Patient Gender" = 'male'),
    female: Count("Unique Influenza Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    outpatient: Count("Unique Influenza Episodes" E where "GetEncounterType"(E.encounter) = 'Outpatient'),
    emergency: Count("Unique Influenza Episodes" E where "GetEncounterType"(E.encounter) = 'Emergency'),
    inpatient: Count("Unique Influenza Episodes" E where "GetEncounterType"(E.encounter) = 'Inpatient')
  }
