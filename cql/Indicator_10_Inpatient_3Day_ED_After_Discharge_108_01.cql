library Indicator_10_Inpatient_3Day_ED_After_Discharge_108_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

/*
 * 來源：醫療給付檔案分析系統
 * 指標代碼：108.01
 * 指標名稱：住院案件出院後三日以內急診率
 * 製作日期：114/11/06
 * 製作單位：衛生福利部 中央健康保險署
 * 
 * 公式說明:
 * 分子：3日內再急診案件數
 * 分母：出院案件數
 * 
 * 排除條件(10項):
 * (1)腫瘤科個案(就醫科別=13)
 * (2)乳癌試辦案件(案件分類4+疾患來源N或R或C)
 * (3)化學治療及放射線治療、安寧接受抗腫瘤免疫療法(主、次診斷ICD-10-CM Z510、Z5111、Z51.12)
 * (4)早產安胎個案(主診斷ICD-10-CM：前五碼O4291及全碼O4410~O4413、O4690~O4693、O4702~O4703、O6002、O6003)
 * (5)罕見疾病(主診斷E760-E763)點多醣症
 * (6)轉院案件(轉歸代碼5、6或7)
 * (7)新生兒床號(部分負擔計費903)
 * (8)血友病(主診斷D66、D67、D681、D682)
 * (9)器官移植(68035、68037、68047、75020、76020)
 * (10)病患死亡或病危自動出院案件(轉歸代碼4或A)
 */

codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'

valueset "Inpatient Encounters": 'http://nhi.gov.tw/fhir/ValueSet/inpatient-encounters'
valueset "Emergency Encounters": 'http://nhi.gov.tw/fhir/ValueSet/emergency-encounters'

// Encounter Type Codes
code "Inpatient": 'IMP' from "ActCode" display 'Inpatient'
code "Emergency": 'EMER' from "ActCode" display 'Emergency'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// Department Codes
code "Oncology Department": '13' from "NHI_CLAIM" display '腫瘤科'

// Case Type Codes
code "Special Case Type": '4' from "NHI_CLAIM" display '特殊案件分類'

// Disease Source Codes
code "Disease Source N": 'N' from "NHI_CLAIM" display '疾患來源-新生兒'
code "Disease Source R": 'R' from "NHI_CLAIM" display '疾患來源-再住院'
code "Disease Source C": 'C' from "NHI_CLAIM" display '疾患來源-慢性病'

// Discharge Status Codes
code "Transfer Code 5": '5' from "NHI_CLAIM" display '轉院(計畫性)'
code "Transfer Code 6": '6' from "NHI_CLAIM" display '轉院(緊急)'
code "Transfer Code 7": '7' from "NHI_CLAIM" display '轉院(其他)'
code "Death Status": '4' from "NHI_CLAIM" display '死亡'
code "Critical Discharge": 'A' from "NHI_CLAIM" display '病危自動出院'

// Copayment Codes
code "Newborn Bed": '903' from "NHI_CLAIM" display '新生兒床號'

// Cancer Treatment Codes (ICD-10-CM)
code "Radiotherapy Z510": 'Z510' from "ICD10CM" display 'Encounter for antineoplastic radiation therapy'
code "Chemotherapy Z5111": 'Z5111' from "ICD10CM" display 'Encounter for antineoplastic chemotherapy'
code "Immunotherapy Z5112": 'Z51.12' from "ICD10CM" display 'Encounter for antineoplastic immunotherapy'

// Preterm Labor Codes (ICD-10-CM)
code "Preterm O4291": 'O4291' from "ICD10CM" display '早產安胎(前五碼)'
code "Preterm O4410": 'O4410' from "ICD10CM" display 'Placenta previa without hemorrhage, unspecified trimester'
code "Preterm O4411": 'O4411' from "ICD10CM" display 'Placenta previa without hemorrhage, first trimester'
code "Preterm O4412": 'O4412' from "ICD10CM" display 'Placenta previa without hemorrhage, second trimester'
code "Preterm O4413": 'O4413' from "ICD10CM" display 'Placenta previa without hemorrhage, third trimester'
code "Preterm O4690": 'O4690' from "ICD10CM" display 'Unspecified antepartum hemorrhage, unspecified trimester'
code "Preterm O4691": 'O4691' from "ICD10CM" display 'Unspecified antepartum hemorrhage, first trimester'
code "Preterm O4692": 'O4692' from "ICD10CM" display 'Unspecified antepartum hemorrhage, second trimester'
code "Preterm O4693": 'O4693' from "ICD10CM" display 'Unspecified antepartum hemorrhage, third trimester'
code "Preterm O4702": 'O4702' from "ICD10CM" display 'False labor before 37 weeks, second trimester'
code "Preterm O4703": 'O4703' from "ICD10CM" display 'False labor before 37 weeks, third trimester'
code "Preterm O6002": 'O6002' from "ICD10CM" display 'Preterm labor without delivery, second trimester'
code "Preterm O6003": 'O6003' from "ICD10CM" display 'Preterm labor without delivery, third trimester'

