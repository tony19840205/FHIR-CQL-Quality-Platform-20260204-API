library Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案分析系統 指標代碼: 1712
// 條件依據：同醫院門診同藥理用藥日數重疊率-降血糖(不分口服及注射)
// 製作日期：2025-11-20

// 【公式說明】
// 分子: 同院ID不同處方之間給用藥日期與結束用藥日期有重覆之給藥日數
// 分母: 各案件之「給藥日數」總和
// 降血糖藥(不分口服及注射): ATC前5碼=A10AB、A10AC、A10AD、A10AE、A10BA、A10BB、A10BF、A10BG、A10BX、A10BH、A10BJ、A10BK

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'

// Helper function: 檢查是否為降血糖藥(不分口服及注射)
define function IsAntidiabeticDrug(atcCode String):
  // ATC前5碼為指定代碼（包含口服及注射）
  Substring(atcCode, 0, 5) in {
    'A10AB', 'A10AC', 'A10AD', 'A10AE', 
    'A10BA', 'A10BB', 'A10BF', 'A10BG', 'A10BX',
    'A10BH', 'A10BJ', 'A10BK'
  }

// Helper function: 計算兩個日期區間的重疊天數
define function CalculateOverlapDays(start1 Date, end1 Date, start2 Date, end2 Date):
  if start1 is null or end1 is null or start2 is null or end2 is null then
    0
  else
    let overlapStart: if start1 > start2 then start1 else start2,
        overlapEnd: if end1 < end2 then end1 else end2,
        overlapDays: days between overlapStart and overlapEnd + 1
    in
      if overlapStart <= overlapEnd then overlapDays else 0

// 1. 同醫院門診降血糖藥品處方
define "Antidiabetic Prescriptions":
  [MedicationRequest] MR
    where MR.status.value = 'completed'
    and exists (
      MR.medicationCodeableConcept.coding MC
        where MC.system.value = 'http://www.whocc.no/atc'
        and exists (
          MR.contained C
            where C is FHIR.Medication
            and IsAntidiabeticDrug(MC.code.value)
        )
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(MR.encounter.reference.value, '/'))
        and E.class.code.value = 'AMB'
        and E.status.value = 'finished'
        // 排除代辦案件
        and not exists (E.type T where exists (T.coding C where C.code.value = 'AGENCY'))
    )

// 2. 計算同院同病人的藥品重疊日數
define "Drug Overlap Days":
  flatten (
    "Antidiabetic Prescriptions" P1
      let 
        patientRef: P1.subject.reference.value,
        organizationRef: P1.requester.reference.value,
        start1: P1.dispenseRequest.validityPeriod.start.value,
        end1: P1.dispenseRequest.validityPeriod.end.value
      return
        "Antidiabetic Prescriptions" P2
          where P2.subject.reference.value = patientRef
          and P2.requester.reference.value = organizationRef
          and P2.id.value != P1.id.value
          let
            start2: P2.dispenseRequest.validityPeriod.start.value,
            end2: P2.dispenseRequest.validityPeriod.end.value,
            overlap: CalculateOverlapDays(start1, end1, start2, end2)
          where overlap > 0
          return {
            prescription1: P1.id.value,
            prescription2: P2.id.value,
            overlapDays: overlap
          }
  )

// 3. 分母：降血糖藥品總給藥日數
define "Total Drug Days":
  Sum(
    "Antidiabetic Prescriptions" P
      return days between P.dispenseRequest.validityPeriod.start.value 
                     and P.dispenseRequest.validityPeriod.end.value + 1
  )

// 4. 分子：重疊給藥日數
define "Overlap Drug Days":
  Sum("Drug Overlap Days" D return D.overlapDays) / 2  // 除以2避免重複計算

// 5. 指標計算結果：用藥日數重疊率
define "Drug Overlap Rate":
  if "Total Drug Days" > 0 then
    ("Overlap Drug Days" / "Total Drug Days") * 100
  else
    null
    UNION ALL SELECT '2024Q4', '2024-10-01', '2024-12-31'
    UNION ALL SELECT '2025Q1', '2025-01-01', '2025-03-31'
    UNION ALL SELECT '2025Q2', '2025-04-01', '2025-06-30'
    UNION ALL SELECT '2025Q3', '2025-07-01', '2025-09-30'
    UNION ALL SELECT '2025Q4', '2025-10-01', CURRENT_DATE()  -- 計算到當前日期
),

