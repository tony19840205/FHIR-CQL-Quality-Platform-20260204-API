# Fix all organization CQL files with common patterns

$orgFiles = @(
    ".\CQL 2026\中醫\Indicator_TCM_Pediatric_Asthma_Program_Organization_List.cql",
    ".\CQL 2026\中醫\Indicator_TCM_Pediatric_Cerebral_Palsy_Program_Organization_List.cql",
    ".\CQL 2026\中醫\Indicator_TCM_Global_Budget_Program_Organization_List.cql"
)

foreach ($file in $orgFiles) {
    if (Test-Path $file) {
        Write-Host "Processing: $file" -ForegroundColor Cyan
        $content = Get-Content $file -Raw -Encoding UTF8
        
        # Fix 1: CodeSystem reference
        $content = $content -replace 'system: "TWCaseType"', "system: 'https://twcore.mohw.gov.tw/ig/twcore/CodeSystem/tw-case-type'"
        
        # Fix 2: GetExtensionString function
        $content = $content -replace 'define function GetExtensionString\(element FHIR\.Element, url String\):\s+singleton from \(\s+element\.extension E where E\.url = url\s+\)\.value as FHIR\.string', 
            "define function GetExtensionString(element FHIR.Organization, url String):`n  singleton from (`n    element.extension E where E.url.value = url`n  ).value.value"
        
        # Fix 3: GetExtensionBoolean function  
        $content = $content -replace 'define function GetExtensionBoolean\(element FHIR\.Element, url String\):\s+singleton from \(\s+element\.extension E where E\.url = url\s+\)\.value as FHIR\.boolean',
            "define function GetExtensionBoolean(element FHIR.Organization, url String):`n  singleton from (`n    element.extension E where E.url.value = url`n  ).value.value"
        
        # Save file
        $content | Set-Content $file -Encoding UTF8 -NoNewline
        Write-Host "  ✓ Fixed" -ForegroundColor Green
    }
}

Write-Host "`nDone! Re-run gradle cql2elm to test." -ForegroundColor Yellow
