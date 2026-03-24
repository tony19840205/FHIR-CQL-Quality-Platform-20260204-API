# 手动转换中醫CQL文件为官方ELM JSON

## 现状分析

### ❌ 当前简化版的问题
所有8个中醫JSON文件都是**简化版**，缺少完整表达式树：

```json
{
  "name": "TCM Outpatient Case Type",
  "expression": {
    "type": "Expression",  // ⚠️ 这是占位符，不是真实表达式
    "locator": "1064,1164"
  }
}
```

### ✅ 官方完整版应该是：
```json
{
  "name": "TCM Outpatient Case Type",
  "expression": {
    "type": "Code",  // ✅ 真实的表达式类型
    "code": {
      "value": "05",
      "system": "https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type"
    },
    "display": {
      "value": "中醫門診"
    }
  }
}
```

---

## 手动转换步骤

### 方法1: 使用VS Code CQL插件

已为你打开文件：`Indicator_TCM_Same_Day_Revisit_Rate.cql`

**操作步骤：**

1. ✅ **文件已打开** - Indicator_TCM_Same_Day_Revisit_Rate.cql

2. ⏳ **执行CQL命令：**
   - 按 `Ctrl + Shift + P` 打开命令面板
   - 输入 "CQL"
   - 查找并选择以下命令之一：
     * "CQL: Execute CQL"
     * "CQL: Translate to ELM"  
     * "CQL: Convert to JSON"

3. ✅ **检查生成结果：**
   - 插件会在CQL文件同目录生成JSON文件
   - 或者在输出面板显示转换结果
   - 文件名可能是：`Indicator_TCM_Same_Day_Revisit_Rate.json`

4. 📊 **对比差异：**
   ```powershell
   # 简化版
   cat "ELM_JSON\中醫\Indicator_TCM_Same_Day_Revisit_Rate.json"
   
   # 官方完整版（转换后）
   cat "CQL 2026\中醫\Indicator_TCM_Same_Day_Revisit_Rate.json"
   ```

---

## 如果VS Code命令不可用

### 备选方案：创建测试批量转换脚本

**问题：** VS Code CQL插件可能不提供命令行接口

**解决方案：** 手动操作，或者研究插件源码：

```powershell
# 查看插件源码
code "$env:USERPROFILE\.vscode\extensions\cqframework.cql-0.7.8"

# 查看package.json中的命令定义
cat "$env:USERPROFILE\.vscode\extensions\cqframework.cql-0.7.8\package.json" | Select-String "command"
```

---

## 批量转换策略（如果手动转换可行）

### 对于8个中醫文件：

1. **测试阶段：** 手动转换1-2个文件验证
2. **批量阶段：** 逐个打开并转换剩余文件
3. **预计时间：** 8个文件 × 30秒 = 4分钟

### 对于132个全部文件：

1. **优先级分类：**
   - 高优先级：常用指标（约20个）→ 手动转换
   - 中优先级：偶尔使用（约50个）→ 根据需求转换
   - 低优先级：备用指标（约62个）→ 使用简化版

2. **渐进式转换：**
   - 第1天：转换中醫（8个）
   - 第2天：转换牙科（18-20个）
   - 第3天：转换重要西醫指标（20个）
   - 后续：按需转换

---

## 下一步行动

### 立即执行：
1. ✅ 文件已打开：Indicator_TCM_Same_Day_Revisit_Rate.cql
2. ⏳ 按 Ctrl+Shift+P
3. ⏳ 输入 "CQL" 并执行转换命令
4. ⏳ 查看生成的JSON文件
5. ⏳ 对比简化版 vs 官方版差异

### 如果转换成功：
- 重复步骤转换其余7个中醫文件
- 生成完整的官方版中醫JSON集合
- 评估是否继续转换其他分类

### 如果找不到转换命令：
- 查看VS Code输出面板寻找提示
- 检查插件文档：README.md
- 考虑使用在线转换服务（需网络）

---

**当前状态：** ⏳ 等待手动执行VS Code CQL转换命令
**目标文件：** Indicator_TCM_Same_Day_Revisit_Rate.cql  
**预期输出：** 官方完整版ELM JSON
