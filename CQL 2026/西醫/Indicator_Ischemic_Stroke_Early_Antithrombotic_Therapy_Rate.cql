library Indicator_Ischemic_Stroke_Early_Antithrombotic_Therapy_Rate version '1.0.0'

/*
未使用血栓溶解劑治療之缺血性腦中風病人住院一日內給予抗血栓藥治療之比率
Ischemic Stroke Early Antithrombotic Therapy Rate (Without Thrombolytic Treatment)

計算說明:
- 分子：分母案例中，1天內給予抗血栓治療處方之人次數
- 分母：18歲(含)以上有缺血性腦中風急性症狀且未使用血栓溶解劑(tPA)治療的急診或住院的病人次數
- 資料範圍：西醫醫院急診及住院資料
- 計算頻率：半年及年

備註:
1. 18歲(含)以上：(入院年或就醫年-出生年)≥18
2. 缺血性腦中風：主診斷碼前三碼為I63、全碼為P91821、P91822、P91823、P91829
3. 急診：實令類別(ORDER_TYPE)為'A'且實令代碼(ORDER_CODE)為'ER'
4. 血栓溶解劑(tPA)：ATC7為B01AD02（Alteplase）
5. 1天內：住院為(藥物執行起日-住院日)≤1；門診為(藥物執行起日-就醫日)≤1，若藥物執行起日為空值則改抓就醫日
6. 抗血栓治療：ATC7前四碼B01A（包括抗凝劑、抗血小板藥物等）
7. 臨床意義：急性缺血性中風未使用溶栓治療時，應盡早給予抗血栓藥物以降低再發風險
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

// 早期治療時間窗（1天內）
parameter "Early Treatment Days" Integer default 1

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

// 血栓溶解劑（tPA）
code "B01AD02": 'B01AD02' from "ATC" display 'Alteplase'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 所有急診Encounter
define "All Emergency Encounters":
  [Encounter: type in "Emergency Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// Encounter類型編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

define "Emergency Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'EMER', display: 'emergency' }
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

// 判斷Encounter是否有缺血性中風主診斷
define function "HasIschemicStrokePrimaryDiagnosis"(encounter Encounter):
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
        and "IsIschemicStrokeDiagnosis"(C)
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

// 取得就診日（急診或住院入院日）
define function "GetEncounterDate"(encounter Encounter):
  start of encounter.period

// 計算病人在就診時的年齡
define function "GetAgeAtEncounter"(encounter Encounter):
  AgeInYearsAt(date from "GetEncounterDate"(encounter))

// 判斷病人在就診時是否≥18歲
define function "IsAdultAtEncounter"(encounter Encounter):
  "GetAgeAtEncounter"(encounter) >= "Minimum Age"

// ===== 血栓溶解劑(tPA)判斷 =====

// 判斷MedicationRequest是否為血栓溶解劑（B01AD02, Alteplase）
define function "IsThrombolyticMedication"(medication MedicationRequest):
  medication.status in {'active', 'completed'}
    and exists(
      medication.medication as CodeableConcept MC
        return MC.coding C
          where C.system = 'http://www.whocc.no/atc'
            and C.code = 'B01AD02'
    )

// 判斷Encounter是否使用血栓溶解劑
define function "HasThrombolyticTreatment"(encounter Encounter):
  exists(
    "All Medication Requests" M
      where M.encounter.reference = 'Encounter/' + encounter.id
        and "IsThrombolyticMedication"(M)
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

// 計算藥物執行起日與就診日的天數差
define function "GetDaysBetweenMedicationAndEncounter"(medication MedicationRequest, encounterDate DateTime):
  let medDate: "GetMedicationDate"(medication),
      medDateOrEncounterDate: Coalesce(medDate, encounterDate)
  return
    days between encounterDate and medDateOrEncounterDate

// 判斷MedicationRequest是否在1天內給予（執行起日-就診日≤1）
define function "IsEarlyMedication"(medication MedicationRequest, encounterDate DateTime):
  "GetDaysBetweenMedicationAndEncounter"(medication, encounterDate) <= "Early Treatment Days"

// 判斷Encounter是否在1天內給予抗血栓藥物
define function "HasEarlyAntithromboticTreatment"(encounter Encounter):
  let encounterDate: "GetEncounterDate"(encounter)
  return
    exists(
      "All Medication Requests" M
        where M.encounter.reference = 'Encounter/' + encounter.id
          and "IsAntithromboticMedication"(M)
          and "IsEarlyMedication"(M, encounterDate)
    )

// 取得Encounter的早期抗血栓藥物處方
define function "GetEarlyAntithromboticPrescriptions"(encounter Encounter):
  let encounterDate: "GetEncounterDate"(encounter)
  return
    "All Medication Requests" M
      where M.encounter.reference = 'Encounter/' + encounter.id
        and "IsAntithromboticMedication"(M)
        and "IsEarlyMedication"(M, encounterDate)

// ===== 分母定義 =====

// 所有急診或住院缺血性中風案件
define "All Ischemic Stroke Encounters":
  ("All Emergency Encounters" union "All Inpatient Encounters") E
    where "HasIschemicStrokePrimaryDiagnosis"(E)

// 分母：18歲以上缺血性中風案件，未使用血栓溶解劑
define "Denominator Encounters":
  "All Ischemic Stroke Encounters" E
    where "IsAdultAtEncounter"(E)
      and not "HasThrombolyticTreatment"(E)

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

// ===== 分子定義 =====

// 分子：1天內給予抗血栓治療的案件
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasEarlyAntithromboticTreatment"(E)

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
    total_emergency_encounters: Count("All Emergency Encounters"),
    total_inpatient_encounters: Count("All Inpatient Encounters"),
    ischemic_stroke_encounters: Count("All Ischemic Stroke Encounters"),
    age_under_18_exclusions: Count(
      "All Ischemic Stroke Encounters" E 
        where not "IsAdultAtEncounter"(E)
    ),
    thrombolytic_treatment_exclusions: Count(
      "All Ischemic Stroke Encounters" E 
        where "IsAdultAtEncounter"(E)
          and "HasThrombolyticTreatment"(E)
    ),
    qualified_ischemic_stroke_cases: "Denominator",
    cases_with_early_antithrombotic: "Numerator"
  }

// Encounter類型統計
define "Encounter Type Statistics":
  Tuple {
    emergency_encounters: Count("Denominator Encounters" E where E.type in "Emergency Encounter Codes"),
    inpatient_encounters: Count("Denominator Encounters" E where E.type in "Inpatient Encounter Codes"),
    emergency_with_treatment: Count("Numerator Encounters" E where E.type in "Emergency Encounter Codes"),
    inpatient_with_treatment: Count("Numerator Encounters" E where E.type in "Inpatient Encounter Codes")
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
    )
  }

// I63詳細亞型統計（前4碼）
define "I63 Subtype Statistics":
  Tuple {
    I630_precerebral_arteries: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I630'))
        )
    ),
    I631_anterior_cerebral_artery: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I631'))
        )
    ),
    I632_posterior_cerebral_artery: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I632'))
        )
    ),
    I633_brain_stem: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I633'))
        )
    ),
    I634_cerebellar: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I634'))
        )
    ),
    I635_lacunar: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I635'))
        )
    ),
    I636_other: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I636'))
        )
    ),
    I638_multiple: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I638'))
        )
    ),
    I639_unspecified: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I639'))
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
          "GetEarlyAntithromboticPrescriptions"(E) M
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
          "GetEarlyAntithromboticPrescriptions"(E) M
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
          "GetEarlyAntithromboticPrescriptions"(E) M
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
          "GetEarlyAntithromboticPrescriptions"(E) M
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
          "GetEarlyAntithromboticPrescriptions"(E) M
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
          "GetEarlyAntithromboticPrescriptions"(E) M
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

// 常用抗血小板藥物統計（B01AC次分類）
define "Antiplatelet Drug Statistics":
  Tuple {
    B01AC04_clopidogrel: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where C.code = 'B01AC04'
            )
        )
    ),
    B01AC05_ticlopidine: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where C.code = 'B01AC05'
            )
        )
    ),
    B01AC06_aspirin: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where C.code = 'B01AC06'
            )
        )
    ),
    B01AC07_dipyridamole: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where C.code = 'B01AC07'
            )
        )
    ),
    B01AC22_prasugrel: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where C.code = 'B01AC22'
            )
        )
    ),
    B01AC24_ticagrelor: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where C.code = 'B01AC24'
            )
        )
    ),
    B01AC30_combinations: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where C.code = 'B01AC30'
            )
        )
    )
  }

// 年齡分組統計
define "Age Group Statistics":
  Tuple {
    age_18_44: Count("Denominator Encounters" E where "GetAgeAtEncounter"(E) >= 18 and "GetAgeAtEncounter"(E) <= 44),
    age_45_64: Count("Denominator Encounters" E where "GetAgeAtEncounter"(E) >= 45 and "GetAgeAtEncounter"(E) <= 64),
    age_65_plus: Count("Denominator Encounters" E where "GetAgeAtEncounter"(E) >= 65),
    age_18_44_with_treatment: Count("Numerator Encounters" E where "GetAgeAtEncounter"(E) >= 18 and "GetAgeAtEncounter"(E) <= 44),
    age_45_64_with_treatment: Count("Numerator Encounters" E where "GetAgeAtEncounter"(E) >= 45 and "GetAgeAtEncounter"(E) <= 64),
    age_65_plus_with_treatment: Count("Numerator Encounters" E where "GetAgeAtEncounter"(E) >= 65)
  }

// 治療時機統計（當日 vs 次日）
define "Treatment Timing Statistics":
  Tuple {
    same_day_treatment: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where "GetDaysBetweenMedicationAndEncounter"(M, "GetEncounterDate"(E)) = 0
        )
    ),
    next_day_treatment: Count(
      "Numerator Encounters" E
        where exists(
          "GetEarlyAntithromboticPrescriptions"(E) M
            where "GetDaysBetweenMedicationAndEncounter"(M, "GetEncounterDate"(E)) = 1
        )
        and not exists(
          "GetEarlyAntithromboticPrescriptions"(E) M2
            where "GetDaysBetweenMedicationAndEncounter"(M2, "GetEncounterDate"(E)) = 0
        )
    )
  }

// 處方分析
define "Prescription Pattern Analysis":
  Tuple {
    cases_with_single_antithrombotic: Count(
      "Numerator Encounters" E
        where Count("GetEarlyAntithromboticPrescriptions"(E)) = 1
    ),
    cases_with_multiple_antithrombotics: Count(
      "Numerator Encounters" E
        where Count("GetEarlyAntithromboticPrescriptions"(E)) > 1
    ),
    total_antithrombotic_prescriptions: Sum(
      "Numerator Encounters" E
        return Count("GetEarlyAntithromboticPrescriptions"(E))
    ),
    average_prescriptions_per_case: 
      if "Numerator" > 0
        then Round(
          Sum("Numerator Encounters" E return Count("GetEarlyAntithromboticPrescriptions"(E))) / "Numerator",
          2
        )
        else null
  }

// 性別統計
define "Gender Statistics":
  Tuple {
    male: Count("Denominator Encounters" E where Patient.gender = 'male'),
    female: Count("Denominator Encounters" E where Patient.gender = 'female'),
    male_with_treatment: Count("Numerator Encounters" E where Patient.gender = 'male'),
    female_with_treatment: Count("Numerator Encounters" E where Patient.gender = 'female')
  }

// 血栓溶解劑使用情況統計（排除案件分析）
define "Thrombolytic Exclusion Statistics":
  Tuple {
    total_ischemic_stroke_cases: Count("All Ischemic Stroke Encounters"),
    cases_with_thrombolytic: Count(
      "All Ischemic Stroke Encounters" E
        where "IsAdultAtEncounter"(E)
          and "HasThrombolyticTreatment"(E)
    ),
    cases_without_thrombolytic: "Denominator",
    thrombolytic_rate: 
      if Count("All Ischemic Stroke Encounters" E where "IsAdultAtEncounter"(E)) > 0
        then Round(
          Count("All Ischemic Stroke Encounters" E where "IsAdultAtEncounter"(E) and "HasThrombolyticTreatment"(E)) / 
          Count("All Ischemic Stroke Encounters" E where "IsAdultAtEncounter"(E)) * 100,
          2
        )
        else null
  }

// 住院天數統計（僅住院案件）
define "Length of Stay Statistics":
  Tuple {
    inpatient_los_1_3_days: Count(
      "Denominator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period >= 1 
          and days between start of E.period and end of E.period <= 3
    ),
    inpatient_los_4_7_days: Count(
      "Denominator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period >= 4 
          and days between start of E.period and end of E.period <= 7
    ),
    inpatient_los_8_14_days: Count(
      "Denominator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period >= 8 
          and days between start of E.period and end of E.period <= 14
    ),
    inpatient_los_over_14_days: Count(
      "Denominator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period > 14
    ),
    inpatient_los_1_3_with_treatment: Count(
      "Numerator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period >= 1 
          and days between start of E.period and end of E.period <= 3
    ),
    inpatient_los_4_7_with_treatment: Count(
      "Numerator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period >= 4 
          and days between start of E.period and end of E.period <= 7
    ),
    inpatient_los_8_14_with_treatment: Count(
      "Numerator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period >= 8 
          and days between start of E.period and end of E.period <= 14
    ),
    inpatient_los_over_14_with_treatment: Count(
      "Numerator Encounters" E 
        where E.type in "Inpatient Encounter Codes"
          and days between start of E.period and end of E.period > 14
    )
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '未使用血栓溶解劑治療之缺血性腦中風病人住院一日內給予抗血栓藥治療之比率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '急性缺血性中風未使用溶栓治療時，應盡早給予抗血栓藥物以降低再發風險',
    
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
    
    // Encounter類型統計
    encounter_type_statistics: "Encounter Type Statistics",
    
    // 診斷類型統計
    diagnosis_type_statistics: "Diagnosis Type Statistics",
    
    // I63詳細亞型統計
    i63_subtype_statistics: "I63 Subtype Statistics",
    
    // 抗血栓藥物類型統計
    antithrombotic_type_statistics: "Antithrombotic Type Statistics",
    
    // 常用抗血小板藥物統計
    antiplatelet_drug_statistics: "Antiplatelet Drug Statistics",
    
    // 年齡分組統計
    age_group_statistics: "Age Group Statistics",
    
    // 治療時機統計
    treatment_timing_statistics: "Treatment Timing Statistics",
    
    // 處方模式分析
    prescription_pattern_analysis: "Prescription Pattern Analysis",
    
    // 性別統計
    gender_statistics: "Gender Statistics",
    
    // 血栓溶解劑使用情況統計
    thrombolytic_exclusion_statistics: "Thrombolytic Exclusion Statistics",
    
    // 住院天數統計
    length_of_stay_statistics: "Length of Stay Statistics"
  }
