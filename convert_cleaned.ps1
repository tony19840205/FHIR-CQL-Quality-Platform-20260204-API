$files = @(
    'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01',
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726'
)

$outputDir = "C:\Users\tony1\Desktop\UI UX- 20260108\ELM_JSON_OFFICIAL\舊50"
$headers = @{"Content-Type"="application/cql"}
$success = @()
$failed = @()

Write-Host "`n=== 轉換清理後的CQL文件 ===" -ForegroundColor Cyan

foreach ($file in $files) {
    Write-Host "`n處理: $file.cql" -ForegroundColor Yellow
    
    try {
        $cqlContent = Get-Content "cql\$file.cql" -Raw -Encoding UTF8
        $output = Join-Path $outputDir "$file.json"
        
        $response = Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" `
            -Method POST `
            -Headers $headers `
            -Body $cqlContent
        
        $json = $response | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($output, $json, [System.Text.Encoding]::UTF8)
        
        $size = (Get-Item $output).Length
        Write-Host "  成功: $([math]::Round($size/1KB, 2)) KB" -ForegroundColor Green
        $success += $file
    }
    catch {
        Write-Host "  失敗: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $file
    }
}

Write-Host "`n=== 完成 ===" -ForegroundColor Cyan
Write-Host "成功: $($success.Count) / 失敗: $($failed.Count)" -ForegroundColor Green

if ($failed.Count -gt 0) {
    Write-Host "`n失敗的文件:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  $_" }
}
