library Indicator_01_Outpatient_Injection_Usage_Rate_3127 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 靘?嚗?策隞??格???蝟餌絞 ??隞?Ⅳ: 3127
// 璇辣靘?嚗?閮箸釣撠?雿輻??
// 鋆賭??交?嚗?025-11-20
// 
// ?風?脣??皞?11撟渡洵1摮?(2022Q1)
// ??蝯西獢辣?? 54,653
// 蝯西獢辣?? 5,831,409
// ?閮箸釣撠?雿輻?? 0.94%

// ?撘牧??
// ??: 蝯西獢辣銋?????思誘隞?Ⅳ??0蝣潦?蝚?蝣潛'2')獢辣??
// ??: 蝯西獢辣??
// ?:
//   1.?閮箏??釣撠?(37005B,37031B~37041B?TC蝣澆?3蝣嘴01?02?摰TC蝣?
//   2.?亥那獢辣?????ATC??蝣嘲07BB)??琿◢(ATC:J07AM01)
//   3.?閮箸?銵?隞?獢辣??03)???祟?亥?TAT?亙???鈭箸??釣撠??

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'

// ??隞?Ⅳ嚗釣撠?嚗?
code "Injection": '385219001' from "SNOMEDCT" display 'Injection'
code "Ampoule": '385221006' from "SNOMEDCT" display 'Ampoule'
code "Vial": '415818006' from "SNOMEDCT" display 'Vial'

// 撠梢憿?隞?Ⅳ
code "Ambulatory": 'AMB' from "ActCode" display 'Ambulatory - ?閮?
code "Emergency": 'EMER' from "ActCode" display 'Emergency - ?亥那'

// ?閮箏??釣撠??思誘隞?Ⅳ嚗??嚗?
code "37005B": '37005B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37031B": '37031B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37032B": '37032B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37033B": '37033B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37034B": '37034B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37035B": '37035B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37036B": '37036B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37037B": '37037B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37038B": '37038B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37039B": '37039B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37040B": '37040B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'
code "37041B": '37041B' from "NHI_PROCEDURE" display '?閮箏??釣撠?'

// Helper function: 瑼Ｘ?亙?隞?Ⅳ?臬蝚血?瘜典??撘?10蝣潔?蝚?蝣潛'2'嚗?
define function IsInjectionDrugCode(drugCode String):
  Length(drugCode) = 10 and Substring(drugCode, 7, 1) = '2'

// Helper function: 瑼Ｘ ATC 隞?Ⅳ?臬?粹???????
define function IsExcludedChemotherapyDrug(atcCode String):
  Substring(atcCode, 0, 3) in { 'L01', 'L02' } or
  atcCode in {
    'H01AB01', 'L03AB01', 'L03AB04', 'L03AB05', 'L03AB15',
    'L03AC01', 'L03AX03', 'L03AX16', 'L04AX01',
    'M05BA02', 'M05BA03', 'M05BA06', 'M05BA08', 'M05BX04',
    'V10XX03', 'J07AM01'
  }

// Helper function: 瑼Ｘ?臬?箸????
define function IsInfluenzaVaccine(atcCode String):
  Substring(atcCode, 0, 5) = 'J07BB'

// Helper function: 瑼Ｘ?亙?隞?Ⅳ?臬?粹????閮箏??釣撠?
define function IsExcludedChemoProcedure(procedureCode String):
  procedureCode in {
    '37005B', '37031B', '37032B', '37033B', '37034B', '37035B',
    '37036B', '37037B', '37038B', '37039B', '37040B', '37041B'
  }

// 1. ?閮箇策?交?隞塚???嚗?
define "Outpatient Drug Encounters":
  [Encounter] E
    where E.status.value = 'finished'
    and E.class.code.value = 'AMB'
    and exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        and (
          // ?亥祥銝0??蝯西憭拇銝0???隤踹??孵?蝚血?璇辣
          exists (MR.dosageInstruction DI where DI.timing.repeat.bounds is not null)
        )
    )
    // ?隞?齒獢辣
    and not exists (
      E.type T where exists (T.coding C where C.code.value = 'AGENCY')
    )

// 2. ?閮箸釣撠?獢辣嚗?摮?
define "Outpatient Injection Cases":
  "Outpatient Drug Encounters" E
    where exists (
      [MedicationRequest] MR
        where MR.encounter.reference.value = 'Encounter/' + E.id.value
        and MR.status.value = 'completed'
        // 璇辣嚗隞支誨蝣潛10蝣潔?蝚?蝣潛'2'
        and exists (
          MR.(medication as FHIR.CodeableConcept).coding MC
            where IsInjectionDrugCode(MC.code.value)
        )
        // ??閮箏??釣撠??思誘
        and not exists (
          MR.(medication as FHIR.CodeableConcept).coding MC
            where IsExcludedChemoProcedure(MC.code.value)
        )
        // ????亙?嚗TC蝣潭炎?伐?
        and not exists (
          MR.(medication as FHIR.CodeableConcept).coding MC
            where MC.system.value = 'http://www.whocc.no/atc'
            and IsExcludedChemotherapyDrug(MC.code.value)
        )
        // ?瘚??怨?
        and not exists (
          MR.(medication as FHIR.CodeableConcept).coding MC
            where MC.system.value = 'http://www.whocc.no/atc'
            and IsInfluenzaVaccine(MC.code.value)
        )
        // ??亥那獢辣
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '02')
        )
        // ??閮箸?銵?隞?
        and not exists (
          E.type T where exists (T.coding C where C.code.value = '03')
        )
        // ?鈭?撖拇?亙?
        and (MR.extension is null or not exists (
          MR.extension Ext 
            where Ext.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/prior-approval'
            and Ext.(value as FHIR.boolean).value = true
        ))
        // ? STAT ?刻
        and not exists (
          MR.dosageInstruction DI
            where DI.(asNeeded as FHIR.boolean).value = true
            or exists (DI.additionalInstruction AI 
              where exists (AI.coding C where C.code.value = 'STAT'))
        )
        // ??犖??瘜典??亙?
        and not exists (
          MR.extension Ext
            where Ext.url.value = 'http://www.nhi.gov.tw/fhir/StructureDefinition/take-home-injection'
            and Ext.(value as FHIR.boolean).value = true
        )
    )

// 3. ??嚗?閮箇策?交?隞嗆
define "Denominator":
  Count(
    distinct "Outpatient Drug Encounters" E
      return E.id.value
  )

// 4. ??嚗?閮箸釣撠?獢辣??
define "Numerator":
  Count(
    distinct "Outpatient Injection Cases" E
      return E.id.value
  )

// 5. ??閮?蝯?嚗?閮箸釣撠?雿輻??
define "Injection Usage Rate":
  if "Denominator" > 0 then
    ("Numerator" / "Denominator") * 100
  else
    null
