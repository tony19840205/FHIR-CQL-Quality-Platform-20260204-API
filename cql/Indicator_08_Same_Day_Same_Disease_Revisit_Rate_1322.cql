library Indicator_08_Same_Day_Same_Disease_Revisit_Rate_1322 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 就診後同日於同醫院因同疾病再次就診率
// 指標代碼: 1322

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// ============================================
// Helper Functions
// ============================================

define function GetExtValue(E FHIR.Encounter, extUrl String):
  First(
    E.extension Ext
      where Ext.url.value = extUrl
      return (Ext.value as FHIR.code).value
  )

define function GetExtDecimal(E FHIR.Encounter, extUrl String):
  Coalesce(
    First(
      E.extension Ext
        where Ext.url.value = extUrl
        return (Ext.value as FHIR.decimal).value
    ),
    0
  )

define function GetExtBoolean(E FHIR.Encounter, extUrl String):
  exists(
    E.extension Ext
      where Ext.url.value = extUrl
        and (Ext.value as FHIR.boolean).value = true
  )

define function GetMainDiagCode(E FHIR.Encounter):
  First(
    [Condition] C
      where C.encounter.reference.value = 'Encounter/' + E.id.value
      return First(C.code.coding Co where Co.system.value = 'http://hl7.org/fhir/sid/icd-10-cm' return Co.code.value)
  )

define function GetDiagPrefix3(code String):
  if Length(code) >= 3 then Substring(code, 0, 3)
  else code

define function GetHospitalId(E FHIR.Encounter):
  Coalesce(E.serviceProvider.reference.value, '')

define function GetEncounterDate(E FHIR.Encounter):
  date from start of E.period

define function GetConsultationFee(E FHIR.Encounter):
  GetExtDecimal(E, 'http://nhi.gov.tw/fhir/StructureDefinition/consultation-fee')

define function GetCaseType(E FHIR.Encounter):
  Coalesce(GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/case-type'), '')

define function GetRegionCode(E FHIR.Encounter):
  Coalesce(GetExtValue(E, 'http://nhi.gov.tw/fhir/StructureDefinition/region-code'), '')

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

define function IsCatastrophicIllness(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/catastrophic-illness')

define function IsSpecialProgram(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/special-program')

define function ToDecimal(v Integer):
  v * 1.0

// ============================================
// Data Retrieval
// ============================================

define "All Outpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'AMB'

define "Valid Encounters":
  "All Outpatient Encounters" E
    where GetConsultationFee(E) > 0
      and not IsAgencyCase(E)
      and not IsCatastrophicIllness(E)
      and not IsSpecialProgram(E)
      and not (GetCaseType(E) in {'02', '03'})

define "Encounters With Diagnosis":
  "Valid Encounters" E
    where GetMainDiagCode(E) is not null
      and Length(GetMainDiagCode(E)) >= 3

// ============================================
// Same-Day Revisit Detection
// ============================================

define function HasSameDayRevisit(enc FHIR.Encounter):
  exists(
    "Encounters With Diagnosis" E2
      where E2.id.value != enc.id.value
        and GetEncounterDate(E2) = GetEncounterDate(enc)
        and GetHospitalId(E2) = GetHospitalId(enc)
        and GetRegionCode(E2) = GetRegionCode(enc)
        and GetDiagPrefix3(GetMainDiagCode(E2)) = GetDiagPrefix3(GetMainDiagCode(enc))
  )

define "Same Day Revisit Encounters":
  "Encounters With Diagnosis" E
    where HasSameDayRevisit(E)

// ============================================
// Quarterly Date Ranges
// ============================================

define "2024Q1 Start": DateTime(2024, 1, 1, 0, 0, 0, 0)
define "2024Q1 End": DateTime(2024, 3, 31, 23, 59, 59, 999)
define "2024Q2 Start": DateTime(2024, 4, 1, 0, 0, 0, 0)
define "2024Q2 End": DateTime(2024, 6, 30, 23, 59, 59, 999)
define "2024Q3 Start": DateTime(2024, 7, 1, 0, 0, 0, 0)
define "2024Q3 End": DateTime(2024, 9, 30, 23, 59, 59, 999)
define "2024Q4 Start": DateTime(2024, 10, 1, 0, 0, 0, 0)
define "2024Q4 End": DateTime(2024, 12, 31, 23, 59, 59, 999)
define "2025Q1 Start": DateTime(2025, 1, 1, 0, 0, 0, 0)
define "2025Q1 End": DateTime(2025, 3, 31, 23, 59, 59, 999)
define "2025Q2 Start": DateTime(2025, 4, 1, 0, 0, 0, 0)
define "2025Q2 End": DateTime(2025, 6, 30, 23, 59, 59, 999)
define "2025Q3 Start": DateTime(2025, 7, 1, 0, 0, 0, 0)
define "2025Q3 End": DateTime(2025, 9, 30, 23, 59, 59, 999)
define "2025Q4 Start": DateTime(2025, 10, 1, 0, 0, 0, 0)
define "2025Q4 End": DateTime(2025, 12, 31, 23, 59, 59, 999)
define "2026Q1 Start": DateTime(2026, 1, 1, 0, 0, 0, 0)
define "2026Q1 End": DateTime(2026, 3, 31, 23, 59, 59, 999)

// ============================================
// Quarterly Statistics
// ============================================

define "2024Q1 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Denominator": Count("Encounters With Diagnosis" E where start of E.period in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Numerator": Count("Same Day Revisit Encounters" E where start of E.period in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

define "Total Denominator": Count("Encounters With Diagnosis")
define "Total Numerator": Count("Same Day Revisit Encounters")
define "Total Rate": if "Total Denominator" > 0 then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100 else null

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCode: '1322',
    indicatorName: '就診後同日於同醫院因同疾病再次就診率',
    sameDayCriteria: '同一人+同一天+同一疾病(主診斷前三碼)+同一分區+同一院所',
    revisitThreshold: 2,
    excludedCases: '代辦案件、重大傷病、急診、門診手術、特殊計畫、診察費=0',
    quarters: List{
      Tuple { quarter: '2024Q1', numerator: "2024Q1 Numerator", denominator: "2024Q1 Denominator", rate: "2024Q1 Rate" },
      Tuple { quarter: '2024Q2', numerator: "2024Q2 Numerator", denominator: "2024Q2 Denominator", rate: "2024Q2 Rate" },
      Tuple { quarter: '2024Q3', numerator: "2024Q3 Numerator", denominator: "2024Q3 Denominator", rate: "2024Q3 Rate" },
      Tuple { quarter: '2024Q4', numerator: "2024Q4 Numerator", denominator: "2024Q4 Denominator", rate: "2024Q4 Rate" },
      Tuple { quarter: '2025Q1', numerator: "2025Q1 Numerator", denominator: "2025Q1 Denominator", rate: "2025Q1 Rate" },
      Tuple { quarter: '2025Q2', numerator: "2025Q2 Numerator", denominator: "2025Q2 Denominator", rate: "2025Q2 Rate" },
      Tuple { quarter: '2025Q3', numerator: "2025Q3 Numerator", denominator: "2025Q3 Denominator", rate: "2025Q3 Rate" },
      Tuple { quarter: '2025Q4', numerator: "2025Q4 Numerator", denominator: "2025Q4 Denominator", rate: "2025Q4 Rate" },
      Tuple { quarter: '2026Q1', numerator: "2026Q1 Numerator", denominator: "2026Q1 Denominator", rate: "2026Q1 Rate" }
    },
    total: Tuple { numerator: "Total Numerator", denominator: "Total Denominator", rate: "Total Rate" }
  }
