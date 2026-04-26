library Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ============================================
// 來源：醫療給付檔案案分析系統
// 指標代碼: 3249
// 指標名稱：全人工膝關節置換手術後九十日以內置換物深部感染率
// 製作日期：2026-01-09
// Translator: CQL-to-ELM Translator version 3.10.0
// 時間範圍：無限制（All available data）
// ============================================
//
// 【備註】
// 1.資料來源：醫療給付檔案分析系統。指標代碼：3249
// 2.資料範圍：(1)每季所有醫療院所總額之住院案件。(2)排除代辦案件。
//
// 【公式說明】
// 分子：分母案件中全人工膝關節置換後90天內發生置換物感染之案件數。
// 分母：當季內醫院全人工膝關節置換術執行案件數。
//
// 全人工膝關節置換執行案件數：醫令代碼為64164B且醫令類別為2或醫令代碼為97805K、97806A、97807B之住院案件。
//
// 置換物感染：西醫院所之住院跨院案件中，以手術醫令行後續醫療置換物感染於術後90天，有執行64053B、64198B任一醫令之案件，
// 排除執行人工膝關節置換術(64164B)同日申報64198B或全人工膝關節置換術(64169B)同日申報64198B。
//
// 4.製表日期：114/11/06
// 5.製表單位：衛生福利部 中央健康保險署
// ============================================

// Code Systems
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ICD10PCS": 'http://www.cms.gov/Medicare/Coding/ICD10'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// ============================================
// 健保全人工膝關節置換術代碼
// ============================================
code "64164B": '64164B' from "NHI_PROCEDURE" display '人工膝關節置換術'
code "97805K": '97805K' from "NHI_PROCEDURE" display '全人工膝關節置換術-雙側'
code "97806A": '97806A' from "NHI_PROCEDURE" display '全人工膝關節置換術-單側'
code "97807B": '97807B' from "NHI_PROCEDURE" display '全人工膝關節置換術-複雜'
code "64169B": '64169B' from "NHI_PROCEDURE" display '全人工膝關節置換術'

// ============================================
// 健保置換物深部感染代碼
// ============================================
code "64053B": '64053B' from "NHI_PROCEDURE" display '西醫院所之住院案件中，以手術醫令行後續醫療置換物感染之手術'
code "64198B": '64198B' from "NHI_PROCEDURE" display '置換物深部感染之手術'

// ============================================
// SNOMED CT 全膝關節置換代碼
// ============================================
code "609588000": '609588000' from "SNOMEDCT" display 'Total knee replacement'
code "179344006": '179344006' from "SNOMEDCT" display 'Primary total knee replacement'
code "265157000": '265157000' from "SNOMEDCT" display 'Total knee arthroplasty'
code "112727000": '112727000' from "SNOMEDCT" display 'Total knee arthroplasty, bilateral'
code "85643006": '85643006' from "SNOMEDCT" display 'Prosthetic arthroplasty of knee joint'

// ============================================
// ICD-10-PCS 全膝關節置換代碼
// ============================================
code "0SRC0JZ": '0SRC0JZ' from "ICD10PCS" display 'Replacement of Right Knee Joint with Synthetic Substitute, Open Approach'
code "0SRD0JZ": '0SRD0JZ' from "ICD10PCS" display 'Replacement of Left Knee Joint with Synthetic Substitute, Open Approach'

// ============================================
// 就醫類型代碼
// ============================================
code "IMP": 'IMP' from "ActCode" display 'Inpatient encounter - 住院'

context Patient

// ============================================
// Helper Functions
// ============================================

// Function: 取得手術執行日期
define function GetProcedureDate(p Procedure):
  case
    when p.performed is FHIR.dateTime then (p.performed as FHIR.dateTime).value
    when p.performed is FHIR.Period then (p.performed as FHIR.Period).start.value
    else null
  end

// Function: 檢查是否為全人工膝關節置換術（健保代碼）
define function IsTKAProcedureNHI(p Procedure):
  exists (
    p.code.coding C 
      where C.code.value in {
        '64164B', '97805K', '97806A', '97807B', '64169B'
      }
      and C.system.value = 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
  )

