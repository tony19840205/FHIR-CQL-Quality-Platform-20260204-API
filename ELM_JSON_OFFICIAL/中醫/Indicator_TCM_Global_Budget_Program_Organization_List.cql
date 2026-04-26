/**
 * 指標名稱: 參與中醫門診總額所訂計畫或方案之院所名單
 * 指標類別: 中醫照護品質指標 - 組織名單
 * 計算頻率: 每季
 * 
 * 指標定義: 參與中醫門診總額所訂計畫或方案之中醫特約醫事服務機構
 * 
 * 資料範圍: 
 * - 參與中醫門診總額支付制度下各項計畫或方案的醫療機構
 * - 包括但不限於：
 *   1. 小兒氣喘緩解期中醫優質門診照護試辦計畫
 *   2. 小兒腦性麻痺中醫優質門診照護試辦計畫
 *   3. 其他中醫門診總額相關計畫或方案
 * 
 * 說明: 此為組織名單指標，不計算分子分母，僅列出參與機構清單及相關統計資訊
 * 
 * 計算年度: 2026年(民國115年)
 */

library Indicator_TCM_Global_Budget_Program_Organization_List version '1.0.0'

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

// 中醫門診總額計畫類型
define "TCM Global Budget Program Types":
  { 'PEDIATRIC_ASTHMA',           // 小兒氣喘緩解期照護
    'PEDIATRIC_CEREBRAL_PALSY',   // 小兒腦性麻痺照護
    'GERIATRIC_CARE',             // 老人醫療照護
    'CHRONIC_DISEASE',            // 慢性病管理
    'PREVENTIVE_CARE',            // 預防保健
    'SPECIAL_TREATMENT',          // 特殊治療計畫
    'QUALITY_IMPROVEMENT',        // 品質提升方案
    'OTHER_PROGRAM'               // 其他計畫
  }

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

// 取得Extension列表值
define function GetExtensionStringList(element FHIR.Organization, url String):
  element.extension E where E.url.value = url
  return (E.value.value as String)

// 取得Organization參與的計畫列表
define function GetParticipatingPrograms(org Organization):
  GetExtensionStringList(org, 'participatingTCMPrograms')

// 取得Organization的計畫核准日期
define function GetProgramApprovalDate(org Organization):
  GetExtensionString(org, 'tcmProgramApprovalDate')

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

// 檢查Organization是否參與任何中醫門診總額計畫
define function IsParticipatingInTCMProgram(org Organization):
  exists (GetParticipatingPrograms(org))

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

