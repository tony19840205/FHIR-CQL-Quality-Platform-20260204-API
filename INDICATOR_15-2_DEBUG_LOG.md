# 指标15-2 (全膝关节置换术90日感染率) 调试记录

**日期**: 2026-01-02
**状态**: 分母找到6个，分子仍为0

---

## 当前状态

### CQL查询结果
- **分母**: 6 个患者
- **分子**: 0 个感染
- **比例**: 0.00%
- **预期**: 应该有至少1-2个感染被计入

### 患者范围
- CQL搜索: `identifier.value = "TW10001" 至 "TW10046"`
- 找到的6个分母患者: TW10001-TW10006

---

## 6个分母患者详细信息

### TW10001 (Patient/total-knee-15-2-001)
- ✅ **Procedure**: 0SRC0JZ (ICD-10-PCS 全膝置换术)
- ✅ **Condition**: T84.54XA (感染诊断)
- ⚠️ **问题**: 
  - Procedure缺少手术日期 (performedPeriod.start为空)
  - Condition刚添加了clinicalStatus: active
  - Condition缺少onsetDateTime

### TW10002 (Patient/total-knee-15-2-002)
- ✅ **Procedure**: 0SRC0JZ (ICD-10-PCS 全膝置换术)
- ✅ **Condition**: T84.54XA (感染诊断)
- ⚠️ **问题**: 
  - Procedure缺少手术日期
  - Condition缺少clinicalStatus, onsetDateTime

### TW10003 (Patient/TW10003)
- ✅ **Procedure**: 64164B (NHI台湾健保码 全膝置换术)
- ✅ **Procedure**: 64053B (感染治疗手术)
- ❌ **Condition**: Z48.815 (术后随访，不是T84.54XA)
- **结论**: 有感染治疗但无T84.54XA诊断 → 不会计入分子

### TW10004 (Patient/TW10004)
- ✅ **Procedure**: 64164B (NHI台湾健保码)
- ❌ 无感染记录

### TW10005 (Patient/TW10005)
- ✅ **Procedure**: 64164B (NHI台湾健保码)
- ❌ 无感染记录

### TW10006 (Patient/TW10006)
- ✅ **Procedure**: 64164B (NHI台湾健保码)
- ❌ 无感染记录

---

## 关键发现

### 1. 编码系统混用
- **TW10001-TW10002**: 使用 0SRC0JZ (ICD-10-PCS 国际码)
- **TW10003-TW10006**: 使用 64164B (NHI 台湾健保码)
- **结论**: CQL同时接受两种编码系统作为分母！

### 2. TW10019的情况
- ✅ 有完整的膝关节手术 + T84.54XA感染结构
- ❌ identifier.value = "TW10019" 在TW10001-TW10006范围外
- **结论**: 虽然数据结构正确，但不在CQL搜索的分母范围内，上传了也没用

### 3. Condition结构对比

**TW10001-TW10002的Condition (我们上传的)**:
```json
{
  "id": "cond-infection-tw10001",
  "code": { "coding": [{ "code": "T84.54XA", "system": "http://hl7.org/fhir/sid/icd-10-cm" }] },
  "clinicalStatus": { "coding": [{ "code": "active", "system": "..." }] },  // 刚添加
  "subject": { "reference": "Patient/total-knee-15-2-001" },
  "encounter": { "reference": "Encounter/total-knee-15-2-enc-001" }
  // 缺少: onsetDateTime, verificationStatus
}
```

**TW10019的Condition (2025Q4原始数据)**:
```json
{
  "id": "COND1001902",
  "code": { "coding": [{ "code": "T84.54XA", "system": "http://hl7.org/fhir/sid/icd-10" }] },
  "clinicalStatus": { "coding": [{ "code": "active", "system": "..." }] },
  "subject": { "reference": "Patient/TW10019" },
  "encounter": { "reference": "Encounter/ENC1001901" }
  // 也没有: onsetDateTime, verificationStatus
}
```

**注意**: TW10019的System是 `icd-10`，我们用的是 `icd-10-cm`

