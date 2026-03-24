# 使用Docker转换CQL文件到官方ELM JSON
# 创建日期: 2026-01-08

$files = @(
    'Indicator_02_Outpatient_Antibiotic_Usage_Rate_1140_01.cql',
    'Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql',
    'Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql',
    'Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql',
    'Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql'
)

$outputDir = Join-Path $PWD "ELM_JSON_OFFICIAL" | Join-Path -ChildPath "舊50"
$success = @()
$failed = @()

Write-Host "=== CQL to ELM Conversion ===" -ForegroundColor Cyan
Write-Host "Files: $($files.Count)" -ForegroundColor Yellow

# Create output directory
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

# Check Docker
Write-Host "`n[1/6] Checking Docker..." -ForegroundColor Yellow
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK: Docker running" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Docker not running" -ForegroundColor Red
    exit 1
}

# Clean old container
Write-Host "`n[2/6] Cleaning old containers..." -ForegroundColor Yellow
$oldContainer = docker ps -a -q --filter "name=cql-service" 2>$null
if ($oldContainer) {
    docker rm -f cql-service 2>&1 | Out-Null
    Write-Host "  Removed old container" -ForegroundColor Green
}

# Pull image
Write-Host "`n[3/6] Pulling CQL service image..." -ForegroundColor Yellow
docker pull cqframework/cql-translation-service:latest 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Image ready" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Pull failed" -ForegroundColor Red
    exit 1
}

# Start service
Write-Host "`n[4/6] Starting CQL service..." -ForegroundColor Yellow
$containerId = docker run -d -p 8080:8080 --name cql-service cqframework/cql-translation-service:latest 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Container started" -ForegroundColor Green
    Write-Host "  Waiting for service..." -ForegroundColor Gray
    Start-Sleep -Seconds 15
    
    $serviceReady = $false
    for ($i = 1; $i -le 10; $i++) {
        try {
            $null = Invoke-WebRequest -Uri "http://localhost:8080/cql/translator" -Method GET -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
            $serviceReady = $true
            Write-Host "  Service ready" -ForegroundColor Green
            break
        }
        catch {
            Start-Sleep -Seconds 3
        }
    }
    
    if (-not $serviceReady) {
        Write-Host "  ERROR: Service timeout" -ForegroundColor Red
        docker rm -f cql-service 2>&1 | Out-Null
        exit 1
    }
} else {
    Write-Host "  ERROR: Container failed" -ForegroundColor Red
    exit 1
}

# Convert files
Write-Host "`n[5/6] Converting files..." -ForegroundColor Yellow

foreach ($file in $files) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $sourcePath = ".\cql\$file"
    $outputPath = "$outputDir\$baseName.json"
    
    Write-Host "`n  Converting: $file" -ForegroundColor Cyan
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "    ERROR: File not found" -ForegroundColor Red
        $failed += $file
        continue
    }
    
    try {
        $cqlContent = Get-Content $sourcePath -Raw -Encoding UTF8
        
        if ($cqlContent -match '(?s)(-- .*?WITH quarters AS.*?ORDER BY[^;]+;?\s*$)') {
            $sqlPart = $matches[1]
            $cqlContent = $cqlContent -replace [regex]::Escape($sqlPart), "`n// SQL logic removed`n"
            Write-Host "    Removed SQL code" -ForegroundColor Gray
        }
        
        $body = @{ cql = $cqlContent } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://localhost:8080/cql/translator" -Method POST -ContentType "application/json" -Body $body -UseBasicParsing
        
        if ($response.library) {
            $elmJson = $response | ConvertTo-Json -Depth 100
            [System.IO.File]::WriteAllText($outputPath, $elmJson, [System.Text.Encoding]::UTF8)
            
            $size = (Get-Item $outputPath).Length
            Write-Host "    OK: $([math]::Round($size/1KB, 2)) KB" -ForegroundColor Green
            $success += $file
        }
        else {
            Write-Host "    ERROR: No library in response" -ForegroundColor Red
            if ($response.errors) {
                $response.errors | ForEach-Object {
                    Write-Host "      Error: $_" -ForegroundColor Red
                }
            }
            $failed += $file
        }
    }
    catch {
        Write-Host "    ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $file
    }
}

# Cleanup
Write-Host "`n[6/6] Cleanup..." -ForegroundColor Yellow
docker rm -f cql-service 2>&1 | Out-Null
Write-Host "  Stopped container" -ForegroundColor Green

# Summary
Write-Host "`n=== Conversion Complete ===" -ForegroundColor Cyan
Write-Host "  Success: $($success.Count)/$($files.Count)" -ForegroundColor Green
Write-Host "  Failed: $($failed.Count)/$($files.Count)" -ForegroundColor $(if ($failed.Count -eq 0) { "Green" } else { "Red" })

if ($success.Count -gt 0) {
    Write-Host "`nSuccess:" -ForegroundColor Green
    $success | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

if ($failed.Count -gt 0) {
    Write-Host "`nFailed:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

Write-Host "`nOutput: $outputDir" -ForegroundColor Yellow
