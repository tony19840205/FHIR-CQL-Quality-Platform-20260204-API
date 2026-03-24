# 为什么不应该直接编辑ELM JSON文件

## 问题：能否直接在JSON中增加健保代号支持？

### ❌ 技术上可以，但**极度不推荐**

---

## ELM JSON的本质

```
CQL源代码 (人类可读)
    ↓
[CQL-to-ELM Translator 编译]
    ↓
ELM JSON (机器可读的抽象语法树)
    ↓
[CQL Execution Engine 执行]
    ↓
结果
```

**ELM JSON = CQL的"编译产物"** (类似于Java的.class文件)

---

## 方式对比

### 🔴 方式1：直接修改JSON（不推荐）

#### 你需要手动添加的内容

**Step 1: 添加CodeSystem定义**
```json
{
  "library": {
    "codeSystems": {
      "def": [
        {
          "name": "ATC",
          "id": "http://www.whocc.no/atc",
          "accessLevel": "Public"
        },
        // ⚠️ 手动添加这个 - 容易出错！
        {
          "name": "NHI_MEDICATION",
          "id": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
          "accessLevel": "Public",
          "annotation": []
        }
      ]
    }
  }
}
```

**Step 2: 添加GetNHICode函数（超级复杂！）**
```json
{
  "name": "GetNHICode",
  "context": "Unfiltered",
  "accessLevel": "Public",
  "type": "FunctionDef",
  "annotation": [],
  "expression": {
    "type": "First",
    "annotation": [],
    "signature": [],
    "source": {
      "type": "Query",
      "annotation": [],
      "source": [{
        "alias": "C",
        "annotation": [],
        "expression": {
          "path": "coding",
          "type": "Property",
          "annotation": [],
          "source": {
            "name": "medication",
            "type": "OperandRef",
            "annotation": []
          }
        }
      }],
      "let": [],
      "relationship": [],
      "where": {
        "type": "Equal",
        "annotation": [],
        "signature": [{
          "name": "{urn:hl7-org:elm-types:r1}String",
          "type": "NamedTypeSpecifier",
          "annotation": []
        }, {
          "name": "{urn:hl7-org:elm-types:r1}String",
          "type": "NamedTypeSpecifier",
          "annotation": []
        }],
        "operand": [{
          "path": "value",
          "type": "Property",
          "annotation": [],
          "source": {
            "path": "system",
            "type": "Property",
            "annotation": [],
            "source": {
              "name": "C",
              "type": "AliasRef",
              "annotation": []
            }
          }
        }, {
          "valueType": "{urn:hl7-org:elm-types:r1}String",
          "value": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code",
          "type": "Literal",
          "annotation": []
        }]
      },
      "return": {
        "annotation": [],
        "expression": {
          "path": "value",
          "type": "Property",
          "annotation": [],
          "source": {
            "path": "code",
            "type": "Property",
            "annotation": [],
            "source": {
              "name": "C",
              "type": "AliasRef",
              "annotation": []
            }
          }
        }
      }
    }
  },
  "operand": [{
    "name": "medication",
    "annotation": [],
    "operandTypeSpecifier": {
      "name": "{http://hl7.org/fhir}CodeableConcept",
      "type": "NamedTypeSpecifier",
      "annotation": []
    }
  }]
}
```

**Step 3: 修改IsAntihypertensiveOralDrug函数（更复杂！）**
- 需要添加OR逻辑的嵌套结构
- 至少100+行JSON代码
- 每个括号、逗号位置都不能错

#### 问题：

1. ❌ **超级复杂**：手写嵌套的抽象语法树
2. ❌ **容易出错**：一个括号错误就无法运行
3. ❌ **无法验证**：没有编译器检查语法
4. ❌ **难以维护**：下次修改需要重新理解整个JSON结构
5. ❌ **版本控制困难**：无法追踪逻辑变更
6. ❌ **团队协作困难**：其他人无法理解你的修改

---

### ✅ 方式2：修改CQL源代码（推荐）

#### 你只需要做的事

**Step 1: 添加CodeSystem（1行）**
```cql
codesystem "NHI_MEDICATION": 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code'
```

**Step 2: 添加GetNHICode函数（5行）**
```cql
define function GetNHICode(medication FHIR.CodeableConcept):
  First(
    medication.coding C
      where C.system.value = 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/nhi-medication-code'
      return C.code.value
  )
```

**Step 3: 修改判断逻辑（3行）**
```cql
define function IsAntihypertensiveOralDrug(medication FHIR.CodeableConcept):
  let atcCode: GetATCCode(medication),
      nhiCode: GetNHICode(medication)
  in
    (IsAntihypertensiveByATC(atcCode) or IsAntihypertensiveByNHI(nhiCode))
    and not IsInjection(...)
```

**Step 4: 重新编译（1条命令）**
```bash
cql-to-elm --input Indicator_03_1.cql --output Indicator_03_1.json
```

#### 优势：

1. ✅ **简单易读**：人类可理解的语法
2. ✅ **自动验证**：编译器检查语法错误
3. ✅ **易于维护**：逻辑清晰可见
4. ✅ **版本控制友好**：Git diff可读
5. ✅ **团队协作容易**：标准CQL语法
6. ✅ **可测试**：可以单独测试CQL逻辑

