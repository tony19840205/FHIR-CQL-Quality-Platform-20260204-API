library Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 1658(季)、1666(年)
// 條件依據：住院手術傷口感染率
// 製作日期：2025-11-20

codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'

// NHI 手術代碼：醫令代碼全長6碼且前2碼為62-88及97者
// 這裡列出範圍，實際應包含所有62-88及97開頭的手術代碼

// ICD-10-CM 傷口感染診斷代碼
code "D78.01": 'D78.01' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a circulatory system organ or structure complicating a circulatory system procedure'
code "D78.02": 'D78.02' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a circulatory system organ or structure complicating other procedure'
code "D78.21": 'D78.21' from "ICD10CM" display 'Postprocedural hemorrhage of a circulatory system organ or structure following a circulatory system procedure'
code "D78.22": 'D78.22' from "ICD10CM" display 'Postprocedural hemorrhage of a circulatory system organ or structure following other procedure'

code "E36.01": 'E36.01' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of an endocrine system organ or structure complicating an endocrine system procedure'
code "E36.02": 'E36.02' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of an endocrine system organ or structure complicating other procedure'

code "G97.31": 'G97.31' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a nervous system organ or structure complicating a nervous system procedure'
code "G97.32": 'G97.32' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a nervous system organ or structure complicating other procedure'
code "G97.51": 'G97.51' from "ICD10CM" display 'Postprocedural hemorrhage of a nervous system organ or structure following a nervous system procedure'
code "G97.52": 'G97.52' from "ICD10CM" display 'Postprocedural hemorrhage of a nervous system organ or structure following other procedure'

code "H59.111": 'H59.111' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of right eye and adnexa complicating an ophthalmic procedure'
code "H59.112": 'H59.112' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of left eye and adnexa complicating an ophthalmic procedure'
code "H59.113": 'H59.113' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of eye and adnexa complicating an ophthalmic procedure, bilateral'
code "H59.119": 'H59.119' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of unspecified eye and adnexa complicating an ophthalmic procedure'
code "H59.121": 'H59.121' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of right eye and adnexa complicating other procedure'
code "H59.122": 'H59.122' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of left eye and adnexa complicating other procedure'
code "H59.123": 'H59.123' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of eye and adnexa complicating other procedure, bilateral'
code "H59.129": 'H59.129' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of unspecified eye and adnexa complicating other procedure'

code "H59.311": 'H59.311' from "ICD10CM" display 'Postprocedural hemorrhage of right eye and adnexa following an ophthalmic procedure'
code "H59.312": 'H59.312' from "ICD10CM" display 'Postprocedural hemorrhage of left eye and adnexa following an ophthalmic procedure'
code "H59.313": 'H59.313' from "ICD10CM" display 'Postprocedural hemorrhage of eye and adnexa following an ophthalmic procedure, bilateral'
code "H59.319": 'H59.319' from "ICD10CM" display 'Postprocedural hemorrhage of unspecified eye and adnexa following an ophthalmic procedure'
code "H59.321": 'H59.321' from "ICD10CM" display 'Postprocedural hemorrhage of right eye and adnexa following other procedure'
code "H59.322": 'H59.322' from "ICD10CM" display 'Postprocedural hemorrhage of left eye and adnexa following other procedure'
code "H59.323": 'H59.323' from "ICD10CM" display 'Postprocedural hemorrhage of eye and adnexa following other procedure, bilateral'
code "H59.329": 'H59.329' from "ICD10CM" display 'Postprocedural hemorrhage of unspecified eye and adnexa following other procedure'

code "H95.21": 'H95.21' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of ear and mastoid process complicating a procedure on the ear and mastoid process'
code "H95.22": 'H95.22' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of ear and mastoid process complicating other procedure'
code "H95.41": 'H95.41' from "ICD10CM" display 'Postprocedural hemorrhage of ear and mastoid process following a procedure on the ear and mastoid process'
code "H95.42": 'H95.42' from "ICD10CM" display 'Postprocedural hemorrhage of ear and mastoid process following other procedure'

code "I97.410": 'I97.410' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a circulatory system organ or structure complicating a cardiac catheterization'
code "I97.411": 'I97.411' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a circulatory system organ or structure complicating a cardiac bypass'
code "I97.418": 'I97.418' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a circulatory system organ or structure complicating other circulatory system procedure'

