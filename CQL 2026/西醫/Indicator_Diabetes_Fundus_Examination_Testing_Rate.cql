library Indicator_Diabetes_Fundus_Examination_Testing_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：2026年糖尿病品質指標
// 條件依據：眼底檢查或眼底彩色攝影執行率
// 製作日期：2026-01-06

/**
 * 公式說明:
 * 眼底檢查或眼底彩色攝影執行率 = 
 *     分子: 分母ID中，在統計期間有執行眼底檢查或眼底彩色攝影檢查人數
 *     分母: 門診主次診斷為糖尿病且使用糖尿病用藥之病人數
 * 
 * 備註:
 * (1)糖尿病：任一主、次診斷之ICD_10_CM前三碼為E08-E13之門診案件。
 * (2)糖尿病用藥：指ATC前3碼為A10。
 * (3)眼底檢查或眼底彩色攝影案件係指申報醫令代碼前五碼為23501或23502或23702之案件。
 * (4)計算符合分母條件之ID時，主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件。
 * (5)計算符合分子之ID時，從分母的ID繼續觀察，只要該ID於統計期間有執行眼底檢查或眼底彩色攝影檢驗即成立。
 * (6)資料範圍：西醫基層、西醫醫院。
 * (7)運算範圍：每半年。
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 就醫紀錄 (門診)
 * - Condition: 診斷資料 (主次診斷，糖尿病E08-E13)
 * - MedicationRequest: 藥品處方 (糖尿病用藥A10)
 * - Procedure: 處置記錄 (眼底檢查、眼底彩色攝影)
 * - Observation: 檢查結果 (眼底檢查結果)
 * - ImagingStudy: 影像檢查 (眼底彩色攝影)
 * - Claim: 醫療費用申報 (檢查項目代碼23501/23502/23702)
 */

-- ==================== 代碼系統定義 ====================

codesystem "NHI_INDICATOR": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-indicator'
    -- 健保指標代碼系統
    -- 糖尿病品質指標

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
    -- ICD-10-CM 國際疾病分類代碼系統
    -- E08-E13: 糖尿病相關診斷
    -- E08: 其他特定的糖尿病
    -- E09: 藥物或化學物質引起的糖尿病
    -- E10: 第1型糖尿病
    -- E11: 第2型糖尿病
    -- E13: 其他特定的糖尿病
    -- H35.0*: 糖尿病視網膜病變

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 73211009: Diabetes mellitus (糖尿病)
    -- 46635009: Type 1 diabetes mellitus (第1型糖尿病)
    -- 44054006: Type 2 diabetes mellitus (第2型糖尿病)
    -- 4855003: Ophthalmoscopy (眼底鏡檢查)
    -- 314971003: Fundus photography (眼底攝影)
    -- 252779009: Single digital image of fundus (單一數位眼底影像)
    -- 314972005: Color fundus photography (彩色眼底攝影)
    -- 420037003: Diabetic retinopathy screening (糖尿病視網膜病變篩檢)
    -- 314994006: Diabetic retinopathy (糖尿病視網膜病變)

codesystem "ATC": 'http://www.whocc.no/atc'
    -- 解剖治療化學分類系統 (ATC)
    -- A10: 糖尿病用藥
    -- A10A: 胰島素及其類似物
    -- A10B: 降血糖藥，不包括胰島素

codesystem "LOINC": 'http://loinc.org'
    -- 邏輯觀察識別碼命名和編碼系統 (LOINC)
    -- 32451-7: Physical findings of Macula [Identifier] in Eye by Ophthalmoscopy
    -- 71484-9: Diabetic retinopathy [Interpretation] in Eye
    -- 79894-3: Fundus photography procedure
    -- 82810-3: Pregnancy status

codesystem "CPT": 'http://www.ama-assn.org/go/cpt'
    -- Current Procedural Terminology (CPT)
    -- 92201: Ophthalmoscopy, extended
    -- 92202: Ophthalmoscopy, extended with drawing
    -- 92250: Fundus photography with interpretation and report
    -- 92228: Remote imaging for detection of retinal disease

codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    -- HL7 ActCode 代碼系統
    -- AMB: 門診 (Ambulatory)
    -- IMP: 住院 (Inpatient)
    -- EMER: 急診 (Emergency)

codesystem "NHI": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-code'
    -- 台灣健保局專用代碼系統
    -- 醫療服務代碼
    -- 藥品代碼
    -- 醫令代碼

codesystem "NHI_PROCEDURE_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure-code'
    -- 健保處置代碼系統
    -- 23501: 眼底檢查 (Fundus Examination)
    -- 23502: 眼底檢查 (Fundus Examination - Enhanced)
    -- 23702: 眼底彩色攝影 (Color Fundus Photography)

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- O: 門診
    -- E: 急診
    -- I: 住院

-- ==================== 值集定義 ====================

valueset "Diabetes Diagnosis Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-diagnosis'
    -- 糖尿病診斷代碼值集
    -- ICD-10-CM: E08*, E09*, E10*, E11*, E13*
    -- SNOMED CT: 73211009, 46635009, 44054006

valueset "Diabetic Retinopathy Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetic-retinopathy'
    -- 糖尿病視網膜病變代碼值集
    -- ICD-10-CM: H35.0*, E11.3*
    -- SNOMED CT: 314994006

valueset "Diabetes Medications": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-medications'
    -- 糖尿病用藥值集
    -- ATC: A10* (所有糖尿病用藥)

valueset "Fundus Examination Procedures": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/fundus-examination'
    -- 眼底檢查處置值集
    -- NHI: 23501, 23502, 23702
    -- SNOMED CT: 4855003, 314971003, 252779009, 314972005
    -- CPT: 92201, 92202, 92250, 92228

valueset "Outpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/outpatient-encounter-types'
    -- 門診就醫類別值集
    -- ActCode: AMB (門診)
    -- NHI: O (門診)

valueset "Medical Facility Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/medical-facility-types'
    -- 醫療機構類別值集
    -- 西醫基層診所
    -- 西醫醫院 (醫學中心、區域醫院、地區醫院)

-- ==================== 代碼對照表 ====================

define fundus_examination_codes:
    tuple {
        fundus_exam_1: tuple {
            nhi_code: '23501',
            cpt_code: '92201',
            snomed_code: '4855003',
            name: '眼底檢查 (Fundus Examination)',
            description: '使用眼底鏡進行視網膜檢查'
        },
        fundus_exam_2: tuple {
            nhi_code: '23502',
            cpt_code: '92202',
            snomed_code: '4855003',
            name: '眼底檢查 - 加強版 (Fundus Examination - Enhanced)',
            description: '擴瞳後詳細眼底檢查'
        },
        color_fundus_photography: tuple {
            nhi_code: '23702',
            cpt_code: '92250',
            snomed_code: '314972005',
            name: '眼底彩色攝影 (Color Fundus Photography)',
            description: '數位彩色眼底攝影含判讀'
        }
    }

-- ==================== 統計期間定義 ====================

-- 半年期間定義 (每半年運算)
define semiannual_periods:
    {
        {id: 1, year: 2026, half: 1, start_date: @2026-01-01, end_date: @2026-06-30, label: '115年上半年'},
        {id: 2, year: 2026, half: 2, start_date: @2026-07-01, end_date: @2026-12-31, label: '115年下半年'}
    }

-- 季度期間定義 (供參考)
define quarters:
    {
        {id: 1, year: 2026, quarter: 1, start_date: @2026-01-01, end_date: @2026-03-31, label: '115年第1季'},
        {id: 2, year: 2026, quarter: 2, start_date: @2026-04-01, end_date: @2026-06-30, label: '115年第2季'},
        {id: 3, year: 2026, quarter: 3, start_date: @2026-07-01, end_date: @2026-09-30, label: '115年第3季'},
        {id: 4, year: 2026, quarter: 4, start_date: @2026-10-01, end_date: @2026-12-31, label: '115年第4季'}
    }

-- 年度期間定義
define annual_period:
    {
        year: 2026,
        start_date: @2026-01-01,
        end_date: @2026-12-31,
        label: '115年 (2026)'
    }

