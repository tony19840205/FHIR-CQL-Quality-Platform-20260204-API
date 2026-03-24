library Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 清淨手術術後使用抗生素超過三日比率
// 指標代碼: 1155
// 資料來源: 醫療給付檔案分析系統，指標代碼：1155
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署

// 指標名稱: 清淨手術術後使用抗生素超過三日比率
// 指標代碼: 1155
// 資料來源: 醫療給付檔案分析系統，指標代碼：1155
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署

codesystem "NHI_CLAIM": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-claim'
codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "ATC": 'http://www.whocc.no/atc'

code "Finished": 'finished' from "EncounterStatus" display '已完成'
code "Inpatient": 'IMP' from "ActCode" display '住院'
code "Case_Category_05": '05' from "NHI_CLAIM" display '住院西醫'

// Exclusion diagnosis codes
code "Exclude_C40": 'C40' from "NHI_CLAIM" display '骨惡性腫瘤'
code "Exclude_C41": 'C41' from "NHI_CLAIM" display '關節惡性腫瘤'
code "Exclude_D65": 'D65' from "NHI_CLAIM" display '凝血異常D65'
code "Exclude_D66": 'D66' from "NHI_CLAIM" display '凝血異常D66'
code "Exclude_D67": 'D67' from "NHI_CLAIM" display '凝血異常D67'
code "Exclude_D68": 'D68' from "NHI_CLAIM" display '凝血異常D68'
code "Exclude_H65": 'H65' from "NHI_CLAIM" display '中耳炎H65'
code "Exclude_H66": 'H66' from "NHI_CLAIM" display '中耳炎H66'
code "Exclude_H67": 'H67' from "NHI_CLAIM" display '中耳炎H67'
code "Exclude_H68": 'H68' from "NHI_CLAIM" display '耳咽管疾病H68'
code "Exclude_H69": 'H69' from "NHI_CLAIM" display '耳咽管疾病H69'
code "Exclude_J12": 'J12' from "NHI_CLAIM" display '病毒性肺炎'
code "Exclude_J13": 'J13' from "NHI_CLAIM" display '肺炎鏈球菌肺炎'
code "Exclude_J14": 'J14' from "NHI_CLAIM" display '嗜血桿菌肺炎'
code "Exclude_J15": 'J15' from "NHI_CLAIM" display '細菌性肺炎'
code "Exclude_J16": 'J16' from "NHI_CLAIM" display '其他感染性肺炎'
code "Exclude_J17": 'J17' from "NHI_CLAIM" display '他處歸類肺炎'
code "Exclude_J18": 'J18' from "NHI_CLAIM" display '未明示肺炎'
code "Exclude_N30": 'N30' from "NHI_CLAIM" display '膀胱炎'
code "Exclude_N34": 'N34' from "NHI_CLAIM" display '尿道炎'
code "Exclude_N390": 'N390' from "NHI_CLAIM" display '泌尿道感染'

// Thyroid disease codes (for inclusion with thyroid surgery)
code "Thyroid_E00": 'E00' from "NHI_CLAIM" display '甲狀腺疾病E00'
code "Thyroid_E01": 'E01' from "NHI_CLAIM" display '甲狀腺疾病E01'
code "Thyroid_E02": 'E02' from "NHI_CLAIM" display '甲狀腺疾病E02'
code "Thyroid_E03": 'E03' from "NHI_CLAIM" display '甲狀腺疾病E03'
code "Thyroid_E04": 'E04' from "NHI_CLAIM" display '甲狀腺疾病E04'
code "Thyroid_E05": 'E05' from "NHI_CLAIM" display '甲狀腺疾病E05'
code "Thyroid_E06": 'E06' from "NHI_CLAIM" display '甲狀腺疾病E06'
code "Thyroid_E07": 'E07' from "NHI_CLAIM" display '甲狀腺疾病E07'
code "Thyroid_E35": 'E35' from "NHI_CLAIM" display '內分泌腺疾病'
code "Thyroid_E890": 'E89.0' from "NHI_CLAIM" display '術後甲狀腺功能低下'
code "Thyroid_D440": 'D44.0' from "NHI_CLAIM" display '甲狀腺良性腫瘤'

// ICD-10-PCS Joint repair codes (18 codes)
code "Joint_0YQ50ZZ": '0YQ50ZZ' from "NHI_PROCEDURE" display '膝關節修復'
code "Joint_0YQ53ZZ": '0YQ53ZZ' from "NHI_PROCEDURE" display '膝關節修復經皮'
code "Joint_0YQ54ZZ": '0YQ54ZZ' from "NHI_PROCEDURE" display '膝關節修復內視鏡'
code "Joint_0YQ60ZZ": '0YQ60ZZ' from "NHI_PROCEDURE" display '膝關節修復右'
code "Joint_0YQ63ZZ": '0YQ63ZZ' from "NHI_PROCEDURE" display '膝關節修復右經皮'
code "Joint_0YQ64ZZ": '0YQ64ZZ' from "NHI_PROCEDURE" display '膝關節修復右內視鏡'
code "Joint_0YQ70ZZ": '0YQ70ZZ' from "NHI_PROCEDURE" display '髖關節修復'
code "Joint_0YQ73ZZ": '0YQ73ZZ' from "NHI_PROCEDURE" display '髖關節修復經皮'
code "Joint_0YQ74ZZ": '0YQ74ZZ' from "NHI_PROCEDURE" display '髖關節修復內視鏡'
code "Joint_0YQ80ZZ": '0YQ80ZZ' from "NHI_PROCEDURE" display '髖關節修復右'
code "Joint_0YQ83ZZ": '0YQ83ZZ' from "NHI_PROCEDURE" display '髖關節修復右經皮'
code "Joint_0YQ84ZZ": '0YQ84ZZ' from "NHI_PROCEDURE" display '髖關節修復右內視鏡'
code "Joint_0YQC0ZZ": '0YQC0ZZ' from "NHI_PROCEDURE" display '踝關節修復'
code "Joint_0YQC3ZZ": '0YQC3ZZ' from "NHI_PROCEDURE" display '踝關節修復經皮'
code "Joint_0YQC4ZZ": '0YQC4ZZ' from "NHI_PROCEDURE" display '踝關節修復內視鏡'
code "Joint_0YQE0ZZ": '0YQE0ZZ' from "NHI_PROCEDURE" display '跗骨關節修復'
code "Joint_0YQE3ZZ": '0YQE3ZZ' from "NHI_PROCEDURE" display '跗骨關節修復經皮'
code "Joint_0YQE4ZZ": '0YQE4ZZ' from "NHI_PROCEDURE" display '跗骨關節修復內視鏡'

// NHI procedure codes for joint surgery (6 codes)
code "NHI_Joint_75607C": '75607C' from "NHI_PROCEDURE" display '全膝關節置換術'
code "NHI_Joint_75610B": '75610B' from "NHI_PROCEDURE" display '全髖關節置換術'
code "NHI_Joint_75613C": '75613C' from "NHI_PROCEDURE" display '髖關節修復術'
code "NHI_Joint_75614C": '75614C' from "NHI_PROCEDURE" display '膝關節修復術'
code "NHI_Joint_75615C": '75615C' from "NHI_PROCEDURE" display '踝關節修復術'
code "NHI_Joint_88029C": '88029C' from "NHI_PROCEDURE" display '關節置換處置費'

