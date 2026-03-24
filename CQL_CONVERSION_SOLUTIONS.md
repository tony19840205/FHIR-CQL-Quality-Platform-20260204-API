# CQL批量轉換解決方案

## 問題診斷

1. ❌ **AHRQ官方API**：網路不可達 (ENOTFOUND)
2. ❌ **Dataphoria API**：網路不可達 (ENOTFOUND)  
3. ❌ **Java JAR (cql-to-elm.jar)**：文件損壞（缺少主要資訊清單屬性）
4. ❌ **IG Publisher**：需要完整IG結構 + 路徑不能有空格

## ✅ 推薦解決方案

### 方案1：手動線上轉換（立即可用）

**適用情況**：少量文件（<10個）

**步驟**：
1. 開啟線上工具：https://cql.dataphoria.org/
2. 將CQL內容貼上
3. 點擊"Translate"
4. 下載ELM JSON

**優點**：
- 無需安裝任何工具
- 100%官方標準
- 立即可用

**缺點**：
- 需要手動操作
- 不適合批量處理150個文件

---

### 方案2：修復網路連線（推薦）

**問題原因**：DNS解析失敗或防火牆封鎖

**解決方案**：

#### A. 檢查DNS設置
```powershell
# 測試DNS
nslookup cql-translation-service.ahrq.gov

# 如果失敗，更換DNS為Google DNS
netsh interface ip set dns "乙太網路" static 8.8.8.8
netsh interface ip add dns "乙太網路" 8.8.4.4 index=2

# 重新測試
node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL/output"
```

#### B. 檢查防火牆
```powershell
# 允許Node.js訪問網路
New-NetFirewallRule -DisplayName "Node.js" -Direction Outbound -Program "C:\Program Files\nodejs\node.exe" -Action Allow
```

#### C. 使用代理（如果公司網路）
```javascript
// 在batch_convert_reliable.js中添加代理設置
const client = new Client(serviceUrl, {
    proxy: {
        host: 'proxy.company.com',
        port: 8080
    }
});
```

**使用方法**（網路修復後）：
```powershell
# 轉換當前文件
node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL/舊50"

# 批量轉換150個文件
node batch_convert_reliable.js "CQL 2026/全部" "ELM_JSON_OFFICIAL/2026Q1"
```

---

### 方案3：下載獨立CQL編譯器（離線方案）

**下載地址**：
https://github.com/cqframework/clinical_quality_language/releases

**選擇版本**：
- cql-to-elm-3.18.0-SNAPSHOT.jar (最新)
- cql-to-elm-3.8.0.jar (穩定)

**重要**：下載後必須驗證JAR完整性：
```powershell
# 檢查JAR是否可執行
java -jar cql-to-elm-3.18.0-SNAPSHOT.jar --version

# 如果顯示"缺少主要資訊清單屬性"，重新下載
```

**使用方法**：
```powershell
java -jar cql-to-elm-3.18.0-SNAPSHOT.jar \
    --input input/cql \
    --output output/elm \
    --format JSON \
    --include-FHIRHelpers
```

**批量轉換腳本**（創建convert_with_jar.ps1）：
```powershell
$jar = "cql-to-elm-3.18.0-SNAPSHOT.jar"
$cqlFiles = Get-ChildItem "cql" -Filter "*.cql"

foreach ($file in $cqlFiles) {
    $out = "ELM_JSON_OFFICIAL\$($file.BaseName).json"
    java -jar $jar $file.FullName --format JSON --output $out
    Write-Host "Converted: $($file.Name)"
}
```

---

### 方案4：使用Docker（最可靠）

**優點**：
- 環境完全隔離
- 官方鏡像保證正確
- 適合批量處理

**步驟**：

1. 安裝Docker Desktop for Windows

2. 創建Dockerfile：
```dockerfile
FROM openjdk:21-slim
WORKDIR /app
ADD https://github.com/cqframework/clinical_quality_language/releases/download/v3.18.0/cql-to-elm-3.18.0-SNAPSHOT.jar cql-to-elm.jar
COPY cql/ /app/input/
CMD ["java", "-jar", "cql-to-elm.jar", "--input", "/app/input", "--output", "/app/output", "--format", "JSON"]
```

3. 運行：
```powershell
docker build -t cql-converter .
docker run -v "${PWD}/output:/app/output" cql-converter
```

