library Indicator_Uterine_Fibroid_Surgery_Hospitalization_Over_7Days_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 子宮肌瘤手術當次住院日數大於七日比率
// 製作日期：2026-01-06

/*
 * 指標名稱: 子宮肌瘤手術當次住院日數大於七日比率
 * Indicator: Rate of Uterine Fibroid Surgery with Hospital Stay Over 7 Days
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 資料範圍: 西醫醫院、西醫基層
 * 
 * 公式說明:
 * 分子: 分母案件住院天數大於7日之人次數
 * 分母: 申報子宮肌瘤診斷(排除癌症診斷)且有施行子宮肌瘤摘除或子宮切除手術治療住院人次數
 * 
 * 子宮肌瘤診斷: 住診案件任一主次診斷之ICD-10-CM前3碼為D25
 * 
 * 癌症診斷: 門、住診案件任一主、次診斷ICD-10-CM前3碼為C00-C96(但排除C944、C946)、D37-D48、
 *           全碼為Z5112、J8481
 *           (在判斷該婦女是否有癌症診斷時，需用其ID住前6個月的門住診資料來判斷，此部分為跨院勾稽。)
 * 
 * 子宮肌瘤摘除術: 住診案件，醫令類別2、醫令代碼97010K、97011A、97012B、97013B、80402C、
 *                 80420C、80415B、97013C、80415C、80425C
 * 
 * 子宮切除術: 住診案件，醫令類別2、醫令代碼97025K、97026A、97027B、97020K、97021A、97022B、
 *             97035K、97036A、97037B、80403B、80404B、80421B、80416B、80412B、97027C、80404C
 * 
 * 住院天數大於7日: 當次住院急性病床天數 + 當次住院慢性病床天數 > 7
 * 
 * 子宮肌瘤診斷與手術(子宮肌瘤摘除或子宮切除手術)需限定發生在同一清單案件(同案件分類、流水號)
 * 
 * 製作日期: 115/01/06
 */

-- ==================== Codesystem 定義 ====================

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ICD10PCS": 'http://hl7.org/fhir/sid/icd-10-pcs'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
codesystem "NHI_PROCEDURE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "LOINC": 'http://loinc.org'
codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'

-- ==================== Code 定義 ====================

-- ICD-10-CM 子宮肌瘤診斷 (D25)
code "Uterine_Leiomyoma_D25": 'D25' from "ICD10CM" display '子宮平滑肌瘤(子宮肌瘤)'
code "Uterine_Leiomyoma_D250": 'D25.0' from "ICD10CM" display '子宮體部之黏膜下平滑肌瘤'
code "Uterine_Leiomyoma_D251": 'D25.1' from "ICD10CM" display '子宮體部之壁內平滑肌瘤'
code "Uterine_Leiomyoma_D252": 'D25.2' from "ICD10CM" display '子宮體部之漿膜下平滑肌瘤'
code "Uterine_Leiomyoma_D259": 'D25.9' from "ICD10CM" display '子宮平滑肌瘤，未明示部位'

-- ICD-10-CM 癌症診斷 (排除項目)
-- C00-C96 (惡性腫瘤，但排除C944、C946)
code "Cancer_Exclusion_C944": 'C94.4' from "ICD10CM" display '急性全骨髓性白血病(排除)'
code "Cancer_Exclusion_C946": 'C94.6' from "ICD10CM" display '骨髓增生性疾病(排除)'

-- D37-D48 (不確定或未知性質之腫瘤)
code "Cancer_Neoplasm_D37": 'D37' from "ICD10CM" display '口腔及消化器官之不確定或未知性質之腫瘤'
code "Cancer_Neoplasm_D48": 'D48' from "ICD10CM" display '其他及未明示部位之不確定或未知性質之腫瘤'

-- Z51.12, J84.81
code "Cancer_Chemo_Z5112": 'Z51.12' from "ICD10CM" display '抗腫瘤化學治療之後續照護'
code "Cancer_Related_J8481": 'J84.81' from "ICD10CM" display '淋巴管平滑肌瘤病'

