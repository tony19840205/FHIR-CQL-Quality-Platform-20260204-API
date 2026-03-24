library Indicator_11_3_Cesarean_Section_Rate_With_Indication_1138_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

/*
 * 來源：醫療給付檔案分析系統
 * 指標代碼：1138.01
 * 指標名稱：剖腹產率-具適應症
 * 製表日期：114/11/06
 * 製表單位：衛生福利部 中央健康保險署
 * 
 * 公式說明:
 * 分子：具適應症之剖腹產案件(不具適應症之剖腹產之外的剖腹產案件)
 * 分母：生產案件數(自然產案件+剖腹產案件)
 * 
 * (1) 自然產案件，符合任一條件：
 *     a. TW-DRG前三碼為372~375
 *     b. DRG_CODE為0373A、0373C
 *     c. 符合任一自然產醫令代碼：81017C、81018C、81019C、81024C、81025C、81026C、81034C、97004C、97005D、97934C
 * 
 * (2) 剖腹產案件，符合任一條件：
 *     a. TW-DRG前三碼為370、371、513
 *     b. DRG_CODE為0371A、0373B
 *     c. 符合任一剖腹產醫令代碼：81004C、81005C、81028C、81029C、97009C、97014C
 * 
 * (3) 不具適應症之剖腹產案件，符合任一條件：
 *     a. TW-DRG前三碼為513
 *     b. DRG_CODE為0373B
 *     c. 醫令代碼為97014C
 * 
 * 備註：本項指標含符合適應症及自行要求剖腹產案件，各院所收治產婦之複雜度不同
 */

codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

valueset "Inpatient Encounters": 'http://nhi.gov.tw/fhir/ValueSet/inpatient-encounters'

// Encounter Status
code "Finished": 'finished' from "EncounterStatus" display 'Finished'
code "Inpatient": 'IMP' from "ActCode" display 'Inpatient'

// TW-DRG Codes - Natural Delivery (自然產)
code "Natural DRG 372": '372' from "NHI_CLAIM" display 'TW-DRG 372 自然產'
code "Natural DRG 373": '373' from "NHI_CLAIM" display 'TW-DRG 373 自然產'
code "Natural DRG 374": '374' from "NHI_CLAIM" display 'TW-DRG 374 自然產'
code "Natural DRG 375": '375' from "NHI_CLAIM" display 'TW-DRG 375 自然產'

// TW-DRG Codes - Cesarean Delivery (剖腹產)
code "Cesarean DRG 370": '370' from "NHI_CLAIM" display 'TW-DRG 370 剖腹產'
code "Cesarean DRG 371": '371' from "NHI_CLAIM" display 'TW-DRG 371 剖腹產'
code "Cesarean DRG 513": '513' from "NHI_CLAIM" display 'TW-DRG 513 不具適應症剖腹產'

// DRG_CODE - Natural Delivery
code "Natural 0373A": '0373A' from "NHI_CLAIM" display 'DRG_CODE 0373A 自然產'
code "Natural 0373C": '0373C' from "NHI_CLAIM" display 'DRG_CODE 0373C 自然產'

// DRG_CODE - Cesarean Delivery
code "Cesarean 0371A": '0371A' from "NHI_CLAIM" display 'DRG_CODE 0371A 剖腹產'
code "Cesarean 0373B": '0373B' from "NHI_CLAIM" display 'DRG_CODE 0373B 不具適應症剖腹產'

// Natural Delivery Procedure Codes (自然產醫令)
code "Natural 81017C": '81017C' from "NHI_PROCEDURE" display '自然產接生'
code "Natural 81018C": '81018C' from "NHI_PROCEDURE" display '自然產接生(含會陰切開)'
code "Natural 81019C": '81019C' from "NHI_PROCEDURE" display '自然產接生(含會陰修補)'
code "Natural 81024C": '81024C' from "NHI_PROCEDURE" display '產鉗助產'
code "Natural 81025C": '81025C' from "NHI_PROCEDURE" display '真空吸引助產'
code "Natural 81026C": '81026C' from "NHI_PROCEDURE" display '臀位牽引術'
code "Natural 81034C": '81034C' from "NHI_PROCEDURE" display '複雜性陰道分娩'
code "Natural 97004C": '97004C' from "NHI_PROCEDURE" display '自然產接生費'
code "Natural 97005D": '97005D' from "NHI_PROCEDURE" display '陰道分娩'
code "Natural 97934C": '97934C' from "NHI_PROCEDURE" display '產科接生處置'

