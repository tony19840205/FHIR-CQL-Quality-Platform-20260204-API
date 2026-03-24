# Manual conversion script
# Service is already running at localhost:8080

$files = @(
    'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql',
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql'
)

$outputDir = Join-Path $PWD "ELM_JSON_OFFICIAL" | Join-Path -ChildPath "舊50"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$success = @()
$failed = @()

Write-Host "`n=== Converting $($files.Count) files ===" -ForegroundColor Cyan

foreach ($file in $files) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $sourcePath = Join-Path $PWD "cql" | Join-Path -ChildPath $file
    $outputPath = Join-Path $outputDir "$baseName.json"
    
    Write-Host "`nProcessing: $file" -ForegroundColor Yellow
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  ERROR: File not found" -ForegroundColor Red
        $failed += $file
        continue
    }
    
    try {
        $cqlContent = Get-Content $sourcePath -Raw -Encoding UTF8
        
        # Remove SQL parts
        if ($cqlContent -match '(?s)(-- .*?WITH quarters AS.*$)') {
            $sqlPart = $matches[1]
            $cqlContent = $cqlContent -replace [regex]::Escape($sqlPart), "`n// SQL removed`n"
            Write-Host "  Removed SQL code" -ForegroundColor Gray
        }
        
        $body = @{ code = $cqlContent } | ConvertTo-Json -Depth 5 -Compress
        
        $headers = @{
            "Content-Type" = "application/json; charset=utf-8"
        }
        
        $response = Invoke-RestMethod `
            -Uri "http://localhost:8080/cql/translator" `
            -Method POST `
            -Headers $headers `
            -Body $body `
            -UseBasicParsing `
            -TimeoutSec 60
        
        if ($response.library) {
            $elmJson = $response | ConvertTo-Json -Depth 100
            [System.IO.File]::WriteAllText($outputPath, $elmJson, [System.Text.Encoding]::UTF8)
            
            $size = (Get-Item $outputPath).Length
            Write-Host "  SUCCESS: $([math]::Round($size/1KB, 2)) KB" -ForegroundColor Green
            $success += $file
        }
        else {
            Write-Host "  ERROR: No library" -ForegroundColor Red
            if ($response.errors) {
                $response.errors | ForEach-Object {
                    Write-Host "    $_" -ForegroundColor Red
                }
            }
            $failed += $file
        }
    }
    catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $file
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Success: $($success.Count)/$($files.Count)" -ForegroundColor Green
Write-Host "Failed: $($failed.Count)/$($files.Count)" -ForegroundColor $(if ($failed.Count -eq 0) { "Green" } else { "Red" })

if ($success.Count -gt 0) {
    Write-Host "`nSuccessful:" -ForegroundColor Green
    $success | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
}

if ($failed.Count -gt 0) {
    Write-Host "`nFailed:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
}

Write-Host "`nOutput directory: $outputDir" -ForegroundColor Yellow
