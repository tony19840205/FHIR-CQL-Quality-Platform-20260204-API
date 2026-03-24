# Indicator 15-2 轉換步驟 (使用 Translator 3.10.0)

## 與 15-1 相同的方法

### 步驟 1: 在 VS Code 中查看 ELM

1. **確認文件已打開**: `Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.cql`
2. **按 `Ctrl+Shift+P`** 打開命令面板
3. **輸入**: `CQL: View ELM`
4. **選擇**: "CQL: View ELM" 命令
5. **等待生成**: VS Code 會在新窗口顯示 ELM JSON

### 步驟 2: 複製 ELM JSON

1. **全選**: `Ctrl+A`
2. **複製**: `Ctrl+C`

### 步驟 3: 保存文件

保存到: `ELM_JSON_OFFICIAL\舊50\Indicator_15_2_Total_Knee_Arthroplasty_90Day_Deep_Infection_3249.json`

### 質量標準（參考 15-1）

- ✓ 檔案大小: >= 50 KB (15-1 是 78 KB)
- ✓ 行數: >= 1000 行
- ✓ Translator Version: 3.10.0
- ✓ 包含所有主要定義

### 執行完成後

執行 PowerShell 腳本進行質量檢查:
```powershell
.\check_15_2_elm_quality.ps1
```
