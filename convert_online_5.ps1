# Quick convert 5 Indicator files using online API
$files = @(
    'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01',
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726'
)

$outputDir = Join-Path $PWD "ELM_JSON_OFFICIAL" | Join-Path -ChildPath "舊50"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

Write-Host "`n=== Converting 5 Indicator CQL Files ===" -ForegroundColor Cyan
Write-Host "Using online CQL Runner API`n" -ForegroundColor Yellow

$success = 0
$failed = 0
$successFiles = @()
$failedFiles = @()

foreach ($name in $files) {
    $cqlFile = Join-Path $PWD "cql" | Join-Path -ChildPath "$name.cql"
    $jsonFile = Join-Path $outputDir "$name.json"
    
    Write-Host "[$($success+$failed+1)/$($files.Count)] $name.cql" -ForegroundColor Cyan
    
    if (-not (Test-Path $cqlFile)) {
        Write-Host "  ERROR: File not found" -ForegroundColor Red
        $failed++
        $failedFiles += $name
        continue
    }
    
    $cql = Get-Content $cqlFile -Raw -Encoding UTF8
    
    # Remove SQL parts if present
    if ($cql -match '(?s)(-- .*?WITH quarters AS.*$)') {
        $sqlPart = $matches[1]
        $cql = $cql -replace [regex]::Escape($sqlPart), "`n// SQL removed`n"
        Write-Host "  Removed SQL code" -ForegroundColor Gray
    }
    
    try {
        $body = @{ cql = $cql } | ConvertTo-Json -Depth 5
        
        $result = Invoke-RestMethod `
            -Uri "https://cql-runner.dataphoria.org/cql-to-elm" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 60
        
        $result | ConvertTo-Json -Depth 100 | Out-File $jsonFile -Encoding UTF8
        
        $size = [math]::Round((Get-Item $jsonFile).Length / 1KB, 2)
        Write-Host "  SUCCESS: $size KB" -ForegroundColor Green
        $success++
        $successFiles += $name
    }
    catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
        $failedFiles += $name
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Success: $success/$($files.Count)" -ForegroundColor $(if ($success -eq $files.Count) { "Green" } else { "Yellow" })
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($successFiles.Count -gt 0) {
    Write-Host "`nSuccessful files:" -ForegroundColor Green
    $successFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
}

if ($failedFiles.Count -gt 0) {
    Write-Host "`nFailed files:" -ForegroundColor Red
    $failedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
}

Write-Host "`nOutput directory: $outputDir" -ForegroundColor Yellow
