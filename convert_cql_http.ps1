# CQL to ELM JSON converter using HTTP API
$cqlFile = "cql\Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql"
$outputFile = "ELM_JSON_OFFICIAL\舊50\Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.json"

Write-Host "Reading CQL file..." -ForegroundColor Cyan
$cqlContent = Get-Content $cqlFile -Raw -Encoding UTF8

Write-Host "Converting CQL to ELM..." -ForegroundColor Cyan

# Method 1: Try cql.hl7.org
try {
    Write-Host "Trying https://cql.hl7.org/translator..." -ForegroundColor Yellow
    $uri = "https://cql.hl7.org/translator"
    
    $headers = @{
        "Content-Type" = "application/cql"
        "Accept" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $cqlContent -Headers $headers
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "✓ 轉換成功！" -ForegroundColor Green
    Write-Host "Output: $outputFile" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "Method 1 failed: $_" -ForegroundColor Red
}

# Method 2: Try localhost
try {
    Write-Host "Trying localhost:8080..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" -Method Post -Body $cqlContent -ContentType "application/cql"
    $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "✓ 轉換成功！" -ForegroundColor Green
    Write-Host "Output: $outputFile" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "Method 2 failed: $_" -ForegroundColor Red
}

Write-Host "`n✗ 所有方法都失敗" -ForegroundColor Red
Write-Host "請確認:" -ForegroundColor Yellow
Write-Host "1. CQL語法正確" -ForegroundColor Yellow
Write-Host "2. Docker服務運行中 (docker ps)" -ForegroundColor Yellow
Write-Host "3. 網路連線正常" -ForegroundColor Yellow
