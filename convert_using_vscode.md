# 使用VS Code CQL插件进行官方转换

## 现状
- ✅ VS Code CQL插件已安装 (cqframework.cql-0.7.8)  
- ✅ 包含Language Server (cql-ls-service-3.8.0.jar, 190MB)
- ❌ 插件设计为IDE使用，不支持批量命令行转换
- ❌ 官方CLI工具未找到可用的jar-with-dependencies版本

## 官方转换方案

### 方案1: 使用VS Code插件手动转换（推荐测试）

**步骤：**
1. 在VS Code中打开任意 `.cql` 文件
2. 右键点击编辑器区域
3. 查找CQL相关命令（可能名称：
   - "Execute CQL"
   - "CQL: Translate to ELM"
   - "CQL: Convert to JSON"
4. 插件会在同目录生成 `.json` 文件

**优点：**
- ✅ 官方工具，生成完整ELM
- ✅ 包含完整表达式树
- ✅ 适合测试和验证

**缺点：**
- ❌ 只能单文件操作
- ❌ 需要手动处理132个文件
- ❌ 耗时较长

---

### 方案2: 下载独立CLI工具（需网络）

**Maven Central下载链接：**
```
待确认的版本（4.0.0+已改为Kotlin多平台）：
- https://repo1.maven.org/maven2/org/cqframework/cql-to-elm-cli/
```

**GitHub Releases:**
- https://github.com/cqframework/clinical_quality_language/releases

**说明：**
- 3.x版本可能有jar-with-dependencies
- 4.x版本架构重构，CLI工具可能改变
- 需要逐个版本测试下载

---

### 方案3: 使用在线转换服务

**CQL Translation Service:**
- https://cql-translation-service.org/
- ⚠️ 目前网络不可达

**Dataphoria CQL Translator:**
- http://cql.dataphoria.org/translator
- ⚠️ 目前网络不可达

---

### 方案4: 继续使用Python简化版（当前已完成）

**现有成果：**
- ✅ 132个文件已转换
- ✅ 生成简化版ELM JSON
- ✅ 包含元数据、参数、定义名称
- ⚠️ 缺少完整表达式树

**适用场景：**
- 文档化和结构查看
- 快速浏览CQL内容
- 不需要执行CQL计算

**不适用：**
- CQL执行引擎
- 需要完整AST的工具
- 生产环境部署

---

## 推荐决策

### 如果你需要：

**1. 快速查看CQL结构** → 使用现有Python简化版
- 路径：`ELM_JSON` 文件夹
- 132个文件已完成

**2. 验证几个关键文件** → 使用VS Code插件手动转换
- 选择5-10个重要指标
- 手动转换并对比简化版差异
- 验证表达式树完整性

**3. 完整批量转换** → 需要额外努力
- 选项A：逐个手动转换（耗时但可靠）
- 选项B：等待网络恢复后使用在线服务
- 选项C：下载老版本CLI工具（3.8.0或更早）

---

## 下一步建议

### 立即可行：
1. ✅ 打开 `Indicator_CKD_Hemoglobin_Testing_Rate.cql`（已打开）
2. ✅ 右键 → 查找CQL转换命令
3. ✅ 生成官方ELM JSON
4. ✅ 对比 `ELM_JSON/Indicator_CKD_Hemoglobin_Testing_Rate.json`
5. ✅ 评估差异和需求

### 长期方案：
- 如果简化版满足需求 → 使用现有结果
- 如果需要完整版 → 手动转换关键文件
- 如果必须批量 → 研究4.x版本新CLI工具

---

## 技术说明

### ELM JSON差异对比

**简化版（Python生成）：**
```json
{
  "library": {
    "identifier": { "id": "Indicator_Name", "version": "1.0.0" }
  },
  "statements": {
    "def": [
      {
        "name": "Patient",
        "context": "Patient",
        "expression": "[placeholder - 简化版未实现]"
      }
    ]
  }
}
```

**完整版（官方工具）：**
```json
{
  "library": {
    "identifier": { "id": "Indicator_Name", "version": "1.0.0" }
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
            "templateId": "http://hl7.org/fhir/StructureDefinition/Patient",
            "type": "Retrieve"
          }
        }
      }
    ]
  }
}
```

**关键差异：**
- ✅ 完整版包含 `expression` 完整AST树
- ✅ 包含类型信息（type, dataType, templateId）  
- ✅ 包含操作符结构（Retrieve, Filter, Query等）
- ⚠️ 简化版只有定义名称和占位符

---

## 命令快速参考

### 检查VS Code CQL命令
```powershell
# 在VS Code中：
Ctrl + Shift + P  → 输入 "CQL"
```

### 手动转换单个文件
```
1. 打开 .cql 文件
2. 右键编辑器
3. 选择 CQL 转换命令
4. 查看生成的 .json 文件
```

### 对比简化版和完整版
```powershell
# 简化版
cat "ELM_JSON\Indicator_Name.json"

# 完整版（手动转换后）
cat "Indicator_Name.json"
```

---

**最后更新：** 2026-01-08  
**工具版本：** cqframework.cql-0.7.8, cql-ls-service-3.8.0
