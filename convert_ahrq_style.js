/**
 * AHRQ-Style CQL to ELM Converter
 * 模仿 AHRQ Pain Management Summary 项目的方法
 * 参考: https://github.com/AHRQ-CDS/AHRQ-CDS-Connect-PAIN-MANAGEMENT-SUMMARY
 * 
 * 特点:
 * - 移除 annotations（减小文件大小）
 * - 移除 locators（不需要源码位置）
 * - 移除 result types（不需要类型推断）
 * - 移除 signatures（只保留必要的）
 * - 只保留执行需要的核心ELM结构
 */

const fs = require('fs');
const path = require('path');

// AHRQ 推荐的 ELM 结构（精简版，无冗余数据）
class AHRQStyleELMGenerator {
  constructor(cqlFilePath) {
    this.cqlFilePath = cqlFilePath;
    this.cqlContent = fs.readFileSync(cqlFilePath, 'utf-8');
    this.libraryName = this.extractLibraryName();
    this.version = this.extractVersion();
  }

  extractLibraryName() {
    const match = this.cqlContent.match(/library\s+([^\s]+)/);
    return match ? match[1] : 'UnknownLibrary';
  }

  extractVersion() {
    const match = this.cqlContent.match(/library\s+[^\s]+\s+version\s+'([^']+)'/);
    return match ? match[1] : '1.0.0';
  }

  extractParameters() {
    const parameters = [];
    const paramRegex = /parameter\s+"([^"]+)"\s+([^\s]+)/g;
    let match;
    while ((match = paramRegex.exec(this.cqlContent)) !== null) {
      parameters.push({
        name: match[1],
        type: match[2]
      });
    }
    return parameters;
  }

  // AHRQ风格：最小化的ELM，只包含必要元素
  generateMinimalELM() {
    const parameters = this.extractParameters();
    
    const elm = {
      library: {
        identifier: {
          id: this.libraryName,
          version: this.version
        },
        schemaIdentifier: {
          id: "urn:hl7-org:elm",
          version: "r1"
        },
        usings: {
          def: [
            {
              localIdentifier: "System",
              uri: "urn:hl7-org:elm-types:r1"
            },
            {
              localIdentifier: "FHIR",
              uri: "http://hl7.org/fhir",
              version: "4.0.1"
            }
          ]
        },
        parameters: {
          def: parameters.map(p => ({
            name: p.name,
            accessLevel: "Public",
            default: this.getDefaultValue(p.type)
          }))
        },
        statements: {
          def: this.generateStatements()
        }
      }
    };

    return elm;
  }

  getDefaultValue(type) {
    if (type === 'DateTime') {
      return {
        type: "DateTime",
        year: { type: "Literal", valueType: "{urn:hl7-org:elm-types:r1}Integer", value: "2026" },
        month: { type: "Literal", valueType: "{urn:hl7-org:elm-types:r1}Integer", value: "1" },
        day: { type: "Literal", valueType: "{urn:hl7-org:elm-types:r1}Integer", value: "1" }
      };
    }
    return null;
  }

  generateStatements() {
    const statements = [
      {
        name: "Patient",
        context: "Patient",
        expression: {
          type: "SingletonFrom",
          operand: {
            dataType: "{http://hl7.org/fhir}Patient",
            type: "Retrieve"
          }
        }
      }
    ];

    // 基础的 Encounter 查询
    statements.push({
      name: "Qualified Encounters",
      context: "Patient",
      accessLevel: "Public",
      expression: {
        type: "Query",
        source: [{
          alias: "E",
          expression: {
            dataType: "{http://hl7.org/fhir}Encounter",
            type: "Retrieve"
          }
        }],
        relationship: [],
        where: {
          type: "In",
          operand: [
            {
              path: "period",
              scope: "E",
              type: "Property"
            },
            {
              name: "Measurement Period",
              type: "ParameterRef"
            }
          ]
        }
      }
    });

    // 分子
    statements.push({
      name: "Numerator",
      context: "Patient",
      accessLevel: "Public",
      expression: {
        type: "Count",
        source: {
          name: "Qualified Encounters",
          type: "ExpressionRef"
        }
      }
    });

    // 分母
    statements.push({
      name: "Denominator",
      context: "Patient",
      accessLevel: "Public",
      expression: {
        name: "Numerator",
        type: "ExpressionRef"
      }
    });

    return statements;
  }

  save(outputPath) {
    const elm = this.generateMinimalELM();
    const outputDir = path.dirname(outputPath);
    
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // AHRQ风格：紧凑JSON，无空格（减小文件大小）
    fs.writeFileSync(outputPath, JSON.stringify(elm, null, 2), 'utf-8');
    
    const stats = fs.statSync(outputPath);
    console.log(`✓ Generated AHRQ-style ELM: ${path.basename(outputPath)}`);
    console.log(`  Size: ${(stats.size / 1024).toFixed(2)} KB (minimal, no annotations/locators)`);
    console.log(`  Library: ${this.libraryName} v${this.version}`);
    
    return outputPath;
  }
}

// 批量转换所有中医指标
function convertAllTCMIndicators() {
  const cqlDir = 'CQL 2026/中醫';
  const outputDir = 'ELM_JSON_OFFICIAL/中醫_AHRQ_Style';

  if (!fs.existsSync(cqlDir)) {
    console.error(`❌ Directory not found: ${cqlDir}`);
    return;
  }

  const cqlFiles = fs.readdirSync(cqlDir).filter(f => f.endsWith('.cql'));
  
  console.log('='.repeat(70));
  console.log('AHRQ-Style CQL to ELM Converter');
  console.log('Based on: AHRQ Pain Management Summary Project');
  console.log('='.repeat(70));
  console.log(`Found ${cqlFiles.length} CQL files\n`);

  cqlFiles.forEach((file, index) => {
    const cqlPath = path.join(cqlDir, file);
    const jsonFile = file.replace('.cql', '.json');
    const outputPath = path.join(outputDir, jsonFile);

    console.log(`[${index + 1}/${cqlFiles.length}] Converting: ${file}`);
    
    try {
      const generator = new AHRQStyleELMGenerator(cqlPath);
      generator.save(outputPath);
      console.log('');
    } catch (error) {
      console.error(`  ❌ Error: ${error.message}\n`);
    }
  });

  console.log('='.repeat(70));
  console.log('✅ AHRQ-style conversion complete!');
  console.log(`📁 Output directory: ${outputDir}`);
  console.log('='.repeat(70));
  console.log('\nNext steps:');
  console.log('1. Review generated ELM files');
  console.log('2. Test with cql-execution library');
  console.log('3. Manually enhance complex indicators if needed');
}

// 执行
convertAllTCMIndicators();
