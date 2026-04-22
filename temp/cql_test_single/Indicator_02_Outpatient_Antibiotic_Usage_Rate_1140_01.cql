library Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1140.01
// 條件依據：門診抗生素使用率
// 製作日期：2025-11-20
//
// 【歷史參考基準】111年第1季 (2022Q1)
// 抗生素給藥案件數: 1,156,837
// 給藥案件數: 5,831,409
// 門診抗生素使用率: 19.84%

// 【公式說明】
// 分子: 給藥案件之抗生素藥品案件數（ATC碼前3碼為'J01'）
// 分母: 給藥案件數（藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6）
// 排除: 急診案件(02)、門診手術(03)、事前審查藥品、STAT藥品、代辦案件

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'
code "Emergency": 'EMER' from "ActCode" display 'Emergency - 急診'

// ATC 抗生素代碼
code "ATC_J01": 'J01' from "ATC" display 'ANTIBACTERIALS FOR SYSTEMIC USE'

// Helper function: 檢查 ATC 代碼是否為抗生素
define function IsAntibioticDrug(atcCode String):
  Substring(atcCode, 0, 3) = 'J01'

// 1. 門診給藥案件（分母）
define "Outpatient Drug Encounters":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'AMB'
    and exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and (
          // 藥費不為0、或給藥天數不為0、或處方調劑方式符合條件
          exists (MR.dosageInstruction DI where DI.timing.repeat.boundsPeriod.start.value is not null)
        )
    )
    // 排除代辦案件
    and not exists (
      E.type T where exists (T.coding C where C.code.value = 'AGENCY')
    )

// 2. 門診抗生素案件（分子）
define "Outpatient Antibiotic Cases":
  "Outpatient Drug Encounters" E
    where exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        // 條件：ATC碼前3碼為'J01'（抗生素）
        and exists (
          MR.medicationCodeableConcept.coding MC
            where MC.system.value = 'http://www.whocc.no/atc'
            and IsAntibioticDrug(MC.code.value)
        )
        // 排除急診案件
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '02')
        )
        // 排除門診手術案件
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '03')
        )
        // 排除事前審查藥品
        and (MR.extension is null or not exists (
          MR.extension Ext 
            where Ext.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/prior-approval'
            and Ext.valueBoolean.value = true
        ))
        // 排除 STAT 用藥
        and not exists (
          MR.dosageInstruction DI
            where DI.asNeededBoolean.value = true
            or exists (DI.additionalInstruction AI 
              where exists (AI.coding C where C.code.value = 'STAT'))
        )
    )

// 3. 分母：門診給藥案件數
define "Denominator":
  Count(
    distinct "Outpatient Drug Encounters" E
      return E.id.value
  )

// 4. 分子：門診抗生素案件數
define "Numerator":
  Count(
    distinct "Outpatient Antibiotic Cases" E
      return E.id.value
  )

// 5. 指標計算結果：門診抗生素使用率
define "Antibiotic Usage Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null

    SELECT '2024Q1' as quarter, '2024-01-01' as start_date, '2024-03-31' as end_date
    UNION ALL SELECT '2024Q2', '2024-04-01', '2024-06-30'
    UNION ALL SELECT '2024Q3', '2024-07-01', '2024-09-30'
    UNION ALL SELECT '2024Q4', '2024-10-01', '2024-12-31'
    UNION ALL SELECT '2025Q1', '2025-01-01', '2025-03-31'
    UNION ALL SELECT '2025Q2', '2025-04-01', '2025-06-30'
    UNION ALL SELECT '2025Q3', '2025-07-01', '2025-09-30'
    UNION ALL SELECT '2025Q4', '2025-10-01', '2025-11-06'  -- 計算到今天 2025-11-06
),

