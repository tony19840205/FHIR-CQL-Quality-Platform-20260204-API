# 批量获取官方ELM的半自动化方案
# 结合VS Code手动操作和自动化整理

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      官方ELM获取方案 - VS Code View ELM辅助工具               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 当前情况分析：" -ForegroundColor Yellow
Write-Host "   ✅ FHIRHelpers已下载（26KB）" -ForegroundColor Green
Write-Host "   ✅ VS Code CQL插件已安装" -ForegroundColor Green
Write-Host "   ✅ 工作区已配置" -ForegroundColor Green
Write-Host "   ❌ 自动化工具全部失败（路径空格、jar不完整、网络不通）" -ForegroundColor Red
Write-Host ""

Write-Host "🎯 最佳方案：半自动化批量转换" -ForegroundColor Cyan
Write-Host ""

# 准备输出目录
$outputDir = "ELM_JSON_OFFICIAL"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

$categories = @("中醫", "牙科", "西醫", "門診透析品質指標")
foreach ($cat in $categories) {
    $catDir = Join-Path $outputDir $cat
    if (-not (Test-Path $catDir)) {
        New-Item -Path $catDir -ItemType Directory | Out-Null
    }
}

Write-Host "✅ 输出目录已创建: $outputDir" -ForegroundColor Green
Write-Host ""

# 生成CQL文件清单
Write-Host "📁 CQL文件清单：" -ForegroundColor Cyan
Write-Host ""

$totalFiles = 0
foreach ($cat in $categories) {
    $cqlPath = Join-Path "CQL 2026" $cat
    if (Test-Path $cqlPath) {
        $files = Get-ChildItem -Path $cqlPath -Filter "*.cql"
        $totalFiles += $files.Count
        
        Write-Host "  [$cat] - $($files.Count) 个文件" -ForegroundColor Yellow
        
        $files | ForEach-Object {
            Write-Host "    - $($_.Name)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

Write-Host "📊 总计：$totalFiles 个CQL文件" -ForegroundColor Green
Write-Host ""

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "手动操作步骤（每个文件）：" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 在VS Code中打开CQL文件" -ForegroundColor White
Write-Host "2. 按 Ctrl+Shift+P" -ForegroundColor White
Write-Host "3. 输入 'CQL: View ELM'" -ForegroundColor White  
Write-Host "4. 复制生成的ELM JSON" -ForegroundColor White
Write-Host "5. 保存到 ELM_JSON_OFFICIAL\<分类>\<文件名>.json" -ForegroundColor White
Write-Host ""

Write-Host "💡 建议分批处理：" -ForegroundColor Cyan
Write-Host "   第1批：中醫（8个文件）- 预计10分钟" -ForegroundColor Gray
Write-Host "   第2批：牙科（20个文件）- 预计20分钟" -ForegroundColor Gray
Write-Host "   第3批：西醫关键指标（选20个）- 预计20分钟" -ForegroundColor Gray
Write-Host "   第4批：其余文件（按需）" -ForegroundColor Gray
Write-Host ""

# 创建进度追踪文件
$progressFile = "conversion_progress.txt"
if (-not (Test-Path $progressFile)) {
    "# 官方ELM转换进度追踪" | Out-File -FilePath $progressFile -Encoding UTF8
    "" | Out-File -FilePath $progressFile -Append -Encoding UTF8
    "## 待转换" | Out-File -FilePath $progressFile -Append -Encoding UTF8
    
    foreach ($cat in $categories) {
        $cqlPath = Join-Path "CQL 2026" $cat
        if (Test-Path $cqlPath) {
            "" | Out-File -FilePath $progressFile -Append -Encoding UTF8
            "### $cat" | Out-File -FilePath $progressFile -Append -Encoding UTF8
            Get-ChildItem -Path $cqlPath -Filter "*.cql" | ForEach-Object {
                "[ ] $($_.BaseName)" | Out-File -FilePath $progressFile -Append -Encoding UTF8
            }
        }
    }
    
    Write-Host "✅ 进度追踪文件已创建：$progressFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "🚀 开始转换！" -ForegroundColor Green
Write-Host ""
Write-Host "提示：每转换完一个文件，在 $progressFile 中标记为 [x]" -ForegroundColor Yellow
Write-Host ""

# 打开第一个中醫文件
$firstFile = "CQL 2026\中醫\Indicator_TCM_Same_Day_Revisit_Rate.cql"
if (Test-Path $firstFile) {
    Write-Host "正在打开第一个文件..." -ForegroundColor Cyan
    code $firstFile
    Start-Sleep -Seconds 2
    
    Write-Host ""
    Write-Host "✨ 现在执行：" -ForegroundColor Green
    Write-Host "   1. 按 Ctrl+Shift+P" -ForegroundColor Yellow
    Write-Host "   2. 输入 'CQL: View ELM'" -ForegroundColor Yellow
    Write-Host "   3. 查看转换结果" -ForegroundColor Yellow
    Write-Host ""
}

# 打开输出目录
Invoke-Item $outputDir

Write-Host "📂 输出目录已打开" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 目标：获取132个官方ELM JSON文件" -ForegroundColor Cyan
Write-Host "   优先：中醫8个 → 牙科20个 → 重点西醫20个" -ForegroundColor Gray