// ICD-10-PCS Thyroid surgery codes (12 codes)
code "Thyroid_0GBG0ZZ": '0GBG0ZZ' from "NHI_PROCEDURE" display '甲狀腺切除開放式'
code "Thyroid_0GBG3ZZ": '0GBG3ZZ' from "NHI_PROCEDURE" display '甲狀腺切除經皮'
code "Thyroid_0GBG4ZZ": '0GBG4ZZ' from "NHI_PROCEDURE" display '甲狀腺切除內視鏡'
code "Thyroid_0GBH0ZZ": '0GBH0ZZ' from "NHI_PROCEDURE" display '甲狀腺右葉切除開放式'
code "Thyroid_0GBH3ZZ": '0GBH3ZZ' from "NHI_PROCEDURE" display '甲狀腺右葉切除經皮'
code "Thyroid_0GBH4ZZ": '0GBH4ZZ' from "NHI_PROCEDURE" display '甲狀腺右葉切除內視鏡'
code "Thyroid_0GTG0ZZ": '0GTG0ZZ' from "NHI_PROCEDURE" display '甲狀腺全切除開放式'
code "Thyroid_0GTG4ZZ": '0GTG4ZZ' from "NHI_PROCEDURE" display '甲狀腺全切除內視鏡'
code "Thyroid_0GTH0ZZ": '0GTH0ZZ' from "NHI_PROCEDURE" display '甲狀腺右葉全切除開放式'
code "Thyroid_0GTH4ZZ": '0GTH4ZZ' from "NHI_PROCEDURE" display '甲狀腺右葉全切除內視鏡'
code "Thyroid_0GTK0ZZ": '0GTK0ZZ' from "NHI_PROCEDURE" display '甲狀腺左葉全切除開放式'
code "Thyroid_0GTK4ZZ": '0GTK4ZZ' from "NHI_PROCEDURE" display '甲狀腺左葉全切除內視鏡'

// NHI procedure codes for thyroid surgery (4 codes)
code "NHI_Thyroid_64162B": '64162B' from "NHI_PROCEDURE" display '甲狀腺全切除術'
code "NHI_Thyroid_64164B": '64164B' from "NHI_PROCEDURE" display '甲狀腺次全切除術'
code "NHI_Thyroid_64169B": '64169B' from "NHI_PROCEDURE" display '甲狀腺葉切除術'
code "NHI_Thyroid_64170B": '64170B' from "NHI_PROCEDURE" display '甲狀腺峽部切除術'

// NHI procedure codes for joint replacement (4 codes)
code "NHI_Replace_64162B": '64162B' from "NHI_PROCEDURE" display '關節置換64162B'
code "NHI_Replace_64164B": '64164B' from "NHI_PROCEDURE" display '關節置換64164B'
code "NHI_Replace_64169B": '64169B' from "NHI_PROCEDURE" display '關節置換64169B'
code "NHI_Replace_64170B": '64170B' from "NHI_PROCEDURE" display '關節置換64170B'

// Antibiotic ATC code
code "Antibiotic_J01": 'J01' from "ATC" display '全身性抗細菌劑'

valueset "Inpatient Encounters": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307'

parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

define function GetId(encounter Encounter): String is encounter.id

define function GetDischargeDate(encounter Encounter): DateTime is 
  end of encounter.period

define function GetCaseCategory(encounter Encounter): String is
  singleton from (
    [Claim] C
      where C.id.contains(encounter.id)
      return First(
        C.extension E
          where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/case-category'
          return E.valueString
      )
  )

define function GetMainDiagnosisPrefix3(encounter Encounter): String is
  let diagnosis: singleton from (
    [Condition] C
      where C.encounter.reference.contains(encounter.id)
        and exists(C.category.coding c where c.code = 'principal-diagnosis')
      return First(C.code.coding).code
  )
  return if diagnosis is not null and Length(diagnosis) >= 3
    then Substring(diagnosis, 0, 3)
    else null

define function GetMainDiagnosisFull(encounter Encounter): String is
  singleton from (
    [Condition] C
      where C.encounter.reference.contains(encounter.id)
        and exists(C.category.coding c where c.code = 'principal-diagnosis')
      return First(C.code.coding).code
  )

define function HasJointRepairProcedure(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (
          P.code ~ "Joint_0YQ50ZZ" or P.code ~ "Joint_0YQ53ZZ" or P.code ~ "Joint_0YQ54ZZ" or
          P.code ~ "Joint_0YQ60ZZ" or P.code ~ "Joint_0YQ63ZZ" or P.code ~ "Joint_0YQ64ZZ" or
          P.code ~ "Joint_0YQ70ZZ" or P.code ~ "Joint_0YQ73ZZ" or P.code ~ "Joint_0YQ74ZZ" or
          P.code ~ "Joint_0YQ80ZZ" or P.code ~ "Joint_0YQ83ZZ" or P.code ~ "Joint_0YQ84ZZ" or
          P.code ~ "Joint_0YQC0ZZ" or P.code ~ "Joint_0YQC3ZZ" or P.code ~ "Joint_0YQC4ZZ" or
          P.code ~ "Joint_0YQE0ZZ" or P.code ~ "Joint_0YQE3ZZ" or P.code ~ "Joint_0YQE4ZZ"
        )
  )

define function HasJointNHIProcedure(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (
          P.code ~ "NHI_Joint_75607C" or P.code ~ "NHI_Joint_75610B" or 
          P.code ~ "NHI_Joint_75613C" or P.code ~ "NHI_Joint_75614C" or 
          P.code ~ "NHI_Joint_75615C" or P.code ~ "NHI_Joint_88029C"
        )
  )

define function HasThyroidProcedure(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (
          P.code ~ "Thyroid_0GBG0ZZ" or P.code ~ "Thyroid_0GBG3ZZ" or P.code ~ "Thyroid_0GBG4ZZ" or
          P.code ~ "Thyroid_0GBH0ZZ" or P.code ~ "Thyroid_0GBH3ZZ" or P.code ~ "Thyroid_0GBH4ZZ" or
          P.code ~ "Thyroid_0GTG0ZZ" or P.code ~ "Thyroid_0GTG4ZZ" or
          P.code ~ "Thyroid_0GTH0ZZ" or P.code ~ "Thyroid_0GTH4ZZ" or
          P.code ~ "Thyroid_0GTK0ZZ" or P.code ~ "Thyroid_0GTK4ZZ"
        )
  )

define function HasThyroidNHIProcedure(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (
          P.code ~ "NHI_Thyroid_64162B" or P.code ~ "NHI_Thyroid_64164B" or 
          P.code ~ "NHI_Thyroid_64169B" or P.code ~ "NHI_Thyroid_64170B"
        )
  )

define function HasThyroidDiagnosis(encounter Encounter): Boolean is
  let diagPrefix3: GetMainDiagnosisPrefix3(encounter),
      diagFull: GetMainDiagnosisFull(encounter)
  return (
    diagPrefix3 in {'E00', 'E01', 'E02', 'E03', 'E04', 'E05', 'E06', 'E07', 'E35'} or
    diagFull in {'E89.0', 'D44.0'}
  )

define function HasExclusionDiagnosis(encounter Encounter): Boolean is
  let diagPrefix3: GetMainDiagnosisPrefix3(encounter),
      diagFull: GetMainDiagnosisFull(encounter)
  return (
    diagPrefix3 in {'C40', 'C41', 'D65', 'D66', 'D67', 'D68', 
                    'H65', 'H66', 'H67', 'H68', 'H69',
                    'J12', 'J13', 'J14', 'J15', 'J16', 'J17', 'J18',
                    'N30', 'N34'} or
    diagFull = 'N390'
  )

