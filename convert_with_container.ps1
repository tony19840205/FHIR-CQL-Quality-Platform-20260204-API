# 使用容器API轉換5個指標文件
$files = @(
    'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql',
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql'
)

$outputDir = "ELM_JSON_OFFICIAL\舊50"
$success = @()
$failed = @()

Write-Host "`n=== 使用容器轉換CQL到ELM JSON ===" -ForegroundColor Cyan

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

foreach ($file in $files) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $sourcePath = "cql\$file"
    $outputPath = "$outputDir\$baseName.json"
    
    Write-Host "`n轉換: $file" -ForegroundColor Yellow
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  錯誤: 檔案不存在" -ForegroundColor Red
        $failed += $file
        continue
    }
    
    try {
        # 讀取CQL
        $cqlContent = Get-Content $sourcePath -Raw -Encoding UTF8
        
        # 移除SQL部分
        if ($cqlContent -match '(?s)(-- .*?WITH quarters AS.*$)') {
            $cqlContent = $cqlContent -replace '(?s)(-- .*?WITH quarters AS.*$)', "`n// SQL removed`n"
            Write-Host "  已移除SQL代碼" -ForegroundColor Gray
        }
        
        # 準備請求
        $jsonBody = @{
            code = $cqlContent
        } | ConvertTo-Json -Depth 10
        
        # 調用API
        $response = Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" `
            -Method POST `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($jsonBody))
        
        # 保存結果
        if ($response) {
            $elmJson = $response | ConvertTo-Json -Depth 100
            [System.IO.File]::WriteAllText($outputPath, $elmJson, [System.Text.Encoding]::UTF8)
            
            $size = (Get-Item $outputPath).Length
            Write-Host "  成功: $([math]::Round($size/1KB, 2)) KB" -ForegroundColor Green
            $success += $file
        } else {
            Write-Host "  錯誤: 無回應" -ForegroundColor Red
            $failed += $file
        }
    }
    catch {
        Write-Host "  錯誤: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $file
    }
}

Write-Host "`n=== 完成 ===" -ForegroundColor Cyan
Write-Host "成功: $($success.Count)/$($files.Count)" -ForegroundColor Green
Write-Host "失敗: $($failed.Count)/$($files.Count)" -ForegroundColor $(if ($failed.Count -eq 0) { "Green" } else { "Red" })

if ($success.Count -gt 0) {
    Write-Host "`n成功:" -ForegroundColor Green
    $success | ForEach-Object { Write-Host "  $_" }
}

if ($failed.Count -gt 0) {
    Write-Host "`n失敗:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  $_" }
}
