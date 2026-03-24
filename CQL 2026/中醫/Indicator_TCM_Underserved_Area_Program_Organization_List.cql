/**
 * 指標名稱: 參與醫療資源不足地區改善方案之院所名單
 * 指標類別: 中醫照護品質指標 - 組織名單
 * 計算頻率: 每季
 * 
 * 指標定義: 參與醫療資源不足地區改善方案之中醫特約醫事服務機構
 * 
 * 資料範圍: 
 * - 參與健保署「醫療資源不足地區改善方案」的中醫醫療機構
 * - 提供醫療資源不足地區民眾中醫醫療服務
 * - 經健保署核定參與該方案的醫療機構
 * 
 * 說明: 此為組織名單指標，不計算分子分母，僅列出參與機構清單及相關統計資訊
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_TCM_Underserved_Area_Program_Organization_List version '1.0.0'

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

// 醫療資源不足地區案件分類（案件分類25的子類別）
define "Underserved Area Case Classification":
  { '25' }  // 中醫診療總額醫療資源不足地區改善方案

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

// 取得Organization的參與方案資訊
define function IsParticipatingInUnderservedAreaProgram(org Organization):
  GetExtensionBoolean(org, 'participateInUnderservedAreaProgram') = true

// 取得Organization的方案核准日期
define function GetProgramApprovalDate(org Organization):
  GetExtensionString(org, 'underservedAreaProgramApprovalDate')

// 取得Organization服務的醫療資源不足地區
define function GetUnderservedAreaCode(org Organization):
  GetExtensionString(org, 'underservedAreaCode')

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

// 取得Organization地址
define function GetOrganizationAddress(org Organization):
  if org.address is not null and Count(org.address) > 0
  then org.address[0].text.value
  else null

// 取得Organization電話
define function GetOrganizationPhone(org Organization):
  if org.telecom is not null
  then (
    singleton from (
      org.telecom T where T.system.value = 'phone'
    )
  ).value.value
  else null

// 取得Encounter的案件分類
define function GetEncounterCaseType(encounter Encounter):
  if encounter.type is not null and Count(encounter.type) > 0
  and encounter.type[0].coding is not null and Count(encounter.type[0].coding) > 0
  then encounter.type[0].coding[0].code.value
  else null

// ========================================================================================
// 主要邏輯
// ========================================================================================

// 觀察期間
define "Measurement Period": 
  Interval[MeasurementPeriodStart, MeasurementPeriodEnd]

// 所有醫療機構
define "All Organizations":
  [Organization] O
  where O.active.value = true

// 觀察期間內提供醫療資源不足地區服務的Encounter
define "Underserved Area Service Encounters":
  [Encounter] E
  where E.period during "Measurement Period"
  and E.status.value = 'finished'
  and GetEncounterCaseType(E) in "Underserved Area Case Classification"
  and exists (
    E.type T
    where exists (
      T.coding C
      where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'
      and C.code.value = '05'
    )
  )

// 提供醫療資源不足地區服務的機構（基於實際服務記錄）
define "Organizations Serving Underserved Areas":
  distinct (
    "Underserved Area Service Encounters" E
    return singleton from ([Organization] O where 'Organization/' + O.id = E.serviceProvider.reference.value)
  )

// 參與醫療資源不足地區改善方案的醫療機構
define "Underserved Area Program Participating Organizations":
  "Organizations Serving Underserved Areas" O
  where IsParticipatingInUnderservedAreaProgram(O) or 
        exists (
          "Underserved Area Service Encounters" E
          where 'Organization/' + O.id = E.serviceProvider.reference.value
        )
  return {
    organizationId: 'Organization/' + O.id,
    organizationName: GetOrganizationName(O),
    organizationType: GetOrganizationType(O),
    region: GetOrganizationRegion(O),
    underservedAreaCode: GetUnderservedAreaCode(O),
    address: GetOrganizationAddress(O),
    phone: GetOrganizationPhone(O),
    approvalDate: GetProgramApprovalDate(O),
    isActive: O.active.value
  }

// 參與機構總數
define "Total Participating Organizations":
  Count("Underserved Area Program Participating Organizations")

// ========================================================================================
// 分層分析
// ========================================================================================

// 依分區別統計
define "Participating Organizations By Region":
  distinct (
    "Underserved Area Program Participating Organizations" O return O.region
  ) Region
  let regionCount: Count(
        "Underserved Area Program Participating Organizations" O 
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
    "Underserved Area Program Participating Organizations" O return O.organizationType
  ) OrgType
  let typeCount: Count(
        "Underserved Area Program Participating Organizations" O 
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

// 依醫療資源不足地區代碼統計
define "Participating Organizations By Underserved Area":
  distinct (
    "Underserved Area Program Participating Organizations" O return O.underservedAreaCode
  ) AreaCode
  let areaCount: Count(
        "Underserved Area Program Participating Organizations" O 
        where O.underservedAreaCode = AreaCode
      )
  return {
    underservedAreaCode: AreaCode,
    organizationCount: areaCount,
    percentage: if "Total Participating Organizations" > 0
                then Round((areaCount / "Total Participating Organizations") * 100.0, 2)
                else null
  }
  sort by organizationCount desc

// 機構詳細名冊（依分區別、機構名稱排序）
define "Detailed Organization List":
  "Underserved Area Program Participating Organizations" O
  return {
    organizationId: O.organizationId,
    organizationName: O.organizationName,
    organizationType: O.organizationType,
    region: O.region,
    underservedAreaCode: O.underservedAreaCode,
    address: O.address,
    phone: O.phone,
    approvalDate: O.approvalDate,
    status: if O.isActive then '正常服務' else '停止服務'
  }
  sort by region, organizationName

// 服務量統計（參與方案的機構在觀察期間的服務量）
define "Service Volume Statistics":
  "Underserved Area Program Participating Organizations" PO
  let encounterCount: Count(
        "Underserved Area Service Encounters" E
        where E.serviceProvider.reference.value = PO.organizationId
      ),
      patientCount: Count(
        distinct (
          "Underserved Area Service Encounters" E
          where E.serviceProvider.reference.value = PO.organizationId
          return E.subject.reference.value
        )
      ),
      totalTCMEncounters: Count(
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
      )
  return {
    organizationId: PO.organizationId,
    organizationName: PO.organizationName,
    region: PO.region,
    underservedAreaCode: PO.underservedAreaCode,
    underservedAreaEncounters: encounterCount,
    underservedAreaPatients: patientCount,
    totalTCMEncounters: totalTCMEncounters,
    underservedAreaPercentage: if totalTCMEncounters > 0
                               then Round((encounterCount / totalTCMEncounters) * 100.0, 2)
                               else null,
    avgEncountersPerPatient: if patientCount > 0
                             then Round(encounterCount / patientCount, 2)
                             else null
  }
  sort by underservedAreaEncounters desc

// 服務量總覽
define "Service Volume Overview":
  {
    participatingOrganizations: "Total Participating Organizations",
    totalUnderservedAreaEncounters: Sum("Service Volume Statistics" S return S.underservedAreaEncounters),
    totalUnderservedAreaPatients: Sum("Service Volume Statistics" S return S.underservedAreaPatients),
    totalTCMEncounters: Sum("Service Volume Statistics" S return S.totalTCMEncounters),
    underservedAreaServicePercentage: if Sum("Service Volume Statistics" S return S.totalTCMEncounters) > 0
                                      then Round((Sum("Service Volume Statistics" S return S.underservedAreaEncounters) / Sum("Service Volume Statistics" S return S.totalTCMEncounters)) * 100.0, 2)
                                      else null,
    avgUnderservedEncountersPerOrganization: if "Total Participating Organizations" > 0
                                             then Round(Sum("Service Volume Statistics" S return S.underservedAreaEncounters) / "Total Participating Organizations", 2)
                                             else null,
    avgUnderservedPatientsPerOrganization: if "Total Participating Organizations" > 0
                                           then Round(Sum("Service Volume Statistics" S return S.underservedAreaPatients) / "Total Participating Organizations", 2)
                                           else null
  }

// 月度服務趨勢
define "Monthly Service Trend":
  "Underserved Area Service Encounters" E
  return {
    encounterId: 'Encounter/' + E.id,
    periodStart: E.period.start
  }

// 月度統計
define "Monthly Statistics":
  distinct (
    "Monthly Service Trend" T return T.encounterId
  )

// ========================================================================================
// 最終輸出
// ========================================================================================

define "Final Output":
  {
    indicatorName: '參與醫療資源不足地區改善方案之院所名單',
    indicatorType: '組織名單指標（無分子分母）',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    totalParticipatingOrganizations: "Total Participating Organizations",
    organizationList: "Detailed Organization List",
    regionalDistribution: "Participating Organizations By Region",
    typeDistribution: "Participating Organizations By Type",
    underservedAreaDistribution: "Participating Organizations By Underserved Area",
    serviceVolumeOverview: "Service Volume Overview",
    topServiceProviders: "Service Volume Statistics",
    monthlyTrend: "Monthly Statistics",
    dataSource: '參與健保署醫療資源不足地區改善方案的中醫特約醫事服務機構（案件分類25）',
    note: '此指標為組織名單，列出所有參與醫療資源不足地區改善方案的中醫醫療機構及其服務統計'
  }
