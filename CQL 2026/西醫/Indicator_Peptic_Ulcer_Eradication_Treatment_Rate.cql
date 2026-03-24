library Indicator_Peptic_Ulcer_Eradication_Treatment_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 消化性潰瘍病人接受除菌藥物治療比率
// 製作日期：2026-01-06

/*
 * 指標名稱: 消化性潰瘍病人接受除菌藥物治療比率
 * Indicator: Rate of Peptic Ulcer Patients Receiving Eradication Therapy
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 
 * 公式說明:
 * 分子: 接受除菌藥物治療人數，指消化性潰瘍新病患中，合併使用消化性潰瘍用藥(註2)及1種以上抗生素，
 *       持續使用7天以上之人數
 * 分母: 消化性潰瘍人數，指消化性潰瘍新病患(註1)人數
 * 
 * (註1) 消化性潰瘍新病患定義：
 * 在觀察期間，同時符合下列二項條件者，視為消化性潰瘍新病患：
 * 1. 前一年沒有因消化性潰瘍(主、次診斷前三碼為K25-K28)或重大傷病身份(申報部份負擔代號001)
 *    而就醫(門診、急診或住院)者
 * 2. 初次使用消化性潰瘍用藥且前4個月內有執行上消化道泛內視鏡檢查(28016C或33006B上消化道攝影)
 *    之門診個案
 * 
 * (註2) 消化性潰瘍用藥：
 * 1. 制酸懸浮劑：藥理分類代碼為560400或560499且藥品代碼最後二碼不為00或G0，
 *    再排除下列成份代碼5604001500、9600065500、4008000700(僅排除單方劑型)、
 *    5604002500(僅排除單方劑型)、5604002501(僅排除單方劑型)、5604002900(僅排除單方劑型)、
 *    5604001200(僅排除單方劑型)、5612001300(僅排除單方劑型)
 * 2. 組織胺受器拮抗劑(H2RA)：藥理分類代碼為560500之藥品品項
 * 3. 氫離子幫浦抑制劑(PPI)：藥理分類代碼為560900之藥品品項
 * 4. 細胞保護劑及其他消化性潰瘍用藥：藥理分類代碼為560700之藥品
 * 
 * 抗生素：藥理分類代碼J01FA09
 * 
 * 持續使用7天以上：合併使用消化性潰瘍用藥及抗生素，持續使用7天以上
 * 
 * 製作日期: 115/01/06
 */

-- ==================== Codesystem 定義 ====================

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHI_DRUG": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-drug-code'
codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_DRUG_CLASS": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-drug-classification'
codesystem "NHI_CATASTROPHIC": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-catastrophic-illness'

-- ==================== Code 定義 ====================

-- ICD-10-CM 消化性潰瘍診斷 (K25-K28)
code "Peptic_Ulcer_K25": 'K25' from "ICD10CM" display '胃潰瘍'
code "Peptic_Ulcer_K26": 'K26' from "ICD10CM" display '十二指腸潰瘍'
code "Peptic_Ulcer_K27": 'K27' from "ICD10CM" display '胃泌素瘤相關潰瘍'
code "Peptic_Ulcer_K28": 'K28' from "ICD10CM" display '胃空腸潰瘍'

-- 健保處置代碼 - 上消化道內視鏡檢查
code "NHI_Upper_GI_Endoscopy_28016C": '28016C' from "NHI_PROCEDURE" display '上消化道泛內視鏡檢查'
code "NHI_Upper_GI_Series_33006B": '33006B' from "NHI_PROCEDURE" display '上消化道攝影'

-- 重大傷病代號
code "Catastrophic_Illness_001": '001' from "NHI_CATASTROPHIC" display '重大傷病(部份負擔代號001)'

-- SNOMED CT - 消化性潰瘍
code "SNOMED_Peptic_Ulcer": '13200003' from "SNOMEDCT" display 'Peptic ulcer'
code "SNOMED_Gastric_Ulcer": '397825006' from "SNOMEDCT" display 'Gastric ulcer'
code "SNOMED_Duodenal_Ulcer": '397881002' from "SNOMEDCT" display 'Duodenal ulcer'

