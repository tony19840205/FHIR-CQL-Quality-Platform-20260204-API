library Indicator_18_Dementia_Hospice_Care_Utilization_Rate_2795Q_2796Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 2795(季)、2796(年)
// 條件依據：失智者使用安寧緩和服務使用率
// 製作日期：2025-11-20

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// ICD-10-CM 失智症診斷代碼（主、次診斷碼）
// F01-F03 系列
code "F01": 'F01' from "ICD10CM" display 'Vascular dementia'
code "F02": 'F02' from "ICD10CM" display 'Dementia in other diseases classified elsewhere'
code "F03": 'F03' from "ICD10CM" display 'Unspecified dementia'

// G30 系列 - Alzheimer disease
code "G30": 'G30' from "ICD10CM" display 'Alzheimer disease'
code "G30.0": 'G30.0' from "ICD10CM" display 'Alzheimer disease with early onset'
code "G30.1": 'G30.1' from "ICD10CM" display 'Alzheimer disease with late onset'
code "G30.8": 'G30.8' from "ICD10CM" display 'Other Alzheimer disease'
code "G30.9": 'G30.9' from "ICD10CM" display 'Alzheimer disease, unspecified'

// G31 系列
code "G31": 'G31' from "ICD10CM" display 'Other degenerative diseases of nervous system, not elsewhere classified'

// F1027, F1097, F1327, F1397, F1827, F1897, F1927, F1997 系列
code "F1027": 'F1027' from "ICD10CM" display 'Alcohol dependence with alcohol-induced persisting dementia'
code "F1097": 'F1097' from "ICD10CM" display 'Alcohol use, unspecified with alcohol-induced persisting dementia'
code "F1327": 'F1327' from "ICD10CM" display 'Sedative, hypnotic or anxiolytic dependence with sedative, hypnotic or anxiolytic-induced persisting dementia'
code "F1397": 'F1397' from "ICD10CM" display 'Sedative, hypnotic or anxiolytic use, unspecified with sedative, hypnotic or anxiolytic-induced persisting dementia'
code "F1827": 'F1827' from "ICD10CM" display 'Inhalant dependence with inhalant-induced persisting dementia'
code "F1897": 'F1897' from "ICD10CM" display 'Inhalant use, unspecified with inhalant-induced persisting dementia'
code "F1927": 'F1927' from "ICD10CM" display 'Other psychoactive substance dependence with psychoactive substance-induced persisting dementia'
code "F1997": 'F1997' from "ICD10CM" display 'Other psychoactive substance use, unspecified with psychoactive substance-induced persisting dementia'

// NHI 安寧照護醫令代碼
code "05601K": '05601K' from "NHI_PROCEDURE" display '安寧住院照護醫令'
code "05602A": '05602A' from "NHI_PROCEDURE" display '安寧住院照護醫令'
code "05603B": '05603B' from "NHI_PROCEDURE" display '安寧住院照護醫令'

// NHI 全民健康保險安寧共同照護試辦方案醫令代碼
code "P4401B": 'P4401B' from "NHI_PROCEDURE" display '全民健康保險安寧共同照護試辦方案醫令'
code "P4402B": 'P4402B' from "NHI_PROCEDURE" display '全民健康保險安寧共同照護試辦方案醫令'
code "P4403B": 'P4403B' from "NHI_PROCEDURE" display '全民健康保險安寧共同照護試辦方案醫令'

// NHI 安寧居家療護醫令代碼
code "05312C": '05312C' from "NHI_PROCEDURE" display '安寧居家療護醫令'
code "05316C": '05316C' from "NHI_PROCEDURE" display '安寧居家療護醫令'
code "05323C": '05323C' from "NHI_PROCEDURE" display '安寧居家療護醫令'
code "05327C": '05327C' from "NHI_PROCEDURE" display '安寧居家療護醫令'
code "05336C": '05336C' from "NHI_PROCEDURE" display '安寧居家療護醫令'
code "05341C": '05341C' from "NHI_PROCEDURE" display '安寧居家療護醫令'
code "05362C": '05362C' from "NHI_PROCEDURE" display '安寧居家療護醫令'
code "05374C": '05374C' from "NHI_PROCEDURE" display '安寧居家療護醫令'

// Helper function
define function CodeInList(codeValue String, codeList List<String>):
  codeValue in codeList

context Patient

// 1. 失智症病人數 (Denominator)
// 每季所有屬醫院總額之門住診及門診其他醫療機構案件，排除代辦案件
define "Dementia Patients":
  [Condition] C
    where exists (
      C.code.coding CD 
        where CodeInList(CD.code.value, {
          'F01', 'F02', 'F03',
          'G30', 'G30.0', 'G30.1', 'G30.8', 'G30.9',
          'G31',
          'F1027', 'F1097', 'F1327', 'F1397',
          'F1827', 'F1897', 'F1927', 'F1997'
        })
    )
    and exists (
      [Encounter] E
        where E.subject.reference.value = C.subject.reference.value
        and (E.class.code.value = 'IMP' or E.class.code.value = 'AMB')
    )

// 2. 分母病人使用安寧緩和服務的人數 (Numerator)
define "Dementia Patients Using Hospice Care":
  "Dementia Patients" DP
    where exists (
      [Procedure] P
        where P.subject.reference.value = DP.subject.reference.value
        and P.status.value = 'completed'
        and exists (
          P.code.coding C
            where CodeInList(C.code.value, {
              '05601K', '05602A', '05603B',
              'P4401B', 'P4402B', 'P4403B',
              '05312C', '05316C', '05323C', '05327C',
              '05336C', '05341C', '05362C', '05374C'
            })
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
    (ToDecimal("Numerator") / ToDecimal("Denominator")) * 100
  else
    null
