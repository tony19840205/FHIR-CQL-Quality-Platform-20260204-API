# Taiwan MOHW FHIR Server Upload Test
# Test uploading patient data to https://thas.mohw.gov.tw/v/r4/fhir

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Taiwan MOHW FHIR Upload Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$fhirServerUrl = "https://thas.mohw.gov.tw/v/r4/fhir"

# Test with single patient (simplest)
$testFile = "test_single_cesarean.json"
$testFilePath = Join-Path $PSScriptRoot $testFile

Write-Host "Selected test file: $testFile" -ForegroundColor Green
Write-Host "File path: $testFilePath`n" -ForegroundColor Gray

# Check if file exists
if (-not (Test-Path $testFilePath)) {
    Write-Host "ERROR: Cannot find test file: $testFilePath" -ForegroundColor Red
    exit 1
}

# Read test data
Write-Host "Reading test data..." -ForegroundColor Cyan
try {
    $jsonContent = Get-Content $testFilePath -Raw -Encoding UTF8
    $jsonObject = $jsonContent | ConvertFrom-Json
    
    Write-Host "SUCCESS: Data loaded!" -ForegroundColor Green
    Write-Host "  Data size: $([math]::Round($jsonContent.Length / 1KB, 2)) KB" -ForegroundColor Gray
    Write-Host "  Resource type: $($jsonObject.resourceType)" -ForegroundColor Gray
    Write-Host "  Number of entries: $($jsonObject.entry.Count)`n" -ForegroundColor Gray
} catch {
    Write-Host "ERROR reading file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test server connection (Metadata)
Write-Host "Testing FHIR server connection..." -ForegroundColor Cyan
Write-Host "  URL: $fhirServerUrl/metadata`n" -ForegroundColor Gray

try {
    $metadataUrl = "$fhirServerUrl/metadata"
    $metadataResponse = Invoke-RestMethod -Uri $metadataUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    Write-Host "SUCCESS: Server connected!" -ForegroundColor Green
    Write-Host "  FHIR version: $($metadataResponse.fhirVersion)" -ForegroundColor Gray
    Write-Host "  Software: $($metadataResponse.software.name)`n" -ForegroundColor Gray
} catch {
    Write-Host "WARNING: Server connection failed!" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPossible reasons:" -ForegroundColor Yellow
    Write-Host "  1. Server is under maintenance" -ForegroundColor Gray
    Write-Host "  2. Network connection issue" -ForegroundColor Gray
    Write-Host "  3. CORS policy blocking (use Postman instead)`n" -ForegroundColor Gray
    
    Write-Host "Continue with upload? (y/N): " -ForegroundColor Yellow -NoNewline
    $continue = Read-Host
    
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "`nTest cancelled.`n" -ForegroundColor Red
        exit 1
    }
}

# Upload data
Write-Host "`nUploading test data..." -ForegroundColor Cyan
Write-Host "  Target: $fhirServerUrl" -ForegroundColor Gray
Write-Host "  Patient count: 1`n" -ForegroundColor Gray

try {
    $headers = @{
        "Content-Type" = "application/fhir+json"
        "Accept" = "application/fhir+json"
    }
    
    $startTime = Get-Date
    
    $response = Invoke-RestMethod -Uri $fhirServerUrl -Method Post -Body $jsonContent -Headers $headers -TimeoutSec 60
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "SUCCESS: Upload completed!" -ForegroundColor Green
    Write-Host "  Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor Gray
    Write-Host "  Response type: $($response.resourceType)" -ForegroundColor Gray
    
    if ($response.type -eq "transaction-response") {
        Write-Host "  Result: Transaction Bundle" -ForegroundColor Gray
        
        $successCount = ($response.entry | Where-Object { $_.response.status -match "^2" }).Count
        $totalCount = $response.entry.Count
        
        Write-Host "  Success: $successCount / $totalCount resources`n" -ForegroundColor Green
    }
    
} catch {
    Write-Host "ERROR: Upload failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "  HTTP Status: $statusCode" -ForegroundColor Yellow
    }
    
    Write-Host "`nSuggestion: Use Postman for testing (no CORS restrictions)`n" -ForegroundColor Cyan
    exit 1
}

# Verify upload
Write-Host "`nVerifying upload..." -ForegroundColor Cyan

try {
    $patientSearchUrl = "$fhirServerUrl/Patient?_count=10&_sort=-_lastUpdated"
    Write-Host "  Querying recent patients: $patientSearchUrl`n" -ForegroundColor Gray
    
    $patients = Invoke-RestMethod -Uri $patientSearchUrl -Method Get -ContentType "application/fhir+json" -TimeoutSec 30
    
    if ($patients.total -gt 0) {
        Write-Host "SUCCESS: Found $($patients.total) patients!" -ForegroundColor Green
        Write-Host "`n  Recent patients:" -ForegroundColor Cyan
        
        $patients.entry | Select-Object -First 3 | ForEach-Object {
            $patient = $_.resource
            $patientId = $patient.id
            $patientName = if ($patient.name) { $patient.name[0].text } else { "No name" }
            Write-Host "  - ID: $patientId | Name: $patientName" -ForegroundColor White
        }
        Write-Host ""
    } else {
        Write-Host "WARNING: No patients found (may need to wait 1-2 minutes)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "WARNING: Verification query failed (server delay)" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Display SAND-BOX Launch info
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SAND-BOX Launch Information" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "FHIR Server URL:" -ForegroundColor Yellow
Write-Host "  $fhirServerUrl`n" -ForegroundColor White

Write-Host "Launch URL options:" -ForegroundColor Yellow
Write-Host "  [1] GitHub Pages: https://tony19840205.github.io/FHIR-CQL-Quality-Platform/index.html" -ForegroundColor White
Write-Host "  [2] Local test: http://localhost:8080/index.html`n" -ForegroundColor White

Write-Host "Test completed! Please enter the above information in SAND-BOX for Launch testing.`n" -ForegroundColor Green

Write-Host "========================================`n" -ForegroundColor Cyan