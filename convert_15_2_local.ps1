# 使用本地 JAR 轉換 Indicator 15_2 CQL 到 ELM JSON
# Translator Version: 3.10.0

$ErrorActionPreference = "Stop"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host " Convert Indicator 15_2 (3249) using Local JAR" -ForegroundColor Yellow
Write-Host " Total Knee Arthroplasty 90Day Deep Infection Rate" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

# 設定路徑
$cqlFile = "cql\Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.cql"
$outputDir = "ELM_JSON_OFFICIAL\舊50"
$outputFile = Join-Path $outputDir "Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.json"

# Check CQL file
if (!(Test-Path $cqlFile)) {
    Write-Host "ERROR: CQL file not found: $cqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "`nOK CQL file: $cqlFile" -ForegroundColor Green
$cqlSize = (Get-Item $cqlFile).Length / 1KB
Write-Host "  大小: $($cqlSize.ToString('F2')) KB" -ForegroundColor Gray

# Create output directory
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "OK Created output directory: $outputDir" -ForegroundColor Green
}

# Check fhir-ig-publisher.jar
$publisherJar = "fhir-ig-publisher.jar"
if (!(Test-Path $publisherJar)) {
    Write-Host "ERROR: Cannot find $publisherJar" -ForegroundColor Red
    exit 1
}

Write-Host "`nUsing FHIR IG Publisher to convert..." -ForegroundColor Cyan
Write-Host "Option: -convert $(Split-Path $cqlFile -Leaf)" -ForegroundColor Gray

# Temporary output directory
$tempDir = "temp_elm_15_2"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Copy CQL file to temp directory
    Copy-Item $cqlFile -Destination $tempDir
    
    # Execute conversion
    Write-Host "`nExecuting conversion..." -ForegroundColor Yellow
    $result = & java -jar $publisherJar `
        -convert "$tempDir\$(Split-Path $cqlFile -Leaf)" `
        -version 4.0.1 2>&1
    
    Write-Host $result -ForegroundColor Gray
    
    # Find generated JSON file
    $elmFile = Get-ChildItem -Path $tempDir -Filter "*.json" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($elmFile) {
        # Move to final directory
        Move-Item $elmFile.FullName -Destination $outputFile -Force
        
        # Check result
        $jsonSize = (Get-Item $outputFile).Length / 1KB
        $jsonLines = (Get-Content $outputFile).Count
        
        Write-Host "`n" + "=" * 80 -ForegroundColor Green
        Write-Host " SUCCESS: Conversion completed!" -ForegroundColor Green
        Write-Host "=" * 80 -ForegroundColor Green
        
        Write-Host "`nOutput File:" -ForegroundColor Cyan
        Write-Host "  Path: $outputFile" -ForegroundColor White
        Write-Host "  Size: $($jsonSize.ToString('F2')) KB" -ForegroundColor White
        Write-Host "  Lines: $jsonLines" -ForegroundColor White
        
        # 質量檢查
        Write-Host "`nQuality Check:" -ForegroundColor Cyan
        $sizeOK = $jsonSize -ge 50
        $linesOK = $jsonLines -ge 1000
        
        if ($sizeOK) {
            Write-Host "  OK File size: $($jsonSize.ToString('F2')) KB" -ForegroundColor Green
        } else {
            Write-Host "  WARNING File size too small: $($jsonSize.ToString('F2')) KB" -ForegroundColor Yellow
        }
        
        if ($linesOK) {
            Write-Host "  OK Lines: $jsonLines" -ForegroundColor Green
        } else {
            Write-Host "  WARNING Lines too few: $jsonLines" -ForegroundColor Yellow
        }
        
        # Verify JSON structure
        try {
            $json = Get-Content $outputFile -Raw | ConvertFrom-Json
            
            if ($json.library) {
                Write-Host "`nELM Structure:" -ForegroundColor Cyan
                Write-Host "  OK library: $($json.library.identifier.id)" -ForegroundColor Green
                Write-Host "  OK version: $($json.library.identifier.version)" -ForegroundColor Green
                
                if ($json.library.annotation) {
                    $anno = $json.library.annotation[0]
                    Write-Host "  OK translatorVersion: $($anno.translatorVersion)" -ForegroundColor Green
                }
                
                if ($json.library.statements) {
                    $stmtCount = $json.library.statements.def.Count
                    Write-Host "  OK statements: $stmtCount definitions" -ForegroundColor Green
                }
            }
            
            if ($sizeOK -and $linesOK) {
                Write-Host "`n" + "=" * 80 -ForegroundColor Green
                Write-Host " SUCCESS: Conversion and quality check passed!" -ForegroundColor Green
                Write-Host "=" * 80 -ForegroundColor Green
            }
            
        } catch {
            Write-Host "`nWARNING: Cannot parse JSON: $_" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "`nERROR: Generated ELM JSON file not found" -ForegroundColor Red
        Write-Host "Temp directory contents:" -ForegroundColor Gray
        Get-ChildItem $tempDir | Format-Table
        exit 1
    }
    
} catch {
    Write-Host "`nERROR: Conversion failed: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
} finally {
    # Clean up temp directory
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`nCompleted!" -ForegroundColor Cyan
