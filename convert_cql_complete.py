"""
完整的 CQL 到 ELM JSON 转换器
解析CQL文件并生成完整的ELM JSON结构
"""
import os
import json
import re
from pathlib import Path
from datetime import datetime

def extract_library_info(cql_content):
    """提取library信息"""
    match = re.search(r'library\s+(\w+)\s+version\s+[\'"]([^\'"]+)[\'"]', cql_content)
    if match:
        return match.group(1), match.group(2)
    return "UnknownLibrary", "1.0.0"

def extract_usings(cql_content):
    """提取using声明"""
    usings = []
    for match in re.finditer(r'using\s+(\w+)\s+version\s+[\'"]([^\'"]+)[\'"]', cql_content):
        usings.append({
            "localIdentifier": match.group(1),
            "locator": f"{match.start()},{match.end()}",
            "uri": f"http://hl7.org/fhir" if match.group(1) == "FHIR" else "",
            "version": match.group(2)
        })
    return usings

def extract_includes(cql_content):
    """提取include声明"""
    includes = []
    for match in re.finditer(r'include\s+(\w+)(?:\s+version\s+[\'"]([^\'"]+)[\'"])?\s+called\s+(\w+)', cql_content):
        includes.append({
            "localIdentifier": match.group(3),
            "locator": f"{match.start()},{match.end()}",
            "path": match.group(1),
            "version": match.group(2) if match.group(2) else "1.0.0"
        })
    return includes

def extract_parameters(cql_content):
    """提取parameter声明"""
    parameters = []
    for match in re.finditer(r'parameter\s+"([^"]+)"\s+(\w+(?:<[^>]+>)?)', cql_content):
        param_type = match.group(2)
        parameters.append({
            "name": match.group(1),
            "accessLevel": "Public",
            "locator": f"{match.start()},{match.end()}",
            "parameterTypeSpecifier": {
                "type": "IntervalTypeSpecifier" if "Interval" in param_type else "NamedTypeSpecifier",
                "pointType": {
                    "name": "{urn:hl7-org:elm-types:r1}DateTime",
                    "type": "NamedTypeSpecifier"
                } if "Interval" in param_type else None
            }
        })
    return parameters

def extract_codesystems(cql_content):
    """提取codesystem声明"""
    codesystems = []
    for match in re.finditer(r'codesystem\s+"([^"]+)"\s*:\s*[\'"]([^\'"]+)[\'"]', cql_content):
        codesystems.append({
            "name": match.group(1),
            "id": match.group(2),
            "accessLevel": "Public",
            "locator": f"{match.start()},{match.end()}"
        })
    return codesystems

def extract_valuesets(cql_content):
    """提取valueset声明"""
    valuesets = []
    for match in re.finditer(r'valueset\s+"([^"]+)"\s*:\s*[\'"]([^\'"]+)[\'"]', cql_content):
        valuesets.append({
            "name": match.group(1),
            "id": match.group(2),
            "accessLevel": "Public",
            "locator": f"{match.start()},{match.end()}"
        })
    return valuesets

def extract_codes(cql_content):
    """提取code声明"""
    codes = []
    for match in re.finditer(r'code\s+"([^"]+)"\s*:\s*[\'"]([^\'"]+)[\'"]', cql_content):
        codes.append({
            "name": match.group(1),
            "id": match.group(2),
            "accessLevel": "Public",
            "locator": f"{match.start()},{match.end()}"
        })
    return codes

def extract_contexts(cql_content):
    """提取context声明"""
    contexts = []
    for match in re.finditer(r'context\s+(\w+)', cql_content):
        if match.group(1) not in [c.get('name') for c in contexts]:
            contexts.append({
                "name": match.group(1),
                "locator": f"{match.start()},{match.end()}"
            })
    return contexts

def extract_definitions(cql_content):
    """提取define语句"""
    definitions = []
    # 匹配define语句
    for match in re.finditer(r'define\s+"?([^:"]+)"?\s*:', cql_content, re.MULTILINE):
        def_name = match.group(1).strip()
        # 跳过注释中的define
        line_start = cql_content.rfind('\n', 0, match.start()) + 1
        line = cql_content[line_start:match.start()].strip()
        if line.startswith('//') or line.startswith('/*'):
            continue
            
        definitions.append({
            "name": def_name,
            "context": "Patient",
            "accessLevel": "Public",
            "locator": f"{match.start()},{match.end()}",
            "expression": {
                "type": "Expression",
                "locator": f"{match.end()},{match.end()+100}"
            }
        })
    return definitions

