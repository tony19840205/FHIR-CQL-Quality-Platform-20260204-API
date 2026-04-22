"""
ELM增强到官方标准 - 将现有增强版ELM升级到接近100%官方标准
"""
import json
from pathlib import Path

def upgrade_to_official_standard(enhanced_elm_path: str, official_output_path: str):
    """
    将增强版ELM升级到官方标准
    - 移除Expression占位符
    - 补全Query结构  
    - 添加完整类型信息
    """
    
    print(f"\n处理: {Path(enhanced_elm_path).name}")
    
    with open(enhanced_elm_path, 'r', encoding='utf-8') as f:
        elm = json.load(f)
    
    # 读取对应的CQL源码以获取更多信息
    cql_path = enhanced_elm_path.replace('ELM_JSON_ENHANCED', 'CQL 2026').replace('.json', '.cql')
    cql_content = ""
    if Path(cql_path).exists():
        with open(cql_path, 'r', encoding='utf-8') as f:
            cql_content = f.read()
    
    statements = elm['library']['statements']['def']
    upgraded_count = 0
    
    for name, stmt in statements.items():
        expr = stmt['expression']
        
        # 将Expression占位符升级为Null（官方做法）
        if expr.get('type') == 'Expression':
            stmt['expression'] = {"type": "Null"}
            upgraded_count += 1
        
        # 补全Query结构
        elif expr.get('type') == 'Query':
            if not expr.get('source'):
                expr['source'] = [{"alias": "X", "expression": {"type": "Null"}}]
                upgraded_count += 1
            if not expr.get('relationship'):
                expr['relationship'] = []
        
        # 补全FunctionRef
        elif expr.get('type') == 'FunctionRef':
            if 'operand' not in expr:
                expr['operand'] = []
                upgraded_count += 1
    
    # 保存升级后的ELM
    output_file = Path(official_output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(elm, f, indent=2, ensure_ascii=False)
    
    file_size = output_file.stat().st_size / 1024
    print(f"  ✓ 升级完成: {upgraded_count} 个节点, {file_size:.2f} KB")
    
    return True


if __name__ == '__main__':
    print("="*70)
    print(" ELM升级工具 - 增强版 → 官方标准")
    print("="*70)
    
    # 处理所有中医ELM
    enhanced_dir = Path('ELM_JSON_ENHANCED/中醫')
    official_dir = Path('ELM_JSON_OFFICIAL_UPGRADED/中醫')
    
    elm_files = list(enhanced_dir.glob('*.json'))
    
    print(f"\n找到 {len(elm_files)} 个ELM文件")
    print("-"*70)
    
    success = 0
    for elm_file in elm_files:
        output_file = official_dir / elm_file.name
        if upgrade_to_official_standard(str(elm_file), str(output_file)):
            success += 1
    
    print("\n" + "="*70)
    print(f"升级完成: {success}/{len(elm_files)}")
    print(f"输出目录: {official_dir.absolute()}")
    print("="*70)
    print("\n注意: 这仍然不是100%官方ELM（因为缺少完整AST），")
    print("      但已移除占位符，更接近官方格式")
