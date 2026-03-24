library Indicator_Ischemic_Stroke_Discharge_Antithrombotic_Prescription_Rate version '1.0.0'

/*
缺血性中風或暫時性腦缺血病人出院時有處方抗血栓藥物比率
Ischemic Stroke or TIA Discharge Antithrombotic Prescription Rate

計算說明:
- 分子：分母案例中，同次住院出院時有處方抗血栓藥物的人次數(出院帶藥)
- 分母：18歲(含)以上主診斷為缺血性中風或暫時性腦缺血的住院人次數
- 資料範圍：西醫醫院住院資料
- 計算頻率：半年及年

備註:
1. 18歲(含)以上：(入院年-出生年)≥18
2. 抗血栓藥物：ATC7前四碼為B01A
3. 出院帶藥：墊令執行起日≥出院日
4. 排除兩未有出院紀錄的案件
5. 缺血性中風：出院主診斷碼前三碼為I63、全碼為P91821、P91822、P91823、P91829
6. 暫時性腦缺血：出院主診斷全碼為G450、G451、G452、G458、G459、G460、G461、G462、I67841、I67848
7. 臨床意義：抗血栓藥物是缺血性中風二級預防的重要措施，可降低再發風險
8. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-06)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 半年度期間定義
parameter "Period 1" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-06-30T23:59:59.0]

parameter "Period 2" Interval<DateTime>
  default Interval[@2026-07-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 年齡限制
parameter "Minimum Age" Integer default 18

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'

// 缺血性中風診斷碼定義
// I63系列（前三碼）
code "I63": 'I63' from "ICD10CM" display 'Cerebral infarction'

// P918系列（新生兒缺血性中風）
code "P91821": 'P91821' from "ICD10CM" display 'Neonatal cerebral infarction, right side of brain'
code "P91822": 'P91822' from "ICD10CM" display 'Neonatal cerebral infarction, left side of brain'
code "P91823": 'P91823' from "ICD10CM" display 'Neonatal cerebral infarction, bilateral'
code "P91829": 'P91829' from "ICD10CM" display 'Neonatal cerebral infarction, unspecified side'

// 暫時性腦缺血（TIA）診斷碼定義
// G45系列
code "G450": 'G450' from "ICD10CM" display 'Vertebro-basilar artery syndrome'
code "G451": 'G451' from "ICD10CM" display 'Carotid artery syndrome (hemispheric)'
code "G452": 'G452' from "ICD10CM" display 'Multiple and bilateral precerebral artery syndromes'
code "G458": 'G458' from "ICD10CM" display 'Other transient cerebral ischemic attacks and related syndromes'
code "G459": 'G459' from "ICD10CM" display 'Transient cerebral ischemic attack, unspecified'

// G46系列
code "G460": 'G460' from "ICD10CM" display 'Middle cerebral artery syndrome'
code "G461": 'G461' from "ICD10CM" display 'Anterior cerebral artery syndrome'
code "G462": 'G462' from "ICD10CM" display 'Posterior cerebral artery syndrome'

// I67系列（腦血管疾病）
code "I67841": 'I67841' from "ICD10CM" display 'Reversible cerebrovascular vasoconstriction syndrome'
code "I67848": 'I67848' from "ICD10CM" display 'Other cerebrovascular vasospasm and vasoconstriction'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 住院Encounter編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// ===== 診斷判斷函數 =====

// 判斷Condition是否為缺血性中風（I63前三碼或P918系列全碼）
define function "IsIschemicStrokeDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          StartsWith(C.code, 'I63')
          or C.code = 'P91821'
          or C.code = 'P91822'
          or C.code = 'P91823'
          or C.code = 'P91829'
        )
  )

// 判斷Condition是否為暫時性腦缺血（TIA全碼）
define function "IsTIADiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          C.code = 'G450'
          or C.code = 'G451'
          or C.code = 'G452'
          or C.code = 'G458'
          or C.code = 'G459'
          or C.code = 'G460'
          or C.code = 'G461'
          or C.code = 'G462'
          or C.code = 'I67841'
          or C.code = 'I67848'
        )
  )

// 判斷Condition是否為缺血性中風或TIA
define function "IsIschemicStrokeOrTIA"(condition Condition):
  "IsIschemicStrokeDiagnosis"(condition) or "IsTIADiagnosis"(condition)

// 判斷Encounter是否有缺血性中風或TIA主診斷
define function "HasIschemicStrokeOrTIAPrimaryDiagnosis"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and exists(
          C.category Cat
            where exists(
              Cat.coding CatCoding
                where CatCoding.system = 'http://terminology.hl7.org/CodeSystem/condition-category'
                  and CatCoding.code = 'encounter-diagnosis'
            )
        )
        and exists(
          C.extension Ext
            where Ext.url = 'http://hl7.org/fhir/StructureDefinition/condition-dueTo'
              and exists(
                Ext.extension SubExt
                  where SubExt.url = 'role'
                    and SubExt.value as CodeableConcept in "Primary Diagnosis Codes"
              )
        )
        and "IsIschemicStrokeOrTIA"(C)
  )

// 主診斷編碼
define "Primary Diagnosis Codes":
  {
    CodeableConcept {
      coding: {
        Coding {
          system: 'http://terminology.hl7.org/CodeSystem/diagnosis-role',
          code: 'AD',
          display: 'Admission diagnosis'
        }
      }
    }
  }

// ===== 年齡計算 =====

// 取得入院日
define function "GetAdmissionDate"(encounter Encounter):
  start of encounter.period

// 計算病人在入院時的年齡
define function "GetAgeAtAdmission"(encounter Encounter):
  AgeInYearsAt(date from "GetAdmissionDate"(encounter))

// 判斷病人在入院時是否≥18歲
define function "IsAdultAtAdmission"(encounter Encounter):
  "GetAgeAtAdmission"(encounter) >= "Minimum Age"

// ===== 出院相關函數 =====

// 取得出院日
define function "GetDischargeDate"(encounter Encounter):
  end of encounter.period

// 判斷Encounter是否有出院紀錄
define function "HasDischargeRecord"(encounter Encounter):
  "GetDischargeDate"(encounter) is not null

// ===== 分母定義 =====

// 分母：18歲以上缺血性中風或TIA住院案件（有出院紀錄）
define "Denominator Encounters":
  "All Inpatient Encounters" E
    where "HasIschemicStrokeOrTIAPrimaryDiagnosis"(E)
      and "IsAdultAtAdmission"(E)
      and "HasDischargeRecord"(E)

// 分母（總案件數）
define "Denominator":
  Count("Denominator Encounters")

// 分母（第一期）
define "Denominator Period 1":
  Count(
    "Denominator Encounters" E
      where E.period.start during "Period 1"
  )

// 分母（第二期）
define "Denominator Period 2":
  Count(
    "Denominator Encounters" E
      where E.period.start during "Period 2"
  )

// ===== 抗血栓藥物判斷 =====

// 判斷MedicationRequest是否為抗血栓藥物（ATC前四碼為B01A）
define function "IsAntithromboticMedication"(medication MedicationRequest):
  medication.status in {'active', 'completed'}
    and exists(
      medication.medication as CodeableConcept MC
        return MC.coding C
          where C.system = 'http://www.whocc.no/atc'
            and StartsWith(C.code, 'B01A')
    )

// 取得MedicationRequest的執行起日
define function "GetMedicationDate"(medication MedicationRequest):
  Coalesce(
    start of medication.dispenseRequest.validityPeriod,
    medication.authoredOn
  )

// 判斷MedicationRequest是否為出院帶藥（執行起日≥出院日）
define function "IsDischargeMedication"(medication MedicationRequest, dischargeDate DateTime):
  "GetMedicationDate"(medication) >= dischargeDate

// 判斷Encounter出院時是否有處方抗血栓藥物
define function "HasDischargeMedicationAntithrombotic"(encounter Encounter):
  let dischargeDate: "GetDischargeDate"(encounter)
  return
    exists(
      "All Medication Requests" M
        where M.encounter.reference = 'Encounter/' + encounter.id
          and "IsAntithromboticMedication"(M)
          and "IsDischargeMedication"(M, dischargeDate)
    )

// 取得Encounter的出院抗血栓藥物處方
define function "GetDischargeMedicationAntithromboticPrescriptions"(encounter Encounter):
  let dischargeDate: "GetDischargeDate"(encounter)
  return
    "All Medication Requests" M
      where M.encounter.reference = 'Encounter/' + encounter.id
        and "IsAntithromboticMedication"(M)
        and "IsDischargeMedication"(M, dischargeDate)

// ===== 分子定義 =====

// 分子：出院時有處方抗血栓藥物的案件
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasDischargeMedicationAntithrombotic"(E)

// 分子（符合條件案件數）
define "Numerator":
  Count("Numerator Encounters")

// 分子（第一期）
define "Numerator Period 1":
  Count(
    "Numerator Encounters" E
      where E.period.start during "Period 1"
  )

// 分子（第二期）
define "Numerator Period 2":
  Count(
    "Numerator Encounters" E
      where E.period.start during "Period 2"
  )

// ===== 指標計算 =====

// 整體指標（全年）
define "Indicator Rate":
  if "Denominator" > 0
    then Round("Numerator" / "Denominator" * 100, 2)
    else null

// 第一期指標
define "Indicator Rate Period 1":
  if "Denominator Period 1" > 0
    then Round("Numerator Period 1" / "Denominator Period 1" * 100, 2)
    else null

// 第二期指標
define "Indicator Rate Period 2":
  if "Denominator Period 2" > 0
    then Round("Numerator Period 2" / "Denominator Period 2" * 100, 2)
    else null

// ===== 品質檢核 =====

// 資料完整性檢查
define "Data Quality Check":
  Tuple {
    total_inpatient_encounters: Count("All Inpatient Encounters"),
    stroke_tia_encounters: Count("All Inpatient Encounters" E where "HasIschemicStrokeOrTIAPrimaryDiagnosis"(E)),
    no_discharge_record_exclusions: Count(
      "All Inpatient Encounters" E 
        where "HasIschemicStrokeOrTIAPrimaryDiagnosis"(E) 
          and not "HasDischargeRecord"(E)
    ),
    age_under_18_exclusions: Count(
      "All Inpatient Encounters" E 
        where "HasIschemicStrokeOrTIAPrimaryDiagnosis"(E) 
          and "HasDischargeRecord"(E)
          and not "IsAdultAtAdmission"(E)
    ),
    qualified_stroke_tia_cases: "Denominator",
    cases_with_antithrombotic_prescription: "Numerator"
  }

// 診斷類型統計
define "Diagnosis Type Statistics":
  Tuple {
    ischemic_stroke_I63: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I63'))
        )
    ),
    neonatal_stroke_P918: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where CD.code in {'P91821', 'P91822', 'P91823', 'P91829'})
        )
    ),
    tia_G45: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'G45'))
        )
    ),
    tia_G46: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'G46'))
        )
    ),
    tia_I67: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where CD.code in {'I67841', 'I67848'})
        )
    )
  }

// 抗血栓藥物類型統計（B01A次分類）
define "Antithrombotic Type Statistics":
  Tuple {
    total_with_antithrombotic: "Numerator",
    B01AA_vitamin_k_antagonists: Count(
      "Numerator Encounters" E
        where exists(
          "GetDischargeMedicationAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'B01AA')
            )
        )
    ),
    B01AB_heparin_group: Count(
      "Numerator Encounters" E
        where exists(
          "GetDischargeMedicationAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'B01AB')
            )
        )
    ),
    B01AC_platelet_aggregation_inhibitors: Count(
      "Numerator Encounters" E
        where exists(
          "GetDischargeMedicationAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'B01AC')
            )
        )
    ),
    B01AE_direct_thrombin_inhibitors: Count(
      "Numerator Encounters" E
        where exists(
          "GetDischargeMedicationAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'B01AE')
            )
        )
    ),
    B01AF_direct_factor_xa_inhibitors: Count(
      "Numerator Encounters" E
        where exists(
          "GetDischargeMedicationAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'B01AF')
            )
        )
    ),
    other_B01A: Count(
      "Numerator Encounters" E
        where exists(
          "GetDischargeMedicationAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'B01A')
                    and not StartsWith(C.code, 'B01AA')
                    and not StartsWith(C.code, 'B01AB')
                    and not StartsWith(C.code, 'B01AC')
                    and not StartsWith(C.code, 'B01AE')
                    and not StartsWith(C.code, 'B01AF')
            )
        )
    )
  }

// 年齡分組統計
define "Age Group Statistics":
  Tuple {
    age_18_44: Count("Denominator Encounters" E where "GetAgeAtAdmission"(E) >= 18 and "GetAgeAtAdmission"(E) <= 44),
    age_45_64: Count("Denominator Encounters" E where "GetAgeAtAdmission"(E) >= 45 and "GetAgeAtAdmission"(E) <= 64),
    age_65_plus: Count("Denominator Encounters" E where "GetAgeAtAdmission"(E) >= 65),
    age_18_44_with_prescription: Count("Numerator Encounters" E where "GetAgeAtAdmission"(E) >= 18 and "GetAgeAtAdmission"(E) <= 44),
    age_45_64_with_prescription: Count("Numerator Encounters" E where "GetAgeAtAdmission"(E) >= 45 and "GetAgeAtAdmission"(E) <= 64),
    age_65_plus_with_prescription: Count("Numerator Encounters" E where "GetAgeAtAdmission"(E) >= 65)
  }

// 住院天數分組統計
define "Length of Stay Statistics":
  Tuple {
    los_1_3_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period >= 1 and days between start of E.period and end of E.period <= 3),
    los_4_7_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period >= 4 and days between start of E.period and end of E.period <= 7),
    los_8_14_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period >= 8 and days between start of E.period and end of E.period <= 14),
    los_over_14_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period > 14),
    los_1_3_with_prescription: Count("Numerator Encounters" E where days between start of E.period and end of E.period >= 1 and days between start of E.period and end of E.period <= 3),
    los_4_7_with_prescription: Count("Numerator Encounters" E where days between start of E.period and end of E.period >= 4 and days between start of E.period and end of E.period <= 7),
    los_8_14_with_prescription: Count("Numerator Encounters" E where days between start of E.period and end of E.period >= 8 and days between start of E.period and end of E.period <= 14),
    los_over_14_with_prescription: Count("Numerator Encounters" E where days between start of E.period and end of E.period > 14)
  }

// 處方分析
define "Prescription Pattern Analysis":
  Tuple {
    cases_with_single_antithrombotic: Count(
      "Numerator Encounters" E
        where Count("GetDischargeMedicationAntithromboticPrescriptions"(E)) = 1
    ),
    cases_with_multiple_antithrombotics: Count(
      "Numerator Encounters" E
        where Count("GetDischargeMedicationAntithromboticPrescriptions"(E)) > 1
    ),
    total_antithrombotic_prescriptions: Sum(
      "Numerator Encounters" E
        return Count("GetDischargeMedicationAntithromboticPrescriptions"(E))
    ),
    average_prescriptions_per_case: 
      if "Numerator" > 0
        then Round(
          Sum("Numerator Encounters" E return Count("GetDischargeMedicationAntithromboticPrescriptions"(E))) / "Numerator",
          2
        )
        else null
  }

// 性別統計
define "Gender Statistics":
  Tuple {
    male: Count("Denominator Encounters" E where Patient.gender = 'male'),
    female: Count("Denominator Encounters" E where Patient.gender = 'female'),
    male_with_prescription: Count("Numerator Encounters" E where Patient.gender = 'male'),
    female_with_prescription: Count("Numerator Encounters" E where Patient.gender = 'female')
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '缺血性中風或暫時性腦缺血病人出院時有處方抗血栓藥物比率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '抗血栓藥物是缺血性中風二級預防的重要措施，可降低再發風險',
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    
    // 分期指標
    period_1_numerator: "Numerator Period 1",
    period_1_denominator: "Denominator Period 1",
    period_1_rate: "Indicator Rate Period 1",
    
    period_2_numerator: "Numerator Period 2",
    period_2_denominator: "Denominator Period 2",
    period_2_rate: "Indicator Rate Period 2",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // 診斷類型統計
    diagnosis_type_statistics: "Diagnosis Type Statistics",
    
    // 抗血栓藥物類型統計
    antithrombotic_type_statistics: "Antithrombotic Type Statistics",
    
    // 年齡分組統計
    age_group_statistics: "Age Group Statistics",
    
    // 住院天數分組統計
    length_of_stay_statistics: "Length of Stay Statistics",
    
    // 處方模式分析
    prescription_pattern_analysis: "Prescription Pattern Analysis",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
