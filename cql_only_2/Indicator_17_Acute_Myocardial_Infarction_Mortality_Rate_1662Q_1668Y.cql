library Indicator_17_Acute_Myocardial_Infarction_Mortality_Rate_1662Q_1668Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付檔案案分析系統 指標代碼: 1662(季)、1668(年)
// 條件依據：急性心肌梗塞死亡率
// 製作日期：2025-11-20

// ICD-10-CM 急性心肌梗塞診斷代碼：I21.* 和 I22.* 系列
// NHI 轉歸代碼：4(死亡)、A(病危自動出院)

context Patient

// 1. 18歲以上且主診斷為急性心肌梗塞的住院+門診案件數 (Denominator)
define "AMI Patients Over 18":
  [Condition] C
    where exists (
      C.code.coding CD 
        where CD.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
        and CD.code.value in {
          'I21', 'I21.0', 'I21.01', 'I21.02', 'I21.09',
          'I21.1', 'I21.11', 'I21.19',
          'I21.2', 'I21.21', 'I21.29',
          'I21.3', 'I21.4', 'I21.9',
          'I21.A', 'I21.A1', 'I21.A9', 'I21.B',
          'I22', 'I22.0', 'I22.1', 'I22.2', 'I22.8', 'I22.9'
        }
    )
    and exists (
      [Patient] P
        where P.id.value = Last(Split(C.subject.reference.value, '/'))
        and AgeInYearsAt(Today()) >= 18
    )
    and exists (
      [Encounter] E
        where E.id.value = Last(Split(C.encounter.reference.value, '/'))
        and (E.class.code.value = 'IMP' or E.class.code.value = 'AMB')
    )

// 2. 分母病患死亡個案數 (Numerator)
define "AMI Deaths":
  "AMI Patients Over 18" AMI
    where (
      exists (
        [Patient] P
          where P.id.value = Last(Split(AMI.subject.reference.value, '/'))
          and P.deceased is not null
          and (
            (P.deceased is FHIR.boolean and (P.deceased as FHIR.boolean).value = true)
            or (P.deceased is FHIR.dateTime and (P.deceased as FHIR.dateTime).value is not null)
          )
      )
      or exists (
        [Encounter] E
          where E.id.value = Last(Split(AMI.encounter.reference.value, '/'))
          and E.class.code.value = 'IMP'
          and exists (
            E.extension EXT
              where EXT.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/tran-code'
              and (EXT.value as FHIR.string).value in {'4', 'A'}
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
    ("Numerator" / "Denominator") * 100
  else
    null