// Function: 檢查是否為全人工膝關節置換術（SNOMED）
define function IsTKAProcedureSNOMED(p Procedure):
  exists (
    p.code.coding C 
      where C.code.value in {
        '609588000', '179344006', '265157000', '112727000', '85643006'
      }
      and C.system.value = 'http://snomed.info/sct'
  )

// Function: 檢查是否為全人工膝關節置換術（ICD-10-PCS）
define function IsTKAProcedureICD10(p Procedure):
  exists (
    p.code.coding C 
      where C.code.value in {
        '0SRC0JZ', '0SRD0JZ'
      }
      and C.system.value = 'http://www.cms.gov/Medicare/Coding/ICD10'
  )

// Function: 檢查是否為置換物深部感染處置
define function IsDeepInfectionProcedure(p Procedure):
  exists (
    p.code.coding C 
      where C.code.value in {'64053B', '64198B'}
      and C.system.value = 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
  )

// Function: 檢查是否為64164B代碼
define function Is64164B(p Procedure):
  exists (
    p.code.coding C 
      where C.code.value = '64164B'
      and C.system.value = 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
  )

// Function: 檢查是否為64169B代碼
define function Is64169B(p Procedure):
  exists (
    p.code.coding C 
      where C.code.value = '64169B'
      and C.system.value = 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
  )

// Function: 檢查是否為64198B代碼
define function Is64198B(p Procedure):
  exists (
    p.code.coding C 
      where C.code.value = '64198B'
      and C.system.value = 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
  )

// Function: 檢查兩個手術是否在同一天
define function IsSameDay(date1 DateTime, date2 DateTime):
  date from date1 = date from date2

// Function: 計算日期差異（天數）
define function DaysBetween(startDate DateTime, endDate DateTime):
  days between startDate and endDate

// ============================================
// Main Definitions - 所有已完成的手術記錄
// ============================================

// 1. 所有已完成的手術記錄
define "All Completed Procedures":
  [Procedure] P
    where P.status.value = 'completed'

// 2. 所有住院就診記錄
define "All Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'IMP'
    // 排除代辦案件
    and not exists (
      E.type T 
        where exists (T.coding C where C.code.value = 'AGENCY')
    )

// 3. 住院手術記錄
define "Inpatient Procedures":
  "All Completed Procedures" P
    with "All Inpatient Encounters" E
      such that P.encounter.reference.value = 'Encounter/' + E.id.value

// ============================================
// TKA Procedures - 全人工膝關節置換手術
// ============================================

// 4. 全人工膝關節置換手術（健保代碼）
define "TKA Procedures NHI":
  "Inpatient Procedures" P
    where IsTKAProcedureNHI(P)

// 5. 全人工膝關節置換手術（SNOMED CT）
define "TKA Procedures SNOMED":
  "Inpatient Procedures" P
    where IsTKAProcedureSNOMED(P)

// 6. 全人工膝關節置換手術（ICD-10-PCS）
define "TKA Procedures ICD10":
  "Inpatient Procedures" P
    where IsTKAProcedureICD10(P)

// 7. 全人工膝關節置換手術（所有代碼系統）
define "All TKA Procedures":
  "TKA Procedures NHI"
    union "TKA Procedures SNOMED"
    union "TKA Procedures ICD10"

// ============================================
// Deep Infection Cases - 置換物深部感染案件
// ============================================

// 8. 置換物深部感染處置手術
define "Deep Infection Procedures":
  "Inpatient Procedures" PI
    where IsDeepInfectionProcedure(PI)

// 9. TKA術後90天內的深部感染案件
define "Deep Infection Within 90 Days After TKA":
  "Deep Infection Procedures" PI
    where exists (
      "All TKA Procedures" TKA
        where TKA.subject.reference.value = PI.subject.reference.value
        and GetProcedureDate(PI) is not null
        and GetProcedureDate(TKA) is not null
        // 感染發生在 TKA 手術後 90 天內（包含當天）
        and GetProcedureDate(PI) in Interval[
          GetProcedureDate(TKA),
          GetProcedureDate(TKA) + 90 days
        ]
    )

