library Indicator_Peptic_Ulcer_NSAID_Usage_Within_1Year_Rate version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 消化性潰瘍病人開始治療一年以內有用口服非類固醇抗發炎劑比率
// 製作日期：2026-01-06

/*
 * 指標名稱: 消化性潰瘍病人開始治療一年以內有用口服非類固醇抗發炎劑比率
 * Indicator: Rate of Peptic Ulcer Patients Using Oral NSAIDs within 1 Year of Treatment Initiation
 * 
 * 資料來源: 醫療給付檔案分析系統
 * 
 * 公式說明:
 * 分子: 使用口服非類固醇抗發炎劑人數，指消化性潰瘍新病患(註1)，1年內在同一家醫療院所
 *       連續使用14日以上非類固醇類抗發炎劑(ATC碼為M01A)之人數
 * 分母: 消化性潰瘍人數，指消化性潰瘍新病人人數(詳註1)
 * 
 * 分母排除條件：
 * 【排除長期必要用藥之病人，含類風濕性關節炎(主、次診斷ICD-10-CM前三碼為M05-M06、M08、M12)、
 * 紅斑性狼瘡(主、次診斷ICD-10-CM為M32)、僵直性脊椎炎(主、次診斷ICD-10-CM為M081、M45、M488X)、
 * 心血管疾病(主、次診斷ICD-10-CM為G450、G451、G454、G458、G459、I63019、I63119、I63139、I6320、
 * I63219、I6322、I63239、I6330、I6340、I6350、I6359、I6509、I651、I6529、I658、I659、I6609、
 * I6619、I6629、I669、I671、I672、I674、I675、I676、I677、I67781、I6782、I67848、I67850、
 * I67858、I6789、I679、P91821、P91822、P91823、P91829)、使用低劑量之Aspirin（ATC code B01AC06）之病人】
 * 
 * (註1) 消化性潰瘍新病人定義：
 * 在觀察期間，同時符合下列二項條件者，視為消化性潰瘍新病人：
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

-- ICD-10-CM 排除診斷 - 類風濕性關節炎 (M05-M06、M08、M12)
code "Rheumatoid_Arthritis_M05": 'M05' from "ICD10CM" display '血清陽性類風濕性關節炎'
code "Rheumatoid_Arthritis_M06": 'M06' from "ICD10CM" display '其他類風濕性關節炎'
code "Rheumatoid_Arthritis_M08": 'M08' from "ICD10CM" display '幼年型關節炎'
code "Rheumatoid_Arthritis_M12": 'M12' from "ICD10CM" display '其他特定關節病變'

-- ICD-10-CM 排除診斷 - 紅斑性狼瘡 (M32)
code "Systemic_Lupus_M32": 'M32' from "ICD10CM" display '全身性紅斑性狼瘡'

-- ICD-10-CM 排除診斷 - 僵直性脊椎炎 (M081、M45、M488X)
code "Ankylosing_Spondylitis_M081": 'M081' from "ICD10CM" display '幼年型僵直性脊椎炎'
code "Ankylosing_Spondylitis_M45": 'M45' from "ICD10CM" display '僵直性脊椎炎'
code "Ankylosing_Spondylitis_M488X": 'M488X' from "ICD10CM" display '其他脊椎病變'

-- 健保處置代碼 - 上消化道內視鏡檢查
code "NHI_Upper_GI_Endoscopy_28016C": '28016C' from "NHI_PROCEDURE" display '上消化道泛內視鏡檢查'
code "NHI_Upper_GI_Series_33006B": '33006B' from "NHI_PROCEDURE" display '上消化道攝影'

-- 重大傷病代號
code "Catastrophic_Illness_001": '001' from "NHI_CATASTROPHIC" display '重大傷病(部份負擔代號001)'

-- ATC Code - NSAID (M01A)
code "ATC_NSAID_M01A": 'M01A' from "ATC" display '非類固醇抗發炎劑'

-- ATC Code - 低劑量Aspirin (B01AC06)
code "ATC_Aspirin_B01AC06": 'B01AC06' from "ATC" display 'Aspirin'

-- ActCode
code "ActCode_Outpatient": 'AMB' from "ActCode" display '門診'
code "ActCode_Emergency": 'EMER' from "ActCode" display '急診'
code "ActCode_Inpatient": 'IMP' from "ActCode" display '住院'

-- ==================== ValueSet 定義 ====================

valueset "Peptic_Ulcer_Diagnosis_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/peptic-ulcer-diagnosis'
valueset "NSAID_Medications_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/nsaid-medications'
valueset "Exclusion_Diagnoses_ValueSet": 'https://twcore.mohw.gov.tw/ig/twcore/ValueSet/nsaid-exclusion-diagnoses'

-- ==================== 參數 ====================

parameter "Measurement_Period" Interval<DateTime>
    default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.999]

parameter "Lookback_Period_1Year" Interval<DateTime>
    default Interval[start of "Measurement_Period" - 1 year, start of "Measurement_Period"]

parameter "Endoscopy_Lookback_Period_4Months" Interval<DateTime>
    default Interval[start of "Measurement_Period" - 4 months, end of "Measurement_Period"]

parameter "NSAID_Followup_Period_1Year" Interval<DateTime>
    default Interval[start of "Measurement_Period", start of "Measurement_Period" + 1 year]

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
 * 定義6: 排除診斷條件
 * 類風濕性關節炎、紅斑性狼瘡、僵直性脊椎炎、心血管疾病
 */
