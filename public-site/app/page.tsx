'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Activity, ShieldCheck, TrendingUp, Building2,
  Clock, BarChart3, MessageSquare, ArrowRight,
  Sparkles, Bell, Tag, FileText, ChevronRight, AlertTriangle,
} from 'lucide-react';
import { StatCard } from '@/components/stat-card';
import { DiseaseTrendChart, QualityBarChart } from '@/components/charts';
import {
  diseaseTrendData as mockDiseaseTrend,
  qualityBarData as mockQualityBar,
  qualityIndicators as mockQualityIndicators,
  esgIndicators as mockEsgIndicators,
  announcements as mockAnnouncements,
  stats as mockStats,
} from '@/lib/mock-data';
import { loadDashboardData, type DashboardData } from '@/lib/data-loader';
import { formatNumber } from '@/lib/utils';

const badgeStyles = {
  new: 'bg-red-100 text-red-700',
  feature: 'bg-blue-100 text-blue-700',
  report: 'bg-emerald-100 text-emerald-700',
  upcoming: 'bg-violet-100 text-violet-700',
};

export default function HomePage() {
  const [diseaseTrendData, setDiseaseTrend] = useState(mockDiseaseTrend);
  const [qualityBarData, setQualityBar] = useState(mockQualityBar);
  const [qualityIndicators, setQualityIndicators] = useState(mockQualityIndicators);
  const [esgIndicators, setEsgIndicators] = useState(mockEsgIndicators);
  const [announcements, setAnnouncements] = useState(mockAnnouncements);
  const [stats, setStats] = useState(mockStats);
  const [dataSource, setDataSource] = useState<'mock' | 'real'>('mock');

  useEffect(() => {
    loadDashboardData().then((d) => {
      if (d.exportedAt) setDataSource('real');
      setDiseaseTrend(d.diseaseTrendData);
      setQualityBar(d.qualityBarData);
      setQualityIndicators(d.qualityIndicators);
      setEsgIndicators(d.esgIndicators);
      setAnnouncements(d.announcements);
      setStats(d.stats);
    });
  }, []);

  return (
    <div>
      {/* ─── Data Source Banner ─── */}
      {dataSource === 'mock' && (
        <div className="bg-amber-50 border-b border-amber-200 px-4 py-3">
          <div className="max-w-7xl mx-auto flex items-center gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-500 shrink-0" />
            <p className="text-sm text-amber-800">
              <span className="font-semibold">目前顯示為示範數據</span>
              <span className="hidden sm:inline"> — 待醫療品質控制台執行查詢並匯出後，將自動替換為真實數據</span>
            </p>
          </div>
        </div>
      )}
      {dataSource === 'real' && (
        <div className="bg-emerald-50 border-b border-emerald-200 px-4 py-3">
          <div className="max-w-7xl mx-auto flex items-center gap-3">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <p className="text-sm text-emerald-800">
              <span className="font-semibold">真實數據</span> — 來自醫療品質控制台匯出
            </p>
          </div>
        </div>
      )}

      {/* ─── Hero ─── */}
      <section className="hero-gradient text-white relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-20 left-10 w-72 h-72 bg-white rounded-full blur-3xl" />
          <div className="absolute bottom-10 right-20 w-96 h-96 bg-violet-300 rounded-full blur-3xl" />
        </div>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 md:py-24 relative">
          <div className="max-w-3xl">
            <div className="inline-flex items-center gap-2 bg-white/15 backdrop-blur-sm px-4 py-1.5 rounded-full text-sm mb-6">
              <Sparkles className="w-4 h-4" />
              <span>即時更新 &middot; 去識別化 &middot; AI 分析</span>
              {dataSource === 'real' && (
                <span className="ml-2 px-2 py-0.5 bg-emerald-400/25 rounded-full text-xs font-medium">● 真實數據</span>
              )}
            </div>
            <h1 className="text-3xl md:text-5xl font-extrabold leading-tight mb-4">
              公共健康數據<br />透明開放平台
            </h1>
            <p className="text-lg md:text-xl text-white/80 mb-8 leading-relaxed">
              整合 FHIR 醫療標準數據，提供傳染病趨勢、醫療品質指標與 ESG 永續報告。<br />
              所有資料皆經去識別化處理，保護病患隱私。
            </p>
            <div className="flex flex-wrap gap-3">
              <Link
                href="/data/"
                className="inline-flex items-center gap-2 bg-white text-blue-700 font-semibold px-6 py-3 rounded-xl hover:bg-blue-50 transition-colors shadow-lg shadow-black/10"
              >
                <BarChart3 className="w-5 h-5" />
                瀏覽數據
              </Link>
              <Link
                href="/ai-chat/"
                className="inline-flex items-center gap-2 bg-white/15 backdrop-blur-sm text-white font-semibold px-6 py-3 rounded-xl hover:bg-white/25 transition-colors border border-white/30"
              >
                <MessageSquare className="w-5 h-5" />
                AI 健康問答
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ─── Stats ─── */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 -mt-10 relative z-10">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard title="監控疾病數" value={`${stats.diseases}+`} subtitle="傳染病項目" icon={ShieldCheck} variant="blue" />
          <StatCard title="品質指標" value={`${stats.qualityMetrics}+`} subtitle="醫療品質量測" icon={TrendingUp} variant="emerald" />
          <StatCard title="更新頻率" value={stats.updateFrequency} subtitle="資料更新週期" icon={Clock} variant="amber" />
          <StatCard title="醫療機構" value={`${stats.hospitals}+`} subtitle="合作醫院" icon={Building2} variant="violet" />
        </div>
      </section>

      {/* ─── Trend Chart ─── */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-12">
        <div className="section-card">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-6">
            <div>
              <h2 className="text-xl font-bold text-slate-900">傳染病趨勢</h2>
              <p className="text-sm text-slate-500 mt-1">近 9 個月通報數統計</p>
            </div>
            <Link href="/data/" className="text-sm text-blue-600 hover:text-blue-700 font-medium inline-flex items-center gap-1 mt-2 sm:mt-0">
              查看完整數據 <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
          <DiseaseTrendChart data={diseaseTrendData} />
        </div>
      </section>

      {/* ─── Quality + ESG ─── */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
        <div className="grid lg:grid-cols-2 gap-6">
          {/* Quality bar chart */}
          <div className="section-card">
            <h2 className="text-xl font-bold text-slate-900 mb-1">醫療品質指標</h2>
            <p className="text-sm text-slate-500 mb-6">實際值 vs 目標值</p>
            <QualityBarChart data={qualityBarData} />
          </div>

          {/* ESG indicators */}
          <div className="section-card">
            <h2 className="text-xl font-bold text-slate-900 mb-1">ESG 永續指標</h2>
            <p className="text-sm text-slate-500 mb-6">環境 · 社會 · 治理</p>
            <div className="space-y-3">
              {esgIndicators.map((item) => (
                <div key={item.category} className="flex items-center justify-between p-3 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">
                  <div>
                    <p className="text-sm font-medium text-slate-800">{item.category}</p>
                    <p className="text-xs text-slate-500">{item.unit}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-lg font-bold text-slate-900">{formatNumber(item.value)}</p>
                    <p className={`text-xs font-medium ${item.trend === 'up' ? 'text-emerald-600' : 'text-blue-600'}`}>
                      {item.change > 0 ? '+' : ''}{item.change}%
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ─── Quality Indicator Mini-list ─── */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
        <div className="section-card">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-xl font-bold text-slate-900">品質達標狀態</h2>
              <p className="text-sm text-slate-500 mt-1">主要監測指標達標一覽</p>
            </div>
          </div>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-3">
            {qualityIndicators.map((ind) => (
              <div
                key={ind.name}
                className={`p-4 rounded-xl border ${
                  ind.status === 'good'
                    ? 'bg-emerald-50 border-emerald-100'
                    : 'bg-amber-50 border-amber-100'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-slate-700">{ind.name}</span>
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                    ind.status === 'good' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'
                  }`}>
                    {ind.status === 'good' ? '達標' : '待改善'}
                  </span>
                </div>
                <div className="flex items-baseline gap-1">
                  <span className="text-2xl font-bold text-slate-900">{ind.value}</span>
                  <span className="text-sm text-slate-500">{ind.unit}</span>
                </div>
                <p className="text-xs text-slate-500 mt-1">目標：{ind.target} {ind.unit}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── News + AI promo ─── */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 mb-16">
        <div className="grid lg:grid-cols-5 gap-6">
          {/* Announcements */}
          <div className="lg:col-span-3 section-card">
            <div className="flex items-center gap-2 mb-5">
              <Bell className="w-5 h-5 text-blue-600" />
              <h2 className="text-xl font-bold text-slate-900">最新消息</h2>
            </div>
            <div className="space-y-3">
              {announcements.map((a, i) => (
                <div key={i} className="flex items-start gap-4 p-3 rounded-xl hover:bg-slate-50 transition-colors group cursor-pointer">
                  <div className="text-xs text-slate-400 w-20 shrink-0 pt-0.5">{a.date}</div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-slate-800 group-hover:text-blue-700 transition-colors">{a.title}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <Tag className="w-3 h-3 text-slate-400" />
                      <span className="text-xs text-slate-500">{a.category}</span>
                      <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium ${badgeStyles[a.badge]}`}>
                        {a.badge === 'new' ? '新' : a.badge === 'feature' ? '功能' : a.badge === 'report' ? '報告' : '即將'}
                      </span>
                    </div>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-300 group-hover:text-blue-500 transition-colors shrink-0 mt-1" />
                </div>
              ))}
            </div>
          </div>

          {/* AI promo */}
          <div className="lg:col-span-2 rounded-2xl bg-gradient-to-br from-violet-600 to-blue-600 p-6 text-white flex flex-col justify-between">
            <div>
              <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center mb-4">
                <MessageSquare className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">AI 健康問答</h3>
              <p className="text-white/80 text-sm leading-relaxed mb-6">
                輸入健康相關問題，AI 將根據最新的公開統計數據為您分析趨勢、提供衛教資訊。
              </p>
            </div>
            <Link
              href="/ai-chat/"
              className="inline-flex items-center gap-2 bg-white text-violet-700 font-semibold px-5 py-2.5 rounded-xl hover:bg-violet-50 transition-colors w-fit"
            >
              開始提問 <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
