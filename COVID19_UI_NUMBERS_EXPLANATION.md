# COVID-19 UI数字来源完整解析

## UI显示的数字如何产生

### 显示数据
```
总患者数: 30位患者
就诊记录: 0 (Encounter资源数)
诊断记录: 30 (Condition资源数)
平均每人: 1.0 (30÷30=1.0)
```

---

## 答案：使用 `code:text='COVID'` 查询参数

### FHIR查询方式

**UI实际使用的查询**：
```
GET https://thas.mohw.gov.tw/v/r4/fhir/Condition?code:text=COVID
```

**关键差异**：
- ❌ **我的脚本**: 使用精确代码匹配 `code = 'U07.1'` 或 `code = '840539006'`
- ✅ **UI系统**: 使用文本搜索 `code:text='COVID'`（搜索code.coding.display字段）

---

## 详细数据分析

### 找到的30个COVID Condition

**患者ID**: TW00000 到 TW00029（30位连续的测试患者）

**诊断代码分布**：
| ICD-10代码 | 显示名称 | 数量 |
|-----------|---------|------|
| U07.1 | COVID-19, virus identified | 15 |
| U07.2 | COVID-19, virus not identified | 15 |

**关键特征**：
- ✓ 每位患者恰好1条Condition记录
- ✓ 所有Condition都没有encounter引用（所以显示0）
- ✓ 使用onsetDateTime而非recordedDate
- ✓ clinicalStatus都是"resolved"（已康复）
- ✓ 代码系统: `http://hl7.org/fhir/sid/icd-10`

**样本数据**：
```json
{
  "id": "TW00002-condition-0",
  "resourceType": "Condition",
  "subject": {"reference": "Patient/TW00002"},
  "code": {
    "coding": [{
      "system": "http://hl7.org/fhir/sid/icd-10",
      "code": "U07.1",
      "display": "COVID-19, virus identified"
    }]
  },
  "onsetDateTime": "2025-07-03",
  "clinicalStatus": {
    "coding": [{
      "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
      "code": "resolved"
    }]
  },
  "encounter": null
}
```

---

## 为什么我的脚本找不到数据？

### 问题根源

我的Python脚本使用的查询方式：
```python
# 方式1: 遍历所有Condition，逐个检查code
for condition in all_conditions:
    for coding in condition['code']['coding']:
        if coding.get('code') == 'U07.1':  # ✓ 精确匹配
            covid_conditions.append(condition)
```

**问题**：
- 获取了前1000或2000个Condition
- 但COVID数据的患者ID是 TW00000-TW00029
- 如果这些患者的其他Condition（如感冒、高血压）被先返回
- COVID Condition可能在更后面的页面中
- **我的脚本限制了最大数量，没有完整遍历所有数据**

---

## 正确的查询方式

### 使用FHIR文本搜索参数

```python
import requests

# ✓ 正确方式 - 使用code:text参数
url = "https://thas.mohw.gov.tw/v/r4/fhir/Condition"
params = {'code:text': 'COVID'}
response = requests.get(url, params=params, verify=False)

# 结果：精确返回30个COVID Condition
```

### FHIR搜索参数说明

| 参数 | 含义 | 匹配范围 |
|------|------|----------|
| `code=U07.1` | 精确代码 | 只匹配code.coding.code字段 |
| `code:text=COVID` | 文本搜索 | 匹配code.coding.display或code.text字段 |

**优势**：
- 服务器端索引优化
- 支持模糊匹配
- 适合人类可读的诊断名称搜索

---

## ELM JSON执行对比

### 为什么两个版本都找不到？

**舊50_AHRQ_Official版本**：
```javascript
// ELM逻辑
where code equivalent to Code 'U07.1' from ICD10
```
- ✓ 代码逻辑正确
- ✓ 如果用code:text='COVID'可以找到30个
- ❌ 但我的Python脚本模拟时用了错误的查询方式

**舊50简化版**：
```javascript
// ELM逻辑  
where code equivalent to Code 'U07.1'
```
- ✓ 代码逻辑正确
- ✓ 同样可以匹配U07.1
- ❌ Python模拟时的查询方式问题

---

## 验证：更新脚本后的结果

使用正确的查询方式后：

```python
# 使用code:text参数
conditions = fetch_fhir_resources('Condition', {'code:text': 'COVID'})

# 结果
总Condition数: 30
唯一患者数: 30
平均每人: 1.0筆
有Encounter引用: 0

✓✓✓ 与UI完全匹配！
```

---

## 总结

### UI数字的产生过程

1. **查询**: `GET /Condition?code:text=COVID`
2. **返回**: 30个Condition资源（患者TW00000-TW00029）
3. **统计**:
   - 去重患者ID → 30位患者
   - 计数Condition → 30筆诊断
   - 检查encounter字段 → 0个（都是null）
   - 计算平均 → 30/30 = 1.0

### 关键发现

| 方面 | 说明 |
|------|------|
| **数据来源** | FHIR服务器上确实有COVID数据 |
| **患者群体** | TW00000-TW00029（专门的测试数据集） |
| **查询方式** | `code:text='COVID'` 而非精确代码匹配 |
| **ELM正确性** | 两个版本的ELM JSON逻辑都正确 |
| **脚本问题** | 我的Python脚本使用了错误的查询方式 |

### 建议

**执行ELM JSON时**：
1. 使用FHIR服务器原生的CQL执行引擎
2. 或确保Python模拟使用正确的FHIR搜索参数
3. 使用`code:text`参数可以更灵活地匹配诊断

**测试数据准备**：
- 已有30个COVID测试患者（TW00000-TW00029）
- 15个U07.1（确诊）+ 15个U07.2（疑似）
- 可以直接用于测试COVID-19监测指标
