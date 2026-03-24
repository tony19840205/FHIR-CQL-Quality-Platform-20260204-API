library Indicator_09_Unplanned_14Day_Readmission_Rate_1077_01Q_1809Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 非計畫性住院案件出院後十四日內再住院率
// 指標代碼: 1077.01 (季度), 1809 (年度)
// 製作日期：2026-01-09
// 製表日期: 114/11/06
// 製表單位: 衛生福利部 中央健康保險署
//
// 【資料時間範圍】
// 查詢期間: 2024-01-01 ~ 2099-12-31 (無限制)
// 統計單位: 每季 (2024Q1-Q4, 2025Q1-Q4, 2026Q1)
// ============================================
//
// 【公式說明】
// 分子: 病人14日再住院人數
// 分母: 當季出院人數
//
// 【排除條件】分母分子均排除下列計畫性再住院案件:
// (1)腫瘤科個案(就醫科別=13)
// (2)乳癌試辦案件(案件分類4+疾患來源N或R或C)
// (3)癌症、性態未明腫瘤治療(主次診斷ICD-10-CM前3碼為C00-C96(排除C94.4、C94.6)、D37-D48、全碼Z51.0、Z51.11、Z51.12、Z08)
// (4)早產安胎個案(主診斷ICD-10-CM：前五碼O4291及全碼O4410~O4413、O4690~O4693、O4702~O4703、O6002、O6003)
// (5)罕見疾病(主診斷E760~E763)一點多醣症
// (6)轉院案件(轉歸代碼5、6或7)
// (7)新生兒床號(部分負擔計費903)
// (8)血友病(主診斷D66、D67、D681、D682)
// (9)執行心導管(醫令代碼前5碼為18020、18021、97501、97502、97503、97506、97507、97508)
// (10)心血管線道手術(主次處置代碼前5碼為68023或68024或68025)
// (11)瓣膜置換術(醫令代碼前5碼為68016、68017、68018且主診斷碼前3碼為I00-I99)
// (12)器官移植(手術代碼75010、68003~68037、68043、75020、76020、75418、85213)
// (13)支架置放術(PTCA+血管支架)
// (14)急性後期整合照護計畫案件(住院案件分類4+試辦計畫代碼1腦中風、2燒燙傷、3創傷性神經損傷、4腦弱性骨折、6衰弱高齡)
// (15)安寧照護(給付類別A)
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "NHI_CLAIM": 'http://www.nhi.gov.tw/codes/claim'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "CPT": 'http://www.ama-assn.org/go/cpt'

valueset "Inpatient Encounters": 'http://nhi.gov.tw/fhir/ValueSet/inpatient-encounters'
valueset "Planned Readmissions": 'http://nhi.gov.tw/fhir/ValueSet/planned-readmissions'

// 就醫類型代碼
code "Inpatient": 'IMP' from "ActCode" display 'Inpatient'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'

// 腫瘤科科別代碼
code "Oncology Department": '13' from "NHI_CLAIM" display '腫瘤科'

// 案件分類代碼
code "Special Case Type": '4' from "NHI_CLAIM" display '特殊案件分類'

// 疾患來源代碼
code "Disease Source N": 'N' from "NHI_CLAIM" display '疾患來源-新生兒'
code "Disease Source R": 'R' from "NHI_CLAIM" display '疾患來源-再住院'
code "Disease Source C": 'C' from "NHI_CLAIM" display '疾患來源-慢性病'

// 轉歸代碼
code "Transfer Code 5": '5' from "NHI_CLAIM" display '轉院(計畫性)'
code "Transfer Code 6": '6' from "NHI_CLAIM" display '轉院(緊急)'
code "Transfer Code 7": '7' from "NHI_CLAIM" display '轉院(其他)'

// 部分負擔計費代碼
code "Newborn Bed": '903' from "NHI_CLAIM" display '新生兒床號'

// 給付類別代碼
code "Hospice Payment": 'A' from "NHI_CLAIM" display '安寧照護'

// 試辦計畫代碼
code "Pilot Stroke": '1' from "NHI_CLAIM" display '急性後期-腦中風'
code "Pilot Burn": '2' from "NHI_CLAIM" display '急性後期-燒燙傷'
code "Pilot Trauma": '3' from "NHI_CLAIM" display '急性後期-創傷性神經損傷'
code "Pilot Fracture": '4' from "NHI_CLAIM" display '急性後期-腦弱性骨折'
code "Pilot Frailty": '6' from "NHI_CLAIM" display '急性後期-衰弱高齡'

// 癌症診斷代碼 (ICD-10-CM C00-C96, 排除C94.4、C94.6)
code "Cancer C00": 'C00' from "ICD10CM" display 'Malignant neoplasm of lip'
code "Cancer C01": 'C01' from "ICD10CM" display 'Malignant neoplasm of base of tongue'
code "Cancer C02": 'C02' from "ICD10CM" display 'Malignant neoplasm of other and unspecified parts of tongue'
code "Cancer C94": 'C94' from "ICD10CM" display 'Other leukemias of specified cell type'
code "Cancer C944": 'C94.4' from "ICD10CM" display 'Acute panmyelosis with myelofibrosis - 排除'
code "Cancer C946": 'C94.6' from "ICD10CM" display 'Myelodysplastic disease, not classified - 排除'

// 性態未明腫瘤代碼 (D37-D48)
code "Uncertain D37": 'D37' from "ICD10CM" display 'Neoplasm of uncertain behavior of oral cavity and digestive organs'
code "Uncertain D48": 'D48' from "ICD10CM" display 'Neoplasm of uncertain behavior of other and unspecified sites'

// 腫瘤治療代碼
code "Radiotherapy Z510": 'Z51.0' from "ICD10CM" display 'Encounter for antineoplastic radiation therapy'
code "Chemotherapy Z5111": 'Z51.11' from "ICD10CM" display 'Encounter for antineoplastic chemotherapy'
code "Chemotherapy Z5112": 'Z51.12' from "ICD10CM" display 'Encounter for antineoplastic immunotherapy'
code "Cancer Followup Z08": 'Z08' from "ICD10CM" display 'Encounter for follow-up examination after completed treatment for malignant neoplasm'

// 早產安胎代碼
code "Preterm O4291": 'O4291' from "ICD10CM" display 'Premature separation of placenta with coagulation defect - 早產安胎(前五碼)'
code "Preterm O4410": 'O4410' from "ICD10CM" display 'Placenta previa specified as without hemorrhage, unspecified trimester'
code "Preterm O4411": 'O4411' from "ICD10CM" display 'Placenta previa specified as without hemorrhage, first trimester'
code "Preterm O4412": 'O4412' from "ICD10CM" display 'Placenta previa specified as without hemorrhage, second trimester'
code "Preterm O4413": 'O4413' from "ICD10CM" display 'Placenta previa specified as without hemorrhage, third trimester'
code "Preterm O4690": 'O4690' from "ICD10CM" display 'Unspecified antepartum hemorrhage, unspecified trimester'
code "Preterm O4691": 'O4691' from "ICD10CM" display 'Unspecified antepartum hemorrhage, first trimester'
code "Preterm O4692": 'O4692' from "ICD10CM" display 'Unspecified antepartum hemorrhage, second trimester'
code "Preterm O4693": 'O4693' from "ICD10CM" display 'Unspecified antepartum hemorrhage, third trimester'
code "Preterm O4702": 'O4702' from "ICD10CM" display 'False labor before 37 completed weeks of gestation, second trimester'
code "Preterm O4703": 'O4703' from "ICD10CM" display 'False labor before 37 completed weeks of gestation, third trimester'
code "Preterm O6002": 'O6002' from "ICD10CM" display 'Preterm labor without delivery, second trimester'
code "Preterm O6003": 'O6003' from "ICD10CM" display 'Preterm labor without delivery, third trimester'