// 10. 需排除的案件（同日申報情況）
define "Excluded Same Day Cases":
  "Deep Infection Within 90 Days After TKA" PI
    where exists (
      "All TKA Procedures" TKA
        where TKA.subject.reference.value = PI.subject.reference.value
        and GetProcedureDate(PI) is not null
        and GetProcedureDate(TKA) is not null
        // 同日申報
        and IsSameDay(GetProcedureDate(TKA), GetProcedureDate(PI))
        // 64164B同日申報64198B 或 64169B同日申報64198B
        and Is64198B(PI)
        and (Is64164B(TKA) or Is64169B(TKA))
    )

// 11. 有效的深部感染案件（排除同日申報）
define "Valid Deep Infection Cases":
  "Deep Infection Within 90 Days After TKA" PI
    where not exists (
      "Excluded Same Day Cases" EX
        where EX.id.value = PI.id.value
    )

// ============================================
// Final Calculations - 指標計算
// ============================================

// 12. 分母：全人工膝關節置換執行案件數
define "Denominator":
  Count(distinct "All TKA Procedures")

// 13. 分子：置換物深部感染案件數
define "Numerator":
  Count(distinct "Valid Deep Infection Cases")

// 14. 指標計算結果：感染率（百分比）
define "Infection Rate":
  if "Denominator" > 0 then
    Round((ToDecimal("Numerator") / ToDecimal("Denominator")) * 100, 2)
  else
    null

// ============================================
// Additional Analysis - 補充分析
// ============================================

// 15. TKA手術明細（含病患資訊）
define "TKA Case Details":
  "All TKA Procedures" P
    return {
      procedureId: P.id.value,
      patientRef: P.subject.reference.value,
      procedureDate: GetProcedureDate(P),
      procedureCode: (
        singleton from (
          P.code.coding C
            where C.system.value = 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
            return C.code.value
        )
      ),
      encounterRef: P.encounter.reference.value
    }

// 16. 深部感染案件明細
define "Infection Case Details":
  "Valid Deep Infection Cases" PI
    return {
      infectionProcedureId: PI.id.value,
      patientRef: PI.subject.reference.value,
      infectionDate: GetProcedureDate(PI),
      infectionCode: (
        singleton from (
          PI.code.coding C
            where C.system.value = 'http://www.nhi.gov.tw/fhir/CodeSystem/nhi-procedure-codes'
            return C.code.value
        )
      ),
      relatedTKA: (
        "All TKA Procedures" TKA
          where TKA.subject.reference.value = PI.subject.reference.value
          and GetProcedureDate(PI) in Interval[
            GetProcedureDate(TKA),
            GetProcedureDate(TKA) + 90 days
          ]
          return {
            tkaId: TKA.id.value,
            tkaDate: GetProcedureDate(TKA),
            daysSinceTKA: DaysBetween(GetProcedureDate(TKA), GetProcedureDate(PI))
          }
      )
    }

// 17. 排除案件統計
define "Exclusion Summary":
  {
    totalInfectionsWithin90Days: Count("Deep Infection Within 90 Days After TKA"),
    excludedSameDayCases: Count("Excluded Same Day Cases"),
    validInfectionCases: Count("Valid Deep Infection Cases"),
    exclusionRate: if Count("Deep Infection Within 90 Days After TKA") > 0 then
      Round((ToDecimal(Count("Excluded Same Day Cases")) / ToDecimal(Count("Deep Infection Within 90 Days After TKA"))) * 100, 2)
    else
      null
  }

// 18. 最終報告摘要
define "Final Report":
  {
    indicator_code: '3249',
    indicator_name: '全人工膝關節置換手術後九十日以內置換物深部感染率',
    measurement_period: 'All available data (無時間限制)',
    denominator: "Denominator",
    numerator: "Numerator",
    infection_rate: "Infection Rate",
    exclusion_summary: "Exclusion Summary",
    data_quality: {
      tka_cases_nhi: Count("TKA Procedures NHI"),
      tka_cases_snomed: Count("TKA Procedures SNOMED"),
      tka_cases_icd10: Count("TKA Procedures ICD10"),
      total_unique_tka: "Denominator"
    }
  }
