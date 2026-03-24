# 获取官方ELM的完整方案

## ✅ 已完成步骤

1. **下载FHIRHelpers库** ✅
   - 位置：`CQL 2026/FHIRHelpers/FHIRHelpers-4.0.1.cql`
   - 大小：26,594 bytes
   - 来源：官方GitHub仓库

2. **配置VS Code工作区** ✅
   - 创建了 `.vscode/settings.json`
   - 设置了CQL库路径

3. **安装Node.js依赖** ✅
   - cql-execution 2.4.6
   - cql-exec-fhir 2.1.0
   - antlr4 4.13.1

---

## 🎯 方案A: 使用VS Code CQL插件（推荐尝试）

### 前置条件
- ✅ FHIRHelpers已下载
- ✅ VS Code CQL插件已安装
- ✅ 工作区已配置

### 操作步骤
1. **打开CQL文件**
   ```
   已打开：CQL 2026\中醫\Indicator_TCM_Same_Day_Revisit_Rate.cql
   ```

2. **执行转换命令**
   - 按 `Ctrl + Shift + P`
   - 输入 `CQL: View ELM`
   - 执行命令

3. **预期结果**
   - 现在有了FHIRHelpers，转换应该能成功
   - 会生成官方完整版ELM JSON

### 如果仍然失败
检查VS Code输出面板查看详细错误信息

---

## 🎯 方案B: 使用在线编译服务（如果网络恢复）

### CQL Translation Service API

```javascript
const axios = require('axios');
const fs = require('fs');

async function translateCQL(cqlContent) {
  const response = await axios.post('https://cql-translation.dataphoria.org/cql/translator', {
    cql: cqlContent,
    annotations: true,
    locators: true,
    resultTypes: true
  });
  
  return response.data;
}
```

### 使用方法
```bash
node translate_online.js "CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql"
```

---

## 🎯 方案C: 使用Java CLI工具（需要正确的jar文件）

### 下载正确的jar文件

需要的是 `cql-to-elm-cli-{version}-jar-with-dependencies.jar`

**可能的下载位置：**
1. GitHub Releases Assets（需要登录）
2. Maven Central（需要找到正确URL）
3. FHIR IG Publisher（包含cql-to-elm）

### 使用FHIR IG Publisher的方法

```powershell
# 下载FHIR IG Publisher（包含CQL编译器）
Invoke-WebRequest -Uri "https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar" -OutFile "publisher.jar"

# 使用方法（需要研究参数）
java -jar publisher.jar -cql-to-elm "CQL 2026/中醫/*.cql"
```

---

## 🎯 方案D: 手动逐个使用VS Code插件（最可靠）

### 优点
- 使用官方工具
- 生成标准ELM
- 每个文件都经过验证

### 缺点
- 需要手动操作132个文件
- 耗时约1-2小时

### 执行计划（渐进式）

**第1阶段：中醫（8个文件）**
- 预计时间：5-10分钟
- 打开每个CQL → View ELM → 保存JSON

**第2阶段：牙科（20个文件）**
- 预计时间：15-20分钟

**第3阶段：西醫（80个文件）**
- 预计时间：60-80分钟
- 可分批处理

**第4阶段：門診透析（24个文件）**
- 预计时间：20-30分钟

---

## 🎯 方案E: 创建自动化脚本（如果VS Code命令行可用）

### 检查VS Code CLI命令

```powershell
# 测试VS Code扩展命令
code --list-extensions
code --install-extension cqframework.cql

# 尝试执行扩展命令（需要研究）
code --extensionDevelopmentPath="$env:USERPROFILE\.vscode\extensions\cqframework.cql-0.7.8" `
     --wait `
     "CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql"
```

---

## 📋 立即行动建议

### 步骤1: 测试VS Code插件（5分钟）

现在就试试：
1. 确认文件已打开：`Indicator_TCM_Same_Day_Revisit_Rate.cql`
2. 按 `Ctrl + Shift + P`
3. 执行 `CQL: View ELM`
4. 查看是否成功

### 步骤2: 如果成功，批量转换中醫（10分钟）

- 逐个打开8个中醫CQL文件
- 执行View ELM
- 保存到 `ELM_JSON_OFFICIAL/中醫/`

### 步骤3: 评估并选择最终方案

根据步骤1和2的结果决定：
- 如果插件可用 → 继续手动转换
- 如果插件不可用 → 研究其他方案

---

## 🔍 当前状态

| 项目 | 状态 |
|------|------|
| FHIRHelpers | ✅ 已下载 |
| VS Code配置 | ✅ 已完成 |
| Node.js依赖 | ✅ 已安装 |
| VS Code插件测试 | ⏳ 待执行 |
| 官方ELM获取 | ⏳ 进行中 |

---

**下一步：** 立即测试VS Code插件的View ELM命令！
