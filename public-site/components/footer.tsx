import { Activity, Github, Heart } from 'lucide-react';

export function Footer() {
  return (
    <footer className="bg-white border-t border-slate-200 mt-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Brand */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-600 to-violet-600 flex items-center justify-center">
                <Activity className="w-4 h-4 text-white" />
              </div>
              <span className="font-bold text-slate-900">公共健康數據平台</span>
            </div>
            <p className="text-sm text-slate-500 leading-relaxed">
              基於 FHIR 標準的開放醫療數據平台，提供匿名化公共健康統計資訊，
              促進資訊透明與公眾健康意識。
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="font-semibold text-slate-900 mb-3 text-sm">快速連結</h4>
            <ul className="space-y-2 text-sm text-slate-500">
              <li><a href="/data/" className="hover:text-blue-600 transition-colors">數據查詢</a></li>
              <li><a href="/ai-chat/" className="hover:text-blue-600 transition-colors">AI 健康問答</a></li>
              <li><a href="/about/" className="hover:text-blue-600 transition-colors">關於平台</a></li>
            </ul>
          </div>

          {/* Info */}
          <div>
            <h4 className="font-semibold text-slate-900 mb-3 text-sm">資訊</h4>
            <ul className="space-y-2 text-sm text-slate-500">
              <li>資料來源：FHIR R4 標準格式</li>
              <li>更新頻率：每日更新</li>
              <li>所有數據皆經去識別化處理</li>
            </ul>
          </div>
        </div>

        <div className="border-t border-slate-100 mt-8 pt-6 flex flex-col sm:flex-row justify-between items-center gap-3">
          <p className="text-xs text-slate-400 flex items-center gap-1">
            &copy; {new Date().getFullYear()} FHIR CQL 整合平台 &middot; Made with <Heart className="w-3 h-3 text-rose-400 fill-rose-400" /> in Taiwan
          </p>
          <a
            href="https://github.com"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-slate-600 transition-colors"
          >
            <Github className="w-4 h-4" />
            GitHub
          </a>
        </div>
      </div>
    </footer>
  );
}
