library Indicator_Uterine_Fibroid_Surgery_Organ_Injury_14Days_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 子宮肌瘤手術出院後十四日以內相關器官損傷發生率
// 製作日期：2026-01-06

/*
 * 指標名稱: 子宮肌瘤手術出院後十四日以內相關器官損傷發生率
 * Indicator: Rate of Related Organ Injury within 14 Days after Uterine Fibroid Surgery
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 資料範圍: 西醫醫院、西醫基層
 * 
 * 公式說明:
 * 分子: 分母案件出院14日內門、住診有相關器官之損傷診斷人次數
 * 分母: 申報子宮肌瘤診斷(排除癌症診斷)且有施行子宮肌瘤摘除或子宮切除手術治療住院人次數
 * 
 * 子宮肌瘤診斷: 住診案件任一主次診斷之ICD-10-CM前3碼為D25
 * 
 * 癌症診斷: 門、住診案件任一主、次診斷ICD-10-CM前3碼為C00-C96(但排除C944、C946)、D37-D48、
 *           全碼為Z5112、J8481
 *           (在判斷該婦女是否有癌症診斷時，需用其ID住前6個月的門住診資料來判斷，此部分為跨院勾稽。)
 * 
 * 子宮肌瘤摘除術: 住診案件，醫令類別2且醫令代碼97010K、97011A、97012B、97013B、80402C、
 *                 80420C、80415B、97013C、80415C、80425C
 * 
 * 子宮切除術: 住診案件，醫令類別2且醫令代碼97025K、97026A、97027B、97020K、97021A、97022B、
 *             97035K、97036A、97037B、80403B、80404B、80421B、80416B、80412B、97027C、80404C
 * 
 * 相關器官之損傷包含:
 * 1. 腎盂輸尿管損傷: 門、住診案件任一主、次診斷ICD-10-CM前四碼S371-S379(第7位碼為"A")
 * 2. 腎臟道損傷: 門、住診案件任一主、次診斷ICD-10-CM前四碼S363-S364(第7位碼為"A")
 * 
 * 14日內發生率勾稽方式:
 * 門診:(門診就醫日期 - 手術當次住院出院日) <= 14(跨院)
 * 住診:(再次住院入院日 - 手術當次住院出院日) <= 14(跨院)
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
code "Cancer_Exclusion_C944": 'C94.4' from "ICD10CM" display '急性全骨髓性白血病(排除)'
code "Cancer_Exclusion_C946": 'C94.6' from "ICD10CM" display '骨髓增生性疾病(排除)'
code "Cancer_Neoplasm_D37": 'D37' from "ICD10CM" display '口腔及消化器官之不確定或未知性質之腫瘤'
code "Cancer_Neoplasm_D48": 'D48' from "ICD10CM" display '其他及未明示部位之不確定或未知性質之腫瘤'
code "Cancer_Chemo_Z5112": 'Z51.12' from "ICD10CM" display '抗腫瘤化學治療之後續照護'
code "Cancer_Related_J8481": 'J84.81' from "ICD10CM" display '淋巴管平滑肌瘤病'

-- ICD-10-CM 相關器官損傷診斷
-- 腎盂輸尿管損傷 (S371-S379, 第7位碼為"A")
code "Ureter_Injury_S371": 'S371' from "ICD10CM" display '腎盂損傷'
code "Ureter_Injury_S372": 'S372' from "ICD10CM" display '輸尿管損傷'
code "Ureter_Injury_S373": 'S373' from "ICD10CM" display '尿道損傷'
code "Ureter_Injury_S374": 'S374' from "ICD10CM" display '卵巢損傷'
code "Ureter_Injury_S375": 'S375' from "ICD10CM" display '輸卵管損傷'
code "Ureter_Injury_S376": 'S376' from "ICD10CM" display '子宮損傷'
code "Ureter_Injury_S377": 'S377' from "ICD10CM" display '多個骨盆腔器官損傷'
code "Ureter_Injury_S378": 'S378' from "ICD10CM" display '其他骨盆腔器官損傷'
code "Ureter_Injury_S379": 'S379' from "ICD10CM" display '未明示之骨盆腔器官損傷'

-- 腎臟道損傷 (S363-S364, 第7位碼為"A")
code "Kidney_Injury_S363": 'S363' from "ICD10CM" display '輸尿管損傷'
code "Kidney_Injury_S364": 'S364' from "ICD10CM" display '卵巢損傷'

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

-- SNOMED CT - 器官損傷
code "SNOMED_Ureteral_Injury": '262532001' from "SNOMEDCT" display 'Injury of ureter'
code "SNOMED_Kidney_Injury": '125603002' from "SNOMEDCT" display 'Injury of kidney'
code "SNOMED_Bladder_Injury": '262588009' from "SNOMEDCT" display 'Injury of urinary bladder'
code "SNOMED_Bowel_Injury": '125608006' from "SNOMEDCT" display 'Injury of intestine'

-- ActCode
code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'
code "ActCode_Outpatient": 'AMB' from "ActCode" display '門診'

-- ==================== ValueSet 定義 ====================

valueset "Uterine_Leiomyoma_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/uterine-leiomyoma-diagnosis'
valueset "Cancer_Exclusion_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-exclusion'
valueset "Myomectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/myomectomy-procedures'
valueset "Hysterectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hysterectomy-procedures'
valueset "Organ_Injury_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/organ-injury-diagnosis'

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
 * 定義2: 門診案件（西醫醫院、西醫基層）
 */
