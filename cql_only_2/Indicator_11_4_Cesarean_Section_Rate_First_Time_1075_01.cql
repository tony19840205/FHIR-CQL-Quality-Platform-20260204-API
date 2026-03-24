library Indicator_11_4_Cesarean_Section_Rate_First_Time_1075_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

define function GetDischargeDate(encounter Encounter):
  end of encounter.period

define function GetTWDRG(encounter Encounter):
  singleton from (
    [Claim] C
      where C.id.value.contains(encounter.id.value)
      return First(
        C.extension E
          where E.url.value = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/tw-drg'
          return (E.value as FHIR.string).value
      )
  )

define function GetDRGCode(encounter Encounter):
  singleton from (
    [Claim] C
      where C.id.value.contains(encounter.id.value)
      return First(
        C.extension E
          where E.url.value = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drg-code'
          return (E.value as FHIR.string).value
      )
  )

define function GetDRGPrefix3(twdrg String):
  if twdrg is not null and Length(twdrg) >= 3 then Substring(twdrg, 0, 3) else null

define function GetMainDiagnosis(encounter Encounter):
  singleton from (
    [Condition] C
      where C.encounter.reference.value.contains(encounter.id.value)
        and exists(C.category.coding cc where cc.code.value = 'principal-diagnosis')
      return First(C.code.coding).code.value
  )

define function GetSecondaryDiagnosis(encounter Encounter):
  singleton from (
    [Condition] C
      where C.encounter.reference.value.contains(encounter.id.value)
        and exists(C.category.coding cc where cc.code.value = 'secondary-diagnosis')
      return First(C.code.coding).code.value
  )

define function HasNaturalProcedure(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value.contains(encounter.id.value)
        and P.status.value = 'completed'
        and First(P.code.coding).code.value in {'81017C','81018C','81019C','81024C','81025C','81026C','81034C','97004C','97005D','97934C'}
  )

define function HasCesareanProcedure(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value.contains(encounter.id.value)
        and P.status.value = 'completed'
        and First(P.code.coding).code.value in {'81004C','81005C','81028C','81029C','97009C','97014C'}
  )

define function HasFirstTimeCesareanProcedure(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value.contains(encounter.id.value)
        and P.status.value = 'completed'
        and First(P.code.coding).code.value in {'81004C','81028C','10D00Z0','10D00Z1','10D00Z2'}
  )

define function HasICD10PCSCesarean(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value.contains(encounter.id.value)
        and P.status.value = 'completed'
        and First(P.code.coding).code.value in {'10D00Z0','10D00Z1','10D00Z2'}
  )

define function HasPreviousCesareanDiagnosis(encounter Encounter):
  (GetMainDiagnosis(encounter) = 'O342') or (GetSecondaryDiagnosis(encounter) = 'O342')

define function IsNaturalDelivery(encounter Encounter):
  GetDRGPrefix3(GetTWDRG(encounter)) in {'372','373','374','375'} or GetDRGCode(encounter) in {'0373A','0373C'} or HasNaturalProcedure(encounter)

define function IsCesareanDelivery(encounter Encounter):
  GetDRGPrefix3(GetTWDRG(encounter)) in {'370','371','513'} or GetDRGCode(encounter) in {'0371A','0373B'} or HasCesareanProcedure(encounter)

define function IsFirstTimeWithIndicationCesarean(encounter Encounter):
  HasFirstTimeCesareanProcedure(encounter) and GetDRGCode(encounter) != '0373B' and not (HasICD10PCSCesarean(encounter) and HasPreviousCesareanDiagnosis(encounter))

define "All Inpatient Discharges":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and GetDischargeDate(E) during "Measurement Period"

define "Natural Deliveries":
  "All Inpatient Discharges" E where IsNaturalDelivery(E)

define "Cesarean Deliveries":
  "All Inpatient Discharges" E where IsCesareanDelivery(E)

define "First Time Cesarean With Indication Deliveries":
  "Cesarean Deliveries" E where IsFirstTimeWithIndicationCesarean(E)

define "All Deliveries":
  distinct ("Natural Deliveries" union "Cesarean Deliveries")
define "2024Q1 Period": Interval[@2024-01-01, @2024-03-31]
define "2024Q1 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2024Q1 Period"))
define "2024Q1 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2024Q1 Period"))
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then Round(("2024Q1 Numerator" / "2024Q1 Denominator") * 100.0, 2) else 0.0

