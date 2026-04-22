# FHIR 測試資料慢速上傳腳本
# 每批100筆資源，批次間延遲5秒

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$bundlePath = "complete_test_data_bundle.json"
$fhirServer = "https://thas.mohw.gov.tw/v/r4/fhir"
$batchSize = 100
$delaySeconds = 5

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FHIR 測試資料慢速上傳" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 讀取原始 Bundle
Write-Host "讀取資料..." -ForegroundColor Yellow
$bundle = Get-Content $bundlePath -Raw -Encoding UTF8 | ConvertFrom-Json
$allEntries = $bundle.entry

Write-Host "總資源數: $($allEntries.Count)" -ForegroundColor Green
Write-Host "批次大小: $batchSize" -ForegroundColor Green
Write-Host "批次延遲: ${delaySeconds}秒" -ForegroundColor Green
Write-Host ""

$totalBatches = [Math]::Ceiling($allEntries.Count / $batchSize)
$successCount = 0
$failCount = 0

for ($i = 0; $i -lt $totalBatches; $i++) {
    $startIndex = $i * $batchSize
    $endIndex = [Math]::Min($startIndex + $batchSize - 1, $allEntries.Count - 1)
    $currentBatchSize = $endIndex - $startIndex + 1
    
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "批次 $($i + 1)/$totalBatches" -ForegroundColor Cyan
    Write-Host "資源範圍: $startIndex ~ $endIndex (共 $currentBatchSize 筆)" -ForegroundColor White
    
    # 建立此批次的 Bundle
    $batchBundle = @{
        resourceType = "Bundle"
        type = "transaction"
        entry = $allEntries[$startIndex..$endIndex]
    }
    
    $batchJson = $batchBundle | ConvertTo-Json -Depth 20 -Compress
    
    try {
        Write-Host "上傳中..." -ForegroundColor Yellow -NoNewline
        
        $response = Invoke-RestMethod -Uri $fhirServer `
                                      -Method Post `
                                      -Body $batchJson `
                                      -ContentType 'application/fhir+json; charset=utf-8' `
                                      -TimeoutSec 300 `
                                      -ErrorAction Stop
        
        Write-Host " ✓ 成功" -ForegroundColor Green
        $successCount += $currentBatchSize
        
        if ($response.entry) {
            Write-Host "伺服器回應: $($response.entry.Count) 筆資源已處理" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host " ✗ 失敗" -ForegroundColor Red
        Write-Host "錯誤: $($_.Exception.Message)" -ForegroundColor Red
        $failCount += $currentBatchSize
        
        # 如果失敗，詢問是否繼續
        $continue = Read-Host "是否繼續下一批？(Y/N)"
        if ($continue -ne 'Y' -and $continue -ne 'y') {
            Write-Host "上傳中止" -ForegroundColor Yellow
            break
        }
    }
    
    # 延遲後再上傳下一批（最後一批不需要延遲）
    if ($i -lt $totalBatches - 1) {
        Write-Host "等待 ${delaySeconds}秒..." -ForegroundColor Gray
        Start-Sleep -Seconds $delaySeconds
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "成功: $successCount 筆" -ForegroundColor Green
Write-Host "失敗: $failCount 筆" -ForegroundColor Red
Write-Host "總計: $($allEntries.Count) 筆" -ForegroundColor White
