'use client';

import { useState, useRef, useEffect } from 'react';
import { Send, Bot, User, Sparkles, AlertCircle, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
}

const WELCOME_MESSAGES: Message[] = [
  {
    id: 'welcome',
    role: 'assistant',
    content: '您好！我是公共健康 AI 助手。\n\n我可以根據最新的**去識別化公開統計數據**，回答您有關：\n\n• 傳染病趨勢與防疫建議\n• 醫療品質指標說明\n• ESG 永續指標解讀\n\n請問您想了解什麼？',
    timestamp: new Date(),
  },
];

const SUGGESTED_QUESTIONS = [
  '最近流感趨勢如何？',
  '剖腹產率是否達標？',
  '目前有哪些傳染病需要注意？',
  'ESG 碳排放趨勢如何？',
];

/** Markdown-lite renderer: bold, newline, bullet list */
function renderContent(text: string) {
  return text.split('\n').map((line, i) => {
    // Bold
    const parts = line.split(/(\*\*[^*]+\*\*)/g).map((part, j) => {
      if (part.startsWith('**') && part.endsWith('**')) {
        return <strong key={j}>{part.slice(2, -2)}</strong>;
      }
      return part;
    });

    // Bullet list
    if (line.startsWith('• ') || line.startsWith('- ')) {
      return <li key={i} className="ml-4 list-disc">{parts.slice(0)}</li>;
    }
    if (line === '') return <br key={i} />;
    return <p key={i}>{parts}</p>;
  });
}

export default function AIChatPage() {
  const [messages, setMessages] = useState<Message[]>(WELCOME_MESSAGES);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [llmConfigured, setLlmConfigured] = useState(false);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  /** Simulate AI response (replace with real LLM API call) */
  async function handleSend(text?: string) {
    const userText = (text || input).trim();
    if (!userText || isLoading) return;

    const userMsg: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: userText,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setIsLoading(true);

    // Simulate delay
    await new Promise((r) => setTimeout(r, 1200 + Math.random() * 800));

    const aiMsg: Message = {
      id: (Date.now() + 1).toString(),
      role: 'assistant',
      content: generateMockResponse(userText),
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, aiMsg]);
    setIsLoading(false);
  }

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-2">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-violet-600 to-blue-600 flex items-center justify-center shadow-md">
            <Sparkles className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">AI 健康問答</h1>
            <p className="text-sm text-slate-500">基於公開統計數據的智慧分析</p>
          </div>
        </div>

        {/* LLM not configured notice */}
        {!llmConfigured && (
          <div className="mt-4 p-4 rounded-xl bg-amber-50 border border-amber-200 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-amber-800">LLM 尚未設定</p>
              <p className="text-xs text-amber-700 mt-0.5">
                目前為模擬回覆模式。待 LLM API 設定完成後，將可提供即時 AI 分析。
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Chat area */}
      <div className="section-card flex flex-col" style={{ height: 'calc(100vh - 320px)', minHeight: '400px' }}>
        {/* Messages */}
        <div className="flex-1 overflow-y-auto custom-scrollbar p-4 space-y-4">
          {messages.map((msg) => (
            <div
              key={msg.id}
              className={cn(
                'flex gap-3',
                msg.role === 'user' ? 'flex-row-reverse' : 'flex-row'
              )}
            >
              <div className={cn(
                'w-8 h-8 rounded-full flex items-center justify-center shrink-0',
                msg.role === 'user' ? 'bg-blue-600' : 'bg-gradient-to-br from-violet-500 to-blue-500'
              )}>
                {msg.role === 'user' ? <User className="w-4 h-4 text-white" /> : <Bot className="w-4 h-4 text-white" />}
              </div>
              <div className={cn(
                'max-w-[80%] text-sm leading-relaxed',
                msg.role === 'user' ? 'chat-bubble-user' : 'chat-bubble-ai'
              )}>
                {renderContent(msg.content)}
              </div>
            </div>
          ))}

          {isLoading && (
            <div className="flex gap-3">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-500 to-blue-500 flex items-center justify-center shrink-0">
                <Bot className="w-4 h-4 text-white" />
              </div>
              <div className="chat-bubble-ai">
                <Loader2 className="w-4 h-4 animate-spin text-slate-400" />
              </div>
            </div>
          )}
          <div ref={endRef} />
        </div>

        {/* Suggested questions */}
        {messages.length <= 1 && (
          <div className="px-4 pb-3 flex flex-wrap gap-2">
            {SUGGESTED_QUESTIONS.map((q) => (
              <button
                key={q}
                onClick={() => handleSend(q)}
                className="text-xs px-3 py-1.5 rounded-full bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors border border-blue-100"
              >
                {q}
              </button>
            ))}
          </div>
        )}

        {/* Input */}
        <div className="border-t border-slate-100 p-4">
          <form
            onSubmit={(e) => { e.preventDefault(); handleSend(); }}
            className="flex gap-3"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="輸入您的健康問題..."
              disabled={isLoading}
              className="flex-1 px-4 py-2.5 rounded-xl border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-400 transition-all disabled:opacity-50"
            />
            <button
              type="submit"
              disabled={isLoading || !input.trim()}
              className="px-4 py-2.5 rounded-xl bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            >
              <Send className="w-4 h-4" />
            </button>
          </form>
          <p className="text-[11px] text-slate-400 mt-2 text-center">
            AI 回覆僅供參考，不構成醫療建議。若有健康疑慮請諮詢醫師。
          </p>
        </div>
      </div>
    </div>
  );
}

