#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
2026 Q1 測試資料日期轉換腳本
將2025 Q4的測試資料轉換為2026-01-01 ~ 2026-01-15的日期範圍
"""

import json
import os
import re
from datetime import datetime, timedelta
from pathlib import Path
import shutil

class DateConverter:
    """日期轉換器"""
    
    def __init__(self, target_start_date="2026-01-01", days_range=15):
        """
        初始化轉換器
        
        Args:
            target_start_date: 目標開始日期 (預設2026-01-01)
            days_range: 日期分散範圍 (預設15天)
        """
        self.target_start = datetime.fromisoformat(f"{target_start_date}T00:00:00")
        self.days_range = days_range
        self.conversion_log = []
    
    def convert_date(self, date_str):
        """
        轉換單一日期字串
        
        策略: 將2025 Q4的日期等比例壓縮到2026-01-01~2026-01-15
        - 2025-10月 → 2026-01-01~01-05
        - 2025-11月 → 2026-01-06~01-10
        - 2025-12月 → 2026-01-11~01-15
        """
        if not date_str or not isinstance(date_str, str):
            return date_str
        
        # 匹配各種日期格式
        # ISO 8601: 2025-10-15T08:00:00+08:00 或 2025-10-15
        date_patterns = [
            r'(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-]\d{2}:\d{2}|Z)?',
            r'(\d{4})-(\d{2})-(\d{2})'
        ]
        
        for pattern in date_patterns:
            match = re.match(pattern, date_str)
            if match:
                try:
                    # 解析原始日期
                    original_dt = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
                    
                    # 計算在原始月份中的相對位置 (0-1)
                    year = original_dt.year
                    month = original_dt.month
                    day = original_dt.day
                    
                    # 2025 Q4: 10月、11月、12月
                    if year == 2025 and 10 <= month <= 12:
                        # 計算該月的第幾天 (1-31)
                        # 映射到5天範圍
                        if month == 10:  # 10月 → 1/1-1/5
                            day_offset = int((day - 1) / 31 * 5)
                        elif month == 11:  # 11月 → 1/6-1/10
                            day_offset = 5 + int((day - 1) / 30 * 5)
                        elif month == 12:  # 12月 → 1/11-1/15
                            day_offset = 10 + int((day - 1) / 31 * 5)
                        else:
                            day_offset = 0
                        
                        # 確保在15天範圍內
                        day_offset = min(day_offset, self.days_range - 1)
                        
                        # 計算新日期
                        new_dt = self.target_start + timedelta(days=day_offset)
                        
                        # 保持原始時間
                        new_dt = new_dt.replace(
                            hour=original_dt.hour,
                            minute=original_dt.minute,
                            second=original_dt.second,
                            microsecond=original_dt.microsecond
                        )
                        
                        # 保持原始時區
                        if 'T' in date_str:
                            if date_str.endswith('Z'):
                                result = new_dt.isoformat() + 'Z'
                            elif '+' in date_str or date_str.count('-') > 2:
                                # 保持時區信息
                                tz_part = date_str[date_str.rfind('+'):] if '+' in date_str else date_str[date_str.rfind('-', 10):]
                                result = new_dt.strftime('%Y-%m-%dT%H:%M:%S') + tz_part
                            else:
                                result = new_dt.isoformat()
                        else:
                            result = new_dt.strftime('%Y-%m-%d')
                        
                        self.conversion_log.append({
                            'original': date_str,
                            'converted': result,
                            'offset_days': day_offset
                        })
                        
                        return result
                    else:
                        # 不是2025 Q4的日期，保持不變
                        return date_str
                        
                except Exception as e:
                    print(f"警告: 無法轉換日期 '{date_str}': {e}")
                    return date_str
        
        # 沒有匹配到日期格式，返回原值
        return date_str
    
    def convert_resource(self, resource, resource_type=None):
        """
        轉換FHIR資源中的所有日期欄位
        
        Args:
            resource: FHIR資源 (dict)
            resource_type: 資源類型 (可選)
        """
        if not isinstance(resource, dict):
            return resource
        
        # 確定資源類型
        if not resource_type:
            resource_type = resource.get('resourceType', 'Unknown')
        
        # 需要轉換的日期欄位 (按資源類型)
        date_fields = {
            'Patient': ['birthDate', 'deceasedDateTime'],
            'Encounter': ['period.start', 'period.end'],
            'Procedure': ['performedDateTime', 'performedPeriod.start', 'performedPeriod.end'],
            'MedicationRequest': ['authoredOn', 'dispenseRequest.validityPeriod.start', 'dispenseRequest.validityPeriod.end'],
            'Observation': ['effectiveDateTime', 'effectivePeriod.start', 'effectivePeriod.end', 'issued'],
            'Condition': ['onsetDateTime', 'recordedDate', 'abatementDateTime'],
            'Immunization': ['occurrenceDateTime'],
            'DiagnosticReport': ['effectiveDateTime', 'effectivePeriod.start', 'effectivePeriod.end', 'issued'],
            'Claim': ['created', 'billablePeriod.start', 'billablePeriod.end']
        }
        
        # 遞歸轉換所有日期
        def convert_nested(obj, path=''):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    new_path = f"{path}.{key}" if path else key
                    
                    # 檢查是否為日期欄位
                    if isinstance(value, str) and (
                        'date' in key.lower() or 
                        'time' in key.lower() or
                        key in ['start', 'end', 'issued', 'created', 'authored']
                    ):
                        obj[key] = self.convert_date(value)
                    elif isinstance(value, (dict, list)):
                        convert_nested(value, new_path)
                        
            elif isinstance(obj, list):
                for i, item in enumerate(obj):
                    convert_nested(item, f"{path}[{i}]")
        
        convert_nested(resource)
        return resource
    
    def convert_bundle(self, bundle_data):
        """
        轉換整個FHIR Bundle
        
        Args:
            bundle_data: FHIR Bundle (dict)
        """
        if bundle_data.get('resourceType') != 'Bundle':
            print("警告: 這不是一個FHIR Bundle")
            return bundle_data
        
        entries = bundle_data.get('entry', [])
        converted_count = 0
        
        for entry in entries:
            resource = entry.get('resource', {})
            resource_type = resource.get('resourceType')
            
            if resource_type:
                self.convert_resource(resource, resource_type)
                converted_count += 1
        
        print(f"  ✓ 已轉換 {converted_count} 個資源")
        return bundle_data

def convert_file(input_path, output_dir, converter):
    """
    轉換單一JSON檔案
    
    Args:
        input_path: 輸入檔案路徑
        output_dir: 輸出目錄
        converter: DateConverter實例
    """
    try:
        # 讀取原始檔案
        with open(input_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 轉換日期
        print(f"處理: {os.path.basename(input_path)}")
        converted_data = converter.convert_bundle(data)
        
        # 生成輸出檔名
        original_name = os.path.basename(input_path)
        # 移除可能的舊標記
        new_name = original_name.replace('_2025Q4', '').replace('2025Q4', '')
        # 加上新標記
        if '.json' in new_name:
            new_name = new_name.replace('.json', '_2026Q1.json')
        else:
            new_name = new_name + '_2026Q1.json'
        
        output_path = os.path.join(output_dir, new_name)
        
        # 寫入轉換後的檔案
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(converted_data, f, ensure_ascii=False, indent=2)
        
        print(f"  ✓ 已儲存: {new_name}\n")
        return True
        
    except Exception as e:
        print(f"  ✗ 錯誤: {e}\n")
        return False

def main():
    """主程式"""
    print("=" * 80)
    print("2026 Q1 測試資料日期轉換工具")
    print("目標日期範圍: 2026-01-01 ~ 2026-01-15 (15天)")
    print("=" * 80)
    print()
    
    # 設定路徑
    base_dir = Path(r"c:\Users\tony1\Desktop\UI UX-20251218(2313) - MIKE")
    output_dir = base_dir / "2026Q1_Medical_Quality_Test_Data"
    
    # 建立輸出目錄
    output_dir.mkdir(exist_ok=True)
    
    # 初始化轉換器
    converter = DateConverter(target_start_date="2026-01-01", days_range=15)
    
    # 尋找所有測試資料檔案
    patterns = [
        "test_data*.json",
        "Cesarean*.json",
        "ESWL*.json",
        "Dementia*.json",
        "Fibroid*.json",
        "Knee*.json",
        "Surgical*.json",
        "First_Time*.json",
        "Same_Hospital*.json"
    ]
    
    all_files = []
    for pattern in patterns:
        files = list(base_dir.glob(pattern))
        all_files.extend(files)
    
    # 過濾掉不需要的檔案
    exclude_patterns = ['complete_test_data', 'eswl_query', 'cors', '_2026Q1']
    filtered_files = [
        f for f in all_files 
        if not any(exc in f.name for exc in exclude_patterns)
    ]
    
    # 去重
    filtered_files = list(set(filtered_files))
    filtered_files.sort()
    
    print(f"找到 {len(filtered_files)} 個檔案需要轉換\n")
    
    # 轉換檔案
    success_count = 0
    fail_count = 0
    
    for i, file_path in enumerate(filtered_files, 1):
        print(f"[{i}/{len(filtered_files)}] ", end='')
        if convert_file(file_path, output_dir, converter):
            success_count += 1
        else:
            fail_count += 1
    
    # 顯示總結
    print("=" * 80)
    print("轉換完成！")
    print(f"成功: {success_count} 個檔案")
    print(f"失敗: {fail_count} 個檔案")
    print(f"輸出目錄: {output_dir}")
    print("=" * 80)
    
    # 儲存轉換日誌
    log_path = output_dir / "conversion_log.json"
    with open(log_path, 'w', encoding='utf-8') as f:
        json.dump({
            'conversion_date': datetime.now().isoformat(),
            'target_date_range': '2026-01-01 to 2026-01-15',
            'total_files': len(filtered_files),
            'success_count': success_count,
            'fail_count': fail_count,
            'sample_conversions': converter.conversion_log[:20]  # 前20個轉換範例
        }, f, ensure_ascii=False, indent=2)
    
    print(f"\n轉換日誌已儲存: {log_path}")

if __name__ == "__main__":
    main()