define function GetAntibioticDays(encounter Encounter): Integer is
  let surgeryDate: GetDischargeDate(encounter),
      antibiotics: (
        [MedicationRequest] M
          where M.subject.reference.contains(encounter.subject.reference)
            and M.authoredOn > surgeryDate
            and exists(M.medication.concept.coding c where c.system = 'http://www.whocc.no/atc' and c.code starts with 'J01')
      )
  return if Count(antibiotics) > 0
    then days between Min(antibiotics A return A.authoredOn) and Max(antibiotics A return A.authoredOn) + 1
    else 0

define function IsCleanSurgeryJointRepair(encounter Encounter): Boolean is
  GetCaseCategory(encounter) = '05'
  and HasJointRepairProcedure(encounter)
  and HasJointNHIProcedure(encounter)
  and not HasExclusionDiagnosis(encounter)

define function IsCleanSurgeryThyroid(encounter Encounter): Boolean is
  GetCaseCategory(encounter) = '05'
  and HasThyroidProcedure(encounter)
  and HasThyroidNHIProcedure(encounter)
  and HasThyroidDiagnosis(encounter)
  and not HasExclusionDiagnosis(encounter)

define function IsCleanSurgery(encounter Encounter): Boolean is
  IsCleanSurgeryJointRepair(encounter) or IsCleanSurgeryThyroid(encounter)

define "All Inpatient Discharges":
  [Encounter: type in "Inpatient Encounters"] E
    where E.status ~ "Finished"
      and E.class ~ "Inpatient"
      and GetDischargeDate(E) during "Measurement Period"

define "Clean Surgery Cases":
  "All Inpatient Discharges" E
    where IsCleanSurgery(E)

define "Antibiotic Over 3 Days Cases":
  "Clean Surgery Cases" E
    where GetAntibioticDays(E) > 3

define "2024Q1 Start": DateTime(2024, 1, 1, 0, 0, 0, 0)
define "2024Q1 End": DateTime(2024, 3, 31, 23, 59, 59, 999)
define "2024Q2 Start": DateTime(2024, 4, 1, 0, 0, 0, 0)
define "2024Q2 End": DateTime(2024, 6, 30, 23, 59, 59, 999)
define "2024Q3 Start": DateTime(2024, 7, 1, 0, 0, 0, 0)
define "2024Q3 End": DateTime(2024, 9, 30, 23, 59, 59, 999)
define "2024Q4 Start": DateTime(2024, 10, 1, 0, 0, 0, 0)
define "2024Q4 End": DateTime(2024, 12, 31, 23, 59, 59, 999)
define "2025Q1 Start": DateTime(2025, 1, 1, 0, 0, 0, 0)
define "2025Q1 End": DateTime(2025, 3, 31, 23, 59, 59, 999)
define "2025Q2 Start": DateTime(2025, 4, 1, 0, 0, 0, 0)
define "2025Q2 End": DateTime(2025, 6, 30, 23, 59, 59, 999)
define "2025Q3 Start": DateTime(2025, 7, 1, 0, 0, 0, 0)
define "2025Q3 End": DateTime(2025, 9, 30, 23, 59, 59, 999)
define "2025Q4 Start": DateTime(2025, 10, 1, 0, 0, 0, 0)
define "2025Q4 End": DateTime(2025, 12, 31, 23, 59, 59, 999)
define "2026Q1 Start": DateTime(2026, 1, 1, 0, 0, 0, 0)
define "2026Q1 End": DateTime(2026, 3, 31, 23, 59, 59, 999)

define "2024Q1 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then ("2024Q1 Numerator" / "2024Q1 Denominator") * 100 else null

define "2024Q2 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then ("2024Q2 Numerator" / "2024Q2 Denominator") * 100 else null

define "2024Q3 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then ("2024Q3 Numerator" / "2024Q3 Denominator") * 100 else null

define "2024Q4 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then ("2024Q4 Numerator" / "2024Q4 Denominator") * 100 else null

define "2025Q1 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then ("2025Q1 Numerator" / "2025Q1 Denominator") * 100 else null

define "2025Q2 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then ("2025Q2 Numerator" / "2025Q2 Denominator") * 100 else null

define "2025Q3 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then ("2025Q3 Numerator" / "2025Q3 Denominator") * 100 else null

define "2025Q4 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then ("2025Q4 Numerator" / "2025Q4 Denominator") * 100 else null

define "2026Q1 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then ("2026Q1 Numerator" / "2026Q1 Denominator") * 100 else null

define "Total Numerator": Count("Antibiotic Over 3 Days Cases")
define "Total Denominator": Count("Clean Surgery Cases")
define "Total Rate": if "Total Denominator" > 0 then ("Total Numerator" / "Total Denominator") * 100 else null