// 罕見疾病代碼 (E760-E763 一點多醣症)
code "Rare E760": 'E760' from "ICD10CM" display 'Mucopolysaccharidosis, type I'
code "Rare E761": 'E761' from "ICD10CM" display 'Mucopolysaccharidosis, type II'
code "Rare E762": 'E762' from "ICD10CM" display 'Other mucopolysaccharidoses'
code "Rare E763": 'E763' from "ICD10CM" display 'Mucopolysaccharidosis, unspecified'

// 血友病代碼
code "Hemophilia D66": 'D66' from "ICD10CM" display 'Hereditary factor VIII deficiency'
code "Hemophilia D67": 'D67' from "ICD10CM" display 'Hereditary factor IX deficiency'
code "Hemophilia D681": 'D681' from "ICD10CM" display "Von Willebrand's disease"
code "Hemophilia D682": 'D682' from "ICD10CM" display 'Hereditary deficiency of other clotting factors'

// 心臟疾病代碼 (I00-I99, 配合瓣膜置換術)
code "Heart I00": 'I00' from "ICD10CM" display 'Rheumatic fever without heart involvement'
code "Heart I99": 'I99' from "ICD10CM" display 'Other and unspecified disorders of circulatory system'

// 心導管醫令代碼
code "Cardiac Cath 18020": '18020' from "NHI_PROCEDURE" display '心導管檢查-18020'
code "Cardiac Cath 18021": '18021' from "NHI_PROCEDURE" display '心導管檢查-18021'
code "Cardiac Cath 97501": '97501' from "NHI_PROCEDURE" display '心導管檢查-97501'
code "Cardiac Cath 97502": '97502' from "NHI_PROCEDURE" display '心導管檢查-97502'
code "Cardiac Cath 97503": '97503' from "NHI_PROCEDURE" display '心導管檢查-97503'
code "Cardiac Cath 97506": '97506' from "NHI_PROCEDURE" display '心導管檢查-97506'
code "Cardiac Cath 97507": '97507' from "NHI_PROCEDURE" display '心導管檢查-97507'
code "Cardiac Cath 97508": '97508' from "NHI_PROCEDURE" display '心導管檢查-97508'

// 冠狀動脈繞道手術代碼
code "CABG 68023": '68023' from "NHI_PROCEDURE" display '冠狀動脈繞道手術-68023'
code "CABG 68024": '68024' from "NHI_PROCEDURE" display '冠狀動脈繞道手術-68024'
code "CABG 68025": '68025' from "NHI_PROCEDURE" display '冠狀動脈繞道手術-68025'

// 瓣膜置換術代碼
code "Valve 68016": '68016' from "NHI_PROCEDURE" display '瓣膜置換術-68016'
code "Valve 68017": '68017' from "NHI_PROCEDURE" display '瓣膜置換術-68017'
code "Valve 68018": '68018' from "NHI_PROCEDURE" display '瓣膜置換術-68018'

// 器官移植代碼
code "Transplant 75010": '75010' from "NHI_PROCEDURE" display '甲臟移植'
code "Transplant 68003": '68003' from "NHI_PROCEDURE" display '腎臟移植-68003'
code "Transplant 68037": '68037' from "NHI_PROCEDURE" display '腎臟移植-68037'
code "Transplant 68043": '68043' from "NHI_PROCEDURE" display '骨髓移植後續追蹤'
code "Transplant 75020": '75020' from "NHI_PROCEDURE" display '肺臟移植'
code "Transplant 76020": '76020' from "NHI_PROCEDURE" display '腎臟移植'
code "Transplant 75418": '75418' from "NHI_PROCEDURE" display '胰臟移植'
code "Transplant 85213": '85213' from "NHI_PROCEDURE" display '骨髓移植'

// PTCA經皮冠狀動脈擴張術代碼
code "PTCA 02703ZZ": '02703ZZ' from "CPT" display 'Dilation of Coronary Artery, One Artery, Percutaneous Approach'
code "PTCA 02704ZZ": '02704ZZ' from "CPT" display 'Dilation of Coronary Artery, Two Arteries, Percutaneous Approach'
code "PTCA 3E07317": '3E07317' from "CPT" display 'Introduction of Other Thrombolytic into Coronary Artery'
code "PTCA 02713ZZ": '02713ZZ' from "CPT" display 'Dilation of Coronary Artery, One Artery with Intraluminal Device'
code "PTCA 02714ZZ": '02714ZZ' from "CPT" display 'Dilation of Coronary Artery, Two Arteries with Intraluminal Device'
code "PTCA 02723ZZ": '02723ZZ' from "CPT" display 'Dilation of Coronary Artery, Three Arteries'
code "PTCA 02733ZZ": '02733ZZ' from "CPT" display 'Dilation of Coronary Artery, Four or More Arteries'
code "PTCA 02734ZZ": '02734ZZ' from "CPT" display 'Dilation of Coronary Artery, Four or More Arteries with Device'

// PTCA醫令代碼
code "PTCA Order 33076": '33076' from "NHI_PROCEDURE" display 'PTCA醫令-33076'
code "PTCA Order 33077": '33077' from "NHI_PROCEDURE" display 'PTCA醫令-33077'
code "PTCA Order 33078": '33078' from "NHI_PROCEDURE" display 'PTCA醫令-33078'

// 血管支架特材代碼
code "Stent CBP02A1": 'CBP02A1' from "NHI_CLAIM" display '血管支架-CBP02A1'
code "Stent CBP06A1": 'CBP06A1' from "NHI_CLAIM" display '血管支架-CBP06A1'
code "Stent CBP06A2": 'CBP06A2' from "NHI_CLAIM" display '血管支架-CBP06A2'
code "Stent CBP06A3": 'CBP06A3' from "NHI_CLAIM" display '血管支架-CBP06A3'

// ============================================
// Quarter Definitions (2024-2026)
// ============================================

define "2024Q1 Start": @2024-01-01
define "2024Q1 End": @2024-03-31
define "2024Q2 Start": @2024-04-01
define "2024Q2 End": @2024-06-30
define "2024Q3 Start": @2024-07-01
define "2024Q3 End": @2024-09-30
define "2024Q4 Start": @2024-10-01
define "2024Q4 End": @2024-12-31

define "2025Q1 Start": @2025-01-01
define "2025Q1 End": @2025-03-31
define "2025Q2 Start": @2025-04-01
define "2025Q2 End": @2025-06-30
define "2025Q3 Start": @2025-07-01
define "2025Q3 End": @2025-09-30
define "2025Q4 Start": @2025-10-01
define "2025Q4 End": @2025-12-31