-- 健保代碼與標準代碼系統對照表
-- 依據健保指標代碼 1140.01 (門診抗生素使用率) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1140.01', '1140.01', 'NHI', 'Outpatient Antibiotic Usage Rate - 門診抗生素使用率'),
        
        -- ATC碼對照 (依健保規範：ATC碼前3碼為J01)
        ('ATC', 'J01', 'J01', 'ATC', 'ANTIBACTERIALS FOR SYSTEMIC USE - 全身性抗細菌劑'),
        
        -- 健保處方調劑方式代碼
        ('DISPENSING', '1', '1', 'NHI', '門診給藥 - 處方調劑方式1'),
        ('DISPENSING', '0', '0', 'NHI', '門診給藥 - 處方調劑方式0'),
        ('DISPENSING', '6', '6', 'NHI', '門診給藥 - 處方調劑方式6'),
        
        -- 健保案件分類代碼
        ('CASE_CATEGORY', '02', '02', 'NHI', 'Emergency - 急診案件分類(應排除)'),
        ('CASE_CATEGORY', '03', '03', 'NHI', 'Outpatient Surgery - 門診手術(應排除)'),
        
        -- 就醫類型代碼
        ('ENCOUNTER', 'O', 'O', 'NHI', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'NHI', 'Ambulatory - 門診'),
        
        -- 藥品使用頻率代碼
        ('FREQUENCY', 'STAT', 'STAT', 'NHI', 'Immediately - 立即使用(應排除)'),
        ('FREQUENCY', 'QD', 'QD', 'NHI', 'Once daily - 每日一次'),
        ('FREQUENCY', 'BID', 'BID', 'NHI', 'Twice daily - 每日兩次'),
        ('FREQUENCY', 'TID', 'TID', 'NHI', 'Three times daily - 每日三次'),
        ('FREQUENCY', 'QID', 'QID', 'NHI', 'Four times daily - 每日四次'),
        
        -- 事前審查註記
        ('APPROVAL', 'Y', 'Y', 'NHI', 'Prior Approval Required - 需事前審查(應排除)'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 分子: 計算各醫療機構門診使用抗生素的件數
-- 抗生素定義(依健保規範 1140.01): 
--   藥品成分ATC碼前3碼為'J01' (ANTIBACTERIALS FOR SYSTEMIC USE - 全身性抗細菌劑)
numerator_data AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        o.claim_id,
        o.visit_date,
        o.encounter_type,
        d.drug_code,
        d.drug_name,
        d.dosage_form,
        d.nhi_code,
        d.atc_code,
        d.route,
        d.frequency,
        ncm.standard_code as nhi_standard_code,
        ncm.description as standard_description
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診
    INNER JOIN drug_details d 
        ON o.claim_id = d.claim_id
    LEFT JOIN nhi_code_mapping ncm 
        ON SUBSTRING(d.atc_code, 1, 3) = ncm.nhi_code 
        AND ncm.code_type = 'ATC'
    WHERE 
        -- 條件1: 給藥案件(藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6)
        (d.drug_cost > 0 OR d.supply_days > 0 OR d.dispensing_method IN ('1', '0', '6'))
        
        -- 條件2: ATC碼前3碼為'J01' (依健保規範：ANTIBACTERIALS FOR SYSTEMIC USE)
        AND SUBSTRING(d.atc_code, 1, 3) = 'J01'
        
        -- 排除急診案件(案件分類代碼為02)
        AND o.case_category <> '02'
        
        -- 排除急診類型
        AND NOT (
            d.drug_category IN ('急診抗生素')
            OR o.encounter_type = 'EMER'  -- 急診
        )
        
        -- 排除門診手術案件(案件分類類碼03)
        AND o.case_category <> '03'
        
        -- 排除事前審查藥品(藥品主檔之事前審查註記為Y)
        AND (d.prior_approval_flag IS NULL OR d.prior_approval_flag <> 'Y')
        
        -- 排除立刻使用之藥品(藥品使用頻率為STAT)
        AND (d.frequency IS NULL OR d.frequency <> 'STAT')
        
        -- 排除代辦案件
        AND (o.agency_case_flag IS NULL OR o.agency_case_flag <> 'Y')
),

-- 計算分子: 門診使用抗生素件數
numerator AS (
    SELECT 
        quarter,
        hospital_id,
        COUNT(DISTINCT claim_id) as antibiotic_claim_count
    FROM numerator_data
    GROUP BY quarter, hospital_id
),

-- 分母: 門診給藥案件總數
-- 給藥案件定義: 藥費不為0、或給藥天數不為0、或處方調劑方式為1/0/6
denominator AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        COUNT(DISTINCT o.claim_id) as total_claim_count
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診類型
    INNER JOIN drug_details d
        ON o.claim_id = d.claim_id
    WHERE 
        -- 給藥案件條件
        (d.drug_cost > 0 OR d.supply_days > 0 OR d.dispensing_method IN ('1', '0', '6'))
        
        -- 排除代辦案件
        AND (o.agency_case_flag IS NULL OR o.agency_case_flag <> 'Y')
    GROUP BY q.quarter, o.hospital_id
),

-- 計算使用率
calculation AS (
    SELECT 
        d.quarter,
        d.hospital_id,
        h.hospital_name,
        h.hospital_level,
        h.region,
        COALESCE(n.antibiotic_claim_count, 0) as antibiotic_claim_count,
        d.total_claim_count,
        CASE 
            WHEN d.total_claim_count > 0 
            THEN ROUND((COALESCE(n.antibiotic_claim_count, 0) * 100.0 / d.total_claim_count), 2)
            ELSE 0 
        END as antibiotic_usage_rate
    FROM denominator d
    LEFT JOIN numerator n 
        ON d.quarter = n.quarter 
        AND d.hospital_id = n.hospital_id
    LEFT JOIN hospital_master h 
        ON d.hospital_id = h.hospital_id
),

