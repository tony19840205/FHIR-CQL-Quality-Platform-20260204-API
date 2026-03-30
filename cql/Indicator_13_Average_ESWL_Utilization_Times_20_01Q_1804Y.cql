library Indicator_13_Average_ESWL_Utilization_Times_20_01Q_1804Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 接受體外震波碎石術(ESWL)病人平均利用ESWL之次數
// 指標代碼: 20.01 (季), 1804 (年)
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 分母: 接受ESWL之病人數
// 分子: 接受ESWL之總次數
// 指標值: 分子/分母 = 平均每位病人接受ESWL次數
// ESWL醫令代碼: 50023A, 50024A, 50025A, 50026A
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

// ============================================
// Helper Functions
// ============================================

define function IsESWLCode(codeVal String):
  codeVal in {'50023A', '50024A', '50025A', '50026A'}

define function GetProcedureDate(p Procedure):
  case
    when p.performed is FHIR.dateTime then (p.performed as FHIR.dateTime).value
    when p.performed is FHIR.Period then (p.performed as FHIR.Period).start.value
    else null
  end

define function GetDischargeDate(enc Encounter):
  end of FHIRHelpers.ToInterval(enc.period)

// ============================================
// Main Definitions
// ============================================

// All ESWL procedures
define "All ESWL Procedures":
  [Procedure] P
    where P.status.value = 'completed'
    and exists (P.code.coding C where IsESWLCode(C.code.value))

// ESWL procedures during measurement period
define "ESWL Procedures In Period":
  "All ESWL Procedures" P
    where GetProcedureDate(P) during "Measurement Period"

// Total ESWL procedure count
define "Total ESWL Procedures":
  Count("ESWL Procedures In Period")

// Unique patients with ESWL
define "ESWL Patient Refs":
  distinct (
    "ESWL Procedures In Period" P
      return P.subject.reference.value
  )

define "Total ESWL Patients":
  Count("ESWL Patient Refs")

// Average ESWL per patient
define "Average ESWL Per Patient":
  if "Total ESWL Patients" > 0
  then ToDecimal("Total ESWL Procedures") / ToDecimal("Total ESWL Patients")
  else null

// ============================================
// Quarterly Date Ranges
// ============================================

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

// ============================================
// Quarterly Statistics
// ============================================

define "2024Q1 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q1 Start", "2024Q1 End"] return P.subject.reference.value))
define "2024Q1 Average":
  if "2024Q1 Patients" > 0 then ToDecimal("2024Q1 Procedures") / ToDecimal("2024Q1 Patients") else null

define "2024Q2 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q2 Start", "2024Q2 End"] return P.subject.reference.value))
define "2024Q2 Average":
  if "2024Q2 Patients" > 0 then ToDecimal("2024Q2 Procedures") / ToDecimal("2024Q2 Patients") else null

define "2024Q3 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q3 Start", "2024Q3 End"] return P.subject.reference.value))
define "2024Q3 Average":
  if "2024Q3 Patients" > 0 then ToDecimal("2024Q3 Procedures") / ToDecimal("2024Q3 Patients") else null

define "2024Q4 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2024Q4 Start", "2024Q4 End"] return P.subject.reference.value))
define "2024Q4 Average":
  if "2024Q4 Patients" > 0 then ToDecimal("2024Q4 Procedures") / ToDecimal("2024Q4 Patients") else null

define "2025Q1 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q1 Start", "2025Q1 End"] return P.subject.reference.value))
define "2025Q1 Average":
  if "2025Q1 Patients" > 0 then ToDecimal("2025Q1 Procedures") / ToDecimal("2025Q1 Patients") else null

define "2025Q2 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q2 Start", "2025Q2 End"] return P.subject.reference.value))
define "2025Q2 Average":
  if "2025Q2 Patients" > 0 then ToDecimal("2025Q2 Procedures") / ToDecimal("2025Q2 Patients") else null

define "2025Q3 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q3 Start", "2025Q3 End"] return P.subject.reference.value))
define "2025Q3 Average":
  if "2025Q3 Patients" > 0 then ToDecimal("2025Q3 Procedures") / ToDecimal("2025Q3 Patients") else null

define "2025Q4 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2025Q4 Start", "2025Q4 End"] return P.subject.reference.value))
define "2025Q4 Average":
  if "2025Q4 Patients" > 0 then ToDecimal("2025Q4 Procedures") / ToDecimal("2025Q4 Patients") else null

define "2026Q1 Procedures":
  Count("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Patients":
  Count(distinct ("All ESWL Procedures" P where GetProcedureDate(P) in Interval["2026Q1 Start", "2026Q1 End"] return P.subject.reference.value))
define "2026Q1 Average":
  if "2026Q1 Patients" > 0 then ToDecimal("2026Q1 Procedures") / ToDecimal("2026Q1 Patients") else null

// ============================================
// Final Report
// ============================================

define "Indicator Result":
  Tuple {
    IndicatorCode: '20.01/1804',
    IndicatorName: '接受體外震波碎石術(ESWL)病人平均利用ESWL之次數',
    TotalProcedures: "Total ESWL Procedures",
    TotalPatients: "Total ESWL Patients",
    AveragePerPatient: "Average ESWL Per Patient"
  }
