library Indicator_04_Chronic_Continuous_Prescription_Rate_1318 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 慢性病連續處方箋開立率
// 指標代碼: 1318
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
// 分子: 開立慢性病連續處方箋件數
// 分母: 慢性病案件數
//
// 慢性病案件條件:
// (1)診察費項目代碼為慢性病代碼(51個代碼)
// (2)案件分類=04、E1
//
// 開立慢性病連續處方箋的條件:
// (1)診察費項目代碼為慢性病代碼
// (2)案件分類=E1且慢性病連續處方箋有效期間處方日份 > 給藥天數且慢性病連續處方箋有效日份為給藥天數的倍數
//
// 排除條件:
// (1)排除代辦案件
// (2)排除婦產科專科醫院(醫院型態別=03，且日門診婦產科(05)之申請點數占全科別最高者)
// (3)排除小兒科專科醫院(醫院型態別=03，且日門診小兒科(04)之申請點數占全科別最高者)
// (4)排除呼吸照護病房申請點數≧80%之醫院(有申請P1011C或P1012C令碼，且申請點數占全院申請點數80%(含)以上之醫院)
// ============================================

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes/procedure'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "EncounterStatus": 'http://hl7.org/fhir/encounter-status'
codesystem "MedicationRequestStatus": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'
codesystem "MedicationRequestIntent": 'http://hl7.org/fhir/CodeSystem/medicationrequest-intent'

valueset "Chronic Consultation Codes": 'http://nhi.gov.tw/fhir/ValueSet/chronic-consultation-codes'

code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory'
code "Outpatient": 'O' from "ActCode" display 'Outpatient'
code "Finished": 'finished' from "EncounterStatus" display 'Finished'
code "Active": 'active' from "MedicationRequestStatus" display 'Active'
code "Completed": 'completed' from "MedicationRequestStatus" display 'Completed'

