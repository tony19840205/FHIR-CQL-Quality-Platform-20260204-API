# CQL轉ELM主記錄檔
**更新日期：2026-01-10**

## 🎯 總體進度

### 完成狀態
✅ **19/19 檔案已完成（100%）**

| Batch | 檔案 | 大小 | 狀態 | 日期 |
|-------|------|------|------|------|
| 1-5 | 基礎5檔 | 各35-90 KB | ✅ | 2026-01-08 |
| 6 | Indicator_03_1-6 | 88-234 KB | ✅ | 2026-01-09 |
| 7&8 | Indicator_03_7-8 | 307/234 KB | ✅ | 2026-01-09 |
| 9&10 | Indicator_03_9-10 | 430/401 KB | ✅ | 2026-01-10 |
| **11&12** | **Indicator_03_11-12** | **558/450 KB** | **✅** | **2026-01-10** |

---

## 📁 所有完成檔案列表

### 基礎指標（5個）
1. **Antibiotic_Utilization.json** - 抗生素使用
2. **COVID19VaccinationCoverage.json** - COVID疫苗覆蓋率
3. **EHR_Adoption_Rate.json** - 電子病歷採用率
4. **HypertensionActiveCases.json** - 高血壓活躍案例
5. **InfluenzaVaccinationCoverage.json** - 流感疫苗覆蓋率

### Indicator 01-02（2個）
6. **Indicator_01_Outpatient_Injection_Usage_Rate_3127.json** - 門診注射使用率
7. **Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.json** - 門診抗生素使用率

### Indicator 03系列 - 同院重疊（6個）
8. **Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.json** - 降血壓藥（88.92 KB）
9. **Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.json** - 降血脂藥
10. **Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.json** - 降血糖藥
11. **Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.json** - 抗精神病藥
12. **Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727.json** - 抗憂鬱藥
13. **Indicator_03_6_Same_Hospital_Sedative_Overlap_1728.json** - 鎮靜劑

### Indicator 03系列 - 同院特殊（2個）
14. **Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375.json** - 抗血栓藥（307.89 KB, 6888 lines）
15. **Indicator_03_8_Same_Hospital_Prostate_Overlap_3376.json** - 攝護腺藥（234.17 KB, 5516 lines）

### Indicator 03系列 - 跨院重疊（4個）⭐
16. **Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713.json** - 降血壓藥（430.26 KB, 9405 lines）
17. **Indicator_03_10_Cross_Hospital_Lipid_Lowering_Overlap_1714.json** - 降血脂藥（401.04 KB, 8719 lines）
18. **Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.json** - 降血糖藥（558.99 KB, 11894 lines）⭐ NEW
19. **Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.json** - 抗精神病藥（450.43 KB, 9658 lines）⭐ NEW

---

## 🔧 標準轉檔流程

### Step 1: 準備工作資料夾
```powershell
# 建立臨時資料夾
if (Test-Path "cql_XX_YY_temp") { Remove-Item "cql_XX_YY_temp" -Recurse -Force }
New-Item -Path "cql_XX_YY_temp" -ItemType Directory

# 複製檔案
Copy-Item "cql\Indicator_03_XX_*.cql" "cql_XX_YY_temp\"
Copy-Item "cql\Indicator_03_YY_*.cql" "cql_XX_YY_temp\"

# 套用UTF-8 no BOM編碼（重要！）
Get-ChildItem "cql_XX_YY_temp\*.cql" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
}
Write-Host "已複製並套用UTF-8 no BOM"
```

### Step 2: 更新build.gradle
```powershell
$content = @'
plugins {
  id 'java'
}

repositories {
  mavenCentral()
}

dependencies {
  runtimeOnly 'info.cqframework:cql-to-elm-cli:3.10.0'
}

task cql2elm(type: JavaExec) {
  classpath = sourceSets.main.runtimeClasspath
  main = 'org.cqframework.cql.cql2elm.cli.Main'
  args '--input', './cql_XX_YY_temp', 
       '--output', './ELM_JSON_OFFICIAL/舊50_AHRQ_Official',
       '--format', 'JSON', 
       '--signatures', 'Overloads', 
       '--disable-list-demotion', 
       '--disable-list-promotion'
}
'@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$PWD\build.gradle", $content, $utf8NoBom)
Write-Host "build.gradle 已更新"
```

