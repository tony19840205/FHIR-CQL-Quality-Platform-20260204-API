library Indicator_14_Uterine_Fibroid_Surgery_14Day_Readmission_473_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率
// 指標代碼: 473.01
// 資料來源: 醫療給付檔案分析系統，指標代碼：473.01
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署

codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'

code "Finished": 'finished' from "EncounterStatus" display '已完成'
code "Inpatient": 'IMP' from "ActCode" display '住院'
code "Case_Category_05": '05' from "NHI_CLAIM" display '住院西醫'

code "Fibroid_D25": 'D25' from "NHI_CLAIM" display '子宮肌瘤'
code "Cancer_C00": 'C00' from "NHI_CLAIM" display '癌症C00'
code "Cancer_C96": 'C96' from "NHI_CLAIM" display '癌症C96'
code "Cancer_C944": 'C94.4' from "NHI_CLAIM" display '排除C944'
code "Cancer_C946": 'C94.6' from "NHI_CLAIM" display '排除C946'
code "Cancer_D37": 'D37' from "NHI_CLAIM" display '癌症D37'
code "Cancer_D48": 'D48' from "NHI_CLAIM" display '癌症D48'
code "Cancer_Z5112": 'Z51.12' from "NHI_CLAIM" display '癌症Z5112'
code "Cancer_J8481": 'J84.81' from "NHI_CLAIM" display '癌症J8481'

code "Related_N70": 'N70' from "NHI_CLAIM" display '相關診斷N70'
code "Related_N71": 'N71' from "NHI_CLAIM" display '相關診斷N71'
code "Related_N72": 'N72' from "NHI_CLAIM" display '相關診斷N72'
code "Related_N73": 'N73' from "NHI_CLAIM" display '相關診斷N73'
code "Related_N74": 'N74' from "NHI_CLAIM" display '相關診斷N74'
code "Related_N75": 'N75' from "NHI_CLAIM" display '相關診斷N75'
code "Related_N76": 'N76' from "NHI_CLAIM" display '相關診斷N76'
code "Related_N77": 'N77' from "NHI_CLAIM" display '相關診斷N77'
code "Related_N80": 'N80' from "NHI_CLAIM" display '相關診斷N80'
code "Related_N81": 'N81' from "NHI_CLAIM" display '相關診斷N81'
code "Related_N82": 'N82' from "NHI_CLAIM" display '相關診斷N82'
code "Related_N83": 'N83' from "NHI_CLAIM" display '相關診斷N83'
code "Related_N84": 'N84' from "NHI_CLAIM" display '相關診斷N84'
code "Related_N85": 'N85' from "NHI_CLAIM" display '相關診斷N85'

code "Myomectomy_97010K": '97010K' from "NHI_PROCEDURE" display '子宮肌瘤摘除術97010K'
code "Myomectomy_97011A": '97011A' from "NHI_PROCEDURE" display '子宮肌瘤摘除術97011A'
code "Myomectomy_97012B": '97012B' from "NHI_PROCEDURE" display '子宮肌瘤摘除術97012B'
code "Myomectomy_97013B": '97013B' from "NHI_PROCEDURE" display '子宮肌瘤摘除術97013B'
code "Myomectomy_80402C": '80402C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術80402C'
code "Myomectomy_80420C": '80420C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術80420C'
code "Myomectomy_80415B": '80415B' from "NHI_PROCEDURE" display '子宮肌瘤摘除術80415B'
code "Myomectomy_97013C": '97013C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術97013C'
code "Myomectomy_80415C": '80415C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術80415C'
code "Myomectomy_80425C": '80425C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術80425C'

