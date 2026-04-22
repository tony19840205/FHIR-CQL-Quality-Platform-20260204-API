library InfectiousDisease_AcuteDiarrhea_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 急性腹瀉監測系統
// 功能：追蹤急性腹瀉案例，支援 Episode 邏輯（30天內合併為一次）

parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

context Patient

// ICD-9-CM 急性腸炎代碼列表
define "ICD9 Diarrhea Codes": {
  '001', '001.0', '001.1', '001.9',
  '002', '002.0', '002.1', '002.2', '002.3', '002.9',
  '003', '003.0', '003.1', '003.2', '003.20', '003.21', '003.22', '003.23', '003.24', '003.29',
  '004', '004.0', '004.1', '004.2', '004.3', '004.9',
  '005', '005.0', '005.1', '005.2', '005.3', '005.4', '005.81', '005.89', '005.9',
  '006', '006.0', '006.1', '006.2', '006.3', '006.4',
  '007', '007.0', '007.1', '007.2', '007.3', '007.4', '007.5',
  '008', '008.0', '008.00', '008.01', '008.02', '008.03', '008.04',
  '008.1', '008.2', '008.3', '008.4', '008.42', '008.43', '008.44', '008.45', '008.46', '008.47', '008.5',
  '008.6', '008.61', '008.62', '008.63', '008.64', '008.65', '008.66', '008.69', '008.8',
  '009', '009.0', '009.1', '009.2', '009.3',
  '558.9', '787.91', '558'
}

// ICD-10-CM 腹瀉代碼列表
define "ICD10 Diarrhea Codes": {
  'A09', 'K52', 'R19.7', 'K52.9', 'K59.1',
  'A00', 'A01.0', 'A01.1', 'A02.0', 'A03', 'A05', 'A06',
  'A07.1', 'A07.2', 'A08.0', 'A08.1', 'A08.2'
}

// SNOMED CT 腹瀉代碼列表
define "SNOMED Diarrhea Codes": {
  '111939009', '62315008', '25374005', '41345002', '4602008', '70524001', '409825003',
  '63650001', '4834000', '302231008', '3992009', '36188001', '186024005', '84794001',
  '186561008', '52886002', '186431008', '4855003', '7406009', '65415000'
}

// LOINC 實驗室檢驗代碼列表
define "LOINC Lab Codes": {
  '625-4', '673-4', '6575-4', '75756-7', '17583-0',
  '630-4', '535-5', '595-9', '6571-3', '6568-9',
  '82208-6', '75757-5', '88462-7', '9829-3', '27157-7', '821-6'
}

// 所有急性腹瀉診斷條件
define "Acute Diarrhea Diagnosis Conditions":
  [Condition] C
    where exists (
      C.code.coding CD
        where (
          (CD.system.value = 'http://hl7.org/fhir/sid/icd-9-cm' and CD.code.value in "ICD9 Diarrhea Codes")
          or (CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm' and CD.code.value in "ICD10 Diarrhea Codes")
          or (CD.system.value = 'http://snomed.info/sct' and CD.code.value in "SNOMED Diarrhea Codes")
        )
    )

// 所有急性腹瀉實驗室檢驗
define "Acute Diarrhea Lab Results":
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

// 合併所有急性腹瀉相關事件
define "All Acute Diarrhea Events":
  (
    "Acute Diarrhea Diagnosis Conditions" C
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
    "Acute Diarrhea Lab Results" L
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
define "Sorted Acute Diarrhea Events":
  "All Acute Diarrhea Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次
define "Unique Acute Diarrhea Episodes":
  "Sorted Acute Diarrhea Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent.encounterId),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      priorEventsInSameEpisode: 
        "Sorted Acute Diarrhea Events" PriorEvent
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

// 判斷病原體種類
define function "DeterminePathogenType"(codeDisplay String):
  if codeDisplay is null then 'Unknown'
  else
    case
      when PositionOf('rotavirus', codeDisplay) >= 0 or PositionOf('Rotavirus', codeDisplay) >= 0 then 'Rotavirus'
      when PositionOf('norovirus', codeDisplay) >= 0 or PositionOf('Norovirus', codeDisplay) >= 0 or PositionOf('norwalk', codeDisplay) >= 0 or PositionOf('Norwalk', codeDisplay) >= 0 then 'Norovirus'
      when PositionOf('adenovirus', codeDisplay) >= 0 or PositionOf('Adenovirus', codeDisplay) >= 0 then 'Adenovirus'
      when PositionOf('difficile', codeDisplay) >= 0 or PositionOf('C difficile', codeDisplay) >= 0 or PositionOf('Clostridium', codeDisplay) >= 0 then 'C. difficile'
      when PositionOf('Salmonella', codeDisplay) >= 0 or PositionOf('salmonella', codeDisplay) >= 0 then 'Salmonella'
      when PositionOf('Shigella', codeDisplay) >= 0 or PositionOf('shigella', codeDisplay) >= 0 then 'Shigella'
      when PositionOf('Campylobacter', codeDisplay) >= 0 or PositionOf('campylobacter', codeDisplay) >= 0 then 'Campylobacter'
      when PositionOf('coli', codeDisplay) >= 0 or PositionOf('E. coli', codeDisplay) >= 0 then 'E. coli'
      else codeDisplay
    end

// 最終輸出結果
define "Acute Diarrhea Surveillance Results":
  "Unique Acute Diarrhea Episodes" Episode
    return {
      patientID: Patient.id.value,
      eventDate: ToString(Episode.episodeStartDate),
      episodeEndDate: ToString(Episode.episodeEndDate),
      age: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      gender: "Patient Gender",
      encounterType: "GetEncounterType"(Episode.encounter),
      pathogenType: "DeterminePathogenType"(Episode.codeDisplay),
      eventType: Episode.eventType,
      diagnosisCode: Episode.codeValue,
      diagnosisName: Episode.codeDisplay
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique Acute Diarrhea Episodes")

define "Episode Count By Gender":
  {
    male: Count("Unique Acute Diarrhea Episodes" E where "Patient Gender" = 'male'),
    female: Count("Unique Acute Diarrhea Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    outpatient: Count("Unique Acute Diarrhea Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    emergency: Count("Unique Acute Diarrhea Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    inpatient: Count("Unique Acute Diarrhea Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }
