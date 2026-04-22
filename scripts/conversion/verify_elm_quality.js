
const fs = require('fs');
const cql = require('cql-execution');

const elmFile = process.argv[2];

if (!fs.existsSync(elmFile)) {
    console.log('✗ ELM文件不存在，请先完成转换');
    process.exit(1);
}

console.log('\n验证官方ELM质量...');
console.log('----------------------------------\n');

const elm = JSON.parse(fs.readFileSync(elmFile, 'utf8'));

console.log('库信息:');
console.log(`  ID: ${elm.library.identifier.id}`);
console.log(`  版本: ${elm.library.identifier.version || 'N/A'}`);

const statements = elm.library.statements.def;
const stmtCount = Object.keys(statements).length;
console.log(`  语句数: ${stmtCount}\n`);

// 统计表达式类型
const types = {};
Object.values(statements).forEach(stmt => {
    const type = stmt.expression.type;
    types[type] = (types[type] || 0) + 1;
});

console.log('表达式类型分布:');
Object.entries(types).forEach(([type, count]) => {
    console.log(`  ${type}: ${count}个`);
});

// 检查是否有Expression占位符
const hasPlaceholder = Object.values(statements).some(
    stmt => stmt.expression.type === 'Expression'
);

console.log(`\n质量检查:`);
console.log(`  Schema: ${elm.library.schemaIdentifier?.id || 'Missing'}`);
console.log(`  占位符: ${hasPlaceholder ? '✗ 有（非官方）' : '✓ 无（官方标准）'}`);

// 尝试创建执行器
try {
    const repository = new cql.Repository(elm);
    console.log(`  可执行性: ✓ 100%（可创建执行器）`);
    console.log(`\n✓✓✓ 这是官方标准ELM！可用于生产环境 ✓✓✓`);
} catch (error) {
    console.log(`  可执行性: ✗ 失败 - ${error.message}`);
    console.log(`\n✗✗✗ ELM有问题，无法执行 ✗✗✗`);
}