code "Hysterectomy_97025K": '97025K' from "NHI_PROCEDURE" display '子宮切除術97025K'
code "Hysterectomy_97026A": '97026A' from "NHI_PROCEDURE" display '子宮切除術97026A'
code "Hysterectomy_97027B": '97027B' from "NHI_PROCEDURE" display '子宮切除術97027B'
code "Hysterectomy_97020K": '97020K' from "NHI_PROCEDURE" display '子宮切除術97020K'
code "Hysterectomy_97021A": '97021A' from "NHI_PROCEDURE" display '子宮切除術97021A'
code "Hysterectomy_97022B": '97022B' from "NHI_PROCEDURE" display '子宮切除術97022B'
code "Hysterectomy_97035K": '97035K' from "NHI_PROCEDURE" display '子宮切除術97035K'
code "Hysterectomy_97036A": '97036A' from "NHI_PROCEDURE" display '子宮切除術97036A'
code "Hysterectomy_97037B": '97037B' from "NHI_PROCEDURE" display '子宮切除術97037B'
code "Hysterectomy_80403B": '80403B' from "NHI_PROCEDURE" display '子宮切除術80403B'
code "Hysterectomy_80404B": '80404B' from "NHI_PROCEDURE" display '子宮切除術80404B'
code "Hysterectomy_80421B": '80421B' from "NHI_PROCEDURE" display '子宮切除術80421B'
code "Hysterectomy_80416B": '80416B' from "NHI_PROCEDURE" display '子宮切除術80416B'
code "Hysterectomy_80412B": '80412B' from "NHI_PROCEDURE" display '子宮切除術80412B'
code "Hysterectomy_97027C": '97027C' from "NHI_PROCEDURE" display '子宮切除術97027C'
code "Hysterectomy_80404C": '80404C' from "NHI_PROCEDURE" display '子宮切除術80404C'

-- ==================== Code 定義 ====================


valueset "Inpatient Encounters": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

define function GetId(encounter Encounter):
  Last(Split(encounter.id, '/'))

define function GetDischargeDate(encounter Encounter):
  end of FHIRHelpers.ToInterval(encounter.period)

define function GetAdmissionDate(encounter Encounter):
  start of FHIRHelpers.ToInterval(encounter.period)

define function GetCaseCategory(encounter Encounter):
  First(
    encounter.type T
      where exists (T.coding C where C.system = 'http://www.nhi.gov.tw/codes/claim')
      return First(T.coding).code.value
  )

define function GetMainDiagnosisPrefix3(encounter Encounter):
  First(
    encounter.diagnosis D
      where D.use.coding.exists(c: c.code = 'principal')
      return First(
        D.condition.extension E
          where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/diagnosis-code'
          return Substring((E.value as CodeableConcept).coding[0].code.value, 0, 3)
      )
  )

define function GetMainDiagnosisFull(encounter Encounter):
  First(
    encounter.diagnosis D
      where D.use.coding.exists(c: c.code = 'principal')
      return First(
        D.condition.extension E
          where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/diagnosis-code'
          return (E.value as CodeableConcept).coding[0].code.value
      )
  )

define function GetSecondaryDiagnosisPrefix3List(encounter Encounter):
  encounter.diagnosis D
    where D.use.coding.exists(c: c.code = 'secondary')
    return First(
      D.condition.extension E
        where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/diagnosis-code'
        return Substring((E.value as CodeableConcept).coding[0].code.value, 0, 3)
    )

define function GetSecondaryDiagnosisFullList(encounter Encounter):
  encounter.diagnosis D
    where D.use.coding.exists(c: c.code = 'secondary')
    return First(
      D.condition.extension E
        where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/diagnosis-code'
        return (E.value as CodeableConcept).coding[0].code.value
    )

define function HasFibroidDiagnosis(encounter Encounter):
  GetMainDiagnosisPrefix3(encounter) = 'D25'
    or exists (GetSecondaryDiagnosisPrefix3List(encounter) D where D = 'D25')

define function HasCancerDiagnosis(encounter Encounter):
  (GetMainDiagnosisPrefix3(encounter) >= 'C00' and GetMainDiagnosisPrefix3(encounter) <= 'C96'
    and GetMainDiagnosisFull(encounter) != 'C94.4'
    and GetMainDiagnosisFull(encounter) != 'C94.6')
  or (GetMainDiagnosisPrefix3(encounter) >= 'D37' and GetMainDiagnosisPrefix3(encounter) <= 'D48')
  or GetMainDiagnosisFull(encounter) = 'Z51.12'
  or GetMainDiagnosisFull(encounter) = 'J84.81'
  or exists (
    GetSecondaryDiagnosisPrefix3List(encounter) D
      where (D >= 'C00' and D <= 'C96')
        or (D >= 'D37' and D <= 'D48')
  )
  or exists (
    GetSecondaryDiagnosisFullList(encounter) D
      where D = 'Z51.12' or D = 'J84.81'
        and D != 'C94.4' and D != 'C94.6'
  )

