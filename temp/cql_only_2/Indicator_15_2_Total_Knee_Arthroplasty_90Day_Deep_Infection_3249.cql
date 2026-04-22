library Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 全人工膝關節置換手術後九十日以內置換物深部感染率
// 指標代碼: 3249
// 資料來源: 醫療給付檔案分析系統，指標代碼：3249
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署

codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

code "Finished": 'finished' from "EncounterStatus" display '已完成'
code "Inpatient": 'IMP' from "ActCode" display '住院'
code "Case_Category_05": '05' from "NHI_CLAIM" display '住院西醫'

code "Total_TKA_64164B": '64164B' from "NHI_PROCEDURE" display '全人工膝關節置換術64164B'
code "Total_TKA_97805K": '97805K' from "NHI_PROCEDURE" display '全人工膝關節置換術97805K'
code "Total_TKA_97806A": '97806A' from "NHI_PROCEDURE" display '全人工膝關節置換術97806A'
code "Total_TKA_97807B": '97807B' from "NHI_PROCEDURE" display '全人工膝關節置換術97807B'


code "Infection_Surgery_64053B": '64053B' from "NHI_PROCEDURE" display '感染清創術64053B'
code "Infection_Surgery_64198B": '64198B' from "NHI_PROCEDURE" display '置換物移除術64198B'

valueset "Inpatient Encounters": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

define function GetId(encounter Encounter):
  Last(Split(encounter.id, '/'))

define function GetDischargeDate(encounter Encounter):
  end of FHIRHelpers.ToInterval(encounter.period)

define function GetCaseCategory(encounter Encounter):
  First(
    encounter.type T
      where exists (T.coding C where C.system = 'http://www.nhi.gov.tw/codes/claim')
      return First(T.coding).code.value
  )

define function HasTotalTKAProcedure(encounter Encounter):
  exists (
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and First((PE.value as CodeableConcept).coding).code.value in {'64164B', '97805K', '97806A', '97807B'}
        )
  )

define function GetTKAProcedureDate(encounter Encounter):
  First(
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and First((PE.value as CodeableConcept).coding).code.value in {'64164B', '97805K', '97806A', '97807B'}
        )
      return First(
        E.extension PE
          where PE.url = 'performedDateTime'
          return (PE.value as dateTime).value
      )
  )

define function HasInfectionSurgeryWithin90Days(encounter Encounter, tkaDate DateTime):
  exists (
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and First((PE.value as CodeableConcept).coding).code.value in {'64053B', '64198B'}
        )
        and exists (
          E.extension PE
            where PE.url = 'performedDateTime'
              and (PE.value as dateTime).value in Interval[tkaDate, tkaDate + 90 days]
        )
  )

define function HasSameDayExclusion(encounter Encounter):
  exists (
    encounter.extension E1
      where E1.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E1.extension PE1
            where PE1.url = 'code'
              and First((PE1.value as CodeableConcept).coding).code.value = '64164B'
        )
        and exists (
          encounter.extension E2
            where E2.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
              and exists (
                E2.extension PE2
                  where PE2.url = 'code'
                    and First((PE2.value as CodeableConcept).coding).code.value = '64198B'
              )
              and First(E1.extension Ex1 where Ex1.url = 'performedDateTime' return (Ex1.value as dateTime).value)
                = First(E2.extension Ex2 where Ex2.url = 'performedDateTime' return (Ex2.value as dateTime).value)
        )
  )

define "All Inpatient Discharges":
  [Encounter: type in "Inpatient Encounters"] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and GetDischargeDate(E) during "Measurement Period"
      and GetCaseCategory(E) = '05'

define "Denominator Cases":
  "All Inpatient Discharges" E
    where HasTotalTKAProcedure(E)

define "Numerator Cases":
  "Denominator Cases" E
    let tkaDate: GetTKAProcedureDate(E)
    where tkaDate is not null
      and HasInfectionSurgeryWithin90Days(E, tkaDate)
      and not HasSameDayExclusion(E)

define "2024Q1 Start": DateTime(2024, 1, 1, 0, 0, 0, 0)
define "2024Q1 End": DateTime(2024, 3, 31, 23, 59, 59, 999)
define "2024Q2 Start": DateTime(2024, 4, 1, 0, 0, 0, 0)
define "2024Q2 End": DateTime(2024, 6, 30, 23, 59, 59, 999)
define "2024Q3 Start": DateTime(2024, 7, 1, 0, 0, 0, 0)
define "2024Q3 End": DateTime(2024, 9, 30, 23, 59, 59, 999)
define "2024Q4 Start": DateTime(2024, 10, 1, 0, 0, 0, 0)
define "2024Q4 End": DateTime(2024, 12, 31, 23, 59, 59, 999)
define "2025Q1 Start": DateTime(2025, 1, 1, 0, 0, 0, 0)
define "2025Q1 End": DateTime(2025, 3, 31, 23, 59, 59, 999)
define "2025Q2 Start": DateTime(2025, 4, 1, 0, 0, 0, 0)
define "2025Q2 End": DateTime(2025, 6, 30, 23, 59, 59, 999)
define "2025Q3 Start": DateTime(2025, 7, 1, 0, 0, 0, 0)
define "2025Q3 End": DateTime(2025, 9, 30, 23, 59, 59, 999)
define "2025Q4 Start": DateTime(2025, 10, 1, 0, 0, 0, 0)
define "2025Q4 End": DateTime(2025, 12, 31, 23, 59, 59, 999)
define "2026Q1 Start": DateTime(2026, 1, 1, 0, 0, 0, 0)
define "2026Q1 End": DateTime(2026, 3, 31, 23, 59, 59, 999)

