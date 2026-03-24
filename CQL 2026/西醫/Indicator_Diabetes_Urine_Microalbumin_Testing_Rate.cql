library Indicator_Diabetes_Urine_Microalbumin_Testing_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：2026年糖尿病品質指標
// 條件依據：尿液蛋白質(微蛋白尿白)檢查執行率
// 製作日期：2026-01-06

/**
 * 公式說明:
 * 尿液蛋白質(微蛋白尿白)檢查執行率 = 
 *     分子: 分母ID中，在統計期間有執行尿液微蛋白尿白檢查人數
 *     分母: 門診主次診斷為糖尿病且使用糖尿病用藥之病人數
 * 
 * 備註:
 * (1)糖尿病：任一主、次診斷之ICD_10_CM前三碼為E08-E13之門診案件。
 * (2)糖尿病用藥：指ATC前3碼為A10。
 * (3)尿液微蛋白尿白檢查案件係指申報醫令代碼前五碼為12111或27065之案件。
 * (4)計算符合分母條件之ID時，主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件。
 * (5)計算符合分子之ID時，從分母的ID繼續觀察，只要該ID於統計期間有執行尿液微蛋白尿白檢驗即成立。
 * (6)資料範圍：西醫基層、西醫醫院。
 * (7)運算範圍：每半年。
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 就醫紀錄 (門診)
 * - Condition: 診斷資料 (主次診斷，糖尿病E08-E13)
 * - MedicationRequest: 藥品處方 (糖尿病用藥A10)
 * - Observation: 檢驗數據 (尿液微蛋白、尿蛋白)
 * - Specimen: 檢體資訊 (尿液檢體)
 * - Claim: 醫療費用申報 (檢驗項目代碼12111/27065)
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
    -- E11.21: 第2型糖尿病併糖尿病腎病變
    -- N08.3: 糖尿病腎小球疾病

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 73211009: Diabetes mellitus (糖尿病)
    -- 46635009: Type 1 diabetes mellitus (第1型糖尿病)
    -- 44054006: Type 2 diabetes mellitus (第2型糖尿病)
    -- 312975006: Microalbuminuria (微蛋白尿)
    -- 236499007: Microalbuminuria due to diabetes mellitus (糖尿病性微蛋白尿)
    -- 68172002: Proteinuria (蛋白尿)
    -- 127036006: Diabetic nephropathy (糖尿病腎病變)
    -- 43396009: Urine protein test (尿蛋白檢驗)
    -- 167217005: Urine microalbumin measurement (尿液微蛋白測定)

codesystem "ATC": 'http://www.whocc.no/atc'
    -- 解剖治療化學分類系統 (ATC)
    -- A10: 糖尿病用藥
    -- A10A: 胰島素及其類似物
    -- A10B: 降血糖藥，不包括胰島素

codesystem "LOINC": 'http://loinc.org'
    -- 邏輯觀察識別碼命名和編碼系統 (LOINC)
    -- 1754-1: Albumin [Mass/volume] in Urine (尿液白蛋白)
    -- 2888-6: Protein [Mass/volume] in Urine (尿液蛋白質)
    -- 2889-4: Protein [Mass/time] in 24 hour Urine (24小時尿蛋白)
    -- 13705-9: Albumin/Creatinine [Mass Ratio] in Urine (尿液白蛋白/肌酸酐比值)
    -- 14957-5: Microalbumin [Mass/volume] in Urine (尿液微蛋白)
    -- 30000-4: Microalbumin [Mass/time] in 24 hour Urine (24小時尿液微蛋白)
    -- 9318-7: Albumin/Creatinine [Mass Ratio] in Urine by Test strip (試紙法)
    -- 14958-3: Microalbumin/Creatinine [Mass Ratio] in Urine (微蛋白/肌酸酐比值)

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

codesystem "NHI_LAB_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-lab-code'
    -- 健保檢驗檢查代碼系統
    -- 12111: 尿液微蛋白 (Urine Microalbumin)
    -- 27065: 尿蛋白質定量 (Urine Protein Quantitative)

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- O: 門診
    -- E: 急診
    -- I: 住院

codesystem "SPECIMEN_TYPE": 'http://terminology.hl7.org/CodeSystem/v2-0487'
    -- 檢體類型代碼系統
    -- UR: Urine (尿液)
    -- URC: Urine clean catch (清潔中段尿)
    -- URNS: Urine sediment (尿沉渣)

-- ==================== 值集定義 ====================

valueset "Diabetes Diagnosis Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-diagnosis'
    -- 糖尿病診斷代碼值集
    -- ICD-10-CM: E08*, E09*, E10*, E11*, E13*
    -- SNOMED CT: 73211009, 46635009, 44054006

valueset "Diabetic Nephropathy Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetic-nephropathy'
    -- 糖尿病腎病變代碼值集
    -- ICD-10-CM: E11.21, E11.22, N08.3
    -- SNOMED CT: 127036006, 236499007

valueset "Diabetes Medications": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-medications'
    -- 糖尿病用藥值集
    -- ATC: A10* (所有糖尿病用藥)

valueset "Urine Microalbumin Tests": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/urine-microalbumin-tests'
    -- 尿液微蛋白檢驗值集
    -- NHI: 12111, 27065
    -- LOINC: 1754-1, 14957-5, 13705-9, 9318-7, 14958-3

valueset "Urine Protein Tests": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/urine-protein-tests'
    -- 尿蛋白檢驗值集
    -- LOINC: 2888-6, 2889-4
    -- SNOMED CT: 43396009

valueset "Outpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/outpatient-encounter-types'
    -- 門診就醫類別值集
    -- ActCode: AMB (門診)
    -- NHI: O (門診)

valueset "Medical Facility Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/medical-facility-types'
    -- 醫療機構類別值集
    -- 西醫基層診所
    -- 西醫醫院 (醫學中心、區域醫院、地區醫院)

-- ==================== 代碼對照表 ====================

define urine_microalbumin_test_codes:
    tuple {
        microalbumin: tuple {
            nhi_code: '12111',
            loinc_codes: ['14957-5', '1754-1'],
            snomed_code: '167217005',
            name: '尿液微蛋白 (Urine Microalbumin)',
            description: '尿液中微量白蛋白檢測',
            test_method: 'Immunoturbidimetric / Immunonephelometric'
        },
        protein_quantitative: tuple {
            nhi_code: '27065',
            loinc_codes: ['2888-6', '2889-4'],
            snomed_code: '43396009',
            name: '尿蛋白質定量 (Urine Protein Quantitative)',
            description: '尿液蛋白質定量分析',
            test_method: 'Photometric / Turbidimetric'
        },
        albumin_creatinine_ratio: tuple {
            nhi_code: '12111',  -- 可能包含在微蛋白檢查中
            loinc_codes: ['13705-9', '14958-3', '9318-7'],
            snomed_code: '312975006',
            name: '尿液白蛋白/肌酸酐比值 (Urine Albumin/Creatinine Ratio, ACR)',
            description: '尿液白蛋白與肌酸酐比值',
            test_method: 'Calculated Ratio'
        }
    }

define microalbuminuria_thresholds:
    -- 微蛋白尿診斷標準
    tuple {
        normal: tuple {
            acr_mgPerG: {lower: 0, upper: 30},
            microalbumin_mgPerL: {lower: 0, upper: 20},
            description: '正常範圍'
        },
        microalbuminuria: tuple {
            acr_mgPerG: {lower: 30, upper: 300},
            microalbumin_mgPerL: {lower: 20, upper: 200},
            description: '微蛋白尿'
        },
        macroalbuminuria: tuple {
            acr_mgPerG: {lower: 300, upper: 999999},
            microalbumin_mgPerL: {lower: 200, upper: 999999},
            description: '巨量蛋白尿'
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
        -- 檢查是否有糖尿病腎病變診斷
        CASE 
            WHEN SUBSTRING(oe.primary_diagnosis, 1, 5) IN ('E11.2', 'E10.2', 'E08.2', 'E09.2', 'E13.2')
                OR SUBSTRING(oe.primary_diagnosis, 1, 4) = 'N08.3'
                OR EXISTS (
                    SELECT 1 FROM UNNEST(oe.secondary_diagnoses) as sd
                    WHERE SUBSTRING(sd, 1, 5) IN ('E11.2', 'E10.2', 'E08.2', 'E09.2', 'E13.2')
                        OR SUBSTRING(sd, 1, 4) = 'N08.3'
                ) THEN TRUE
            ELSE FALSE
        END as has_diabetic_nephropathy
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

-- ==================== 尿液微蛋白檢查條件 ====================

-- 4. 尿液微蛋白或尿蛋白檢驗 (醫令代碼前五碼為12111或27065)
define urine_microalbumin_tests AS (
    SELECT 
        o.observation_id,
        o.encounter_id,
        o.patient_id,
        o.observation_date,
        o.loinc_code,
        o.nhi_lab_code,
        o.test_name,
        o.test_value,
        o.test_value_numeric,
        o.unit,
        o.reference_range_low,
        o.reference_range_high,
        o.interpretation,
        o.specimen_type
    FROM 
        observation_lab o
    WHERE 
        -- 健保檢驗代碼前五碼為 12111 或 27065
        (
            SUBSTRING(o.nhi_lab_code, 1, 5) = '12111'  -- 尿液微蛋白
            OR SUBSTRING(o.nhi_lab_code, 1, 5) = '27065'  -- 尿蛋白質定量
        )
        
        -- 或 LOINC代碼
        OR o.loinc_code IN (
            '14957-5',  -- Microalbumin [Mass/volume] in Urine
            '1754-1',   -- Albumin [Mass/volume] in Urine
            '2888-6',   -- Protein [Mass/volume] in Urine
            '2889-4',   -- Protein [Mass/time] in 24 hour Urine
            '13705-9',  -- Albumin/Creatinine [Mass Ratio] in Urine
            '14958-3',  -- Microalbumin/Creatinine [Mass Ratio] in Urine
            '9318-7',   -- Albumin/Creatinine [Mass Ratio] by Test strip
            '30000-4'   -- Microalbumin [Mass/time] in 24 hour Urine
        )
        
        -- 檢體類型為尿液
        AND (o.specimen_type IS NULL OR o.specimen_type IN ('UR', 'URINE', 'URC', 'URNS'))
        
        -- 檢驗結果狀態為完成
        AND o.result_status IN ('final', 'amended', 'corrected')
        
        -- 限定統計期間
        AND o.observation_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 5. 尿液檢體資訊
define urine_specimens AS (
    SELECT 
        s.specimen_id,
        s.encounter_id,
        s.patient_id,
        s.collection_date,
        s.specimen_type,
        s.collection_method,
        s.received_date,
        s.quality_status
    FROM 
        specimen_records s
    WHERE 
        -- 檢體類型為尿液
        s.specimen_type IN ('UR', 'URINE', 'URC', 'URNS')
        
        -- 檢體品質合格
        AND (s.quality_status IS NULL OR s.quality_status IN ('acceptable', 'qualified'))
        
        -- 限定統計期間
        AND s.collection_date BETWEEN annual_period.start_date AND annual_period.end_date
)

-- 6. 合併尿液微蛋白檢查記錄（包含檢體資訊）
define all_urine_microalbumin_tests AS (
    SELECT DISTINCT
        t.observation_id,
        t.encounter_id,
        t.patient_id,
        t.observation_date,
        t.nhi_lab_code,
        t.loinc_code,
        t.test_name,
        t.test_value,
        t.test_value_numeric,
        t.unit,
        t.interpretation,
        s.specimen_type as specimen_detail,
        s.collection_method,
        CASE 
            WHEN SUBSTRING(t.nhi_lab_code, 1, 5) = '12111' THEN 'MICROALBUMIN'
            WHEN SUBSTRING(t.nhi_lab_code, 1, 5) = '27065' THEN 'PROTEIN_QUANTITATIVE'
            WHEN t.loinc_code IN ('13705-9', '14958-3', '9318-7') THEN 'ACR'
            ELSE 'OTHER'
        END as test_category,
        -- 判斷微蛋白尿程度
        CASE 
            WHEN t.loinc_code IN ('13705-9', '14958-3', '9318-7') THEN
                CASE 
                    WHEN t.test_value_numeric < 30 THEN 'NORMAL'
                    WHEN t.test_value_numeric BETWEEN 30 AND 300 THEN 'MICROALBUMINURIA'
                    WHEN t.test_value_numeric > 300 THEN 'MACROALBUMINURIA'
                    ELSE 'UNKNOWN'
                END
            WHEN t.loinc_code IN ('14957-5', '1754-1') THEN
                CASE 
                    WHEN t.test_value_numeric < 20 THEN 'NORMAL'
                    WHEN t.test_value_numeric BETWEEN 20 AND 200 THEN 'MICROALBUMINURIA'
                    WHEN t.test_value_numeric > 200 THEN 'MACROALBUMINURIA'
                    ELSE 'UNKNOWN'
                END
            ELSE 'NOT_APPLICABLE'
        END as albuminuria_level
    FROM 
        urine_microalbumin_tests t
    LEFT JOIN 
        urine_specimens s 
        ON t.encounter_id = s.encounter_id
        AND t.patient_id = s.patient_id
        AND t.observation_date = s.collection_date
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
        de.has_diabetic_nephropathy,
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
        MAX(has_diabetic_nephropathy) as has_nephropathy,
        COUNT(DISTINCT encounter_id) as total_diabetes_encounters
    FROM 
        diabetes_patients_with_medication_denominator
    GROUP BY 
        patient_id
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子: 分母ID中，在統計期間有執行尿液微蛋白尿白檢查人數
-- 從分母的ID繼續觀察，只要該ID於統計期間有執行檢驗即成立

define patients_with_urine_microalbumin_test_numerator AS (
    SELECT DISTINCT
        d.patient_id,
        d.first_diabetes_medication_date,
        d.has_nephropathy,
        t.observation_date,
        t.nhi_lab_code,
        t.loinc_code,
        t.test_category,
        t.test_value,
        t.test_value_numeric,
        t.unit,
        t.albuminuria_level,
        t.interpretation
    FROM 
        denominator_unique_patients d
    INNER JOIN 
        all_urine_microalbumin_tests t
        ON d.patient_id = t.patient_id
    WHERE 
        -- 檢驗日期在統計期間內
        t.observation_date BETWEEN annual_period.start_date AND annual_period.end_date
        
        -- 檢驗日期 >= 糖尿病用藥日期 (確保是糖尿病病患之後的檢驗)
        AND t.observation_date >= d.first_diabetes_medication_date
)

-- 計算分子唯一病患數
define numerator_unique_patients AS (
    SELECT DISTINCT
        patient_id,
        MIN(observation_date) as first_test_date,
        MAX(observation_date) as last_test_date,
        COUNT(DISTINCT observation_date) as total_test_count,
        STRING_AGG(DISTINCT test_category || ': ' || SUBSTRING(nhi_lab_code, 1, 5), '; ') as test_details,
        MAX(has_nephropathy) as has_nephropathy,
        -- 統計最嚴重的蛋白尿程度
        MAX(
            CASE albuminuria_level
                WHEN 'MACROALBUMINURIA' THEN 3
                WHEN 'MICROALBUMINURIA' THEN 2
                WHEN 'NORMAL' THEN 1
                ELSE 0
            END
        ) as max_albuminuria_severity,
        STRING_AGG(DISTINCT albuminuria_level, '; ') as albuminuria_levels
    FROM 
        patients_with_urine_microalbumin_test_numerator
    GROUP BY 
        patient_id
)

-- ==================== 半年統計 (每半年運算) ====================

define semiannual_statistics:
    semiannual_periods S
    return {
        indicator_name: '尿液蛋白質(微蛋白尿白)檢查執行率',
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
        
        -- 分子: 該半年有尿液微蛋白檢驗的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT n.patient_id)
            FROM patients_with_urine_microalbumin_test_numerator n
            INNER JOIN denominator_unique_patients d 
                ON n.patient_id = d.patient_id
            WHERE n.observation_date BETWEEN S.start_date AND S.end_date
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
                         FROM patients_with_urine_microalbumin_test_numerator n
                         INNER JOIN denominator_unique_patients d 
                             ON n.patient_id = d.patient_id
                         WHERE n.observation_date BETWEEN S.start_date AND S.end_date
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
            microalbumin_12111_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE observation_date BETWEEN S.start_date AND S.end_date
                    AND test_category = 'MICROALBUMIN'
            ),
            protein_27065_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE observation_date BETWEEN S.start_date AND S.end_date
                    AND test_category = 'PROTEIN_QUANTITATIVE'
            ),
            acr_test_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE observation_date BETWEEN S.start_date AND S.end_date
                    AND test_category = 'ACR'
            ),
            with_nephropathy_diagnosis: (
                SELECT COUNT(DISTINCT n.patient_id)
                FROM patients_with_urine_microalbumin_test_numerator n
                WHERE n.observation_date BETWEEN S.start_date AND S.end_date
                    AND n.has_nephropathy = TRUE
            ),
            microalbuminuria_detected: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE observation_date BETWEEN S.start_date AND S.end_date
                    AND albuminuria_level = 'MICROALBUMINURIA'
            ),
            macroalbuminuria_detected: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE observation_date BETWEEN S.start_date AND S.end_date
                    AND albuminuria_level = 'MACROALBUMINURIA'
            )
        }
    }

-- ==================== 季度統計 (供參考) ====================

define quarterly_statistics:
    quarters Q
    return {
        indicator_name: '尿液蛋白質(微蛋白尿白)檢查執行率',
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
        
        -- 分子: 該季有尿液微蛋白檢驗的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT n.patient_id)
            FROM patients_with_urine_microalbumin_test_numerator n
            INNER JOIN denominator_unique_patients d 
                ON n.patient_id = d.patient_id
            WHERE n.observation_date BETWEEN Q.start_date AND Q.end_date
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
                         FROM patients_with_urine_microalbumin_test_numerator n
                         INNER JOIN denominator_unique_patients d 
                             ON n.patient_id = d.patient_id
                         WHERE n.observation_date BETWEEN Q.start_date AND Q.end_date
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
        indicator_name: '尿液蛋白質(微蛋白尿白)檢查執行率',
        year: annual_period.year,
        period_label: annual_period.label,
        start_date: annual_period.start_date,
        end_date: annual_period.end_date,
        
        -- 分母: 全年糖尿病病患數
        denominator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM denominator_unique_patients
        ),
        
        -- 分子: 全年有尿液微蛋白檢驗的糖尿病病患數
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
            total_urine_tests: (
                SELECT SUM(total_test_count)
                FROM numerator_unique_patients
            ),
            patients_with_nephropathy: (
                SELECT COUNT(DISTINCT patient_id)
                FROM numerator_unique_patients
                WHERE has_nephropathy = TRUE
            ),
            test_code_12111_microalbumin: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE test_category = 'MICROALBUMIN'
            ),
            test_code_27065_protein: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE test_category = 'PROTEIN_QUANTITATIVE'
            ),
            acr_tests: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_urine_microalbumin_test_numerator
                WHERE test_category = 'ACR'
            ),
            normal_results: (
                SELECT COUNT(DISTINCT patient_id)
                FROM numerator_unique_patients
                WHERE max_albuminuria_severity = 1
            ),
            microalbuminuria_results: (
                SELECT COUNT(DISTINCT patient_id)
                FROM numerator_unique_patients
                WHERE max_albuminuria_severity = 2
            ),
            macroalbuminuria_results: (
                SELECT COUNT(DISTINCT patient_id)
                FROM numerator_unique_patients
                WHERE max_albuminuria_severity = 3
            ),
            avg_tests_per_patient: (
                SELECT ROUND(AVG(total_test_count), 2)
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
        d.has_nephropathy,
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

-- 分子病患清單 (有尿液微蛋白檢驗)
define "Numerator Patient List":
    SELECT 
        n.patient_id,
        n.first_test_date,
        n.last_test_date,
        n.total_test_count,
        n.test_details,
        n.has_nephropathy,
        n.albuminuria_levels,
        CASE n.max_albuminuria_severity
            WHEN 3 THEN 'MACROALBUMINURIA (巨量蛋白尿)'
            WHEN 2 THEN 'MICROALBUMINURIA (微蛋白尿)'
            WHEN 1 THEN 'NORMAL (正常)'
            ELSE 'UNKNOWN (未知)'
        END as albuminuria_status,
        d.first_diabetes_medication_date,
        DATEDIFF(day, d.first_diabetes_medication_date, n.first_test_date) as days_to_first_test,
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

-- 詳細檢驗記錄
define "Detailed Test Records":
    SELECT 
        t.patient_id,
        t.encounter_id,
        t.observation_date,
        t.nhi_lab_code,
        t.loinc_code,
        t.test_category,
        t.test_name,
        t.test_value,
        t.test_value_numeric,
        t.unit,
        t.albuminuria_level,
        t.interpretation,
        t.specimen_detail,
        t.collection_method,
        e.facility_type,
        d.has_nephropathy,
        p.name as patient_name,
        p.gender,
        YEAR(t.observation_date) - YEAR(p.birth_date) as age_at_test
    FROM 
        all_urine_microalbumin_tests t
    INNER JOIN 
        denominator_unique_patients d ON t.patient_id = d.patient_id
    LEFT JOIN 
        outpatient_encounters e ON t.encounter_id = e.encounter_id
    LEFT JOIN 
        patient_demographics p ON t.patient_id = p.patient_id
    ORDER BY 
        t.patient_id, t.observation_date

-- ==================== 資料品質檢核 ====================

-- 檢核1: 檢驗代碼分布
define "Quality Check Test Code Distribution":
    SELECT 
        test_category,
        SUBSTRING(nhi_lab_code, 1, 5) as test_code,
        COUNT(DISTINCT patient_id) as patient_count,
        COUNT(*) as total_test_count,
        MIN(observation_date) as earliest_test,
        MAX(observation_date) as latest_test
    FROM 
        all_urine_microalbumin_tests
    WHERE 
        patient_id IN (SELECT patient_id FROM denominator_unique_patients)
    GROUP BY 
        test_category, SUBSTRING(nhi_lab_code, 1, 5)
    ORDER BY 
        patient_count DESC

-- 檢核2: 蛋白尿程度分布
define "Quality Check Albuminuria Level Distribution":
    SELECT 
        albuminuria_level,
        COUNT(DISTINCT patient_id) as patient_count,
        COUNT(*) as total_test_count,
        ROUND(COUNT(DISTINCT patient_id) * 100.0 / 
            (SELECT COUNT(DISTINCT patient_id) FROM numerator_unique_patients), 2) as percentage
    FROM 
        all_urine_microalbumin_tests
    WHERE 
        patient_id IN (SELECT patient_id FROM numerator_unique_patients)
        AND albuminuria_level != 'NOT_APPLICABLE'
    GROUP BY 
        albuminuria_level
    ORDER BY 
        patient_count DESC

-- 檢核3: 檢驗日期與糖尿病診斷日期的時序關係
define "Quality Check Date Sequence":
    SELECT 
        n.patient_id,
        d.first_diabetes_medication_date,
        n.first_test_date,
        DATEDIFF(day, d.first_diabetes_medication_date, n.first_test_date) as days_between,
        CASE 
            WHEN n.first_test_date >= d.first_diabetes_medication_date THEN 'VALID'
            WHEN DATEDIFF(day, d.first_diabetes_medication_date, n.first_test_date) > -30 THEN 'ACCEPTABLE'
            ELSE 'QUESTIONABLE'
        END as sequence_status
    FROM 
        numerator_unique_patients n
    INNER JOIN 
        denominator_unique_patients d ON n.patient_id = d.patient_id

-- 檢核4: 腎病變診斷與檢驗結果關聯
define "Quality Check Nephropathy Correlation":
    SELECT 
        CASE 
            WHEN has_nephropathy = TRUE THEN '有腎病變診斷'
            ELSE '無腎病變診斷'
        END as nephropathy_status,
        COUNT(DISTINCT patient_id) as patient_count,
        ROUND(AVG(total_test_count), 2) as avg_tests_per_patient,
        SUM(CASE WHEN max_albuminuria_severity >= 2 THEN 1 ELSE 0 END) as abnormal_results,
        ROUND(COUNT(DISTINCT patient_id) * 100.0 / 
            (SELECT COUNT(*) FROM numerator_unique_patients), 2) as percentage
    FROM 
        numerator_unique_patients
    GROUP BY 
        has_nephropathy

-- 檢核5: 檢驗數值分布 (ACR測試)
define "Quality Check ACR Value Distribution":
    SELECT 
        CASE 
            WHEN test_value_numeric < 30 THEN '< 30 mg/g (正常)'
            WHEN test_value_numeric BETWEEN 30 AND 300 THEN '30-300 mg/g (微蛋白尿)'
            WHEN test_value_numeric > 300 THEN '> 300 mg/g (巨量蛋白尿)'
            ELSE '無數值'
        END as acr_range,
        COUNT(DISTINCT patient_id) as patient_count,
        ROUND(AVG(test_value_numeric), 2) as avg_value,
        MIN(test_value_numeric) as min_value,
        MAX(test_value_numeric) as max_value
    FROM 
        all_urine_microalbumin_tests
    WHERE 
        patient_id IN (SELECT patient_id FROM numerator_unique_patients)
        AND test_category = 'ACR'
        AND test_value_numeric IS NOT NULL
    GROUP BY 
        CASE 
            WHEN test_value_numeric < 30 THEN '< 30 mg/g (正常)'
            WHEN test_value_numeric BETWEEN 30 AND 300 THEN '30-300 mg/g (微蛋白尿)'
            WHEN test_value_numeric > 300 THEN '> 300 mg/g (巨量蛋白尿)'
            ELSE '無數值'
        END
    ORDER BY 
        patient_count DESC

-- ==================== 統計報告 ====================

define "Summary Report":
    {
        report_title: '尿液蛋白質(微蛋白尿白)檢查執行率 - 糖尿病品質指標',
        report_date: Today(),
        measurement_period: annual_period.label,
        computation_frequency: '每半年',
        
        overall_statistics: {
            total_diabetes_patients: (SELECT COUNT(*) FROM denominator_unique_patients),
            patients_with_urine_tests: (SELECT COUNT(*) FROM numerator_unique_patients),
            overall_performance_rate: annual_statistics.performance_rate,
            
            by_test_code: {
                code_12111_microalbumin: {
                    patient_count: annual_statistics.statistics_detail.test_code_12111_microalbumin,
                    description: '尿液微蛋白'
                },
                code_27065_protein: {
                    patient_count: annual_statistics.statistics_detail.test_code_27065_protein,
                    description: '尿蛋白質定量'
                },
                acr_test: {
                    patient_count: annual_statistics.statistics_detail.acr_tests,
                    description: '白蛋白/肌酸酐比值'
                }
            },
            
            by_result_category: {
                normal: {
                    patient_count: annual_statistics.statistics_detail.normal_results,
                    description: '正常範圍',
                    threshold: '< 30 mg/g (ACR) or < 20 mg/L (Microalbumin)'
                },
                microalbuminuria: {
                    patient_count: annual_statistics.statistics_detail.microalbuminuria_results,
                    description: '微蛋白尿',
                    threshold: '30-300 mg/g (ACR) or 20-200 mg/L (Microalbumin)'
                },
                macroalbuminuria: {
                    patient_count: annual_statistics.statistics_detail.macroalbuminuria_results,
                    description: '巨量蛋白尿',
                    threshold: '> 300 mg/g (ACR) or > 200 mg/L (Microalbumin)'
                }
            },
            
            by_nephropathy_status: {
                with_nephropathy: annual_statistics.statistics_detail.patients_with_nephropathy,
                without_nephropathy: (
                    (SELECT COUNT(*) FROM numerator_unique_patients) - 
                    annual_statistics.statistics_detail.patients_with_nephropathy
                )
            }
        },
        
        semiannual_breakdown: semiannual_statistics,
        
        data_quality: {
            denominator_encounters: annual_statistics.statistics_detail.total_diabetes_encounters,
            numerator_tests: annual_statistics.statistics_detail.total_urine_tests,
            avg_tests_per_patient: annual_statistics.statistics_detail.avg_tests_per_patient,
            data_completeness: 'See Quality Check reports'
        },
        
        clinical_notes: {
            note1: '微蛋白尿是糖尿病腎病變的早期指標',
            note2: 'ACR (白蛋白/肌酸酐比值) 是推薦的篩檢方法',
            note3: '建議糖尿病患者每年至少檢測一次尿液微蛋白',
            note4: 'ACR ≥ 30 mg/g 或微蛋白 ≥ 20 mg/L 提示微蛋白尿',
            note5: '持續性微蛋白尿需要重複檢測確認'
        },
        
        notes: {
            note1: '分母為門診主次診斷為糖尿病(E08-E13)且使用糖尿病用藥(ATC:A10)之病人數',
            note2: '分子為分母ID中，於統計期間有執行尿液微蛋白檢驗之人數',
            note3: '檢驗代碼為健保代碼前五碼：12111(微蛋白)、27065(尿蛋白定量)',
            note4: '資料範圍限定西醫基層、西醫醫院',
            note5: '運算範圍為每半年',
            note6: '包含ACR、尿液微蛋白、尿蛋白質定量等多種檢驗方式'
        }
    }
