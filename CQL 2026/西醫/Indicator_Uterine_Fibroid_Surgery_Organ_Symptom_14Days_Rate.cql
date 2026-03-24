library Indicator_Uterine_Fibroid_Surgery_Organ_Symptom_14Days_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 子宮肌瘤手術出院後十四日以內相關器官徵候發生率
// 製作日期：2026-01-06

/*
 * 指標名稱: 子宮肌瘤手術出院後十四日以內相關器官徵候發生率
 * Indicator: Rate of Related Organ Symptoms within 14 Days after Uterine Fibroid Surgery
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 資料範圍: 西醫醫院、西醫基層
 * 
 * 公式說明:
 * 分子: 分母案件出院14日內門、住診有相關器官之徵候診斷人次數
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
 * 相關器官之徵候診斷包含:
 * 1. 侵及泌尿系統之徵候: 門、住診案件任一主、次診斷ICD-10-CM前三碼R30-R39
 * 2. 侵及腹部及骨盆之徵候: 門、住診案件任一主、次診斷ICD-10-CM前三碼R10、R16、R18、R19
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

-- ICD-10-CM 相關器官徵候診斷
-- 侵及泌尿系統之徵候 (R30-R39)
code "Urinary_Symptom_R30": 'R30' from "ICD10CM" display '與排尿有關之疼痛'
code "Urinary_Symptom_R31": 'R31' from "ICD10CM" display '血尿'
code "Urinary_Symptom_R32": 'R32' from "ICD10CM" display '未明示之尿失禁'
code "Urinary_Symptom_R33": 'R33' from "ICD10CM" display '尿滯留'
code "Urinary_Symptom_R34": 'R34' from "ICD10CM" display '無尿及少尿'
code "Urinary_Symptom_R35": 'R35' from "ICD10CM" display '多尿'
code "Urinary_Symptom_R36": 'R36' from "ICD10CM" display '尿道分泌物'
code "Urinary_Symptom_R37": 'R37' from "ICD10CM" display '未明示之性器官分泌物'
code "Urinary_Symptom_R39": 'R39' from "ICD10CM" display '泌尿系統之其他及未明示之症狀及徵候'

-- 侵及腹部及骨盆之徵候 (R10, R16, R18, R19)
code "Abdominal_Symptom_R10": 'R10' from "ICD10CM" display '腹部及骨盆疼痛'
code "Abdominal_Symptom_R16": 'R16' from "ICD10CM" display '肝腫大及脾腫大，他處未歸類者'
code "Abdominal_Symptom_R18": 'R18' from "ICD10CM" display '腹水'
code "Abdominal_Symptom_R19": 'R19' from "ICD10CM" display '涉及消化系統及腹部之其他症狀及徵候'

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

-- SNOMED CT - 泌尿系統症狀
code "SNOMED_Hematuria": '34436003' from "SNOMEDCT" display 'Hematuria'
code "SNOMED_Dysuria": '49650001' from "SNOMEDCT" display 'Dysuria'
code "SNOMED_Urinary_Retention": '130951007' from "SNOMEDCT" display 'Urinary retention'
code "SNOMED_Urinary_Incontinence": '165232002' from "SNOMEDCT" display 'Urinary incontinence'

-- SNOMED CT - 腹部症狀
code "SNOMED_Abdominal_Pain": '21522001' from "SNOMEDCT" display 'Abdominal pain'
code "SNOMED_Pelvic_Pain": '30473006' from "SNOMEDCT" display 'Pelvic pain'
code "SNOMED_Ascites": '271861000' from "SNOMEDCT" display 'Ascites'

-- ActCode
code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'
code "ActCode_Outpatient": 'AMB' from "ActCode" display '門診'

-- ==================== ValueSet 定義 ====================

valueset "Uterine_Leiomyoma_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/uterine-leiomyoma-diagnosis'
valueset "Cancer_Exclusion_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/cancer-exclusion'
valueset "Myomectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/myomectomy-procedures'
valueset "Hysterectomy_Procedures_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/hysterectomy-procedures'
valueset "Organ_Symptom_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/organ-symptom-diagnosis'

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
 * 定義9: 相關器官徵候診斷
 * 1. 侵及泌尿系統之徵候：R30-R39
 * 2. 侵及腹部及骨盆之徵候：R10、R16、R18、R19
 */