-- ==================== 資料篩選條件 ====================

-- 1. 門診就醫記錄 (限定西醫基層、西醫醫院)
define outpatient_encounters AS (
    SELECT 
        e.encounter_id,
        e.patient_id,
        e.visit_date,
        e.encounter_type,
        e.primary_diagnosis,
        e.secondary_diagnoses,
        e.facility_type,
        e.visit_sequence,
        e.agency_flag
    FROM 
        encounter_details e
    WHERE 
        -- 門診案件 (O=門診 or AMB=Ambulatory)
        e.encounter_type IN ('O', 'AMB')
        
        -- 限定西醫基層、西醫醫院
        AND e.facility_type IN ('CLINIC_WESTERN', 'HOSPITAL_MEDICAL_CENTER', 
                                'HOSPITAL_REGIONAL', 'HOSPITAL_DISTRICT')
        
        -- 排除代辦案件
        AND (e.agency_flag IS NULL OR e.agency_flag != 'Y')
        
        -- 限定統計期間
        AND e.visit_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 2. 糖尿病診斷條件
-- ICD-10-CM前三碼為E08-E13
define diabetes_encounters AS (
    SELECT 
        oe.encounter_id,
        oe.patient_id,
        oe.visit_date,
        oe.primary_diagnosis,
        oe.secondary_diagnoses,
        oe.facility_type,
        oe.visit_sequence,
        CASE 
            WHEN SUBSTRING(oe.primary_diagnosis, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13') 
            THEN oe.primary_diagnosis
            ELSE NULL
        END as diabetes_primary_diagnosis,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM UNNEST(oe.secondary_diagnoses) as sd
                WHERE SUBSTRING(sd, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
            ) THEN TRUE
            ELSE FALSE
        END as has_diabetes_secondary_diagnosis,
        -- 檢查是否有糖尿病視網膜病變診斷
        CASE 
            WHEN SUBSTRING(oe.primary_diagnosis, 1, 4) = 'H35.0'
                OR EXISTS (
                    SELECT 1 FROM UNNEST(oe.secondary_diagnoses) as sd
                    WHERE SUBSTRING(sd, 1, 4) = 'H35.0'
                ) THEN TRUE
            ELSE FALSE
        END as has_diabetic_retinopathy
    FROM 
        outpatient_encounters oe
    WHERE 
        -- 主診斷或次診斷有糖尿病 (E08-E13)
        (
            SUBSTRING(oe.primary_diagnosis, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
            OR 
            EXISTS (
                SELECT 1 FROM UNNEST(oe.secondary_diagnoses) as sd
                WHERE SUBSTRING(sd, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
            )
        )
)

-- 3. 糖尿病用藥條件
-- ATC前3碼為A10
define diabetes_medications AS (
    SELECT 
        d.dispense_id,
        d.encounter_id,
        d.patient_id,
        d.dispense_date,
        d.atc_code_7,
        d.medication_name,
        d.quantity,
        d.days_supply
    FROM 
        drug_dispense d
    WHERE 
        -- ATC前3碼為A10 (糖尿病用藥)
        SUBSTRING(d.atc_code_7, 1, 3) = 'A10'
        
        -- 有實際給藥
        AND d.quantity > 0
        
        -- 限定統計期間
        AND d.dispense_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- ==================== 眼底檢查條件 ====================

-- 4. 眼底檢查或眼底彩色攝影 (醫令代碼前五碼為23501或23502或23702)
define fundus_examination_procedures AS (
    SELECT 
        p.procedure_id,
        p.encounter_id,
        p.patient_id,
        p.procedure_date,
        p.procedure_code,
        p.procedure_name,
        p.nhi_procedure_code,
        p.performed_by,
        p.result_status
    FROM 
        procedure_records p
    WHERE 
        -- 健保處置代碼前五碼為 23501, 23502, 23702
        (
            SUBSTRING(p.nhi_procedure_code, 1, 5) = '23501'  -- 眼底檢查
            OR SUBSTRING(p.nhi_procedure_code, 1, 5) = '23502'  -- 眼底檢查 (加強版)
            OR SUBSTRING(p.nhi_procedure_code, 1, 5) = '23702'  -- 眼底彩色攝影
        )
        
        -- 或 CPT代碼
        OR p.procedure_code IN (
            '92201',  -- Ophthalmoscopy, extended
            '92202',  -- Ophthalmoscopy, extended with drawing
            '92250',  -- Fundus photography
            '92228'   -- Remote imaging for retinal disease
        )
        
        -- 或 SNOMED CT代碼
        OR p.snomed_code IN (
            '4855003',     -- Ophthalmoscopy
            '314971003',   -- Fundus photography
            '252779009',   -- Single digital image of fundus
            '314972005',   -- Color fundus photography
            '420037003'    -- Diabetic retinopathy screening
        )
        
        -- 處置已完成
        AND p.result_status IN ('completed', 'final', 'amended')
        
        -- 限定統計期間
        AND p.procedure_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 5. 眼底檢查影像記錄 (ImagingStudy)
define fundus_imaging_studies AS (
    SELECT 
        i.imaging_id,
        i.encounter_id,
        i.patient_id,
        i.study_date,
        i.modality,
        i.body_site,
        i.study_description,
        i.nhi_imaging_code
    FROM 
        imaging_study i
    WHERE 
        -- 眼底攝影相關代碼
        (
            SUBSTRING(i.nhi_imaging_code, 1, 5) = '23702'  -- 眼底彩色攝影
            OR i.modality = 'FUNDUS'
            OR i.body_site IN ('EYE', 'RETINA', 'FUNDUS')
        )
        
        -- 影像檢查已完成
        AND i.study_status IN ('available', 'final')
        
        -- 限定統計期間
        AND i.study_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 6. 眼底檢查觀察記錄 (Observation)
define fundus_examination_observations AS (
    SELECT 
        o.observation_id,
        o.encounter_id,
        o.patient_id,
        o.observation_date,
        o.loinc_code,
        o.observation_type,
        o.observation_value,
        o.interpretation
    FROM 
        observation_clinical o
    WHERE 
        -- LOINC代碼
        o.loinc_code IN (
            '32451-7',  -- Physical findings of Macula in Eye by Ophthalmoscopy
            '71484-9'   -- Diabetic retinopathy [Interpretation] in Eye
        )
        
        -- 或觀察類型
        OR o.observation_type IN ('FUNDUS_EXAM', 'RETINAL_EXAM', 'DIABETIC_RETINOPATHY_SCREENING')
        
        -- 限定統計期間
        AND o.observation_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 7. 合併所有眼底檢查記錄
define all_fundus_examinations AS (
    -- 處置記錄
    SELECT 
        encounter_id, patient_id, procedure_date as exam_date,
        'PROCEDURE' as source_type,
        SUBSTRING(nhi_procedure_code, 1, 5) as exam_code,
        procedure_name as exam_description
    FROM fundus_examination_procedures
    
    UNION
    
    -- 影像記錄
    SELECT 
        encounter_id, patient_id, study_date as exam_date,
        'IMAGING' as source_type,
        SUBSTRING(nhi_imaging_code, 1, 5) as exam_code,
        study_description as exam_description
    FROM fundus_imaging_studies
    
    UNION
    
    -- 觀察記錄
    SELECT 
        encounter_id, patient_id, observation_date as exam_date,
        'OBSERVATION' as source_type,
        loinc_code as exam_code,
        observation_type as exam_description
    FROM fundus_examination_observations
)

-- ==================== 分母計算 (Denominator) ====================

-- 分母: 門診主次診斷為糖尿病且使用糖尿病用藥之病人數
-- 條件: 主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件

define diabetes_patients_with_medication_denominator AS (
    SELECT DISTINCT
        de.patient_id,
        de.encounter_id,
        de.visit_date,
        de.diabetes_primary_diagnosis,
        de.has_diabetes_secondary_diagnosis,
        de.has_diabetic_retinopathy,
        de.facility_type,
        dm.atc_code_7,
        dm.medication_name,
        dm.dispense_date
    FROM 
        diabetes_encounters de
    INNER JOIN 
        diabetes_medications dm 
        ON de.encounter_id = dm.encounter_id
        AND de.patient_id = dm.patient_id
        AND de.visit_date = dm.dispense_date
    WHERE 
        -- 確保同一處方案件: 同encounter_id, 同visit_date
        de.encounter_id = dm.encounter_id
        AND de.visit_date = dm.dispense_date
)

-- 計算分母唯一病患數
define denominator_unique_patients AS (
    SELECT DISTINCT
        patient_id,
        MIN(visit_date) as first_diabetes_medication_date,
        MAX(has_diabetic_retinopathy) as has_retinopathy,
        COUNT(DISTINCT encounter_id) as total_diabetes_encounters
    FROM 
        diabetes_patients_with_medication_denominator
    GROUP BY 
        patient_id
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子: 分母ID中，在統計期間有執行眼底檢查或眼底彩色攝影檢查人數
-- 從分母的ID繼續觀察，只要該ID於統計期間有執行檢查即成立

define patients_with_fundus_examination_numerator AS (
    SELECT DISTINCT
        d.patient_id,
        d.first_diabetes_medication_date,
        d.has_retinopathy,
        e.exam_date,
        e.source_type,
        e.exam_code,
        e.exam_description
    FROM 
        denominator_unique_patients d
    INNER JOIN 
        all_fundus_examinations e
        ON d.patient_id = e.patient_id
    WHERE 
        -- 檢查日期在統計期間內
        e.exam_date BETWEEN annual_period.start_date AND annual_period.end_date
        
        -- 檢查日期 >= 糖尿病用藥日期 (確保是糖尿病病患之後的檢查)
        AND e.exam_date >= d.first_diabetes_medication_date
)

-- 計算分子唯一病患數
define numerator_unique_patients AS (
    SELECT DISTINCT
        patient_id,
        MIN(exam_date) as first_exam_date,
        MAX(exam_date) as last_exam_date,
        COUNT(DISTINCT exam_date) as total_exam_count,
        STRING_AGG(DISTINCT source_type || ': ' || exam_code, '; ') as exam_details,
        MAX(has_retinopathy) as has_retinopathy
    FROM 
        patients_with_fundus_examination_numerator
    GROUP BY 
        patient_id
)

-- ==================== 半年統計 (每半年運算) ====================

define semiannual_statistics:
    semiannual_periods S
    return {
        indicator_name: '眼底檢查或眼底彩色攝影執行率',
        year: S.year,
        half: S.half,
        period_label: S.label,
        start_date: S.start_date,
        end_date: S.end_date,
        
        -- 分母: 該半年糖尿病病患數 (有糖尿病診斷+用藥)
        denominator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM diabetes_patients_with_medication_denominator
            WHERE visit_date BETWEEN S.start_date AND S.end_date
        ),
        
        -- 分子: 該半年有眼底檢查的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT n.patient_id)
            FROM patients_with_fundus_examination_numerator n
            INNER JOIN denominator_unique_patients d 
                ON n.patient_id = d.patient_id
            WHERE n.exam_date BETWEEN S.start_date AND S.end_date
                AND d.first_diabetes_medication_date <= S.end_date
        ),
        
        -- 執行率 (%)
        performance_rate: (
            CASE 
                WHEN (SELECT COUNT(DISTINCT patient_id) 
                      FROM diabetes_patients_with_medication_denominator 
                      WHERE visit_date BETWEEN S.start_date AND S.end_date) > 0
                THEN 
                    ROUND(
                        (SELECT COUNT(DISTINCT n.patient_id)
                         FROM patients_with_fundus_examination_numerator n
                         INNER JOIN denominator_unique_patients d 
                             ON n.patient_id = d.patient_id
                         WHERE n.exam_date BETWEEN S.start_date AND S.end_date
                             AND d.first_diabetes_medication_date <= S.end_date
                        ) * 100.0 / 
                        (SELECT COUNT(DISTINCT patient_id) 
                         FROM diabetes_patients_with_medication_denominator 
                         WHERE visit_date BETWEEN S.start_date AND S.end_date)
                    , 2)
                ELSE 0.0
            END
        ),
        
        -- 統計細節
        statistics_detail: {
            procedure_based_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fundus_examination_numerator
                WHERE exam_date BETWEEN S.start_date AND S.end_date
                    AND source_type = 'PROCEDURE'
            ),
            imaging_based_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fundus_examination_numerator
                WHERE exam_date BETWEEN S.start_date AND S.end_date
                    AND source_type = 'IMAGING'
            ),
            observation_based_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fundus_examination_numerator
                WHERE exam_date BETWEEN S.start_date AND S.end_date
                    AND source_type = 'OBSERVATION'
            ),
            with_retinopathy_diagnosis: (
                SELECT COUNT(DISTINCT n.patient_id)
                FROM patients_with_fundus_examination_numerator n
                WHERE n.exam_date BETWEEN S.start_date AND S.end_date
                    AND n.has_retinopathy = TRUE
            )
        }
    }

-- ==================== 季度統計 (供參考) ====================

define quarterly_statistics:
    quarters Q
    return {
        indicator_name: '眼底檢查或眼底彩色攝影執行率',
        year: Q.year,
        quarter: Q.quarter,
        period_label: Q.label,
        start_date: Q.start_date,
        end_date: Q.end_date,
        
        -- 分母: 該季糖尿病病患數 (有糖尿病診斷+用藥)
        denominator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM diabetes_patients_with_medication_denominator
            WHERE visit_date BETWEEN Q.start_date AND Q.end_date
        ),
        
        -- 分子: 該季有眼底檢查的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT n.patient_id)
            FROM patients_with_fundus_examination_numerator n
            INNER JOIN denominator_unique_patients d 
                ON n.patient_id = d.patient_id
            WHERE n.exam_date BETWEEN Q.start_date AND Q.end_date
                AND d.first_diabetes_medication_date <= Q.end_date
        ),
        
        -- 執行率 (%)
        performance_rate: (
            CASE 
                WHEN (SELECT COUNT(DISTINCT patient_id) 
                      FROM diabetes_patients_with_medication_denominator 
                      WHERE visit_date BETWEEN Q.start_date AND Q.end_date) > 0
                THEN 
                    ROUND(
                        (SELECT COUNT(DISTINCT n.patient_id)
                         FROM patients_with_fundus_examination_numerator n
                         INNER JOIN denominator_unique_patients d 
                             ON n.patient_id = d.patient_id
                         WHERE n.exam_date BETWEEN Q.start_date AND Q.end_date
                             AND d.first_diabetes_medication_date <= Q.end_date
                        ) * 100.0 / 
                        (SELECT COUNT(DISTINCT patient_id) 
                         FROM diabetes_patients_with_medication_denominator 
                         WHERE visit_date BETWEEN Q.start_date AND Q.end_date)
                    , 2)
                ELSE 0.0
            END
        )
    }

