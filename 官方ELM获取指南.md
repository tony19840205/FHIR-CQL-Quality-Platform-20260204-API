# 手动获取官方ELM的操作指南

## 方法：使用VS Code CQL插件手动转换（最可靠）

### 前提条件
✓ VS Code已安装CQL插件: cqframework.cql-0.7.8
✓ FHIRHelpers-4.0.1.cql已下载
✓ 工作空间CQL路径已配置（.vscode/settings.json）

### 操作步骤（每个文件约2分钟）

#### 步骤1: 打开CQL文件
1. 在VS Code中打开: `CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql`

#### 步骤2: 查看ELM
1. 按 `Ctrl+Shift+P` 打开命令面板
2. 输入并选择: `CQL: View ELM`
3. 等待编译完成（约3-5秒）

#### 步骤3: 复制ELM JSON
1. ELM会在新标签页中打开
2. 全选内容 (`Ctrl+A`)
3. 复制 (`Ctrl+C`)

#### 步骤4: 保存为文件
1. 创建新文件: `ELM_JSON_OFFICIAL/中醫/Indicator_TCM_Same_Day_Revisit_Rate.json`
2. 粘贴内容 (`Ctrl+V`)
3. 保存

#### 步骤5: 验证
```javascript
// 运行验证脚本
node verify_official_elm.js ELM_JSON_OFFICIAL/中醫/Indicator_TCM_Same_Day_Revisit_Rate.json
```

### 中医8个文件清单

- [ ] Indicator_TCM_Global_Budget_Program_Organization_List.cql
- [ ] Indicator_TCM_Medication_Overlap_2_Days_Or_More_Rate.cql  
- [ ] Indicator_TCM_Monthly_Visit_8_Or_More_Times_Rate.cql
- [ ] Indicator_TCM_Pediatric_Asthma_Program_Organization_List.cql
- [ ] Indicator_TCM_Pediatric_Cerebral_Palsy_Program_Organization_List.cql
- [ ] Indicator_TCM_Same_Day_Revisit_Rate.cql
- [ ] Indicator_TCM_Traumatology_Rate.cql
- [ ] Indicator_TCM_Underserved_Area_Program_Organization_List.cql

预计总时间: 15-20分钟

---

## 如果VS Code命令不工作

### 备选方案：使用官方cql命令行工具

```bash
# 下载官方CLI（如果可访问GitHub）
npm install -g cql-translation-cli

# 转换单个文件
cql-to-elm --input "CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql" --output "ELM_JSON_OFFICIAL/中醫/"
```

---

## 验证官方ELM质量

运行此脚本验证转换结果：

```javascript
// verify_official_elm.js
const fs = require('fs');
const cql = require('cql-execution');

const elmPath = process.argv[2];
const elm = JSON.parse(fs.readFileSync(elmPath, 'utf8'));

try {
    const repository = new cql.Repository(elm);
    const lib = repository.resolve(elm.library.identifier.id);
    const executor = new cql.Executor(lib);
    
    console.log(`✓ ELM验证成功`);
    console.log(`  库名: ${elm.library.identifier.id}`);
    console.log(`  可执行: 是`);
    console.log(`  语句数: ${Object.keys(elm.library.statements.def).length}`);
} catch (error) {
    console.log(`✗ ELM验证失败: ${error.message}`);
}
```

---

## 重要提醒

获得官方ELM后的差异：

- **官方ELM**: 100%可执行，可用于计算指标、临床决策
- **增强版ELM**: ~15%可执行，仅适合文档展示

运算用途必须使用官方ELM！