// Rare Disease Codes (ICD-10-CM)
code "Rare E760": 'E760' from "ICD10CM" display 'Mucopolysaccharidosis, type I'
code "Rare E761": 'E761' from "ICD10CM" display 'Mucopolysaccharidosis, type II'
code "Rare E762": 'E762' from "ICD10CM" display 'Other mucopolysaccharidoses'
code "Rare E763": 'E763' from "ICD10CM" display 'Mucopolysaccharidosis, unspecified'

// Hemophilia Codes (ICD-10-CM)
code "Hemophilia D66": 'D66' from "ICD10CM" display 'Hereditary factor VIII deficiency'
code "Hemophilia D67": 'D67' from "ICD10CM" display 'Hereditary factor IX deficiency'
code "Hemophilia D681": 'D681' from "ICD10CM" display "Von Willebrand's disease"
code "Hemophilia D682": 'D682' from "ICD10CM" display 'Hereditary deficiency of other clotting factors'

// Organ Transplant Procedure Codes
code "Transplant 68035": '68035' from "NHI_PROCEDURE" display '肺臟移植'
code "Transplant 68037": '68037' from "NHI_PROCEDURE" display '雙肺移植'
code "Transplant 68047": '68047' from "NHI_PROCEDURE" display '雙肺移植'
code "Transplant 75020": '75020' from "NHI_PROCEDURE" display '肝臟移植'
code "Transplant 76020": '76020' from "NHI_PROCEDURE" display '腎臟移植'

// Helper Functions
define function GetId(encounter Encounter):
  encounter.id.value

define function GetDischargeDate(encounter Encounter):
  encounter.period.end.value

define function GetAdmissionDate(encounter Encounter):
  encounter.period.start.value

define function GetPrimaryDiagnosis(encounter Encounter):
  First(
    encounter.diagnosis D
      where exists(D.use.coding C where C.code.value = 'AD')
      return D.condition.reference.value
  )

define function GetDiagnosisPrefix5(diagnosisCode String):
  if Length(diagnosisCode) >= 5 then Substring(diagnosisCode, 0, 5)
  else diagnosisCode

define function GetDepartment(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/department'
      return E.value as String
  )

define function GetCaseType(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/case-type'
      return E.value as String
  )

define function GetDiseaseSource(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/disease-source'
      return E.value as String
  )

define function GetDischargeStatus(encounter Encounter):
  First(
    encounter.hospitalization.dischargeDisposition.coding C
      return C.code.value
  )

define function GetCopayment(encounter Encounter):
  First(
    encounter.extension E
      where E.url.value = 'http://www.nhi.gov.tw/extensions/copayment'
      return E.value as String
  )

define function DaysBetween(date1 DateTime, date2 DateTime):
  days between date1 and date2

// Exclusion Criteria Functions
define function IsOncologyCase(encounter Encounter):
  GetDepartment(encounter) = '13'

define function IsBreastCancerPilot(encounter Encounter):
  GetCaseType(encounter) = '4'
    and GetDiseaseSource(encounter) in {'N', 'R', 'C'}

define function IsCancerTreatment(encounter Encounter):
  exists(
    encounter.diagnosis D
      let condition: D.condition.reference.value,
          conditionCode: Last(Split(condition, '/'))
      where conditionCode in {'Z510', 'Z5111', 'Z51.12'}
  )

define function IsPretermLabor(encounter Encounter):
  exists(
    encounter.diagnosis D
      let condition: D.condition.reference.value,
          conditionCode: Last(Split(condition, '/')),
          prefix5: GetDiagnosisPrefix5(conditionCode)
      where prefix5 = 'O4291'
        or conditionCode in {
          'O4410', 'O4411', 'O4412', 'O4413',
          'O4690', 'O4691', 'O4692', 'O4693',
          'O4702', 'O4703', 'O6002', 'O6003'
        }
  )