-- ==================== 年度統計 ====================

define annual_statistics:
    {
        indicator_name: '眼底檢查或眼底彩色攝影執行率',
        year: annual_period.year,
        period_label: annual_period.label,
        start_date: annual_period.start_date,
        end_date: annual_period.end_date,
        
        -- 分母: 全年糖尿病病患數
        denominator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM denominator_unique_patients
        ),
        
        -- 分子: 全年有眼底檢查的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM numerator_unique_patients
        ),
        
        -- 執行率 (%)
        performance_rate: (
            CASE 
                WHEN (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients) > 0
                THEN 
                    ROUND(
                        (SELECT COUNT(DISTINCT patient_id) FROM numerator_unique_patients) * 100.0 /
                        (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
                    , 2)
                ELSE 0.0
            END
        ),
        
        -- 統計細節
        statistics_detail: {
            total_diabetes_encounters: (
                SELECT SUM(total_diabetes_encounters)
                FROM denominator_unique_patients
            ),
            total_fundus_exams: (
                SELECT SUM(total_exam_count)
                FROM numerator_unique_patients
            ),
            patients_with_retinopathy: (
                SELECT COUNT(DISTINCT patient_id)
                FROM numerator_unique_patients
                WHERE has_retinopathy = TRUE
            ),
            procedure_code_23501_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fundus_examination_numerator
                WHERE exam_code = '23501'
            ),
            procedure_code_23502_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fundus_examination_numerator
                WHERE exam_code = '23502'
            ),
            procedure_code_23702_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fundus_examination_numerator
                WHERE exam_code = '23702'
            ),
            avg_exams_per_patient: (
                SELECT ROUND(AVG(total_exam_count), 2)
                FROM numerator_unique_patients
            )
        }
    }