define "2026Q1 Start": @2026-01-01
define "2026Q1 End": @2026-03-31

// Measurement Period (無限制 - Unlimited)
define "Measurement Period Start": @2024-01-01
define "Measurement Period End": @2099-12-31
define "Measurement Period": Interval["Measurement Period Start", "Measurement Period End"]

// ============================================
// Helper Functions
// ============================================

define function GetId(resource FHIR.Resource):
  Last(Split(resource.id, '/'))

define function GetDischargeDate(encounter FHIR.Encounter):
  end of encounter.period

define function GetAdmissionDate(encounter FHIR.Encounter):
  start of encounter.period

define function GetPrimaryDiagnosis(encounter FHIR.Encounter):
  Coalesce(
    First(
      encounter.diagnosis D
        where exists (D.use.coding C where C.code.value = 'primary')
        return First(
          [Condition: id in GetId(D.condition.reference)]
        ).code.coding[0].code.value
    ),
    ''
  )

define function GetDiagnosisPrefix3(diagnosisCode String):
  if Length(diagnosisCode) >= 3 then
    Substring(diagnosisCode, 0, 3)
  else
    diagnosisCode

define function GetDiagnosisPrefix5(diagnosisCode String):
  if Length(diagnosisCode) >= 5 then
    Substring(diagnosisCode, 0, 5)
  else
    diagnosisCode

define function DaysBetween(date1 DateTime, date2 DateTime):
  days between date1 and date2

// ============================================
// Data Retrieval
// ============================================

context Patient

define "All Inpatient Discharges":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and end of E.period in "Measurement Period"

// ============================================
// Exclusion Criteria (15 types of planned readmissions)
// ============================================

define function IsOncologyCase(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/department-code'
        and (E.value as FHIR.code).value = '13'
  )

define function IsBreastCancerPilot(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/case-type'
        and (E.value as FHIR.code).value = '4'
  )
  and exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/disease-source'
        and (E.value as FHIR.code).value in {'N', 'R', 'C'}
  )

define function IsCancerTreatment(encounter FHIR.Encounter):
  GetDiagnosisPrefix3(GetPrimaryDiagnosis(encounter)) in {
    'C00', 'C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C07', 'C08', 'C09',
    'C10', 'C11', 'C12', 'C13', 'C14', 'C15', 'C16', 'C17', 'C18', 'C19',
    'C20', 'C21', 'C22', 'C23', 'C24', 'C25', 'C26', 'C30', 'C31', 'C32',
    'C33', 'C34', 'C37', 'C38', 'C39', 'C40', 'C41', 'C43', 'C44', 'C45',
    'C46', 'C47', 'C48', 'C49', 'C50', 'C51', 'C52', 'C53', 'C54', 'C55',
    'C56', 'C57', 'C58', 'C60', 'C61', 'C62', 'C63', 'C64', 'C65', 'C66',
    'C67', 'C68', 'C69', 'C70', 'C71', 'C72', 'C73', 'C74', 'C75', 'C76',
    'C77', 'C78', 'C79', 'C80', 'C81', 'C82', 'C83', 'C84', 'C85', 'C86',
    'C88', 'C90', 'C91', 'C92', 'C93', 'C95', 'C96',
    'D37', 'D38', 'D39', 'D40', 'D41', 'D42', 'D43', 'D44', 'D45', 'D46',
    'D47', 'D48'
  }
  and GetPrimaryDiagnosis(encounter) not in {'C94.4', 'C94.6'}
  or GetPrimaryDiagnosis(encounter) in {'Z51.0', 'Z51.11', 'Z51.12', 'Z08'}

define function IsPretermLabor(encounter FHIR.Encounter):
  GetDiagnosisPrefix5(GetPrimaryDiagnosis(encounter)) = 'O4291'
  or GetPrimaryDiagnosis(encounter) in {
    'O4410', 'O4411', 'O4412', 'O4413',
    'O4690', 'O4691', 'O4692', 'O4693',
    'O4702', 'O4703', 'O6002', 'O6003'
  }

define function IsRareDisease(encounter FHIR.Encounter):
  GetPrimaryDiagnosis(encounter) in {'E760', 'E761', 'E762', 'E763'}

define function IsTransferCase(encounter FHIR.Encounter):
  exists (
    encounter.hospitalization.dischargeDisposition.coding C
      where C.code.value in {'5', '6', '7'}
  )

define function IsNewbornBed(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/copayment-code'
        and (E.value as FHIR.code).value = '903'
  )

define function IsHemophilia(encounter FHIR.Encounter):
  GetPrimaryDiagnosis(encounter) in {'D66', 'D67', 'D681', 'D682'}

define function HasCardiacCath(encounter FHIR.Encounter):
  exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where Substring(C.code.value, 0, 5) in {
              '18020', '18021', '97501', '97502', '97503', '97506', '97507', '97508'
            }
        )
  )

define function HasCABG(encounter FHIR.Encounter):
  exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where Substring(C.code.value, 0, 5) in {'68023', '68024', '68025'}
        )
  )

define function HasValveReplacement(encounter FHIR.Encounter):
  exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where Substring(C.code.value, 0, 5) in {'68016', '68017', '68018'}
        )
  )
  and GetDiagnosisPrefix3(GetPrimaryDiagnosis(encounter)) >= 'I00'
  and GetDiagnosisPrefix3(GetPrimaryDiagnosis(encounter)) <= 'I99'

define function HasOrganTransplant(encounter FHIR.Encounter):
  exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where C.code.value in {
              '75010', '68003', '68037', '68043', '75020', '76020', '75418', '85213'
            }
        )
  )

define function HasStentPlacement(encounter FHIR.Encounter):
  exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where C.code.value in {
              '02703ZZ', '02704ZZ', '3E07317', '02713ZZ', '02714ZZ', '02723ZZ', '02733ZZ', '02734ZZ'
            }
        )
  )
  and exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where Substring(C.code.value, 0, 5) in {'33076', '33077', '33078'}
        )
  )

define function IsPostAcuteCare(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/case-type'
        and (E.value as FHIR.code).value = '4'
  )
  and exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/pilot-program'
        and (E.value as FHIR.code).value in {'1', '2', '3', '4', '6'}
  )

define function IsHospiceCare(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/payment-type'
        and (E.value as FHIR.code).value = 'A'
  )

define function IsPlannedReadmission(encounter FHIR.Encounter):
  IsOncologyCase(encounter)
  or IsBreastCancerPilot(encounter)
  or IsCancerTreatment(encounter)
  or IsPretermLabor(encounter)
  or IsRareDisease(encounter)
  or IsTransferCase(encounter)
  or IsNewbornBed(encounter)
  or IsHemophilia(encounter)
  or HasCardiacCath(encounter)
  or HasCABG(encounter)
  or HasValveReplacement(encounter)
  or HasOrganTransplant(encounter)
  or HasStentPlacement(encounter)
  or IsPostAcuteCare(encounter)
  or IsHospiceCare(encounter)

// ============================================
// Unplanned Discharges (分母)
// ============================================

define "Unplanned Discharges":
  "All Inpatient Discharges" E
    where not IsPlannedReadmission(E)

