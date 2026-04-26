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
// 值集定義 (URL-based for CQL-to-ELM compatibility)
// ============================================

valueset "Enterovirus ICD9 Codes": 'http://example.org/fhir/ValueSet/enterovirus-icd9'
valueset "Enterovirus ICD10 Codes": 'http://example.org/fhir/ValueSet/enterovirus-icd10'
valueset "Enterovirus SNOMED Codes": 'http://example.org/fhir/ValueSet/enterovirus-snomed'
valueset "Enterovirus Lab Codes": 'http://example.org/fhir/ValueSet/enterovirus-lab'

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

// 診斷事件清單
define "Diagnosis Events":
  "Enterovirus Diagnosis Conditions" C
    return Tuple {
      eventDate: FHIRHelpers.ToDateTime(Coalesce(C.onset as FHIR.dateTime, C.recordedDate)),
      eventType: 'Diagnosis',
      codeSystem: Coalesce(C.code.coding[0].system.value, 'unknown'),
      codeValue: Coalesce(C.code.coding[0].code.value, 'unknown'),
      codeDisplay: Coalesce(C.code.coding[0].display.value, 'unknown'),
      encounterId: C.encounter.reference.value
    }

// 檢驗事件清單
define "Lab Events":
  "Enterovirus Lab Results" L
    return Tuple {
      eventDate: FHIRHelpers.ToDateTime(L.effective as FHIR.dateTime),
      eventType: 'Laboratory',
      codeSystem: Coalesce(L.code.coding[0].system.value, 'unknown'),
      codeValue: Coalesce(L.code.coding[0].code.value, 'unknown'),
      codeDisplay: Coalesce(L.code.coding[0].display.value, 'unknown'),
      encounterId: L.encounter.reference.value
    }

// 合併所有腸病毒相關事件
define "All Enterovirus Events":
  "Diagnosis Events" union "Lab Events"

// 排序所有事件（按時間）
define "Sorted Enterovirus Events":
  "All Enterovirus Events" E
    where E.eventDate is not null
    sort by eventDate

// ============================================
// 去重複：30天內算一次 (Episode Window Logic)
// ============================================

define function "IsNewEpisode"(currentDate DateTime, allEvents List<Tuple { eventDate DateTime, eventType String, codeSystem String, codeValue String, codeDisplay String, encounterId String }>):
  not exists (
    allEvents PriorEvent
      where PriorEvent.eventDate < currentDate
        and PriorEvent.eventDate >= (currentDate - 30 days)
  )

define "Unique Enterovirus Episodes":
  "Sorted Enterovirus Events" CurrentEvent
    where "IsNewEpisode"(CurrentEvent.eventDate, "Sorted Enterovirus Events")

// ============================================
// 輸出結果：年齡、性別、就醫類型
// ============================================

define function "CalculateAgeAtEvent"(eventDate DateTime):
  AgeInYearsAt(eventDate)

define "Patient Gender":
  Patient.gender.value

define function "GetEncounterTypeById"(encId String):
  First(
    "All Encounters" E
      where ('Encounter/' + E.id.value) = encId
      return
        case
          when E.class ~ "ActCode Inpatient" then 'Inpatient'
          when E.class ~ "ActCode Emergency" then 'Emergency'
          when E.class ~ "ActCode Outpatient" then 'Outpatient'
          else 'Other'
        end
  )

// 最終輸出結果
define "Enterovirus Surveillance Results":
  "Unique Enterovirus Episodes" Episode
    return Tuple {
      patientId: Patient.id.value,
      eventDate: ToString(Episode.eventDate),
      age: "CalculateAgeAtEvent"(Episode.eventDate),
      gender: "Patient Gender",
      encounterType: "GetEncounterTypeById"(Episode.encounterId),
      eventType: Episode.eventType,
      diagnosisCode: Episode.codeValue,
      diagnosisName: Episode.codeDisplay,
      codeSystem: Episode.codeSystem
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique Enterovirus Episodes")

define "Male Episode Count":
  Count("Unique Enterovirus Episodes" E where "Patient Gender" = 'male')

define "Female Episode Count":
  Count("Unique Enterovirus Episodes" E where "Patient Gender" = 'female')

define "Diagnosis Episode Count":
  Count("Unique Enterovirus Episodes" E where E.eventType = 'Diagnosis')

define "Lab Episode Count":
  Count("Unique Enterovirus Episodes" E where E.eventType = 'Laboratory')

// 資料完整性檢查
define "Has Condition Data":
  exists("Enterovirus Diagnosis Conditions")

define "Has Lab Data":
  exists("Enterovirus Lab Results")

define "Data Availability Check":
  Tuple {
    hasConditionData: "Has Condition Data",
    hasLabData: "Has Lab Data",
    totalDiagnoses: Count("Enterovirus Diagnosis Conditions"),
    totalLabResults: Count("Enterovirus Lab Results"),
    totalEvents: Count("All Enterovirus Events"),
    uniqueEpisodes: "Total Unique Episodes"
  }
