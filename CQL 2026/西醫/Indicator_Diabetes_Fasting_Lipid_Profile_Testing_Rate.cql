library Indicator_Diabetes_Fasting_Lipid_Profile_Testing_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：2026年糖尿病品質指標
// 條件依據：空腹血脂(Fasting Lipid Profile)執行率
// 製作日期：2026-01-06

/**
 * 公式說明:
 * 空腹血脂(Fasting Lipid Profile)執行率 = 
 *     分子: 分母ID中，在統計期間有執行空腹血脂(Fasting lipid profile)檢驗人數
 *     分母: 門診主次診斷為糖尿病且使用糖尿病用藥之病人數
 * 
 * 備註:
 * (1)糖尿病：任一主、次診斷之ICD 10 CM前三碼為E08-E13之門診案件。
 * (2)糖尿病用藥：指ATC前3碼為A10。
 * (3)空腹血脂(Fasting lipid profile)人數係指年季內:
 *    【條件1】有申報醫令代碼前五碼為09001(血清總膽固醇CHOL)+09004(空腹血清中性脂肪TG)+09043(高密度脂蛋白膽固醇HDL)三項；
 *    【條件2】或有申報醫令代碼前五碼為09001(血清總膽固醇CHOL)+09004(空腹血清中性脂肪TG)+09044(低密度脂蛋白膽固醇LDL)三項；
 *    【條件3】或申報醫令代碼21及就醫序號IC21、或醫令代碼22及就醫序號IC22、或醫令代碼25及就醫序號IC23、
 *             或醫令代碼27及就醫序號IC24、或醫令代碼21+L1001C及就醫序號IC21、或醫令代碼25+L1001C及就醫序號IC23。
 *    【註1：條件1、2的三項檢查需限定要發生在同處方案件。註2：條件3為101年(含)起，新增之空腹血脂人數定義。】
 * (4)計算符合分母條件之ID時，主次診斷為糖尿病且使用糖尿病用藥這兩個條件限定要發生在同處方案件。
 * (5)計算符合分子之ID時，從分母的ID繼續觀察，只要該ID於統計期間有執行空腹血脂(Fasting lipid profile)檢驗即成立。
 * (6)資料範圍：西醫基層、西醫醫院。
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 就醫紀錄 (門診)
 * - Condition: 診斷資料 (主次診斷，糖尿病E08-E13)
 * - MedicationRequest: 藥品處方 (糖尿病用藥A10)
 * - Observation: 檢驗數據 (空腹血脂相關檢驗)
 * - Claim: 醫療費用申報 (檢驗項目代碼09001/09004/09043/09044等)
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

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 73211009: Diabetes mellitus (糖尿病)
    -- 46635009: Type 1 diabetes mellitus (第1型糖尿病)
    -- 44054006: Type 2 diabetes mellitus (第2型糖尿病)
    -- 166842003: Total cholesterol measurement (總膽固醇)
    -- 14647-2: Cholesterol measurement (膽固醇檢測)
    -- 166832001: Serum triglyceride measurement (三酸甘油脂)
    -- 166830009: Serum HDL cholesterol measurement (高密度脂蛋白膽固醇)
    -- 166840006: Serum LDL cholesterol measurement (低密度脂蛋白膽固醇)

codesystem "ATC": 'http://www.whocc.no/atc'
    -- 解剖治療化學分類系統 (ATC)
    -- A10: 糖尿病用藥
    -- A10A: 胰島素及其類似物
    -- A10B: 降血糖藥，不包括胰島素

codesystem "LOINC": 'http://loinc.org'
    -- 邏輯觀察識別碼命名和編碼系統 (LOINC)
    -- 2093-3: Total cholesterol [Mass/volume] in Serum or Plasma (總膽固醇)
    -- 2571-8: Triglyceride [Mass/volume] in Serum or Plasma (三酸甘油脂)
    -- 2085-9: HDL Cholesterol [Mass/volume] in Serum or Plasma (高密度脂蛋白)
    -- 2089-1: LDL Cholesterol [Mass/volume] in Serum or Plasma (低密度脂蛋白)
    -- 57698-3: Lipid panel with direct LDL - Serum or Plasma (血脂組合)
    -- 24331-1: Lipid panel - Serum or Plasma (血脂組合)

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
    -- 09001: 血清總膽固醇(CHOL)
    -- 09004: 空腹血清中性脂肪(TG)
    -- 09043: 高密度脂蛋白膽固醇(HDL)
    -- 09044: 低密度脂蛋白膽固醇(LDL)

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- O: 門診
    -- E: 急診
    -- I: 住院

codesystem "NHI_MEDICAL_ORDER": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medical-order'
    -- 健保醫令代碼系統 (101年起新增)
    -- 21: 空腹血脂檢查組合 (IC21)
    -- 22: 空腹血脂檢查組合 (IC22)
    -- 25: 空腹血脂檢查組合 (IC23)
    -- 27: 空腹血脂檢查組合 (IC24)
    -- L1001C: 血脂檢查加項

-- ==================== 值集定義 ====================

valueset "Diabetes Diagnosis Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-diagnosis'
    -- 糖尿病診斷代碼值集
    -- ICD-10-CM: E08*, E09*, E10*, E11*, E13*
    -- SNOMED CT: 73211009, 46635009, 44054006

valueset "Diabetes Medications": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-medications'
    -- 糖尿病用藥值集
    -- ATC: A10* (所有糖尿病用藥)

valueset "Fasting Lipid Profile Component Tests": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/fasting-lipid-tests'
    -- 空腹血脂組成項目值集
    -- NHI: 09001 (CHOL), 09004 (TG), 09043 (HDL), 09044 (LDL)
    -- LOINC: 2093-3 (CHOL), 2571-8 (TG), 2085-9 (HDL), 2089-1 (LDL)

valueset "Fasting Lipid Profile Package Tests": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/fasting-lipid-package'
    -- 空腹血脂組合檢查值集 (101年起)
    -- NHI Medical Order: 21 (IC21), 22 (IC22), 25 (IC23), 27 (IC24)
    -- LOINC: 57698-3, 24331-1 (Lipid panel)

valueset "Outpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/outpatient-encounter-types'
    -- 門診就醫類別值集
    -- ActCode: AMB (門診)
    -- NHI: O (門診)

valueset "Medical Facility Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/medical-facility-types'
    -- 醫療機構類別值集
    -- 西醫基層診所
    -- 西醫醫院 (醫學中心、區域醫院、地區醫院)

-- ==================== 代碼對照表 ====================

define lipid_test_codes:
    tuple {
        -- 條件1、2: 個別檢驗項目代碼
        cholesterol: tuple {
            nhi_code: '09001',
            loinc_code: '2093-3',
            name: '血清總膽固醇 (Total Cholesterol, CHOL)',
            snomed_code: '166842003'
        },
        triglyceride: tuple {
            nhi_code: '09004',
            loinc_code: '2571-8',
            name: '空腹血清中性脂肪 (Triglyceride, TG)',
            snomed_code: '166832001'
        },
        hdl_cholesterol: tuple {
            nhi_code: '09043',
            loinc_code: '2085-9',
            name: '高密度脂蛋白膽固醇 (HDL Cholesterol)',
            snomed_code: '166830009'
        },
        ldl_cholesterol: tuple {
            nhi_code: '09044',
            loinc_code: '2089-1',
            name: '低密度脂蛋白膽固醇 (LDL Cholesterol)',
            snomed_code: '166840006'
        }
    }

define lipid_package_codes:
    -- 條件3: 組合檢查代碼 (101年起)
    tuple {
        ic21: tuple {
            order_code: '21',
            visit_sequence: 'IC21',
            name: '空腹血脂檢查組合 IC21',
            year_from: 2012  -- 101年
        },
        ic22: tuple {
            order_code: '22',
            visit_sequence: 'IC22',
            name: '空腹血脂檢查組合 IC22',
            year_from: 2012
        },
        ic23: tuple {
            order_code: '25',
            visit_sequence: 'IC23',
            name: '空腹血脂檢查組合 IC23',
            year_from: 2012
        },
        ic24: tuple {
            order_code: '27',
            visit_sequence: 'IC24',
            name: '空腹血脂檢查組合 IC24',
            year_from: 2012
        },
        ic21_enhanced: tuple {
            order_code: '21+L1001C',
            visit_sequence: 'IC21',
            name: '空腹血脂檢查組合 IC21 (加強版)',
            year_from: 2012
        },
        ic23_enhanced: tuple {
            order_code: '25+L1001C',
            visit_sequence: 'IC23',
            name: '空腹血脂檢查組合 IC23 (加強版)',
            year_from: 2012
        }
    }

-- ==================== 統計期間定義 ====================

-- 季度期間定義
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
        END as has_diabetes_secondary_diagnosis
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

-- ==================== 空腹血脂檢驗條件 ====================

-- 4A. 條件1: CHOL + TG + HDL (三項需在同處方案件)
define fasting_lipid_profile_condition1 AS (
    SELECT 
        o1.encounter_id,
        o1.patient_id,
        o1.observation_date,
        o1.visit_sequence,
        'CONDITION_1' as condition_type,
        'CHOL+TG+HDL' as test_combination,
        MAX(CASE WHEN SUBSTRING(o1.nhi_lab_code, 1, 5) = '09001' THEN o1.test_value END) as chol_value,
        MAX(CASE WHEN SUBSTRING(o1.nhi_lab_code, 1, 5) = '09004' THEN o1.test_value END) as tg_value,
        MAX(CASE WHEN SUBSTRING(o1.nhi_lab_code, 1, 5) = '09043' THEN o1.test_value END) as hdl_value
    FROM 
        observation_lab o1
    WHERE 
        -- 同一encounter有三項檢驗
        o1.encounter_id IN (
            SELECT encounter_id
            FROM observation_lab
            WHERE SUBSTRING(nhi_lab_code, 1, 5) IN ('09001', '09004', '09043')
                AND observation_date BETWEEN annual_period.start_date AND annual_period.end_date
            GROUP BY encounter_id, observation_date
            HAVING 
                COUNT(DISTINCT CASE WHEN SUBSTRING(nhi_lab_code, 1, 5) = '09001' THEN 1 END) >= 1
                AND COUNT(DISTINCT CASE WHEN SUBSTRING(nhi_lab_code, 1, 5) = '09004' THEN 1 END) >= 1
                AND COUNT(DISTINCT CASE WHEN SUBSTRING(nhi_lab_code, 1, 5) = '09043' THEN 1 END) >= 1
        )
        AND SUBSTRING(o1.nhi_lab_code, 1, 5) IN ('09001', '09004', '09043')
        AND o1.observation_date BETWEEN annual_period.start_date AND annual_period.end_date
    GROUP BY 
        o1.encounter_id, o1.patient_id, o1.observation_date, o1.visit_sequence
    HAVING 
        -- 確保三項都有值
        COUNT(DISTINCT CASE WHEN SUBSTRING(o1.nhi_lab_code, 1, 5) = '09001' THEN 1 END) >= 1
        AND COUNT(DISTINCT CASE WHEN SUBSTRING(o1.nhi_lab_code, 1, 5) = '09004' THEN 1 END) >= 1
        AND COUNT(DISTINCT CASE WHEN SUBSTRING(o1.nhi_lab_code, 1, 5) = '09043' THEN 1 END) >= 1
)

-- 4B. 條件2: CHOL + TG + LDL (三項需在同處方案件)
define fasting_lipid_profile_condition2 AS (
    SELECT 
        o2.encounter_id,
        o2.patient_id,
        o2.observation_date,
        o2.visit_sequence,
        'CONDITION_2' as condition_type,
        'CHOL+TG+LDL' as test_combination,
        MAX(CASE WHEN SUBSTRING(o2.nhi_lab_code, 1, 5) = '09001' THEN o2.test_value END) as chol_value,
        MAX(CASE WHEN SUBSTRING(o2.nhi_lab_code, 1, 5) = '09004' THEN o2.test_value END) as tg_value,
        MAX(CASE WHEN SUBSTRING(o2.nhi_lab_code, 1, 5) = '09044' THEN o2.test_value END) as ldl_value
    FROM 
        observation_lab o2
    WHERE 
        -- 同一encounter有三項檢驗
        o2.encounter_id IN (
            SELECT encounter_id
            FROM observation_lab
            WHERE SUBSTRING(nhi_lab_code, 1, 5) IN ('09001', '09004', '09044')
                AND observation_date BETWEEN annual_period.start_date AND annual_period.end_date
            GROUP BY encounter_id, observation_date
            HAVING 
                COUNT(DISTINCT CASE WHEN SUBSTRING(nhi_lab_code, 1, 5) = '09001' THEN 1 END) >= 1
                AND COUNT(DISTINCT CASE WHEN SUBSTRING(nhi_lab_code, 1, 5) = '09004' THEN 1 END) >= 1
                AND COUNT(DISTINCT CASE WHEN SUBSTRING(nhi_lab_code, 1, 5) = '09044' THEN 1 END) >= 1
        )
        AND SUBSTRING(o2.nhi_lab_code, 1, 5) IN ('09001', '09004', '09044')
        AND o2.observation_date BETWEEN annual_period.start_date AND annual_period.end_date
    GROUP BY 
        o2.encounter_id, o2.patient_id, o2.observation_date, o2.visit_sequence
    HAVING 
        -- 確保三項都有值
        COUNT(DISTINCT CASE WHEN SUBSTRING(o2.nhi_lab_code, 1, 5) = '09001' THEN 1 END) >= 1
        AND COUNT(DISTINCT CASE WHEN SUBSTRING(o2.nhi_lab_code, 1, 5) = '09004' THEN 1 END) >= 1
        AND COUNT(DISTINCT CASE WHEN SUBSTRING(o2.nhi_lab_code, 1, 5) = '09044' THEN 1 END) >= 1
)

-- 4C. 條件3: 組合檢查代碼 (101年起)
define fasting_lipid_profile_condition3 AS (
    SELECT 
        mo.encounter_id,
        mo.patient_id,
        mo.order_date as observation_date,
        mo.visit_sequence,
        'CONDITION_3' as condition_type,
        mo.order_code || ' (' || mo.visit_sequence || ')' as test_combination,
        NULL as chol_value,
        NULL as tg_value,
        NULL as ldl_value
    FROM 
        medical_order mo
    WHERE 
        -- 醫令代碼與就醫序號配對
        (
            (mo.order_code = '21' AND mo.visit_sequence = 'IC21')
            OR (mo.order_code = '22' AND mo.visit_sequence = 'IC22')
            OR (mo.order_code = '25' AND mo.visit_sequence = 'IC23')
            OR (mo.order_code = '27' AND mo.visit_sequence = 'IC24')
            OR (mo.order_code = '21+L1001C' AND mo.visit_sequence = 'IC21')
            OR (mo.order_code = '25+L1001C' AND mo.visit_sequence = 'IC23')
        )
        
        -- 限定統計期間
        AND mo.order_date BETWEEN annual_period.start_date AND annual_period.end_date
        
        -- 限定101年(含)起
        AND YEAR(mo.order_date) >= 2012
)

-- 4D. 合併所有條件的空腹血脂檢驗
define all_fasting_lipid_profile_tests AS (
    -- 條件1
    SELECT 
        encounter_id, patient_id, observation_date, visit_sequence,
        condition_type, test_combination
    FROM fasting_lipid_profile_condition1
    
    UNION
    
    -- 條件2
    SELECT 
        encounter_id, patient_id, observation_date, visit_sequence,
        condition_type, test_combination
    FROM fasting_lipid_profile_condition2
    
    UNION
    
    -- 條件3
    SELECT 
        encounter_id, patient_id, observation_date, visit_sequence,
        condition_type, test_combination
    FROM fasting_lipid_profile_condition3
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
        COUNT(DISTINCT encounter_id) as total_diabetes_encounters
    FROM 
        diabetes_patients_with_medication_denominator
    GROUP BY 
        patient_id
)

-- ==================== 分子計算 (Numerator) ====================

-- 分子: 分母ID中，在統計期間有執行空腹血脂檢驗人數
-- 從分母的ID繼續觀察，只要該ID於統計期間有執行檢驗即成立

define patients_with_fasting_lipid_profile_test_numerator AS (
    SELECT DISTINCT
        d.patient_id,
        d.first_diabetes_medication_date,
        t.observation_date,
        t.visit_sequence,
        t.condition_type,
        t.test_combination
    FROM 
        denominator_unique_patients d
    INNER JOIN 
        all_fasting_lipid_profile_tests t
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
        COUNT(DISTINCT observation_date) as total_test_count,
        STRING_AGG(DISTINCT condition_type || ': ' || test_combination, '; ') as test_details
    FROM 
        patients_with_fasting_lipid_profile_test_numerator
    GROUP BY 
        patient_id
)

-- ==================== 季度統計 ====================

define quarterly_statistics:
    quarters Q
    return {
        indicator_name: '空腹血脂(Fasting Lipid Profile)執行率',
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
        
        -- 分子: 該季有空腹血脂檢驗的糖尿病病患數
        numerator: (
            SELECT COUNT(DISTINCT n.patient_id)
            FROM patients_with_fasting_lipid_profile_test_numerator n
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
                         FROM patients_with_fasting_lipid_profile_test_numerator n
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
        ),
        
        -- 統計細節
        statistics_detail: {
            condition1_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fasting_lipid_profile_test_numerator
                WHERE observation_date BETWEEN Q.start_date AND Q.end_date
                    AND condition_type = 'CONDITION_1'
            ),
            condition2_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fasting_lipid_profile_test_numerator
                WHERE observation_date BETWEEN Q.start_date AND Q.end_date
                    AND condition_type = 'CONDITION_2'
            ),
            condition3_count: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fasting_lipid_profile_test_numerator
                WHERE observation_date BETWEEN Q.start_date AND Q.end_date
                    AND condition_type = 'CONDITION_3'
            )
        }
    }

-- ==================== 年度統計 ====================

define annual_statistics:
    {
        indicator_name: '空腹血脂(Fasting Lipid Profile)執行率',
        year: annual_period.year,
        period_label: annual_period.label,
        start_date: annual_period.start_date,
        end_date: annual_period.end_date,
        
        -- 分母: 全年糖尿病病患數
        denominator: (
            SELECT COUNT(DISTINCT patient_id)
            FROM denominator_unique_patients
        ),
        
        -- 分子: 全年有空腹血脂檢驗的糖尿病病患數
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
            total_lipid_tests: (
                SELECT SUM(total_test_count)
                FROM numerator_unique_patients
            ),
            condition1_patients: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fasting_lipid_profile_test_numerator
                WHERE condition_type = 'CONDITION_1'
            ),
            condition2_patients: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fasting_lipid_profile_test_numerator
                WHERE condition_type = 'CONDITION_2'
            ),
            condition3_patients: (
                SELECT COUNT(DISTINCT patient_id)
                FROM patients_with_fasting_lipid_profile_test_numerator
                WHERE condition_type = 'CONDITION_3'
            ),
            avg_tests_per_patient: (
                SELECT ROUND(AVG(total_test_count), 2)
                FROM numerator_unique_patients
            )
        }
    }

-- ==================== 主要結果輸出 ====================

-- 季度執行率
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

-- 分子病患清單 (有空腹血脂檢驗)
define "Numerator Patient List":
    SELECT 
        n.patient_id,
        n.first_test_date,
        n.total_test_count,
        n.test_details,
        d.first_diabetes_medication_date,
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
        t.visit_sequence,
        t.condition_type,
        t.test_combination,
        e.facility_type,
        p.name as patient_name,
        p.gender,
        YEAR(t.observation_date) - YEAR(p.birth_date) as age_at_test
    FROM 
        all_fasting_lipid_profile_tests t
    LEFT JOIN 
        outpatient_encounters e ON t.encounter_id = e.encounter_id
    LEFT JOIN 
        patient_demographics p ON t.patient_id = p.patient_id
    WHERE 
        t.patient_id IN (SELECT patient_id FROM denominator_unique_patients)
    ORDER BY 
        t.patient_id, t.observation_date

-- ==================== 資料品質檢核 ====================

-- 檢核1: 條件1的檢驗完整性
define "Quality Check Condition 1":
    SELECT 
        encounter_id,
        patient_id,
        observation_date,
        CASE WHEN chol_value IS NOT NULL THEN 'Y' ELSE 'N' END as has_chol,
        CASE WHEN tg_value IS NOT NULL THEN 'Y' ELSE 'N' END as has_tg,
        CASE WHEN hdl_value IS NOT NULL THEN 'Y' ELSE 'N' END as has_hdl,
        CASE 
            WHEN chol_value IS NOT NULL 
                AND tg_value IS NOT NULL 
                AND hdl_value IS NOT NULL 
            THEN 'COMPLETE'
            ELSE 'INCOMPLETE'
        END as completeness_status
    FROM 
        fasting_lipid_profile_condition1

-- 檢核2: 條件2的檢驗完整性
define "Quality Check Condition 2":
    SELECT 
        encounter_id,
        patient_id,
        observation_date,
        CASE WHEN chol_value IS NOT NULL THEN 'Y' ELSE 'N' END as has_chol,
        CASE WHEN tg_value IS NOT NULL THEN 'Y' ELSE 'N' END as has_tg,
        CASE WHEN ldl_value IS NOT NULL THEN 'Y' ELSE 'N' END as has_ldl,
        CASE 
            WHEN chol_value IS NOT NULL 
                AND tg_value IS NOT NULL 
                AND ldl_value IS NOT NULL 
            THEN 'COMPLETE'
            ELSE 'INCOMPLETE'
        END as completeness_status
    FROM 
        fasting_lipid_profile_condition2

-- 檢核3: 檢驗日期與糖尿病診斷日期的時序關係
define "Quality Check Date Sequence":
    SELECT 
        n.patient_id,
        d.first_diabetes_medication_date,
        n.first_test_date,
        DATEDIFF(day, d.first_diabetes_medication_date, n.first_test_date) as days_between,
        CASE 
            WHEN n.first_test_date >= d.first_diabetes_medication_date THEN 'VALID'
            ELSE 'INVALID'
        END as sequence_status
    FROM 
        numerator_unique_patients n
    INNER JOIN 
        denominator_unique_patients d ON n.patient_id = d.patient_id

-- ==================== 統計報告 ====================

define "Summary Report":
    {
        report_title: '空腹血脂(Fasting Lipid Profile)執行率 - 糖尿病品質指標',
        report_date: Today(),
        measurement_period: annual_period.label,
        
        overall_statistics: {
            total_diabetes_patients: (SELECT COUNT(*) FROM denominator_unique_patients),
            patients_with_lipid_tests: (SELECT COUNT(*) FROM numerator_unique_patients),
            overall_performance_rate: annual_statistics.performance_rate,
            
            by_condition: {
                condition1_chol_tg_hdl: {
                    patient_count: annual_statistics.statistics_detail.condition1_patients,
                    description: '血清總膽固醇+三酸甘油脂+高密度脂蛋白'
                },
                condition2_chol_tg_ldl: {
                    patient_count: annual_statistics.statistics_detail.condition2_patients,
                    description: '血清總膽固醇+三酸甘油脂+低密度脂蛋白'
                },
                condition3_package_test: {
                    patient_count: annual_statistics.statistics_detail.condition3_patients,
                    description: '組合檢查代碼 (101年起)'
                }
            }
        },
        
        quarterly_breakdown: quarterly_statistics,
        
        data_quality: {
            denominator_encounters: annual_statistics.statistics_detail.total_diabetes_encounters,
            numerator_tests: annual_statistics.statistics_detail.total_lipid_tests,
            avg_tests_per_patient: annual_statistics.statistics_detail.avg_tests_per_patient,
            data_completeness: 'See Quality Check reports'
        },
        
        notes: {
            note1: '分母為門診主次診斷為糖尿病(E08-E13)且使用糖尿病用藥(ATC:A10)之病人數',
            note2: '分子為分母ID中，於統計期間有執行空腹血脂檢驗之人數',
            note3: '條件1、2的三項檢查需在同一處方案件',
            note4: '條件3為101年(含)起新增定義',
            note5: '資料範圍限定西醫基層、西醫醫院'
        }
    }