define function UnplannedDischargesInPeriod(periodStart Date, periodEnd Date):
  "Unplanned Discharges" E
    where date from GetDischargeDate(E) in Interval[periodStart, periodEnd]

define function DischargePatientCountInPeriod(periodStart Date, periodEnd Date):
  Count(
    distinct (
      UnplannedDischargesInPeriod(periodStart, periodEnd) E
        return GetId([Patient])
    )
  )

// ============================================
// 14-Day Readmissions (分子)
// ============================================

define function Has14DayReadmission(dischargeEncounter FHIR.Encounter):
  exists (
    "All Inpatient Discharges" R
      where R.id != dischargeEncounter.id
        and GetId(R.subject.reference) = GetId(dischargeEncounter.subject.reference)
        and GetAdmissionDate(R) > GetDischargeDate(dischargeEncounter)
        and DaysBetween(GetDischargeDate(dischargeEncounter), GetAdmissionDate(R)) <= 14
        and not IsPlannedReadmission(R)
  )

define function ReadmissionPatientsInPeriod(periodStart Date, periodEnd Date):
  UnplannedDischargesInPeriod(periodStart, periodEnd) E
    where Has14DayReadmission(E)

define function ReadmissionPatientCountInPeriod(periodStart Date, periodEnd Date):
  Count(
    distinct (
      ReadmissionPatientsInPeriod(periodStart, periodEnd) E
        return GetId([Patient])
    )
  )

// ============================================
// 2024Q1 Statistics
// ============================================

define "2024Q1 Denominator":
  DischargePatientCountInPeriod("2024Q1 Start", "2024Q1 End")

define "2024Q1 Numerator":
  ReadmissionPatientCountInPeriod("2024Q1 Start", "2024Q1 End")

define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then
    ("2024Q1 Numerator" / "2024Q1 Denominator") * 100
  else null

// ============================================
// 2024Q2 Statistics
// ============================================

define "2024Q2 Denominator":
  DischargePatientCountInPeriod("2024Q2 Start", "2024Q2 End")

define "2024Q2 Numerator":
  ReadmissionPatientCountInPeriod("2024Q2 Start", "2024Q2 End")

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then
    ("2024Q2 Numerator" / "2024Q2 Denominator") * 100
  else null

// ============================================
// 2024Q3 Statistics
// ============================================

define "2024Q3 Denominator":
  DischargePatientCountInPeriod("2024Q3 Start", "2024Q3 End")

define "2024Q3 Numerator":
  ReadmissionPatientCountInPeriod("2024Q3 Start", "2024Q3 End")

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then
    ("2024Q3 Numerator" / "2024Q3 Denominator") * 100
  else null

// ============================================
// 2024Q4 Statistics
// ============================================

define "2024Q4 Denominator":
  DischargePatientCountInPeriod("2024Q4 Start", "2024Q4 End")

define "2024Q4 Numerator":
  ReadmissionPatientCountInPeriod("2024Q4 Start", "2024Q4 End")

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then
    ("2024Q4 Numerator" / "2024Q4 Denominator") * 100
  else null

// ============================================
// 2025Q1 Statistics
// ============================================

define "2025Q1 Denominator":
  DischargePatientCountInPeriod("2025Q1 Start", "2025Q1 End")

define "2025Q1 Numerator":
  ReadmissionPatientCountInPeriod("2025Q1 Start", "2025Q1 End")

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then
    ("2025Q1 Numerator" / "2025Q1 Denominator") * 100
  else null

// ============================================
// 2025Q2 Statistics
// ============================================

define "2025Q2 Denominator":
  DischargePatientCountInPeriod("2025Q2 Start", "2025Q2 End")

define "2025Q2 Numerator":
  ReadmissionPatientCountInPeriod("2025Q2 Start", "2025Q2 End")

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then
    ("2025Q2 Numerator" / "2025Q2 Denominator") * 100
  else null

// ============================================
// 2025Q3 Statistics
// ============================================

define "2025Q3 Denominator":
  DischargePatientCountInPeriod("2025Q3 Start", "2025Q3 End")

define "2025Q3 Numerator":
  ReadmissionPatientCountInPeriod("2025Q3 Start", "2025Q3 End")

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then
    ("2025Q3 Numerator" / "2025Q3 Denominator") * 100
  else null

// ============================================
// 2025Q4 Statistics
// ============================================

define "2025Q4 Denominator":
  DischargePatientCountInPeriod("2025Q4 Start", "2025Q4 End")

define "2025Q4 Numerator":
  ReadmissionPatientCountInPeriod("2025Q4 Start", "2025Q4 End")

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then
    ("2025Q4 Numerator" / "2025Q4 Denominator") * 100
  else null

// ============================================
// 2026Q1 Statistics
// ============================================

define "2026Q1 Denominator":
  DischargePatientCountInPeriod("2026Q1 Start", "2026Q1 End")

