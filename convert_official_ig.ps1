# FHIR IG Publisher batch conversion - CQL to official ELM
param([string]$Category = "中醫")

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " FHIR IG Publisher Batch Convert - Official ELM " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$newBasePath = "C:\CQL_Project"
$currentPath = Get-Location
$sourceBase = Join-Path $currentPath "CQL 2026"

Write-Host "Setup..." -ForegroundColor Cyan
Write-Host "   Current: $currentPath" -ForegroundColor Gray
Write-Host "   Target: $newBasePath" -ForegroundColor Gray
Write-Host ""

if (Test-Path $newBasePath) {
    Write-Host "   Cleaning old directory..." -ForegroundColor Yellow
    Remove-Item -Path $newBasePath -Recurse -Force
}

New-Item -Path $newBasePath -ItemType Directory | Out-Null
New-Item -Path "$newBasePath\input\cql" -ItemType Directory -Force | Out-Null
Write-Host "[OK] Directories created" -ForegroundColor Green
Write-Host ""

Write-Host "Copying files..." -ForegroundColor Cyan
$publisherJar = Join-Path $currentPath "fhir-ig-publisher.jar"
Copy-Item $publisherJar -Destination $newBasePath -Force
Write-Host "   [OK] IG Publisher" -ForegroundColor Green

$fhirHelpers = Join-Path $sourceBase "FHIRHelpers\FHIRHelpers-4.0.1.cql"
if (Test-Path $fhirHelpers) {
    Copy-Item $fhirHelpers -Destination "$newBasePath\input\cql\" -Force
    Write-Host "   [OK] FHIRHelpers" -ForegroundColor Green
}

$categoryPath = Join-Path $sourceBase $Category
$cqlFiles = Get-ChildItem -Path $categoryPath -Filter "*.cql"
foreach ($file in $cqlFiles) {
    Copy-Item $file.FullName -Destination "$newBasePath\input\cql\" -Force
}
Write-Host "   [OK] $($cqlFiles.Count) CQL files [$Category]" -ForegroundColor Green
Write-Host ""

Write-Host "Creating config..." -ForegroundColor Cyan
"[IG]`nig=input/ig.json`ntemplate=hl7.fhir.template" | Out-File -FilePath "$newBasePath\ig.ini" -Encoding ASCII
@"
{
  "resourceType": "ImplementationGuide",
  "id": "cql",
  "url": "http://example.org",
  "version": "1.0.0",
  "name": "CQL",
  "packageId": "example.org.cql",
  "status": "draft",
  "fhirVersion": ["4.0.1"],
  "definition": {
    "grouping": [],
    "resource": [],
    "page": {
      "nameUrl": "toc.html",
      "title": "Table of Contents",
      "generation": "html",
      "page": []
    },
    "parameter": [
      {
        "code": "copyrightyear",
        "value": "2026"
      },
      {
        "code": "releaselabel",
        "value": "CI Build"
      }
    ]
  }
}
"@ | Out-File -FilePath "$newBasePath\input\ig.json" -Encoding UTF8
Write-Host "   [OK] Config complete" -ForegroundColor Green
Write-Host ""

Write-Host "Running IG Publisher..." -ForegroundColor Cyan
Write-Host ""

# Switch to new path and run
Push-Location $newBasePath
java -jar fhir-ig-publisher.jar -ig . -tx n/a
Pop-Location

Write-Host ""
Write-Host "Collecting results..." -ForegroundColor Cyan

$elmFiles = Get-ChildItem -Path "$newBasePath\output" -Recurse -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $content -and $content.Contains('"library"')
}

if ($elmFiles) {
    $outputDir = Join-Path $currentPath "ELM_JSON_OFFICIAL\$Category"
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    
    foreach ($elm in $elmFiles) {
        Copy-Item $elm.FullName -Destination $outputDir -Force
    }
    
    Write-Host "[OK] Collected $($elmFiles.Count) ELM files to:" -ForegroundColor Green
    Write-Host "   $outputDir" -ForegroundColor Gray
} else {
    Write-Host "[WARN] No ELM output files found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[COMPLETE]" -ForegroundColor Green
