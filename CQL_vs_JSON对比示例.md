# CQL vs 直接写ELM JSON - 完全可行！

## 核心概念
- **CQL**: 人类可读的查询语言（就像SQL）
- **ELM JSON**: 机器执行的格式（就像编译后的字节码）
- **结论**: 直接写JSON完全可以，绕过所有转换问题！

---

## 示例对比

### CQL代码（人类友好）
```cql
library Example version '1.0.0'

using FHIR version '4.0.1'

parameter MeasurementPeriod Interval<DateTime>

define "Encounters":
  [Encounter] E
  where E.period during MeasurementPeriod
```

### 等价的ELM JSON（直接可执行）
```json
{
  "library": {
    "identifier": {
      "id": "Example",
      "version": "1.0.0"
    },
    "schemaIdentifier": {
      "id": "urn:hl7-org:elm",
      "version": "r1"
    },
    "usings": {
      "def": [
        {
          "localIdentifier": "System",
          "uri": "urn:hl7-org:elm-types:r1"
        },
        {
          "localIdentifier": "FHIR",
          "uri": "http://hl7.org/fhir",
          "version": "4.0.1"
        }
      ]
    },
    "parameters": {
      "def": [
        {
          "name": "MeasurementPeriod",
          "accessLevel": "Public",
          "parameterTypeSpecifier": {
            "type": "IntervalTypeSpecifier",
            "pointType": {
              "name": "{urn:hl7-org:elm-types:r1}DateTime",
              "type": "NamedTypeSpecifier"
            }
          }
        }
      ]
    },
    "statements": {
      "def": [
        {
          "name": "Patient",
          "context": "Patient",
          "expression": {
            "type": "SingletonFrom",
            "operand": {
              "dataType": "{http://hl7.org/fhir}Patient",
              "type": "Retrieve"
            }
          }
        },
        {
          "name": "Encounters",
          "context": "Patient",
          "accessLevel": "Public",
          "expression": {
            "type": "Query",
            "source": [
              {
                "alias": "E",
                "expression": {
                  "dataType": "{http://hl7.org/fhir}Encounter",
                  "type": "Retrieve"
                }
              }
            ],
            "relationship": [],
            "where": {
              "type": "IncludedIn",
              "operand": [
                {
                  "path": "period",
                  "scope": "E",
                  "type": "Property"
                },
                {
                  "name": "MeasurementPeriod",
                  "type": "ParameterRef"
                }
              ]
            }
          }
        }
      ]
    }
  }
}
```

---

## 优点：直接写JSON

### ✅ 优势
1. **完全控制**: 精确到每个节点
2. **无转换错误**: 不依赖任何转换工具
3. **100%可执行**: 保证官方标准
4. **即时验证**: 用cql-execution测试

### ⚠️ 挑战
1. **冗长**: 代码量是CQL的10-20倍
2. **容易出错**: 手写易遗漏字段
3. **维护困难**: 修改逻辑需要改很多地方

---

## 实用方案：混合模式

### 策略1: 模板化
创建常用模式的JSON模板，填充参数即可

### 策略2: 部分手写
- 简单逻辑：直接写JSON
- 复杂逻辑：用增强版转换器生成骨架，手工补全

### 策略3: 验证循环
```
编写JSON → 用cql-execution测试 → 修复错误 → 重复
```

---

## 我可以为你创建

### 工具1: JSON模板生成器
输入：数据类型、条件、参数
输出：完整ELM JSON骨架

### 工具2: JSON片段库
常用模式：
- Retrieve（查询资源）
- Query with Where（条件过滤）
- Function调用
- 日期比较
- 数量计算

### 工具3: 智能验证器
检查：
- Schema正确性
- 类型匹配
- 必需字段
- 可执行性

---

## 立即开始

你想要：
1. **选项A**: 我创建8个中医指标的ELM JSON模板，你填充业务逻辑
2. **选项B**: 我创建JSON片段库，你组装成完整ELM
3. **选项C**: 针对某个具体指标，我手工写完整ELM JSON示例

哪个对你最有帮助？
