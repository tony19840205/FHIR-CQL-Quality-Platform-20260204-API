library InfectiousDisease_Influenza_Surveillance version '1.0.0'

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
// 流感相關代碼定義
// ============================================

// ICD-9-CM 代碼
code "ICD9 Influenza": '487' from "ICD-9-CM" display 'Influenza'
code "ICD9 Influenza with pneumonia": '487.0' from "ICD-9-CM" display 'Influenza with pneumonia'
code "ICD9 Influenza with respiratory": '487.1' from "ICD-9-CM" display 'Influenza with other respiratory manifestations'
code "ICD9 Influenza with other": '487.8' from "ICD-9-CM" display 'Influenza with other manifestations'

// ICD-10-CM 代碼  
code "ICD10 Influenza J09": 'J09' from "ICD-10-CM" display 'Influenza due to identified novel influenza A virus'
code "ICD10 Influenza J10": 'J10' from "ICD-10-CM" display 'Influenza due to other identified influenza virus'
code "ICD10 Influenza J11": 'J11' from "ICD-10-CM" display 'Influenza due to unidentified influenza virus'

// SNOMED CT 代碼
code "SNOMED Influenza": '6142004' from "SNOMEDCT" display 'Influenza'

// LOINC 實驗室檢驗代碼
code "LOINC Influenza A RNA": '92142-9' from "LOINC" display 'Influenza virus A RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC Influenza B RNA": '92141-1' from "LOINC" display 'Influenza virus B RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC Influenza A Ag": '80382-5' from "LOINC" display 'Influenza virus A Ag [Presence] in Nasopharynx by Immunoassay'
code "LOINC Influenza B Ag": '80383-3' from "LOINC" display 'Influenza virus B Ag [Presence] in Nasopharynx by Immunoassay'

// ActCode 就醫類型
code "ActCode Outpatient": 'AMB' from "ActCode" display 'Ambulatory/Outpatient'
code "ActCode Emergency": 'EMER' from "ActCode" display 'Emergency'
code "ActCode Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'

// ============================================
// 核心邏輯：患者與事件定義
// ============================================

context Patient

// 所有流感診斷條件 (Condition resources)
define "Influenza Diagnosis Conditions":
  [Condition] C
    where exists (C.code.coding Coding 
      where Coding.code.value in { '487', '487.0', '487.1', '487.8', 'J09', 'J10', 'J11', '6142004' })

// 所有流感實驗室檢驗 (Observation resources)
define "Influenza Lab Results":
  [Observation] Lab
    where exists (Lab.code.coding Coding 
      where Coding.code.value in { '92142-9', '92141-1', '80382-5', '80383-3' })
      and Lab.status in { 'final', 'amended', 'corrected' }
      and Lab.value is not null

// 所有就醫記錄
define "All Encounters":
  [Encounter] E
    where E.status = 'finished'

// 合併所有流感相關事件 (診斷 + 檢驗)
define "All Influenza Events":
  (
    "Influenza Diagnosis Conditions" C
      return Tuple {
        eventDate: Coalesce(FHIRHelpers.ToDateTime(C.onset as FHIR.dateTime), FHIRHelpers.ToDateTime(C.recordedDate)),
        eventType: 'Diagnosis',
        code: C.code,
        encounterId: FHIRHelpers.ToString(C.encounter.reference)
      }
  )
  union
  (
    "Influenza Lab Results" L
      return Tuple {
        eventDate: Coalesce(FHIRHelpers.ToDateTime(L.effective as FHIR.dateTime), FHIRHelpers.ToDateTime(L.issued)),
        eventType: 'Laboratory',
        code: L.code,
        encounterId: FHIRHelpers.ToString(L.encounter.reference)
      }
  )

// 取得事件對應的就醫記錄
define function "GetEncounterForEvent"(eventParam Tuple { eventDate DateTime, eventType String, code FHIR.CodeableConcept, encounterId String }):
  First(
    "All Encounters" E
      where 'Encounter/' + E.id = eventParam.encounterId
  )

// 排序所有事件（按時間）
define "Sorted Influenza Events":
  "All Influenza Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次
define "Unique Influenza Episodes":
  "Sorted Influenza Events" CurrentEvent
    let encounter: "GetEncounterForEvent"(CurrentEvent),
        priorEventsInSameEpisode: 
          "Sorted Influenza Events" PriorEvent
            where PriorEvent.eventDate < CurrentEvent.eventDate
              and days between PriorEvent.eventDate and CurrentEvent.eventDate <= 30
    where not exists(priorEventsInSameEpisode)
    return Tuple {
      episodeStartDate: CurrentEvent.eventDate,
      eventType: CurrentEvent.eventType,
      code: CurrentEvent.code,
      encounter: encounter,
      encounterId: CurrentEvent.encounterId
    }

// ============================================
// 輸出結果
// ============================================

// 計算年齡
define function "CalculateAgeAtEvent"(eventDate DateTime):
  AgeInYearsAt(eventDate)

// 取得性別
define "Patient Gender":
  Patient.gender.value

// 判斷就醫類型
define function "GetEncounterType"(encounter Encounter):
  case
    when encounter.class ~ "ActCode Inpatient" then '住院'
    when encounter.class ~ "ActCode Emergency" then '急診'
    when encounter.class ~ "ActCode Outpatient" then '門診'
    else '其他'
  end

// 判斷病毒種類
define function "DetermineVirusType"(codeParam FHIR.CodeableConcept):
  'Influenza'

// 最終結果
define "Final Result":
  "Unique Influenza Episodes" Episode
    return Tuple {
      episodeDate: Episode.episodeStartDate,
      age: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      gender: "Patient Gender",
      encounterType: "GetEncounterType"(Episode.encounter),
      virusType: "DetermineVirusType"(Episode.code),
      eventType: Episode.eventType,
      diagnosisCode: Episode.code
    }