define function IsRareDisease(encounter Encounter):
  exists(
    encounter.diagnosis D
      let condition: D.condition.reference.value,
          conditionCode: Last(Split(condition, '/'))
      where conditionCode in {'E760', 'E761', 'E762', 'E763'}
  )

define function IsTransferCase(encounter Encounter):
  GetDischargeStatus(encounter) in {'5', '6', '7'}

define function IsNewbornBed(encounter Encounter):
  GetCopayment(encounter) = '903'

define function IsHemophilia(encounter Encounter):
  exists(
    encounter.diagnosis D
      let condition: D.condition.reference.value,
          conditionCode: Last(Split(condition, '/'))
      where conditionCode in {'D66', 'D67', 'D681', 'D682'}
  )

define function HasOrganTransplant(encounter Encounter):
  exists(
    [Procedure] P
      where P.encounter.reference.value = 'Encounter/' + GetId(encounter)
        and exists(
          P.code.coding C
            where C.code.value in {'68035', '68037', '68047', '75020', '76020'}
        )
  )

define function IsDeathOrCriticalDischarge(encounter Encounter):
  GetDischargeStatus(encounter) in {'4', 'A'}

define function IsExcluded(encounter Encounter):
  IsOncologyCase(encounter)
    or IsBreastCancerPilot(encounter)
    or IsCancerTreatment(encounter)
    or IsPretermLabor(encounter)
    or IsRareDisease(encounter)
    or IsTransferCase(encounter)
    or IsNewbornBed(encounter)
    or IsHemophilia(encounter)
    or HasOrganTransplant(encounter)
    or IsDeathOrCriticalDischarge(encounter)

// Data Retrieval
define "All Inpatient Discharges":
  [Encounter] E
    where E.class.code.value = 'IMP'
      and E.status.value = 'finished'
      and E.hospitalization is not null

define "Valid Discharges":
  "All Inpatient Discharges" E
    where not IsExcluded(E)

define function Has3DayEmergency(discharge Encounter):
  exists(
    [Encounter] ER
      where ER.class.code.value = 'EMER'
        and ER.subject.reference.value = discharge.subject.reference.value
        and GetAdmissionDate(ER) > GetDischargeDate(discharge)
        and DaysBetween(GetDischargeDate(discharge), GetAdmissionDate(ER)) <= 3
  )

// Quarter Definitions
define "2024Q1 Start": Date(2024, 1, 1)
define "2024Q1 End": Date(2024, 3, 31)
define "2024Q2 Start": Date(2024, 4, 1)
define "2024Q2 End": Date(2024, 6, 30)
define "2024Q3 Start": Date(2024, 7, 1)
define "2024Q3 End": Date(2024, 9, 30)
define "2024Q4 Start": Date(2024, 10, 1)
define "2024Q4 End": Date(2024, 12, 31)
define "2025Q1 Start": Date(2025, 1, 1)
define "2025Q1 End": Date(2025, 3, 31)
define "2025Q2 Start": Date(2025, 4, 1)
define "2025Q2 End": Date(2025, 6, 30)
define "2025Q3 Start": Date(2025, 7, 1)
define "2025Q3 End": Date(2025, 9, 30)
define "2025Q4 Start": Date(2025, 10, 1)
define "2025Q4 End": Date(2025, 12, 31)
define "2026Q1 Start": Date(2026, 1, 1)
define "2026Q1 End": Date(2026, 3, 31)

define "Measurement Period Start": Date(2024, 1, 1)
define "Measurement Period End": Date(2099, 12, 31)
define "Measurement Period": 
  Interval["Measurement Period Start", "Measurement Period End"]

// Denominator - Valid Discharges by Quarter
define "2024Q1 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2024Q1 Start", "2024Q1 End"])

define "2024Q2 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2024Q2 Start", "2024Q2 End"])

define "2024Q3 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2024Q3 Start", "2024Q3 End"])

define "2024Q4 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2024Q4 Start", "2024Q4 End"])

define "2025Q1 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2025Q1 Start", "2025Q1 End"])

define "2025Q2 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2025Q2 Start", "2025Q2 End"])

define "2025Q3 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2025Q3 Start", "2025Q3 End"])

define "2025Q4 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2025Q4 Start", "2025Q4 End"])

define "2026Q1 Denominator":
  Count("Valid Discharges" D where GetDischargeDate(D) during Interval["2026Q1 Start", "2026Q1 End"])

