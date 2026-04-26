library Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 1662(季)、1668(年)
// 條件依據：急性心肌梗塞死亡率
// 製作日期：2025-11-20

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "NHI_TRAN_CODE": 'http://www.nhi.gov.tw/tran-code'

// ICD-10-CM 急性心肌梗塞診斷代碼（主診斷）
code "I21": 'I21' from "ICD10CM" display 'Acute myocardial infarction'
code "I22": 'I22' from "ICD10CM" display 'Subsequent ST elevation (STEMI) and non-ST elevation (NSTEMI) myocardial infarction'

// 更詳細的 I21 子代碼
code "I21.0": 'I21.0' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction of anterior wall'
code "I21.01": 'I21.01' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction involving left main coronary artery'
code "I21.02": 'I21.02' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction involving left anterior descending coronary artery'
code "I21.09": 'I21.09' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction involving other coronary artery of anterior wall'
code "I21.1": 'I21.1' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction of inferior wall'
code "I21.11": 'I21.11' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction involving right coronary artery'
code "I21.19": 'I21.19' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction involving other coronary artery of inferior wall'
code "I21.2": 'I21.2' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction of other sites'
code "I21.21": 'I21.21' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction involving left circumflex coronary artery'
code "I21.29": 'I21.29' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction involving other sites'
code "I21.3": 'I21.3' from "ICD10CM" display 'ST elevation (STEMI) myocardial infarction of unspecified site'
code "I21.4": 'I21.4' from "ICD10CM" display 'Non-ST elevation (NSTEMI) myocardial infarction'
code "I21.9": 'I21.9' from "ICD10CM" display 'Acute myocardial infarction, unspecified'
code "I21.A": 'I21.A' from "ICD10CM" display 'Myocardial infarction type 2'
code "I21.A1": 'I21.A1' from "ICD10CM" display 'Myocardial infarction type 2'
code "I21.A9": 'I21.A9' from "ICD10CM" display 'Other myocardial infarction type'
code "I21.B": 'I21.B' from "ICD10CM" display 'Myocardial infarction with coronary microvascular dysfunction'

// I22 子代碼
code "I22.0": 'I22.0' from "ICD10CM" display 'Subsequent ST elevation (STEMI) myocardial infarction of anterior wall'
code "I22.1": 'I22.1' from "ICD10CM" display 'Subsequent ST elevation (STEMI) myocardial infarction of inferior wall'
code "I22.2": 'I22.2' from "ICD10CM" display 'Subsequent non-ST elevation (NSTEMI) myocardial infarction'
code "I22.8": 'I22.8' from "ICD10CM" display 'Subsequent ST elevation (STEMI) myocardial infarction of other sites'
code "I22.9": 'I22.9' from "ICD10CM" display 'Subsequent ST elevation (STEMI) myocardial infarction of unspecified site'

// NHI 轉歸代碼
code "TRAN_CODE_4": '4' from "NHI_TRAN_CODE" display '死亡'
code "TRAN_CODE_A": 'A' from "NHI_TRAN_CODE" display '病危自動出院'
// Helper function
define function CodeInList(codeValue String, codeList List<String>):
  codeValue in codeList

context Patient
// 1. 18歲以上且主診斷為急性心肌梗塞的住院+門診案件數 (Denominator)
define "AMI Patients Over 18":
  [Condition] C
    where exists (
      C.code.coding CD 
        where CodeInList(CD.code.value, {
          'I21', 'I21.0', 'I21.01', 'I21.02', 'I21.09',
          'I21.1', 'I21.11', 'I21.19',
          'I21.2', 'I21.21', 'I21.29',
          'I21.3', 'I21.4', 'I21.9',
          'I21.A', 'I21.A1', 'I21.A9', 'I21.B',
          'I22', 'I22.0', 'I22.1', 'I22.2', 'I22.8', 'I22.9'
        })
    )
    and exists (
      [Patient] P
        where ('Patient/' + P.id.value) = C.subject.reference.value
        and AgeInYearsAt(Today()) >= 18
    )
    and exists (
      [Encounter] E
        where E.subject.reference.value = C.subject.reference.value
        and (E.class.code.value = 'IMP' or E.class.code.value = 'AMB')
    )

// 2. 分母病患死亡個案數 (Numerator)
// 死亡：門住診勾稽保資料保險對象資訊檔註記為死亡者；住院再依院所、ID、生日、住院日歸戶下有任一件之轉歸代碼(TRAN_CODE)為4(死亡)、A(病危自動出院)，也視為死亡者
define "AMI Deaths":
  "AMI Patients Over 18" AMI
    where (
      // 方法1: 病患死亡旗標
      exists (
        [Patient] P
          where ('Patient/' + P.id.value) = AMI.subject.reference.value
          and P.deceased is not null
          and (
            (P.deceased is FHIR.boolean and (P.deceased as FHIR.boolean).value = true)
            or P.deceased is FHIR.dateTime
          )
      )
      // 方法2: 轉歸代碼為死亡或病危自動出院（住院案件）
      or exists (
        [Encounter] E
          where E.subject.reference.value = AMI.subject.reference.value
          and E.class.code.value = 'IMP'
          and exists (
            E.extension EXT
              where EXT.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/tran-code'
              and (
                (EXT.value as FHIR.string).value = '4'
                or (EXT.value as FHIR.string).value = 'A'
              )
          )
      )
    )

// 3. 分母：18歲以上且主診斷為急性心肌梗塞的病患數
define "Denominator":
  Count(
    distinct "AMI Patients Over 18" AMI
      return AMI.subject.reference
  )

// 4. 分子：分母病患死亡個案數
define "Numerator":
  Count(
    distinct "AMI Deaths" D
      return D.subject.reference
  )

// 5. 指標計算結果
define "Mortality Rate":
  if "Denominator" > 0 then
    (ToDecimal("Numerator") / ToDecimal("Denominator")) * 100
  else
    null