-- 健保代碼與標準代碼系統對照表
-- 依據健保指標代碼 1712 (同醫院門診同藥理用藥日數重疊率-降血糖) 規範
nhi_code_mapping AS (
    SELECT code_type, nhi_code, standard_code, code_system, description FROM (
        VALUES
        -- 健保指標代碼
        ('INDICATOR', '1712', '1712', 'NHI', 'Antidiabetic Drug Overlap Rate - 同醫院門診同藥理用藥日數重疊率-降血糖'),
        
        -- ATC碼對照 (降血糖藥品)
        -- A10: Drugs used in diabetes (降血糖藥物)
        ('ATC', 'A10', 'A10', 'http://www.whocc.no/atc', 'Drugs used in diabetes - 降血糖藥物'),
        ('ATC', 'A10A', 'A10A', 'http://www.whocc.no/atc', 'Insulins and analogues - 胰島素及類似藥物'),
        ('ATC', 'A10B', 'A10B', 'http://www.whocc.no/atc', 'Blood glucose lowering drugs, excl. insulins - 降血糖藥(不含胰島素)'),
        ('ATC', 'A10BA', 'A10BA', 'http://www.whocc.no/atc', 'Biguanides - 雙胍類'),
        ('ATC', 'A10BB', 'A10BB', 'http://www.whocc.no/atc', 'Sulfonamides (sulfonylurea derivatives) - 磺醯尿素類'),
        ('ATC', 'A10BG', 'A10BG', 'http://www.whocc.no/atc', 'Thiazolidinediones - 噻唑烷二酮類'),
        ('ATC', 'A10BH', 'A10BH', 'http://www.whocc.no/atc', 'DPP-4 inhibitors - DPP-4抑制劑'),
        ('ATC', 'A10BJ', 'A10BJ', 'http://www.whocc.no/atc', 'GLP-1 analogues - GLP-1類似物'),
        ('ATC', 'A10BK', 'A10BK', 'http://www.whocc.no/atc', 'SGLT2 inhibitors - SGLT2抑制劑'),
        ('ATC', 'A10BX', 'A10BX', 'http://www.whocc.no/atc', 'Other blood glucose lowering drugs - 其他降血糖藥'),
        
        -- 劑型代碼 (SNOMED CT)
        ('DOSAGE_FORM', '1', '385219001', 'http://snomed.info/sct', 'Injection - 注射劑(應排除)'),
        ('DOSAGE_FORM', '2', '385268001', 'http://snomed.info/sct', 'Oral - 口服(應排除)'),
        ('DOSAGE_FORM', '3', '385194003', 'http://snomed.info/sct', 'Topical - 外用'),
        ('DOSAGE_FORM', '4', '385229008', 'http://snomed.info/sct', 'Other routes - 其他途徑'),
        
        -- 就醫類型代碼
        ('ENCOUNTER', 'O', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Outpatient - 門診'),
        ('ENCOUNTER', 'AMB', 'AMB', 'http://terminology.hl7.org/CodeSystem/v3-ActCode', 'Ambulatory - 門診'),
        
        -- 代辦案件註記
        ('AGENCY', 'Y', 'Y', 'NHI', 'Agency Case - 代辦案件(應排除)')
    ) AS t(code_type, nhi_code, standard_code, code_system, description)
),

-- 篩選降血糖藥品(口服及注射)
-- 條件: ATC代碼以 A10 開頭，包含口服及注射劑型
antidiabetic_drugs AS (
    SELECT 
        q.quarter,
        o.hospital_id,
        o.patient_id,
        o.claim_id,
        o.visit_date,
        d.drug_code,
        d.drug_name,
        d.atc_code,
        d.order_code,
        -- 給藥日數: 優先取 ORDER_DRUG_DAY，若為空則取 DRUG_DAYS
        COALESCE(d.order_drug_day, d.drug_days, 0) as drug_days,
        -- 給藥開始日期: 處方開始日期
        d.prescription_date as start_date,
        -- 給藥結束日期: 處方開始日期 + 給藥日數 - 1
        DATE_ADD(d.prescription_date, INTERVAL (COALESCE(d.order_drug_day, d.drug_days, 0) - 1) DAY) as end_date,
        ncm.standard_code as atc_standard_code,
        ncm.description as atc_description,
        SUBSTRING(d.order_code, 8, 1) as dosage_form_code
    FROM quarters q
    INNER JOIN outpatient_claims o 
        ON o.visit_date BETWEEN q.start_date AND q.end_date
        AND o.encounter_type IN ('O', 'AMB')  -- 門診
    INNER JOIN drug_details d 
        ON o.claim_id = d.claim_id
    LEFT JOIN nhi_code_mapping ncm 
        ON SUBSTRING(d.atc_code, 1, 3) = SUBSTRING(ncm.nhi_code, 1, 3)
        AND ncm.code_type = 'ATC'
    WHERE 
        -- 條件1: 降血糖藥品 ATC 代碼 (以A10開頭)
        SUBSTRING(d.atc_code, 1, 3) = 'A10'
        
        -- 條件2: 包含口服及注射劑 (無需排除任何劑型)
        -- 醫令代碼第8碼為1(注射)或2(口服)都包含
        
        -- 條件3: 給藥日數 > 0
        AND COALESCE(d.order_drug_day, d.drug_days, 0) > 0
        
        -- 排除代辦案件
        AND (o.agency_case_flag IS NULL OR o.agency_case_flag <> 'Y')
),

-- 計算同院同病人不同處方之間的用藥日期重疊
-- 使用自我連接找出同院、同病人、不同處方且日期有重疊的案件
drug_overlaps AS (
    SELECT 
        a1.quarter,
        a1.hospital_id,
        a1.patient_id,
        a1.claim_id as claim_id_1,
        a2.claim_id as claim_id_2,
        a1.drug_code as drug_code_1,
        a2.drug_code as drug_code_2,
        a1.start_date as start_date_1,
        a1.end_date as end_date_1,
        a2.start_date as start_date_2,
        a2.end_date as end_date_2,
        a1.drug_days as drug_days_1,
        a2.drug_days as drug_days_2,
        -- 計算重疊日數
        -- 重疊開始日 = MAX(start_date_1, start_date_2)
        -- 重疊結束日 = MIN(end_date_1, end_date_2)
        -- 重疊日數 = 重疊結束日 - 重疊開始日 + 1 (如果 > 0)
        CASE 
            WHEN GREATEST(a1.start_date, a2.start_date) <= LEAST(a1.end_date, a2.end_date)
            THEN DATEDIFF(LEAST(a1.end_date, a2.end_date), GREATEST(a1.start_date, a2.start_date)) + 1
            ELSE 0
        END as overlap_days
    FROM antidiabetic_drugs a1
    INNER JOIN antidiabetic_drugs a2
        ON a1.quarter = a2.quarter
        AND a1.hospital_id = a2.hospital_id  -- 同醫院
        AND a1.patient_id = a2.patient_id    -- 同病人
        AND a1.claim_id < a2.claim_id        -- 不同處方 (避免重複計算)
    WHERE 
        -- 有日期重疊: start_date_1 <= end_date_2 AND start_date_2 <= end_date_1
        a1.start_date <= a2.end_date
        AND a2.start_date <= a1.end_date
),

-- 分子: 計算各醫院每季的重疊給藥日數總和
numerator AS (
    SELECT 
        quarter,
        hospital_id,
        SUM(overlap_days) as total_overlap_days
    FROM drug_overlaps
    GROUP BY quarter, hospital_id
),

-- 分母: 計算各醫院每季的總給藥日數
denominator AS (
    SELECT 
        quarter,
        hospital_id,
        SUM(drug_days) as total_drug_days,
        COUNT(DISTINCT claim_id) as total_prescriptions,
        COUNT(DISTINCT patient_id) as total_patients
    FROM antidiabetic_drugs
    GROUP BY quarter, hospital_id
),

-- 計算重疊率
calculation AS (
    SELECT 
        d.quarter,
        d.hospital_id,
        h.hospital_name,
        h.hospital_level,
        h.region,
        COALESCE(n.total_overlap_days, 0) as total_overlap_days,
        d.total_drug_days,
        d.total_prescriptions,
        d.total_patients,
        CASE 
            WHEN d.total_drug_days > 0 
            THEN ROUND((COALESCE(n.total_overlap_days, 0) * 100.0 / d.total_drug_days), 2)
            ELSE 0 
        END as overlap_rate
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
        SUM(total_overlap_days) as sum_overlap_days,
        SUM(total_drug_days) as sum_drug_days,
        SUM(total_prescriptions) as sum_prescriptions,
        SUM(total_patients) as sum_patients,
        ROUND(AVG(overlap_rate), 2) as avg_overlap_rate,
        MIN(overlap_rate) as min_overlap_rate,
        MAX(overlap_rate) as max_overlap_rate,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY overlap_rate) as q25_overlap_rate,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY overlap_rate) as median_overlap_rate,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY overlap_rate) as q75_overlap_rate
    FROM calculation
    GROUP BY quarter
),