define "Outpatient_Encounters":
    [Encounter: type in "ActCode_Outpatient"] E
        where E.status = 'finished'
            and E.class ~ "ActCode_Outpatient"
            and E.period starts during "Measurement_Period"

/*
 * 定義3: 所有就醫案件（門診+住診）
 */
define "All_Encounters":
    "Inpatient_Encounters"
        union "Outpatient_Encounters"

/*
 * 定義4: 子宮肌瘤診斷（D25）
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
 * 定義5: 癌症診斷 (門、住診案件，前6個月)
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
 * 定義6: 子宮肌瘤摘除術
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
 * 定義7: 子宮切除術
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
 * 定義8: 所有子宮肌瘤相關手術（摘除或切除）
 */
define "All_Fibroid_Surgeries":
    "Myomectomy_Procedures"
        union "Hysterectomy_Procedures"

/*
 * 定義9: 相關器官損傷診斷
 * 1. 腎盂輸尿管損傷：S371-S379 (第7位碼為"A")
 * 2. 腎臟道損傷：S363-S364 (第7位碼為"A")
 */
define "Organ_Injury_Diagnosis":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        -- S371-S379 腎盂輸尿管損傷 (第7位碼為A)
                        (
                            (
                                StartsWith(Cod.code, 'S371')
                                or StartsWith(Cod.code, 'S372')
                                or StartsWith(Cod.code, 'S373')
                                or StartsWith(Cod.code, 'S374')
                                or StartsWith(Cod.code, 'S375')
                                or StartsWith(Cod.code, 'S376')
                                or StartsWith(Cod.code, 'S377')
                                or StartsWith(Cod.code, 'S378')
                                or StartsWith(Cod.code, 'S379')
                            )
                            and (
                                Length(Cod.code) >= 7
                                and Substring(Cod.code, 6, 1) = 'A'
                            )
                        )
                        -- S363-S364 腎臟道損傷 (第7位碼為A)
                        or (
                            (
                                StartsWith(Cod.code, 'S363')
                                or StartsWith(Cod.code, 'S364')
                            )
                            and (
                                Length(Cod.code) >= 7
                                and Substring(Cod.code, 6, 1) = 'A'
                            )
                        )
                    )
        )
        and C.verificationStatus ~ ToConcept(Code { code: 'confirmed', system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status' })

/*
 * 定義10: 獲取住院出院日期
 */
define function "Get_Discharge_Date"(Enc Encounter):
    end of Enc.period

/*
 * 定義11: 獲取門診就醫日期
 */
define function "Get_Outpatient_Visit_Date"(Enc Encounter):
    start of Enc.period

/*
 * 定義12: 獲取住院入院日期
 */
define function "Get_Admission_Date"(Enc Encounter):
    start of Enc.period

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
 * 分子定義: 分母案件出院14日內門、住診有相關器官之損傷診斷人次數
 * 
 * 14日內發生率勾稽方式:
 * 門診:(門診就醫日期 - 手術當次住院出院日) <= 14(跨院)
 * 住診:(再次住院入院日 - 手術當次住院出院日) <= 14(跨院)
 */
define "Numerator":
    "Denominator" DenomEnc
        where exists (
            "All_Encounters" FollowUpEnc
                let 
                    discharge_date: "Get_Discharge_Date"(DenomEnc),
                    followup_date: 
                        if FollowUpEnc.class ~ "ActCode_Outpatient"
                        then "Get_Outpatient_Visit_Date"(FollowUpEnc)
                        else "Get_Admission_Date"(FollowUpEnc),
                    days_diff: difference in days between discharge_date and followup_date
                where days_diff >= 0 
                    and days_diff <= 14
                    and exists (
                        "Organ_Injury_Diagnosis" InjuryCond
                            where InjuryCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
                    )
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
 * 統計1: 損傷類型分布
 */
define "Injury_Type_Distribution":
    "Numerator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            injury_encounters: 
                "All_Encounters" FollowUpEnc
                    let 
                        followup_date: 
                            if FollowUpEnc.class ~ "ActCode_Outpatient"
                            then "Get_Outpatient_Visit_Date"(FollowUpEnc)
                            else "Get_Admission_Date"(FollowUpEnc),
                        days_diff: difference in days between discharge_date and followup_date
                    where days_diff >= 0 
                        and days_diff <= 14
                        and exists (
                            "Organ_Injury_Diagnosis" InjuryCond
                                where InjuryCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
                        )
        return {
            denominator_encounter_id: DenomEnc.id,
            injury_encounters: injury_encounters,
            has_ureter_injury: exists(
                injury_encounters InjEnc
                    where exists (
                        "Organ_Injury_Diagnosis" C
                            where C.encounter.reference = 'Encounter/' + InjEnc.id
                                and exists (
                                    C.code.coding Cod
                                        where StartsWith(Cod.code, 'S371')
                                            or StartsWith(Cod.code, 'S372')
                                            or StartsWith(Cod.code, 'S373')
                                            or StartsWith(Cod.code, 'S374')
                                            or StartsWith(Cod.code, 'S375')
                                            or StartsWith(Cod.code, 'S376')
                                            or StartsWith(Cod.code, 'S377')
                                            or StartsWith(Cod.code, 'S378')
                                            or StartsWith(Cod.code, 'S379')
                                )
                    )
            ),
            has_kidney_injury: exists(
                injury_encounters InjEnc
                    where exists (
                        "Organ_Injury_Diagnosis" C
                            where C.encounter.reference = 'Encounter/' + InjEnc.id
                                and exists (
                                    C.code.coding Cod
                                        where StartsWith(Cod.code, 'S363')
                                            or StartsWith(Cod.code, 'S364')
                                )
                    )
            )
        }

/*
 * 統計2: 損傷發生時機分布（門診 vs 住診）
 */
define "Injury_Encounter_Type_Distribution":
    "Numerator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            outpatient_injuries: Count(
                "Outpatient_Encounters" OutEnc
                    let days_diff: difference in days between discharge_date and "Get_Outpatient_Visit_Date"(OutEnc)
                    where days_diff >= 0 
                        and days_diff <= 14
                        and exists (
                            "Organ_Injury_Diagnosis" InjuryCond
                                where InjuryCond.encounter.reference = 'Encounter/' + OutEnc.id
                        )
            ),
            inpatient_injuries: Count(
                "Inpatient_Encounters" InpEnc
                    let days_diff: difference in days between discharge_date and "Get_Admission_Date"(InpEnc)
                    where days_diff >= 0 
                        and days_diff <= 14
                        and InpEnc.id != DenomEnc.id
                        and exists (
                            "Organ_Injury_Diagnosis" InjuryCond
                                where InjuryCond.encounter.reference = 'Encounter/' + InpEnc.id
                        )
            )
        return {
            denominator_encounter_id: DenomEnc.id,
            outpatient_injury_count: outpatient_injuries,
            inpatient_injury_count: inpatient_injuries,
            total_injury_count: outpatient_injuries + inpatient_injuries,
            injury_type: 
                if outpatient_injuries > 0 and inpatient_injuries > 0 then '門診+住診'
                else if outpatient_injuries > 0 then '門診'
                else if inpatient_injuries > 0 then '住診'
                else '無'
        }

/*
 * 統計3: 損傷發生天數分布
 */
define "Injury_Days_Distribution":
    "Numerator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            injury_days: 
                "All_Encounters" FollowUpEnc
                    let 
                        followup_date: 
                            if FollowUpEnc.class ~ "ActCode_Outpatient"
                            then "Get_Outpatient_Visit_Date"(FollowUpEnc)
                            else "Get_Admission_Date"(FollowUpEnc),
                        days_diff: difference in days between discharge_date and followup_date
                    where days_diff >= 0 
                        and days_diff <= 14
                        and exists (
                            "Organ_Injury_Diagnosis" InjuryCond
                                where InjuryCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
                        )
                    return days_diff,
            min_days: Min(injury_days)
        return {
            denominator_encounter_id: DenomEnc.id,
            earliest_injury_days: min_days,
            days_category: 
                if min_days <= 3 then '0-3天'
                else if min_days <= 7 then '4-7天'
                else if min_days <= 10 then '8-10天'
                else '11-14天'
        }

/*
 * 統計4: 按手術類型的損傷發生率
 */
define "Surgery_Type_Injury_Distribution":
    "Denominator" E
        let 
            has_myomectomy: exists("Myomectomy_Procedures" P where P.encounter.reference = 'Encounter/' + E.id),
            has_hysterectomy: exists("Hysterectomy_Procedures" P where P.encounter.reference = 'Encounter/' + E.id),
            has_injury: exists(
                "Numerator" N where N.id = E.id
            )
        return {
            encounter_id: E.id,
            surgery_type: 
                if has_myomectomy and has_hysterectomy then '摘除+切除'
                else if has_myomectomy then '肌瘤摘除'
                else if has_hysterectomy then '子宮切除'
                else '未知',
            has_organ_injury: has_injury
        }

/*
 * 統計5: 按手術類型的損傷發生率摘要
 */
define "Surgery_Type_Injury_Summary":
    {
        myomectomy_only: {
            total: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '肌瘤摘除'),
            with_injury: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '肌瘤摘除' and D.has_organ_injury = true),
            rate: 
                let total: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '肌瘤摘除'),
                    with_injury: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '肌瘤摘除' and D.has_organ_injury = true)
                return if total > 0 then Round((with_injury / total) * 100, 2) else null
        },
        hysterectomy_only: {
            total: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '子宮切除'),
            with_injury: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '子宮切除' and D.has_organ_injury = true),
            rate: 
                let total: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '子宮切除'),
                    with_injury: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '子宮切除' and D.has_organ_injury = true)
                return if total > 0 then Round((with_injury / total) * 100, 2) else null
        },
        both_surgeries: {
            total: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '摘除+切除'),
            with_injury: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '摘除+切除' and D.has_organ_injury = true),
            rate: 
                let total: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '摘除+切除'),
                    with_injury: Count("Surgery_Type_Injury_Distribution" D where D.surgery_type = '摘除+切除' and D.has_organ_injury = true)
                return if total > 0 then Round((with_injury / total) * 100, 2) else null
        }
    }

