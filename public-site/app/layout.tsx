import type { Metadata } from 'next';
import { Navbar } from '@/components/navbar';
import { Footer } from '@/components/footer';
import './globals.css';

export const metadata: Metadata = {
  title: '公共健康數據平台 | FHIR Open Data',
  description: '基於 FHIR 標準的開放醫療數據平台，提供匿名化公共健康統計資訊與 AI 健康趨勢分析。',
  keywords: 'FHIR, 公共健康, 醫療數據, 傳染病, AI, 健康趨勢',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh-TW">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Noto+Sans+TC:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-screen flex flex-col custom-scrollbar">
        <Navbar />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
