const fs = require('fs');
const https = require('https');

// 尝试多个在线CQL-to-ELM服务
const services = [
  {
    name: 'CQL Translation Service',
    url: 'cql.dataphoria.org',
    port: 443,
    path: '/cql/translator',
    method: 'POST'
  }
];

async function convertCQLToELM(cqlFilePath) {
  console.log('正在读取CQL文件...');
  const cqlContent = fs.readFileSync(cqlFilePath, 'utf-8');
  
  console.log(`文件大小: ${cqlContent.length} bytes`);
  console.log('');
  
  for (const service of services) {
    console.log(`尝试服务: ${service.name}`);
    console.log(`URL: https://${service.url}${service.path}`);
    
    try {
      const result = await callService(service, cqlContent);
      
      if (result.success) {
        console.log('✅ 转换成功!');
        return result.elm;
      } else {
        console.log(`❌ 失败: ${result.error}`);
      }
    } catch (err) {
      console.log(`❌ 错误: ${err.message}`);
    }
    
    console.log('');
  }
  
  console.log('所有服务都失败了');
  return null;
}

function callService(service, cqlContent) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      cql: cqlContent,
      annotations: true,
      locators: true,
      resultTypes: true,
      signatures: 'All'
    });
    
    const options = {
      hostname: service.url,
      port: service.port,
      path: service.path,
      method: service.method,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 10000
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const parsed = JSON.parse(data);
            resolve({ success: true, elm: parsed });
          } catch (err) {
            resolve({ success: false, error: `解析失败: ${err.message}` });
          }
        } else {
          resolve({ success: false, error: `HTTP ${res.statusCode}` });
        }
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('请求超时'));
    });
    
    req.write(postData);
    req.end();
  });
}

// 主程序
const cqlFile = process.argv[2] || 'CQL 2026/中醫/Indicator_TCM_Same_Day_Revisit_Rate.cql';
const outputFile = process.argv[3] || 'output_official.json';

console.log('╔═══════════════════════════════════════════════════════════════╗');
console.log('║         在线CQL-to-ELM转换服务                                ║');
console.log('╚═══════════════════════════════════════════════════════════════╝');
console.log('');
console.log(`输入文件: ${cqlFile}`);
console.log(`输出文件: ${outputFile}`);
console.log('');

convertCQLToELM(cqlFile).then(elm => {
  if (elm) {
    fs.writeFileSync(outputFile, JSON.stringify(elm, null, 2), 'utf-8');
    console.log('');
    console.log(`✅ ELM已保存到: ${outputFile}`);
    console.log('');
    console.log('📊 ELM统计:');
    if (elm.library && elm.library.statements) {
      const stmtCount = elm.library.statements.def ? elm.library.statements.def.length : 0;
      console.log(`   语句数: ${stmtCount}`);
    }
  } else {
    console.log('❌ 转换失败');
    process.exit(1);
  }
}).catch(err => {
  console.error('错误:', err);
  process.exit(1);
});