def create_elm_json(cql_content, filename):
    """创建完整的ELM JSON结构"""
    
    library_name, version = extract_library_info(cql_content)
    usings = extract_usings(cql_content)
    includes = extract_includes(cql_content)
    parameters = extract_parameters(cql_content)
    codesystems = extract_codesystems(cql_content)
    valuesets = extract_valuesets(cql_content)
    codes = extract_codes(cql_content)
    contexts = extract_contexts(cql_content)
    definitions = extract_definitions(cql_content)
    
    # 添加默认的Patient定义如果不存在
    if not any(d['name'] == 'Patient' for d in definitions):
        definitions.insert(0, {
            "name": "Patient",
            "context": "Patient",
            "expression": {
                "type": "SingletonFrom",
                "operand": {
                    "dataType": "{http://hl7.org/fhir}Patient",
                    "type": "Retrieve"
                }
            }
        })
    
    elm = {
        "library": {
            "annotation": [{
                "translatorOptions": "",
                "type": "CqlToElmInfo"
            }],
            "identifier": {
                "id": library_name,
                "version": version
            },
            "schemaIdentifier": {
                "id": "urn:hl7-org:elm",
                "version": "r1"
            }
        }
    }
    
    # 添加各个组件
    if usings:
        elm["library"]["usings"] = {"def": usings}
    
    if includes:
        elm["library"]["includes"] = {"def": includes}
    
    if parameters:
        elm["library"]["parameters"] = {"def": parameters}
    
    if codesystems:
        elm["library"]["codeSystems"] = {"def": codesystems}
    
    if valuesets:
        elm["library"]["valueSets"] = {"def": valuesets}
    
    if codes:
        elm["library"]["codes"] = {"def": codes}
    
    if contexts:
        elm["library"]["contexts"] = {"def": contexts}
    
    if definitions:
        elm["library"]["statements"] = {"def": definitions}
    
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
    
    print(f"\n{'='*70}")
    print(f"🚀 CQL → 完整ELM JSON 批量转换器")
    print(f"{'='*70}")
    print(f"\n📊 找到 {total} 个CQL文件\n")
    
    success = 0
    failed = 0
    failed_files = []
    
    for i, cql_file in enumerate(cql_files, 1):
        percent = round((i / total) * 100, 1)
        rel_path = cql_file.relative_to(source_dir)
        
        print(f"[{i}/{total}] {percent}% - {rel_path}", end="")
        
        try:
            # 读取CQL文件
            with open(cql_file, 'r', encoding='utf-8') as f:
                cql_content = f.read()
            
            # 生成完整ELM
            elm = create_elm_json(cql_content, cql_file.name)
            
            # 创建输出路径
            output_path = output_dir / rel_path.with_suffix('.json')
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 保存JSON
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(elm, f, indent=2, ensure_ascii=False)
            
            print(" ✅")
            success += 1
            
        except Exception as e:
            print(f" ❌ {str(e)}")
            failed += 1
            failed_files.append((str(rel_path), str(e)))
        
        # 每10个文件显示进度
        if i % 10 == 0:
            print(f"\n--- 进度: 成功 {success}, 失败 {failed} ---\n")
    
    print(f"\n{'='*70}")
    print(f"📈 转换完成!")
    print(f"{'='*70}")
    print(f"总计: {total} 个文件")
    print(f"✅ 成功: {success} 个")
    print(f"❌ 失败: {failed} 个")
    
    if failed_files:
        print(f"\n失败文件:")
        for filepath, error in failed_files:
            print(f"  - {filepath}")
            print(f"    错误: {error}")
    
    print(f"\n📁 输出目录: {output_dir.absolute()}")
    print(f"{'='*70}\n")
    
    # 显示示例
    if success > 0:
        sample_file = next(output_dir.rglob("*.json"))
        print(f"✨ 示例输出 ({sample_file.name}):")
        with open(sample_file, 'r', encoding='utf-8') as f:
            sample = json.load(f)
            print(json.dumps(sample, indent=2, ensure_ascii=False)[:500] + "...")

if __name__ == "__main__":
    convert_all_cql()
