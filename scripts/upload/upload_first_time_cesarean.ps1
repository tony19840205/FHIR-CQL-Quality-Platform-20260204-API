# Upload First Time Cesarean Section test data
# Indicator 11-4: Cesarean Section Rate - First Time with Medical Indication
# 11 patients with first-time cesarean section (with medical indication)
# Total: 44 resources (11 patients × 4 resources each)

$baseUrl = "https://thas.mohw.gov.tw/v/r4/fhir"
$jsonFile = "First_Time_Cesarean_11_Patients.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "上傳 初產婦剖腹產率 指標測試資料" -ForegroundColor Cyan
Write-Host "指標 11-4: 初產婦剖腹產率" -ForegroundColor Cyan
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
