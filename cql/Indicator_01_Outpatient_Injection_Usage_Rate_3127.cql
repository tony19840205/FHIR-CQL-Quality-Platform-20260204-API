library Indicator_01_Outpatient_Injection_Usage_Rate_3127 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 來源：醫療給付項目案分析系統 指標代碼: 3127
// 條件依據：門診注射劑使用率
// 製作日期：2025-11-20
// 
// 【歷史參考基準】111年第1季 (2022Q1)
// 針劑給藥案件數: 54,653
// 給藥案件數: 5,831,409
// 門診注射劑使用率: 0.94%

// 【公式說明】
// 分子: 給藥案件之針劑藥品(醫令代碼為10碼、且第8碼為'2')案件數
// 分母: 給藥案件數
// 排除:
//   1.門診化療注射劑(37005B,37031B~37041B或ATC碼前3碼L01、L02或特定ATC碼)
//   2.急診案件、流感疫苗(ATC前5碼J07BB)、破傷風(ATC:J07AM01)
//   3.門診手術案件(案件分類03)、事前審查藥品、STAT藥品、病人攜回注射藥品

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// 劑型代碼（注射劑）
code "Injection": '385219001' from "SNOMEDCT" display 'Injection'
code "Ampoule": '385221006' from "SNOMEDCT" display 'Ampoule'
code "Vial": '415818006' from "SNOMEDCT" display 'Vial'

// 就醫類型代碼
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - 門診'
code "Emergency": 'EMER' from "ActCode" display 'Emergency - 急診'

// 門診化療注射劑醫令代碼（需排除）
code "37005B": '37005B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37031B": '37031B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37032B": '37032B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37033B": '37033B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37034B": '37034B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37035B": '37035B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37036B": '37036B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37037B": '37037B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37038B": '37038B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37039B": '37039B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37040B": '37040B' from "NHI_PROCEDURE" display '門診化療注射劑'
code "37041B": '37041B' from "NHI_PROCEDURE" display '門診化療注射劑'

// Helper function: 檢查藥品代碼是否符合注射劑格式（10碼且第8碼為'2'）
define function IsInjectionDrugCode(drugCode String):
  Length(drugCode) = 10 and Substring(drugCode, 7, 1) = '2'

// Helper function: 檢查 ATC 代碼是否為需排除的化療藥品
define function IsExcludedChemotherapyDrug(atcCode String):
  Substring(atcCode, 0, 3) in { 'L01', 'L02' } or
  atcCode in {
    'H01AB01', 'L03AB01', 'L03AB04', 'L03AB05', 'L03AB15',
    'L03AC01', 'L03AX03', 'L03AX16', 'L04AX01',
    'M05BA02', 'M05BA03', 'M05BA06', 'M05BA08', 'M05BX04',
    'V10XX03', 'J07AM01'
  }

// Helper function: 檢查是否為流感疫苗
define function IsInfluenzaVaccine(atcCode String):
  Substring(atcCode, 0, 5) = 'J07BB'

// Helper function: 檢查藥品代碼是否為需排除的門診化療注射劑
define function IsExcludedChemoProcedure(procedureCode String):
  procedureCode in {
    '37005B', '37031B', '37032B', '37033B', '37034B', '37035B',
    '37036B', '37037B', '37038B', '37039B', '37040B', '37041B'
  }

// 1. 門診給藥案件（分母）
define "Outpatient Drug Encounters":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'AMB'
    and exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and (
          // 藥費不為0、或給藥天數不為0、或處方調劑方式符合條件
          exists (MR.dosageInstruction DI where DI.timing.repeat.boundsPeriod.start.value is not null)
        )
    )
    // 排除代辦案件
    and not exists (
      E.type T where exists (T.coding C where C.code.value = 'AGENCY')
    )

// 2. 門診注射劑案件（分子）
define "Outpatient Injection Cases":
  "Outpatient Drug Encounters" E
    where exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        // 條件：醫令代碼為10碼且第8碼為'2'
        and exists (
          MR.medicationCodeableConcept.coding MC
            where IsInjectionDrugCode(MC.code.value)
        )
        // 排除門診化療注射劑醫令
        and not exists (
          MR.medicationCodeableConcept.coding MC
            where IsExcludedChemoProcedure(MC.code.value)
        )
        // 排除化療藥品（ATC碼檢查）
        and not exists (
          MR.medicationCodeableConcept.coding MC
            where MC.system.value = 'http://www.whocc.no/atc'
            and IsExcludedChemotherapyDrug(MC.code.value)
        )
        // 排除流感疫苗
        and not exists (
          MR.medicationCodeableConcept.coding MC
            where MC.system.value = 'http://www.whocc.no/atc'
            and IsInfluenzaVaccine(MC.code.value)
        )
        // 排除急診案件
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '02')
        )
        // 排除門診手術案件
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '03')
        )
        // 排除事前審查藥品
        and (MR.extension is null or not exists (
          MR.extension Ext 
            where Ext.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/prior-approval'
            and Ext.valueBoolean.value = true
        ))
        // 排除 STAT 用藥
        and not exists (
          MR.dosageInstruction DI
            where DI.asNeededBoolean.value = true
            or exists (DI.additionalInstruction AI 
              where exists (AI.coding C where C.code.value = 'STAT'))
        )
        // 排除病人攜回注射藥品
        and not exists (
          MR.extension Ext
            where Ext.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/take-home-injection'
            and Ext.valueBoolean.value = true
        )
    )

// 3. 分母：門診給藥案件數
define "Denominator":
  Count(
    distinct "Outpatient Drug Encounters" E
      return E.id.value
  )

// 4. 分子：門診注射劑案件數
define "Numerator":
  Count(
    distinct "Outpatient Injection Cases" E
      return E.id.value
  )

// 5. 指標計算結果：門診注射劑使用率
define "Injection Usage Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null