// 慢性病診察費代碼 (51個)
code "00155A": '00155A' from "NHI_PROCEDURE" display '慢性病診察費155A'
code "00157A": '00157A' from "NHI_PROCEDURE" display '慢性病診察費157A'
code "00170A": '00170A' from "NHI_PROCEDURE" display '慢性病診察費170A'
code "00171A": '00171A' from "NHI_PROCEDURE" display '慢性病診察費171A'
code "00131B": '00131B' from "NHI_PROCEDURE" display '慢性病診察費131B'
code "00132B": '00132B' from "NHI_PROCEDURE" display '慢性病診察費132B'
code "00172B": '00172B' from "NHI_PROCEDURE" display '慢性病診察費172B'
code "00173B": '00173B' from "NHI_PROCEDURE" display '慢性病診察費173B'
code "00135B": '00135B' from "NHI_PROCEDURE" display '慢性病診察費135B'
code "00136B": '00136B' from "NHI_PROCEDURE" display '慢性病診察費136B'
code "00174B": '00174B' from "NHI_PROCEDURE" display '慢性病診察費174B'
code "00175B": '00175B' from "NHI_PROCEDURE" display '慢性病診察費175B'
code "00137B": '00137B' from "NHI_PROCEDURE" display '慢性病診察費137B'
code "00138B": '00138B' from "NHI_PROCEDURE" display '慢性病診察費138B'
code "00176B": '00176B' from "NHI_PROCEDURE" display '慢性病診察費176B'
code "00177B": '00177B' from "NHI_PROCEDURE" display '慢性病診察費177B'
code "00139C": '00139C' from "NHI_PROCEDURE" display '慢性病診察費139C'
code "00140C": '00140C' from "NHI_PROCEDURE" display '慢性病診察費140C'
code "00158C": '00158C' from "NHI_PROCEDURE" display '慢性病診察費158C'
code "00159C": '00159C' from "NHI_PROCEDURE" display '慢性病診察費159C'
code "00141C": '00141C' from "NHI_PROCEDURE" display '慢性病診察費141C'
code "00142C": '00142C' from "NHI_PROCEDURE" display '慢性病診察費142C'
code "00160C": '00160C' from "NHI_PROCEDURE" display '慢性病診察費160C'
code "00161C": '00161C' from "NHI_PROCEDURE" display '慢性病診察費161C'
code "00143C": '00143C' from "NHI_PROCEDURE" display '慢性病診察費143C'
code "00144C": '00144C' from "NHI_PROCEDURE" display '慢性病診察費144C'
code "00162C": '00162C' from "NHI_PROCEDURE" display '慢性病診察費162C'
code "00163C": '00163C' from "NHI_PROCEDURE" display '慢性病診察費163C'
code "00145C": '00145C' from "NHI_PROCEDURE" display '慢性病診察費145C'
code "00146C": '00146C' from "NHI_PROCEDURE" display '慢性病診察費146C'
code "00164C": '00164C' from "NHI_PROCEDURE" display '慢性病診察費164C'
code "00165C": '00165C' from "NHI_PROCEDURE" display '慢性病診察費165C'
code "00147C": '00147C' from "NHI_PROCEDURE" display '慢性病診察費147C'
code "00148C": '00148C' from "NHI_PROCEDURE" display '慢性病診察費148C'
code "00166C": '00166C' from "NHI_PROCEDURE" display '慢性病診察費166C'
code "00167C": '00167C' from "NHI_PROCEDURE" display '慢性病診察費167C'
code "00149C": '00149C' from "NHI_PROCEDURE" display '慢性病診察費149C'
code "00150C": '00150C' from "NHI_PROCEDURE" display '慢性病診察費150C'
code "00168C": '00168C' from "NHI_PROCEDURE" display '慢性病診察費168C'
code "00169C": '00169C' from "NHI_PROCEDURE" display '慢性病診察費169C'
code "00178B": '00178B' from "NHI_PROCEDURE" display '慢性病診察費178B'
code "00179B": '00179B' from "NHI_PROCEDURE" display '慢性病診察費179B'
code "00180B": '00180B' from "NHI_PROCEDURE" display '慢性病診察費180B'
code "00181B": '00181B' from "NHI_PROCEDURE" display '慢性病診察費181B'
code "00182C": '00182C' from "NHI_PROCEDURE" display '慢性病診察費182C'
code "00183C": '00183C' from "NHI_PROCEDURE" display '慢性病診察費183C'
code "00184C": '00184C' from "NHI_PROCEDURE" display '慢性病診察費184C'
code "00185C": '00185C' from "NHI_PROCEDURE" display '慢性病診察費185C'
code "00187C": '00187C' from "NHI_PROCEDURE" display '慢性病診察費187C'
code "00189C": '00189C' from "NHI_PROCEDURE" display '慢性病診察費189C'
code "00190C": '00190C' from "NHI_PROCEDURE" display '慢性病診察費190C'
code "00191C": '00191C' from "NHI_PROCEDURE" display '慢性病診察費191C'

code "Chronic Prescription": '04' from "NHI_PROCEDURE" display 'Chronic Disease Prescription - 慢性病處方'
code "Chronic Continuous Prescription": 'E1' from "NHI_PROCEDURE" display 'Chronic Disease Continuous Prescription - 慢性病連續處方'

code "Pediatrics": '04' from "NHI_PROCEDURE" display 'Pediatrics - 小兒科'
code "Obstetrics and Gynecology": '05' from "NHI_PROCEDURE" display 'Obstetrics and Gynecology - 婦產科'

code "Respiratory Care Ward 1": 'P1011C' from "NHI_PROCEDURE" display 'Respiratory Care Ward - 呼吸照護病房(P1011C)'
code "Respiratory Care Ward 2": 'P1012C' from "NHI_PROCEDURE" display 'Respiratory Care Ward - 呼吸照護病房(P1012C)'

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