-- ==================== 主要結果輸出 ====================

-- 半年執行率 (主要運算範圍)
define "Semiannual Performance Rate":
    semiannual_statistics

-- 季度執行率 (供參考)
define "Quarterly Performance Rate":
    quarterly_statistics

-- 年度執行率
define "Annual Performance Rate":
    annual_statistics

-- 分母病患清單 (糖尿病+用藥)
define "Denominator Patient List":
    SELECT 
        d.patient_id,
        d.first_diabetes_medication_date,
        d.has_retinopathy,
        d.total_diabetes_encounters,
        p.name,
        p.birth_date,
        p.gender,
        YEAR(annual_period.end_date) - YEAR(p.birth_date) as age
    FROM 
        denominator_unique_patients d
    LEFT JOIN 
        patient_demographics p ON d.patient_id = p.patient_id
    ORDER BY 
        d.patient_id

-- 分子病患清單 (有眼底檢查)
define "Numerator Patient List":
    SELECT 
        n.patient_id,
        n.first_exam_date,
        n.last_exam_date,
        n.total_exam_count,
        n.exam_details,
        n.has_retinopathy,
        d.first_diabetes_medication_date,
        DATEDIFF(day, d.first_diabetes_medication_date, n.first_exam_date) as days_to_first_exam,
        p.name,
        p.birth_date,
        p.gender,
        YEAR(annual_period.end_date) - YEAR(p.birth_date) as age
    FROM 
        numerator_unique_patients n
    INNER JOIN 
        denominator_unique_patients d ON n.patient_id = d.patient_id
    LEFT JOIN 
        patient_demographics p ON n.patient_id = p.patient_id
    ORDER BY 
        n.patient_id