-- 統計摘要 (依季度)
summary_by_quarter AS (
    SELECT 
        quarter,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(antibiotic_claim_count) as total_antibiotic_claims,
        SUM(total_claim_count) as total_claims,
        ROUND(AVG(antibiotic_usage_rate), 2) as avg_usage_rate,
        MIN(antibiotic_usage_rate) as min_usage_rate,
        MAX(antibiotic_usage_rate) as max_usage_rate,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY antibiotic_usage_rate) as q25_usage_rate,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY antibiotic_usage_rate) as median_usage_rate,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY antibiotic_usage_rate) as q75_usage_rate
    FROM calculation
    GROUP BY quarter
),

-- 統計摘要 (依醫院層級)
summary_by_level AS (
    SELECT 
        quarter,
        hospital_level,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(antibiotic_claim_count) as total_antibiotic_claims,
        SUM(total_claim_count) as total_claims,
        ROUND(AVG(antibiotic_usage_rate), 2) as avg_usage_rate,
        MIN(antibiotic_usage_rate) as min_usage_rate,
        MAX(antibiotic_usage_rate) as max_usage_rate
    FROM calculation
    GROUP BY quarter, hospital_level
),

-- 統計摘要 (依區域)
summary_by_region AS (
    SELECT 
        quarter,
        region,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(antibiotic_claim_count) as total_antibiotic_claims,
        SUM(total_claim_count) as total_claims,
        ROUND(AVG(antibiotic_usage_rate), 2) as avg_usage_rate,
        MIN(antibiotic_usage_rate) as min_usage_rate,
        MAX(antibiotic_usage_rate) as max_usage_rate
    FROM calculation
    GROUP BY quarter, region
),

-- 抗生素用藥明細分析 (依ATC碼分類)
antibiotic_detail_by_atc AS (
    SELECT 
        n.quarter,
        SUBSTRING(n.atc_code, 1, 3) as atc_class,
        CASE 
            WHEN SUBSTRING(n.atc_code, 1, 3) = 'J01' THEN 'Antibacterials - 抗細菌劑'
            WHEN SUBSTRING(n.atc_code, 1, 3) = 'J02' THEN 'Antimycotics - 抗黴菌劑'
            WHEN SUBSTRING(n.atc_code, 1, 3) = 'J04' THEN 'Antimycobacterials - 抗結核菌劑'
            WHEN SUBSTRING(n.atc_code, 1, 3) = 'J05' THEN 'Antivirals - 抗病毒劑'
            ELSE 'Other - 其他抗感染劑'
        END as atc_class_name,
        COUNT(DISTINCT n.claim_id) as claim_count,
        COUNT(DISTINCT n.hospital_id) as hospital_count
    FROM numerator_data n
    GROUP BY n.quarter, SUBSTRING(n.atc_code, 1, 3)
),

-- 抗生素用藥明細分析 (依給藥途徑)
antibiotic_detail_by_route AS (
    SELECT 
        n.quarter,
        n.route,
        CASE 
            WHEN n.route = 'PO' THEN 'Oral - 口服'
            WHEN n.route = 'IV' THEN 'Intravenous - 靜脈注射'
            WHEN n.route = 'IM' THEN 'Intramuscular - 肌肉注射'
            WHEN n.route = 'SC' THEN 'Subcutaneous - 皮下注射'
            WHEN n.route = 'TOP' THEN 'Topical - 外用'
            ELSE 'Other - 其他途徑'
        END as route_name,
        COUNT(DISTINCT n.claim_id) as claim_count,
        COUNT(DISTINCT n.hospital_id) as hospital_count
    FROM numerator_data n
    GROUP BY n.quarter, n.route
),

-- 趨勢分析 (各季度變化)
trend_analysis AS (
    SELECT 
        c1.quarter as current_quarter,
        c1.hospital_id,
        c1.hospital_name,
        c1.antibiotic_usage_rate as current_rate,
        c2.quarter as previous_quarter,
        c2.antibiotic_usage_rate as previous_rate,
        CASE 
            WHEN c2.antibiotic_usage_rate IS NOT NULL 
            THEN ROUND((c1.antibiotic_usage_rate - c2.antibiotic_usage_rate), 2)
            ELSE NULL 
        END as rate_change,
        CASE 
            WHEN c2.antibiotic_usage_rate IS NOT NULL AND c2.antibiotic_usage_rate > 0
            THEN ROUND(((c1.antibiotic_usage_rate - c2.antibiotic_usage_rate) * 100.0 / c2.antibiotic_usage_rate), 2)
            ELSE NULL 
        END as rate_change_percent
    FROM calculation c1
    LEFT JOIN calculation c2 
        ON c1.hospital_id = c2.hospital_id
        AND c1.quarter = CASE c2.quarter
            WHEN '2024Q1' THEN '2024Q2'
            WHEN '2024Q2' THEN '2024Q3'
            WHEN '2024Q3' THEN '2024Q4'
            WHEN '2024Q4' THEN '2025Q1'
            WHEN '2025Q1' THEN '2025Q2'
            WHEN '2025Q2' THEN '2025Q3'
            WHEN '2025Q3' THEN '2025Q4'
        END
)

