library Indicator_12_Clean_Surgery_Antibiotic_Over_3Days_Rate_1155 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// 指標名稱: 清淨手術術後使用抗生素超過三日比率
// 指標代碼: 1155
// 資料來源: 醫療給付檔案分析系統
// 製表單位: 衛生福利部 中央健康保險署
// 公式: 分子=手術後>3日使用抗生素案件數 / 分母=清淨手術案件數

parameter "Measurement Period" Interval<DateTime> default Interval[@2024-01-01T00:00:00.0, @2099-12-31T23:59:59.999]

context Patient

// ==================== Helper Functions ====================

define function IsJointRepairCode(code String):
  code in {
    '0YQ50ZZ','0YQ53ZZ','0YQ54ZZ','0YQ60ZZ','0YQ63ZZ','0YQ64ZZ',
    '0YQ70ZZ','0YQ73ZZ','0YQ74ZZ','0YQ80ZZ','0YQ83ZZ','0YQ84ZZ',
    '0YQC0ZZ','0YQC3ZZ','0YQC4ZZ','0YQE0ZZ','0YQE3ZZ','0YQE4ZZ'
  }

define function IsJointNHICode(code String):
  code in {'75607C','75610B','75613C','75614C','75615C','88029C'}

define function IsThyroidSurgeryCode(code String):
  code in {
    '0GBG0ZZ','0GBG3ZZ','0GBG4ZZ','0GBH0ZZ','0GBH3ZZ','0GBH4ZZ',
    '0GTG0ZZ','0GTG4ZZ','0GTH0ZZ','0GTH4ZZ','0GTK0ZZ','0GTK4ZZ'
  }

define function IsThyroidNHICode(code String):
  code in {'64162B','64164B','64169B','64170B'}

define function IsJointReplacementCode(code String):
  code in {
    '0SR9019','0SR901A','0SR901Z','0SR9029','0SR902A','0SR902Z',
    '0SR9039','0SR903A','0SR903Z','0SR907Z',
    '0SRB019','0SRB01A','0SRB01Z','0SRB029','0SRB02A','0SRB02Z',
    '0SRB039','0SRB03A','0SRB03Z','0SRB04Z','0SRB07Z',
    '0SRC019','0SRC01A','0SRC01Z','0SRC029','0SRC03A','0SRC03Z',
    '0SRD019','0SRD01A','0SRD01Z','0SRD029','0SRD02A','0SRD02Z',
    '0SRD039','0SRD03A','0SRD03Z','0SRD04Z','0SRD07Z',
    '0SRE019','0SRE01A','0SRE01Z','0SRE029','0SRE02A','0SRE02Z',
    '0SRE039','0SRE03A','0SRE03Z','0SRE04Z','0SRE07Z',
    '0SRF019','0SRF01A','0SRF01Z','0SRF029','0SRF02A','0SRF02Z',
    '0SRF039','0SRF03A','0SRF03Z',
    '0SRG019','0SRG01A','0SRG01Z','0SRG029','0SRG02A','0SRG02Z',
    '0SRG039','0SRG03A','0SRG03Z','0SRG04Z','0SRG07Z',
    '0SRH019','0SRH01A','0SRH01Z','0SRH029','0SRH02A','0SRH02Z',
    '0SRH039','0SRH03A','0SRH03Z','0SRH04Z','0SRH07Z',
    '0SRJ019','0SRJ01A','0SRJ01Z','0SRJ029','0SRJ02A','0SRJ02Z',
    '0SRJ039','0SRJ03A','0SRJ03Z','0SRJ04Z','0SRJ07Z',
    '0SRK019','0SRK01A','0SRK01Z','0SRK029','0SRK02A','0SRK02Z',
    '0SRK039','0SRK03A','0SRK03Z','0SRK04Z','0SRK07Z',
    '0SRT019','0SRT01A','0SRT01Z','0SRT029','0SRT02A','0SRT02Z',
    '0SRT039','0SRT03A','0SRT03Z','0SRT04Z','0SRT07Z',
    '0SRU019','0SRU01A','0SRU01Z','0SRU029','0SRU02A','0SRU02Z',
    '0SRU039','0SRU03A','0SRU03Z','0SRU04Z','0SRU07Z',
    '0SRV019','0SRV01A','0SRV01Z','0SRV029','0SRV02A','0SRV02Z',
    '0SRV039','0SRV03A','0SRV03Z','0SRV04Z','0SRV07Z',
    '0SRW019','0SRW01A','0SRW01Z','0SRW029','0SRW02A','0SRW02Z',
    '0SRW039','0SRW03A','0SRW03Z','0SRW04Z','0SRW07Z'
  }

