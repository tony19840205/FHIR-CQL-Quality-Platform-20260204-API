# Batch 11&12 轉檔完成報告
**日期：2026-01-10**
**狀態：✅ 成功完成**

## 📊 轉換成果

### 完成文件
**Batch 11 - Indicator_03_11（降血糖藥物跨院重疊）**
- **檔名**：`Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.json`
- **大小**：558.99 KB
- **行數**：11,894 lines
- **Translator版本**：3.10.0 ✓
- **特殊功能**：
  - 追蹤口服和注射劑型（GetDosageFormType函數）
  - ATC代碼：A10前綴（所有降血糖藥物）
  - 統計項目包含：totalDrugDays, oralDrugDays, injectionDrugDays

**Batch 12 - Indicator_03_12（抗精神病藥物跨院重疊）**
- **檔名**：`Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.json`
- **大小**：450.43 KB
- **行數**：9,658 lines
- **Translator版本**：3.10.0 ✓
- **特殊功能**：
  - 11種ATC類別（N05AA到N05AX）
  - 排除：N05AB04（Prochlorperazine）、N05AN01（Lithium carbonate）
  - 僅計算口服劑型

### 總體進度
**成功完成：19/19 檔案（100%）**

累計文件列表：
1. Antibiotic_Utilization.json
2. COVID19VaccinationCoverage.json
3. EHR_Adoption_Rate.json
4. HypertensionActiveCases.json
5. InfluenzaVaccinationCoverage.json
6. Indicator_01_Outpatient_Injection_Usage_Rate_3127.json
7. Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.json
8. Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.json (88.92 KB)
9. Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.json
10. Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.json
11. Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.json
12. Indicator_03_5_Same_Hospital_Antidepressant_Overlap_1727.json
13. Indicator_03_6_Same_Hospital_Sedative_Overlap_1728.json
14. Indicator_03_7_Same_Hospital_Antithrombotic_Overlap_3375.json (307.89 KB)
15. Indicator_03_8_Same_Hospital_Prostate_Overlap_3376.json (234.17 KB)
16. Indicator_03_9_Cross_Hospital_Antihypertensive_Overlap_1713.json (430.26 KB)
17. Indicator_03_10_Cross_Hospital_Lipid_Lowering_Overlap_1714.json (401.04 KB)
18. **Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.json (558.99 KB)** ⭐ NEW
19. **Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.json (450.43 KB)** ⭐ NEW

---

## 🔧 轉換過程記錄

### 準備階段
```powershell
# 1. 建立臨時資料夾
if (Test-Path "cql_11_12_temp") { Remove-Item "cql_11_12_temp" -Recurse -Force }
New-Item -Path "cql_11_12_temp" -ItemType Directory

# 2. 複製檔案並套用UTF-8 no BOM編碼
Copy-Item "cql\Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.cql" "cql_11_12_temp\"
Copy-Item "cql\Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.cql" "cql_11_12_temp\"

# 對每個檔案套用UTF-8 no BOM
$files = Get-ChildItem "cql_11_12_temp\*.cql"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
}
```

### 修正build.gradle
```gradle
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
  args '--input', './cql_11_12_temp', 
       '--output', './ELM_JSON_OFFICIAL/舊50_AHRQ_Official',
       '--format', 'JSON', 
       '--signatures', 'Overloads', 
       '--disable-list-demotion', 
       '--disable-list-promotion'
}
```

---

## ❌ 遇到的錯誤與解決方案

### 第一次轉檔錯誤（共12種錯誤類型）

#### 錯誤1：Let語法逗號分隔
```
Error:[159:2, 159:2] Syntax error at let
Error:[159:10, 159:10] Syntax error at :
```

**原因**：CQL不支援 `let a: x, b: y in ...` 語法

**解決方案**：
```cql
// ❌ 錯誤寫法
define function IsAntidiabeticATC(medication Medication):
  let atc3: GetATCCodePrefix3(medication)
  in atc3 = 'A10'

// ✅ 正確寫法 - 直接內聯
define function IsAntidiabeticATC(medication Medication):
  GetATCCodePrefix3(medication) = 'A10'
```

#### 錯誤2：Days關鍵字
```
Error:[180:71, 180:71] Syntax error at days
```

