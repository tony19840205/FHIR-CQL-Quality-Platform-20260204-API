library Indicator_15_3_Partial_Knee_Arthroplasty_90Day_Deep_Infection_3250 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 3250
// 條件依據：半人工膝關節置換手術後九十日以內置換物深部感染率
// 製作日期：2025-11-20

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

context Patient

// Helper: check if code string is in a list
define function CodeInList(codeVal String, codeList List<String>):
  codeList CL where CL = codeVal

// 1. 半人工膝關節置換執行案件數 (Denominator)
define "Partial TKA Procedures":
  [Procedure] P
    where (
      exists (P.code.coding C where exists CodeInList(C.code.value, {'64169B', '425272008', '609590004'}))
    )
    and P.status.value = 'completed'

// 2. 置換物深部感染案件數 (Numerator)
define "Deep Infection After Partial TKA":
  [Procedure] PI
    where (
      exists (PI.code.coding C where exists CodeInList(C.code.value, {'64053B', '64198B'}))
    )
    and PI.status.value = 'completed'
    and exists (
      "Partial TKA Procedures" PTKA
        where PTKA.subject.reference.value = PI.subject.reference.value
        // Infection within 90 days after partial TKA
        and (PI.performed as FHIR.dateTime).value in Interval[
          (PTKA.performed as FHIR.dateTime).value,
          (PTKA.performed as FHIR.dateTime).value + 90 days
        ]
        // Exclude: 64198B reported same day as 64164B or 64169B
        and not (
          exists (PI.code.coding C where C.code.value = '64198B')
          and (
            exists (PTKA.code.coding C where C.code.value = '64164B')
            or exists (PTKA.code.coding C where C.code.value = '64169B')
          )
          and (PTKA.performed as FHIR.dateTime).value = (PI.performed as FHIR.dateTime).value
        )
    )

// 3. 分母：每季半人工膝關節置換執行案件數
define "Denominator":
  Count("Partial TKA Procedures")

// 4. 分子：每季置換物深部感染案件數
define "Numerator":
  Count("Deep Infection After Partial TKA")

// 5. 指標計算結果
define "Infection Rate":
  if "Denominator" > 0 then
    (ToDecimal("Numerator") / ToDecimal("Denominator")) * 100
  else
    null
