# 指标1710 双编码支持对比分析

## 问题：当前CQL是否支持双编码？

### ❌ 答案：**没有！**

---

## 当前版本 vs 改进版本对比

### 📄 当前版本 (Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql)

**编码系统定义**：
```cql
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHI_PROCEDURE": 'http://www.nhi.gov.tw/codes'  // ⚠️ 只定义了procedure，没有medication
```

**药品查询逻辑**：
```cql
define "Antihypertensive Prescriptions":
  [MedicationRequest] MR
    where MR.status.value = 'completed'
    and exists (
      MR.medicationCodeableConcept.coding MC
        where MC.system.value = 'http://www.whocc.no/atc'  // ❌ 只检查ATC
        and exists (
          MR.contained C
            where C is FHIR.Medication
            and IsAntihypertensiveOralDrug(MC.code.value, C.code.coding[0].code.value)
        )
    )
```

**问题**：
- ❌ 只支持ATC代码
- ❌ 医院如果只提供健保代号，无法识别
- ❌ 依赖所有医院必须提供ATC编码
- ❌ 覆盖率可能不完整

---

### ✅ 改进版本 (Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710_DUAL_CODING.cql)

**编码系统定义**：
```cql
codesystem "ATC": 'http://www.whocc.no/atc'
codesystem "NHI_MEDICATION": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code'  // ✅ 新增
```

**ValueSet定义**：
```cql
// ATC降血压药品值集
valueset "ATC Antihypertensive Drugs": 'http://example.org/fhir/ValueSet/atc-antihypertensive-drugs'

// 健保降血压药品值集
valueset "NHI Antihypertensive Drugs": 'http://example.org/fhir/ValueSet/nhi-antihypertensive-drugs'
```

**关键改进函数**：
```cql
// 函数2: 获取ATC代码
define function GetATCCode(medication FHIR.CodeableConcept):
  First(
    medication.coding C
      where C.system.value = 'http://www.whocc.no/atc'
      return C.code.value
  )

// 函数3: 获取健保药品代号
define function GetNHICode(medication FHIR.CodeableConcept):
  First(
    medication.coding C
      where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code'
      return C.code.value
  )

// 函数4: 检查ATC代码是否为降血压药
define function IsAntihypertensiveByATC(atcCode String):
  // ATC逻辑判断

// 函数5: 检查健保代号是否为降血压药
define function IsAntihypertensiveByNHI(nhiCode String):
  // 健保代号逻辑判断

// 函数7: 综合判断（关键 OR 逻辑）
define function IsAntihypertensiveOralDrug(medication FHIR.CodeableConcept):
  let 
    atcCode: GetATCCode(medication),
    nhiCode: GetNHICode(medication),
    isAntihypertensiveByATC: IsAntihypertensiveByATC(atcCode),
    isAntihypertensiveByNHI: IsAntihypertensiveByNHI(nhiCode),
    isInjection: IsInjection(Coalesce(nhiCode, atcCode))
  in
    // ✅ OR逻辑: 符合ATC标准 或 符合健保标准
    (isAntihypertensiveByATC or isAntihypertensiveByNHI)
    and not isInjection
```

**主查询逻辑**：
```cql
define "Antihypertensive Prescriptions":
  [MedicationRequest] MR
    where 
      MR.status.value = 'completed'
      // ✅ 使用改进后的函数，支持双编码
      and IsAntihypertensiveOralDrug(GetMedicationCodeableConcept(MR))
      and exists ("Outpatient Encounters" E where E.id.value = GetEncounterId(MR))
```

**优势**：
- ✅ 同时支持健保代号 + ATC代号
- ✅ 使用OR逻辑，符合任一即可
- ✅ 兼容只有健保代号的医院
- ✅ 兼容只有ATC代号的医院
- ✅ 对双编码医院效率最优
- ✅ 最大化覆盖率

---

## 数据资源对比

