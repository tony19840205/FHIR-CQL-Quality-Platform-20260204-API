library Indicator_Stroke_Rehabilitation_Services_Within_4Months_Rate version '1.0.0'

/*
缺血性或出血性中風病人住院期間或出院後四個月內接受復健服務比率
Ischemic or Hemorrhagic Stroke Rehabilitation Services Within 4 Months Rate

計算說明:
- 分子：分母案例中，有接受任何一項住院/門診/交付機構(物理治療所)復健服務的人次數
- 分母：18歲(含)以上缺血性或出血性中風的急診或住院病患，中風後持續於該院就診3個月以上的人次數
- 資料範圍：西醫醫院急診及住院資料
- 計算頻率：半年及年

備註:
1. 18歲(含)以上：(入院年或就醫年-出生年)≥18
2. 缺血性或出血性腦中風：出院主診斷碼前三碼為I60、I61、I63、全碼為P91821、P91822、P91823、P91829
3. 急診：實令類別(ORDER_TYPE)為'A'且實令代碼(ORDER_CODE)為'ER'
4. 中風後持續於該院就診3個月以上：該病患在[出院日(或就醫日)+90]~[出院日(或就醫日)+120]這段期間於同院門/住診有就診紀錄符合此定義
5. 門/住診有就診：門診實院或住診實院中任一主次診斷全碼落在附註代碼者，門診抓就醫日期判斷，住院抓住院日判斷
6. 復健服務：包含一般復健檢查及治療、物理治療、職能治療、語言治療，以及急性後期照護試辦計畫(PAC-STROKE)
   - 前5碼為41002~41007：一般復健檢查及治療
   - 前5碼為42001~42019：物理治療 Physical Therapy
   - 前5碼為43001~43038：職能治療 Occupational Therapy
   - 前5碼為44001~44016：語言治療 Communication Therapy
   - 前5碼為P5101~P5106：PAC(FRG 1)復健專用
   - 前5碼為P5107~P5112：PAC(FRG 2)復健專用
   - 前5碼為P5119~P5122：PAC(FRG 1)日間照護復健專用
   - 全碼為PACOT1~PACOT20：PAC職能治療
   - 全碼為PACPT1~PACPT21：PAC物理治療
   - 全碼為PACST1~PACST14：PAC語言治療
7. 復健時間範圍：住院期間或出院後四個月內(120天)
8. 臨床意義：早期復健介入可改善中風患者功能恢復，降低失能程度
9. 計算範圍：2026年(115年)資料

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

// 年齡限制
parameter "Minimum Age" Integer default 18

// 持續就診檢查期間（出院後90-120天）
parameter "Follow-up Start Days" Integer default 90
parameter "Follow-up End Days" Integer default 120

// 復健服務時間範圍（出院後4個月=120天）
parameter "Rehabilitation Period Days" Integer default 120

// 編碼系統定義
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "TWProcedure": 'http://healthcare.gov.tw/procedure'

// 資料來源定義
context Patient

// ===== 基礎資料定義 =====

// 所有住院Encounter
define "All Inpatient Encounters":
  [Encounter: type in "Inpatient Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 所有急診Encounter
define "All Emergency Encounters":
  [Encounter: type in "Emergency Encounter Codes"] E
    where E.status = 'finished'
      and E.period.start during "Measurement Period"

// 所有門診Encounter
define "All Outpatient Encounters":
  [Encounter: type in "Outpatient Encounter Codes"] E
    where E.status = 'finished'

// Encounter類型編碼
define "Inpatient Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'IMP', display: 'inpatient encounter' }
  }

define "Emergency Encounter Codes":
  { 
    Code { system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode', code: 'EMER', display: 'emergency' }
  }

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

// ===== 中風診斷判斷函數 =====

// 判斷Condition是否為缺血性中風（I63前三碼或P918系列全碼）
define function "IsIschemicStrokeDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          StartsWith(C.code, 'I63')
          or C.code = 'P91821'
          or C.code = 'P91822'
          or C.code = 'P91823'
          or C.code = 'P91829'
        )
  )

// 判斷Condition是否為出血性中風（I60或I61前三碼）
define function "IsHemorrhagicStrokeDiagnosis"(condition Condition):
  exists(
    condition.code.coding C
      where C.system = 'http://hl7.org/fhir/sid/icd-10-cm'
        and (
          StartsWith(C.code, 'I60')
          or StartsWith(C.code, 'I61')
        )
  )

// 判斷Condition是否為中風（缺血性或出血性）
define function "IsStrokeDiagnosis"(condition Condition):
  "IsIschemicStrokeDiagnosis"(condition) or "IsHemorrhagicStrokeDiagnosis"(condition)

// 判斷Encounter是否有中風主診斷
define function "HasStrokePrimaryDiagnosis"(encounter Encounter):
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
        and "IsStrokeDiagnosis"(C)
  )

// 判斷Encounter是否有中風主次診斷（用於追蹤就診判斷）
define function "HasStrokeAnyDiagnosis"(encounter Encounter):
  exists(
    "All Conditions" C
      where C.encounter.reference = 'Encounter/' + encounter.id
        and "IsStrokeDiagnosis"(C)
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

// ===== 年齡計算 =====

// 取得就診日（急診或住院入院日）
define function "GetEncounterDate"(encounter Encounter):
  start of encounter.period

// 計算病人在就診時的年齡
define function "GetAgeAtEncounter"(encounter Encounter):
  AgeInYearsAt(date from "GetEncounterDate"(encounter))

// 判斷病人在就診時是否≥18歲
define function "IsAdultAtEncounter"(encounter Encounter):
  "GetAgeAtEncounter"(encounter) >= "Minimum Age"

// ===== 出院相關函數 =====

// 取得出院日或就醫日
define function "GetDischargeOrVisitDate"(encounter Encounter):
  end of encounter.period

// 判斷Encounter是否有出院/就醫紀錄
define function "HasDischargeOrVisitRecord"(encounter Encounter):
  "GetDischargeOrVisitDate"(encounter) is not null

// ===== 持續就診判斷 =====

// 計算追蹤期間（出院後90-120天）
define function "GetFollowUpPeriod"(encounter Encounter):
  let dischargeDate: "GetDischargeOrVisitDate"(encounter)
  return
    if dischargeDate is not null
      then Interval[dischargeDate + "Follow-up Start Days" days, dischargeDate + "Follow-up End Days" days]
      else null as Interval<DateTime>

// 判斷病人是否在追蹤期間有中風相關就診（門診或住院）
define function "HasFollowUpVisit"(indexEncounter Encounter):
  let followUpPeriod: "GetFollowUpPeriod"(indexEncounter),
      organizationRef: indexEncounter.serviceProvider.reference
  return
    exists(
      ("All Outpatient Encounters" union "All Inpatient Encounters") E
        where E.period.start during followUpPeriod
          and E.serviceProvider.reference = organizationRef
          and "HasStrokeAnyDiagnosis"(E)
    )

// ===== 分母定義 =====

// 所有急診或住院中風案件
define "All Stroke Encounters":
  ("All Emergency Encounters" union "All Inpatient Encounters") E
    where "HasStrokePrimaryDiagnosis"(E)

// 分母：18歲以上中風案件，有出院紀錄，且有3個月持續追蹤
define "Denominator Encounters":
  "All Stroke Encounters" E
    where "IsAdultAtEncounter"(E)
      and "HasDischargeOrVisitRecord"(E)
      and "HasFollowUpVisit"(E)

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

// ===== 復健服務判斷 =====

// 判斷Procedure是否為一般復健檢查及治療（41002~41007）
define function "IsGeneralRehabProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            (ToInteger(Substring(C.code, 0, 5)) >= 41002 and ToInteger(Substring(C.code, 0, 5)) <= 41007)
          )
    )

// 判斷Procedure是否為物理治療（42001~42019）
define function "IsPhysicalTherapyProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            (ToInteger(Substring(C.code, 0, 5)) >= 42001 and ToInteger(Substring(C.code, 0, 5)) <= 42019)
          )
    )

// 判斷Procedure是否為職能治療（43001~43038）
define function "IsOccupationalTherapyProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            (ToInteger(Substring(C.code, 0, 5)) >= 43001 and ToInteger(Substring(C.code, 0, 5)) <= 43038)
          )
    )

// 判斷Procedure是否為語言治療（44001~44016）
define function "IsCommunicationTherapyProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            (ToInteger(Substring(C.code, 0, 5)) >= 44001 and ToInteger(Substring(C.code, 0, 5)) <= 44016)
          )
    )

// 判斷Procedure是否為PAC-STROKE FRG1復健（P5101~P5106）
define function "IsPACFRG1Procedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            (Substring(C.code, 0, 5) >= 'P5101' and Substring(C.code, 0, 5) <= 'P5106')
          )
    )

// 判斷Procedure是否為PAC-STROKE FRG2復健（P5107~P5112）
define function "IsPACFRG2Procedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            (Substring(C.code, 0, 5) >= 'P5107' and Substring(C.code, 0, 5) <= 'P5112')
          )
    )

// 判斷Procedure是否為PAC-STROKE FRG1日間照護（P5119~P5122）
define function "IsPACFRG1DayCare"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and (
            (Substring(C.code, 0, 5) >= 'P5119' and Substring(C.code, 0, 5) <= 'P5122')
          )
    )

// 判斷Procedure是否為PAC職能治療（PACOT1~PACOT20）
define function "IsPACOTProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and StartsWith(C.code, 'PACOT')
          and (
            ToInteger(Substring(C.code, 5)) >= 1 and ToInteger(Substring(C.code, 5)) <= 20
          )
    )

// 判斷Procedure是否為PAC物理治療（PACPT1~PACPT21）
define function "IsPACPTProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and StartsWith(C.code, 'PACPT')
          and (
            ToInteger(Substring(C.code, 5)) >= 1 and ToInteger(Substring(C.code, 5)) <= 21
          )
    )

// 判斷Procedure是否為PAC語言治療（PACST1~PACST14）
define function "IsPACSTProcedure"(procedure Procedure):
  procedure.status = 'completed'
    and exists(
      procedure.code.coding C
        where C.system = 'http://healthcare.gov.tw/procedure'
          and StartsWith(C.code, 'PACST')
          and (
            ToInteger(Substring(C.code, 5)) >= 1 and ToInteger(Substring(C.code, 5)) <= 14
          )
    )

// 判斷Procedure是否為任何復健服務
define function "IsRehabilitationProcedure"(procedure Procedure):
  "IsGeneralRehabProcedure"(procedure)
    or "IsPhysicalTherapyProcedure"(procedure)
    or "IsOccupationalTherapyProcedure"(procedure)
    or "IsCommunicationTherapyProcedure"(procedure)
    or "IsPACFRG1Procedure"(procedure)
    or "IsPACFRG2Procedure"(procedure)
    or "IsPACFRG1DayCare"(procedure)
    or "IsPACOTProcedure"(procedure)
    or "IsPACPTProcedure"(procedure)
    or "IsPACSTProcedure"(procedure)

// 取得Procedure執行日期
define function "GetProcedureDate"(procedure Procedure):
  Coalesce(
    start of (procedure.performed as Period),
    procedure.performed as dateTime
  )

// 計算復健服務期間（住院期間+出院後4個月）
define function "GetRehabilitationPeriod"(encounter Encounter):
  let admissionDate: start of encounter.period,
      dischargeDate: "GetDischargeOrVisitDate"(encounter)
  return
    if dischargeDate is not null
      then Interval[admissionDate, dischargeDate + "Rehabilitation Period Days" days]
      else null as Interval<DateTime>

// 判斷Encounter是否有復健服務（住院期間或出院後4個月內）
define function "HasRehabilitationService"(encounter Encounter):
  let rehabPeriod: "GetRehabilitationPeriod"(encounter)
  return
    exists(
      "All Procedures" P
        where "IsRehabilitationProcedure"(P)
          and "GetProcedureDate"(P) during rehabPeriod
          and (
            P.encounter.reference = 'Encounter/' + encounter.id
            or exists(
              P.subject.reference
                where P.subject.reference = 'Patient/' + Patient.id
            )
          )
    )

// 取得Encounter的復健服務Procedure
define function "GetRehabilitationProcedures"(encounter Encounter):
  let rehabPeriod: "GetRehabilitationPeriod"(encounter)
  return
    "All Procedures" P
      where "IsRehabilitationProcedure"(P)
        and "GetProcedureDate"(P) during rehabPeriod
        and (
          P.encounter.reference = 'Encounter/' + encounter.id
          or exists(
            P.subject.reference
              where P.subject.reference = 'Patient/' + Patient.id
          )
        )

// ===== 分子定義 =====

// 分子：有接受復健服務的案件
define "Numerator Encounters":
  "Denominator Encounters" E
    where "HasRehabilitationService"(E)

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

// ===== 指標計算 =====

// 整體指標（全年）
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
    total_emergency_encounters: Count("All Emergency Encounters"),
    total_inpatient_encounters: Count("All Inpatient Encounters"),
    stroke_encounters: Count("All Stroke Encounters"),
    no_discharge_record_exclusions: Count(
      "All Stroke Encounters" E 
        where not "HasDischargeOrVisitRecord"(E)
    ),
    age_under_18_exclusions: Count(
      "All Stroke Encounters" E 
        where "HasDischargeOrVisitRecord"(E)
          and not "IsAdultAtEncounter"(E)
    ),
    no_follow_up_exclusions: Count(
      "All Stroke Encounters" E 
        where "IsAdultAtEncounter"(E)
          and "HasDischargeOrVisitRecord"(E)
          and not "HasFollowUpVisit"(E)
    ),
    qualified_stroke_cases: "Denominator",
    cases_with_rehabilitation: "Numerator"
  }

// Encounter類型統計
define "Encounter Type Statistics":
  Tuple {
    emergency_encounters: Count("Denominator Encounters" E where E.type in "Emergency Encounter Codes"),
    inpatient_encounters: Count("Denominator Encounters" E where E.type in "Inpatient Encounter Codes"),
    emergency_with_rehab: Count("Numerator Encounters" E where E.type in "Emergency Encounter Codes"),
    inpatient_with_rehab: Count("Numerator Encounters" E where E.type in "Inpatient Encounter Codes")
  }

// 診斷類型統計
define "Diagnosis Type Statistics":
  Tuple {
    ischemic_stroke_I63: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I63'))
        )
    ),
    hemorrhagic_I60: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I60'))
        )
    ),
    hemorrhagic_I61: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where StartsWith(CD.code, 'I61'))
        )
    ),
    neonatal_stroke_P918: Count(
      "Denominator Encounters" E
        where exists(
          "All Conditions" C
            where C.encounter.reference = 'Encounter/' + E.id
              and exists(C.code.coding CD where CD.code in {'P91821', 'P91822', 'P91823', 'P91829'})
        )
    )
  }

// 復健服務類型統計
define "Rehabilitation Type Statistics":
  Tuple {
    total_with_rehabilitation: "Numerator",
    general_rehab_41002_41007: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsGeneralRehabProcedure"(P)
        )
    ),
    physical_therapy_42001_42019: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsPhysicalTherapyProcedure"(P)
        )
    ),
    occupational_therapy_43001_43038: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsOccupationalTherapyProcedure"(P)
        )
    ),
    communication_therapy_44001_44016: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsCommunicationTherapyProcedure"(P)
        )
    ),
    PAC_FRG1_P5101_P5106: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsPACFRG1Procedure"(P)
        )
    ),
    PAC_FRG2_P5107_P5112: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsPACFRG2Procedure"(P)
        )
    ),
    PAC_FRG1_DayCare_P5119_P5122: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsPACFRG1DayCare"(P)
        )
    ),
    PAC_OT_PACOT1_20: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsPACOTProcedure"(P)
        )
    ),
    PAC_PT_PACPT1_21: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsPACPTProcedure"(P)
        )
    ),
    PAC_ST_PACST1_14: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "IsPACSTProcedure"(P)
        )
    )
  }

// 年齡分組統計
define "Age Group Statistics":
  Tuple {
    age_18_44: Count("Denominator Encounters" E where "GetAgeAtEncounter"(E) >= 18 and "GetAgeAtEncounter"(E) <= 44),
    age_45_64: Count("Denominator Encounters" E where "GetAgeAtEncounter"(E) >= 45 and "GetAgeAtEncounter"(E) <= 64),
    age_65_plus: Count("Denominator Encounters" E where "GetAgeAtEncounter"(E) >= 65),
    age_18_44_with_rehab: Count("Numerator Encounters" E where "GetAgeAtEncounter"(E) >= 18 and "GetAgeAtEncounter"(E) <= 44),
    age_45_64_with_rehab: Count("Numerator Encounters" E where "GetAgeAtEncounter"(E) >= 45 and "GetAgeAtEncounter"(E) <= 64),
    age_65_plus_with_rehab: Count("Numerator Encounters" E where "GetAgeAtEncounter"(E) >= 65)
  }

// 住院天數分組統計
define "Length of Stay Statistics":
  Tuple {
    los_1_3_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period >= 1 and days between start of E.period and end of E.period <= 3),
    los_4_7_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period >= 4 and days between start of E.period and end of E.period <= 7),
    los_8_14_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period >= 8 and days between start of E.period and end of E.period <= 14),
    los_over_14_days: Count("Denominator Encounters" E where days between start of E.period and end of E.period > 14),
    los_1_3_with_rehab: Count("Numerator Encounters" E where days between start of E.period and end of E.period >= 1 and days between start of E.period and end of E.period <= 3),
    los_4_7_with_rehab: Count("Numerator Encounters" E where days between start of E.period and end of E.period >= 4 and days between start of E.period and end of E.period <= 7),
    los_8_14_with_rehab: Count("Numerator Encounters" E where days between start of E.period and end of E.period >= 8 and days between start of E.period and end of E.period <= 14),
    los_over_14_with_rehab: Count("Numerator Encounters" E where days between start of E.period and end of E.period > 14)
  }

// 復健服務次數分析
define "Rehabilitation Frequency Analysis":
  Tuple {
    cases_with_1_5_sessions: Count(
      "Numerator Encounters" E
        where Count("GetRehabilitationProcedures"(E)) >= 1 and Count("GetRehabilitationProcedures"(E)) <= 5
    ),
    cases_with_6_10_sessions: Count(
      "Numerator Encounters" E
        where Count("GetRehabilitationProcedures"(E)) >= 6 and Count("GetRehabilitationProcedures"(E)) <= 10
    ),
    cases_with_11_20_sessions: Count(
      "Numerator Encounters" E
        where Count("GetRehabilitationProcedures"(E)) >= 11 and Count("GetRehabilitationProcedures"(E)) <= 20
    ),
    cases_with_over_20_sessions: Count(
      "Numerator Encounters" E
        where Count("GetRehabilitationProcedures"(E)) > 20
    ),
    total_rehab_sessions: Sum(
      "Numerator Encounters" E
        return Count("GetRehabilitationProcedures"(E))
    ),
    average_sessions_per_case: 
      if "Numerator" > 0
        then Round(
          Sum("Numerator Encounters" E return Count("GetRehabilitationProcedures"(E))) / "Numerator",
          2
        )
        else null
  }

// 復健開始時間分析（住院期間 vs 出院後）
define "Rehabilitation Timing Analysis":
  Tuple {
    rehab_during_hospitalization: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "GetProcedureDate"(P) during E.period
        )
    ),
    rehab_after_discharge: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P
            where "GetProcedureDate"(P) after end of E.period
        )
    ),
    rehab_both_periods: Count(
      "Numerator Encounters" E
        where exists(
          "GetRehabilitationProcedures"(E) P1
            where "GetProcedureDate"(P1) during E.period
        )
        and exists(
          "GetRehabilitationProcedures"(E) P2
            where "GetProcedureDate"(P2) after end of E.period
        )
    )
  }

// 性別統計
define "Gender Statistics":
  Tuple {
    male: Count("Denominator Encounters" E where Patient.gender = 'male'),
    female: Count("Denominator Encounters" E where Patient.gender = 'female'),
    male_with_rehab: Count("Numerator Encounters" E where Patient.gender = 'male'),
    female_with_rehab: Count("Numerator Encounters" E where Patient.gender = 'female')
  }

// ===== 最終報告輸出 =====

define "Final Report":
  Tuple {
    indicator_name: '缺血性或出血性中風病人住院期間或出院後四個月內接受復健服務比率',
    measurement_period: ToString("Measurement Period"),
    clinical_note: '早期復健介入可改善中風患者功能恢復，降低失能程度',
    
    // 整體指標
    overall_numerator: "Numerator",
    overall_denominator: "Denominator",
    overall_rate: "Indicator Rate",
    
    // 分期指標
    period_1_numerator: "Numerator Period 1",
    period_1_denominator: "Denominator Period 1",
    period_1_rate: "Indicator Rate Period 1",
    
    period_2_numerator: "Numerator Period 2",
    period_2_denominator: "Denominator Period 2",
    period_2_rate: "Indicator Rate Period 2",
    
    // 品質檢核
    data_quality: "Data Quality Check",
    
    // Encounter類型統計
    encounter_type_statistics: "Encounter Type Statistics",
    
    // 診斷類型統計
    diagnosis_type_statistics: "Diagnosis Type Statistics",
    
    // 復健服務類型統計
    rehabilitation_type_statistics: "Rehabilitation Type Statistics",
    
    // 年齡分組統計
    age_group_statistics: "Age Group Statistics",
    
    // 住院天數分組統計
    length_of_stay_statistics: "Length of Stay Statistics",
    
    // 復健服務次數分析
    rehabilitation_frequency_analysis: "Rehabilitation Frequency Analysis",
    
    // 復健開始時間分析
    rehabilitation_timing_analysis: "Rehabilitation Timing Analysis",
    
    // 性別統計
    gender_statistics: "Gender Statistics"
  }