---

## 实际操作对比

### 直接修改JSON需要的工作量

| 任务 | 复杂度 | 出错风险 | 时间估计 |
|------|--------|---------|---------|
| 理解ELM JSON结构 | ⭐⭐⭐⭐⭐ | 高 | 4-8小时 |
| 添加CodeSystem | ⭐⭐ | 中 | 10分钟 |
| 添加GetNHICode函数 | ⭐⭐⭐⭐⭐ | 极高 | 2-4小时 |
| 修改IsAntihypertensive | ⭐⭐⭐⭐⭐ | 极高 | 4-6小时 |
| 调试JSON语法错误 | ⭐⭐⭐⭐⭐ | 极高 | 2-4小时 |
| **总计** | **极难** | **极高** | **12-22小时** |

### 修改CQL + 重新编译

| 任务 | 复杂度 | 出错风险 | 时间估计 |
|------|--------|---------|---------|
| 修改CQL文件 | ⭐⭐ | 低 | 30分钟 |
| 安装CQL-to-ELM工具 | ⭐ | 低 | 10分钟 |
| 编译生成JSON | ⭐ | 无 | 1分钟 |
| 验证编译结果 | ⭐ | 低 | 5分钟 |
| **总计** | **简单** | **低** | **46分钟** |

---

## 特殊情况：何时可以考虑直接修改JSON？

### 唯一例外：紧急热修复（Hotfix）

**场景**：生产环境紧急问题，无法等待完整的CQL编译流程

**条件**：
1. ✅ 只是修改**简单的字面值**（如日期、字符串常量）
2. ✅ 有完整的JSON备份
3. ✅ 有经验的ELM JSON专家操作
4. ✅ 事后必须补充正式的CQL修改

**示例：可以直接修改的简单内容**
```json
// ✅ 可以改：简单的字面值
{
  "name": "Measurement Period Start",
  "expression": {
    "type": "Date",
    "year": { "value": "2024" },  // 改成 "2025"
    "month": { "value": "1" },
    "day": { "value": "1" }
  }
}

// ❌ 不要改：复杂的逻辑结构
{
  "name": "IsAntihypertensiveOralDrug",
  "expression": {
    "type": "If",
    "condition": { /* 100+ lines */ },
    "then": { /* 50+ lines */ }
  }
}
```

---

## 推荐的完整工作流程

### 标准开发流程

```
1. 修改CQL源文件
   ↓
2. 本地编译测试
   ↓
3. 单元测试验证
   ↓
4. Code Review
   ↓
5. 生成最终ELM JSON
   ↓
6. 部署到生产环境
```

### 需要的工具

1. **CQL编辑器**
   - VS Code + CQL语法高亮插件
   - 或任何文本编辑器

2. **CQL-to-ELM Translator**
   - Java版本：`cql-translation-service`
   - Node.js版本：`cql-exec-vsac`
   - Docker版本：`alphora/cql-translation-service`

3. **测试工具**
   - CQL Execution Engine
   - FHIR测试服务器

---

## 安装CQL-to-ELM Translator

### 方式1: Docker（最简单）

```powershell
# 拉取镜像
docker pull alphora/cql-translation-service:latest

# 运行服务
docker run -d -p 8080:8080 alphora/cql-translation-service

# 转换CQL文件
Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" `
  -Method Post `
  -ContentType "application/cql" `
  -InFile "Indicator_03_1.cql" `
  -OutFile "Indicator_03_1.json"
```

### 方式2: Java命令行

```powershell
# 下载translator JAR
wget https://github.com/cqframework/clinical_quality_language/releases/download/v3.10.0/cql-to-elm.jar

# 转换CQL
java -jar cql-to-elm.jar --input Indicator_03_1.cql --output Indicator_03_1.json
```

### 方式3: Node.js

```powershell
# 安装工具
npm install -g cql-translation

# 转换CQL
cql-to-elm --input Indicator_03_1.cql --output Indicator_03_1.json
```

---

## 总结

| 对比项 | 直接修改JSON | 修改CQL+编译 |
|--------|-------------|-------------|
| 复杂度 | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| 出错风险 | 极高 | 低 |
| 开发时间 | 12-22小时 | 46分钟 |
| 可维护性 | 极差 | 优秀 |
| 团队协作 | 困难 | 容易 |
| 版本控制 | 困难 | 容易 |
| 可测试性 | 差 | 好 |
| 推荐程度 | ❌ | ✅ |

---

## 结论

**直接修改JSON理论上可以，但除非紧急热修复简单字面值，否则：**

### ✅ 永远应该：
1. 修改CQL源文件
2. 使用CQL-to-ELM Translator编译
3. 验证生成的JSON
4. 部署到生产环境

### ❌ 永远不要：
1. 手动编辑复杂的ELM JSON逻辑
2. 绕过CQL编译流程
3. 在生产环境直接改JSON

---

**时间投资**：
- 学习CQL-to-ELM工具：1小时
- 以后每次修改：< 1小时
- 避免无数小时的JSON调试噩梦！