define "Indicator Result":
  Tuple {
    indicatorCode: '1155',
    indicatorName: '清淨手術術後使用抗生素超過三日比率',
    measurementPeriod: "Measurement Period",
    quarters: List{
      Tuple { quarter: '2024Q1', numerator: "2024Q1 Numerator", denominator: "2024Q1 Denominator", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', numerator: "2024Q2 Numerator", denominator: "2024Q2 Denominator", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', numerator: "2024Q3 Numerator", denominator: "2024Q3 Denominator", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', numerator: "2024Q4 Numerator", denominator: "2024Q4 Denominator", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', numerator: "2025Q1 Numerator", denominator: "2025Q1 Denominator", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', numerator: "2025Q2 Numerator", denominator: "2025Q2 Denominator", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', numerator: "2025Q3 Numerator", denominator: "2025Q3 Denominator", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', numerator: "2025Q4 Numerator", denominator: "2025Q4 Denominator", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', numerator: "2026Q1 Numerator", denominator: "2026Q1 Denominator", rate: "2026Q1 Rate" }
    },
    total: Tuple { numerator: "Total Numerator", denominator: "Total Denominator", rate: "Total Rate" }
  }
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 資料範圍: 每季所有醫院總額之清淨手術案件
 * 
 * 製表單位: 衛生福利部 中央健康保險署
 * 製表日期: 114/05/13
 * 
 * 公式說明:
 * 清淨手術術後使用抗生素超過三日比率 = 
 *     分子: 手術後>3日使用抗生素案件數
 *     分母: 清淨手術案件數
 * 
 * 清淨手術定義：
 * 住院西醫院，案件分類為5日符合下列任一條件，但排除(i)主診斷ICD-10-CM碼前3碼為C40、C41、D65-D68，
 * 或主診斷ICD-10-CM碼前3碼為H65-H69，肺炎(前3碼為J12-J18)，UTI(前3碼N30、N34、全碼N390)
 * 
 * (1) 主處置代碼(ICD-10-PCS手術代碼)為0YQ50ZZ、0YQ53ZZ、0YQ54ZZ、0YQ60ZZ、0YQ63ZZ、
 *     0YQ64ZZ、0YQ70ZZ、0YQ73ZZ、0YQ74ZZ、0YQ80ZZ、0YQ83ZZ、0YQ84ZZ、0YQC0ZZ、0YQC3ZZ、
 *     0YQC4ZZ、0YQE0ZZ、0YQE3ZZ、0YQE4ZZ且支付標準碼(醫令代碼)為75607C、75610B、75613C、
 *     75614C、75615C、88029C
 * 
 * (2) 主處置代碼(ICD-10-PCS手術代碼)為0GBGOZZ、0GBG3ZZ、0GBG4ZZ、0GBH0ZZ、0GBH3ZZ、
 *     0GBH4ZZ、0GTG0ZZ、0GTG4ZZ、0GTH0ZZ、0GTH4ZZ、0GTK0ZZ、0GTK4ZZ且主診斷ICD-10-CM
 *     碼前3碼為E00-E07、E35，全碼E89.0，全碼D44.0
 * 
 * (3) 主處置代碼(ICD-10-PCS手術代碼)為0SR9019、0SR901A、0SR901Z、0SR9029、0SR902A、
 *     0SR902Z、0SR9039、0SR903A、0SR903Z、0SR907Z、0SRB019、0SRB01A、0SRB01Z、0SRB029、
 *     0SRB02A、0SRB02Z、0SRB039、0SRB03A、0SRB03Z、0SRB04Z、0SRB07Z、0SRC019、0SRC01A、
 *     0SRC01Z、0SRC029、0SRC03A、0SRC03Z、0SRD019、0SRD01A、0SRD01Z、0SRD029、0SRD02A、
 *     0SRD02Z、0SRD039、0SRD03A、0SRD03Z、0SRD04Z、0SRD07Z、0SRE019、0SRE01A、0SRE01Z、
 *     0SRE029、0SRE02A、0SRE02Z、0SRE039、0SRE03A、0SRE03Z、0SRE04Z、0SRE07Z、0SRF019、
 *     0SRF01A、0SRF01Z、0SRF029、0SRF02A、0SRF02Z、0SRF039、0SRF03A、0SRF03Z、0SRG019、
 *     0SRG01A、0SRG01Z、0SRG029、0SRG02A、0SRG02Z、0SRG039、0SRG03A、0SRG03Z、0SRG04Z、
 *     0SRG07Z、0SRH019、0SRH01A、0SRH01Z、0SRH029、0SRH02A、0SRH02Z、0SRH039、0SRH03A、
 *     0SRH03Z、0SRH04Z、0SRH07Z、0SRJ019、0SRJ01A、0SRJ01Z、0SRJ029、0SRJ02A、0SRJ02Z、
 *     0SRJ039、0SRJ03A、0SRJ03Z、0SRJ04Z、0SRJ07Z、0SRK019、0SRK01A、0SRK01Z、0SRK029、
 *     0SRK02A、0SRK02Z、0SRK039、0SRK03A、0SRK03Z、0SRK04Z、0SRK07Z、0SRT019、0SRT01A、
 *     0SRT01Z、0SRT029、0SRT02A、0SRT02Z、0SRT039、0SRT03A、0SRT03Z、0SRT04Z、0SRT07Z、
 *     0SRU019、0SRU01A、0SRU01Z、0SRU029、0SRU02A、0SRU02Z、0SRU039、0SRU03A、0SRU03Z、
 *     0SRU04Z、0SRU07Z、0SRV019、0SRV01A、0SRV01Z、0SRV029、0SRV02A、0SRV02Z、0SRV039、
 *     0SRV03A、0SRV03Z、0SRV04Z、0SRV07Z、0SRW019、0SRW01A、0SRW01Z、0SRW029、0SRW02A、
 *     0SRW02Z、0SRW039、0SRW03A、0SRW03Z、0SRW04Z、0SRW07Z且支付標準碼(醫令代碼)為64162B、
 *     64164B、64169B、64170B
 * 
 * 抗生素定義: ATC碼前三碼為J01 (ANTIBACTERIALS FOR SYSTEMIC USE)
 * 
 * 備註:
 * - 清淨手術為感染風險最低的手術類型
 * - 術後抗生素使用應限於3日內（預防性使用）
 * - 超過3日可能表示不必要的抗生素使用或術後感染
 * 
 * 臨床意義:
 * - 監測清淨手術術後抗生素使用適當性
 * - 降低抗生素過度使用
 * - 減少抗藥性產生風險
 * - 提升感染控制品質
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 住院手術紀錄
 * - Procedure: 清淨手術處置資料
 * - Condition: 診斷資料
 * - MedicationRequest: 抗生素處方
 * - MedicationAdministration: 抗生素給藥記錄
 * - Claim: 醫療費用申報
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 1155 (指標代碼)

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- C40, C41: 骨與關節軟骨惡性腫瘤（排除）
    -- D65-D68: 凝血異常（排除）
    -- H65-H69: 中耳及乳突疾病（排除）
    -- J12-J18: 肺炎（排除）
    -- N30: 膀胱炎（排除）
    -- N34: 尿道炎（排除）
    -- N390: 尿路感染（排除）
    -- E00-E07: 甲狀腺疾病
    -- E35: 內分泌腺疾病
    -- E89.0: 術後甲狀腺功能低下
    -- D44.0: 甲狀腺良性腫瘤

codesystem "ICD10PCS": 'http://hl7.org/fhir/sid/icd-10-pcs'
    -- ICD-10-PCS 處置代碼系統
    -- 0YQ系列: 下肢關節修復
    -- 0GBG/0GBH系列: 甲狀腺切除
    -- 0GTG/0GTH/0GTK系列: 甲狀腺切除
    -- 0SR系列: 關節置換術

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 清淨手術相關代碼
    -- 69536005: Total knee replacement (全膝關節置換術)
    -- 52734007: Total hip replacement (全髖關節置換術)
    -- 179352005: Thyroidectomy (甲狀腺切除術)
    -- 24486003: Thyroid lobectomy (甲狀腺葉切除術)
    -- 54396005: Total knee arthroplasty (全膝關節成形術)
    -- 52734007: Total hip arthroplasty (全髖關節成形術)
    -- 265157000: Partial thyroidectomy (部分甲狀腺切除術)
    -- 387713003: Surgical procedure (外科手術)
    -- 抗生素給藥相關
    -- 432102000: Administration of substance (物質給藥)
    -- 281790008: Antibiotic therapy (抗生素治療)
    -- 419492006: Prophylactic antibiotic therapy (預防性抗生素治療)

codesystem "ATC": 'http://www.whocc.no/atc'
    -- ATC藥品分類代碼系統
    -- J01: ANTIBACTERIALS FOR SYSTEMIC USE (全身性抗細菌劑)
    -- J01A: Tetracyclines (四環黴素類)
    -- J01C: Beta-lactam antibacterials, penicillins (青黴素類)
    -- J01D: Other beta-lactam antibacterials (其他β-內醯胺類)
    -- J01E: Sulfonamides and trimethoprim (磺胺類)
    -- J01F: Macrolides, lincosamides and streptogramins (巨環類)
    -- J01G: Aminoglycoside antibacterials (胺基醣苷類)
    -- J01M: Quinolone antibacterials (喹諾酮類)
    -- J01X: Other antibacterials (其他抗細菌劑)

codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
    -- 健保處置代碼系統
    -- 關節手術: 75607C, 75610B, 75613C, 75614C, 75615C, 88029C
    -- 甲狀腺手術: 64162B, 64164B, 64169B, 64170B

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode
    -- IMP: 住院

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-organization'
    -- 台灣健保局專用代碼
    -- 醫事機構代碼

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別
    -- I: 住院

codesystem "NHI_CASE_CATEGORY": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-case-category'
    -- 健保案件分類代碼
    -- 05: 住院西醫

codesystem "LOINC": 'http://loinc.org'
    -- LOINC 實驗室及臨床觀察代碼
    -- 86574-8: Antibiotic therapy
    -- 87275-1: Antibiotic administration duration
    -- 95412-3: Surgery date
    -- 87209-0: Infection status

-- ==================== 指標代碼定義 ====================

code "Indicator_1155": '1155' from "NHI_INDICATOR" display '清淨手術術後使用抗生素超過三日比率'

-- ==================== 案件分類代碼 ====================

code "Inpatient_Western_Medicine": '05' from "NHI_CASE_CATEGORY" display '住院西醫'

