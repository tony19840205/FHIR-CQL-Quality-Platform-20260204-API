library Indicator_13_Average_ESWL_Utilization_Times_20_01Q_1804Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 接受體外震波碎石術(ESWL)病人平均利用ESWL之次數
// 指標代碼: 20.01 (季), 1804 (年)
// 資料來源: 醫療給付檔案分析系統，指標代碼：20.01 (季)、1804 (年)
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署

codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

code "Finished": 'finished' from "EncounterStatus" display '已完成'
code "Inpatient": 'IMP' from "ActCode" display '住院'
code "Case_Category_05": '05' from "NHI_CLAIM" display '住院西醫'

code "ESWL_50023A": '50023A' from "NHI_PROCEDURE" display 'ESWL處置50023A'
code "ESWL_50024A": '50024A' from "NHI_PROCEDURE" display 'ESWL處置50024A'
code "ESWL_50025A": '50025A' from "NHI_PROCEDURE" display 'ESWL處置50025A'
code "ESWL_50026A": '50026A' from "NHI_PROCEDURE" display 'ESWL處置50026A'

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

define function HasESWLProcedure(encounter Encounter):
  exists (
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and PE.value as CodeableConcept ~ "ESWL_50023A"
                or PE.value as CodeableConcept ~ "ESWL_50024A"
                or PE.value as CodeableConcept ~ "ESWL_50025A"
                or PE.value as CodeableConcept ~ "ESWL_50026A"
        )
  )

define function CountESWLProcedures(encounter Encounter):
  Count(
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and (PE.value as CodeableConcept ~ "ESWL_50023A"
                or PE.value as CodeableConcept ~ "ESWL_50024A"
                or PE.value as CodeableConcept ~ "ESWL_50025A"
                or PE.value as CodeableConcept ~ "ESWL_50026A")
        )
  )

define "All Inpatient Discharges":
  [Encounter: type in "Inpatient Encounters"] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and GetDischargeDate(E) during "Measurement Period"
      and GetCaseCategory(E) = '05'

define "ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)

define "ESWL Patient IDs":
  distinct (
    "ESWL Cases" E
      return Last(Split(E.subject.reference, '/'))
  )

define "Total ESWL Procedures":
  Sum(
    "ESWL Cases" E
      return CountESWLProcedures(E)
  )

define "Total ESWL Patients":
  Count("ESWL Patient IDs")

define "Average ESWL Per Patient":
  if "Total ESWL Patients" > 0
  then "Total ESWL Procedures" / "Total ESWL Patients"
  else null

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

define "2024Q1 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"]

define "2024Q1 ESWL Procedures":
  Sum("2024Q1 ESWL Cases" E return CountESWLProcedures(E))