-- 健保處置代碼 - 子宮肌瘤摘除術
code "NHI_Myomectomy_97010K": '97010K' from "NHI_PROCEDURE" display '子宮肌瘤摘除術-腹腔鏡'
code "NHI_Myomectomy_97011A": '97011A' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_97012B": '97012B' from "NHI_PROCEDURE" display '子宮肌瘤摘除術(含腹腔鏡)'
code "NHI_Myomectomy_97013B": '97013B' from "NHI_PROCEDURE" display '腹腔鏡子宮肌瘤摘除術'
code "NHI_Myomectomy_80402C": '80402C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_80420C": '80420C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術(腹腔鏡)'
code "NHI_Myomectomy_80415B": '80415B' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_97013C": '97013C' from "NHI_PROCEDURE" display '腹腔鏡子宮肌瘤摘除術'
code "NHI_Myomectomy_80415C": '80415C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術'
code "NHI_Myomectomy_80425C": '80425C' from "NHI_PROCEDURE" display '子宮肌瘤摘除術(腹腔鏡)'

-- 健保處置代碼 - 子宮切除術
code "NHI_Hysterectomy_97025K": '97025K' from "NHI_PROCEDURE" display '子宮切除術-腹腔鏡'
code "NHI_Hysterectomy_97026A": '97026A' from "NHI_PROCEDURE" display '子宮切除術'
code "NHI_Hysterectomy_97027B": '97027B' from "NHI_PROCEDURE" display '子宮切除術(含腹腔鏡)'
code "NHI_Hysterectomy_97020K": '97020K' from "NHI_PROCEDURE" display '全子宮切除術-腹腔鏡'
code "NHI_Hysterectomy_97021A": '97021A' from "NHI_PROCEDURE" display '全子宮切除術'
code "NHI_Hysterectomy_97022B": '97022B' from "NHI_PROCEDURE" display '全子宮切除術(含腹腔鏡)'
code "NHI_Hysterectomy_97035K": '97035K' from "NHI_PROCEDURE" display '次全子宮切除術-腹腔鏡'
code "NHI_Hysterectomy_97036A": '97036A' from "NHI_PROCEDURE" display '次全子宮切除術'
code "NHI_Hysterectomy_97037B": '97037B' from "NHI_PROCEDURE" display '次全子宮切除術(含腹腔鏡)'
code "NHI_Hysterectomy_80403B": '80403B' from "NHI_PROCEDURE" display '子宮切除術'
code "NHI_Hysterectomy_80404B": '80404B' from "NHI_PROCEDURE" display '子宮切除術(腹腔鏡)'
code "NHI_Hysterectomy_80421B": '80421B' from "NHI_PROCEDURE" display '全子宮切除術'
code "NHI_Hysterectomy_80416B": '80416B' from "NHI_PROCEDURE" display '子宮切除術'
code "NHI_Hysterectomy_80412B": '80412B' from "NHI_PROCEDURE" display '次全子宮切除術'
code "NHI_Hysterectomy_97027C": '97027C' from "NHI_PROCEDURE" display '子宮切除術(腹腔鏡)'
code "NHI_Hysterectomy_80404C": '80404C' from "NHI_PROCEDURE" display '子宮切除術(腹腔鏡)'

-- SNOMED CT - 子宮肌瘤
code "SNOMED_Uterine_Leiomyoma": '95315005' from "SNOMEDCT" display 'Leiomyoma of uterus'
code "SNOMED_Fibroid_Uterus": '78000009' from "SNOMEDCT" display 'Fibroid uterus'

-- SNOMED CT - 子宮肌瘤摘除術
code "SNOMED_Myomectomy": '176697007' from "SNOMEDCT" display 'Myomectomy'
code "SNOMED_Laparoscopic_Myomectomy": '69712005' from "SNOMEDCT" display 'Laparoscopic myomectomy'

-- SNOMED CT - 子宮切除術
code "SNOMED_Hysterectomy": '236886002' from "SNOMEDCT" display 'Hysterectomy'
code "SNOMED_Total_Hysterectomy": '116140006' from "SNOMEDCT" display 'Total hysterectomy'
code "SNOMED_Subtotal_Hysterectomy": '387643005' from "SNOMEDCT" display 'Subtotal hysterectomy'
code "SNOMED_Laparoscopic_Hysterectomy": '446446002' from "SNOMEDCT" display 'Laparoscopic hysterectomy'

