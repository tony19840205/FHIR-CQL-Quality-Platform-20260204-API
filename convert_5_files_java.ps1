# 批量轉換5個CQL文件到官方ELM JSON (使用Java工具)

$files = @(
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql',
    'Waste.cql'
)

$tempDir = ".\cql_batch_temp"
$outputDir = ".\ELM_JSON_OFFICIAL\舊50"

# 創建目錄
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$success = @()
$failed = @()

Write-Host "`n=== 批量轉換CQL到官方ELM JSON ===" -ForegroundColor Cyan

foreach ($file in $files) {
    Write-Host "`n處理: $file" -ForegroundColor Yellow
    
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $sourcePath = ".\cql\$file"
    $tempPath = "$tempDir\$file"
    $outputPath = "$outputDir\$baseName.json"
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  ✗ 源文件不存在" -ForegroundColor Red
        $failed += @{ File = $file; Error = "源文件不存在" }
        continue
    }
    
    # 讀取並修復CQL
    $content = [System.IO.File]::ReadAllText($sourcePath, [System.Text.Encoding]::UTF8)
    
    # 移除SQL代碼
    if ($content -match '(?s)((?:^|\n)(?:--\s*)?WITH quarters AS.*?$)') {
        $sqlPart = $matches[1]
        $content = $content -replace [regex]::Escape($sqlPart), "`n// SQL邏輯已移除，請使用FHIR查詢`n"
        Write-Host "  ✓ 已移除SQL代碼" -ForegroundColor Green
    }
    
    # 保存修復後的CQL
    [System.IO.File]::WriteAllText($tempPath, $content, [System.Text.Encoding]::UTF8)
    
    # 使用Java轉換
    try {
        $javaCmd = "java -jar cql-to-elm.jar ""$tempPath"" --format=JSON --output ""$outputPath"" 2>&1"
        $result = Invoke-Expression $javaCmd
        
        if (Test-Path $outputPath) {
            $size = (Get-Item $outputPath).Length
            Write-Host "  ✓ 轉換成功: $([math]::Round($size/1KB, 2)) KB" -ForegroundColor Green
            $success += $file
        } else {
            Write-Host "  ✗ 轉換失敗" -ForegroundColor Red
            Write-Host "  $result" -ForegroundColor Gray
            $failed += @{ File = $file; Error = "轉換失敗" }
        }
    } catch {
        Write-Host "  ✗ 錯誤: $($_.Exception.Message)" -ForegroundColor Red
        $failed += @{ File = $file; Error = $_.Exception.Message }
    }
}

# 清理臨時目錄
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# 顯示結果
Write-Host "`n=== 轉換結果 ===" -ForegroundColor Green -BackgroundColor Black
Write-Host "成功: $($success.Count)" -ForegroundColor Green
Write-Host "失敗: $($failed.Count)" -ForegroundColor Red

if ($success.Count -gt 0) {
    Write-Host "`n成功轉換的文件:" -ForegroundColor Green
    $success | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor White }
}

if ($failed.Count -gt 0) {
    Write-Host "`n失敗的文件:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  ✗ $($_.File): $($_.Error)" -ForegroundColor White }
}