-- ==================== ICD-10-CM 排除診斷代碼 ====================

-- 骨與關節惡性腫瘤（排除）
code "Malignant_Bone_C40": 'C40' from "ICD10CM" display '四肢骨與關節軟骨惡性腫瘤'
code "Malignant_Bone_C41": 'C41' from "ICD10CM" display '其他及未明示部位骨與關節軟骨惡性腫瘤'

-- 凝血異常（排除）
code "Coagulation_Disorder_D65": 'D65' from "ICD10CM" display '播散性血管內凝血'
code "Coagulation_Disorder_D66": 'D66' from "ICD10CM" display '遺傳性第VIII因子缺乏'
code "Coagulation_Disorder_D67": 'D67' from "ICD10CM" display '遺傳性第IX因子缺乏'
code "Coagulation_Disorder_D68": 'D68' from "ICD10CM" display '其他凝血缺陷'

-- 中耳及乳突疾病（排除）
code "Otitis_Media_H65": 'H65' from "ICD10CM" display '非化膿性中耳炎'
code "Otitis_Media_H66": 'H66' from "ICD10CM" display '化膿性與未明示之中耳炎'
code "Otitis_Media_H67": 'H67' from "ICD10CM" display '他處歸類之疾病引起的中耳炎'
code "Eustachian_H68": 'H68' from "ICD10CM" display '耳咽管疾患'
code "Eustachian_H69": 'H69' from "ICD10CM" display '其他耳咽管疾患'

-- 肺炎（排除）
code "Viral_Pneumonia_J12": 'J12' from "ICD10CM" display '病毒性肺炎'
code "Pneumonia_J13": 'J13' from "ICD10CM" display '肺炎鏈球菌引起的肺炎'
code "Pneumonia_J14": 'J14' from "ICD10CM" display '嗜血桿菌引起的肺炎'
code "Bacterial_Pneumonia_J15": 'J15' from "ICD10CM" display '細菌性肺炎'
code "Pneumonia_J16": 'J16' from "ICD10CM" display '其他感染性病原體引起的肺炎'
code "Pneumonia_J17": 'J17' from "ICD10CM" display '他處歸類之疾病引起的肺炎'
code "Pneumonia_Unspecified_J18": 'J18' from "ICD10CM" display '肺炎，病原體未明示'

-- 泌尿道感染（排除）
code "Cystitis_N30": 'N30' from "ICD10CM" display '膀胱炎'
code "Urethritis_N34": 'N34' from "ICD10CM" display '尿道炎與尿道症候群'
code "UTI_N390": 'N390' from "ICD10CM" display '部位未明示之泌尿道感染'

-- 甲狀腺疾病（允許）
code "Thyroid_E00": 'E00' from "ICD10CM" display '先天性碘缺乏症候群'
code "Thyroid_E01": 'E01' from "ICD10CM" display '碘相關之甲狀腺疾患'
code "Thyroid_E02": 'E02' from "ICD10CM" display '亞臨床碘缺乏性甲狀腺功能低下'
code "Thyroid_E03": 'E03' from "ICD10CM" display '其他甲狀腺功能低下'
code "Thyroid_E04": 'E04' from "ICD10CM" display '其他非毒性甲狀腺腫'
code "Thyroid_E05": 'E05' from "ICD10CM" display '甲狀腺毒症'
code "Thyroid_E06": 'E06' from "ICD10CM" display '甲狀腺炎'
code "Thyroid_E07": 'E07' from "ICD10CM" display '其他甲狀腺疾患'
code "Endocrine_E35": 'E35' from "ICD10CM" display '他處歸類之疾病引起之內分泌腺疾患'
code "Postop_Hypothyroidism_E890": 'E89.0' from "ICD10CM" display '術後甲狀腺功能低下'
code "Thyroid_Neoplasm_D440": 'D44.0' from "ICD10CM" display '甲狀腺良性腫瘤'

-- ==================== ICD-10-PCS 手術代碼 ====================

-- (1) 下肢關節修復手術
code "Knee_Repair_0YQ50ZZ": '0YQ50ZZ' from "ICD10PCS" display '膝關節開放式修復'
code "Knee_Repair_0YQ53ZZ": '0YQ53ZZ' from "ICD10PCS" display '膝關節經皮修復'
code "Knee_Repair_0YQ54ZZ": '0YQ54ZZ' from "ICD10PCS" display '膝關節經皮內視鏡修復'
code "Knee_Repair_0YQ60ZZ": '0YQ60ZZ' from "ICD10PCS" display '膝關節開放式修復（右）'
code "Knee_Repair_0YQ63ZZ": '0YQ63ZZ' from "ICD10PCS" display '膝關節經皮修復（右）'
code "Knee_Repair_0YQ64ZZ": '0YQ64ZZ' from "ICD10PCS" display '膝關節經皮內視鏡修復（右）'
code "Hip_Repair_0YQ70ZZ": '0YQ70ZZ' from "ICD10PCS" display '髖關節開放式修復'
code "Hip_Repair_0YQ73ZZ": '0YQ73ZZ' from "ICD10PCS" display '髖關節經皮修復'
code "Hip_Repair_0YQ74ZZ": '0YQ74ZZ' from "ICD10PCS" display '髖關節經皮內視鏡修復'
code "Hip_Repair_0YQ80ZZ": '0YQ80ZZ' from "ICD10PCS" display '髖關節開放式修復（右）'
code "Hip_Repair_0YQ83ZZ": '0YQ83ZZ' from "ICD10PCS" display '髖關節經皮修復（右）'
code "Hip_Repair_0YQ84ZZ": '0YQ84ZZ' from "ICD10PCS" display '髖關節經皮內視鏡修復（右）'
code "Ankle_Repair_0YQCOZZ": '0YQC0ZZ' from "ICD10PCS" display '踝關節開放式修復'
code "Ankle_Repair_0YQC3ZZ": '0YQC3ZZ' from "ICD10PCS" display '踝關節經皮修復'
code "Ankle_Repair_0YQC4ZZ": '0YQC4ZZ' from "ICD10PCS" display '踝關節經皮內視鏡修復'
code "Tarsal_Repair_0YQEOZZ": '0YQE0ZZ' from "ICD10PCS" display '跗骨關節開放式修復'
code "Tarsal_Repair_0YQE3ZZ": '0YQE3ZZ' from "ICD10PCS" display '跗骨關節經皮修復'
code "Tarsal_Repair_0YQE4ZZ": '0YQE4ZZ' from "ICD10PCS" display '跗骨關節經皮內視鏡修復'

-- (2) 甲狀腺手術
code "Thyroid_Excision_0GBGOZZ": '0GBG0ZZ' from "ICD10PCS" display '甲狀腺開放式切除'
code "Thyroid_Excision_0GBG3ZZ": '0GBG3ZZ' from "ICD10PCS" display '甲狀腺經皮切除'
code "Thyroid_Excision_0GBG4ZZ": '0GBG4ZZ' from "ICD10PCS" display '甲狀腺經皮內視鏡切除'
code "Thyroid_Excision_0GBHOZZ": '0GBH0ZZ' from "ICD10PCS" display '甲狀腺右葉開放式切除'
code "Thyroid_Excision_0GBH3ZZ": '0GBH3ZZ' from "ICD10PCS" display '甲狀腺右葉經皮切除'
code "Thyroid_Excision_0GBH4ZZ": '0GBH4ZZ' from "ICD10PCS" display '甲狀腺右葉經皮內視鏡切除'
code "Thyroid_Resection_0GTGOZZ": '0GTG0ZZ' from "ICD10PCS" display '甲狀腺開放式全切除'
code "Thyroid_Resection_0GTG4ZZ": '0GTG4ZZ' from "ICD10PCS" display '甲狀腺經皮內視鏡全切除'
code "Thyroid_Resection_0GTHOZZ": '0GTH0ZZ' from "ICD10PCS" display '甲狀腺右葉開放式全切除'
code "Thyroid_Resection_0GTH4ZZ": '0GTH4ZZ' from "ICD10PCS" display '甲狀腺右葉經皮內視鏡全切除'
code "Thyroid_Resection_0GTKOZZ": '0GTK0ZZ' from "ICD10PCS" display '甲狀腺左葉開放式全切除'
code "Thyroid_Resection_0GTK4ZZ": '0GTK4ZZ' from "ICD10PCS" display '甲狀腺左葉經皮內視鏡全切除'