-- CPT - 子宮肌瘤摘除術
code "CPT_Myomectomy_58140": '58140' from "CPT" display 'Myomectomy, excision of fibroid tumor(s) of uterus'
code "CPT_Myomectomy_58145": '58145' from "CPT" display 'Myomectomy, excision of fibroid tumor(s), with total weight > 250 grams'
code "CPT_Myomectomy_58146": '58146' from "CPT" display 'Myomectomy, excision of fibroid tumor(s), with total weight > 250 grams, with removal of tube(s) and/or ovary(s)'

-- CPT - 子宮切除術
code "CPT_Hysterectomy_58150": '58150' from "CPT" display 'Total abdominal hysterectomy'
code "CPT_Hysterectomy_58180": '58180' from "CPT" display 'Supracervical abdominal hysterectomy'
code "CPT_Hysterectomy_58260": '58260' from "CPT" display 'Vaginal hysterectomy'
code "CPT_Hysterectomy_58550": '58550' from "CPT" display 'Laparoscopy, surgical, with vaginal hysterectomy'
code "CPT_Hysterectomy_58570": '58570' from "CPT" display 'Laparoscopy, surgical, with total hysterectomy'

-- ActCode
code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'

-- ==================== ValueSet 定義 ====================

valueset "Uterine_Leiomyoma_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/uterine-leiomyoma-diagnosis'
valueset "Cancer_Exclusion_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-exclusion'
valueset "Myomectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/myomectomy-procedures'
valueset "Hysterectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hysterectomy-procedures'

-- ==================== 參數 ====================

parameter "Measurement_Period" Interval<DateTime>
    default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.999]

parameter "Cancer_Lookback_Period" Interval<DateTime>
    default Interval[start of "Measurement_Period" - 6 months, end of "Measurement_Period"]

-- ==================== Context 定義 ====================

context Patient

-- ==================== 主要定義 ====================

/*
 * 定義1: 住院案件（西醫醫院、西醫基層）
 */
