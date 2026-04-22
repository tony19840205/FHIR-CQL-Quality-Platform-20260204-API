library Indicator_11_3_Cesarean_Section_Rate_With_Indication_1138_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.0]

define function "GetId"(reference Reference):
  Last(Split(reference.reference.value, '/'))

define function "GetEncounterId"(encounter Encounter):
  encounter.id.value

define function "GetDischargeDate"(encounter Encounter):
  encounter.period.end.value

define function "GetTWDRG"(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/tw-drg'
      return (E.value as FHIR.string).value
  )

define function "GetDRGCode"(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/drg-code'
      return (E.value as FHIR.string).value
  )

define function "GetDRGPrefix3"(drgCode String):
  if drgCode is null then null
  else if Length(drgCode) >= 3 then Substring(drgCode, 0, 3)
  else drgCode

define function "HasNaturalDeliveryProcedure"(encounter Encounter):
  exists(
    [Procedure] P
      where "GetId"(P.encounter) = "GetEncounterId"(encounter)
        and exists(
          P.code.coding C
            where C.code.value in {
              '81017C', '81018C', '81019C', '81024C', '81025C',
              '81026C', '81034C', '97004C', '97005D', '97934C'
            }
        )
  )

define function "HasCesareanDeliveryProcedure"(encounter Encounter):
  exists(
    [Procedure] P
      where "GetId"(P.encounter) = "GetEncounterId"(encounter)
        and exists(
          P.code.coding C
            where C.code.value in {
              '81004C', '81005C', '81028C', '81029C', '97009C', '97014C'
            }
        )
  )

define function "HasPatientRequestedProcedure"(encounter Encounter):
  exists(
    [Procedure] P
      where "GetId"(P.encounter) = "GetEncounterId"(encounter)
        and exists(
          P.code.coding C
            where C.code.value = '97014C'
        )
  )

define function "IsNaturalDelivery"(encounter Encounter):
  (
    "GetDRGPrefix3"("GetTWDRG"(encounter)) in {'372', '373', '374', '375'}
    or "GetDRGCode"(encounter) in {'0373A', '0373C'}
    or "HasNaturalDeliveryProcedure"(encounter)
  )

define function "IsCesareanDelivery"(encounter Encounter):
  (
    "GetDRGPrefix3"("GetTWDRG"(encounter)) in {'370', '371', '513'}
    or "GetDRGCode"(encounter) in {'0371A', '0373B'}
    or "HasCesareanDeliveryProcedure"(encounter)
  )

define function "IsPatientRequestedCesarean"(encounter Encounter):
  (
    "GetDRGPrefix3"("GetTWDRG"(encounter)) = '513'
    or "GetDRGCode"(encounter) = '0373B'
    or "HasPatientRequestedProcedure"(encounter)
  )

define "All Inpatient Discharges":
  [Encounter] E
    where E.class.code.value = 'IMP'
      and E.status.value = 'finished'
      and E.period.end.value during "Measurement Period"

define "Natural Deliveries":
  "All Inpatient Discharges" E
    where "IsNaturalDelivery"(E)

define "Cesarean Deliveries":
  "All Inpatient Discharges" E
    where "IsCesareanDelivery"(E)

define "Patient Requested Cesarean Deliveries":
  "All Inpatient Discharges" E
    where "IsPatientRequestedCesarean"(E)

define "Cesarean With Indication Deliveries":
  distinct ("Cesarean Deliveries" except "Patient Requested Cesarean Deliveries")

define "All Deliveries":
  distinct ("Natural Deliveries" union "Cesarean Deliveries")
define "2024Q1 Period": Interval[@2024-01-01, @2024-03-31]
define "2024Q2 Period": Interval[@2024-04-01, @2024-06-30]
define "2024Q3 Period": Interval[@2024-07-01, @2024-09-30]
define "2024Q4 Period": Interval[@2024-10-01, @2024-12-31]
define "2025Q1 Period": Interval[@2025-01-01, @2025-03-31]
define "2025Q2 Period": Interval[@2025-04-01, @2025-06-30]
define "2025Q3 Period": Interval[@2025-07-01, @2025-09-30]
define "2025Q4 Period": Interval[@2025-10-01, @2025-12-31]
define "2026Q1 Period": Interval[@2026-01-01, @2026-03-31]

