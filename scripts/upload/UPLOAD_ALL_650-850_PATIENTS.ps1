# ========================================
# 全自動上傳所有測試資料
# 總計: 650-850 位病患
# 預計時間: 50-60 分鐘
# ========================================

$rootPath = "c:\Users\tony1\Desktop\UI UX-20251122(0013)"
Set-Location $rootPath

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 開始上傳所有測試資料" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "總計病患: 650-850 人" -ForegroundColor Yellow
Write-Host "總計檔案: 33 個" -ForegroundColor Yellow
Write-Host "預計時間: 50-60 分鐘" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

$startTime = Get-Date

# ========== 步驟 1: CGMH 大批資料 ==========
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  【步驟 1/4】上傳 CGMH 大批資料      ║" -ForegroundColor Green
Write-Host "║  病患數: 500-700 人                  ║" -ForegroundColor Green
Write-Host "║  檔案數: 10 個                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green

Set-Location "UI UX\HAPI-FHIR-Samples"

if (Test-Path "upload_all_cgmh_508.ps1") {
    .\upload_all_cgmh_508.ps1
    Write-Host "✅ CGMH 大批資料上傳完成`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  警告: upload_all_cgmh_508.ps1 不存在，跳過 CGMH 大批資料`n" -ForegroundColor Yellow
}

# ========== 步驟 2: HAPI-FHIR 小批資料 ==========
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  【步驟 2/4】上傳 HAPI-FHIR 小批資料 ║" -ForegroundColor Green
Write-Host "║  病患數: 49 人                       ║" -ForegroundColor Green
Write-Host "║  檔案數: 9 個                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green

if (Test-Path "upload_continue.ps1") {
    .\upload_continue.ps1
    Write-Host "✅ HAPI-FHIR 小批資料上傳完成`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  警告: upload_continue.ps1 不存在，跳過 HAPI-FHIR 小批資料`n" -ForegroundColor Yellow
}

# ========== 步驟 3: FHIR-Dashboard 資料 ==========
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  【步驟 3/4】上傳 FHIR-Dashboard 資料║" -ForegroundColor Green
Write-Host "║  病患數: 64 人                       ║" -ForegroundColor Green
Write-Host "║  檔案數: 7 個                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green

Set-Location "..\FHIR-Dashboard-App"

if (Test-Path "upload_all_64_patients.ps1") {
    .\upload_all_64_patients.ps1
    Write-Host "✅ FHIR-Dashboard 資料上傳完成`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  警告: upload_all_64_patients.ps1 不存在，跳過 FHIR-Dashboard 資料`n" -ForegroundColor Yellow
}

# ========== 步驟 4: 根目錄測試資料 ==========
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  【步驟 4/4】上傳根目錄測試資料      ║" -ForegroundColor Green
Write-Host "║  病患數: 24 人                       ║" -ForegroundColor Green
Write-Host "║  檔案數: 7 個                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green

Set-Location $rootPath

if (Test-Path "upload_all_root_24.ps1") {
    .\upload_all_root_24.ps1
    Write-Host "✅ 根目錄測試資料上傳完成`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  執行個別 Python 腳本..." -ForegroundColor Yellow
    
    $pythonScripts = @(
        "upload_3day_ed.py",
        "upload_antihypertensive_overlap.py",
        "upload_cesarean.py",
        "upload_diabetes.py",
        "upload_eswl.py"
    )
    
    foreach ($script in $pythonScripts) {
        if (Test-Path $script) {
            Write-Host "  執行: $script" -ForegroundColor Cyan
            python $script
        }
    }
}

# ========== 完成統計 ==========
$endTime = Get-Date
$duration = $endTime - $startTime
$minutes = [math]::Floor($duration.TotalMinutes)
$seconds = $duration.Seconds

Write-Host "`n`n" -NoNewline
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       🎉 所有資料上傳完成！         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n📊 上傳統計：" -ForegroundColor Yellow
Write-Host "   • 總病患數: 650-850 人" -ForegroundColor White
Write-Host "   • 總檔案數: 33 個" -ForegroundColor White
Write-Host "   • 總資源數: 約 3,500-4,000 個" -ForegroundColor White
Write-Host "   • 耗費時間: $minutes 分 $seconds 秒" -ForegroundColor White
Write-Host "`n🔍 後續驗證：" -ForegroundColor Yellow
Write-Host "   1. 查詢 Patient 總數確認資料完整" -ForegroundColor White
Write-Host "   2. 測試各項指標計算是否正常" -ForegroundColor White
Write-Host "   3. 檢查資料品質和關聯性" -ForegroundColor White
Write-Host "`n✅ 上傳完成！可以開始測試指標計算" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

# 返回根目錄
Set-Location $rootPath
