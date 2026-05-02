library Indicator_Dental_Filling_Permanent_Tooth_Refill_Rate_Within_1Year version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標代碼: 38
// 指標名稱: 牙體復形同牙位再補率-1年以內
// 計算公式: 分子 / 分母 × 100%
//
// 分子: 同診所同病患同牙位，不同就醫日期有兩筆以上(含)牙體復形醫令之牙位數
//   ※同診所、同病患、同牙位、同就醫日期，有兩筆以上(含)的牙體復形醫令為補報案件，
//     不算重補，不計入分子
// 分母: 同診所同病患同牙位，含有牙體復形醫令，則分母為1
//   ※若為同案件、同病患、同牙位執行2筆以上牙體復形醫令時，該牙位仍視為1
//
// 牙體復形醫令代碼:
//   89001C, 89002C, 89003C, 89004C, 89005C,
//   89008C, 89009C, 89010C, 89011C, 89012C, 89014C, 89015C
//   (106年3月始增加89014C、89015C)
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

define function IsFillingProcedure(P FHIR.Procedure):
  exists(
    P.code.coding C
      where C.code.value in {
        '89001C', '89002C', '89003C', '89004C', '89005C',
        '89008C', '89009C', '89010C', '89011C', '89012C',
        '89014C', '89015C'
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
// Refill Detection (1-year forward tracking)
// =============================================================================

// 判斷特定牙位於填補日 fillDate 之後 1 年內是否有重補
// 重補定義：不同就醫日期（fillDate 之後至 fillDate + 1 year）再次執行牙體復形
define function HasRefillWithin1Year(toothCode String, fillDate Date):
  exists(
    [Procedure] P2
      where IsCompletedProcedure(P2)
        and IsFillingProcedure(P2)
        and GetBodySiteCode(P2) = toothCode
        and GetProcedureDate(P2) in Interval[fillDate, fillDate + 1 year]
        and GetProcedureDate(P2) != fillDate
  )

// =============================================================================
// Period-based Count Functions
// =============================================================================

// 分母: 期間內牙體復形執行牙位數（FDI 11-48 + 51-85）
define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsFillingProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and IsValidFDITooth(GetBodySiteCode(P))
  )

// 分子（重補）: 期間內 1 年內有重補之牙位數
define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  Count(
    [Procedure] P
      where IsCompletedProcedure(P)
        and IsFillingProcedure(P)
        and GetProcedureDate(P) in Interval[periodStart, periodEnd]
        and IsValidFDITooth(GetBodySiteCode(P))
        and HasRefillWithin1Year(GetBodySiteCode(P), GetProcedureDate(P))
  )

// 1 年再補率 = (重補牙位數 / 總牙位數) × 100%
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
    indicatorCode: '38',
    indicatorName: '牙體復形同牙位再補率-1年以內',
    indicatorType: 'rate',
    unit: '%',
    denominatorCriteria: '同診所同病患同牙位含填補醫令之不重複牙位數',
    numeratorCriteria: '同診所同病患同牙位，不同就醫日期1年內有重補之填補牙位數',
    fillingCodes: '89001C~89005C, 89008C~89012C, 89014C, 89015C',
    toothScope: 'FDI 成人32顆(11-48) + 乳齒20顆(51-85)',
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
