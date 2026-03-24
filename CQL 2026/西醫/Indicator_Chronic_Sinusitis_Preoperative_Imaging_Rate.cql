library Indicator_Chronic_Sinusitis_Preoperative_Imaging_Rate version '1.0.0'

/*
十八歲以上慢性鼻竇炎病人於住院手術前三個月內有做電腦斷層造影或鼻竇內視鏡檢查比率
Chronic Sinusitis Preoperative Imaging Rate for Patients Aged 18 and Above

計算說明:
- 分子：接受手術前3個月內有做電腦斷層或鼻竇內視鏡檢查件數，係於統計期間接受鼻竇炎相關手術前3個月(0-90日)內，
        執行電腦斷層造影或鼻竇內視鏡檢查(註)的件數
- 分母：18歲以上慢性鼻竇炎接受手術件數，指於統計期間，18歲以上慢性鼻竇炎病人接受鼻竇炎相關手術(註)的件數
- 資料範圍：西醫醫院住院及門診資料
- 計算頻率：半年及年

備註:
1. 慢性鼻竇炎病人：指主診斷為J320、J321、J322、J323、J324、J328、J329
2. 鼻竇炎相關手術：囊令代碼為65063B、65064B、65025C、65030B、65012B、65037B、65052B、
                    65067B、65068B、65069B、65015B、65006B、65009B、65010B、65013B、65014B
3. 電腦斷層造影：囊令代碼為33070B、33071B、33072B
4. 鼻竇內視鏡檢查：囊令代碼為28003C
5. 術前3個月：0天≤手術囊令執行起日-檢查囊令執行起日≤90天
6. 年齡計算：病人門診就醫年月(或住診入院日)-出生年月≥216(個月)
7. 計算範圍：2026年(115年)資料

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

// 術前檢查期間（90天）
parameter "Preoperative Period Days" Integer default 90

// 年齡限制（216個月 = 18歲）
parameter "Minimum Age Months" Integer default 216

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'

// 慢性鼻竇炎診斷碼定義
code "J320": 'J320' from "ICD10CM" display 'Chronic maxillary sinusitis'
code "J321": 'J321' from "ICD10CM" display 'Chronic frontal sinusitis'
code "J322": 'J322' from "ICD10CM" display 'Chronic ethmoidal sinusitis'
code "J323": 'J323' from "ICD10CM" display 'Chronic sphenoidal sinusitis'
code "J324": 'J324' from "ICD10CM" display 'Chronic pansinusitis'
code "J328": 'J328' from "ICD10CM" display 'Other chronic sinusitis'
code "J329": 'J329' from "ICD10CM" display 'Chronic sinusitis, unspecified'

// 鼻竇炎相關手術碼（16個手術代碼）
code "65063B": '65063B' from "TWProcedure" display '鼻竇炎手術-65063B'
code "65064B": '65064B' from "TWProcedure" display '鼻竇炎手術-65064B'
code "65025C": '65025C' from "TWProcedure" display '鼻竇炎手術-65025C'
code "65030B": '65030B' from "TWProcedure" display '鼻竇炎手術-65030B'
code "65012B": '65012B' from "TWProcedure" display '鼻竇炎手術-65012B'
code "65037B": '65037B' from "TWProcedure" display '鼻竇炎手術-65037B'
code "65052B": '65052B' from "TWProcedure" display '鼻竇炎手術-65052B'
code "65067B": '65067B' from "TWProcedure" display '鼻竇炎手術-65067B'
code "65068B": '65068B' from "TWProcedure" display '鼻竇炎手術-65068B'
code "65069B": '65069B' from "TWProcedure" display '鼻竇炎手術-65069B'
code "65015B": '65015B' from "TWProcedure" display '鼻竇炎手術-65015B'
code "65006B": '65006B' from "TWProcedure" display '鼻竇炎手術-65006B'
code "65009B": '65009B' from "TWProcedure" display '鼻竇炎手術-65009B'
code "65010B": '65010B' from "TWProcedure" display '鼻竇炎手術-65010B'
code "65013B": '65013B' from "TWProcedure" display '鼻竇炎手術-65013B'
code "65014B": '65014B' from "TWProcedure" display '鼻竇炎手術-65014B'

// 電腦斷層造影代碼（3個CT代碼）
code "33070B": '33070B' from "TWProcedure" display 'CT掃描-33070B'
code "33071B": '33071B' from "TWProcedure" display 'CT掃描-33071B'
code "33072B": '33072B' from "TWProcedure" display 'CT掃描-33072B'

// 鼻竇內視鏡檢查代碼
code "28003C": '28003C' from "TWProcedure" display '鼻竇內視鏡檢查'

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

// 所有Encounter（住院+門診）
define "All Encounters":
  "All Inpatient Encounters" union "All Outpatient Encounters"

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有Procedure
define "All Procedures":
  [Procedure] P

// ===== 診斷判斷函數 =====

// 判斷Condition是否為慢性鼻竇炎（J320-J329）
define function "IsChronicSinusitisDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          C.code = 'J320'
          or C.code = 'J321'
          or C.code = 'J322'
          or C.code = 'J323'
          or C.code = 'J324'
          or C.code = 'J328'
          or C.code = 'J329'
        )
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

// ===== 手術與檢查判斷函數 =====

// 判斷Procedure是否為鼻竇炎相關手術（16個手術代碼）
define function "IsSinusitisSurgery"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
          and (
            C.code = '65063B'
            or C.code = '65064B'
            or C.code = '65025C'
            or C.code = '65030B'
            or C.code = '65012B'
            or C.code = '65037B'
            or C.code = '65052B'
            or C.code = '65067B'
            or C.code = '65068B'
            or C.code = '65069B'
            or C.code = '65015B'
            or C.code = '65006B'
            or C.code = '65009B'
            or C.code = '65010B'
            or C.code = '65013B'
            or C.code = '65014B'
          )
    )

// 判斷Procedure是否為電腦斷層造影（3個CT代碼）
define function "IsCTScan"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
          and (
            C.code = '33070B'
            or C.code = '33071B'
            or C.code = '33072B'
          )
    )

// 判斷Procedure是否為鼻竇內視鏡檢查
define function "IsNasalEndoscopy"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
          and C.code = '28003C'
    )

// 判斷Procedure是否為術前影像檢查（CT或內視鏡）
define function "IsPreoperativeImaging"(procedure Procedure):
  "IsCTScan"(procedure) or "IsNasalEndoscopy"(procedure)

// 取得Procedure執行日期
define function "GetProcedureDate"(procedure Procedure):
  Coalesce(
    start of procedure.performed as Period,
    procedure.performed as dateTime
  )

// ===== 年齡計算 =====

// 計算病人在特定日期的年齡（以月為單位）
define function "GetAgeInMonthsAt"(date DateTime):
  months between Patient.birthDate and date from date

// 判斷病人在特定日期是否≥18歲（≥216個月）
define function "IsAdultAt"(date DateTime):
  "GetAgeInMonthsAt"(date) >= "Minimum Age Months"

// ===== 分母定義 =====

// 所有鼻竇炎相關手術
define "All Sinusitis Surgeries":
  "All Procedures" P
    where "IsSinusitisSurgery"(P)
      and "GetProcedureDate"(P) during "Measurement Period"

// 取得手術對應的Encounter
define function "GetSurgeryEncounter"(surgery Procedure):
  singleton from (
    "All Encounters" E
      where E.id = Last(Split(surgery.encounter.reference, '/'))
  )

// 分母：18歲以上慢性鼻竇炎接受手術件數
define "Denominator Surgeries":
  "All Sinusitis Surgeries" S
    let surgeryEncounter: "GetSurgeryEncounter"(S),
        surgeryDate: "GetProcedureDate"(S)
    where surgeryEncounter is not null
      and "HasChronicSinusitisPrimaryDiagnosis"(surgeryEncounter)
      and "IsAdultAt"(surgeryDate)

// 分母（總案件數）
define "Denominator":
  Count("Denominator Surgeries")

// 分母（第一期）
define "Denominator Period 1":
  Count(
    "Denominator Surgeries" S
      where "GetProcedureDate"(S) during "Period 1"
  )

// 分母（第二期）
define "Denominator Period 2":
  Count(
    "Denominator Surgeries" S
      where "GetProcedureDate"(S) during "Period 2"
  )

// ===== 術前檢查判斷 =====

// 計算術前檢查期間（手術前0-90天）
define function "GetPreoperativePeriod"(surgeryDate DateTime):
  Interval[surgeryDate - "Preoperative Period Days" days, surgeryDate]

// 判斷手術前是否有影像檢查（CT或內視鏡）
define function "HasPreoperativeImaging"(surgery Procedure):
  let surgeryDate: "GetProcedureDate"(surgery),
      preoperativePeriod: "GetPreoperativePeriod"(surgeryDate)
  return
    exists(
      "All Procedures" P
        where P.subject.reference = surgery.subject.reference
          and "IsPreoperativeImaging"(P)
          and "GetProcedureDate"(P) in preoperativePeriod
          and days between "GetProcedureDate"(P) and surgeryDate >= 0
          and days between "GetProcedureDate"(P) and surgeryDate <= "Preoperative Period Days"
    )

// 取得手術前的影像檢查（CT或內視鏡）
define function "GetPreoperativeImagingProcedures"(surgery Procedure):
  let surgeryDate: "GetProcedureDate"(surgery),
      preoperativePeriod: "GetPreoperativePeriod"(surgeryDate)
  return
    "All Procedures" P
      where P.subject.reference = surgery.subject.reference
        and "IsPreoperativeImaging"(P)
        and "GetProcedureDate"(P) in preoperativePeriod
        and days between "GetProcedureDate"(P) and surgeryDate >= 0
        and days between "GetProcedureDate"(P) and surgeryDate <= "Preoperative Period Days"

// ===== 分子定義 =====

// 分子：手術前3個月內有做電腦斷層或鼻竇內視鏡檢查的案件
define "Numerator Surgeries":
  "Denominator Surgeries" S
    where "HasPreoperativeImaging"(S)

// 分子（符合條件案件數）
define "Numerator":
  Count("Numerator Surgeries")

// 分子（第一期）
define "Numerator Period 1":
  Count(
    "Numerator Surgeries" S
      where "GetProcedureDate"(S) during "Period 1"
  )

// 分子（第二期）
define "Numerator Period 2":
  Count(
    "Numerator Surgeries" S
      where "GetProcedureDate"(S) during "Period 2"
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
    total_encounters: Count("All Encounters"),
    total_procedures: Count("All Procedures"),
    chronic_sinusitis_encounters: Count("All Encounters" E where "HasChronicSinusitisPrimaryDiagnosis"(E)),
    total_sinusitis_surgeries: Count("All Sinusitis Surgeries"),
    age_under_18_exclusions: Count(
      "All Sinusitis Surgeries" S
        where not "IsAdultAt"("GetProcedureDate"(S))
    ),
    non_chronic_sinusitis_exclusions: Count(
      "All Sinusitis Surgeries" S
        let surgeryEncounter: "GetSurgeryEncounter"(S)
        where surgeryEncounter is not null
          and not "HasChronicSinusitisPrimaryDiagnosis"(surgeryEncounter)
    ),
    qualified_surgeries: "Denominator",
    surgeries_with_preoperative_imaging: "Numerator"
  }

// 影像檢查類型統計
define "Imaging Type Statistics":
  Tuple {
    total_with_imaging: "Numerator",
    ct_scan_only: Count(
      "Numerator Surgeries" S
        let imagingProcs: "GetPreoperativeImagingProcedures"(S)
        where exists(imagingProcs P where "IsCTScan"(P))
          and not exists(imagingProcs P where "IsNasalEndoscopy"(P))
    ),
    endoscopy_only: Count(
      "Numerator Surgeries" S
        let imagingProcs: "GetPreoperativeImagingProcedures"(S)
        where exists(imagingProcs P where "IsNasalEndoscopy"(P))
          and not exists(imagingProcs P where "IsCTScan"(P))
    ),
    both_ct_and_endoscopy: Count(
      "Numerator Surgeries" S
        let imagingProcs: "GetPreoperativeImagingProcedures"(S)
        where exists(imagingProcs P where "IsCTScan"(P))
          and exists(imagingProcs P where "IsNasalEndoscopy"(P))
    )
  }

// 手術類型統計
define "Surgery Type Statistics":
  Tuple {
    surgery_65063B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65063B')),
    surgery_65064B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65064B')),
    surgery_65025C: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65025C')),
    surgery_65030B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65030B')),
    surgery_65012B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65012B')),
    surgery_65037B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65037B')),
    surgery_65052B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65052B')),
    surgery_65067B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65067B')),
    surgery_65068B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65068B')),
    surgery_65069B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65069B')),
    surgery_65015B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65015B')),
    surgery_65006B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65006B')),
    surgery_65009B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65009B')),
    surgery_65010B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65010B')),
    surgery_65013B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65013B')),
    surgery_65014B: Count("Denominator Surgeries" S where exists(S.code.coding C where C.code = '65014B'))
  }

// 診斷類型統計
define "Diagnosis Type Statistics":
  Tuple {
    J320_maxillary: Count("Denominator Surgeries" S let enc: "GetSurgeryEncounter"(S) where exists("All Conditions" C where C.encounter.reference = 'Encounter/' + enc.id and exists(C.code.coding CD where CD.code = 'J320'))),
    J321_frontal: Count("Denominator Surgeries" S let enc: "GetSurgeryEncounter"(S) where exists("All Conditions" C where C.encounter.reference = 'Encounter/' + enc.id and exists(C.code.coding CD where CD.code = 'J321'))),
    J322_ethmoidal: Count("Denominator Surgeries" S let enc: "GetSurgeryEncounter"(S) where exists("All Conditions" C where C.encounter.reference = 'Encounter/' + enc.id and exists(C.code.coding CD where CD.code = 'J322'))),
    J323_sphenoidal: Count("Denominator Surgeries" S let enc: "GetSurgeryEncounter"(S) where exists("All Conditions" C where C.encounter.reference = 'Encounter/' + enc.id and exists(C.code.coding CD where CD.code = 'J323'))),
    J324_pansinusitis: Count("Denominator Surgeries" S let enc: "GetSurgeryEncounter"(S) where exists("All Conditions" C where C.encounter.reference = 'Encounter/' + enc.id and exists(C.code.coding CD where CD.code = 'J324'))),
    J328_other: Count("Denominator Surgeries" S let enc: "GetSurgeryEncounter"(S) where exists("All Conditions" C where C.encounter.reference = 'Encounter/' + enc.id and exists(C.code.coding CD where CD.code = 'J328'))),
    J329_unspecified: Count("Denominator Surgeries" S let enc: "GetSurgeryEncounter"(S) where exists("All Conditions" C where C.encounter.reference = 'Encounter/' + enc.id and exists(C.code.coding CD where CD.code = 'J329')))
  }

// 年齡分組統計
define "Age Group Statistics":
  Tuple {
    age_18_44: Count("Denominator Surgeries" S where "GetAgeInMonthsAt"("GetProcedureDate"(S)) >= 216 and "GetAgeInMonthsAt"("GetProcedureDate"(S)) < 540),
    age_45_64: Count("Denominator Surgeries" S where "GetAgeInMonthsAt"("GetProcedureDate"(S)) >= 540 and "GetAgeInMonthsAt"("GetProcedureDate"(S)) < 780),
    age_65_plus: Count("Denominator Surgeries" S where "GetAgeInMonthsAt"("GetProcedureDate"(S)) >= 780),
    age_18_44_with_imaging: Count("Numerator Surgeries" S where "GetAgeInMonthsAt"("GetProcedureDate"(S)) >= 216 and "GetAgeInMonthsAt"("GetProcedureDate"(S)) < 540),
    age_45_64_with_imaging: Count("Numerator Surgeries" S where "GetAgeInMonthsAt"("GetProcedureDate"(S)) >= 540 and "GetAgeInMonthsAt"("GetProcedureDate"(S)) < 780),
    age_65_plus_with_imaging: Count("Numerator Surgeries" S where "GetAgeInMonthsAt"("GetProcedureDate"(S)) >= 780)
  }

// 檢查時機分析（手術前幾天進行檢查）
define "Imaging Timing Analysis":
  "Numerator Surgeries" S
    let surgeryDate: "GetProcedureDate"(S),
        imagingProcs: "GetPreoperativeImagingProcedures"(S),
        firstImaging: First(imagingProcs sort by "GetProcedureDate"(this)),
        lastImaging: Last(imagingProcs sort by "GetProcedureDate"(this))
    return Tuple {
      patient_id: Patient.id,
      surgery_date: ToString(surgeryDate),
      first_imaging_date: ToString("GetProcedureDate"(firstImaging)),
      last_imaging_date: ToString("GetProcedureDate"(lastImaging)),
      days_before_surgery_first: days between "GetProcedureDate"(firstImaging) and surgeryDate,
      days_before_surgery_last: days between "GetProcedureDate"(lastImaging) and surgeryDate,
      total_imaging_procedures: Count(imagingProcs),
      has_ct: exists(imagingProcs P where "IsCTScan"(P)),
      has_endoscopy: exists(imagingProcs P where "IsNasalEndoscopy"(P))
    }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '十八歲以上慢性鼻竇炎病人於住院手術前三個月內有做電腦斷層造影或鼻竇內視鏡檢查比率',
    measurement_period: ToString("Measurement Period"),
    
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
    
    // 影像檢查類型統計
    imaging_type_statistics: "Imaging Type Statistics",
    
    // 手術類型統計
    surgery_type_statistics: "Surgery Type Statistics",
    
    // 診斷類型統計
    diagnosis_type_statistics: "Diagnosis Type Statistics",
    
    // 年齡分組統計
    age_group_statistics: "Age Group Statistics",
    
    // 檢查時機分析（前10筆樣本）
    timing_analysis_sample: "Imaging Timing Analysis"
  }
