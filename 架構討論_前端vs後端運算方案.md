# 架構討論：JSON撈到資料後在哪運算（分子分母）？

**討論日期**: 2026-01-15  
**討論主題**: 當從FHIR服務器獲取JSON數據後，分子分母的計算應該在前端還是後端？

---

## 一、當前架構分析

### 1.1 現況
根據 `js/quality-indicators.js` 的代碼分析，**當前採用 100% 前端運算架構**：

```javascript
// 當前運算流程（以指標01為例）
async function queryOutpatientInjectionRateSample(conn, quarter = null) {
    // 步驟1: 從FHIR服務器查詢Encounter（門診資料）
    const encounters = await conn.query('Encounter', {...});
    
    // 步驟2: 從FHIR服務器查詢MedicationRequest（用藥資料）
    const allMedications = await conn.query('MedicationRequest', {...});
    
    // 步驟3: 在瀏覽器JavaScript中計算分子分母
    let injectionCount = 0;      // 分子
    let totalDrugCount = 0;      // 分母
    
    for (const medEntry of allMedications.entry) {
        // 複雜的過濾邏輯（化療藥、疫苗、STAT用藥...）
        if (符合注射劑條件 && !被排除) {
            injectionCount++;    // 計算分子
        }
        totalDrugCount++;        // 計算分母
    }
    
    // 步驟4: 計算比率
    const rate = ((injectionCount / totalDrugCount) * 100).toFixed(2);
    
    return { rate, numerator: injectionCount, denominator: totalDrugCount };
}
```

**運算位置**: 全部在瀏覽器（JavaScript）執行

---

## 二、兩種架構方案比較

### 方案A：前端運算（當前方案）

#### 架構圖
```
[FHIR Server] 
    ↓ (回傳原始JSON)
[瀏覽器] 
    ├─ 接收JSON
    ├─ 過濾資料（化療藥、疫苗、STAT...）
    ├─ 計算分子分母
    └─ 顯示結果
```

#### 優點
✅ **無需後端服務器** - 節省基礎設施成本  
✅ **部署簡單** - 只需託管靜態HTML/JS檔案（GitHub Pages、Netlify）  
✅ **開發快速** - 不需要開發/維護後端API  
✅ **降低延遲** - 少一層網路往返  
✅ **透明度高** - 所有運算邏輯在前端可檢視（符合政府開放精神）  

#### 缺點
❌ **效能瓶頸** - 當資料量大（>10萬筆）時，瀏覽器可能卡頓  
❌ **安全性考量** - 運算邏輯完全暴露在前端（雖然醫療品質規範是公開的）  
❌ **網路流量** - 需要下載完整的原始資料到瀏覽器  
❌ **跨域問題** - 可能受限於FHIR服務器的CORS設定  

---

### 方案B：後端運算

#### 架構圖
```
[FHIR Server] 
    ↓ (原始JSON)
[後端服務器 Node.js/Python]
    ├─ 接收FHIR資料
    ├─ 執行複雜運算（過濾+計算）
    ├─ 快取結果
    └─ 回傳最終結果 {"numerator":12,"denominator":158,"rate":"7.59%"}
        ↓ (小型JSON)
[瀏覽器]
    └─ 顯示結果
```

#### 優點
✅ **高效能** - 後端運算速度快，可處理大數據  
✅ **減少網路流量** - 只傳最終結果到前端  
✅ **可快取** - 運算結果可存Redis/記憶體快取  
✅ **安全性** - 運算邏輯在後端，不易被竄改  
✅ **可擴展** - 易於添加排程任務、批次計算  

#### 缺點
❌ **需要後端服務器** - 增加基礎設施成本（VM或容器）  
❌ **開發成本高** - 需開發API、處理認證、部署維護  
❌ **額外延遲** - 多一層網路往返  
❌ **部署複雜** - 需要CI/CD、監控、日誌系統  

---

## 三、建議方案（混合架構）

### 3.1 架構設計