define "2026Q1 Numerator":
  ReadmissionPatientCountInPeriod("2026Q1 Start", "2026Q1 End")

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then
    ("2026Q1 Numerator" / "2026Q1 Denominator") * 100
  else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  {
    indicatorCodeQuarterly: '1077.01',
    indicatorCodeAnnual: '1809',
    indicatorName: '非計畫性住院案件出院後十四日內再住院率',
    indicatorNameEn: 'Unplanned 14-Day Readmission Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/11/06',
    version: '1.0.0',
    readmissionDays: 14,
    denominatorCriteria: '當季出院人數(排除計畫性再住院)',
    numeratorCriteria: '病人14日再住院人數(排除計畫性再住院)',
    exclusionCount: 15,
    exclusionCriteria: '腫瘤科、乳癌試辦、癌症治療、早產安胎、罕見疾病、轉院、新生兒床號、血友病、心導管、冠狀動脈繞道、瓣膜置換、器官移植、支架置放、急性後期照護、安寧照護'
  }
 * 
 * 公式說明:
 * 非計畫性住院案件出院後十四日內再住院率 = 
 *     分子: 病人14日再住院人數
 *     分母: 當季出院人數
 * 
 * 分母分子均排除下列計畫性再住院案件:
 * (1)腫瘤科個案(就醫科別=13)
 * (2)乳癌試辦案件(案件分類4+疾患來源N或R或C)
 * (3)癌症、性態未明腫瘤治療(主、次診斷ICD-10-CM前3碼為C00-C96(排除C94.4、C94.6)、D37-D48、全碼Z51.0、Z51.11、Z51.12、Z08)
 * (4)早產安胎個案(主診斷ICD-10-CM：前五碼O4291及全碼O4410~O4413、O4690~O4693、O4702~O4703、O6002、O6003)
 * (5)罕見疾病(主診斷E760~E763)一點多醣症
 * (6)轉院案件(轉歸代碼5、6或7)
 * (7)新生兒床號(部分負擔計費903)
 * (8)血友病(主診斷D66、D67、D681、D682)
 * (9)執行心導管(心導管線碼手術或尿膜置換術或支架置放術)
 * (10)與手術有關之代碼前5碼為0.甲臟移植:75010、乙.腎臟移植:68003到68037(肺、肝、腎臟移植合併麻醉管理)、68043或骨髓移植後續追蹤(肺、肝、心臟、腎移植、骨髓移植:75020 d.腎臟移植:76020 e.胰臟移植:75418 f.骨髓移植:85213)
 * (11)急性後期整合照護計畫案件(住院案件分類4 + 試辦計畫代碼1 腦中風、2燒燙傷、3創傷性神經損傷、4腦弱性骨折、6衰弱高齡)
 * (12)安寧照護(給付類別A)
 * 心導管: 醫令代碼前5碼為18020、18021、97501、97502、97503、97506、97507、97508
 * 心血管線道手術: 以冠狀動脈線道手術為主，主次處置代碼(手術代碼計2)日醫令代碼前5碼為68023或68024或68025
 * 瓣膜置換術: 醫令代碼前5碼為68016、68017、68018且主診斷碼前3碼為I00-I99且主處置代碼(手術代碼計2)
 * 
 * 支架置放術: 同時申報「經皮冠狀動脈擴張術(PTCA)」及放置血管支架之案件。經皮冠狀動脈擴張術(PTCA): 主次處置代碼(手術代碼)為02703ZZ、02704ZZ、3E07317、02713ZZ、02714ZZ、02723ZZ、02733ZZ、02734ZZ且醫令代碼前5碼為33076、33077、33078。
 * 放置血管支架: 主次處置代碼(手術代碼計2)且特材代碼前7碼為CBP02A1、CBP06A1、CBP06A2及CBP06A3
 * 
 * 註1: 新增1809就行年指標統計，自統計期間101年開始產製。
 * 註2: 手術代碼請至本署健保資訊網服務系統(VPN)/下載檔案/院所醫療服務指標查詢書版「醫療服務指標操作型定義說明」檔案查詢。
 * 
 * 臨床意義:
 * - 評估出院計畫的完整性
 * - 監測醫療品質與連續性照護
 * - 辨識高風險再住院病患
 * - 降低非必要再住院
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 住院紀錄 (住院、出院)
 * - Condition: 診斷資料 (主診斷、次診斷)
 * - Procedure: 手術處置資料
 * - MedicationRequest: 用藥資料
 * - Claim: 醫療費用申報
 * - Device: 特殊材料 (支架等)
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 1077.01 (季度)
    -- 1809 (年度)

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- 用於主診斷和次診斷識別
    -- C00-C96: 惡性腫瘤 (排除C94.4、C94.6)
    -- D37-D48: 性態未明腫瘤
    -- Z51.0, Z51.11, Z51.12: 放射線治療、化學治療
    -- Z08: 惡性腫瘤治療後追蹤檢查
    -- O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003: 早產安胎
    -- E760-E763: 罕見疾病(一點多醣症)
    -- D66, D67, D681, D682: 血友病
    -- I00-I99: 心臟疾病 (配合瓣膜置換術)

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 32485007: Hospital admission (住院)
    -- 58000006: Patient discharge (病患出院)
    -- 417005: Hospital readmission (再住院)
    -- 183452005: Emergency hospital admission (緊急住院)
    -- 71388002: Procedure (手術處置)
    -- 304561000: Chemotherapy (化學治療)
    -- 33195004: Radiotherapy (放射線治療)
    -- 82433008: Organ transplantation (器官移植)
    -- 18027006: Transplantation of kidney (腎臟移植)
    -- 32413006: Transplantation of liver (肝臟移植)
    -- 32413006: Transplantation of heart (心臟移植)
    -- 52213001: Transplantation of lung (肺臟移植)
    -- 23719005: Transplantation of pancreas (胰臟移植)
    -- 23719005: Bone marrow transplantation (骨髓移植)
    -- 119565006: Malignant tumor (惡性腫瘤)
    -- 309884000: Oncology specialty (腫瘤科)
    -- 392021009: Lapsed planned readmission (計畫性再住院)

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode 代碼系統
    -- IMP: 住院 (Inpatient)
    -- AMB: 門診 (Ambulatory)
    -- EMER: 急診 (Emergency)

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
    -- 台灣健保局專用代碼系統
    -- 醫事機構代碼
    -- 醫療服務代碼
    -- 案件類別代碼
    -- 醫令代碼
    -- 特材代碼

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- I: 住院
    -- O: 門診
    -- E: 急診

codesystem "NHI_DEPARTMENT": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-department'
    -- 健保科別代碼系統
    -- 13: 腫瘤科

codesystem "NHI_CASE_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-case-type'
    -- 健保案件分類代碼系統
    -- 案件分類4: 特殊案件

codesystem "NHI_DISEASE_SOURCE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-disease-source'
    -- 健保疾患來源代碼系統
    -- N: 新生兒
    -- R: 再住院
    -- C: 慢性病

codesystem "NHI_DISCHARGE_STATUS": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-discharge-status'
    -- 健保出院轉歸代碼系統
    -- 5: 轉院(計畫性)
    -- 6: 轉院(緊急)
    -- 7: 轉院(其他)

codesystem "NHI_COPAYMENT": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-copayment'
    -- 健保部分負擔計費代碼系統
    -- 903: 新生兒床號

codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
    -- 健保手術處置代碼系統
    -- 75010: 甲臟移植
    -- 68003-68037: 腎臟移植(肺、肝、腎臟移植合併麻醉管理)
    -- 68043: 骨髓移植後續追蹤
    -- 75020: 肺移植
    -- 76020: 腎臟移植
    -- 75418: 胰臟移植
    -- 85213: 骨髓移植

codesystem "NHI_ORDER": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-order'
    -- 健保醫令代碼系統
    -- 18020, 18021, 97501, 97502, 97503, 97506, 97507, 97508: 心導管
    -- 68023, 68024, 68025: 冠狀動脈線道手術
    -- 68016, 68017, 68018: 瓣膜置換術
    -- 33076, 33077, 33078: 經皮冠狀動脈擴張術(PTCA)

codesystem "NHI_MATERIAL": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-material'
    -- 健保特材代碼系統
    -- CBP02A1, CBP06A1, CBP06A2, CBP06A3: 血管支架

codesystem "NHI_PAYMENT_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-payment-type'
    -- 健保給付類別代碼系統
    -- A: 安寧照護

codesystem "NHI_PILOT_PROGRAM": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-pilot-program'
    -- 健保試辦計畫代碼系統
    -- 1: 腦中風
    -- 2: 燒燙傷
    -- 3: 創傷性神經損傷
    -- 4: 腦弱性骨折
    -- 6: 衰弱高齡

codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
    -- Current Procedural Terminology
    -- 用於手術處置代碼對照
    -- 02703ZZ, 02704ZZ, 3E07317, 02713ZZ, 02714ZZ, 02723ZZ, 02733ZZ, 02734ZZ: PTCA

-- ==================== 值集定義 ====================

valueset "Inpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/inpatient-encounter-types'
    -- 住院就醫類別值集
    -- ActCode: IMP (住院)
    -- NHI: I (住院)

valueset "Cancer Diagnosis Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-diagnosis-codes'
    -- 惡性腫瘤診斷代碼值集
    -- ICD-10-CM: C00-C96 (排除C94.4, C94.6)
    -- ICD-10-CM: D37-D48 (性態未明腫瘤)

