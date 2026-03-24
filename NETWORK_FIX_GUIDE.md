# 網路問題診斷報告

## 問題確認

✅ **已確認：DNS逾時問題**

當前DNS伺服器：10.30.11.2（公司/學校DNS）
症狀：DNS請求逾時（timeout 2秒）

測試結果：
```
cql-translation-service.ahrq.gov -> DNS timeout
cql.dataphoria.org -> DNS timeout
```

當前網卡DNS設置：
- Wi-Fi: {10.30.11.2, 8.8.8.8, 168.95.1.1}

## 問題原因

公司DNS (10.30.11.2) 無法解析外部域名或速度過慢

## 🔧 立即修復方案

### 方案A：臨時更換DNS（推薦）

**步驟1：查看網卡名稱**
```powershell
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object Name, InterfaceDescription
```

**步驟2：更換為Google DNS**
```powershell
# 假設是 "Wi-Fi" 網卡
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("8.8.8.8", "8.8.4.4")
```

**步驟3：驗證**
```powershell
# 清除DNS快取
Clear-DnsClientCache

# 測試新DNS
Resolve-DnsName cql-translation-service.ahrq.gov
```

**步驟4：重新運行轉換**
```powershell
node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL/test"
```

**恢復原設定**（完成後）：
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("10.30.11.2", "8.8.8.8", "168.95.1.1")
```

---

### 方案B：使用Hosts文件（備選）

如果無法更改DNS設定，可添加hosts記錄：

**步驟1：以管理員身份開啟記事本**
```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

**步驟2：添加以下行**（需要先查詢IP）
```
# CQL Translation Services
23.185.0.2 cql-translation-service.ahrq.gov
104.21.50.123 cql.dataphoria.org
```

**步驟3：保存並測試**

---

### 方案C：使用代理（如果公司有代理伺服器）

修改batch_convert_reliable.js：

```javascript
const client = new Client(serviceUrl, {
    httpsAgent: new require('https').Agent({
        rejectUnauthorized: false  // 如果公司用自簽證書
    }),
    proxy: {
        host: 'proxy.company.com',  // 公司代理地址
        port: 8080,                  // 代理端口
        auth: {
            username: 'your_username',
            password: 'your_password'
        }
    }
});
```

---

### 方案D：完全離線方案（不需要網路）

由於網路問題無法短期解決，使用離線JAR文件：

**步驟1：手動下載JAR**（在有網路的電腦上）

訪問：https://github.com/cqframework/clinical_quality_language/releases

下載：
- cql-to-elm-3.18.0-SNAPSHOT-jar-with-dependencies.jar

**步驟2：使用USB或網路分享複製到工作電腦**

**步驟3：創建批量轉換腳本**

創建：convert_offline.ps1
```powershell
param([string]$CqlFolder, [string]$OutputFolder)

$jar = "cql-to-elm-3.18.0-SNAPSHOT-jar-with-dependencies.jar"

if (-not (Test-Path $jar)) {
    Write-Host "ERROR: $jar not found"
    exit 1
}

$files = Get-ChildItem $CqlFolder -Filter "*.cql"
$success = 0

foreach ($file in $files) {
    Write-Host "Converting: $($file.Name) ..." -NoNewline
    
    $outFile = Join-Path $OutputFolder "$($file.BaseName).json"
    
    try {
        java -jar $jar `
            --format JSON `
            --output-file $outFile `
            $file.FullName 2>&1 | Out-Null
        
        if (Test-Path $outFile) {
            $size = [math]::Round((Get-Item $outFile).Length/1KB, 2)
            Write-Host " OK ($size KB)" -ForegroundColor Green
            $success++
        } else {
            Write-Host " FAIL (No output)" -ForegroundColor Red
        }
    } catch {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nDone: $success/$($files.Count) succeeded"
```

**步驟4：運行**
```powershell
.\convert_offline.ps1 -CqlFolder "cql" -OutputFolder "ELM_JSON_OFFICIAL/output"
```

---

## 📊 診斷命令集合

**檢查當前DNS**
```powershell
Get-DnsClientServerAddress -AddressFamily IPv4 | 
    Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | 
    Select-Object InterfaceAlias, ServerAddresses
```

**測試DNS解析**
```powershell
Resolve-DnsName cql-translation-service.ahrq.gov
Resolve-DnsName cql.dataphoria.org
```

**測試HTTP連線**
```powershell
Test-NetConnection cql-translation-service.ahrq.gov -Port 443
```

**檢查代理設置**
```powershell
netsh winhttp show proxy
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
```

**清除DNS快取**
```powershell
Clear-DnsClientCache
ipconfig /flushdns
```

---

## ⚡ 快速決策樹

```
DNS逾時問題
    │
    ├─ 有管理員權限？
    │   ├─ 是 → 使用方案A（更換DNS為8.8.8.8）
    │   └─ 否 → 使用方案B（修改hosts文件）
    │
    ├─ 公司網路有代理？
    │   ├─ 是 → 使用方案C（配置代理）
    │   └─ 否 → 繼續下一步
    │
    └─ 無法修復網路？
        └─ 使用方案D（離線JAR文件）
```

---

## 💡 推薦執行順序（150個文件）

### 選項1：快速DNS修復（總時間：~20分鐘）

1. 更換DNS為8.8.8.8（1分鐘）
2. 清除快取（1分鐘）
3. 測試單檔（2分鐘）
4. 批量轉換150個文件（15分鐘）
5. 恢復原DNS設定（1分鐘）

### 選項2：離線JAR方案（總時間：~60分鐘）

1. 在有網路的電腦下載JAR（5分鐘）
2. 複製到工作電腦（5分鐘）
3. 創建批量腳本（5分鐘）
4. 批量轉換150個文件（45分鐘）

---

## 🔍 故障排除

**Q: 更換DNS後仍然無法連線？**
A: 清除DNS快取：`Clear-DnsClientCache`，然後重啟網路卡

**Q: 不知道公司代理設置？**
A: 查看IE代理設置：控制台 → 網際網路選項 → 連線 → 區域網路設定

**Q: JAR文件執行錯誤？**
A: 確保下載的是 "-jar-with-dependencies.jar" 版本（包含所有依賴）

**Q: 150個文件需要多久？**
A: 
- 網路API：~10分鐘（每個4秒）
- JAR本地：~30-45分鐘（每個12-18秒）
- IG Publisher：~75-150分鐘（每個30-60秒）

---

## 📝 下一步行動

**立即執行**（選擇一個）：

### 方案A - DNS修復
```powershell
# 1. 更換DNS
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("8.8.8.8", "8.8.4.4")

# 2. 清除快取
Clear-DnsClientCache

# 3. 測試
node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL/test"

# 4. 成功後批量轉換
node batch_convert_reliable.js "所有CQL資料夾" "ELM_JSON_OFFICIAL/output"
```

### 方案D - 離線JAR
1. 通知有網路的人下載JAR
2. 接收文件後運行convert_offline.ps1
3. 批量處理150個文件