### 当前版本要求的数据格式（仅ATC）

```json
{
  "resourceType": "MedicationRequest",
  "medicationCodeableConcept": {
    "coding": [
      {
        "system": "http://www.whocc.no/atc",
        "code": "C09AA05"
      }
    ]
  }
}
```

**结果**：✅ 可以识别

---

### 改进版本支持的数据格式

**情境1: 仅健保代号**
```json
{
  "resourceType": "MedicationRequest",
  "medicationCodeableConcept": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
        "code": "AC12345100"
      }
    ]
  }
}
```
- 当前版本：❌ 无法识别
- 改进版本：✅ 可以识别

**情境2: 仅ATC代号**
```json
{
  "resourceType": "MedicationRequest",
  "medicationCodeableConcept": {
    "coding": [
      {
        "system": "http://www.whocc.no/atc",
        "code": "C09AA05"
      }
    ]
  }
}
```
- 当前版本：✅ 可以识别
- 改进版本：✅ 可以识别

**情境3: 双编码（最佳实践）**
```json
{
  "resourceType": "MedicationRequest",
  "medicationCodeableConcept": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
        "code": "AC12345100",
        "display": "Ramipril 5mg"
      },
      {
        "system": "http://www.whocc.no/atc",
        "code": "C09AA05",
        "display": "ramipril"
      }
    ]
  }
}
```
- 当前版本：✅ 可以识别（通过ATC）
- 改进版本：✅ 可以识别（通过ATC或健保，两者都匹配）

---

## 核心差异总结

| 特性 | 当前版本 | 改进版本 |
|------|---------|---------|
| 支持健保代号 | ❌ 否 | ✅ 是 |
| 支持ATC代号 | ✅ 是 | ✅ 是 |
| OR逻辑 | ❌ 否 | ✅ 是 |
| 兼容单一编码 | 部分（仅ATC） | ✅ 完全 |
| 覆盖率 | 低（依赖ATC） | ✅ 高 |
| 过渡期友好 | ❌ 否 | ✅ 是 |
| ValueSet支持 | ❌ 否 | ✅ 是 |
| 函数模块化 | 部分 | ✅ 完全 |

---

## 实施建议

### 短期（立即可做）

1. **更新CQL文件**
   - 采用改进版本的逻辑
   - 添加`NHI_MEDICATION` CodeSystem定义
   - 实现OR逻辑函数

2. **建立健保代号清单**
   - 收集所有降血压药品的健保代号
   - 创建对应的ValueSet
   - 上传到FHIR服务器

3. **数据质量检查**
   - 检查现有MedicationRequest资源的编码完整度
   - 统计只有健保代号、只有ATC、双编码的比例

### 中期（1-3个月）

1. **鼓励医院提供双编码**
   - 发布数据质量指南
   - 提供健保-ATC对照表
   - 技术支持与培训

2. **建立自动转换机制**
   - 开发健保代号→ATC自动映射服务
   - 在数据上传时自动补充缺失的编码

3. **监控与评估**
   - 追踪双编码覆盖率提升
   - 对比改进前后的指标计算结果

### 长期（6-12个月）

1. **强制要求双编码**
   - 所有新上传的处方必须包含双编码
   - 对旧数据进行回溯补充

2. **扩展到其他指标**
   - 将双编码策略应用到所有药品相关指标
   - Condition、Procedure等资源也实施双编码

3. **国际标准对齐**
   - 确保所有临床资源符合FHIR最佳实践
   - 提升台湾FHIR数据的国际互操作性

---

## 结论

**当前CQL文件没有双编码支持**，仅支持ATC代码。建议采用改进版本，实现：

1. ✅ 健保代号 + ATC代号双编码
2. ✅ OR逻辑（符合任一即可）
3. ✅ 最大化数据覆盖率
4. ✅ 平滑过渡机制

这样才能真正实现"完美兼容"的双编码最佳实践！
