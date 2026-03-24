library Indicator_11_4_Cesarean_Section_Rate_First_Time_1075_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 剖腹產率-初次具適應症
// 指標代碼: 1075.01
// 資料來源: 醫療給付檔案分析系統，指標代碼：1075.01
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署

codesystem "NHI_CLAIM": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-claim'
codesystem "NHI_CLAIM": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-claim'
codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

code "Finished": 'finished' from "EncounterStatus" display '已完成'
code "Inpatient": 'IMP' from "ActCode" display '住院'

// TW-DRG codes (自然產)
code "Natural_DRG_372": '372' from "NHI_CLAIM" display '自然產DRG-372'
code "Natural_DRG_373": '373' from "NHI_CLAIM" display '自然產DRG-373'
code "Natural_DRG_374": '374' from "NHI_CLAIM" display '自然產DRG-374'
code "Natural_DRG_375": '375' from "NHI_CLAIM" display '自然產DRG-375'

// TW-DRG codes (剖腹產)
code "Cesarean_DRG_370": '370' from "NHI_CLAIM" display '剖腹產DRG-370'
code "Cesarean_DRG_371": '371' from "NHI_CLAIM" display '剖腹產DRG-371'
code "Cesarean_DRG_513": '513' from "NHI_CLAIM" display '剖腹產DRG-513'

// DRG_CODE codes
code "Natural_0373A": '0373A' from "NHI_CLAIM" display '自然產-0373A'
code "Natural_0373C": '0373C' from "NHI_CLAIM" display '自然產-0373C'
code "Cesarean_0371A": '0371A' from "NHI_CLAIM" display '剖腹產-0371A'
code "Patient_Requested_0373B": '0373B' from "NHI_CLAIM" display '自行要求剖腹產-0373B'

// ICD-10-CM診斷代碼
code "Previous_Cesarean_O342": 'O342' from "NHI_CLAIM" display '前胎剖腹產生產'

// ICD-10-PCS處置代碼
code "Cesarean_10D00Z0": '10D00Z0' from "NHI_PROCEDURE" display '經腹低段剖腹產取出產物'
code "Cesarean_10D00Z1": '10D00Z1' from "NHI_PROCEDURE" display '經腹低段剖腹產-保留子宮'
code "Cesarean_10D00Z2": '10D00Z2' from "NHI_PROCEDURE" display '經腹低段剖腹產-切除子宮'

// 自然產醫令代碼
code "Natural_81017C": '81017C' from "NHI_PROCEDURE" display '自然產接生'
code "Natural_81018C": '81018C' from "NHI_PROCEDURE" display '自然產接生(含會陰切開)'
code "Natural_81019C": '81019C' from "NHI_PROCEDURE" display '自然產接生(含會陰修補)'
code "Natural_81024C": '81024C' from "NHI_PROCEDURE" display '產鉗助產'
code "Natural_81025C": '81025C' from "NHI_PROCEDURE" display '真空吸引助產'
code "Natural_81026C": '81026C' from "NHI_PROCEDURE" display '臀位牽引術'
code "Natural_81034C": '81034C' from "NHI_PROCEDURE" display '複雜性陰道分娩'
code "Natural_97004C": '97004C' from "NHI_PROCEDURE" display '自然產接生費'
code "Natural_97005D": '97005D' from "NHI_PROCEDURE" display '陰道分娩'
code "Natural_97934C": '97934C' from "NHI_PROCEDURE" display '產科接生處置'

// 剖腹產醫令代碼
code "Cesarean_81004C": '81004C' from "NHI_PROCEDURE" display '剖腹產術(初次)'
code "Cesarean_81005C": '81005C' from "NHI_PROCEDURE" display '剖腹產合併子宮切除'
code "Cesarean_81028C": '81028C' from "NHI_PROCEDURE" display '選擇性剖腹產(初次)'
code "Cesarean_81029C": '81029C' from "NHI_PROCEDURE" display '緊急剖腹產'
code "Cesarean_97009C": '97009C' from "NHI_PROCEDURE" display '剖腹產手術費'
code "Cesarean_97014C": '97014C' from "NHI_PROCEDURE" display '剖腹產處置費'

valueset "Inpatient Encounters": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307'

parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

define function GetId(encounter Encounter): String is encounter.id

define function GetDischargeDate(encounter Encounter): DateTime is 
  end of encounter.period

define function GetTWDRG(encounter Encounter): String is
  singleton from (
    [Claim] C
      where C.id.contains(encounter.id)
      return First(
        C.extension E
          where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/tw-drg'
          return E.valueString
      )
  )

define function GetDRGCode(encounter Encounter): String is
  singleton from (
    [Claim] C
      where C.id.contains(encounter.id)
      return First(
        C.extension E
          where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code'
          return E.valueString
      )
  )

define function GetDRGPrefix3(twdrg String): String is
  if twdrg is not null and Length(twdrg) >= 3
  then Substring(twdrg, 0, 3)
  else null

define function GetMainDiagnosis(encounter Encounter): String is
  singleton from (
    [Condition] C
      where C.encounter.reference.contains(encounter.id)
        and exists(C.category.coding c where c.code = 'principal-diagnosis')
      return First(C.code.coding).code
  )

