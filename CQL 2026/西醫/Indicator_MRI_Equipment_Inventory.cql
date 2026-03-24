library Indicator_MRI_Equipment_Inventory version '1.0.0'

/*
磁振造影(MRI)之廠牌、機型、磁場強度(T)、使用年限(機齡)
MRI Equipment Inventory - Manufacturer, Model, Field Strength (Tesla), and Age

指標定義:
該醫事服務機構磁振造影的設備廠牌、型號、磁場強度(T)及使用年限(機齡)

指標說明:
本指標為設備管理類型指標，無分子分母計算，主要用於追蹤與統計醫療機構內MRI設備的基本資訊與狀態。

追蹤項目:
1. 廠牌 (Manufacturer): 設備製造商，如GE、Siemens、Philips、Toshiba、Hitachi等
2. 機型 (Model): 具體型號名稱
3. 磁場強度(T) (Field Strength in Tesla): MRI掃描器的磁場強度，如0.5T、1.0T、1.5T、3.0T、7.0T等
4. 使用年限(機齡) (Equipment Age): 從製造日期或安裝日期計算至今的年數

設備分類:
- 按磁場強度分類:
  * 低場強: < 1.0T (如0.2T、0.5T)
  * 中場強: 1.0-1.5T (如1.0T、1.5T)
  * 高場強: 1.5-3.0T (如1.5T、3.0T)
  * 超高場強: ≥ 3.0T (如3.0T、7.0T、9.4T)

- 按機齡分類:
  * 新設備: < 5年
  * 中齡設備: 5-10年
  * 老舊設備: > 10年

臨床意義:
- 磁場強度影響影像品質、掃描時間與診斷能力
- 高場強MRI提供更高解析度與更短掃描時間
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

// MRI掃描器代碼
code "MRI_Scanner": '113091000' from "SNOMEDCT" display 'Magnetic resonance imaging scanner, device'

// ===== 資料來源定義 =====

context Device

// ===== Device Extension 函數 =====

// 從Device Extension中取得磁場強度(T)
define function "GetFieldStrength"(device Device):
  (singleton from (
    device.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/mri-field-strength'
  )).value as Decimal

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

// 判斷設備是否為MRI掃描器
define function "IsMRIScanner"(device Device):
  exists(
    device.type.coding C
      where C.system = 'http://snomed.info/sct'
        and C.code = '113091000'
  )

// 判斷設備狀態（active/inactive）
define function "IsActive"(device Device):
  device.status in {'active'}

// ===== MRI設備分類函數 =====

// 按磁場強度分類
define function "ClassifyByFieldStrength"(fieldStrength Decimal):
  case
    when fieldStrength is null then 'Unknown'
    when fieldStrength < 1.0 then 'Low Field (<1.0T)'
    when fieldStrength >= 1.0 and fieldStrength < 1.5 then 'Mid Field (1.0-1.5T)'
    when fieldStrength >= 1.5 and fieldStrength < 3.0 then 'High Field (1.5-3.0T)'
    when fieldStrength >= 3.0 then 'Ultra High Field (≥3.0T)'
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

// ===== MRI設備清單 =====

// 所有MRI設備（包含active和inactive）
define "All MRI Equipment":
  [Device] D
    where "IsMRIScanner"(D)
    return {
      device_id: D.id,
      manufacturer: "GetManufacturer"(D),
      model: "GetModel"(D),
      field_strength: "GetFieldStrength"(D),
      manufacture_date: "GetManufactureDate"(D),
      installation_date: "GetInstallationDate"(D),
      equipment_age: "CalculateEquipmentAge"(D),
      field_strength_classification: "ClassifyByFieldStrength"("GetFieldStrength"(D)),
      age_classification: "ClassifyByAge"("CalculateEquipmentAge"(D)),
      status: D.status,
      is_active: "IsActive"(D),
      organization_id: "GetOrganizationId"(D),
      serial_number: D.serialNumber,
      device_name: D.deviceName[0].name
    }

// 使用中的MRI設備
define "Active MRI Equipment":
  "All MRI Equipment" MRI
    where MRI.is_active = true

// 停用的MRI設備
define "Inactive MRI Equipment":
  "All MRI Equipment" MRI
    where MRI.is_active = false

// ===== 統計分析 =====

// 總設備數
define "Total MRI Equipment Count":
  Count("All MRI Equipment")

define "Active MRI Equipment Count":
  Count("Active MRI Equipment")

define "Inactive MRI Equipment Count":
  Count("Inactive MRI Equipment")

// 按廠牌統計
define "Statistics By Manufacturer":
  distinct (
    "Active MRI Equipment" MRI return MRI.manufacturer
  ) Manufacturer
  let EquipmentList: "Active MRI Equipment" MRI where MRI.manufacturer = Manufacturer
  return {
    manufacturer: Manufacturer,
    equipment_count: Count(EquipmentList),
    models: distinct (EquipmentList E return E.model),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    ),
    average_field_strength: Round(
      Sum(EquipmentList E return E.field_strength as Decimal) / Count(EquipmentList) as Decimal,
      2
    )
  }
  sort by equipment_count desc

// 按磁場強度統計
define "Statistics By Field Strength":
  distinct (
    "Active MRI Equipment" MRI return MRI.field_strength
  ) FieldStrength
  let EquipmentList: "Active MRI Equipment" MRI where MRI.field_strength = FieldStrength
  return {
    field_strength: FieldStrength,
    field_strength_display: ToString(FieldStrength) + 'T',
    classification: "ClassifyByFieldStrength"(FieldStrength),
    equipment_count: Count(EquipmentList),
    manufacturers: distinct (EquipmentList E return E.manufacturer),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    )
  }
  sort by field_strength desc

// 按磁場強度分類統計
define "Statistics By Field Strength Classification":
  distinct (
    "Active MRI Equipment" MRI return MRI.field_strength_classification
  ) Classification
  let EquipmentList: "Active MRI Equipment" MRI where MRI.field_strength_classification = Classification
  return {
    classification: Classification,
    equipment_count: Count(EquipmentList),
    percentage: Round((Count(EquipmentList) as Decimal / "Active MRI Equipment Count" as Decimal) * 100.0, 1)
  }

// 按機齡分類統計
define "Statistics By Age Classification":
  distinct (
    "Active MRI Equipment" MRI return MRI.age_classification
  ) Classification
  let EquipmentList: "Active MRI Equipment" MRI where MRI.age_classification = Classification
  return {
    classification: Classification,
    equipment_count: Count(EquipmentList),
    percentage: Round((Count(EquipmentList) as Decimal / "Active MRI Equipment Count" as Decimal) * 100.0, 1),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    )
  }

// 按醫療機構統計
define "Statistics By Organization":
  distinct (
    "Active MRI Equipment" MRI return MRI.organization_id
  ) OrgId
  let EquipmentList: "Active MRI Equipment" MRI where MRI.organization_id = OrgId
  return {
    organization_id: OrgId,
    equipment_count: Count(EquipmentList),
    manufacturers: distinct (EquipmentList E return E.manufacturer),
    average_field_strength: Round(
      Sum(EquipmentList E return E.field_strength as Decimal) / Count(EquipmentList) as Decimal,
      2
    ),
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    ),
    field_strength_classifications: distinct (EquipmentList E return E.field_strength_classification),
    age_classifications: distinct (EquipmentList E return E.age_classification)
  }

// 按機型統計（Top 10）
define "Statistics By Model":
  distinct (
    "Active MRI Equipment" MRI return {manufacturer: MRI.manufacturer, model: MRI.model}
  ) ModelInfo
  let EquipmentList: "Active MRI Equipment" MRI 
      where MRI.manufacturer = ModelInfo.manufacturer and MRI.model = ModelInfo.model
  return {
    manufacturer: ModelInfo.manufacturer,
    model: ModelInfo.model,
    equipment_count: Count(EquipmentList),
    field_strength: First(EquipmentList).field_strength,
    average_age: Round(
      Sum(EquipmentList E return E.equipment_age as Decimal) / Count(EquipmentList) as Decimal,
      1
    )
  }
  sort by equipment_count desc

// ===== 設備汰換建議 =====

// 高優先汰換設備（>10年且<1.5T）
define "High Priority Replacement Equipment":
  "Active MRI Equipment" MRI
    where MRI.equipment_age > 10
      and MRI.field_strength < 1.5

// 中優先汰換設備（8-10年或<1.5T且≥5年）
define "Medium Priority Replacement Equipment":
  "Active MRI Equipment" MRI
    where (MRI.equipment_age >= 8 and MRI.equipment_age <= 10)
      or (MRI.field_strength < 1.5 and MRI.equipment_age >= 5)

// 設備汰換統計
define "Replacement Priority Statistics":
  {
    high_priority_count: Count("High Priority Replacement Equipment"),
    medium_priority_count: Count("Medium Priority Replacement Equipment"),
    high_priority_list: "High Priority Replacement Equipment",
    medium_priority_list: "Medium Priority Replacement Equipment"
  }

// ===== 進階分析 =====

// 3.0T以上超高場強MRI統計
define "Ultra High Field MRI Statistics":
  "Active MRI Equipment" MRI
    where MRI.field_strength >= 3.0
  return {
    total_count: Count(MRI),
    percentage: Round((Count(MRI) as Decimal / "Active MRI Equipment Count" as Decimal) * 100.0, 1),
    manufacturers: distinct (MRI M return M.manufacturer),
    models: distinct (MRI M return M.model),
    average_age: Round(
      Sum(MRI M return M.equipment_age as Decimal) / Count(MRI) as Decimal,
      1
    )
  }

// 1.5T標準MRI統計
define "Standard 1.5T MRI Statistics":
  "Active MRI Equipment" MRI
    where MRI.field_strength >= 1.5 and MRI.field_strength < 3.0
  return {
    total_count: Count(MRI),
    percentage: Round((Count(MRI) as Decimal / "Active MRI Equipment Count" as Decimal) * 100.0, 1),
    manufacturers: distinct (MRI M return M.manufacturer),
    average_age: Round(
      Sum(MRI M return M.equipment_age as Decimal) / Count(MRI) as Decimal,
      1
    )
  }

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '磁振造影(MRI)之廠牌、機型、磁場強度(T)、使用年限(機齡)',
    indicator_type: '設備管理類型指標（無分子分母）',
    reference_date: "Reference Date",
    measurement_year: "Measurement Year",
    
    // 總體統計
    total_equipment_count: "Total MRI Equipment Count",
    active_equipment_count: "Active MRI Equipment Count",
    inactive_equipment_count: "Inactive MRI Equipment Count",
    
    // 設備清單
    all_mri_equipment: "All MRI Equipment",
    active_mri_equipment: "Active MRI Equipment",
    inactive_mri_equipment: "Inactive MRI Equipment",
    
    // 各維度統計
    statistics_by_manufacturer: "Statistics By Manufacturer",
    statistics_by_field_strength: "Statistics By Field Strength",
    statistics_by_field_strength_classification: "Statistics By Field Strength Classification",
    statistics_by_age_classification: "Statistics By Age Classification",
    statistics_by_organization: "Statistics By Organization",
    statistics_by_model: "Statistics By Model",
    
    // 設備汰換建議
    replacement_priority_statistics: "Replacement Priority Statistics",
    
    // 進階分析
    ultra_high_field_mri_statistics: "Ultra High Field MRI Statistics",
    standard_1_5t_mri_statistics: "Standard 1.5T MRI Statistics",
    
    // 說明
    notes: {
      definition: '追蹤醫療機構內MRI設備的廠牌、型號、磁場強度(T)及使用年限',
      tracked_items: {
        manufacturer: '設備製造商（如GE、Siemens、Philips、Toshiba、Hitachi等）',
        model: '具體型號名稱',
        field_strength: 'MRI掃描器的磁場強度（Tesla，如0.5T、1.0T、1.5T、3.0T、7.0T）',
        equipment_age: '從製造日期或安裝日期計算至今的年數'
      },
      field_strength_classification: {
        low_field: '低場強: <1.0T（如0.2T、0.5T）',
        mid_field: '中場強: 1.0-1.5T（如1.0T、1.5T）',
        high_field: '高場強: 1.5-3.0T（如1.5T、3.0T）',
        ultra_high_field: '超高場強: ≥3.0T（如3.0T、7.0T、9.4T）'
      },
      age_classification: {
        new: '新設備: <5年',
        medium: '中齡設備: 5-10年',
        old: '老舊設備: >10年'
      },
      clinical_significance: '磁場強度影響影像品質、掃描時間與診斷能力，高場強MRI提供更高解析度與更短掃描時間',
      management_value: '有助於設備汰換計劃與預算編列，確保醫療品質與病人安全',
      replacement_criteria: {
        high_priority: '使用年限>10年且磁場強度<1.5T的設備建議優先汰換',
        medium_priority: '使用年限8-10年或磁場強度<1.5T且年限≥5年的設備建議列入汰換計劃'
      },
      field_strength_trend: '目前醫療機構以1.5T為主流，3.0T及以上超高場強MRI逐漸普及，用於神經、心血管等高階影像診斷'
    }
  }