// 設有中醫門診的醫療機構
define "Organizations With TCM Outpatient":
  "All Organizations" O
  let hasTCMService: exists (
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
  where hasTCMService
  return O

// 參與中醫門診總額計畫或方案的醫療機構
define "TCM Program Participating Organizations":
  "Organizations With TCM Outpatient" O
  let programs: GetParticipatingPrograms(O)
  where IsParticipatingInTCMProgram(O)
  return {
    organizationId: 'Organization/' + O.id,
    organizationName: GetOrganizationName(O),
    organizationType: GetOrganizationType(O),
    region: GetOrganizationRegion(O),
    address: GetOrganizationAddress(O),
    phone: GetOrganizationPhone(O),
    participatingPrograms: programs,
    programCount: Count(programs),
    approvalDate: GetProgramApprovalDate(O),
    isActive: O.active.value
  }

// 參與機構總數
define "Total Participating Organizations":
  Count("TCM Program Participating Organizations")

// ========================================================================================
// 分層分析
// ========================================================================================

// 依分區別統計
define "Participating Organizations By Region":
  distinct (
    "TCM Program Participating Organizations" O return O.region
  ) Region
  let regionCount: Count(
        "TCM Program Participating Organizations" O 
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
    "TCM Program Participating Organizations" O return O.organizationType
  ) OrgType
  let typeCount: Count(
        "TCM Program Participating Organizations" O 
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

// 依參與計畫數量統計
define "Organizations By Program Count":
  "TCM Program Participating Organizations" O
  return {
    programCount: O.programCount,
    organizationId: O.organizationId,
    organizationName: O.organizationName
  }

// 計畫數量統計
define "Program Count Statistics":
  distinct (
    "Organizations By Program Count" O return O.programCount
  ) Count
  let countOrgs: Count(
        "Organizations By Program Count" O 
        where O.programCount = Count
      )
  return {
    programCount: Count,
    organizationCount: countOrgs,
    percentage: if "Total Participating Organizations" > 0
                then Round((countOrgs / "Total Participating Organizations") * 100.0, 2)
                else null
  }
  sort by programCount desc

// 依計畫類型統計
define "Program Type Distribution":
  flatten (
    "TCM Program Participating Organizations" O
    return O.participatingPrograms P
    return {
      programType: P,
      organizationId: O.organizationId
    }
  )

// 各計畫參與機構統計
define "Organizations Per Program Type":
  distinct (
    "Program Type Distribution" P return P.programType
  ) ProgramType
  let programOrgs: Count(
        "Program Type Distribution" P 
        where P.programType = ProgramType
      )
  return {
    programType: ProgramType,
    organizationCount: programOrgs,
    percentage: if "Total Participating Organizations" > 0
                then Round((programOrgs / "Total Participating Organizations") * 100.0, 2)
                else null
  }
  sort by organizationCount desc

// 機構詳細名冊（依分區別、機構名稱排序）
define "Detailed Organization List":
  "TCM Program Participating Organizations" O
  return {
    organizationId: O.organizationId,
    organizationName: O.organizationName,
    organizationType: O.organizationType,
    region: O.region,
    address: O.address,
    phone: O.phone,
    participatingPrograms: O.participatingPrograms,
    programCount: O.programCount,
    approvalDate: O.approvalDate,
    status: if O.isActive then '正常服務' else '停止服務'
  }
  sort by region, organizationName

// 多計畫參與機構（參與2個以上計畫的機構）
define "Multi Program Organizations":
  "TCM Program Participating Organizations" O
  where O.programCount >= 2
  return {
    organizationId: O.organizationId,
    organizationName: O.organizationName,
    region: O.region,
    programCount: O.programCount,
    programs: O.participatingPrograms
  }
  sort by programCount desc, organizationName

// 服務量統計（參與計畫的機構在觀察期間的服務量）
define "Service Volume Statistics":
  "TCM Program Participating Organizations" PO
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
    programCount: PO.programCount,
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
    totalPrograms: Sum("TCM Program Participating Organizations" O return O.programCount),
    totalEncounters: Sum("Service Volume Statistics" S return S.totalEncounters),
    totalPatients: Sum("Service Volume Statistics" S return S.totalPatients),
    avgProgramsPerOrganization: if "Total Participating Organizations" > 0
                                then Round(Sum("TCM Program Participating Organizations" O return O.programCount) / "Total Participating Organizations", 2)
                                else null,
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
    indicatorName: '參與中醫門診總額所訂計畫或方案之院所名單',
    indicatorType: '組織名單指標（無分子分母）',
    calculationPeriod: ToString(MeasurementPeriodStart) + ' to ' + ToString(MeasurementPeriodEnd),
    totalParticipatingOrganizations: "Total Participating Organizations",
    organizationList: "Detailed Organization List",
    regionalDistribution: "Participating Organizations By Region",
    typeDistribution: "Participating Organizations By Type",
    programCountDistribution: "Program Count Statistics",
    programTypeDistribution: "Organizations Per Program Type",
    multiProgramOrganizations: "Multi Program Organizations",
    serviceVolumeOverview: "Service Volume Overview",
    topServiceProviders: "Service Volume Statistics",
    dataSource: '參與中醫門診總額支付制度下各項計畫或方案的中醫特約醫事服務機構',
    note: '此指標為組織名單，列出所有參與中醫門診總額計畫的醫療機構及其詳細資訊'
  }
