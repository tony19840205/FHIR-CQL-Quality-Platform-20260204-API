# Quality Check for Indicator 15-2 ELM JSON

$file = "ELM_JSON_OFFICIAL\舊50\Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.json"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host " Indicator 15-2 ELM JSON Quality Check" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

if (!(Test-Path $file)) {
    Write-Host "`nERROR: File not found: $file" -ForegroundColor Red
    Write-Host "`nPlease complete the conversion first!" -ForegroundColor Yellow
    exit 1
}

# File info
$fileInfo = Get-Item $file
$sizeKB = $fileInfo.Length / 1KB
$lines = (Get-Content $file).Count

Write-Host "`nFile Information:" -ForegroundColor Cyan
Write-Host "  Path: $file" -ForegroundColor White
Write-Host "  Size: $($sizeKB.ToString('F2')) KB" -ForegroundColor White
Write-Host "  Lines: $lines" -ForegroundColor White
Write-Host "  Created: $($fileInfo.CreationTime)" -ForegroundColor White

# Quality checks
Write-Host "`nQuality Checks:" -ForegroundColor Cyan

$sizeOK = $sizeKB -ge 50
$linesOK = $lines -ge 1000

if ($sizeOK) {
    Write-Host "  OK Size >= 50 KB: $($sizeKB.ToString('F2')) KB" -ForegroundColor Green
} else {
    Write-Host "  WARNING Size < 50 KB: $($sizeKB.ToString('F2')) KB" -ForegroundColor Red
}

if ($linesOK) {
    Write-Host "  OK Lines >= 1000: $lines" -ForegroundColor Green
} else {
    Write-Host "  WARNING Lines < 1000: $lines" -ForegroundColor Red
}

# Parse JSON
try {
    $json = Get-Content $file -Raw | ConvertFrom-Json
    
    Write-Host "`nELM Structure:" -ForegroundColor Cyan
    
    if ($json.library) {
        Write-Host "  OK Library ID: $($json.library.identifier.id)" -ForegroundColor Green
        Write-Host "  OK Version: $($json.library.identifier.version)" -ForegroundColor Green
        
        if ($json.library.annotation -and $json.library.annotation.Count -gt 0) {
            $anno = $json.library.annotation[0]
            $translatorVersion = $anno.translatorVersion
            
            Write-Host "  Translator Version: $translatorVersion" -ForegroundColor $(if ($translatorVersion -like "*3.10*") { "Green" } else { "Yellow" })
            
            if ($anno.translatorOptions) {
                Write-Host "  Translator Options: $($anno.translatorOptions)" -ForegroundColor Gray
            }
            if ($anno.signatureLevel) {
                Write-Host "  Signature Level: $($anno.signatureLevel)" -ForegroundColor Gray
            }
        }
        
        # Check key definitions
        if ($json.library.statements -and $json.library.statements.def) {
            $stmts = $json.library.statements.def
            Write-Host "`nDefinitions ($($stmts.Count) total):" -ForegroundColor Cyan
            
            $keyDefs = @(
                "All TKA Procedures",
                "Valid Deep Infection Cases", 
                "Denominator",
                "Numerator",
                "Infection Rate",
                "Final Report"
            )
            
            foreach ($def in $keyDefs) {
                $found = $stmts | Where-Object { $_.name -eq $def }
                if ($found) {
                    Write-Host "  OK $def" -ForegroundColor Green
                } else {
                    Write-Host "  MISSING $def" -ForegroundColor Red
                }
            }
        }
        
        # Compare with 15-1
        $ref15_1 = "ELM_JSON_OFFICIAL\舊50\Indicator_15_1_Knee_Arthroplasty_90Day_Deep_Infection_353_01.json"
        if (Test-Path $ref15_1) {
            $ref15_1Info = Get-Item $ref15_1
            $ref15_1SizeKB = $ref15_1Info.Length / 1KB
            
            Write-Host "`nComparison with 15-1:" -ForegroundColor Cyan
            Write-Host "  15-1 Size: $($ref15_1SizeKB.ToString('F2')) KB" -ForegroundColor Gray
            Write-Host "  15-2 Size: $($sizeKB.ToString('F2')) KB" -ForegroundColor Gray
            Write-Host "  Difference: $([Math]::Abs($sizeKB - $ref15_1SizeKB).ToString('F2')) KB" -ForegroundColor Gray
        }
    }
    
    if ($sizeOK -and $linesOK) {
        Write-Host "`n" + "=" * 80 -ForegroundColor Green
        Write-Host " SUCCESS: Quality check passed!" -ForegroundColor Green
        Write-Host "=" * 80 -ForegroundColor Green
    } else {
        Write-Host "`n" + "=" * 80 -ForegroundColor Yellow
        Write-Host " WARNING: Some quality checks failed" -ForegroundColor Yellow
        Write-Host "=" * 80 -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`nERROR: Cannot parse JSON: $_" -ForegroundColor Red
    exit 1
}
