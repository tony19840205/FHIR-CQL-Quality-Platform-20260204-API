# 修復 JavaScript 檔案編碼問題

$jsFile = "C:\Users\tony1\OneDrive\桌面\UI UX-20251122(0013)\UI UX\FHIR-Dashboard-App\js\quality-indicators.js"

Write-Host "=== 修復 JavaScript 編碼問題 ===" -ForegroundColor Cyan
Write-Host ""

# 讀取檔案
Write-Host "1. 讀取原始檔案..." -ForegroundColor Yellow
try {
    $bytes = [System.IO.File]::ReadAllBytes($jsFile)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    
    Write-Host "   檔案大小: $($bytes.Length) bytes" -ForegroundColor Gray
    Write-Host "   字元數: $($content.Length)" -ForegroundColor Gray
    
    # 檢查是否有問號亂碼
    $hasGarbage = $content -match '\?��'
    if ($hasGarbage) {
        Write-Host "   ✗ 發現編碼錯誤!" -ForegroundColor Red
        
        # 嘗試用不同編碼讀取
        Write-Host ""
        Write-Host "2. 嘗試修復..." -ForegroundColor Yellow
        
        # 方法1: 嘗試 Big5 編碼
        try {
            $big5 = [System.Text.Encoding]::GetEncoding("Big5")
            $contentBig5 = $big5.GetString($bytes)
            
            if ($contentBig5 -notmatch '\?��') {
                Write-Host "   ✓ Big5 編碼成功!" -ForegroundColor Green
                $content = $contentBig5
            }
        } catch {
            Write-Host "   ✗ Big5 編碼失敗" -ForegroundColor Red
        }
        
        # 方法2: 移除所有非 ASCII 和非中文字元的問號亂碼
        if ($content -match '\?��') {
            Write-Host "   嘗試移除亂碼..." -ForegroundColor Yellow
            $content = $content -replace '\?[��]+', ''
            Write-Host "   ✓ 已移除亂碼" -ForegroundColor Green
        }
    } else {
        Write-Host "   ✓ 編碼正常" -ForegroundColor Green
    }
    
    # 儲存為 UTF-8 without BOM
    Write-Host ""
    Write-Host "3. 儲存為 UTF-8..." -ForegroundColor Yellow
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($jsFile, $content, $utf8NoBom)
    
    Write-Host "   ✓ 檔案已修復!" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "=== 修復完成 ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步:" -ForegroundColor Cyan
    Write-Host "1. 按 Ctrl+Shift+Delete 清除瀏覽器緩存" -ForegroundColor Yellow
    Write-Host "2. 重新開啟 quality-indicators.html" -ForegroundColor Yellow
    Write-Host "3. 按 F12 打開開發者工具檢查是否還有錯誤" -ForegroundColor Yellow
    
} catch {
    Write-Host "✗ 修復失敗: $($_.Exception.Message)" -ForegroundColor Red
}