define "2024Q1 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2024Q1 Period"))
define "2024Q1 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2024Q1 Period"))
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then Round(("2024Q1 Numerator" / "2024Q1 Denominator") * 100.0, 2) else 0.0

define "2024Q2 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2024Q2 Period"))
define "2024Q2 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2024Q2 Period"))
define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then Round(("2024Q2 Numerator" / "2024Q2 Denominator") * 100.0, 2) else 0.0

define "2024Q3 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2024Q3 Period"))
define "2024Q3 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2024Q3 Period"))
define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then Round(("2024Q3 Numerator" / "2024Q3 Denominator") * 100.0, 2) else 0.0

define "2024Q4 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2024Q4 Period"))
define "2024Q4 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2024Q4 Period"))
define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then Round(("2024Q4 Numerator" / "2024Q4 Denominator") * 100.0, 2) else 0.0

define "2025Q1 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2025Q1 Period"))
define "2025Q1 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2025Q1 Period"))
define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then Round(("2025Q1 Numerator" / "2025Q1 Denominator") * 100.0, 2) else 0.0

define "2025Q2 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2025Q2 Period"))
define "2025Q2 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2025Q2 Period"))
define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then Round(("2025Q2 Numerator" / "2025Q2 Denominator") * 100.0, 2) else 0.0

define "2025Q3 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2025Q3 Period"))
define "2025Q3 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2025Q3 Period"))
define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then Round(("2025Q3 Numerator" / "2025Q3 Denominator") * 100.0, 2) else 0.0

define "2025Q4 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2025Q4 Period"))
define "2025Q4 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2025Q4 Period"))
define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then Round(("2025Q4 Numerator" / "2025Q4 Denominator") * 100.0, 2) else 0.0

define "2026Q1 Denominator":
  Count(distinct("All Deliveries" D where "GetDischargeDate"(D) during "2026Q1 Period"))
define "2026Q1 Numerator":
  Count(distinct("Cesarean With Indication Deliveries" C where "GetDischargeDate"(C) during "2026Q1 Period"))
define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then Round(("2026Q1 Numerator" / "2026Q1 Denominator") * 100.0, 2) else 0.0

define "Total Denominator": Count(distinct "All Deliveries")
define "Total Numerator": Count(distinct "Cesarean With Indication Deliveries")
define "Total Rate":
  if "Total Denominator" > 0 then Round(("Total Numerator" / "Total Denominator") * 100.0, 2) else 0.0

define "Indicator Result": { indicatorCode: '1138.01', indicatorName: 'Cesarean With Indication', version: '1.0.0', q2024_1_denominator: "2024Q1 Denominator", q2024_1_numerator: "2024Q1 Numerator", q2024_1_rate: "2024Q1 Rate", q2024_2_denominator: "2024Q2 Denominator", q2024_2_numerator: "2024Q2 Numerator", q2024_2_rate: "2024Q2 Rate", q2024_3_denominator: "2024Q3 Denominator", q2024_3_numerator: "2024Q3 Numerator", q2024_3_rate: "2024Q3 Rate", q2024_4_denominator: "2024Q4 Denominator", q2024_4_numerator: "2024Q4 Numerator", q2024_4_rate: "2024Q4 Rate", q2025_1_denominator: "2025Q1 Denominator", q2025_1_numerator: "2025Q1 Numerator", q2025_1_rate: "2025Q1 Rate", q2025_2_denominator: "2025Q2 Denominator", q2025_2_numerator: "2025Q2 Numerator", q2025_2_rate: "2025Q2 Rate", q2025_3_denominator: "2025Q3 Denominator", q2025_3_numerator: "2025Q3 Numerator", q2025_3_rate: "2025Q3 Rate", q2025_4_denominator: "2025Q4 Denominator", q2025_4_numerator: "2025Q4 Numerator", q2025_4_rate: "2025Q4 Rate", q2026_1_denominator: "2026Q1 Denominator", q2026_1_numerator: "2026Q1 Numerator", q2026_1_rate: "2026Q1 Rate", total_denominator: "Total Denominator", total_numerator: "Total Numerator", total_rate: "Total Rate" }