define "2024Q1 ESWL Patients":
  Count(distinct ("2024Q1 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2024Q1 Average":
  if "2024Q1 ESWL Patients" > 0
  then "2024Q1 ESWL Procedures" / "2024Q1 ESWL Patients"
  else null

define "2024Q2 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"]

define "2024Q2 ESWL Procedures":
  Sum("2024Q2 ESWL Cases" E return CountESWLProcedures(E))

define "2024Q2 ESWL Patients":
  Count(distinct ("2024Q2 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2024Q2 Average":
  if "2024Q2 ESWL Patients" > 0
  then "2024Q2 ESWL Procedures" / "2024Q2 ESWL Patients"
  else null

define "2024Q3 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"]

define "2024Q3 ESWL Procedures":
  Sum("2024Q3 ESWL Cases" E return CountESWLProcedures(E))

define "2024Q3 ESWL Patients":
  Count(distinct ("2024Q3 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2024Q3 Average":
  if "2024Q3 ESWL Patients" > 0
  then "2024Q3 ESWL Procedures" / "2024Q3 ESWL Patients"
  else null

define "2024Q4 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"]

define "2024Q4 ESWL Procedures":
  Sum("2024Q4 ESWL Cases" E return CountESWLProcedures(E))

define "2024Q4 ESWL Patients":
  Count(distinct ("2024Q4 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2024Q4 Average":
  if "2024Q4 ESWL Patients" > 0
  then "2024Q4 ESWL Procedures" / "2024Q4 ESWL Patients"
  else null

define "2025Q1 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"]

define "2025Q1 ESWL Procedures":
  Sum("2025Q1 ESWL Cases" E return CountESWLProcedures(E))

define "2025Q1 ESWL Patients":
  Count(distinct ("2025Q1 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2025Q1 Average":
  if "2025Q1 ESWL Patients" > 0
  then "2025Q1 ESWL Procedures" / "2025Q1 ESWL Patients"
  else null

define "2025Q2 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"]

define "2025Q2 ESWL Procedures":
  Sum("2025Q2 ESWL Cases" E return CountESWLProcedures(E))

define "2025Q2 ESWL Patients":
  Count(distinct ("2025Q2 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2025Q2 Average":
  if "2025Q2 ESWL Patients" > 0
  then "2025Q2 ESWL Procedures" / "2025Q2 ESWL Patients"
  else null

define "2025Q3 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"]

define "2025Q3 ESWL Procedures":
  Sum("2025Q3 ESWL Cases" E return CountESWLProcedures(E))

define "2025Q3 ESWL Patients":
  Count(distinct ("2025Q3 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2025Q3 Average":
  if "2025Q3 ESWL Patients" > 0
  then "2025Q3 ESWL Procedures" / "2025Q3 ESWL Patients"
  else null

define "2025Q4 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"]

define "2025Q4 ESWL Procedures":
  Sum("2025Q4 ESWL Cases" E return CountESWLProcedures(E))

define "2025Q4 ESWL Patients":
  Count(distinct ("2025Q4 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2025Q4 Average":
  if "2025Q4 ESWL Patients" > 0
  then "2025Q4 ESWL Procedures" / "2025Q4 ESWL Patients"
  else null

define "2026Q1 ESWL Cases":
  "All Inpatient Discharges" E
    where HasESWLProcedure(E)
      and GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"]

define "2026Q1 ESWL Procedures":
  Sum("2026Q1 ESWL Cases" E return CountESWLProcedures(E))

define "2026Q1 ESWL Patients":
  Count(distinct ("2026Q1 ESWL Cases" E return Last(Split(E.subject.reference, '/'))))

define "2026Q1 Average":
  if "2026Q1 ESWL Patients" > 0
  then "2026Q1 ESWL Procedures" / "2026Q1 ESWL Patients"
  else null

define "Indicator Result":
  {
    IndicatorCode: '20.01/1804',
    IndicatorName: '接受體外震波碎石術(ESWL)病人平均利用ESWL之次數',
    MeasurementPeriod: "Measurement Period",
    TotalESWLProcedures: "Total ESWL Procedures",
    TotalESWLPatients: "Total ESWL Patients",
    AveragePerPatient: "Average ESWL Per Patient",
    Q2024_1_Procedures: "2024Q1 ESWL Procedures",
    Q2024_1_Patients: "2024Q1 ESWL Patients",
    Q2024_1_Average: "2024Q1 Average",
    Q2024_2_Procedures: "2024Q2 ESWL Procedures",
    Q2024_2_Patients: "2024Q2 ESWL Patients",
    Q2024_2_Average: "2024Q2 Average",
    Q2024_3_Procedures: "2024Q3 ESWL Procedures",
    Q2024_3_Patients: "2024Q3 ESWL Patients",
    Q2024_3_Average: "2024Q3 Average",
    Q2024_4_Procedures: "2024Q4 ESWL Procedures",
    Q2024_4_Patients: "2024Q4 ESWL Patients",
    Q2024_4_Average: "2024Q4 Average",
    Q2025_1_Procedures: "2025Q1 ESWL Procedures",
    Q2025_1_Patients: "2025Q1 ESWL Patients",
    Q2025_1_Average: "2025Q1 Average",
    Q2025_2_Procedures: "2025Q2 ESWL Procedures",
    Q2025_2_Patients: "2025Q2 ESWL Patients",
    Q2025_2_Average: "2025Q2 Average",
    Q2025_3_Procedures: "2025Q3 ESWL Procedures",
    Q2025_3_Patients: "2025Q3 ESWL Patients",
    Q2025_3_Average: "2025Q3 Average",
    Q2025_4_Procedures: "2025Q4 ESWL Procedures",
    Q2025_4_Patients: "2025Q4 ESWL Patients",
    Q2025_4_Average: "2025Q4 Average",
    Q2026_1_Procedures: "2026Q1 ESWL Procedures",
    Q2026_1_Patients: "2026Q1 ESWL Patients",
    Q2026_1_Average: "2026Q1 Average"
  }
