'use client';

import {
  LineChart, Line, BarChart, Bar,
  RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis,
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Legend, ReferenceLine, Cell,
} from 'recharts';

/* ─── 門診用藥趨勢折線圖 ─── */

interface TrendItem {
  quarter: string;
  injection: number;
  antibiotic: number;
}

export function OutpatientTrendChart({ data }: { data: TrendItem[] }) {
  return (
    <ResponsiveContainer width="100%" height={320}>
      <LineChart data={data} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
        <XAxis
          dataKey="quarter"
          tick={{ fontSize: 12, fill: '#64748b' }}
          tickLine={false}
          axisLine={{ stroke: '#e2e8f0' }}
        />
        <YAxis
          yAxisId="left"
          tick={{ fontSize: 12, fill: '#64748b' }}
          tickLine={false}
          axisLine={false}
          domain={[0, 2]}
          label={{ value: '注射劑 (%)', angle: -90, position: 'insideLeft', style: { fontSize: 11, fill: '#64748b' } }}
        />
        <YAxis
          yAxisId="right"
          orientation="right"
          tick={{ fontSize: 12, fill: '#64748b' }}
          tickLine={false}
          axisLine={false}
          domain={[0, 30]}
          label={{ value: '抗生素 (%)', angle: 90, position: 'insideRight', style: { fontSize: 11, fill: '#64748b' } }}
        />
        <Tooltip
          contentStyle={{
            background: 'rgba(255,255,255,0.96)',
            border: '1px solid #e2e8f0',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
            fontSize: '13px',
          }}
          formatter={(value: number, name: string) => [
            `${value}%`,
            name === 'injection' ? '注射劑使用率' : '抗生素使用率',
          ]}
        />
        <Legend
          wrapperStyle={{ fontSize: '12px', paddingTop: '8px' }}
          formatter={(val) => (val === 'injection' ? '注射劑使用率' : '抗生素使用率')}
        />
        {/* 注射劑目標線 0.94% */}
        <ReferenceLine yAxisId="left" y={0.94} stroke="#3b82f6" strokeDasharray="6 3" strokeWidth={1.5} label={{ value: '目標 0.94%', position: 'right', fontSize: 10, fill: '#3b82f6' }} />
        {/* 抗生素目標線 19.84% */}
        <ReferenceLine yAxisId="right" y={19.84} stroke="#f59e0b" strokeDasharray="6 3" strokeWidth={1.5} label={{ value: '目標 19.84%', position: 'right', fontSize: 10, fill: '#f59e0b' }} />
        <Line
          yAxisId="left"
          type="monotone" dataKey="injection" name="injection"
          stroke="#3b82f6" strokeWidth={2.5} dot={{ r: 4 }} activeDot={{ r: 6 }}
        />
        <Line
          yAxisId="right"
          type="monotone" dataKey="antibiotic" name="antibiotic"
          stroke="#f59e0b" strokeWidth={2.5} dot={{ r: 4 }} activeDot={{ r: 6 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}

/* ─── 用藥重疊率雷達圖 ─── */

interface OverlapItem {
  drug: string;
  code: string;
  value: number;
  target: number;
  fullMark: number;
}

export function DrugOverlapRadarChart({ data, title }: { data: OverlapItem[]; title: string }) {
  return (
    <div>
      <h4 className="text-sm font-semibold text-slate-700 text-center mb-2">{title}</h4>
      <ResponsiveContainer width="100%" height={300}>
        <RadarChart data={data} cx="50%" cy="50%" outerRadius="70%">
          <PolarGrid stroke="#e2e8f0" />
          <PolarAngleAxis
            dataKey="drug"
            tick={{ fontSize: 11, fill: '#475569' }}
          />
          <PolarRadiusAxis
            angle={90}
            tick={{ fontSize: 10, fill: '#94a3b8' }}
          />
          <Tooltip
            contentStyle={{
              background: 'rgba(255,255,255,0.96)',
              border: '1px solid #e2e8f0',
              borderRadius: '12px',
              boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
              fontSize: '13px',
            }}
            formatter={(value: number, name: string) => [
              `${value}%`,
              name === 'value' ? '本院' : '全國平均',
            ]}
          />
          <Legend
            wrapperStyle={{ fontSize: '12px' }}
            formatter={(val) => (val === 'value' ? '本院' : '全國平均')}
          />
          <Radar name="value" dataKey="value" stroke="#3b82f6" fill="#3b82f6" fillOpacity={0.25} strokeWidth={2} />
          <Radar name="target" dataKey="target" stroke="#94a3b8" fill="#94a3b8" fillOpacity={0.1} strokeWidth={1.5} strokeDasharray="4 3" />
        </RadarChart>
      </ResponsiveContainer>
    </div>
  );
}

/* ─── 用藥重疊率水平柱狀圖 ─── */

export function DrugOverlapBarChart({ data }: { data: OverlapItem[] }) {
  return (
    <ResponsiveContainer width="100%" height={320}>
      <BarChart
        data={data}
        layout="vertical"
        margin={{ top: 5, right: 40, left: 20, bottom: 5 }}
      >
        <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" horizontal={false} />
        <XAxis
          type="number"
          tick={{ fontSize: 12, fill: '#64748b' }}
          tickLine={false}
          axisLine={false}
          unit="%"
        />
        <YAxis
          type="category"
          dataKey="drug"
          tick={{ fontSize: 12, fill: '#475569' }}
          tickLine={false}
          axisLine={false}
          width={80}
        />
        <Tooltip
          contentStyle={{
            background: 'rgba(255,255,255,0.96)',
            border: '1px solid #e2e8f0',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
            fontSize: '13px',
          }}
          formatter={(value: number, name: string) => [
            `${value}%`,
            name === 'value' ? '本院' : '目標值',
          ]}
        />
        <Legend
          wrapperStyle={{ fontSize: '12px' }}
          formatter={(val) => (val === 'value' ? '本院' : '目標值')}
        />
        <Bar dataKey="value" name="value" radius={[0, 6, 6, 0]} barSize={16}>
          {data.map((entry, index) => (
            <Cell
              key={`cell-${index}`}
              fill={entry.value <= entry.target ? '#10b981' : '#f59e0b'}
            />
          ))}
        </Bar>
        <Bar dataKey="target" name="target" fill="#e2e8f0" radius={[0, 6, 6, 0]} barSize={16} />
      </BarChart>
    </ResponsiveContainer>
  );
}

/* ─── 處方管理環形進度 ─── */

interface PrescriptionItem {
  name: string;
  code: string;
  value: number;
  target: number;
  unit: string;
  lowerBetter: boolean;
}

export function GaugeCard({ item }: { item: PrescriptionItem }) {
  const { name, value, target, unit, lowerBetter } = item;
  const isGood = lowerBetter ? value <= target : value >= target;
  const pct = lowerBetter
    ? Math.max(0, Math.min(100, ((target - value) / target) * 100 + 50))
    : Math.max(0, Math.min(100, (value / target) * 100));
  const color = isGood ? '#10b981' : '#f59e0b';
  const circumference = 2 * Math.PI * 54;
  const offset = circumference - (pct / 100) * circumference;

  return (
    <div className="flex flex-col items-center p-4 rounded-2xl border border-slate-100 bg-white/60 backdrop-blur">
      <div className="relative w-32 h-32">
        <svg className="w-32 h-32 -rotate-90" viewBox="0 0 120 120">
          <circle cx="60" cy="60" r="54" fill="none" stroke="#e2e8f0" strokeWidth="10" />
          <circle
            cx="60" cy="60" r="54" fill="none"
            stroke={color} strokeWidth="10"
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            className="transition-all duration-700"
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-2xl font-bold" style={{ color }}>{value}{unit}</span>
        </div>
      </div>
      <p className="mt-2 text-sm font-medium text-slate-700 text-center leading-tight">{name}</p>
      <p className="text-xs text-slate-500 mt-1">
        目標: {lowerBetter ? '≤' : '≥'} {target}{unit}
      </p>
      <span className={`mt-1 text-xs font-semibold px-2 py-0.5 rounded-full ${isGood ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'}`}>
        {isGood ? '✓ 達標' : '⚠ 待改善'}
      </span>
    </div>
  );
}
