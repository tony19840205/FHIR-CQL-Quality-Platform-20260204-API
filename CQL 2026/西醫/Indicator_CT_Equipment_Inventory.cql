library Indicator_CT_Equipment_Inventory version '1.0.0'

/*
電腦斷層造影(CT)之廠牌、機型、切數、使用年限(機齡)
CT Equipment Inventory - Manufacturer, Model, Slices, and Age

指標定義:
該醫事服務機構電腦斷層造影的設備廠牌、型號、切數及使用年限(機齡)

指標說明:
本指標為設備管理類型指標，無分子分母計算，主要用於追蹤與統計醫療機構內CT設備的基本資訊與狀態。

追蹤項目:
1. 廠牌 (Manufacturer): 設備製造商，如GE、Siemens、Philips、Toshiba等
2. 機型 (Model): 具體型號名稱
3. 切數 (Detector Rows/Slices): CT掃描器的探測器排數，如16切、64切、128切、256切、320切等
4. 使用年限(機齡) (Equipment Age): 從製造日期或安裝日期計算至今的年數

設備分類:
- 按切數分類:
  * 16切以下: 基礎型CT
  * 16-64切: 標準型CT
  * 64-128切: 進階型CT
  * 128切以上: 高階型CT（含256切、320切等）

- 按機齡分類:
  * 新設備: < 5年
  * 中齡設備: 5-10年
  * 老舊設備: > 10年

臨床意義:
- 設備切數影響影像品質與診斷能力
- 設備機齡影響維修成本與可靠性
- 有助於設備汰換計劃與預算編列
- 確保醫療品質與病人安全

統計範圍: 2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-07)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ===== 參數定義 =====

// 統計時點：2026年12月31日
parameter "Reference Date" DateTime default @2026-12-31T23:59:59.0

// 統計年度
parameter "Measurement Year" Integer default 2026

// ===== 編碼系統定義 =====

// SNOMED CT
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 設備類型代碼系統
codesystem "DeviceType": 'http://terminology.hl7.org/CodeSystem/device-type'

// ===== 代碼定義 =====

// CT掃描器代碼
code "CT_Scanner": '43252007' from "SNOMEDCT" display 'Computed tomography scanner, device'

// ===== 資料來源定義 =====

context Device

// ===== Device Extension 函數 =====

// 從Device Extension中取得切數
define function "GetDetectorRows"(device Device):
  (singleton from (
    device.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/ct-detector-rows'
  )).value as Integer

// 從Device Extension中取得安裝日期
define function "GetInstallationDate"(device Device):
  (singleton from (
    device.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/installation-date'
  )).value as DateTime

// 從Device Extension中取得所屬醫療機構
define function "GetOrganizationId"(device Device):
  if device.owner is not null then
    Last(Split(device.owner.reference, '/'))
  else
    null

// 取得設備製造商
define function "GetManufacturer"(device Device):
  device.manufacturer

// 取得設備型號
define function "GetModel"(device Device):
  device.modelNumber

// 取得製造日期
define function "GetManufactureDate"(device Device):
  device.manufactureDate

// 計算設備年齡（優先使用安裝日期，其次使用製造日期）
define function "CalculateEquipmentAge"(device Device):
  Coalesce(
    years between "GetInstallationDate"(device) and "Reference Date",
    years between "GetManufactureDate"(device) and "Reference Date"
  )

// 判斷設備是否為CT掃描器
define function "IsCTScanner"(device Device):
  exists(
    device.type.coding C
      where C.system = 'http://snomed.info/sct'
        and C.code = '43252007'
  )

// 判斷設備狀態（active/inactive）
define function "IsActive"(device Device):
  device.status in {'active'}

// ===== CT設備分類函數 =====

// 按切數分類
define function "ClassifyBySlices"(slices Integer):
  case
    when slices is null then 'Unknown'
    when slices < 16 then 'Basic (<16 slices)'
    when slices >= 16 and slices < 64 then 'Standard (16-64 slices)'
    when slices >= 64 and slices < 128 then 'Advanced (64-128 slices)'
    when slices >= 128 then 'Premium (≥128 slices)'
    else 'Unknown'
  end

// 按機齡分類
define function "ClassifyByAge"(age Integer):
  case
    when age is null then 'Unknown'
    when age < 5 then 'New (<5 years)'
    when age >= 5 and age <= 10 then 'Medium (5-10 years)'
    when age > 10 then 'Old (>10 years)'
    else 'Unknown'
  end

// ===== CT設備清單 =====

// 所有CT設備（包含active和inactive）
define "All CT Equipment":
  [Device] D
    where "IsCTScanner"(D)
    return {
      device_id: D.id,
      manufacturer: "GetManufacturer"(D),
      model: "GetModel"(D),
      detector_rows: "GetDetectorRows"(D),
      manufacture_date: "GetManufactureDate"(D),
      installation_date: "GetInstallationDate"(D),
      equipment_age: "CalculateEquipmentAge"(D),
      slice_classification: "ClassifyBySlices"("GetDetectorRows"(D)),
      age_classification: "ClassifyByAge"("CalculateEquipmentAge"(D)),
      status: D.status,
      is_active: "IsActive"(D),
      organization_id: "GetOrganizationId"(D),
      serial_number: D.serialNumber,
      device_name: D.deviceName[0].name
    }

// 使用中的CT設備
define "Active CT Equipment":
  "All CT Equipment" CT
    where CT.is_active = true

// 停用的CT設備
define "Inactive CT Equipment":
  "All CT Equipment" CT
    where CT.is_active = false

// ===== 統計分析 =====

// 總設備數
define "Total CT Equipment Count":
  Count("All CT Equipment")

define "Active CT Equipment Count":
  Count("Active CT Equipment")

define "Inactive CT Equipment Count":
  Count("Inactive CT Equipment")

// 按廠牌統計
define "Statistics By Manufacturer":
  distinct (
    "Active CT Equipment" CT return CT.manufacturer
  ) Manufacturer
  let EquipmentList: "Active CT Equipment" CT where CT.manufacturer = Manufacturer
  return {
    manufacturer: Manufacturer,
    equipment_count: Count(EquipmentList),
    models: distinct (EquipmentList E return E.model),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    ),
    average_detector_rows: Round(
      Sum(EquipmentList E return E.detector_rows as Decimal) / Count(EquipmentList) as Decimal,
      0
    )
  }
  sort by equipment_count desc

// 按切數統計
define "Statistics By Detector Rows":
  distinct (
    "Active CT Equipment" CT return CT.detector_rows
  ) Rows
  let EquipmentList: "Active CT Equipment" CT where CT.detector_rows = Rows
  return {
    detector_rows: Rows,
    classification: "ClassifyBySlices"(Rows),
    equipment_count: Count(EquipmentList),
    manufacturers: distinct (EquipmentList E return E.manufacturer),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    )
  }
  sort by detector_rows desc

// 按切數分類統計
define "Statistics By Slice Classification":
  distinct (
    "Active CT Equipment" CT return CT.slice_classification
  ) Classification
  let EquipmentList: "Active CT Equipment" CT where CT.slice_classification = Classification
  return {
    classification: Classification,
    equipment_count: Count(EquipmentList),
    percentage: Round((Count(EquipmentList) as Decimal / "Active CT Equipment Count" as Decimal) * 100.0, 1)
  }

// 按機齡分類統計
define "Statistics By Age Classification":
  distinct (
    "Active CT Equipment" CT return CT.age_classification
  ) Classification
  let EquipmentList: "Active CT Equipment" CT where CT.age_classification = Classification
  return {
    classification: Classification,
    equipment_count: Count(EquipmentList),
    percentage: Round((Count(EquipmentList) as Decimal / "Active CT Equipment Count" as Decimal) * 100.0, 1),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    )
  }

// 按醫療機構統計
define "Statistics By Organization":
  distinct (
    "Active CT Equipment" CT return CT.organization_id
  ) OrgId
  let EquipmentList: "Active CT Equipment" CT where CT.organization_id = OrgId
  return {
    organization_id: OrgId,
    equipment_count: Count(EquipmentList),
    manufacturers: distinct (EquipmentList E return E.manufacturer),
    average_detector_rows: Round(
      Sum(EquipmentList E return E.detector_rows as Decimal) / Count(EquipmentList) as Decimal,
      0
    ),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    ),
    slice_classifications: distinct (EquipmentList E return E.slice_classification),
    age_classifications: distinct (EquipmentList E return E.age_classification)
  }

// 按機型統計（Top 10）
define "Statistics By Model":
  distinct (
    "Active CT Equipment" CT return {manufacturer: CT.manufacturer, model: CT.model}
  ) ModelInfo
  let EquipmentList: "Active CT Equipment" CT 
      where CT.manufacturer = ModelInfo.manufacturer and CT.model = ModelInfo.model
  return {
    manufacturer: ModelInfo.manufacturer,
    model: ModelInfo.model,
    equipment_count: Count(EquipmentList),
    detector_rows: First(EquipmentList).detector_rows,
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    )
  }
  sort by equipment_count desc

// ===== 設備汰換建議 =====

// 高優先汰換設備（>10年且<64切）
define "High Priority Replacement Equipment":
  "Active CT Equipment" CT
    where CT.equipment_age > 10
      and CT.detector_rows < 64

// 中優先汰換設備（8-10年或<64切）
define "Medium Priority Replacement Equipment":
  "Active CT Equipment" CT
    where (CT.equipment_age >= 8 and CT.equipment_age <= 10)
      or (CT.detector_rows < 64 and CT.equipment_age >= 5)

// 設備汰換統計
define "Replacement Priority Statistics":
  {
    high_priority_count: Count("High Priority Replacement Equipment"),
    medium_priority_count: Count("Medium Priority Replacement Equipment"),
    high_priority_list: "High Priority Replacement Equipment",
    medium_priority_list: "Medium Priority Replacement Equipment"
  }

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '電腦斷層造影(CT)之廠牌、機型、切數、使用年限(機齡)',
    indicator_type: '設備管理類型指標（無分子分母）',
    reference_date: "Reference Date",
    measurement_year: "Measurement Year",
    
    // 總體統計
    total_equipment_count: "Total CT Equipment Count",
    active_equipment_count: "Active CT Equipment Count",
    inactive_equipment_count: "Inactive CT Equipment Count",
    
    // 設備清單
    all_ct_equipment: "All CT Equipment",
    active_ct_equipment: "Active CT Equipment",
    inactive_ct_equipment: "Inactive CT Equipment",
    
    // 各維度統計
    statistics_by_manufacturer: "Statistics By Manufacturer",
    statistics_by_detector_rows: "Statistics By Detector Rows",
    statistics_by_slice_classification: "Statistics By Slice Classification",
    statistics_by_age_classification: "Statistics By Age Classification",
    statistics_by_organization: "Statistics By Organization",
    statistics_by_model: "Statistics By Model",
    
    // 設備汰換建議
    replacement_priority_statistics: "Replacement Priority Statistics",
    
    // 說明
    notes: {
      definition: '追蹤醫療機構內CT設備的廠牌、型號、切數及使用年限',
      tracked_items: {
        manufacturer: '設備製造商（如GE、Siemens、Philips、Toshiba等）',
        model: '具體型號名稱',
        detector_rows: 'CT掃描器的探測器排數（切數）',
        equipment_age: '從製造日期或安裝日期計算至今的年數'
      },
      slice_classification: {
        basic: '基礎型CT: <16切',
        standard: '標準型CT: 16-64切',
        advanced: '進階型CT: 64-128切',
        premium: '高階型CT: ≥128切（含256切、320切等）'
      },
      age_classification: {
        new: '新設備: <5年',
        medium: '中齡設備: 5-10年',
        old: '老舊設備: >10年'
      },
      clinical_significance: '設備切數影響影像品質與診斷能力，設備機齡影響維修成本與可靠性',
      management_value: '有助於設備汰換計劃與預算編列，確保醫療品質與病人安全',
      replacement_criteria: {
        high_priority: '使用年限>10年且切數<64的設備建議優先汰換',
        medium_priority: '使用年限8-10年或切數<64且年限≥5年的設備建議列入汰換計劃'
      }
    }
  }
