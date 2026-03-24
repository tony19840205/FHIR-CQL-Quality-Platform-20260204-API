# 15-2指標修復成功記錄

**日期**: 2026-01-04  
**問題**: 15-2全膝關節90天感染率指標無法命中分子（numerator=0）  
**結果**: ✅ 成功顯示 **57.14%** 感染率

---

## 根本原因

1. **ICD-10代碼不完整**  
   - 錯誤: `T84.54`  
   - 正確: `T84.54XA`（程式要求完整代碼含後綴）

2. **Condition綁定錯誤的Encounter**  
   - 錯誤: 綁定感染專用的encounter (e.g., `tka-infection-encounter-TW10001`)  
   - 正確: 綁定TKA手術的encounter (e.g., `tka-encounter-TW10001`)

---

## 解決方案

### 步驟1: 修正ICD-10代碼
```json
"code": {
  "coding": [{
    "system": "http://hl7.org/fhir/sid/icd-10-cm",
    "code": "T84.54XA",  // ← 必須加XA後綴
    "display": "Infection and inflammatory reaction due to internal knee prosthesis, initial encounter"
  }]
}
```

### 步驟2: 修正Encounter Reference
```json
"encounter": {
  "reference": "Encounter/tka-encounter-TW10001"  // ← 必須是TKA手術的encounter
}
```

---

## 修正的資料

**檔案**: `fix_condition_code_to_T84_54XA.json`  
更新3筆Condition代碼：
- `tka-infection-condition-001` (2025-Q4)
- `tka-infection-condition-002` (2025-Q4)
- `tka-infection-condition-TW10001` (2026-Q1)

**檔案**: `fix_condition_encounter_TW10001.json`  
修正encounter reference

**檔案**: `add_infections_2026Q1.json`  
新增3筆感染Condition：
- `tka-infection-condition-001-2026Q1` (TW10001, Encounter: tka-enc-001)
- `tka-infection-condition-003-2026Q1` (TW10003, Encounter: tka-enc-003)
- `tka-infection-condition-005-2026Q1` (TW10005, Encounter: tka-enc-005)

---

## 驗證結果

### 2026-Q1 感染資料
| 病人 | TKA Procedure | 感染狀態 |
|------|--------------|---------|
| TW10001 | tka-proc-001 | ✓ 有感染 |
| TW10001 | tka-procedure-TW10001 | ✓ 有感染 |
| TW10003 | tka-proc-003 | ✓ 有感染 |
| TW10005 | tka-proc-005 | ✓ 有感染 |

**總計**: 4筆感染 / 7筆TKA手術 = **57.14%**

---

## 程式邏輯確認

位置: [js/quality-indicators.js:3737-3746](js/quality-indicators.js#L3737-L3746)

```javascript
const conditions = await conn.query('Condition', {
    encounter: `Encounter/${encounterId}`,  // 查詢TKA手術的encounter
    _count: 10
});

if (conditions.entry) {
    for (const condEntry of conditions.entry) {
        const condition = condEntry.resource;
        const icd10Code = condition.code?.coding?.find(c => 
            c.system?.includes('icd-10'))?.code;
        
        if (icd10Code === 'T84.54XA') {  // 必須完全符合
            infectionCount++;
            break;
        }
    }
}
```

---

## 關鍵學習

1. **FHIR資料結構必須精確**  
   - ICD-10代碼必須包含完整後綴 (XA = initial encounter)
   - Condition必須綁定正確的Encounter

2. **程式查詢邏輯**  
   - 透過Procedure的encounter查詢關聯的Condition
   - 不是透過時間範圍或Patient查詢

3. **測試方法**  
   - 獨立測試頁面可以驗證邏輯正確性
   - PowerShell腳本可以模擬程式查詢流程

---

## 成功標準

✅ 分母能正確計算TKA手術數量  
✅ 分子能正確識別90天內感染案例  
✅ 感染率顯示 **57.14%**（4/7）  
✅ 無需修改程式碼，僅調整病人資料

---

**修復完成**: 2026-01-04  
**方法**: 資料結構修正（遵循用戶「不要改程式!!改病人資料」要求）
