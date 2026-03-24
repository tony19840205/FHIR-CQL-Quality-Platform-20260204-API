# Test IG Publisher CQL conversion
param([string]$CqlFile)

Write-Host "Testing IG Publisher..." -ForegroundColor Cyan
Write-Host ""

# Check IG Publisher
if (-not (Test-Path "fhir-ig-publisher.jar")) {
    Write-Host "ERROR: fhir-ig-publisher.jar not found" -ForegroundColor Red
    exit 1
}

# Create temp directory
$tempDir = "temp_ig_test"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}

New-Item -Path $tempDir -ItemType Directory | Out-Null
New-Item -Path "$tempDir\input" -ItemType Directory | Out-Null
New-Item -Path "$tempDir\input\cql" -ItemType Directory | Out-Null

# Create ig.ini
$iniContent = "[IG]`nig = input/ig.json`ntemplate = #fhir.base.template"
$iniContent | Out-File -FilePath "$tempDir\ig.ini" -Encoding ASCII

# Create minimal IG JSON
$igContent = '{"resourceType":"ImplementationGuide","id":"test","url":"http://test.org","version":"1.0.0","name":"Test","status":"draft","fhirVersion":["4.0.1"],"definition":{"resource":[]}}'
$igContent | Out-File -FilePath "$tempDir\input\ig.json" -Encoding ASCII

# Copy CQL files
if ($CqlFile -and (Test-Path $CqlFile)) {
    Copy-Item $CqlFile -Destination "$tempDir\input\cql\" -Force
    Write-Host "Copied: $(Split-Path $CqlFile -Leaf)" -ForegroundColor Green
}

if (Test-Path "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql") {
    Copy-Item "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql" -Destination "$tempDir\input\cql\" -Force
    Write-Host "Copied: FHIRHelpers-4.0.1.cql" -ForegroundColor Green
}

Write-Host ""
Write-Host "Running IG Publisher..." -ForegroundColor Cyan
Write-Host ""

# Run IG Publisher
java -jar fhir-ig-publisher.jar -ig $tempDir -tx n/a

Write-Host ""
Write-Host "Checking output..." -ForegroundColor Cyan

# Check for ELM output
if (Test-Path "$tempDir\output") {
    Get-ChildItem "$tempDir\output" -Recurse -Filter "*.json" | ForEach-Object {
        Write-Host "Found: $($_.FullName)" -ForegroundColor Yellow
    }
} else {
    Write-Host "No output folder found" -ForegroundColor Red
}