/*
 * 統計6: 損傷類型摘要統計
 */
define "Injury_Type_Summary":
    {
        total_injuries: "Numerator_Count",
        ureter_injuries: Count("Injury_Type_Distribution" D where D.has_ureter_injury = true),
        kidney_injuries: Count("Injury_Type_Distribution" D where D.has_kidney_injury = true),
        both_injuries: Count("Injury_Type_Distribution" D where D.has_ureter_injury = true and D.has_kidney_injury = true)
    }

/*
 * 統計7: 損傷發生時機摘要統計
 */
define "Injury_Timing_Summary":
    {
        outpatient_only: Count("Injury_Encounter_Type_Distribution" D where D.injury_type = '門診'),
        inpatient_only: Count("Injury_Encounter_Type_Distribution" D where D.injury_type = '住診'),
        both_settings: Count("Injury_Encounter_Type_Distribution" D where D.injury_type = '門診+住診')
    }

/*
 * 統計8: 損傷發生天數摘要統計
 */
define "Injury_Days_Summary":
    {
        days_0_to_3: Count("Injury_Days_Distribution" D where D.days_category = '0-3天'),
        days_4_to_7: Count("Injury_Days_Distribution" D where D.days_category = '4-7天'),
        days_8_to_10: Count("Injury_Days_Distribution" D where D.days_category = '8-10天'),
        days_11_to_14: Count("Injury_Days_Distribution" D where D.days_category = '11-14天')
    }

