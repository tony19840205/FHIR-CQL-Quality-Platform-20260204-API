# CQL to ELM Converter using Java

param(
    [string]$CqlFile = "CQL 2026\zhongyi\Indicator_TCM_Traumatology_Rate.cql",
    [string]$OutputDir = "ELM_JSON_OFFICIAL\zhongyi"
)

Write-Host "=== CQL to ELM Java Converter ===" -ForegroundColor Cyan

# Check Java
Write-Host "Checking Java..." -ForegroundColor Yellow
$javaCheck = java -version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Java not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Java found" -ForegroundColor Green

# Check JAR
$jarFile = "cql-to-elm.jar"
if (-not (Test-Path $jarFile)) {
    Write-Host "ERROR: $jarFile not found" -ForegroundColor Red
    exit 1
}
$jarSize = [math]::Round((Get-Item $jarFile).Length / 1MB, 2)
Write-Host "OK: JAR file found ($jarSize MB)" -ForegroundColor Green

# Check CQL file
$cqlPath = $CqlFile -replace '\\zhongyi\\', '\中醫\'
if (-not (Test-Path $cqlPath)) {
    Write-Host "ERROR: CQL file not found: $cqlPath" -ForegroundColor Red
    exit 1
}
Write-Host "OK: CQL file: $cqlPath" -ForegroundColor Green

# Check FHIRHelpers
$fhirHelpers = "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql"
if (-not (Test-Path $fhirHelpers)) {
    Write-Host "ERROR: FHIRHelpers not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: FHIRHelpers found" -ForegroundColor Green

# Create temp directory
$tempDir = "C:\CQL_Temp"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path "$tempDir\input" -Force | Out-Null

Write-Host "`nPreparing files..." -ForegroundColor Yellow

# Copy files
$cqlFileName = Split-Path $cqlPath -Leaf
Copy-Item $cqlPath "$tempDir\input\$cqlFileName" -Force
Copy-Item $fhirHelpers "$tempDir\input\" -Force
Copy-Item $jarFile "$tempDir\" -Force
Write-Host "OK: Files copied" -ForegroundColor Green

# Convert
Push-Location $tempDir
try {
    Write-Host "`nConverting..." -ForegroundColor Yellow
    $output = java -jar $jarFile input 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Conversion completed!" -ForegroundColor Green
        
        $elmFile = "input\$($cqlFileName -replace '\.cql$', '.json')"
        if (Test-Path $elmFile) {
            $elmSize = [math]::Round((Get-Item $elmFile).Length / 1KB, 2)
            Write-Host "OK: ELM generated ($elmSize KB)" -ForegroundColor Green
            
            # Copy back
            $outDir = $OutputDir -replace '\\zhongyi', '\中醫'
            if (-not (Test-Path $outDir)) {
                New-Item -ItemType Directory -Path $outDir -Force | Out-Null
            }
            $destFile = Join-Path $PSScriptRoot "$outDir\$($cqlFileName -replace '\.cql$', '.json')"
            Copy-Item $elmFile $destFile -Force
            
            Write-Host "OK: Saved to: $destFile" -ForegroundColor Green
            
            Write-Host "`nVerify with:" -ForegroundColor Yellow
            Write-Host "node verify_elm_quality.js `"$destFile`"" -ForegroundColor Gray
        } else {
            Write-Host "WARNING: Output file not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "ERROR: Conversion failed" -ForegroundColor Red
        Write-Host $output
    }
} finally {
    Pop-Location
}
