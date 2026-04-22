# 根目錄測試資料批次上傳
# 總計: 24 位病患

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "開始上傳根目錄測試資料（24 人）" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scripts = @(
    "upload_3day_ed.py",
    "upload_antihypertensive_overlap.py",
    "upload_cesarean.py",
    "upload_diabetes.py",
    "upload_eswl.py"
)

$totalScripts = $scripts.Count
$successCount = 0
$failCount = 0

foreach ($i in 0..($scripts.Count-1)) {
    $script = $scripts[$i]
    $scriptNumber = $i + 1
    
    Write-Host "`n【$scriptNumber/$totalScripts】執行: $script" -ForegroundColor Cyan
    
    if (-not (Test-Path $script)) {
        Write-Host "  ❌ 腳本不存在，跳過" -ForegroundColor Red
        $failCount++
        continue
    }
    
    try {
        python $script
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ 執行成功" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ❌ 執行失敗（Exit Code: $LASTEXITCODE）" -ForegroundColor Red
            $failCount++
        }
        
        # 等待 2 秒
        if ($scriptNumber -lt $totalScripts) {
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-Host "  ❌ 執行錯誤: $_" -ForegroundColor Red
        $failCount++
    }
}

# 顯示統計
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "上傳完成統計" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 成功: $successCount 個腳本" -ForegroundColor Green
Write-Host "❌ 失敗: $failCount 個腳本" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host "========================================`n" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "🎉 所有根目錄資料上傳完成！" -ForegroundColor Green
} else {
    Write-Host "⚠️  部分腳本執行失敗，請檢查錯誤訊息" -ForegroundColor Yellow
}