**解決方案**：
```cql
// ❌ 錯誤
GetDrugStartDate(medicationRequest) + GetDrugDays(medicationRequest) days - 1 day

// ✅ 正確
GetDrugStartDate(medicationRequest) + System.Quantity { value: GetDrugDays(medicationRequest) - 1, unit: 'day' }
```

#### 錯誤3：ToString()在FHIR類型
```
Error:[136:15, 136:32] Could not resolve call to operator ToString with signature (FHIR.uri)
```

**解決方案**：
```cql
// ❌ 錯誤
ToString(C.system) = 'http://www.whocc.no/atc'

// ✅ 正確
C.system.value = 'http://www.whocc.no/atc'
```

#### 錯誤4：Singleton from缺少括號
```
Error:[275:35, 275:35] Syntax error at [
```

**解決方案**：
```cql
// ❌ 錯誤
singleton from [Medication: id in GetId(MR.medication)]

// ✅ 正確
singleton from ([Medication: id in GetId(MR.medication)])
```

#### 錯誤5：Statistics by Quarter迭代語法
```
Error:[364:97, 364:97] Syntax error at Q
Error:[370:12, 370:12] Syntax error at return
```

**解決方案**：必須使用顯式列表
```cql
// ❌ 錯誤 - 使用迭代
flatten (
  { '2024Q1', '2024Q2', '2024Q3' } Q
    return {
      quarter: Q,
      totalDrugDays: Sum(...where P.quarter = Q...)
    }
)

// ✅ 正確 - 顯式列表
{
  {
    quarter: '2024Q1',
    totalDrugDays: Sum("Outpatient Antidiabetic Prescriptions" P where P.quarter = '2024Q1' return P.drugDays),
    overlapRate: if Sum(...) = 0 then null else (Sum(...) / Sum(...)) * 100
  },
  {
    quarter: '2024Q2',
    totalDrugDays: Sum("Outpatient Antidiabetic Prescriptions" P where P.quarter = '2024Q2' return P.drugDays),
    overlapRate: if Sum(...) = 0 then null else (Sum(...) / Sum(...)) * 100
  },
  // ... 共9個季度
}
```

#### 錯誤6：GetDrugDays需要Truncate
```cql
// ❌ 錯誤
define function GetDrugDays(medicationRequest MedicationRequest):
  Coalesce(
    medicationRequest.dispenseRequest.expectedSupplyDuration.value,
    30
  )

// ✅ 正確
define function GetDrugDays(medicationRequest MedicationRequest):
  if medicationRequest.dispenseRequest.expectedSupplyDuration is not null then
    Truncate(medicationRequest.dispenseRequest.expectedSupplyDuration.value)
  else
    30
```

#### 錯誤7：CalculateOverlapDays參數類型
```cql
// ❌ 錯誤 - Date類型
define function CalculateOverlapDays(start1 Date, end1 Date, start2 Date, end2 Date):
  ...

// ✅ 正確 - DateTime類型
define function CalculateOverlapDays(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then 0
  else
    if start1 > end2 or start2 > end1 then 0
    else
      days between (if start1 > start2 then start1 else start2) and (if end1 < end2 then end1 else end2) + 1
```

#### 錯誤8：With...such that語法
```cql
// ❌ 錯誤
"Antidiabetic Medication Requests" MR
  with "Outpatient Encounters" E
    such that GetId(MR.encounter) = E.id

// ✅ 正確
from
  "Outpatient Encounters" E,
  "Antidiabetic Medication Requests" MR
where GetId(MR.encounter) = E.id
```

#### 錯誤9：Extension值的類型轉換
```cql
// ❌ 錯誤
E.value = '1'

// ✅ 正確
(E.value as FHIR.string).value = '1'
```

### 第二次轉檔錯誤（Indicator_03_12特有）

#### 錯誤10：Not in語法
```
Error:[162:31, 162:31] Syntax error at not
Error:[161:3, 162:30] Could not resolve call to operator And with signature (System.Boolean,System.String)
```

**原CQL**：
```cql
define function IsAntipsychoticATC(medication Medication):
  GetATCCodePrefix5(medication) in { 'N05AA', 'N05AB', ... }
    and GetATCCode(medication) not in { 'N05AB04', 'N05AN01' }
```

**問題**：CQL不支援 `not in` 語法

