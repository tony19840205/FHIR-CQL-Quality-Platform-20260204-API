library Indicator_06_Pediatric_Asthma_ED_Rate_1315Q_1317Y version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 十八歲以下氣喘病人急診率
// 指標代碼: 1315 (季度), 1317 (年度)
// 氣喘: ICD-10-CM J45
// 氣喘用藥: 20種ATC藥品

codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

context Patient

// ============================================
// Helper Functions
// ============================================

define function GetExtBoolean(E FHIR.Encounter, extUrl String):
  exists(
    E.extension Ext
      where Ext.url.value = extUrl
        and (Ext.value as FHIR.boolean).value = true
  )

define function IsAgencyCase(E FHIR.Encounter):
  GetExtBoolean(E, 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case')

define function IsAsthmaCode(diagCode String):
  Substring(diagCode, 0, 3) = 'J45'

define function IsAsthmaMedication(atcCode String):
  atcCode in {
    'R03AC02', 'R03AC03', 'R03AC04', 'R03AC06',
    'R03AC12', 'R03AC13', 'R03AC16', 'R03AC18',
    'R03BA01', 'R03BA02', 'R03BA05', 'R03BA08',
    'R03AK06', 'R03AK07', 'R03AK08',
    'H02AB06', 'H02AB07',
    'R03DC01', 'R03DC03', 'R03DA05'
  }

define function HasAsthmaDiagnosis(E FHIR.Encounter):
  exists(
    [Condition] C
      where C.encounter.reference.value = 'Encounter/' + E.id.value
        and exists(
          C.code.coding Co
            where Co.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
              and IsAsthmaCode(Co.code.value)
        )
  )

define function GetEncounterDate(E FHIR.Encounter):
  date from start of E.period

// ============================================
// Asthma Medication Check
// ============================================

define "All Asthma Medication Requests":
  [MedicationRequest] MR
    where MR.status.value in {'active', 'completed'}
      and IsAsthmaMedication(
        First((MR.medication as FHIR.CodeableConcept).coding).code.value
      )

define function HasAsthmaMedicationInEncounter(E FHIR.Encounter):
  exists(
    "All Asthma Medication Requests" MR
      where MR.encounter.reference.value = 'Encounter/' + E.id.value
  )

// ============================================
// Patient Age Check
// ============================================

define "Patient Birth Date":
  First([Patient]).birthDate.value

define "Patient Age":
  if "Patient Birth Date" is not null then
    AgeInYears()
  else null

define "Is Patient Under 18":
  "Patient Age" is not null and "Patient Age" <= 18

// ============================================
// Data Retrieval
// ============================================

define "All Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and not IsAgencyCase(E)

define "Asthma Encounters":
  "All Encounters" E
    where HasAsthmaDiagnosis(E)

define "Asthma ED Encounters":
  "Asthma Encounters" E
    where E.class.code.value = 'EMER'

define "Asthma Inpatient Encounters":
  "Asthma Encounters" E
    where E.class.code.value = 'IMP'

define "Asthma Outpatient Encounters":
  "Asthma Encounters" E
    where E.class.code.value = 'AMB'

// ============================================
// Condition a: >=1 asthma ED visit
// ============================================

define function HasAsthmaEDVisit(qStart Date, qEnd Date):
  exists(
    "Asthma ED Encounters" E
      where GetEncounterDate(E) in Interval[qStart, qEnd]
  )

define function FirstAsthmaEDDate(qStart Date, qEnd Date):
  Min(
    "Asthma ED Encounters" E
      where GetEncounterDate(E) in Interval[qStart, qEnd]
      return GetEncounterDate(E)
  )

// ============================================
// Condition b: >=1 asthma inpatient visit
// ============================================

define function HasAsthmaInpatient(qStart Date, qEnd Date):
  exists(
    "Asthma Inpatient Encounters" E
      where GetEncounterDate(E) in Interval[qStart, qEnd]
  )

define function FirstAsthmaInpatientDate(qStart Date, qEnd Date):
  Min(
    "Asthma Inpatient Encounters" E
      where GetEncounterDate(E) in Interval[qStart, qEnd]
      return GetEncounterDate(E)
  )

// ============================================
// Condition c: outpatient + prior year 4 visits + 2 with medication
// ============================================

define function HasCurrentQuarterOutpatient(qStart Date, qEnd Date):
  exists(
    "Asthma Outpatient Encounters" E
      where GetEncounterDate(E) in Interval[qStart, qEnd]
  )

define function PriorYearOutpatientVisits(qStart Date, qEnd Date):
  "Asthma Outpatient Encounters" E
    where GetEncounterDate(E) in Interval[qStart - 1 year, qEnd]

define function PriorYearOutpatientCount(qStart Date, qEnd Date):
  Count(PriorYearOutpatientVisits(qStart, qEnd))

define function PriorYearMedicationVisitCount(qStart Date, qEnd Date):
  Count(
    "Asthma Outpatient Encounters" E
      where GetEncounterDate(E) in Interval[qStart - 1 year, qEnd]
        and HasAsthmaMedicationInEncounter(E)
  )

define function MeetsConditionC(qStart Date, qEnd Date):
  HasCurrentQuarterOutpatient(qStart, qEnd)
    and PriorYearOutpatientCount(qStart, qEnd) >= 4
    and PriorYearMedicationVisitCount(qStart, qEnd) >= 2

define function FirstAsthmaOutpatientDate(qStart Date, qEnd Date):
  Min(
    "Asthma Outpatient Encounters" E
      where GetEncounterDate(E) in Interval[qStart, qEnd]
      return GetEncounterDate(E)
  )

// ============================================
// Denominator: Asthma patient under 18 (a or b or c)
// ============================================

define function IsAsthmaPatient(qStart Date, qEnd Date):
  "Is Patient Under 18"
    and (
      HasAsthmaEDVisit(qStart, qEnd)
        or HasAsthmaInpatient(qStart, qEnd)
        or MeetsConditionC(qStart, qEnd)
    )

define function AsthmaPatientDate(qStart Date, qEnd Date):
  if IsAsthmaPatient(qStart, qEnd) then
    Coalesce(
      Min({
        FirstAsthmaEDDate(qStart, qEnd),
        FirstAsthmaInpatientDate(qStart, qEnd),
        FirstAsthmaOutpatientDate(qStart, qEnd)
      }),
      qStart
    )
  else null

// ============================================
// Numerator: ED after asthma patient date
// ============================================

define function HasEDAfterAsthmaDate(qStart Date, qEnd Date):
  if IsAsthmaPatient(qStart, qEnd) then
    exists(
      "Asthma ED Encounters" E
        where GetEncounterDate(E) > AsthmaPatientDate(qStart, qEnd)
          and GetEncounterDate(E) <= qEnd
    )
  else false

// ============================================
// Quarterly Statistics
// ============================================

define "2024Q1 Is Asthma Patient": IsAsthmaPatient(@2024-01-01, @2024-03-31)
define "2024Q1 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2024-01-01, @2024-03-31)

define "2024Q2 Is Asthma Patient": IsAsthmaPatient(@2024-04-01, @2024-06-30)
define "2024Q2 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2024-04-01, @2024-06-30)

define "2024Q3 Is Asthma Patient": IsAsthmaPatient(@2024-07-01, @2024-09-30)
define "2024Q3 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2024-07-01, @2024-09-30)

define "2024Q4 Is Asthma Patient": IsAsthmaPatient(@2024-10-01, @2024-12-31)
define "2024Q4 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2024-10-01, @2024-12-31)

define "2025Q1 Is Asthma Patient": IsAsthmaPatient(@2025-01-01, @2025-03-31)
define "2025Q1 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2025-01-01, @2025-03-31)

define "2025Q2 Is Asthma Patient": IsAsthmaPatient(@2025-04-01, @2025-06-30)
define "2025Q2 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2025-04-01, @2025-06-30)

define "2025Q3 Is Asthma Patient": IsAsthmaPatient(@2025-07-01, @2025-09-30)
define "2025Q3 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2025-07-01, @2025-09-30)

define "2025Q4 Is Asthma Patient": IsAsthmaPatient(@2025-10-01, @2025-12-31)
define "2025Q4 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2025-10-01, @2025-12-31)

define "2026Q1 Is Asthma Patient": IsAsthmaPatient(@2026-01-01, @2026-03-31)
define "2026Q1 Has ED After Diagnosis": HasEDAfterAsthmaDate(@2026-01-01, @2026-03-31)

// ============================================
// Indicator Result
// ============================================

define "Indicator Result":
  Tuple {
    indicatorCodeQuarterly: '1315',
    indicatorCodeAnnual: '1317',
    indicatorName: '十八歲以下氣喘病人急診率',
    asthmaCriteria: 'ICD-10-CM J45',
    denominatorCriteria: 'a)>=1次急診 or b)>=1次住院 or c)當期門診+前一年>=4次門診+其中>=2次有用藥',
    numeratorCriteria: '分母病患中急診日期>氣喘病患日期',
    medicationCount: 20,
    ageLimit: 18,
    quarters: List{
      Tuple { quarter: '2024Q1', isDenominator: "2024Q1 Is Asthma Patient", isNumerator: "2024Q1 Has ED After Diagnosis" },
      Tuple { quarter: '2024Q2', isDenominator: "2024Q2 Is Asthma Patient", isNumerator: "2024Q2 Has ED After Diagnosis" },
      Tuple { quarter: '2024Q3', isDenominator: "2024Q3 Is Asthma Patient", isNumerator: "2024Q3 Has ED After Diagnosis" },
      Tuple { quarter: '2024Q4', isDenominator: "2024Q4 Is Asthma Patient", isNumerator: "2024Q4 Has ED After Diagnosis" },
      Tuple { quarter: '2025Q1', isDenominator: "2025Q1 Is Asthma Patient", isNumerator: "2025Q1 Has ED After Diagnosis" },
      Tuple { quarter: '2025Q2', isDenominator: "2025Q2 Is Asthma Patient", isNumerator: "2025Q2 Has ED After Diagnosis" },
      Tuple { quarter: '2025Q3', isDenominator: "2025Q3 Is Asthma Patient", isNumerator: "2025Q3 Has ED After Diagnosis" },
      Tuple { quarter: '2025Q4', isDenominator: "2025Q4 Is Asthma Patient", isNumerator: "2025Q4 Has ED After Diagnosis" },
      Tuple { quarter: '2026Q1', isDenominator: "2026Q1 Is Asthma Patient", isNumerator: "2026Q1 Has ED After Diagnosis" }
    }
  }
