# HAPI FHIR 伺服器監控腳本
# 每天自動檢查一次

$urls = @(
    "https://hapi.fhir.org/baseR4/metadata",
    "http://hapi.fhir.org/baseR4/metadata"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "HAPI FHIR 伺服器狀態檢查" -ForegroundColor Cyan
Write-Host "檢查時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

foreach($url in $urls) {
    Write-Host "測試: $url" -ForegroundColor White
    try {
        $response = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        Write-Host "   狀態: $($response.StatusCode) - 伺服器已恢復!" -ForegroundColor Green
        Write-Host "   恢復時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
        return $true
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if($statusCode) {
            Write-Host "   狀態: $statusCode - 仍然無法使用" -ForegroundColor Red
        } else {
            Write-Host "   無法連線" -ForegroundColor Red
        }
    }
}

Write-Host "`n 建議: 繼續使用替代伺服器" -ForegroundColor Yellow
Write-Host "  - Firely Server: https://server.fire.ly/r4" -ForegroundColor White
Write-Host "  - SMART Health IT: https://r4.smarthealthit.org" -ForegroundColor White
Write-Host "  - 台灣衛福部: https://thas.mohw.gov.tw/v/r4/fhir`n" -ForegroundColor White
