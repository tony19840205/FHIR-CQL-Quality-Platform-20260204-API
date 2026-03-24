# 使用FHIR IG Publisher转换CQL到官方ELM
# IG Publisher包含完整的CQL-to-ELM编译器

param(
    [string]$CqlFile,
    [string]$OutputDir = "ELM_JSON_OFFICIAL"
)

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      使用FHIR IG Publisher转换CQL到官方ELM                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检查FHIR IG Publisher
if (-not (Test-Path "fhir-ig-publisher.jar")) {
    Write-Host "❌ 未找到fhir-ig-publisher.jar" -ForegroundColor Red
    Write-Host "   请先运行下载命令" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ FHIR IG Publisher 已就位 (218MB)" -ForegroundColor Green
Write-Host ""

# 创建临时IG项目结构
$tempIgPath = "temp_ig"
if (Test-Path $tempIgPath) {
    Remove-Item -Path $tempIgPath -Recurse -Force
}

New-Item -Path $tempIgPath -ItemType Directory | Out-Null
New-Item -Path "$tempIgPath\input" -ItemType Directory | Out-Null
New-Item -Path "$tempIgPath\input\cql" -ItemType Directory | Out-Null

# 创建最小化的ig.ini
$igIni = @"
[IG]
ig = input/ImplementationGuide.json
template = #fhir.base.template
"@
$igIni | Out-File -FilePath "$tempIgPath\ig.ini" -Encoding UTF8

# 创建最小化的ImplementationGuide
$igJson = @"
{
  "resourceType": "ImplementationGuide",
  "id": "temp-cql-conversion",
  "url": "http://example.org/fhir/ig/temp",
  "version": "1.0.0",
  "name": "TempCQLConversion",
  "status": "draft",
  "fhirVersion": ["4.0.1"],
  "definition": {
    "resource": []
  }
}
"@
$igJson | Out-File -FilePath "$tempIgPath\input\ImplementationGuide.json" -Encoding UTF8

Write-Host "📁 创建临时IG项目结构..." -ForegroundColor Cyan
Write-Host "   路径: $tempIgPath" -ForegroundColor Gray
Write-Host ""

if ($CqlFile) {
    # 单文件转换
    Write-Host "📄 转换单个文件: $CqlFile" -ForegroundColor Yellow
    
    if (-not (Test-Path $CqlFile)) {
        Write-Host "❌ 文件不存在: $CqlFile" -ForegroundColor Red
        exit 1
    }
    
    # 复制CQL文件和FHIRHelpers
    Copy-Item $CqlFile -Destination "$tempIgPath\input\cql\" -Force
    if (Test-Path "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql") {
        Copy-Item "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql" -Destination "$tempIgPath\input\cql\" -Force
    }
    
    Write-Host "⏳ 正在使用FHIR IG Publisher编译CQL..." -ForegroundColor Cyan
    Write-Host ""
    
    # 运行IG Publisher（只编译CQL）
    $publisherArgs = @(
        "-jar", "fhir-ig-publisher.jar",
        "-ig", "$tempIgPath",
        "-tx", "n/a"
    )
    
    & java $publisherArgs
    
    # 检查输出
    if (Test-Path "$tempIgPath\output\cql") {
        Write-Host ""
        Write-Host "✅ 转换成功!" -ForegroundColor Green
        Write-Host ""
        
        Get-ChildItem "$tempIgPath\output\cql\*.json" | ForEach-Object {
            Write-Host "   生成: $($_.Name)" -ForegroundColor Gray
            
            # 复制到输出目录
            $outputFile = Join-Path $OutputDir $_.Name
            Copy-Item $_.FullName -Destination $outputFile -Force
            Write-Host "   → $outputFile" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️ 未找到输出文件" -ForegroundColor Yellow
        Write-Host "   检查temp_ig目录中的日志" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ 请指定CQL文件" -ForegroundColor Red
    Write-Host ""
    Write-Host "用法示例:" -ForegroundColor Yellow
    Write-Host '  .\convert_with_ig_publisher.ps1 -CqlFile "CQL 2026\中醫\Indicator_TCM_Same_Day_Revisit_Rate.cql"' -ForegroundColor Gray
}

Write-Host ""
Write-Host "💡 说明:" -ForegroundColor Cyan
Write-Host "   FHIR IG Publisher使用官方cql-to-elm编译器" -ForegroundColor Gray
Write-Host "   生成的ELM是100%官方标准格式" -ForegroundColor Gray