code "I97.42": 'I97.42' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a circulatory system organ or structure complicating other procedure'
code "I97.610": 'I97.610' from "ICD10CM" display 'Postprocedural hemorrhage of a circulatory system organ or structure following a cardiac catheterization'
code "I97.611": 'I97.611' from "ICD10CM" display 'Postprocedural hemorrhage of a circulatory system organ or structure following cardiac bypass'
code "I97.618": 'I97.618' from "ICD10CM" display 'Postprocedural hemorrhage of a circulatory system organ or structure following other circulatory system procedure'
code "I97.62": 'I97.62' from "ICD10CM" display 'Postprocedural hemorrhage, hematoma and seroma of a circulatory system organ or structure following other procedure'
code "I97.631": 'I97.631' from "ICD10CM" display 'Postprocedural hematoma of a circulatory system organ or structure following a circulatory system procedure'
code "I97.641": 'I97.641' from "ICD10CM" display 'Postprocedural seroma of a circulatory system organ or structure following a circulatory system procedure'

code "J95.61": 'J95.61' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a respiratory system organ or structure complicating a respiratory system procedure'
code "J95.62": 'J95.62' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a respiratory system organ or structure complicating other procedure'
code "J95.830": 'J95.830' from "ICD10CM" display 'Postprocedural hemorrhage of a respiratory system organ or structure following a respiratory system procedure'
code "J95.831": 'J95.831' from "ICD10CM" display 'Postprocedural hemorrhage of a respiratory system organ or structure following other procedure'

code "K68.11": 'K68.11' from "ICD10CM" display 'Postprocedural retroperitoneal abscess'
code "K91.61": 'K91.61' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a digestive system organ or structure complicating a digestive system procedure'
code "K91.62": 'K91.62' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a digestive system organ or structure complicating other procedure'
code "K91.840": 'K91.840' from "ICD10CM" display 'Postprocedural hemorrhage of a digestive system organ or structure following a digestive system procedure'
code "K91.841": 'K91.841' from "ICD10CM" display 'Postprocedural hemorrhage of a digestive system organ or structure following other procedure'

code "L76.01": 'L76.01' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of skin and subcutaneous tissue complicating a dermatologic procedure'
code "L76.02": 'L76.02' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of skin and subcutaneous tissue complicating other procedure'
code "L76.21": 'L76.21' from "ICD10CM" display 'Postprocedural hemorrhage of skin and subcutaneous tissue following a dermatologic procedure'
code "L76.22": 'L76.22' from "ICD10CM" display 'Postprocedural hemorrhage of skin and subcutaneous tissue following other procedure'

code "M96.810": 'M96.810' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a musculoskeletal structure complicating a musculoskeletal system procedure'
code "M96.811": 'M96.811' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a musculoskeletal structure complicating other procedure'
code "M96.830": 'M96.830' from "ICD10CM" display 'Postprocedural hemorrhage of a musculoskeletal structure following a musculoskeletal system procedure'
code "M96.831": 'M96.831' from "ICD10CM" display 'Postprocedural hemorrhage of a musculoskeletal structure following other procedure'

code "N99.61": 'N99.61' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a genitourinary system organ or structure complicating a genitourinary system procedure'
code "N99.62": 'N99.62' from "ICD10CM" display 'Intraoperative hemorrhage and hematoma of a genitourinary system organ or structure complicating other procedure'
code "N99.820": 'N99.820' from "ICD10CM" display 'Postprocedural hemorrhage of a genitourinary system organ or structure following a genitourinary system procedure'
code "N99.821": 'N99.821' from "ICD10CM" display 'Postprocedural hemorrhage of a genitourinary system organ or structure following other procedure'

code "R50.84": 'R50.84' from "ICD10CM" display 'Febrile nonhemolytic transfusion reaction'

code "T80.211A": 'T80.211A' from "ICD10CM" display 'Bloodstream infection due to central venous catheter, initial encounter'
code "T80.212A": 'T80.212A' from "ICD10CM" display 'Local infection due to central venous catheter, initial encounter'
code "T80.218A": 'T80.218A' from "ICD10CM" display 'Other infection due to central venous catheter, initial encounter'
code "T80.219A": 'T80.219A' from "ICD10CM" display 'Unspecified infection due to central venous catheter, initial encounter'
code "T80.22XA": 'T80.22XA' from "ICD10CM" display 'Infection due to immunization, initial encounter'

