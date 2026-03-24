# CQL转ELM - 逐个文件转换并实时报告进度
$ErrorActionPreference = "Continue"

$sourceFolder = ".\CQL 2026"
$outputFolder = ".\ELM_JSON"
$apiUrl = "https://cql.dataphoria.org/translate"

# 创建输出文件夹
if (-not (Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
}

# 获取所有CQL文件
Write-Host "`n=== 正在扫描CQL文件... ===" -ForegroundColor Cyan
$cqlFiles = Get-ChildItem -Path $sourceFolder -Filter "*.cql" -Recurse
$total = $cqlFiles.Count
Write-Host "找到 $total 个CQL文件`n" -ForegroundColor Green

$success = 0
$failed = 0
$failedList = @()

# 逐个转换
for ($i = 0; $i -lt $total; $i++) {
    $file = $cqlFiles[$i]
    $num = $i + 1
    $percent = [math]::Round(($num / $total) * 100, 1)
    
    # 计算相对路径
    $relativePath = $file.FullName.Substring($sourceFolder.Length + 2)
    $outputPath = Join-Path $outputFolder ($relativePath -replace "\.cql$", ".json")
    $outputDir = Split-Path $outputPath -Parent
    
    Write-Host "[$num/$total] ($percent%) " -NoNewline -ForegroundColor Yellow
    Write-Host "$relativePath" -ForegroundColor White
    
    try {
        # 创建输出目录
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # 读取CQL内容
        $cqlContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # 准备请求
        $body = @{ cql = $cqlContent } | ConvertTo-Json -Depth 10
        $headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/elm+json"
        }
        
        # 调用API转换
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -Headers $headers -TimeoutSec 60
        
        # 保存结果
        $response | ConvertTo-Json -Depth 100 | Set-Content -Path $outputPath -Encoding UTF8
        
        Write-Host "  ✅ 成功 -> " -NoNewline -ForegroundColor Green
        Write-Host "$outputPath`n" -ForegroundColor Gray
        $success++
        
    } catch {
        Write-Host "  ❌ 失败: " -NoNewline -ForegroundColor Red
        Write-Host "$($_.Exception.Message)`n" -ForegroundColor Yellow
        $failed++
        $failedList += $relativePath
    }
    
    # 每10个文件显示一次汇总
    if ($num % 10 -eq 0) {
        Write-Host "--- 已完成 $num/$total, 成功: $success, 失败: $failed ---`n" -ForegroundColor Cyan
    }
}

# 最终统计
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "转换完成!" -ForegroundColor Green
Write-Host "总计: $total 个文件" -ForegroundColor White
Write-Host "成功: $success 个" -ForegroundColor Green
Write-Host "失败: $failed 个" -ForegroundColor Red

if ($failedList.Count -gt 0) {
    Write-Host "`n失败文件列表:" -ForegroundColor Red
    foreach ($f in $failedList) {
        Write-Host "  - $f" -ForegroundColor Yellow
    }
}

Write-Host "`n输出目录: $outputFolder" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