-- 統計摘要 (依醫院層級)
summary_by_level AS (
    SELECT 
        quarter,
        hospital_level,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(total_overlap_days) as sum_overlap_days,
        SUM(total_drug_days) as sum_drug_days,
        ROUND(AVG(overlap_rate), 2) as avg_overlap_rate,
        MIN(overlap_rate) as min_overlap_rate,
        MAX(overlap_rate) as max_overlap_rate
    FROM calculation
    GROUP BY quarter, hospital_level
),

-- 統計摘要 (依區域)
summary_by_region AS (
    SELECT 
        quarter,
        region,
        COUNT(DISTINCT hospital_id) as hospital_count,
        SUM(total_overlap_days) as sum_overlap_days,
        SUM(total_drug_days) as sum_drug_days,
        ROUND(AVG(overlap_rate), 2) as avg_overlap_rate,
        MIN(overlap_rate) as min_overlap_rate,
        MAX(overlap_rate) as max_overlap_rate
    FROM calculation
    GROUP BY quarter, region
),

-- 依ATC碼分類統計 (降血糖藥品類別)
antidiabetic_by_atc AS (
    SELECT 
        quarter,
        SUBSTRING(atc_code, 1, 4) as atc_class_4,
        CASE 
            WHEN SUBSTRING(atc_code, 1, 4) = 'A10A' THEN 'A10A - Insulins and analogues (胰島素及類似藥物)'
            WHEN SUBSTRING(atc_code, 1, 4) = 'A10B' THEN 'A10B - Blood glucose lowering drugs (降血糖藥)'
            WHEN SUBSTRING(atc_code, 1, 5) = 'A10BA' THEN 'A10BA - Biguanides (雙胍類)'
            WHEN SUBSTRING(atc_code, 1, 5) = 'A10BB' THEN 'A10BB - Sulfonamides (磺醯尿素類)'
            WHEN SUBSTRING(atc_code, 1, 5) = 'A10BG' THEN 'A10BG - Thiazolidinediones (噻唑烷二酮類)'
            WHEN SUBSTRING(atc_code, 1, 5) = 'A10BH' THEN 'A10BH - DPP-4 inhibitors (DPP-4抑制劑)'
            WHEN SUBSTRING(atc_code, 1, 5) = 'A10BJ' THEN 'A10BJ - GLP-1 analogues (GLP-1類似物)'
            WHEN SUBSTRING(atc_code, 1, 5) = 'A10BK' THEN 'A10BK - SGLT2 inhibitors (SGLT2抑制劑)'
            WHEN SUBSTRING(atc_code, 1, 5) = 'A10BX' THEN 'A10BX - Other blood glucose lowering drugs (其他降血糖藥)'
            ELSE 'Other'
        END as atc_class_name,
        COUNT(DISTINCT claim_id) as prescription_count,
        SUM(drug_days) as total_drug_days,
        COUNT(DISTINCT patient_id) as patient_count
    FROM antidiabetic_drugs
    GROUP BY quarter, SUBSTRING(atc_code, 1, 4)
),

