library Indicator_Root_Canal_Treatment_Retention_Rate_Permanent_Tooth_6Months version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 1177
// 指標名稱: 恆牙根管治療6個月以內保存率
// 計算公式: 1 - (分子/分母) × 100%
//
// 分母: 依同案件同病患同一恆牙牙位，統計執行根管開擴及清創(90015C)且同時申報
//   任一根管治療單根(90001C)、雙根(90002C)、三根(90003C)、四根(90004C)、
//   五根(90005C)之牙位數；若同案件同病患同牙位執行2筆以上時，該牙位仍視為1
// 分子: 以分母之牙位追蹤跨院所6個月(180天)內再次執行根管治療單根、雙根、
//   三根、四根、五根或拔牙之牙位數
//
// 恆牙牙位 (FDI): 11-18, 21-28, 31-38, 41-48 (成人32顆牙，其餘排除)
// 追蹤視窗: 180天（6個月）
// 統計範圍: 2024Q1 ~ 2026Q1 (9 個季度)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// =============================================================================
// Helper Functions
// =============================================================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetProcedureDate(P FHIR.Procedure):
  case
    when P.performed is FHIR.dateTime then date from (P.performed as FHIR.dateTime)
    when P.performed is FHIR.Period then date from (P.performed as FHIR.Period).start
    else null
  end

define function IsCompletedProcedure(P FHIR.Procedure):
  P.status.value = 'completed'

// 根管開擴及清創（分母觸發代碼）
define function IsRootCanalDebridement(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value = '90015C'
  )

// 根管治療（單根~五根）- 用於分母的「同時申報」條件 及 分子的「再次治療」
define function IsRootCanalTreatment(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value in {
        '90001C', '90002C', '90003C', '90004C', '90005C'
      }
  )

// 拔牙（簡單/複雜）- 用於分子的「失敗」判斷
define function IsExtraction(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value in { '92015C', '92016C' }
  )

// 取得 FDI 牙位代碼（來自 Procedure.bodySite）
define function GetBodySiteCode(P FHIR.Procedure):
  Coalesce(
    First(
      flatten(
        P.bodySite BS
          return (BS.coding C return C.code.value)
      )
    ),
    ''
  )

// 驗證 FDI 牙位是否為恆牙（11-48）
define function IsPermanentTooth(toothCode String):
  toothCode in {
    '11', '12', '13', '14', '15', '16', '17', '18',
    '21', '22', '23', '24', '25', '26', '27', '28',
    '31', '32', '33', '34', '35', '36', '37', '38',
    '41', '42', '43', '44', '45', '46', '47', '48'
  }

// =============================================================================
// 180-Day Forward Tracking (Failure Detection)
// =============================================================================

// 判斷特定恆牙牙位，於治療日後 180 天內是否有再次根管治療或拔牙
define function HasFailureWithin180Days(toothCode String, triggerDate Date):
  exists(
    [Procedure] P2
      where IsCompletedProcedure(P2)
        and (IsRootCanalTreatment(P2) or IsExtraction(P2))
        and GetBodySiteCode(P2) = toothCode
        and GetProcedureDate(P2) in Interval[triggerDate, triggerDate + 180 days]
        and GetProcedureDate(P2) != triggerDate
  )

// =============================================================================
// Period-based Count Functions
// =============================================================================

// 分母: 期間內執行 90015C 且同日同牙位有根管治療(90001C~90005C)之恆牙牙位數
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P1
      where IsCompletedProcedure(P1)
        and IsRootCanalDebridement(P1)
        and IsPermanentTooth(GetBodySiteCode(P1))
        and GetProcedureDate(P1) in Interval[periodStart, periodEnd]
        and exists(
          [Procedure] P2
            where IsCompletedProcedure(P2)
              and IsRootCanalTreatment(P2)
              and GetBodySiteCode(P2) = GetBodySiteCode(P1)
              and GetProcedureDate(P2) = GetProcedureDate(P1)
        )
  )

