# 🎯 本地CQL轉換服務部署方案

## ✅ 最佳方案：運行本地翻譯服務

GitHub官方提供了 **cql-translation-service**，可以在本地運行！

### 優點
- ✅ 完全離線，不需要外部網路
- ✅ 官方支持，最新版本 v2.7.1
- ✅ 使用 CQL Tools 3.22.0
- ✅ 與線上API完全相同
- ✅ 批量轉換150個文件：10-15分鐘

---

## 方案A：使用Java直接運行（推薦）

### 步驟1：下載服務

訪問：https://github.com/cqframework/cql-translation-service/releases/tag/v2.7.1

下載：**cqlTranslationServer-2.7.1.jar** 和 **libs.zip**

### 步驟2：解壓並準備

```powershell
# 創建目錄
New-Item "cql-service" -ItemType Directory -Force
cd cql-service

# 將下載的檔案放入此目錄
# - cqlTranslationServer-2.7.1.jar
# - 解壓 libs.zip 到 libs/ 資料夾

# 目錄結構應該是：
# cql-service/
#   ├── cqlTranslationServer-2.7.1.jar
#   └── libs/
#       ├── ... (所有依賴jar文件)
```

### 步驟3：啟動服務

```powershell
# 啟動CQL轉換服務（在8080端口）
java -jar cqlTranslationServer-2.7.1.jar

# 或指定其他端口
$env:CQL_TRANSLATOR_PORT=9090
java -jar cqlTranslationServer-2.7.1.jar
```

服務啟動後會顯示：
```
Started CqlTranslationServer in X.XXX seconds
```

### 步驟4：測試服務

在**另一個PowerShell視窗**執行：
```powershell
# 測試服務是否運行
Invoke-WebRequest http://localhost:8080/cql/formatter -Method GET
```

### 步驟5：批量轉換

使用提供的轉換腳本：
```powershell
node batch_convert_local.js "cql" "ELM_JSON_OFFICIAL/output"
```

---

## 方案B：使用Docker（最簡單，需安裝Docker）

### 步驟1：安裝Docker Desktop

下載：https://www.docker.com/products/docker-desktop

### 步驟2：運行服務

```powershell
# 拉取並運行官方鏡像
docker run -d -p 8080:8080 --name cql-service cqframework/cql-translation-service:latest

# 查看服務狀態
docker ps

# 查看日誌
docker logs cql-service
```

### 步驟3：批量轉換

```powershell
node batch_convert_local.js "cql" "ELM_JSON_OFFICIAL/output"
```

### 停止服務

```powershell
docker stop cql-service
docker rm cql-service
```

---

## 方案C：使用Maven本地編譯（進階）

如果已安裝Maven：

```powershell
# 克隆倉庫
git clone https://github.com/cqframework/cql-translation-service.git
cd cql-translation-service

# 編譯
mvn package

# 運行
java -jar target/cqlTranslationServer-2.7.1.jar
```

---

## 📝 使用本地服務的批量轉換腳本

已創建：`batch_convert_local.js`

特點：
- 連接本地服務（http://localhost:8080）
- 無需外部網路
- 支持批量處理
- 進度顯示

使用方法：
```powershell
# 啟動本地服務（在一個視窗）
java -jar cqlTranslationServer-2.7.1.jar

# 運行轉換（在另一個視窗）
node batch_convert_local.js "cql" "ELM_JSON_OFFICIAL/output"
```

---

## ⚡ 快速開始指南

### 今天立即可做（不需要Docker）：

1. **下載文件**（5分鐘）
   - 訪問：https://github.com/cqframework/cql-translation-service/releases/tag/v2.7.1
   - 下載：`cqlTranslationServer-2.7.1.jar`
   - 下載：`libs.zip`（約100MB）

2. **準備環境**（2分鐘）
   ```powershell
   New-Item "cql-service" -ItemType Directory
   # 將jar和解壓的libs/移到此目錄
   ```

3. **啟動服務**（1分鐘）
   ```powershell
   cd cql-service
   java -jar cqlTranslationServer-2.7.1.jar
   ```

4. **批量轉換**（15分鐘）
   ```powershell
   # 在另一個視窗
   node batch_convert_local.js "cql" "ELM_JSON_OFFICIAL/output"
   ```

**總時間：約25分鐘完成所有150個文件！**

---

## 🔧 故障排除

### Q: 服務無法啟動
A: 確保libs/目錄與jar在同一目錄，並包含所有依賴

### Q: 端口8080被佔用
A: 使用環境變數更改端口：
```powershell
$env:CQL_TRANSLATOR_PORT=9090
java -jar cqlTranslationServer-2.7.1.jar
```
然後修改batch_convert_local.js中的端口號

### Q: Java版本問題
A: 需要Java 11或更高版本
```powershell
java -version
```

---

## 📊 方案對比

| 方案 | 下載大小 | 設置時間 | 轉換時間 | 難度 |
|------|---------|---------|---------|------|
| Java本地服務 | ~100MB | 5分鐘 | 15分鐘 | ⭐⭐ |
| Docker | ~200MB | 10分鐘 | 15分鐘 | ⭐ |
| 線上工具 | 0 | 0 | 75分鐘 | ⭐ |
| 下載JAR | ~50MB | 30分鐘 | 45分鐘 | ⭐⭐⭐ |

**推薦：Java本地服務** - 平衡速度和易用性

---

## 🎯 下一步

您想要：
1. 我協助您下載並設置本地服務？
2. 創建自動化部署腳本？
3. 先測試Docker方案（如果您願意安裝Docker）？
