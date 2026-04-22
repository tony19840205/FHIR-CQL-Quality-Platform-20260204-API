# 整合所有測試資料
$allEntries = @()

# 1. 載入645人完整包中的資料
Write-Host "正在載入 645人完整包..."
$folders = @(
    "FHIR_測試資料_完整包_645人_2025-12-08\A_CGMH大批資料_508人",
    "FHIR_測試資料_完整包_645人_2025-12-08\B_HAPI小批資料_49人", 
    "FHIR_測試資料_完整包_645人_2025-12-08\C_Dashboard資料_64人",
    "FHIR_測試資料_完整包_645人_2025-12-08\D_根目錄測試_24人"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        $jsonFiles = Get-ChildItem -Path $folder -Filter "*.json" -Recurse
        foreach ($file in $jsonFiles) {
            try {
                $content = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($content.entry) {
                    $allEntries += $content.entry
                    Write-Host "   $($file.Name): $($content.entry.Count) 筆資源"
                }
            } catch {
                Write-Host "   無法讀取: $($file.Name)"
            }
        }
    }
}

# 2. 載入根目錄的昨天新增測試資料
Write-Host "`n正在載入昨天新增的測試資料..."
$recentFiles = @(
    "eswl_q4_2025.json",
    "fibroid_fixed.json", 
    "cesarean_complete_q4.json",
    "cesarean_snomed.json",
    "test_data_antihypertensive_overlap_3_patients.json",
    "test_data_eswl_3_patients.json",
    "test_data_3day_ed_6_patients.json"
)

foreach ($fileName in $recentFiles) {
    if (Test-Path $fileName) {
        try {
            $content = Get-Content $fileName -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($content.entry) {
                $allEntries += $content.entry
                Write-Host "   $fileName: $($content.entry.Count) 筆資源"
            }
        } catch {
            Write-Host "   無法讀取: $fileName"
        }
    }
}

# 3. 建立完整Bundle
$bundle = @{
    resourceType = "Bundle"
    type = "transaction"
    entry = $allEntries
}

$json = $bundle | ConvertTo-Json -Depth 20 -Compress:$false
$json | Out-File -FilePath "complete_test_data_bundle.json" -Encoding UTF8

Write-Host "`n=========================================="
Write-Host " 整合完成！"
Write-Host "總資源數量: $($allEntries.Count)"
Write-Host "輸出檔案: complete_test_data_bundle.json"
Write-Host "檔案大小: $([math]::Round((Get-Item complete_test_data_bundle.json).Length / 1MB, 2)) MB"
Write-Host "=========================================="
