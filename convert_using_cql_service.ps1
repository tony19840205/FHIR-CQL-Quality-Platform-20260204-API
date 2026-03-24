# Use CQL Translation Service (官方在线服务) to convert CQL to ELM
# This is the EXACT method used for TCM indicators

$cqlFiles = @(
    "cql\Indicator_03_13_Cross_Hospital_Antidepressant_Overlap_1730.cql",
    "cql\Indicator_03_14_Cross_Hospital_Sedative_Overlap_1731.cql"
)

$fhirHelpersPath = "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql"
$outputDir = "ELM_JSON_OFFICIAL\舊50_AHRQ_Official"

if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "=== CQL Translation Service (Official Method) ===" -ForegroundColor Cyan
Write-Host ""

# Read FHIRHelpers
$fhirHelpersContent = Get-Content $fhirHelpersPath -Raw -Encoding UTF8

foreach ($cqlFile in $cqlFiles) {
    $fileName = Split-Path $cqlFile -Leaf
    Write-Host "Converting: $fileName" -ForegroundColor Yellow
    
    # Read CQL file
    $cqlContent = Get-Content $cqlFile -Raw -Encoding UTF8
    
    # Prepare the request body (multipart form data style)
    $body = @{
        cql = $cqlContent
        fhirHelpers = $fhirHelpersContent
    } | ConvertTo-Json
    
    # Call CQL Translation Service
    try {
        $response = Invoke-RestMethod -Uri "https://cql.dataphoria.org/cql/translator" `
            -Method Post `
            -Headers @{
                "Content-Type" = "application/cql"
                "Accept" = "application/elm+json"
            } `
            -Body $cqlContent
        
        # Save ELM JSON
        $outputFile = Join-Path $outputDir ($fileName -replace '\.cql$', '.json')
        $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $outputFile -Encoding UTF8
        
        Write-Host "  [OK] Saved to: $outputFile" -ForegroundColor Green
        
    } catch {
        Write-Host "  [ERROR] Failed: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Conversion complete!" -ForegroundColor Green