code "T81.30XA": 'T81.30XA' from "ICD10CM" display 'Disruption of wound, unspecified, initial encounter'
code "T81.31XA": 'T81.31XA' from "ICD10CM" display 'Disruption of external operation (surgical) wound, not elsewhere classified, initial encounter'
code "T81.32XA": 'T81.32XA' from "ICD10CM" display 'Disruption of internal operation (surgical) wound, not elsewhere classified, initial encounter'
code "T81.33XA": 'T81.33XA' from "ICD10CM" display 'Disruption of traumatic injury wound repair, initial encounter'

code "T81.4XXA": 'T81.4XXA' from "ICD10CM" display 'Infection following a procedure, initial encounter'

code "T82.6XXA": 'T82.6XXA' from "ICD10CM" display 'Infection and inflammatory reaction due to cardiac valve prosthesis, initial encounter'
code "T82.7XXA": 'T82.7XXA' from "ICD10CM" display 'Infection and inflammatory reaction due to other cardiac and vascular devices, implants and grafts, initial encounter'

code "T83.51XA": 'T83.51XA' from "ICD10CM" display 'Infection and inflammatory reaction due to indwelling urinary catheter, initial encounter'
code "T83.59XA": 'T83.59XA' from "ICD10CM" display 'Infection and inflammatory reaction due to prosthetic device, implant and graft in urinary system, initial encounter'

code "T83.6XXA": 'T83.6XXA' from "ICD10CM" display 'Infection and inflammatory reaction due to prosthetic device, implant and graft in genital tract, initial encounter'

code "T84.50XA": 'T84.50XA' from "ICD10CM" display 'Infection and inflammatory reaction due to unspecified internal joint prosthesis, initial encounter'
code "T84.51XA": 'T84.51XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal right hip prosthesis, initial encounter'
code "T84.52XA": 'T84.52XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal left hip prosthesis, initial encounter'
code "T84.53XA": 'T84.53XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal right knee prosthesis, initial encounter'
code "T84.54XA": 'T84.54XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal left knee prosthesis, initial encounter'
code "T84.59XA": 'T84.59XA' from "ICD10CM" display 'Infection and inflammatory reaction due to other internal joint prosthesis, initial encounter'
code "T84.60XA": 'T84.60XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of unspecified site, initial encounter'
code "T84.610A": 'T84.610A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right humerus, initial encounter'
code "T84.611A": 'T84.611A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left humerus, initial encounter'
code "T84.612A": 'T84.612A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right radius, initial encounter'
code "T84.613A": 'T84.613A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left radius, initial encounter'
code "T84.614A": 'T84.614A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right ulna, initial encounter'
code "T84.615A": 'T84.615A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left ulna, initial encounter'
code "T84.619A": 'T84.619A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of unspecified bone of arm, initial encounter'
code "T84.620A": 'T84.620A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right femur, initial encounter'
code "T84.621A": 'T84.621A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left femur, initial encounter'
code "T84.622A": 'T84.622A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right tibia, initial encounter'
code "T84.623A": 'T84.623A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left tibia, initial encounter'
code "T84.624A": 'T84.624A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of right fibula, initial encounter'
code "T84.625A": 'T84.625A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of left fibula, initial encounter'
code "T84.629A": 'T84.629A' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of unspecified bone of leg, initial encounter'

code "T84.63XA": 'T84.63XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of spine, initial encounter'
code "T84.69XA": 'T84.69XA' from "ICD10CM" display 'Infection and inflammatory reaction due to internal fixation device of other site, initial encounter'
code "T84.7XXA": 'T84.7XXA' from "ICD10CM" display 'Infection and inflammatory reaction due to other internal orthopedic prosthetic devices, implants and grafts, initial encounter'

code "T85.71XA": 'T85.71XA' from "ICD10CM" display 'Infection and inflammatory reaction due to peritoneal dialysis catheter, initial encounter'
code "T85.72XA": 'T85.72XA' from "ICD10CM" display 'Infection and inflammatory reaction due to insulin pump, initial encounter'
code "T85.79XA": 'T85.79XA' from "ICD10CM" display 'Infection and inflammatory reaction due to other internal prosthetic devices, implants and grafts, initial encounter'

