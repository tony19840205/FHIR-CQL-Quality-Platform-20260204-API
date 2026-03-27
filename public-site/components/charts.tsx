'use client';

import {
  LineChart, Line, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Legend,
} from 'recharts';

/* ─── 傳染病趨勢折線圖 ─── */

interface TrendData {
  month: string;
  covid: number;
  influenza: number;
  dengue: number;
  tb: number;
}

export function DiseaseTrendChart({ data }: { data: TrendData[] }) {
  return (
    <ResponsiveContainer width="100%" height={320}>
      <LineChart data={data} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
        <XAxis
          dataKey="month"
          tick={{ fontSize: 12, fill: '#64748b' }}
          tickLine={false}
          axisLine={{ stroke: '#e2e8f0' }}
        />
        <YAxis
          tick={{ fontSize: 12, fill: '#64748b' }}
          tickLine={false}
          axisLine={false}
        />
        <Tooltip
          contentStyle={{
            background: 'rgba(255,255,255,0.96)',
            border: '1px solid #e2e8f0',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
            fontSize: '13px',
          }}
        />
        <Legend
          wrapperStyle={{ fontSize: '12px', paddingTop: '8px' }}
        />
        <Line
          type="monotone" dataKey="covid" name="COVID-19"
          stroke="#3b82f6" strokeWidth={2.5} dot={{ r: 3 }} activeDot={{ r: 5 }}
        />
        <Line
          type="monotone" dataKey="influenza" name="流感"
          stroke="#f59e0b" strokeWidth={2.5} dot={{ r: 3 }} activeDot={{ r: 5 }}
        />
        <Line
          type="monotone" dataKey="dengue" name="登革熱"
          stroke="#10b981" strokeWidth={2.5} dot={{ r: 3 }} activeDot={{ r: 5 }}
        />
        <Line
          type="monotone" dataKey="tb" name="結核病"
          stroke="#8b5cf6" strokeWidth={2.5} dot={{ r: 3 }} activeDot={{ r: 5 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}

/* ─── 品質指標柱狀圖 ─── */

interface BarData {
  name: string;
  actual: number;
  target: number;
}

export function QualityBarChart({ data }: { data: BarData[] }) {
  return (
    <ResponsiveContainer width="100%" height={320}>
      <BarChart data={data} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
        <XAxis
          dataKey="name"
          tick={{ fontSize: 11, fill: '#64748b' }}
          tickLine={false}
          axisLine={{ stroke: '#e2e8f0' }}
          interval={0}
        />
        <YAxis
          tick={{ fontSize: 12, fill: '#64748b' }}
          tickLine={false}
          axisLine={false}
        />
        <Tooltip
          contentStyle={{
            background: 'rgba(255,255,255,0.96)',
            border: '1px solid #e2e8f0',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
            fontSize: '13px',
          }}
        />
        <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '8px' }} />
        <Bar dataKey="actual" name="實際值" fill="#3b82f6" radius={[6, 6, 0, 0]} barSize={28} />
        <Bar dataKey="target" name="目標值" fill="#e2e8f0" radius={[6, 6, 0, 0]} barSize={28} />
      </BarChart>
    </ResponsiveContainer>
  );
}
