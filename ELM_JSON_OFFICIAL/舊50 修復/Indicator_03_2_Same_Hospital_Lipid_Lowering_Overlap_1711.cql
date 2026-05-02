library Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 同醫院門診同藥理用藥日數重疊率-降血脂(口服)
// 指標代碼: 1711
// 資料來源：醫療給付檔案分析系統
// 分子: 同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數
// 分母: 各案件之「給藥日數」總和
// 降血脂藥(口服): ATC前5碼=C10AA、C10AB、C10AC、C10AD、C10AX，且醫令代碼第8碼不為1(排除注射劑)
// 排除代辦案件

codesystem "ATC": 'http://www.whocc.no/atc'
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

// 降血脂藥 ATC 前5碼：C10AA、C10AB、C10AC、C10AD、C10AX
define function IsLipidLoweringATC(atcCode String):
  Substring(atcCode, 0, 5) in {
    'C10AA', 'C10AB', 'C10AC', 'C10AD', 'C10AX'
  }

// 口服劑型：醫令代碼第8碼不為1（1=注射劑）
define function IsOralDrug(drugCode String):
  Length(drugCode) >= 8 and Substring(drugCode, 7, 1) != '1'

// ============================================
// Overlap Days Calculation
// ============================================

define function CalculateOverlapDays(start1 Date, end1 Date, start2 Date, end2 Date):
  if start1 is null or end1 is null or start2 is null or end2 is null then 0
  else
    Max({
      days between (
        if start1 after start2 then start1 else start2
      ) and (
        if end1 before end2 then end1 else end2
      ) + 1,
      0
    })

// ============================================
// Outpatient Encounters
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and not IsAgencyCase(E)

// ============================================
// Lipid Lowering MedicationRequests (oral)
// ============================================

define "Lipid Lowering Prescriptions":
  [MedicationRequest] MR
    let drugCode: Coalesce(First((MR.medication as FHIR.CodeableConcept).coding).code.value, ''),
        medCodings: (MR.medication as FHIR.CodeableConcept).coding
    where MR.status.value = 'completed'
      and IsOralDrug(drugCode)
      and exists(
        medCodings AC
          where AC.system.value = 'http://www.whocc.no/atc'
            and IsLipidLoweringATC(AC.code.value)
      )
      and exists(
        "Outpatient Encounters" E
          where MR.encounter.reference.value = 'Encounter/' + E.id.value
      )
      and MR.dispenseRequest.validityPeriod.start is not null
      and MR.dispenseRequest.validityPeriod.end is not null

// ============================================
// Total Drug Days (Denominator)
// ============================================

define "Total Drug Days":
  Sum(
    "Lipid Lowering Prescriptions" P
      return days between date from P.dispenseRequest.validityPeriod.start.value
                     and date from P.dispenseRequest.validityPeriod.end.value + 1
  )

// ============================================
// Overlap Pairs Detection
// ============================================

define "Overlap Pair Days":
  Sum(
    flatten (
      "Lipid Lowering Prescriptions" P1
        return
          "Lipid Lowering Prescriptions" P2
            where P2.id.value > P1.id.value
              and P1.encounter.reference.value != P2.encounter.reference.value
              and CalculateOverlapDays(
                date from P1.dispenseRequest.validityPeriod.start.value,
                date from P1.dispenseRequest.validityPeriod.end.value,
                date from P2.dispenseRequest.validityPeriod.start.value,
                date from P2.dispenseRequest.validityPeriod.end.value
              ) > 0
            return CalculateOverlapDays(
              date from P1.dispenseRequest.validityPeriod.start.value,
              date from P1.dispenseRequest.validityPeriod.end.value,
              date from P2.dispenseRequest.validityPeriod.start.value,
              date from P2.dispenseRequest.validityPeriod.end.value
            )
    )
  )

// ============================================
// Rate Calculation
// ============================================

define "Drug Overlap Rate":
  if "Total Drug Days" > 0 then
    (ToDecimal(Coalesce("Overlap Pair Days", 0)) / ToDecimal("Total Drug Days")) * 100
  else null

// ============================================
// Quarterly Statistics
// ============================================

define "2024Q1 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-01-01, @2024-03-31]

define "2024Q1 Drug Days":
  Sum("2024Q1 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q1 Overlap Days":
  Sum(flatten("2024Q1 Prescriptions" P1 return "2024Q1 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q1 Rate":
  if "2024Q1 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q1 Overlap Days", 0)) / ToDecimal("2024Q1 Drug Days")) * 100 else null

define "2024Q2 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-04-01, @2024-06-30]