-- 詳細檢查記錄
define "Detailed Examination Records":
    SELECT 
        e.patient_id,
        e.encounter_id,
        e.exam_date,
        e.source_type,
        e.exam_code,
        e.exam_description,
        en.facility_type,
        d.has_retinopathy,
        p.name as patient_name,
        p.gender,
        YEAR(e.exam_date) - YEAR(p.birth_date) as age_at_exam
    FROM 
        all_fundus_examinations e
    INNER JOIN 
        denominator_unique_patients d ON e.patient_id = d.patient_id
    LEFT JOIN 
        outpatient_encounters en ON e.encounter_id = en.encounter_id
    LEFT JOIN 
        patient_demographics p ON e.patient_id = p.patient_id
    ORDER BY 
        e.patient_id, e.exam_date

-- ==================== 資料品質檢核 ====================

-- 檢核1: 檢查代碼分布
define "Quality Check Exam Code Distribution":
    SELECT 
        exam_code,
        COUNT(DISTINCT patient_id) as patient_count,
        COUNT(*) as total_exam_count,
        MIN(exam_date) as earliest_exam,
        MAX(exam_date) as latest_exam
    FROM 
        all_fundus_examinations
    WHERE 
        patient_id IN (SELECT patient_id FROM denominator_unique_patients)
    GROUP BY 
        exam_code
    ORDER BY 
        patient_count DESC

