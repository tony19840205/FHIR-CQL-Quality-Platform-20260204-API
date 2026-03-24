# FHIR IG Publisher - Convert Cross Hospital Indicators 13 and 14
# Use the same method as TCM indicators

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Convert Cross Hospital Indicators (Official ELM) " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$newBasePath = "C:\CQL_Cross_Hospital"
$currentPath = Get-Location

Write-Host "1. Setup directories..." -ForegroundColor Cyan
if (Test-Path $newBasePath) {
    Remove-Item -Path $newBasePath -Recurse -Force
}
New-Item -Path $newBasePath -ItemType Directory | Out-Null
New-Item -Path "$newBasePath\input\cql" -ItemType Directory -Force | Out-Null
Write-Host "   [OK] Directories created" -ForegroundColor Green
Write-Host ""

Write-Host "2. Copy necessary files..." -ForegroundColor Cyan

# Copy IG Publisher
$publisherJar = Join-Path $currentPath "fhir-ig-publisher.jar"
if (Test-Path $publisherJar) {
    Copy-Item $publisherJar -Destination $newBasePath -Force
    Write-Host "   [OK] fhir-ig-publisher.jar" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] fhir-ig-publisher.jar not found" -ForegroundColor Red
    exit 1
}

# Copy FHIRHelpers
$fhirHelpers = Join-Path $currentPath "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql"
if (Test-Path $fhirHelpers) {
    Copy-Item $fhirHelpers -Destination "$newBasePath\input\cql\" -Force
    Write-Host "   [OK] FHIRHelpers-4.0.1.cql" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] FHIRHelpers not found" -ForegroundColor Red
    exit 1
}

# Copy CQL files
$cqlFiles = @(
    "cql\Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730.cql",
    "cql\Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731.cql"
)

foreach ($cqlFile in $cqlFiles) {
    $fullPath = Join-Path $currentPath $cqlFile
    if (Test-Path $fullPath) {
        $fileName = Split-Path $cqlFile -Leaf
        Copy-Item $fullPath -Destination "$newBasePath\input\cql\" -Force
        Write-Host "   [OK] $fileName" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] $cqlFile not found" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "3. Create IG config files..." -ForegroundColor Cyan

# Create ig.ini
"[IG]`nig=input/ig.json`ntemplate=hl7.fhir.template" | Out-File -FilePath "$newBasePath\ig.ini" -Encoding ASCII

# Create ig.json
@"
{
  "resourceType": "ImplementationGuide",
  "id": "cross-hospital-indicators",
  "url": "http://nhi.gov.tw/fhir/ig/cross-hospital",
  "version": "1.0.0",
  "name": "CrossHospitalIndicators",
  "packageId": "nhi.gov.tw.fhir.cross-hospital",
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

Write-Host "   [OK] Config files created" -ForegroundColor Green
Write-Host ""

Write-Host "4. Run FHIR IG Publisher (this may take several minutes)..." -ForegroundColor Cyan
Write-Host ""

# Switch to working directory and run
Push-Location $newBasePath
try {
    java -jar fhir-ig-publisher.jar -ig . -tx n/a
} catch {
    Write-Host "   [ERROR] Conversion failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host ""
Write-Host "5. Collect conversion results..." -ForegroundColor Cyan

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
        Write-Host "   [OK] $($elm.Name) - $size KB" -ForegroundColor Green
        $copiedCount++
    }
    
    Write-Host ""
    Write-Host "[SUCCESS] Conversion complete!" -ForegroundColor Green
    Write-Host "   Files: $copiedCount" -ForegroundColor Gray
    Write-Host "   Output: $outputDir" -ForegroundColor Gray
    
} else {
    Write-Host "   [WARN] No ELM output files found" -ForegroundColor Yellow
    Write-Host "   Check directory: $newBasePath\output" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
