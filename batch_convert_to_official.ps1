# 批量轉換CQL到官方ELM JSON
param(
    [string[]]$Files
)

$tempDir = ".\cql_batch_temp"
$outputDir = ".\ELM_JSON_OFFICIAL\舊50"

# 創建臨時和輸出目錄
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$success = @()
$failed = @()

foreach ($file in $Files) {
    Write-Host "`n處理: $file" -ForegroundColor Yellow
    
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $sourcePath = ".\cql\$file"
    $tempPath = "$tempDir\$file"
    
    # 讀取並修復CQL
    $content = Get-Content $sourcePath -Raw -Encoding UTF8
    
    # 移除SQL代碼（從WITH開始到最後的SELECT）
    if ($content -match '(?s)(-- .*?WITH quarters AS.*?ORDER BY[^;]+;?\s*$)') {
        $sqlPart = $matches[1]
        $content = $content -replace [regex]::Escape($sqlPart), "`n// SQL邏輯已移除，請使用FHIR查詢`n"
        Write-Host "   已移除SQL代碼" -ForegroundColor Green
    }
    
    # 保存修復後的CQL
    [System.IO.File]::WriteAllText($tempPath, $content, [System.Text.Encoding]::UTF8)
    
    # 轉換為ELM JSON
    try {
        $result = gradle run --args="$tempPath --format=JSON --output-file=$outputDir\$baseName.json --date-range-optimization=false --annotations --locators --result-types --detailed-errors --disable-list-traversal --disable-list-demotion --disable-list-promotion --disable-method-invocation --enable-annotations --signatures=Overloads" 2>&1
        
        if (Test-Path "$outputDir\$baseName.json") {
            $size = (Get-Item "$outputDir\$baseName.json").Length
            Write-Host "   轉換成功: $([math]::Round($size/1KB, 2)) KB" -ForegroundColor Green
            $success += $file
        } else {
            Write-Host "   轉換失敗" -ForegroundColor Red
            $failed += $file
        }
    } catch {
        Write-Host "   錯誤: $_" -ForegroundColor Red
        $failed += $file
    }
}

# 清理臨時目錄
Remove-Item $tempDir -Recurse -Force

# 顯示結果
Write-Host "`n=== 轉換結果 ===" -ForegroundColor Green
Write-Host "成功: $($success.Count)" -ForegroundColor Green
Write-Host "失敗: $($failed.Count)" -ForegroundColor Red

if ($failed.Count -gt 0) {
    Write-Host "`n失敗的文件:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" }
}