define "Organ_Symptom_Diagnosis":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        -- R30-R39 泌尿系統徵候
                        (Cod.code >= 'R30' and Cod.code <= 'R39.9')
                        or StartsWith(Cod.code, 'R30')
                        or StartsWith(Cod.code, 'R31')
                        or StartsWith(Cod.code, 'R32')
                        or StartsWith(Cod.code, 'R33')
                        or StartsWith(Cod.code, 'R34')
                        or StartsWith(Cod.code, 'R35')
                        or StartsWith(Cod.code, 'R36')
                        or StartsWith(Cod.code, 'R37')
                        or StartsWith(Cod.code, 'R39')
                        -- R10、R16、R18、R19 腹部及骨盆徵候
                        or StartsWith(Cod.code, 'R10')
                        or StartsWith(Cod.code, 'R16')
                        or StartsWith(Cod.code, 'R18')
                        or StartsWith(Cod.code, 'R19')
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
 * 分子定義: 分母案件出院14日內門、住診有相關器官之徵候診斷人次數
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
                        "Organ_Symptom_Diagnosis" SymptomCond
                            where SymptomCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
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
 * 統計1: 徵候類型分布
 */
define "Symptom_Type_Distribution":
    "Numerator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            symptom_encounters: 
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
                            "Organ_Symptom_Diagnosis" SymptomCond
                                where SymptomCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
                        )
        return {
            denominator_encounter_id: DenomEnc.id,
            symptom_encounters: symptom_encounters,
            has_urinary_symptom: exists(
                symptom_encounters SympEnc
                    where exists (
                        "Organ_Symptom_Diagnosis" C
                            where C.encounter.reference = 'Encounter/' + SympEnc.id
                                and exists (
                                    C.code.coding Cod
                                        where (Cod.code >= 'R30' and Cod.code <= 'R39.9')
                                            or StartsWith(Cod.code, 'R30')
                                            or StartsWith(Cod.code, 'R31')
                                            or StartsWith(Cod.code, 'R32')
                                            or StartsWith(Cod.code, 'R33')
                                            or StartsWith(Cod.code, 'R34')
                                            or StartsWith(Cod.code, 'R35')
                                            or StartsWith(Cod.code, 'R36')
                                            or StartsWith(Cod.code, 'R37')
                                            or StartsWith(Cod.code, 'R39')
                                )
                    )
            ),
            has_abdominal_symptom: exists(
                symptom_encounters SympEnc
                    where exists (
                        "Organ_Symptom_Diagnosis" C
                            where C.encounter.reference = 'Encounter/' + SympEnc.id
                                and exists (
                                    C.code.coding Cod
                                        where StartsWith(Cod.code, 'R10')
                                            or StartsWith(Cod.code, 'R16')
                                            or StartsWith(Cod.code, 'R18')
                                            or StartsWith(Cod.code, 'R19')
                                )
                    )
            )
        }

/*
 * 統計2: 徵候發生時機分布（門診 vs 住診）
 */
define "Symptom_Encounter_Type_Distribution":
    "Numerator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            outpatient_symptoms: Count(
                "Outpatient_Encounters" OutEnc
                    let days_diff: difference in days between discharge_date and "Get_Outpatient_Visit_Date"(OutEnc)
                    where days_diff >= 0 
                        and days_diff <= 14
                        and exists (
                            "Organ_Symptom_Diagnosis" SymptomCond
                                where SymptomCond.encounter.reference = 'Encounter/' + OutEnc.id
                        )
            ),
            inpatient_symptoms: Count(
                "Inpatient_Encounters" InpEnc
                    let days_diff: difference in days between discharge_date and "Get_Admission_Date"(InpEnc)
                    where days_diff >= 0 
                        and days_diff <= 14
                        and InpEnc.id != DenomEnc.id
                        and exists (
                            "Organ_Symptom_Diagnosis" SymptomCond
                                where SymptomCond.encounter.reference = 'Encounter/' + InpEnc.id
                        )
            )
        return {
            denominator_encounter_id: DenomEnc.id,
            outpatient_symptom_count: outpatient_symptoms,
            inpatient_symptom_count: inpatient_symptoms,
            total_symptom_count: outpatient_symptoms + inpatient_symptoms,
            symptom_type: 
                if outpatient_symptoms > 0 and inpatient_symptoms > 0 then '門診+住診'
                else if outpatient_symptoms > 0 then '門診'
                else if inpatient_symptoms > 0 then '住診'
                else '無'
        }