define function GetSecondaryDiagnosis(encounter Encounter): String is
  singleton from (
    [Condition] C
      where C.encounter.reference.contains(encounter.id)
        and exists(C.category.coding c where c.code = 'secondary-diagnosis')
      return First(C.code.coding).code
  )

define function HasNaturalDeliveryProcedure(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (
          P.code ~ "Natural_81017C" or P.code ~ "Natural_81018C" or P.code ~ "Natural_81019C" or
          P.code ~ "Natural_81024C" or P.code ~ "Natural_81025C" or P.code ~ "Natural_81026C" or
          P.code ~ "Natural_81034C" or P.code ~ "Natural_97004C" or P.code ~ "Natural_97005D" or
          P.code ~ "Natural_97934C"
        )
  )

define function HasCesareanDeliveryProcedure(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (
          P.code ~ "Cesarean_81004C" or P.code ~ "Cesarean_81005C" or P.code ~ "Cesarean_81028C" or
          P.code ~ "Cesarean_81029C" or P.code ~ "Cesarean_97009C" or P.code ~ "Cesarean_97014C"
        )
  )

define function HasFirstTimeCesareanProcedure(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (
          P.code ~ "Cesarean_81004C" or P.code ~ "Cesarean_81028C" or
          P.code ~ "Cesarean_10D00Z0" or P.code ~ "Cesarean_10D00Z1" or P.code ~ "Cesarean_10D00Z2"
        )
  )

define function HasICD10PCSCesarean(encounter Encounter): Boolean is
  exists(
    [Procedure] P
      where P.encounter.reference.contains(encounter.id)
        and P.status ~ 'completed'
        and (P.code ~ "Cesarean_10D00Z0" or P.code ~ "Cesarean_10D00Z1" or P.code ~ "Cesarean_10D00Z2")
  )

define function HasPreviousCesareanDiagnosis(encounter Encounter): Boolean is
  (GetMainDiagnosis(encounter) = 'O342') or (GetSecondaryDiagnosis(encounter) = 'O342')

define function IsNaturalDelivery(encounter Encounter): Boolean is
  let twdrg: GetTWDRG(encounter),
      drgcode: GetDRGCode(encounter),
      drg_prefix3: GetDRGPrefix3(twdrg)
  return (
    drg_prefix3 in {'372', '373', '374', '375'} or
    drgcode in {'0373A', '0373C'} or
    HasNaturalDeliveryProcedure(encounter)
  )

define function IsCesareanDelivery(encounter Encounter): Boolean is
  let twdrg: GetTWDRG(encounter),
      drgcode: GetDRGCode(encounter),
      drg_prefix3: GetDRGPrefix3(twdrg)
  return (
    drg_prefix3 in {'370', '371', '513'} or
    drgcode in {'0371A', '0373B'} or
    HasCesareanDeliveryProcedure(encounter)
  )

define function IsFirstTimeWithIndicationCesarean(encounter Encounter): Boolean is
  let drgcode: GetDRGCode(encounter)
  return (
    HasFirstTimeCesareanProcedure(encounter)
    and drgcode != '0373B'
    and not (HasICD10PCSCesarean(encounter) and HasPreviousCesareanDiagnosis(encounter))
  )

define "All Inpatient Discharges":
  [Encounter: type in "Inpatient Encounters"] E
    where E.status ~ "Finished"
      and E.class ~ "Inpatient"
      and GetDischargeDate(E) during "Measurement Period"

define "Natural Deliveries":
  "All Inpatient Discharges" E
    where IsNaturalDelivery(E)

define "Cesarean Deliveries":
  "All Inpatient Discharges" E
    where IsCesareanDelivery(E)

define "First Time Cesarean With Indication Deliveries":
  "Cesarean Deliveries" E
    where IsFirstTimeWithIndicationCesarean(E)

define "All Deliveries":
  "Natural Deliveries" union "Cesarean Deliveries"

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

define "2024Q1 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then ("2024Q1 Numerator" / "2024Q1 Denominator") * 100 else null

define "2024Q2 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then ("2024Q2 Numerator" / "2024Q2 Denominator") * 100 else null

define "2024Q3 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then ("2024Q3 Numerator" / "2024Q3 Denominator") * 100 else null

define "2024Q4 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then ("2024Q4 Numerator" / "2024Q4 Denominator") * 100 else null

define "2025Q1 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then ("2025Q1 Numerator" / "2025Q1 Denominator") * 100 else null

define "2025Q2 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then ("2025Q2 Numerator" / "2025Q2 Denominator") * 100 else null

define "2025Q3 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then ("2025Q3 Numerator" / "2025Q3 Denominator") * 100 else null

define "2025Q4 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then ("2025Q4 Numerator" / "2025Q4 Denominator") * 100 else null

define "2026Q1 Numerator": Count("First Time Cesarean With Indication Deliveries" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Denominator": Count("All Deliveries" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then ("2026Q1 Numerator" / "2026Q1 Denominator") * 100 else null

define "Total Numerator": Count("First Time Cesarean With Indication Deliveries")
define "Total Denominator": Count("All Deliveries")
define "Total Rate": if "Total Denominator" > 0 then ("Total Numerator" / "Total Denominator") * 100 else null

define "Indicator Result":
  Tuple {
    indicatorCode: '1075.01',
    indicatorName: '剖腹產率-初次具適應症',
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