valueset "Cancer Treatment Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-treatment-codes'
    -- 腫瘤治療代碼值集
    -- ICD-10-CM: Z51.0, Z51.11, Z51.12, Z08

valueset "Preterm Labor Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/preterm-labor-codes'
    -- 早產安胎代碼值集
    -- ICD-10-CM: O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003

valueset "Rare Disease Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/rare-disease-codes'
    -- 罕見疾病代碼值集
    -- ICD-10-CM: E760-E763 (一點多醣症)

valueset "Hemophilia Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hemophilia-codes'
    -- 血友病代碼值集
    -- ICD-10-CM: D66, D67, D681, D682

valueset "Cardiac Catheterization Orders": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cardiac-catheterization-orders'
    -- 心導管醫令代碼值集
    -- NHI_ORDER: 18020, 18021, 97501, 97502, 97503, 97506, 97507, 97508

valueset "Coronary Bypass Orders": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/coronary-bypass-orders'
    -- 冠狀動脈線道手術醫令代碼值集
    -- NHI_ORDER: 68023, 68024, 68025

valueset "Valve Replacement Orders": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/valve-replacement-orders'
    -- 瓣膜置換術醫令代碼值集
    -- NHI_ORDER: 68016, 68017, 68018

valueset "Organ Transplant Procedures": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/organ-transplant-procedures'
    -- 器官移植手術代碼值集
    -- NHI_PROCEDURE: 75010, 68003-68037, 68043, 75020, 76020, 75418, 85213

valueset "PTCA Procedures": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/ptca-procedures'
    -- 經皮冠狀動脈擴張術代碼值集
    -- CPT: 02703ZZ, 02704ZZ, 3E07317, 02713ZZ, 02714ZZ, 02723ZZ, 02733ZZ, 02734ZZ

valueset "Vascular Stent Materials": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/vascular-stent-materials'
    -- 血管支架特材代碼值集
    -- NHI_MATERIAL: CBP02A1, CBP06A1, CBP06A2, CBP06A3

valueset "Post-Acute Care Programs": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/post-acute-care-programs'
    -- 急性後期整合照護計畫值集
    -- NHI_PILOT_PROGRAM: 1(腦中風), 2(燒燙傷), 3(創傷性神經損傷), 4(腦弱性骨折), 6(衰弱高齡)

valueset "Hospice Care Payment Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hospice-care-payment-types'
    -- 安寧照護給付類別值集
    -- NHI_PAYMENT_TYPE: A

-- ==================== NHI指標代碼對照 ====================

/*
 * 指標代碼定義
 * 1077.01: 季度指標
 * 1809: 年度指標
 */
code "Indicator_1077_01": '1077.01' from "NHI_INDICATOR" display '非計畫性住院案件出院後十四日內再住院率(季)'
code "Indicator_1809": '1809' from "NHI_INDICATOR" display '非計畫性住院案件出院後十四日內再住院率(年)'

-- ==================== ICD-10-CM診斷代碼對照 ====================

/*
 * 惡性腫瘤代碼 (C00-C96, 排除C94.4, C94.6)
 * 性態未明腫瘤代碼 (D37-D48)
 * 腫瘤治療代碼 (Z51.0, Z51.11, Z51.12, Z08)
 * 早產安胎代碼 (O4291, O4410-O4413, O4690-O4693, O4702-O4703, O6002, O6003)
 * 罕見疾病代碼 (E760-E763)
 * 血友病代碼 (D66, D67, D681, D682)
 * 心臟疾病代碼 (I00-I99)
 */

-- ==================== 健保科別代碼對照 ====================

code "Oncology_Department": '13' from "NHI_DEPARTMENT" display '腫瘤科'

-- ==================== 健保案件分類代碼對照 ====================

code "Special_Case_Type": '4' from "NHI_CASE_TYPE" display '特殊案件'

-- ==================== 健保疾患來源代碼對照 ====================

code "Disease_Source_N": 'N' from "NHI_DISEASE_SOURCE" display '新生兒'
code "Disease_Source_R": 'R' from "NHI_DISEASE_SOURCE" display '再住院'
code "Disease_Source_C": 'C' from "NHI_DISEASE_SOURCE" display '慢性病'

-- ==================== 健保出院轉歸代碼對照 ====================

code "Transfer_Status_5": '5' from "NHI_DISCHARGE_STATUS" display '轉院(計畫性)'
code "Transfer_Status_6": '6' from "NHI_DISCHARGE_STATUS" display '轉院(緊急)'
code "Transfer_Status_7": '7' from "NHI_DISCHARGE_STATUS" display '轉院(其他)'

-- ==================== 健保部分負擔計費代碼對照 ====================

code "Newborn_Copayment": '903' from "NHI_COPAYMENT" display '新生兒床號'

-- ==================== 健保給付類別代碼對照 ====================

code "Hospice_Payment": 'A' from "NHI_PAYMENT_TYPE" display '安寧照護'

-- ==================== 健保試辦計畫代碼對照 ====================

code "Pilot_Stroke": '1' from "NHI_PILOT_PROGRAM" display '腦中風'
code "Pilot_Burn": '2' from "NHI_PILOT_PROGRAM" display '燒燙傷'
code "Pilot_Trauma": '3' from "NHI_PILOT_PROGRAM" display '創傷性神經損傷'
code "Pilot_Fracture": '4' from "NHI_PILOT_PROGRAM" display '腦弱性骨折'
code "Pilot_Frailty": '6' from "NHI_PILOT_PROGRAM" display '衰弱高齡'

-- ==================== 參數定義 ====================

parameter "Measurement Period" Interval<DateTime>
    -- 統計期間（季度或年度）

parameter "Readmission Days" Integer default 14
    -- 再住院觀察天數（預設14天）

-- ==================== 統計期間定義 ====================

define quarters AS (
    List<Tuple {
        id: Integer,
        label: String,
        start_date: DateTime,
        end_date: DateTime
    }> {
        { id: 1, label: '113年第1季', start_date: @2024-01-01T00:00:00, end_date: @2024-03-31T23:59:59 },
        { id: 2, label: '113年第2季', start_date: @2024-04-01T00:00:00, end_date: @2024-06-30T23:59:59 },
        { id: 3, label: '113年第3季', start_date: @2024-07-01T00:00:00, end_date: @2024-09-30T23:59:59 },
        { id: 4, label: '113年第4季', start_date: @2024-10-01T00:00:00, end_date: @2024-12-31T23:59:59 }
    }
)

define annual_period AS (
    Tuple {
        id: 5,
        label: '113年',
        start_date: @2024-01-01T00:00:00,
        end_date: @2024-12-31T23:59:59
    }
)

-- ==================== FHIR資源查詢 ====================

-- 1. 所有住院出院案件（未過濾）
define all_inpatient_discharges AS (
    [Encounter: type in "Inpatient Encounter Types"] E
    where E.status = 'finished'
        and E.period.end during "Measurement Period"
        and E.hospitalization.dischargeDisposition is not null
)

-- 2. 排除條件1：腫瘤科個案（就醫科別=13）
define oncology_cases AS (
    all_inpatient_discharges E
    where exists (
        E.participant P
        where P.individual.resolve().specialty.coding contains Code { code: '13', system: "NHI_DEPARTMENT" }
    )
)