### 4. Procedure日期问题
- TW10001-TW10002的Procedure查询返回空的手术日期
- 这可能影响CQL计算90天感染窗口

---

## 可能的问题原因

### ✅ 已排除
- ~~identifier.value范围~~ - 确认TW10001-TW10006在范围内
- ~~Procedure编码~~ - 0SRC0JZ和64164B都被接受
- ~~Condition编码~~ - T84.54XA是正确的感染码

### ⚠️ 待验证

1. **Procedure日期缺失**
   - TW10001和TW10002的Procedure没有performedPeriod.start
   - CQL可能需要手术日期来计算90天窗口
   - 如果没有手术日期，可能无法验证感染是否在90天内

2. **Condition日期缺失**
   - 我们的Condition缺少onsetDateTime
   - CQL可能需要这个字段来确定感染发生时间
   - 但TW10019也没有onsetDateTime，所以可能不是关键

3. **ICD编码系统差异**
   - 我们用: `http://hl7.org/fhir/sid/icd-10-cm`
   - TW10019用: `http://hl7.org/fhir/sid/icd-10`
   - 可能CQL只识别icd-10，不识别icd-10-cm

4. **clinicalStatus时机**
   - TW10001刚更新了clinicalStatus
   - TW10002还没更新
   - 需要验证TW10002也加上后是否有变化

---

## 下一步行动计划

### 方案A: 修复Procedure日期
1. 查询TW10001和TW10002的Procedure完整数据
2. 检查为什么手术日期为空
3. 重新上传Procedure，添加完整的performedPeriod
4. 确保日期在2026-01 (Q1)

### 方案B: 修复Condition结构
1. 将TW10002的Condition也更新，添加clinicalStatus
2. 尝试修改System从icd-10-cm改为icd-10（与TW10019一致）
3. 考虑添加onsetDateTime（手术后45天）

### 方案C: 完全复制TW10019结构
1. 提取TW10019的完整5个资源（Patient, Encounter, Procedure, 2 Conditions）
2. 仅修改identifier.value从TW10019改为TW10001
3. 保持所有其他字段、日期、ID结构完全一致
4. 这样可以测试是否是结构问题还是identifier问题

### 方案D: 使用64164B编码
1. 既然TW10003-TW10006用64164B也能被找到
2. 尝试为TW10003添加T84.54XA Condition
3. 因为它已经有64053B感染治疗Procedure，只差诊断

---

## 推荐优先级

**第一优先**: 方案A - 修复Procedure日期
- 理由: 没有手术日期就无法计算90天窗口，这是最可能的原因

**第二优先**: 方案B - 统一Condition结构
- 理由: 确保所有必要字段存在且与TW10019一致

**第三优先**: 方案D - 利用TW10003
- 理由: 它已经在分母且有感染治疗记录，只需加T84.54XA

**备选**: 方案C - 完全复制TW10019
- 理由: 如果其他方案都失败，这是最后的测试手段

---

## 已上传的文件

1. `test_data_15_2_with_tw_ids.json` - 6个患者基础数据
2. `test_data_15_2_timezone_fixed.json` - 时区修正版本
3. `test_data_15_2_with_infection_encounters.json` - 添加感染Encounter
4. `test_data_15_2_tw10019.json` - TW10019完整数据
5. `tw10019_condition_template.json` - T84.54XA Condition模板
6. `test_data_15_2_add_infection_tw10001.json` - TW10001的感染Condition
7. `tw10001_condition_with_status.json` - 添加clinicalStatus的版本

---

## 备注

- 指标15-1和15-3使用Patient.id搜索，15-2使用identifier.value搜索（完全不同！）
- 2025Q4原始数据中，TW10001-TW10010都是0W9F30Z手术（非膝关节），只有TW10019是真正的膝关节+感染患者
- 现在服务器上的TW10001-TW10006是我们重新创建的，与2025Q4不同
- CQL能找到6个分母证明identifier.value搜索逻辑是对的
- 分子为0说明Condition的某些条件没满足

---

**最后更新**: 2026-01-02 17:00
**下次继续**: 从方案A开始，检查并修复Procedure日期
