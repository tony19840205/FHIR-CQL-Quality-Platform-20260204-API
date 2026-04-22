# 分批上傳完整測試資料到 FHIR 伺服器
# 總計: 3480 筆資源 (每批 500 筆)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FHIR 測試資料分批上傳工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: 收集所有測試資料
Write-Host "Step 1: 收集所有測試資料..." -ForegroundColor Yellow
$allEntries = @()

# 載入645人完整包
foreach ($folder in @(
    "FHIR_測試資料_完整包_645人_2025-12-08\A_CGMH大批資料_508人",
    "FHIR_測試資料_完整包_645人_2025-12-08\B_HAPI小批資料_49人",
    "FHIR_測試資料_完整包_645人_2025-12-08\C_Dashboard資料_64人",
    "FHIR_測試資料_完整包_645人_2025-12-08\D_根目錄測試_24人"
)) {
    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Filter "*.json" -Recurse | ForEach-Object {
            try {
                $content = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($content.entry) {
                    $allEntries += $content.entry
                }
            } catch {}
        }
    }
}

# 載入根目錄測試檔案
Get-ChildItem -Filter "*.json" | Where-Object { 
    $_.Name -match "^(test_|cesarean_|fibroid_|eswl_)" -and 
    $_.Name -ne "complete_test_data_bundle.json" 
} | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($content.entry) {
            $allEntries += $content.entry
        }
    } catch {}
}

Write-Host "  收集完成: $($allEntries.Count) 筆資源" -ForegroundColor Green
Write-Host ""

# Step 2: 分批上傳
Write-Host "Step 2: 開始分批上傳..." -ForegroundColor Yellow
Write-Host "  伺服器: https://thas.mohw.gov.tw/v/r4/fhir" -ForegroundColor Gray
Write-Host "  批次大小: 500 筆/批" -ForegroundColor Gray
Write-Host ""

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$batchSize = 500
$totalBatches = [math]::Ceiling($allEntries.Count / $batchSize)
$uploaded = 0
$failed = 0

for ($i = 0; $i -lt $totalBatches; $i++) {
    $start = $i * $batchSize
    $end = [math]::Min(($i + 1) * $batchSize, $allEntries.Count)
    $batch = $allEntries[$start..($end-1)]
    
    $bundle = @{
        resourceType = "Bundle"
        type = "transaction"
        entry = $batch
    } | ConvertTo-Json -Depth 20 -Compress
    
    Write-Host "  批次 $($i+1)/$totalBatches : 上傳 $($batch.Count) 筆資源..." -NoNewline
    
    try {
        $response = Invoke-RestMethod -Uri 'https://thas.mohw.gov.tw/v/r4/fhir' `
                                      -Method Post `
                                      -Body $bundle `
                                      -ContentType 'application/fhir+json' `
                                      -TimeoutSec 300
        
        $uploaded += $response.entry.Count
        Write-Host " ✓ 成功 (累計: $uploaded)" -ForegroundColor Green
        
        # 避免請求太快
        Start-Sleep -Milliseconds 500
        
    } catch {
        $failed += $batch.Count
        Write-Host " ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  成功上傳: $uploaded 筆" -ForegroundColor Green
Write-Host "  失敗: $failed 筆" -ForegroundColor Red
Write-Host "  總計: $($allEntries.Count) 筆" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "按任意鍵關閉..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