```
┌─────────────────────────────────────────────────────────┐
│                    使用者端（瀏覽器）                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │           智能調度器 (Dispatcher.js)             │   │
│  │                                                   │   │
│  │  if (資料量 < 1000筆) {                          │   │
│  │      → 前端運算                                   │   │
│  │  } else {                                         │   │
│  │      → 呼叫後端API                                │   │
│  │  }                                                │   │
│  └─────────────────────────────────────────────────┘   │
│           ↓ 前端                    ↓ 後端              │
│  ┌────────────────┐        ┌────────────────┐          │
│  │  前端計算引擎  │        │  後端API呼叫   │          │
│  │ (JS運算)       │        │  (fetch)       │          │
│  └────────────────┘        └────────────────┘          │
└─────────────────────────────────────────────────────────┘
                                  ↓
                    ┌──────────────────────────┐
                    │  後端服務器 (可選)       │
                    │  ├─ Node.js Express      │
                    │  ├─ Redis快取            │
                    │  └─ 批次計算排程         │
                    └──────────────────────────┘
```

### 3.2 實作策略

#### 階段1（當前）：純前端運算
**適用場景**: 測試環境、小型醫院（資料量 < 5萬筆）

```javascript
// 保持現有架構
async function executeQuery(indicatorId) {
    const result = await queryOutpatientInjectionRateSample(conn);
    return result;
}
```

#### 階段2（未來）：混合架構
**適用場景**: 大型醫院、區域健保局

```javascript
// 智能調度器
async function executeQuery(indicatorId) {
    // 先查詢資料量
    const dataCount = await estimateDataSize(indicatorId);
    
    if (dataCount < 1000) {
        // 前端運算（保留現有邏輯）
        return await queryInBrowser(indicatorId);
    } else {
        // 呼叫後端API
        return await queryFromBackend(indicatorId);
    }
}

// 後端API範例（Express.js）
app.post('/api/calculate-indicator', async (req, res) => {
    const { indicatorId, quarter } = req.body;
    
    // 從FHIR服務器獲取資料
    const fhirData = await fetchFromFHIR(indicatorId, quarter);
    
    // 執行運算（與前端相同邏輯）
    const result = calculateIndicator(fhirData);
    
    // 快取結果（10分鐘）
    await redis.set(`indicator:${indicatorId}:${quarter}`, result, 'EX', 600);
    
    res.json(result);
});
```

---

## 四、針對你們的專案建議

### 4.1 短期建議（1個月內）
**建議：保持當前純前端架構**

**理由**:
1. ✅ 你們已經完成39項指標的前端運算邏輯
2. ✅ 測試數據量不大（646位病人 × 8季度 ≈ 5,000筆Encounter）
3. ✅ 展示給評審時，前端運算更直觀透明
4. ✅ 政府正式公告FHIR IG前，不適合大改架構

**行動項目**:
- 無需修改，維持現況
- 加強前端效能優化（Web Worker、分頁載入）
- 監控瀏覽器效能，記錄運算時間

### 4.2 中期計畫（3-6個月）
**建議：開發後端API作為選項**

**觸發條件**:
- 單一指標查詢時間 > 5秒
- 資料量 > 5萬筆
- 需要定時批次計算（每月自動報表）

**實作步驟**:
```bash
# 1. 建立後端專案
mkdir quality-indicators-backend
cd quality-indicators-backend
npm init -y
npm install express axios redis

# 2. 開發API（複製前端運算邏輯）
# 3. Docker化部署
docker build -t quality-backend .
docker run -p 3000:3000 quality-backend
```

### 4.3 長期架構（1年後）
**建議：混合架構 + 邊緣運算**

```
┌─────────────────────────────────────────────────────────┐
│  Tier 1: 前端運算（小數據）                             │
│  ├─ 個人電腦瀏覽器                                       │
│  └─ 資料量 < 1,000筆                                     │
├─────────────────────────────────────────────────────────┤
│  Tier 2: 邊緣運算（中等數據）                           │
│  ├─ 醫院內部伺服器                                       │
│  └─ 資料量 1,000-50,000筆                                │
├─────────────────────────────────────────────────────────┤
│  Tier 3: 雲端運算（大數據）                             │
│  ├─ AWS/Azure/GCP                                        │
│  └─ 資料量 > 50,000筆                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 五、關鍵決策點

### 5.1 何時需要後端？

| 場景 | 前端足夠 | 需要後端 |
|------|----------|----------|
| 展示Demo給評審 | ✅ | ❌ |
| 小型診所（<5萬筆） | ✅ | ❌ |
| 中型醫院（5-20萬筆） | ⚠️ 建議後端 | ✅ |
| 大型醫院（>20萬筆） | ❌ | ✅✅✅ |
| 區域健保局（跨院） | ❌ | ✅✅✅ |
| 需要定時批次計算 | ❌ | ✅ |
| 需要歷史趨勢分析 | ⚠️ | ✅ |

### 5.2 評估清單

在決定是否需要後端前，請檢查：

- [ ] 單一指標查詢時間是否 > 3秒？
- [ ] 資料量是否 > 10,000筆Encounter？
- [ ] 是否需要每月自動產生報表？
- [ ] 是否需要支援100+併發用戶？
- [ ] 是否需要複雜的權限管理？

**如果勾選 ≥ 3項 → 建議開發後端**

---

## 六、程式碼範例

### 6.1 前端運算（保留現況）

```javascript
// js/quality-indicators.js
async function queryOutpatientInjectionRateSample(conn, quarter) {
    // 直接在瀏覽器計算
    const encounters = await conn.query('Encounter', {...});
    const medications = await conn.query('MedicationRequest', {...});
    
    // 分子分母計算
    let numerator = 0;
    let denominator = 0;
    
    for (const med of medications.entry) {
        if (符合條件) numerator++;
        denominator++;
    }
    
    return { numerator, denominator, rate: (numerator/denominator*100).toFixed(2) };
}
```

### 6.2 後端API（未來選項）

```javascript
// backend/routes/indicators.js
const express = require('express');
const router = express.Router();
const FHIRClient = require('../utils/fhir-client');

