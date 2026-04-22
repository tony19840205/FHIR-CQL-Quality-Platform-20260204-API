# 上傳完整測試資料到 FHIR 伺服器
# 總計: 3480 筆資源 (645人完整包 + 根目錄所有測試資料)

$serverUrl = "https://thas.mohw.gov.tw/v/r4/fhir"
$bundleFile = "complete_test_data_bundle.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FHIR 完整測試資料上傳工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "伺服器: $serverUrl" -ForegroundColor Yellow
Write-Host "資料檔案: $bundleFile" -ForegroundColor Yellow
Write-Host "總資源數: 3480 筆" -ForegroundColor Yellow
Write-Host ""

# 確認檔案存在
if (-not (Test-Path $bundleFile)) {
    Write-Host "❌ 錯誤: 找不到 $bundleFile" -ForegroundColor Red
    exit 1
}

$fileSize = [math]::Round((Get-Item $bundleFile).Length / 1MB, 2)
Write-Host "檔案大小: $fileSize MB" -ForegroundColor Green
Write-Host ""

# 詢問確認
Write-Host "⚠️  警告: 這將上傳 3480 筆資源到伺服器" -ForegroundColor Yellow
$confirm = Read-Host "是否繼續? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "已取消上傳" -ForegroundColor Gray
    exit 0
}

Write-Host ""
Write-Host "開始上傳..." -ForegroundColor Cyan

try {
    # 忽略 SSL 證書驗證
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    
    # 讀取 Bundle
    $bundle = Get-Content $bundleFile -Raw -Encoding UTF8
    
    # 上傳
    $response = Invoke-RestMethod -Uri $serverUrl `
                                  -Method Post `
                                  -Body $bundle `
                                  -ContentType 'application/fhir+json' `
                                  -TimeoutSec 300
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ 上傳成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "已上傳資源數: $($response.entry.Count)" -ForegroundColor Green
    Write-Host ""
    
    # 顯示資源類型統計
    $resourceTypes = $response.entry | Group-Object {$_.resource.resourceType} | Sort-Object Count -Descending
    Write-Host "資源類型統計:" -ForegroundColor Cyan
    foreach ($type in $resourceTypes) {
        Write-Host "  $($type.Name): $($type.Count)" -ForegroundColor White
    }
    
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ 上傳失敗" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "錯誤訊息: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "按任意鍵關閉..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
