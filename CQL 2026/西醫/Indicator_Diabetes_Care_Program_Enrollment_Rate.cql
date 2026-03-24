library Indicator_Diabetes_Care_Program_Enrollment_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：2026年糖尿病品質指標
// 條件依據：糖尿病病人加入照護方案比率
// 製作日期：2026-01-06

/**
 * 公式說明:
 * 糖尿病病人加入照護方案比率 = 
 *     分子: 在統計期間收案進入「糖尿病方案或糖尿病合併初期慢性腎臟病照護整合方案」之人數
 *          (即：門診及住院中，有申報醫令前3碼為P14或門診中，有申報醫令前3碼為P70之人數)
 *     分母: 上年度全年資料中門診主診斷為糖尿病且在同院、同ID、同生日下，任2次就醫日期間隔介於0到90天之人數
 * 
 * 備註:
 * (1)分母條件：上年度全年資料中門診主診斷為糖尿病且在同院、同ID、同生日下，任2次就醫日期間隔介於0到90天之人數。
 *    【註1：100年分母，分子統計期間相同，如：100年上半年度分子、分母統計期間皆為100.01-100.06，100年全年度皆為100.01-100.12。
 *     註2：101年修訂定義，A.若分子>分母時，修改成分母=分子(以分子為主)；B.分母改採用「上年度全年資料」即分母固定，
 *          如：101年上半年度及全年度，分母統計期間皆為100.01-100.12。
 *     註3：102年分母刪除收案條件需「同醫師」之規定】
 * (2)分母排除：08案件、補載原因註記為2案件及醫令調劑方式為3、5之案件。
 * (3)糖尿病：主診斷之ICD-10-CM前三碼為E08-E13之門診案件。
 * (4)分子自112年1月起新增糖尿病合併初期慢性腎臟病照護整合方案之案件。
 * (5)資料範圍：門診(西醫基層+西醫醫院)+住院(西醫基層+西醫醫院)。
 * (6)運算範圍：103年起更改為季累計，之前為每半年。
 * 
 * FHIR Resource對照:
 * - Patient: 病患基本資料
 * - Encounter: 就醫紀錄 (門診+住院)
 * - Condition: 診斷資料 (主診斷，糖尿病E08-E13)
 * - CarePlan: 照護計畫 (糖尿病照護方案)
 * - Procedure: 處置記錄 (照護方案執行)
 * - Claim: 醫療費用申報 (醫令代碼P14/P70)
 * - Organization: 醫療機構資訊
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
    -- E11.2*: 第2型糖尿病併腎臟併發症
    -- N18.1-N18.3: 慢性腎臟病第1-3期

codesystem "SNOMEDCT": 'http://snomed.info/sct'
    -- SNOMED CT 臨床術語系統
    -- 73211009: Diabetes mellitus (糖尿病)
    -- 46635009: Type 1 diabetes mellitus (第1型糖尿病)
    -- 44054006: Type 2 diabetes mellitus (第2型糖尿病)
    -- 385804009: Diabetes care plan (糖尿病照護計畫)
    -- 386359008: Diabetes management program (糖尿病管理方案)
    -- 127036006: Diabetic nephropathy (糖尿病腎病變)
    -- 431855005: Chronic kidney disease stage 1 (慢性腎臟病第1期)
    -- 431856006: Chronic kidney disease stage 2 (慢性腎臟病第2期)
    -- 433144002: Chronic kidney disease stage 3 (慢性腎臟病第3期)

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

codesystem "NHI_CARE_PLAN_CODE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-care-plan-code'
    -- 健保照護方案代碼系統
    -- P14: 糖尿病醫療給付改善方案
    -- P70: 糖尿病合併初期慢性腎臟病照護整合方案 (112年1月起)

codesystem "NHI_ENCOUNTER_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-encounter-type'
    -- 健保就醫類別代碼系統
    -- O: 門診
    -- E: 急診
    -- I: 住院

codesystem "NHI_CASE_TYPE": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-case-type'
    -- 健保案件類別代碼
    -- 08: 特殊案件 (需排除)

codesystem "NHI_DISPENSING_METHOD": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-dispensing-method'
    -- 健保調劑方式代碼
    -- 3: 特殊調劑方式 (需排除)
    -- 5: 特殊調劑方式 (需排除)

-- ==================== 值集定義 ====================

valueset "Diabetes Diagnosis Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-diagnosis'
    -- 糖尿病診斷代碼值集 (主診斷)
    -- ICD-10-CM: E08*, E09*, E10*, E11*, E13*
    -- SNOMED CT: 73211009, 46635009, 44054006

valueset "Diabetic Nephropathy Early Stage Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetic-nephropathy-early'
    -- 糖尿病合併初期慢性腎臟病代碼值集
    -- ICD-10-CM: E11.21, E11.22, N18.1, N18.2, N18.3
    -- SNOMED CT: 127036006, 431855005, 431856006, 433144002

valueset "Diabetes Care Plan Codes": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/diabetes-care-plan'
    -- 糖尿病照護方案值集
    -- NHI: P14 (糖尿病方案), P70 (糖尿病合併初期慢性腎臟病方案)

valueset "Outpatient and Inpatient Encounter Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/outpatient-inpatient-encounter-types'
    -- 門診及住院就醫類別值集
    -- ActCode: AMB (門診), IMP (住院)
    -- NHI: O (門診), I (住院)

valueset "Medical Facility Types": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/medical-facility-types'
    -- 醫療機構類別值集
    -- 西醫基層診所
    -- 西醫醫院 (醫學中心、區域醫院、地區醫院)

-- ==================== 代碼對照表 ====================

define diabetes_care_plan_codes:
    tuple {
        p14_diabetes_program: tuple {
            nhi_code: 'P14',
            full_code_prefix: 'P14',
            name: '糖尿病醫療給付改善方案',
            description: '糖尿病共同照護網照護方案',
            effective_date: @2011-01-01,  -- 100年起
            applicable_settings: ['OUTPATIENT', 'INPATIENT'],
            snomed_code: '385804009'
        },
        p70_diabetes_ckd_program: tuple {
            nhi_code: 'P70',
            full_code_prefix: 'P70',
            name: '糖尿病合併初期慢性腎臟病照護整合方案',
            description: '糖尿病合併CKD 1-3a期整合照護',
            effective_date: @2023-01-01,  -- 112年1月起
            applicable_settings: ['OUTPATIENT'],
            snomed_code: '386359008'
        }
    }

define excluded_case_criteria:
    -- 分母排除條件
    tuple {
        case_type_08: tuple {
            code: '08',
            description: '特殊案件 (需排除)',
            exclusion_reason: '非一般案件'
        },
        reload_reason_2: tuple {
            code: '2',
            description: '補載原因註記為2',
            exclusion_reason: '資料補載案件'
        },
        dispensing_method_3: tuple {
            code: '3',
            description: '醫令調劑方式為3',
            exclusion_reason: '特殊調劑方式'
        },
        dispensing_method_5: tuple {
            code: '5',
            description: '醫令調劑方式為5',
            exclusion_reason: '特殊調劑方式'
        }
    }

-- ==================== 統計期間定義 ====================

-- 當前年度與上年度定義
define current_year: 2026  -- 115年
define previous_year: 2025  -- 114年 (分母使用上年度全年資料)

-- 季度期間定義 (103年起改為季累計)
define quarters_current_year:
    {
        {id: 1, year: current_year, quarter: 1, start_date: @2026-01-01, end_date: @2026-03-31, label: '115年第1季', cumulative_start: @2026-01-01},
        {id: 2, year: current_year, quarter: 2, start_date: @2026-04-01, end_date: @2026-06-30, label: '115年第2季', cumulative_start: @2026-01-01},
        {id: 3, year: current_year, quarter: 3, start_date: @2026-07-01, end_date: @2026-09-30, label: '115年第3季', cumulative_start: @2026-01-01},
        {id: 4, year: current_year, quarter: 4, start_date: @2026-10-01, end_date: @2026-12-31, label: '115年第4季', cumulative_start: @2026-01-01}
    }

-- 上年度期間定義 (分母固定使用上年度全年)
define previous_year_period:
    {
        year: previous_year,
        start_date: @2025-01-01,
        end_date: @2025-12-31,
        label: '114年 (2025) 全年'
    }

-- 當前年度期間定義
define current_year_period:
    {
        year: current_year,
        start_date: @2026-01-01,
        end_date: @2026-12-31,
        label: '115年 (2026)'
    }

-- ==================== 資料篩選條件 ====================

-- 1. 門診及住院就醫記錄 (限定西醫基層+西醫醫院)
define outpatient_and_inpatient_encounters AS (
    SELECT 
        e.encounter_id,
        e.patient_id,
        e.visit_date,
        e.encounter_type,
        e.primary_diagnosis,
        e.secondary_diagnoses,
        e.facility_id,
        e.facility_name,
        e.facility_type,
        e.case_type,
        e.reload_reason,
        e.dispensing_method,
        e.agency_flag,
        p.birth_date
    FROM 
        encounter_details e
    INNER JOIN
        patient_demographics p ON e.patient_id = p.patient_id
    WHERE 
        -- 門診或住院案件
        e.encounter_type IN ('O', 'I', 'AMB', 'IMP')
        
        -- 限定西醫基層、西醫醫院
        AND e.facility_type IN ('CLINIC_WESTERN', 'HOSPITAL_MEDICAL_CENTER', 
                                'HOSPITAL_REGIONAL', 'HOSPITAL_DISTRICT')
        
        -- 排除代辦案件
        AND (e.agency_flag IS NULL OR e.agency_flag != 'Y')
)

-- ==================== 分母計算 (Denominator) ====================
-- 分母：上年度全年資料中門診主診斷為糖尿病且在同院、同ID、同生日下，任2次就醫日期間隔介於0到90天之人數

-- 2A. 上年度門診糖尿病主診斷案件 (排除特殊案件)
define previous_year_diabetes_encounters AS (
    SELECT 
        e.encounter_id,
        e.patient_id,
        e.visit_date,
        e.primary_diagnosis,
        e.facility_id,
        e.facility_name,
        e.birth_date
    FROM 
        outpatient_and_inpatient_encounters e
    WHERE 
        -- 限定門診案件
        e.encounter_type IN ('O', 'AMB')
        
        -- 主診斷為糖尿病 (E08-E13)
        AND SUBSTRING(e.primary_diagnosis, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
        
        -- 上年度全年資料
        AND e.visit_date BETWEEN previous_year_period.start_date AND previous_year_period.end_date
        
        -- 排除條件：08案件
        AND (e.case_type IS NULL OR e.case_type != '08')
        
        -- 排除條件：補載原因註記為2
        AND (e.reload_reason IS NULL OR e.reload_reason != '2')
        
        -- 排除條件：醫令調劑方式為3或5
        AND (e.dispensing_method IS NULL OR e.dispensing_method NOT IN ('3', '5'))
)

-- 2B. 找出符合條件的病患：同院、同ID、同生日、任2次就醫間隔0-90天
define denominator_qualified_patients AS (
    SELECT DISTINCT
        e1.patient_id,
        e1.facility_id,
        e1.facility_name,
        e1.birth_date,
        COUNT(DISTINCT e1.encounter_id) as total_encounters,
        MIN(e1.visit_date) as first_visit_date,
        MAX(e1.visit_date) as last_visit_date
    FROM 
        previous_year_diabetes_encounters e1
    WHERE 
        EXISTS (
            SELECT 1
            FROM previous_year_diabetes_encounters e2
            WHERE 
                -- 同一病患
                e1.patient_id = e2.patient_id
                
                -- 同一醫院
                AND e1.facility_id = e2.facility_id
                
                -- 同生日 (已在JOIN時確保)
                AND e1.birth_date = e2.birth_date
                
                -- 不同次就醫
                AND e1.encounter_id != e2.encounter_id
                
                -- 就醫日期間隔介於0到90天
                AND ABS(DATEDIFF(day, e1.visit_date, e2.visit_date)) BETWEEN 0 AND 90
        )
    GROUP BY 
        e1.patient_id, e1.facility_id, e1.facility_name, e1.birth_date
)

-- 2C. 分母病患清單
define denominator_unique_patients AS (
    SELECT DISTINCT
        patient_id,
        MIN(first_visit_date) as earliest_diabetes_visit,
        MAX(last_visit_date) as latest_diabetes_visit,
        COUNT(DISTINCT facility_id) as total_facilities,
        SUM(total_encounters) as total_qualifying_encounters
    FROM 
        denominator_qualified_patients
    GROUP BY 
        patient_id
)

-- ==================== 分子計算 (Numerator) ====================
-- 分子：在統計期間收案進入照護方案之人數

-- 3A. P14 糖尿病照護方案 (門診+住院)
define p14_care_plan_enrollments AS (
    SELECT 
        cp.care_plan_id,
        cp.encounter_id,
        cp.patient_id,
        cp.enrollment_date,
        cp.care_plan_code,
        cp.care_plan_name,
        cp.status,
        e.encounter_type,
        e.facility_id,
        e.facility_name
    FROM 
        care_plan_records cp
    INNER JOIN
        outpatient_and_inpatient_encounters e ON cp.encounter_id = e.encounter_id
    WHERE 
        -- P14 醫令代碼前3碼
        SUBSTRING(cp.care_plan_code, 1, 3) = 'P14'
        
        -- 照護方案狀態為已啟動
        AND cp.status IN ('active', 'completed')
        
        -- 門診或住院案件
        AND e.encounter_type IN ('O', 'I', 'AMB', 'IMP')
        
        -- 當前年度
        AND cp.enrollment_date BETWEEN current_year_period.start_date AND current_year_period.end_date
)

-- 3B. P70 糖尿病合併初期慢性腎臟病照護整合方案 (門診) - 112年1月起
define p70_care_plan_enrollments AS (
    SELECT 
        cp.care_plan_id,
        cp.encounter_id,
        cp.patient_id,
        cp.enrollment_date,
        cp.care_plan_code,
        cp.care_plan_name,
        cp.status,
        e.encounter_type,
        e.facility_id,
        e.facility_name
    FROM 
        care_plan_records cp
    INNER JOIN
        outpatient_and_inpatient_encounters e ON cp.encounter_id = e.encounter_id
    WHERE 
        -- P70 醫令代碼前3碼
        SUBSTRING(cp.care_plan_code, 1, 3) = 'P70'
        
        -- 照護方案狀態為已啟動
        AND cp.status IN ('active', 'completed')
        
        -- 僅門診案件 (P70限定門診)
        AND e.encounter_type IN ('O', 'AMB')
        
        -- 112年1月起
        AND cp.enrollment_date >= @2023-01-01
        
        -- 當前年度
        AND cp.enrollment_date BETWEEN current_year_period.start_date AND current_year_period.end_date
)

-- 3C. 合併所有照護方案收案記錄
define all_care_plan_enrollments AS (
    -- P14方案
    SELECT 
        patient_id, enrollment_date, 'P14' as program_type,
        care_plan_code, care_plan_name, encounter_type, facility_id, facility_name
    FROM p14_care_plan_enrollments
    
    UNION
    
    -- P70方案
    SELECT 
        patient_id, enrollment_date, 'P70' as program_type,
        care_plan_code, care_plan_name, encounter_type, facility_id, facility_name
    FROM p70_care_plan_enrollments
)

-- 3D. 分子病患清單 (僅限分母中的病患)
define numerator_enrolled_patients AS (
    SELECT DISTINCT
        e.patient_id,
        MIN(e.enrollment_date) as first_enrollment_date,
        MAX(e.enrollment_date) as last_enrollment_date,
        COUNT(DISTINCT e.program_type) as enrolled_program_count,
        STRING_AGG(DISTINCT e.program_type, ', ') as enrolled_programs,
        COUNT(DISTINCT e.enrollment_date) as total_enrollment_count
    FROM 
        all_care_plan_enrollments e
    INNER JOIN
        denominator_unique_patients d ON e.patient_id = d.patient_id
    GROUP BY 
        e.patient_id
)

-- 3E. 分子病患清單 (包含非分母病患，用於比例修正)
define numerator_all_enrolled_patients AS (
    SELECT DISTINCT
        patient_id,
        MIN(enrollment_date) as first_enrollment_date,
        MAX(enrollment_date) as last_enrollment_date,
        COUNT(DISTINCT program_type) as enrolled_program_count,
        STRING_AGG(DISTINCT program_type, ', ') as enrolled_programs,
        COUNT(DISTINCT enrollment_date) as total_enrollment_count
    FROM 
        all_care_plan_enrollments
    GROUP BY 
        patient_id
)

-- ==================== 季度累計統計 (103年起改為季累計) ====================

define quarterly_cumulative_statistics:
    quarters_current_year Q
    return {
        indicator_name: '糖尿病病人加入照護方案比率',
        year: Q.year,
        quarter: Q.quarter,
        period_label: Q.label,
        start_date: Q.start_date,
        end_date: Q.end_date,
        cumulative_start_date: Q.cumulative_start,
        is_cumulative: TRUE,
        
        -- 分母：上年度全年符合條件的糖尿病病患數 (固定)
        denominator_original: (
            SELECT COUNT(DISTINCT patient_id)
            FROM denominator_unique_patients
        ),
        
        -- 分子：該季累計收案人數 (從年初到當季末)
        numerator_original: (
            SELECT COUNT(DISTINCT e.patient_id)
            FROM all_care_plan_enrollments e
            INNER JOIN denominator_unique_patients d ON e.patient_id = d.patient_id
            WHERE e.enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
        ),
        
        -- 分子 (所有收案人數，含非分母病患)
        numerator_total: (
            SELECT COUNT(DISTINCT patient_id)
            FROM all_care_plan_enrollments
            WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
        ),
        
        -- 修正後的分母 (101年起：若分子>分母，則分母=分子)
        denominator_adjusted: (
            CASE 
                WHEN (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments 
                      WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date) >
                     (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
                THEN (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments 
                      WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date)
                ELSE (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
            END
        ),
        
        -- 修正後的分子 (使用所有收案人數)
        numerator_adjusted: (
            SELECT COUNT(DISTINCT patient_id)
            FROM all_care_plan_enrollments
            WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
        ),
        
        -- 加入率 (%) - 使用修正後數值
        enrollment_rate: (
            CASE 
                WHEN (
                    CASE 
                        WHEN (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments 
                              WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date) >
                             (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
                        THEN (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments 
                              WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date)
                        ELSE (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
                    END
                ) > 0
                THEN 
                    ROUND(
                        (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments
                         WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date) * 100.0 /
                        (
                            CASE 
                                WHEN (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments 
                                      WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date) >
                                     (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
                                THEN (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments 
                                      WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date)
                                ELSE (SELECT COUNT(DISTINCT patient_id) FROM denominator_unique_patients)
                            END
                        )
                    , 2)
                ELSE 0.0
            END
        ),
        
        -- 統計細節
        statistics_detail: {
            p14_enrollments: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
                    AND program_type = 'P14'
            ),
            p70_enrollments: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
                    AND program_type = 'P70'
            ),
            both_programs: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
                    AND patient_id IN (
                        SELECT patient_id FROM all_care_plan_enrollments
                        WHERE program_type = 'P14' AND enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
                    )
                    AND patient_id IN (
                        SELECT patient_id FROM all_care_plan_enrollments
                        WHERE program_type = 'P70' AND enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
                    )
            ),
            outpatient_enrollments: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
                    AND encounter_type IN ('O', 'AMB')
            ),
            inpatient_enrollments: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE enrollment_date BETWEEN Q.cumulative_start AND Q.end_date
                    AND encounter_type IN ('I', 'IMP')
            )
        }
    }

-- ==================== 年度統計 ====================

define annual_statistics:
    {
        indicator_name: '糖尿病病人加入照護方案比率',
        year: current_year_period.year,
        period_label: current_year_period.label,
        start_date: current_year_period.start_date,
        end_date: current_year_period.end_date,
        denominator_period: previous_year_period.label,
        
        -- 分母：上年度全年符合條件的糖尿病病患數 (固定)
        denominator_original: (
            SELECT COUNT(DISTINCT patient_id)
            FROM denominator_unique_patients
        ),
        
        -- 分子：當前年度全年收案人數
        numerator_original: (
            SELECT COUNT(DISTINCT e.patient_id)
            FROM all_care_plan_enrollments e
            INNER JOIN denominator_unique_patients d ON e.patient_id = d.patient_id
        ),
        
        -- 分子 (所有收案人數，含非分母病患)
        numerator_total: (
            SELECT COUNT(DISTINCT patient_id)
            FROM numerator_all_enrolled_patients
        ),
        
        -- 修正後的分母 (101年起：若分子>分母，則分母=分子)
        denominator_adjusted: (
            CASE 
                WHEN (SELECT COUNT(*) FROM numerator_all_enrolled_patients) >
                     (SELECT COUNT(*) FROM denominator_unique_patients)
                THEN (SELECT COUNT(*) FROM numerator_all_enrolled_patients)
                ELSE (SELECT COUNT(*) FROM denominator_unique_patients)
            END
        ),
        
        -- 修正後的分子
        numerator_adjusted: (
            SELECT COUNT(*)
            FROM numerator_all_enrolled_patients
        ),
        
        -- 加入率 (%) - 使用修正後數值
        enrollment_rate: (
            CASE 
                WHEN (
                    CASE 
                        WHEN (SELECT COUNT(*) FROM numerator_all_enrolled_patients) >
                             (SELECT COUNT(*) FROM denominator_unique_patients)
                        THEN (SELECT COUNT(*) FROM numerator_all_enrolled_patients)
                        ELSE (SELECT COUNT(*) FROM denominator_unique_patients)
                    END
                ) > 0
                THEN 
                    ROUND(
                        (SELECT COUNT(*) FROM numerator_all_enrolled_patients) * 100.0 /
                        (
                            CASE 
                                WHEN (SELECT COUNT(*) FROM numerator_all_enrolled_patients) >
                                     (SELECT COUNT(*) FROM denominator_unique_patients)
                                THEN (SELECT COUNT(*) FROM numerator_all_enrolled_patients)
                                ELSE (SELECT COUNT(*) FROM denominator_unique_patients)
                            END
                        )
                    , 2)
                ELSE 0.0
            END
        ),
        
        -- 統計細節
        statistics_detail: {
            denominator_facilities: (
                SELECT COUNT(DISTINCT facility_id)
                FROM denominator_qualified_patients
            ),
            denominator_total_encounters: (
                SELECT SUM(total_qualifying_encounters)
                FROM denominator_unique_patients
            ),
            p14_total_enrollments: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE program_type = 'P14'
            ),
            p70_total_enrollments: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE program_type = 'P70'
            ),
            both_programs_enrolled: (
                SELECT COUNT(*)
                FROM numerator_all_enrolled_patients
                WHERE enrolled_program_count >= 2
            ),
            outpatient_only_enrollments: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE encounter_type IN ('O', 'AMB')
            ),
            inpatient_enrolled: (
                SELECT COUNT(DISTINCT patient_id)
                FROM all_care_plan_enrollments
                WHERE encounter_type IN ('I', 'IMP')
            ),
            avg_enrollments_per_patient: (
                SELECT ROUND(AVG(total_enrollment_count), 2)
                FROM numerator_all_enrolled_patients
            )
        }
    }

-- ==================== 主要結果輸出 ====================

-- 季度累計統計 (主要運算範圍 - 103年起)
define "Quarterly Cumulative Statistics":
    quarterly_cumulative_statistics

-- 年度統計
define "Annual Statistics":
    annual_statistics

-- 分母病患清單 (上年度符合條件的糖尿病病患)
define "Denominator Patient List":
    SELECT 
        d.patient_id,
        d.earliest_diabetes_visit,
        d.latest_diabetes_visit,
        d.total_facilities,
        d.total_qualifying_encounters,
        p.name,
        p.birth_date,
        p.gender,
        YEAR(current_year_period.end_date) - YEAR(p.birth_date) as current_age,
        CASE 
            WHEN d.patient_id IN (SELECT patient_id FROM numerator_enrolled_patients)
            THEN 'ENROLLED'
            ELSE 'NOT_ENROLLED'
        END as enrollment_status
    FROM 
        denominator_unique_patients d
    LEFT JOIN 
        patient_demographics p ON d.patient_id = p.patient_id
    ORDER BY 
        d.patient_id

-- 分子病患清單 (已加入照護方案)
define "Numerator Patient List":
    SELECT 
        n.patient_id,
        n.first_enrollment_date,
        n.last_enrollment_date,
        n.enrolled_program_count,
        n.enrolled_programs,
        n.total_enrollment_count,
        d.earliest_diabetes_visit as diabetes_diagnosis_date,
        DATEDIFF(day, d.earliest_diabetes_visit, n.first_enrollment_date) as days_to_enrollment,
        p.name,
        p.birth_date,
        p.gender,
        YEAR(current_year_period.end_date) - YEAR(p.birth_date) as current_age,
        CASE 
            WHEN d.patient_id IS NOT NULL THEN 'IN_DENOMINATOR'
            ELSE 'NOT_IN_DENOMINATOR'
        END as denominator_status
    FROM 
        numerator_all_enrolled_patients n
    LEFT JOIN 
        denominator_unique_patients d ON n.patient_id = d.patient_id
    LEFT JOIN 
        patient_demographics p ON n.patient_id = p.patient_id
    ORDER BY 
        n.patient_id

-- 詳細收案記錄
define "Detailed Enrollment Records":
    SELECT 
        e.patient_id,
        e.enrollment_date,
        e.program_type,
        e.care_plan_code,
        e.care_plan_name,
        e.encounter_type,
        e.facility_id,
        e.facility_name,
        d.earliest_diabetes_visit as patient_diabetes_date,
        p.name as patient_name,
        p.birth_date,
        p.gender,
        YEAR(e.enrollment_date) - YEAR(p.birth_date) as age_at_enrollment,
        CASE 
            WHEN d.patient_id IS NOT NULL THEN 'YES'
            ELSE 'NO'
        END as in_denominator
    FROM 
        all_care_plan_enrollments e
    LEFT JOIN 
        denominator_unique_patients d ON e.patient_id = d.patient_id
    LEFT JOIN 
        patient_demographics p ON e.patient_id = p.patient_id
    ORDER BY 
        e.patient_id, e.enrollment_date

-- ==================== 資料品質檢核 ====================

-- 檢核1: 分母資格檢查 (兩次就醫間隔檢查)
define "Quality Check Denominator Visit Intervals":
    SELECT 
        e1.patient_id,
        e1.facility_id,
        e1.encounter_id as encounter_1,
        e2.encounter_id as encounter_2,
        e1.visit_date as visit_date_1,
        e2.visit_date as visit_date_2,
        ABS(DATEDIFF(day, e1.visit_date, e2.visit_date)) as days_between,
        CASE 
            WHEN ABS(DATEDIFF(day, e1.visit_date, e2.visit_date)) BETWEEN 0 AND 90 THEN 'QUALIFIED'
            ELSE 'NOT_QUALIFIED'
        END as qualification_status
    FROM 
        previous_year_diabetes_encounters e1
    INNER JOIN
        previous_year_diabetes_encounters e2
        ON e1.patient_id = e2.patient_id
        AND e1.facility_id = e2.facility_id
        AND e1.birth_date = e2.birth_date
        AND e1.encounter_id != e2.encounter_id
    WHERE 
        e1.patient_id IN (SELECT patient_id FROM denominator_unique_patients)
    ORDER BY 
        e1.patient_id, e1.visit_date

-- 檢核2: 收案方案分布
define "Quality Check Enrollment Program Distribution":
    SELECT 
        program_type,
        encounter_type,
        COUNT(DISTINCT patient_id) as patient_count,
        COUNT(*) as total_enrollment_count,
        MIN(enrollment_date) as earliest_enrollment,
        MAX(enrollment_date) as latest_enrollment
    FROM 
        all_care_plan_enrollments
    GROUP BY 
        program_type, encounter_type
    ORDER BY 
        patient_count DESC

-- 檢核3: 分母排除案件統計
define "Quality Check Excluded Cases":
    SELECT 
        CASE 
            WHEN e.case_type = '08' THEN 'CASE_TYPE_08'
            WHEN e.reload_reason = '2' THEN 'RELOAD_REASON_2'
            WHEN e.dispensing_method = '3' THEN 'DISPENSING_METHOD_3'
            WHEN e.dispensing_method = '5' THEN 'DISPENSING_METHOD_5'
            ELSE 'OTHER'
        END as exclusion_reason,
        COUNT(DISTINCT e.patient_id) as excluded_patient_count,
        COUNT(DISTINCT e.encounter_id) as excluded_encounter_count
    FROM 
        outpatient_and_inpatient_encounters e
    WHERE 
        -- 門診案件
        e.encounter_type IN ('O', 'AMB')
        
        -- 主診斷為糖尿病
        AND SUBSTRING(e.primary_diagnosis, 1, 3) IN ('E08', 'E09', 'E10', 'E11', 'E13')
        
        -- 上年度
        AND e.visit_date BETWEEN previous_year_period.start_date AND previous_year_period.end_date
        
        -- 符合任一排除條件
        AND (
            e.case_type = '08'
            OR e.reload_reason = '2'
            OR e.dispensing_method IN ('3', '5')
        )
    GROUP BY 
        CASE 
            WHEN e.case_type = '08' THEN 'CASE_TYPE_08'
            WHEN e.reload_reason = '2' THEN 'RELOAD_REASON_2'
            WHEN e.dispensing_method = '3' THEN 'DISPENSING_METHOD_3'
            WHEN e.dispensing_method = '5' THEN 'DISPENSING_METHOD_5'
            ELSE 'OTHER'
        END

-- 檢核4: 分子分母一致性檢查
define "Quality Check Numerator Denominator Consistency":
    SELECT 
        'Total Enrolled' as category,
        (SELECT COUNT(*) FROM numerator_all_enrolled_patients) as count_value
    UNION ALL
    SELECT 
        'Enrolled in Denominator' as category,
        (SELECT COUNT(*) FROM numerator_enrolled_patients) as count_value
    UNION ALL
    SELECT 
        'Enrolled NOT in Denominator' as category,
        (SELECT COUNT(*) FROM numerator_all_enrolled_patients) - 
        (SELECT COUNT(*) FROM numerator_enrolled_patients) as count_value
    UNION ALL
    SELECT 
        'Denominator Total' as category,
        (SELECT COUNT(*) FROM denominator_unique_patients) as count_value
    UNION ALL
    SELECT 
        'Adjustment Applied' as category,
        CASE 
            WHEN (SELECT COUNT(*) FROM numerator_all_enrolled_patients) >
                 (SELECT COUNT(*) FROM denominator_unique_patients)
            THEN 1
            ELSE 0
        END as count_value

-- 檢核5: 醫療機構分布
define "Quality Check Facility Distribution":
    SELECT 
        facility_id,
        facility_name,
        COUNT(DISTINCT patient_id) as denominator_patients,
        (
            SELECT COUNT(DISTINCT patient_id)
            FROM all_care_plan_enrollments e
            WHERE e.facility_id = dq.facility_id
        ) as enrolled_patients,
        ROUND(
            (SELECT COUNT(DISTINCT patient_id) FROM all_care_plan_enrollments e 
             WHERE e.facility_id = dq.facility_id) * 100.0 /
            NULLIF(COUNT(DISTINCT dq.patient_id), 0)
        , 2) as facility_enrollment_rate
    FROM 
        denominator_qualified_patients dq
    GROUP BY 
        facility_id, facility_name
    ORDER BY 
        denominator_patients DESC

-- ==================== 統計報告 ====================

define "Summary Report":
    {
        report_title: '糖尿病病人加入照護方案比率',
        report_date: Today(),
        measurement_period: current_year_period.label,
        denominator_period: previous_year_period.label,
        computation_frequency: '季累計 (103年起)',
        
        methodology_notes: {
            note_101_year_change: '101年修訂：A.若分子>分母時，分母=分子；B.分母改採用上年度全年資料',
            note_102_year_change: '102年修訂：分母刪除收案條件需「同醫師」之規定',
            note_103_year_change: '103年起：運算範圍改為季累計，之前為每半年',
            note_112_year_addition: '112年1月起：新增P70糖尿病合併初期慢性腎臟病照護整合方案'
        },
        
        overall_statistics: {
            denominator_base_year: previous_year,
            denominator_count: annual_statistics.denominator_original,
            numerator_count: annual_statistics.numerator_total,
            denominator_adjusted: annual_statistics.denominator_adjusted,
            numerator_adjusted: annual_statistics.numerator_adjusted,
            enrollment_rate: annual_statistics.enrollment_rate,
            adjustment_applied: (
                annual_statistics.numerator_total > annual_statistics.denominator_original
            ),
            
            by_program_type: {
                p14_diabetes: {
                    patient_count: annual_statistics.statistics_detail.p14_total_enrollments,
                    description: '糖尿病醫療給付改善方案',
                    effective_since: '100年 (2011)'
                },
                p70_diabetes_ckd: {
                    patient_count: annual_statistics.statistics_detail.p70_total_enrollments,
                    description: '糖尿病合併初期慢性腎臟病照護整合方案',
                    effective_since: '112年1月 (2023)'
                },
                both_programs: {
                    patient_count: annual_statistics.statistics_detail.both_programs_enrolled,
                    description: '同時加入兩項方案'
                }
            },
            
            by_encounter_type: {
                outpatient: annual_statistics.statistics_detail.outpatient_only_enrollments,
                inpatient: annual_statistics.statistics_detail.inpatient_enrolled
            }
        },
        
        quarterly_breakdown: quarterly_cumulative_statistics,
        
        data_quality: {
            denominator_facilities: annual_statistics.statistics_detail.denominator_facilities,
            denominator_encounters: annual_statistics.statistics_detail.denominator_total_encounters,
            avg_enrollments_per_patient: annual_statistics.statistics_detail.avg_enrollments_per_patient,
            data_completeness: 'See Quality Check reports'
        },
        
        denominator_criteria: {
            criterion1: '上年度全年資料中門診主診斷為糖尿病(E08-E13)',
            criterion2: '同院、同ID、同生日',
            criterion3: '任2次就醫日期間隔介於0到90天',
            exclusions: '排除08案件、補載原因註記2、醫令調劑方式3或5'
        },
        
        numerator_criteria: {
            criterion1: '當年度收案進入照護方案',
            criterion2: 'P14方案：門診或住院皆可',
            criterion3: 'P70方案：僅限門診 (112年1月起)',
            criterion4: '醫令代碼前3碼為P14或P70'
        },
        
        notes: {
            note1: '分母使用上年度全年資料(固定)，分子使用當年度收案資料',
            note2: '101年起：若分子>分母，則調整分母=分子',
            note3: '103年起：改為季累計統計',
            note4: '112年1月起：新增P70糖尿病合併初期CKD照護整合方案',
            note5: '資料範圍：門診(西醫基層+西醫醫院)+住院(西醫基層+西醫醫院)',
            note6: '照護方案有助於提升糖尿病病患自我管理能力並減少併發症'
        }
    }