-- 檢核2: 資料來源分布
define "Quality Check Source Type Distribution":
    SELECT 
        source_type,
        COUNT(DISTINCT patient_id) as patient_count,
        COUNT(*) as total_record_count,
        ROUND(COUNT(DISTINCT patient_id) * 100.0 / 
            (SELECT COUNT(DISTINCT patient_id) FROM numerator_unique_patients), 2) as percentage
    FROM 
        all_fundus_examinations
    WHERE 
        patient_id IN (SELECT patient_id FROM numerator_unique_patients)
    GROUP BY 
        source_type

-- 檢核3: 檢查日期與糖尿病診斷日期的時序關係
define "Quality Check Date Sequence":
    SELECT 
        n.patient_id,
        d.first_diabetes_medication_date,
        n.first_exam_date,
        DATEDIFF(day, d.first_diabetes_medication_date, n.first_exam_date) as days_between,
        CASE 
            WHEN n.first_exam_date >= d.first_diabetes_medication_date THEN 'VALID'
            WHEN DATEDIFF(day, d.first_diabetes_medication_date, n.first_exam_date) > -30 THEN 'ACCEPTABLE'
            ELSE 'QUESTIONABLE'
        END as sequence_status
    FROM 
        numerator_unique_patients n
    INNER JOIN 
        denominator_unique_patients d ON n.patient_id = d.patient_id