-- 3. 排除條件2：乳癌試辦案件（案件分類4+疾患來源N或R或C）
define breast_cancer_pilot_cases AS (
    all_inpatient_discharges E
    where E.class = "IMP"
        and exists (
            E.type T
            where T.coding contains Code { code: '4', system: "NHI_CASE_TYPE" }
        )
        and exists (
            E.diagnosis D
            where D.condition.resolve().code.coding C
                where C.code in { 'N', 'R', 'C' }
                    and C.system = "NHI_DISEASE_SOURCE"
        )
)

-- 4. 排除條件3：癌症、性態未明腫瘤治療
define cancer_treatment_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                -- C00-C96 (排除C94.4, C94.6)
                (D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (C.code >= 'C00' and C.code <= 'C96')
                    and C.code not in { 'C94.4', 'C94.6' }
                )
                -- D37-D48
                or (D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (C.code >= 'D37' and C.code <= 'D48')
                )
                -- Z51.0, Z51.11, Z51.12, Z08
                or (D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and C.code in { 'Z51.0', 'Z51.11', 'Z51.12', 'Z08' }
                )
            )
    )
)

-- 5. 排除條件4：早產安胎個案
define preterm_labor_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (
                        C.code = 'O4291'
                        or (C.code >= 'O4410' and C.code <= 'O4413')
                        or (C.code >= 'O4690' and C.code <= 'O4693')
                        or (C.code >= 'O4702' and C.code <= 'O4703')
                        or C.code in { 'O6002', 'O6003' }
                    )
            )
    )
)

-- 6. 排除條件5：罕見疾病（一點多醣症）
define rare_disease_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and (C.code >= 'E760' and C.code <= 'E763')
            )
    )
)

-- 7. 排除條件6：轉院案件（轉歸代碼5、6或7）
define transfer_cases AS (
    all_inpatient_discharges E
    where E.hospitalization.dischargeDisposition.coding C
        where C.system = "NHI_DISCHARGE_STATUS"
            and C.code in { '5', '6', '7' }
)

-- 8. 排除條件7：新生兒床號（部分負擔計費903）
define newborn_bed_cases AS (
    all_inpatient_discharges E
    where exists (
        [Claim] Cl
        where Cl.encounter.reference = ('Encounter/' + E.id)
            and exists (
                Cl.item I
                where I.revenue.coding contains Code { code: '903', system: "NHI_COPAYMENT" }
            )
    )
)

-- 9. 排除條件8：血友病
define hemophilia_cases AS (
    all_inpatient_discharges E
    where exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and C.code in { 'D66', 'D67', 'D681', 'D682' }
            )
    )
)

-- 10. 排除條件9：執行心導管
define cardiac_catheterization_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and (
                -- 心導管醫令代碼
                P.code.coding C where C.system = "NHI_ORDER"
                    and Substring(C.code, 0, 5) in { '18020', '18021', '97501', '97502', '97503', '97506', '97507', '97508' }
            )
    )
)

-- 11. 排除條件10：心血管線道手術
define coronary_bypass_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and P.code.coding C where C.system = "NHI_ORDER"
                and Substring(C.code, 0, 5) in { '68023', '68024', '68025' }
    )
)

-- 12. 排除條件11：瓣膜置換術
define valve_replacement_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and P.code.coding C where C.system = "NHI_ORDER"
                and Substring(C.code, 0, 5) in { '68016', '68017', '68018' }
    )
    and exists (
        E.diagnosis D
        where D.use.coding contains Code { code: 'AD', system: "http://terminology.hl7.org/CodeSystem/diagnosis-role" }
            and (
                D.condition.resolve().code.coding C where C.system = "ICD10CM" 
                    and Substring(C.code, 0, 3) >= 'I00' and Substring(C.code, 0, 3) <= 'I99'
            )
    )
)

-- 13. 排除條件12：器官移植案件
define organ_transplant_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            and (
                P.code.coding C where C.system = "NHI_PROCEDURE"
                    and (
                        C.code = '75010'  -- 甲臟移植
                        or (C.code >= '68003' and C.code <= '68037')  -- 腎臟移植合併麻醉
                        or C.code = '68043'  -- 骨髓移植後續追蹤
                        or C.code = '75020'  -- 肺移植
                        or C.code = '76020'  -- 腎臟移植
                        or C.code = '75418'  -- 胰臟移植
                        or C.code = '85213'  -- 骨髓移植
                    )
            )
    )
)

-- 14. 排除條件13：支架置放術（PTCA + 血管支架）
define stent_placement_cases AS (
    all_inpatient_discharges E
    where exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            -- PTCA手術代碼
            and P.code.coding C where C.system = "CPT"
                and C.code in { '02703ZZ', '02704ZZ', '3E07317', '02713ZZ', '02714ZZ', '02723ZZ', '02733ZZ', '02734ZZ' }
    )
    and exists (
        [Procedure] P
        where P.encounter.reference = ('Encounter/' + E.id)
            and P.status = 'completed'
            -- 醫令代碼前5碼為33076, 33077, 33078
            and P.code.coding C where C.system = "NHI_ORDER"
                and Substring(C.code, 0, 5) in { '33076', '33077', '33078' }
    )
    and exists (
        [Device] D
        where D.patient.reference = ('Patient/' + E.subject.reference)
            -- 特材代碼前7碼為CBP02A1, CBP06A1, CBP06A2, CBP06A3
            and D.deviceName.name.coding C where C.system = "NHI_MATERIAL"
                and Substring(C.code, 0, 7) in { 'CBP02A1', 'CBP06A1', 'CBP06A2', 'CBP06A3' }
    )
)

-- 15. 排除條件14：急性後期整合照護計畫案件
define post_acute_care_cases AS (
    all_inpatient_discharges E
    where E.class = "IMP"
        and exists (
            E.type T
            where T.coding contains Code { code: '4', system: "NHI_CASE_TYPE" }
        )
        and exists (
            [Claim] Cl
            where Cl.encounter.reference = ('Encounter/' + E.id)
                and exists (
                    Cl.item I
                    where I.programCode.coding C
                        where C.system = "NHI_PILOT_PROGRAM"
                            and C.code in { '1', '2', '3', '4', '6' }
                )
        )
)

-- 16. 排除條件15：安寧照護（給付類別A）
define hospice_care_cases AS (
    all_inpatient_discharges E
    where exists (
        [Claim] Cl
        where Cl.encounter.reference = ('Encounter/' + E.id)
            and Cl.type.coding contains Code { code: 'A', system: "NHI_PAYMENT_TYPE" }
    )
)

-- ==================== 非計畫性住院案件 ====================

-- 排除所有計畫性再住院條件後的非計畫性住院案件
define unplanned_discharges AS (
    all_inpatient_discharges E
    where E not in oncology_cases
        and E not in breast_cancer_pilot_cases
        and E not in cancer_treatment_cases
        and E not in preterm_labor_cases
        and E not in rare_disease_cases
        and E not in transfer_cases
        and E not in newborn_bed_cases
        and E not in hemophilia_cases
        and E not in cardiac_catheterization_cases
        and E not in coronary_bypass_cases
        and E not in valve_replacement_cases
        and E not in organ_transplant_cases
        and E not in stent_placement_cases
        and E not in post_acute_care_cases
        and E not in hospice_care_cases
)

