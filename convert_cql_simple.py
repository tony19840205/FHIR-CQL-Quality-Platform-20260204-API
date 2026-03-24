"""
CQL 转 ELM JSON 简化版
直接读取CQL文件并生成基础的ELM JSON结构
"""
import os
import json
import re
from pathlib import Path

def parse_cql_to_elm(cql_content, filename):
    """解析CQL内容并生成基础ELM JSON"""
    
    # 提取library声明
    library_match = re.search(r'library\s+(\w+)\s+version\s+[\'"]([^\'"]+)[\'"]', cql_content)
    if not library_match:
        library_name = filename.replace('.cql', '')
        version = '1.0.0'
    else:
        library_name = library_match.group(1)
        version = library_match.group(2)
    
    # 提取using声明
    using_matches = re.findall(r'using\s+(\w+)\s+version\s+[\'"]([^\'"]+)[\'"]', cql_content)
    usings = [{"localIdentifier": model, "version": ver} for model, ver in using_matches]
    
    # 提取include声明
    include_matches = re.findall(r'include\s+(\w+)(?:\s+version\s+[\'"]([^\'"]+)[\'"])?\s+called\s+(\w+)', cql_content)
    includes = [{"localIdentifier": alias, "path": lib, "version": ver or "1.0.0"} for lib, ver, alias in include_matches]
    
    # 提取parameter声明
    parameter_matches = re.findall(r'parameter\s+"([^"]+)"\s+(\w+(?:<[^>]+>)?)', cql_content)
    parameters = [{"name": name, "accessLevel": "Public", "parameterTypeSpecifier": {"type": ptype}} for name, ptype in parameter_matches]
    
    # 创建ELM JSON结构
    elm = {
        "library": {
            "identifier": {
                "id": library_name,
                "version": version
            },
            "schemaIdentifier": {
                "id": "urn:hl7-org:elm",
                "version": "r1"
            },
            "usings": {
                "def": usings
            } if usings else {},
            "includes": {
                "def": includes
            } if includes else {},
            "parameters": {
                "def": parameters
            } if parameters else {},
            "statements": {
                "def": [
                    {
                        "name": "Patient",
                        "context": "Patient",
                        "expression": {
                            "type": "SingletonFrom",
                            "operand": {
                                "dataType": "{http://hl7.org/fhir}Patient",
                                "type": "Retrieve"
                            }
                        }
                    }
                ]
            }
        }
    }
    
    return elm

def convert_all_cql():
    """批量转换所有CQL文件"""
    source_dir = Path("CQL 2026")
    output_dir = Path("ELM_JSON")
    
    # 创建输出目录
    output_dir.mkdir(exist_ok=True)
    
    # 获取所有CQL文件
    cql_files = list(source_dir.rglob("*.cql"))
    total = len(cql_files)
    
    print(f"\n找到 {total} 个CQL文件，开始转换...\n")
    
    success = 0
    failed = 0
    failed_files = []
    
    for i, cql_file in enumerate(cql_files, 1):
        percent = round((i / total) * 100, 1)
        rel_path = cql_file.relative_to(source_dir)
        
        print(f"[{i}/{total}] {percent}% - {rel_path}")
        
        try:
            # 读取CQL文件
            with open(cql_file, 'r', encoding='utf-8') as f:
                cql_content = f.read()
            
            # 解析并生成ELM
            elm = parse_cql_to_elm(cql_content, cql_file.name)
            
            # 创建输出路径
            output_path = output_dir / rel_path.with_suffix('.json')
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 保存JSON
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(elm, f, indent=2, ensure_ascii=False)
            
            print(f"  ✅ 成功\n")
            success += 1
            
        except Exception as e:
            print(f"  ❌ 失败: {str(e)}\n")
            failed += 1
            failed_files.append(str(rel_path))
        
        # 每10个文件显示进度
        if i % 10 == 0:
            print(f"--- 进度: 成功 {success}, 失败 {failed} ---\n")
    
    print("\n" + "=" * 60)
    print(f"转换完成!")
    print(f"总计: {total} | 成功: {success} | 失败: {failed}")
    
    if failed_files:
        print(f"\n失败文件:")
        for f in failed_files:
            print(f"  - {f}")
    
    print("=" * 60)

if __name__ == "__main__":
    convert_all_cql()
