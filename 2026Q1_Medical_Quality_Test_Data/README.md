# 2026 Q1 醫療品質測試資料

**建立日期**: 2025-12-24  
**資料時間範圍**: 2026-01-01 ~ 2026-01-15 (15天)  
**檔案數量**: 65個  
**用途**: 2026 Q1評審使用

---

## 📋 資料概要

本資料包包含65個FHIR Bundle JSON檔案，涵蓋所有39個醫療品質指標的測試資料。

### 日期分布策略

- **2025-10月資料** → 轉換到 **2026-01-01 ~ 2026-01-05**
- **2025-11月資料** → 轉換到 **2026-01-06 ~ 2026-01-10**
- **2025-12月資料** → 轉換到 **2026-01-11 ~ 2026-01-15**

---

## 📊 指標類別分布

### 1. 用藥品質 (2個指標)
- 門診注射劑使用率
- 門診抗生素使用率

### 2. 藥品重疊 (16個指標)
**同院用藥重疊 (8個)**:
- `test_data_antihypertensive_overlap_*.json` - 降血壓藥
- `test_data_lipid_lowering_overlap_*.json` - 降血脂藥
- `test_data_antidiabetic_overlap_*.json` - 降血糖藥
- `test_data_antipsychotic_same_hospital*.json` - 抗思覺失調藥
- `test_data_antidepressant_overlap_*.json` - 抗憂鬱藥
- `test_data_sedative_overlap_*.json` - 安眠鎮靜藥
- `test_data_antithrombotic_overlap_*.json` - 抗血栓藥
- `test_data_prostate_overlap_*.json` - 前列腺藥

**跨院用藥重疊 (8個)**:
- 各類藥品的 `*_cross_hospital_*.json` 版本

### 3. 門診品質 (5個指標)
- `test_data_10drugs_*.json` - 處方10種以上藥品率
- `test_data_diabetes_*.json` - 糖尿病HbA1c檢驗率
- 慢性病連處箋、小兒氣喘急診、同日再就診

### 4. 住院品質 (6個指標)
- `test_data_3day_ed_*.json` - 出院後3天內急診率
- **剖腹產 (4個子指標)**:
  - `*cesarean*` 系列檔案
  - `Cesarean_With_Indication_*.json` - 有適應症剖腹產
  - `First_Time_Cesarean_*.json` - 初次剖腹產

### 5. 手術品質 (8個指標)
- `ESWL_*.json` - 體外震波碎石術
- `Knee_Arthroplasty_*.json` - 膝關節置換感染率
- `test_data_clean_surgery_*.json` - 清淨手術
- `Surgical_Wound_Infection_*.json` - 手術傷口感染
- `fibroid_*.json` - 子宮肌瘤手術

### 6. 結果品質 (2個指標)
- `test_data_ami_*.json` - 急性心肌梗塞死亡率
- `Dementia_Hospice_*.json` - 失智症安寧療護

---

## 📁 檔案列表

**總計**: 65個JSON檔案

### 主要檔案
- cesarean_complete_q4_2026Q1.json
- cesarean_snomed_2026Q1.json
- Cesarean_With_Indication_5_Patients_2026Q1.json
- Dementia_Hospice_19_Patients_2026Q1.json
- ESWL_5_Patients_2026Q1.json
- First_Time_Cesarean_11_Patients_2026Q1.json
- Knee_Arthroplasty_Infection_5_Patients_2026Q1.json
- Same_Hospital_Antihypertensive_Overlap_4_Patients_2026Q1.json
- Surgical_Wound_Infection_15_Patients_2026Q1.json
- test_data_ami_death_3_patients_2026Q1.json
- test_data_10drugs_fixed_2026Q1.json
- test_data_3day_ed_6_patients_2026Q1.json
- ... 以及其他52個檔案

---

## 📤 上傳建議

### 上傳時間
建議在 **2026-01-16之後** 上傳到FHIR伺服器

### 為什麼1/16之後上傳沒問題？
FHIR系統查詢時看的是**資料內容的日期**（如`Encounter.period.start`），不是**上傳時間**（`meta.lastUpdated`）。

即使在1/16上傳1/1-1/15的資料，CQL查詢2026 Q1時仍然會正確找到這些資料。

### 上傳方式
使用現有的PowerShell上傳腳本，例如：
```powershell
# 批次上傳所有檔案
$files = Get-ChildItem "2026Q1_Medical_Quality_Test_Data\*.json"
foreach ($file in $files) {
    # 使用你的FHIR上傳函數
    Upload-FHIRBundle -Path $file.FullName -Server "https://your-fhir-server.com"
}
```

---

## ✅ 驗證資訊

### 日期轉換驗證
- ✅ 所有2025-10月日期已轉換為2026-01-01~05
- ✅ 所有2025-11月日期已轉換為2026-01-06~10
- ✅ 所有2025-12月日期已轉換為2026-01-11~15
- ✅ 沒有殘留的2025 Q4日期

### FHIR資源完整性
- ✅ 所有JSON檔案格式正確
- ✅ Bundle結構完整
- ✅ 資源參照關係保持完整

### 指標覆蓋率
- ✅ 涵蓋所有39個醫療品質指標
- ✅ 每個指標都有對應的測試資料

---

## 🔄 2026 Q2準備

若需要2026 Q2的資料（2026-04-01 ~ 2026-04-15），可以：

1. 使用相同的腳本 `Simple-Convert-2026Q1.ps1`
2. 修改日期替換規則：將 `2026-01` 改為 `2026-04`
3. 或直接從原始2025 Q4資料重新生成

---

## 📝 使用注意事項

1. **時間間隔指標**: 部分需要時間間隔的指標（如14天再入院）已壓縮到15天範圍內
2. **編碼保持不變**: 所有ICD-10、SNOMED CT等醫療編碼維持原樣
3. **病患ID不變**: Patient ID保持不變，只修改日期欄位
4. **UTF-8編碼**: 所有檔案使用UTF-8編碼，支援中文

---

**建立者**: GitHub Copilot  
**轉換腳本**: Simple-Convert-2026Q1.ps1  
**原始資料來源**: 2025 Q4測試資料  
**最後更新**: 2025-12-24
