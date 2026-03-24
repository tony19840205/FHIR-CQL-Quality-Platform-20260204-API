# CQL翻譯服務 - 簡易安裝方案
# 因為GitHub release沒有預編譯jar，提供最簡單的解決方案

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     CQL翻譯服務 - 快速安裝精靈               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "檢測到GitHub release沒有預編譯JAR文件" -ForegroundColor Yellow
Write-Host "提供3個可用方案:`n" -ForegroundColor Cyan

Write-Host "方案1: 使用Docker (最簡單)" -ForegroundColor Green
Write-Host "  ✅ 一行命令啟動" -ForegroundColor White
Write-Host "  ✅ 無需編譯" -ForegroundColor White
Write-Host "  ❌ 需要安裝Docker Desktop`n" -ForegroundColor Red

Write-Host "方案2: 使用線上工具 (最快)" -ForegroundColor Green
Write-Host "  ✅ 無需安裝任何軟體" -ForegroundColor White
Write-Host "  ✅ 立即可用" -ForegroundColor White
Write-Host "  ❌ 需要手動操作`n" -ForegroundColor Red

Write-Host "方案3: 從源碼編譯 (最完整)" -ForegroundColor Green
Write-Host "  ✅ 本地服務" -ForegroundColor White
Write-Host "  ✅ 完全離線" -ForegroundColor White
Write-Host "  ❌ 需要Maven和時間`n" -ForegroundColor Red

$choice = Read-Host "請選擇方案 (1/2/3)"

