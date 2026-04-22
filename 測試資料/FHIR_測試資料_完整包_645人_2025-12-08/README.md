# 📦 完整病人測試資料打包說明

**打包日期**：2025-12-08  
**目的**：提供給對方上傳至 FHIR Server  
**總病患數**：645 人（保守估計）/ 650-850 人（實際估計）

---

## 📊 資料總覽

| 分類 | 檔案數 | 病患數 | 資源數 | 備註 |
|------|--------|--------|--------|------|
| **A. CGMH 大批資料** | 10 | 508 | 2,457 | 主要測試資料，涵蓋 29 個指標 |
| **B. HAPI 小批資料** | 9 | 49 | ~298 | 含 Mr. FHIR CQL 示範病人 |
| **C. Dashboard 待上傳** | 7 | 64 | 226 | 7 個醫療品質指標 |
| **D. 根目錄測試資料** | 7 | 24 | ~150 | 小批測試案例 |
| **總計** | **33** | **645** | **~3,131** | 完整測試資料包 |

---

## 📁 檔案清單與位置

### A. CGMH 大批測試資料（508 人，2,457 資源）⭐ 最重要

**位置**：`UI UX\HAPI-FHIR-Samples\`

```
1.  CGMH_test_data_taiwan_100_bundle.json          (100人, 200資源) - 傳染病監測
2.  CGMH_test_data_vaccine_100_bundle.json         (100人, 219資源) - 疫苗接種
3.  CGMH_test_data_antibiotic_49_bundle.json       (49人, 241資源) - 抗生素使用
4.  CGMH_test_data_waste_9_bundle.json             (9人, 45資源) - 醫療廢棄物
5.  CGMH_test_data_quality_50_bundle.json          (50人, 502資源) - 用藥安全
6.  CGMH_test_data_outpatient_quality_53_bundle.json (53人, 585資源) - 門診品質
7.  CGMH_test_data_inpatient_quality_46_bundle.json  (46人, 172資源) - 住院品質
8.  CGMH_test_data_surgical_quality_46_bundle.json   (46人, 196資源) - 手術品質
9.  CGMH_test_data_outcome_quality_12_bundle.json    (12人, 45資源) - 疾病結果
10. CGMH_test_data_same_hospital_overlap_42_bundle.json (42人, 252資源) - 用藥重疊
```

**涵蓋指標**：
- 傳染病管制：5 個
- ESG 指標：3 個
- 用藥安全：2 個
- 用藥重疊：8 個
- 門診品質：5 個
- 住院品質：2 個
- 手術品質：3 個
- 疾病結果：6 個

**病患 ID 範圍**：TW00001 ~ TW00507  
**資料時間**：2025 Q4 (2025-10-01 至 2025-12-31)

---

### B. HAPI 小批測試資料（49 人，~298 資源）

**位置**：`UI UX\HAPI-FHIR-Samples\`

```
1. Mr_FHIR_CQL_Demo_Patient.json                  (1人, 23資源) ⭐ 示範病人
2. Acute_Conjunctivitis_4_Patients.json           (4人) - 急性結膜炎
3. Cesarean_Section_8_Patients.json               (8人) - 剖腹產
4. Chronic_Prescription_2_Patients.json           (2人) - 慢性病連續處方
5. Diabetes_HbA1c_5_Patients.json                 (5人) - 糖尿病 HbA1c
6. EHR_Adoption_5_Patients.json                   (5人) - 電子病歷採用
7. Pediatric_Asthma_ED_5_Patients.json            (5人) - 兒童氣喘急診
8. Readmission_3Day_ED_12_Patients.json           (12人) - 3日內急診再入院
9. Same_Day_Revisit_7_Patients.json               (7人) - 當日重複就診
```

**特別說明**：
- **Mr. FHIR CQL**：1 歲示範病人（生日：2024-12-04）
  - 完整測試資料：COVID-19、疫苗接種（2 劑 COVID + 1 劑流感）、高血壓慢性病
  - 用於展示 FHIR + CQL 查詢功能

---

### C. Dashboard 待上傳資料（64 人，226 資源）

**位置**：`UI UX\FHIR-Dashboard-App\`

```
1. ESWL_5_Patients.json                                      (5人, 20資源) - 體外震波碎石術
2. Surgical_Wound_Infection_15_Patients.json                 (15人, 47資源) - 手術傷口感染
3. Dementia_Hospice_19_Patients.json                         (19人, 51資源) - 失智症安寧療護
4. Knee_Arthroplasty_Infection_5_Patients.json               (5人, 23資源) - 膝關節置換感染 (指標 15-1)
5. First_Time_Cesarean_11_Patients.json                      (11人, 44資源) - 初產婦剖腹產 (指標 11-4)
6. Cesarean_With_Indication_5_Patients.json                  (5人, 20資源) - 有適應症剖腹產 (指標 11-3)
7. Same_Hospital_Antihypertensive_Overlap_4_Patients.json    (4人, 21資源) - 同院降血壓藥重疊 (指標 03-1)
```

---

### D. 根目錄測試資料（24 人，~150 資源）

**位置**：根目錄 `c:\Users\tony1\Desktop\UI UX-20251122(0013)\`

```
1. test_data_3day_ed_6_patients.json                         (6人) - 3日急診
2. test_data_antihypertensive_overlap_3_patients.json        (3人) - 降血壓藥重疊
3. test_data_cesarean_3_simple.json                          (3人) - 簡易剖腹產
4. test_data_cesarean_6_patients.json                        (6人) - 剖腹產
5. test_data_diabetes_2_patients.json                        (2人) - 糖尿病
6. test_data_eswl_3_patients.json                            (3人) - 體外震波碎石
7. test_single_cesarean.json                                 (1人) - 單一剖腹產
```

---

## 📦 打包方式建議

### 方式 1：壓縮成 ZIP 檔（推薦）⭐

建立壓縮檔包含：
```
FHIR_測試資料_完整包_645人_2025-12-08.zip
├── 📄 README.md                                    (本說明文件)
├── 📄 上傳指令說明.md                              (上傳步驟)
├── 📁 A_CGMH大批資料_508人/
│   ├── CGMH_test_data_taiwan_100_bundle.json
│   └── ... (10 個檔案)
├── 📁 B_HAPI小批資料_49人/
│   ├── Mr_FHIR_CQL_Demo_Patient.json
│   └── ... (9 個檔案)
├── 📁 C_Dashboard資料_64人/
│   ├── ESWL_5_Patients.json
│   └── ... (7 個檔案)
└── 📁 D_根目錄測試_24人/
    ├── test_data_3day_ed_6_patients.json
    └── ... (7 個檔案)