/* ─── Mock response generator (will be replaced by real LLM) ─── */
function generateMockResponse(question: string): string {
  const q = question.toLowerCase();

  if (q.includes('流感')) {
    return '根據最新統計數據：\n\n• **2026年3月流感通報數**為 4,100 例，較上月 6,400 例**下降 35.9%**\n• 流感高峰期通常在冬季（12月-2月），目前已逐漸趨緩\n• 建議持續注意個人衛生與接種疫苗\n\n整體而言，本季流感疫情已過高峰，呈現穩定下降趨勢。';
  }
  if (q.includes('剖腹') || q.includes('cesarean')) {
    return '根據醫療品質指標數據：\n\n• **剖腹產率**目前為 **32.5%**，目標值為 30.0%\n• 目前狀態：**待改善** ⚠️\n• 超出目標 2.5 個百分點\n\n剖腹產率偏高可能與醫療資源分配、產婦年齡結構等因素相關，各醫療機構正持續推動自然產的衛教宣導。';
  }
  if (q.includes('傳染病') || q.includes('注意')) {
    return '目前需要關注的傳染病趨勢：\n\n• **登革熱**：本月 67 例，較上月大幅上升（+458%），進入好發季節\n• **腸病毒**：520 例，上升 36.8%，兒童族群需注意\n• **COVID-19**：1,890 例，持續下降中\n• **流感**：4,100 例，已過高峰期\n\n建議加強防蚊措施，兒童注意手部衛生。';
  }
  if (q.includes('esg') || q.includes('碳排') || q.includes('永續')) {
    return '最新 ESG 永續指標概況：\n\n• **碳排放量**：4,250 噸CO₂e，年減 8.2% ✅\n• **廢棄物回收率**：72.5%，提升 3.1%\n• **綠色採購比**：45.8%，提升 5.6%\n• **能源使用強度**：186 kWh/m²，下降 4.5%\n\n整體而言，ESG 各項指標均呈正向發展，碳排放持續下降表現良好。';
  }

  return '感謝您的提問！以下是基於我們公開數據的分析：\n\n根據目前平台收集的去識別化統計數據，我們正持續監測 **9 種以上的傳染病**及 **20+ 項醫療品質指標**。\n\n您可以嘗試詢問：\n• 特定疾病的趨勢（如流感、登革熱）\n• 醫療品質指標（如剖腹產率、院內感染率）\n• ESG 永續指標（如碳排放、綠色採購）\n\n我將根據最新數據為您提供分析。';
}
