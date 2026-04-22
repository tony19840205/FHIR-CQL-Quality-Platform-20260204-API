library Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 2524(季)、2526(年)
// 條件依據：清淨手術術後傷口感染率
// 製作日期：2025-11-20

// 清淨手術代碼：ICD-10-PCS、NHI 手術醫令代碼
// 傷口感染代碼：ICD-10-CM 診斷代碼

context Patient

// 1. 執行清淨手術之人數 (Denominator)
define "Clean Surgery Procedures":
  [Procedure] P
    where P.status.value = 'completed'
    and (
      // NHI 清淨手術醫令代碼（第一組）
      exists (
        P.code.coding C 
          where C.system.value = 'http://www.nhi.gov.tw/codes'
          and C.code.value in {
            '75607C', '75610B', '75613C', '75614C', '75615C', '88029C'
          }
      )
      // ICD-10-PCS 手術代碼（第一組：乳房、卵巢手術）
      or exists (
        P.code.coding C 
          where C.system.value = 'http://hl7.org/fhir/sid/icd-10-pcs'
          and C.code.value in {
            '0YQ50ZZ', '0YQ537Z', '0YQ54ZZ', '0YQ60ZZ', '0YQ637Z', '0YQ74ZZ',
            '0YQ80ZZ', '0YQ83ZZ', '0YQ8C0Z', '0YQ8C3Z', '0YQ8C4Z',
            '0YQA0ZZ', '0YQA4ZZ', '0YQE0ZZ', '0YQE3ZZ', '0YQE4ZZ'
          }
      )
      // ICD-10-PCS + ICD-10-CM 組合（第二組：甲狀腺手術）
      or (
        exists (
          P.code.coding C 
            where C.system.value = 'http://hl7.org/fhir/sid/icd-10-pcs'
            and C.code.value in {
              '0GBG0ZZ', '0GBG3ZZ', '0GBG4ZZ', '0GBH0ZZ', '0GBH3ZZ', '0GBH4ZZ',
              '0GTG0ZZ', '0GTG4ZZ', '0GTH0ZZ', '0GTH4ZZ', '0GTK0ZZ', '0GTK4ZZ'
            }
        )
        and exists (
          [Condition] Cond
            where Last(Split(Cond.subject.reference.value, '/')) = Last(Split(P.subject.reference.value, '/'))
            and exists (
              Cond.code.coding CD 
                where CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
                and CD.code.value in {
                  'E00', 'E01', 'E02', 'E03', 'E04', 'E05', 'E06', 'E07', 'E35', 'E89.0'
                }
            )
        )
      )
      // NHI 甲狀腺手術醫令代碼
      or exists (
        P.code.coding C 
          where C.system.value = 'http://www.nhi.gov.tw/codes'
          and C.code.value in {
            '82001C', '82002C', '82003C', '82004B', '82008B', '82015B', '82016B',
            '66012B', '66013B', '66014B', '66023B'
          }
      )
      // ICD-10-PCS 疝氣修補、關節置換等（第三組）
      or exists (
        P.code.coding C 
          where C.system.value = 'http://hl7.org/fhir/sid/icd-10-pcs'
          and C.code.value in {
            '0SR9019', '0SR901A', '0SR901Z', '0SR9029', '0SR902A', '0SR902Z',
            '0SR9039', '0SR903A', '0SR903Z', '0SR9049', '0SR904A', '0SR904Z',
            '0SR907Z', '0SR90J9', '0SR90JA', '0SR90JZ', '0SR90KZ',
            '0SRB019', '0SRB01A', '0SRB01Z', '0SRB029', '0SRB02A', '0SRB02Z',
            '0SRB039', '0SRB03A', '0SRB03Z', '0SRB049', '0SRB04A', '0SRB04Z',
            '0SRB07Z', '0SRB0JA',
            '0SRC07Z', '0SRC0J9', '0SRC0JA', '0SRC0JZ', '0SRC0KZ',
            '0SRD0J9', '0SRD0JA', '0SRD0JZ', '0SRDKZ',
            '0SRT07Z', '0SRT0J9', '0SRT0JA', '0SRT0JZ', '0SRT0KZ',
            '0SRU07Z', '0SRU0J9', '0SRU0JA', '0SRU0JZ', '0SRU0KZ',
            '0SRV07Z', '0SRV0J9', '0SRV0JA', '0SRV0JZ', '0SRV0KZ',
            '0SRW07Z', '0SRW0J9', '0SRW0JA', '0SRW0JZ', '0SRW0KZ'
          }
      )
      // NHI 疝氣修補醫令代碼
      or exists (
        P.code.coding C 
          where C.system.value = 'http://www.nhi.gov.tw/codes'
          and C.code.value in {
            '64162B', '64164B', '64169B', '64170B'
          }
      )
    )

// 2. 執行清淨手術且傷口感染之人數 (Numerator)
define "Clean Surgery With Wound Infection":
  "Clean Surgery Procedures" CSP
    where exists (
      [Condition] C
        where Last(Split(C.subject.reference.value, '/')) = Last(Split(CSP.subject.reference.value, '/'))
        and exists (
          C.code.coding CD 
            where CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
            and CD.code.value in {
              'K6811', 'R5084', 'T80211A', 'T80212A', 'T80218A', 'T80219A',
              'T80222XA', 'T81302A', 'T81303XA', 'T81304XA', 'T81351XA', 'T81359XA',
              'T82451XA', 'T82452XA', 'T82453XA', 'T8459XA',
              'T84600XA', 'T84610A', 'T84611A', 'T84612A', 'T84613A', 'T84615A', 'T84619A',
              'T84620A', 'T84621A', 'T84622A', 'T84623A', 'T84624A', 'T84625A', 'T84629A',
              'T84633XA', 'T84639XA', 'T84699XA',
              'T8571XA', 'T8572XA', 'T8579XA', 'T86842'
            }
        )
    )

// 3. 分母：執行清淨手術之人數
define "Denominator":
  Count(
    distinct "Clean Surgery Procedures" CSP
      return CSP.subject.reference.value
  )

// 4. 分子：執行清淨手術且傷口感染之人數
define "Numerator":
  Count(
    distinct "Clean Surgery With Wound Infection" CSWI
      return CSWI.subject.reference.value
  )

// 5. 指標計算結果
define "Infection Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null