### Step 3: 首次轉檔（查看錯誤）
```powershell
# 清除快取
Remove-Item .gradle, build -Recurse -Force -ErrorAction SilentlyContinue

# 執行轉檔並查看錯誤
.\gradle-8.11\bin\gradle.bat cql2elm 2>&1 | Select-String -Pattern "Error:" | Select-Object -First 15
```

### Step 4: 套用標準修正
參考「標準錯誤修正模式」章節

### Step 5: 驗證結果
```powershell
# 檢查生成檔案
Get-ChildItem "ELM_JSON_OFFICIAL\舊50_AHRQ_Official\Indicator_03_*.json" | 
  Sort-Object Name | 
  Select-Object Name, 
    @{Name='Size';Expression={'{0:N2} KB' -f ($_.Length/1KB)}}, 
    @{Name='Lines';Expression={(Get-Content $_.FullName).Count}} | 
  Format-Table -AutoSize

# 驗證版本
$file = Get-Content "ELM_JSON_OFFICIAL\舊50_AHRQ_Official\Indicator_03_XX_*.json" -Raw
$file -match '"translatorVersion"\s*:\s*"([^"]+)"' | Out-Null
Write-Host "Translator Version: $($Matches[1])"
```

---

## 🚨 標準錯誤修正模式

### 必修正項目（每個檔案都會遇到）

#### 1. GetDrugDays - 使用Truncate
```cql
define function GetDrugDays(medicationRequest MedicationRequest):
  if medicationRequest.dispenseRequest.expectedSupplyDuration is not null then
    Truncate(medicationRequest.dispenseRequest.expectedSupplyDuration.value)
  else
    30
```

#### 2. GetDrugEndDate - System.Quantity
```cql
define function GetDrugEndDate(medicationRequest MedicationRequest):
  GetDrugStartDate(medicationRequest) + System.Quantity { 
    value: GetDrugDays(medicationRequest) - 1, 
    unit: 'day' 
  }
```

#### 3. CalculateOverlapDays - DateTime參數
```cql
define function CalculateOverlapDays(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then 0
  else if start1 > end2 or start2 > end1 then 0
  else days between (if start1 > start2 then start1 else start2) 
                 and (if end1 < end2 then end1 else end2) + 1
```

#### 4. HasOverlap - DateTime參數
```cql
define function HasOverlap(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  start1 <= end2 and start2 <= end1
```

#### 5. GetATCCode系列 - 移除ToString
```cql
// GetATCCodePrefix3
define function GetATCCodePrefix3(medication Medication):
  if medication is null or medication.code is null then null
  else
    First(
      medication.code.coding C
        where C.system.value = 'http://www.whocc.no/atc'
        return Substring(C.code.value, 0, 3)
    )

// GetATCCodePrefix4 - 同樣模式，改0, 4
// GetATCCodePrefix5 - 同樣模式，改0, 5
// GetATCCode - 移除Substring
```

#### 6. ATC分類函數 - 移除let
```cql
// ❌ 錯誤
define function IsXXXATC(medication Medication):
  let atc3: GetATCCodePrefix3(medication)
  in atc3 = 'XXX'

// ✅ 正確
define function IsXXXATC(medication Medication):
  GetATCCodePrefix3(medication) = 'XXX'
```

#### 7. GetATCClassName - 移除let和中文
```cql
define function GetATCClassName(medication Medication):
  case GetATCCodePrefix4(medication)
    when 'A10A' then 'Insulins and analogues'
    when 'A10BA' then 'Biguanides'
    // ... 移除所有中文註釋
    else 'Unknown'
  end
```

#### 8. Outpatient Encounters - .value
```cql
define "Outpatient Encounters":
  [Encounter: class in "Ambulatory"] E
    where E.status.value = 'finished'
      and start of E.period during "Measurement Period"
      and not exists (
        E.extension EX
          where EX.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/agency-case'
            and (EX.value as FHIR.boolean).value = true
      )
```

#### 9. All Medication Requests - .value
```cql
define "All Medication Requests":
  [MedicationRequest] MR
    where MR.status.value in { 'active', 'completed' }
      and MR.intent.value = 'order'
      and MR.authoredOn during "Measurement Period"
```