-- ============================================
-- 最終輸出結果
-- ============================================

-- 輸出1: 各醫療機構門診抗生素使用率
SELECT 
    quarter as '季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    hospital_level as '醫院層級',
    region as '區域',
    antibiotic_claim_count as '抗生素給藥案件數',
    total_claim_count as '給藥案件數',
    antibiotic_usage_rate as '門診抗生素使用率(%)'
FROM calculation
ORDER BY quarter, antibiotic_usage_rate DESC;

-- 輸出2: 各季度統計摘要
SELECT 
    quarter as '季度',
    hospital_count as '醫療機構數',
    total_antibiotic_claims as '抗生素給藥案件總數',
    total_claims as '給藥案件總數',
    avg_usage_rate as '平均使用率(%)',
    min_usage_rate as '最低使用率(%)',
    q25_usage_rate as '第1四分位數(%)',
    median_usage_rate as '中位數(%)',
    q75_usage_rate as '第3四分位數(%)',
    max_usage_rate as '最高使用率(%)'
FROM summary_by_quarter
ORDER BY quarter;

-- 輸出3: 依醫院層級統計
SELECT 
    quarter as '季度',
    hospital_level as '醫院層級',
    hospital_count as '醫療機構數',
    total_antibiotic_claims as '抗生素給藥案件數',
    total_claims as '給藥案件數',
    avg_usage_rate as '平均使用率(%)',
    min_usage_rate as '最低使用率(%)',
    max_usage_rate as '最高使用率(%)'
FROM summary_by_level
ORDER BY quarter, hospital_level;

-- 輸出4: 依區域統計
SELECT 
    quarter as '季度',
    region as '區域',
    hospital_count as '醫療機構數',
    total_antibiotic_claims as '抗生素給藥案件數',
    total_claims as '給藥案件數',
    avg_usage_rate as '平均使用率(%)',
    min_usage_rate as '最低使用率(%)',
    max_usage_rate as '最高使用率(%)'
FROM summary_by_region
ORDER BY quarter, region;

-- 輸出5: 依ATC碼分類統計
SELECT 
    quarter as '季度',
    atc_class as 'ATC分類代碼',
    atc_class_name as 'ATC分類名稱',
    claim_count as '案件數',
    hospital_count as '使用醫療機構數'
FROM antibiotic_detail_by_atc
ORDER BY quarter, claim_count DESC;

-- 輸出6: 依給藥途徑統計
SELECT 
    quarter as '季度',
    route as '給藥途徑代碼',
    route_name as '給藥途徑名稱',
    claim_count as '案件數',
    hospital_count as '使用醫療機構數'
FROM antibiotic_detail_by_route
ORDER BY quarter, claim_count DESC;

-- 輸出7: 趨勢分析
SELECT 
    current_quarter as '當前季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    current_rate as '當前使用率(%)',
    previous_quarter as '前一季度',
    previous_rate as '前一季使用率(%)',
    rate_change as '使用率變化(百分點)',
    rate_change_percent as '使用率變化率(%)'
FROM trend_analysis
WHERE previous_quarter IS NOT NULL
ORDER BY current_quarter, rate_change DESC;

-- ============================================
-- FHIR資源查詢說明
-- ============================================
-- 
-- 1. MedicationRequest (藥品處方)
--    GET {FHIR_SERVER}/MedicationRequest?
--        date=ge2024-01-01&
--        category=outpatient&
--        status=completed&
--        medication.code:text=antibiotic&
--        _include=MedicationRequest:medication
-- 
-- 2. Encounter (就診記錄)
--    GET {FHIR_SERVER}/Encounter?
--        date=ge2024-01-01&
--        class=AMB&
--        status=finished&
--        _include=Encounter:patient
-- 
-- 3. Medication (藥品資訊)
--    GET {FHIR_SERVER}/Medication?
--        code:text=antibiotic&
--        _filter=code.coding.system eq 'http://www.whocc.no/atc' and 
--                code.coding.code sw 'J' and
--                code.coding.code ne 'J07' and
--                code.coding.code ne 'J06BA'
-- 
-- 4. Patient (病人資訊)
--    GET {FHIR_SERVER}/Patient?
--        _id={patient_id}
-- 
-- 5. Organization (醫療機構)
--    GET {FHIR_SERVER}/Organization?
--        type=prov&
--        _id={organization_id}
-- 
-- ============================================
-- 查詢結束
-- ============================================