-- ==================== 品質檢核定義 ====================

/*
 * 品質檢核1: 檢查是否有損傷診斷但第7位碼不是"A"
 */
define "Quality_Check_Invalid_Seventh_Character":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        (
                            StartsWith(Cod.code, 'S371')
                            or StartsWith(Cod.code, 'S372')
                            or StartsWith(Cod.code, 'S373')
                            or StartsWith(Cod.code, 'S374')
                            or StartsWith(Cod.code, 'S375')
                            or StartsWith(Cod.code, 'S376')
                            or StartsWith(Cod.code, 'S377')
                            or StartsWith(Cod.code, 'S378')
                            or StartsWith(Cod.code, 'S379')
                            or StartsWith(Cod.code, 'S363')
                            or StartsWith(Cod.code, 'S364')
                        )
                        and (
                            Length(Cod.code) < 7
                            or Substring(Cod.code, 6, 1) != 'A'
                        )
                    )
        )
        return {
            condition_id: C.id,
            code: First(C.code.coding).code,
            issue: '損傷診斷第7位碼不是"A"或缺少第7位碼',
            encounter_reference: C.encounter.reference
        }

/*
 * 品質檢核2: 檢查分母案件的手術與診斷關聯
 */
define "Quality_Check_Surgery_Diagnosis_Link":
    "Inpatient_Encounters" E
        where exists (
            "All_Fibroid_Surgeries" P
                where P.encounter.reference = 'Encounter/' + E.id
        )
        and not exists (
            "Has_Uterine_Leiomyoma_Diagnosis" C
                where C.encounter.reference = 'Encounter/' + E.id
        )
        return {
            encounter_id: E.id,
            issue: '有手術但無子宮肌瘤診斷',
            encounter_period: E.period
        }

