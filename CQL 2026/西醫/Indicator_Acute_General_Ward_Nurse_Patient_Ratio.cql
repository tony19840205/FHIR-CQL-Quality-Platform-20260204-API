library Indicator_Acute_General_Ward_Nurse_Patient_Ratio version '1.0.0'

/*
急性一般病床全日平均護病比
Acute General Ward Average Daily Nurse-to-Patient Ratio

計算說明:
- 分子：(參考醫院評鑑基準)醫院急性一般病床床位數 × 占床率 × 3
- 分母：全日平均三班護理人員數
- 計算公式：分子/分母，計算至小數位第一位
- 計算頻率：每季或每月

備註:
1. 急性一般病床：包含急性一般病床、經濟病床、精神急性一般病床、精神急性經濟病床
2. 表列醫院，不含未設置「急性一般(經濟)、精神急性一般(經濟)病床」醫院
3. 表列醫院各項數據如為空值，表示醫院未登錄相關資料；占床率如為0，表示醫院急性一般病床未收治病人
4. 此指標為醫療品質管理指標，數值越小表示護理人力配置越充足

定義:
- 急性一般病床床位數：醫院登記之急性一般病床、經濟病床、精神急性一般病床、精神急性經濟病床的總床位數
- 占床率：實際使用床位數 / 總床位數 × 100%
- 全日平均三班護理人員數：包含日班、小夜班、大夜班的平均護理人員總數

Version History:
- 1.0.0: Initial implementation (2026-01-07)
*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ===== 參數定義 =====

// 測量期間：2026年全年
parameter "Measurement Period" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 季度期間定義
parameter "Q1 2026" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-03-31T23:59:59.0]

parameter "Q2 2026" Interval<DateTime>
  default Interval[@2026-04-01T00:00:00.0, @2026-06-30T23:59:59.0]

parameter "Q3 2026" Interval<DateTime>
  default Interval[@2026-07-01T00:00:00.0, @2026-09-30T23:59:59.0]

parameter "Q4 2026" Interval<DateTime>
  default Interval[@2026-10-01T00:00:00.0, @2026-12-31T23:59:59.0]

// 月度期間定義（1-12月）
parameter "M1 2026" Interval<DateTime>
  default Interval[@2026-01-01T00:00:00.0, @2026-01-31T23:59:59.0]

parameter "M2 2026" Interval<DateTime>
  default Interval[@2026-02-01T00:00:00.0, @2026-02-28T23:59:59.0]

parameter "M3 2026" Interval<DateTime>
  default Interval[@2026-03-01T00:00:00.0, @2026-03-31T23:59:59.0]

parameter "M4 2026" Interval<DateTime>
  default Interval[@2026-04-01T00:00:00.0, @2026-04-30T23:59:59.0]

parameter "M5 2026" Interval<DateTime>
  default Interval[@2026-05-01T00:00:00.0, @2026-05-31T23:59:59.0]

parameter "M6 2026" Interval<DateTime>
  default Interval[@2026-06-01T00:00:00.0, @2026-06-30T23:59:59.0]

parameter "M7 2026" Interval<DateTime>
  default Interval[@2026-07-01T00:00:00.0, @2026-07-31T23:59:59.0]

parameter "M8 2026" Interval<DateTime>
  default Interval[@2026-08-01T00:00:00.0, @2026-08-31T23:59:59.0]

parameter "M9 2026" Interval<DateTime>
  default Interval[@2026-09-01T00:00:00.0, @2026-09-30T23:59:59.0]

parameter "M10 2026" Interval<DateTime>
  default Interval[@2026-10-01T00:00:00.0, @2026-10-31T23:59:59.0]

parameter "M11 2026" Interval<DateTime>
  default Interval[@2026-11-01T00:00:00.0, @2026-11-30T23:59:59.0]

parameter "M12 2026" Interval<DateTime>
  default Interval[@2026-12-01T00:00:00.0, @2026-12-31T23:59:59.0]

// ===== 編碼系統定義 =====

// 台灣健保床位類型代碼系統
codesystem "TWBedType": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/bed-type-tw'

// 台灣健保Extension系統
codesystem "TWExtension": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/extension-tw'

// ===== 床位類型代碼定義 =====

// 急性一般病床類型
code "Acute_General_Bed": '01' from "TWBedType" display '急性一般病床'
code "Economy_Bed": '02' from "TWBedType" display '經濟病床'
code "Psychiatric_Acute_General_Bed": '11' from "TWBedType" display '精神急性一般病床'
code "Psychiatric_Acute_Economy_Bed": '12' from "TWBedType" display '精神急性經濟病床'

// ===== 資料來源定義 =====

context Patient

// ===== 醫院Location資源 =====

// 取得所有急性一般病床的Location
define "Acute General Ward Locations":
  [Location] L
    where L.type in "Acute General Ward Bed Types"
      and L.status = 'active'

// 急性一般病床類型
define "Acute General Ward Bed Types":
  {
    "Acute_General_Bed",
    "Economy_Bed",
    "Psychiatric_Acute_General_Bed",
    "Psychiatric_Acute_Economy_Bed"
  }

// ===== 床位數計算函數 =====

// 從Location Extension中取得床位數
define function "GetBedCount"(location Location):
  (singleton from (
    location.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/bed-count'
  )).value as Integer

// 從Location Extension中取得占床數（實際使用床位數）
define function "GetOccupiedBedCount"(location Location, period Interval<DateTime>):
  (singleton from (
    location.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/occupied-bed-count'
        and E.extension.exists(ex where ex.url = 'period' and ex.value as Period overlaps period)
  )).value as Integer

// 計算占床率
define function "CalculateOccupancyRate"(location Location, period Interval<DateTime>):
  if "GetBedCount"(location) > 0 then
    ("GetOccupiedBedCount"(location, period) / "GetBedCount"(location)) * 100.0
  else
    0.0

// ===== 護理人員資源 =====

// 取得所有護理人員（Practitioner角色為護理師）
define "All Nurses":
  [Practitioner] P
    where exists (
      [PractitionerRole] PR
        where PR.practitioner.reference = 'Practitioner/' + P.id
          and PR.code.exists(c => 
            c.coding.exists(coding => 
              coding.system = 'http://snomed.info/sct' 
              and coding.code in { '106292003', '224535009' } // Nurse, Registered Nurse
            )
          )
    )

// 從Organization Extension中取得指定期間的平均護理人員數
define function "GetAverageNurseCount"(organization Organization, period Interval<DateTime>):
  (singleton from (
    organization.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/average-nurse-count'
        and E.extension.exists(ex where ex.url = 'period' and ex.value as Period overlaps period)
  )).value as Decimal

// 從Organization Extension中取得全日平均三班護理人員數
define function "GetDailyAverageThreeShiftNurseCount"(organization Organization, period Interval<DateTime>):
  (singleton from (
    organization.extension E
      where E.url = 'https://twcore.mohw.gov.tw/ig/twcore/StructureDefinition/daily-average-three-shift-nurse-count'
        and E.extension.exists(ex where ex.url = 'period' and ex.value as Period overlaps period)
  )).value as Decimal

// ===== 分子計算 =====

// 計算指定期間的分子（急性一般病床床位數 × 占床率 × 3）
define function "CalculateNumeratorForPeriod"(period Interval<DateTime>):
  Sum(
    "Acute General Ward Locations" L
      return "GetBedCount"(L) * ("CalculateOccupancyRate"(L, period) / 100.0) * 3.0
  )

// 年度分子
define "Numerator Annual":
  "CalculateNumeratorForPeriod"("Measurement Period")

// 季度分子
define "Numerator Q1":
  "CalculateNumeratorForPeriod"("Q1 2026")

define "Numerator Q2":
  "CalculateNumeratorForPeriod"("Q2 2026")

define "Numerator Q3":
  "CalculateNumeratorForPeriod"("Q3 2026")

define "Numerator Q4":
  "CalculateNumeratorForPeriod"("Q4 2026")

// 月度分子
define "Numerator M1":
  "CalculateNumeratorForPeriod"("M1 2026")

define "Numerator M2":
  "CalculateNumeratorForPeriod"("M2 2026")

define "Numerator M3":
  "CalculateNumeratorForPeriod"("M3 2026")

define "Numerator M4":
  "CalculateNumeratorForPeriod"("M4 2026")

define "Numerator M5":
  "CalculateNumeratorForPeriod"("M5 2026")

define "Numerator M6":
  "CalculateNumeratorForPeriod"("M6 2026")

define "Numerator M7":
  "CalculateNumeratorForPeriod"("M7 2026")

define "Numerator M8":
  "CalculateNumeratorForPeriod"("M8 2026")

define "Numerator M9":
  "CalculateNumeratorForPeriod"("M9 2026")

define "Numerator M10":
  "CalculateNumeratorForPeriod"("M10 2026")

define "Numerator M11":
  "CalculateNumeratorForPeriod"("M11 2026")

define "Numerator M12":
  "CalculateNumeratorForPeriod"("M12 2026")

// ===== 分母計算 =====

// 取得醫院Organization
define "Hospital Organization":
  singleton from [Organization] O
    where O.type.exists(t => 
      t.coding.exists(c => 
        c.system = 'http://terminology.hl7.org/CodeSystem/organization-type'
        and c.code = 'prov'
      )
    )

// 計算指定期間的分母（全日平均三班護理人員數）
define function "CalculateDenominatorForPeriod"(period Interval<DateTime>):
  "GetDailyAverageThreeShiftNurseCount"("Hospital Organization", period)

// 年度分母
define "Denominator Annual":
  "CalculateDenominatorForPeriod"("Measurement Period")

// 季度分母
define "Denominator Q1":
  "CalculateDenominatorForPeriod"("Q1 2026")

define "Denominator Q2":
  "CalculateDenominatorForPeriod"("Q2 2026")

define "Denominator Q3":
  "CalculateDenominatorForPeriod"("Q3 2026")

define "Denominator Q4":
  "CalculateDenominatorForPeriod"("Q4 2026")

// 月度分母
define "Denominator M1":
  "CalculateDenominatorForPeriod"("M1 2026")

define "Denominator M2":
  "CalculateDenominatorForPeriod"("M2 2026")

define "Denominator M3":
  "CalculateDenominatorForPeriod"("M3 2026")

define "Denominator M4":
  "CalculateDenominatorForPeriod"("M4 2026")

define "Denominator M5":
  "CalculateDenominatorForPeriod"("M5 2026")

define "Denominator M6":
  "CalculateDenominatorForPeriod"("M6 2026")

define "Denominator M7":
  "CalculateDenominatorForPeriod"("M7 2026")

define "Denominator M8":
  "CalculateDenominatorForPeriod"("M8 2026")

define "Denominator M9":
  "CalculateDenominatorForPeriod"("M9 2026")

define "Denominator M10":
  "CalculateDenominatorForPeriod"("M10 2026")

define "Denominator M11":
  "CalculateDenominatorForPeriod"("M11 2026")

define "Denominator M12":
  "CalculateDenominatorForPeriod"("M12 2026")

// ===== 指標計算（護病比） =====

// 計算護病比（分子/分母，四捨五入至小數點第一位）
define function "CalculateNursePatientRatio"(numerator Decimal, denominator Decimal):
  if denominator is null or denominator = 0.0 then
    null
  else
    Round(numerator / denominator, 1)

// 年度護病比
define "Nurse Patient Ratio Annual":
  "CalculateNursePatientRatio"("Numerator Annual", "Denominator Annual")

// 季度護病比
define "Nurse Patient Ratio Q1":
  "CalculateNursePatientRatio"("Numerator Q1", "Denominator Q1")

define "Nurse Patient Ratio Q2":
  "CalculateNursePatientRatio"("Numerator Q2", "Denominator Q2")

define "Nurse Patient Ratio Q3":
  "CalculateNursePatientRatio"("Numerator Q3", "Denominator Q3")

define "Nurse Patient Ratio Q4":
  "CalculateNursePatientRatio"("Numerator Q4", "Denominator Q4")

// 月度護病比
define "Nurse Patient Ratio M1":
  "CalculateNursePatientRatio"("Numerator M1", "Denominator M1")

define "Nurse Patient Ratio M2":
  "CalculateNursePatientRatio"("Numerator M2", "Denominator M2")

define "Nurse Patient Ratio M3":
  "CalculateNursePatientRatio"("Numerator M3", "Denominator M3")

define "Nurse Patient Ratio M4":
  "CalculateNursePatientRatio"("Numerator M4", "Denominator M4")

define "Nurse Patient Ratio M5":
  "CalculateNursePatientRatio"("Numerator M5", "Denominator M5")

define "Nurse Patient Ratio M6":
  "CalculateNursePatientRatio"("Numerator M6", "Denominator M6")

define "Nurse Patient Ratio M7":
  "CalculateNursePatientRatio"("Numerator M7", "Denominator M7")

define "Nurse Patient Ratio M8":
  "CalculateNursePatientRatio"("Numerator M8", "Denominator M8")

define "Nurse Patient Ratio M9":
  "CalculateNursePatientRatio"("Numerator M9", "Denominator M9")

define "Nurse Patient Ratio M10":
  "CalculateNursePatientRatio"("Numerator M10", "Denominator M10")

define "Nurse Patient Ratio M11":
  "CalculateNursePatientRatio"("Numerator M11", "Denominator M11")

define "Nurse Patient Ratio M12":
  "CalculateNursePatientRatio"("Numerator M12", "Denominator M12")

// ===== 統計資訊 =====

// 床位統計
define "Total Acute General Bed Count":
  Sum("Acute General Ward Locations" L return "GetBedCount"(L))

// 年度平均占床率
define "Annual Average Occupancy Rate":
  if "Total Acute General Bed Count" > 0 then
    Round(
      Sum("Acute General Ward Locations" L 
        return "CalculateOccupancyRate"(L, "Measurement Period")
      ) / Count("Acute General Ward Locations"),
      1
    )
  else
    null

// 各季度平均占床率
define "Q1 Average Occupancy Rate":
  if "Total Acute General Bed Count" > 0 then
    Round(
      Sum("Acute General Ward Locations" L 
        return "CalculateOccupancyRate"(L, "Q1 2026")
      ) / Count("Acute General Ward Locations"),
      1
    )
  else
    null

define "Q2 Average Occupancy Rate":
  if "Total Acute General Bed Count" > 0 then
    Round(
      Sum("Acute General Ward Locations" L 
        return "CalculateOccupancyRate"(L, "Q2 2026")
      ) / Count("Acute General Ward Locations"),
      1
    )
  else
    null

define "Q3 Average Occupancy Rate":
  if "Total Acute General Bed Count" > 0 then
    Round(
      Sum("Acute General Ward Locations" L 
        return "CalculateOccupancyRate"(L, "Q3 2026")
      ) / Count("Acute General Ward Locations"),
      1
    )
  else
    null

define "Q4 Average Occupancy Rate":
  if "Total Acute General Bed Count" > 0 then
    Round(
      Sum("Acute General Ward Locations" L 
        return "CalculateOccupancyRate"(L, "Q4 2026")
      ) / Count("Acute General Ward Locations"),
      1
    )
  else
    null

// ===== 最終報告 =====

define "Final Report":
  {
    indicator_name: '急性一般病床全日平均護病比',
    measurement_period: '2026年(115年)',
    calculation_formula: '(醫院急性一般病床床位數 × 占床率 × 3) / 全日平均三班護理人員數',
    
    // 床位資訊
    total_acute_general_beds: "Total Acute General Bed Count",
    annual_average_occupancy_rate: "Annual Average Occupancy Rate",
    
    // 年度指標
    annual_nurse_patient_ratio: "Nurse Patient Ratio Annual",
    annual_numerator: "Numerator Annual",
    annual_denominator: "Denominator Annual",
    
    // 季度指標
    q1_nurse_patient_ratio: "Nurse Patient Ratio Q1",
    q1_numerator: "Numerator Q1",
    q1_denominator: "Denominator Q1",
    q1_occupancy_rate: "Q1 Average Occupancy Rate",
    
    q2_nurse_patient_ratio: "Nurse Patient Ratio Q2",
    q2_numerator: "Numerator Q2",
    q2_denominator: "Denominator Q2",
    q2_occupancy_rate: "Q2 Average Occupancy Rate",
    
    q3_nurse_patient_ratio: "Nurse Patient Ratio Q3",
    q3_numerator: "Numerator Q3",
    q3_denominator: "Denominator Q3",
    q3_occupancy_rate: "Q3 Average Occupancy Rate",
    
    q4_nurse_patient_ratio: "Nurse Patient Ratio Q4",
    q4_numerator: "Numerator Q4",
    q4_denominator: "Denominator Q4",
    q4_occupancy_rate: "Q4 Average Occupancy Rate",
    
    // 月度指標（僅列出關鍵數據）
    monthly_ratios: {
      m1: "Nurse Patient Ratio M1",
      m2: "Nurse Patient Ratio M2",
      m3: "Nurse Patient Ratio M3",
      m4: "Nurse Patient Ratio M4",
      m5: "Nurse Patient Ratio M5",
      m6: "Nurse Patient Ratio M6",
      m7: "Nurse Patient Ratio M7",
      m8: "Nurse Patient Ratio M8",
      m9: "Nurse Patient Ratio M9",
      m10: "Nurse Patient Ratio M10",
      m11: "Nurse Patient Ratio M11",
      m12: "Nurse Patient Ratio M12"
    },
    
    // 說明
    notes: {
      definition: '急性一般病床包含：急性一般病床、經濟病床、精神急性一般病床、精神急性經濟病床',
      interpretation: '護病比數值越小表示護理人力配置越充足，照護品質越佳',
      exclusion: '不含未設置急性一般(經濟)、精神急性一般(經濟)病床之醫院',
      data_quality: '如醫院各項數據為空值，表示未登錄相關資料；占床率為0表示急性一般病床未收治病人'
    }
  }
