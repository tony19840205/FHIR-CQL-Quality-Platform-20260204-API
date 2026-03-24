$files = @(
    'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql',
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql'
)

$outputDir = Join-Path (Get-Location) "ELM_JSON_OFFICIAL"
$outputDir = Join-Path $outputDir "舊50"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Force -Path $outputDir | Out-Null }

$success = @()
$failed = @()

Write-Host "`n=== 轉換 CQL 到 ELM JSON ===" -ForegroundColor Cyan

foreach ($file in $files) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $outputPath = "$outputDir\$baseName.json"
    
    Write-Host "`n$file" -ForegroundColor Yellow
    
    try {
        $cqlContent = Get-Content "cql\$file" -Raw -Encoding UTF8
        
        # 移除SQL部分
        $cqlContent = $cqlContent -replace '(?s)(-- .*?WITH quarters AS.*$)', "`n// SQL removed`n"
        
        $headers = @{"Content-Type"="application/cql"}
        $response = Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" -Method POST -Headers $headers -Body $cqlContent
        
        $elmJson = $response | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($outputPath, $elmJson, [System.Text.Encoding]::UTF8)
        
        $size = (Get-Item $outputPath).Length
        Write-Host "  成功: $([math]::Round($size/1KB, 2)) KB" -ForegroundColor Green
        $success += $file
    }
    catch {
        Write-Host "  失敗: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $file
    }
}

Write-Host "`n=== 完成 ===" -ForegroundColor Cyan
Write-Host "成功: $($success.Count) / 失敗: $($failed.Count)" -ForegroundColor $(if ($failed.Count -eq 0) { "Green" } else { "Yellow" })