-- SNOMED CT - 幽門螺旋桿菌
code "SNOMED_H_Pylori": '80774000' from "SNOMEDCT" display 'Helicobacter pylori'
code "SNOMED_H_Pylori_Infection": '235653007' from "SNOMEDCT" display 'Helicobacter pylori infection'

-- ActCode
code "ActCode_Outpatient": 'AMB' from "ActCode" display '門診'
code "ActCode_Emergency": 'EMER' from "ActCode" display '急診'
code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'

-- ==================== ValueSet 定義 ====================

valueset "Peptic_Ulcer_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/peptic-ulcer-diagnosis'
valueset "Antacid_Medications_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/antacid-medications'
valueset "H2RA_Medications_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/h2ra-medications'
valueset "PPI_Medications_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/ppi-medications'
valueset "Cytoprotective_Medications_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cytoprotective-medications'
valueset "Antibiotic_J01FA09_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/antibiotic-j01fa09'

-- ==================== 參數 ====================

parameter "Measurement_Period" Interval<DateTime>
    default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.999]

parameter "Lookback_Period_1Year" Interval<DateTime>
    default Interval[start of "Measurement_Period" - 1 year, start of "Measurement_Period"]

parameter "Endoscopy_Lookback_Period_4Months" Interval<DateTime>
    default Interval[start of "Measurement_Period" - 4 months, end of "Measurement_Period"]

-- ==================== Context 定義 ====================

context Patient

-- ==================== 主要定義 ====================

/*
 * 定義1: 門診案件
 */
