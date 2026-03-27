'use client';

import { useState } from 'react';
import {
  Syringe, Pill, ArrowLeftRight, ClipboardList,
  TrendingDown, TrendingUp, Building2, Repeat2,
} from 'lucide-react';
import { StatCard } from '@/components/stat-card';
import {
  OutpatientTrendChart,
  DrugOverlapRadarChart,
  DrugOverlapBarChart,
  GaugeCard,
} from '@/components/outpatient-charts';
import {
  outpatientTrendData,
  sameHospitalOverlapData,
  crossHospitalOverlapData,
  prescriptionManagementData,
} from '@/lib/mock-data';

type OverlapTab = 'same' | 'cross';

export default function OutpatientPage() {
  const [overlapTab, setOverlapTab] = useState<OverlapTab>('same');

  const latestTrend = outpatientTrendData[outpatientTrendData.length - 1];
  const injectionStatus = latestTrend.injection <= 0.94 ? 'good' : 'warning';
  const antibioticStatus = latestTrend.antibiotic <= 19.84 ? 'good' : 'warning';

  const overlapData = overlapTab === 'same' ? sameHospitalOverlapData : crossHospitalOverlapData;

  return (
    <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900">門診品質指標儀表板</h1>
        <p className="text-sm text-slate-500 mt-1">
          醫院總額醫療品質資訊 — 門診用藥管理 ＆ 處方品質監測
        </p>
      </div>

      {/* ── 區塊 1: 總覽卡片 ── */}
      <section className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="注射劑使用率"
          value={`${latestTrend.injection}%`}
          subtitle={injectionStatus === 'good' ? '✓ 低於目標 0.94%' : '⚠ 高於目標 0.94%'}
          icon={Syringe}
          variant={injectionStatus === 'good' ? 'emerald' : 'amber'}
        />
        <StatCard
          title="抗生素使用率"
          value={`${latestTrend.antibiotic}%`}
          subtitle={antibioticStatus === 'good' ? '✓ 低於目標 19.84%' : '⚠ 高於目標 19.84%'}
          icon={Pill}
          variant={antibioticStatus === 'good' ? 'emerald' : 'amber'}
        />
        <StatCard
          title="同院重疊指標"
          value={`${sameHospitalOverlapData.length} 項`}
          subtitle="均低於全國平均"
          icon={Building2}
          variant="blue"
        />
        <StatCard
          title="跨院重疊指標"
          value={`${crossHospitalOverlapData.length} 項`}
          subtitle="監測 8 類藥理分類"
          icon={Repeat2}
          variant="violet"
        />
      </section>

      {/* ── 區塊 2: 用藥趨勢折線圖 ── */}
      <section className="rounded-2xl border border-slate-200/60 bg-white/70 backdrop-blur p-6">
        <h2 className="text-lg font-semibold text-slate-800 mb-1">門診用藥趨勢</h2>
        <p className="text-xs text-slate-500 mb-4">
          指標 01 注射劑使用率 &amp; 指標 02 抗生素使用率 — 季度追蹤（虛線 = 目標值）
        </p>
        <OutpatientTrendChart data={outpatientTrendData} />
      </section>

      {/* ── 區塊 3: 用藥重疊率 ── */}
      <section className="rounded-2xl border border-slate-200/60 bg-white/70 backdrop-blur p-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-lg font-semibold text-slate-800">門診同藥理用藥日數重疊率</h2>
            <p className="text-xs text-slate-500 mt-0.5">指標 03-1 ~ 03-16（8 類藥理分類，同院 vs 跨院）</p>
          </div>
          {/* Tab 切換 */}
          <div className="flex bg-slate-100 rounded-lg p-1">
            <button
              onClick={() => setOverlapTab('same')}
              className={`px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
                overlapTab === 'same'
                  ? 'bg-white text-blue-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              同院
            </button>
            <button
              onClick={() => setOverlapTab('cross')}
              className={`px-4 py-1.5 text-sm font-medium rounded-md transition-all ${
                overlapTab === 'cross'
                  ? 'bg-white text-blue-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              跨院
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* 雷達圖 */}
          <DrugOverlapRadarChart
            data={overlapData}
            title={overlapTab === 'same' ? '同院用藥重疊率' : '跨院用藥重疊率'}
          />
          {/* 水平柱狀圖 */}
          <div>
            <h4 className="text-sm font-semibold text-slate-700 text-center mb-2">各藥理分類詳細數值</h4>
            <DrugOverlapBarChart data={overlapData} />
          </div>
        </div>
      </section>

      {/* ── 區塊 4: 處方管理 & 慢性病管理 ── */}
      <section className="rounded-2xl border border-slate-200/60 bg-white/70 backdrop-blur p-6">
        <h2 className="text-lg font-semibold text-slate-800 mb-1">處方管理 &amp; 慢性病管理</h2>
        <p className="text-xs text-slate-500 mb-6">
          指標 04 慢性病連續處方箋 · 指標 05 多重用藥 · 指標 06 兒童氣喘急診 · 指標 07 糖尿病 HbA1c
        </p>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {prescriptionManagementData.map((item) => (
            <GaugeCard key={item.code} item={item} />
          ))}
        </div>
      </section>
    </main>
  );
}
