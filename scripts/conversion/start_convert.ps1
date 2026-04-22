$cqlFiles = Get-ChildItem ".\CQL 2026" -Filter *.cql -Recurse
$total = $cqlFiles.Count
$success = 0
$failed = 0

Write-Host "`n找到 $total 个CQL文件，开始转换...`n" -ForegroundColor Cyan

for ($i = 0; $i -lt $total; $i++) {
    $file = $cqlFiles[$i]
    $num = $i + 1
    $percent = [math]::Round(($num/$total)*100, 1)
    
    $relPath = $file.FullName.Replace((Get-Location).Path + "\CQL 2026\", "")
    $outPath = ".\ELM_JSON\$($relPath -replace '\.cql$','.json')"
    $outDir = Split-Path $outPath
    
    Write-Host "[$num/$total] $percent% - $relPath" -ForegroundColor Yellow
    
    try {
        if (!(Test-Path $outDir)) { New-Item $outDir -ItemType Directory -Force | Out-Null }
        
        $cql = Get-Content $file.FullName -Raw -Encoding UTF8
        $json = @{ cql = $cql } | ConvertTo-Json
        
        $result = Invoke-RestMethod -Uri "https://cql.dataphoria.org/translate" `
            -Method Post `
            -Body $json `
            -ContentType "application/json" `
            -TimeoutSec 60
        
        $result | ConvertTo-Json -Depth 100 | Out-File $outPath -Encoding UTF8
        
        Write-Host "  ✅ 成功`n" -ForegroundColor Green
        $success++
    }
    catch {
        Write-Host "  ❌ 失败: $($_.Exception.Message)`n" -ForegroundColor Red
        $failed++
    }
    
    if ($num % 10 -eq 0) {
        Write-Host "--- 进度: 成功 $success, 失败 $failed ---`n" -ForegroundColor Cyan
    }
}

Write-Host "`n完成! 总计: $total | 成功: $success | 失败: $failed`n" -ForegroundColor Green
