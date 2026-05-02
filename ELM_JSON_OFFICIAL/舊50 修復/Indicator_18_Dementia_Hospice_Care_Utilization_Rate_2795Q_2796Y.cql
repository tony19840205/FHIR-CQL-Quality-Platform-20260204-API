library Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 失智症病人安寧緩和服務使用率
// 指標代碼: 2795 (季)、2796 (年)
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍: 每季所有屬醫院總額之門住診及門診其他醫事機構案件
//           排除代辦案件
//
// 分母: 失智症病人數
//   (1) 主、次診斷碼(ICD-10-CM)前3碼為 F01-F03、G30、G31
//   (2) 或全碼為 F06.70、F06.71、F10.27、F10.97、F13.27、F13.97
//       F18.27、F18.97、F19.27、F19.97
//
// 分子: 分母病人使用安寧緩和服務的人數
//   安寧住院照護醫令: 05601K、05602A、05603B
//   安寧共同照護試辦方案醫令: P4401B、P4402B、P4403B
//   安寧居家療護醫令: 05312C-05316C、05323C-05327C
//                     05336C-05341C、05362C-05374C
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

// 失智症判定:
//   前3碼: F01, F02, F03, G30, G31
//   或全碼: F06.70, F06.71, F10.27, F10.97, F13.27, F13.97,
//           F18.27, F18.97, F19.27, F19.97
define function IsDementiaCode(code String):
  code is not null
  and (
    Substring(code, 0, 3) in {'F01', 'F02', 'F03', 'G30', 'G31'}
    or code in {
      'F06.70', 'F06.71',
      'F10.27', 'F10.97',
      'F13.27', 'F13.97',
      'F18.27', 'F18.97',
      'F19.27', 'F19.97'
    }
  )

// 安寧緩和服務醫令判定
define function IsHospiceCode(code String):
  code in {
    // 安寧住院照護醫令
    '05601K', '05602A', '05603B',
    // 全民健康保險安寧共同照護試辦方案醫令
    'P4401B', 'P4402B', 'P4403B',
    // 安寧居家療護醫令 05312C-05316C
    '05312C', '05313C', '05314C', '05315C', '05316C',
    // 05323C-05327C
    '05323C', '05324C', '05325C', '05326C', '05327C',
    // 05336C-05341C
    '05336C', '05337C', '05338C', '05339C', '05340C', '05341C',
    // 05362C-05374C
    '05362C', '05363C', '05364C', '05365C', '05366C', '05367C',
    '05368C', '05369C', '05370C', '05371C', '05372C', '05373C', '05374C'
  }

// ============================================
// 失智症 Encounters (門住診，排除代辦)
// ============================================

define "Dementia Encounters":
  [Encounter] E
    where (E.class.code.value = 'IMP' or E.class.code.value = 'AMB')
      and E.status.value = 'finished'
      and not exists (
        E.type T
          where exists (T.coding C where C.code.value = 'AGENCY')
      )
      and exists (
        [Condition] C
          where C.encounter.reference.value = 'Encounter/' + E.id.value
            and exists (
              C.code.coding CD
                where IsDementiaCode(CD.code.value)
            )
      )

// ============================================
// 安寧緩和 Procedures
// ============================================

define "Hospice Procedures":
  [Procedure] P
    where P.status.value = 'completed'
      and exists (
        P.code.coding C
          where IsHospiceCode(C.code.value)
      )

// ============================================
// 失智症病人中使用安寧緩和服務者 (分子 Base)
// ============================================

define "Dementia Encounters With Hospice":
  "Dementia Encounters" E
    where exists (
      "Hospice Procedures" P
        where P.encounter.reference.value = 'Encounter/' + E.id.value
    )

// ============================================
// Overall Denominator / Numerator / Rate
// ============================================

define "Total Denominator":
  Count("Dementia Encounters")

define "Total Numerator":
  Count("Dementia Encounters With Hospice")

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
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator":
  Count("Dementia Encounters" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator":
  Count("Dementia Encounters With Hospice" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '2795',
    indicatorName: '失智症病人安寧緩和服務使用率',
    dementiaCriteria: 'ICD-10-CM 前3碼 F01-F03/G30/G31 或指定全碼，門住診排除代辦',
    hospiceCriteria: '安寧住院/共同照護/居家療護指定醫令',
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
