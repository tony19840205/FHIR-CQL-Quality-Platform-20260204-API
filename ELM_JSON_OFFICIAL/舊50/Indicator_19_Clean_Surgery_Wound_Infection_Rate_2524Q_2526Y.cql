library Indicator_19_Clean_Surgery_Wound_Infection_Rate_2524Q_2526Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 2524(季)、2526(年)
// 條件依據：清淨手術術後傷口感染率
// 製作日期：2025-11-20

codesystem "ICD10PCS": 'http://hl7.org/fhir/sid/icd-10-pcs'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 清淨手術：案件分類為5且符合下列任一條件
// 條件(i): 主診斷碼前3碼為C40、C41、D65-D68或主診斷碼C7951-C7952、R791
// 條件(ii): 任一主次診斷碼為J或I(HI8碼為H65-H93或排除(HI3碼為J12-J18)或Z11(HI3碼為N30、N34、主碼N39.0)

// (1) 主處置代碼(ICD-10-PCS手術代碼) - 第一組（乳房、卵巢手術等）
code "0YQ50ZZ": '0YQ50ZZ' from "ICD10PCS" display 'Repair Right Breast, Open Approach'
code "0YQ537Z": '0YQ537Z' from "ICD10PCS" display 'Repair Right Breast, Percutaneous Approach'
code "0YQ54ZZ": '0YQ54ZZ' from "ICD10PCS" display 'Repair Right Breast, Percutaneous Endoscopic Approach'
code "0YQ60ZZ": '0YQ60ZZ' from "ICD10PCS" display 'Repair Left Breast, Open Approach'
code "0YQ637Z": '0YQ637Z' from "ICD10PCS" display 'Repair Left Breast, Percutaneous Approach'
code "0YQ74ZZ": '0YQ74ZZ' from "ICD10PCS" display 'Repair Bilateral Breast, Percutaneous Endoscopic'
code "0YQ80ZZ": '0YQ80ZZ' from "ICD10PCS" display 'Repair Nipple, Right, Open Approach'
code "0YQ83ZZ": '0YQ83ZZ' from "ICD10PCS" display 'Repair Nipple, Right, Percutaneous'
code "0YQ8C0Z": '0YQ8C0Z' from "ICD10PCS" display 'Repair Right Nipple, Open'
code "0YQ8C3Z": '0YQ8C3Z' from "ICD10PCS" display 'Repair Right Nipple, Percutaneous'
code "0YQ8C4Z": '0YQ8C4Z' from "ICD10PCS" display 'Repair Right Nipple, Percutaneous Endoscopic'
code "0YQA0ZZ": '0YQA0ZZ' from "ICD10PCS" display 'Repair Left Nipple, Open'
code "0YQA4ZZ": '0YQA4ZZ' from "ICD10PCS" display 'Repair Left Nipple, Percutaneous Endoscopic'
code "0YQE0ZZ": '0YQE0ZZ' from "ICD10PCS" display 'Repair Bilateral Nipple, Open'
code "0YQE3ZZ": '0YQE3ZZ' from "ICD10PCS" display 'Repair Bilateral Nipple, Percutaneous'
code "0YQE4ZZ": '0YQE4ZZ' from "ICD10PCS" display 'Repair Bilateral Nipple, Percutaneous Endoscopic'

// NHI 清淨手術醫令代碼
code "75607C": '75607C' from "NHI_PROCEDURE" display '清淨手術醫令'
code "75610B": '75610B' from "NHI_PROCEDURE" display '清淨手術醫令'
code "75613C": '75613C' from "NHI_PROCEDURE" display '清淨手術醫令'
code "75614C": '75614C' from "NHI_PROCEDURE" display '清淨手術醫令'
code "75615C": '75615C' from "NHI_PROCEDURE" display '清淨手術醫令'
code "88029C": '88029C' from "NHI_PROCEDURE" display '清淨手術醫令'

