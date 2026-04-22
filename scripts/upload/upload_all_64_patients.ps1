# 批次上傳待上傳的 64 位病人資料
# 目標伺服器: EMR-Smart (https://emr-smart.appx.com.tw/v/r4/fhir)

$baseUrl = "https://emr-smart.appx.com.tw/v/r4/fhir"

$files = @(
    @{Name="ESWL_5_Patients.json"; Patients=5; ResourceCount=20; Batch=1},
    @{Name="Surgical_Wound_Infection_15_Patients.json"; Patients=15; ResourceCount=47; Batch=2},
    @{Name="Dementia_Hospice_19_Patients.json"; Patients=19; ResourceCount=51; Batch=3},
    @{Name="Knee_Arthroplasty_Infection_5_Patients.json"; Patients=5; ResourceCount=23; Batch=4},
    @{Name="Same_Hospital_Antihypertensive_Overlap_4_Patients.json"; Patients=4; ResourceCount=21; Batch=5},
    @{Name="Cesarean_With_Indication_5_Patients.json"; Patients=5; ResourceCount=20; Batch=6},
    @{Name="First_Time_Cesarean_11_Patients.json"; Patients=11; ResourceCount=44; Batch=7}
)

$totalSuccess = 0
$totalError = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "批次上傳 64 位病人資料 (226 resources) 到 EMR-Smart" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($file in $files) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "批次 $($file.Batch)/7: $($file.Name)" -ForegroundColor Cyan
    Write-Host "$($file.Patients) 位病人, $($file.ResourceCount) resources" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    if (-not (Test-Path $file.Name)) {
        Write-Host "X 檔案不存在，跳過" -ForegroundColor Red
        continue
    }
    
    $json = Get-Content $file.Name -Raw -Encoding UTF8 | ConvertFrom-Json
    $successCount = 0
    $errorCount = 0
    
    foreach ($entry in $json.entry) {
        $resource = $entry.resource
        $request = $entry.request
        
        Write-Host "[$($successCount+$errorCount+1)/$($file.ResourceCount)] $($resource.resourceType)/$($resource.id)" -NoNewline
        
        try {
            $resourceJson = $resource | ConvertTo-Json -Depth 10 -Compress
            $url = "$baseUrl/$($request.url)"
            
            $result = Invoke-RestMethod -Uri $url -Method Put -Body $resourceJson -ContentType "application/fhir+json; charset=utf-8"
            
            Write-Host " OK" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host " FAIL" -ForegroundColor Red
            $errorCount++
        }
        
        Start-Sleep -Seconds 2
    }
    
    $totalSuccess += $successCount
    $totalError += $errorCount
    
    Write-Host "`n批次結果: OK $successCount / FAIL $errorCount" -ForegroundColor $(if($errorCount -eq 0){"Green"}else{"Yellow"})
    
    if ($file.Batch -lt 7) {
        Write-Host "`n等待 5 秒後繼續下一批次..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "上傳完成統計" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "總計: OK $totalSuccess / FAIL $totalError" -ForegroundColor $(if($totalError -eq 0){"Green"}else{"Yellow"})
Write-Host "64 位病人 / 226 resources" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($totalError -eq 0) {
    Write-Host "全部上傳成功！" -ForegroundColor Green
} else {
    Write-Host "有 $totalError 個資源上傳失敗，請檢查錯誤訊息" -ForegroundColor Yellow
}