/*
 * 品質檢核3: 檢查14日內追蹤是否超出範圍
 */
define "Quality_Check_Followup_Beyond_14Days":
    "Denominator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            beyond_14_days: 
                "All_Encounters" FollowUpEnc
                    let 
                        followup_date: 
                            if FollowUpEnc.class ~ "ActCode_Outpatient"
                            then "Get_Outpatient_Visit_Date"(FollowUpEnc)
                            else "Get_Admission_Date"(FollowUpEnc),
                        days_diff: difference in days between discharge_date and followup_date
                    where days_diff > 14
                        and days_diff <= 30
                        and exists (
                            "Organ_Injury_Diagnosis" InjuryCond
                                where InjuryCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
                        )
        where Count(beyond_14_days) > 0
        return {
            denominator_encounter_id: DenomEnc.id,
            issue: '14日後仍有損傷診斷(15-30日)',
            count: Count(beyond_14_days)
        }

/*
 * 品質檢核4: 檢查癌症排除邏輯
 */
define "Quality_Check_Cancer_Exclusion":
    {
        total_with_fibroid_diagnosis_and_surgery: Count(
            "Inpatient_Encounters" E
                where exists (
                    "Has_Uterine_Leiomyoma_Diagnosis" C
                        where C.encounter.reference = 'Encounter/' + E.id
                )
                and exists (
                    "All_Fibroid_Surgeries" P
                        where P.encounter.reference = 'Encounter/' + E.id
                )
        ),
        excluded_due_to_cancer: Count(
            "Inpatient_Encounters" E
                where exists (
                    "Has_Uterine_Leiomyoma_Diagnosis" C
                        where C.encounter.reference = 'Encounter/' + E.id
                )
                and exists (
                    "All_Fibroid_Surgeries" P
                        where P.encounter.reference = 'Encounter/' + E.id
                )
                and "Has_Cancer_Diagnosis"
        ),
        included_in_denominator: "Denominator_Count"
    }

/*
 * 品質檢核5: 整體品質檢核摘要
 */
define "Quality_Check_Summary":
    {
        invalid_seventh_character_count: Count("Quality_Check_Invalid_Seventh_Character"),
        surgery_without_diagnosis_count: Count("Quality_Check_Surgery_Diagnosis_Link"),
        injury_beyond_14days_count: Count("Quality_Check_Followup_Beyond_14Days"),
        cancer_exclusion_info: "Quality_Check_Cancer_Exclusion"
    }

-- ==================== 最終結果輸出 ====================

/*
 * 最終指標結果
 */
define "Final_Result":
    {
        indicator_name: '子宮肌瘤手術出院後十四日以內相關器官損傷發生率',
        measurement_period: "Measurement_Period",
        denominator: "Denominator_Count",
        numerator: "Numerator_Count",
        rate_percentage: "Indicator_Rate",
        injury_type_summary: "Injury_Type_Summary",
        injury_timing_summary: "Injury_Timing_Summary",
        injury_days_summary: "Injury_Days_Summary",
        surgery_type_injury_summary: "Surgery_Type_Injury_Summary",
        quality_check_summary: "Quality_Check_Summary"
    }
