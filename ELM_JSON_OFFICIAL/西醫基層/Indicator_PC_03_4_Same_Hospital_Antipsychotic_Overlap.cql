library Indicator_PC_03_4_Same_Hospital_Antipsychotic_Overlap version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 指標名稱: 西醫基層門診同院所同藥理用藥日數重疊率-抗思覺失調症
// 指標代碼: 1726
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
//
// 資料範圍:
//   西醫基層總額之門診處方抗思覺失調症藥物案件，排除代辦案件
//
// 公式說明:
//   分子: 同院所同ID不同處方之開始用藥日期與結束用藥日期間
//         有重疊之給藥日數 (允許慢箋提早拿藥)
//   分母: 各案件之「給藥日數」總和
//
//   (1) 「給藥日數」抓取醫令檔之醫令給藥日份(ORDER_DRUG_DAY)，
//       若為空值則抓清單檔之給藥日份(DRUG_DAYS)。
//   (2) 抗思覺失調藥物: ATC前5碼=
//       N05AA (Phenothiazines aliphatic)、N05AB (Phenothiazines piperazine)、
//       N05AC (Phenothiazines piperidine)、N05AD (Butyrophenones)、
//       N05AE (Indole derivatives)、N05AF (Thioxanthenes)、
//       N05AG (Diphenylbutylpiperidines)、N05AH (Diazepines/Oxazepines)、
//       N05AL (Benzamides)、N05AN(排除 N05AN01)、N05AX (Other antipsychotics)。
//       不限醫令代碼第8碼。
//
// 製表日期: 114/10/22
// ============================================

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

define function GetExtCodingCode(E FHIR.Encounter, extUrl String):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.Coding).code.value
    ),
    ''
  )

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

// ============================================
// Antipsychotic ATC Check
// N05AN 系列排除 N05AN01 (Lithium)
// ============================================

define function IsAntipsychoticATC(atcCode String):
  (
    Substring(atcCode, 0, 5) in {
      'N05AA', 'N05AB', 'N05AC', 'N05AD', 'N05AE',
      'N05AF', 'N05AG', 'N05AH', 'N05AL', 'N05AX'
    }
  )
  or (Substring(atcCode, 0, 5) = 'N05AN' and atcCode != 'N05AN01')

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
// Outpatient Encounters (西醫基層, 排除代辦)
// ============================================

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'
      and not IsAgencyCase(E)

// ============================================
// Antipsychotic MedicationRequests
// ============================================

define "Antipsychotic Prescriptions":
  [MedicationRequest] MR
    let medCodings: (MR.medication as FHIR.CodeableConcept).coding
    where MR.status.value = 'completed'
      and exists(
        medCodings AC
          where AC.system.value = 'http://www.whocc.no/atc'
            and IsAntipsychoticATC(AC.code.value)
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
    "Antipsychotic Prescriptions" P
      return days between date from P.dispenseRequest.validityPeriod.start.value
                     and date from P.dispenseRequest.validityPeriod.end.value + 1
  )

// ============================================
// Overlap Pair Days (Numerator base)
// 同院所同ID不同處方有重疊之給藥日數
// ============================================

