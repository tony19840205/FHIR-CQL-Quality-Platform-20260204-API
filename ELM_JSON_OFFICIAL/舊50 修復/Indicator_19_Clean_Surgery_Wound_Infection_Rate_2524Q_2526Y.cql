library Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 清淨手術傷口感染率
// 指標代碼: 2524 (季)、2526 (年)
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍: 醫院總額之住院案件，排除膳食費案件
//
// 分母: 執行清淨手術之人數
//   清淨手術分三組(任一滿足)，但排除下列:
//   (i)  主診斷碼前3碼為C40、C41、D65-D68或全碼C79.51-C79.52、R79.1
//   (ii) 任一主次診斷碼為中耳炎(H65-H69)或肺炎(J12-J18)或UTI(N30、N34、N39.0)
//
// 分子: 執行清淨手術且傷口感染之人數
//
// 清淨手術三組說明:
//   (1) 腦神經手術: PCS碼0YQ*/0GBJ*/0GTJ* + 支付標準碼 75607C/75610B/75613C/75614C/75615C/88029C
//   (2) 甲狀腺/副甲狀腺手術: PCS碼0GBG*/0GBH*/0GTG*/0GTH*/0GTK* + E00-E07/E35/E89.0診斷
//       + 支付標準碼 82001C/82002C/82003C/82004B/82008B/82015B/82016B/66012B/66013B/66014B/66023B
//   (3) 關節置換手術: PCS碼0SR*/XRRG*/XRRH* + 支付標準碼 64162B/64164B/64169B/64170B
//
// ※ 自114年第1季起配合ICD-10-CM/PCS 2023年版重新計算
// ============================================

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

// ============================================
// Helper Functions
// ============================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetEncounterStart(E FHIR.Encounter):
  if E.period is not null then E.period.start.value
  else null

// ---- Group 1: 腦神經清淨手術 支付標準碼 ----
define function IsGroup1OrderCode(code String):
  code in {
    '75607C', '75610B', '75613C', '75614C', '75615C', '88029C'
  }

// ---- Group 2: 甲狀腺/副甲狀腺清淨手術 支付標準碼 ----
define function IsGroup2OrderCode(code String):
  code in {
    '82001C', '82002C', '82003C', '82004B', '82008B',
    '82015B', '82016B',
    '66012B', '66013B', '66014B', '66023B'
  }

// ---- Group 2: 需要主診斷為 E00-E07、E35、全碼 E89.0 ----
define function IsGroup2DiagCode(code String):
  code is not null
  and (
    Substring(code, 0, 3) in {
      'E00', 'E01', 'E02', 'E03', 'E04', 'E05', 'E06', 'E07', 'E35'
    }
    or code = 'E89.0'
  )

// ---- Group 3: 關節置換清淨手術 支付標準碼 ----
define function IsGroup3OrderCode(code String):
  code in {
    '64162B', '64164B', '64169B', '64170B'
  }

// ---- 排除 (i): 主診斷碼 C40、C41、D65-D68、C79.51、C79.52、R79.1 ----
define function IsExclusionMainDiag(code String):
  code is not null
  and (
    Substring(code, 0, 3) in {'C40', 'C41', 'D65', 'D66', 'D67', 'D68'}
    or code in {'C79.51', 'C79.52', 'R79.1'}
  )

// ---- 排除 (ii): 任一主次診斷碼 中耳炎(H65-H69)、肺炎(J12-J18)、UTI(N30、N34、N39.0) ----
define function IsExclusionAnyDiag(code String):
  code is not null
  and (
    (Substring(code, 0, 1) = 'H'
      and Substring(code, 1, 2) >= '65'
      and Substring(code, 1, 2) <= '69')
    or (Substring(code, 0, 1) = 'J'
      and Substring(code, 1, 2) >= '12'
      and Substring(code, 1, 2) <= '18')
    or Substring(code, 0, 3) in {'N30', 'N34'}
    or code = 'N39.0'
  )

// ---- 傷口感染診斷碼 (ICD-10-CM 2023年版) ----
define function IsWoundInfectionCode(code String):
  code in {
    'K68.11', 'R50.84',
    'T80.211A', 'T80.212A', 'T80.218A', 'T80.219A', 'T80.22XA',
    'T81.30XA', 'T81.31XA', 'T81.32XA', 'T81.33XA',
    'T81.40XA', 'T81.41XA', 'T81.42XA', 'T81.43XA', 'T81.44XA', 'T81.49XA',
    'T82.6XXA', 'T82.7XXA',
    'T83.510A', 'T83.511A', 'T83.512A', 'T83.518A',
    'T83.590A', 'T83.591A', 'T83.592A', 'T83.593A', 'T83.598A',
    'T83.61XA', 'T83.62XA', 'T83.69XA',
    'T84.50XA', 'T84.51XA', 'T84.52XA', 'T84.53XA', 'T84.54XA', 'T84.59XA',
    'T84.60XA',
    'T84.610A', 'T84.611A', 'T84.612A', 'T84.613A', 'T84.614A', 'T84.615A', 'T84.619A',
    'T84.620A', 'T84.621A', 'T84.622A', 'T84.623A', 'T84.624A', 'T84.625A', 'T84.629A',
    'T84.63XA', 'T84.69XA', 'T84.7XXA',
    'T85.71XA', 'T85.72XA',
    'T85.730A', 'T85.731A', 'T85.732A', 'T85.733A', 'T85.734A', 'T85.735A', 'T85.738A',
    'T85.79XA',
    'T86.8421', 'T86.8422', 'T86.8423', 'T86.8429'
  }

// ============================================
// Clean Surgery Inpatient Encounters (Denominator Base)
// ============================================