define "2024Q2 Drug Days":
  Sum("2024Q2 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q2 Overlap Days":
  Sum(flatten("2024Q2 Prescriptions" P1 return "2024Q2 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q2 Rate":
  if "2024Q2 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q2 Overlap Days", 0)) / ToDecimal("2024Q2 Drug Days")) * 100 else null

define "2024Q3 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-07-01, @2024-09-30]

define "2024Q3 Drug Days":
  Sum("2024Q3 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q3 Overlap Days":
  Sum(flatten("2024Q3 Prescriptions" P1 return "2024Q3 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q3 Rate":
  if "2024Q3 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q3 Overlap Days", 0)) / ToDecimal("2024Q3 Drug Days")) * 100 else null

define "2024Q4 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-10-01, @2024-12-31]

define "2024Q4 Drug Days":
  Sum("2024Q4 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q4 Overlap Days":
  Sum(flatten("2024Q4 Prescriptions" P1 return "2024Q4 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q4 Rate":
  if "2024Q4 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q4 Overlap Days", 0)) / ToDecimal("2024Q4 Drug Days")) * 100 else null

define "2025Q1 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-01-01, @2025-03-31]

define "2025Q1 Drug Days":
  Sum("2025Q1 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q1 Overlap Days":
  Sum(flatten("2025Q1 Prescriptions" P1 return "2025Q1 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q1 Rate":
  if "2025Q1 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q1 Overlap Days", 0)) / ToDecimal("2025Q1 Drug Days")) * 100 else null

define "2025Q2 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-04-01, @2025-06-30]

define "2025Q2 Drug Days":
  Sum("2025Q2 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q2 Overlap Days":
  Sum(flatten("2025Q2 Prescriptions" P1 return "2025Q2 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q2 Rate":
  if "2025Q2 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q2 Overlap Days", 0)) / ToDecimal("2025Q2 Drug Days")) * 100 else null

define "2025Q3 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-07-01, @2025-09-30]

define "2025Q3 Drug Days":
  Sum("2025Q3 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q3 Overlap Days":
  Sum(flatten("2025Q3 Prescriptions" P1 return "2025Q3 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q3 Rate":
  if "2025Q3 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q3 Overlap Days", 0)) / ToDecimal("2025Q3 Drug Days")) * 100 else null

define "2025Q4 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-10-01, @2025-12-31]

define "2025Q4 Drug Days":
  Sum("2025Q4 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q4 Overlap Days":
  Sum(flatten("2025Q4 Prescriptions" P1 return "2025Q4 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q4 Rate":
  if "2025Q4 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q4 Overlap Days", 0)) / ToDecimal("2025Q4 Drug Days")) * 100 else null

define "2026Q1 Prescriptions":
  "Lipid Lowering Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2026-01-01, @2026-03-31]

define "2026Q1 Drug Days":
  Sum("2026Q1 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2026Q1 Overlap Days":
  Sum(flatten("2026Q1 Prescriptions" P1 return "2026Q1 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2026Q1 Rate":
  if "2026Q1 Drug Days" > 0 then (ToDecimal(Coalesce("2026Q1 Overlap Days", 0)) / ToDecimal("2026Q1 Drug Days")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1711',
    indicatorName: '同醫院門診同藥理用藥日數重疊率-降血脂(口服)',
    drugCategory: '降血脂藥(口服)',
    atcCriteria: 'C10AA, C10AB, C10AC, C10AD, C10AX',
    excludeInjection: '醫令第8碼不為1',
    totalDrugDays: "Total Drug Days",
    totalOverlapDays: "Overlap Pair Days",
    overallRate: "Drug Overlap Rate",
    quarters: List{
      Tuple { quarter: '2024Q1', drugDays: "2024Q1 Drug Days", overlapDays: "2024Q1 Overlap Days", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', drugDays: "2024Q2 Drug Days", overlapDays: "2024Q2 Overlap Days", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', drugDays: "2024Q3 Drug Days", overlapDays: "2024Q3 Overlap Days", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', drugDays: "2024Q4 Drug Days", overlapDays: "2024Q4 Overlap Days", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', drugDays: "2025Q1 Drug Days", overlapDays: "2025Q1 Overlap Days", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', drugDays: "2025Q2 Drug Days", overlapDays: "2025Q2 Overlap Days", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', drugDays: "2025Q3 Drug Days", overlapDays: "2025Q3 Overlap Days", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', drugDays: "2025Q4 Drug Days", overlapDays: "2025Q4 Overlap Days", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', drugDays: "2026Q1 Drug Days", overlapDays: "2026Q1 Overlap Days", rate: "2026Q1 Rate" }
    }
  }