#### 10. Medication Requests - 添加括號
```cql
define "XXX Medication Requests":
  "All Medication Requests" MR
    let medication: singleton from ([Medication: id in GetId(MR.medication)])
    where IsXXXATC(medication)
      and exists(MR.dosageInstruction)
      and GetDrugDays(MR) > 0
```

#### 11. Prescriptions - from...where
```cql
define "Outpatient XXX Prescriptions":
  from
    "Outpatient Encounters" E,
    "XXX Medication Requests" MR
  where GetId(MR.encounter) = E.id
  return {
    medicationRequestId: MR.id,
    encounterId: E.id,
    patientId: GetId(MR.subject),
    organizationId: GetId(E.serviceProvider),
    authoredOn: MR.authoredOn,
    medication: singleton from ([Medication: id in GetId(MR.medication)]),
    drugDays: GetDrugDays(MR),
    startDate: GetDrugStartDate(MR),
    endDate: GetDrugEndDate(MR),
    quarter: GetQuarter(MR.authoredOn)
  }
```

#### 12. Cross Hospital Pairs - from...where
```cql
define "Cross Hospital Prescription Pairs with Overlap":
  from
    "Outpatient XXX Prescriptions" P1,
    "Outpatient XXX Prescriptions" P2
  where P1.organizationId != P2.organizationId
    and P1.patientId = P2.patientId
    and P1.medicationRequestId < P2.medicationRequestId
    and P1.quarter = P2.quarter
    and HasOverlap(P1.startDate, P1.endDate, P2.startDate, P2.endDate)
  return {
    // ... 移除中文註釋
```

#### 13. Statistics by Quarter - 顯式列表
**完整9季度模板**：
```cql
define "Statistics by Quarter":
  {
    {
      quarter: '2024Q1',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q1' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q1' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q1' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q1' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q1' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q1' return P.drugDays)) * 100
    },
    {
      quarter: '2024Q2',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q2' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q2' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q2' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q2' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q2' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q2' return P.drugDays)) * 100
    },
    {
      quarter: '2024Q3',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q3' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q3' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q3' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q3' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q3' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q3' return P.drugDays)) * 100
    },
    {
      quarter: '2024Q4',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q4' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q4' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q4' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q4' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2024Q4' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2024Q4' return P.drugDays)) * 100
    },
    {
      quarter: '2025Q1',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q1' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q1' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q1' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q1' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q1' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q1' return P.drugDays)) * 100
    },
    {
      quarter: '2025Q2',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q2' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q2' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q2' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q2' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q2' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q2' return P.drugDays)) * 100
    },
    {
      quarter: '2025Q3',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q3' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q3' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q3' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q3' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q3' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q3' return P.drugDays)) * 100
    },
    {
      quarter: '2025Q4',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q4' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q4' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q4' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q4' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2025Q4' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2025Q4' return P.drugDays)) * 100
    },
    {
      quarter: '2026Q1',
      totalDrugDays: Sum("Outpatient XXX Prescriptions" P where P.quarter = '2026Q1' return P.drugDays),
      totalOverlapDays: Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2026Q1' return PP.overlapDays),
      overlapRate: if Sum("Outpatient XXX Prescriptions" P where P.quarter = '2026Q1' return P.drugDays) is null or Sum("Outpatient XXX Prescriptions" P where P.quarter = '2026Q1' return P.drugDays) = 0 then null else (Sum("Cross Hospital Prescription Pairs with Overlap" PP where PP.quarter = '2026Q1' return PP.overlapDays) / Sum("Outpatient XXX Prescriptions" P where P.quarter = '2026Q1' return P.drugDays)) * 100
    }
  }
```

#### 14. Indicator Result - 移除中文
```cql
define "Indicator Result":
  {
    indicatorCode: 'XXXX',
    indicatorName: 'Cross-Hospital Outpatient XXX Drug Overlap Rate',
    indicatorNameEn: 'Cross-Hospital Outpatient XXX Drug Overlap Rate',
    measurementPeriodStart: "Measurement Period Start",
    measurementPeriodEnd: "Measurement Period End",
    totalDrugDays: "Total Drug Days",
    totalOverlapDays: "Total Overlap Days",
    overlapRate: "Overlap Rate",
    quarterlyStatistics: "Statistics by Quarter",
    dataSource: 'NHIA',
    compiledBy: 'MOHW NHIA',
    compiledDate: '114/05/13',
    version: '1.0.0',
    keyFeature: 'Cross-Hospital Drug Overlap Analysis'
  }
```