define "2024Q1 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"]
  )

define "2024Q1 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"]
  )

define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0
  then ("2024Q1 Numerator" / "2024Q1 Denominator") * 100
  else null

define "2024Q2 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"]
  )

define "2024Q2 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"]
  )

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0
  then ("2024Q2 Numerator" / "2024Q2 Denominator") * 100
  else null

define "2024Q3 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"]
  )

define "2024Q3 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"]
  )

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0
  then ("2024Q3 Numerator" / "2024Q3 Denominator") * 100
  else null

define "2024Q4 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"]
  )

define "2024Q4 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"]
  )

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0
  then ("2024Q4 Numerator" / "2024Q4 Denominator") * 100
  else null

define "2025Q1 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"]
  )

define "2025Q1 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"]
  )

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0
  then ("2025Q1 Numerator" / "2025Q1 Denominator") * 100
  else null

define "2025Q2 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"]
  )

define "2025Q2 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"]
  )

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0
  then ("2025Q2 Numerator" / "2025Q2 Denominator") * 100
  else null

define "2025Q3 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"]
  )

define "2025Q3 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"]
  )

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0
  then ("2025Q3 Numerator" / "2025Q3 Denominator") * 100
  else null

define "2025Q4 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"]
  )

define "2025Q4 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"]
  )

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0
  then ("2025Q4 Numerator" / "2025Q4 Denominator") * 100
  else null

define "2026Q1 Denominator":
  Count(
    "Denominator Cases" E
      where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"]
  )

define "2026Q1 Numerator":
  Count(
    "Numerator Cases" E
      where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"]
  )

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0
  then ("2026Q1 Numerator" / "2026Q1 Denominator") * 100
  else null

define "Total Denominator":
  Count("Denominator Cases")

define "Total Numerator":
  Count("Numerator Cases")

define "Overall Rate":
  if "Total Denominator" > 0
  then ("Total Numerator" / "Total Denominator") * 100
  else null

define "Indicator Result":
  {
    IndicatorCode: '3249',
    IndicatorName: '全人工膝關節置換手術後九十日以內置換物深部感染率',
    MeasurementPeriod: "Measurement Period",
    TotalDenominator: "Total Denominator",
    TotalNumerator: "Total Numerator",
    OverallRate: "Overall Rate",
    Q2024_1_Denominator: "2024Q1 Denominator",
    Q2024_1_Numerator: "2024Q1 Numerator",
    Q2024_1_Rate: "2024Q1 Rate",
    Q2024_2_Denominator: "2024Q2 Denominator",
    Q2024_2_Numerator: "2024Q2 Numerator",
    Q2024_2_Rate: "2024Q2 Rate",
    Q2024_3_Denominator: "2024Q3 Denominator",
    Q2024_3_Numerator: "2024Q3 Numerator",
    Q2024_3_Rate: "2024Q3 Rate",
    Q2024_4_Denominator: "2024Q4 Denominator",
    Q2024_4_Numerator: "2024Q4 Numerator",
    Q2024_4_Rate: "2024Q4 Rate",
    Q2025_1_Denominator: "2025Q1 Denominator",
    Q2025_1_Numerator: "2025Q1 Numerator",
    Q2025_1_Rate: "2025Q1 Rate",
    Q2025_2_Denominator: "2025Q2 Denominator",
    Q2025_2_Numerator: "2025Q2 Numerator",
    Q2025_2_Rate: "2025Q2 Rate",
    Q2025_3_Denominator: "2025Q3 Denominator",
    Q2025_3_Numerator: "2025Q3 Numerator",
    Q2025_3_Rate: "2025Q3 Rate",
    Q2025_4_Denominator: "2025Q4 Denominator",
    Q2025_4_Numerator: "2025Q4 Numerator",
    Q2025_4_Rate: "2025Q4 Rate",
    Q2026_1_Denominator: "2026Q1 Denominator",
    Q2026_1_Numerator: "2026Q1 Numerator",
    Q2026_1_Rate: "2026Q1 Rate"
  }