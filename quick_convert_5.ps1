# 快速轉換5個CQL - 使用線上API
$files = @(
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726',
    'Waste'
)

$outputDir = ".\ELM_JSON_OFFICIAL\舊50"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "`n=== 快速轉換5個CQL ===" -ForegroundColor Cyan
Write-Host "使用 CQL Runner API`n" -ForegroundColor Yellow

$success = 0
$failed = 0

foreach ($name in $files) {
    $cqlFile = ".\cql\$name.cql"
    $jsonFile = "$outputDir\$name.json"
    
    Write-Host "[$($success+$failed+1)/$($files.Count)] $name.cql" -ForegroundColor Cyan
    
    if (-not (Test-Path $cqlFile)) {
        Write-Host "  ✗ 文件不存在" -ForegroundColor Red
        $failed++
        continue
    }
    
    $cql = Get-Content $cqlFile -Raw -Encoding UTF8
    
    try {
        $body = @{ cql = $cql } | ConvertTo-Json
        
        $result = Invoke-RestMethod `
            -Uri "https://cql-runner.dataphoria.org/cql-to-elm" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -TimeoutSec 30
        
        $result | ConvertTo-Json -Depth 100 | Out-File $jsonFile -Encoding UTF8
        
        $size = [math]::Round((Get-Item $jsonFile).Length / 1KB, 2)
        Write-Host "  ✓ $size KB" -ForegroundColor Green
        $success++
    }
    catch {
        Write-Host "  ✗ 失敗: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n結果: 成功 $success / 失敗 $failed" -ForegroundColor Cyan