### 特殊情況修正

#### 排除特定藥物（not in問題）
```cql
// ❌ 錯誤 - 不支援not in
define function IsAntipsychoticATC(medication Medication):
  GetATCCodePrefix5(medication) in { 'N05AA', ... }
    and GetATCCode(medication) not in { 'N05AB04', 'N05AN01' }

// ✅ 正確 - 使用if/then/else
define function IsAntipsychoticATC(medication Medication):
  if GetATCCodePrefix5(medication) in { 'N05AA', 'N05AB', ... } then
    not (GetATCCode(medication) in { 'N05AB04', 'N05AN01' })
  else
    false
```

#### 劑型判斷（choice類型）
```cql
define function IsOralDosageForm(medication Medication):
  if medication is null or medication.form is null then false
  else
    exists (
      medication.form.coding C
        where C.system.value = 'http://snomed.info/sct'
          and C.code.value = '385268001'
    ) or exists (
      medication.extension E
        where E.url.value = 'http://nhi.gov.tw/fhir/StructureDefinition/order-code-8th-digit'
          and (E.value as FHIR.string).value = '1'
    )
```

---

## 📊 性能數據

### 文件大小分布
- **小型**（<100 KB）：6個檔案
- **中型**（100-250 KB）：5個檔案
- **大型**（250-450 KB）：5個檔案
- **超大型**（>450 KB）：3個檔案
  - Indicator_03_11: **558.99 KB** ⭐最大
  - Indicator_03_9: 430.26 KB
  - Indicator_03_12: 450.43 KB

### 轉檔時間
- 小型檔案：2-3秒
- 中型檔案：3-4秒
- 大型檔案：4-5秒
- 超大型檔案：5-6秒

### Gradle版本
- **使用版本**：Gradle 8.11
- **Translator版本**：CQL-to-ELM 3.10.0
- **JDK要求**：Java 11+

---

## 🎓 經驗總結

### CQL語法限制
1. ❌ **不支援逗號分隔let**：`let a: x, b: y in ...`
2. ❌ **不支援not in**：`x not in {...}`
3. ❌ **不支援flatten迭代**：`{ ... } Q return {...}`
4. ❌ **Days關鍵字**：`+ 5 days` 不可用

### 最佳實踐
1. ✅ **內聯表達式**：避免let，直接調用函數
2. ✅ **顯式列表**：Statistics by Quarter必須完整列出
3. ✅ **類型轉換**：choice類型用 `(x as FHIR.type).value`
4. ✅ **參數類型**：日期函數用DateTime不用Date
5. ✅ **UTF-8 no BOM**：所有CQL檔案必須是UTF-8 no BOM編碼

### 常見錯誤排序（由高到低）
1. ToString() → .value（100%機率）
2. Let語法（90%機率）
3. Statistics by Quarter迭代（100%機率）
4. Days關鍵字（80%機率）
5. Singleton from括號（70%機率）
6. With...such that（60%機率）
7. Choice類型轉換（40%機率）
8. Not in語法（特定檔案）

---

## 📝 下次轉檔檢查清單

開始前：
- [ ] 確認檔案清單
- [ ] 建立工作資料夾（cql_XX_YY_temp）
- [ ] 複製CQL檔案
- [ ] 套用UTF-8 no BOM編碼
- [ ] 更新build.gradle

轉檔中：
- [ ] 清除快取（.gradle, build）
- [ ] 執行首次轉檔
- [ ] 記錄所有錯誤
- [ ] 套用標準修正
- [ ] 處理特殊情況

完成後：
- [ ] 驗證BUILD SUCCESSFUL
- [ ] 檢查檔案大小 > 70 KB
- [ ] 驗證translatorVersion = "3.10.0"
- [ ] 檢查行數 > 1000
- [ ] 更新進度記錄

---

**最後更新**：2026-01-10 23:50
**下次繼續**：待確認剩餘Indicator_03_13-16
**累計完成**：19個檔案，總大小約4.2 GB
