library Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

/*
 * 來源：醫療給付檔案分析系統
 * 指標代碼: 1155
 * 指標名稱：清淨手術術後使用抗生素超過三日比率
 * 製作日期：2026-01-10
 * 
 * 【公式說明】
 * 分子: 清淨手術術後使用抗生素超過三日之案件數
 * 分母: 清淨手術案件數
 */

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

// Thyroid disease codes
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

// Antibiotic ATC code
code "Antibiotic_J01": 'J01' from "ATC" display '全身性抗細菌劑'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2024-12-31T23:59:59.999]

context Patient

// Helper Functions
define function GetMedicationCodeableConcept(mr MedicationRequest):
  case 
    when mr.medication is FHIR.CodeableConcept then mr.medication as FHIR.CodeableConcept
    when mr.medication is FHIR.Reference then 
      if mr.contained is not null then
        singleton from (mr.contained C 
          where C is FHIR.Medication 
          return (C as FHIR.Medication).code)
      else null
    else null
  end

define function IsAntibiotic(atcCode String):
  if atcCode is null then false
  else Substring(atcCode, 0, 3) = 'J01'

define function HasExclusionDiagnosis(enc Encounter):
  exists (
    [Condition] C
      where C.encounter.reference.value.contains(enc.id.value)
      and exists (
        C.code.coding Coding
          where Coding.code.value in {
            'C40', 'C41', 'D65', 'D66', 'D67', 'D68',
            'H65', 'H66', 'H67', 'H68', 'H69',
            'J12', 'J13', 'J14', 'J15', 'J16', 'J17', 'J18',
            'N30', 'N34', 'N390'
          }
      )
  )

define function IsCleanSurgeryProcedure(proc Procedure):
  exists (
    proc.code.coding Coding
      where Coding.code.value in {
        '0YQ50ZZ', '0YQ53ZZ', '0YQ54ZZ', '0YQ60ZZ', '0YQ63ZZ', '0YQ64ZZ',
        '0YQ70ZZ', '0YQ73ZZ', '0YQ74ZZ', '0YQ80ZZ', '0YQ83ZZ', '0YQ84ZZ',
        '0YQC0ZZ', '0YQC3ZZ', '0YQC4ZZ', '0YQE0ZZ', '0YQE3ZZ', '0YQE4ZZ',
        '75607C', '75610B', '75613C', '75614C', '75615C', '88029C',
        '0GBG0ZZ', '0GBG3ZZ', '0GBG4ZZ', '0GBH0ZZ', '0GBH3ZZ', '0GBH4ZZ',
        '0GTG0ZZ', '0GTG4ZZ', '0GTH0ZZ', '0GTH4ZZ', '0GTK0ZZ', '0GTK4ZZ',
        '64162B', '64164B', '64169B', '64170B'
      }
  )

// Core Definitions
define "Inpatient Encounters":
  [Encounter] E
    where E.class.code.value = 'IMP'
    and E.status.value = 'finished'
    and E.period.end during "Measurement Period"
    and not HasExclusionDiagnosis(E)

define "Clean Surgery Procedures":
  [Procedure] P
    where P.status.value = 'completed'
    and IsCleanSurgeryProcedure(P)
    and exists (
      "Inpatient Encounters" E
        where P.encounter.reference.value.contains(E.id.value)
    )

define "Surgery Cases":
  "Inpatient Encounters" E
    where exists (
      "Clean Surgery Procedures" P
        where P.encounter.reference.value.contains(E.id.value)
    )

define "Antibiotic Medications":
  [MedicationRequest] MR
    let medicationCC: GetMedicationCodeableConcept(MR)
    where MR.status.value = 'completed'
    and medicationCC is not null
    and exists (
      medicationCC.coding Coding
        where Coding.system.value = 'http://www.whocc.no/atc'
        and IsAntibiotic(Coding.code.value)
    )

define "Surgery Cases With Antibiotics":
  "Surgery Cases" SC
    where exists (
      "Antibiotic Medications" AM
        where AM.encounter.reference.value.contains(SC.id.value)
        and AM.authoredOn.value after SC.period.start.value
    )

define "Surgery Cases With Antibiotics Over 3 Days":
  "Surgery Cases With Antibiotics" SC
    let 
      antibiotics: "Antibiotic Medications" AM
        where AM.encounter.reference.value.contains(SC.id.value)
        and AM.authoredOn.value after SC.period.start.value,
      antibioticCount: Count(antibiotics)
    where antibioticCount >= 2

// Final Population Definitions
define "Initial Population":
  "Surgery Cases"

define "Denominator":
  "Surgery Cases With Antibiotics"

define "Numerator":
  "Surgery Cases With Antibiotics Over 3 Days"

define "Antibiotic Over 3 Days Rate":
  if Count("Denominator") > 0 then
    (Count("Numerator") * 100.0) / Count("Denominator")
  else
    null