define "Exclusion_Diagnoses":
    [Condition] C
        where exists (
            C.code.coding Cod
                where Cod.system = 'http://hl7.org/fhir/sid/icd-10-cm'
                    and (
                        -- 類風濕性關節炎 (M05-M06、M08、M12)
                        StartsWith(Cod.code, 'M05')
                        or StartsWith(Cod.code, 'M06')
                        or StartsWith(Cod.code, 'M08')
                        or StartsWith(Cod.code, 'M12')
                        -- 紅斑性狼瘡 (M32)
                        or StartsWith(Cod.code, 'M32')
                        -- 僵直性脊椎炎 (M081、M45、M488X)
                        or Cod.code = 'M081'
                        or Cod.code = 'M45'
                        or StartsWith(Cod.code, 'M488')
                        -- 心血管疾病 (G450系列)
                        or Cod.code = 'G450'
                        or Cod.code = 'G451'
                        or Cod.code = 'G454'
                        or Cod.code = 'G458'
                        or Cod.code = 'G459'
                        -- 心血管疾病 (I63系列)
                        or Cod.code = 'I63019'
                        or Cod.code = 'I63119'
                        or Cod.code = 'I63139'
                        or Cod.code = 'I6320'
                        or Cod.code = 'I63219'
                        or Cod.code = 'I6322'
                        or Cod.code = 'I63239'
                        or Cod.code = 'I6330'
                        or Cod.code = 'I6340'
                        or Cod.code = 'I6350'
                        or Cod.code = 'I6359'
                        or Cod.code = 'I6509'
                        or Cod.code = 'I651'
                        or Cod.code = 'I6529'
                        or Cod.code = 'I658'
                        or Cod.code = 'I659'
                        or Cod.code = 'I6609'
                        or Cod.code = 'I6619'
                        or Cod.code = 'I6629'
                        or Cod.code = 'I669'
                        or Cod.code = 'I671'
                        or Cod.code = 'I672'
                        or Cod.code = 'I674'
                        or Cod.code = 'I675'
                        or Cod.code = 'I676'
                        or Cod.code = 'I677'
                        or Cod.code = 'I67781'
                        or Cod.code = 'I6782'
                        or Cod.code = 'I67848'
                        or Cod.code = 'I67850'
                        or Cod.code = 'I67858'
                        or Cod.code = 'I6789'
                        or Cod.code = 'I679'
                        -- P91系列
                        or Cod.code = 'P91821'
                        or Cod.code = 'P91822'
                        or Cod.code = 'P91823'
                        or Cod.code = 'P91829'
                    )
        )
        and C.verificationStatus ~ ToConcept(Code { code: 'confirmed', system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status' })

/*
 * 定義7: 有排除診斷
 */
define "Has_Exclusion_Diagnosis":
    exists("Exclusion_Diagnoses")

/*
 * 定義8: 前一年因消化性潰瘍就醫記錄
 */
define "Previous_Year_Peptic_Ulcer_Encounters":
    "All_Encounters" E
        where E.period starts during "Lookback_Period_1Year"
            and exists (
                "Peptic_Ulcer_Diagnosis" C
                    where C.encounter.reference = 'Encounter/' + E.id
            )

/*
 * 定義9: 前一年有重大傷病身份(代號001)
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
 * 定義10: 上消化道內視鏡檢查 (28016C或33006B)
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
 * 定義11: 制酸懸浮劑 (560400或560499)
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
                        and not (
                            EndsWith(Cod.code, '00')
                            or EndsWith(Cod.code, 'G0')
                        )
                        and Cod.code not in {
                            '5604001500', '9600065500', '4008000700',
                            '5604002500', '5604002501', '5604002900',
                            '5604001200', '5612001300'
                        }
            )

/*
 * 定義12: H2RA (560500)
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
 * 定義13: PPI (560900)
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
 * 定義14: 細胞保護劑 (560700)
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
 * 定義15: 所有消化性潰瘍用藥
 */
define "All_Peptic_Ulcer_Medications":
    "Antacid_Medications"
        union "H2RA_Medications"
        union "PPI_Medications"
        union "Cytoprotective_Medications"

/*
 * 定義16: 獲取藥物處方日期
 */
define function "Get_Medication_Date"(Med MedicationRequest):
    if Med.authoredOn is not null
    then Med.authoredOn
    else start of Med.dispenseRequest.validityPeriod

/*
 * 定義17: 計算藥物使用天數
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
 * 定義18: 初次使用消化性潰瘍用藥的門診個案
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
            and not exists (
                "All_Peptic_Ulcer_Medications" PrevMed
                    where "Get_Medication_Date"(PrevMed) during "Lookback_Period_1Year"
            )
        return E

/*
 * 定義19: NSAID藥物 (ATC碼M01A)
 */
define "NSAID_Medications":
    [MedicationRequest] M
        where M.status = 'completed'
            and exists (
                M.medicationCodeableConcept.coding Cod
                    where Cod.system = 'http://www.whocc.no/atc'
                        and StartsWith(Cod.code, 'M01A')
            )

/*
 * 定義20: 低劑量Aspirin (ATC碼B01AC06)
 */
define "Low_Dose_Aspirin":
    [MedicationRequest] M
        where M.status = 'completed'
            and exists (
                M.medicationCodeableConcept.coding Cod
                    where Cod.system = 'http://www.whocc.no/atc'
                        and Cod.code = 'B01AC06'
            )

/*
 * 定義21: 有使用低劑量Aspirin
 */
define "Has_Low_Dose_Aspirin":
    exists("Low_Dose_Aspirin")

/*
 * 定義22: 獲取就醫機構代碼
 */
define function "Get_Organization_ID"(Enc Encounter):
    if Enc.serviceProvider is not null
    then Last(Split(Enc.serviceProvider.reference, '/'))
    else null

/*
 * 分母定義: 消化性潰瘍新病患人數（排除長期必要用藥之病人）
 * 
 * 條件:
 * 1. 前一年無消化性潰瘍(K25-K28)就醫記錄
 * 2. 前一年無重大傷病身份(代號001)
 * 3. 初次使用消化性潰瘍用藥的門診個案
 * 4. 前4個月內有上消化道內視鏡檢查(28016C或33006B)
 * 5. 排除有類風濕性關節炎、紅斑性狼瘡、僵直性脊椎炎、心血管疾病診斷者
 * 6. 排除使用低劑量Aspirin者
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
            and not "Has_Exclusion_Diagnosis"
            and not "Has_Low_Dose_Aspirin"

define "Denominator_Count":
    Count("Denominator")

/*
 * 定義23: 檢查1年內在同一家醫療院所連續使用NSAID 14日以上
 */
define function "Has_NSAID_14Days_Same_Facility"(IndexEnc Encounter):
    let 
        facility_id: "Get_Organization_ID"(IndexEnc),
        index_date: start of IndexEnc.period,
        followup_period: Interval[index_date, index_date + 1 year],
        nsaid_prescriptions: 
            "NSAID_Medications" N
                where "Get_Medication_Date"(N) during followup_period
                    and exists (
                        [Encounter] E
                            where E.id = Last(Split(N.encounter.reference, '/'))
                                and "Get_Organization_ID"(E) = facility_id
                    ),
        total_nsaid_days: Sum(nsaid_prescriptions N return "Calculate_Medication_Days"(N))
    return total_nsaid_days >= 14

/*
 * 分子定義: 使用口服非類固醇抗發炎劑人數
 * 
 * 條件:
 * 1. 符合分母條件
 * 2. 1年內在同一家醫療院所連續使用14日以上非類固醇類抗發炎劑(ATC碼為M01A)
 */
define "Numerator":
    "Denominator" E
        where "Has_NSAID_14Days_Same_Facility"(E)

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
 * 統計1: NSAID使用情況分布
 */
define "NSAID_Usage_Distribution":
    "Denominator" E
        let 
            facility_id: "Get_Organization_ID"(E),
            index_date: start of E.period,
            followup_period: Interval[index_date, index_date + 1 year],
            nsaid_prescriptions: 
                "NSAID_Medications" N
                    where "Get_Medication_Date"(N) during followup_period
                        and exists (
                            [Encounter] Enc
                                where Enc.id = Last(Split(N.encounter.reference, '/'))
                                    and "Get_Organization_ID"(Enc) = facility_id
                        ),
            total_days: Sum(nsaid_prescriptions N return "Calculate_Medication_Days"(N)),
            prescription_count: Count(nsaid_prescriptions)
        return {
            encounter_id: E.id,
            facility_id: facility_id,
            nsaid_prescription_count: prescription_count,
            total_nsaid_days: total_days,
            meets_14day_requirement: total_days >= 14,
            days_category: 
                if total_days = 0 then '無使用'
                else if total_days < 7 then '<7天'
                else if total_days < 14 then '7-13天'
                else if total_days <= 30 then '14-30天'
                else if total_days <= 90 then '31-90天'
                else '>90天'
        }

/*
 * 統計2: NSAID使用天數摘要
 */
define "NSAID_Usage_Summary":
    {
        no_usage: Count("NSAID_Usage_Distribution" D where D.days_category = '無使用'),
        less_than_7_days: Count("NSAID_Usage_Distribution" D where D.days_category = '<7天'),
        days_7_to_13: Count("NSAID_Usage_Distribution" D where D.days_category = '7-13天'),
        days_14_to_30: Count("NSAID_Usage_Distribution" D where D.days_category = '14-30天'),
        days_31_to_90: Count("NSAID_Usage_Distribution" D where D.days_category = '31-90天'),
        more_than_90_days: Count("NSAID_Usage_Distribution" D where D.days_category = '>90天'),
        meets_requirement: Count("NSAID_Usage_Distribution" D where D.meets_14day_requirement = true)
    }

/*
 * 統計3: 排除診斷分布
 */
define "Exclusion_Diagnosis_Distribution":
    let 
        all_conditions: "Exclusion_Diagnoses"
    return {
        rheumatoid_arthritis: Count(all_conditions C where exists(C.code.coding Cod where StartsWith(Cod.code, 'M05') or StartsWith(Cod.code, 'M06') or StartsWith(Cod.code, 'M08') or StartsWith(Cod.code, 'M12'))),
        systemic_lupus: Count(all_conditions C where exists(C.code.coding Cod where StartsWith(Cod.code, 'M32'))),
        ankylosing_spondylitis: Count(all_conditions C where exists(C.code.coding Cod where Cod.code = 'M081' or Cod.code = 'M45' or StartsWith(Cod.code, 'M488'))),
        cardiovascular_disease: Count(all_conditions C where exists(C.code.coding Cod where StartsWith(Cod.code, 'G45') or StartsWith(Cod.code, 'I6') or StartsWith(Cod.code, 'P918')))
    }

/*
 * 統計4: 消化性潰瘍新病患篩選流程統計
 */
define "New_Patient_Screening_Summary":
    {
        total_first_time_ulcer_med: Count("First_Time_Peptic_Ulcer_Medication_Outpatient"),
        excluded_previous_encounter: Count(
            "First_Time_Peptic_Ulcer_Medication_Outpatient" E
                where exists("Previous_Year_Peptic_Ulcer_Encounters")
        ),
        excluded_catastrophic_illness: Count(
            "First_Time_Peptic_Ulcer_Medication_Outpatient" E
                where "Has_Catastrophic_Illness_Previous_Year"
        ),
        excluded_no_endoscopy: Count(
            "First_Time_Peptic_Ulcer_Medication_Outpatient" E
                where not exists (
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
        ),
        excluded_exclusion_diagnosis: Count(
            "First_Time_Peptic_Ulcer_Medication_Outpatient" E
                where "Has_Exclusion_Diagnosis"
        ),
        excluded_low_dose_aspirin: Count(
            "First_Time_Peptic_Ulcer_Medication_Outpatient" E
                where "Has_Low_Dose_Aspirin"
        ),
        final_denominator: "Denominator_Count"
    }

/*
 * 統計5: 內視鏡檢查類型分布
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
 * 統計6: 內視鏡檢查類型摘要
 */
define "Endoscopy_Type_Summary":
    {
        endoscopy_28016C: Count("Endoscopy_Type_Distribution" D where D.has_endoscopy_28016C = true),
        upper_gi_series_33006B: Count("Endoscopy_Type_Distribution" D where D.has_upper_gi_series_33006B = true),
        both: Count("Endoscopy_Type_Distribution" D where D.endoscopy_type = '兩者皆有')
    }

/*
 * 統計7: 消化性潰瘍診斷類型分布
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
 * 品質檢核1: 檢查NSAID使用是否在同一家醫療院所
 */
define "Quality_Check_Same_Facility_NSAID":
    "Numerator" E
        let 
            facility_id: "Get_Organization_ID"(E),
            index_date: start of E.period,
            followup_period: Interval[index_date, index_date + 1 year],
            nsaid_prescriptions: "NSAID_Medications" N where "Get_Medication_Date"(N) during followup_period,
            same_facility_prescriptions: 
                nsaid_prescriptions N
                    where exists (
                        [Encounter] Enc
                            where Enc.id = Last(Split(N.encounter.reference, '/'))
                                and "Get_Organization_ID"(Enc) = facility_id
                    ),
            different_facility_count: Count(nsaid_prescriptions) - Count(same_facility_prescriptions)
        return {
            encounter_id: E.id,
            index_facility_id: facility_id,
            total_nsaid_prescriptions: Count(nsaid_prescriptions),
            same_facility_prescriptions: Count(same_facility_prescriptions),
            different_facility_prescriptions: different_facility_count,
            issue: if different_facility_count > 0 then '有跨院所NSAID處方' else null
        }

/*
 * 品質檢核2: 檢查排除條件的完整性
 */
define "Quality_Check_Exclusion_Criteria":
    {
        screening_summary: "New_Patient_Screening_Summary",
        exclusion_diagnosis_summary: "Exclusion_Diagnosis_Distribution",
        low_dose_aspirin_count: Count("Low_Dose_Aspirin")
    }

/*
 * 品質檢核3: 檢查NSAID使用天數計算
 */
define "Quality_Check_NSAID_Days_Calculation":
    "Numerator" E
        let 
            facility_id: "Get_Organization_ID"(E),
            index_date: start of E.period,
            followup_period: Interval[index_date, index_date + 1 year],
            nsaid_prescriptions: 
                "NSAID_Medications" N
                    where "Get_Medication_Date"(N) during followup_period
                        and exists (
                            [Encounter] Enc
                                where Enc.id = Last(Split(N.encounter.reference, '/'))
                                    and "Get_Organization_ID"(Enc) = facility_id
                        ),
            total_days: Sum(nsaid_prescriptions N return "Calculate_Medication_Days"(N))
        return {
            encounter_id: E.id,
            prescription_count: Count(nsaid_prescriptions),
            total_days: total_days,
            meets_14day_requirement: total_days >= 14,
            issue: if total_days < 14 then '天數不足14天但在分子中' else null
        }

/*
 * 品質檢核4: 檢查內視鏡檢查時間範圍
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
 * 品質檢核5: 整體品質檢核摘要
 */
define "Quality_Check_Summary":
    {
        exclusion_criteria_info: "Quality_Check_Exclusion_Criteria",
        cross_facility_nsaid_count: Count("Quality_Check_Same_Facility_NSAID" Q where Q.different_facility_prescriptions > 0),
        insufficient_nsaid_days_count: Count("Quality_Check_NSAID_Days_Calculation" Q where Q.issue is not null)
    }

-- ==================== 最終結果輸出 ====================

/*
 * 最終指標結果
 */
define "Final_Result":
    {
        indicator_name: '消化性潰瘍病人開始治療一年以內有用口服非類固醇抗發炎劑比率',
        measurement_period: "Measurement_Period",
        denominator: "Denominator_Count",
        numerator: "Numerator_Count",
        rate_percentage: "Indicator_Rate",
        nsaid_usage_summary: "NSAID_Usage_Summary",
        exclusion_diagnosis_summary: "Exclusion_Diagnosis_Distribution",
        new_patient_screening_summary: "New_Patient_Screening_Summary",
        endoscopy_type_summary: "Endoscopy_Type_Summary",
        diagnosis_type_summary: "Diagnosis_Type_Summary",
        quality_check_summary: "Quality_Check_Summary"
    }
