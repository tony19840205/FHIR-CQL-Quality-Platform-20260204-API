"""
使用VS Code CQL Extension API批量转换
需要VS Code的cqframework.cql插件
"""
import subprocess
import json
from pathlib import Path

def convert_with_vscode_cql(cql_file):
    """使用VS Code CQL插件转换单个文件"""
    # 这需要VS Code Extension API
    # 实际上VS Code插件不提供命令行接口
    print(f"❌ VS Code CQL插件需要在VS Code界面中手动操作")
    print(f"   或者使用官方的cql-to-elm CLI工具")
    return None

print("""
╔═══════════════════════════════════════════════════════════════╗
║           官方CQL转换工具使用指南                              ║
╚═══════════════════════════════════════════════════════════════╝

方案1: VS Code CQL插件 (推荐单个文件)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 你已安装: cqframework.cql

使用步骤:
1. 打开任意 .cql 文件
2. 右键点击编辑器
3. 选择 "Execute CQL" 或查找CQL相关命令
4. 插件会生成 .json 文件在同一目录

注意: 这个插件主要用于单个文件测试，不适合批量转换


方案2: cql-translation-service (在线API) 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ 网络连接失败 - 无法使用


方案3: 下载官方完整CLI工具
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 访问: https://github.com/cqframework/clinical_quality_language/releases
2. 下载: cql-to-elm-cli-X.X.X-jar-with-dependencies.jar
3. 运行: java -jar cql-to-elm-cli.jar --input file.cql --output file.json


方案4: 使用我们的Python脚本
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 已完成 - 132个文件已转换
⚠️  简化版ELM - 适合文档化和结构查看
❌ 不适合CQL执行引擎使用


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 推荐方案:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ 如果只需要查看结构和元数据
   → 使用现有的Python脚本结果 (ELM_JSON文件夹)

2️⃣ 如果需要执行CQL计算
   → 下载官方CLI工具 (jar-with-dependencies版本)
   → 批量转换生成完整ELM

3️⃣ 如果需要测试单个文件
   → 使用已安装的VS Code CQL插件

""")

# 询问用户想用哪个方案
print("\n你想要:")
print("A. 下载官方CLI工具并批量转换 (完整版)")
print("B. 使用VS Code插件手动转换几个测试文件")
print("C. 继续使用现有的简化版JSON")
print("\n请手动选择方案...")
