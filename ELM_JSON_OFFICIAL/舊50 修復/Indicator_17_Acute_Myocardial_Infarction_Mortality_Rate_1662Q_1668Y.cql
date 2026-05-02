library Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 急性心肌梗塞死亡率
// 指標代碼: 1662 (季)、1668 (年)
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍: 每季所有屬醫院總額之住院+門診案件
//
// 分母: 18歲以上且主診斷為急性心肌梗塞之病患數
//   急性心肌梗塞: 主診斷ICD-10-CM碼前3碼為I21-I22者
//
// 分子: 分母病患死亡個案數
//   死亡: 門住診勾稽保資料保險對象資訊檔註記為死亡者
//         住院再依[院所、ID、生日、住院日]歸戶下有任一件之
//         轉歸代碼(TRAN_CODE)為4(死亡)、A(病危自動出院)者
//
// ※ 分母分子需排除轉院個案
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

// 急性心肌梗塞: ICD-10-CM 前3碼為 I21 或 I22
define function IsAMICode(code String):
  code is not null
  and (Substring(code, 0, 3) = 'I21' or Substring(code, 0, 3) = 'I22')

// 轉歸代碼判斷 (NHI TRAN_CODE extension)
define function HasTranCode(E FHIR.Encounter, tranCode String):
  exists (
    E.extension EXT
      where EXT.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/tran-code'
        and (EXT.value as FHIR.string).value = tranCode
  )

// ============================================
// 所有 AMI 相關 Encounters (住院+門診, 18歲以上)
// ============================================

define "All AMI Encounters":
  [Encounter] E
    where (E.class.code.value = 'IMP' or E.class.code.value = 'AMB')
      and E.status.value = 'finished'
      and AgeInYearsAt(Today()) >= 18
      and exists (
        [Condition] C
          where C.encounter.reference.value = 'Encounter/' + E.id.value
            and exists (
              C.code.coding CD
                where IsAMICode(CD.code.value)
            )
      )

// ============================================
// 分母: 排除轉院個案 (TRAN_CODE = '2')
// ============================================

define "Denominator Encounters":
  "All AMI Encounters" E
    where not HasTranCode(E, '2')

// ============================================
// 死亡判斷
// ============================================

// Patient.deceased 旗標 (門診/住院勾稽保資料)
define "Patient Is Deceased":
  (Patient.deceased is FHIR.boolean and (Patient.deceased as FHIR.boolean).value = true)
  or Patient.deceased is FHIR.dateTime

// ============================================
// 分子: 死亡個案 (排除轉院後)
// ============================================

define "Numerator Encounters":
  "Denominator Encounters" E
    where "Patient Is Deceased"
      or HasTranCode(E, '4')
      or HasTranCode(E, 'A')

// ============================================
// Overall Denominator / Numerator / Rate
// ============================================

define "Total Denominator":
  Count("Denominator Encounters")

define "Total Numerator":
  Count("Numerator Encounters")

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
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator":
  Count("Denominator Encounters" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator":
  Count("Numerator Encounters" E where GetEncounterStart(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1662',
    indicatorName: '急性心肌梗塞死亡率',
    amiCriteria: 'ICD-10-CM 前3碼 I21-I22，18歲以上，住院+門診',
    deathCriteria: 'Patient.deceased OR TRAN_CODE=4/A，排除轉院(TRAN_CODE=2)',
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