**解決方案**：
```cql
define function IsAntipsychoticATC(medication Medication):
  if GetATCCodePrefix5(medication) in { 'N05AA', 'N05AB', 'N05AC', 'N05AD', 'N05AE', 'N05AF', 'N05AG', 'N05AH', 'N05AL', 'N05AN', 'N05AX' } then
    not (GetATCCode(medication) in { 'N05AB04', 'N05AN01' })
  else
    false
```

---

## 🎯 完整修正清單（Batch 11&12）

### Indicator_03_11修正項目（16處）
1. ✅ GetDrugDays → Truncate + if/else
2. ✅ GetDrugEndDate → System.Quantity
3. ✅ CalculateOverlapDays → DateTime參數
4. ✅ HasOverlap → DateTime參數
5. ✅ GetATCCodePrefix3 → 移除ToString
6. ✅ GetATCCodePrefix4 → 移除ToString
7. ✅ GetATCCode → 移除ToString
8. ✅ IsAntidiabeticATC → 移除let，內聯表達式
9. ✅ GetATCClassName → 移除let和中文
10. ✅ GetDosageFormType → 移除ToString，修正類型轉換
11. ✅ Outpatient Encounters → .value
12. ✅ All Medication Requests → .value
13. ✅ Antidiabetic Medication Requests → 添加括號
14. ✅ Outpatient Antidiabetic Prescriptions → from...where
15. ✅ Statistics by Quarter → 顯式列表（9季度）
16. ✅ Indicator Result → 移除中文

### Indicator_03_12修正項目（13處）
1-8. ✅ 與03_11相同的函數修正
9. ✅ GetATCCodePrefix5 → 移除ToString
10. ✅ IsAntipsychoticATC → **使用if...then...else避免not in語法**
11. ✅ IsOralDosageForm → 修正類型轉換
12. ✅ GetATCClassName → 移除let和中文
13. ✅ Statistics by Quarter → 顯式列表

---

## 💡 重要發現

### ⚠️ CQL語法限制
1. **不支援let逗號分隔**：`let a: x, b: y` ❌
2. **不支援not in**：`x not in {...}` ❌，應使用 `not (x in {...})` ✅
3. **不支援flatten迭代**：`{ ... } Q return {...}` ❌
4. **Days關鍵字**：必須用 `System.Quantity` ✅

### ✅ 最佳實踐
1. **內聯表達式**：避免let，直接在case或if中使用函數調用
2. **顯式列表**：Statistics by Quarter必須明確列出每個季度
3. **類型轉換**：FHIR choice類型需要 `(x as FHIR.type).value`
4. **參數類型**：日期運算函數使用DateTime，不要用Date

---

## 📁 工作資料夾狀態

### 當前資料夾結構
```
UI UX- 20260108/
├── cql_11_12_temp/          ← Batch 11&12工作資料夾
│   ├── Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.cql (已修正)
│   └── Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.cql (已修正)
├── ELM_JSON_OFFICIAL/
│   └── 舊50_AHRQ_Official/  ← 輸出資料夾
│       ├── Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.json ✓
│       ├── Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.json ✓
│       └── ... (17個之前的檔案)
└── cql/                     ← 原始檔案
    ├── Indicator_03_11_Cross_Hospital_Antidiabetic_Overlap_1715.cql
    └── Indicator_03_12_Cross_Hospital_Antipsychotic_Overlap_1729.cql
```

### 轉檔指令
```powershell
# 清除快取
Remove-Item .gradle, build -Recurse -Force -ErrorAction SilentlyContinue

# 執行轉檔
.\gradle-8.11\bin\gradle.bat cql2elm

# 檢查結果
Get-ChildItem "ELM_JSON_OFFICIAL\舊50_AHRQ_Official\Indicator_03_1*.json" | 
  Select-Object Name, @{Name='Size';Expression={'{0:N2} KB' -f ($_.Length/1KB)}}, 
                @{Name='Lines';Expression={(Get-Content $_.FullName).Count}}
```

---

## 📋 下一步計劃

### 剩餘檔案（Indicator_03_13至03_16）
根據檔案命名推測，還有4個跨院重疊指標：

**預計Batch 13&14：**
- Indicator_03_13（可能是跨院抗憂鬱藥物）
- Indicator_03_14（可能是跨院鎮靜劑）

