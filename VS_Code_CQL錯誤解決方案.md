# VS Code CQL插件錯誤解決方案

## 錯誤信息
```
Command 'CQL: View ELM' resulted in an error
Cannot read properties of undefined (reading 'toString')
```

## 問題原因
VS Code CQL插件在處理某些CQL文件時出現內部錯誤，可能原因：
1. 插件版本問題
2. CQL文件中的某些語法觸發了插件bug
3. FHIRHelpers依賴解析問題

## 解決方案

### 方案1: 重新加載VS Code（推薦首選）
1. 按 `Ctrl + Shift + P`
2. 輸入並選擇: **"Developer: Reload Window"**
3. 等待窗口重新加載
4. 重新嘗試 "CQL: View ELM"

### 方案2: 嘗試更簡單的CQL文件（測試）
先測試更簡單的CQL文件是否可以轉換：

**測試文件**: `Indicator_TCM_Same_Day_Revisit_Rate.cql`

1. 打開此文件
2. `Ctrl+Shift+P` → "CQL: View ELM"
3. 如果成功，說明 `Indicator_TCM_Traumatology_Rate.cql` 可能有特定問題
4. 如果也失敗，說明是插件配置問題

### 方案3: 檢查VS Code Output面板
1. 按 `Ctrl + Shift + U` 打開Output面板
2. 在右上角下拉選擇: **"CQL Language Server"**
3. 查看詳細錯誤日誌
4. 截圖錯誤信息並報告

### 方案4: 重新安裝CQL插件
1. 按 `Ctrl + Shift + X` 打開Extensions
2. 搜索 "CQL"
3. 卸載 "CQL" 插件 (cqframework.cql)
4. 重啟VS Code
5. 重新安裝插件
6. 重新配置 `.vscode/settings.json`

### 方案5: 使用臨時工作區（繞過路徑問題）
路徑中的空格可能導致問題："UI UX- 20260108"

1. 創建新的無空格路徑: `C:\CQL_Project`
2. 複製所需文件到該目錄:
   ```powershell
   $newPath = "C:\CQL_Project"
   New-Item -ItemType Directory -Path $newPath -Force
   Copy-Item "CQL 2026" $newPath -Recurse
   ```
3. 在VS Code中打開 `C:\CQL_Project`
4. 配置 `.vscode/settings.json`
5. 嘗試轉換

### 方案6: 手動創建官方級別ELM（最後手段）
如果VS Code插件完全無法使用，我們可以使用增強版轉換器作為基礎，然後：

1. 使用增強版轉換生成基礎ELM
2. 參考官方ELM示例手動補全缺失部分
3. 使用 `cql-execution` 測試執行

## 立即行動

### 第一步: 重新加載窗口
```
Ctrl + Shift + P → "Developer: Reload Window"
```

### 第二步: 測試簡單文件
打開: `CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql`
執行: `Ctrl + Shift + P` → "CQL: View ELM"

### 第三步: 報告結果
如果仍然失敗，檢查Output面板的詳細錯誤信息

## 備選：批量轉換腳本（如果VS Code無法修復）

我可以創建一個腳本：
1. 讀取所有8個中醫CQL文件
2. 使用Node.js的CQL解析器
3. 生成盡可能接近官方的ELM（85-90%完整度）
4. 足以用於大多數執行場景

## 需要幫助？
告訴我：
1. 重新加載後是否解決？
2. 測試簡單文件是否成功？
3. Output面板顯示什麼錯誤？
4. 是否想嘗試無空格路徑方案？
