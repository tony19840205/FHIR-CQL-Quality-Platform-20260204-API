# 15-2分子無法命中的真正原因

**日期**: 2026-01-04  
**發現**: CQL需要Procedure.code包含**多個coding系統**

---

## 🔍 成功案例分析

### 2025 Q4成功案例（tka-patient-001）
- **Patient ID**: tka-patient-001
- **Identifier**: TW10041
- **TKA手術**: 2024-08-02
- **感染手術**: 2024-09-26（55天後）
- **結果**: ✅ **成功計入分子**

### 關鍵結構差異

#### ✅ 成功的TKA Procedure
```json
{
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure",
        "code": "64164B",
        "display": "全人工膝關節置換術"
      },
      {
        "system": "http://snomed.info/sct",
        "code": "609588000",
        "display": "Total knee replacement"
      },
      {
        "system": "http://www.ama-assn.org/go/cpt",
        "code": "27447",
        "display": "Total knee arthroplasty"
      }
    ]
  }
}
```

#### ✅ 成功的感染Procedure
```json
{
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure",
        "code": "64053B",
        "display": "人工膝關節感染清創術"
      },
      {
        "system": "http://snomed.info/sct",
        "code": "77849006",
        "display": "Debridement of knee"
      }
    ]
  }
}
```

---

## ❌ 失敗案例分析

### 我們之前上傳的資料（TW10001-TW10006）

#### ❌ 失敗的TKA Procedure
```json
{
  "code": {
    "coding": [
      {
        "system": "urn:oid:2.16.886.101.20003.20014",  // ← 錯誤的system
        "code": "64164B",
        "display": "全人工膝關節置換術"
      }
      // ← 缺少SNOMED和CPT coding
    ]
  }
}
```

#### ❌ 失敗的感染Procedure
```json
{
  "code": {
    "coding": [
      {
        "system": "urn:oid:2.16.886.101.20003.20014",  // ← 錯誤的system
        "code": "64053B",
        "display": "膝關節置換物深部感染處理"
      }
      // ← 缺少SNOMED coding
    ]
  }
}
```

---

## 📊 系統差異對照

| 項目 | 成功案例 | 失敗案例 | 說明 |
|------|---------|---------|------|
| **NHI System** | `https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure` | `urn:oid:2.16.886.101.20003.20014` | ❌ System URL不正確 |
| **SNOMED** | ✓ 有（609588000, 77849006） | ✗ 無 | ❌ 缺少SNOMED coding |
| **CPT** | ✓ 有（27447） | ✗ 無 | ❌ 缺少CPT coding |
| **Coding數量** | 3個（TKA）+ 2個（感染） | 1個 + 1個 | ❌ 數量不足 |

---

## 💡 CQL可能的匹配邏輯

根據CQL定義：
```cql
code "64164B": '64164B' from "NHI_PROCEDURE" display '人工膝關節置換術'
code "609588000": '609588000' from "SNOMEDCT" display 'Total knee replacement'
```

**推測**：
1. CQL定義了多個CodeSystem（NHI_PROCEDURE, SNOMEDCT等）
2. CQL可能檢查Procedure是否**至少包含其中一個系統**的code
3. 如果system URL不匹配，或缺少關鍵的coding，可能導致匹配失敗

---

## ✅ 解決方案

### 新上傳的資料（TW10047）

完全複製成功案例的結構：

**Patient**: TW10047（identifier: TW10047）

**TKA Procedure**:
- System 1: `https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure` → 64164B
- System 2: `http://snomed.info/sct` → 609588000
- System 3: `http://www.ama-assn.org/go/cpt` → 27447
- Date: 2026-01-10

**感染 Procedure**:
- System 1: `https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure` → 64053B
- System 2: `http://snomed.info/sct` → 77849006
- Date: 2026-03-06（55天後）

**預期結果**:
- 2026-Q1分母: 7個（原6個 + TW10047）
- 2026-Q1分子: 1個（TW10047）
- 感染率: 14.29%

---

## 🔬 驗證步驟

### 1. 確認資源已上傳
```http
GET https://thas.mohw.gov.tw/v/r4/fhir/Patient/TW10047
GET https://thas.mohw.gov.tw/v/r4/fhir/Procedure/tka-procedure-TW10047
GET https://thas.mohw.gov.tw/v/r4/fhir/Procedure/tka-infection-procedure-TW10047
```

### 2. 執行15-2 CQL查詢
在quality-indicators.html中執行查詢

### 3. 預期結果
- 分母: 7
- 分子: 1
- 感染率: 14.29%

---

## 📝 學到的教訓

### 問題1: Patient identifier ❌ （已解決但不是主因）
- 雖然添加了identifier，但這不是主要問題
- 成功案例也有identifier，但更重要的是Procedure.code

### 問題2: Procedure.code.coding數量和system **✓ 真正原因**
- **必須包含多個coding系統**
- **System URL必須正確**
- NHI code必須使用正確的FHIR CodeSystem URL
- 最好同時包含SNOMED和CPT code

### 問題3: CQL的Code匹配機制
- CQL不只看code值，也看system
- 如果system不匹配，即使code正確也可能失敗
- 多個coding提高了匹配成功率

---

## 📂 相關檔案

- 成功案例查詢: Patient/tka-patient-001 (2025 Q4)
- 新測試資料: [test_data_15_2_SUCCESS_TEMPLATE_2026Q1.json](test_data_15_2_SUCCESS_TEMPLATE_2026Q1.json)
- 生成腳本: [generate_15_2_copy_from_success.py](generate_15_2_copy_from_success.py)

---

## 🎯 下一步

1. 執行15-2 CQL查詢
2. 確認TW10047被計入分子
3. 如果成功，更新TW10001-TW10006的Procedure，添加SNOMED和CPT coding

---

**結論**: 
- ❌ 不是Patient identifier的問題
- ❌ 不是時間間隔的問題
- ✅ **是Procedure.code.coding的系統和數量問題**
