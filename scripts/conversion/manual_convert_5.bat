@echo off
chcp 65001 >nul
echo.
echo === 手動轉換5個CQL文件 ===
echo.

set OUTPUT=ELM_JSON_OFFICIAL\舊50
if not exist "%OUTPUT%" mkdir "%OUTPUT%"

echo [1/5] Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql
type "cql\Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.cql" | clip
echo   已複製到剪貼簿
echo.
echo   請在瀏覽器 (https://cql.dataphoria.org/):
echo   1. 貼上CQL (Ctrl+V)
echo   2. 點擊 Translate to ELM
echo   3. 複製右側JSON (Ctrl+A, Ctrl+C)
echo   4. 回來按任意鍵
pause >nul

powershell -Command "Get-Clipboard | Out-File '%OUTPUT%\Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.json' -Encoding UTF8"
echo   已保存
echo.

echo [2/5] Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql
type "cql\Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.cql" | clip
echo   已複製到剪貼簿
echo.
echo   請重複上述步驟
pause >nul

powershell -Command "Get-Clipboard | Out-File '%OUTPUT%\Indicator_03_2_Same_Hospital_Lipid_Lowering_Overlap_1711.json' -Encoding UTF8"
echo   已保存
echo.

echo [3/5] Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql
type "cql\Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.cql" | clip
echo   已複製到剪貼簿
pause >nul

powershell -Command "Get-Clipboard | Out-File '%OUTPUT%\Indicator_03_3_Same_Hospital_Antidiabetic_Overlap_1712.json' -Encoding UTF8"
echo   已保存
echo.

echo [4/5] Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql
type "cql\Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.cql" | clip
echo   已複製到剪貼簿
pause >nul

powershell -Command "Get-Clipboard | Out-File '%OUTPUT%\Indicator_03_4_Same_Hospital_Antipsychotic_Overlap_1726.json' -Encoding UTF8"
echo   已保存
echo.

echo [5/5] Waste.cql
type "cql\Waste.cql" | clip
echo   已複製到剪貼簿
pause >nul

powershell -Command "Get-Clipboard | Out-File '%OUTPUT%\Waste.json' -Encoding UTF8"
echo   已保存
echo.

echo.
echo === 轉換完成！===
echo 輸出目錄: %OUTPUT%
echo.
dir "%OUTPUT%\*.json" /b
pause