define "Inpatient_Encounters":
    [Encounter: type in "ActCode_Inpatient"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Inpatient"
            and E.period ends during "Measurement_Period"

/*
 * 定義2: 子宮肌瘤診斷（D25）
 * 住診案件任一主次診斷之ICD-10-CM前3碼為D25
 */
define "Has_Uterine_Leiomyoma_Diagnosis":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        Cod.code ~ 'D25'
                        or Cod.code ~ 'D25.0'
                        or Cod.code ~ 'D25.1'
                        or Cod.code ~ 'D25.2'
                        or Cod.code ~ 'D25.9'
                        or StartsWith(Cod.code, 'D25')
                    )
        )
        and C.verificationStatus ~ ToConcept(Code { code: 'confirmed', system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status' })

/*
 * 定義3: 癌症診斷 (門、住診案件，前6個月)
 * C00-C96 (但排除C944、C946), D37-D48, Z51.12, J84.81
 */
define "Has_Cancer_Diagnosis":
    exists (
        [Condition] C
            where (
                exists (
                    C.code.coding Cod
                        where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                            and (
                                -- C00-C96 範圍 (排除C944、C946)
                                (
                                    (Cod.code >= 'C00' and Cod.code <= 'C96.Z')
                                    and Cod.code != 'C94.4'
                                    and Cod.code != 'C94.6'
                                    and not StartsWith(Cod.code, 'C94.4')
                                    and not StartsWith(Cod.code, 'C94.6')
                                )
                                -- D37-D48 範圍
                                or (Cod.code >= 'D37' and Cod.code <= 'D48.9')
                                or StartsWith(Cod.code, 'D37')
                                or StartsWith(Cod.code, 'D38')
                                or StartsWith(Cod.code, 'D39')
                                or StartsWith(Cod.code, 'D40')
                                or StartsWith(Cod.code, 'D41')
                                or StartsWith(Cod.code, 'D42')
                                or StartsWith(Cod.code, 'D43')
                                or StartsWith(Cod.code, 'D44')
                                or StartsWith(Cod.code, 'D45')
                                or StartsWith(Cod.code, 'D46')
                                or StartsWith(Cod.code, 'D47')
                                or StartsWith(Cod.code, 'D48')
                                -- Z51.12 全碼
                                or Cod.code = 'Z51.12'
                                -- J84.81 全碼
                                or Cod.code = 'J84.81'
                            )
                )
            )
            and C.verificationStatus ~ ToConcept(Code { code: 'confirmed', system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status' })
            and (
                C.recordedDate during "Cancer_Lookback_Period"
                or C.onsetDateTime during "Cancer_Lookback_Period"
            )
    )

/*
 * 定義4: 子宮肌瘤摘除術
 * 住診案件，醫令類別2，醫令代碼97010K、97011A、97012B、97013B、80402C、
 * 80420C、80415B、97013C、80415C、80425C
 */
define "Myomectomy_Procedures":
    [Procedure] P
        where P.status = 'completed'
            and exists (
                P.code.coding Cod
                    where Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                        and Cod.code in {
                            '97010K', '97011A', '97012B', '97013B', '80402C',
                            '80420C', '80415B', '97013C', '80415C', '80425C'
                        }
            )

/*
 * 定義5: 子宮切除術
 * 住診案件，醫令類別2，醫令代碼97025K、97026A、97027B、97020K、97021A、97022B、
 * 97035K、97036A、97037B、80403B、80404B、80421B、80416B、80412B、97027C、80404C
 */
define "Hysterectomy_Procedures":
    [Procedure] P
        where P.status = 'completed'
            and exists (
                P.code.coding Cod
                    where Cod.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure'
                        and Cod.code in {
                            '97025K', '97026A', '97027B', '97020K', '97021A', '97022B',
                            '97035K', '97036A', '97037B', '80403B', '80404B', '80421B',
                            '80416B', '80412B', '97027C', '80404C'
                        }
            )

/*
 * 定義6: 所有子宮肌瘤相關手術（摘除或切除）
 */
define "All_Fibroid_Surgeries":
    "Myomectomy_Procedures"
        union "Hysterectomy_Procedures"

/*
 * 定義7: 住院天數計算
 * 當次住院急性病床天數 + 當次住院慢性病床天數
 */
define function "Calculate_Hospital_Days"(Enc Encounter):
    Coalesce(
        (
            singleton from (
                Enc.hospitalization.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/acute-bed-days'
                    return Ex.valueInteger
            )
        ), 0
    ) +
    Coalesce(
        (
            singleton from (
                Enc.hospitalization.extension Ex
                    where Ex.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/chronic-bed-days'
                    return Ex.valueInteger
            )
        ), 0
    )

/*
 * 定義8: 計算標準住院天數（使用period計算）
 * 如果沒有extension，則使用encounter.period計算
 */
define function "Calculate_Standard_Hospital_Days"(Enc Encounter):
    if Enc.period.start is not null and Enc.period.end is not null
    then difference in days between Enc.period.start and Enc.period.end + 1
    else 0

/*
 * 分母定義: 申報子宮肌瘤診斷(排除癌症診斷)且有施行子宮肌瘤摘除或子宮切除手術治療住院人次數
 * 
 * 條件:
 * 1. 住院案件
 * 2. 有子宮肌瘤診斷 (D25)
 * 3. 無癌症診斷 (前6個月門住診資料)
 * 4. 有子宮肌瘤摘除術或子宮切除術
 * 5. 診斷與手術需在同一次住院
 */
define "Denominator":
    "Inpatient_Encounters" E
        where exists (
            "Has_Uterine_Leiomyoma_Diagnosis" C
                where C.encounter.reference = 'Encounter/' + E.id
        )
        and not "Has_Cancer_Diagnosis"
        and exists (
            "All_Fibroid_Surgeries" P
                where P.encounter.reference = 'Encounter/' + E.id
        )

define "Denominator_Count":
    Count("Denominator")

/*
 * 分子定義: 分母案件住院天數大於7日之人次數
 * 
 * 條件:
 * 1. 符合分母條件
 * 2. 當次住院急性病床天數 + 當次住院慢性病床天數 > 7
 */
define "Numerator":
    "Denominator" E
        where (
            "Calculate_Hospital_Days"(E) > 7
            or "Calculate_Standard_Hospital_Days"(E) > 7
        )

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
 * 統計1: 按住院天數分組統計
 */
define "Hospital_Days_Distribution":
    "Denominator" E
        let days: Coalesce("Calculate_Hospital_Days"(E), "Calculate_Standard_Hospital_Days"(E))
        return {
            encounter_id: E.id,
            hospital_days: days,
            days_category: 
                if days <= 3 then '1-3天'
                else if days <= 5 then '4-5天'
                else if days <= 7 then '6-7天'
                else if days <= 10 then '8-10天'
                else if days <= 14 then '11-14天'
                else '15天以上',
            over_7_days: days > 7
        }

/*
 * 統計2: 住院天數摘要
 */
define "Hospital_Days_Summary":
    {
        total_cases: "Denominator_Count",
        cases_over_7_days: "Numerator_Count",
        rate_over_7_days: "Indicator_Rate",
        days_1_to_3: Count("Hospital_Days_Distribution" D where D.days_category = '1-3天'),
        days_4_to_5: Count("Hospital_Days_Distribution" D where D.days_category = '4-5天'),
        days_6_to_7: Count("Hospital_Days_Distribution" D where D.days_category = '6-7天'),
        days_8_to_10: Count("Hospital_Days_Distribution" D where D.days_category = '8-10天'),
        days_11_to_14: Count("Hospital_Days_Distribution" D where D.days_category = '11-14天'),
        days_15_plus: Count("Hospital_Days_Distribution" D where D.days_category = '15天以上')
    }

/*
 * 統計3: 按手術類型分組
 */
define "Surgery_Type_Distribution":
    "Denominator" E
        let 
            has_myomectomy: exists("Myomectomy_Procedures" P where P.encounter.reference = 'Encounter/' + E.id),
            has_hysterectomy: exists("Hysterectomy_Procedures" P where P.encounter.reference = 'Encounter/' + E.id),
            days: Coalesce("Calculate_Hospital_Days"(E), "Calculate_Standard_Hospital_Days"(E))
        return {
            encounter_id: E.id,
            surgery_type: 
                if has_myomectomy and has_hysterectomy then '摘除+切除'
                else if has_myomectomy then '肌瘤摘除'
                else if has_hysterectomy then '子宮切除'
                else '未知',
            hospital_days: days,
            over_7_days: days > 7
        }

/*
 * 統計4: 按手術類型的住院天數統計
 */
define "Surgery_Type_Summary":
    {
        myomectomy_only: {
            total: Count("Surgery_Type_Distribution" D where D.surgery_type = '肌瘤摘除'),
            over_7_days: Count("Surgery_Type_Distribution" D where D.surgery_type = '肌瘤摘除' and D.over_7_days = true),
            rate: 
                let total: Count("Surgery_Type_Distribution" D where D.surgery_type = '肌瘤摘除'),
                    over_7: Count("Surgery_Type_Distribution" D where D.surgery_type = '肌瘤摘除' and D.over_7_days = true)
                return if total > 0 then Round((over_7 / total) * 100, 2) else null
        },
        hysterectomy_only: {
            total: Count("Surgery_Type_Distribution" D where D.surgery_type = '子宮切除'),
            over_7_days: Count("Surgery_Type_Distribution" D where D.surgery_type = '子宮切除' and D.over_7_days = true),
            rate: 
                let total: Count("Surgery_Type_Distribution" D where D.surgery_type = '子宮切除'),
                    over_7: Count("Surgery_Type_Distribution" D where D.surgery_type = '子宮切除' and D.over_7_days = true)
                return if total > 0 then Round((over_7 / total) * 100, 2) else null
        },
        both_surgeries: {
            total: Count("Surgery_Type_Distribution" D where D.surgery_type = '摘除+切除'),
            over_7_days: Count("Surgery_Type_Distribution" D where D.surgery_type = '摘除+切除' and D.over_7_days = true),
            rate: 
                let total: Count("Surgery_Type_Distribution" D where D.surgery_type = '摘除+切除'),
                    over_7: Count("Surgery_Type_Distribution" D where D.surgery_type = '摘除+切除' and D.over_7_days = true)
                return if total > 0 then Round((over_7 / total) * 100, 2) else null
        }
    }

/*
 * 統計5: 診斷類型分布
 */
define "Diagnosis_Type_Distribution":
    "Denominator" E
        let 
            conditions: [Condition] C where C.encounter.reference = 'Encounter/' + E.id,
            days: Coalesce("Calculate_Hospital_Days"(E), "Calculate_Standard_Hospital_Days"(E))
        return {
            encounter_id: E.id,
            has_D250: exists(conditions C where exists(C.code.coding Cod where Cod.code ~ 'D25.0' or StartsWith(Cod.code, 'D25.0'))),
            has_D251: exists(conditions C where exists(C.code.coding Cod where Cod.code ~ 'D25.1' or StartsWith(Cod.code, 'D25.1'))),
            has_D252: exists(conditions C where exists(C.code.coding Cod where Cod.code ~ 'D25.2' or StartsWith(Cod.code, 'D25.2'))),
            has_D259: exists(conditions C where exists(C.code.coding Cod where Cod.code ~ 'D25.9' or StartsWith(Cod.code, 'D25.9'))),
            hospital_days: days,
            over_7_days: days > 7
        }

-- ==================== 品質檢核定義 ====================

/*
 * 品質檢核1: 檢查是否有住院天數資料
 */
define "Quality_Check_Missing_Hospital_Days":
    "Denominator" E
        where "Calculate_Hospital_Days"(E) = 0
            and "Calculate_Standard_Hospital_Days"(E) = 0
        return {
            encounter_id: E.id,
            issue: '缺少住院天數資料',
            encounter_period: E.period
        }

/*
 * 品質檢核2: 檢查是否有異常長的住院天數 (>30天)
 */
define "Quality_Check_Abnormal_Long_Stay":
    "Denominator" E
        let days: Coalesce("Calculate_Hospital_Days"(E), "Calculate_Standard_Hospital_Days"(E))
        where days > 30
        return {
            encounter_id: E.id,
            hospital_days: days,
            issue: '住院天數異常過長 (>30天)',
            encounter_period: E.period
        }

/*
 * 品質檢核3: 檢查分母案件的癌症排除邏輯
 */
define "Quality_Check_Cancer_Exclusion":
    {
        total_with_fibroid_diagnosis: Count([Condition] C 
            where exists(C.code.coding Cod where StartsWith(Cod.code, 'D25'))),
        excluded_due_to_cancer: Count([Condition] C 
            where exists(C.code.coding Cod where StartsWith(Cod.code, 'D25'))
                and "Has_Cancer_Diagnosis"),
        included_in_denominator: "Denominator_Count"
    }

/*
 * 品質檢核4: 檢查手術與住院的關聯性
 */
define "Quality_Check_Surgery_Encounter_Link":
    "All_Fibroid_Surgeries" P
        where P.encounter is null
            or not exists("Inpatient_Encounters" E where 'Encounter/' + E.id = P.encounter.reference)
        return {
            procedure_id: P.id,
            procedure_code: First(P.code.coding).code,
            issue: '手術未正確關聯到住院案件',
            encounter_reference: P.encounter.reference
        }

/*
 * 品質檢核5: 整體品質檢核摘要
 */
define "Quality_Check_Summary":
    {
        missing_hospital_days_count: Count("Quality_Check_Missing_Hospital_Days"),
        abnormal_long_stay_count: Count("Quality_Check_Abnormal_Long_Stay"),
        unlinked_surgeries_count: Count("Quality_Check_Surgery_Encounter_Link"),
        cancer_exclusion_info: "Quality_Check_Cancer_Exclusion"
    }

-- ==================== 最終結果輸出 ====================

/*
 * 最終指標結果
 */
define "Final_Result":
    {
        indicator_name: '子宮肌瘤手術當次住院日數大於七日比率',
        measurement_period: "Measurement_Period",
        denominator: "Denominator_Count",
        numerator: "Numerator_Count",
        rate_percentage: "Indicator_Rate",
        hospital_days_summary: "Hospital_Days_Summary",
        surgery_type_summary: "Surgery_Type_Summary",
        quality_check_summary: "Quality_Check_Summary"
    }
