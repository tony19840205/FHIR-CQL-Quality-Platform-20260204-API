# ========================================
# CQL Batch Convert to ELM JSON (Local Java)
# ========================================

param(
    [string]$SourceFolder = ".\CQL 2026",
    [string]$OutputFolder = ".\ELM_JSON",
    [string]$TranslatorJar = ".\cql-to-elm-cli.jar",
    [switch]$DownloadTranslator = $false
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Check Java
Write-ColorOutput "`nChecking Java environment..." "Cyan"
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-ColorOutput "OK $javaVersion" "Green"
} catch {
    Write-ColorOutput "ERROR: Java not found! Please install Java 11+" "Red"
    Write-ColorOutput "Download: https://adoptium.net/" "Yellow"
    exit 1
}

# Download Translator if needed
if ($DownloadTranslator -or -not (Test-Path $TranslatorJar)) {
    Write-ColorOutput "`nDownloading CQL-to-ELM Translator..." "Cyan"
    $translatorUrl = "https://github.com/cqframework/clinical_quality_language/releases/download/v3.8.0/cql-to-elm-cli-3.8.0.jar"
    try {
        Invoke-WebRequest -Uri $translatorUrl -OutFile $TranslatorJar
        Write-ColorOutput "OK Downloaded: $TranslatorJar" "Green"
    } catch {
        Write-ColorOutput "ERROR: Download failed: $($_.Exception.Message)" "Red"
        Write-ColorOutput "Please manually download and place at: $TranslatorJar" "Yellow"
        exit 1
    }
}

# Check Translator
if (-not (Test-Path $TranslatorJar)) {
    Write-ColorOutput "ERROR: Translator JAR not found: $TranslatorJar" "Red"
    Write-ColorOutput "Use -DownloadTranslator parameter or download manually" "Yellow"
    exit 1
}

# Create output folder
if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
    Write-ColorOutput "OK Created output folder: $OutputFolder" "Green"
}

# Get all CQL files
$cqlFiles = Get-ChildItem -Path $SourceFolder -Filter "*.cql" -Recurse
$totalFiles = $cqlFiles.Count
Write-ColorOutput "`nFound $totalFiles CQL files" "Cyan"
Write-ColorOutput "========================================`n" "Gray"

$successCount = 0
$failCount = 0
$failedFiles = @()

# Process each file
foreach ($i in 1..$totalFiles) {
    $file = $cqlFiles[$i - 1]
    $relativePath = $file.FullName.Replace((Resolve-Path $SourceFolder).Path, "").TrimStart("\")
    $outputPath = Join-Path $OutputFolder ($relativePath -replace "\.cql$", ".json")
    $outputDir = Split-Path $outputPath -Parent
    
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    Write-ColorOutput "[$i/$totalFiles] $relativePath" "Cyan"
    
    try {
        $inputPath = $file.FullName
        
        # Run CQL-to-ELM conversion
        $result = & java -jar $TranslatorJar `
            --format=JSON `
            --input $inputPath `
            --output $outputDir 2>&1
        
        # Check if JSON was generated
        $tempOutputPath = [System.IO.Path]::ChangeExtension($inputPath, "json")
        $fileDir = Split-Path $inputPath -Parent
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($inputPath)
        $possibleOutput = Join-Path $fileDir "$fileName.json"
        
        if (Test-Path $possibleOutput) {
            Move-Item -Path $possibleOutput -Destination $outputPath -Force
            Write-ColorOutput "  OK Success -> $outputPath" "Green"
            $successCount++
        } else {
            throw "Output file not generated"
        }
        
    } catch {
        Write-ColorOutput "  ERROR: $($_.Exception.Message)" "Red"
        $failCount++
        $failedFiles += $relativePath
    }
}

Write-ColorOutput "`n========================================" "Gray"
Write-ColorOutput "Conversion Summary:" "Cyan"
Write-ColorOutput "  Total: $totalFiles files" "White"
Write-ColorOutput "  Success: $successCount" "Green"
Write-ColorOutput "  Failed: $failCount" "Red"

if ($failedFiles.Count -gt 0) {
    Write-ColorOutput "`nFailed files:" "Red"
    foreach ($failedFile in $failedFiles) {
        Write-ColorOutput "  - $failedFile" "Yellow"
    }
}

Write-ColorOutput "`nBatch conversion complete!" "Green"
Write-ColorOutput "Output folder: $OutputFolder" "Cyan"