define function IsExclusionDiagPrefix3(prefix3 String):
  prefix3 in {
    'C40','C41','D65','D66','D67','D68',
    'H65','H66','H67','H68','H69',
    'J12','J13','J14','J15','J16','J17','J18',
    'N30','N34'
  }

define function IsThyroidDiagPrefix3(prefix3 String):
  prefix3 in {'E00','E01','E02','E03','E04','E05','E06','E07','E35'}

define function GetProcedureCode(P Procedure):
  First(P.code.coding).code.value

define function GetDischargeDate(E Encounter):
  end of E.period

// ==================== Base Data ====================

define "All Inpatient Encounters":
  [Encounter] E
    where E.status.value = 'finished'
      and E.class.code.value = 'IMP'
      and GetDischargeDate(E) during "Measurement Period"

define "All Procedures":
  [Procedure] P where P.status.value = 'completed'

define "All Conditions":
  [Condition] C

// ==================== Diagnosis Helpers ====================

define function GetMainDiagCode(E Encounter):
  First(
    "All Conditions" C
      where C.encounter.reference.value = 'Encounter/' + E.id.value
      return First(C.code.coding).code.value
  )

define function GetDiagPrefix3(E Encounter):
  if GetMainDiagCode(E) is not null and Length(GetMainDiagCode(E)) >= 3
    then Substring(GetMainDiagCode(E), 0, 3)
    else null

// ==================== Clean Surgery Category 1: Joint Repair ====================

define function HasJointRepairProc(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and IsJointRepairCode(GetProcedureCode(P))
  )

define function HasJointNHIProc(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and IsJointNHICode(GetProcedureCode(P))
  )

define function IsCleanSurgeryJointRepair(E Encounter):
  HasJointRepairProc(E)
    and HasJointNHIProc(E)
    and not IsExclusionDiagPrefix3(GetDiagPrefix3(E))
    and GetMainDiagCode(E) != 'N390'

// ==================== Clean Surgery Category 2: Thyroid ====================

define function HasThyroidProc(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and IsThyroidSurgeryCode(GetProcedureCode(P))
  )

define function HasThyroidNHIProc(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and IsThyroidNHICode(GetProcedureCode(P))
  )

define function IsCleanSurgeryThyroid(E Encounter):
  HasThyroidProc(E)
    and HasThyroidNHIProc(E)
    and (IsThyroidDiagPrefix3(GetDiagPrefix3(E)) or GetMainDiagCode(E) in {'E89.0','D44.0'})
    and not IsExclusionDiagPrefix3(GetDiagPrefix3(E))
    and GetMainDiagCode(E) != 'N390'

// ==================== Clean Surgery Category 3: Joint Replacement (0SR series) ====================

define function HasJointReplacementProc(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and IsJointReplacementCode(GetProcedureCode(P))
  )

define function HasReplacementNHIProc(E Encounter):
  exists(
    "All Procedures" P
      where P.encounter.reference.value = 'Encounter/' + E.id.value
        and GetProcedureCode(P) in {'64162B','64164B','64169B','64170B'}
  )

define function IsCleanSurgeryJointReplacement(E Encounter):
  HasJointReplacementProc(E)
    and HasReplacementNHIProc(E)
    and not IsExclusionDiagPrefix3(GetDiagPrefix3(E))
    and GetMainDiagCode(E) != 'N390'

// ==================== Combined Clean Surgery ====================

