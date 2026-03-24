library Indicator_11_1_Overall_Cesarean_Section_Rate_1136_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

/*
 * 來源：醫療給付檔案分析系統
 * 指標代碼：1136.01
 * 指標名稱：剖腹產率-整體
 * 製表日期：114/11/06
 * 製表單位：衛生福利部 中央健康保險署
 * 
 * 公式說明:
 * 分子：剖腹產案件數
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
code "Cesarean DRG 513": '513' from "NHI_CLAIM" display 'TW-DRG 513 剖腹產'

// DRG_CODE - Natural Delivery
code "Natural 0373A": '0373A' from "NHI_CLAIM" display 'DRG_CODE 0373A 自然產'
code "Natural 0373C": '0373C' from "NHI_CLAIM" display 'DRG_CODE 0373C 自然產'

// DRG_CODE - Cesarean Delivery
code "Cesarean 0371A": '0371A' from "NHI_CLAIM" display 'DRG_CODE 0371A 剖腹產'
code "Cesarean 0373B": '0373B' from "NHI_CLAIM" display 'DRG_CODE 0373B 剖腹產'

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
code "Cesarean 97014C": '97014C' from "NHI_PROCEDURE" display '剖腹產處置費'

// Helper Functions
define function GetId(encounter Encounter):
  encounter.id.value

define function GetDischargeDate(encounter Encounter):
  encounter.period.end.value

define function GetTWDRG(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/tw-drg'
      return E.value as String
  )

define function GetDRGCode(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/drg-code'
      return E.value as String
  )

define function GetDRGPrefix3(drgCode String):
  if Length(drgCode) >= 3 then Substring(drgCode, 0, 3)
  else drgCode

define function HasNaturalDeliveryProcedure(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + GetId(encounter)
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
      where P.encounter.reference.value = 'Encounter/' + GetId(encounter)
        and exists(
          P.code.coding C
            where C.code.value in {
              '81004C', '81005C', '81028C', '81029C', '97009C', '97014C'
            }
        )
  )

define function IsNaturalDelivery(encounter Encounter):
  let twdrg: GetTWDRG(encounter),
      drgcode: GetDRGCode(encounter),
      drgPrefix: GetDRGPrefix3(twdrg)
  return 
    // Condition a: TW-DRG前三碼為372~375
    drgPrefix in {'372', '373', '374', '375'}
    // Condition b: DRG_CODE為0373A、0373C
    or drgcode in {'0373A', '0373C'}
    // Condition c: 符合任一自然產醫令代碼
    or HasNaturalDeliveryProcedure(encounter)

define function IsCesareanDelivery(encounter Encounter):
  let twdrg: GetTWDRG(encounter),
      drgcode: GetDRGCode(encounter),
      drgPrefix: GetDRGPrefix3(twdrg)
  return 
    // Condition a: TW-DRG前三碼為370、371、513
    drgPrefix in {'370', '371', '513'}
    // Condition b: DRG_CODE為0371A、0373B
    or drgcode in {'0371A', '0373B'}
    // Condition c: 符合任一剖腹產醫令代碼
    or HasCesareanDeliveryProcedure(encounter)

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

// Numerator - Cesarean Deliveries by Quarter
define "2024Q1 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2024Q1 Start", "2024Q1 End"])

define "2024Q2 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2024Q2 Start", "2024Q2 End"])

define "2024Q3 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2024Q3 Start", "2024Q3 End"])

define "2024Q4 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2024Q4 Start", "2024Q4 End"])

define "2025Q1 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2025Q1 Start", "2025Q1 End"])

define "2025Q2 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2025Q2 Start", "2025Q2 End"])

define "2025Q3 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2025Q3 Start", "2025Q3 End"])

define "2025Q4 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2025Q4 Start", "2025Q4 End"])

define "2026Q1 Numerator":
  Count("Cesarean Deliveries" C where GetDischargeDate(C) during Interval["2026Q1 Start", "2026Q1 End"])

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
    indicatorCode: '1136.01',
    indicatorName: '剖腹產率-整體',
    indicatorNameEn: 'Overall Cesarean Section Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/11/06',
    version: '1.0.0',
    denominatorCriteria: '生產案件數(自然產案件+剖腹產案件)',
    numeratorCriteria: '剖腹產案件數',
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
 * 
 * 公式說明:
 * 剖腹產率 = 
 *     分子: 剖腹產案件數
 *     分母: 生產案件數(自然產案件+剖腹產案件)
 * 
 * (1) 自然產案件：符合下列任一條件：
 *     a.TW-DRG前三碼為372~375
 *     b.DRG_CODE為0373A、0373C
 *     c.符合任一自然產醫令代碼：81017C、81018C、81019C、81024C、81025C、81026C、81034C、97004C、97005D、97934C
 * 
 * (2) 剖腹產案件：符合下列任一條件：
 *     a.TW-DRG前三碼為370、371、513
 *     b.DRG_CODE為0371A、0373B
 *     c.符合任一剖腹產醫令代碼：81004C、81005C、81028C、81029C、97009C、97014C
 * 
 * 備註:
 * - 本項指標含符合應催症及自行要求剖腹產案件
 * - 各院所收治產婦之複雜度不同，故觀察結果也不同
 * - 本項指標不宜逕予判斷院所生產照護品質
 * 
 * 臨床意義:
 * - 監測剖腹產使用趨勢
 * - 評估生產方式選擇適當性
 * - 辨識可能過度使用剖腹產的情況
 * - 促進自然產的推廣
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料（產婦）
 * - Encounter: 住院生產紀錄
 * - Procedure: 手術處置資料（剖腹產、自然產）
 * - Condition: 診斷資料
 * - Claim: 醫療費用申報（DRG代碼）
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 1136.01 (指標代碼)

codesystem "TW_DRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'
    -- 台灣診斷關聯群（TW-DRG）代碼系統
    -- 370, 371, 513: 剖腹產DRG
    -- 372, 373, 374, 375: 自然產DRG

codesystem "DRG_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'
    -- DRG明細代碼系統
    -- 0373A, 0373C: 自然產
    -- 0371A, 0373B: 剖腹產

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- O80-O84: 分娩相關診斷
    -- O82: 剖腹產分娩
    -- O80: 單胎自然分娩

codesystem "ICD10PCS": 'http://hl7.org/fhir/sid/icd-10-pcs'
    -- ICD-10-PCS 處置代碼系統
    -- 10D00Z0-10D00Z2: 剖腹產
    -- 10E0XZZ: 陰道分娩

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 11466000: Cesarean section (剖腹產)
    -- 177141003: Elective cesarean section (選擇性剖腹產)
    -- 177152005: Emergency cesarean section (緊急剖腹產)
    -- 62508004: Cesarean hysterectomy (剖腹產子宮切除術)
    -- 40219000: Classical cesarean section (傳統式剖腹產)
    -- 18946005: Lower segment cesarean section (下段剖腹產)
    -- 3311000175109: Cesarean section following previous cesarean section (前次剖腹產後再次剖腹產)
    -- 302383004: Delivery normal (正常分娩)
    -- 289253008: Spontaneous vaginal delivery (自然陰道分娩)
    -- 236974004: Instrumental delivery (器械輔助分娩)
    -- 274130007: Emergency cesarean hysterectomy (緊急剖腹產子宮切除術)
    -- 177157004: Vaginal delivery (陰道分娩)
    -- 236973005: Normal vaginal delivery (正常陰道分娩)
    -- 289256000: Forceps delivery (產鉗助產)
    -- 61586001: Vacuum extraction delivery (真空吸引助產)
    -- 384729004: Delivery of product of conception (分娩)
    -- 200144004: Obstetric delivery (產科分娩)

codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
    -- Current Procedural Terminology 處置代碼系統
    -- 59510: Cesarean delivery (剖腹產)
    -- 59514: Cesarean delivery with postpartum care (剖腹產含產後照護)
    -- 59515: Cesarean delivery with antepartum and postpartum care (剖腹產含產前產後照護)
    -- 59400: Vaginal delivery (陰道分娩)
    -- 59409: Vaginal delivery with episiotomy (陰道分娩含會陰切開)
    -- 59410: Vaginal delivery including postpartum care (陰道分娩含產後照護)
    -- 59612: Vaginal delivery after previous cesarean (前次剖腹產後陰道分娩 VBAC)
    -- 59620: Cesarean delivery after attempted vaginal delivery (嘗試陰道分娩後改剖腹產)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode 代碼系統
    -- IMP: 住院 (Inpatient)
    -- OBSENC: Obstetrics encounter (產科就醫)

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
    -- 台灣健保局專用代碼系統
    -- 醫事機構代碼
    -- 醫療服務代碼

codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
    -- 健保處置代碼系統
    -- 自然產醫令代碼
    -- 81017C: 自然產接生
    -- 81018C: 自然產接生(含會陰切開)
    -- 81019C: 自然產接生(含會陰修補)
    -- 81024C: 產鉗助產
    -- 81025C: 真空吸引助產
    -- 81026C: 臀位牽引術
    -- 81034C: 複雜性陰道分娩
    -- 97004C: 自然產接生費
    -- 97005D: 陰道分娩
    -- 97934C: 產科接生處置
    -- 剖腹產醫令代碼
    -- 81004C: 剖腹產術
    -- 81005C: 剖腹產合併子宮切除
    -- 81028C: 選擇性剖腹產
    -- 81029C: 緊急剖腹產
    -- 97009C: 剖腹產手術費
    -- 97014C: 剖腹產處置費

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- I: 住院

codesystem "LOINC": 'http://loinc.org'
    -- Logical Observation Identifiers Names and Codes
    -- 11636-8: Delivery method (分娩方式)
    -- 73761-9: Type of cesarean section (剖腹產類型)
    -- 57074-7: Indication for cesarean section (剖腹產適應症)

-- ==================== 代碼定義 ====================

-- ==================== 健保指標代碼 ====================

code "Indicator_1136_01": '1136.01' from "NHI_INDICATOR" display '剖腹產率-整體'

-- ==================== TW-DRG代碼（自然產）====================

code "Natural_Delivery_DRG_372": '372' from "TW_DRG" display '自然產DRG-372'
code "Natural_Delivery_DRG_373": '373' from "TW_DRG" display '自然產DRG-373'
code "Natural_Delivery_DRG_374": '374' from "TW_DRG" display '自然產DRG-374'
code "Natural_Delivery_DRG_375": '375' from "TW_DRG" display '自然產DRG-375'

-- ==================== TW-DRG代碼（剖腹產）====================

code "Cesarean_DRG_370": '370' from "TW_DRG" display '剖腹產DRG-370'
code "Cesarean_DRG_371": '371' from "TW_DRG" display '剖腹產DRG-371'
code "Cesarean_DRG_513": '513' from "TW_DRG" display '剖腹產DRG-513'

-- ==================== DRG_CODE代碼 ====================

code "Natural_Delivery_0373A": '0373A' from "DRG_CODE" display '自然產-0373A'
code "Natural_Delivery_0373C": '0373C' from "DRG_CODE" display '自然產-0373C'
code "Cesarean_0371A": '0371A' from "DRG_CODE" display '剖腹產-0371A'
code "Cesarean_0373B": '0373B' from "DRG_CODE" display '剖腹產-0373B'

-- ==================== ICD-10-CM 分娩診斷代碼 ====================

code "Single_Spontaneous_Delivery": 'O80' from "ICD10CM" display '單胎自然分娩'
code "Single_Delivery_By_Forceps": 'O81' from "ICD10CM" display '單胎產鉗助產'
code "Single_Delivery_By_Cesarean": 'O82' from "ICD10CM" display '單胎剖腹產分娩'
code "Other_Assisted_Single_Delivery": 'O83' from "ICD10CM" display '其他輔助性單胎分娩'
code "Multiple_Delivery": 'O84' from "ICD10CM" display '多胎分娩'

-- ==================== ICD-10-PCS 處置代碼 ====================

code "Cesarean_Classic": '10D00Z0' from "ICD10PCS" display '傳統式剖腹產'
code "Cesarean_Low_Cervical": '10D00Z1' from "ICD10PCS" display '低位頸段剖腹產'
code "Cesarean_Extraperitoneal": '10D00Z2' from "ICD10PCS" display '腹膜外剖腹產'
code "Vaginal_Delivery": '10E0XZZ' from "ICD10PCS" display '陰道分娩'

-- ==================== SNOMED CT 代碼 ====================

code "Cesarean_Section": '11466000' from "SNOMEDCT" display '剖腹產'
code "Elective_Cesarean": '177141003' from "SNOMEDCT" display '選擇性剖腹產'
code "Emergency_Cesarean": '177152005' from "SNOMEDCT" display '緊急剖腹產'
code "Cesarean_Hysterectomy": '62508004' from "SNOMEDCT" display '剖腹產子宮切除術'
code "Classical_Cesarean": '40219000' from "SNOMEDCT" display '傳統式剖腹產'
code "Lower_Segment_Cesarean": '18946005' from "SNOMEDCT" display '下段剖腹產'
code "Repeat_Cesarean": '3311000175109' from "SNOMEDCT" display '重複剖腹產'
code "Emergency_Cesarean_Hysterectomy": '274130007' from "SNOMEDCT" display '緊急剖腹產子宮切除術'
code "Normal_Delivery": '302383004' from "SNOMEDCT" display '正常分娩'
code "Spontaneous_Vaginal_Delivery": '289253008' from "SNOMEDCT" display '自然陰道分娩'
code "Instrumental_Delivery": '236974004' from "SNOMEDCT" display '器械輔助分娩'
code "Vaginal_Delivery_SNOMED": '177157004' from "SNOMEDCT" display '陰道分娩'
code "Normal_Vaginal_Delivery": '236973005' from "SNOMEDCT" display '正常陰道分娩'
code "Forceps_Delivery": '289256000' from "SNOMEDCT" display '產鉗助產'
code "Vacuum_Extraction": '61586001' from "SNOMEDCT" display '真空吸引助產'
code "Delivery_Of_Product": '384729004' from "SNOMEDCT" display '分娩'
code "Obstetric_Delivery": '200144004' from "SNOMEDCT" display '產科分娩'

-- ==================== CPT 處置代碼 ====================

code "CPT_Cesarean_Delivery": '59510' from "CPT" display '剖腹產'
code "CPT_Cesarean_With_Postpartum": '59514' from "CPT" display '剖腹產含產後照護'
code "CPT_Cesarean_Complete": '59515' from "CPT" display '剖腹產含產前產後照護'
code "CPT_Vaginal_Delivery": '59400' from "CPT" display '陰道分娩'
code "CPT_Vaginal_With_Episiotomy": '59409' from "CPT" display '陰道分娩含會陰切開'
code "CPT_Vaginal_With_Postpartum": '59410' from "CPT" display '陰道分娩含產後照護'
code "CPT_VBAC": '59612' from "CPT" display '前次剖腹產後陰道分娩'
code "CPT_Cesarean_After_Trial": '59620' from "CPT" display '嘗試陰道分娩後改剖腹產'

-- ==================== 健保處置代碼（自然產）====================

code "NHI_Natural_Delivery_81017C": '81017C' from "NHI_PROCEDURE" display '自然產接生'
code "NHI_Natural_Delivery_81018C": '81018C' from "NHI_PROCEDURE" display '自然產接生(含會陰切開)'
code "NHI_Natural_Delivery_81019C": '81019C' from "NHI_PROCEDURE" display '自然產接生(含會陰修補)'
code "NHI_Forceps_Delivery_81024C": '81024C' from "NHI_PROCEDURE" display '產鉗助產'
code "NHI_Vacuum_Delivery_81025C": '81025C' from "NHI_PROCEDURE" display '真空吸引助產'
code "NHI_Breech_Extraction_81026C": '81026C' from "NHI_PROCEDURE" display '臀位牽引術'
code "NHI_Complex_Vaginal_81034C": '81034C' from "NHI_PROCEDURE" display '複雜性陰道分娩'
code "NHI_Natural_Fee_97004C": '97004C' from "NHI_PROCEDURE" display '自然產接生費'
code "NHI_Vaginal_Delivery_97005D": '97005D' from "NHI_PROCEDURE" display '陰道分娩'
code "NHI_Obstetric_Procedure_97934C": '97934C' from "NHI_PROCEDURE" display '產科接生處置'

-- ==================== 健保處置代碼（剖腹產）====================

code "NHI_Cesarean_81004C": '81004C' from "NHI_PROCEDURE" display '剖腹產術'
code "NHI_Cesarean_Hysterectomy_81005C": '81005C' from "NHI_PROCEDURE" display '剖腹產合併子宮切除'
code "NHI_Elective_Cesarean_81028C": '81028C' from "NHI_PROCEDURE" display '選擇性剖腹產'
code "NHI_Emergency_Cesarean_81029C": '81029C' from "NHI_PROCEDURE" display '緊急剖腹產'
code "NHI_Cesarean_Fee_97009C": '97009C' from "NHI_PROCEDURE" display '剖腹產手術費'
code "NHI_Cesarean_Procedure_97014C": '97014C' from "NHI_PROCEDURE" display '剖腹產處置費'

-- ==================== ActCode ====================

code "Inpatient": 'IMP' from "ActCode" display '住院'
code "Obstetrics_Encounter": 'OBSENC' from "ActCode" display '產科就醫'

-- ==================== LOINC 觀察代碼 ====================

code "Delivery_Method": '11636-8' from "LOINC" display '分娩方式'
code "Cesarean_Type": '73761-9' from "LOINC" display '剖腹產類型'
code "Cesarean_Indication": '57074-7' from "LOINC" display '剖腹產適應症'

-- ==================== 參數定義 ====================

parameter "Measurement Period" Interval<DateTime>
    -- 統計期間（季度或年度）

-- ==================== 統計期間定義 ====================

define quarters AS (
    List<Tuple {
        id: Integer,
        label: String,
        start_date: DateTime,
        end_date: DateTime
    }> {
        { id: 1, label: '113年第1季', start_date: @2024-01-01T00:00:00, end_date: @2024-03-31T23:59:59 },
        { id: 2, label: '113年第2季', start_date: @2024-04-01T00:00:00, end_date: @2024-06-30T23:59:59 },
        { id: 3, label: '113年第3季', start_date: @2024-07-01T00:00:00, end_date: @2024-09-30T23:59:59 },
        { id: 4, label: '113年第4季', start_date: @2024-10-01T00:00:00, end_date: @2024-12-31T23:59:59 }
    }
)

define annual_period AS (
    Tuple {
        id: 5,
        label: '113年',
        start_date: @2024-01-01T00:00:00,
        end_date: @2024-12-31T23:59:59
    }
)

-- ==================== FHIR資源查詢 ====================

-- 1. 所有住院生產案件
define all_delivery_encounters AS (
    [Encounter: class = "Inpatient"] E
    where E.status = 'finished'
        and E.period.end during "Measurement Period"
        and (
            -- 包含產科相關類型
            exists (E.type T where T.coding C where C.code = 'OBSENC')
            or
            -- 或包含分娩相關診斷
            exists (
                E.diagnosis D
                where D.condition.resolve().code.coding Coding
                    where Coding.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                        and (
                            Coding.code starts with 'O80'
                            or Coding.code starts with 'O81'
                            or Coding.code starts with 'O82'
                            or Coding.code starts with 'O83'
                            or Coding.code starts with 'O84'
                        )
            )
            or
            -- 或包含分娩相關處置
            exists (
                [Procedure: encounter.reference = ('Encounter/' + E.id)] P
                where P.code.coding C
                    where C.system in {
                        'http://snomed.info/sct',
                        'http://www.ama-assn.org/go/cpt',
                        'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                    }
                    and (
                        C.code in {
                            '11466000', '177141003', '177152005', '62508004', '40219000', '18946005',
                            '289253008', '236974004', '177157004', '236973005', '289256000', '61586001',
                            '59510', '59514', '59515', '59400', '59409', '59410', '59612', '59620',
                            '81017C', '81018C', '81019C', '81024C', '81025C', '81026C', '81034C',
                            '97004C', '97005D', '97934C', '81004C', '81005C', '81028C', '81029C',
                            '97009C', '97014C'
                        }
                    )
            )
        )
)

-- ==================== 自然產案件判定 ====================

-- 2. 自然產案件（符合任一條件）
define natural_delivery_cases AS (
    all_delivery_encounters E
    where (
        -- 條件a: TW-DRG前三碼為372~375
        exists (
            E.account.resolve().extension Ext
            where Ext.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/tw-drg'
                and (
                    Ext.valueString starts with '372'
                    or Ext.valueString starts with '373'
                    or Ext.valueString starts with '374'
                    or Ext.valueString starts with '375'
                )
        )
        or
        -- 條件b: DRG_CODE為0373A、0373C
        exists (
            E.account.resolve().extension Ext
            where Ext.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code'
                and Ext.valueString in { '0373A', '0373C' }
        )
        or
        -- 條件c: 符合任一自然產醫令代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                    and C.code in {
                        '81017C', '81018C', '81019C', '81024C', '81025C',
                        '81026C', '81034C', '97004C', '97005D', '97934C'
                    }
        )
        or
        -- 額外判定: SNOMED CT 自然產相關代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://snomed.info/sct'
                    and C.code in {
                        '302383004',  -- Normal delivery
                        '289253008',  -- Spontaneous vaginal delivery
                        '236974004',  -- Instrumental delivery
                        '177157004',  -- Vaginal delivery
                        '236973005',  -- Normal vaginal delivery
                        '289256000',  -- Forceps delivery
                        '61586001'    -- Vacuum extraction
                    }
        )
        or
        -- 額外判定: CPT 自然產相關代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://www.ama-assn.org/go/cpt'
                    and C.code in {
                        '59400',  -- Vaginal delivery
                        '59409',  -- Vaginal with episiotomy
                        '59410',  -- Vaginal with postpartum care
                        '59612'   -- VBAC
                    }
        )
        or
        -- 額外判定: ICD-10-PCS 陰道分娩
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-pcs'
                    and C.code = '10E0XZZ'
        )
        or
        -- 額外判定: ICD-10-CM 診斷代碼 O80, O81, O83
        exists (
            E.diagnosis D
            where D.condition.resolve().code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        C.code starts with 'O80'
                        or C.code starts with 'O81'
                        or C.code starts with 'O83'
                    )
        )
    )
)

-- ==================== 剖腹產案件判定 ====================

-- 3. 剖腹產案件（符合任一條件）
define cesarean_delivery_cases AS (
    all_delivery_encounters E
    where (
        -- 條件a: TW-DRG前三碼為370、371、513
        exists (
            E.account.resolve().extension Ext
            where Ext.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/tw-drg'
                and (
                    Ext.valueString starts with '370'
                    or Ext.valueString starts with '371'
                    or Ext.valueString starts with '513'
                )
        )
        or
        -- 條件b: DRG_CODE為0371A、0373B
        exists (
            E.account.resolve().extension Ext
            where Ext.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code'
                and Ext.valueString in { '0371A', '0373B' }
        )
        or
        -- 條件c: 符合任一剖腹產醫令代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                    and C.code in {
                        '81004C', '81005C', '81028C', '81029C', '97009C', '97014C'
                    }
        )
        or
        -- 額外判定: SNOMED CT 剖腹產相關代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://snomed.info/sct'
                    and C.code in {
                        '11466000',     -- Cesarean section
                        '177141003',    -- Elective cesarean
                        '177152005',    -- Emergency cesarean
                        '62508004',     -- Cesarean hysterectomy
                        '40219000',     -- Classical cesarean
                        '18946005',     -- Lower segment cesarean
                        '3311000175109', -- Repeat cesarean
                        '274130007'     -- Emergency cesarean hysterectomy
                    }
        )
        or
        -- 額外判定: CPT 剖腹產相關代碼
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://www.ama-assn.org/go/cpt'
                    and C.code in {
                        '59510',  -- Cesarean delivery
                        '59514',  -- Cesarean with postpartum
                        '59515',  -- Cesarean complete
                        '59620'   -- Cesarean after trial
                    }
        )
        or
        -- 額外判定: ICD-10-PCS 剖腹產
        exists (
            [Procedure: encounter.reference = ('Encounter/' + E.id)] P
            where P.code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-pcs'
                    and C.code in { '10D00Z0', '10D00Z1', '10D00Z2' }
        )
        or
        -- 額外判定: ICD-10-CM 診斷代碼 O82
        exists (
            E.diagnosis D
            where D.condition.resolve().code.coding C
                where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and C.code starts with 'O82'
        )
    )
)

-- ==================== 分母計算 (Denominator) ====================

-- 分母：生產案件數（自然產+剖腹產）
define denominator_total_deliveries AS (
    natural_delivery_cases union cesarean_delivery_cases
)

define denominator_count AS (
    SELECT 
        COUNT(*) as total_delivery_count,
        COUNT(DISTINCT subject.reference) as unique_patient_count,
        COUNT(DISTINCT serviceProvider.reference) as unique_hospital_count
    FROM 
        denominator_total_deliveries
)

-- 按季度統計分母
define denominator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        start_date: Q.start_date,
        end_date: Q.end_date,
        total_delivery_count: Count(
            denominator_total_deliveries D
            where D.period.end >= Q.start_date and D.period.end <= Q.end_date
        ),
        natural_delivery_count: Count(
            natural_delivery_cases N
            where N.period.end >= Q.start_date and N.period.end <= Q.end_date
        ),
        cesarean_delivery_count: Count(
            cesarean_delivery_cases C
            where C.period.end >= Q.start_date and C.period.end <= Q.end_date
        )
    }
)

-- 年度統計分母
define denominator_annual AS (
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        start_date: annual_period.start_date,
        end_date: annual_period.end_date,
        total_delivery_count: Count(
            denominator_total_deliveries D
            where D.period.end >= annual_period.start_date 
                and D.period.end <= annual_period.end_date
        ),
        natural_delivery_count: Count(
            natural_delivery_cases N
            where N.period.end >= annual_period.start_date 
                and N.period.end <= annual_period.end_date
        ),
        cesarean_delivery_count: Count(
            cesarean_delivery_cases C
            where C.period.end >= annual_period.start_date 
                and C.period.end <= annual_period.end_date
        )
    }
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子：剖腹產案件數
define numerator_cesarean_deliveries AS (
    cesarean_delivery_cases
)

define numerator_count AS (
    SELECT 
        COUNT(*) as cesarean_count,
        COUNT(DISTINCT subject.reference) as unique_patient_count
    FROM 
        numerator_cesarean_deliveries
)

-- 按季度統計分子
define numerator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        cesarean_count: Count(
            numerator_cesarean_deliveries C
            where C.period.end >= Q.start_date and C.period.end <= Q.end_date
        )
    }
)

-- 年度統計分子
define numerator_annual AS (
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        cesarean_count: Count(
            numerator_cesarean_deliveries C
            where C.period.end >= annual_period.start_date 
                and C.period.end <= annual_period.end_date
        )
    }
)

-- ==================== 指標計算 (Indicator Calculation) ====================

-- 按季度計算剖腹產率
define indicator_by_quarter AS (
    (numerator_by_quarter N join denominator_by_quarter D on N.quarter_id = D.quarter_id)
    return {
        indicator_code: "Indicator_1136_01",
        quarter_id: N.quarter_id,
        quarter_label: N.quarter_label,
        numerator: N.cesarean_count,
        denominator: D.total_delivery_count,
        natural_delivery_count: D.natural_delivery_count,
        cesarean_delivery_count: D.cesarean_delivery_count,
        rate: if D.total_delivery_count > 0 
              then Round((N.cesarean_count / D.total_delivery_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((N.cesarean_count / D.total_delivery_count) * 100, 2)) + '%'
    }
)

-- 年度計算剖腹產率
define indicator_annual AS (
    {
        indicator_code: "Indicator_1136_01",
        period_label: numerator_annual.period_label,
        numerator: numerator_annual.cesarean_count,
        denominator: denominator_annual.total_delivery_count,
        natural_delivery_count: denominator_annual.natural_delivery_count,
        cesarean_delivery_count: denominator_annual.cesarean_delivery_count,
        rate: if denominator_annual.total_delivery_count > 0 
              then Round((numerator_annual.cesarean_count / denominator_annual.total_delivery_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((numerator_annual.cesarean_count / denominator_annual.total_delivery_count) * 100, 2)) + '%'
    }
)

-- ==================== 綜合結果 ====================

-- 所有期間的指標結果
define all_periods_results AS (
    indicator_by_quarter 
    union 
    { indicator_annual }
)

-- ==================== 進階分析 ====================

-- 剖腹產類型分析
define cesarean_type_analysis AS (
    numerator_cesarean_deliveries C
    let elective := exists (
        [Procedure: encounter.reference = ('Encounter/' + C.id)] P
        where P.code.coding Coding
            where (Coding.code = '177141003' and Coding.system = 'http://snomed.info/sct')
                or (Coding.code = '81028C' and Coding.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure')
    ),
    emergency := exists (
        [Procedure: encounter.reference = ('Encounter/' + C.id)] P
        where P.code.coding Coding
            where (Coding.code = '177152005' and Coding.system = 'http://snomed.info/sct')
                or (Coding.code = '81029C' and Coding.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure')
    )
    return {
        encounter_id: C.id,
        patient_id: C.subject.reference,
        organization_id: C.serviceProvider.reference,
        delivery_date: C.period.end,
        cesarean_type: if elective then '選擇性剖腹產'
                      else if emergency then '緊急剖腹產'
                      else '一般剖腹產'
    }
)

-- 醫院剖腹產率排名
define hospital_cesarean_rate_ranking AS (
    cesarean_delivery_cases C
    return {
        organization_id: C.serviceProvider.reference,
        cesarean_count: Count(C),
        total_delivery_count: Count(denominator_total_deliveries D where D.serviceProvider.reference = C.serviceProvider.reference),
        cesarean_rate: Round((Count(C) / Count(denominator_total_deliveries D where D.serviceProvider.reference = C.serviceProvider.reference)) * 100, 2)
    }
    group by organization_id
    sort by cesarean_rate desc
)

-- 產婦年齡分布分析
define maternal_age_distribution AS (
    denominator_total_deliveries D
    let patient := D.subject.resolve(),
        birth_date := patient.birthDate,
        delivery_date := D.period.end,
        age := years between birth_date and delivery_date
    return {
        age_group: if age < 20 then '<20歲'
                   else if age >= 20 and age < 25 then '20-24歲'
                   else if age >= 25 and age < 30 then '25-29歲'
                   else if age >= 30 and age < 35 then '30-34歲'
                   else if age >= 35 and age < 40 then '35-39歲'
                   else '≥40歲',
        is_cesarean: D in cesarean_delivery_cases,
        delivery_count: Count(D)
    }
    group by age_group
)

-- ==================== 主要輸出 ====================

/*
 * 主要指標結果
 * 包含季度和年度的剖腹產率
 */
define "Main Output" AS (
    all_periods_results
)

/*
 * 詳細剖腹產案件清單
 */
define "Detailed Cesarean List" AS (
    cesarean_type_analysis
)

/*
 * 醫院剖腹產率排名
 */
define "Hospital Ranking" AS (
    hospital_cesarean_rate_ranking
)

/*
 * 產婦年齡分布
 */
define "Age Distribution" AS (
    maternal_age_distribution
)