-- (3) 關節置換術（部分列舉，完整代碼見註解）
code "Hip_Replacement_0SR9019": '0SR9019' from "ICD10PCS" display '髖關節置換術-金屬對聚乙烯'
code "Hip_Replacement_0SR901A": '0SR901A' from "ICD10PCS" display '髖關節置換術-金屬對金屬'
code "Hip_Replacement_0SR901Z": '0SR901Z' from "ICD10PCS" display '髖關節置換術-合成材料'
code "Knee_Replacement_0SRC019": '0SRC019' from "ICD10PCS" display '膝關節置換術-金屬對聚乙烯'
code "Knee_Replacement_0SRC01A": '0SRC01A' from "ICD10PCS" display '膝關節置換術-金屬對金屬'
code "Knee_Replacement_0SRC01Z": '0SRC01Z' from "ICD10PCS" display '膝關節置換術-合成材料'

-- ==================== SNOMED CT 代碼 ====================

-- 清淨手術相關
code "Total_Knee_Replacement": '69536005' from "SNOMEDCT" display '全膝關節置換術'
code "Total_Hip_Replacement": '52734007' from "SNOMEDCT" display '全髖關節置換術'
code "Thyroidectomy": '179352005' from "SNOMEDCT" display '甲狀腺切除術'
code "Thyroid_Lobectomy": '24486003' from "SNOMEDCT" display '甲狀腺葉切除術'
code "Total_Knee_Arthroplasty": '54396005' from "SNOMEDCT" display '全膝關節成形術'
code "Total_Hip_Arthroplasty": '52734007' from "SNOMEDCT" display '全髖關節成形術'
code "Partial_Thyroidectomy": '265157000' from "SNOMEDCT" display '部分甲狀腺切除術'
code "Surgical_Procedure": '387713003' from "SNOMEDCT" display '外科手術'

-- 抗生素給藥相關
code "Administration_Of_Substance": '432102000' from "SNOMEDCT" display '物質給藥'
code "Antibiotic_Therapy": '281790008' from "SNOMEDCT" display '抗生素治療'
code "Prophylactic_Antibiotic": '419492006' from "SNOMEDCT" display '預防性抗生素治療'

-- ==================== 健保處置代碼 ====================

-- 關節手術處置費
code "NHI_Joint_75607C": '75607C' from "NHI_PROCEDURE" display '全膝關節置換術'
code "NHI_Joint_75610B": '75610B' from "NHI_PROCEDURE" display '全髖關節置換術'
code "NHI_Joint_75613C": '75613C' from "NHI_PROCEDURE" display '髖關節修復術'
code "NHI_Joint_75614C": '75614C' from "NHI_PROCEDURE" display '膝關節修復術'
code "NHI_Joint_75615C": '75615C' from "NHI_PROCEDURE" display '踝關節修復術'
code "NHI_Joint_88029C": '88029C' from "NHI_PROCEDURE" display '關節置換術處置費'

-- 甲狀腺手術處置費
code "NHI_Thyroid_64162B": '64162B' from "NHI_PROCEDURE" display '甲狀腺全切除術'
code "NHI_Thyroid_64164B": '64164B' from "NHI_PROCEDURE" display '甲狀腺次全切除術'
code "NHI_Thyroid_64169B": '64169B' from "NHI_PROCEDURE" display '甲狀腺葉切除術'
code "NHI_Thyroid_64170B": '64170B' from "NHI_PROCEDURE" display '甲狀腺峽部切除術'

-- ==================== 就醫類別代碼 ====================

code "Inpatient_Encounter": 'IMP' from "ActCode" display '住院'
code "Inpatient_Type": 'I' from "NHI_ENCOUNTER_TYPE" display '住院'

-- ==================== LOINC 觀察代碼 ====================

code "Antibiotic_Therapy_Code": '86574-8' from "LOINC" display '抗生素治療'
code "Antibiotic_Duration": '87275-1' from "LOINC" display '抗生素給藥持續時間'
code "Surgery_Date": '95412-3' from "LOINC" display '手術日期'
code "Infection_Status": '87209-0' from "LOINC" display '感染狀態'

-- ==================== 基本參數設定 ====================

-- 查詢期間設定
parameter "Measurement_Start_Date" DateTime default @2023-01-01T00:00:00.0
parameter "Measurement_End_Date" DateTime default @2024-12-31T23:59:59.0

-- 清淨手術定義：術後抗生素使用天數閾值
parameter "Antibiotic_Day_Threshold" Integer default 3

-- ==================== 查詢期間定義 ====================

-- 定義查詢的年度與季度
define "Measurement_Period":
    Interval[Measurement_Start_Date, Measurement_End_Date]

-- 季度時間定義
define quarters AS
    {
        { id: '112Q1', label: '112年第1季', start_date: @2023-01-01, end_date: @2023-03-31 },
        { id: '112Q2', label: '112年第2季', start_date: @2023-04-01, end_date: @2023-06-30 },
        { id: '112Q3', label: '112年第3季', start_date: @2023-07-01, end_date: @2023-09-30 },
        { id: '112Q4', label: '112年第4季', start_date: @2023-10-01, end_date: @2023-12-31 },
        { id: '113Q1', label: '113年第1季', start_date: @2024-01-01, end_date: @2024-03-31 },
        { id: '113Q2', label: '113年第2季', start_date: @2024-04-01, end_date: @2024-06-30 },
        { id: '113Q3', label: '113年第3季', start_date: @2024-07-01, end_date: @2024-09-30 },
        { id: '113Q4', label: '113年第4季', start_date: @2024-10-01, end_date: @2024-12-31 }
    }

-- 年度期間定義
define annual_period AS
    {
        id: '113',
        label: '113年度',
        start_date: @2024-01-01,
        end_date: @2024-12-31
    }

-- ==================== 所有住院案件（基礎集合）====================

-- 取得所有住院案件
define all_inpatient_encounters AS
    [Encounter: class = "IMP"] E
    where E.status = 'finished'
        and E.period.end during "Measurement_Period"
        and E.type.coding.code = '05'  -- 住院西醫案件分類

-- ==================== 清淨手術判定（分母）====================

-- (1) 下肢關節修復手術案件
define joint_repair_procedures AS
    all_inpatient_encounters E
    where (
        -- ICD-10-PCS 下肢關節修復代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-pcs'
                    and C.code in {
                        '0YQ50ZZ', '0YQ53ZZ', '0YQ54ZZ', '0YQ60ZZ', '0YQ63ZZ', '0YQ64ZZ',
                        '0YQ70ZZ', '0YQ73ZZ', '0YQ74ZZ', '0YQ80ZZ', '0YQ83ZZ', '0YQ84ZZ',
                        '0YQC0ZZ', '0YQC3ZZ', '0YQC4ZZ', '0YQE0ZZ', '0YQE3ZZ', '0YQE4ZZ'
                    }
        )
        and
        -- 健保處置代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                    and C.code in {
                        '75607C', '75610B', '75613C', '75614C', '75615C', '88029C'
                    }
        )
    )