define "2024Q2 Period": Interval[@2024-04-01, @2024-06-30]
define "2024Q2 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2024Q2 Period"))
define "2024Q2 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2024Q2 Period"))
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then Round(("2024Q2 Numerator" / "2024Q2 Denominator") * 100.0, 2) else 0.0

define "2024Q3 Period": Interval[@2024-07-01, @2024-09-30]
define "2024Q3 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2024Q3 Period"))
define "2024Q3 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2024Q3 Period"))
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then Round(("2024Q3 Numerator" / "2024Q3 Denominator") * 100.0, 2) else 0.0

define "2024Q4 Period": Interval[@2024-10-01, @2024-12-31]
define "2024Q4 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2024Q4 Period"))
define "2024Q4 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2024Q4 Period"))
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then Round(("2024Q4 Numerator" / "2024Q4 Denominator") * 100.0, 2) else 0.0

define "2025Q1 Period": Interval[@2025-01-01, @2025-03-31]
define "2025Q1 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2025Q1 Period"))
define "2025Q1 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2025Q1 Period"))
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then Round(("2025Q1 Numerator" / "2025Q1 Denominator") * 100.0, 2) else 0.0

define "2025Q2 Period": Interval[@2025-04-01, @2025-06-30]
define "2025Q2 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2025Q2 Period"))
define "2025Q2 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2025Q2 Period"))
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then Round(("2025Q2 Numerator" / "2025Q2 Denominator") * 100.0, 2) else 0.0

define "2025Q3 Period": Interval[@2025-07-01, @2025-09-30]
define "2025Q3 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2025Q3 Period"))
define "2025Q3 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2025Q3 Period"))
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then Round(("2025Q3 Numerator" / "2025Q3 Denominator") * 100.0, 2) else 0.0

define "2025Q4 Period": Interval[@2025-10-01, @2025-12-31]
define "2025Q4 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2025Q4 Period"))
define "2025Q4 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2025Q4 Period"))
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then Round(("2025Q4 Numerator" / "2025Q4 Denominator") * 100.0, 2) else 0.0

define "2026Q1 Period": Interval[@2026-01-01, @2026-03-31]
define "2026Q1 Denominator": Count(distinct("All Deliveries" D where GetDischargeDate(D) during "2026Q1 Period"))
define "2026Q1 Numerator": Count(distinct("First Time Cesarean With Indication Deliveries" C where GetDischargeDate(C) during "2026Q1 Period"))
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then Round(("2026Q1 Numerator" / "2026Q1 Denominator") * 100.0, 2) else 0.0

define "Total Denominator": Count(distinct("All Deliveries"))
define "Total Numerator": Count(distinct("First Time Cesarean With Indication Deliveries"))
define "Total Rate": if "Total Denominator" > 0 then Round(("Total Numerator" / "Total Denominator") * 100.0, 2) else 0.0

define "Indicator Result": { indicatorCode: '1075.01', indicatorName: 'First Time Cesarean With Indication', version: '1.0.0', q2024_1_denominator: "2024Q1 Denominator", q2024_1_numerator: "2024Q1 Numerator", q2024_1_rate: "2024Q1 Rate", q2024_2_denominator: "2024Q2 Denominator", q2024_2_numerator: "2024Q2 Numerator", q2024_2_rate: "2024Q2 Rate", q2024_3_denominator: "2024Q3 Denominator", q2024_3_numerator: "2024Q3 Numerator", q2024_3_rate: "2024Q3 Rate", q2024_4_denominator: "2024Q4 Denominator", q2024_4_numerator: "2024Q4 Numerator", q2024_4_rate: "2024Q4 Rate", q2025_1_denominator: "2025Q1 Denominator", q2025_1_numerator: "2025Q1 Numerator", q2025_1_rate: "2025Q1 Rate", q2025_2_denominator: "2025Q2 Denominator", q2025_2_numerator: "2025Q2 Numerator", q2025_2_rate: "2025Q2 Rate", q2025_3_denominator: "2025Q3 Denominator", q2025_3_numerator: "2025Q3 Numerator", q2025_3_rate: "2025Q3 Rate", q2025_4_denominator: "2025Q4 Denominator", q2025_4_numerator: "2025Q4 Numerator", q2025_4_rate: "2025Q4 Rate", q2026_1_denominator: "2026Q1 Denominator", q2026_1_numerator: "2026Q1 Numerator", q2026_1_rate: "2026Q1 Rate", total_denominator: "Total Denominator", total_numerator: "Total Numerator", total_rate: "Total Rate" }