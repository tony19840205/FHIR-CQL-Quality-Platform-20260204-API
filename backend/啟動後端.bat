@echo off
chcp 65001 >nul
echo.
echo ╔════════════════════════════════════════════════════╗
echo ║        醫療品質指標後端 - 啟動程式                ║
echo ╚════════════════════════════════════════════════════╝
echo.
echo 📦 檢查套件...
if not exist "node_modules\" (
    echo ⚠️  尚未安裝套件，開始安裝...
    call npm install
    echo ✅ 套件安裝完成
) else (
    echo ✅ 套件已安裝
)
echo.
echo 🚀 啟動後端伺服器...
echo.
node server.js
pause