switch ($choice) {
    "1" {
        Write-Host "`n=== 方案1: Docker安裝 ===" -ForegroundColor Cyan
        
        # 檢查Docker
        try {
            docker --version | Out-Null
            Write-Host "✅ Docker已安裝`n" -ForegroundColor Green
            
            Write-Host "步驟1: 拉取Docker鏡像..." -ForegroundColor Yellow
            Write-Host "執行: docker pull cqframework/cql-translation-service:latest`n" -ForegroundColor White
            
            $pull = Read-Host "是否現在拉取? (y/n)"
            if ($pull -eq 'y') {
                docker pull cqframework/cql-translation-service:latest
                
                Write-Host "`n步驟2: 啟動服務..." -ForegroundColor Yellow
                Write-Host "執行: docker run -d -p 8080:8080 --name cql-service cqframework/cql-translation-service:latest`n" -ForegroundColor White
                
                $start = Read-Host "是否現在啟動? (y/n)"
                if ($start -eq 'y') {
                    docker run -d -p 8080:8080 --name cql-service cqframework/cql-translation-service:latest
                    Start-Sleep -Seconds 3
                    
                    Write-Host "`n測試服務..." -ForegroundColor Yellow
                    try {
                        $test = Invoke-WebRequest http://localhost:8080/cql/translator -Method GET -UseBasicParsing -ErrorAction Stop
                        Write-Host "✅ 服務運行成功！" -ForegroundColor Green
                        Write-Host "`n現在可以執行批量轉換:" -ForegroundColor Cyan
                        Write-Host "  node batch_convert_local.js `"cql`" `"ELM_JSON_OFFICIAL/output`"" -ForegroundColor White
                    } catch {
                        Write-Host "⚠️  服務啟動中，請稍等30秒後測試" -ForegroundColor Yellow
                    }
                }
            }
            
        } catch {
            Write-Host "❌ Docker未安裝`n" -ForegroundColor Red
            Write-Host "請先安裝Docker Desktop:" -ForegroundColor Yellow
            Write-Host "  https://www.docker.com/products/docker-desktop`n" -ForegroundColor Cyan
            
            $openBrowser = Read-Host "是否打開下載頁面? (y/n)"
            if ($openBrowser -eq 'y') {
                Start-Process "https://www.docker.com/products/docker-desktop"
            }
        }
    }
    
    "2" {
        Write-Host "`n=== 方案2: 線上工具 ===" -ForegroundColor Cyan
        Write-Host "`n✅ 已創建輔助工具: AutoConvert_Web.ps1`n" -ForegroundColor Green
        
        Write-Host "使用方法:" -ForegroundColor Yellow
        Write-Host "  1. 執行輔助腳本:" -ForegroundColor White
        Write-Host "     .\AutoConvert_Web.ps1 -CqlFolder `"cql`" -OutputFolder `"ELM_JSON_OFFICIAL/output`"`n" -ForegroundColor DarkGray
        
        Write-Host "  2. 在瀏覽器開啟:" -ForegroundColor White
        Write-Host "     https://cql.dataphoria.org/`n" -ForegroundColor DarkGray
        
        Write-Host "  3. 腳本會自動:" -ForegroundColor White
        Write-Host "     - 複製CQL到剪貼簿" -ForegroundColor Gray
        Write-Host "     - 等待您在網頁上貼上並轉換" -ForegroundColor Gray
        Write-Host "     - 自動保存JSON結果`n" -ForegroundColor Gray
        
        $openBrowser = Read-Host "是否打開線上工具? (y/n)"
        if ($openBrowser -eq 'y') {
            Start-Process "https://cql.dataphoria.org/"
        }
        
        $runScript = Read-Host "是否現在執行輔助腳本? (y/n)"
        if ($runScript -eq 'y') {
            .\AutoConvert_Web.ps1 -CqlFolder "cql" -OutputFolder "ELM_JSON_OFFICIAL/web_output"
        }
    }
    
    "3" {
        Write-Host "`n=== 方案3: 從源碼編譯 ===" -ForegroundColor Cyan
        
        # 檢查Maven
        try {
            $mvnVersion = mvn --version 2>&1 | Select-Object -First 1
            Write-Host "✅ Maven已安裝: $mvnVersion`n" -ForegroundColor Green
            
            Write-Host "步驟1: 下載源碼..." -ForegroundColor Yellow
            $sourceUrl = "https://github.com/cqframework/cql-translation-service/archive/refs/tags/v2.7.1.zip"
            $sourceZip = "cql-service-source.zip"
            
            Write-Host "下載中..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $sourceUrl -OutFile $sourceZip -UseBasicParsing
            Write-Host "✅ 下載完成`n" -ForegroundColor Green
            
            Write-Host "步驟2: 解壓源碼..." -ForegroundColor Yellow
            Expand-Archive -Path $sourceZip -DestinationPath "." -Force
            Write-Host "✅ 解壓完成`n" -ForegroundColor Green
            
            Write-Host "步驟3: 編譯服務 (需要幾分鐘)..." -ForegroundColor Yellow
            Push-Location "cql-translation-service-2.7.1"
            mvn package -DskipTests
            Pop-Location
            
            Write-Host "`n✅ 編譯完成！`n" -ForegroundColor Green
            Write-Host "啟動服務:" -ForegroundColor Yellow
            Write-Host "  cd cql-translation-service-2.7.1" -ForegroundColor White
            Write-Host "  java -jar target\cqlTranslationServer-2.7.1.jar`n" -ForegroundColor White
            
            $start = Read-Host "是否現在啟動服務? (y/n)"
            if ($start -eq 'y') {
                Push-Location "cql-translation-service-2.7.1"
                Start-Process powershell -ArgumentList "-NoExit", "-Command", "java -jar target\cqlTranslationServer-2.7.1.jar"
                Pop-Location
                Write-Host "`n✅ 服務已在新視窗啟動" -ForegroundColor Green
                Write-Host "等待5秒讓服務啟動..." -ForegroundColor Cyan
                Start-Sleep -Seconds 5
            }
            
        } catch {
            Write-Host "❌ Maven未安裝`n" -ForegroundColor Red
            Write-Host "請先安裝Maven:" -ForegroundColor Yellow
            Write-Host "  https://maven.apache.org/download.cgi`n" -ForegroundColor Cyan
            Write-Host "或選擇方案1(Docker)或方案2(線上工具)" -ForegroundColor Yellow
        }
    }
    
    default {
        Write-Host "`n無效選擇，請重新執行腳本" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              設置完成！                          ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Green

if ($choice -eq "1" -or $choice -eq "3") {
    Write-Host "下一步: 批量轉換150個文件" -ForegroundColor Cyan
    Write-Host "  node batch_convert_local.js `"cql`" `"ELM_JSON_OFFICIAL/output`"`n" -ForegroundColor White
}
