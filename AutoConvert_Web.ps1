# 線上工具批量轉換輔助腳本
# 配合 https://cql.dataphoria.org/ 使用

param(
    [string]$CqlFolder = "cql",
    [string]$OutputFolder = "ELM_JSON_OFFICIAL\web_converted"
)

Write-Host "`n=== CQL線上轉換輔助工具 ===" -ForegroundColor Cyan
Write-Host "使用網站: https://cql.dataphoria.org/`n" -ForegroundColor Yellow

# 確保輸出目錄存在
if (-not (Test-Path $OutputFolder)) {
    New-Item $OutputFolder -ItemType Directory -Force | Out-Null
}

$files = Get-ChildItem $CqlFolder -Filter "*.cql"
Write-Host "找到 $($files.Count) 個CQL文件`n" -ForegroundColor Cyan
Write-Host "=" * 70

$completed = 0
$skipped = 0

foreach ($file in $files) {
    $outFile = Join-Path $OutputFolder "$($file.BaseName).json"
    
    # 檢查是否已轉換
    if (Test-Path $outFile) {
        Write-Host "[$($completed+$skipped+1)/$($files.Count)] $($file.Name) - 已存在，跳過" -ForegroundColor Gray
        $skipped++
        continue
    }
    
    Write-Host "`n[$($completed+$skipped+1)/$($files.Count)] $($file.Name)" -ForegroundColor Cyan
    Write-Host "=" * 70
    
    # 讀取並複製CQL到剪貼簿
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    Set-Clipboard $content
    
    Write-Host "`n✅ CQL代碼已複製到剪貼簿" -ForegroundColor Green
    Write-Host "`n請執行以下步驟:" -ForegroundColor Yellow
    Write-Host "  1. 確保瀏覽器已開啟 https://cql.dataphoria.org/" -ForegroundColor White
    Write-Host "  2. 在左側編輯器貼上CQL代碼 (Ctrl+V)" -ForegroundColor White
    Write-Host "  3. 點擊 'Translate to ELM' 按鈕" -ForegroundColor White
    Write-Host "  4. 等待右側顯示JSON結果" -ForegroundColor White
    Write-Host "  5. 複製整個JSON結果 (Ctrl+A, Ctrl+C)" -ForegroundColor White
    Write-Host "  6. 回到此視窗按Enter" -ForegroundColor White
    
    Read-Host "`n按Enter表示已複製JSON結果"
    
    # 從剪貼簿讀取JSON
    $json = Get-Clipboard
    
    # 驗證是否為有效的ELM JSON
    if ($json -match '"library"' -and $json -match '"identifier"') {
        $json | Out-File $outFile -Encoding UTF8
        $sizeKB = [math]::Round((Get-Item $outFile).Length / 1KB, 2)
        Write-Host "`n✅ 已保存: $sizeKB KB" -ForegroundColor Green
        $completed++
    } else {
        Write-Host "`n❌ 剪貼簿內容不是有效的ELM JSON" -ForegroundColor Red
        Write-Host "請確認已複製JSON結果，然後重試" -ForegroundColor Yellow
        
        $retry = Read-Host "重試此文件? (y/n)"
        if ($retry -eq 'y') {
            # 重新處理當前文件
            continue
        } else {
            Write-Host "跳過此文件" -ForegroundColor Yellow
            $skipped++
        }
    }
}

Write-Host "`n" + ("=" * 70)
Write-Host "`n轉換結果:" -ForegroundColor Cyan
Write-Host "  ✅ 完成: $completed" -ForegroundColor Green
Write-Host "  ⏭️  跳過: $skipped" -ForegroundColor Gray
Write-Host "  📁 輸出: $OutputFolder" -ForegroundColor Cyan

if ($completed -gt 0) {
    Write-Host "`n✅ 批量轉換完成！" -ForegroundColor Green
}

# 恢復原DNS設置（可選）
Write-Host "`n提示: DNS已修改為Google DNS" -ForegroundColor Yellow
$restore = Read-Host "是否恢復原DNS設置? (y/n)"
if ($restore -eq 'y') {
    try {
        Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("10.30.11.2", "8.8.8.8", "168.95.1.1")
        Write-Host "✅ DNS已恢復" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  需要管理員權限" -ForegroundColor Yellow
    }
}