// Cesarean Delivery Procedure Codes (剖腹產醫令)
code "Cesarean 81004C": '81004C' from "NHI_PROCEDURE" display '剖腹產術'
code "Cesarean 81005C": '81005C' from "NHI_PROCEDURE" display '剖腹產合併子宮切除'
code "Cesarean 81028C": '81028C' from "NHI_PROCEDURE" display '選擇性剖腹產'
code "Cesarean 81029C": '81029C' from "NHI_PROCEDURE" display '緊急剖腹產'
code "Cesarean 97009C": '97009C' from "NHI_PROCEDURE" display '剖腹產手術費'
code "Cesarean 97014C": '97014C' from "NHI_PROCEDURE" display '不具適應症之剖腹產處置費'

// Helper Functions
define function GetDischargeDate(encounter Encounter):
  encounter.period.end.value

define function GetTWDRG(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/tw-drg'
      return (E.value as FHIR.code).value
  )

define function GetDRGCode(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/drg-code'
      return (E.value as FHIR.code).value
  )

define function GetDRGPrefix3(drgCode String):
  if Length(drgCode) >= 3 then Substring(drgCode, 0, 3)
  else drgCode

define function HasNaturalDeliveryProcedure(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + encounter.id.value
        and exists(
          P.code.coding C
            where C.code.value in {
              '81017C', '81018C', '81019C', '81024C', '81025C',
              '81026C', '81034C', '97004C', '97005D', '97934C'
            }
        )
  )

define function HasCesareanDeliveryProcedure(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + encounter.id.value
        and exists(
          P.code.coding C
            where C.code.value in {
              '81004C', '81005C', '81028C', '81029C', '97009C', '97014C'
            }
        )
  )

define function HasPatientRequestedProcedure(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + encounter.id.value
        and exists(
          P.code.coding C
            where C.code.value = '97014C'
        )
  )

define function IsNaturalDelivery(encounter Encounter):
  // Get the required values inline instead of using let
  GetDRGPrefix3(GetTWDRG(encounter)) in {'372', '373', '374', '375'}
  // Condition b: DRG_CODE為0373A、0373C
  or GetDRGCode(encounter) in {'0373A', '0373C'}
  // Condition c: 符合任一自然產醫令代碼
  or HasNaturalDeliveryProcedure(encounter)

define function IsCesareanDelivery(encounter Encounter):
  // Get the required values inline instead of using let
  GetDRGPrefix3(GetTWDRG(encounter)) in {'370', '371', '513'}
  // Condition b: DRG_CODE為0371A、0373B
  or GetDRGCode(encounter) in {'0371A', '0373B'}
  // Condition c: 符合任一剖腹產醫令代碼
  or HasCesareanDeliveryProcedure(encounter)

define function IsPatientRequestedCesarean(encounter Encounter):
  // Get the required values inline instead of using let
  GetDRGPrefix3(GetTWDRG(encounter)) = '513'
  // Condition b: DRG_CODE為0373B
  or GetDRGCode(encounter) = '0373B'
  // Condition c: 醫令代碼為97014C
  or HasPatientRequestedProcedure(encounter)

// Data Retrieval
define "All Inpatient Discharges":
  [Encounter] E
    where E.class.code.value = 'IMP'
      and E.status.value = 'finished'

define "Natural Deliveries":
  "All Inpatient Discharges" E
    where IsNaturalDelivery(E)

define "Cesarean Deliveries":
  "All Inpatient Discharges" E
    where IsCesareanDelivery(E)

define "Patient Requested Cesarean Deliveries":
  "All Inpatient Discharges" E
    where IsPatientRequestedCesarean(E)

define "Cesarean With Indication Deliveries":
  "Cesarean Deliveries" except "Patient Requested Cesarean Deliveries"

define "All Deliveries":
  "Natural Deliveries" union "Cesarean Deliveries"

// Quarter Definitions
define "2024Q1 Start": Date(2024, 1, 1)
define "2024Q1 End": Date(2024, 3, 31)
define "2024Q2 Start": Date(2024, 4, 1)
define "2024Q2 End": Date(2024, 6, 30)
define "2024Q3 Start": Date(2024, 7, 1)
define "2024Q3 End": Date(2024, 9, 30)
define "2024Q4 Start": Date(2024, 10, 1)
define "2024Q4 End": Date(2024, 12, 31)
define "2025Q1 Start": Date(2025, 1, 1)
define "2025Q1 End": Date(2025, 3, 31)
define "2025Q2 Start": Date(2025, 4, 1)
define "2025Q2 End": Date(2025, 6, 30)
define "2025Q3 Start": Date(2025, 7, 1)
define "2025Q3 End": Date(2025, 9, 30)
define "2025Q4 Start": Date(2025, 10, 1)
define "2025Q4 End": Date(2025, 12, 31)
define "2026Q1 Start": Date(2026, 1, 1)
define "2026Q1 End": Date(2026, 3, 31)

define "Measurement Period Start": Date(2024, 1, 1)
define "Measurement Period End": Date(2099, 12, 31)
define "Measurement Period": 
  Interval["Measurement Period Start", "Measurement Period End"]