-- 趨勢分析 (各季度變化)
trend_analysis AS (
    SELECT 
        c1.quarter as current_quarter,
        c1.hospital_id,
        c1.hospital_name,
        c1.overlap_rate as current_rate,
        c2.quarter as previous_quarter,
        c2.overlap_rate as previous_rate,
        CASE 
            WHEN c2.overlap_rate IS NOT NULL 
            THEN ROUND((c1.overlap_rate - c2.overlap_rate), 2)
            ELSE NULL 
        END as rate_change,
        CASE 
            WHEN c2.overlap_rate IS NOT NULL AND c2.overlap_rate > 0
            THEN ROUND(((c1.overlap_rate - c2.overlap_rate) * 100.0 / c2.overlap_rate), 2)
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

-- 輸出1: 各醫療機構降血糖藥品用藥日數重疊率
SELECT 
    quarter as '季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    hospital_level as '醫院層級',
    region as '區域',
    total_overlap_days as '重疊給藥日數',
    total_drug_days as '總給藥日數',
    total_prescriptions as '處方件數',
    total_patients as '病人數',
    overlap_rate as '用藥日數重疊率(%)'
FROM calculation
ORDER BY quarter, overlap_rate DESC;

-- 輸出2: 各季度統計摘要
SELECT 
    quarter as '季度',
    hospital_count as '醫療機構數',
    sum_overlap_days as '總重疊日數',
    sum_drug_days as '總給藥日數',
    sum_prescriptions as '總處方件數',
    sum_patients as '總病人數',
    avg_overlap_rate as '平均重疊率(%)',
    min_overlap_rate as '最低重疊率(%)',
    q25_overlap_rate as '第1四分位數(%)',
    median_overlap_rate as '中位數(%)',
    q75_overlap_rate as '第3四分位數(%)',
    max_overlap_rate as '最高重疊率(%)'
FROM summary_by_quarter
ORDER BY quarter;

-- 輸出3: 依醫院層級統計
SELECT 
    quarter as '季度',
    hospital_level as '醫院層級',
    hospital_count as '醫療機構數',
    sum_overlap_days as '總重疊日數',
    sum_drug_days as '總給藥日數',
    avg_overlap_rate as '平均重疊率(%)',
    min_overlap_rate as '最低重疊率(%)',
    max_overlap_rate as '最高重疊率(%)'
FROM summary_by_level
ORDER BY quarter, hospital_level;

-- 輸出4: 依區域統計
SELECT 
    quarter as '季度',
    region as '區域',
    hospital_count as '醫療機構數',
    sum_overlap_days as '總重疊日數',
    sum_drug_days as '總給藥日數',
    avg_overlap_rate as '平均重疊率(%)',
    min_overlap_rate as '最低重疊率(%)',
    max_overlap_rate as '最高重疊率(%)'
FROM summary_by_region
ORDER BY quarter, region;

-- 輸出5: 依ATC碼分類統計 (降血糖藥品類別)
SELECT 
    quarter as '季度',
    atc_class_4 as 'ATC前4碼',
    atc_class_name as 'ATC分類名稱',
    prescription_count as '處方件數',
    total_drug_days as '總給藥日數',
    patient_count as '病人數'
FROM antidiabetic_by_atc
ORDER BY quarter, prescription_count DESC;

-- 輸出6: 趨勢分析
SELECT 
    current_quarter as '當前季度',
    hospital_id as '醫療機構代碼',
    hospital_name as '醫療機構名稱',
    current_rate as '當前重疊率(%)',
    previous_quarter as '前一季度',
    previous_rate as '前一季重疊率(%)',
    rate_change as '重疊率變化(百分點)',
    rate_change_percent as '重疊率變化率(%)'
FROM trend_analysis
WHERE previous_quarter IS NOT NULL
ORDER BY current_quarter, rate_change DESC;

-- ============================================
-- FHIR資源查詢說明
-- ============================================
-- 
-- 1. MedicationRequest (降血糖藥品處方)
--    GET {FHIR_SERVER}/MedicationRequest?
--        date=ge2024-01-01&
--        category=outpatient&
--        status=completed&
--        medication.code:text=antidiabetic&
--        _include=MedicationRequest:medication&
--        _include=MedicationRequest:patient
-- 
-- 2. Encounter (就診記錄)
--    GET {FHIR_SERVER}/Encounter?
--        date=ge2024-01-01&
--        class=AMB&
--        status=finished
-- 
-- 3. Medication (降血糖藥品資訊)
--    GET {FHIR_SERVER}/Medication?
--        code:text=antidiabetic&
--        _filter=(code.coding.system eq 'http://www.whocc.no/atc' and 
--                 code.coding.code sw 'A10')
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
