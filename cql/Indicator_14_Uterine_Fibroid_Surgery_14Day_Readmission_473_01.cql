library Indicator_14_Uterine_Fibroid_Surgery_14Day_Readmission_473_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率
// 指標代碼: 473.01
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 分母: 當季子宮肌瘤手術住院案件數（含肌瘤摘除術、子宮切除術）
//   排除: 癌症案件(C00-C96, D37-D48, Z51.12, J84.81)
// 分子: 分母案件出院後14天內因相關診斷(N70-N85)再住院
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

// ============================================
// Helper Functions
// ============================================

define function CodeInList(codeVal String, codeList List<String>):
  codeList CL where CL = codeVal

define function GetDischargeDate(enc Encounter):
  end of FHIRHelpers.ToInterval(enc.period)

define function GetAdmissionDate(enc Encounter):
  start of FHIRHelpers.ToInterval(enc.period)

define function GetProcedureDate(p Procedure):
  case
    when p.performed is FHIR.dateTime then (p.performed as FHIR.dateTime).value
    when p.performed is FHIR.Period then (p.performed as FHIR.Period).start.value
    else null
  end

define function IsFibroidSurgeryCode(codeVal String):
  codeVal in {
    '97010K', '97011A', '97012B', '97013B',
    '80402C', '80420C', '80415B', '97013C', '80415C', '80425C',
    '97025K', '97026A', '97027B',
    '97020K', '97021A', '97022B',
    '97035K', '97036A', '97037B',
    '80403B', '80404B', '80421B', '80416B', '80412B',
    '97027C', '80404C'
  }

define function IsFibroidDiagnosisCode(codeVal String):
  Substring(codeVal, 0, 3) = 'D25'

define function IsCancerDiagnosisCode(codeVal String):
  (Substring(codeVal, 0, 1) = 'C'
    and Substring(codeVal, 0, 3) >= 'C00'
    and Substring(codeVal, 0, 3) <= 'C96'
    and codeVal != 'C94.4'
    and codeVal != 'C94.6')
  or (Substring(codeVal, 0, 3) >= 'D37' and Substring(codeVal, 0, 3) <= 'D48')
  or codeVal = 'Z51.12'
  or codeVal = 'J84.81'

define function IsRelatedDiagnosisCode(codeVal String):
  Substring(codeVal, 0, 3) >= 'N70' and Substring(codeVal, 0, 3) <= 'N85'

// ============================================
// Main Definitions
// ============================================

// All inpatient encounters
define "All Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'IMP'
    and GetDischargeDate(E) during "Measurement Period"

// Fibroid surgery procedures
define "Fibroid Surgery Procedures":
  [Procedure] P
    where P.status.value = 'completed'
    and exists (P.code.coding C where IsFibroidSurgeryCode(C.code.value))

// Encounters with fibroid diagnosis
define "Encounters With Fibroid Diagnosis":
  "All Inpatient Encounters" E
    where exists (
      E.diagnosis D
        where exists (
          D.condition.extension EX
            where EX.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/diagnosis-code'
            and IsFibroidDiagnosisCode(First((EX.value as CodeableConcept).coding).code.value)
        )
    )
    or exists (
      [Condition] C
        where C.subject.reference.value = E.subject.reference.value
        and exists (C.code.coding CC where IsFibroidDiagnosisCode(CC.code.value))
    )

// Encounters with cancer diagnosis (exclusion)
define "Encounters With Cancer Diagnosis":
  "All Inpatient Encounters" E
    where exists (
      E.diagnosis D
        where exists (
          D.condition.extension EX
            where EX.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/diagnosis-code'
            and IsCancerDiagnosisCode(First((EX.value as CodeableConcept).coding).code.value)
        )
    )
    or exists (
      [Condition] C
        where C.subject.reference.value = E.subject.reference.value
        and exists (C.code.coding CC where IsCancerDiagnosisCode(CC.code.value))
    )

// Denominator: fibroid surgery encounters, excluding cancer
define "Denominator Cases":
  "Encounters With Fibroid Diagnosis" E
    where exists (
      "Fibroid Surgery Procedures" P
        where P.encounter.reference.value = 'Encounter/' + E.id.value
          or P.subject.reference.value = E.subject.reference.value
    )
    and not exists (
      "Encounters With Cancer Diagnosis" CE
        where CE.id.value = E.id.value
    )

// Readmission within 14 days with related diagnosis
define "Readmission Within 14 Days":
  "Denominator Cases" IndexEnc
    where exists (
      "All Inpatient Encounters" ReadmitEnc
        where ReadmitEnc.subject.reference.value = IndexEnc.subject.reference.value
        and ReadmitEnc.id.value != IndexEnc.id.value
        and GetAdmissionDate(ReadmitEnc) in Interval[
          GetDischargeDate(IndexEnc) + 1 day,
          GetDischargeDate(IndexEnc) + 14 days
        ]
        and (
          exists (
            ReadmitEnc.diagnosis D
              where exists (
                D.condition.extension EX
                  where EX.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/diagnosis-code'
                  and IsRelatedDiagnosisCode(First((EX.value as CodeableConcept).coding).code.value)
              )
          )
          or exists (
            [Condition] C
              where C.subject.reference.value = ReadmitEnc.subject.reference.value
              and exists (C.code.coding CC where IsRelatedDiagnosisCode(CC.code.value))
          )
        )
    )

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
// Quarterly Denominator/Numerator/Rate
// ============================================

define "2024Q1 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator":
  Count("Denominator Cases" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator":
  Count("Readmission Within 14 Days" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Overall Totals
// ============================================

define "Total Denominator":
  Count("Denominator Cases")

define "Total Numerator":
  Count("Readmission Within 14 Days")

define "Overall Rate":
  if "Total Denominator" > 0
  then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100
  else null

// ============================================
// Final Report
// ============================================

define "Indicator Result":
  Tuple {
    IndicatorCode: '473.01',
    IndicatorName: '子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率',
    TotalDenominator: "Total Denominator",
    TotalNumerator: "Total Numerator",
    OverallRate: "Overall Rate"
  }