-- (2) 甲狀腺手術案件
define thyroid_surgery_procedures AS
    all_inpatient_encounters E
    where (
        -- ICD-10-PCS 甲狀腺手術代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-pcs'
                    and C.code in {
                        '0GBG0ZZ', '0GBG3ZZ', '0GBG4ZZ', '0GBH0ZZ', '0GBH3ZZ', '0GBH4ZZ',
                        '0GTG0ZZ', '0GTG4ZZ', '0GTH0ZZ', '0GTH4ZZ', '0GTK0ZZ', '0GTK4ZZ'
                    }
        )
        and
        -- 健保處置代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                    and C.code in {
                        '64162B', '64164B', '64169B', '64170B'
                    }
        )
        and
        -- 主診斷為甲狀腺相關疾病
        exists (
            [Condition: subject.reference = E.subject.reference] Cond
            where Cond.code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        C.code starts with 'E00' or C.code starts with 'E01' or
                        C.code starts with 'E02' or C.code starts with 'E03' or
                        C.code starts with 'E04' or C.code starts with 'E05' or
                        C.code starts with 'E06' or C.code starts with 'E07' or
                        C.code starts with 'E35' or C.code = 'E89.0' or C.code = 'D44.0'
                    )
        )
    )

-- (3) 關節置換術案件（0SR系列，共164個代碼）
define joint_replacement_procedures AS
    all_inpatient_encounters E
    where (
        -- ICD-10-PCS 關節置換術代碼（0SR開頭）
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-pcs'
                    and (
                        -- Hip (0SR9系列)
                        C.code in {
                            '0SR9019', '0SR901A', '0SR901Z', '0SR9029', '0SR902A', '0SR902Z',
                            '0SR9039', '0SR903A', '0SR903Z', '0SR907Z'
                        }
                        or
                        -- Hip (0SRB系列)
                        C.code in {
                            '0SRB019', '0SRB01A', '0SRB01Z', '0SRB029', '0SRB02A', '0SRB02Z',
                            '0SRB039', '0SRB03A', '0SRB03Z', '0SRB04Z', '0SRB07Z'
                        }
                        or
                        -- Knee (0SRC系列)
                        C.code in {
                            '0SRC019', '0SRC01A', '0SRC01Z', '0SRC029', '0SRC03A', '0SRC03Z'
                        }
                        or
                        -- Knee (0SRD系列)
                        C.code in {
                            '0SRD019', '0SRD01A', '0SRD01Z', '0SRD029', '0SRD02A', '0SRD02Z',
                            '0SRD039', '0SRD03A', '0SRD03Z', '0SRD04Z', '0SRD07Z'
                        }
                        or
                        -- Ankle/Foot (0SRE-0SRW系列)
                        C.code in {
                            '0SRE019', '0SRE01A', '0SRE01Z', '0SRE029', '0SRE02A', '0SRE02Z',
                            '0SRE039', '0SRE03A', '0SRE03Z', '0SRE04Z', '0SRE07Z',
                            '0SRF019', '0SRF01A', '0SRF01Z', '0SRF029', '0SRF02A', '0SRF02Z',
                            '0SRF039', '0SRF03A', '0SRF03Z',
                            '0SRG019', '0SRG01A', '0SRG01Z', '0SRG029', '0SRG02A', '0SRG02Z',
                            '0SRG039', '0SRG03A', '0SRG03Z', '0SRG04Z', '0SRG07Z',
                            '0SRH019', '0SRH01A', '0SRH01Z', '0SRH029', '0SRH02A', '0SRH02Z',
                            '0SRH039', '0SRH03A', '0SRH03Z', '0SRH04Z', '0SRH07Z',
                            '0SRJ019', '0SRJ01A', '0SRJ01Z', '0SRJ029', '0SRJ02A', '0SRJ02Z',
                            '0SRJ039', '0SRJ03A', '0SRJ03Z', '0SRJ04Z', '0SRJ07Z',
                            '0SRK019', '0SRK01A', '0SRK01Z', '0SRK029', '0SRK02A', '0SRK02Z',
                            '0SRK039', '0SRK03A', '0SRK03Z', '0SRK04Z', '0SRK07Z',
                            '0SRT019', '0SRT01A', '0SRT01Z', '0SRT029', '0SRT02A', '0SRT02Z',
                            '0SRT039', '0SRT03A', '0SRT03Z', '0SRT04Z', '0SRT07Z',
                            '0SRU019', '0SRU01A', '0SRU01Z', '0SRU029', '0SRU02A', '0SRU02Z',
                            '0SRU039', '0SRU03A', '0SRU03Z', '0SRU04Z', '0SRU07Z',
                            '0SRV019', '0SRV01A', '0SRV01Z', '0SRV029', '0SRV02A', '0SRV02Z',
                            '0SRV039', '0SRV03A', '0SRV03Z', '0SRV04Z', '0SRV07Z',
                            '0SRW019', '0SRW01A', '0SRW01Z', '0SRW029', '0SRW02A', '0SRW02Z',
                            '0SRW039', '0SRW03A', '0SRW03Z', '0SRW04Z', '0SRW07Z'
                        }
                    )
        )
        and
        -- 健保處置代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                    and C.code in {
                        '64162B', '64164B', '64169B', '64170B'
                    }
        )
    )

-- ==================== 排除條件判定 ====================

-- 排除：骨與關節惡性腫瘤
define has_malignant_bone_tumor AS
    all_inpatient_encounters E
    where exists (
        [Condition: subject.reference = E.subject.reference] Cond
        where Cond.code.coding C
            where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                and (C.code starts with 'C40' or C.code starts with 'C41')
    )

-- 排除：凝血異常
define has_coagulation_disorder AS
    all_inpatient_encounters E
    where exists (
        [Condition: subject.reference = E.subject.reference] Cond
        where Cond.code.coding C
            where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                and (
                    C.code starts with 'D65' or C.code starts with 'D66' or
                    C.code starts with 'D67' or C.code starts with 'D68'
                )
    )

-- 排除：中耳及乳突疾病
define has_otitis_media AS
    all_inpatient_encounters E
    where exists (
        [Condition: subject.reference = E.subject.reference] Cond
        where Cond.code.coding C
            where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                and (
                    C.code starts with 'H65' or C.code starts with 'H66' or
                    C.code starts with 'H67' or C.code starts with 'H68' or
                    C.code starts with 'H69'
                )
    )

-- 排除：肺炎
define has_pneumonia AS
    all_inpatient_encounters E
    where exists (
        [Condition: subject.reference = E.subject.reference] Cond
        where Cond.code.coding C
            where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                and (
                    C.code starts with 'J12' or C.code starts with 'J13' or
                    C.code starts with 'J14' or C.code starts with 'J15' or
                    C.code starts with 'J16' or C.code starts with 'J17' or
                    C.code starts with 'J18'
                )
    )

-- 排除：泌尿道感染
define has_urinary_tract_infection AS
    all_inpatient_encounters E
    where exists (
        [Condition: subject.reference = E.subject.reference] Cond
        where Cond.code.coding C
            where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                and (
                    C.code starts with 'N30' or C.code starts with 'N34' or
                    C.code = 'N390'
                )
    )

-- ==================== 分母：清淨手術案件 ====================

