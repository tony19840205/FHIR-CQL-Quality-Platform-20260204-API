/**
 * 指標名稱: 「小兒腦性麻痺中醫優質門診照護試辦計畫」參與院所名冊
 * 指標類別: 中醫照護品質指標 - 組織名單
 * 計算頻率: 每季
 * 
 * 指標定義: 參與「小兒腦性麻痺中醫優質門診照護試辦計畫」中醫特約醫事服務機構
 * 
 * 資料範圍: 
 * - 設有中醫門診之醫院且領有「中醫師公會全國聯合會」所辦理講習會之繼續教育說明的中醫師
 * - 向「中華民國中醫師公會全國聯合會」提出申請
 * - 經審查通過後，與健保署轄區分區治商辦理本試辦計畫服務
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_TCM_Pediatric_Cerebral_Palsy_Program_Organization_List version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "TWCaseType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
codesystem "TWOrganizationType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/organization-type'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// ========================================================================================
// 參數定義
// ========================================================================================

parameter MeasurementPeriodStart DateTime default @2026-01-01T00:00:00.0+08:00
parameter MeasurementPeriodEnd DateTime default @2026-03-31T23:59:59.0+08:00

// ========================================================================================
// 值集定義
// ========================================================================================

// 中醫門診案件類型碼
define "TCM Outpatient Case Type": 
  Code { code: '05', system: 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type', display: '中醫門診' }

// 小兒腦性麻痺照護計畫代碼（假設使用特定計畫代碼）
define "Pediatric Cerebral Palsy Program Codes": 
  { 'TCMCP01', 'TCMCP02', 'TCMCP03' }  // 實際代碼需依健保署規定

// ========================================================================================
// 輔助函數
// ========================================================================================

// 取得Extension值
define function GetExtensionString(element FHIR.Organization, url String):
  (
    singleton from (
      element.extension E where E.url.value = url
    ).value.value
  ) as String

// 取得Extension布林值
define function GetExtensionBoolean(element FHIR.Organization, url String):
  (
    singleton from (
      element.extension E where E.url.value = url
    ).value.value
  ) as Boolean

// 取得Organization的參與計畫資訊
define function IsParticipatingInPediatricCerebralPalsyProgram(org Organization):
  GetExtensionBoolean(org, 'participateInPediatricCerebralPalsyProgram') = true

// 取得Organization的中醫師認證資訊
define function HasCertifiedTCMPhysician(org Organization):
  GetExtensionBoolean(org, 'hasCertifiedTCMPhysician') = true

// 取得Organization的計畫核准日期
define function GetProgramApprovalDate(org Organization):
  GetExtensionString(org, 'pediatricCerebralPalsyProgramApprovalDate')

// 取得Organization的分區
define function GetOrganizationRegion(org Organization):
  GetExtensionString(org, 'nhiaRegion')

// 取得Organization名稱
define function GetOrganizationName(org Organization):
  if org.name is not null
  then org.name.value
  else null

// 取得Organization類型
define function GetOrganizationType(org Organization):
  if org.type is not null and Count(org.type) > 0
  then (org.type[0].coding[0].code.value)
  else null

// 檢查是否為醫院
define function IsHospital(orgType String):
  orgType in { 'HOSP', 'HOSPITAL', 'MEDICAL_CENTER', 'REGIONAL_HOSPITAL', 'DISTRICT_HOSPITAL' }

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 觀察期間內有服務的Organization
define "Active Organizations During Measurement Period":
  distinct (
    [Encounter] E
    where E.period during "Measurement Period"
    and E.status.value = 'finished'
    return singleton from ([Organization] O where 'Organization/' + O.id = E.serviceProvider.reference.value)
  )

// 所有醫療機構
define "All Organizations":
  [Organization] O
  where O.active.value = true

// 設有中醫門診的醫院
define "Hospitals With TCM Outpatient":
  "All Organizations" O
  let orgType: GetOrganizationType(O),
      hasTCMService: exists (
        [Encounter] E
        where 'Organization/' + O.id = E.serviceProvider.reference.value
        and E.period during "Measurement Period"
        and exists (
          E.type T
          where exists (
            T.coding C
            where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
            and C.code.value = '05'
          )
        )
      )
  where IsHospital(orgType)
  and hasTCMService
  return O

// 參與小兒腦性麻痺中醫優質門診照護試辦計畫的醫療機構
define "Pediatric Cerebral Palsy Program Participating Organizations":
  "Hospitals With TCM Outpatient" O
  where IsParticipatingInPediatricCerebralPalsyProgram(O)
  and HasCertifiedTCMPhysician(O)
  return {
    organizationId: 'Organization/' + O.id,
    organizationName: GetOrganizationName(O),
    organizationType: GetOrganizationType(O),
    region: GetOrganizationRegion(O),
    approvalDate: GetProgramApprovalDate(O),
    isActive: O.active.value
  }

// 參與機構總數
define "Total Participating Organizations":
  Count("Pediatric Cerebral Palsy Program Participating Organizations")

// ========================================================================================
// 分層分析
// ========================================================================================

// 依分區別統計
define "Participating Organizations By Region":
  distinct (
    "Pediatric Cerebral Palsy Program Participating Organizations" O return O.region
  ) Region
  let regionCount: Count(
        "Pediatric Cerebral Palsy Program Participating Organizations" O 
        where O.region = Region
      )
  return {
    region: Region,
    organizationCount: regionCount,
    percentage: if "Total Participating Organizations" > 0
                then Round((regionCount / "Total Participating Organizations") * 100.0, 2)
                else null
  }
  sort by organizationCount desc

// 依機構類型統計
define "Participating Organizations By Type":
  distinct (
    "Pediatric Cerebral Palsy Program Participating Organizations" O return O.organizationType
  ) OrgType
  let typeCount: Count(
        "Pediatric Cerebral Palsy Program Participating Organizations" O 
        where O.organizationType = OrgType
      )
  return {
    organizationType: OrgType,
    organizationCount: typeCount,
    percentage: if "Total Participating Organizations" > 0
                then Round((typeCount / "Total Participating Organizations") * 100.0, 2)
                else null
  }
  sort by organizationCount desc

// 依核准年度統計
define "Participating Organizations By Approval Year":
  "Pediatric Cerebral Palsy Program Participating Organizations" O
  let approvalYear: if O.approvalDate is not null
                    then Substring(O.approvalDate, 0, 4)
                    else 'Unknown'
  return {
    approvalYear: approvalYear,
    organizationId: O.organizationId,
    organizationName: O.organizationName
  }

// 年度統計
define "Approval Year Statistics":
  distinct (
    "Participating Organizations By Approval Year" O return O.approvalYear
  ) Year
  let yearCount: Count(
        "Participating Organizations By Approval Year" O 
        where O.approvalYear = Year
      )
  return {
    approvalYear: Year,
    organizationCount: yearCount,
    percentage: if "Total Participating Organizations" > 0
                then Round((yearCount / "Total Participating Organizations") * 100.0, 2)
                else null
  }
  sort by approvalYear desc

// 機構詳細名冊（依分區別排序）
define "Detailed Organization List By Region":
  "Pediatric Cerebral Palsy Program Participating Organizations" O
  return {
    organizationId: O.organizationId,
    organizationName: O.organizationName,
    organizationType: O.organizationType,
    region: O.region,
    approvalDate: O.approvalDate,
    status: if O.isActive then '正常服務' else '停止服務'
  }
  sort by region, organizationName

// 服務量統計（參與計畫的機構在觀察期間的服務量）
define "Service Volume Statistics":
  "Pediatric Cerebral Palsy Program Participating Organizations" PO
  let encounterCount: Count(
        [Encounter] E
        where E.serviceProvider.reference.value = PO.organizationId
        and E.period during "Measurement Period"
        and exists (
          E.type T
          where exists (
            T.coding C
            where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
            and C.code.value = '05'
          )
        )
      ),
      patientCount: Count(
        distinct (
          [Encounter] E
          where E.serviceProvider.reference.value = PO.organizationId
          and E.period during "Measurement Period"
          and exists (
            E.type T
            where exists (
              T.coding C
              where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
              and C.code.value = '05'
            )
          )
          return E.subject.reference.value
        )
      )
  return {
    organizationId: PO.organizationId,
    organizationName: PO.organizationName,
    region: PO.region,
    totalEncounters: encounterCount,
    totalPatients: patientCount,
    avgEncountersPerPatient: if patientCount > 0
                             then Round(encounterCount / patientCount, 2)
                             else null
  }
  sort by totalEncounters desc

// 服務量總覽
define "Service Volume Overview":
  {
    participatingOrganizations: "Total Participating Organizations",
    totalEncounters: Sum("Service Volume Statistics" S return S.totalEncounters),
    totalPatients: Sum("Service Volume Statistics" S return S.totalPatients),
    avgEncountersPerOrganization: if "Total Participating Organizations" > 0
                                  then Round(Sum("Service Volume Statistics" S return S.totalEncounters) / "Total Participating Organizations", 2)
                                  else null,
    avgPatientsPerOrganization: if "Total Participating Organizations" > 0
                                then Round(Sum("Service Volume Statistics" S return S.totalPatients) / "Total Participating Organizations", 2)
                                else null
  }

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '「小兒腦性麻痺中醫優質門診照護試辦計畫」參與院所名冊',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    totalParticipatingOrganizations: "Total Participating Organizations",
    organizationList: "Detailed Organization List By Region",
    regionalDistribution: "Participating Organizations By Region",
    typeDistribution: "Participating Organizations By Type",
    approvalYearDistribution: "Approval Year Statistics",
    serviceVolumeOverview: "Service Volume Overview",
    topServiceProviders: "Service Volume Statistics",
    dataSource: '設有中醫門診之醫院，且醫師領有中醫師公會全國聯合會繼續教育證明，經審查通過參與試辦計畫'
  }