code "T86.842": 'T86.842' from "ICD10CM" display 'Corneal transplant infection'
code "T88.8XXA": 'T88.8XXA' from "ICD10CM" display 'Other specified complications of surgical and medical care, not elsewhere classified, initial encounter'

// Helper function
define function CodeInList(codeValue String, codeList List<String>):
  codeValue in codeList

// Helper: check if NHI procedure code is surgical (prefix 62-88 or 97, length 6)
define function IsSurgicalCode(codeValue String):
  Length(codeValue) = 6
    and (
      (Substring(codeValue, 0, 2) >= '62' and Substring(codeValue, 0, 2) <= '88')
      or Substring(codeValue, 0, 2) = '97'
    )

context Patient

// 1. 住院手術案件數 (Denominator)
// 醫令代碼全長6碼且前2碼為62-88及97者
define "Inpatient Surgical Procedures":
  [Procedure] P
    where P.status.value = 'completed'
    and exists (
      P.code.coding C 
        where C.system.value = 'http://www.nhi.gov.tw/codes'
        and IsSurgicalCode(C.code.value)
    )
    and exists (
      [Encounter] E
        where E.subject.reference.value = P.subject.reference.value
        and E.class.code.value = 'IMP'
    )

// 2. 手術傷口感染人數 (Numerator)
define "Surgical Wound Infections":
  [Condition] C
    where exists (
      C.code.coding CD 
        where CodeInList(CD.code.value, {
          'D78.01', 'D78.02', 'D78.21', 'D78.22',
          'E36.01', 'E36.02',
          'G97.31', 'G97.32', 'G97.51', 'G97.52',
          'H59.111', 'H59.112', 'H59.113', 'H59.119', 'H59.121', 'H59.122', 'H59.123', 'H59.129',
          'H59.311', 'H59.312', 'H59.313', 'H59.319', 'H59.321', 'H59.322', 'H59.323', 'H59.329',
          'H95.21', 'H95.22', 'H95.41', 'H95.42',
          'I97.410', 'I97.411', 'I97.418', 'I97.42', 'I97.610', 'I97.611', 'I97.618', 'I97.62', 'I97.631', 'I97.641',
          'J95.61', 'J95.62', 'J95.830', 'J95.831',
          'K68.11', 'K91.61', 'K91.62', 'K91.840', 'K91.841',
          'L76.01', 'L76.02', 'L76.21', 'L76.22',
          'M96.810', 'M96.811', 'M96.830', 'M96.831',
          'N99.61', 'N99.62', 'N99.820', 'N99.821',
          'R50.84',
          'T80.211A', 'T80.212A', 'T80.218A', 'T80.219A', 'T80.22XA',
          'T81.30XA', 'T81.31XA', 'T81.32XA', 'T81.33XA', 'T81.4XXA',
          'T82.6XXA', 'T82.7XXA',
          'T83.51XA', 'T83.59XA', 'T83.6XXA',
          'T84.50XA', 'T84.51XA', 'T84.52XA', 'T84.53XA', 'T84.54XA', 'T84.59XA',
          'T84.60XA', 'T84.610A', 'T84.611A', 'T84.612A', 'T84.613A', 'T84.614A', 'T84.615A', 'T84.619A',
          'T84.620A', 'T84.621A', 'T84.622A', 'T84.623A', 'T84.624A', 'T84.625A', 'T84.629A',
          'T84.63XA', 'T84.69XA', 'T84.7XXA',
          'T85.71XA', 'T85.72XA', 'T85.79XA',
          'T86.842', 'T88.8XXA'
        })
    )
    and exists (
      [Encounter] E
        where E.subject.reference.value = C.subject.reference.value
        and E.class.code.value = 'IMP'
    )

// 3. 分母：每季所有住院手術案件數
define "Denominator":
  Count("Inpatient Surgical Procedures")

// 4. 分子：手術傷口感染人數
define "Numerator":
  Count(
    distinct "Surgical Wound Infections" SWI
      return SWI.subject.reference
  )

// 5. 指標計算結果
define "Infection Rate":
  if "Denominator" > 0 then
    (ToDecimal("Numerator") / ToDecimal("Denominator")) * 100
  else
    null