/*
 * 統計3: 徵候發生天數分布
 */
define "Symptom_Days_Distribution":
    "Numerator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            symptom_days: 
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
                            "Organ_Symptom_Diagnosis" SymptomCond
                                where SymptomCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
                        )
                    return days_diff,
            min_days: Min(symptom_days)
        return {
            denominator_encounter_id: DenomEnc.id,
            earliest_symptom_days: min_days,
            days_category: 
                if min_days <= 3 then '0-3天'
                else if min_days <= 7 then '4-7天'
                else if min_days <= 10 then '8-10天'
                else '11-14天'
        }

/*
 * 統計4: 按手術類型的徵候發生率
 */
define "Surgery_Type_Symptom_Distribution":
    "Denominator" E
        let 
            has_myomectomy: exists("Myomectomy_Procedures" P where P.encounter.reference = 'Encounter/' + E.id),
            has_hysterectomy: exists("Hysterectomy_Procedures" P where P.encounter.reference = 'Encounter/' + E.id),
            has_symptom: exists(
                "Numerator" N where N.id = E.id
            )
        return {
            encounter_id: E.id,
            surgery_type: 
                if has_myomectomy and has_hysterectomy then '摘除+切除'
                else if has_myomectomy then '肌瘤摘除'
                else if has_hysterectomy then '子宮切除'
                else '未知',
            has_organ_symptom: has_symptom
        }

/*
 * 統計5: 按手術類型的徵候發生率摘要
 */
define "Surgery_Type_Symptom_Summary":
    {
        myomectomy_only: {
            total: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '肌瘤摘除'),
            with_symptom: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '肌瘤摘除' and D.has_organ_symptom = true),
            rate: 
                let total: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '肌瘤摘除'),
                    with_symptom: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '肌瘤摘除' and D.has_organ_symptom = true)
                return if total > 0 then Round((with_symptom / total) * 100, 2) else null
        },
        hysterectomy_only: {
            total: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '子宮切除'),
            with_symptom: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '子宮切除' and D.has_organ_symptom = true),
            rate: 
                let total: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '子宮切除'),
                    with_symptom: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '子宮切除' and D.has_organ_symptom = true)
                return if total > 0 then Round((with_symptom / total) * 100, 2) else null
        },
        both_surgeries: {
            total: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '摘除+切除'),
            with_symptom: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '摘除+切除' and D.has_organ_symptom = true),
            rate: 
                let total: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '摘除+切除'),
                    with_symptom: Count("Surgery_Type_Symptom_Distribution" D where D.surgery_type = '摘除+切除' and D.has_organ_symptom = true)
                return if total > 0 then Round((with_symptom / total) * 100, 2) else null
        }
    }

/*
 * 統計6: 徵候類型摘要統計
 */
define "Symptom_Type_Summary":
    {
        total_symptoms: "Numerator_Count",
        urinary_symptoms: Count("Symptom_Type_Distribution" D where D.has_urinary_symptom = true),
        abdominal_symptoms: Count("Symptom_Type_Distribution" D where D.has_abdominal_symptom = true),
        both_symptoms: Count("Symptom_Type_Distribution" D where D.has_urinary_symptom = true and D.has_abdominal_symptom = true)
    }

/*
 * 統計7: 徵候發生時機摘要統計
 */
define "Symptom_Timing_Summary":
    {
        outpatient_only: Count("Symptom_Encounter_Type_Distribution" D where D.symptom_type = '門診'),
        inpatient_only: Count("Symptom_Encounter_Type_Distribution" D where D.symptom_type = '住診'),
        both_settings: Count("Symptom_Encounter_Type_Distribution" D where D.symptom_type = '門診+住診')
    }

/*
 * 統計8: 徵候發生天數摘要統計
 */
define "Symptom_Days_Summary":
    {
        days_0_to_3: Count("Symptom_Days_Distribution" D where D.days_category = '0-3天'),
        days_4_to_7: Count("Symptom_Days_Distribution" D where D.days_category = '4-7天'),
        days_8_to_10: Count("Symptom_Days_Distribution" D where D.days_category = '8-10天'),
        days_11_to_14: Count("Symptom_Days_Distribution" D where D.days_category = '11-14天')
    }

