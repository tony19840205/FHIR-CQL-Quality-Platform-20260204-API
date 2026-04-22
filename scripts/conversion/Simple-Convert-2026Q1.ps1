# Simple Date Replacement Script for 2026 Q1
# Uses text replacement to convert dates

$BaseDir = "c:\Users\tony1\Desktop\UI UX-20251218(2313) - MIKE"
$OutputDir = Join-Path $BaseDir "2026Q1_Medical_Quality_Test_Data"

Write-Host "Simple Date Conversion - 2026 Q1" -ForegroundColor Yellow
Write-Host "Target: 2026-01-01 to 2026-01-15`n" -ForegroundColor Green

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Find files
$files = Get-ChildItem -Path $BaseDir -Filter "*.json" | Where-Object {
    $_.Name -match "test_data|Cesarean|ESWL|Dementia|Fibroid|Knee|Surgical|First_Time|Same_Hospital" -and
    $_.Name -notmatch "complete_test_data|eswl_query|cors|_2026Q1|conversion_log"
}

Write-Host "Found $($files.Count) files`n"

$success = 0
foreach ($file in $files) {
    try {
        Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan
        
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        
        # Replace 2025-10 dates -> 2026-01 (days 1-5)
        $content = $content -replace '2025-10-0([1-6])', '2026-01-01'
        $content = $content -replace '2025-10-0([789])', '2026-01-02'
        $content = $content -replace '2025-10-1([0-3])', '2026-01-03'
        $content = $content -replace '2025-10-1([4-7])', '2026-01-04'
        $content = $content -replace '2025-10-(1[89]|2[0-9]|3[01])', '2026-01-05'
        
        # Replace 2025-11 dates -> 2026-01 (days 6-10)
        $content = $content -replace '2025-11-0([1-6])', '2026-01-06'
        $content = $content -replace '2025-11-0([789])', '2026-01-07'
        $content = $content -replace '2025-11-1([0-3])', '2026-01-08'
        $content = $content -replace '2025-11-1([4-7])', '2026-01-09'
        $content = $content -replace '2025-11-(1[89]|2[0-9]|30)', '2026-01-10'
        
        # Replace 2025-12 dates -> 2026-01 (days 11-15)
        $content = $content -replace '2025-12-0([1-6])', '2026-01-11'
        $content = $content -replace '2025-12-0([789])', '2026-01-12'
        $content = $content -replace '2025-12-1([0-3])', '2026-01-13'
        $content = $content -replace '2025-12-1([4-7])', '2026-01-14'
        $content = $content -replace '2025-12-(1[89]|2[0-9]|3[01])', '2026-01-15'
        
        $newName = $file.Name -replace '_2025Q4', '' -replace '2025Q4', '' -replace '\.json$', '_2026Q1.json'
        $outPath = Join-Path $OutputDir $newName
        
        $content | Set-Content $outPath -Encoding UTF8
        
        Write-Host "  -> Saved: $newName" -ForegroundColor Green
        $success++
    }
    catch {
        Write-Host "  -> Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nConversion Complete!" -ForegroundColor Green
Write-Host "Success: $success files" -ForegroundColor Green
Write-Host "Output: $OutputDir" -ForegroundColor Cyan
