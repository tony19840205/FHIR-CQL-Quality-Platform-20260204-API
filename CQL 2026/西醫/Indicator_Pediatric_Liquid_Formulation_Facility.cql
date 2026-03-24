library Indicator_Pediatric_Liquid_Formulation_Facility version '1.0.0'

/*
申報使用兒童藥劑院所
Facilities Reporting Pediatric Liquid Formulation Usage

計算說明:
- 指標定義：針對12歲以下兒童開立原瓶口服液劑的院所
- 資料範圍：醫院門診資料
- 計算頻率：年

備註:
1. 12歲以下兒童：實用年月(年)-出生日期(年)≤12
2. 原瓶口服液劑(下列2條件擇1)：
   (1) 藥品主檔的「DRUG_DOSE_CODE」為('141','142','145','151','152','170','174','175','177','180','182','183','184','186','191','193','15A','15C','169')
       且藥品代碼末2碼非99碼且藥品代碼非排除清單
       排除藥品代碼：'B017750127','B020742119','B020742D3','B023462129','A016867177','B023724110','A036041109','A036104109','A038163199','BC23462129'
   (2) 藥品代碼為('A025977125','B010773113','B010773126','AC25977125','BC22931116','B022931116')
3. 臨床意義：監測院所是否提供兒童友善的液體製劑，提升兒童用藥安全與順從性
4. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-06)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 年齡上限（年）
parameter "Maximum Age Years" Integer default 12

// 編碼系統定義
codesystem "TWDrug": 'http://healthcare.gov.tw/drug'
codesystem "TWDrugDose": 'http://healthcare.gov.tw/drug/dose'

// 原瓶口服液劑劑型codes (DRUG_DOSE_CODE)
code "141": '141' from "TWDrugDose" display '口服液劑'
code "142": '142' from "TWDrugDose" display '口服液劑'
code "145": '145' from "TWDrugDose" display '口服液劑'
code "151": '151' from "TWDrugDose" display '口服液劑'
code "152": '152' from "TWDrugDose" display '口服液劑'
code "170": '170' from "TWDrugDose" display '口服液劑'
code "174": '174' from "TWDrugDose" display '口服液劑'
code "175": '175' from "TWDrugDose" display '口服液劑'
code "177": '177' from "TWDrugDose" display '口服液劑'
code "180": '180' from "TWDrugDose" display '口服液劑'
code "182": '182' from "TWDrugDose" display '口服液劑'
code "183": '183' from "TWDrugDose" display '口服液劑'
code "184": '184' from "TWDrugDose" display '口服液劑'
code "186": '186' from "TWDrugDose" display '口服液劑'
code "191": '191' from "TWDrugDose" display '口服液劑'
code "193": '193' from "TWDrugDose" display '口服液劑'
code "15A": '15A' from "TWDrugDose" display '口服液劑'
code "15C": '15C' from "TWDrugDose" display '口服液劑'
code "169": '169' from "TWDrugDose" display '口服液劑'

// 特定包含的藥品代碼 (條件2)
code "A025977125": 'A025977125' from "TWDrug" display '兒童口服液劑'
code "B010773113": 'B010773113' from "TWDrug" display '兒童口服液劑'
code "B010773126": 'B010773126' from "TWDrug" display '兒童口服液劑'
code "AC25977125": 'AC25977125' from "TWDrug" display '兒童口服液劑'
code "BC22931116": 'BC22931116' from "TWDrug" display '兒童口服液劑'
code "B022931116": 'B022931116' from "TWDrug" display '兒童口服液劑'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// Encounter類型編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// ===== 年齡計算 =====

// 計算處方時的年齡（年）- 實用年月(年) - 出生日期(年)
define function "GetAgeInYearsAtPrescription"(prescriptionDate DateTime):
  years between Patient.birthDate and date from prescriptionDate

// 判斷年齡是否≤12歲
define function "IsAge12OrYounger"(prescriptionDate DateTime):
  let ageYears: "GetAgeInYearsAtPrescription"(prescriptionDate)
  return
    ageYears is not null and ageYears <= "Maximum Age Years"

// ===== 原瓶口服液劑判斷 =====

// 原瓶口服液劑劑型代碼清單 (DRUG_DOSE_CODE)
define "Liquid Formulation Dose Codes":
  {
    '141', '142', '145', '151', '152', '170', '174', '175', '177',
    '180', '182', '183', '184', '186', '191', '193', '15A', '15C', '169'
  }

// 排除的藥品代碼清單
define "Excluded Drug Codes":
  {
    'B017750127', 'B020742119', 'B020742D3', 'B023462129', 'A016867177',
    'B023724110', 'A036041109', 'A036104109', 'A038163199', 'BC23462129'
  }

// 特定包含的藥品代碼清單 (條件2)
define "Specific Included Drug Codes":
  {
    'A025977125', 'B010773113', 'B010773126', 'AC25977125', 'BC22931116', 'B022931116'
  }

// 判斷藥品代碼末2碼是否為99
define function "EndsWithNineNine"(drugCode String):
  if Length(drugCode) >= 2
    then Substring(drugCode, Length(drugCode) - 2, 2) = '99'
    else false

// 判斷MedicationRequest的劑型代碼是否為原瓶口服液劑
define function "HasLiquidFormulationDoseCode"(medication MedicationRequest):
  exists(
    medication.medicationCodeableConcept.coding C
      where C.system = 'http://healthcare.gov.tw/drug/dose'
        and C.code in "Liquid Formulation Dose Codes"
  )

// 判斷MedicationRequest的藥品代碼
define function "GetDrugCode"(medication MedicationRequest):
  singleton from (
    medication.medicationCodeableConcept.coding C
      where C.system = 'http://healthcare.gov.tw/drug'
      return C.code
  )

// 判斷MedicationRequest是否符合條件1（劑型代碼+藥品代碼規則）
define function "MeetsCondition1"(medication MedicationRequest):
  let drugCode: "GetDrugCode"(medication)
  return
    "HasLiquidFormulationDoseCode"(medication)
      and drugCode is not null
      and not "EndsWithNineNine"(drugCode)
      and not (drugCode in "Excluded Drug Codes")

// 判斷MedicationRequest是否符合條件2（特定藥品代碼）
define function "MeetsCondition2"(medication MedicationRequest):
  let drugCode: "GetDrugCode"(medication)
  return
    drugCode is not null
      and drugCode in "Specific Included Drug Codes"

// 判斷MedicationRequest是否為原瓶口服液劑（條件1或條件2）
define function "IsPediatricLiquidFormulation"(medication MedicationRequest):
  medication.status in { 'active', 'completed' }
    and (
      "MeetsCondition1"(medication)
      or "MeetsCondition2"(medication)
    )

// ===== 期間內兒童原瓶口服液劑處方 =====

// 取得期間內為12歲以下兒童開立的原瓶口服液劑處方
define function "GetPediatricLiquidFormulationsInPeriod"(period Interval<DateTime>):
  "All Medication Requests" M
    where "IsPediatricLiquidFormulation"(M)
      and M.authoredOn during period
      and "IsAge12OrYounger"(M.authoredOn)

// 判斷期間內是否有為12歲以下兒童開立原瓶口服液劑
define function "HasPediatricLiquidFormulationsInPeriod"(period Interval<DateTime>):
  exists("GetPediatricLiquidFormulationsInPeriod"(period))

// ===== 指標定義 =====

// 院所是否符合標準（全年）
define "Facility Meets Criteria":
  "HasPediatricLiquidFormulationsInPeriod"("Measurement Period")

// 指標值（1=符合, 0=不符合）
define "Indicator Value":
  if "Facility Meets Criteria" then 1 else 0

// ===== 品質檢核 =====

// 資料完整性檢查（全年）
define "Data Quality Check":
  let pediatricLiquidFormulations: "GetPediatricLiquidFormulationsInPeriod"("Measurement Period"),
      allPediatricMedications: "All Medication Requests" M
        where M.authoredOn during "Measurement Period"
          and "IsAge12OrYounger"(M.authoredOn)
  return Tuple {
    total_pediatric_medications: Count(allPediatricMedications),
    pediatric_liquid_formulations: Count(pediatricLiquidFormulations),
    meets_condition_1: Count(
      pediatricLiquidFormulations M
        where "MeetsCondition1"(M)
    ),
    meets_condition_2: Count(
      pediatricLiquidFormulations M
        where "MeetsCondition2"(M)
    ),
    facility_meets_criteria: "Facility Meets Criteria"
  }

// 兒童處方統計
define "Pediatric Prescription Statistics":
  let pediatricLiquidFormulations: "GetPediatricLiquidFormulationsInPeriod"("Measurement Period"),
      allPediatricMedications: "All Medication Requests" M
        where M.authoredOn during "Measurement Period"
          and "IsAge12OrYounger"(M.authoredOn)
  return Tuple {
    total_pediatric_patients: Count(
      distinct (allPediatricMedications M return M.subject.reference)
    ),
    total_pediatric_prescriptions: Count(allPediatricMedications),
    total_pediatric_liquid_formulations: Count(pediatricLiquidFormulations),
    liquid_formulation_percentage: if Count(allPediatricMedications) > 0
      then Round(Count(pediatricLiquidFormulations) / Count(allPediatricMedications) * 100, 2)
      else null,
    first_prescription_date: if exists(pediatricLiquidFormulations)
      then ToString(First(pediatricLiquidFormulations M sort by authoredOn ascending).authoredOn)
      else null,
    last_prescription_date: if exists(pediatricLiquidFormulations)
      then ToString(Last(pediatricLiquidFormulations M sort by authoredOn ascending).authoredOn)
      else null
  }

// 藥品代碼統計
define "Drug Code Statistics":
  let pediatricLiquidFormulations: "GetPediatricLiquidFormulationsInPeriod"("Measurement Period")
  return Tuple {
    unique_drug_codes: distinct (
      pediatricLiquidFormulations M
        return "GetDrugCode"(M)
    ),
    drug_code_counts: pediatricLiquidFormulations M
      let drugCode: "GetDrugCode"(M)
      where drugCode is not null
      return Tuple {
        drug_code: drugCode,
        meets_condition_1: "MeetsCondition1"(M),
        meets_condition_2: "MeetsCondition2"(M),
        has_liquid_dose_code: "HasLiquidFormulationDoseCode"(M),
        ends_with_99: "EndsWithNineNine"(drugCode),
        is_excluded: drugCode in "Excluded Drug Codes"
      }
  }

// 劑型代碼統計
define "Dose Code Statistics":
  let pediatricLiquidFormulations: "GetPediatricLiquidFormulationsInPeriod"("Measurement Period"),
      doseCodes: flatten(
        pediatricLiquidFormulations M
          return M.medicationCodeableConcept.coding C
            where C.system = 'http://healthcare.gov.tw/drug/dose'
            return C.code
      )
  return Tuple {
    unique_dose_codes: distinct doseCodes,
    dose_code_distribution: "Liquid Formulation Dose Codes" code
      return Tuple {
        dose_code: code,
        count: Count(doseCodes D where D = code)
      }
  }

// 年齡分布統計
define "Age Distribution Statistics":
  let pediatricLiquidFormulations: "GetPediatricLiquidFormulationsInPeriod"("Measurement Period"),
      ageDistribution: pediatricLiquidFormulations M
        let ageYears: "GetAgeInYearsAtPrescription"(M.authoredOn)
        return ageYears
  return Tuple {
    average_age: if exists(ageDistribution) 
      then Round(Sum(ageDistribution) / Count(ageDistribution), 1)
      else null,
    min_age: if exists(ageDistribution) then First(ageDistribution A sort ascending) else null,
    max_age: if exists(ageDistribution) then Last(ageDistribution A sort ascending) else null,
    age_0_2: Count(ageDistribution A where A >= 0 and A <= 2),
    age_3_5: Count(ageDistribution A where A >= 3 and A <= 5),
    age_6_8: Count(ageDistribution A where A >= 6 and A <= 8),
    age_9_12: Count(ageDistribution A where A >= 9 and A <= 12)
  }

// 月度趨勢統計
define "Monthly Trend Statistics":
  {
    Interval[@2026-01-01T00:00:00.0, @2026-01-31T23:59:59.0],
    Interval[@2026-02-01T00:00:00.0, @2026-02-28T23:59:59.0],
    Interval[@2026-03-01T00:00:00.0, @2026-03-31T23:59:59.0],
    Interval[@2026-04-01T00:00:00.0, @2026-04-30T23:59:59.0],
    Interval[@2026-05-01T00:00:00.0, @2026-05-31T23:59:59.0],
    Interval[@2026-06-01T00:00:00.0, @2026-06-30T23:59:59.0],
    Interval[@2026-07-01T00:00:00.0, @2026-07-31T23:59:59.0],
    Interval[@2026-08-01T00:00:00.0, @2026-08-31T23:59:59.0],
    Interval[@2026-09-01T00:00:00.0, @2026-09-30T23:59:59.0],
    Interval[@2026-10-01T00:00:00.0, @2026-10-31T23:59:59.0],
    Interval[@2026-11-01T00:00:00.0, @2026-11-30T23:59:59.0],
    Interval[@2026-12-01T00:00:00.0, @2026-12-31T23:59:59.0]
  } P
    return Tuple {
      month_period: ToString(P),
      has_pediatric_liquid_formulations: "HasPediatricLiquidFormulationsInPeriod"(P),
      prescription_count: Count("GetPediatricLiquidFormulationsInPeriod"(P))
    }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '申報使用兒童藥劑院所',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '監測院所是否提供兒童友善的液體製劑，提升兒童用藥安全與順從性',
    
    // 指標值
    facility_meets_criteria: "Facility Meets Criteria",
    indicator_value: "Indicator Value",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // 兒童處方統計
    pediatric_prescription_statistics: "Pediatric Prescription Statistics",
    
    // 藥品代碼統計
    drug_code_statistics: "Drug Code Statistics",
    
    // 劑型代碼統計
    dose_code_statistics: "Dose Code Statistics",
    
    // 年齡分布統計
    age_distribution_statistics: "Age Distribution Statistics",
    
    // 月度趨勢統計
    monthly_trend_statistics: "Monthly Trend Statistics"
  }