define "Overlap Pair Days":
  Sum(
    flatten (
      "Antipsychotic Prescriptions" P1
        return
          "Antipsychotic Prescriptions" P2
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
// Quarterly Statistics (2024Q1 ~ 2026Q1)
// ============================================

define "2024Q1 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-01-01, @2024-03-31]

define "2024Q1 Drug Days":
  Sum("2024Q1 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q1 Overlap Days":
  Sum(flatten("2024Q1 Prescriptions" P1 return "2024Q1 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q1 Rate":
  if "2024Q1 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q1 Overlap Days", 0)) / ToDecimal("2024Q1 Drug Days")) * 100 else null

define "2024Q2 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-04-01, @2024-06-30]

define "2024Q2 Drug Days":
  Sum("2024Q2 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q2 Overlap Days":
  Sum(flatten("2024Q2 Prescriptions" P1 return "2024Q2 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q2 Rate":
  if "2024Q2 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q2 Overlap Days", 0)) / ToDecimal("2024Q2 Drug Days")) * 100 else null

define "2024Q3 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-07-01, @2024-09-30]

define "2024Q3 Drug Days":
  Sum("2024Q3 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q3 Overlap Days":
  Sum(flatten("2024Q3 Prescriptions" P1 return "2024Q3 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q3 Rate":
  if "2024Q3 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q3 Overlap Days", 0)) / ToDecimal("2024Q3 Drug Days")) * 100 else null

define "2024Q4 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2024-10-01, @2024-12-31]

define "2024Q4 Drug Days":
  Sum("2024Q4 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2024Q4 Overlap Days":
  Sum(flatten("2024Q4 Prescriptions" P1 return "2024Q4 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2024Q4 Rate":
  if "2024Q4 Drug Days" > 0 then (ToDecimal(Coalesce("2024Q4 Overlap Days", 0)) / ToDecimal("2024Q4 Drug Days")) * 100 else null

define "2025Q1 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-01-01, @2025-03-31]

define "2025Q1 Drug Days":
  Sum("2025Q1 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q1 Overlap Days":
  Sum(flatten("2025Q1 Prescriptions" P1 return "2025Q1 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q1 Rate":
  if "2025Q1 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q1 Overlap Days", 0)) / ToDecimal("2025Q1 Drug Days")) * 100 else null

define "2025Q2 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-04-01, @2025-06-30]

define "2025Q2 Drug Days":
  Sum("2025Q2 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q2 Overlap Days":
  Sum(flatten("2025Q2 Prescriptions" P1 return "2025Q2 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q2 Rate":
  if "2025Q2 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q2 Overlap Days", 0)) / ToDecimal("2025Q2 Drug Days")) * 100 else null

define "2025Q3 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-07-01, @2025-09-30]

define "2025Q3 Drug Days":
  Sum("2025Q3 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q3 Overlap Days":
  Sum(flatten("2025Q3 Prescriptions" P1 return "2025Q3 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q3 Rate":
  if "2025Q3 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q3 Overlap Days", 0)) / ToDecimal("2025Q3 Drug Days")) * 100 else null

define "2025Q4 Prescriptions":
  "Antipsychotic Prescriptions" P
    where date from P.dispenseRequest.validityPeriod.start.value in Interval[@2025-10-01, @2025-12-31]

define "2025Q4 Drug Days":
  Sum("2025Q4 Prescriptions" P return days between date from P.dispenseRequest.validityPeriod.start.value and date from P.dispenseRequest.validityPeriod.end.value + 1)

define "2025Q4 Overlap Days":
  Sum(flatten("2025Q4 Prescriptions" P1 return "2025Q4 Prescriptions" P2 where P2.id.value > P1.id.value and P1.encounter.reference.value != P2.encounter.reference.value and CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value) > 0 return CalculateOverlapDays(date from P1.dispenseRequest.validityPeriod.start.value, date from P1.dispenseRequest.validityPeriod.end.value, date from P2.dispenseRequest.validityPeriod.start.value, date from P2.dispenseRequest.validityPeriod.end.value)))

define "2025Q4 Rate":
  if "2025Q4 Drug Days" > 0 then (ToDecimal(Coalesce("2025Q4 Overlap Days", 0)) / ToDecimal("2025Q4 Drug Days")) * 100 else null

define "2026Q1 Prescriptions":
  "Antipsychotic Prescriptions" P
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
    indicatorCode: '1726',
    indicatorName: '西醫基層門診同院所同藥理用藥日數重疊率-抗思覺失調症',
    drugCategory: '抗思覺失調藥物',
    atcCriteria: 'N05AA/N05AB/N05AC/N05AD/N05AE/N05AF/N05AG/N05AH/N05AL/N05AN(排除N05AN01)/N05AX',
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
