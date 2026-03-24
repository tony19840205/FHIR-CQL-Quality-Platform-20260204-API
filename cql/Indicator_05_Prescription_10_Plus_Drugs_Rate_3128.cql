library Indicator_05_Prescription_10_Plus_Drugs_Rate_3128 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 門診每張處方箋開藥品項數大於等於十項之案件比率
// 指標代碼: 3128
// 製作日期：2026-01-09
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署
//
// 【資料時間範圍】
// 查詢期間: 2024-01-01 ~ 2099-12-31 (無限制)
// 統計單位: 每季 (2024Q1-Q4, 2025Q1-Q4, 2026Q1)
// ============================================
//
// 【公式說明】
// 分子: 分母案件中藥品品項數≥10項之案件數
// 分母: 給藥案件數
//
// 給藥案件條件:
// (1)藥費不為0，或給藥天數不為0，或處方調劑方式為1、0、6
//
// 藥品品項數計算:
// (2)醫令檔別1或4且醫令代碼為10碼且醫令令數量>0，取同處方下同醫令代碼户數
//
// 排除條件:
// (1)排除代辦案件
// (2)排除「插報原因註記」為2之案件
//
// 備註:
// ※分子排除下列條件:
// - 重大傷病(部分自擔代碼為001)
// - 居家醫療照護整合計畫(正一特定治療項目代碼為EC)
// - 醫院以病人為中心門診整合照護計畫(整合式照護模式註記:111年7月1日起為Q,R,S;108年起為X,Q,R,S;107年以前為A,B,D,E,F)
// - 急診案件(案件分類為02)
// - 門診手術案件(案件分類為03)
// - 立刻使用處方箋(藥品使用處方箋(SN)使用時機為STAT、PRN)
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'

valueset "Drug Order Types": 'http://nhi.gov.tw/fhir/ValueSet/drug-order-types'
valueset "Dispense Methods": 'http://nhi.gov.tw/fhir/ValueSet/dispense-methods'

code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// 醫令檔別代碼
code "Drug Order Type 1": '1' from "NHI_PROCEDURE" display 'Medication Order - 藥品醫令'
code "Drug Order Type 4": '4' from "NHI_PROCEDURE" display 'Medication Supply - 藥品供應'

// 處方調劑方式代碼
code "Dispense Method 0": '0' from "NHI_CLAIM" display 'General Dispense - 一般調劑'
code "Dispense Method 1": '1' from "NHI_CLAIM" display 'Chronic Continuous Dispense - 慢性病連續調劑'
code "Dispense Method 6": '6' from "NHI_CLAIM" display 'Special Dispense - 特殊調劑'

// 重大傷病代碼
code "Catastrophic Illness 001": '001' from "NHI_CLAIM" display 'Catastrophic Illness - 重大傷病(部分自擔代碼001)'

// 居家醫療代碼
code "Home Care EC": 'EC' from "NHI_PROCEDURE" display 'Home Care - 居家醫療照護整合計畫'

// 整合照護模式代碼
code "Integrated Care Q": 'Q' from "NHI_CLAIM" display 'Integrated Care Q - 整合照護Q'
code "Integrated Care R": 'R' from "NHI_CLAIM" display 'Integrated Care R - 整合照護R'
code "Integrated Care S": 'S' from "NHI_CLAIM" display 'Integrated Care S - 整合照護S'
code "Integrated Care X": 'X' from "NHI_CLAIM" display 'Integrated Care X - 整合照護X'
code "Integrated Care A": 'A' from "NHI_CLAIM" display 'Integrated Care A - 整合照護A'
code "Integrated Care B": 'B' from "NHI_CLAIM" display 'Integrated Care B - 整合照護B'
code "Integrated Care D": 'D' from "NHI_CLAIM" display 'Integrated Care D - 整合照護D'
code "Integrated Care E": 'E' from "NHI_CLAIM" display 'Integrated Care E - 整合照護E'
code "Integrated Care F": 'F' from "NHI_CLAIM" display 'Integrated Care F - 整合照護F'

// 案件分類代碼
code "Claim Type 02": '02' from "NHI_CLAIM" display 'Emergency - 急診'
code "Claim Type 03": '03' from "NHI_CLAIM" display 'Outpatient Surgery - 門診手術'

// 使用時機代碼
code "STAT": 'STAT' from "NHI_CLAIM" display 'Immediately - 立即使用'
code "PRN": 'PRN' from "NHI_CLAIM" display 'As Needed - 需要時使用'

// 插報原因代碼
code "Report Reason 2": '2' from "NHI_CLAIM" display 'Supplementary Report - 插報原因2'

// ============================================
// Quarter Definitions (2024-2026)
// ============================================

define "2024Q1 Start": @2024-01-01
define "2024Q1 End": @2024-03-31
define "2024Q2 Start": @2024-04-01
define "2024Q2 End": @2024-06-30
define "2024Q3 Start": @2024-07-01
define "2024Q3 End": @2024-09-30
define "2024Q4 Start": @2024-10-01
define "2024Q4 End": @2024-12-31

