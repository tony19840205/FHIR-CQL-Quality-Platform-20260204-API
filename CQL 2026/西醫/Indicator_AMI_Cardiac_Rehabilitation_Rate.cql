library Indicator_AMI_Cardiac_Rehabilitation_Rate version '1.0.0'

/*
急性心肌梗塞病人接受心臟復健比率
Acute Myocardial Infarction (AMI) Cardiac Rehabilitation Rate

計算說明:
- 分子：分母病人入院日起6個月內(含跨院住院及門診)期間接受心臟復健人次數
- 分母：18歲以上因急性心肌梗塞(AMI)入院治療的出院人次數
- 資料範圍：西醫醫院住院資料、門診資料
- 計算頻率：半年及年

備註:
1. 分母條件：出院日在統計期間18歲以上的急性心肌梗塞(AMI)案件，按【院所, ID, 生日, 住院日】歸戶，
   以最晚之出院日為代表案件
2. 18歲以上：（出院年-出生年）≥18
3. 急性心肌梗塞(AMI)：同次住院有任一筆主診斷ICD_10_CM Code前3碼為I21-I22、I5A，
   但若同次住院有任一筆主診斷為I214、I222，則該次住院全部排除
4. 分母排除條件：符合以下任一條件之同次住院全部排除
   a. 住院期間死亡(轉歸代碼為4)
   b. 病危自動出院(轉歸代碼為A)
   c. 出院前仍有以下任一情形，不適合極度踏車運動試驗及心臟復健，包括：
      (1) 心臟梗塞後仍有不穩定心絞痛
      (2) 非代償性心衰竭
      (3) 威脅生命的心臟心律不整
      (4) 嚴重限制的非心臟疾病導致無法從事運動試驗或運動訓練，例如：
          曾有腦中風、腦傷、脊髓損傷、失智症病史，具急性肝腎衰竭、血液動力學不穩定、敗血症等
5. 心臟復健：支付標準碼如下
   a. 物理治療-復雜治療(42014B或42019C)或(P7601P心肺疾病患者復健整合治療費)或
      (P5133B心臟衰竭急性後期物理治療-復雜治療)
   b. 物理治療項目代號-心肺功能訓練(PTC5)
6. 入院日起6個月內(含跨院住院及門診)期間：入院日+180天內
7. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-06)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 半年度期間定義
parameter "Period 1" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-06-30T23:59:59.0]

parameter "Period 2" Interval<DateTime>
  default Interval[@2026-07-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 入院後追蹤期間（6個月 = 180天）
parameter "Post Admission Follow Up Days" Integer default 180

// 年齡限制
parameter "Minimum Age" Integer default 18

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "TWProcedure": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
codesystem "DischargeDisposition": 'http://terminology.hl7.org/CodeSystem/discharge-disposition'

// AMI診斷碼定義 (I21, I22, I5A系列)
code "I21": 'I21' from "ICD10CM" display 'Acute myocardial infarction'
code "I22": 'I22' from "ICD10CM" display 'Subsequent ST elevation (STEMI) and non-ST elevation (NSTEMI) myocardial infarction'
code "I5A": 'I5A' from "ICD10CM" display 'Non-ischemic myocardial injury (non-traumatic)'

// AMI排除診斷碼 (NSTEMI)
code "I214": 'I214' from "ICD10CM" display 'Non-ST elevation (NSTEMI) myocardial infarction'
code "I222": 'I222' from "ICD10CM" display 'Subsequent non-ST elevation (NSTEMI) myocardial infarction'

// 排除條件診斷碼
// 不穩定心絞痛
code "I200": 'I200' from "ICD10CM" display 'Unstable angina'

// 心衰竭相關
code "I50": 'I50' from "ICD10CM" display 'Heart failure'
code "I5001": 'I5001' from "ICD10CM" display 'Unspecified systolic (congestive) heart failure'

// 心律不整相關
code "I47": 'I47' from "ICD10CM" display 'Paroxysmal tachycardia'
code "I48": 'I48' from "ICD10CM" display 'Atrial fibrillation and flutter'
code "I49": 'I49' from "ICD10CM" display 'Other cardiac arrhythmias'

// 腦中風相關
code "I60": 'I60' from "ICD10CM" display 'Nontraumatic subarachnoid hemorrhage'
code "I61": 'I61' from "ICD10CM" display 'Nontraumatic intracerebral hemorrhage'
code "I62": 'I62' from "ICD10CM" display 'Other and unspecified nontraumatic intracranial hemorrhage'
code "I63": 'I63' from "ICD10CM" display 'Cerebral infarction'
code "I64": 'I64' from "ICD10CM" display 'Stroke, not specified as hemorrhage or infarction'
code "I69": 'I69' from "ICD10CM" display 'Sequelae of cerebrovascular disease'

// 腦傷相關
code "S06": 'S06' from "ICD10CM" display 'Intracranial injury'

// 脊髓損傷相關
code "S14": 'S14' from "ICD10CM" display 'Injury of nerves and spinal cord at neck level'
code "S24": 'S24' from "ICD10CM" display 'Injury of nerves and spinal cord at thorax level'
code "S34": 'S34' from "ICD10CM" display 'Injury of lumbar and sacral spinal cord and nerves at abdomen, lower back and pelvis level'

// 失智症相關
code "F00": 'F00' from "ICD10CM" display 'Dementia in Alzheimer disease'
code "F01": 'F01' from "ICD10CM" display 'Vascular dementia'
code "F02": 'F02' from "ICD10CM" display 'Dementia in other diseases classified elsewhere'
code "F03": 'F03' from "ICD10CM" display 'Unspecified dementia'
code "G30": 'G30' from "ICD10CM" display 'Alzheimer disease'

// 肝腎衰竭相關
code "K72": 'K72' from "ICD10CM" display 'Hepatic failure, not elsewhere classified'
code "N17": 'N17' from "ICD10CM" display 'Acute kidney failure'
code "N19": 'N19' from "ICD10CM" display 'Unspecified kidney failure'

// 血液動力學不穩定相關
code "R57": 'R57' from "ICD10CM" display 'Shock, not elsewhere classified'
code "I95": 'I95' from "ICD10CM" display 'Hypotension'

// 敗血症相關
code "A41": 'A41' from "ICD10CM" display 'Other sepsis'
code "R6520": 'R6520' from "ICD10CM" display 'Severe sepsis without septic shock'
code "R6521": 'R6521' from "ICD10CM" display 'Severe sepsis with septic shock'

// 心臟復健治療碼
code "42014B": '42014B' from "TWProcedure" display '物理治療-復雜治療(42014B)'
code "42019C": '42019C' from "TWProcedure" display '物理治療-復雜治療(42019C)'
code "P7601P": 'P7601P' from "TWProcedure" display '心肺疾病患者復健整合治療費'
code "P5133B": 'P5133B' from "TWProcedure" display '心臟衰竭急性後期物理治療-復雜治療'
code "PTC5": 'PTC5' from "TWProcedure" display '物理治療項目代號-心肺功能訓練'

// 轉歸代碼
code "DischargeDisposition4": '4' from "DischargeDisposition" display '住院期間死亡'
code "DischargeDispositionA": 'A' from "DischargeDisposition" display '病危自動出院'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 住院Encounter編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// 門診Encounter編碼
define "Outpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'AMB', display: 'ambulatory' }
  }

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有Procedure
define "All Procedures":
  [Procedure] P

// ===== 診斷判斷函數 =====

// 判斷Condition是否符合指定的ICD-10-CM前綴碼（任意位數）
define function "ConditionCodeStartsWith"(condition Condition, prefix String):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and StartsWith(C.code, prefix)
  )

// 判斷Condition是否為完全符合指定的ICD-10-CM碼
define function "ConditionCodeEquals"(condition Condition, code String):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and C.code = code
  )

// 判斷Encounter是否有AMI主診斷 (I21, I22, I5A前三碼)
define function "HasAMIDiagnosis"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and exists(
          C.category Cat
            where exists(
              Cat.coding CatCoding
                where CatCoding.system = 'http://terminology.hl7.org/CodeSystem/condition-category'
                  and CatCoding.code = 'encounter-diagnosis'
            )
        )
        and exists(
          C.extension Ext
            where Ext.url = 'http://hl7.org/fhir/StructureDefinition/condition-dueTo'
              and exists(
                Ext.extension SubExt
                  where SubExt.url = 'role'
                    and SubExt.value as CodeableConcept in "Primary Diagnosis Codes"
              )
        )
        and (
          "ConditionCodeStartsWith"(C, 'I21')
          or "ConditionCodeStartsWith"(C, 'I22')
          or "ConditionCodeStartsWith"(C, 'I5A')
        )
  )

// 主診斷編碼
define "Primary Diagnosis Codes":
  {
    CodeableConcept {
      coding: {
        Coding {
          system: 'http://terminology.hl7.org/CodeSystem/diagnosis-role',
          code: 'AD',
          display: 'Admission diagnosis'
        }
      }
    }
  }

// 判斷Encounter是否有NSTEMI排除診斷 (I214 或 I222主診斷)
define function "HasNSTEMIExclusion"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and exists(
          C.category Cat
            where exists(
              Cat.coding CatCoding
                where CatCoding.system = 'http://terminology.hl7.org/CodeSystem/condition-category'
                  and CatCoding.code = 'encounter-diagnosis'
            )
        )
        and exists(
          C.extension Ext
            where Ext.url = 'http://hl7.org/fhir/StructureDefinition/condition-dueTo'
              and exists(
                Ext.extension SubExt
                  where SubExt.url = 'role'
                    and SubExt.value as CodeableConcept in "Primary Diagnosis Codes"
              )
        )
        and (
          "ConditionCodeEquals"(C, 'I214')
          or "ConditionCodeEquals"(C, 'I222')
        )
  )

// 判斷Encounter是否有不穩定心絞痛
define function "HasUnstableAngina"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and "ConditionCodeEquals"(C, 'I200')
  )

// 判斷Encounter是否有非代償性心衰竭
define function "HasDecompensatedHeartFailure"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'I50')
          or "ConditionCodeEquals"(C, 'I5001')
        )
  )

// 判斷Encounter是否有威脅生命的心律不整
define function "HasLifeThreateningArrhythmia"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'I47')
          or "ConditionCodeStartsWith"(C, 'I48')
          or "ConditionCodeStartsWith"(C, 'I49')
        )
  )

// 判斷Encounter是否有腦血管疾病史（腦中風、腦傷）
define function "HasCerebrovascularDisease"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'I60')
          or "ConditionCodeStartsWith"(C, 'I61')
          or "ConditionCodeStartsWith"(C, 'I62')
          or "ConditionCodeStartsWith"(C, 'I63')
          or "ConditionCodeStartsWith"(C, 'I64')
          or "ConditionCodeStartsWith"(C, 'I69')
          or "ConditionCodeStartsWith"(C, 'S06')
        )
  )

// 判斷Encounter是否有脊髓損傷史
define function "HasSpinalCordInjury"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'S14')
          or "ConditionCodeStartsWith"(C, 'S24')
          or "ConditionCodeStartsWith"(C, 'S34')
        )
  )

// 判斷Encounter是否有失智症病史
define function "HasDementia"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'F00')
          or "ConditionCodeStartsWith"(C, 'F01')
          or "ConditionCodeStartsWith"(C, 'F02')
          or "ConditionCodeStartsWith"(C, 'F03')
          or "ConditionCodeStartsWith"(C, 'G30')
        )
  )

// 判斷Encounter是否有急性肝腎衰竭
define function "HasAcuteLiverKidneyFailure"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'K72')
          or "ConditionCodeStartsWith"(C, 'N17')
          or "ConditionCodeStartsWith"(C, 'N19')
        )
  )

// 判斷Encounter是否有血液動力學不穩定
define function "HasHemodynamicInstability"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'R57')
          or "ConditionCodeStartsWith"(C, 'I95')
        )
  )

// 判斷Encounter是否有敗血症
define function "HasSepsis"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and (
          "ConditionCodeStartsWith"(C, 'A41')
          or "ConditionCodeEquals"(C, 'R6520')
          or "ConditionCodeEquals"(C, 'R6521')
        )
  )

// 判斷Encounter是否有不適合心臟復健的嚴重疾病
define function "HasSevereDiseaseLimitingRehabilitation"(encounter Encounter):
  "HasCerebrovascularDisease"(encounter)
    or "HasSpinalCordInjury"(encounter)
    or "HasDementia"(encounter)
    or "HasAcuteLiverKidneyFailure"(encounter)
    or "HasHemodynamicInstability"(encounter)
    or "HasSepsis"(encounter)

// 判斷Encounter是否有不適合心臟復健的條件
define function "HasRehabilitationContraindication"(encounter Encounter):
  "HasUnstableAngina"(encounter)
    or "HasDecompensatedHeartFailure"(encounter)
    or "HasLifeThreateningArrhythmia"(encounter)
    or "HasSevereDiseaseLimitingRehabilitation"(encounter)

// 判斷Encounter的轉歸代碼
define function "GetDischargeDisposition"(encounter Encounter):
  encounter.hospitalization.dischargeDisposition.coding[0].code

// 判斷Encounter是否為死亡或病危自動出院
define function "HasExcludedDischargeDisposition"(encounter Encounter):
  let dispositionCode: "GetDischargeDisposition"(encounter)
  return dispositionCode = '4' or dispositionCode = 'A'

// ===== 案件定義與群組 =====

// 取得Organization ID的函數
define function "GetOrganizationId"(encounter Encounter):
  if encounter.serviceProvider.reference is not null
    then Last(Split(encounter.serviceProvider.reference, '/'))
    else null

// 取得同一住院案件的所有Encounter
define function "GetSameHospitalizationEncounters"(encounter Encounter):
  "All Inpatient Encounters" E
    where "GetOrganizationId"(E) = "GetOrganizationId"(encounter)
      and E.subject.reference = encounter.subject.reference
      and Patient.birthDate = Patient.birthDate
      and date from start of E.period = date from start of encounter.period

// 取得最晚出院日的Encounter
define function "GetLatestDischargeEncounter"(encounter Encounter):
  Last(
    "GetSameHospitalizationEncounters"(encounter) E
      sort by end of period
  )

// 取得最晚出院日
define function "GetLatestDischargeDate"(encounter Encounter):
  end of "GetLatestDischargeEncounter"(encounter).period

// 取得入院日
define function "GetAdmissionDate"(encounter Encounter):
  start of encounter.period

// 計算年齡
define function "GetAgeAtDischarge"(encounter Encounter):
  AgeInYearsAt(date from "GetLatestDischargeDate"(encounter))

// 判斷整個住院案件是否符合AMI且無排除條件
define function "IsQualifiedAMIHospitalization"(encounter Encounter):
  let sameHospEncounters: "GetSameHospitalizationEncounters"(encounter)
  return
    // 至少有一個Encounter有AMI主診斷
    exists(sameHospEncounters E where "HasAMIDiagnosis"(E))
    // 沒有任何Encounter有NSTEMI排除診斷
    and not exists(sameHospEncounters E where "HasNSTEMIExclusion"(E))
    // 年齡18歲以上
    and "GetAgeAtDischarge"(encounter) >= "Minimum Age"
    // 沒有死亡或病危自動出院
    and not exists(sameHospEncounters E where "HasExcludedDischargeDisposition"(E))
    // 沒有不適合心臟復健的條件
    and not exists(sameHospEncounters E where "HasRehabilitationContraindication"(E))

// ===== 分母定義 =====

// 所有符合條件的AMI住院案件（18歲以上，無排除條件）
define "Denominator Encounters":
  "All Inpatient Encounters" E
    where "IsQualifiedAMIHospitalization"(E)
      and E = "GetLatestDischargeEncounter"(E)  // 只取最晚出院日的Encounter作為代表

// 分母（總案件數）
define "Denominator":
  Count("Denominator Encounters")

// 分母（第一期）
define "Denominator Period 1":
  Count(
    "Denominator Encounters" E
      where E.period.start during "Period 1"
  )

// 分母（第二期）
define "Denominator Period 2":
  Count(
    "Denominator Encounters" E
      where E.period.start during "Period 2"
  )

// ===== 心臟復健判斷 =====

// 計算入院後6個月追蹤期間
define function "GetPostAdmissionFollowUpPeriod"(admissionDate DateTime):
  Interval[admissionDate, admissionDate + "Post Admission Follow Up Days" days]

// 判斷Procedure是否為心臟復健
define function "IsCardiacRehabilitationProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-procedure'
          and (
            C.code = '42014B'
            or C.code = '42019C'
            or C.code = 'P7601P'
            or C.code = 'P5133B'
            or C.code = 'PTC5'
          )
    )

// 判斷病人在入院後6個月內是否接受心臟復健（含跨院住院及門診）
define function "HasCardiacRehabilitationWithin6Months"(inpatientEncounter Encounter):
  let admissionDate: "GetAdmissionDate"(inpatientEncounter),
      followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
  return
    exists(
      "All Procedures" P
        where P.subject.reference = inpatientEncounter.subject.reference
          and "IsCardiacRehabilitationProcedure"(P)
          and (
            // 住院期間的復健
            exists(
              "All Inpatient Encounters" E
                where E.subject.reference = inpatientEncounter.subject.reference
                  and P.encounter.reference = 'Encounter/' + E.id
                  and start of E.period in followUpPeriod
            )
            // 或門診期間的復健
            or exists(
              "All Outpatient Encounters" E
                where E.subject.reference = inpatientEncounter.subject.reference
                  and P.encounter.reference = 'Encounter/' + E.id
                  and start of E.period in followUpPeriod
            )
          )
    )

// 取得病人在入院後6個月內的心臟復健次數
define function "GetCardiacRehabilitationCount"(inpatientEncounter Encounter):
  let admissionDate: "GetAdmissionDate"(inpatientEncounter),
      followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
  return
    Count(
      "All Procedures" P
        where P.subject.reference = inpatientEncounter.subject.reference
          and "IsCardiacRehabilitationProcedure"(P)
          and (
            exists(
              "All Inpatient Encounters" E
                where E.subject.reference = inpatientEncounter.subject.reference
                  and P.encounter.reference = 'Encounter/' + E.id
                  and start of E.period in followUpPeriod
            )
            or exists(
              "All Outpatient Encounters" E
                where E.subject.reference = inpatientEncounter.subject.reference
                  and P.encounter.reference = 'Encounter/' + E.id
                  and start of E.period in followUpPeriod
            )
          )
    )

// ===== 分子定義 =====

// 分子案件（入院後6個月內接受心臟復健的案件）
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasCardiacRehabilitationWithin6Months"(E)

// 分子（符合條件案件數）
define "Numerator":
  Count("Numerator Encounters")

// 分子（第一期）
define "Numerator Period 1":
  Count(
    "Numerator Encounters" E
      where E.period.start during "Period 1"
  )

// 分子（第二期）
define "Numerator Period 2":
  Count(
    "Numerator Encounters" E
      where E.period.start during "Period 2"
  )

// 總心臟復健人次數（所有分子案件的復健次數總和）
define "Total Rehabilitation Sessions":
  Sum(
    "Numerator Encounters" E
      return "GetCardiacRehabilitationCount"(E)
  )

// 總心臟復健人次數（第一期）
define "Total Rehabilitation Sessions Period 1":
  Sum(
    ("Numerator Encounters" E where E.period.start during "Period 1")
      return "GetCardiacRehabilitationCount"(E)
  )

// 總心臟復健人次數（第二期）
define "Total Rehabilitation Sessions Period 2":
  Sum(
    ("Numerator Encounters" E where E.period.start during "Period 2")
      return "GetCardiacRehabilitationCount"(E)
  )

// ===== 指標計算 =====

// 整體指標（全年）- 接受復健的病人比率
define "Indicator Rate":
  if "Denominator" > 0
    then Round("Numerator" / "Denominator" * 100, 2)
    else null

// 第一期指標
define "Indicator Rate Period 1":
  if "Denominator Period 1" > 0
    then Round("Numerator Period 1" / "Denominator Period 1" * 100, 2)
    else null

// 第二期指標
define "Indicator Rate Period 2":
  if "Denominator Period 2" > 0
    then Round("Numerator Period 2" / "Denominator Period 2" * 100, 2)
    else null

// ===== 品質檢核 =====

// 資料完整性檢查
define "Data Quality Check":
  Tuple {
    total_inpatient_encounters: Count("All Inpatient Encounters"),
    ami_encounters_with_diagnosis: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E)),
    nstemi_exclusions: Count("All Inpatient Encounters" E where "HasNSTEMIExclusion"(E)),
    age_under_18_exclusions: Count(
      "All Inpatient Encounters" E 
        where "HasAMIDiagnosis"(E) 
          and "GetAgeAtDischarge"(E) < "Minimum Age"
    ),
    discharge_disposition_exclusions: Count(
      "All Inpatient Encounters" E
        where "HasAMIDiagnosis"(E)
          and "HasExcludedDischargeDisposition"(E)
    ),
    rehabilitation_contraindication_exclusions: Count(
      "All Inpatient Encounters" E
        where "HasAMIDiagnosis"(E)
          and "HasRehabilitationContraindication"(E)
    ),
    qualified_ami_hospitalizations: "Denominator",
    cases_with_cardiac_rehabilitation: "Numerator",
    total_rehabilitation_sessions: "Total Rehabilitation Sessions"
  }

// 心臟復健項目統計
define "Rehabilitation Procedure Statistics":
  Tuple {
    total_rehabilitation_cases: "Numerator",
    procedure_42014B: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and P.status = 'completed'
              and exists(P.code.coding C where C.code = '42014B')
              and (
                exists("All Inpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
                or exists("All Outpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
              )
        )
    ),
    procedure_42019C: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and P.status = 'completed'
              and exists(P.code.coding C where C.code = '42019C')
              and (
                exists("All Inpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
                or exists("All Outpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
              )
        )
    ),
    procedure_P7601P: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and P.status = 'completed'
              and exists(P.code.coding C where C.code = 'P7601P')
              and (
                exists("All Inpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
                or exists("All Outpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
              )
        )
    ),
    procedure_P5133B: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and P.status = 'completed'
              and exists(P.code.coding C where C.code = 'P5133B')
              and (
                exists("All Inpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
                or exists("All Outpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
              )
        )
    ),
    procedure_PTC5: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and P.status = 'completed'
              and exists(P.code.coding C where C.code = 'PTC5')
              and (
                exists("All Inpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
                or exists("All Outpatient Encounters" Enc where Enc.subject.reference = E.subject.reference and P.encounter.reference = 'Encounter/' + Enc.id and start of Enc.period in followUpPeriod)
              )
        )
    )
  }

// 心臟復健場所統計
define "Rehabilitation Setting Statistics":
  Tuple {
    inpatient_rehabilitation: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and "IsCardiacRehabilitationProcedure"(P)
              and exists(
                "All Inpatient Encounters" Enc
                  where Enc.subject.reference = E.subject.reference
                    and P.encounter.reference = 'Encounter/' + Enc.id
                    and start of Enc.period in followUpPeriod
              )
        )
    ),
    outpatient_rehabilitation: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and "IsCardiacRehabilitationProcedure"(P)
              and exists(
                "All Outpatient Encounters" Enc
                  where Enc.subject.reference = E.subject.reference
                    and P.encounter.reference = 'Encounter/' + Enc.id
                    and start of Enc.period in followUpPeriod
              )
        )
    ),
    same_hospital_rehabilitation: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate),
            originalOrgId: "GetOrganizationId"(E)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and "IsCardiacRehabilitationProcedure"(P)
              and (
                exists(
                  "All Inpatient Encounters" Enc
                    where Enc.subject.reference = E.subject.reference
                      and P.encounter.reference = 'Encounter/' + Enc.id
                      and start of Enc.period in followUpPeriod
                      and "GetOrganizationId"(Enc) = originalOrgId
                )
                or exists(
                  "All Outpatient Encounters" Enc
                    where Enc.subject.reference = E.subject.reference
                      and P.encounter.reference = 'Encounter/' + Enc.id
                      and start of Enc.period in followUpPeriod
                      and "GetOrganizationId"(Enc) = originalOrgId
                )
              )
        )
    ),
    cross_hospital_rehabilitation: Count(
      "Numerator Encounters" E
        let admissionDate: "GetAdmissionDate"(E),
            followUpPeriod: "GetPostAdmissionFollowUpPeriod"(admissionDate),
            originalOrgId: "GetOrganizationId"(E)
        where exists(
          "All Procedures" P
            where P.subject.reference = E.subject.reference
              and "IsCardiacRehabilitationProcedure"(P)
              and (
                exists(
                  "All Inpatient Encounters" Enc
                    where Enc.subject.reference = E.subject.reference
                      and P.encounter.reference = 'Encounter/' + Enc.id
                      and start of Enc.period in followUpPeriod
                      and "GetOrganizationId"(Enc) != originalOrgId
                )
                or exists(
                  "All Outpatient Encounters" Enc
                    where Enc.subject.reference = E.subject.reference
                      and P.encounter.reference = 'Encounter/' + Enc.id
                      and start of Enc.period in followUpPeriod
                      and "GetOrganizationId"(Enc) != originalOrgId
                )
              )
        )
    )
  }

// 年齡分組統計
define "Age Group Statistics":
  Tuple {
    age_18_44: Count("Denominator Encounters" E where "GetAgeAtDischarge"(E) >= 18 and "GetAgeAtDischarge"(E) <= 44),
    age_45_64: Count("Denominator Encounters" E where "GetAgeAtDischarge"(E) >= 45 and "GetAgeAtDischarge"(E) <= 64),
    age_65_plus: Count("Denominator Encounters" E where "GetAgeAtDischarge"(E) >= 65),
    age_18_44_rehabilitation: Count("Numerator Encounters" E where "GetAgeAtDischarge"(E) >= 18 and "GetAgeAtDischarge"(E) <= 44),
    age_45_64_rehabilitation: Count("Numerator Encounters" E where "GetAgeAtDischarge"(E) >= 45 and "GetAgeAtDischarge"(E) <= 64),
    age_65_plus_rehabilitation: Count("Numerator Encounters" E where "GetAgeAtDischarge"(E) >= 65)
  }

// 排除條件詳細統計
define "Exclusion Criteria Details":
  Tuple {
    unstable_angina: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasUnstableAngina"(E)),
    decompensated_heart_failure: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasDecompensatedHeartFailure"(E)),
    life_threatening_arrhythmia: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasLifeThreateningArrhythmia"(E)),
    cerebrovascular_disease: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasCerebrovascularDisease"(E)),
    spinal_cord_injury: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasSpinalCordInjury"(E)),
    dementia: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasDementia"(E)),
    acute_liver_kidney_failure: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasAcuteLiverKidneyFailure"(E)),
    hemodynamic_instability: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasHemodynamicInstability"(E)),
    sepsis: Count("All Inpatient Encounters" E where "HasAMIDiagnosis"(E) and "HasSepsis"(E))
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '急性心肌梗塞病人接受心臟復健比率',
    measurement_period: ToString("Measurement Period"),
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    overall_total_sessions: "Total Rehabilitation Sessions",
    
    // 分期指標
    period_1_numerator: "Numerator Period 1",
    period_1_denominator: "Denominator Period 1",
    period_1_rate: "Indicator Rate Period 1",
    period_1_total_sessions: "Total Rehabilitation Sessions Period 1",
    
    period_2_numerator: "Numerator Period 2",
    period_2_denominator: "Denominator Period 2",
    period_2_rate: "Indicator Rate Period 2",
    period_2_total_sessions: "Total Rehabilitation Sessions Period 2",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // 心臟復健項目統計
    rehabilitation_procedure_statistics: "Rehabilitation Procedure Statistics",
    
    // 心臟復健場所統計
    rehabilitation_setting_statistics: "Rehabilitation Setting Statistics",
    
    // 年齡分組統計
    age_group_statistics: "Age Group Statistics",
    
    // 排除條件詳細統計
    exclusion_criteria_details: "Exclusion Criteria Details"
  }
