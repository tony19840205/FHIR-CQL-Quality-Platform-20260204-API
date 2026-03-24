library Indicator_15_1_Knee_Arthroplasty_90Day_Deep_Infection_353_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 人工膝關節置換手術後九十日以內置換物深部感染率
// 指標代碼: 353.01
// 資料來源: 醫療給付檔案分析系統，指標代碼：353.01
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

code "Partial_TKA_64169B": '64169B' from "NHI_PROCEDURE" display '半人工膝關節置換術64169B'

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
              and (PE.value as CodeableConcept ~ "Total_TKA_64164B"
                or PE.value as CodeableConcept ~ "Total_TKA_97805K"
                or PE.value as CodeableConcept ~ "Total_TKA_97806A"
                or PE.value as CodeableConcept ~ "Total_TKA_97807B")
        )
  )

define function HasPartialTKAProcedure(encounter Encounter):
  exists (
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and PE.value as CodeableConcept ~ "Partial_TKA_64169B"
        )
  )

define function GetTKAProcedureDate(encounter Encounter):
  First(
    encounter.extension E
      where E.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
        and exists (
          E.extension PE
            where PE.url = 'code'
              and (PE.value as CodeableConcept ~ "Total_TKA_64164B"
                or PE.value as CodeableConcept ~ "Total_TKA_97805K"
                or PE.value as CodeableConcept ~ "Total_TKA_97806A"
                or PE.value as CodeableConcept ~ "Total_TKA_97807B"
                or PE.value as CodeableConcept ~ "Partial_TKA_64169B")
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
              and (PE.value as CodeableConcept ~ "Infection_Surgery_64053B"
                or PE.value as CodeableConcept ~ "Infection_Surgery_64198B")
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
              and (PE1.value as CodeableConcept ~ "Total_TKA_64164B"
                or PE1.value as CodeableConcept ~ "Partial_TKA_64169B")
        )
        and exists (
          encounter.extension E2
            where E2.url = 'http://www.nhi.gov.tw/fhir/StructureDefinition/procedure'
              and exists (
                E2.extension PE2
                  where PE2.url = 'code'
                    and PE2.value as CodeableConcept ~ "Infection_Surgery_64198B"
              )
              and First(E1.extension where url = 'performedDateTime' return (value as dateTime).value)
                = First(E2.extension where url = 'performedDateTime' return (value as dateTime).value)
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
    where HasTotalTKAProcedure(E) or HasPartialTKAProcedure(E)

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
    IndicatorCode: '353.01',
    IndicatorName: '人工膝關節置換手術後九十日以內置換物深部感染率',
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

/*
 * 指標名稱: 15-1. 人工膝關節置換手術後九十日以內置換物深部感染率
 * Indicator: Deep Infection Rate within 90 Days after Total Knee Arthroplasty (TKA)
 * 指標代碼: 353.01
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 資料範圍: 
 *   (1) 每季所有屬醫院總額之住院案件
 *   (2) 排除代辦案件
 * 
 * 公式說明:
 * 分子: 分母案件中，人工膝關節置換執行後90天內發生置換物感染之案件數
 * 分母: 當季內醫院人工膝關節置換執行案件數
 * 
 * 人工膝關節置換執行案件數:
 *   全人工膝關節置換執行案件數: 醫令代碼為64164B且醫令類別為2或醫令代碼為97805K、97806A、97807B之住院案件
 *   半人工膝關節置換執行案件數: 醫令代碼為64169B之住院案件
 * 
 * 置換物感染:
 *   西醫醫院之住診設限案件中，以手術碼專執行起日任後推算90天，有執行64053B、64198B任一醫令之案件，
 *   排除執行人工膝關節置換(64164B)同日申報64198B或半人工膝關節置換(64169B)同日申報64198B。
 * 
 * 製表日期: 114/05/13
 * 製表單位: 衛生福利部 中央健康保險署
 */

-- ==================== Codesystem 定義 ====================

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "LOINC": 'http://loinc.org'
codesystem "TW_DRG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-drg'
codesystem "DRG_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/drg-code'
codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'

-- ==================== Code 定義 ====================

-- 健保處置代碼 - 全人工膝關節置換術
code "NHI_Total_TKA_64164B": '64164B' from "NHI_PROCEDURE" display '全人工膝關節置換術'
code "NHI_Total_TKA_97805K": '97805K' from "NHI_PROCEDURE" display '全人工膝關節置換術'
code "NHI_Total_TKA_97806A": '97806A' from "NHI_PROCEDURE" display '全人工膝關節置換術'
code "NHI_Total_TKA_97807B": '97807B' from "NHI_PROCEDURE" display '全人工膝關節置換術'

-- 健保處置代碼 - 半人工膝關節置換術
code "NHI_Partial_TKA_64169B": '64169B' from "NHI_PROCEDURE" display '半人工膝關節置換術'

-- 健保處置代碼 - 置換物感染相關手術
code "NHI_Infection_Surgery_64053B": '64053B' from "NHI_PROCEDURE" display '人工膝關節感染清創術'
code "NHI_Infection_Surgery_64198B": '64198B' from "NHI_PROCEDURE" display '人工膝關節置換物移除術'

-- SNOMED CT - 全人工膝關節置換術
code "SNOMED_Total_Knee_Replacement": '609588000' from "SNOMEDCT" display 'Total knee replacement'
code "SNOMED_TKA": '179344006' from "SNOMEDCT" display 'Total arthroplasty of knee'
code "SNOMED_Primary_TKA": '265157000' from "SNOMEDCT" display 'Primary total knee replacement'
code "SNOMED_Bilateral_TKA": '446634006' from "SNOMEDCT" display 'Bilateral total knee replacement'
code "SNOMED_Unilateral_TKA": '446633000' from "SNOMEDCT" display 'Unilateral total knee replacement'

-- SNOMED CT - 半人工膝關節置換術
code "SNOMED_Partial_Knee_Replacement": '314489006' from "SNOMEDCT" display 'Partial knee replacement'
code "SNOMED_Unicompartmental_TKA": '179345007' from "SNOMEDCT" display 'Unicompartmental knee replacement'
code "SNOMED_Unicondylar_TKA": '62402000' from "SNOMEDCT" display 'Unicondylar knee arthroplasty'

-- SNOMED CT - 人工膝關節感染
code "SNOMED_Prosthetic_Joint_Infection": '737147000' from "SNOMEDCT" display 'Infection of joint prosthesis'
code "SNOMED_Knee_Prosthesis_Infection": '429280009' from "SNOMEDCT" display 'Infection of knee joint prosthesis'
code "SNOMED_Deep_Joint_Infection": '449103002' from "SNOMEDCT" display 'Deep infection of joint'

-- SNOMED CT - 感染相關手術
code "SNOMED_Removal_Knee_Prosthesis": '397956004' from "SNOMEDCT" display 'Removal of knee prosthesis'
code "SNOMED_Revision_TKA": '609589008' from "SNOMEDCT" display 'Revision of total knee replacement'
code "SNOMED_Debridement_Knee": '77849006' from "SNOMEDCT" display 'Debridement of knee'
code "SNOMED_Irrigation_Knee": '225367005' from "SNOMEDCT" display 'Irrigation of knee joint'

-- ICD-10-CM - 人工膝關節感染診斷
code "ICD10CM_Prosthetic_Joint_Infection_T8484": 'T84.84' from "ICD10CM" display '感染及炎症反應，由內部骨科義肢裝置、植入物及移植物引起，髖關節及膝關節'
code "ICD10CM_Prosthetic_Joint_Infection_T8450": 'T84.50' from "ICD10CM" display '內部關節義肢之感染及炎症反應，未明示部位'
code "ICD10CM_Prosthetic_Joint_Infection_T8454": 'T84.54' from "ICD10CM" display '內部膝關節義肢之感染及炎症反應'
code "ICD10CM_Knee_Joint_Infection_M0066": 'M00.66' from "ICD10CM" display '其他細菌所致葡萄球菌性關節炎，膝'
code "ICD10CM_Knee_Joint_Infection_M0086": 'M00.86' from "ICD10CM" display '其他細菌所致關節炎，膝'

-- ICD-10-PCS - 全人工膝關節置換術
code "ICD10PCS_TKA_0SRC": '0SRC0JZ' from "ICD10PCS" display 'Replacement of Right Knee Joint with Synthetic Substitute, Open Approach'
code "ICD10PCS_TKA_0SRD": '0SRD0JZ' from "ICD10PCS" display 'Replacement of Left Knee Joint with Synthetic Substitute, Open Approach'
code "ICD10PCS_TKA_Cemented_0SRC0JA": '0SRC0JA' from "ICD10PCS" display 'Replacement of Right Knee Joint with Synthetic Substitute, Cemented, Open Approach'
code "ICD10PCS_TKA_Cemented_0SRD0JA": '0SRD0JA' from "ICD10PCS" display 'Replacement of Left Knee Joint with Synthetic Substitute, Cemented, Open Approach'

-- ICD-10-PCS - 人工膝關節移除/感染處理
code "ICD10PCS_Remove_Knee_0SPC": '0SPC0JZ' from "ICD10PCS" display 'Removal of Synthetic Substitute from Right Knee Joint, Open Approach'
code "ICD10PCS_Remove_Knee_0SPD": '0SPD0JZ' from "ICD10PCS" display 'Removal of Synthetic Substitute from Left Knee Joint, Open Approach'
code "ICD10PCS_Revision_Knee_0SWC": '0SWC0JZ' from "ICD10PCS" display 'Revision of Synthetic Substitute in Right Knee Joint, Open Approach'
code "ICD10PCS_Revision_Knee_0SWD": '0SWD0JZ' from "ICD10PCS" display 'Revision of Synthetic Substitute in Left Knee Joint, Open Approach'

-- CPT - 全人工膝關節置換術
code "CPT_TKA_27447": '27447' from "CPT" display 'Total knee arthroplasty'
code "CPT_TKA_Primary_27445": '27445' from "CPT" display 'Arthroplasty, knee, hinge prosthesis'

-- CPT - 半人工膝關節置換術
code "CPT_Partial_TKA_27446": '27446' from "CPT" display 'Arthroplasty, knee, condyle and plateau; medial OR lateral compartment'

-- CPT - 人工膝關節移除/感染處理
code "CPT_Remove_TKA_27486": '27486' from "CPT" display 'Revision of total knee arthroplasty, with or without allograft; one component'
code "CPT_Debridement_Knee_27301": '27301' from "CPT" display 'Incision and drainage, deep abscess, bursa, or hematoma, thigh or knee region'
code "CPT_Irrigation_Knee_29871": '29871' from "CPT" display 'Arthroscopy, knee, surgical; for infection, lavage and drainage'

-- ActCode
code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'

-- ==================== ValueSet 定義 ====================

valueset "Total_Knee_Arthroplasty_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/total-knee-arthroplasty'
valueset "Partial_Knee_Arthroplasty_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/partial-knee-arthroplasty'
valueset "Prosthetic_Joint_Infection_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/prosthetic-joint-infection'
valueset "Infection_Surgery_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/knee-prosthesis-infection-surgery'

-- ==================== 參數 ====================

parameter "Measurement_Period" Interval<DateTime>
    default Interval[@2024-01-01T00:00:00.0, @2024-12-31T23:59:59.999]

-- ==================== Context 定義 ====================

context Patient

-- ==================== 主要定義 ====================

/*
 * 定義1: 住院案件（排除代辦案件）
 */
define "Inpatient_Encounters":
    [Encounter: type in "ActCode_Inpatient"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Inpatient"
            and E.period ends during "Measurement_Period"
            and not exists (
                E.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/proxy-case'
                        and Ex.valueBoolean = true
            )

/*
 * 定義2: 全人工膝關節置換術（TKA）
 * 醫令代碼: 64164B（醫令類別2）或 97805K、97806A、97807B
 */
define "Has_Total_Knee_Arthroplasty":
    exists (
        [Procedure] P
            where P.status = 'completed'
                and exists (
                    P.code.coding Cod
                        where (
                            // 健保代碼
                            Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                            and Cod.code in {
                                '64164B',  // 全人工膝關節置換術（醫令類別2）
                                '97805K',  // 全人工膝關節置換術
                                '97806A',  // 全人工膝關節置換術
                                '97807B'   // 全人工膝關節置換術
                            }
                        )
                        or (
                            // SNOMED CT代碼
                            Cod.system = 'http://snomed.info/sct'
                            and Cod.code in {
                                '609588000',  // Total knee replacement
                                '179344006',  // Total arthroplasty of knee
                                '265157000',  // Primary total knee replacement
                                '446634006',  // Bilateral total knee replacement
                                '446633000'   // Unilateral total knee replacement
                            }
                        )
                        or (
                            // CPT代碼
                            Cod.system = 'http://www.ama-assn.org/go/cpt'
                            and Cod.code in {
                                '27447',  // Total knee arthroplasty
                                '27445'   // Arthroplasty, knee, hinge prosthesis
                            }
                        )
                        or (
                            // ICD-10-PCS代碼
                            Cod.system = 'http://www.cms.gov/Medicare/Coding/ICD10'
                            and (
                                Cod.code in {
                                    '0SRC0JZ',  // Right knee
                                    '0SRD0JZ',  // Left knee
                                    '0SRC0JA',  // Right knee cemented
                                    '0SRD0JA'   // Left knee cemented
                                }
                                or Cod.code starts with '0SRC'  // Right knee replacement variations
                                or Cod.code starts with '0SRD'  // Left knee replacement variations
                            )
                        )
                )
    )

/*
 * 定義3: 半人工膝關節置換術
 * 醫令代碼: 64169B
 */
define "Has_Partial_Knee_Arthroplasty":
    exists (
        [Procedure] P
            where P.status = 'completed'
                and exists (
                    P.code.coding Cod
                        where (
                            // 健保代碼
                            Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                            and Cod.code = '64169B'
                        )
                        or (
                            // SNOMED CT代碼
                            Cod.system = 'http://snomed.info/sct'
                            and Cod.code in {
                                '314489006',  // Partial knee replacement
                                '179345007',  // Unicompartmental knee replacement
                                '62402000'    // Unicondylar knee arthroplasty
                            }
                        )
                        or (
                            // CPT代碼
                            Cod.system = 'http://www.ama-assn.org/go/cpt'
                            and Cod.code = '27446'  // Partial knee arthroplasty
                        )
                )
    )

/*
 * 定義4: 分母案件 - 人工膝關節置換執行案件
 * 包含: 全人工膝關節置換術 或 半人工膝關節置換術
 */
define "Denominator_Cases":
    "Inpatient_Encounters" E
        where exists (
            [Procedure] P
                where P.encounter.reference = 'Encounter/' + E.id
                    and P.status = 'completed'
                    and exists (
                        P.code.coding Cod
                            where (
                                // 全人工膝關節置換術
                                (
                                    Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                                    and Cod.code in {'64164B', '97805K', '97806A', '97807B'}
                                )
                                or (
                                    Cod.system = 'http://snomed.info/sct'
                                    and Cod.code in {'609588000', '179344006', '265157000', '446634006', '446633000'}
                                )
                                or (
                                    Cod.system = 'http://www.ama-assn.org/go/cpt'
                                    and Cod.code in {'27447', '27445'}
                                )
                                // 半人工膝關節置換術
                                or (
                                    Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                                    and Cod.code = '64169B'
                                )
                                or (
                                    Cod.system = 'http://snomed.info/sct'
                                    and Cod.code in {'314489006', '179345007', '62402000'}
                                )
                                or (
                                    Cod.system = 'http://www.ama-assn.org/go/cpt'
                                    and Cod.code = '27446'
                                )
                            )
                    )
        )

/*
 * 定義5: 取得人工膝關節置換術的執行日期
 */
define function "Get_TKA_Procedure_Date"(Encounter "Encounter"):
    singleton from (
        [Procedure] P
            where P.encounter.reference = 'Encounter/' + Encounter.id
                and P.status = 'completed'
                and exists (
                    P.code.coding Cod
                        where (
                            Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                            and Cod.code in {'64164B', '97805K', '97806A', '97807B', '64169B'}
                        )
                        or (
                            Cod.system = 'http://snomed.info/sct'
                            and Cod.code in {'609588000', '179344006', '265157000', '446634006', '446633000', 
                                           '314489006', '179345007', '62402000'}
                        )
                )
            return P.performedDateTime
    )

/*
 * 定義6: 檢查是否為同日申報排除情況
 * 排除: 64164B同日申報64198B 或 64169B同日申報64198B
 */
define function "Is_Same_Day_Exclusion"(IndexEncounter "Encounter", InfectionProcedure "Procedure"):
    exists (
        [Procedure] TKA_Proc
            where TKA_Proc.encounter.reference = 'Encounter/' + IndexEncounter.id
                and TKA_Proc.status = 'completed'
                and exists (
                    TKA_Proc.code.coding TKA_Code
                        where TKA_Code.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                            and TKA_Code.code in {'64164B', '64169B'}
                )
                and exists (
                    InfectionProcedure.code.coding Inf_Code
                        where Inf_Code.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                            and Inf_Code.code = '64198B'
                )
                // 檢查是否同日
                and date from TKA_Proc.performedDateTime = date from InfectionProcedure.performedDateTime
    )

/*
 * 定義7: 90日內發生置換物深部感染
 * 檢查是否執行 64053B 或 64198B（排除同日申報情況）
 */
define "Deep_Infection_Within_90_Days":
    "Denominator_Cases" IndexEncounter
        let TKA_Date: "Get_TKA_Procedure_Date"(IndexEncounter)
        where TKA_Date is not null
            and exists (
                [Procedure] InfectionProc
                    where InfectionProc.status = 'completed'
                        // 90日內執行
                        and InfectionProc.performedDateTime in Interval[
                            TKA_Date,
                            TKA_Date + 90 days
                        ]
                        // 檢查是否為感染相關手術代碼
                        and exists (
                            InfectionProc.code.coding Cod
                                where (
                                    Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                                    and Cod.code in {'64053B', '64198B'}
                                )
                                or (
                                    Cod.system = 'http://snomed.info/sct'
                                    and Cod.code in {
                                        '397956004',  // Removal of knee prosthesis
                                        '609589008',  // Revision of TKA
                                        '77849006',   // Debridement of knee
                                        '225367005'   // Irrigation of knee joint
                                    }
                                )
                                or (
                                    Cod.system = 'http://www.ama-assn.org/go/cpt'
                                    and Cod.code in {
                                        '27486',  // Revision of TKA
                                        '27301',  // Incision and drainage
                                        '29871'   // Arthroscopy for infection
                                    }
                                )
                        )
                        // 排除同日申報64198B的情況
                        and not "Is_Same_Day_Exclusion"(IndexEncounter, InfectionProc)
            )

/*
 * 定義8: 分子（90日內深部感染案件數）
 */
define "Numerator":
    Count("Deep_Infection_Within_90_Days")

/*
 * 定義9: 分母（人工膝關節置換執行案件數）
 */
define "Denominator":
    Count("Denominator_Cases")

/*
 * 定義10: 深部感染率
 */
define "Deep_Infection_Rate":
    if "Denominator" > 0
    then ("Numerator" / "Denominator") * 100
    else null

/*
 * 定義11: 指標結果
 */
define "Indicator_15_1_Result":
    {
        IndicatorCode: '353.01',
        IndicatorName: '人工膝關節置換手術後九十日以內置換物深部感染率',
        Numerator: "Numerator",
        Denominator: "Denominator",
        Rate: "Deep_Infection_Rate",
        Unit: '%',
        MeasurementPeriod: "Measurement_Period",
        CalculationDate: Now()
    }

-- End of file
