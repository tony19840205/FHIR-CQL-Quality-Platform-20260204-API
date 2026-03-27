import {
  diseaseTrendData,
  qualityBarData,
  qualityIndicators,
  esgIndicators,
  announcements,
  stats,
  diseaseTableData,
} from './mock-data';

export interface DashboardData {
  exportedAt?: string;
  diseaseTrendData: typeof diseaseTrendData;
  qualityBarData: typeof qualityBarData;
  qualityIndicators: typeof qualityIndicators;
  esgIndicators: typeof esgIndicators;
  announcements: typeof announcements;
  stats: typeof stats;
  diseaseTableData: typeof diseaseTableData;
}

export async function loadDashboardData(): Promise<DashboardData> {
  try {
    const res = await fetch('/data/dashboard-data.json');
    if (res.ok) {
      const json = await res.json();
      if (json && json.exportedAt) return json as DashboardData;
    }
  } catch {
    // fall through to mock data
  }

  return {
    diseaseTrendData,
    qualityBarData,
    qualityIndicators,
    esgIndicators,
    announcements,
    stats,
    diseaseTableData,
  };
}
