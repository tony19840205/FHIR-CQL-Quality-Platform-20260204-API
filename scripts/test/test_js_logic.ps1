$tka = Invoke-RestMethod -Uri "https://thas.mohw.gov.tw/v/r4/fhir/Procedure/tka-proc-001"
$procDate = $tka.performedDateTime
$patientRef = $tka.subject.reference
$procDateObj = [DateTime]::Parse($procDate)
$ninetyDays = $procDateObj.AddDays(90)

Write-Host "TKA: $($tka.id)" -ForegroundColor Cyan
Write-Host "  Date: $procDate"
Write-Host "  Patient: $patientRef"
Write-Host "  90天後: $($ninetyDays.ToString('yyyy-MM-dd'))"

$query = "https://thas.mohw.gov.tw/v/r4/fhir/Procedure?patient=$patientRef&status=completed&date=ge$($procDateObj.ToString('yyyy-MM-dd'))&date=le$($ninetyDays.ToString('yyyy-MM-dd'))"
Write-Host "`n查詢: $query" -ForegroundColor White

$result = Invoke-RestMethod -Uri $query
Write-Host "`n找到 $($result.total) 個Procedure"

$infectionCodes = @('64053B', '64198B')
$foundInfection = $false

foreach ($e in $result.entry) {
    $code = $e.resource.code.coding[0].code
    $date = $e.resource.performedDateTime
    $isSameDay = $procDate.Split('T')[0] -eq $date.Split('T')[0]
    $isInfection = $infectionCodes -contains $code
    
    if ($isInfection) {
        Write-Host "`n  ✓ 感染Procedure: $($e.resource.id)" -ForegroundColor Green
        Write-Host "    Code: $code"
        Write-Host "    Date: $date"
        
        if ($code -eq '64198B' -and $isSameDay) {
            Write-Host "    ✗ 同日64198B，排除" -ForegroundColor Red
        } else {
            Write-Host "    ✓ 應計入分子！" -ForegroundColor Green
            $foundInfection = $true
        }
    }
}

if (-not $foundInfection) {
    Write-Host "`n✗ 沒有找到符合條件的感染Procedure" -ForegroundColor Red
}
