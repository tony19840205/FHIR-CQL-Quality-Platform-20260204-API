import {
  ShieldCheck, Database, Eye, Lock,
  Server, Brain, FileText, Heart,
} from 'lucide-react';

export default function AboutPage() {
  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      {/* Hero */}
      <div className="mb-12">
        <h1 className="text-2xl md:text-3xl font-bold text-slate-900 mb-3">關於平台</h1>
        <p className="text-lg text-slate-500 leading-relaxed">
          公共健康數據平台是基於 FHIR（Fast Healthcare Interoperability Resources）國際標準建立的開放式醫療數據展示系統。
        </p>
      </div>

      {/* Mission */}
      <section className="section-card mb-8">
        <h2 className="text-xl font-bold text-slate-900 mb-4 flex items-center gap-2">
          <Heart className="w-5 h-5 text-rose-500" />
          平台使命
        </h2>
        <p className="text-slate-600 leading-relaxed">
          我們相信<strong>資訊透明</strong>是公共健康的基石。透過將醫療機構的統計數據以匿名化、標準化的方式對外公開，
          讓民眾能即時了解傳染病趨勢、醫療品質以及醫療機構的 ESG 永續表現，
          進而提升全民健康意識，促進醫療體系持續改善。
        </p>
      </section>

      {/* Features */}
      <section className="mb-8">
        <h2 className="text-xl font-bold text-slate-900 mb-6">核心特色</h2>
        <div className="grid sm:grid-cols-2 gap-4">
          {[
            {
              icon: Database,
              title: 'FHIR 國際標準',
              desc: '採用 HL7 FHIR R4 標準格式，確保數據互通性與國際接軌。'
            },
            {
              icon: ShieldCheck,
              title: '去識別化處理',
              desc: '所有對外公開數據皆經嚴格去識別化，絕不包含個人資訊。'
            },
            {
              icon: Eye,
              title: '即時透明',
              desc: '數據每日更新，民眾可即時掌握最新公共健康動態。'
            },
            {
              icon: Brain,
              title: 'AI 智慧分析',
              desc: '整合大型語言模型，提供趨勢分析與健康資訊問答服務。'
            },
            {
              icon: Lock,
              title: '隱私保護',
              desc: '內部醫療資料與外部展示完全隔離，確保病患隱私安全。'
            },
            {
              icon: Server,
              title: '開放架構',
              desc: '部署於 GitHub Pages，程式碼開源，歡迎各界檢視與合作。'
            },
          ].map(({ icon: Icon, title, desc }) => (
            <div key={title} className="section-card flex gap-4">
              <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center shrink-0">
                <Icon className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h3 className="font-semibold text-slate-900 mb-1">{title}</h3>
                <p className="text-sm text-slate-500 leading-relaxed">{desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Data flow */}
      <section className="section-card mb-8">
        <h2 className="text-xl font-bold text-slate-900 mb-4 flex items-center gap-2">
          <FileText className="w-5 h-5 text-blue-600" />
          數據流程
        </h2>
        <div className="space-y-4">
          {[
            {
              step: '1',
              title: '數據採集',
              desc: '醫療機構透過 FHIR 標準介面提供結構化醫療數據。',
            },
            {
              step: '2',
              title: '去識別化處理',
              desc: '系統自動進行數據去識別化，移除所有個人身分資訊，僅保留統計性聚合數據。',
            },
            {
              step: '3',
              title: '對外發布',
              desc: '處理後的匿名化統計數據發布至本公開平台，供民眾瀏覽。',
            },
            {
              step: '4',
              title: 'AI 分析',
              desc: '大型語言模型僅接收統計數據，提供趨勢分析與衛教資訊問答。',
            },
          ].map(({ step, title, desc }) => (
            <div key={step} className="flex gap-4 items-start">
              <div className="w-8 h-8 rounded-full bg-blue-600 text-white flex items-center justify-center text-sm font-bold shrink-0">
                {step}
              </div>
              <div>
                <h3 className="font-semibold text-slate-900">{title}</h3>
                <p className="text-sm text-slate-500 mt-0.5">{desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Disclaimer */}
      <section className="rounded-2xl bg-slate-100 border border-slate-200 p-6">
        <h2 className="text-lg font-bold text-slate-900 mb-3">免責聲明</h2>
        <ul className="space-y-2 text-sm text-slate-600">
          <li>• 本平台提供之資訊僅供參考，不構成醫療診斷或治療建議。</li>
          <li>• 若有健康疑慮，請諮詢專業醫療人員。</li>
          <li>• 所有統計數據皆經去識別化處理，不包含任何個人可識別資訊。</li>
          <li>• AI 回覆基於統計數據生成，可能存在侷限性，請審慎參考。</li>
        </ul>
      </section>
    </div>
  );
}
