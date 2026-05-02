library Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 住院手術傷口感染率
// 指標代碼: 1658 (季)、1666 (年)
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍: 每季所有屬醫院總額之住院手術案件
//
// 分母: 所有住院手術病人數
//   手術: 醫令代碼全長6碼且前2碼為62-88及97者
//
// 分子: 手術傷口感染病人數
//   傷口感染: 依[院所、ID、生日、住院日]歸戶下有任一件之任一次診斷
//   ICD-10-CM碼為指定感染代碼者
//
// ※ 自114年第1季起配合ICD-10-CM/PCS 2023年版重新計算
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
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

// 手術判定: 醫令代碼全長6碼且前2碼為62-88或97
define function IsSurgicalProcedureCode(code String):
  code is not null
  and Length(code) = 6
  and (
    (Substring(code, 0, 1) = '6' and Substring(code, 1, 1) >= '2')
    or Substring(code, 0, 1) = '7'
    or (Substring(code, 0, 1) = '8' and Substring(code, 1, 1) <= '8')
    or Substring(code, 0, 2) = '97'
  )

// 傷口感染診斷碼: ICD-10-CM (依官方規格表 2023年版)
define function IsWoundInfectionCode(code String):
  code in {
    'D78.01','D78.02','D78.21','D78.22','D78.31','D78.32','D78.33','D78.34',
    'E36.01','E36.02',
    'G97.31','G97.32','G97.51','G97.52','G97.61','G97.62','G97.63','G97.64',
    'H59.111','H59.112','H59.113','H59.119',
    'H59.121','H59.122','H59.123','H59.129',
    'H59.311','H59.312','H59.313','H59.319',
    'H59.321','H59.322','H59.323','H59.329',
    'H59.331','H59.332','H59.333','H59.339',
    'H59.341','H59.342','H59.343','H59.349',
    'H59.351','H59.352','H59.353','H59.359',
    'H59.361','H59.362','H59.363','H59.369',
    'H95.21','H95.22','H95.41','H95.42',
    'H95.51','H95.52','H95.53','H95.54',
    'I97.410','I97.411','I97.418','I97.42',
    'I97.610','I97.611','I97.618',
    'I97.620','I97.621','I97.622',
    'I97.630','I97.631','I97.638',
    'I97.640','I97.641','I97.648',
    'J95.61','J95.62',
    'J95.830','J95.831',
    'J95.860','J95.861','J95.862','J95.863',
    'K68.11',
    'K91.61','K91.62',
    'K91.840','K91.841',
    'K91.870','K91.871','K91.872','K91.873',
    'L76.01','L76.02',
    'L76.21','L76.22',
    'L76.31','L76.32','L76.33','L76.34',
    'M96.810','M96.811',
    'M96.830','M96.831',
    'M96.840','M96.841','M96.842','M96.843',
    'N99.61','N99.62',
    'N99.820','N99.821',
    'N99.840','N99.841','N99.842','N99.843',
    'R50.84',
    'T80.211A','T80.212A','T80.218A','T80.219A','T80.22XA',
    'T81.30XA','T81.31XA','T81.32XA','T81.33XA',
    'T81.40XA','T81.41XA','T81.42XA','T81.43XA','T81.44XA','T81.49XA',
    'T82.6XXA','T82.7XXA',
    'T83.511A','T83.512A','T83.518A',
    'T83.59XA',
    'T83.590A','T83.591A','T83.592A','T83.593A','T83.598A',
    'T83.61XA','T83.62XA','T83.69XA',
    'T84.50XA','T84.51XA','T84.52XA','T84.53XA','T84.54XA','T84.59XA',
    'T84.60XA',
    'T84.610A','T84.611A','T84.612A','T84.613A','T84.614A','T84.615A','T84.619A',
    'T84.620A','T84.621A','T84.622A','T84.623A','T84.624A','T84.625A','T84.629A',
    'T84.63XA','T84.69XA','T84.7XXA',
    'T85.71XA','T85.72XA',
    'T85.730A','T85.731A','T85.732A','T85.733A','T85.734A','T85.735A','T85.738A',
    'T85.79XA',
    'T86.8421','T86.8422','T86.8423','T86.8429',
    'T88.8XXA'
  }

// ============================================
// Inpatient Encounters
// ============================================

define "Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'

// ============================================
// Surgical Inpatient Encounters (Denominator Base)
// 醫令代碼全長6碼且前2碼62-88或97
// ============================================

define "Surgical Inpatient Encounters":
  "Inpatient Encounters" E
    where exists (
      [Procedure] P
        where P.encounter.reference.value = 'Encounter/' + E.id.value
          and P.status.value = 'completed'
          and exists (
            P.code.coding C
              where IsSurgicalProcedureCode(C.code.value)
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
// Surgical Encounters With Wound Infection (Numerator Base)
// ============================================

define "Surgical Encounters With Infection":
  "Surgical Inpatient Encounters" E
    where exists (
      "Wound Infection Conditions" C
        where C.encounter.reference.value = 'Encounter/' + E.id.value
    )

// ============================================
// Overall Denominator / Numerator / Rate
// ============================================

define "Total Denominator":
  Count("Surgical Inpatient Encounters")

define "Total Numerator":
  Count("Surgical Encounters With Infection")

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
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator":
  Count("Surgical Inpatient Encounters" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator":
  Count("Surgical Encounters With Infection" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1658',
    indicatorName: '住院手術傷口感染率',
    surgicalCriteria: '醫令代碼全長6碼且前2碼62-88或97',
    infectionCriteria: 'ICD-10-CM 指定感染診斷碼',
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