// Denominator - All Deliveries by Quarter
define "2024Q1 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2024Q1 Start", "2024Q1 End"])

define "2024Q2 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2024Q2 Start", "2024Q2 End"])

define "2024Q3 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2024Q3 Start", "2024Q3 End"])

define "2024Q4 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2024Q4 Start", "2024Q4 End"])

define "2025Q1 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2025Q1 Start", "2025Q1 End"])

define "2025Q2 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2025Q2 Start", "2025Q2 End"])

define "2025Q3 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2025Q3 Start", "2025Q3 End"])

define "2025Q4 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2025Q4 Start", "2025Q4 End"])

define "2026Q1 Denominator":
  Count("All Deliveries" D where GetDischargeDate(D) during Interval["2026Q1 Start", "2026Q1 End"])

// Numerator - Cesarean With Indication Deliveries by Quarter
define "2024Q1 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2024Q1 Start", "2024Q1 End"])

define "2024Q2 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2024Q2 Start", "2024Q2 End"])

define "2024Q3 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2024Q3 Start", "2024Q3 End"])

define "2024Q4 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2024Q4 Start", "2024Q4 End"])

define "2025Q1 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2025Q1 Start", "2025Q1 End"])

define "2025Q2 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2025Q2 Start", "2025Q2 End"])

define "2025Q3 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2025Q3 Start", "2025Q3 End"])

define "2025Q4 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2025Q4 Start", "2025Q4 End"])

define "2026Q1 Numerator":
  Count("Cesarean With Indication Deliveries" C where GetDischargeDate(C) during Interval["2026Q1 Start", "2026Q1 End"])

// Indicator Rate by Quarter
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 
  then "2024Q1 Numerator" / "2024Q1 Denominator" 
  else 0

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 
  then "2024Q2 Numerator" / "2024Q2 Denominator" 
  else 0

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 
  then "2024Q3 Numerator" / "2024Q3 Denominator" 
  else 0

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 
  then "2024Q4 Numerator" / "2024Q4 Denominator" 
  else 0

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 
  then "2025Q1 Numerator" / "2025Q1 Denominator" 
  else 0

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 
  then "2025Q2 Numerator" / "2025Q2 Denominator" 
  else 0

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 
  then "2025Q3 Numerator" / "2025Q3 Denominator" 
  else 0

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 
  then "2025Q4 Numerator" / "2025Q4 Denominator" 
  else 0

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 
  then "2026Q1 Numerator" / "2026Q1 Denominator" 
  else 0

// Indicator Result
define "Indicator Result":
  Tuple {
    indicatorCode: '1138.01',
    indicatorName: '剖腹產率-具適應症',
    indicatorNameEn: 'Cesarean Section Rate - With Medical Indication',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/11/06',
    version: '1.0.0',
    denominatorCriteria: '生產案件數(自然產案件+剖腹產案件)',
    numeratorCriteria: '具適應症之剖腹產案件(不具適應症之剖腹產之外的剖腹產案件)',
    calculationMethod: '具適應症剖腹產 = 所有剖腹產 - 不具適應症剖腹產',
    note: '本項指標含符合適應症及自行要求剖腹產案件，各院所收治產婦之複雜度不同',
    q2024_1_denominator: "2024Q1 Denominator",
    q2024_1_numerator: "2024Q1 Numerator",
    q2024_1_rate: "2024Q1 Rate",
    q2024_2_denominator: "2024Q2 Denominator",
    q2024_2_numerator: "2024Q2 Numerator",
    q2024_2_rate: "2024Q2 Rate",
    q2024_3_denominator: "2024Q3 Denominator",
    q2024_3_numerator: "2024Q3 Numerator",
    q2024_3_rate: "2024Q3 Rate",
    q2024_4_denominator: "2024Q4 Denominator",
    q2024_4_numerator: "2024Q4 Numerator",
    q2024_4_rate: "2024Q4 Rate",
    q2025_1_denominator: "2025Q1 Denominator",
    q2025_1_numerator: "2025Q1 Numerator",
    q2025_1_rate: "2025Q1 Rate",
    q2025_2_denominator: "2025Q2 Denominator",
    q2025_2_numerator: "2025Q2 Numerator",
    q2025_2_rate: "2025Q2 Rate",
    q2025_3_denominator: "2025Q3 Denominator",
    q2025_3_numerator: "2025Q3 Numerator",
    q2025_3_rate: "2025Q3 Rate",
    q2025_4_denominator: "2025Q4 Denominator",
    q2025_4_numerator: "2025Q4 Numerator",
    q2025_4_rate: "2025Q4 Rate",
    q2026_1_denominator: "2026Q1 Denominator",
    q2026_1_numerator: "2026Q1 Numerator",
    q2026_1_rate: "2026Q1 Rate"
  }