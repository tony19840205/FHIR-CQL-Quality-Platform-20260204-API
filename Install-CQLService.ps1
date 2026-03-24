# CQL翻譯服務自動安裝腳本
# 自動下載、解壓並配置本地CQL翻譯服務

param(
    [string]$InstallDir = "cql-service",
    [switch]$AutoStart
)

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     CQL翻譯服務自動安裝程序 v2.7.1            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# 檢查Java
Write-Host "[1/5] 檢查Java環境..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "  ✅ Java已安裝: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ 未安裝Java" -ForegroundColor Red
    Write-Host "  請先安裝Java 11或更高版本" -ForegroundColor Yellow
    Write-Host "  下載: https://adoptium.net/" -ForegroundColor Cyan
    exit 1
}

# 創建安裝目錄
Write-Host "`n[2/5] 創建安裝目錄..." -ForegroundColor Yellow
if (Test-Path $InstallDir) {
    Write-Host "  ⚠️  目錄已存在: $InstallDir" -ForegroundColor Yellow
    $overwrite = Read-Host "  是否覆蓋? (y/n)"
    if ($overwrite -ne 'y') {
        Write-Host "  安裝取消" -ForegroundColor Red
        exit 0
    }
    Remove-Item $InstallDir -Recurse -Force
}
New-Item $InstallDir -ItemType Directory -Force | Out-Null
Write-Host "  ✅ 目錄已創建: $InstallDir" -ForegroundColor Green

# 下載源碼（因為release沒有預編譯jar）
Write-Host "`n[3/5] 下載CQL翻譯服務..." -ForegroundColor Yellow

# 方案A: 嘗試從Maven Central下載（如果有）
$mavenUrl = "https://repo1.maven.org/maven2/org/opencds/cqf/cql/cql-translation-server/2.7.1/cql-translation-server-2.7.1.jar"
$jarFile = Join-Path $InstallDir "cqlTranslationServer-2.7.1.jar"

Write-Host "  正在下載JAR文件..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $mavenUrl -OutFile $jarFile -UseBasicParsing -ErrorAction Stop
    if (Test-Path $jarFile) {
        $sizeMB = [math]::Round((Get-Item $jarFile).Length / 1MB, 2)
        Write-Host "  ✅ 下載成功: $sizeMB MB" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Maven Central下載失敗，嘗試備用方案..." -ForegroundColor Yellow
    
    # 方案B: 從GitHub下載源碼並提示編譯
    $sourceUrl = "https://github.com/cqframework/cql-translation-service/archive/refs/tags/v2.7.1.zip"
    $sourceZip = Join-Path $InstallDir "source.zip"
    
    Write-Host "  正在下載源碼..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $sourceUrl -OutFile $sourceZip -UseBasicParsing -ErrorAction Stop
        Write-Host "  ✅ 源碼下載成功" -ForegroundColor Green
        
        # 檢查Maven
        Write-Host "`n  檢查Maven..." -ForegroundColor Yellow
        try {
            $mvnVersion = mvn --version 2>&1 | Select-Object -First 1
            Write-Host "  ✅ Maven已安裝: $mvnVersion" -ForegroundColor Green
            
            # 解壓源碼
            Write-Host "  正在解壓源碼..." -ForegroundColor Cyan
            Expand-Archive -Path $sourceZip -DestinationPath $InstallDir -Force
            $sourceDir = Join-Path $InstallDir "cql-translation-service-2.7.1"
            
            # 編譯
            Write-Host "  正在編譯服務（這可能需要幾分鐘）..." -ForegroundColor Cyan
            Push-Location $sourceDir
            mvn package -DskipTests 2>&1 | Out-Null
            Pop-Location
            
            # 複製編譯結果
            $compiledJar = Join-Path $sourceDir "target\cqlTranslationServer-2.7.1.jar"
            $compiledLibs = Join-Path $sourceDir "target\libs"
            
            if (Test-Path $compiledJar) {
                Copy-Item $compiledJar $InstallDir -Force
                Copy-Item $compiledLibs $InstallDir -Recurse -Force
                Write-Host "  ✅ 編譯成功" -ForegroundColor Green
            } else {
                Write-Host "  ❌ 編譯失敗" -ForegroundColor Red
                exit 1
            }
            
        } catch {
            Write-Host "  ❌ Maven未安裝，無法編譯" -ForegroundColor Red
            Write-Host "`n  解決方案:" -ForegroundColor Yellow
            Write-Host "    1. 安裝Maven: https://maven.apache.org/download.cgi" -ForegroundColor Cyan
            Write-Host "    2. 或使用Docker方案 (見文檔)" -ForegroundColor Cyan
            Write-Host "    3. 或使用線上工具暫時處理" -ForegroundColor Cyan
            exit 1
        }
    } catch {
        Write-Host "  ❌ 下載失敗: $_" -ForegroundColor Red
        exit 1
    }
}