```

**檔案大小**：約 15-20 MB

---

### 方式 2：分批打包

#### 包 1：CGMH 主要資料（優先）
```
FHIR_CGMH_508人_2025-12-08.zip  (約 10 MB)
- 10 個 CGMH Bundle 檔案
- 涵蓋 29 個指標
```

#### 包 2：補充資料
```
FHIR_補充資料_137人_2025-12-08.zip  (約 5 MB)
- HAPI 小批 (49人)
- Dashboard (64人)
- 根目錄 (24人)
```

---

## 📝 給對方的上傳說明

### 上傳前確認

1. **目標 FHIR Server**：
   - 台灣衛福部：`https://thas.mohw.gov.tw/v/r4/fhir`
   - 或其他指定伺服器

2. **上傳方式**：
   - 每個 JSON 檔案是一個 FHIR Bundle (transaction)
   - 使用 POST 方法上傳到 FHIR Server 根路徑

3. **上傳順序建議**：
   - 優先：A. CGMH 大批資料（10 個檔案）
   - 其次：B. HAPI 小批資料（9 個檔案）
   - 最後：C+D. Dashboard 和根目錄（14 個檔案）

---

### 上傳指令範例（PowerShell）

```powershell
# 設定 FHIR Server 位址
$fhirServer = "https://thas.mohw.gov.tw/v/r4/fhir"

# 上傳單一檔案
$bundle = Get-Content "CGMH_test_data_taiwan_100_bundle.json" -Raw -Encoding UTF8
Invoke-RestMethod -Uri $fhirServer `
    -Method POST `
    -ContentType "application/fhir+json" `
    -Body $bundle

Write-Host "✅ 上傳完成" -ForegroundColor Green
```

---

### 批次上傳腳本（所有 33 個檔案）

```powershell
# ======================================
# FHIR 測試資料批次上傳腳本
# 總計：33 個檔案，645 位病患
# 預計時間：40-50 分鐘
# ======================================

$fhirServer = "https://thas.mohw.gov.tw/v/r4/fhir"
$rootPath = "C:\FHIR_測試資料_完整包_645人_2025-12-08"

# 定義所有資料夾和檔案
$folders = @(
    @{Name="A_CGMH大批資料_508人"; Files=10},
    @{Name="B_HAPI小批資料_49人"; Files=9},
    @{Name="C_Dashboard資料_64人"; Files=7},
    @{Name="D_根目錄測試_24人"; Files=7}
)

$totalFiles = 33
$successCount = 0
$failCount = 0

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "開始上傳 FHIR 測試資料" -ForegroundColor Cyan
Write-Host "目標伺服器: $fhirServer" -ForegroundColor Yellow
Write-Host "總檔案數: $totalFiles 個" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

$currentFile = 0

foreach ($folder in $folders) {
    $folderPath = Join-Path $rootPath $folder.Name
    Write-Host "`n【處理資料夾】$($folder.Name)" -ForegroundColor Green
    
    $jsonFiles = Get-ChildItem -Path $folderPath -Filter "*.json"
    
    foreach ($file in $jsonFiles) {
        $currentFile++
        Write-Host "`n[$currentFile/$totalFiles] 上傳: $($file.Name)" -ForegroundColor Cyan
        
        try {
            $bundleJson = Get-Content $file.FullName -Raw -Encoding UTF8
            
            $response = Invoke-RestMethod -Uri $fhirServer `
                -Method POST `
                -ContentType "application/fhir+json" `
                -Body $bundleJson `
                -ErrorAction Stop
            
            Write-Host "  ✅ 成功" -ForegroundColor Green
            $successCount++
            
            # 等待 3 秒避免伺服器過載
            Start-Sleep -Seconds 3
        }
        catch {
            Write-Host "  ❌ 失敗: $_" -ForegroundColor Red
            $failCount++
        }
    }
}