/*
 * 統計9: 詳細徵候代碼統計
 */
define "Detailed_Symptom_Code_Distribution":
    "Numerator" DenomEnc
        let 
            discharge_date: "Get_Discharge_Date"(DenomEnc),
            symptom_codes: 
                "All_Encounters" FollowUpEnc
                    let 
                        followup_date: 
                            if FollowUpEnc.class ~ "ActCode_Outpatient"
                            then "Get_Outpatient_Visit_Date"(FollowUpEnc)
                            else "Get_Admission_Date"(FollowUpEnc),
                        days_diff: difference in days between discharge_date and followup_date
                    where days_diff >= 0 
                        and days_diff <= 14
                    return 
                        "Organ_Symptom_Diagnosis" C
                            where C.encounter.reference = 'Encounter/' + FollowUpEnc.id
                            return First(C.code.coding).code
        return {
            denominator_encounter_id: DenomEnc.id,
            symptom_codes: symptom_codes
        }

-- ==================== 品質檢核定義 ====================

/*
 * 品質檢核1: 檢查分母案件的手術與診斷關聯
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
 * 品質檢核2: 檢查14日內追蹤是否超出範圍
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
                            "Organ_Symptom_Diagnosis" SymptomCond
                                where SymptomCond.encounter.reference = 'Encounter/' + FollowUpEnc.id
                        )
        where Count(beyond_14_days) > 0
        return {
            denominator_encounter_id: DenomEnc.id,
            issue: '14日後仍有徵候診斷(15-30日)',
            count: Count(beyond_14_days)
        }

/*
 * 品質檢核3: 檢查癌症排除邏輯
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
 * 品質檢核4: 檢查徵候診斷代碼有效性
 */
define "Quality_Check_Symptom_Code_Validity":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        -- 檢查是否為R開頭但不在指定範圍
                        StartsWith(Cod.code, 'R')
                        and not (
                            (Cod.code >= 'R30' and Cod.code <= 'R39.9')
                            or StartsWith(Cod.code, 'R30')
                            or StartsWith(Cod.code, 'R31')
                            or StartsWith(Cod.code, 'R32')
                            or StartsWith(Cod.code, 'R33')
                            or StartsWith(Cod.code, 'R34')
                            or StartsWith(Cod.code, 'R35')
                            or StartsWith(Cod.code, 'R36')
                            or StartsWith(Cod.code, 'R37')
                            or StartsWith(Cod.code, 'R39')
                            or StartsWith(Cod.code, 'R10')
                            or StartsWith(Cod.code, 'R16')
                            or StartsWith(Cod.code, 'R18')
                            or StartsWith(Cod.code, 'R19')
                        )
                    )
        )
        return {
            condition_id: C.id,
            code: First(C.code.coding).code,
            issue: '徵候診斷代碼不在指定範圍內',
            encounter_reference: C.encounter.reference
        }

/*
 * 品質檢核5: 整體品質檢核摘要
 */
define "Quality_Check_Summary":
    {
        surgery_without_diagnosis_count: Count("Quality_Check_Surgery_Diagnosis_Link"),
        symptom_beyond_14days_count: Count("Quality_Check_Followup_Beyond_14Days"),
        invalid_symptom_code_count: Count("Quality_Check_Symptom_Code_Validity"),
        cancer_exclusion_info: "Quality_Check_Cancer_Exclusion"
    }

-- ==================== 最終結果輸出 ====================

/*
 * 最終指標結果
 */
define "Final_Result":
    {
        indicator_name: '子宮肌瘤手術出院後十四日以內相關器官徵候發生率',
        measurement_period: "Measurement_Period",
        denominator: "Denominator_Count",
        numerator: "Numerator_Count",
        rate_percentage: "Indicator_Rate",
        symptom_type_summary: "Symptom_Type_Summary",
        symptom_timing_summary: "Symptom_Timing_Summary",
        symptom_days_summary: "Symptom_Days_Summary",
        surgery_type_symptom_summary: "Surgery_Type_Symptom_Summary",
        quality_check_summary: "Quality_Check_Summary"
    }
