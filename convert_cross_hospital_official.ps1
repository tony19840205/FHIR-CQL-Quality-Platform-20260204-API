# FHIR IG Publisher - 转换跨医院指标13和14 (官方ELM)
# 使用与中医指标相同的方法

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " 转换跨医院指标 - 使用FHIR IG Publisher " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$newBasePath = "C:\CQL_Cross_Hospital"
$currentPath = Get-Location

Write-Host "1. 清理和创建工作目录..." -ForegroundColor Cyan
if (Test-Path $newBasePath) {
    Remove-Item -Path $newBasePath -Recurse -Force
}
New-Item -Path $newBasePath -ItemType Directory | Out-Null
New-Item -Path "$newBasePath\input\cql" -ItemType Directory -Force | Out-Null
Write-Host "   ✓ 目录创建完成" -ForegroundColor Green
Write-Host ""

Write-Host "2. 复制必要文件..." -ForegroundColor Cyan

# 复制IG Publisher
$publisherJar = Join-Path $currentPath "fhir-ig-publisher.jar"
if (Test-Path $publisherJar) {
    Copy-Item $publisherJar -Destination $newBasePath -Force
    Write-Host "   ✓ fhir-ig-publisher.jar" -ForegroundColor Green
} else {
    Write-Host "   ✗ 未找到 fhir-ig-publisher.jar" -ForegroundColor Red
    exit 1
}

# 复制FHIRHelpers
$fhirHelpers = Join-Path $currentPath "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql"
if (Test-Path $fhirHelpers) {
    Copy-Item $fhirHelpers -Destination "$newBasePath\input\cql\" -Force
    Write-Host "   ✓ FHIRHelpers-4.0.1.cql" -ForegroundColor Green
} else {
    Write-Host "   ✗ 未找到 FHIRHelpers" -ForegroundColor Red
    exit 1
}

# 复制两个CQL文件
$cqlFiles = @(
    "cql\Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730.cql",
    "cql\Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731.cql"
)

foreach ($cqlFile in $cqlFiles) {
    $fullPath = Join-Path $currentPath $cqlFile
    if (Test-Path $fullPath) {
        $fileName = Split-Path $cqlFile -Leaf
        Copy-Item $fullPath -Destination "$newBasePath\input\cql\" -Force
        Write-Host "   ✓ $fileName" -ForegroundColor Green
    } else {
        Write-Host "   ✗ 未找到 $cqlFile" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "3. 创建IG配置文件..." -ForegroundColor Cyan

# 创建ig.ini
"[IG]`nig=input/ig.json`ntemplate=hl7.fhir.template" | Out-File -FilePath "$newBasePath\ig.ini" -Encoding ASCII

# 创建ig.json
@"
{
  "resourceType": "ImplementationGuide",
  "id": "cross-hospital-indicators",
  "url": "http://nhi.gov.tw/fhir/ig/cross-hospital",
  "version": "1.0.0",
  "name": "CrossHospitalIndicators",
  "status": "draft",
  "fhirVersion": ["4.0.1"],
  "definition": {
    "resource": [],
    "page": {
      "nameUrl": "toc.html",
      "title": "Table of Contents",
      "generation": "html"
    }
  }
}
"@ | Out-File -FilePath "$newBasePath\input\ig.json" -Encoding UTF8

Write-Host "   ✓ ig.ini" -ForegroundColor Green
Write-Host "   ✓ ig.json" -ForegroundColor Green
Write-Host ""

Write-Host "4. 运行FHIR IG Publisher..." -ForegroundColor Cyan
Write-Host "   这可能需要几分钟时间..." -ForegroundColor Gray
Write-Host ""
Write-Host "======================================================================" -ForegroundColor DarkGray

# 切换到工作目录并运行
Push-Location $newBasePath
try {
    java -jar fhir-ig-publisher.jar -ig . -tx n/a 2>&1 | Out-String | Write-Host
} catch {
    Write-Host "   ✗ 转换失败: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host "======================================================================" -ForegroundColor DarkGray
Write-Host ""

Write-Host "5. 收集转换结果..." -ForegroundColor Cyan

$elmFiles = Get-ChildItem -Path "$newBasePath\output" -Recurse -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $content -and $content.Contains('"library"') -and $content.Contains('"annotation"')
}

if ($elmFiles -and $elmFiles.Count -gt 0) {
    $outputDir = Join-Path $currentPath "ELM_JSON_OFFICIAL\舊50_AHRQ_Official"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    $copiedCount = 0
    foreach ($elm in $elmFiles) {
        $destFile = Join-Path $outputDir $elm.Name
        Copy-Item $elm.FullName -Destination $destFile -Force
        $size = [math]::Round($elm.Length / 1KB, 2)
        Write-Host "   ✓ $($elm.Name) - $size KB" -ForegroundColor Green
        $copiedCount++
    }
    
    Write-Host ""
    Write-Host "转换成功！" -ForegroundColor Green
    Write-Host "   文件数: $copiedCount" -ForegroundColor Gray
    Write-Host "   输出目录: $outputDir" -ForegroundColor Gray
    
} else {
    Write-Host "   ✗ 未找到ELM输出文件" -ForegroundColor Red
    Write-Host "   检查目录: $newBasePath\output" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " 转换完成 " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