// 分子: 分母牙位中，180天內有再次根管治療或拔牙者（失敗牙位數）
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P1
      where IsCompletedProcedure(P1)
        and IsRootCanalDebridement(P1)
        and IsPermanentTooth(GetBodySiteCode(P1))
        and GetProcedureDate(P1) in Interval[periodStart, periodEnd]
        and exists(
          [Procedure] P2
            where IsCompletedProcedure(P2)
              and IsRootCanalTreatment(P2)
              and GetBodySiteCode(P2) = GetBodySiteCode(P1)
              and GetProcedureDate(P2) = GetProcedureDate(P1)
        )
        and HasFailureWithin180Days(GetBodySiteCode(P1), GetProcedureDate(P1))
  )

// 保存率 = [1 - (失敗牙位數 / 總牙位數)] × 100%
define function RateInPeriod(periodStart Date, periodEnd Date):
  if DenominatorInPeriod(periodStart, periodEnd) > 0
    then (1 - (ToDecimal(NumeratorInPeriod(periodStart, periodEnd)) / ToDecimal(DenominatorInPeriod(periodStart, periodEnd)))) * 100
    else null

// =============================================================================
// Quarterly Statistics (2024Q1 ~ 2026Q1, 9 quarters)
// =============================================================================

define "2024Q1 Denominator": DenominatorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Numerator": NumeratorInPeriod(@2024-01-01, @2024-03-31)
define "2024Q1 Rate": RateInPeriod(@2024-01-01, @2024-03-31)

define "2024Q2 Denominator": DenominatorInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Numerator": NumeratorInPeriod(@2024-04-01, @2024-06-30)
define "2024Q2 Rate": RateInPeriod(@2024-04-01, @2024-06-30)

define "2024Q3 Denominator": DenominatorInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Numerator": NumeratorInPeriod(@2024-07-01, @2024-09-30)
define "2024Q3 Rate": RateInPeriod(@2024-07-01, @2024-09-30)

define "2024Q4 Denominator": DenominatorInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Numerator": NumeratorInPeriod(@2024-10-01, @2024-12-31)
define "2024Q4 Rate": RateInPeriod(@2024-10-01, @2024-12-31)

define "2025Q1 Denominator": DenominatorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Numerator": NumeratorInPeriod(@2025-01-01, @2025-03-31)
define "2025Q1 Rate": RateInPeriod(@2025-01-01, @2025-03-31)

define "2025Q2 Denominator": DenominatorInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Numerator": NumeratorInPeriod(@2025-04-01, @2025-06-30)
define "2025Q2 Rate": RateInPeriod(@2025-04-01, @2025-06-30)

define "2025Q3 Denominator": DenominatorInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Numerator": NumeratorInPeriod(@2025-07-01, @2025-09-30)
define "2025Q3 Rate": RateInPeriod(@2025-07-01, @2025-09-30)

define "2025Q4 Denominator": DenominatorInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Numerator": NumeratorInPeriod(@2025-10-01, @2025-12-31)
define "2025Q4 Rate": RateInPeriod(@2025-10-01, @2025-12-31)

define "2026Q1 Denominator": DenominatorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Numerator": NumeratorInPeriod(@2026-01-01, @2026-03-31)
define "2026Q1 Rate": RateInPeriod(@2026-01-01, @2026-03-31)

// =============================================================================
// Summary
// =============================================================================

define "Total Denominator": "2026Q1 Denominator"
define "Total Numerator": "2026Q1 Numerator"
define "Overall Rate": "2026Q1 Rate"

define "Indicator Result":
  Tuple {
    indicatorCode: '1177',
    indicatorName: '恆牙根管治療6個月以內保存率',
    indicatorType: 'rate',
    unit: '%',
    denominatorCriteria: '同案件同病患同恆牙牙位執行90015C且同日有90001C~90005C之牙位數',
    numeratorCriteria: '180天內再次根管治療(90001C~90005C)或拔牙(92015C/92016C)之牙位數',
    debridementCode: '90015C',
    treatmentCodes: '90001C, 90002C, 90003C, 90004C, 90005C',
    extractionCodes: '92015C, 92016C',
    toothScope: 'FDI 恆牙32顆(11-48)',
    trackingWindow: '180天（6個月）',
    formula: '1-(分子/分母)',
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
    }
  }