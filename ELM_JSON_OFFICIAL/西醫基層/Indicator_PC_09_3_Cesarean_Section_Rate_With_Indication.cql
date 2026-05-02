library Indicator_PC_09_3_Cesarean_Section_Rate_With_Indication version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標編號: 1138.01
// 指標名稱: 西醫基層住院生產剖腹產率（具適應症）
// 分子: 具適應症之剖腹產案件（不具適應症剖腹產之外的剖腹產案件），即：
//   IsCesareanDelivery AND NOT IsPatientRequestedCesarean
//   等同符合下列剖腹產條件之一，且不符合自行要求任一條件：
//   (a) TW-DRG 前3碼 in {370, 371}（不含 513）
//   (b) DRG_CODE = 0371A（不含 0373B）
//   (c) 醫令代碼 in {81004C, 81005C, 81028C, 81029C, 97009C}（不含 97014C）
// 分母: 生產案件數（自然產 + 剖腹產），排除代辦案件
//
// 自然產案件（符合任一條件）:
//   a. TW-DRG 前3碼 in {372,373,374,375}
//   b. DRG_CODE in {0373A, 0373C}
//   c. 醫令代碼 in {81017C,81018C,81019C,81024C,81025C,81026C,81034C,97004C,97005D,97934C}
//
// 剖腹產案件（符合任一條件）:
//   a. TW-DRG 前3碼 in {370,371,513}
//   b. DRG_CODE in {0371A, 0373B}
//   c. 醫令代碼 in {81004C,81005C,81028C,81029C,97009C,97014C}
//
// 不具適應症之剖腹產（自行要求）: TW-DRG前3碼=513 / DRG_CODE=0373B / 醫令=97014C
//
// 排除: 代辦案件
// 統計範圍: 2024Q1 ~ 2026Q1 (9 個季度)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// ============================================
// Helper Functions
// ============================================

define function ToDecimal(v Integer):
  v * 1.0

define function GetExtBoolean(E FHIR.Encounter, extUrl String):
  exists(
    E.extension Ext
      where Ext.url.value = extUrl
        and (Ext.value as FHIR.boolean).value = true
  )

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

define function GetEncounterDischargeDate(E FHIR.Encounter):
  date from E.period.end

define function GetTWDRG(E FHIR.Encounter):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = 'http://www.nhi.gov.tw/extensions/tw-drg'
        return (Ext.value as FHIR.string).value
    ),
    ''
  )

define function GetDRGCode(E FHIR.Encounter):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = 'http://www.nhi.gov.tw/extensions/drg-code'
        return (Ext.value as FHIR.string).value
    ),
    ''
  )

define function GetDRGPrefix3(drgCode String):
  if Length(drgCode) >= 3 then Substring(drgCode, 0, 3) else drgCode

// ============================================
// Delivery Classification Functions
// ============================================

define function HasNaturalDeliveryProcedure(E FHIR.Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          P.code.coding C
            where C.code.value in {
              '81017C', '81018C', '81019C', '81024C', '81025C',
              '81026C', '81034C', '97004C', '97005D', '97934C'
            }
        )
  )

define function HasCesareanDeliveryProcedure(E FHIR.Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          P.code.coding C
            where C.code.value in {
              '81004C', '81005C', '81028C', '81029C', '97009C', '97014C'
            }
        )
  )

// 自行要求剖腹產：TW-DRG前3碼=513 / DRG_CODE=0373B / 醫令=97014C
define function HasPatientRequestedCesareanProcedure(E FHIR.Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          P.code.coding C
            where C.code.value = '97014C'
        )
  )

define function IsNaturalDelivery(E FHIR.Encounter):
  GetDRGPrefix3(GetTWDRG(E)) in {'372', '373', '374', '375'}
    or GetDRGCode(E) in {'0373A', '0373C'}
    or HasNaturalDeliveryProcedure(E)

define function IsCesareanDelivery(E FHIR.Encounter):
  GetDRGPrefix3(GetTWDRG(E)) in {'370', '371', '513'}
    or GetDRGCode(E) in {'0371A', '0373B'}
    or HasCesareanDeliveryProcedure(E)

// 自行要求剖腹產（不具適應症）
define function IsPatientRequestedCesarean(E FHIR.Encounter):
  GetDRGPrefix3(GetTWDRG(E)) = '513'
    or GetDRGCode(E) = '0373B'
    or HasPatientRequestedCesareanProcedure(E)

// 具適應症剖腹產 = 剖腹產 AND NOT 自行要求
define function IsIndicatedCesarean(E FHIR.Encounter):
  IsCesareanDelivery(E) and not IsPatientRequestedCesarean(E)

// ============================================
// Base Resources
// ============================================

define "All Inpatient Discharges":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and not IsAgencyCase(E)

define "Natural Deliveries":
  "All Inpatient Discharges" E
    where IsNaturalDelivery(E)

define "Cesarean Deliveries":
  "All Inpatient Discharges" E
    where IsCesareanDelivery(E)

define "All Deliveries":
  "Natural Deliveries" union "Cesarean Deliveries"

// 具適應症剖腹產（分子集合）
define "Indicated Cesarean Deliveries":
  "All Inpatient Discharges" E
    where IsIndicatedCesarean(E)

// ============================================
// Period-based Count Functions
// ============================================

define function DenominatorInPeriod(periodStart Date, periodEnd Date):
  Count(
    "All Deliveries" D
      where GetEncounterDischargeDate(D) in Interval[periodStart, periodEnd]
  )

define function NumeratorInPeriod(periodStart Date, periodEnd Date):
  Count(
    "Indicated Cesarean Deliveries" C
      where GetEncounterDischargeDate(C) in Interval[periodStart, periodEnd]
  )

define function RateInPeriod(periodStart Date, periodEnd Date):
  if DenominatorInPeriod(periodStart, periodEnd) > 0
    then (ToDecimal(NumeratorInPeriod(periodStart, periodEnd)) / ToDecimal(DenominatorInPeriod(periodStart, periodEnd))) * 100
    else null

// ============================================
// Quarterly Statistics (2024Q1 ~ 2026Q1, 9 quarters)
// ============================================

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

// ============================================
// Summary
// ============================================

define "Total Denominator": "2026Q1 Denominator"
define "Total Numerator": "2026Q1 Numerator"
define "Overall Rate": "2026Q1 Rate"

define "Indicator Result":
  Tuple {
    indicatorCode: '1138.01',
    indicatorName: '西醫基層住院生產剖腹產率（具適應症）',
    denominatorCriteria: '生產案件數（自然產+剖腹產），排除代辦案件',
    numeratorCriteria: '具適應症之剖腹產案件（剖腹產排除自行要求後之案件）',
    indicatedCesareanLogic: 'IsCesareanDelivery AND NOT IsPatientRequestedCesarean',
    note: '本指標含符合適應症及自行要求剖腹產案件，各院所收治產婦複雜度不同，不宜逕予判斷院所生產照護品質',
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