**預計Batch 15&16：**
- Indicator_03_15（待確認）
- Indicator_03_16（待確認）

### 預期挑戰
基於Batch 11&12經驗：
1. ✅ Let語法 → 已掌握解決方法
2. ✅ Statistics by Quarter → 使用顯式列表模板
3. ✅ Not in語法 → 使用if/then/else
4. ⚠️ 新的藥物分類可能有特殊邏輯

### 轉檔模板（複製使用）
```powershell
# 1. 建立工作資料夾
if (Test-Path "cql_XX_YY_temp") { Remove-Item "cql_XX_YY_temp" -Recurse -Force }
New-Item -Path "cql_XX_YY_temp" -ItemType Directory
Copy-Item "cql\Indicator_03_XX_*.cql" "cql_XX_YY_temp\"
Copy-Item "cql\Indicator_03_YY_*.cql" "cql_XX_YY_temp\"

# 2. 套用UTF-8 no BOM
Get-ChildItem "cql_XX_YY_temp\*.cql" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8)
}

# 3. 更新build.gradle
$content = @'
plugins { id 'java' }
repositories { mavenCentral() }
dependencies { runtimeOnly 'info.cqframework:cql-to-elm-cli:3.10.0' }
task cql2elm(type: JavaExec) {
  classpath = sourceSets.main.runtimeClasspath
  main = 'org.cqframework.cql.cql2elm.cli.Main'
  args '--input', './cql_XX_YY_temp', 
       '--output', './ELM_JSON_OFFICIAL/舊50_AHRQ_Official',
       '--format', 'JSON', '--signatures', 'Overloads', 
       '--disable-list-demotion', '--disable-list-promotion'
}
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$PWD\build.gradle", $content, $utf8)

# 4. 轉檔
Remove-Item .gradle, build -Recurse -Force -ErrorAction SilentlyContinue
.\gradle-8.11\bin\gradle.bat cql2elm
```

---

## 🔑 關鍵修正模式（快速參考）

### GetDrugDays模式
```cql
define function GetDrugDays(medicationRequest MedicationRequest):
  if medicationRequest.dispenseRequest.expectedSupplyDuration is not null then
    Truncate(medicationRequest.dispenseRequest.expectedSupplyDuration.value)
  else
    30
```

### GetDrugEndDate模式
```cql
define function GetDrugEndDate(medicationRequest MedicationRequest):
  GetDrugStartDate(medicationRequest) + System.Quantity { 
    value: GetDrugDays(medicationRequest) - 1, 
    unit: 'day' 
  }
```

### CalculateOverlapDays模式
```cql
define function CalculateOverlapDays(start1 DateTime, end1 DateTime, start2 DateTime, end2 DateTime):
  if start1 is null or end1 is null or start2 is null or end2 is null then 0
  else if start1 > end2 or start2 > end1 then 0
  else days between (if start1 > start2 then start1 else start2) 
                 and (if end1 < end2 then end1 else end2) + 1
```

### Statistics by Quarter模式（9季度）
```cql
define "Statistics by Quarter":
  {
    {quarter: '2024Q1', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2024Q2', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2024Q3', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2024Q4', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2025Q1', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2025Q2', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2025Q3', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2025Q4', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...},
    {quarter: '2026Q1', totalDrugDays: Sum(...), overlapRate: if Sum(...) = 0 then null else ...}
  }
```

### 排除邏輯模式（not in）
```cql
// 使用if/then/else避免not in語法
define function IsSpecificATC(medication Medication):
  if GetATCCodePrefix5(medication) in { 'CODE1', 'CODE2', ... } then
    not (GetATCCode(medication) in { 'EXCLUDE1', 'EXCLUDE2' })
  else
    false
```

---

## ✅ 驗證清單

每次轉檔完成後檢查：
- [ ] Build SUCCESSFUL
- [ ] ELM檔案已生成
- [ ] 檔案大小 > 70 KB
- [ ] translatorVersion = "3.10.0"
- [ ] 行數 > 1000
- [ ] 無Error訊息（Warning可忽略）

---

**轉檔完成時間**：2026-01-10 23:45
**下次繼續**：Batch 13&14（Indicator_03_13 & 03_14）
**總進度**：19/19 完成 (100%) + 待確認剩餘檔案
