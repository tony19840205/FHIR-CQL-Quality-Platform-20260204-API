param([string]$CqlFolder, [string]$OutputFolder)
Write-Host "=== CQL Batch Converter (IG Publisher) ==="
if (-not (Test-Path "fhir-ig-publisher.jar")) { Write-Host "ERROR: fhir-ig-publisher.jar not found"; exit 1 }
$files = Get-ChildItem $CqlFolder -Filter "*.cql"
Write-Host "Found: $($files.Count) CQL files`n"
$success = 0; $failed = 0
$tempBase = "C:\Temp\cql_convert_" + [guid]::NewGuid().ToString().Substring(0,8)
foreach ($f in $files) {
    Write-Host "[$($success+$failed+1)/$($files.Count)] $($f.Name) ..." -NoNewline
    $temp = $tempBase + "_" + $f.BaseName
    try {
        New-Item "$temp\input\cql" -ItemType Directory -Force | Out-Null
        Copy-Item $f.FullName "$temp\input\cql\" -Force
        if (Test-Path "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql") {
            Copy-Item "CQL 2026\FHIRHelpers\FHIRHelpers-4.0.1.cql" "$temp\input\cql\" -Force
        }
        "[IG]`nig = fhir.cql`ntemplate = fhir.base.template" | Out-File "$temp\ig.ini" -Encoding ascii
        "id: fhir.cql`ncanonical: http://example.org/cql`nname: CQL`nstatus: draft`nversion: 1.0.0`nfhirVersion: 4.0.1" | Out-File "$temp\sushi-config.yaml" -Encoding ascii
        $igPath = (Get-Item "fhir-ig-publisher.jar").FullName
        Push-Location $temp
        java -jar $igPath -ig ig.ini 2>&1 | Out-Null
        Pop-Location
        $elm = Get-ChildItem "$temp\output" -Recurse -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match '"library"' } | Select-Object -First 1
        if ($elm) {
            if (-not (Test-Path $OutputFolder)) { New-Item $OutputFolder -ItemType Directory -Force | Out-Null }
            $out = Join-Path $OutputFolder "$($f.BaseName).json"
            Copy-Item $elm.FullName $out -Force
            $sizeKB = [math]::Round((Get-Item $out).Length/1KB,2)
            Write-Host " OK ($sizeKB KB)" -ForegroundColor Green
            $success++
        } else {
            Write-Host " FAIL (No ELM output)" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    } finally {
        if (Test-Path $temp) { Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
if (Test-Path $tempBase*) { Remove-Item ($tempBase + "*") -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host "`n===========================================" 
Write-Host "SUCCESS: $success/$($files.Count)" -ForegroundColor Green
Write-Host "FAILED: $failed/$($files.Count)" -ForegroundColor $(if($failed -eq 0){"Green"}else{"Red"})
Write-Host "Output: $OutputFolder"