-- ==================== 14日內再住院案件 ====================

-- 查詢14日內的再住院案件
define readmissions_within_14_days AS (
    unplanned_discharges D
    let discharge_date := D.period.end,
        patient_id := D.subject.reference
    return {
        discharge_encounter_id: D.id,
        patient_id: patient_id,
        discharge_date: discharge_date,
        -- 查詢此病患在出院後14日內的再住院
        readmission_encounters: (
            [Encounter: type in "Inpatient Encounter Types"] R
            where R.subject.reference = patient_id
                and R.status = 'finished'
                and R.id != D.id
                and R.period.start > discharge_date
                and days between discharge_date and R.period.start <= 14
                -- 排除計畫性再住院
                and R not in oncology_cases
                and R not in breast_cancer_pilot_cases
                and R not in cancer_treatment_cases
                and R not in preterm_labor_cases
                and R not in rare_disease_cases
                and R not in transfer_cases
                and R not in newborn_bed_cases
                and R not in hemophilia_cases
                and R not in cardiac_catheterization_cases
                and R not in coronary_bypass_cases
                and R not in valve_replacement_cases
                and R not in organ_transplant_cases
                and R not in stent_placement_cases
                and R not in post_acute_care_cases
                and R not in hospice_care_cases
        )
    }
)

-- 有14日內再住院的病患
define patients_with_14day_readmission AS (
    readmissions_within_14_days R
    where exists(R.readmission_encounters)
    return {
        patient_id: R.patient_id,
        discharge_encounter_id: R.discharge_encounter_id,
        discharge_date: R.discharge_date,
        readmission_count: Count(R.readmission_encounters),
        first_readmission_date: First(R.readmission_encounters).period.start,
        days_to_readmission: days between R.discharge_date and First(R.readmission_encounters).period.start
    }
)

-- ==================== 分母計算 (Denominator) ====================

-- 分母：當季出院人數（排除計畫性再住院案件）
define denominator_discharge_patients AS (
    SELECT 
        COUNT(DISTINCT patient_id) as unique_patient_count,
        COUNT(*) as total_discharge_count
    FROM 
        unplanned_discharges
)

-- 按季度統計分母
define denominator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        start_date: Q.start_date,
        end_date: Q.end_date,
        discharge_patient_count: Count(
            unplanned_discharges D
            where D.period.end >= Q.start_date and D.period.end <= Q.end_date
            return distinct D.subject.reference
        ),
        total_discharge_count: Count(
            unplanned_discharges D
            where D.period.end >= Q.start_date and D.period.end <= Q.end_date
        )
    }
)

-- 年度統計分母
define denominator_annual AS (
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        start_date: annual_period.start_date,
        end_date: annual_period.end_date,
        discharge_patient_count: Count(
            unplanned_discharges D
            where D.period.end >= annual_period.start_date 
                and D.period.end <= annual_period.end_date
            return distinct D.subject.reference
        ),
        total_discharge_count: Count(
            unplanned_discharges D
            where D.period.end >= annual_period.start_date 
                and D.period.end <= annual_period.end_date
        )
    }
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子：病人14日再住院人數
define numerator_14day_readmission_patients AS (
    SELECT 
        COUNT(DISTINCT patient_id) as readmission_patient_count,
        COUNT(*) as total_readmission_count
    FROM 
        patients_with_14day_readmission
)

-- 按季度統計分子
define numerator_by_quarter AS (
    quarters Q
    return {
        quarter_id: Q.id,
        quarter_label: Q.label,
        readmission_patient_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= Q.start_date and P.discharge_date <= Q.end_date
            return distinct P.patient_id
        ),
        total_readmission_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= Q.start_date and P.discharge_date <= Q.end_date
        )
    }
)

-- 年度統計分子
define numerator_annual AS (
    {
        period_id: annual_period.id,
        period_label: annual_period.label,
        readmission_patient_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= annual_period.start_date 
                and P.discharge_date <= annual_period.end_date
            return distinct P.patient_id
        ),
        total_readmission_count: Count(
            patients_with_14day_readmission P
            where P.discharge_date >= annual_period.start_date 
                and P.discharge_date <= annual_period.end_date
        )
    }
)

-- ==================== 指標計算 (Indicator Calculation) ====================

-- 按季度計算14日內再住院率
define indicator_by_quarter AS (
    (numerator_by_quarter N join denominator_by_quarter D on N.quarter_id = D.quarter_id)
    return {
        indicator_code: "Indicator_1077_01",
        quarter_id: N.quarter_id,
        quarter_label: N.quarter_label,
        numerator: N.readmission_patient_count,
        denominator: D.discharge_patient_count,
        rate: if D.discharge_patient_count > 0 
              then Round((N.readmission_patient_count / D.discharge_patient_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((N.readmission_patient_count / D.discharge_patient_count) * 100, 2)) + '%'
    }
)

-- 年度計算14日內再住院率
define indicator_annual AS (
    {
        indicator_code: "Indicator_1809",
        period_label: numerator_annual.period_label,
        numerator: numerator_annual.readmission_patient_count,
        denominator: denominator_annual.discharge_patient_count,
        rate: if denominator_annual.discharge_patient_count > 0 
              then Round((numerator_annual.readmission_patient_count / denominator_annual.discharge_patient_count) * 100, 2)
              else 0,
        rate_display: ToString(Round((numerator_annual.readmission_patient_count / denominator_annual.discharge_patient_count) * 100, 2)) + '%'
    }
)

-- ==================== 綜合結果 ====================

-- 所有期間的指標結果
define all_periods_results AS (
    indicator_by_quarter 
    union 
    { indicator_annual }
)

-- ==================== 進階分析 ====================

-- 高風險再住院病患分析
define high_risk_readmission_patients AS (
    patients_with_14day_readmission P
    where P.readmission_count > 1
        or P.days_to_readmission <= 7
    return {
        patient_id: P.patient_id,
        discharge_date: P.discharge_date,
        readmission_count: P.readmission_count,
        days_to_readmission: P.days_to_readmission,
        risk_level: if P.days_to_readmission <= 3 then '極高風險'
                    else if P.days_to_readmission <= 7 then '高風險'
                    else if P.readmission_count > 1 then '多次再住院'
                    else '中度風險'
    }
)

-- 再住院天數分布分析
define readmission_days_distribution AS (
    patients_with_14day_readmission P
    return {
        days_category: if P.days_to_readmission <= 3 then '0-3天'
                      else if P.days_to_readmission <= 7 then '4-7天'
                      else if P.days_to_readmission <= 10 then '8-10天'
                      else '11-14天',
        patient_count: Count(P)
    }
    group by days_category
)

-- ==================== 主要輸出 ====================

/*
 * 主要指標結果
 * 包含季度和年度的14日內再住院率
 */
define "Main Output" AS (
    all_periods_results
)

/*
 * 詳細病患清單
 * 14日內再住院的病患明細
 */
define "Detailed Patient List" AS (
    patients_with_14day_readmission
)

/*
 * 高風險病患清單
 * 需要特別關注的再住院病患
 */
define "High Risk Patients" AS (
    high_risk_readmission_patients
)
