# 健保代号在TWcore FHIR IG中的定义

## 问题2答案：健保代号**可以**在FHIR中使用（通过TWcore IG）

---

## TWcore (Taiwan Core) Implementation Guide

**TWcore** 是台湾FHIR核心实施指南，定义了台湾特有的医疗编码系统在FHIR中的使用方式。

### 官方网址
- **Base URL**: `https://twcore.mohw.gov.tw/ig/twcore/`
- **发布单位**: 卫生福利部（MOHW）

---

## 健保代号的CodeSystem定义

### 1. 健保诊断代号
```
System URL: https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code
OID: urn:oid:2.16.886.101.20003.20001
```

**用途**: Condition资源
**示例**:
```json
{
  "resourceType": "Condition",
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code",
        "code": "A269",
        "display": "高血压病"
      }
    ]
  }
}
```

---

### 2. 健保处置代号 (Procedure)
```
System URL: https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure
OID: urn:oid:2.16.886.101.20003.20014
```

**用途**: Procedure资源
**示例**:
```json
{
  "resourceType": "Procedure",
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure",
        "code": "64164B",
        "display": "人工膝关节置换术"
      },
      {
        "system": "http://snomed.info/sct",
        "code": "609588000",
        "display": "Total knee replacement"
      }
    ]
  }
}
```

---

### 3. 健保药品代号
```
System URL: https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code
OID: urn:oid:2.16.886.101.20003.20005
```

**用途**: Medication, MedicationRequest资源
**示例**:
```json
{
  "resourceType": "MedicationRequest",
  "medicationCodeableConcept": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
        "code": "AC12345100",
        "display": "某某药品"
      },
      {
        "system": "http://www.whocc.no/atc",
        "code": "J01CR02",
        "display": "amoxicillin and beta-lactamase inhibitor"
      }
    ]
  }
}
```

---

### 4. 健保检验代号
```
System URL: https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-laboratory-code
OID: urn:oid:2.16.886.101.20003.20024
```

**用途**: Observation资源（检验）

---

## 混合使用健保代号 + 国际标准代号

### 最佳实践模式

```json
{
  "resourceType": "Condition",
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code",
        "code": "A0991",
        "display": "COVID-19"
      },
      {
        "system": "http://hl7.org/fhir/sid/icd-10-cm",
        "code": "U07.1",
        "display": "COVID-19, virus identified"
      },
      {
        "system": "http://snomed.info/sct",
        "code": "840539006",
        "display": "Disease caused by SARS-CoV-2"
      }
    ],
    "text": "COVID-19确诊"
  }
}
```

**优势**:
1. ✅ 兼容健保系统（申报、统计）
2. ✅ 符合国际FHIR标准（ICD-10、SNOMED）
3. ✅ 查询时使用OR逻辑，符合任一即可

---

## CQL查询示例

### 方式1: 同时支持健保代号和ICD-10

```cql
codesystem "NHI_DIAGNOSIS": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code'
codesystem "ICD10CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

// 定义健保COVID代号
code "NHI_COVID": 'A0991' from "NHI_DIAGNOSIS" display 'COVID-19(健保)'

// 定义ICD-10代号
code "ICD10_COVID_CONFIRMED": 'U07.1' from "ICD10CM" display 'COVID-19确诊'
code "ICD10_COVID_SUSPECTED": 'U07.2' from "ICD10CM" display 'COVID-19疑似'

// 定义SNOMED代号
code "SNOMED_COVID": '840539006' from "SNOMEDCT" display 'COVID-19'

// 查询逻辑：符合任何一个代号系统即可
define "COVID19 Conditions":
  [Condition] C
  where exists (
    C.code.coding Coding
    where 
      (Coding ~ "NHI_COVID")
      or (Coding ~ "ICD10_COVID_CONFIRMED")
      or (Coding ~ "ICD10_COVID_SUSPECTED")
      or (Coding ~ "SNOMED_COVID")
  )
```

---

### 方式2: 使用ValueSet（推荐）

```cql
valueset "COVID19 Diagnosis Codes": 'http://example.org/fhir/ValueSet/covid19-diagnosis'
// ValueSet包含:
// - NHI: A0991
// - ICD-10: U07.1, U07.2
// - SNOMED: 840539006

define "COVID19 Conditions":
  [Condition: "COVID19 Diagnosis Codes"]
```

