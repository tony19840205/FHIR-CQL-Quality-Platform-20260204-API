Write-Host "=== DNS修復 (管理員模式) ===" -ForegroundColor Cyan
Write-Host "`n原DNS設置:" -ForegroundColor Yellow
Get-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4 | Select-Object ServerAddresses

Write-Host "`n更換為Google DNS..." -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("8.8.8.8", "8.8.4.4")

Write-Host "`n新DNS設置:" -ForegroundColor Green
Get-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4 | Select-Object ServerAddresses

Write-Host "`n清除DNS快取..." -ForegroundColor Yellow
Clear-DnsClientCache
ipconfig /flushdns | Out-Null

Write-Host " DNS修復完成!" -ForegroundColor Green
Write-Host "`n按任意鍵關閉..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