# 顯示統計
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳完成統計" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 成功: $successCount 個檔案" -ForegroundColor Green
Write-Host "❌ 失敗: $failCount 個檔案" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host "📊 總病患數: 約 645 人" -ForegroundColor Yellow
Write-Host "📦 總資源數: 約 3,131 個" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "🎉 所有資料上傳完成！" -ForegroundColor Green
} else {
    Write-Host "⚠️  部分檔案上傳失敗，請檢查錯誤訊息" -ForegroundColor Yellow
}
```

---

### 使用 curl 上傳（跨平台）

```bash
# Linux / macOS / Windows Git Bash

FHIR_SERVER="https://thas.mohw.gov.tw/v/r4/fhir"

# 上傳單一檔案
curl -X POST "$FHIR_SERVER" \
  -H "Content-Type: application/fhir+json" \
  -d @CGMH_test_data_taiwan_100_bundle.json

# 批次上傳（Bash 腳本）
for file in A_CGMH大批資料_508人/*.json; do
  echo "上傳: $file"
  curl -X POST "$FHIR_SERVER" \
    -H "Content-Type: application/fhir+json" \
    -d @"$file"
  sleep 3
done
```

---

## ⚠️ 注意事項

### 上傳前

1. ✅ **確認伺服器可用**
   ```powershell
   Invoke-RestMethod -Uri "https://thas.mohw.gov.tw/v/r4/fhir/metadata"
   ```

2. ✅ **檢查權限**
   - 確認有上傳權限
   - 可能需要 API Token 或認證

3. ✅ **測試單一檔案**
   - 先上傳一個小檔案測試
   - 確認格式正確

### 上傳中

1. ⏱️ **預計時間**：
   - 單檔約 1-5 分鐘
   - 總計約 40-50 分鐘

2. 🔄 **建議間隔**：
   - 每個檔案間隔 2-3 秒
   - 避免伺服器過載

3. 📊 **監控進度**：
   - 腳本會顯示成功/失敗數量
   - 記錄錯誤訊息

### 上傳後

1. ✅ **驗證資料**：
   ```powershell
   # 查詢 Patient 總數
   Invoke-RestMethod -Uri "https://thas.mohw.gov.tw/v/r4/fhir/Patient?_summary=count"
   
   # 應該顯示約 645 位病患
   ```

2. 🔍 **測試查詢**：
   ```powershell
   # 查詢特定病患
   Invoke-RestMethod -Uri "https://thas.mohw.gov.tw/v/r4/fhir/Patient/TW00001"
   ```

3. 📈 **指標計算測試**：
   - 測試各項醫療品質指標計算
   - 確認資料完整性

---

## 📋 檢查清單

### 打包前
- [ ] 確認所有 33 個 JSON 檔案存在
- [ ] 檢查檔案大小（總計約 15-20 MB）
- [ ] 建立資料夾結構
- [ ] 包含說明文件和上傳腳本

### 交付給對方
- [ ] ZIP 壓縮檔
- [ ] README.md（本說明）
- [ ] 上傳指令說明.md
- [ ] 批次上傳腳本（PowerShell + Bash）
- [ ] 聯絡資訊（如有問題可詢問）

### 對方上傳後確認
- [ ] Patient 總數約 645 人
- [ ] 資源總數約 3,131 個
- [ ] 可查詢特定病患資料
- [ ] 指標計算正常運作

---

## 📞 聯絡資訊

如上傳過程遇到問題，可提供以下資訊協助除錯：

1. **錯誤訊息截圖**
2. **失敗的檔案名稱**
3. **FHIR Server 回應**
4. **網路連線狀況**

---

## 📊 資料品質說明

### 資料完整性
- ✅ 所有資料符合 FHIR R4 標準
- ✅ 採用多重編碼策略（NHI + ICD + SNOMED）
- ✅ 時間範圍：2024-2025 Q4
- ✅ 已移除 `serviceProvider` 欄位避免錯誤

### 測試指標涵蓋
- ✅ 傳染病管制：5 個指標
- ✅ ESG 指標：3 個
- ✅ 用藥安全：2 個
- ✅ 用藥重疊：8 個
- ✅ 門診品質：5 個
- ✅ 住院品質：2 個
- ✅ 手術品質：3 個
- ✅ 疾病結果：6 個

**總計：34 個醫療品質指標可測試**

---

## 🎯 結論

**完整測試資料包規格**：
- 📁 33 個 JSON Bundle 檔案
- 👥 645 位病患（保守估計）
- 📦 3,131 個 FHIR 資源
- 📊 34 個醫療品質指標
- 💾 約 15-20 MB
- ⏱️ 預計上傳時間：40-50 分鐘

**準備就緒，可隨時交付！** ✅
