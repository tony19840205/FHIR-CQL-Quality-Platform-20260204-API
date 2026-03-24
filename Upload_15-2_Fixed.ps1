# 15-2指標測試資料上傳腳本
# 檔案: test_data_15_2_FIXED_with_identifier.json
# 目標: 修正Patient缺少identifier的問題

$fhirServer = "http://140.115.3.180:8082/fhir"
$bundleFile = "test_data_15_2_FIXED_with_identifier.json"

Write-Host "=== 15-2指標測試資料上傳 ===" -ForegroundColor Cyan
Write-Host ""

# 檢查檔案是否存在
if (-not (Test-Path $bundleFile)) {
    Write-Host "✗ 錯誤: 找不到檔案 $bundleFile" -ForegroundColor Red
    exit 1
}

# 讀取Bundle
Write-Host "讀取測試資料..." -ForegroundColor Yellow
$bundle = Get-Content $bundleFile -Raw -Encoding UTF8

# 顯示資料摘要
$bundleObj = $bundle | ConvertFrom-Json
$resourceCount = $bundleObj.entry.Count
Write-Host "✓ Bundle包含 $resourceCount 個資源" -ForegroundColor Green

# 統計資源類型
$resourceTypes = @{}
foreach ($entry in $bundleObj.entry) {
    $type = $entry.resource.resourceType
    if ($resourceTypes.ContainsKey($type)) {
        $resourceTypes[$type]++
    } else {
        $resourceTypes[$type] = 1
    }
}

Write-Host ""
Write-Host "資源統計:" -ForegroundColor Cyan
foreach ($type in $resourceTypes.Keys) {
    Write-Host "  $type : $($resourceTypes[$type])" -ForegroundColor White
}

Write-Host ""
Write-Host "預期結果:" -ForegroundColor Cyan
Write-Host "  分母: 6個TKA手術" -ForegroundColor White
Write-Host "  分子: 2個感染處理（TW10001, TW10003）" -ForegroundColor White
Write-Host "  感染率: 33.33%" -ForegroundColor White

Write-Host ""
$confirm = Read-Host "確定要上傳到 $fhirServer 嗎? (y/n)"

if ($confirm -ne 'y') {
    Write-Host "已取消上傳" -ForegroundColor Yellow
    exit 0
}

# 上傳
Write-Host ""
Write-Host "正在上傳..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri $fhirServer `
        -Method Post `
        -Body $bundle `
        -ContentType "application/json; charset=utf-8" `
        -TimeoutSec 60
    
    Write-Host ""
    Write-Host "✓ 上傳成功!" -ForegroundColor Green
    Write-Host ""
    
    # 顯示回應摘要
    if ($response.resourceType -eq "Bundle") {
        $successCount = 0
        $errorCount = 0
        
        foreach ($entry in $response.entry) {
            if ($entry.response.status -match "^20") {
                $successCount++
            } else {
                $errorCount++
            }
        }
        
        Write-Host "處理結果:" -ForegroundColor Cyan
        Write-Host "  成功: $successCount" -ForegroundColor Green
        Write-Host "  失敗: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
    }
    
    Write-Host ""
    Write-Host "下一步驗證:" -ForegroundColor Cyan
    Write-Host "1. 開啟 quality-indicators.html" -ForegroundColor White
    Write-Host "2. 選擇 '15-2 全人工膝關節置換90天深部感染率'" -ForegroundColor White
    Write-Host "3. 點擊 '執行查詢'" -ForegroundColor White
    Write-Host "4. 檢查結果是否為: 分母=6, 分子=2, 感染率=33.33%" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "✗ 上傳失敗!" -ForegroundColor Red
    Write-Host "錯誤: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host ""
        Write-Host "伺服器回應:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== 完成 ===" -ForegroundColor Cyan
