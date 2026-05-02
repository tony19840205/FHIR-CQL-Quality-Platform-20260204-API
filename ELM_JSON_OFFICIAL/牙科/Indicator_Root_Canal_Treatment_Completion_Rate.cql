library Indicator_Root_Canal_Treatment_Completion_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 227
// 指標名稱: 同院所90日以內根管治療完成率
// 計算公式: 分子 / 分母 × 100%
//
// 分母: 依同案件同病患同牙位，統計執行根管開擴及清創(90015C)之牙位數
//   ※若同案件、同病患、同牙位執行2筆以上90015C時，該牙位仍視為1
// 分子: 以分母之牙位追蹤其3個月（90天）內於同院所執行任一根管治療之牙位數
//   根管治療醫令: 90001C(單根), 90002C(雙根), 90003C(三根以上),
//                90016C(乳牙根管), 90018C(乳牙多根管), 90019C, 90020C
//
// 牙位範圍 (FDI):
//   成人恆齒: 11-18, 21-28, 31-38, 41-48 (共32顆)
//   乳齒:     51-55, 61-65, 71-75, 81-85 (共20顆)
//   其他牙位資料全部排除
//
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

// 根管開擴及清創（分母用）
define function IsRootCanalDebridement(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value = '90015C'
  )

// 根管治療完成醫令（分子用）: 90001C, 90002C, 90003C, 90016C, 90018C, 90019C, 90020C
define function IsRootCanalTreatment(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value in {
        '90001C', '90002C', '90003C',
        '90016C', '90018C', '90019C', '90020C'
      }
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

// 驗證 FDI 牙位是否在成人恆齒或乳齒範圍內
define function IsValidFDITooth(toothCode String):
  toothCode in {
    '11', '12', '13', '14', '15', '16', '17', '18',
    '21', '22', '23', '24', '25', '26', '27', '28',
    '31', '32', '33', '34', '35', '36', '37', '38',
    '41', '42', '43', '44', '45', '46', '47', '48',
    '51', '52', '53', '54', '55',
    '61', '62', '63', '64', '65',
    '71', '72', '73', '74', '75',
    '81', '82', '83', '84', '85'
  }

// =============================================================================
// 90-Day Forward Tracking
// =============================================================================

// 判斷特定牙位於根管開擴日 debridDate 後 90 天內是否完成根管治療
define function HasRootCanalWithin90Days(toothCode String, debridDate Date):
  exists(
    [Procedure] P2
      where IsCompletedProcedure(P2)
        and IsRootCanalTreatment(P2)
        and GetBodySiteCode(P2) = toothCode
        and GetProcedureDate(P2) in Interval[debridDate, debridDate + 90 days]
  )

// =============================================================================
// Period-based Count Functions
// =============================================================================

// 分母: 期間內執行根管開擴及清創(90015C)的不重複牙位數
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsRootCanalDebridement(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and IsValidFDITooth(GetBodySiteCode(P))
  )

// 分子: 分母牙位中，90天內完成根管治療之牙位數
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsRootCanalDebridement(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and IsValidFDITooth(GetBodySiteCode(P))
        and HasRootCanalWithin90Days(GetBodySiteCode(P), GetProcedureDate(P))
  )

// 90日根管治療完成率 = (分子 / 分母) × 100%
define function RateInPeriod(periodStart Date, periodEnd Date):
  if DenominatorInPeriod(periodStart, periodEnd) > 0
    then (ToDecimal(NumeratorInPeriod(periodStart, periodEnd)) / ToDecimal(DenominatorInPeriod(periodStart, periodEnd))) * 100
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
    indicatorCode: '227',
    indicatorName: '同院所90日以內根管治療完成率',
    indicatorType: 'rate',
    unit: '%',
    denominatorCriteria: '執行根管開擴及清創(90015C)之不重複牙位數',
    numeratorCriteria: '90天內於同院所執行根管治療(90001C/90002C/90003C/90016C/90018C/90019C/90020C)之牙位數',
    debridementCode: '90015C',
    treatmentCodes: '90001C, 90002C, 90003C, 90016C, 90018C, 90019C, 90020C',
    toothScope: 'FDI 成人32顆(11-48) + 乳齒20顆(51-85)',
    trackingWindow: '90天',
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


