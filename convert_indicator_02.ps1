param(
    [string]$CqlFile = "cql\Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql",
    [string]$OutputDir = "ELM_JSON_OFFICIAL\舊50"
)

Write-Host "`n=== CQL轉換官方ELM JSON ===" -ForegroundColor Cyan
Write-Host "使用工具: HL7 FHIR IG Publisher" -ForegroundColor Yellow

# 1. 檢查Java環境
Write-Host "`n[步驟1] 檢查Java環境..." -ForegroundColor Cyan
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "✅ Java已安裝: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ 未找到Java，請先安裝JDK" -ForegroundColor Red
    exit 1
}

# 2. 下載IG Publisher
$igPublisher = "publisher.jar"
if (-not (Test-Path $igPublisher)) {
    Write-Host "`n[步驟2] 下載IG Publisher..." -ForegroundColor Cyan
    $url = "https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar"
    try {
        Invoke-WebRequest -Uri $url -OutFile $igPublisher -UseBasicParsing
        Write-Host "✅ 下載成功: $igPublisher" -ForegroundColor Green
    } catch {
        Write-Host "❌ 下載失敗: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[步驟2] ✅ IG Publisher已存在" -ForegroundColor Green
}

# 3. 創建臨時IG項目結構
Write-Host "`n[步驟3] 創建IG項目結構..." -ForegroundColor Cyan
$tempDir = "temp_ig_convert"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path "$tempDir\input\cql" -Force | Out-Null

# 複製CQL文件
Copy-Item $CqlFile "$tempDir\input\cql\" -Force
$cqlFileName = Split-Path $CqlFile -Leaf
Write-Host "✅ 已複製: $cqlFileName" -ForegroundColor Green

# 4. 創建ig.ini
$igIni = @"
[IG]
ig = fhir.example.cql
template = fhir.base.template
"@
Set-Content "$tempDir\ig.ini" $igIni -Encoding UTF8

# 5. 創建sushi-config.yaml
$sushiConfig = @"
id: fhir.example.cql
canonical: http://example.org/fhir/example
name: CQL_Conversion
title: CQL to ELM Conversion
status: draft
version: 1.0.0
fhirVersion: 4.0.1
copyrightYear: 2026
releaseLabel: ci-build
publisher:
  name: Example Publisher
"@
Set-Content "$tempDir\sushi-config.yaml" $sushiConfig -Encoding UTF8

# 6. 運行IG Publisher進行轉換
Write-Host "`n[步驟4] 執行CQL轉換..." -ForegroundColor Cyan
Push-Location $tempDir
try {
    java -jar "..\$igPublisher" -ig ig.ini 2>&1 | Out-Null
    Write-Host "✅ 轉換完成" -ForegroundColor Green
} catch {
    Write-Host "⚠️ 轉換過程有警告（可能正常）" -ForegroundColor Yellow
} finally {
    Pop-Location
}

# 7. 查找並複製ELM JSON文件
Write-Host "`n[步驟5] 查找ELM JSON文件..." -ForegroundColor Cyan
$elmFiles = Get-ChildItem -Path "$tempDir\output" -Recurse -Filter "*.json" | 
    Where-Object { $_.Name -like "*ELM*" -or $_.Directory.Name -eq "cql" }

if ($elmFiles.Count -eq 0) {
    Write-Host "⚠️ 未找到ELM JSON文件，檢查所有JSON..." -ForegroundColor Yellow
    $elmFiles = Get-ChildItem -Path "$tempDir\output" -Recurse -Filter "*.json" |
        Where-Object { 
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            $content -match '"library"' -and $content -match '"identifier"'
        }
}

if ($elmFiles.Count -gt 0) {
    # 確保輸出目錄存在
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    foreach ($file in $elmFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($cqlFileName)
        $outputFile = Join-Path $OutputDir "$baseName.json"
        Copy-Item $file.FullName $outputFile -Force
        
        Write-Host "✅ 已生成: $outputFile" -ForegroundColor Green
        $sizeKB = [math]::Round((Get-Item $outputFile).Length / 1KB, 2)
        Write-Host "   文件大小: $sizeKB KB" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ 未找到ELM JSON文件" -ForegroundColor Red
    Write-Host "`n檢查輸出目錄結構:" -ForegroundColor Yellow
    Get-ChildItem "$tempDir\output" -Recurse | Select-Object FullName -First 20
}

# 8. 清理臨時文件
Write-Host "`n[步驟6] 清理臨時文件..." -ForegroundColor Cyan
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ 清理完成" -ForegroundColor Green

Write-Host "`n=== 轉換完成 ===" -ForegroundColor Green