define function IsChronicConsultationCode(code String):
  code in {
    '00155A', '00157A', '00170A', '00171A', '00131B', '00132B', '00172B', '00173B',
    '00135B', '00136B', '00174B', '00175B', '00137B', '00138B', '00176B', '00177B',
    '00139C', '00140C', '00158C', '00159C', '00141C', '00142C', '00160C', '00161C',
    '00143C', '00144C', '00162C', '00163C', '00145C', '00146C', '00164C', '00165C',
    '00147C', '00148C', '00166C', '00167C', '00149C', '00150C', '00168C', '00169C',
    '00178B', '00179B', '00180B', '00181B', '00182C', '00183C', '00184C', '00185C',
    '00187C', '00189C', '00190C', '00191C'
  }

define function IsChronicClaimType(claimType String):
  claimType in { '04', 'E1' }

define function GetClaimType(encounter FHIR.Encounter):
  Coalesce(
    First(
      encounter.type T
        return First(T.coding C where C.system = 'http://www.nhi.gov.tw/codes/claim-type').code.value
    ),
    ''
  )

define function GetOrganizationId(encounter FHIR.Encounter):
  if encounter.serviceProvider is not null then
    GetId(encounter.serviceProvider.reference)
  else ''

define function IsAgencyCase(encounter FHIR.Encounter):
  exists (
    encounter.extension E
      where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
        and E.value = true
  )

define function HasChronicConsultation(encounter FHIR.Encounter):
  exists (
    [Procedure] P
      where GetId(P.encounter.reference) = GetId(encounter)
        and exists (
          P.code.coding C
            where C.system.value = 'http://www.nhi.gov.tw/codes/procedure'
              and IsChronicConsultationCode(C.code.value)
        )
  )

define function IsContinuousPrescription(encounter FHIR.Encounter):
  HasChronicConsultation(encounter)
    or (
      GetClaimType(encounter) = 'E1'
      and exists (
        [MedicationRequest] MR
          where GetId(MR.encounter.reference) = GetId(encounter)
            and MR.dispenseRequest.validityPeriod is not null
            and MR.dispenseRequest.expectedSupplyDuration is not null
            and MR.dispenseRequest.validityPeriod.start.value < MR.dispenseRequest.validityPeriod.end.value
      )
    )

// ============================================
// Data Retrieval
// ============================================

context Patient

define "Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and start of E.period in "Measurement Period"
      and not IsAgencyCase(E)

define "Chronic Disease Cases":
  "Outpatient Encounters" E
    where HasChronicConsultation(E)
      or IsChronicClaimType(GetClaimType(E))

define "Chronic Continuous Prescription Cases":
  "Chronic Disease Cases" E
    where IsContinuousPrescription(E)

// ============================================
// 2024Q1 Statistics
// ============================================

define "2024Q1 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2024Q1 Start", "2024Q1 End"]

define "2024Q1 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2024Q1 Start", "2024Q1 End"]

define "2024Q1 Denominator":
  Count("2024Q1 Chronic Cases")

define "2024Q1 Numerator":
  Count("2024Q1 Continuous Prescription Cases")

define "2024Q1 Rate":
  if "2024Q1 Denominator" > 0 then
    ("2024Q1 Numerator" / "2024Q1 Denominator") * 100
  else null

// ============================================
// 2024Q2 Statistics
// ============================================

define "2024Q2 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2024Q2 Start", "2024Q2 End"]

define "2024Q2 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2024Q2 Start", "2024Q2 End"]

define "2024Q2 Denominator":
  Count("2024Q2 Chronic Cases")

define "2024Q2 Numerator":
  Count("2024Q2 Continuous Prescription Cases")

define "2024Q2 Rate":
  if "2024Q2 Denominator" > 0 then
    ("2024Q2 Numerator" / "2024Q2 Denominator") * 100
  else null

// ============================================
// 2024Q3 Statistics
// ============================================

define "2024Q3 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2024Q3 Start", "2024Q3 End"]

define "2024Q3 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2024Q3 Start", "2024Q3 End"]

define "2024Q3 Denominator":
  Count("2024Q3 Chronic Cases")

define "2024Q3 Numerator":
  Count("2024Q3 Continuous Prescription Cases")

define "2024Q3 Rate":
  if "2024Q3 Denominator" > 0 then
    ("2024Q3 Numerator" / "2024Q3 Denominator") * 100
  else null

