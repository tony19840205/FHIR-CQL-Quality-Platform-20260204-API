# ========================================
# CQL 批量转换为 ELM JSON
# ========================================
# 使用 CQL Translation Service API 批量转换CQL文件为ELM JSON格式
# 作者: System
# 日期: 2026-01-08
# ========================================

param(
    [string]$SourceFolder = ".\CQL 2026",
    [string]$OutputFolder = ".\ELM_JSON",
    [string]$TranslationServiceUrl = "https://cql.dataphoria.org/translate",
    [switch]$LocalService = $false,
    [string]$LocalServiceUrl = "http://localhost:8080/cql/translator"
)

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 创建输出文件夹
if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
    Write-ColorOutput "✅ 创建输出文件夹: $OutputFolder" "Green"
}

# 获取所有CQL文件
$cqlFiles = Get-ChildItem -Path $SourceFolder -Filter "*.cql" -Recurse
$totalFiles = $cqlFiles.Count
Write-ColorOutput "`n📊 找到 $totalFiles 个 CQL 文件" "Cyan"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Gray"

# 选择服务URL
$serviceUrl = if ($LocalService) { $LocalServiceUrl } else { $TranslationServiceUrl }
Write-ColorOutput "🌐 使用翻译服务: $serviceUrl`n" "Yellow"

# 统计变量
$successCount = 0
$failCount = 0
$failedFiles = @()

# 处理每个CQL文件
foreach ($i in 1..$totalFiles) {
    $file = $cqlFiles[$i - 1]
    $relativePath = $file.FullName.Replace($SourceFolder, "").TrimStart("\")
    $outputPath = Join-Path $OutputFolder ($relativePath -replace "\.cql$", ".json")
    $outputDir = Split-Path $outputPath -Parent
    
    # 创建子文件夹
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    Write-ColorOutput "[$i/$totalFiles] 处理: $relativePath" "Cyan"
    
    try {
        # 读取CQL文件内容
        $cqlContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # 准备请求体
        $body = @{
            cql = $cqlContent
        } | ConvertTo-Json -Depth 10
        
        # 调用翻译服务
        $headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/elm+json"
        }
        
        $response = Invoke-RestMethod -Uri $serviceUrl -Method Post -Body $body -Headers $headers -TimeoutSec 30
        
        # 保存ELM JSON
        $response | ConvertTo-Json -Depth 100 | Set-Content -Path $outputPath -Encoding UTF8
        
        Write-ColorOutput "  ✅ 成功转换 → $outputPath" "Green"
        $successCount++
        
    } catch {
        Write-ColorOutput "  ❌ 转换失败: $($_.Exception.Message)" "Red"
        $failCount++
        $failedFiles += $relativePath
    }
    
    # 添加短暂延迟避免过载服务器
    Start-Sleep -Milliseconds 100
}

Write-ColorOutput "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Gray"
Write-ColorOutput "📈 转换统计:" "Cyan"
Write-ColorOutput "  总计: $totalFiles 个文件" "White"
Write-ColorOutput "  成功: $successCount 个" "Green"
Write-ColorOutput "  失败: $failCount 个" "Red"

if ($failedFiles.Count -gt 0) {
    Write-ColorOutput "`n❌ 失败文件列表:" "Red"
    foreach ($failedFile in $failedFiles) {
        Write-ColorOutput "  - $failedFile" "Yellow"
    }
}

Write-ColorOutput "`n✨ 批量转换完成！" "Green"
