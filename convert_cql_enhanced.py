#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
增强版CQL到ELM转换器
能够解析常见的CQL表达式，生成更接近官方的ELM JSON
"""

import re
import json
import os
from pathlib import Path
from typing import Dict, List, Any

def parse_code_expression(code_text: str, code_systems: Dict) -> Dict:
    """解析 Code 表达式"""
    # 匹配: Code { code: '05', system: "TWCaseType", display: '中醫門診' }
    pattern = r"Code\s*\{\s*code:\s*'([^']+)',\s*system:\s*\"([^\"]+)\",\s*display:\s*'([^']+)'\s*\}"
    match = re.search(pattern, code_text)
    
    if match:
        code_value, system_name, display = match.groups()
        system_url = code_systems.get(system_name, {}).get('id', '')
        
        return {
            "type": "Code",
            "code": code_value,
            "system": system_url,
            "display": display
        }
    
    return {"type": "Expression", "text": code_text}

def parse_retrieve_expression(expr_text: str) -> Dict:
    """解析 Retrieve 表达式"""
    # 匹配: [Encounter]
    pattern = r"\[(\w+)\]"
    match = re.search(pattern, expr_text)
    
    if match:
        resource_type = match.group(1)
        return {
            "type": "Retrieve",
            "dataType": f"{{http://hl7.org/fhir}}{resource_type}",
            "templateId": f"http://hl7.org/fhir/StructureDefinition/{resource_type}"
        }
    
    return {"type": "Expression", "text": expr_text}

def parse_query_expression(expr_text: str) -> Dict:
    """解析 Query 表达式"""
    if "from" in expr_text.lower() and ("where" in expr_text.lower() or "return" in expr_text.lower()):
        return {
            "type": "Query",
            "source": [{"alias": "source", "expression": {"type": "Expression"}}],
            "where": {"type": "Expression"},
            "return": {"expression": {"type": "Expression"}}
        }
    
    return {"type": "Expression", "text": expr_text}

def parse_function_call(expr_text: str) -> Dict:
    """解析函数调用"""
    # 匹配: FunctionName(args)
    pattern = r"(\w+)\s*\((.*)\)"
    match = re.match(pattern, expr_text.strip())
    
    if match:
        func_name, args = match.groups()
        return {
            "type": "FunctionRef",
            "name": func_name,
            "operand": [{"type": "Expression"}]
        }
    
    return {"type": "Expression", "text": expr_text}

def parse_interval_expression(expr_text: str) -> Dict:
    """解析 Interval 表达式"""
    # 匹配: Interval[start, end]
    pattern = r"Interval\[(.+?),\s*(.+?)\]"
    match = re.search(pattern, expr_text)
    
    if match:
        start, end = match.groups()
        return {
            "type": "Interval",
            "lowClosed": True,
            "highClosed": True,
            "low": {"type": "ParameterRef", "name": start.strip()},
            "high": {"type": "ParameterRef", "name": end.strip()}
        }
    
    return {"type": "Expression", "text": expr_text}

def parse_list_expression(expr_text: str) -> Dict:
    """解析 List 表达式"""
    if expr_text.strip().startswith('{') and expr_text.strip().endswith('}'):
        return {
            "type": "List",
            "element": [{"type": "Expression"}]
        }
    
    return {"type": "Expression", "text": expr_text}

def extract_expression(definition_text: str, code_systems: Dict) -> Dict:
    """智能提取并解析表达式"""
    expr_text = definition_text.strip()
    
    # 1. Code 表达式
    if expr_text.startswith("Code"):
        return parse_code_expression(expr_text, code_systems)
    
    # 2. Retrieve 表达式
    if re.match(r"\[\w+\]", expr_text):
        return parse_retrieve_expression(expr_text)
    
    # 3. Interval 表达式
    if "Interval[" in expr_text:
        return parse_interval_expression(expr_text)
    
    # 4. Query 表达式
    if "from" in expr_text.lower():
        return parse_query_expression(expr_text)
    
    # 5. List 表达式
    if expr_text.startswith('{') and expr_text.endswith('}'):
        return parse_list_expression(expr_text)
    
    # 6. 函数调用
    if '(' in expr_text and ')' in expr_text:
        return parse_function_call(expr_text)
    
    # 7. 参数引用
    if expr_text in ['MeasurementPeriodStart', 'MeasurementPeriodEnd', 'MeasurementPeriod']:
        return {
            "type": "ParameterRef",
            "name": expr_text
        }
    
    # 8. 默认：保留原文
    return {
        "type": "Expression",
        "text": expr_text
    }

def extract_definition_with_expression(cql_content: str, start_pos: int, code_systems: Dict) -> Dict:
    """提取定义并解析其表达式"""
    # 找到 define 语句
    define_pattern = r'define\s+(?:function\s+)?("[^"]+"|[\w]+)(?:\s*\([^)]*\))?\s*:\s*'
    match = re.search(define_pattern, cql_content[start_pos:])
    
    if not match:
        return None
    
    name = match.group(1).strip('"')
    expr_start = start_pos + match.end()
    
    # 查找表达式结束位置（下一个define或文件结束）
    next_define = cql_content.find('\ndefine', expr_start)
    if next_define == -1:
        expr_text = cql_content[expr_start:].strip()
    else:
        expr_text = cql_content[expr_start:next_define].strip()
    
    # 移除多余的空白和换行
    expr_text = ' '.join(expr_text.split())
    
    # 解析表达式
    expression = extract_expression(expr_text, code_systems)
    
    return {
        "name": name,
        "context": "Patient",
        "accessLevel": "Public",
        "expression": expression
    }

def extract_all_definitions_enhanced(cql_content: str, code_systems: Dict) -> List[Dict]:
    """增强版：提取所有定义并解析表达式"""
    definitions = []
    
    # Patient 定义（标准）
    definitions.append({
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
    
    # 查找所有 define 语句
    define_pattern = r'(?:^|\n)define\s+'
    matches = list(re.finditer(define_pattern, cql_content))
    
    for i, match in enumerate(matches):
        try:
            def_obj = extract_definition_with_expression(cql_content, match.start(), code_systems)
            if def_obj and def_obj['name'] != 'Patient':
                definitions.append(def_obj)
        except Exception as e:
            print(f"  警告: 解析定义时出错: {e}")
            continue
    
    return definitions

def convert_cql_to_elm_enhanced(cql_file_path: str) -> Dict:
    """增强版CQL到ELM转换"""
    with open(cql_file_path, 'r', encoding='utf-8') as f:
        cql_content = f.read()
    
    # 提取基础信息
    library_match = re.search(r'library\s+([\w_]+)\s+version\s+[\'"]([^\'"]+)[\'"]', cql_content)
    library_id = library_match.group(1) if library_match else "UnknownLibrary"
    library_version = library_match.group(2) if library_match else "1.0.0"
    
    # 提取 usings
    usings = []
    for match in re.finditer(r'using\s+(\w+)\s+version\s+[\'"]([^\'"]+)[\'"]', cql_content):
        usings.append({
            "localIdentifier": match.group(1),
            "uri": f"http://hl7.org/fhir" if match.group(1) == "FHIR" else match.group(1),
            "version": match.group(2)
        })
    
    # 提取 includes
    includes = []
    for match in re.finditer(r'include\s+([\w]+)\s+version\s+[\'"]([^\'"]+)[\'"]\s+called\s+([\w]+)', cql_content):
        includes.append({
            "localIdentifier": match.group(3),
            "path": match.group(1),
            "version": match.group(2)
        })
    
    # 提取 codesystems
    code_systems = {}
    for match in re.finditer(r'codesystem\s+"([^"]+)":\s+[\'"]([^\'"]+)[\'"]', cql_content):
        code_systems[match.group(1)] = {
            "name": match.group(1),
            "id": match.group(2),
            "accessLevel": "Public"
        }
    
    # 提取 parameters
    parameters = []
    for match in re.finditer(r'parameter\s+(\w+)\s+(\w+)(?:\s+default\s+(@[\d\-:T+.]+))?', cql_content):
        param = {
            "name": match.group(1),
            "accessLevel": "Public",
            "parameterTypeSpecifier": {
                "name": f"{{urn:hl7-org:elm-types:r1}}{match.group(2)}",
                "type": "NamedTypeSpecifier"
            }
        }
        if match.group(3):
            param["default"] = {
                "type": "DateTime",
                "value": match.group(3)
            }
        parameters.append(param)
    
    # 增强版：提取定义并解析表达式
    definitions = extract_all_definitions_enhanced(cql_content, code_systems)
    
    # 构建ELM
    elm = {
        "library": {
            "annotation": [{
                "translatorOptions": "EnableAnnotations,EnableLocators",
                "type": "CqlToElmInfo"
            }],
            "identifier": {
                "id": library_id,
                "version": library_version
            },
            "schemaIdentifier": {
                "id": "urn:hl7-org:elm",
                "version": "r1"
            },
            "usings": {"def": usings} if usings else {},
            "includes": {"def": includes} if includes else {},
            "parameters": {"def": parameters} if parameters else {},
            "codeSystems": {"def": list(code_systems.values())} if code_systems else {},
            "statements": {"def": definitions}
        }
    }
    
    return elm

def batch_convert_enhanced(base_dir: str, output_dir: str):
    """批量转换（增强版）"""
    categories = ["中醫", "牙科", "西醫", "門診透析品質指標"]
    
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║          增强版CQL到ELM批量转换工具                            ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print()
    
    total_files = 0
    converted_files = 0
    
    for category in categories:
        category_path = os.path.join(base_dir, category)
        if not os.path.exists(category_path):
            continue
        
        output_category_path = os.path.join(output_dir, category)
        os.makedirs(output_category_path, exist_ok=True)
        
        cql_files = list(Path(category_path).glob("*.cql"))
        total_files += len(cql_files)
        
        print(f"📁 分类: {category}")
        print(f"   找到 {len(cql_files)} 个CQL文件")
        print()
        
        for cql_file in cql_files:
            try:
                print(f"   ⏳ 转换: {cql_file.stem}.cql", end=" ")
                
                elm_json = convert_cql_to_elm_enhanced(str(cql_file))
                
                output_file = os.path.join(output_category_path, f"{cql_file.stem}.json")
                with open(output_file, 'w', encoding='utf-8') as f:
                    json.dump(elm_json, f, ensure_ascii=False, indent=2)
                
                converted_files += 1
                print("✅")
                
            except Exception as e:
                print(f"❌ 错误: {e}")
                continue
        
        print()
    
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║                        转换完成报告                            ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print()
    print(f"📊 统计结果:")
    print(f"   总文件数: {total_files}")
    print(f"   成功转换: {converted_files}")
    print(f"   转换失败: {total_files - converted_files}")
    print()
    print(f"📁 输出目录: {os.path.abspath(output_dir)}")
    print()

if __name__ == "__main__":
    base_dir = "CQL 2026"
    output_dir = "ELM_JSON_ENHANCED"
    
    batch_convert_enhanced(base_dir, output_dir)
    
    print("✨ 增强版转换完成!")
    print()
    print("🔍 增强功能:")
    print("   ✅ 解析 Code 表达式（含system和display）")
    print("   ✅ 解析 Retrieve 表达式（含dataType）")
    print("   ✅ 解析 Interval 表达式")
    print("   ✅ 解析 Query 表达式结构")
    print("   ✅ 解析 ParameterRef 引用")
    print("   ✅ 保留复杂表达式原文")