// Numerator - 3-Day Emergency by Quarter
define "2024Q1 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2024Q1 Start", "2024Q1 End"]
        and Has3DayEmergency(D)
  )

define "2024Q2 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2024Q2 Start", "2024Q2 End"]
        and Has3DayEmergency(D)
  )

define "2024Q3 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2024Q3 Start", "2024Q3 End"]
        and Has3DayEmergency(D)
  )

define "2024Q4 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2024Q4 Start", "2024Q4 End"]
        and Has3DayEmergency(D)
  )

define "2025Q1 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2025Q1 Start", "2025Q1 End"]
        and Has3DayEmergency(D)
  )

define "2025Q2 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2025Q2 Start", "2025Q2 End"]
        and Has3DayEmergency(D)
  )

define "2025Q3 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2025Q3 Start", "2025Q3 End"]
        and Has3DayEmergency(D)
  )

define "2025Q4 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2025Q4 Start", "2025Q4 End"]
        and Has3DayEmergency(D)
  )

define "2026Q1 Numerator":
  Count(
    "Valid Discharges" D
      where GetDischargeDate(D) during Interval["2026Q1 Start", "2026Q1 End"]
        and Has3DayEmergency(D)
  )

// Indicator Rate by Quarter
define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 
  then "2024Q1 Numerator" / "2024Q1 Denominator" 
  else 0

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 
  then "2024Q2 Numerator" / "2024Q2 Denominator" 
  else 0

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 
  then "2024Q3 Numerator" / "2024Q3 Denominator" 
  else 0

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 
  then "2024Q4 Numerator" / "2024Q4 Denominator" 
  else 0

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 
  then "2025Q1 Numerator" / "2025Q1 Denominator" 
  else 0

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 
  then "2025Q2 Numerator" / "2025Q2 Denominator" 
  else 0

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 
  then "2025Q3 Numerator" / "2025Q3 Denominator" 
  else 0

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 
  then "2025Q4 Numerator" / "2025Q4 Denominator" 
  else 0

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 
  then "2026Q1 Numerator" / "2026Q1 Denominator" 
  else 0

// Indicator Result
define "Indicator Result":
  Tuple {
    indicatorCode: '108.01',
    indicatorName: '住院案件出院後三日以內急診率',
    indicatorNameEn: 'Inpatient 3-Day ED After Discharge Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/11/06',
    version: '1.0.0',
    emergencyDays: 3,
    denominatorCriteria: '出院案件數(排除10項條件)',
    numeratorCriteria: '3日內再急診案件數',
    exclusionCount: 10,
    exclusionCriteria: '腫瘤科、乳癌試辦、癌症治療、早產安胎、罕見疾病、轉院、新生兒床號、血友病、器官移植、死亡或病危出院',
    q2024_1_denominator: "2024Q1 Denominator",
    q2024_1_numerator: "2024Q1 Numerator",
    q2024_1_rate: "2024Q1 Rate",
    q2024_2_denominator: "2024Q2 Denominator",
    q2024_2_numerator: "2024Q2 Numerator",
    q2024_2_rate: "2024Q2 Rate",
    q2024_3_denominator: "2024Q3 Denominator",
    q2024_3_numerator: "2024Q3 Numerator",
    q2024_3_rate: "2024Q3 Rate",
    q2024_4_denominator: "2024Q4 Denominator",
    q2024_4_numerator: "2024Q4 Numerator",
    q2024_4_rate: "2024Q4 Rate",
    q2025_1_denominator: "2025Q1 Denominator",
    q2025_1_numerator: "2025Q1 Numerator",
    q2025_1_rate: "2025Q1 Rate",
    q2025_2_denominator: "2025Q2 Denominator",
    q2025_2_numerator: "2025Q2 Numerator",
    q2025_2_rate: "2025Q2 Rate",
    q2025_3_denominator: "2025Q3 Denominator",
    q2025_3_numerator: "2025Q3 Numerator",
    q2025_3_rate: "2025Q3 Rate",
    q2025_4_denominator: "2025Q4 Denominator",
    q2025_4_numerator: "2025Q4 Numerator",
    q2025_4_rate: "2025Q4 Rate",
    q2026_1_denominator: "2026Q1 Denominator",
    q2026_1_numerator: "2026Q1 Numerator",
    q2026_1_rate: "2026Q1 Rate"
  }