define function HasRelatedDiagnosis(encounter Encounter):
  (GetMainDiagnosisPrefix3(encounter) >= 'N70' and GetMainDiagnosisPrefix3(encounter) <= 'N85')
    or exists (
      GetSecondaryDiagnosisPrefix3List(encounter) D
        where D >= 'N70' and D <= 'N85'
    )

define function HasMyomectomyProcedure(encounter Encounter):
  exists (
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and (PE.value as CodeableConcept ~ "Myomectomy_97010K"
                or PE.value as CodeableConcept ~ "Myomectomy_97011A"
                or PE.value as CodeableConcept ~ "Myomectomy_97012B"
                or PE.value as CodeableConcept ~ "Myomectomy_97013B"
                or PE.value as CodeableConcept ~ "Myomectomy_80402C"
                or PE.value as CodeableConcept ~ "Myomectomy_80420C"
                or PE.value as CodeableConcept ~ "Myomectomy_80415B"
                or PE.value as CodeableConcept ~ "Myomectomy_97013C"
                or PE.value as CodeableConcept ~ "Myomectomy_80415C"
                or PE.value as CodeableConcept ~ "Myomectomy_80425C")
        )
  )

define function HasHysterectomyProcedure(encounter Encounter):
  exists (
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and (PE.value as CodeableConcept ~ "Hysterectomy_97025K"
                or PE.value as CodeableConcept ~ "Hysterectomy_97026A"
                or PE.value as CodeableConcept ~ "Hysterectomy_97027B"
                or PE.value as CodeableConcept ~ "Hysterectomy_97020K"
                or PE.value as CodeableConcept ~ "Hysterectomy_97021A"
                or PE.value as CodeableConcept ~ "Hysterectomy_97022B"
                or PE.value as CodeableConcept ~ "Hysterectomy_97035K"
                or PE.value as CodeableConcept ~ "Hysterectomy_97036A"
                or PE.value as CodeableConcept ~ "Hysterectomy_97037B"
                or PE.value as CodeableConcept ~ "Hysterectomy_80403B"
                or PE.value as CodeableConcept ~ "Hysterectomy_80404B"
                or PE.value as CodeableConcept ~ "Hysterectomy_80421B"
                or PE.value as CodeableConcept ~ "Hysterectomy_80416B"
                or PE.value as CodeableConcept ~ "Hysterectomy_80412B"
                or PE.value as CodeableConcept ~ "Hysterectomy_97027C"
                or PE.value as CodeableConcept ~ "Hysterectomy_80404C")
        )
  )

define "All Inpatient Discharges":
  [Encounter: type in "Inpatient Encounters"] E
    where E.status ~ "Finished"
      and E.class ~ "Inpatient"
      and GetDischargeDate(E) during "Measurement Period"
      and GetCaseCategory(E) = '05'

define "Denominator Cases":
  "All Inpatient Discharges" E
    where HasFibroidDiagnosis(E)
      and not HasCancerDiagnosis(E)
      and (HasMyomectomyProcedure(E) or HasHysterectomyProcedure(E))

define "Readmission Within 14 Days":
  "Denominator Cases" IndexEncounter
    where exists (
      "All Inpatient Discharges" ReadmitEncounter
        where ReadmitEncounter.subject.reference = IndexEncounter.subject.reference
          and GetAdmissionDate(ReadmitEncounter) in Interval[
            GetDischargeDate(IndexEncounter) + 1 day,
            GetDischargeDate(IndexEncounter) + 14 days
          ]
          and HasRelatedDiagnosis(ReadmitEncounter)
    )

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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
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
    "Readmission Within 14 Days" E
      where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"]
  )

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0
  then ("2026Q1 Numerator" / "2026Q1 Denominator") * 100
  else null

define "Total Denominator":
  Count("Denominator Cases")

define "Total Numerator":
  Count("Readmission Within 14 Days")

define "Overall Rate":
  if "Total Denominator" > 0
  then ("Total Numerator" / "Total Denominator") * 100
  else null

define "Indicator Result":
  {
    IndicatorCode: '473.01',
    IndicatorName: '子宮肌瘤手術出院後十四日以內因該手術相關診斷再住院率',
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