define "2025Q1 Start": @2025-01-01
define "2025Q1 End": @2025-03-31
define "2025Q2 Start": @2025-04-01
define "2025Q2 End": @2025-06-30
define "2025Q3 Start": @2025-07-01
define "2025Q3 End": @2025-09-30
define "2025Q4 Start": @2025-10-01
define "2025Q4 End": @2025-12-31

define "2026Q1 Start": @2026-01-01
define "2026Q1 End": @2026-03-31

// Measurement Period (無限制 - Unlimited)
define "Measurement Period Start": @2024-01-01
define "Measurement Period End": @2099-12-31
define "Measurement Period": Interval["Measurement Period Start", "Measurement Period End"]

// ============================================
// Helper Functions
// ============================================

define function GetId(resource FHIR.Resource):
  Last(Split(resource.id, '/'))

define function Is10DigitDrugCode(code String):
  Length(code) = 10

define function IsDrugOrderType(orderType String):
  orderType in {'1', '4'}

define function IsValidDispenseMethod(method String):
  method in {'0', '1', '6'}

define function GetClaimType(encounter FHIR.Encounter):
  Coalesce(
    First(
      encounter.type T
        return First(T.coding C where C.system = 'http://www.nhi.gov.tw/codes/claim').code.value
    ),
    ''
  )

define function GetReportReason(encounter FHIR.Encounter):
  Coalesce(
    First(
      encounter.extension E
        where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/report-reason'
        return (E.value as FHIR.Coding).code.value
    ),
    ''
  )

define function IsAgencyCase(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
        and E.value = true
  )

define function HasCatastrophicIllness(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/catastrophic-illness'
        and (E.value as FHIR.Coding).code.value = '001'
  )

define function HasHomeCare(encounter FHIR.Encounter):
  exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where C.system.value = 'http://www.nhi.gov.tw/codes/procedure'
              and C.code.value = 'EC'
        )
  )

define function HasIntegratedCare(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/integrated-care'
        and (E.value as FHIR.Coding).code.value in {'Q', 'R', 'S', 'X', 'A', 'B', 'D', 'E', 'F'}
  )

define function IsEmergencyOrSurgery(encounter FHIR.Encounter):
  GetClaimType(encounter) in {'02', '03'}

define function HasStatOrPrnMedication(encounter FHIR.Encounter):
  exists (
    [MedicationRequest] MR
      where GetId(MR.encounter.reference) = GetId(encounter)
        and exists (
          MR.dosageInstruction DI
            where DI.timing.code.coding C
              where C.code.value in {'STAT', 'PRN'}
        )
  )

define function ShouldExcludeFromNumerator(encounter FHIR.Encounter):
  HasCatastrophicIllness(encounter)
    or HasHomeCare(encounter)
    or HasIntegratedCare(encounter)
    or IsEmergencyOrSurgery(encounter)
    or HasStatOrPrnMedication(encounter)

define function GetDrugCost(encounter FHIR.Encounter):
  Sum(
    [Claim] C
      where GetId(C.encounter.reference) = GetId(encounter)
      return Coalesce((C.total.value as FHIR.Money).value.value, 0)
  )

define function GetDrugDays(encounter FHIR.Encounter):
  Max(
    [MedicationRequest] MR
      where GetId(MR.encounter.reference) = GetId(encounter)
      return Coalesce(MR.dispenseRequest.expectedSupplyDuration.value.value, 0)
  )

define function GetDispenseMethod(encounter FHIR.Encounter):
  Coalesce(
    First(
      encounter.extension E
        where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/dispense-method'
        return (E.value as FHIR.Coding).code.value
    ),
    ''
  )

define function IsMedicationCase(encounter FHIR.Encounter):
  GetDrugCost(encounter) != 0
    or GetDrugDays(encounter) != 0
    or IsValidDispenseMethod(GetDispenseMethod(encounter))

define function GetDrugItemCount(encounter FHIR.Encounter):
  Count(
    distinct (
      [MedicationRequest] MR
        where GetId(MR.encounter.reference) = GetId(encounter)
          and MR.status.value = 'completed'
          and exists (
            MR.extension E
              where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/order-type'
                and (E.value as FHIR.Coding).code.value in {'1', '4'}
          )
          and exists (
            MR.medicationCodeableConcept.coding MC
              where Is10DigitDrugCode(MC.code.value)
          )
          and Coalesce(
            First(MR.dosageInstruction).doseAndRate[0].dose.value.value,
            0
          ) > 0
      return First(MR.medicationCodeableConcept.coding).code.value
    )
  )

// ============================================
// Data Retrieval
// ============================================

context Patient

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and start of E.period in "Measurement Period"
      and not IsAgencyCase(E)
      and GetReportReason(E) != '2'

define "Medication Cases":
  "Outpatient Encounters" E
    where IsMedicationCase(E)

define "Cases With 10 Or More Drugs":
  "Medication Cases" E
    where GetDrugItemCount(E) >= 10
      and not ShouldExcludeFromNumerator(E)

// ============================================
// 2024Q1 Statistics
// ============================================