// ============================================
// 2024Q4 Statistics
// ============================================

define "2024Q4 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2024Q4 Start", "2024Q4 End"]

define "2024Q4 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2024Q4 Start", "2024Q4 End"]

define "2024Q4 Denominator":
  Count("2024Q4 Chronic Cases")

define "2024Q4 Numerator":
  Count("2024Q4 Continuous Prescription Cases")

define "2024Q4 Rate":
  if "2024Q4 Denominator" > 0 then
    ("2024Q4 Numerator" / "2024Q4 Denominator") * 100
  else null

// ============================================
// 2025Q1 Statistics
// ============================================

define "2025Q1 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2025Q1 Start", "2025Q1 End"]

define "2025Q1 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2025Q1 Start", "2025Q1 End"]

define "2025Q1 Denominator":
  Count("2025Q1 Chronic Cases")

define "2025Q1 Numerator":
  Count("2025Q1 Continuous Prescription Cases")

define "2025Q1 Rate":
  if "2025Q1 Denominator" > 0 then
    ("2025Q1 Numerator" / "2025Q1 Denominator") * 100
  else null

// ============================================
// 2025Q2 Statistics
// ============================================

define "2025Q2 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2025Q2 Start", "2025Q2 End"]

define "2025Q2 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2025Q2 Start", "2025Q2 End"]

define "2025Q2 Denominator":
  Count("2025Q2 Chronic Cases")

define "2025Q2 Numerator":
  Count("2025Q2 Continuous Prescription Cases")

define "2025Q2 Rate":
  if "2025Q2 Denominator" > 0 then
    ("2025Q2 Numerator" / "2025Q2 Denominator") * 100
  else null

// ============================================
// 2025Q3 Statistics
// ============================================

define "2025Q3 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2025Q3 Start", "2025Q3 End"]

define "2025Q3 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2025Q3 Start", "2025Q3 End"]

define "2025Q3 Denominator":
  Count("2025Q3 Chronic Cases")

define "2025Q3 Numerator":
  Count("2025Q3 Continuous Prescription Cases")

define "2025Q3 Rate":
  if "2025Q3 Denominator" > 0 then
    ("2025Q3 Numerator" / "2025Q3 Denominator") * 100
  else null

// ============================================
// 2025Q4 Statistics
// ============================================

define "2025Q4 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2025Q4 Start", "2025Q4 End"]

define "2025Q4 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2025Q4 Start", "2025Q4 End"]

define "2025Q4 Denominator":
  Count("2025Q4 Chronic Cases")

define "2025Q4 Numerator":
  Count("2025Q4 Continuous Prescription Cases")

define "2025Q4 Rate":
  if "2025Q4 Denominator" > 0 then
    ("2025Q4 Numerator" / "2025Q4 Denominator") * 100
  else null

// ============================================
// 2026Q1 Statistics
// ============================================

define "2026Q1 Chronic Cases":
  "Chronic Disease Cases" E
    where start of E.period in Interval["2026Q1 Start", "2026Q1 End"]

define "2026Q1 Continuous Prescription Cases":
  "Chronic Continuous Prescription Cases" E
    where start of E.period in Interval["2026Q1 Start", "2026Q1 End"]

define "2026Q1 Denominator":
  Count("2026Q1 Chronic Cases")

define "2026Q1 Numerator":
  Count("2026Q1 Continuous Prescription Cases")

define "2026Q1 Rate":
  if "2026Q1 Denominator" > 0 then
    ("2026Q1 Numerator" / "2026Q1 Denominator") * 100
  else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  {
    indicatorCode: '1318',
    indicatorName: '慢性病連續處方箋開立率',
    indicatorNameEn: 'Chronic Disease Continuous Prescription Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    dataSource: '醫療給付檔案分析系統',
    compiledBy: '衛生福利部 中央健康保險署',
    compiledDate: '114/11/06',
    version: '1.0.0',
    chronicConsultationCodes: 51,
    keyFeature: '慢性病連續處方箋開立率分析 (51個診察費代碼, 案件分類04/E1)'
  }
