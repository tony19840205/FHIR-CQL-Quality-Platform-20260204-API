library Indicator_Adult_Chronic_Sinusitis_Fluoroquinolone_Use_Rate version '1.0.0'

/*
成人於慢性鼻竇炎使用氟化恩喹類抗生素(Fluoroquinolones)案件比率
Adult Chronic Sinusitis Fluoroquinolone Use Rate

計算說明:
- 分子：分母案件中，使用氟化恩喹類抗生素的案件
- 分母：成人診斷為慢性鼻竇炎的門診案件
- 資料範圍：西醫基層+西醫醫院門診資料
- 計算頻率：半年及年

備註:
1. 資料範圍：
   a. 為門診(西醫基層+西醫醫院)，排除代號案件：案件分類為A3,B1,B6,B7,B8,B9,C4,D1,D2,HN,BA,DF
   b. 排除「補報原因註記」為2的案件
2. 成人：18歲以上（費用年-出生年≥18）
3. 慢性鼻竇炎：主診斷前三碼為J32
4. 氟化恩喹類抗生素fluoroquinolones：藥品ATC碼前五碼為J01MA
5. 臨床意義：Fluoroquinolones不應作為慢性鼻竇炎的首選抗生素，此指標監測不當使用情況
6. 計算範圍：2026年(115年)資料

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

// 慢性鼻竇炎診斷碼定義 (J32系列)
code "J32": 'J32' from "ICD10CM" display 'Chronic sinusitis'

// 排除案件分類代碼
valueset "Excluded Claim Types": 'http://example.org/fhir/ValueSet/excluded-claim-types'
// A3, B1, B6, B7, B8, B9, C4, D1, D2, HN, BA, DF

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 門診Encounter編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// ===== 排除條件函數 =====

// 判斷Encounter是否為排除的案件分類
define function "IsExcludedClaimType"(encounter Encounter):
  exists(
    encounter.type T
      where exists(
        T.coding C
          where C.code in {
            'A3', 'B1', 'B6', 'B7', 'B8', 'B9', 
            'C4', 'D1', 'D2', 'HN', 'BA', 'DF'
          }
      )
  )

// 判斷Encounter是否有補報原因註記為2（需透過extension檢查）
define function "HasSupplementaryReportReason2"(encounter Encounter):
  exists(
    encounter.extension Ext
      where Ext.url = 'http://example.org/fhir/StructureDefinition/supplementary-report-reason'
        and Ext.value as string = '2'
  )

// ===== 診斷判斷函數 =====

// 判斷Condition是否為慢性鼻竇炎（J32前三碼）
define function "IsChronicSinusitisDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and StartsWith(C.code, 'J32')
  )

// 判斷Encounter是否有慢性鼻竇炎主診斷
define function "HasChronicSinusitisPrimaryDiagnosis"(encounter Encounter):
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
        and "IsChronicSinusitisDiagnosis"(C)
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

// 計算病人在特定日期的年齡（以年為單位）
define function "GetAgeInYearsAt"(date DateTime):
  AgeInYearsAt(date from date)

// 判斷病人在特定日期是否≥18歲
define function "IsAdultAt"(date DateTime):
  "GetAgeInYearsAt"(date) >= "Minimum Age"

// ===== 分母定義 =====

// 分母：成人診斷為慢性鼻竇炎的門診案件（排除特定案件分類和補報）
define "Denominator Encounters":
  "All Outpatient Encounters" E
    where "HasChronicSinusitisPrimaryDiagnosis"(E)
      and "IsAdultAt"(start of E.period)
      and not "IsExcludedClaimType"(E)
      and not "HasSupplementaryReportReason2"(E)

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

// ===== 氟化恩喹類抗生素判斷 =====

// 判斷MedicationRequest是否為Fluoroquinolone抗生素（ATC碼前五碼為J01MA）
define function "IsFluoroquinolone"(medication MedicationRequest):
  medication.status in {'active', 'completed'}
    and exists(
      medication.medication as CodeableConcept MC
        return MC.coding C
          where C.system = 'http://www.whocc.no/atc'
            and StartsWith(C.code, 'J01MA')
    )

// 判斷Encounter是否有開立Fluoroquinolone處方
define function "HasFluoroquinolonePrescription"(encounter Encounter):
  exists(
    "All Medication Requests" M
      where M.encounter.reference = 'Encounter/' + encounter.id
        and "IsFluoroquinolone"(M)
  )

// 取得Encounter的Fluoroquinolone處方
define function "GetFluoroquinolonePrescriptions"(encounter Encounter):
  "All Medication Requests" M
    where M.encounter.reference = 'Encounter/' + encounter.id
      and "IsFluoroquinolone"(M)

// ===== 分子定義 =====

// 分子：使用氟化恩喹類抗生素的案件
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasFluoroquinolonePrescription"(E)

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
    total_outpatient_encounters: Count("All Outpatient Encounters"),
    chronic_sinusitis_encounters: Count("All Outpatient Encounters" E where "HasChronicSinusitisPrimaryDiagnosis"(E)),
    excluded_claim_types: Count("All Outpatient Encounters" E where "IsExcludedClaimType"(E)),
    supplementary_report_reason_2: Count("All Outpatient Encounters" E where "HasSupplementaryReportReason2"(E)),
    age_under_18_exclusions: Count(
      "All Outpatient Encounters" E 
        where "HasChronicSinusitisPrimaryDiagnosis"(E) 
          and not "IsAdultAt"(start of E.period)
    ),
    qualified_adult_sinusitis_cases: "Denominator",
    cases_with_fluoroquinolone: "Numerator"
  }

// Fluoroquinolone具體藥品統計（ATC J01MA次分類）
define "Fluoroquinolone Type Statistics":
  Tuple {
    total_with_fluoroquinolone: "Numerator",
    J01MA01_ofloxacin: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA01')
            )
        )
    ),
    J01MA02_ciprofloxacin: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA02')
            )
        )
    ),
    J01MA03_pefloxacin: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA03')
            )
        )
    ),
    J01MA04_enoxacin: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA04')
            )
        )
    ),
    J01MA06_norfloxacin: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA06')
            )
        )
    ),
    J01MA12_levofloxacin: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA12')
            )
        )
    ),
    J01MA14_moxifloxacin: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA14')
            )
        )
    ),
    other_fluoroquinolones: Count(
      "Numerator Encounters" E
        where exists(
          "GetFluoroquinolonePrescriptions"(E) M
            where exists(
              M.medication as CodeableConcept MC
                return MC.coding C
                  where StartsWith(C.code, 'J01MA')
                    and not StartsWith(C.code, 'J01MA01')
                    and not StartsWith(C.code, 'J01MA02')
                    and not StartsWith(C.code, 'J01MA03')
                    and not StartsWith(C.code, 'J01MA04')
                    and not StartsWith(C.code, 'J01MA06')
                    and not StartsWith(C.code, 'J01MA12')
                    and not StartsWith(C.code, 'J01MA14')
            )
        )
    )
  }

// 慢性鼻竇炎診斷細分統計（J32次分類）
define "Sinusitis Diagnosis Type Statistics":
  Tuple {
    J320_chronic_maxillary: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J320'))
        )
    ),
    J321_chronic_frontal: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J321'))
        )
    ),
    J322_chronic_ethmoidal: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J322'))
        )
    ),
    J323_chronic_sphenoidal: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J323'))
        )
    ),
    J324_chronic_pansinusitis: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J324'))
        )
    ),
    J328_other_chronic_sinusitis: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J328'))
        )
    ),
    J329_chronic_sinusitis_unspecified: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J329'))
        )
    )
  }

// 年齡分組統計
define "Age Group Statistics":
  Tuple {
    age_18_44: Count("Denominator Encounters" E where "GetAgeInYearsAt"(start of E.period) >= 18 and "GetAgeInYearsAt"(start of E.period) <= 44),
    age_45_64: Count("Denominator Encounters" E where "GetAgeInYearsAt"(start of E.period) >= 45 and "GetAgeInYearsAt"(start of E.period) <= 64),
    age_65_plus: Count("Denominator Encounters" E where "GetAgeInYearsAt"(start of E.period) >= 65),
    age_18_44_with_fluoroquinolone: Count("Numerator Encounters" E where "GetAgeInYearsAt"(start of E.period) >= 18 and "GetAgeInYearsAt"(start of E.period) <= 44),
    age_45_64_with_fluoroquinolone: Count("Numerator Encounters" E where "GetAgeInYearsAt"(start of E.period) >= 45 and "GetAgeInYearsAt"(start of E.period) <= 64),
    age_65_plus_with_fluoroquinolone: Count("Numerator Encounters" E where "GetAgeInYearsAt"(start of E.period) >= 65)
  }

// 處方分析（每個案件的fluoroquinolone處方數量）
define "Prescription Pattern Analysis":
  Tuple {
    cases_with_single_prescription: Count(
      "Numerator Encounters" E
        where Count("GetFluoroquinolonePrescriptions"(E)) = 1
    ),
    cases_with_multiple_prescriptions: Count(
      "Numerator Encounters" E
        where Count("GetFluoroquinolonePrescriptions"(E)) > 1
    ),
    total_fluoroquinolone_prescriptions: Sum(
      "Numerator Encounters" E
        return Count("GetFluoroquinolonePrescriptions"(E))
    ),
    average_prescriptions_per_case: 
      if "Numerator" > 0
        then Round(
          Sum("Numerator Encounters" E return Count("GetFluoroquinolonePrescriptions"(E))) / "Numerator",
          2
        )
        else null
  }

// 科別統計（如果有科別資訊）
define "Specialty Statistics":
  Tuple {
    primary_care: Count(
      "Denominator Encounters" E
        where exists(
          E.participant P
            where exists(
              P.type T
                where exists(
                  T.coding C
                    where C.code = 'primary-care'
                )
            )
        )
    ),
    ent_specialty: Count(
      "Denominator Encounters" E
        where exists(
          E.participant P
            where exists(
              P.type T
                where exists(
                  T.coding C
                    where C.code = 'ent'
                )
            )
        )
    ),
    other_specialties: Count(
      "Denominator Encounters" E
        where not exists(
          E.participant P
            where exists(
              P.type T
                where exists(
                  T.coding C
                    where C.code in {'primary-care', 'ent'}
                )
            )
        )
    )
  }

// 急性與慢性鼻竇炎比較（同時有急性和慢性診斷的案件）
define "Acute vs Chronic Comparison":
  Tuple {
    chronic_only: Count(
      "Denominator Encounters" E
        where not exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J01'))
        )
    ),
    chronic_with_acute_history: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'J01'))
        )
    )
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '成人於慢性鼻竇炎使用氟化恩喹類抗生素(Fluoroquinolones)案件比率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: 'Fluoroquinolones不應作為慢性鼻竇炎的首選抗生素，此指標用於監測不當使用情況',
    
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
    
    // Fluoroquinolone類型統計
    fluoroquinolone_type_statistics: "Fluoroquinolone Type Statistics",
    
    // 鼻竇炎診斷類型統計
    sinusitis_diagnosis_type_statistics: "Sinusitis Diagnosis Type Statistics",
    
    // 年齡分組統計
    age_group_statistics: "Age Group Statistics",
    
    // 處方模式分析
    prescription_pattern_analysis: "Prescription Pattern Analysis",
    
    // 科別統計
    specialty_statistics: "Specialty Statistics",
    
    // 急性與慢性比較
    acute_vs_chronic_comparison: "Acute vs Chronic Comparison"
  }
