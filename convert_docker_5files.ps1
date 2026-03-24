# 使用Docker轉換5個CQL文件到官方ELM JSON
# 創建日期: 2026-01-08

param(
    [switch]$KeepService
)

$files = @(
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql',
    'Waste.cql'
)

$outputDir = ".\ELM_JSON_OFFICIAL\舊50"
$success = @()
$failed = @()

Write-Host "`n=== 使用Docker轉換CQL到官方ELM JSON ===" -ForegroundColor Cyan
Write-Host "檔案數量: $($files.Count)" -ForegroundColor Yellow
Write-Host ("=" * 70) -ForegroundColor Gray

# 確保輸出目錄存在
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# 步驟1: 檢查Docker是否運行
Write-Host "`n[1/6] 檢查Docker..." -ForegroundColor Yellow
$dockerRunning = $false
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $dockerRunning = $true
        Write-Host "  ✓ Docker運行中" -ForegroundColor Green
    }
}
catch {
    $dockerRunning = $false
}

if (-not $dockerRunning) {
    Write-Host "  ✗ Docker Desktop未運行" -ForegroundColor Red
    Write-Host "  請先啟動Docker Desktop，然後重試" -ForegroundColor Yellow
    exit 1
}

# 步驟2: 清理舊容器
Write-Host "`n[2/6] 清理舊容器..." -ForegroundColor Yellow
try {
    $oldContainer = docker ps -a -q --filter "name=cql-service" 2>$null
    if ($oldContainer) {
        docker rm -f cql-service 2>&1 | Out-Null
        Write-Host "  ✓ 已移除舊容器" -ForegroundColor Green
    } else {
        Write-Host "  - 無舊容器" -ForegroundColor Gray
    }
}
catch {
    Write-Host "  - 跳過" -ForegroundColor Gray
}

# 步驟3: 拉取鏡像
Write-Host "`n[3/6] 拉取CQL轉換服務鏡像..." -ForegroundColor Yellow
Write-Host "  (首次運行可能需要幾分鐘)" -ForegroundColor Gray
docker pull cqframework/cql-translation-service:latest 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ 鏡像已就緒" -ForegroundColor Green
} else {
    Write-Host "  ✗ 鏡像拉取失敗" -ForegroundColor Red
    exit 1
}

# 步驟4: 啟動服務
Write-Host "`n[4/6] 啟動CQL轉換服務..." -ForegroundColor Yellow
$containerId = docker run -d -p 8080:8080 --name cql-service cqframework/cql-translation-service:latest 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ 容器已啟動" -ForegroundColor Green
    Write-Host "  等待服務就緒..." -ForegroundColor Gray
    Start-Sleep -Seconds 15
    
    # 測試服務
    $serviceReady = $false
    for ($i = 1; $i -le 10; $i++) {
        try {
            $test = Invoke-WebRequest -Uri "http://localhost:8080/cql/translator" -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
            $serviceReady = $true
            Write-Host "  ✓ 服務已就緒" -ForegroundColor Green
            break
        }
        catch {
            Start-Sleep -Seconds 3
        }
    }
    
    if (-not $serviceReady) {
        Write-Host "  ✗ 服務啟動超時" -ForegroundColor Red
        docker logs cql-service
        exit 1
    }
} else {
    Write-Host "  ✗ 容器啟動失敗" -ForegroundColor Red
    exit 1
}

# 步驟5: 批量轉換
Write-Host "`n[5/6] 批量轉換CQL文件..." -ForegroundColor Yellow
Write-Host ("=" * 70) -ForegroundColor Gray

foreach ($file in $files) {
    $cqlPath = ".\cql\$file"
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $outPath = "$outputDir\$baseName.json"
    
    Write-Host "`n  處理: $file" -ForegroundColor Cyan
    
    if (-not (Test-Path $cqlPath)) {
        Write-Host "    ✗ 源文件不存在" -ForegroundColor Red
        $failed += $file
        continue
    }
    
    # 讀取CQL
    $cqlContent = Get-Content $cqlPath -Raw -Encoding UTF8
    
    # 調用API
    try {
        $requestBody = @{ code = $cqlContent } | ConvertTo-Json
        
        $result = Invoke-RestMethod `
            -Uri "http://localhost:8080/cql/translator" `
            -Method POST `
            -ContentType "application/json; charset=utf-8" `
            -Body $requestBody `
            -TimeoutSec 60
        
        # 保存結果
        $result | ConvertTo-Json -Depth 100 | Out-File -FilePath $outPath -Encoding UTF8
        
        $size = [math]::Round((Get-Item $outPath).Length / 1KB, 2)
        Write-Host "    ✓ 成功: $size KB" -ForegroundColor Green
        $success += $file
    }
    catch {
        Write-Host "    ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $file
    }
}

# 步驟6: 清理
Write-Host "`n[6/6] 清理..." -ForegroundColor Yellow
if (-not $KeepService) {
    docker stop cql-service 2>&1 | Out-Null
    docker rm cql-service 2>&1 | Out-Null
    Write-Host "  ✓ 服務已停止並移除" -ForegroundColor Green
} else {
    Write-Host "  - 保留服務運行 (使用 -KeepService)" -ForegroundColor Gray
}

# 顯示結果
Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "=== 轉換結果 ===" -ForegroundColor Cyan
Write-Host "成功: $($success.Count) / $($files.Count)" -ForegroundColor $(if ($success.Count -eq $files.Count) { "Green" } else { "Yellow" })
Write-Host "失敗: $($failed.Count)" -ForegroundColor $(if ($failed.Count -eq 0) { "Green" } else { "Red" })

if ($success.Count -gt 0) {
    Write-Host "`n成功轉換:" -ForegroundColor Green
    foreach ($f in $success) {
        Write-Host "  ✓ $f" -ForegroundColor White
    }
}

if ($failed.Count -gt 0) {
    Write-Host "`n失敗文件:" -ForegroundColor Red
    foreach ($f in $failed) {
        Write-Host "  ✗ $f" -ForegroundColor White
    }
}

Write-Host "`n輸出目錄: $outputDir" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Gray
Write-Host ""