---

## FHIR REST API查询

### 查询COVID诊断（同时支持健保和ICD-10）

**方式A: 使用code参数（OR逻辑）**
```http
GET /Condition?code=A0991,U07.1,U07.2,840539006&_count=100
```

**方式B: 使用system|code格式（更精确）**
```http
GET /Condition?code=https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code|A0991,
                   http://hl7.org/fhir/sid/icd-10-cm|U07.1,
                   http://hl7.org/fhir/sid/icd-10-cm|U07.2,
                   http://snomed.info/sct|840539006
              &_count=100
```

**方式C: 使用文本搜索（最灵活）**
```http
GET /Condition?code:text=COVID&_count=100
```

---

## 实际应用场景

### 场景1: 医院上传资料到FHIR服务器

**阶段1: 仅使用健保代号**（兼容旧系统）
```json
{
  "code": {
    "coding": [{
      "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code",
      "code": "A269"
    }]
  }
}
```

**阶段2: 健保代号 + ICD-10**（过渡期）
```json
{
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code",
        "code": "A269"
      },
      {
        "system": "http://hl7.org/fhir/sid/icd-10-cm",
        "code": "I10"
      }
    ]
  }
}
```

**阶段3: 完整编码**（最佳实践）
```json
{
  "code": {
    "coding": [
      {
        "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code",
        "code": "A269",
        "display": "高血压病"
      },
      {
        "system": "http://hl7.org/fhir/sid/icd-10-cm",
        "code": "I10",
        "display": "Essential (primary) hypertension"
      },
      {
        "system": "http://snomed.info/sct",
        "code": "38341003",
        "display": "Hypertensive disorder"
      }
    ],
    "text": "高血压"
  }
}
```

---

### 场景2: CQL指标计算

**支持多编码系统的指标查询**:

```cql
// 定义高血压代号（健保 + ICD-10 + SNOMED）
valueset "Hypertension Codes": 'http://example.org/fhir/ValueSet/hypertension'
// 包含: NHI A269, ICD-10 I10, SNOMED 38341003

// 分母: 所有高血压患者
define "Denominator":
  [Condition: "Hypertension Codes"] C
  where C.clinicalStatus ~ "Active"

// 分子: 有HbA1c检测的高血压患者
define "Numerator":
  "Denominator" D
  with [Observation: "HbA1c"] O
    such that O.subject.reference = 'Patient/' + Patient.id
```

**优势**: 不管医院使用哪种编码系统，都能被正确计算

---

## 总结

### 问题1答案: ✅ 可以使用健保代号 + FHIR代号 OR搜索

1. **技术上完全可行**
   - FHIR设计就支持一个资源包含多个coding系统
   - 使用OR逻辑：符合任何一个就算

2. **查询方式**
   - CQL: 使用`or`连接多个code检查
   - REST API: `code=code1,code2,code3`（逗号=OR）
   - ValueSet: 定义包含多个系统的值集

3. **建议策略**
   - 数据端: 尽可能包含多个编码系统
   - 查询端: 支持所有可能的代号系统
   - 过渡期: 健保代号为主，逐步增加ICD-10/SNOMED

---

### 问题2答案: ✅ 健保代号在TWcore IG中**有定义**

1. **TWcore提供的健保CodeSystem**
   - 诊断: `https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-diagnosis-code`
   - 处置: `https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-procedure`
   - 药品: `https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code`
   - 检验: `https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-laboratory-code`

2. **使用方式**
   - 在FHIR资源的coding数组中使用正确的system URL
   - 可以与ICD-10、SNOMED等国际标准并存
   - CQL查询时使用CodeSystem定义引用

3. **注意事项**
   - ⚠️ 必须使用正确的system URL（`https://twcore.mohw.gov.tw/...`）
   - ⚠️ 不要使用OID格式作为system（虽然TWcore有定义OID，但FHIR推荐用URL）
   - ⚠️ 记得添加_count参数避免分页限制（默认20条）

---

## 参考资源

- TWcore官网: https://twcore.mohw.gov.tw/ig/twcore/
- FHIR R4规范: http://hl7.org/fhir/R4/
- 健保署医疗资讯云端查询系统: https://medcloud.nhi.gov.tw/