define "Clean Surgery Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and (
        // Group 1: 腦神經手術
        exists (
          [Procedure] P
            where P.encounter.reference.value = 'Encounter/' + E.id.value
              and P.status.value = 'completed'
              and exists (
                P.code.coding C where IsGroup1OrderCode(C.code.value)
              )
        )
        // Group 2: 甲狀腺/副甲狀腺手術 (需E00-E07/E35/E89.0診斷)
        or (
          exists (
            [Procedure] P
              where P.encounter.reference.value = 'Encounter/' + E.id.value
                and P.status.value = 'completed'
                and exists (
                  P.code.coding C where IsGroup2OrderCode(C.code.value)
                )
          )
          and exists (
            [Condition] C
              where C.encounter.reference.value = 'Encounter/' + E.id.value
                and exists (
                  C.code.coding CD where IsGroup2DiagCode(CD.code.value)
                )
          )
        )
        // Group 3: 關節置換手術
        or exists (
          [Procedure] P
            where P.encounter.reference.value = 'Encounter/' + E.id.value
              and P.status.value = 'completed'
              and exists (
                P.code.coding C where IsGroup3OrderCode(C.code.value)
              )
        )
      )
      // 排除: C40/C41/D65-D68/C79.51-C79.52/R79.1 及 H65-H69/J12-J18/N30/N34/N39.0
      and not exists (
        [Condition] C
          where C.encounter.reference.value = 'Encounter/' + E.id.value
            and exists (
              C.code.coding CD
                where IsExclusionMainDiag(CD.code.value)
                  or IsExclusionAnyDiag(CD.code.value)
            )
      )

// ============================================
// Wound Infection Conditions
// ============================================

define "Wound Infection Conditions":
  [Condition] C
    where exists (
      C.code.coding CD
        where IsWoundInfectionCode(CD.code.value)
    )

// ============================================
// Clean Surgery With Wound Infection (Numerator Base)
// ============================================

define "Clean Surgery With Infection":
  "Clean Surgery Inpatient Encounters" E
    where exists (
      "Wound Infection Conditions" C
        where C.encounter.reference.value = 'Encounter/' + E.id.value
    )

// ============================================
// Overall Denominator / Numerator / Rate
// ============================================

define "Total Denominator":
  Count("Clean Surgery Inpatient Encounters")

define "Total Numerator":
  Count("Clean Surgery With Infection")

define "Overall Rate":
  if "Total Denominator" > 0
  then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100
  else null

// ============================================
// Quarterly Date Ranges
// ============================================

define "2024Q1 Start": DateTime(2024, 1, 1, 0, 0, 0, 0)
define "2024Q1 End":   DateTime(2024, 3, 31, 23, 59, 59, 999)
define "2024Q2 Start": DateTime(2024, 4, 1, 0, 0, 0, 0)
define "2024Q2 End":   DateTime(2024, 6, 30, 23, 59, 59, 999)
define "2024Q3 Start": DateTime(2024, 7, 1, 0, 0, 0, 0)
define "2024Q3 End":   DateTime(2024, 9, 30, 23, 59, 59, 999)
define "2024Q4 Start": DateTime(2024, 10, 1, 0, 0, 0, 0)
define "2024Q4 End":   DateTime(2024, 12, 31, 23, 59, 59, 999)
define "2025Q1 Start": DateTime(2025, 1, 1, 0, 0, 0, 0)
define "2025Q1 End":   DateTime(2025, 3, 31, 23, 59, 59, 999)
define "2025Q2 Start": DateTime(2025, 4, 1, 0, 0, 0, 0)
define "2025Q2 End":   DateTime(2025, 6, 30, 23, 59, 59, 999)
define "2025Q3 Start": DateTime(2025, 7, 1, 0, 0, 0, 0)
define "2025Q3 End":   DateTime(2025, 9, 30, 23, 59, 59, 999)
define "2025Q4 Start": DateTime(2025, 10, 1, 0, 0, 0, 0)
define "2025Q4 End":   DateTime(2025, 12, 31, 23, 59, 59, 999)
define "2026Q1 Start": DateTime(2026, 1, 1, 0, 0, 0, 0)
define "2026Q1 End":   DateTime(2026, 3, 31, 23, 59, 59, 999)

// ============================================
// Quarterly Denominator / Numerator / Rate
// ============================================

define "2024Q1 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator":
  Count("Clean Surgery Inpatient Encounters" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator":
  Count("Clean Surgery With Infection" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '2524',
    indicatorName: '清淨手術傷口感染率',
    cleanSurgeryCriteria: 'Group1(腦神)/Group2(甲狀腺+E00-E07/E35/E89.0)/Group3(關節置換)，排除C40/C41/D65-D68等',
    infectionCriteria: 'ICD-10-CM 指定傷口感染診斷碼',
    totalDenominator: "Total Denominator",
    totalNumerator: "Total Numerator",
    overallRate: "Overall Rate",
    quarters: List{
      Tuple { quarter: '2024Q1', denominator: "2024Q1 Denominator", numerator: "2024Q1 Numerator", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', denominator: "2024Q2 Denominator", numerator: "2024Q2 Numerator", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', denominator: "2024Q3 Denominator", numerator: "2024Q3 Numerator", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', denominator: "2024Q4 Denominator", numerator: "2024Q4 Numerator", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', denominator: "2025Q1 Denominator", numerator: "2025Q1 Numerator", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', denominator: "2025Q2 Denominator", numerator: "2025Q2 Numerator", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', denominator: "2025Q3 Denominator", numerator: "2025Q3 Numerator", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', denominator: "2025Q4 Denominator", numerator: "2025Q4 Numerator", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', denominator: "2026Q1 Denominator", numerator: "2026Q1 Numerator", rate: "2026Q1 Rate" }
    }
  }
