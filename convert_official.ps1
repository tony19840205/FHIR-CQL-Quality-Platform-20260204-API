# ========================================
# 使用官方 cql-execution 转换所有CQL
# ========================================

Write-Host "`n=== 安装官方cql-execution工具 ===" -ForegroundColor Cyan

# 检查npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm版本: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ 未找到npm，请先安装Node.js" -ForegroundColor Red
    exit 1
}

# 全局安装cql-execution-cli
Write-Host "`n正在安装 cql-execution-cli..." -ForegroundColor Yellow
npm install -g cql-exec-vsac

Write-Host "`n=== 开始批量转换 ===" -ForegroundColor Cyan

$sourceDir = ".\CQL 2026"
$outputDir = ".\ELM_JSON_OFFICIAL"

# 创建输出目录
if (!(Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

$cqlFiles = Get-ChildItem -Path $sourceDir -Filter "*.cql" -Recurse
$total = $cqlFiles.Count

Write-Host "找到 $total 个CQL文件`n" -ForegroundColor Green

$success = 0
$failed = 0

for ($i = 0; $i -lt $total; $i++) {
    $file = $cqlFiles[$i]
    $num = $i + 1
    $percent = [math]::Round(($num/$total)*100, 1)
    
    $relPath = $file.FullName.Substring($sourceDir.Length + 2)
    $outPath = Join-Path $outputDir ($relPath -replace "\.cql$", ".json")
    $outDir = Split-Path $outPath -Parent
    
    Write-Host "[$num/$total] $percent% - $relPath" -ForegroundColor Yellow
    
    try {
        if (!(Test-Path $outDir)) {
            New-Item -Path $outDir -ItemType Directory -Force | Out-Null
        }
        
        # 使用cql-to-elm转换
        $result = cql-to-elm --input $file.FullName --output $outPath 2>&1
        
        if (Test-Path $outPath) {
            Write-Host "  ✅ 成功`n" -ForegroundColor Green
            $success++
        } else {
            throw "未生成输出文件"
        }
        
    } catch {
        Write-Host "  ❌ $($_.Exception.Message)`n" -ForegroundColor Red
        $failed++
    }
    
    if ($num % 10 -eq 0) {
        Write-Host "--- 进度: 成功 $success, 失败 $failed ---`n" -ForegroundColor Cyan
    }
}

Write-Host "`n转换完成!" -ForegroundColor Green
Write-Host "总计: $total | 成功: $success | 失败: $failed`n" -ForegroundColor White
