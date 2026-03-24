library Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 2795(季)、2796(年)
// 條件依據：失智者使用安寧緩和服務使用率
// 製作日期：2025-11-20

// ICD-10-CM 失智症診斷代碼：F01-F03, G30-G31, F1027等系列
// NHI 安寧照護醫令代碼：05601K-05603B, P4401B-P4403B, 05312C-05374C

context Patient

// 1. 失智症病人數 (Denominator)
define "Dementia Patients":
  [Condition] C
    where exists (
      C.code.coding CD 
        where CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
        and CD.code.value in {
          'F01', 'F02', 'F03',
          'G30', 'G30.0', 'G30.1', 'G30.8', 'G30.9',
          'G31',
          'F1027', 'F1097', 'F1327', 'F1397',
          'F1827', 'F1897', 'F1927', 'F1997'
        }
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(C.encounter.reference.value, '/'))
        and (E.class.code.value = 'IMP' or E.class.code.value = 'AMB')
    )

// 2. 分母病人使用安寧緩和服務的人數 (Numerator)
define "Dementia Patients Using Hospice Care":
  "Dementia Patients" DP
    where exists (
      [Procedure] P
        where Last(Split(P.subject.reference.value, '/')) = Last(Split(DP.subject.reference.value, '/'))
        and P.status.value = 'completed'
        and exists (
          P.code.coding C
            where C.system.value = 'http://www.nhi.gov.tw/codes'
            and C.code.value in {
              '05601K', '05602A', '05603B',
              'P4401B', 'P4402B', 'P4403B',
              '05312C', '05316C', '05323C', '05327C',
              '05336C', '05341C', '05362C', '05374C'
            }
        )
    )

// 3. 分母：失智症病人數
define "Denominator":
  Count(
    distinct "Dementia Patients" DP
      return DP.subject.reference
  )

// 4. 分子：分母病人使用安寧緩和服務的人數
define "Numerator":
  Count(
    distinct "Dementia Patients Using Hospice Care" DPUHC
      return DPUHC.subject.reference
  )

// 5. 指標計算結果
define "Utilization Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null