// (2) 主處置代碼(ICD-10-PCS手術代碼) - 第二組
code "0GBG0ZZ": '0GBG0ZZ' from "ICD10PCS" display 'Excision of Right Breast'
code "0GBG3ZZ": '0GBG3ZZ' from "ICD10PCS" display 'Excision of Right Breast, Percutaneous'
code "0GBG4ZZ": '0GBG4ZZ' from "ICD10PCS" display 'Excision of Right Breast, Percutaneous Endoscopic'
code "0GBH0ZZ": '0GBH0ZZ' from "ICD10PCS" display 'Excision of Left Breast'
code "0GBH3ZZ": '0GBH3ZZ' from "ICD10PCS" display 'Excision of Left Breast, Percutaneous'
code "0GBH4ZZ": '0GBH4ZZ' from "ICD10PCS" display 'Excision of Left Breast, Percutaneous Endoscopic'
code "0GTG0ZZ": '0GTG0ZZ' from "ICD10PCS" display 'Resection of Right Ovary'
code "0GTG4ZZ": '0GTG4ZZ' from "ICD10PCS" display 'Resection of Right Ovary, Percutaneous Endoscopic'
code "0GTH0ZZ": '0GTH0ZZ' from "ICD10PCS" display 'Resection of Left Ovary'
code "0GTH4ZZ": '0GTH4ZZ' from "ICD10PCS" display 'Resection of Left Ovary, Percutaneous Endoscopic'
code "0GTK0ZZ": '0GTK0ZZ' from "ICD10PCS" display 'Resection of Bilateral Ovaries'
code "0GTK4ZZ": '0GTK4ZZ' from "ICD10PCS" display 'Resection of Bilateral Ovaries, Percutaneous Endoscopic'

// ICD-10-CM 主診斷碼條件
code "E00": 'E00' from "ICD10CM" display 'Congenital iodine-deficiency syndrome'
code "E01": 'E01' from "ICD10CM" display 'Iodine-deficiency related thyroid disorders'
code "E02": 'E02' from "ICD10CM" display 'Subclinical iodine-deficiency hypothyroidism'
code "E03": 'E03' from "ICD10CM" display 'Other hypothyroidism'
code "E04": 'E04' from "ICD10CM" display 'Other nontoxic goiter'
code "E05": 'E05' from "ICD10CM" display 'Thyrotoxicosis [hyperthyroidism]'
code "E06": 'E06' from "ICD10CM" display 'Thyroiditis'
code "E07": 'E07' from "ICD10CM" display 'Other disorders of thyroid'
code "E35": 'E35' from "ICD10CM" display 'Disorders of endocrine glands in diseases classified elsewhere'
code "E89.0": 'E89.0' from "ICD10CM" display 'Postprocedural hypothyroidism'

// NHI 甲狀腺手術相關醫令代碼
code "82001C": '82001C' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "82002C": '82002C' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "82003C": '82003C' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "82004B": '82004B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "82008B": '82008B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "82015B": '82015B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "82016B": '82016B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "66012B": '66012B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "66013B": '66013B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "66014B": '66014B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'
code "66023B": '66023B' from "NHI_PROCEDURE" display '甲狀腺手術相關醫令'