-- 所有清淨手術案件
define all_clean_surgery_cases AS
    (joint_repair_procedures union thyroid_surgery_procedures union joint_replacement_procedures)
    except (has_malignant_bone_tumor union has_coagulation_disorder union 
            has_otitis_media union has_pneumonia union has_urinary_tract_infection)

-- ==================== 抗生素使用判定 ====================

-- 術後抗生素使用（所有清淨手術案件的抗生素使用情況）
define postoperative_antibiotic_use AS
    all_clean_surgery_cases E
    let surgery_date = E.period.end,
        antibiotic_medications = (
            [MedicationRequest: subject.reference = E.subject.reference] MR
            where MR.authoredOn > surgery_date
                and exists (
                    MR.medication.concept.coding C
                    where C.system = 'http://www.whocc.no/atc'
                        and C.code starts with 'J01'  -- 抗生素ATC碼
                )
        )
    return {
        encounter_id: E.id,
        patient_id: E.subject.reference,
        surgery_date: surgery_date,
        antibiotic_start_date: Min(antibiotic_medications AM return AM.authoredOn),
        antibiotic_end_date: Max(antibiotic_medications AM return AM.authoredOn),
        antibiotic_days: days between Min(antibiotic_medications AM return AM.authoredOn) 
                                  and Max(antibiotic_medications AM return AM.authoredOn) + 1,
        antibiotic_count: Count(antibiotic_medications)
    }

-- ==================== 分子：術後抗生素使用超過3日 ====================

-- 術後抗生素使用超過3日的案件
define antibiotic_over_3_days_cases AS
    postoperative_antibiotic_use PA
    where PA.antibiotic_days > 3

-- ==================== 分母計算 (Denominator) ====================

-- 分母：清淨手術案件數
define denominator_clean_surgery_cases AS
    all_clean_surgery_cases

define denominator_count AS
    SELECT 
        COUNT(*) as clean_surgery_count,
        COUNT(DISTINCT subject.reference) as unique_patient_count
    FROM 
        denominator_clean_surgery_cases

-- 按季度統計分母
define denominator_by_quarter AS
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        clean_surgery_count: Count(
            denominator_clean_surgery_cases E
            where E.period.end >= Q.start_date and E.period.end <= Q.end_date
        )
    }

-- 年度統計分母
define denominator_annual AS
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        clean_surgery_count: Count(
            denominator_clean_surgery_cases E
            where E.period.end >= annual_period.start_date 
                and E.period.end <= annual_period.end_date
        )
    }

-- ==================== 分子計算 (Numerator) ====================

-- 分子：術後抗生素使用超過3日的案件數
define numerator_antibiotic_over_3_days AS
    antibiotic_over_3_days_cases

define numerator_count AS
    SELECT 
        COUNT(*) as antibiotic_over_3_days_count,
        COUNT(DISTINCT patient_id) as unique_patient_count
    FROM 
        numerator_antibiotic_over_3_days

-- 按季度統計分子
define numerator_by_quarter AS
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        antibiotic_over_3_days_count: Count(
            numerator_antibiotic_over_3_days A
            where A.surgery_date >= Q.start_date and A.surgery_date <= Q.end_date
        )
    }

-- 年度統計分子
define numerator_annual AS
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        antibiotic_over_3_days_count: Count(
            numerator_antibiotic_over_3_days A
            where A.surgery_date >= annual_period.start_date 
                and A.surgery_date <= annual_period.end_date
        )
    }

-- ==================== 指標計算 (Indicator Calculation) ====================

-- 按季度計算清淨手術術後抗生素使用超過3日比率
define indicator_by_quarter AS
    (numerator_by_quarter N join denominator_by_quarter D on N.quarter_id = D.quarter_id)
    return {
        indicator_code: "Indicator_1155",
        quarter_id: N.quarter_id,
        quarter_label: N.quarter_label,
        numerator: N.antibiotic_over_3_days_count,
        denominator: D.clean_surgery_count,
        rate: if D.clean_surgery_count > 0 
              then Round((N.antibiotic_over_3_days_count / D.clean_surgery_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((N.antibiotic_over_3_days_count / D.clean_surgery_count) * 100, 2)) + '%'
    }

-- 年度計算清淨手術術後抗生素使用超過3日比率
define indicator_annual AS
    {
        indicator_code: "Indicator_1155",
        period_label: numerator_annual.period_label,
        numerator: numerator_annual.antibiotic_over_3_days_count,
        denominator: denominator_annual.clean_surgery_count,
        rate: if denominator_annual.clean_surgery_count > 0 
              then Round((numerator_annual.antibiotic_over_3_days_count / denominator_annual.clean_surgery_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((numerator_annual.antibiotic_over_3_days_count / denominator_annual.clean_surgery_count) * 100, 2)) + '%'
    }

-- ==================== 綜合結果 ====================

-- 所有期間的指標結果
define all_periods_results AS
    indicator_by_quarter 
    union 
    { indicator_annual }

-- ==================== 進階分析 ====================

-- 清淨手術類型分布
define clean_surgery_type_distribution AS
    {
        joint_repair_count: Count(joint_repair_procedures),
        thyroid_surgery_count: Count(thyroid_surgery_procedures),
        joint_replacement_count: Count(joint_replacement_procedures)
    }

-- 抗生素使用天數分布
define antibiotic_duration_distribution AS
    postoperative_antibiotic_use PA
    return {
        encounter_id: PA.encounter_id,
        antibiotic_days: PA.antibiotic_days,
        duration_category: 
            if PA.antibiotic_days <= 1 then '1日'
            else if PA.antibiotic_days <= 3 then '2-3日'
            else if PA.antibiotic_days <= 7 then '4-7日'
            else if PA.antibiotic_days <= 14 then '8-14日'
            else '超過14日'
    }

-- 醫院別清淨手術術後抗生素使用超過3日比率排名
define hospital_antibiotic_over_3_days_ranking AS
    denominator_clean_surgery_cases E
    let hospital_id = E.serviceProvider.reference
    let total_clean_surgery_by_hospital = Count(
        denominator_clean_surgery_cases E2
        where E2.serviceProvider.reference = hospital_id
    )
    let antibiotic_over_3_days_by_hospital = Count(
        antibiotic_over_3_days_cases A
        where exists (
            denominator_clean_surgery_cases E3
            where E3.id = A.encounter_id
                and E3.serviceProvider.reference = hospital_id
        )
    )
    return {
        hospital_id: hospital_id,
        total_clean_surgery: total_clean_surgery_by_hospital,
        antibiotic_over_3_days: antibiotic_over_3_days_by_hospital,
        rate: if total_clean_surgery_by_hospital > 0
            then Round((antibiotic_over_3_days_by_hospital / total_clean_surgery_by_hospital) * 100, 2)
            else 0
    }

-- ==================== 主要輸出 ====================

/*
 * 主要指標結果
 * 包含季度和年度的清淨手術術後抗生素使用超過3日比率
 */
define "Main Output" AS (
    all_periods_results
)

/*
 * 詳細清淨手術案件清單
 */
define "Detailed Clean Surgery List" AS (
    all_clean_surgery_cases
)

/*
 * 詳細抗生素使用情況
 */
define "Detailed Antibiotic Use" AS (
    postoperative_antibiotic_use
)

/*
 * 清淨手術類型分布
 */
define "Surgery Type Distribution" AS (
    clean_surgery_type_distribution
)

/*
 * 抗生素使用天數分布
 */
define "Antibiotic Duration Distribution" AS (
    antibiotic_duration_distribution
)

/*
 * 醫院排名
 */
define "Hospital Ranking" AS (
    hospital_antibiotic_over_3_days_ranking
)
