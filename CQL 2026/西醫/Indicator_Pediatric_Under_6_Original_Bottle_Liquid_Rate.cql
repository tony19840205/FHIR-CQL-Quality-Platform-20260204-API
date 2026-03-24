library Indicator_Pediatric_Under_6_Original_Bottle_Liquid_Rate version '1.0.0'

/*
六歲以下兒童門診開立原瓶口服液劑比率
Original-Bottle Liquid Formulation Prescription Rate for Children Under 6 Years

計算說明:
- 分子：分母案件中，有開立原瓶口服液劑的案件數
- 分母：6歲以下兒童門診開立健保同成分口服藥品，兼有口服及原瓶口服液劑型同成分藥品的給藥件數
- 資料範圍：醫院門診資料
- 計算頻率：年

備註:
1. 6歲以下兒童：費用年月(年)-出生日期(年)≤6
2. 同成分口服藥品同時有原瓶口服液劑的藥品品項：
   - 藥品主檔的「DRUG_ATC7_CODE」相同
   - 藥品代碼第8碼='1'
   - 且該費用年月的藥價_基準明細檔上限價>0的所有藥品中
   - 該品項有原瓶口服液劑的品項
3. 分子條件：原瓶口服液劑(下列2條件擇1)：
   (1) 藥品主檔的「DRUG_DOSE_CODE」為('141','142','145','151','152','170','174','175','177','180','182','183','184','186','191','193','15A','15C','169')
       且藥品代碼末2碼非99碼
       且藥品代碼非排除清單('B017750127','B020742119','B020742D3','B023462129','A016867177','B023724110','A036041109','A036104109','A038163199','BC23462129')
   (2) 藥品代碼為('A025977125','B010773113','B010773126','AC25977125','BC22931116','B022931116')
4. 計算公式：(分子/分母) x 100%
5. 臨床意義：監測兒童友善液體製劑的使用率，提升兒童用藥安全與順從性
6. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-07)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 年齡上限（年）
parameter "Maximum Age Years" Integer default 6

// 編碼系統定義
codesystem "TWDrug": 'http://healthcare.gov.tw/drug'
codesystem "TWDrugDose": 'http://healthcare.gov.tw/drug/dose'
codesystem "ATC": 'http://www.whocc.no/atc'

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
      and E.period.start during "Measurement Period"

// Encounter類型編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// ===== 年齡計算 =====

// 計算處方時的年齡（年）- 費用年月(年) - 出生日期(年)
define function "GetAgeInYearsAtPrescription"(prescriptionDate DateTime):
  years between Patient.birthDate and date from prescriptionDate

// 判斷年齡是否≤6歲
define function "IsAge6OrYounger"(prescriptionDate DateTime):
  let ageYears: "GetAgeInYearsAtPrescription"(prescriptionDate)
  return
    ageYears is not null and ageYears <= "Maximum Age Years"

// ===== 藥品代碼解析函數 =====

// 獲取藥品代碼
define function "GetDrugCode"(medication FHIR.MedicationRequest):
  medication.medicationCodeableConcept.coding[0].code.value

// 獲取藥品劑型碼（DRUG_DOSE_CODE）
define function "GetDrugDoseCode"(medication FHIR.MedicationRequest):
  (singleton from (
    medication.medicationCodeableConcept.coding C
      where C.system.value = 'http://healthcare.gov.tw/drug/dose'
  )).code.value

// 獲取藥品ATC7碼（DRUG_ATC7_CODE）
define function "GetDrugATC7Code"(medication FHIR.MedicationRequest):
  (singleton from (
    medication.medicationCodeableConcept.coding C
      where C.system.value = 'http://www.whocc.no/atc'
  )).code.value

// 獲取藥品第8碼
define function "GetDrugCode8thDigit"(drugCode String):
  if Length(drugCode) >= 8 then
    Substring(drugCode, 7, 1)
  else
    null

// 獲取藥品末2碼
define function "GetDrugCodeLast2Digits"(drugCode String):
  if Length(drugCode) >= 2 then
    Substring(drugCode, Length(drugCode) - 2, 2)
  else
    null

// 獲取藥價上限價（從Extension中取得）
define function "GetDrugPriceLimit"(medication FHIR.MedicationRequest):
  ToDecimal(
    (singleton from (
      medication.extension E
        where E.url.value = 'http://healthcare.gov.tw/fhir/StructureDefinition/drug-price-limit'
    )).value.value
  )

// ===== 原瓶口服液劑判定 =====

// 藥品排除清單
define "Excluded Drug Codes":
  {
    'B017750127', 'B020742119', 'B020742D3', 'B023462129', 'A016867177',
    'B023724110', 'A036041109', 'A036104109', 'A038163199', 'BC23462129'
  }

// 特定包含藥品代碼
define "Specific Included Drug Codes":
  {
    'A025977125', 'B010773113', 'B010773126', 
    'AC25977125', 'BC22931116', 'B022931116'
  }

// 原瓶口服液劑劑型碼
define "Liquid Formulation Dose Codes":
  {
    '141', '142', '145', '151', '152', '170', '174', '175', '177', '180',
    '182', '183', '184', '186', '191', '193', '15A', '15C', '169'
  }

// 判斷是否為原瓶口服液劑（條件1）
define function "IsOriginalBottleLiquidByDoseCode"(medication FHIR.MedicationRequest):
  let drugCode: "GetDrugCode"(medication),
      doseCode: "GetDrugDoseCode"(medication),
      last2Digits: "GetDrugCodeLast2Digits"(drugCode)
  return
    doseCode in "Liquid Formulation Dose Codes"
    and last2Digits != '99'
    and not (drugCode in "Excluded Drug Codes")

// 判斷是否為原瓶口服液劑（條件2）
define function "IsOriginalBottleLiquidByDrugCode"(medication FHIR.MedicationRequest):
  let drugCode: "GetDrugCode"(medication)
  return
    drugCode in "Specific Included Drug Codes"

// 判斷是否為原瓶口服液劑（條件1或條件2）
define function "IsOriginalBottleLiquid"(medication FHIR.MedicationRequest):
  "IsOriginalBottleLiquidByDoseCode"(medication)
    or "IsOriginalBottleLiquidByDrugCode"(medication)

// ===== 同成分口服藥品判定 =====

// 判斷藥品是否符合：第8碼='1' 且 藥價上限價>0
define function "IsOralDrugWithPrice"(medication FHIR.MedicationRequest):
  let drugCode: "GetDrugCode"(medication),
      digit8: "GetDrugCode8thDigit"(drugCode),
      priceLimit: "GetDrugPriceLimit"(medication)
  return
    digit8 = '1'
    and priceLimit is not null
    and priceLimit > 0

// 獲取所有同ATC7碼的藥品（用於判斷是否有液劑型）
define function "GetSameATC7Medications"(atc7Code String):
  "All Medication Requests" M
    where "GetDrugATC7Code"(M) = atc7Code
      and "IsOralDrugWithPrice"(M)

// 判斷某ATC7碼是否有原瓶口服液劑型
define function "HasLiquidFormulationForATC7"(atc7Code String):
  exists (
    "GetSameATC7Medications"(atc7Code) M
      where "IsOriginalBottleLiquid"(M)
  )

// ===== 6歲以下兒童門診給藥案件 =====

// 6歲以下兒童門診Encounter
define "Pediatric Under 6 Outpatient Encounters":
  "All Outpatient Encounters" E
    where "IsAge6OrYounger"(E.period.start)

// 6歲以下兒童門診給藥處方
define "Pediatric Under 6 Medication Requests":
  "All Medication Requests" M
    where M.status = 'completed'
      and M.authoredOn during "Measurement Period"
      and exists (
        "Pediatric Under 6 Outpatient Encounters" E
          where M.encounter.reference.value = 'Encounter/' + E.id.value
      )

// ===== 分母：兼有口服及原瓶口服液劑型同成分藥品的給藥件數 =====

// 分母處方：同成分藥品兼有液劑型的口服藥品
define "Denominator Medication Requests":
  "Pediatric Under 6 Medication Requests" M
    where "IsOralDrugWithPrice"(M)
      and "HasLiquidFormulationForATC7"("GetDrugATC7Code"(M))

// 分母：給藥案件數（按Encounter計算）
define "Denominator Encounters":
  distinct (
    "Denominator Medication Requests" M
      return [Encounter] E
        where E.id.value = Last(Split(M.encounter.reference.value, '/'))
  )

// 分母數值
define "Denominator":
  Count("Denominator Encounters")

// ===== 分子：有開立原瓶口服液劑的案件數 =====

// 分子處方：原瓶口服液劑
define "Numerator Medication Requests":
  "Denominator Medication Requests" M
    where "IsOriginalBottleLiquid"(M)

// 分子：有開立原瓶口服液劑的案件數（按Encounter計算）
define "Numerator Encounters":
  distinct (
    "Numerator Medication Requests" M
      return [Encounter] E
        where E.id.value = Last(Split(M.encounter.reference.value, '/'))
  )

// 分子數值
define "Numerator":
  Count("Numerator Encounters")

// ===== 指標計算結果 =====

// 六歲以下兒童門診開立原瓶口服液劑比率
define "Original Bottle Liquid Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null

// ===== 詳細結果輸出 =====

// 最終報告
define "Final Report":
  {
    indicator_name: '六歲以下兒童門診開立原瓶口服液劑比率',
    indicator_code: 'Pediatric_Under_6_Original_Bottle_Liquid_Rate',
    calculation_year: 2026,
    calculation_frequency: '年',
    denominator: "Denominator",
    numerator: "Numerator",
    rate: "Original Bottle Liquid Rate",
    data_source: '醫院門診資料',
    age_criteria: '費用年月(年)-出生日期(年)≤6',
    denominator_definition: '6歲以下兒童門診開立健保同成分口服藥品，兼有口服及原瓶口服液劑型同成分藥品的給藥件數',
    numerator_definition: '分母案件中，有開立原瓶口服液劑的案件數',
    liquid_formulation_dose_codes: "Liquid Formulation Dose Codes",
    specific_included_drug_codes: "Specific Included Drug Codes",
    excluded_drug_codes: "Excluded Drug Codes",
    clinical_significance: '監測兒童友善液體製劑的使用率，提升兒童用藥安全與順從性',
    formula: '(分子/分母) x 100%'
  }

// ===== 分層分析（按年齡） =====

// 按年齡層分組計算
define function "Calculate By Age Group"(minAge Integer, maxAge Integer):
  let ageGroupEncounters:
    "All Outpatient Encounters" E
      where "GetAgeInYearsAtPrescription"(E.period.start) >= minAge
        and "GetAgeInYearsAtPrescription"(E.period.start) <= maxAge,
  
  ageGroupMedications:
    "All Medication Requests" M
      where M.status = 'completed'
        and M.authoredOn during "Measurement Period"
        and exists (
          ageGroupEncounters E
            where M.encounter.reference.value = 'Encounter/' + E.id.value
        ),
  
  denominatorMeds:
    ageGroupMedications M
      where "IsOralDrugWithPrice"(M)
        and "HasLiquidFormulationForATC7"("GetDrugATC7Code"(M)),
  
  numeratorMeds:
    denominatorMeds M
      where "IsOriginalBottleLiquid"(M),
  
  denominatorCount:
    Count(
      distinct (
        denominatorMeds M
          return [Encounter] E
            where E.id.value = Last(Split(M.encounter.reference.value, '/'))
      )
    ),
  
  numeratorCount:
    Count(
      distinct (
        numeratorMeds M
          return [Encounter] E
            where E.id.value = Last(Split(M.encounter.reference.value, '/'))
      )
    )
  
  return {
    age_group: ToString(minAge) + '-' + ToString(maxAge) + '歲',
    denominator: denominatorCount,
    numerator: numeratorCount,
    rate: if denominatorCount > 0 
          then (numeratorCount / denominatorCount) * 100 
          else null
  }

// 年齡分層結果
define "Age Stratified Results":
  {
    "Calculate By Age Group"(0, 1),
    "Calculate By Age Group"(2, 3),
    "Calculate By Age Group"(4, 6)
  }

// ===== 藥品品項統計 =====

// 統計最常使用的原瓶口服液劑
define "Top Liquid Formulations":
  from "Numerator Medication Requests" M
    let drugCode: "GetDrugCode"(M),
        atc7Code: "GetDrugATC7Code"(M)
    return {
      drug_code: drugCode,
      atc7_code: atc7Code,
      count: Count(
        "Numerator Medication Requests" M2
          where "GetDrugCode"(M2) = drugCode
      )
    }
    sort by count desc

// 統計未使用液劑型的同成分藥品
define "Missed Liquid Formulation Opportunities":
  from "Denominator Medication Requests" M
    where not "IsOriginalBottleLiquid"(M)
    let atc7Code: "GetDrugATC7Code"(M)
    return {
      atc7_code: atc7Code,
      count: Count(
        "Denominator Medication Requests" M2
          where "GetDrugATC7Code"(M2) = atc7Code
            and not "IsOriginalBottleLiquid"(M2)
      )
    }
    sort by count desc
