library Indicator_09_Unplanned_14Day_Readmission_Rate_1077_01Q_1809Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 非計畫性住院案件出院後十四日內再住院率
// 指標代碼: 1077.01 (季度), 1809 (年度)
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
// 公式: 分子=病人14日再住院人數 / 分母=當季出院人數
// 排除條件(15項): 腫瘤科、乳癌試辦、癌症治療、早產安胎、罕見疾病、
//   轉院、新生兒床號、血友病、心導管、冠狀動脈繞道、瓣膜置換、
//   器官移植、支架置放、急性後期照護、安寧照護

parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

// ==================== Helper Functions ====================

define function GetDischargeDate(E Encounter):
  end of E.period

define function GetAdmissionDate(E Encounter):
  start of E.period

define function GetMainDiagCode(E Encounter):
  First(
    [Condition] C
      where C.encounter.reference.value = 'Encounter/' + E.id.value
      return First(C.code.coding).code.value
  )

define function GetDiagPrefix3(diagCode String):
  if diagCode is not null and Length(diagCode) >= 3
    then Substring(diagCode, 0, 3)
    else null

define function GetDiagPrefix5(diagCode String):
  if diagCode is not null and Length(diagCode) >= 5
    then Substring(diagCode, 0, 5)
    else null

define function GetProcCodePrefix5(codeVal String):
  if codeVal is not null and Length(codeVal) >= 5
    then Substring(codeVal, 0, 5)
    else null

define function GetExtValue(E Encounter, extUrl String):
  First(
    E.extension X
      where X.url.value = extUrl
      return (X.value as FHIR.code).value
  )

// ==================== Base Data ====================

define "All Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and GetDischargeDate(E) during "Measurement Period"

define "All Procedures":
  [Procedure] P where P.status.value = 'completed'

// ==================== Exclusion Criteria (15 items) ====================

// (1) 腫瘤科個案 (就醫科別=13)
define function IsOncologyCase(E Encounter):
  GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/department-code') = '13'

// (2) 乳癌試辦案件 (案件分類4 + 疾患來源N/R/C)
define function IsBreastCancerPilot(E Encounter):
  GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/case-type') = '4'
    and GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/disease-source') in {'N', 'R', 'C'}

// (3) 癌症/性態未明腫瘤治療 (C00-C96排除C94.4/C94.6, D37-D48, Z51.0/Z51.11/Z51.12/Z08)
define function IsCancerPrefix3(prefix3 String):
  prefix3 in {
    'C00','C01','C02','C03','C04','C05','C06','C07','C08','C09',
    'C10','C11','C12','C13','C14','C15','C16','C17','C18','C19',
    'C20','C21','C22','C23','C24','C25','C26','C30','C31','C32',
    'C33','C34','C37','C38','C39','C40','C41','C43','C44','C45',
    'C46','C47','C48','C49','C50','C51','C52','C53','C54','C55',
    'C56','C57','C58','C60','C61','C62','C63','C64','C65','C66',
    'C67','C68','C69','C70','C71','C72','C73','C74','C75','C76',
    'C77','C78','C79','C80','C81','C82','C83','C84','C85','C86',
    'C88','C90','C91','C92','C93','C94','C95','C96',
    'D37','D38','D39','D40','D41','D42','D43','D44','D45','D46','D47','D48'
  }

define function IsCancerTreatment(E Encounter):
  (IsCancerPrefix3(GetDiagPrefix3(GetMainDiagCode(E)))
    and not (GetMainDiagCode(E) in {'C94.4', 'C94.6'}))
  or GetMainDiagCode(E) in {'Z51.0', 'Z51.11', 'Z51.12', 'Z08'}

// (4) 早產安胎個案
define function IsPretermLabor(E Encounter):
  GetDiagPrefix5(GetMainDiagCode(E)) = 'O4291'
    or GetMainDiagCode(E) in {
      'O4410','O4411','O4412','O4413',
      'O4690','O4691','O4692','O4693',
      'O4702','O4703','O6002','O6003'
    }

// (5) 罕見疾病 (E760-E763 一點多醣症)
define function IsRareDisease(E Encounter):
  GetMainDiagCode(E) in {'E760','E761','E762','E763'}

// (6) 轉院案件 (轉歸代碼5/6/7)
define function IsTransferCase(E Encounter):
  exists(
    E.hospitalization.dischargeDisposition.coding C
      where C.code.value in {'5','6','7'}
  )