# 下載依賴庫（如果需要）
Write-Host "`n[4/5] 檢查依賴庫..." -ForegroundColor Yellow
$libsDir = Join-Path $InstallDir "libs"
if (-not (Test-Path $libsDir)) {
    Write-Host "  ⚠️  需要從編譯版本獲取libs目錄" -ForegroundColor Yellow
    Write-Host "  或者libs已包含在JAR中（uber-jar）" -ForegroundColor Cyan
} else {
    $libCount = (Get-ChildItem $libsDir -Filter "*.jar").Count
    Write-Host "  ✅ 找到 $libCount 個依賴庫" -ForegroundColor Green
}

# 創建啟動腳本
Write-Host "`n[5/5] 創建啟動腳本..." -ForegroundColor Yellow
$startScript = @"
# CQL翻譯服務啟動腳本
Write-Host "正在啟動CQL翻譯服務..." -ForegroundColor Cyan
Write-Host "端口: 8080" -ForegroundColor Yellow
Write-Host "訪問: http://localhost:8080/cql/translator`n" -ForegroundColor Yellow

java -jar cqlTranslationServer-2.7.1.jar
"@

$startScript | Out-File (Join-Path $InstallDir "start.ps1") -Encoding UTF8
Write-Host "  ✅ 啟動腳本已創建: start.ps1" -ForegroundColor Green

# 創建測試腳本
$testScript = @"
# 測試CQL翻譯服務
Write-Host "測試CQL翻譯服務..." -ForegroundColor Cyan

`$testCql = @'
library Test version '1.0.0'
using FHIR version '4.0.1'
define Hello: 'World'
'@

try {
    `$response = Invoke-WebRequest ``
        -Uri "http://localhost:8080/cql/translator" ``
        -Method POST ``
        -ContentType "application/cql" ``
        -Headers @{"Accept"="application/elm+json"} ``
        -Body `$testCql ``
        -UseBasicParsing
    
    if (`$response.StatusCode -eq 200) {
        Write-Host "✅ 服務運行正常！" -ForegroundColor Green
        `$elm = `$response.Content | ConvertFrom-Json
        Write-Host "Library ID: `$(`$elm.library.identifier.id)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ 服務未運行或無法連接" -ForegroundColor Red
    Write-Host "錯誤: `$(`$_.Exception.Message)" -ForegroundColor Yellow
}
"@

$testScript | Out-File (Join-Path $InstallDir "test.ps1") -Encoding UTF8
Write-Host "  ✅ 測試腳本已創建: test.ps1" -ForegroundColor Green

# 安裝完成
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          ✅ 安裝完成！                          ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "安裝位置: $(Resolve-Path $InstallDir)" -ForegroundColor Cyan
Write-Host "`n使用方法:" -ForegroundColor Yellow
Write-Host "  1. 進入目錄:" -ForegroundColor White
Write-Host "     cd $InstallDir`n" -ForegroundColor DarkGray
Write-Host "  2. 啟動服務:" -ForegroundColor White
Write-Host "     .\start.ps1" -ForegroundColor DarkGray
Write-Host "     或: java -jar cqlTranslationServer-2.7.1.jar`n" -ForegroundColor DarkGray
Write-Host "  3. 測試服務（在另一個視窗）:" -ForegroundColor White
Write-Host "     .\test.ps1`n" -ForegroundColor DarkGray
Write-Host "  4. 批量轉換:" -ForegroundColor White
Write-Host "     cd .." -ForegroundColor DarkGray
Write-Host "     node batch_convert_local.js `"cql`" `"ELM_JSON_OFFICIAL/output`"`n" -ForegroundColor DarkGray

if ($AutoStart) {
    Write-Host "自動啟動服務中..." -ForegroundColor Yellow
    Push-Location $InstallDir
    Start-Process powershell -ArgumentList "-NoExit", "-File", "start.ps1"
    Pop-Location
    Start-Sleep -Seconds 3
    Write-Host "✅ 服務已在新視窗啟動" -ForegroundColor Green
}

Write-Host "`n提示: 使用 Ctrl+C 停止服務" -ForegroundColor Gray