define "Outpatient_Encounters":
    [Encounter: type in "ActCode_Outpatient"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Outpatient"
            and E.period starts during "Measurement_Period"

/*
 * 定義2: 急診案件
 */
define "Emergency_Encounters":
    [Encounter: type in "ActCode_Emergency"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Emergency"
            and E.period starts during "Measurement_Period"

/*
 * 定義3: 住院案件
 */
define "Inpatient_Encounters":
    [Encounter: type in "ActCode_Inpatient"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Inpatient"
            and E.period ends during "Measurement_Period"

/*
 * 定義4: 所有就醫案件（門診、急診、住診）
 */
define "All_Encounters":
    "Outpatient_Encounters"
        union "Emergency_Encounters"
        union "Inpatient_Encounters"

/*
 * 定義5: 消化性潰瘍診斷 (K25-K28)
 */
define "Peptic_Ulcer_Diagnosis":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        StartsWith(Cod.code, 'K25')
                        or StartsWith(Cod.code, 'K26')
                        or StartsWith(Cod.code, 'K27')
                        or StartsWith(Cod.code, 'K28')
                    )
        )
        and C.verificationStatus ~ ToConcept(Code { code: 'confirmed', system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status' })

/*
 * 定義6: 前一年因消化性潰瘍就醫記錄
 */
define "Previous_Year_Peptic_Ulcer_Encounters":
    "All_Encounters" E
        where E.period starts during "Lookback_Period_1Year"
            and exists (
                "Peptic_Ulcer_Diagnosis" C
                    where C.encounter.reference = 'Encounter/' + E.id
            )

/*
 * 定義7: 前一年有重大傷病身份(代號001)
 */
define "Has_Catastrophic_Illness_Previous_Year":
    exists (
        [Coverage] Cov
            where exists (
                Cov.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/catastrophic-illness-code'
                        and Ex.valueCodeableConcept.coding.code = '001'
                        and Cov.period overlaps "Lookback_Period_1Year"
            )
    )

/*
 * 定義8: 上消化道內視鏡檢查 (28016C或33006B)
 */
define "Upper_GI_Endoscopy_Procedures":
    [Procedure] P
        where P.status = 'completed'
            and exists (
                P.code.coding Cod
                    where Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                        and Cod.code in { '28016C', '33006B' }
            )
            and (
                P.performedDateTime during "Endoscopy_Lookback_Period_4Months"
                or P.performedPeriod starts during "Endoscopy_Lookback_Period_4Months"
            )

/*
 * 定義9: 制酸懸浮劑 (560400或560499)
 * 藥品代碼最後二碼不為00或G0，排除特定成份代碼(僅排除單方劑型)
 */
define "Antacid_Medications":
    [MedicationRequest] M
        where M.status = 'completed'
            and exists (
                M.medicationCodeableConcept.coding Cod
                    where Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-drug-code'
                        and (
                            exists (
                                M.extension Ex
                                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drug-classification'
                                        and (
                                            Ex.valueCodeableConcept.coding.code = '560400'
                                            or Ex.valueCodeableConcept.coding.code = '560499'
                                        )
                            )
                        )
                        -- 檢查藥品代碼最後二碼不為00或G0
                        and not (
                            EndsWith(Cod.code, '00')
                            or EndsWith(Cod.code, 'G0')
                        )
                        -- 排除特定成份代碼(僅排除單方劑型)
                        and Cod.code not in {
                            '5604001500', '9600065500', '4008000700',
                            '5604002500', '5604002501', '5604002900',
                            '5604001200', '5612001300'
                        }
            )

/*
 * 定義10: 組織胺受器拮抗劑 (H2RA) - 560500
 */
define "H2RA_Medications":
    [MedicationRequest] M
        where M.status = 'completed'
            and exists (
                M.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drug-classification'
                        and Ex.valueCodeableConcept.coding.code = '560500'
            )

/*
 * 定義11: 氫離子幫浦抑制劑 (PPI) - 560900
 */
define "PPI_Medications":
    [MedicationRequest] M
        where M.status = 'completed'
            and exists (
                M.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drug-classification'
                        and Ex.valueCodeableConcept.coding.code = '560900'
            )

/*
 * 定義12: 細胞保護劑及其他消化性潰瘍用藥 - 560700
 */
define "Cytoprotective_Medications":
    [MedicationRequest] M
        where M.status = 'completed'
            and exists (
                M.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drug-classification'
                        and Ex.valueCodeableConcept.coding.code = '560700'
            )

/*
 * 定義13: 所有消化性潰瘍用藥
 */
define "All_Peptic_Ulcer_Medications":
    "Antacid_Medications"
        union "H2RA_Medications"
        union "PPI_Medications"
        union "Cytoprotective_Medications"

/*
 * 定義14: 抗生素 (J01FA09)
 */
define "Antibiotics_J01FA09":
    [MedicationRequest] M
        where M.status = 'completed'
            and exists (
                M.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/drug-classification'
                        and Ex.valueCodeableConcept.coding.code = 'J01FA09'
            )

/*
 * 定義15: 獲取藥物處方日期
 */
define function "Get_Medication_Date"(Med MedicationRequest):
    if Med.authoredOn is not null
    then Med.authoredOn
    else start of Med.dispenseRequest.validityPeriod

/*
 * 定義16: 計算藥物使用天數
 */
define function "Calculate_Medication_Days"(Med MedicationRequest):
    Coalesce(
        Med.dispenseRequest.expectedSupplyDuration.value,
        Coalesce(
            Med.dispenseRequest.quantity.value,
            1
        )
    )

/*
 * 定義17: 初次使用消化性潰瘍用藥的門診個案
 */
define "First_Time_Peptic_Ulcer_Medication_Outpatient":
    "Outpatient_Encounters" E
        let 
            ulcer_meds_in_encounter: 
                "All_Peptic_Ulcer_Medications" M
                    where M.encounter.reference = 'Encounter/' + E.id,
            first_med: First(ulcer_meds_in_encounter M sort by "Get_Medication_Date"(M)),
            first_med_date: "Get_Medication_Date"(first_med)
        where exists(ulcer_meds_in_encounter)
            -- 確認是初次使用（前一年無使用記錄）
            and not exists (
                "All_Peptic_Ulcer_Medications" PrevMed
                    where "Get_Medication_Date"(PrevMed) during "Lookback_Period_1Year"
            )
        return E

/*
 * 分母定義: 消化性潰瘍新病患人數
 * 
 * 條件:
 * 1. 前一年沒有因消化性潰瘍(K25-K28)就醫記錄
 * 2. 前一年無重大傷病身份(代號001)
 * 3. 初次使用消化性潰瘍用藥的門診個案
 * 4. 前4個月內有執行上消化道內視鏡檢查(28016C或33006B)
 */
define "Denominator":
    "First_Time_Peptic_Ulcer_Medication_Outpatient" E
        where not exists("Previous_Year_Peptic_Ulcer_Encounters")
            and not "Has_Catastrophic_Illness_Previous_Year"
            and exists (
                "Upper_GI_Endoscopy_Procedures" P
                    let 
                        endoscopy_date: 
                            if P.performedDateTime is not null
                            then P.performedDateTime
                            else start of P.performedPeriod,
                        encounter_date: start of E.period,
                        months_diff: months between endoscopy_date and encounter_date
                    where months_diff >= 0 and months_diff <= 4
            )

define "Denominator_Count":
    Count("Denominator")

/*
 * 定義18: 檢查是否合併使用消化性潰瘍用藥及抗生素持續7天以上
 */
define function "Has_Eradication_Therapy"(Enc Encounter):
    let 
        encounter_date: start of Enc.period,
        ulcer_meds: 
            "All_Peptic_Ulcer_Medications" M
                where M.encounter.reference = 'Encounter/' + Enc.id
                    or (
                        "Get_Medication_Date"(M) during Interval[encounter_date, encounter_date + 14 days]
                    ),
        antibiotics:
            "Antibiotics_J01FA09" A
                where A.encounter.reference = 'Encounter/' + Enc.id
                    or (
                        "Get_Medication_Date"(A) during Interval[encounter_date, encounter_date + 14 days]
                    ),
        total_ulcer_med_days: Sum(ulcer_meds M return "Calculate_Medication_Days"(M)),
        total_antibiotic_days: Sum(antibiotics A return "Calculate_Medication_Days"(A)),
        has_overlap: 
            exists(ulcer_meds) 
            and exists(antibiotics)
            and total_ulcer_med_days >= 7
            and total_antibiotic_days >= 7
    return has_overlap

/*
 * 分子定義: 接受除菌藥物治療人數
 * 
 * 條件:
 * 1. 符合分母條件
 * 2. 合併使用消化性潰瘍用藥(註2)及1種以上抗生素(J01FA09)
 * 3. 持續使用7天以上
 */
define "Numerator":
    "Denominator" E
        where "Has_Eradication_Therapy"(E)

define "Numerator_Count":
    Count("Numerator")

/*
 * 指標計算
 */
define "Indicator_Rate":
    if "Denominator_Count" > 0
    then Round(("Numerator_Count" / "Denominator_Count") * 100, 2)
    else null

-- ==================== 統計分析定義 ====================

/*
 * 統計1: 按消化性潰瘍用藥類型分組
 */
define "Medication_Type_Distribution":
    "Denominator" E
        let 
            has_antacid: exists("Antacid_Medications" M where M.encounter.reference = 'Encounter/' + E.id),
            has_h2ra: exists("H2RA_Medications" M where M.encounter.reference = 'Encounter/' + E.id),
            has_ppi: exists("PPI_Medications" M where M.encounter.reference = 'Encounter/' + E.id),
            has_cytoprotective: exists("Cytoprotective_Medications" M where M.encounter.reference = 'Encounter/' + E.id),
            has_eradication: "Has_Eradication_Therapy"(E)
        return {
            encounter_id: E.id,
            has_antacid: has_antacid,
            has_h2ra: has_h2ra,
            has_ppi: has_ppi,
            has_cytoprotective: has_cytoprotective,
            has_eradication_therapy: has_eradication,
            medication_types: 
                (if has_antacid then '制酸劑 ' else '') +
                (if has_h2ra then 'H2RA ' else '') +
                (if has_ppi then 'PPI ' else '') +
                (if has_cytoprotective then '細胞保護劑' else '')
        }

/*
 * 統計2: 按消化性潰瘍用藥類型摘要
 */
define "Medication_Type_Summary":
    {
        antacid_count: Count("Medication_Type_Distribution" D where D.has_antacid = true),
        h2ra_count: Count("Medication_Type_Distribution" D where D.has_h2ra = true),
        ppi_count: Count("Medication_Type_Distribution" D where D.has_ppi = true),
        cytoprotective_count: Count("Medication_Type_Distribution" D where D.has_cytoprotective = true),
        eradication_therapy_count: Count("Medication_Type_Distribution" D where D.has_eradication_therapy = true)
    }

/*
 * 統計3: 內視鏡檢查類型分布
 */
define "Endoscopy_Type_Distribution":
    "Denominator" E
        let 
            has_28016C: exists(
                "Upper_GI_Endoscopy_Procedures" P
                    where exists(P.code.coding C where C.code = '28016C')
            ),
            has_33006B: exists(
                "Upper_GI_Endoscopy_Procedures" P
                    where exists(P.code.coding C where C.code = '33006B')
            )
        return {
            encounter_id: E.id,
            has_endoscopy_28016C: has_28016C,
            has_upper_gi_series_33006B: has_33006B,
            endoscopy_type: 
                if has_28016C and has_33006B then '兩者皆有'
                else if has_28016C then '內視鏡檢查'
                else if has_33006B then '上消化道攝影'
                else '未知'
        }

/*
 * 統計4: 內視鏡檢查類型摘要
 */
define "Endoscopy_Type_Summary":
    {
        endoscopy_28016C: Count("Endoscopy_Type_Distribution" D where D.has_endoscopy_28016C = true),
        upper_gi_series_33006B: Count("Endoscopy_Type_Distribution" D where D.has_upper_gi_series_33006B = true),
        both: Count("Endoscopy_Type_Distribution" D where D.endoscopy_type = '兩者皆有')
    }

/*
 * 統計5: 藥物使用天數分布
 */
define "Medication_Days_Distribution":
    "Denominator" E
        let 
            ulcer_meds: "All_Peptic_Ulcer_Medications" M where M.encounter.reference = 'Encounter/' + E.id,
            antibiotics: "Antibiotics_J01FA09" A where A.encounter.reference = 'Encounter/' + E.id,
            total_ulcer_days: Sum(ulcer_meds M return "Calculate_Medication_Days"(M)),
            total_antibiotic_days: Sum(antibiotics A return "Calculate_Medication_Days"(A))
        return {
            encounter_id: E.id,
            ulcer_medication_days: total_ulcer_days,
            antibiotic_days: total_antibiotic_days,
            days_category: 
                if total_ulcer_days < 7 then '<7天'
                else if total_ulcer_days <= 10 then '7-10天'
                else if total_ulcer_days <= 14 then '11-14天'
                else '>14天',
            meets_7day_requirement: total_ulcer_days >= 7 and total_antibiotic_days >= 7
        }

/*
 * 統計6: 藥物使用天數摘要
 */
define "Medication_Days_Summary":
    {
        less_than_7_days: Count("Medication_Days_Distribution" D where D.days_category = '<7天'),
        days_7_to_10: Count("Medication_Days_Distribution" D where D.days_category = '7-10天'),
        days_11_to_14: Count("Medication_Days_Distribution" D where D.days_category = '11-14天'),
        more_than_14_days: Count("Medication_Days_Distribution" D where D.days_category = '>14天'),
        meets_requirement: Count("Medication_Days_Distribution" D where D.meets_7day_requirement = true)
    }

/*
 * 統計7: 診斷類型分布
 */
define "Diagnosis_Type_Distribution":
    "Denominator" E
        let 
            conditions: [Condition] C where C.encounter.reference = 'Encounter/' + E.id
        return {
            encounter_id: E.id,
            has_K25: exists(conditions C where exists(C.code.coding Cod where StartsWith(Cod.code, 'K25'))),
            has_K26: exists(conditions C where exists(C.code.coding Cod where StartsWith(Cod.code, 'K26'))),
            has_K27: exists(conditions C where exists(C.code.coding Cod where StartsWith(Cod.code, 'K27'))),
            has_K28: exists(conditions C where exists(C.code.coding Cod where StartsWith(Cod.code, 'K28')))
        }

/*
 * 統計8: 診斷類型摘要
 */
define "Diagnosis_Type_Summary":
    {
        gastric_ulcer_K25: Count("Diagnosis_Type_Distribution" D where D.has_K25 = true),
        duodenal_ulcer_K26: Count("Diagnosis_Type_Distribution" D where D.has_K26 = true),
        gastrinoma_ulcer_K27: Count("Diagnosis_Type_Distribution" D where D.has_K27 = true),
        gastrojejunal_ulcer_K28: Count("Diagnosis_Type_Distribution" D where D.has_K28 = true)
    }

-- ==================== 品質檢核定義 ====================

/*
 * 品質檢核1: 檢查前一年就醫記錄排除邏輯
 */
define "Quality_Check_Previous_Year_Exclusion":
    {
        total_first_time_ulcer_med: Count("First_Time_Peptic_Ulcer_Medication_Outpatient"),
        excluded_due_to_previous_encounter: Count(
            "First_Time_Peptic_Ulcer_Medication_Outpatient" E
                where exists("Previous_Year_Peptic_Ulcer_Encounters")
        ),
        excluded_due_to_catastrophic_illness: Count(
            "First_Time_Peptic_Ulcer_Medication_Outpatient" E
                where "Has_Catastrophic_Illness_Previous_Year"
        ),
        included_in_denominator: "Denominator_Count"
    }

/*
 * 品質檢核2: 檢查內視鏡檢查時間範圍
 */
define "Quality_Check_Endoscopy_Timing":
    "Denominator" E
        let 
            endoscopy_procedures: 
                "Upper_GI_Endoscopy_Procedures" P
                    let 
                        endoscopy_date: 
                            if P.performedDateTime is not null
                            then P.performedDateTime
                            else start of P.performedPeriod,
                        encounter_date: start of E.period,
                        months_diff: months between endoscopy_date and encounter_date
                    where months_diff >= 0 and months_diff <= 4
                    return {
                        procedure_id: P.id,
                        endoscopy_date: endoscopy_date,
                        encounter_date: encounter_date,
                        months_difference: months_diff
                    }
        return {
            encounter_id: E.id,
            endoscopy_count: Count(endoscopy_procedures),
            endoscopy_details: endoscopy_procedures
        }

/*
 * 品質檢核3: 檢查抗生素使用情況
 */
define "Quality_Check_Antibiotic_Usage":
    "Denominator" E
        let 
            antibiotics: "Antibiotics_J01FA09" A where A.encounter.reference = 'Encounter/' + E.id,
            antibiotic_count: Count(antibiotics),
            has_eradication: "Has_Eradication_Therapy"(E)
        return {
            encounter_id: E.id,
            antibiotic_count: antibiotic_count,
            has_antibiotics: antibiotic_count > 0,
            has_eradication_therapy: has_eradication,
            issue: 
                if antibiotic_count = 0 then '無使用抗生素'
                else if not has_eradication then '未達7天治療標準'
                else null
        }

/*
 * 品質檢核4: 檢查消化性潰瘍用藥使用情況
 */
define "Quality_Check_Ulcer_Medication_Usage":
    "Denominator" E
        let 
            ulcer_meds: "All_Peptic_Ulcer_Medications" M where M.encounter.reference = 'Encounter/' + E.id,
            med_count: Count(ulcer_meds),
            total_days: Sum(ulcer_meds M return "Calculate_Medication_Days"(M))
        return {
            encounter_id: E.id,
            medication_count: med_count,
            total_medication_days: total_days,
            meets_7day_requirement: total_days >= 7,
            issue:
                if med_count = 0 then '無消化性潰瘍用藥記錄'
                else if total_days < 7 then '用藥天數不足7天'
                else null
        }

/*
 * 品質檢核5: 整體品質檢核摘要
 */
define "Quality_Check_Summary":
    {
        previous_year_exclusion_info: "Quality_Check_Previous_Year_Exclusion",
        no_antibiotic_count: Count("Quality_Check_Antibiotic_Usage" Q where Q.has_antibiotics = false),
        insufficient_medication_days: Count("Quality_Check_Ulcer_Medication_Usage" Q where Q.meets_7day_requirement = false),
        no_eradication_therapy: Count("Quality_Check_Antibiotic_Usage" Q where Q.has_eradication_therapy = false)
    }

-- ==================== 最終結果輸出 ====================

/*
 * 最終指標結果
 */
define "Final_Result":
    {
        indicator_name: '消化性潰瘍病人接受除菌藥物治療比率',
        measurement_period: "Measurement_Period",
        denominator: "Denominator_Count",
        numerator: "Numerator_Count",
        rate_percentage: "Indicator_Rate",
        medication_type_summary: "Medication_Type_Summary",
        endoscopy_type_summary: "Endoscopy_Type_Summary",
        medication_days_summary: "Medication_Days_Summary",
        diagnosis_type_summary: "Diagnosis_Type_Summary",
        quality_check_summary: "Quality_Check_Summary"
    }
