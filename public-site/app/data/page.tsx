'use client';

import { useState, useEffect } from 'react';
import {
  Search, Download, TrendingUp, TrendingDown, Minus,
  Filter, Calendar, ChevronDown, AlertTriangle,
} from 'lucide-react';
import { DiseaseTrendChart } from '@/components/charts';
import {
  diseaseTrendData as mockDiseaseTrend,
  diseaseTableData as mockDiseaseTable,
} from '@/lib/mock-data';
import { loadDashboardData } from '@/lib/data-loader';
import { formatNumber, cn } from '@/lib/utils';

const timeRanges = ['近 3 個月', '近 6 個月', '近 9 個月', '近 1 年'];

export default function DataPage() {
  const [diseaseTrendData, setDiseaseTrend] = useState(mockDiseaseTrend);
  const [diseaseTableData, setDiseaseTable] = useState(mockDiseaseTable);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedRange, setSelectedRange] = useState('近 9 個月');
  const [sortField, setSortField] = useState<'disease' | 'thisMonth' | 'change'>('thisMonth');
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('desc');
  const [dataSource, setDataSource] = useState<'mock' | 'real'>('mock');

  useEffect(() => {
    loadDashboardData().then((d) => {
      if (d.exportedAt) setDataSource('real');
      setDiseaseTrend(d.diseaseTrendData);
      setDiseaseTable(d.diseaseTableData);
    });
  }, []);

  const filtered = diseaseTableData
    .filter((d) => d.disease.toLowerCase().includes(searchTerm.toLowerCase()))
    .sort((a, b) => {
      const mul = sortDir === 'asc' ? 1 : -1;
      if (sortField === 'disease') return mul * a.disease.localeCompare(b.disease, 'zh-TW');
      return mul * ((a[sortField] as number) - (b[sortField] as number));
    });

  const toggleSort = (field: typeof sortField) => {
    if (sortField === field) setSortDir(sortDir === 'asc' ? 'desc' : 'asc');
    else { setSortField(field); setSortDir('desc'); }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      {/* Data Source Banner */}
      {dataSource === 'mock' && (
        <div className="mb-6 flex items-center gap-3 bg-amber-50 border border-amber-200 rounded-xl px-4 py-3">
          <AlertTriangle className="w-5 h-5 text-amber-500 shrink-0" />
          <p className="text-sm text-amber-800">
            <span className="font-semibold">目前顯示為示範數據</span> — 待控制台執行查詢並匯出後將顯示真實數據
          </p>
        </div>
      )}

      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl md:text-3xl font-bold text-slate-900">數據查詢</h1>
        <p className="text-slate-500 mt-1">瀏覽最新的匿名化公共健康統計數據</p>
      </div>

      {/* Toolbar */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="搜尋疾病名稱..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-400 transition-all"
          />
        </div>
        <div className="flex gap-2">
          {/* Time range */}
          <div className="relative">
            <select
              value={selectedRange}
              onChange={(e) => setSelectedRange(e.target.value)}
              className="appearance-none pl-9 pr-8 py-2.5 rounded-xl border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-400 cursor-pointer"
            >
              {timeRanges.map(r => <option key={r} value={r}>{r}</option>)}
            </select>
            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
            <ChevronDown className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none" />
          </div>
          {/* Export */}
          <button className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-slate-200 bg-white text-sm text-slate-700 hover:bg-slate-50 transition-colors">
            <Download className="w-4 h-4" />
            匯出
          </button>
        </div>
      </div>

      {/* Chart */}
      <div className="section-card mb-8">
        <h2 className="text-lg font-bold text-slate-900 mb-1">趨勢圖表</h2>
        <p className="text-sm text-slate-500 mb-4">{selectedRange}主要傳染病通報數趨勢</p>
        <DiseaseTrendChart data={diseaseTrendData} />
      </div>

      {/* Table */}
      <div className="section-card overflow-hidden">
        <h2 className="text-lg font-bold text-slate-900 mb-4">疾病統計列表</h2>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-100">
                <th className="text-left py-3 px-4 text-slate-500 font-semibold cursor-pointer hover:text-slate-900" onClick={() => toggleSort('disease')}>
                  <span className="inline-flex items-center gap-1">疾病名稱 <Filter className="w-3 h-3" /></span>
                </th>
                <th className="text-right py-3 px-4 text-slate-500 font-semibold cursor-pointer hover:text-slate-900" onClick={() => toggleSort('thisMonth')}>
                  <span className="inline-flex items-center gap-1">本月通報 <Filter className="w-3 h-3" /></span>
                </th>
                <th className="text-right py-3 px-4 text-slate-500 font-semibold">上月通報</th>
                <th className="text-right py-3 px-4 text-slate-500 font-semibold cursor-pointer hover:text-slate-900" onClick={() => toggleSort('change')}>
                  <span className="inline-flex items-center gap-1">變化率 <Filter className="w-3 h-3" /></span>
                </th>
                <th className="text-center py-3 px-4 text-slate-500 font-semibold">嚴重度</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((row) => (
                <tr key={row.id} className="border-b border-slate-50 hover:bg-slate-50/70 transition-colors">
                  <td className="py-3 px-4 font-medium text-slate-800">{row.disease}</td>
                  <td className="py-3 px-4 text-right font-semibold text-slate-900">{formatNumber(row.thisMonth)}</td>
                  <td className="py-3 px-4 text-right text-slate-500">{formatNumber(row.lastMonth)}</td>
                  <td className="py-3 px-4 text-right">
                    <span className={cn(
                      'inline-flex items-center gap-1 font-medium',
                      row.change > 0 ? 'text-red-600' : row.change < 0 ? 'text-emerald-600' : 'text-slate-500'
                    )}>
                      {row.change > 0 ? <TrendingUp className="w-3.5 h-3.5" /> : row.change < 0 ? <TrendingDown className="w-3.5 h-3.5" /> : <Minus className="w-3.5 h-3.5" />}
                      {row.change > 0 ? '+' : ''}{row.change.toFixed(1)}%
                    </span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className={cn(
                      'text-xs px-2.5 py-1 rounded-full font-medium',
                      row.severity === 'high' ? 'bg-red-100 text-red-700' :
                      row.severity === 'medium' ? 'bg-amber-100 text-amber-700' :
                      'bg-slate-100 text-slate-600'
                    )}>
                      {row.severity === 'high' ? '高' : row.severity === 'medium' ? '中' : '低'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filtered.length === 0 && (
          <div className="text-center py-12 text-slate-400">
            <Search className="w-8 h-8 mx-auto mb-2" />
            <p>沒有符合搜尋條件的結果</p>
          </div>
        )}
      </div>
    </div>
  );
}
