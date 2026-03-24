library Indicator_Hypertension_Heart_Block_Beta_Blocker_Use_Rate version '1.0.0'

/*
具二度或三度心臟傳導阻斷病史之高血壓病人使用乙型阻斷劑(β-Blocker)比率
Beta-Blocker Use Rate in Hypertensive Patients with 2nd or 3rd Degree Heart Block History

計算說明:
- 分子：分母案件中有使用β-Blocker人數
- 分母：高血壓且有高血壓用藥病患勾稽病史檔，有二度或三度心臟傳導阻斷病史的人數
- 資料範圍：醫院門診/住院資料
- 計算頻率：季

備註:
1. 分母需排除已使用心律調節器的病人：有申報特材適應症B101-1或特材前五碼為FHP01或FHP02者
2. 高血壓診斷：任一主次診斷前三碼為I10-I15、全碼I160、I161、I169，且有高血壓用藥紀錄的案件
3. 高血壓用藥：ATC代碼前三碼為C02、C03、C07、C08、C09及terazosin (G04CA(5碼))的品項
4. 病史檔：記載病人特定疾病第一次就醫日期(全國資料)且費用年月9201開始記載
5. 病史檔的二度或三度心臟傳導阻斷(2nd or 3rd degree heart block) 主、次診斷碼前四碼為I442、I443、I441之案件
6. 分子條件β-Blocker：ATC前五碼為C07AA、C07AB
7. 計算公式：(分子/分母) x 100%
8. 臨床意義：監測高危險族群使用β-Blocker的情況，預防心臟傳導阻斷惡化風險
9. 計算範圍：2026年(115年)資料

Version History:
- 1.0.0: Initial implementation (2026-01-07)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 參數定義
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 季度期間定義
parameter "Quarterly Periods" List<Interval<DateTime>>
  default {
    Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0],
    Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0],
    Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0],
    Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
  }

// 病史檔起始年月（民國年月）
parameter "History Start Year Month" String default '9201'

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "TWMaterial": 'http://healthcare.gov.tw/material'
codesystem "TWMaterialIndication": 'http://healthcare.gov.tw/material/indication'

// 高血壓診斷codes (ICD-10-CM I10-I15)
code "I10": 'I10' from "ICD10CM" display 'Essential (primary) hypertension'
code "I11": 'I11' from "ICD10CM" display 'Hypertensive heart disease'
code "I110": 'I110' from "ICD10CM" display 'Hypertensive heart disease with heart failure'
code "I119": 'I119' from "ICD10CM" display 'Hypertensive heart disease without heart failure'
code "I12": 'I12' from "ICD10CM" display 'Hypertensive chronic kidney disease'
code "I120": 'I120' from "ICD10CM" display 'Hypertensive chronic kidney disease with stage 5 CKD'
code "I129": 'I129' from "ICD10CM" display 'Hypertensive chronic kidney disease with stage 1-4 CKD'
code "I13": 'I13' from "ICD10CM" display 'Hypertensive heart and chronic kidney disease'
code "I130": 'I130' from "ICD10CM" display 'Hypertensive heart and CKD with heart failure and stage 1-4 CKD'
code "I1310": 'I1310' from "ICD10CM" display 'Hypertensive heart and CKD without heart failure, with stage 1-4 CKD'
code "I1311": 'I1311' from "ICD10CM" display 'Hypertensive heart and CKD without heart failure, with stage 5 CKD'
code "I132": 'I132' from "ICD10CM" display 'Hypertensive heart and CKD with heart failure and stage 5 CKD'
code "I15": 'I15' from "ICD10CM" display 'Secondary hypertension'
code "I150": 'I150' from "ICD10CM" display 'Renovascular hypertension'
code "I151": 'I151' from "ICD10CM" display 'Hypertension secondary to other renal disorders'
code "I152": 'I152' from "ICD10CM" display 'Hypertension secondary to endocrine disorders'
code "I158": 'I158' from "ICD10CM" display 'Other secondary hypertension'
code "I159": 'I159' from "ICD10CM" display 'Secondary hypertension, unspecified'

// 高血壓特定全碼
code "I160": 'I160' from "ICD10CM" display 'Hypertensive urgency'
code "I161": 'I161' from "ICD10CM" display 'Hypertensive emergency'
code "I169": 'I169' from "ICD10CM" display 'Hypertensive crisis, unspecified'

// 心臟傳導阻斷診斷codes (ICD-10-CM I441, I442, I443)
code "I441": 'I441' from "ICD10CM" display 'Second degree atrioventricular block - 二度房室傳導阻斷'
code "I442": 'I442' from "ICD10CM" display 'Third degree atrioventricular block - 三度房室傳導阻斷'
code "I443": 'I443' from "ICD10CM" display 'Other and unspecified atrioventricular block - 其他及未明示房室傳導阻斷'

// 高血壓用藥 ATC codes
code "C02": 'C02' from "ATC" display 'Antihypertensives'
code "C03": 'C03' from "ATC" display 'Diuretics'
code "C07": 'C07' from "ATC" display 'Beta blocking agents'
code "C08": 'C08' from "ATC" display 'Calcium channel blockers'
code "C09": 'C09' from "ATC" display 'Agents acting on the renin-angiotensin system'
code "G04CA": 'G04CA' from "ATC" display 'Alpha-adrenoreceptor antagonists - includes terazosin'

// β-Blocker ATC codes (前五碼)
code "C07AA": 'C07AA' from "ATC" display 'Beta blocking agents, non-selective'
code "C07AB": 'C07AB' from "ATC" display 'Beta blocking agents, selective'

// 心律調節器特材codes
code "B101-1": 'B101-1' from "TWMaterialIndication" display '心律調節器適應症'
code "FHP01": 'FHP01' from "TWMaterial" display '心律調節器特材代碼前五碼'
code "FHP02": 'FHP02' from "TWMaterial" display '心律調節器特材代碼前五碼'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有Encounter (門診+住院)
define "All Encounters":
  [Encounter] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 所有Condition
define "All Conditions":
  [Condition] C

// 所有MedicationRequest
define "All Medication Requests":
  [MedicationRequest] M

// 所有Device (特材)
define "All Devices":
  [Device] D

// ===== 輔助函數定義 =====

// 檢查ICD-10-CM碼是否符合高血壓診斷（前三碼I10-I15）
define function "IsHypertensionDiagnosisCode"(code String):
  let prefix3: Substring(code, 0, 3)
  return
    prefix3 in { 'I10', 'I11', 'I12', 'I13', 'I15' }
    or code in { 'I160', 'I161', 'I169' }

// 檢查ICD-10-CM碼是否為心臟傳導阻斷（前四碼I441, I442, I443）
define function "IsHeartBlockDiagnosisCode"(code String):
  let prefix4: Substring(code, 0, 4)
  return
    prefix4 in { 'I441', 'I442', 'I443' }

// 檢查ATC碼是否為高血壓用藥（前三碼C02, C03, C07, C08, C09 或前五碼G04CA）
define function "IsAntihypertensiveMedication"(atcCode String):
  let prefix3: Substring(atcCode, 0, 3)
  let prefix5: Substring(atcCode, 0, 5)
  return
    prefix3 in { 'C02', 'C03', 'C07', 'C08', 'C09' }
    or prefix5 = 'G04CA'

// 檢查ATC碼是否為β-Blocker（前五碼C07AA, C07AB）
define function "IsBetaBlocker"(atcCode String):
  let prefix5: Substring(atcCode, 0, 5)
  return
    prefix5 in { 'C07AA', 'C07AB' }

// 檢查特材代碼是否為心律調節器（適應症B101-1或前五碼FHP01, FHP02）
define function "IsPacemakerDevice"(deviceCode String, indicationCode String):
  let prefix5: Substring(deviceCode, 0, 5)
  return
    indicationCode = 'B101-1'
    or prefix5 in { 'FHP01', 'FHP02' }

// 獲取Condition的診斷碼
define function "GetConditionCode"(condition FHIR.Condition):
  condition.code.coding[0].code.value

// 獲取MedicationRequest的ATC碼
define function "GetMedicationATCCode"(medication FHIR.MedicationRequest):
  medication.medicationCodeableConcept.coding[0].code.value

// 獲取Device的特材碼
define function "GetDeviceCode"(device FHIR.Device):
  device.type.coding[0].code.value

// 獲取Device的適應症碼
define function "GetDeviceIndicationCode"(device FHIR.Device):
  (singleton from (
    device.extension E
      where E.url.value = 'http://healthcare.gov.tw/fhir/StructureDefinition/device-indication'
  )).value.coding[0].code.value

// ===== 計算季度資料 =====

// 針對特定季度計算
define function "Calculate For Quarter"(period Interval<DateTime>):
  // 分母：高血壓且有高血壓用藥病患勾稽病史檔，有二度或三度心臟傳導阻斷病史的人數
  let denominatorPatients:
    "All Patients With Hypertension And Heart Block History In Period"(period)
      except "Patients With Pacemaker In Period"(period),
  
  // 分子：分母案件中有使用β-Blocker人數
  numeratorPatients:
    denominatorPatients P
      where exists (
        "Beta Blocker Medications In Period"(period) M
          where M.subject.reference.value = 'Patient/' + P.id.value
      )
  
  return {
    period: period,
    denominator: Count(denominatorPatients),
    numerator: Count(numeratorPatients),
    rate: if Count(denominatorPatients) > 0 
          then (Count(numeratorPatients) / Count(denominatorPatients)) * 100 
          else null
  }

// ===== 病史檔相關定義 =====

// 病史檔：二度或三度心臟傳導阻斷診斷（病史檔紀錄第一次就醫日期）
define "Historical Heart Block Conditions":
  "All Conditions" C
    where exists (
      C.code.coding Coding
        where "IsHeartBlockDiagnosisCode"(Coding.code.value)
    )
    and C.onsetDateTime is not null
    // 病史檔從民國92年01月開始記載
    and C.onsetDateTime >= @2003-01-01T00:00:00.0

// ===== 高血壓相關定義 =====

// 高血壓診斷（主次診斷）
define function "Hypertension Diagnoses In Period"(period Interval<DateTime>):
  "All Conditions" C
    where exists (
      C.code.coding Coding
        where "IsHypertensionDiagnosisCode"(Coding.code.value)
    )
    and C.recordedDate during period

// 高血壓用藥
define function "Antihypertensive Medications In Period"(period Interval<DateTime>):
  "All Medication Requests" M
    where M.status = 'completed'
      and M.authoredOn during period
      and exists (
        M.medicationCodeableConcept.coding ATC
          where "IsAntihypertensiveMedication"(ATC.code.value)
      )

// 有高血壓且有高血壓用藥的病人
define function "Patients With Hypertension And Medication In Period"(period Interval<DateTime>):
  [Patient] P
    where exists (
      "Hypertension Diagnoses In Period"(period) C
        where C.subject.reference.value = 'Patient/' + P.id.value
    )
    and exists (
      "Antihypertensive Medications In Period"(period) M
        where M.subject.reference.value = 'Patient/' + P.id.value
    )

// ===== 心臟傳導阻斷病史相關定義 =====

// 有高血壓且有高血壓用藥，並有心臟傳導阻斷病史的病人
define function "All Patients With Hypertension And Heart Block History In Period"(period Interval<DateTime>):
  "Patients With Hypertension And Medication In Period"(period) P
    where exists (
      "Historical Heart Block Conditions" C
        where C.subject.reference.value = 'Patient/' + P.id.value
    )

// ===== 排除條件：心律調節器 =====

// 心律調節器特材（適應症B101-1或前五碼FHP01, FHP02）
define function "Pacemaker Devices In Period"(period Interval<DateTime>):
  "All Devices" D
    where D.patient.reference.value is not null
      // 檢查特材適應症或代碼
      and exists (
        D.type.coding DeviceCode
          where "IsPacemakerDevice"(
            DeviceCode.code.value,
            "GetDeviceIndicationCode"(D)
          )
      )
      // 申報期間在計算期間內
      and exists (
        [Claim] Claim
          where Claim.item.productOrService.coding[0].code.value = "GetDeviceCode"(D)
            and Claim.created during period
      )

// 有使用心律調節器的病人（需排除）
define function "Patients With Pacemaker In Period"(period Interval<DateTime>):
  [Patient] P
    where exists (
      "Pacemaker Devices In Period"(period) D
        where D.patient.reference.value = 'Patient/' + P.id.value
    )

// ===== β-Blocker用藥定義 =====

// β-Blocker用藥（ATC前五碼C07AA, C07AB）
define function "Beta Blocker Medications In Period"(period Interval<DateTime>):
  "All Medication Requests" M
    where M.status = 'completed'
      and M.authoredOn during period
      and exists (
        M.medicationCodeableConcept.coding ATC
          where "IsBetaBlocker"(ATC.code.value)
      )

// ===== 季度計算結果 =====

// Q1 結果 (2026-01-01 to 2026-03-31)
define "Q1 Result":
  "Calculate For Quarter"(
    Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]
  )

// Q2 結果 (2026-04-01 to 2026-06-30)
define "Q2 Result":
  "Calculate For Quarter"(
    Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]
  )

// Q3 結果 (2026-07-01 to 2026-09-30)
define "Q3 Result":
  "Calculate For Quarter"(
    Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]
  )

// Q4 結果 (2026-10-01 to 2026-12-31)
define "Q4 Result":
  "Calculate For Quarter"(
    Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]
  )

// ===== 年度彙總結果 =====

// 全年結果
define "Annual Result":
  "Calculate For Quarter"("Measurement Period")

// 全年分母
define "Annual Denominator":
  Count(
    "All Patients With Hypertension And Heart Block History In Period"("Measurement Period")
      except "Patients With Pacemaker In Period"("Measurement Period")
  )

// 全年分子
define "Annual Numerator":
  let denominatorPatients:
    "All Patients With Hypertension And Heart Block History In Period"("Measurement Period")
      except "Patients With Pacemaker In Period"("Measurement Period")
  return
    Count(
      denominatorPatients P
        where exists (
          "Beta Blocker Medications In Period"("Measurement Period") M
            where M.subject.reference.value = 'Patient/' + P.id.value
        )
    )

// 全年β-Blocker使用率
define "Annual Beta Blocker Use Rate":
  if "Annual Denominator" > 0 then
    ("Annual Numerator" / "Annual Denominator") * 100
  else
    null

// ===== 詳細結果輸出 =====

// 所有季度結果
define "All Quarterly Results":
  {
    "Q1 Result",
    "Q2 Result",
    "Q3 Result",
    "Q4 Result"
  }

// 最終報告
define "Final Report":
  {
    indicator_name: '具二度或三度心臟傳導阻斷病史之高血壓病人使用乙型阻斷劑(β-Blocker)比率',
    indicator_code: 'Heart_Block_Beta_Blocker_Rate',
    calculation_year: 2026,
    calculation_frequency: '季',
    annual_denominator: "Annual Denominator",
    annual_numerator: "Annual Numerator",
    annual_rate: "Annual Beta Blocker Use Rate",
    quarterly_results: "All Quarterly Results",
    data_source: '醫院門診/住院資料',
    history_start_date: '2003-01-01 (民國92年01月)',
    excluded_conditions: '已使用心律調節器的病人（適應症B101-1或特材前五碼FHP01或FHP02）',
    clinical_significance: '監測高危險族群使用β-Blocker的情況，預防心臟傳導阻斷惡化風險',
    formula: '(分子/分母) x 100%'
  }
