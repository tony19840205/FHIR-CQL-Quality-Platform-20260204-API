# DNS修復結果報告

## 執行狀態

### ✅ 已完成
1. DNS伺服器已更換為Google DNS (8.8.8.8, 8.8.4.4)
2. DNS快取已清除
3. PowerShell可以解析部分域名 (ahrq.gov)

### ❌ 仍存在問題
1. **Node.js無法連接CQL轉換服務**
   - 錯誤: `getaddrinfo ENOTFOUND cql-translation-service.ahrq.gov`
   - 原因: 公司網路可能有防火牆或DNS過濾

2. **JAR文件損壞**
   - cql-to-elm.jar: 缺少主要資訊清單屬性
   - 無法用於離線轉換

## 根本問題分析

**公司網路限制**：
- DNS可以部分解析（ahrq.gov可以，但子域名cql-translation-service.ahrq.gov不行）
- 可能有：
  * DNS過濾/黑名單
  * 防火牆規則封鎖特定域名
  * 需要公司代理伺服器

## 📋 實用的150個文件轉換方案

### ⭐ 方案1：使用線上工具（最實用）

**適用**：有瀏覽器，可訪問外網

**工具**：https://cql.dataphoria.org/

**步驟**：
1. 開啟線上工具
2. 貼上CQL代碼
3. 點擊 "Translate to ELM"
4. 複製JSON並保存

**批量處理方法**：
```powershell
# 創建自動化腳本
$files = Get-ChildItem "cql" -Filter "*.cql"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # 方法1: 使用剪貼簿
    Set-Clipboard $content
    Write-Host "$($file.Name) 已複製到剪貼簿"
    Write-Host "請在瀏覽器中貼上並轉換"
    Write-Host "按Enter繼續下一個..."
    Read-Host
    
    # 方法2: 保存JSON（從瀏覽器複製後）
    Write-Host "請將轉換結果貼上並按Enter..."
    $json = Get-Clipboard
    $json | Out-File "ELM_JSON_OFFICIAL\$($file.BaseName).json" -Encoding UTF8
}
```

**時間估算**：150個文件 × 30秒 = 75分鐘

---

### ⭐ 方案2：下載正確的JAR文件（最可靠）

**在有網路的電腦上**：

1. 訪問：https://github.com/cqframework/clinical_quality_language/releases/latest

2. 下載：`cql-to-elm-VERSION-jar-with-dependencies.jar`
   （注意：必須是 `-jar-with-dependencies.jar` 版本）

3. 使用USB或網路分享複製到工作電腦

4. 驗證JAR：
```powershell
java -jar cql-to-elm-xxx-jar-with-dependencies.jar --help
```

5. 批量轉換：
```powershell
$jar = "cql-to-elm-xxx-jar-with-dependencies.jar"
$files = Get-ChildItem "cql" -Filter "*.cql"

foreach ($file in $files) {
    $out = "ELM_JSON_OFFICIAL\$($file.BaseName).json"
    java -jar $jar `
        --input $file.FullName `
        --output $out `
        --format JSON
    
    Write-Host "Converted: $($file.Name)"
}
```

**時間估算**：30-45分鐘（含下載和設置）

---

### ⭐ 方案3：使用其他電腦/網路

**選項A：家中網路**
```powershell
# 複製整個項目到USB
Copy-Item "C:\Users\tony1\Desktop\UI UX- 20260108" "D:\CQL_Backup" -Recurse

# 在家中運行
cd "D:\CQL_Backup"
node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL\output"

# 完成後複製回公司
```

**選項B：手機熱點**
1. 開啟手機熱點
2. 電腦連接手機網路
3. 運行批量轉換工具
4. 完成後切換回公司網路

---

### ⭐ 方案4：請IT部門協助

**需要IT部門做的事**：

```
主旨：請求開放CQL轉換服務的網路訪問

需要訪問的域名：
- cql-translation-service.ahrq.gov (HTTPS/443)
- cql.dataphoria.org (HTTPS/443)