router.post('/calculate/:indicatorId', async (req, res) => {
    const { indicatorId } = req.params;
    const { quarter } = req.body;
    
    try {
        // 從FHIR服務器獲取資料
        const fhirClient = new FHIRClient(req.body.fhirServer);
        const encounters = await fhirClient.query('Encounter', {...});
        const medications = await fhirClient.query('MedicationRequest', {...});
        
        // 複製前端的計算邏輯（可共用同一份程式碼）
        const result = calculateIndicator01(encounters, medications);
        
        // 快取結果
        await cacheResult(indicatorId, quarter, result);
        
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
```

### 6.3 智能調度器（混合架構）

```javascript
// js/dispatcher.js
class CalculationDispatcher {
    async execute(indicatorId, quarter) {
        // 步驟1: 評估資料量
        const dataSize = await this.estimateSize(indicatorId, quarter);
        
        // 步驟2: 決策
        if (dataSize < this.THRESHOLD || !this.hasBackend()) {
            // 前端運算
            console.log('✅ 使用前端運算');
            return await this.calculateInBrowser(indicatorId, quarter);
        } else {
            // 後端運算
            console.log('✅ 使用後端API');
            return await this.calculateViaBackend(indicatorId, quarter);
        }
    }
    
    async estimateSize(indicatorId, quarter) {
        // 查詢Encounter數量（不拉取完整資料）
        const count = await fhirConnection.query('Encounter', {
            _summary: 'count',
            date: getQuarterDateRange(quarter)
        });
        return count.total || 0;
    }
    
    hasBackend() {
        return window.BACKEND_API_URL !== undefined;
    }
}
```

---

## 七、最終建議

### 🎯 **當前階段（比賽/展示期）**
**建議：保持純前端架構，不需要後端**

**原因**:
1. ✅ 現有39項指標全部在前端實作完成
2. ✅ 測試資料量適中（646人 × 8季度）
3. ✅ 展示時透明度高，評審可直接檢視運算邏輯
4. ✅ 部署成本為零（GitHub Pages免費）

### 🚀 **未來擴展（實際上線）**
**建議：採用混合架構**

1. **小型客戶** → 繼續使用前端運算
2. **中型客戶** → 提供後端API選項
3. **大型客戶** → 強制使用後端運算

---

## 八、行動計畫

| 時間 | 任務 | 說明 |
|------|------|------|
| **現在** | 維持前端架構 | 無需修改 |
| **1個月後** | 效能監測 | 記錄運算時間，找出瓶頸 |
| **3個月後** | 評估需求 | 根據實際使用情況決定 |
| **6個月後** | 開發後端（可選） | 如果需求明確才開始 |

---

## 九、總結

### 問題：JSON撈到資料後在哪運算（分子分母）？

**答案**：  
- ✅ **當前方案**: 在前端（瀏覽器JavaScript）運算，**不需要後端**
- ✅ **適用場景**: 測試、展示、小型醫院
- ⚠️ **未來考慮**: 當資料量 >5萬筆或需要批次計算時，再考慮後端

### 核心原則
> **能在前端做的，就不要建後端（Keep It Simple）**  
> **除非遇到效能瓶頸或特殊需求**

---

**文件版本**: v1.0  
**最後更新**: 2026-01-15  
**負責人**: GitHub Copilot