// (3) 主處置代碼(ICD-10-PCS手術代碼) - 第三組（疝氣修補、關節置換等）
code "0SR9019": '0SR9019' from "ICD10PCS" display 'Replacement of Right Hip Joint with Liner, Open Approach'
code "0SR901A": '0SR901A' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Cemented, Open Approach'
code "0SR901Z": '0SR901Z' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Open Approach'
code "0SR9029": '0SR9029' from "ICD10PCS" display 'Replacement of Right Hip Joint with Metal on Polyethylene, Open Approach'
code "0SR902A": '0SR902A' from "ICD10PCS" display 'Replacement of Right Hip Joint with Metal on Polyethylene, Cemented, Open Approach'
code "0SR902Z": '0SR902Z' from "ICD10PCS" display 'Replacement of Right Hip Joint with Metal on Polyethylene, Open Approach'
code "0SR9039": '0SR9039' from "ICD10PCS" display 'Replacement of Right Hip Joint with Ceramic, Open Approach'
code "0SR903A": '0SR903A' from "ICD10PCS" display 'Replacement of Right Hip Joint with Ceramic, Cemented, Open Approach'
code "0SR903Z": '0SR903Z' from "ICD10PCS" display 'Replacement of Right Hip Joint with Ceramic, Open Approach'
code "0SR9049": '0SR9049' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Ceramic on Polyethylene, Open Approach'
code "0SR904A": '0SR904A' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Ceramic on Polyethylene, Cemented, Open Approach'
code "0SR904Z": '0SR904Z' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Ceramic on Polyethylene, Open Approach'
code "0SR907Z": '0SR907Z' from "ICD10PCS" display 'Replacement of Right Hip Joint with Autologous Tissue Substitute, Open Approach'
code "0SR90J9": '0SR90J9' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Oxidized Zirconium on Polyethylene, Open Approach'
code "0SR90JA": '0SR90JA' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Oxidized Zirconium on Polyethylene, Cemented, Open Approach'
code "0SR90JZ": '0SR90JZ' from "ICD10PCS" display 'Replacement of Right Hip Joint with Synthetic Substitute, Oxidized Zirconium on Polyethylene, Open Approach'
code "0SR90KZ": '0SR90KZ' from "ICD10PCS" display 'Replacement of Right Hip Joint with Nonautologous Tissue Substitute, Open Approach'
code "0SRB019": '0SRB019' from "ICD10PCS" display 'Replacement of Left Hip Joint with Liner, Open Approach'
code "0SRB01A": '0SRB01A' from "ICD10PCS" display 'Replacement of Left Hip Joint with Synthetic Substitute, Cemented, Open Approach'
code "0SRB01Z": '0SRB01Z' from "ICD10PCS" display 'Replacement of Left Hip Joint with Synthetic Substitute, Open Approach'
code "0SRB029": '0SRB029' from "ICD10PCS" display 'Replacement of Left Hip Joint with Metal on Polyethylene, Open Approach'
code "0SRB02A": '0SRB02A' from "ICD10PCS" display 'Replacement of Left Hip Joint with Metal on Polyethylene, Cemented, Open Approach'
code "0SRB02Z": '0SRB02Z' from "ICD10PCS" display 'Replacement of Left Hip Joint with Metal on Polyethylene, Open Approach'
code "0SRB039": '0SRB039' from "ICD10PCS" display 'Replacement of Left Hip Joint with Ceramic, Open Approach'
code "0SRB03A": '0SRB03A' from "ICD10PCS" display 'Replacement of Left Hip Joint with Ceramic, Cemented, Open Approach'
code "0SRB03Z": '0SRB03Z' from "ICD10PCS" display 'Replacement of Left Hip Joint with Ceramic, Open Approach'
code "0SRB049": '0SRB049' from "ICD10PCS" display 'Replacement of Left Hip Joint with Ceramic on Polyethylene, Open Approach'
code "0SRB04A": '0SRB04A' from "ICD10PCS" display 'Replacement of Left Hip Joint with Ceramic on Polyethylene, Cemented, Open Approach'
code "0SRB04Z": '0SRB04Z' from "ICD10PCS" display 'Replacement of Left Hip Joint with Ceramic on Polyethylene, Open Approach'
code "0SRB07Z": '0SRB07Z' from "ICD10PCS" display 'Replacement of Left Hip Joint with Autologous Tissue Substitute, Open Approach'
code "0SRB0JA": '0SRB0JA' from "ICD10PCS" display 'Replacement of Left Hip Joint with Synthetic Substitute, Oxidized Zirconium, Cemented, Open Approach'
code "0SRC07Z": '0SRC07Z' from "ICD10PCS" display 'Replacement of Right Knee Joint with Autologous Tissue Substitute, Open Approach'
code "0SRC0J9": '0SRC0J9' from "ICD10PCS" display 'Replacement of Right Knee Joint with Synthetic Substitute, Cemented, Open Approach'
code "0SRC0JA": '0SRC0JA' from "ICD10PCS" display 'Replacement of Right Knee Joint with Synthetic Substitute, Cemented, Open Approach'
code "0SRC0JZ": '0SRC0JZ' from "ICD10PCS" display 'Replacement of Right Knee Joint with Synthetic Substitute, Open Approach'
code "0SRC0KZ": '0SRC0KZ' from "ICD10PCS" display 'Replacement of Right Knee Joint with Nonautologous Tissue Substitute, Open Approach'
code "0SRD0J9": '0SRD0J9' from "ICD10PCS" display 'Replacement of Left Knee Joint with Synthetic Substitute, Cemented, Open Approach'
code "0SRD0JA": '0SRD0JA' from "ICD10PCS" display 'Replacement of Left Knee Joint with Synthetic Substitute, Cemented, Open Approach'
code "0SRD0JZ": '0SRD0JZ' from "ICD10PCS" display 'Replacement of Left Knee Joint with Synthetic Substitute, Open Approach'
code "0SRDKZ": '0SRDKZ' from "ICD10PCS" display 'Replacement of Left Knee Joint with Nonautologous Tissue Substitute'
code "0SRT07Z": '0SRT07Z' from "ICD10PCS" display 'Replacement of Right Knee Joint, Femoral Surface with Autologous Tissue Substitute, Open Approach'
code "0SRT0J9": '0SRT0J9' from "ICD10PCS" display 'Replacement of Right Knee Joint, Femoral Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRT0JA": '0SRT0JA' from "ICD10PCS" display 'Replacement of Right Knee Joint, Femoral Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRT0JZ": '0SRT0JZ' from "ICD10PCS" display 'Replacement of Right Knee Joint, Femoral Surface with Synthetic Substitute, Open Approach'
code "0SRT0KZ": '0SRT0KZ' from "ICD10PCS" display 'Replacement of Right Knee Joint, Femoral Surface with Nonautologous Tissue Substitute, Open Approach'
code "0SRU07Z": '0SRU07Z' from "ICD10PCS" display 'Replacement of Left Knee Joint, Femoral Surface with Autologous Tissue Substitute, Open Approach'
code "0SRU0J9": '0SRU0J9' from "ICD10PCS" display 'Replacement of Left Knee Joint, Femoral Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRU0JA": '0SRU0JA' from "ICD10PCS" display 'Replacement of Left Knee Joint, Femoral Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRU0JZ": '0SRU0JZ' from "ICD10PCS" display 'Replacement of Left Knee Joint, Femoral Surface with Synthetic Substitute, Open Approach'
code "0SRU0KZ": '0SRU0KZ' from "ICD10PCS" display 'Replacement of Left Knee Joint, Femoral Surface with Nonautologous Tissue Substitute, Open Approach'
code "0SRV07Z": '0SRV07Z' from "ICD10PCS" display 'Replacement of Right Knee Joint, Tibial Surface with Autologous Tissue Substitute, Open Approach'
code "0SRV0J9": '0SRV0J9' from "ICD10PCS" display 'Replacement of Right Knee Joint, Tibial Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRV0JA": '0SRV0JA' from "ICD10PCS" display 'Replacement of Right Knee Joint, Tibial Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRV0JZ": '0SRV0JZ' from "ICD10PCS" display 'Replacement of Right Knee Joint, Tibial Surface with Synthetic Substitute, Open Approach'
code "0SRV0KZ": '0SRV0KZ' from "ICD10PCS" display 'Replacement of Right Knee Joint, Tibial Surface with Nonautologous Tissue Substitute, Open Approach'
code "0SRW07Z": '0SRW07Z' from "ICD10PCS" display 'Replacement of Left Knee Joint, Tibial Surface with Autologous Tissue Substitute, Open Approach'
code "0SRW0J9": '0SRW0J9' from "ICD10PCS" display 'Replacement of Left Knee Joint, Tibial Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRW0JA": '0SRW0JA' from "ICD10PCS" display 'Replacement of Left Knee Joint, Tibial Surface with Synthetic Substitute, Cemented, Open Approach'
code "0SRW0JZ": '0SRW0JZ' from "ICD10PCS" display 'Replacement of Left Knee Joint, Tibial Surface with Synthetic Substitute, Open Approach'
code "0SRW0KZ": '0SRW0KZ' from "ICD10PCS" display 'Replacement of Left Knee Joint, Tibial Surface with Nonautologous Tissue Substitute, Open Approach'