用途：醫療品質指標CQL轉換為ELM JSON

時間：約20分鐘批量處理
```

---

## 🔧 已創建的工具

### 可用工具
1. **FixDNS_Admin.ps1** - DNS修復腳本（需管理員）
2. **batch_convert_reliable.js** - 批量轉換（需網路）
3. **convert_offline.js** - 離線轉換（需正確的JAR）
4. **ConvertCQL.ps1** - IG Publisher方案（需無空格路徑）

### 診斷工具
```powershell
# 測試DNS
Resolve-DnsName cql-translation-service.ahrq.gov

# 測試TCP連線
Test-NetConnection cql-translation-service.ahrq.gov -Port 443

# 檢查代理
netsh winhttp show proxy

# 查看當前DNS
Get-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4
```

---

## 📊 方案比較

| 方案 | 時間 | 難度 | 可行性 | 推薦度 |
|------|------|------|--------|--------|
| 線上工具 | 75分鐘 | ⭐ | ✅ 高 | ⭐⭐⭐⭐ |
| 下載JAR | 45分鐘 | ⭐⭐ | ✅ 高 | ⭐⭐⭐⭐⭐ |
| 其他網路 | 20分鐘 | ⭐ | ⚠️ 中 | ⭐⭐⭐ |
| IT協助 | ? | ⭐⭐⭐ | ⚠️ 中 | ⭐⭐ |
| 當前DNS修復 | - | ⭐⭐⭐ | ❌ 低 | ⭐ |

---

## 🎯 立即建議

**最快可執行方案**：

### 今天完成（使用線上工具）

1. 開啟：https://cql.dataphoria.org/
2. 測試轉換一個文件
3. 如果成功，繼續處理150個文件

**自動化腳本**：
```powershell
# 創建輔助腳本
$files = Get-ChildItem "cql" -Filter "*.cql"
$i = 1

foreach ($file in $files) {
    Write-Host "`n[$i/$($files.Count)] $($file.Name)" -ForegroundColor Cyan
    
    # 複製到剪貼簿
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    Set-Clipboard $content
    
    Write-Host "✅ CQL已複製到剪貼簿" -ForegroundColor Green
    Write-Host "請在瀏覽器中:" -ForegroundColor Yellow
    Write-Host "  1. 貼上CQL代碼" -ForegroundColor White
    Write-Host "  2. 點擊Translate" -ForegroundColor White
    Write-Host "  3. 複製JSON結果" -ForegroundColor White
    Write-Host "  4. 回到此視窗按Enter" -ForegroundColor White
    
    Read-Host "`n按Enter繼續"
    
    # 保存JSON（從剪貼簿）
    $json = Get-Clipboard
    if ($json -match '"library"') {
        $outFile = "ELM_JSON_OFFICIAL\auto\$($file.BaseName).json"
        if (-not (Test-Path "ELM_JSON_OFFICIAL\auto")) {
            New-Item "ELM_JSON_OFFICIAL\auto" -ItemType Directory -Force | Out-Null
        }
        $json | Out-File $outFile -Encoding UTF8
        Write-Host "✅ 已保存: $outFile" -ForegroundColor Green
    }
    
    $i++
}

Write-Host "`n✅ 完成！" -ForegroundColor Green
```

保存為：`AutoConvert_Web.ps1`

---

### 明天完成（下載JAR）

1. 通知可以訪問GitHub的同事/朋友
2. 下載正確的JAR文件
3. 接收後運行批量轉換
4. 30分鐘內完成所有150個文件

---

## 📝 當前網路狀態

```
DNS伺服器: 8.8.8.8, 8.8.4.4 ✅
DNS解析: 部分成功（ahrq.gov可，子域名不行）⚠️
TCP連線: 測試失敗 ❌
公司網路限制: 可能存在 ⚠️
```

**結論**：DNS修復無法完全解決問題，需要使用替代方案。

**推薦**：
1. 立即：使用線上工具開始轉換
2. 並行：請人下載正確的JAR文件
3. 備選：聯繫IT部門開放網路訪問
