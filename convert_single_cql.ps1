# Convert single CQL file to official ELM JSON format
param(
    [string]$CqlFileName = "Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01"
)

$baseDir = "c:\Users\tony1\Desktop\UI UX- 20260108"
$cqlFile = Join-Path $baseDir "cql\$CqlFileName.cql"
$outputFile = Join-Path $baseDir "ELM_JSON_OFFICIAL\舊50\$CqlFileName.json"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Official CQL to ELM JSON Converter" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Input:  $cqlFile" -ForegroundColor Yellow
Write-Host "Output: $outputFile" -ForegroundColor Yellow
Write-Host ""

# Read CQL content
$cqlContent = Get-Content $cqlFile -Raw -Encoding UTF8

# Method 1: Try localhost Docker service
Write-Host "[1/3] Trying localhost:8080 Docker service..." -ForegroundColor Cyan
try {
    $headers = @{
        "Content-Type" = "text/cql"
        "Accept" = "application/elm+json"
    }
    
    $response = Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" `
        -Method Post `
        -Body $cqlContent `
        -Headers $headers `
        -TimeoutSec 30
    
    # Save response
    if ($response -is [string]) {
        $response | Out-File -FilePath $outputFile -Encoding UTF8
    } else {
        $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputFile -Encoding UTF8
    }
    
    Write-Host "✓ SUCCESS! Converted using Docker service" -ForegroundColor Green
    Write-Host "Output saved to: $outputFile" -ForegroundColor Green
    
    # Validate JSON
    $jsonContent = Get-Content $outputFile -Raw | ConvertFrom-Json
    Write-Host "✓ JSON validation passed" -ForegroundColor Green
    Write-Host "  Library: $($jsonContent.library.identifier.id)" -ForegroundColor Gray
    Write-Host "  Version: $($jsonContent.library.identifier.version)" -ForegroundColor Gray
    
    exit 0
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 2: Try with application/cql content type
Write-Host "`n[2/3] Trying alternative content-type..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" `
        -Method Post `
        -Body $cqlContent `
        -ContentType "application/cql" `
        -TimeoutSec 30
    
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "✓ SUCCESS! Converted with alternative method" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 3: Try online HL7 service
Write-Host "`n[3/3] Trying HL7.org online service..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "https://cql-translator.dataphoria.org/translate" `
        -Method Post `
        -Body $cqlContent `
        -ContentType "text/plain" `
        -TimeoutSec 30
    
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "✓ SUCCESS! Converted using online service" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n============================================" -ForegroundColor Red
Write-Host "All conversion methods failed!" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
Write-Host "1. Check CQL syntax errors in the source file" -ForegroundColor White
Write-Host "2. Ensure Docker service is running: docker ps" -ForegroundColor White
Write-Host "3. Test service: curl http://localhost:8080/health" -ForegroundColor White
Write-Host "4. Check service logs: docker logs cql-service" -ForegroundColor White

exit 1