define function IsCleanSurgery(E Encounter):
  IsCleanSurgeryJointRepair(E)
    or IsCleanSurgeryThyroid(E)
    or IsCleanSurgeryJointReplacement(E)

// ==================== Antibiotic Requests ====================

define "All Antibiotic Requests":
  [MedicationRequest] M
    where M.status.value in {'active','completed'}
      and StartsWith(First((M.medication as CodeableConcept).coding).code.value, 'J01')

define function GetAntibioticOrderCount(E Encounter):
  Count(
    "All Antibiotic Requests" M
      where M.encounter.reference.value = 'Encounter/' + E.id.value
  )

// ==================== Denominator & Numerator ====================

define "Clean Surgery Cases":
  "All Inpatient Encounters" E
    where IsCleanSurgery(E)

define "Antibiotic Over 3 Days Cases":
  "Clean Surgery Cases" E
    where GetAntibioticOrderCount(E) > 3

// ==================== Quarterly Date Ranges ====================

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

// ==================== Quarterly Statistics ====================

define "2024Q1 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q1 Start", "2024Q1 End"])
define "2024Q1 Rate": if "2024Q1 Denominator" > 0 then (ToDecimal("2024Q1 Numerator") / ToDecimal("2024Q1 Denominator")) * 100 else null

define "2024Q2 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q2 Start", "2024Q2 End"])
define "2024Q2 Rate": if "2024Q2 Denominator" > 0 then (ToDecimal("2024Q2 Numerator") / ToDecimal("2024Q2 Denominator")) * 100 else null

define "2024Q3 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q3 Start", "2024Q3 End"])
define "2024Q3 Rate": if "2024Q3 Denominator" > 0 then (ToDecimal("2024Q3 Numerator") / ToDecimal("2024Q3 Denominator")) * 100 else null

define "2024Q4 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2024Q4 Start", "2024Q4 End"])
define "2024Q4 Rate": if "2024Q4 Denominator" > 0 then (ToDecimal("2024Q4 Numerator") / ToDecimal("2024Q4 Denominator")) * 100 else null

define "2025Q1 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q1 Start", "2025Q1 End"])
define "2025Q1 Rate": if "2025Q1 Denominator" > 0 then (ToDecimal("2025Q1 Numerator") / ToDecimal("2025Q1 Denominator")) * 100 else null

define "2025Q2 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q2 Start", "2025Q2 End"])
define "2025Q2 Rate": if "2025Q2 Denominator" > 0 then (ToDecimal("2025Q2 Numerator") / ToDecimal("2025Q2 Denominator")) * 100 else null

define "2025Q3 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q3 Start", "2025Q3 End"])
define "2025Q3 Rate": if "2025Q3 Denominator" > 0 then (ToDecimal("2025Q3 Numerator") / ToDecimal("2025Q3 Denominator")) * 100 else null

define "2025Q4 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2025Q4 Start", "2025Q4 End"])
define "2025Q4 Rate": if "2025Q4 Denominator" > 0 then (ToDecimal("2025Q4 Numerator") / ToDecimal("2025Q4 Denominator")) * 100 else null

define "2026Q1 Numerator": Count("Antibiotic Over 3 Days Cases" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Denominator": Count("Clean Surgery Cases" E where GetDischargeDate(E) in Interval["2026Q1 Start", "2026Q1 End"])
define "2026Q1 Rate": if "2026Q1 Denominator" > 0 then (ToDecimal("2026Q1 Numerator") / ToDecimal("2026Q1 Denominator")) * 100 else null

define "Total Numerator": Count("Antibiotic Over 3 Days Cases")
define "Total Denominator": Count("Clean Surgery Cases")
define "Total Rate": if "Total Denominator" > 0 then (ToDecimal("Total Numerator") / ToDecimal("Total Denominator")) * 100 else null

// ==================== Indicator Result ====================

define "Indicator Result":
  Tuple {
    indicatorCode: '1155',
    indicatorName: '清淨手術術後使用抗生素超過三日比率',
    measurementPeriod: "Measurement Period",
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