// NHI 疝氣修補相關醫令代碼
code "64162B": '64162B' from "NHI_PROCEDURE" display '疝氣修補相關醫令'
code "64164B": '64164B' from "NHI_PROCEDURE" display '疝氣修補相關醫令'
code "64169B": '64169B' from "NHI_PROCEDURE" display '疝氣修補相關醫令'
code "64170B": '64170B' from "NHI_PROCEDURE" display '疝氣修補相關醫令'

// 傷口感染：診斷碼全碼為K6811、R5084、T80211A-T80219A、T80222XA、T81302A-T8622A、T86842等
code "K6811": 'K6811' from "ICD10CM" display 'Postprocedural retroperitoneal abscess'
code "R5084": 'R5084' from "ICD10CM" display 'Febrile nonhemolytic transfusion reaction'
code "T80211A": 'T80211A' from "ICD10CM" display 'Bloodstream infection due to central venous catheter, initial encounter'
code "T80212A": 'T80212A' from "ICD10CM" display 'Local infection due to central venous catheter, initial encounter'
code "T80218A": 'T80218A' from "ICD10CM" display 'Other infection due to central venous catheter, initial encounter'
code "T80219A": 'T80219A' from "ICD10CM" display 'Unspecified infection due to central venous catheter, initial encounter'
code "T80222XA": 'T80222XA' from "ICD10CM" display 'Infection due to immunization, initial encounter'
code "T81302A": 'T81302A' from "ICD10CM" display 'Disruption of external operation wound, unspecified, initial encounter'
code "T81303XA": 'T81303XA' from "ICD10CM" display 'Disruption of traumatic injury wound repair, initial encounter'
code "T81304XA": 'T81304XA' from "ICD10CM" display 'Disruption of external operation wound, not elsewhere classified, initial encounter'
code "T81351XA": 'T81351XA' from "ICD10CM" display 'Infection following a procedure, superficial incisional surgical site, initial encounter'
code "T81359XA": 'T81359XA' from "ICD10CM" display 'Infection following a procedure, unspecified, initial encounter'
code "T82451XA": 'T82451XA' from "ICD10CM" display 'Breakdown (mechanical) of aortic graft, initial encounter'
code "T82452XA": 'T82452XA' from "ICD10CM" display 'Breakdown (mechanical) of femoral arterial graft, initial encounter'
code "T82453XA": 'T82453XA' from "ICD10CM" display 'Breakdown (mechanical) of other vascular grafts, initial encounter'
code "T8459XA": 'T8459XA' from "ICD10CM" display 'Infection and inflammatory reaction due to other genitourinary device, initial encounter'
code "T84600XA": 'T84600XA' from "ICD10CM" display 'Infection and inflammatory reaction due to unspecified internal joint prosthesis, initial encounter'
code "T84610A": 'T84610A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal right hip prosthesis, initial encounter'
code "T84611A": 'T84611A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal left hip prosthesis, initial encounter'
code "T84612A": 'T84612A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal right knee prosthesis, initial encounter'
code "T84613A": 'T84613A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal left knee prosthesis, initial encounter'
code "T84615A": 'T84615A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal left shoulder prosthesis, initial encounter'
code "T84619A": 'T84619A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal prosthetic joint, unspecified, initial encounter'
code "T84620A": 'T84620A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right humerus, initial encounter'
code "T84621A": 'T84621A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left humerus, initial encounter'
code "T84622A": 'T84622A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right radius, initial encounter'
code "T84623A": 'T84623A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left radius, initial encounter'
code "T84624A": 'T84624A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right ulna, initial encounter'
code "T84625A": 'T84625A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left ulna, initial encounter'
code "T84629A": 'T84629A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of unspecified bone of arm, initial encounter'
code "T84633XA": 'T84633XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of tibia, initial encounter'
code "T84639XA": 'T84639XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of unspecified bone of leg, initial encounter'
code "T84699XA": 'T84699XA' from "ICD10CM" display 'Infection and inflammatory reaction due to other internal orthopedic prosthetic devices, implants and grafts, initial encounter'
code "T8571XA": 'T8571XA' from "ICD10CM" display 'Infection and inflammatory reaction due to peritoneal dialysis catheter, initial encounter'
code "T8572XA": 'T8572XA' from "ICD10CM" display 'Infection and inflammatory reaction due to insulin pump, initial encounter'
code "T8579XA": 'T8579XA' from "ICD10CM" display 'Infection and inflammatory reaction due to other internal prosthetic devices, implants and grafts, initial encounter'
code "T86842": 'T86842' from "ICD10CM" display 'Corneal transplant infection'