// (7) 新生兒床號 (部分負擔計費903)
define function IsNewbornBed(E Encounter):
  GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/copayment-code') = '903'

// (8) 血友病 (主診斷D66/D67/D681/D682)
define function IsHemophilia(E Encounter):
  GetMainDiagCode(E) in {'D66','D67','D681','D682'}

// (9) 執行心導管 (醫令代碼前5碼 18020/18021/97501-97503/97506-97508)
define function HasCardiacCath(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and GetProcCodePrefix5(First(P.code.coding).code.value) in {
          '18020','18021','97501','97502','97503','97506','97507','97508'
        }
  )

// (10) 冠狀動脈繞道手術 (前5碼 68023/68024/68025)
define function HasCABG(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and GetProcCodePrefix5(First(P.code.coding).code.value) in {'68023','68024','68025'}
  )

// (11) 瓣膜置換術 (前5碼 68016/68017/68018 且主診斷I00-I99)
define function HasValveReplacement(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and GetProcCodePrefix5(First(P.code.coding).code.value) in {'68016','68017','68018'}
  )
  and GetDiagPrefix3(GetMainDiagCode(E)) is not null
  and GetDiagPrefix3(GetMainDiagCode(E)) >= 'I00'
  and GetDiagPrefix3(GetMainDiagCode(E)) <= 'I99'

// (12) 器官移植
define function HasOrganTransplant(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and First(P.code.coding).code.value in {
          '75010','68003','68037','68043','75020','76020','75418','85213'
        }
  )

// (13) 支架置放術 (PTCA + 血管支架)
define function HasPTCA(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and First(P.code.coding).code.value in {
          '02703ZZ','02704ZZ','3E07317','02713ZZ','02714ZZ','02723ZZ','02733ZZ','02734ZZ'
        }
  )

define function HasPTCAOrder(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and GetProcCodePrefix5(First(P.code.coding).code.value) in {'33076','33077','33078'}
  )

define function HasStentPlacement(E Encounter):
  HasPTCA(E) and HasPTCAOrder(E)

// (14) 急性後期整合照護計畫案件 (案件分類4 + 試辦計畫1/2/3/4/6)
define function IsPostAcuteCare(E Encounter):
  GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/case-type') = '4'
    and GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/pilot-program') in {'1','2','3','4','6'}

// (15) 安寧照護 (給付類別A)
define function IsHospiceCare(E Encounter):
  GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/payment-type') = 'A'

// ==================== Combined Exclusion ====================

define function IsPlannedReadmission(E Encounter):
  IsOncologyCase(E)
    or IsBreastCancerPilot(E)
    or IsCancerTreatment(E)
    or IsPretermLabor(E)
    or IsRareDisease(E)
    or IsTransferCase(E)
    or IsNewbornBed(E)
    or IsHemophilia(E)
    or HasCardiacCath(E)
    or HasCABG(E)
    or HasValveReplacement(E)
    or HasOrganTransplant(E)
    or HasStentPlacement(E)
    or IsPostAcuteCare(E)
    or IsHospiceCare(E)

// ==================== Denominator: Unplanned Discharges ====================

define "Unplanned Discharges":
  "All Inpatient Encounters" E
    where not IsPlannedReadmission(E)

// ==================== Numerator: 14-Day Readmissions ====================

define function Has14DayReadmission(discharge Encounter):
  exists(
    "All Inpatient Encounters" R
      where R.id.value != discharge.id.value
        and R.subject.reference.value = discharge.subject.reference.value
        and GetAdmissionDate(R) > GetDischargeDate(discharge)
        and days between GetDischargeDate(discharge) and GetAdmissionDate(R) <= 14
        and not IsPlannedReadmission(R)
  )

define "Readmission Cases":
  "Unplanned Discharges" E
    where Has14DayReadmission(E)

// ==================== Quarterly Date Ranges ====================

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

// ==================== Quarterly Statistics ====================

define "2024Q1 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": Count("Unplanned Discharges" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator": Count("Readmission Cases" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

define "Total Denominator": Count("Unplanned Discharges")
define "Total Numerator": Count("Readmission Cases")
define "Total Rate": if "Total Denominator" > 0 then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100 else null

// ==================== Indicator Result ====================

define "Indicator Result":
  Tuple {
    indicatorCodeQuarterly: '1077.01',
    indicatorCodeAnnual: '1809',
    indicatorName: '非計畫性住院案件出院後十四日內再住院率',
    measurementPeriod: "Measurement Period",
    readmissionDays: 14,
    exclusionCount: 15,
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
