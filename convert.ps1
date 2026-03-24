# Simple CQL to ELM converter using cql-translation-service API

$sourceFolder = ".\CQL 2026"
$outputFolder = ".\ELM_JSON"
$apiUrl = "https://cql.dataphoria.org/translate"

# Create output folder
if (-not (Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
}

# Get all CQL files
$cqlFiles = Get-ChildItem -Path $sourceFolder -Filter "*.cql" -Recurse
Write-Host "Found $($cqlFiles.Count) CQL files" -ForegroundColor Cyan
Write-Host ""

$success = 0
$failed = 0

foreach ($file in $cqlFiles) {
    $relativePath = $file.FullName.Replace((Get-Item $sourceFolder).FullName, "").TrimStart("\")
    Write-Host "Converting: $relativePath" -ForegroundColor Yellow
    
    try {
        # Read CQL content
        $cqlContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Call API
        $body = @{ cql = $cqlContent } | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
        
        # Save ELM JSON
        $outputPath = Join-Path $outputFolder ($relativePath -replace "\.cql$", ".json")
        $outputDir = Split-Path $outputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $response | ConvertTo-Json -Depth 100 | Set-Content -Path $outputPath -Encoding UTF8
        Write-Host "  SUCCESS -> $outputPath" -ForegroundColor Green
        $success++
        
    } catch {
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
    
    Start-Sleep -Milliseconds 200
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Conversion Complete!" -ForegroundColor Green
Write-Host "  Success: $success" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