---

## 當前可用工具

### batch_convert_reliable.js（Node.js）

**特點**：
- 自動測試3個轉換服務
- 支持FHIRHelpers
- 批量處理
- 進度顯示

**依賴**：
- Node.js已安裝 ✅
- cql-translation-service-client已安裝 ✅
- **需要網路連線** ❌（當前問題）

**修復網路後使用**：
```powershell
# 單個資料夾
node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL/舊50"

# 150個文件
node batch_convert_reliable.js "所有CQL" "ELM_JSON_OFFICIAL/all"
```

---

### ConvertCQL.ps1（PowerShell + IG Publisher）

**特點**：
- 使用本地IG Publisher
- 無需網路連線
- 已安裝fhir-ig-publisher.jar (218MB)

**問題**：
- 需要完整IG項目結構
- 路徑不能有空格（當前工作區有空格："UI UX- 20260108"）
- 配置複雜

**臨時解決方案**：
1. 將整個項目複製到無空格路徑：
```powershell
Copy-Item "C:\Users\tony1\Desktop\UI UX- 20260108" "C:\CQL_Work" -Recurse
cd C:\CQL_Work
.\ConvertCQL.ps1 -CqlFolder "cql" -OutputFolder "ELM_JSON_OFFICIAL/output"
```

---

## 立即行動方案（150個文件）

### 優先級1：修復網路（最快）

```powershell
# 1. 測試網路
Test-NetConnection cql-translation-service.ahrq.gov -Port 443

# 2. 如果失敗，更換DNS
netsh interface ip set dns "乙太網路" static 8.8.8.8

# 3. 重新測試
node batch_convert_reliable.js "cql" "ELM_JSON_OFFICIAL/test"

# 4. 成功後批量轉換
node batch_convert_reliable.js "所有CQL" "ELM_JSON_OFFICIAL/2026Q1"
```

### 優先級2：下載正確的JAR（最可靠）

1. 到GitHub手動下載：
   https://github.com/cqframework/clinical_quality_language/releases/tag/v3.18.0

2. 下載：cql-to-elm-3.18.0-SNAPSHOT-jar-with-dependencies.jar

3. 驗證：
```powershell
java -jar cql-to-elm-3.18.0-SNAPSHOT-jar-with-dependencies.jar --help
```

4. 批量轉換（創建腳本）

### 優先級3：遷移到無空格路徑

```powershell
# 1. 複製項目
Copy-Item "C:\Users\tony1\Desktop\UI UX- 20260108" "C:\CQL_Project" -Recurse

# 2. 切換目錄
cd C:\CQL_Project

# 3. 使用IG Publisher方案
.\ConvertCQL.ps1 -CqlFolder "cql" -OutputFolder "ELM_JSON_OFFICIAL/output"
```

---

## 測試狀態

| 方法 | 狀態 | 問題 | 解決方案 |
|------|------|------|----------|
| AHRQ API | ❌ | ENOTFOUND | 修復DNS/防火牆 |
| Dataphoria API | ❌ | ENOTFOUND | 修復DNS/防火牆 |
| Java JAR | ❌ | 損壞 | 重新下載正確版本 |
| IG Publisher | ⚠️ | 路徑空格 | 遷移到無空格路徑 |
| 線上工具 | ✅ | 手動操作 | 適合少量文件 |

---

## 建議

**對於150個文件的批量轉換：**

1. **首選**：修復網路連線 → 使用`batch_convert_reliable.js`
   - 最快（網路修復後5-10分鐘完成150個文件）
   - 最可靠（官方API）
   
2. **備選**：下載正確的JAR → 創建批量腳本
   - 完全離線
   - 一次設置，永久可用

3. **臨時**：遷移到無空格路徑 → 使用IG Publisher
   - 需要額外設置
   - 較慢（每個文件30-60秒）

**當前立即可做的：**
1. 測試是否為DNS問題（5分鐘）
2. 如果是DNS，更換為8.8.8.8（1分鐘）
3. 重新運行batch_convert_reliable.js（10分鐘完成150個文件）

**時間估算：**
- 網路修復方案：15-20分鐘完成所有150個文件
- JAR下載方案：30-45分鐘（含下載和設置）
- IG Publisher方案：75-150分鐘（150個文件 × 30-60秒）
