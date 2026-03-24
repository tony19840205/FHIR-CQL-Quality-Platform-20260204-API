library Indicator_16_Inpatient_Surgical_Wound_Infection_Rate_1658Q_1666Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 1658(季)、1666(年)
// 條件依據：住院手術傷口感染率
// 製作日期：2025-11-20

// NHI 手術代碼：醫令代碼全長6碼且前2碼為62-88及97者
// ICD-10-CM 傷口感染診斷代碼：共151個代碼，直接在函數中使用字串比對

context Patient

// 1. 住院手術案件 (Denominator)
define "Inpatient Surgical Procedures":
  [Procedure] P
    where P.status.value = 'completed'
    and exists (
      P.code.coding C
        where C.system.value = 'http://www.nhi.gov.tw/codes'
        and Length(C.code.value) = 6
        and (
          Substring(C.code.value, 0, 2) in {
            '62', '63', '64', '65', '66', '67', '68', '69',
            '70', '71', '72', '73', '74', '75', '76', '77', '78', '79',
            '80', '81', '82', '83', '84', '85', '86', '87', '88', '97'
          }
        )
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(P.encounter.reference.value, '/'))
        and E.class.code.value = 'IMP'
    )

// 2. 手術傷口感染人數 (Numerator)
define "Surgical Wound Infections":
  [Condition] C
    where exists (
      C.code.coding CD 
        where CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
        and CD.code.value in {
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
        }
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(C.encounter.reference.value, '/'))
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
    ("Numerator" / "Denominator") * 100
  else
    null
