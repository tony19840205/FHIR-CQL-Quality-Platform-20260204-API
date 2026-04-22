# Upload Same Hospital Antihypertensive Overlap Test Data (4 Patients)
# Indicator 03-1: 同院降血壓藥重疊 (1710)

$baseUrl = "https://thas.mohw.gov.tw/v/r4/fhir"
$jsonFile = "Same_Hospital_Antihypertensive_Overlap_4_Patients.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳 指標 03-1 (同院降血壓藥重疊) 測試資料" -ForegroundColor Cyan
Write-Host "4位病人 (全部為分子 - 降血壓藥重疊案件)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Read and parse JSON
$json = Get-Content $jsonFile -Raw -Encoding UTF8
$bundle = $json | ConvertFrom-Json

$successCount = 0
$errorCount = 0
$totalResources = $bundle.entry.Count

Write-Host "總資源數: $totalResources" -ForegroundColor Yellow
Write-Host ""

foreach ($entry in $bundle.entry) {
    $resource = $entry.resource
    $request = $entry.request
    $resourceType = $resource.resourceType
    $resourceId = $resource.id
    
    Write-Host "正在上傳: $resourceType/$resourceId" -ForegroundColor White
    
    try {
        $resourceJson = $resource | ConvertTo-Json -Depth 10 -Compress
        $url = "$baseUrl/$($request.url)"
        
        $response = Invoke-RestMethod -Uri $url -Method Put -Body $resourceJson -ContentType "application/fhir+json; charset=utf-8"
        
        Write-Host "✓ 成功上傳: $resourceType/$resourceId" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "✗ 上傳失敗: $resourceType/$resourceId" -ForegroundColor Red
        Write-Host "錯誤: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    # Delay between requests
    Start-Sleep -Seconds 2
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳完成" -ForegroundColor Cyan
Write-Host "成功: $successCount / $totalResources" -ForegroundColor Green
Write-Host "失敗: $errorCount / $totalResources" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
