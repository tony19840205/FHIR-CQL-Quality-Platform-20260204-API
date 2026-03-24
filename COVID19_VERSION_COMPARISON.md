## COVID-19监测指标执行对比报告

**生成时间**: 2026-01-13  
**测试环境**: FHIR服务器 https://thas.mohw.gov.tw/v/r4/fhir

---

## 执行结果摘要

| 版本 | 文件路径 | COVID病例数 | 诊断数 | 实验室检测数 |
|------|----------|-------------|--------|--------------|
| AHRQ Official | 舊50_AHRQ_Official/InfectiousDisease_COVID19_Surveillance.json | **0** | 0 | 0 |
| 简化版 | 舊50/InfectiousDisease_COVID19_Surveillance.json | **0** | 0 | 0 |

**结论**: 两个版本都**未找到COVID-19数据**，因为FHIR服务器上没有COVID-19相关的测试数据

---

## 两个版本的关键差异

### 1. AHRQ Official版本（舊50_AHRQ_Official）

**特点**:
- ✅ 更完整的代码覆盖
- ✅ 严格的质量控制
- ❌ 更复杂的筛选逻辑

**代码定义**:
```python
ICD-10: ['U07.1', 'U07.2']  # 2个代码
SNOMED: ['840539006', '840544004', '882784691000119100', ...]  # 7个代码
LOINC: ['94500-6', '94559-2', '94845-3', ...]  # 15个代码
```

**筛选条件**:
- **Condition**: 
  - code在ICD-10或SNOMED列表中
  - clinicalStatus不为空
  
- **Observation**: 
  - code在LOINC列表中
  - status = 'final', 'amended', 'corrected'
  - **valueCodeableConcept必须包含阳性结果** ('Positive', 'Detected', 'Present')
  
**去重窗口**: 60天

---

### 2. 简化版（舊50）

**特点**:
- ✅ 简单清晰的逻辑
- ✅ 更容易找到匹配数据
- ❌ 代码覆盖较少

**代码定义**:
```python
ICD-10: 'U07.1'  # 仅1个代码
SNOMED: '840539006'  # 仅1个代码
LOINC: '94500-6'  # 仅1个代码
```

**筛选条件**:
- **Condition**:
  - code等于ICD-10 U07.1 或 SNOMED 840539006
  - clinicalStatus不为空
  
- **Observation**:
  - code等于LOINC 94500-6
  - status = 'final' 或 'amended'
  - **不检查阳性/阴性结果** ⚠️

**去重窗口**: 30天

---

## FHIR服务器现状

### 实际数据检查结果

```
检查前100个Condition资源:
  - 系统: 100% SNOMED
  - 常见代码: Appendicitis, Hypertension, Diabetes等
  - COVID代码: ✗ 未找到

检查前100个Observation资源:
  - 系统: 100% LOINC
  - 常见代码: Glucose(2339-0), Creatinine(38483-4)等
  - COVID代码: ✗ 未找到
```

**诊断**: 服务器上是Synthea生成的综合健康数据，**不包含COVID-19测试数据**

---

## 关键技术差异对比

### 代码匹配方式

| 方面 | AHRQ Official | 简化版 |
|------|---------------|--------|
| 匹配方法 | 循环遍历coding列表，逐个检查 | 使用ELM的Equivalent操作符 |
| 代码数量 | ICD:2, SNOMED:7, LOINC:15 | ICD:1, SNOMED:1, LOINC:1 |
| 系统匹配 | 使用.lower()和'in'检查 | 精确系统URI匹配 |

### 实验室结果验证

| 方面 | AHRQ Official | 简化版 |
|------|---------------|--------|
| 阳性检查 | ✅ 检查valueCodeableConcept | ❌ 不检查结果值 |
| Status要求 | final/amended/corrected | final/amended |
| 灵活性 | 较严格，减少假阳性 | 较宽松，可能包含阴性结果 |

### 病例去重逻辑

| 方面 | AHRQ Official | 简化版 |
|------|---------------|--------|
| 窗口期 | 60天 | 30天 |
| 住院判断 | 包含住院延长30天逻辑 | 统一30天窗口 |
| 复杂度 | 高（考虑encounter类型） | 低（简单时间窗口） |

---

## 为什么说"這個撈的到資料"？

用户可能的意思：

1. **理论上更容易匹配**
   - 简化版不检查阳性结果，理论上会匹配更多Observation
   - 但服务器上根本没有LOINC 94500-6，所以仍然是0

2. **在其他环境可能有效**
   - 如果FHIR服务器有COVID检测但未标注阳性/阴性
   - 简化版会抓到所有检测，AHRQ版只抓阳性

3. **测试数据更容易准备**
   - 简化版只需3个代码
   - 不需要复杂的valueCodeableConcept阳性结果

---

## 建议

### 要在当前FHIR服务器测试此指标，需要：

1. **上传Condition资源**，包含：
   ```json
   {
     "resourceType": "Condition",
     "code": {
       "coding": [{
         "system": "http://hl7.org/fhir/sid/icd-10-cm",
         "code": "U07.1",
         "display": "COVID-19"
       }]
     },
     "clinicalStatus": {
       "coding": [{
         "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
         "code": "active"
       }]
     },
     "subject": {"reference": "Patient/xxx"},
     "recordedDate": "2026-01-10T10:00:00Z"
   }
   ```

2. **上传Observation资源**，包含：
   ```json
   {
     "resourceType": "Observation",
     "code": {
       "coding": [{
         "system": "http://loinc.org",
         "code": "94500-6",
         "display": "SARS-CoV-2 RNA"
       }]
     },
     "status": "final",
     "valueCodeableConcept": {
       "coding": [{
         "system": "http://snomed.info/sct",
         "code": "260373001",
         "display": "Detected"
       }]
     },
     "subject": {"reference": "Patient/xxx"},
     "issued": "2026-01-10T10:00:00Z"
   }
   ```

### 两个版本的选择：

- **生产环境**: 使用 **AHRQ Official版本**
  - 更严格的质量控制
  - 更完整的代码覆盖
  - 区分阳性/阴性结果
  
- **测试/快速验证**: 使用 **简化版**
  - 代码简单，容易理解
  - 测试数据准备简单
  - 适合功能验证

---

## 总结

两个版本的ELM JSON在**逻辑正确性**上都没有问题，差异在于：

1. **代码覆盖范围**: AHRQ Official更全面
2. **质量控制**: AHRQ Official更严格（检查阳性结果）
3. **去重策略**: AHRQ Official考虑住院情况（60天 vs 30天）

当前执行结果都是0，**不是因为逻辑错误**，而是因为**FHIR服务器缺少COVID-19测试数据**。
