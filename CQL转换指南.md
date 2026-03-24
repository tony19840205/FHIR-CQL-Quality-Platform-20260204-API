# CQL 批量转换为 ELM JSON 使用指南

## 📋 概述

将282个CQL文件批量转换为ELM (Expression Logical Model) JSON格式，有以下三种方案：

## 🎯 方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **方案1: 在线API** | 无需安装，即用即走 | 依赖网络，可能较慢 | ⭐⭐⭐⭐ |
| **方案2: 本地Java工具** | 快速稳定，离线可用 | 需要Java环境 | ⭐⭐⭐⭐⭐ |
| **方案3: Node.js工具** | 跨平台，易于集成 | 需要Node.js环境 | ⭐⭐⭐ |

---

## 🚀 方案1: 使用在线翻译服务 (最简单)

### 运行方式
```powershell
# 基本用法 (使用公共API)
.\convert_cql_to_elm.ps1

# 指定输入输出文件夹
.\convert_cql_to_elm.ps1 -SourceFolder ".\CQL 2026" -OutputFolder ".\ELM_JSON"

# 使用本地翻译服务
.\convert_cql_to_elm.ps1 -LocalService -LocalServiceUrl "http://localhost:8080/cql/translator"
```

### 优点
- ✅ 无需安装任何软件
- ✅ 自动处理依赖关系
- ✅ 立即可用

### 缺点
- ⚠️ 依赖网络连接
- ⚠️ 282个文件需要较长时间
- ⚠️ 可能受API限流影响

---

## 🔧 方案2: 使用本地Java转换工具 (推荐)

### 前置要求
1. **安装Java 11或更高版本**
   ```powershell
   # 检查Java版本
   java -version
   
   # 如果未安装，下载地址:
   # https://adoptium.net/
   ```

### 运行方式
```powershell
# 自动下载转换器并执行
.\convert_cql_to_elm_local.ps1 -DownloadTranslator

# 手动指定转换器路径
.\convert_cql_to_elm_local.ps1 -TranslatorJar ".\cql-to-elm-cli.jar"

# 完整参数示例
.\convert_cql_to_elm_local.ps1 `
    -SourceFolder ".\CQL 2026" `
    -OutputFolder ".\ELM_JSON" `
    -TranslatorJar ".\cql-to-elm-cli-3.8.0.jar" `
    -DownloadTranslator
```

### 手动下载转换器
如果自动下载失败，可以手动下载：
1. 访问: https://github.com/cqframework/clinical_quality_language/releases
2. 下载最新版本的 `cql-to-elm-cli-X.X.X.jar`
3. 放置到项目根目录

### 优点
- ✅ 速度最快
- ✅ 离线可用
- ✅ 官方工具，最稳定
- ✅ 支持所有CQL特性

---

## 📦 方案3: 使用cql-execution (Node.js)

### 前置要求
```powershell
# 安装Node.js (如果未安装)
# 下载地址: https://nodejs.org/

# 安装cql-translation包
npm install -g cql-translation
```

### 创建批量转换脚本 (batch_convert.js)
```javascript
const fs = require('fs');
const path = require('path');
const { translate } = require('cql-translation');

const sourceDir = './CQL 2026';
const outputDir = './ELM_JSON';

// 递归获取所有CQL文件
function getAllCqlFiles(dir) {
    const files = [];
    const items = fs.readdirSync(dir);
    
    for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        
        if (stat.isDirectory()) {
            files.push(...getAllCqlFiles(fullPath));
        } else if (item.endsWith('.cql')) {
            files.push(fullPath);
        }
    }
    
    return files;
}

// 批量转换
async function batchConvert() {
    const cqlFiles = getAllCqlFiles(sourceDir);
    console.log(`找到 ${cqlFiles.length} 个CQL文件`);
    
    let success = 0, failed = 0;
    
    for (const cqlFile of cqlFiles) {
        try {
            const cqlContent = fs.readFileSync(cqlFile, 'utf8');
            const elm = await translate(cqlContent);
            
            const relativePath = path.relative(sourceDir, cqlFile);
            const outputPath = path.join(outputDir, relativePath.replace('.cql', '.json'));
            
            // 创建输出目录
            fs.mkdirSync(path.dirname(outputPath), { recursive: true });
            
            // 保存ELM JSON
            fs.writeFileSync(outputPath, JSON.stringify(elm, null, 2));
            
            console.log(`✅ ${relativePath}`);
            success++;
        } catch (error) {
            console.error(`❌ ${cqlFile}: ${error.message}`);
            failed++;
        }
    }
    
    console.log(`\n完成: 成功 ${success}, 失败 ${failed}`);
}

batchConvert();
```

### 运行
```powershell
node batch_convert.js
```

---

## 📁 输出结果

转换后的文件结构：
```
ELM_JSON/
├── 西医/
│   ├── Indicator_AMI_Post_Discharge_ACEI_ARB_6Months_Rate.json
│   ├── Indicator_AMI_Post_Discharge_ADP_Antagonist_3Months_Rate.json
│   └── ...
├── 中医/
│   ├── Indicator_TCM_Global_Budget_Program_Organization_List.json
│   └── ...
├── 牙科/
│   ├── Indicator_Dental_Filling_Retention_Rate_Within_2Years.json
│   └── ...
└── 门诊透析品质指标/
    └── ...
```

## 🔍 验证转换结果

### 检查JSON格式
```powershell
# 验证JSON格式正确性
Get-ChildItem -Path ".\ELM_JSON" -Filter "*.json" -Recurse | ForEach-Object {
    try {
        $null = Get-Content $_.FullName | ConvertFrom-Json
        Write-Host "✅ $($_.Name)" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($_.Name): 格式错误" -ForegroundColor Red
    }
}
```

### 查看ELM结构
```powershell
# 查看单个ELM文件内容
Get-Content ".\ELM_JSON\西医\Indicator_AMI_LDL_Testing_Rate.json" | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

## 🎯 ELM JSON 结构示例

转换后的ELM JSON包含：
```json
{
  "library": {
    "identifier": {
      "id": "Indicator_AMI_LDL_Testing_Rate",
      "version": "1.0.0"
    },
    "schemaIdentifier": {
      "id": "urn:hl7-org:elm",
      "version": "r1"
    },
    "usings": [...],
    "includes": [...],
    "parameters": [...],
    "statements": [...]
  }
}
```

## 🚨 常见问题

### Q1: 转换失败怎么办？
检查CQL文件语法是否正确：
- 确保library声明完整
- 检查using FHIR版本
- 验证include语句

### Q2: 如何处理依赖关系？
确保被include的CQL文件也被转换，并且放在正确的路径下。

### Q3: 转换速度慢？
使用本地Java工具（方案2），速度最快。

### Q4: 批量转换中断？
脚本会记录失败文件，可以单独处理失败的文件。

## 📊 预估转换时间

| 方案 | 282个文件预估时间 |
|------|------------------|
| 在线API | 10-30分钟 |
| 本地Java工具 | 2-5分钟 |
| Node.js | 5-10分钟 |

## 💡 推荐流程

1. **首选**: 使用方案2（本地Java工具）- 最快最稳定
2. **备选**: 使用方案1（在线API）- 如果无法安装Java
3. **开发**: 使用方案3（Node.js）- 如果需要集成到工作流

---

## 🎉 开始转换

选择一个方案，执行对应的命令即可！

```powershell
# 推荐命令 (本地Java工具)
.\convert_cql_to_elm_local.ps1 -DownloadTranslator
```

转换完成后，ELM JSON文件可以直接用于：
- FHIR CQL引擎执行
- 医疗品质指标计算
- 临床决策支持系统
