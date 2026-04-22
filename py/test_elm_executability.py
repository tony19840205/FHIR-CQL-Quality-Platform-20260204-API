#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
演示增强版 vs 官方版ELM的实际执行差异
"""

import json

# 模拟一个简单的CQL表达式执行器
class SimpleCQLExecutor:
    """简化的CQL执行引擎模拟"""
    
    def __init__(self, elm_json):
        self.elm = elm_json
        self.context = {}
        
    def execute_expression(self, expression):
        """执行表达式"""
        expr_type = expression.get('type')
        
        # 增强版能处理的类型
        if expr_type == 'Code':
            code = expression.get('code')
            system = expression.get('system', '')
            return f"✅ Code: {code} ({system[:30]}...)"
        
        elif expr_type == 'Retrieve':
            return f"✅ Retrieve: {expression.get('dataType')}"
        
        elif expr_type == 'ParameterRef':
            return f"✅ Parameter: {expression.get('name')}"
        
        elif expr_type == 'Interval':
            return f"✅ Interval 表达式"
        
        elif expr_type == 'SingletonFrom':
            return f"✅ SingletonFrom 表达式"
        
        # ❌ 增强版无法处理的类型（只有占位符）
        elif expr_type == 'Expression':
            text = expression.get('text', '')
            return f"❌ 无法执行: {text[:50]}..." if text else "❌ 无法执行: 未知表达式"
        
        # ✅ 官方版才有的完整类型
        elif expr_type == 'Query':
            # 增强版的Query只有结构，没有详细内容
            if 'source' in expression and isinstance(expression['source'], list):
                sources = expression['source']
                if sources and sources[0].get('expression', {}).get('type') == 'Expression':
                    return "❌ 无法执行: Query结构不完整"
            return "✅ 可以执行: 完整Query"
        
        elif expr_type == 'Filter':
            return "✅ 可以执行: Filter操作"
        
        elif expr_type == 'Where':
            return "✅ 可以执行: Where条件"
        
        elif expr_type == 'Equal':
            return "✅ 可以执行: 相等比较"
        
        else:
            return f"⚠️ 未知类型: {expr_type}"
    
    def test_statements(self):
        """测试所有语句"""
        statements = self.elm.get('library', {}).get('statements', {}).get('def', [])
        
        results = []
        for stmt in statements:
            name = stmt.get('name')
            expression = stmt.get('expression', {})
            result = self.execute_expression(expression)
            
            # 检查是否可执行
            if isinstance(result, str):
                executable = result.startswith('✅')
            else:
                executable = False
                result = str(result)
            
            results.append({
                'name': name,
                'type': expression.get('type'),
                'executable': executable,
                'result': result
            })
        
        return results


def compare_executability(enhanced_file, statement_limit=10):
    """对比增强版的可执行性"""
    
    with open(enhanced_file, 'r', encoding='utf-8') as f:
        enhanced_elm = json.load(f)
    
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║           增强版ELM执行能力测试                                ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print()
    
    executor = SimpleCQLExecutor(enhanced_elm)
    results = executor.test_statements()
    
    executable_count = sum(1 for r in results if r['executable'])
    total_count = len(results)
    
    print(f"📊 测试文件: {enhanced_file}")
    print(f"   总语句数: {total_count}")
    print(f"   可执行: {executable_count} ({executable_count/total_count*100:.1f}%)")
    print(f"   不可执行: {total_count - executable_count} ({(total_count-executable_count)/total_count*100:.1f}%)")
    print()
    
    print("=" * 70)
    print("详细测试结果（前{}个语句）:".format(min(statement_limit, total_count)))
    print("=" * 70)
    print()
    
    for i, result in enumerate(results[:statement_limit], 1):
        status = "✅" if result['executable'] else "❌"
        print(f"{i}. {status} {result['name']}")
        print(f"   类型: {result['type']}")
        print(f"   结果: {result['result']}")
        print()
    
    if total_count > statement_limit:
        print(f"... 还有 {total_count - statement_limit} 个语句")
        print()
    
    # 统计各类型表达式
    print("=" * 70)
    print("表达式类型统计:")
    print("=" * 70)
    print()
    
    type_counts = {}
    for result in results:
        expr_type = result['type']
        type_counts[expr_type] = type_counts.get(expr_type, 0) + 1
    
    for expr_type, count in sorted(type_counts.items(), key=lambda x: x[1], reverse=True):
        executable_this_type = sum(1 for r in results if r['type'] == expr_type and r['executable'])
        percent = executable_this_type / count * 100
        status = "✅" if percent > 50 else "❌"
        print(f"{status} {expr_type:20s}: {count:3d} 个 (可执行: {executable_this_type}/{count}, {percent:.0f}%)")
    
    print()
    print("=" * 70)
    print("结论:")
    print("=" * 70)
    print()
    
    if executable_count / total_count > 0.5:
        print("✅ 增强版对于简单表达式有较好的可执行性")
    else:
        print("❌ 增强版对于复杂表达式可执行性不足")
    
    print()
    print("⚠️  增强版 vs 官方版的差异:")
    print()
    print("   增强版：")
    print("   - ✅ 可执行: Code, Retrieve, Interval, ParameterRef")
    print("   - ❌ 不可执行: 复杂Query, Filter, Where, 运算符等")
    print("   - 📖 适合: 文档化、学习、代码审查")
    print()
    print("   官方版：")
    print("   - ✅ 完全可执行: 所有CQL表达式")
    print("   - ✅ 包含完整AST树")
    print("   - 🚀 适合: CQL执行引擎、生产环境")
    print()


if __name__ == "__main__":
    import sys
    
    file_path = "ELM_JSON_ENHANCED/中醫/Indicator_TCM_Same_Day_Revisit_Rate.json"
    
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    
    compare_executability(file_path, statement_limit=15)
    
    print()
    print("💡 总结:")
    print("   如果你需要【实际执行CQL计算】→ 必须使用官方版")
    print("   如果你只需要【查看和理解CQL结构】→ 增强版完全足够")
