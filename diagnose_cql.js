/**
 * CQL語法診斷工具
 * 檢查CQL文件的常見問題
 */

const fs = require('fs');
const path = require('path');

const cqlFile = process.argv[2] || 'CQL 2026/中醫/Indicator_TCM_Traumatology_Rate.cql';

console.log('='.repeat(70));
console.log(' CQL文件診斷工具');
console.log('='.repeat(70));

try {
    const content = fs.readFileSync(cqlFile, 'utf-8');
    const lines = content.split('\n');
    
    console.log(`\n文件: ${cqlFile}`);
    console.log(`行數: ${lines.length}`);
    console.log(`大小: ${(content.length / 1024).toFixed(2)} KB`);
    
    // 檢查library聲明
    const libraryMatch = content.match(/^library\s+(\w+)\s+version\s+'([^']+)'/m);
    if (libraryMatch) {
        console.log(`\n✓ Library聲明: ${libraryMatch[1]} v${libraryMatch[2]}`);
    } else {
        console.log('\n✗ 錯誤: 未找到library聲明');
    }
    
    // 檢查using聲明
    const usingMatch = content.match(/^using\s+(\w+)\s+version\s+'([^']+)'/m);
    if (usingMatch) {
        console.log(`✓ Using聲明: ${usingMatch[1]} v${usingMatch[2]}`);
    } else {
        console.log('⚠ 警告: 未找到using聲明');
    }
    
    // 檢查include聲明
    const includeMatches = content.matchAll(/^include\s+(\w+)(?:\s+version\s+'([^']+)')?\s+called\s+(\w+)/gm);
    const includes = [...includeMatches];
    if (includes.length > 0) {
        console.log(`\n✓ Include聲明 (${includes.length}個):`);
        includes.forEach(m => {
            console.log(`  - ${m[1]} ${m[2] ? 'v' + m[2] : ''} as ${m[3]}`);
        });
    } else {
        console.log('\n⚠ 警告: 未找到include聲明');
    }
    
    // 檢查codesystem聲明
    const codesystemMatches = content.matchAll(/^codesystem\s+"([^"]+)":\s+'([^']+)'/gm);
    const codesystems = [...codesystemMatches];
    if (codesystems.length > 0) {
        console.log(`\n✓ CodeSystem聲明 (${codesystems.length}個):`);
        codesystems.forEach(m => {
            console.log(`  - ${m[1]}`);
        });
    }
    
    // 檢查parameter聲明
    const paramMatches = content.matchAll(/^parameter\s+(\w+)\s+(\w+(?:<[^>]+>)?)/gm);
    const params = [...paramMatches];
    if (params.length > 0) {
        console.log(`\n✓ Parameter聲明 (${params.length}個):`);
        params.forEach(m => {
            console.log(`  - ${m[1]}: ${m[2]}`);
        });
    }
    
    // 檢查define聲明
    const defineMatches = content.matchAll(/^define\s+"([^"]+)":/gm);
    const defines = [...defineMatches];
    if (defines.length > 0) {
        console.log(`\n✓ Define聲明 (${defines.length}個):`);
        defines.slice(0, 10).forEach(m => {
            console.log(`  - "${m[1]}"`);
        });
        if (defines.length > 10) {
            console.log(`  ... 還有 ${defines.length - 10} 個`);
        }
    }
    
    // 檢查潛在問題
    console.log('\n檢查潛在問題...');
    
    let issues = 0;
    
    // 檢查未閉合的括號
    const openParens = (content.match(/\(/g) || []).length;
    const closeParens = (content.match(/\)/g) || []).length;
    if (openParens !== closeParens) {
        console.log(`✗ 括號不匹配: ( ${openParens} 個, ) ${closeParens} 個`);
        issues++;
    }
    
    // 檢查未閉合的花括號
    const openBraces = (content.match(/\{/g) || []).length;
    const closeBraces = (content.match(/\}/g) || []).length;
    if (openBraces !== closeBraces) {
        console.log(`✗ 花括號不匹配: { ${openBraces} 個, } ${closeBraces} 個`);
        issues++;
    }
    
    // 檢查未閉合的方括號
    const openBrackets = (content.match(/\[/g) || []).length;
    const closeBrackets = (content.match(/\]/g) || []).length;
    if (openBrackets !== closeBrackets) {
        console.log(`✗ 方括號不匹配: [ ${openBrackets} 個, ] ${closeBrackets} 個`);
        issues++;
    }
    
    // 檢查未閉合的引號
    lines.forEach((line, idx) => {
        const singleQuotes = (line.match(/'/g) || []).length;
        const doubleQuotes = (line.match(/"/g) || []).length;
        
        if (singleQuotes % 2 !== 0 && !line.trim().startsWith('//') && !line.trim().startsWith('*')) {
            console.log(`⚠ 行 ${idx + 1}: 單引號可能未閉合`);
        }
        if (doubleQuotes % 2 !== 0 && !line.trim().startsWith('//') && !line.trim().startsWith('*')) {
            console.log(`⚠ 行 ${idx + 1}: 雙引號可能未閉合`);
        }
    });
    
    if (issues === 0) {
        console.log('✓ 未發現明顯的語法問題');
    }
    
    console.log('\n' + '='.repeat(70));
    console.log(' 診斷完成');
    console.log('='.repeat(70));
    
    console.log('\n建議：');
    console.log('1. 確保FHIRHelpers-4.0.1.cql存在於 CQL 2026/FHIRHelpers/');
    console.log('2. 重新加載VS Code窗口: Ctrl+Shift+P → "Reload Window"');
    console.log('3. 檢查VS Code輸出面板的CQL Language Server日誌');
    console.log('4. 嘗試更簡單的CQL文件測試');
    
} catch (error) {
    console.error('\n✗ 錯誤:', error.message);
}
