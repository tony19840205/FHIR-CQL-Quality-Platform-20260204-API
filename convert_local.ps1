$jarFile = ".\cql-to-elm.jar"
$sourceFolder = ".\CQL 2026"
$outputFolder = ".\ELM_JSON"

if (!(Test-Path $jarFile)) {
    Write-Host "错误: 找不到 $jarFile" -ForegroundColor Red
    exit
}

if (!(Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
}

$cqlFiles = Get-ChildItem -Path $sourceFolder -Filter *.cql -Recurse
$total = $cqlFiles.Count
$success = 0
$failed = 0

Write-Host "`n找到 $total 个CQL文件，开始转换...`n" -ForegroundColor Cyan

for ($i = 0; $i -lt $total; $i++) {
    $file = $cqlFiles[$i]
    $num = $i + 1
    $percent = [math]::Round(($num/$total)*100, 1)
    
    $relPath = $file.FullName.Substring($sourceFolder.Length + 2)
    $outPath = Join-Path $outputFolder ($relPath -replace "\.cql$", ".json")
    $outDir = Split-Path $outPath -Parent
    
    Write-Host "[$num/$total] $percent% - $relPath" -ForegroundColor Yellow
    
    try {
        if (!(Test-Path $outDir)) {
            New-Item -Path $outDir -ItemType Directory -Force | Out-Null
        }
        
        # 使用Java执行转换
        $result = & java -jar $jarFile `
            --format json `
            --input $file.FullName `
            2>&1
        
        # 检查生成的JSON文件
        $jsonFile = [System.IO.Path]::ChangeExtension($file.FullName, "json")
        
        if (Test-Path $jsonFile) {
            Move-Item -Path $jsonFile -Destination $outPath -Force
            Write-Host "  ✅ 成功`n" -ForegroundColor Green
            $success++
        } else {
            throw "未生成JSON文件"
        }
    }
    catch {
        Write-Host "  ❌ $($_.Exception.Message)`n" -ForegroundColor Red
        $failed++
    }
    
    if ($num % 10 -eq 0) {
        Write-Host "--- 进度: 成功 $success, 失败 $failed ---`n" -ForegroundColor Cyan
    }
}

Write-Host "`n转换完成!" -ForegroundColor Green
Write-Host "总计: $total | 成功: $success | 失败: $failed`n" -ForegroundColor White