context Patient

// Helper function: check if code value is in list
define function CodeInList(codeValue String, codeList List<String>):
  codeValue in codeList

// 1. 執行清淨手術之人數 (Denominator)
define "Clean Surgery Procedures":
  [Procedure] P
    where P.status.value = 'completed'
    and (
      // 條件1: NHI 清淨手術醫令代碼（第一組）
      exists (
        P.code.coding C 
          where CodeInList(C.code.value, {'75607C', '75610B', '75613C', '75614C', '75615C', '88029C'})
      )
      // 條件2: ICD-10-PCS 手術代碼（第一組：乳房、卵巢手術）
      or exists (
        P.code.coding C 
          where CodeInList(C.code.value, {
            '0YQ50ZZ', '0YQ537Z', '0YQ54ZZ', '0YQ60ZZ', '0YQ637Z', '0YQ74ZZ',
            '0YQ80ZZ', '0YQ83ZZ', '0YQ8C0Z', '0YQ8C3Z', '0YQ8C4Z',
            '0YQA0ZZ', '0YQA4ZZ', '0YQE0ZZ', '0YQE3ZZ', '0YQE4ZZ'
          })
      )
      // 條件3: ICD-10-PCS + ICD-10-CM 組合（第二組：甲狀腺手術）
      or (
        exists (
          P.code.coding C 
            where CodeInList(C.code.value, {
              '0GBG0ZZ', '0GBG3ZZ', '0GBG4ZZ', '0GBH0ZZ', '0GBH3ZZ', '0GBH4ZZ',
              '0GTG0ZZ', '0GTG4ZZ', '0GTH0ZZ', '0GTH4ZZ', '0GTK0ZZ', '0GTK4ZZ'
            })
        )
        and exists (
          [Condition] Cond
            where Cond.subject.reference.value = P.subject.reference.value
            and exists (
              Cond.code.coding CD 
                where CodeInList(CD.code.value, {
                  'E00', 'E01', 'E02', 'E03', 'E04', 'E05', 'E06', 'E07', 'E35', 'E89.0'
                })
            )
        )
      )
      // 條件3-NHI: 甲狀腺手術醫令代碼
      or exists (
        P.code.coding C 
          where CodeInList(C.code.value, {
            '82001C', '82002C', '82003C', '82004B', '82008B', '82015B', '82016B',
            '66012B', '66013B', '66014B', '66023B'
          })
      )
      // 條件4: 疝氣修補、關節置換等（第三組）
      or exists (
        P.code.coding C 
          where CodeInList(C.code.value, {
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
          })
      )
      // 條件4-NHI: 疝氣修補醫令代碼
      or exists (
        P.code.coding C 
          where CodeInList(C.code.value, {
            '64162B', '64164B', '64169B', '64170B'
          })
      )
    )

// 2. 執行清淨手術且傷口感染之人數 (Numerator)
// 2. 執行清淨手術且傷口感染之人數 (Numerator)
define "Clean Surgery With Wound Infection":
  "Clean Surgery Procedures" CSP
    where exists (
      [Condition] C
        where C.subject.reference.value = CSP.subject.reference.value
        and exists (
          C.code.coding CD 
            where CodeInList(CD.code.value, {
              'K6811', 'R5084', 'T80211A', 'T80212A', 'T80218A', 'T80219A',
              'T80222XA', 'T81302A', 'T81303XA', 'T81304XA', 'T81351XA', 'T81359XA',
              'T82451XA', 'T82452XA', 'T82453XA', 'T8459XA',
              'T84600XA', 'T84610A', 'T84611A', 'T84612A', 'T84613A', 'T84615A', 'T84619A',
              'T84620A', 'T84621A', 'T84622A', 'T84623A', 'T84624A', 'T84625A', 'T84629A',
              'T84633XA', 'T84639XA', 'T84699XA',
              'T8571XA', 'T8572XA', 'T8579XA', 'T86842'
            })
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
    (ToDecimal("Numerator") / ToDecimal("Denominator")) * 100
  else
    null
