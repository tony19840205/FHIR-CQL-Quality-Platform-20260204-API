// ============================================================
// 模擬數據 — 正式環境中由控制台匯出去識別化 JSON 取代
// ============================================================

/** 傳染病月趨勢 */
export const diseaseTrendData = [
  { month: '2025/07', covid: 1250, influenza: 3400, dengue: 89, tb: 42 },
  { month: '2025/08', covid: 980, influenza: 2800, dengue: 156, tb: 38 },
  { month: '2025/09', covid: 760, influenza: 2100, dengue: 234, tb: 45 },
  { month: '2025/10', covid: 1120, influenza: 4200, dengue: 178, tb: 41 },
  { month: '2025/11', covid: 1580, influenza: 5600, dengue: 95, tb: 37 },
  { month: '2025/12', covid: 2340, influenza: 7800, dengue: 42, tb: 44 },
  { month: '2026/01', covid: 3100, influenza: 9200, dengue: 18, tb: 39 },
  { month: '2026/02', covid: 2680, influenza: 6400, dengue: 12, tb: 43 },
  { month: '2026/03', covid: 1890, influenza: 4100, dengue: 67, tb: 40 },
];

/** 醫療品質指標 */
export const qualityIndicators = [
  { name: '剖腹產率', value: 32.5, target: 30.0, unit: '%', status: 'warning' as const },
  { name: '抗生素使用率', value: 24.8, target: 25.0, unit: '%', status: 'good' as const },
  { name: '急診轉住院', value: 18.2, target: 20.0, unit: '%', status: 'good' as const },
  { name: '院內感染率', value: 2.1, target: 2.5, unit: '%', status: 'good' as const },
  { name: '手術死亡率', value: 0.8, target: 1.0, unit: '%', status: 'good' as const },
  { name: '再入院率', value: 12.3, target: 10.0, unit: '%', status: 'warning' as const },
  { name: '門診等候時間', value: 28, target: 30, unit: '分鐘', status: 'good' as const },
  { name: '病床使用率', value: 85.6, target: 85.0, unit: '%', status: 'warning' as const },
];

/** ESG 指標 */
export const esgIndicators = [
  { category: '碳排放量', value: 4250, unit: '噸CO₂e', change: -8.2, trend: 'down' as const },
  { category: '廢棄物回收率', value: 72.5, unit: '%', change: 3.1, trend: 'up' as const },
  { category: '綠色採購比', value: 45.8, unit: '%', change: 5.6, trend: 'up' as const },
  { category: '員工滿意度', value: 78.3, unit: '%', change: 2.4, trend: 'up' as const },
  { category: '社區服務時數', value: 1250, unit: '小時', change: 12.0, trend: 'up' as const },
  { category: '能源使用強度', value: 186, unit: 'kWh/m²', change: -4.5, trend: 'down' as const },
];

/** 品質指標柱狀圖數據 */
export const qualityBarData = [
  { name: '指標1\n剖腹產', actual: 32.5, target: 30.0 },
  { name: '指標2\n抗生素', actual: 24.8, target: 25.0 },
  { name: '指標3\n急診轉住院', actual: 18.2, target: 20.0 },
  { name: '指標5\n院內感染', actual: 2.1, target: 2.5 },
  { name: '指標8\n再入院', actual: 12.3, target: 10.0 },
  { name: '指標15\n等候時間', actual: 28, target: 30 },
];

/** 最新消息 */
export const announcements = [
  {
    date: '2026/03/25',
    title: '2026 Q1 流感趨勢報告已更新',
    category: '數據更新',
    badge: 'new' as const,
  },
  {
    date: '2026/03/20',
    title: '新增 ESG 永續指標監測模組',
    category: '功能更新',
    badge: 'feature' as const,
  },
  {
    date: '2026/03/15',
    title: '醫療品質指標 Q4 2025 報告發布',
    category: '報告發布',
    badge: 'report' as const,
  },
  {
    date: '2026/03/10',
    title: 'AI 健康趨勢分析即將上線',
    category: '即將推出',
    badge: 'upcoming' as const,
  },
];

/** 統計數字 */
export const stats = {
  diseases: 9,
  qualityMetrics: 20,
  updateFrequency: '每日',
  hospitals: 6,
  lastUpdated: '2026-03-25T08:00:00+08:00',
};

