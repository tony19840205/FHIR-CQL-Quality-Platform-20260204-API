# Upload Knee Arthroplasty Deep Infection test data
# Indicator 15-1: Deep Infection Rate within 90 Days after Total Knee Arthroplasty
# 5 patients with total knee arthroplasty
# 2 patients with deep infection within 90 days
# Total: 23 resources (2 patients × 6 resources + 3 patients × 3 resources + 2 additional encounters)

$baseUrl = "https://thas.mohw.gov.tw/v/r4/fhir"
$jsonFile = "Knee_Arthroplasty_Infection_5_Patients.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳 膝關節置換90日內深部感染率 指標測試資料" -ForegroundColor Cyan
Write-Host "指標 15-1: 人工膝關節置換手術後九十日以內置換物深部感染率" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Read the JSON file
$bundle = Get-Content $jsonFile -Raw | ConvertFrom-Json

$totalResources = $bundle.entry.Count
Write-Host "總共要上傳 $totalResources 個資源" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0
$currentResource = 0

# Upload each resource
foreach ($entry in $bundle.entry) {
    $currentResource++
    $resource = $entry.resource
    $resourceType = $resource.resourceType
    $resourceId = $resource.id
    
    Write-Host "[$currentResource/$totalResources] 上傳 $resourceType/$resourceId ..." -NoNewline
    
    $url = "$baseUrl/$resourceType/$resourceId"
    $body = $resource | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Put -Body $body -ContentType "application/fhir+json; charset=utf-8"
        Write-Host " ✓ 成功" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " ✗ 失敗" -ForegroundColor Red
        Write-Host "  錯誤: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
    
    # Add delay between uploads
    if ($currentResource -lt $totalResources) {
        Start-Sleep -Seconds 2
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳完成" -ForegroundColor Cyan
Write-Host "成功: $successCount" -ForegroundColor Green
Write-Host "失敗: $failCount" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