define "2024Q1 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2024Q1 Start", "2024Q1 End"]

define "2024Q1 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2024Q1 Start", "2024Q1 End"]

define "2024Q1 Denominator":
  Count("2024Q1 Medication Cases")

define "2024Q1 Numerator":
  Count("2024Q1 Cases With 10 Plus Drugs")

define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then
    ("2024Q1 Numerator" / "2024Q1 Denominator") * 100
  else null

// ============================================
// 2024Q2 Statistics
// ============================================

define "2024Q2 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2024Q2 Start", "2024Q2 End"]

define "2024Q2 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2024Q2 Start", "2024Q2 End"]

define "2024Q2 Denominator":
  Count("2024Q2 Medication Cases")

define "2024Q2 Numerator":
  Count("2024Q2 Cases With 10 Plus Drugs")

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then
    ("2024Q2 Numerator" / "2024Q2 Denominator") * 100
  else null

// ============================================
// 2024Q3 Statistics
// ============================================

define "2024Q3 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2024Q3 Start", "2024Q3 End"]

define "2024Q3 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2024Q3 Start", "2024Q3 End"]

define "2024Q3 Denominator":
  Count("2024Q3 Medication Cases")

define "2024Q3 Numerator":
  Count("2024Q3 Cases With 10 Plus Drugs")

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then
    ("2024Q3 Numerator" / "2024Q3 Denominator") * 100
  else null

// ============================================
// 2024Q4 Statistics
// ============================================

define "2024Q4 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2024Q4 Start", "2024Q4 End"]

define "2024Q4 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2024Q4 Start", "2024Q4 End"]

define "2024Q4 Denominator":
  Count("2024Q4 Medication Cases")

define "2024Q4 Numerator":
  Count("2024Q4 Cases With 10 Plus Drugs")

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then
    ("2024Q4 Numerator" / "2024Q4 Denominator") * 100
  else null

// ============================================
// 2025Q1 Statistics
// ============================================

define "2025Q1 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2025Q1 Start", "2025Q1 End"]

define "2025Q1 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2025Q1 Start", "2025Q1 End"]

define "2025Q1 Denominator":
  Count("2025Q1 Medication Cases")

define "2025Q1 Numerator":
  Count("2025Q1 Cases With 10 Plus Drugs")

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then
    ("2025Q1 Numerator" / "2025Q1 Denominator") * 100
  else null

// ============================================
// 2025Q2 Statistics
// ============================================

define "2025Q2 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2025Q2 Start", "2025Q2 End"]

define "2025Q2 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2025Q2 Start", "2025Q2 End"]

define "2025Q2 Denominator":
  Count("2025Q2 Medication Cases")

define "2025Q2 Numerator":
  Count("2025Q2 Cases With 10 Plus Drugs")

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then
    ("2025Q2 Numerator" / "2025Q2 Denominator") * 100
  else null

// ============================================
// 2025Q3 Statistics
// ============================================

define "2025Q3 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2025Q3 Start", "2025Q3 End"]

define "2025Q3 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2025Q3 Start", "2025Q3 End"]

define "2025Q3 Denominator":
  Count("2025Q3 Medication Cases")

define "2025Q3 Numerator":
  Count("2025Q3 Cases With 10 Plus Drugs")

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then
    ("2025Q3 Numerator" / "2025Q3 Denominator") * 100
  else null

// ============================================
// 2025Q4 Statistics
// ============================================

define "2025Q4 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2025Q4 Start", "2025Q4 End"]

define "2025Q4 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2025Q4 Start", "2025Q4 End"]

define "2025Q4 Denominator":
  Count("2025Q4 Medication Cases")

define "2025Q4 Numerator":
  Count("2025Q4 Cases With 10 Plus Drugs")

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then
    ("2025Q4 Numerator" / "2025Q4 Denominator") * 100
  else null

// ============================================
// 2026Q1 Statistics
// ============================================

define "2026Q1 Medication Cases":
  "Medication Cases" E
    where start of E.period in Interval["2026Q1 Start", "2026Q1 End"]

define "2026Q1 Cases With 10 Plus Drugs":
  "Cases With 10 Or More Drugs" E
    where start of E.period in Interval["2026Q1 Start", "2026Q1 End"]

define "2026Q1 Denominator":
  Count("2026Q1 Medication Cases")

define "2026Q1 Numerator":
  Count("2026Q1 Cases With 10 Plus Drugs")

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then
    ("2026Q1 Numerator" / "2026Q1 Denominator") * 100
  else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  {
    indicatorCode: '3128',
    indicatorName: '門診每張處方箋開藥品項數大於等於十項之案件比率',
    indicatorNameEn: 'Outpatient Prescription Cases with 10 or More Drug Items Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/11/06',
    version: '1.0.0',
    keyFeature: '多重用藥監測 (≥10品項, 排除重大傷病/居家醫療/整合照護/急診/門診手術/立即使用處方)',
    exclusionCriteria: '重大傷病001, 居家醫療EC, 整合照護Q/R/S/X/A/B/D/E/F, 案件分類02/03, STAT/PRN'
  }