-- 檢核4: 視網膜病變診斷與眼底檢查關聯
define "Quality Check Retinopathy Correlation":
    SELECT 
        CASE 
            WHEN has_retinopathy = TRUE THEN '有視網膜病變診斷'
            ELSE '無視網膜病變診斷'
        END as retinopathy_status,
        COUNT(DISTINCT patient_id) as patient_count,
        ROUND(AVG(total_exam_count), 2) as avg_exams_per_patient,
        ROUND(COUNT(DISTINCT patient_id) * 100.0 / 
            (SELECT COUNT(*) FROM numerator_unique_patients), 2) as percentage
    FROM 
        numerator_unique_patients
    GROUP BY 
        has_retinopathy

-- ==================== 統計報告 ====================

define "Summary Report":
    {
        report_title: '眼底檢查或眼底彩色攝影執行率 - 糖尿病品質指標',
        report_date: Today(),
        measurement_period: annual_period.label,
        computation_frequency: '每半年',
        
        overall_statistics: {
            total_diabetes_patients: (SELECT COUNT(*) FROM denominator_unique_patients),
            patients_with_fundus_exams: (SELECT COUNT(*) FROM numerator_unique_patients),
            overall_performance_rate: annual_statistics.performance_rate,
            
            by_exam_code: {
                code_23501_fundus_exam: {
                    patient_count: annual_statistics.statistics_detail.procedure_code_23501_count,
                    description: '眼底檢查'
                },
                code_23502_fundus_exam_enhanced: {
                    patient_count: annual_statistics.statistics_detail.procedure_code_23502_count,
                    description: '眼底檢查 (加強版)'
                },
                code_23702_color_photography: {
                    patient_count: annual_statistics.statistics_detail.procedure_code_23702_count,
                    description: '眼底彩色攝影'
                }
            },
            
            by_retinopathy_status: {
                with_retinopathy: annual_statistics.statistics_detail.patients_with_retinopathy,
                without_retinopathy: (
                    (SELECT COUNT(*) FROM numerator_unique_patients) - 
                    annual_statistics.statistics_detail.patients_with_retinopathy
                )
            }
        },
        
        semiannual_breakdown: semiannual_statistics,
        
        data_quality: {
            denominator_encounters: annual_statistics.statistics_detail.total_diabetes_encounters,
            numerator_exams: annual_statistics.statistics_detail.total_fundus_exams,
            avg_exams_per_patient: annual_statistics.statistics_detail.avg_exams_per_patient,
            data_completeness: 'See Quality Check reports'
        },
        
        notes: {
            note1: '分母為門診主次診斷為糖尿病(E08-E13)且使用糖尿病用藥(ATC:A10)之病人數',
            note2: '分子為分母ID中，於統計期間有執行眼底檢查或眼底彩色攝影之人數',
            note3: '眼底檢查代碼為健保代碼前五碼：23501、23502、23702',
            note4: '資料範圍限定西醫基層、西醫醫院',
            note5: '運算範圍為每半年',
            note6: '建議糖尿病患者每年至少接受一次眼底檢查'
        }
    }
