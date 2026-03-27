import type { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: LucideIcon;
  variant?: 'blue' | 'emerald' | 'amber' | 'violet';
}

const variants = {
  blue: {
    bg: 'stat-blue',
    icon: 'bg-blue-100 text-blue-600',
    value: 'text-blue-900',
    border: 'border-blue-100',
  },
  emerald: {
    bg: 'stat-emerald',
    icon: 'bg-emerald-100 text-emerald-600',
    value: 'text-emerald-900',
    border: 'border-emerald-100',
  },
  amber: {
    bg: 'stat-amber',
    icon: 'bg-amber-100 text-amber-600',
    value: 'text-amber-900',
    border: 'border-amber-100',
  },
  violet: {
    bg: 'stat-violet',
    icon: 'bg-violet-100 text-violet-600',
    value: 'text-violet-900',
    border: 'border-violet-100',
  },
};

export function StatCard({ title, value, subtitle, icon: Icon, variant = 'blue' }: StatCardProps) {
  const v = variants[variant];

  return (
    <div className={cn('rounded-2xl p-5 border card-hover', v.bg, v.border)}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-slate-600 mb-1">{title}</p>
          <p className={cn('text-3xl font-bold tracking-tight', v.value)}>{value}</p>
          {subtitle && (
            <p className="text-xs text-slate-500 mt-1">{subtitle}</p>
          )}
        </div>
        <div className={cn('w-10 h-10 rounded-xl flex items-center justify-center', v.icon)}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
    </div>
  );
}