/** 數據查詢頁面 — 疾病統計表 */
export const diseaseTableData = [
  { id: 1, disease: 'COVID-19', thisMonth: 1890, lastMonth: 2680, change: -29.5, severity: 'medium' as const },
  { id: 2, disease: '流感', thisMonth: 4100, lastMonth: 6400, change: -35.9, severity: 'high' as const },
  { id: 3, disease: '登革熱', thisMonth: 67, lastMonth: 12, change: 458.3, severity: 'low' as const },
  { id: 4, disease: '結核病', thisMonth: 40, lastMonth: 43, change: -7.0, severity: 'low' as const },
  { id: 5, disease: '腸病毒', thisMonth: 520, lastMonth: 380, change: 36.8, severity: 'medium' as const },
  { id: 6, disease: 'A型肝炎', thisMonth: 15, lastMonth: 18, change: -16.7, severity: 'low' as const },
  { id: 7, disease: '百日咳', thisMonth: 8, lastMonth: 12, change: -33.3, severity: 'low' as const },
  { id: 8, disease: '麻疹', thisMonth: 3, lastMonth: 5, change: -40.0, severity: 'low' as const },
  { id: 9, disease: '日本腦炎', thisMonth: 2, lastMonth: 1, change: 100.0, severity: 'low' as const },
];

// ============================================================
// 門診品質指標 模擬數據
// ============================================================

/** 門診用藥趨勢（季度） */
export const outpatientTrendData = [
  { quarter: '113Q1', injection: 0.92, antibiotic: 20.1 },
  { quarter: '113Q2', injection: 0.89, antibiotic: 19.5 },
  { quarter: '113Q3', injection: 0.95, antibiotic: 19.8 },
  { quarter: '113Q4', injection: 0.91, antibiotic: 19.2 },
  { quarter: '114Q1', injection: 0.88, antibiotic: 18.7 },
  { quarter: '114Q2', injection: 0.86, antibiotic: 18.3 },
];

/** 同院用藥重疊率（8類藥理） */
export const sameHospitalOverlapData = [
  { drug: '降血壓', code: '03-1', value: 5.8, target: 8.0, fullMark: 20 },
  { drug: '降血脂', code: '03-2', value: 4.2, target: 6.0, fullMark: 20 },
  { drug: '降血糖', code: '03-3', value: 6.1, target: 8.0, fullMark: 20 },
  { drug: '抗思覺失調', code: '03-4', value: 3.5, target: 5.0, fullMark: 20 },
  { drug: '抗憂鬱', code: '03-5', value: 4.8, target: 6.0, fullMark: 20 },
  { drug: '安眠鎮靜', code: '03-6', value: 7.2, target: 8.0, fullMark: 20 },
  { drug: '抗血栓', code: '03-7', value: 3.1, target: 5.0, fullMark: 20 },
  { drug: '前列腺肥大', code: '03-8', value: 2.4, target: 4.0, fullMark: 20 },
];

/** 跨院用藥重疊率（8類藥理） */
export const crossHospitalOverlapData = [
  { drug: '降血壓', code: '03-9', value: 12.3, target: 15.0, fullMark: 30 },
  { drug: '降血脂', code: '03-10', value: 8.6, target: 12.0, fullMark: 30 },
  { drug: '降血糖', code: '03-11', value: 10.5, target: 14.0, fullMark: 30 },
  { drug: '抗思覺失調', code: '03-12', value: 6.2, target: 10.0, fullMark: 30 },
  { drug: '抗憂鬱', code: '03-13', value: 7.8, target: 10.0, fullMark: 30 },
  { drug: '安眠鎮靜', code: '03-14', value: 14.1, target: 15.0, fullMark: 30 },
  { drug: '抗血栓', code: '03-15', value: 5.5, target: 8.0, fullMark: 30 },
  { drug: '前列腺肥大', code: '03-16', value: 4.9, target: 7.0, fullMark: 30 },
];

/** 處方管理 & 慢性病管理指標 */
export const prescriptionManagementData = [
  { name: '慢性病連續處方箋開立率', code: '04', value: 72.3, target: 80.0, unit: '%', lowerBetter: false },
  { name: '處方≥10項藥品比率', code: '05', value: 8.3, target: 10.0, unit: '%', lowerBetter: true },
  { name: '兒童氣喘急診率', code: '06', value: 4.2, target: 5.0, unit: '%', lowerBetter: true },
  { name: '糖尿病HbA1c執行率', code: '07', value: 85.1, target: 80.0, unit: '%', lowerBetter: false },
];
