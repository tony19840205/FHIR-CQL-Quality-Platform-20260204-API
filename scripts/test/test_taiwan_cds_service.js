/**
 * 测试台湾卫福部CDS Hooks服务
 * 网站: https://medstandard.mohw.gov.tw/rule-library/cql-service
 * 
 * 这个服务主要用于执行CQL（通过CDS Hooks），不是转换工具
 * 但可能有相关的API端点
 */

const https = require('https');

console.log('='.repeat(70));
console.log(' 台湾卫福部 CQL/CDS Hooks 服务测试');
console.log('='.repeat(70));

// CDS Hooks 通常使用的端点
const possibleEndpoints = [
    'https://cds.bdiaj.nslcnc-services/09139C',  // 从截图Response看到的
    'https://medstandard.mohw.gov.tw/api/cql',
    'https://medstandard.mohw.gov.tw/api/cds-services',
    'https://medstandard.mohw.gov.tw/cds-services',
];

console.log('\n检查可能的API端点...\n');

function testEndpoint(url) {
    return new Promise((resolve) => {
        try {
            const urlObj = new URL(url);
            const options = {
                hostname: urlObj.hostname,
                port: 443,
                path: urlObj.pathname,
                method: 'GET',
                timeout: 5000,
                headers: {
                    'User-Agent': 'Mozilla/5.0'
                }
            };

            const req = https.get(options, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    resolve({
                        url,
                        status: res.statusCode,
                        headers: res.headers,
                        data: data.substring(0, 200),
                        available: res.statusCode === 200
                    });
                });
            });

            req.on('error', (err) => {
                resolve({
                    url,
                    available: false,
                    error: err.message
                });
            });

            req.on('timeout', () => {
                req.destroy();
                resolve({
                    url,
                    available: false,
                    error: 'Timeout'
                });
            });
        } catch (err) {
            resolve({
                url,
                available: false,
                error: err.message
            });
        }
    });
}

(async () => {
    const results = [];
    
    for (const endpoint of possibleEndpoints) {
        const result = await testEndpoint(endpoint);
        results.push(result);
        
        if (result.available) {
            console.log(`✓ ${endpoint}`);
            console.log(`  状态: ${result.status}`);
            console.log(`  Content-Type: ${result.headers['content-type']}`);
            console.log(`  预览: ${result.data.substring(0, 100)}...`);
        } else {
            console.log(`✗ ${endpoint}`);
            console.log(`  错误: ${result.error || result.status}`);
        }
        console.log('');
    }
    
    console.log('='.repeat(70));
    console.log(' 分析结果');
    console.log('='.repeat(70));
    
    const available = results.filter(r => r.available);
    
    if (available.length > 0) {
        console.log('\n✓ 找到可用端点！');
        available.forEach(r => {
            console.log(`  - ${r.url}`);
        });
        
        console.log('\n这个服务可能支持:');
        console.log('1. CQL执行（通过CDS Hooks）');
        console.log('2. 临床决策支持规则测试');
        console.log('3. FHIR资源查询');
        
        console.log('\n但是：');
        console.log('⚠ CDS Hooks主要用于执行CQL，不是转换CQL→ELM');
        console.log('⚠ 需要上传CQL文件和Patient资源进行测试');
        console.log('⚠ 返回的是临床建议（cards），不是ELM JSON');
        
    } else {
        console.log('\n✗ 未找到可访问的API端点');
        console.log('\n可能原因:');
        console.log('1. 需要登录/认证');
        console.log('2. API端点不公开');
        console.log('3. 需要在网页界面操作');
    }
    
    console.log('\n' + '='.repeat(70));
    console.log(' 建议');
    console.log('='.repeat(70));
    
    console.log('\n方案1: 继续使用ELM JSON生成器（推荐）');
    console.log('  - 已验证100%可执行');
    console.log('  - 不依赖外部服务');
    console.log('  - 完全可控');
    
    console.log('\n方案2: 使用CDS Hooks Sandbox测试CQL执行');
    console.log('  - 打开网页: https://medstandard.mohw.gov.tw/rule-library/cql-service');
    console.log('  - 上传CQL文件');
    console.log('  - 测试临床决策逻辑');
    console.log('  - 但不能获取ELM JSON');
    
    console.log('\n方案3: 联系台湾卫福部');
    console.log('  - Email: medstandard@itri.org.tw');
    console.log('  - 询问是否有CQL转换API');
    console.log('  - 询问是否能导出ELM');
    
})();
