/**
 * 數據匯出器 — 從控制台收集去識別化數據，匯出至民眾網頁
 * 
 * 策略一：POST 到本地後端 /api/export-public-data 存檔
 * 策略二：透過 GitHub API 直接推送到 public-health-dashboard repo
 * 策略三：降級為瀏覽器下載 JSON
 */

class DataExporter {
    constructor() {
        // 自動偵測後端 URL
        const host = window.location.hostname;
        if (host.includes('onrender.com')) {
            // 在 Render 上時，後端就是同一個 origin
            this.backendUrl = window.location.origin;
        } else if (host.includes('github.io')) {
            // 在 GitHub Pages 上時，打到 Render 後端
            this.backendUrl = 'https://fhir-cql-quality-platform-20260204.onrender.com';
        } else {
            this.backendUrl = 'http://localhost:3000';
        }
        // GitHub 設定
        this.githubOwner = 'tony19840205';
        this.githubRepo  = 'public-health-dashboard';
        this.githubPath  = 'public/data/dashboard-data.json';
        this.CACHE_KEY   = 'fhir_export_cache';

        // 自動快取：每 5 秒把當前頁面的 window.*Results 存入 localStorage
        this._startAutoCache();
    }

    // ──────────────────────────────────────────
    //  跨頁面 localStorage 快取
    // ──────────────────────────────────────────

    _startAutoCache() {
        const tick = () => this._cacheCurrentPageResults();
        setInterval(tick, 5000);
        window.addEventListener('beforeunload', tick);
    }

    /** 將當前頁面的 window.*Results 寫入 localStorage（僅非空時） */
    _cacheCurrentPageResults() {
        try {
            const cache = JSON.parse(localStorage.getItem(this.CACHE_KEY) || '{}');
            if (window.diseaseResults && Object.keys(window.diseaseResults).length > 0)
                cache.diseaseResults = JSON.parse(JSON.stringify(window.diseaseResults));
            if (window.qualityResults && Object.keys(window.qualityResults).length > 0)
                cache.qualityResults = JSON.parse(JSON.stringify(window.qualityResults));
            if (window.healthResults && Object.keys(window.healthResults).length > 0)
                cache.healthResults = JSON.parse(JSON.stringify(window.healthResults));
            if (window.esgResults && Object.keys(window.esgResults).length > 0)
                cache.esgResults = JSON.parse(JSON.stringify(window.esgResults));
            cache.lastCached = new Date().toISOString();
            localStorage.setItem(this.CACHE_KEY, JSON.stringify(cache));
        } catch (_) { /* quota exceeded — ignore */ }
    }

    /** 讀取快取 */
    _getCache() {
        try { return JSON.parse(localStorage.getItem(this.CACHE_KEY) || '{}'); }
        catch { return {}; }
    }

    /** 判斷陣列中是否有任何非 null 值 */
    _hasReal(items, field) {
        return Array.isArray(items) && items.some(i => i[field] != null);
    }

    /** 逐項目、逐欄位合併：current 非 null 優先，否則保留 prev 的值 */
    _mergeItems(current, prev, fields) {
        if (!Array.isArray(current)) return prev || [];
        if (!Array.isArray(prev)) return current;
        const prevMap = {};
        for (const p of prev) if (p.id) prevMap[p.id] = p;
        return current.map(item => {
            const old = prevMap[item.id];
            if (!old) return item;
            const merged = { ...item };
            for (const f of fields) {
                if (merged[f] == null && old[f] != null) merged[f] = old[f];
            }
            return merged;
        });
    }

    /**
     * 從當前頁面收集所有可用的去識別化數據，
     * 並與 localStorage 中其他頁面的歷史查詢結果合併。
     */
    collectData() {
        // 寫入最新的 window.*Results
        this._cacheCurrentPageResults();
        const cached = this._getCache();
        const lastExport = cached.lastExport || {};

        // 從當前頁面收集（window → DOM → null）
        const disease = this._collectDiseaseItems();
        const quality = this._collectAllQualityIndicators();
        const health  = this._collectHealthItems();
        const esg     = this._collectESGItems();

        // 合併：逐項目、逐欄位合併，保留各頁面查詢到的非 null 值
        const data = {
            exportedAt: new Date().toISOString(),
            source: window.location.pathname,
            diseaseItems:      this._mergeItems(disease, lastExport.diseaseItems, ['patients', 'encounters']),
            qualityIndicators: this._mergeItems(quality, lastExport.qualityIndicators, ['numerator', 'denominator', 'rate']),
            healthIndicators:  this._mergeItems(health, lastExport.healthIndicators, ['count', 'rate']),
            esgIndicators:     this._mergeItems(esg, lastExport.esgIndicators, ['count', 'rate']),
            stats: this._collectStats(),
        };

        // 儲存此次匯出結果供下次使用
        cached.lastExport = data;
        try { localStorage.setItem(this.CACHE_KEY, JSON.stringify(cached)); } catch (_) {}

        console.log('📦 已收集匯出數據（含跨頁快取）:', data);
        return data;
    }

    // ──────────────────────────────────────────
    //  疾病數據 — 輸出 DiseaseItem[] 格式
    // ──────────────────────────────────────────

    _collectDiseaseItems() {
        const dr = window.diseaseResults || {};
        const template = [
            { id: 'covid19', name: 'COVID-19', cql: 'InfectiousDisease_COVID19_Surveillance' },
            { id: 'influenza', name: '流感', cql: 'InfectiousDisease_Influenza_Surveillance' },
            { id: 'conjunctivitis', name: '急性結膜炎', cql: 'InfectiousDisease_AcuteConjunctivitis_Surveillance' },
            { id: 'enterovirus', name: '腸病毒', cql: 'InfectiousDisease_Enterovirus_Surveillance' },
            { id: 'diarrhea', name: '腹瀉群聚', cql: 'InfectiousDisease_AcuteDiarrhea_Surveillance' },
        ];

        return template.map(item => {
            const result = dr[item.id];
            let patients = null;
            let encounters = null;
            if (result) {
                // 從 conditions 計算唯一病患數
                if (result.conditions && result.conditions.length > 0) {
                    const patientSet = new Set();
                    for (const cond of result.conditions) {
                        const ref = (cond.resource || cond).subject?.reference;
                        if (ref) patientSet.add(ref);
                    }
                    patients = patientSet.size || result.conditions.length;
                }
                // 從 encounters 取就診數
                if (result.encounters && result.encounters.length > 0) {
                    encounters = result.encounters.length;
                    // 如果 conditions 沒有，從 encounters 補病患數
                    if (!patients) {
                        const patientSet = new Set();
                        for (const enc of result.encounters) {
                            const ref = (enc.resource || enc).subject?.reference;
                            if (ref) patientSet.add(ref);
                        }
                        patients = patientSet.size || encounters;
                    }
                }
                // 兜底：示範模式或其他欄位
                if (!patients) patients = result.total || result.totalPatients || null;
                if (!encounters) encounters = result.totalEncounters || null;
            }

            // DOM 降級：讀卡片數字
            const patientDomIds = { covid19: 'covidPatients', influenza: 'fluPatients', conjunctivitis: 'conjunctivitisPatients', enterovirus: 'enteroPatients', diarrhea: 'diarrheaPatients' };
            const encounterDomIds = { covid19: 'covidEncounters', influenza: 'fluEncounters', conjunctivitis: 'conjunctivitisEncounters', enterovirus: 'enteroEncounters', diarrhea: 'diarrheaEncounters' };
            if (patients === null) {
                const el = document.getElementById(patientDomIds[item.id]);
                if (el) { const v = parseInt(el.textContent, 10); if (!isNaN(v) && v > 0) patients = v; }
            }
            if (encounters === null) {
                const el = document.getElementById(encounterDomIds[item.id]);
                if (el) { const v = parseInt(el.textContent, 10); if (!isNaN(v) && v > 0) encounters = v; }
            }

            // 生成 13 縣市分佈數據
            const cityData = this._generateCityDistribution(patients);

            return { ...item, patients, encounters, cityData };
        });
    }

    /**
     * 將病患總數分配到 13 縣市（北部權重較高）
     * @param {number|null} total - 病患總數
     * @returns {Record<string, number>} 縣市→人數
     */
    _generateCityDistribution(total) {
        const cities = [
            { name: '台北市',  weight: 18 },
            { name: '新北市',  weight: 16 },
            { name: '桃園市',  weight: 10 },
            { name: '新竹市',  weight:  5 },
            { name: '基隆市',  weight:  3 },
            { name: '台中市',  weight: 14 },
            { name: '彰化縣',  weight:  5 },
            { name: '南投縣',  weight:  2 },
            { name: '台南市',  weight:  9 },
            { name: '高雄市',  weight: 10 },
            { name: '屏東縣',  weight:  3 },
            { name: '花蓮縣',  weight:  3 },
            { name: '台東縣',  weight:  2 },
        ];
        if (!total || total <= 0) {
            const result = {};
            cities.forEach(c => result[c.name] = 0);
            return result;
        }
        const totalWeight = cities.reduce((s, c) => s + c.weight, 0);
        const result = {};
        let assigned = 0;
        cities.forEach((c, i) => {
            if (i === cities.length - 1) {
                result[c.name] = total - assigned;
            } else {
                const share = Math.round(total * c.weight / totalWeight);
                result[c.name] = share;
                assigned += share;
            }
        });
        return result;
    }

    // ──────────────────────────────────────────
    //  國民健康 — 輸出 HealthIndicator[] 格式
    // ──────────────────────────────────────────

    _collectHealthItems() {
        const hr = window.healthResults || {};
        const template = [
            { id: 'covid19-vaccine', name: 'COVID-19 疫苗接種率', cql: 'COVID19VaccinationCoverage', description: '監測 COVID-19 疫苗接種涵蓋率與劑次完成度', countLabel: '接種人數', rateLabel: '接種率', rateUnit: '劑/人', domCount: 'covidVaccineCount', domRate: 'covidVaccineRate' },
            { id: 'influenza-vaccine', name: '流感疫苗接種率', cql: 'InfluenzaVaccinationCoverage', description: '追蹤季節性流感疫苗接種涵蓋率', countLabel: '接種人數', rateLabel: '接種率', rateUnit: '劑/人', domCount: 'fluVaccineCount', domRate: 'fluVaccineRate' },
            { id: 'hypertension', name: '高血壓活動個案數', cql: 'HypertensionActiveCases', description: '監測高血壓患者的管理與控制情況', countLabel: '活動個案', rateLabel: '控制率', rateUnit: '%', domCount: 'hypertensionCount', domRate: 'hypertensionRate' },
        ];

        return template.map(item => {
            let count = null, rate = null;

            // 優先從 window.healthResults 讀取
            const result = hr[item.id];
            if (result) {
                // count: uniquePatients (疫苗) / totalCases (高血壓)
                count = parseInt(result.count ?? result.uniquePatients ?? result.totalCases ?? result.vaccinatedCount, 10);
                if (isNaN(count)) count = null;
                // rate: averageDoses (疫苗) / controlRate (高血壓)
                const rv = parseFloat(result.rate ?? result.averageDoses ?? result.controlRate ?? result.avgDoses);
                if (!isNaN(rv)) rate = parseFloat(rv.toFixed(2));
            }

            // DOM 降級
            if (count === null) {
                const el = document.getElementById(item.domCount);
                if (el) { const v = parseInt(el.textContent, 10); if (!isNaN(v) && v > 0) count = v; }
            }
            if (rate === null) {
                const el = document.getElementById(item.domRate);
                if (el) { const v = parseFloat(el.textContent); if (!isNaN(v)) rate = v; }
            }

            return { id: item.id, name: item.name, cql: item.cql, description: item.description, count, rate, countLabel: item.countLabel, rateLabel: item.rateLabel, rateUnit: item.rateUnit };
        });
    }

    // ──────────────────────────────────────────
    //  品質指標 — 輸出全部 39 項 QualityIndicator[]
    // ──────────────────────────────────────────

    _collectAllQualityIndicators() {
        const qr = window.qualityResults || {};

        // 完整 39 項指標定義（與 mock-data.ts 一一對應）
        const defs = [
            { id: 'indicator-01', number: '01', name: '門診注射劑使用率', code: '3127', category: 'medication' },
            { id: 'indicator-02', number: '02', name: '門診抗生素使用率', code: '1140.01', category: 'medication' },
            { id: 'indicator-03-1', number: '03-1', name: '同院降血壓藥重疊', code: '1710', category: 'medication' },
            { id: 'indicator-03-2', number: '03-2', name: '同院降血脂藥重疊', code: '1711', category: 'medication' },
            { id: 'indicator-03-3', number: '03-3', name: '同院降血糖藥重疊', code: '1712', category: 'medication' },
            { id: 'indicator-03-4', number: '03-4', name: '同院抗思覺失調藥重疊', code: '1726', category: 'medication' },
            { id: 'indicator-03-5', number: '03-5', name: '同院抗憂鬱藥重疊', code: '1727', category: 'medication' },
            { id: 'indicator-03-6', number: '03-6', name: '同院安眠鎮靜藥重疊', code: '1728', category: 'medication' },
            { id: 'indicator-03-7', number: '03-7', name: '同院抗血栓藥重疊', code: '3375', category: 'medication' },
            { id: 'indicator-03-8', number: '03-8', name: '同院前列腺藥重疊', code: '3376', category: 'medication' },
            { id: 'indicator-03-9', number: '03-9', name: '跨院降血壓藥重疊', code: '1713', category: 'medication' },
            { id: 'indicator-03-10', number: '03-10', name: '跨院降血脂藥重疊', code: '1714', category: 'medication' },
            { id: 'indicator-03-11', number: '03-11', name: '跨院降血糖藥重疊', code: '1715', category: 'medication' },
            { id: 'indicator-03-12', number: '03-12', name: '跨院抗思覺失調藥重疊', code: '1729', category: 'medication' },
            { id: 'indicator-03-13', number: '03-13', name: '跨院抗憂鬱藥重疊', code: '1730', category: 'medication' },
            { id: 'indicator-03-14', number: '03-14', name: '跨院安眠鎮靜藥重疊', code: '1731', category: 'medication' },
            { id: 'indicator-04', number: '04', name: '慢性病連續處方箋使用率', code: '1318', category: 'outpatient' },
            { id: 'indicator-05', number: '05', name: '處方10種以上藥品率', code: '3128', category: 'outpatient' },
            { id: 'indicator-06', number: '06', name: '小兒氣喘急診率', code: '1315Q', category: 'outpatient' },
            { id: 'indicator-07', number: '07', name: '糖尿病HbA1c檢驗率', code: '109.01Q', category: 'outpatient' },
            { id: 'indicator-08', number: '08', name: '同日同院同疾病再就診率', code: '1322', category: 'outpatient' },
            { id: 'indicator-09', number: '09', name: '14天內非計畫再入院率', code: '1077.01Q', category: 'inpatient' },
            { id: 'indicator-10', number: '10', name: '出院後3天內急診率', code: '108.01', category: 'inpatient' },
            { id: 'indicator-11-1', number: '11-1', name: '整體剖腹產率', code: '1136.01', category: 'inpatient' },
            { id: 'indicator-11-2', number: '11-2', name: '產婦要求剖腹產率', code: '1137.01', category: 'inpatient' },
            { id: 'indicator-11-3', number: '11-3', name: '有適應症剖腹產率', code: '1138.01', category: 'inpatient' },
            { id: 'indicator-11-4', number: '11-4', name: '初產婦剖腹產率', code: '1075.01', category: 'inpatient' },
            { id: 'indicator-12', number: '12', name: '清淨手術抗生素超3天率', code: '1155', category: 'surgery' },
            { id: 'indicator-13', number: '13', name: '體外震波碎石平均利用次數', code: '20.01Q', category: 'surgery' },
            { id: 'indicator-14', number: '14', name: '子宮肌瘤術14天再入院率', code: '473.01', category: 'surgery' },
            { id: 'indicator-15-1', number: '15-1', name: '膝關節置換90天深部感染率', code: '353.01', category: 'surgery' },
            { id: 'indicator-15-2', number: '15-2', name: '全膝置換90天深部感染率', code: '3249', category: 'surgery' },
            { id: 'indicator-15-3', number: '15-3', name: '部分膝置換90天深部感染率', code: '3250', category: 'surgery' },
            { id: 'indicator-16', number: '16', name: '住院手術傷口感染率', code: '1658Q', category: 'surgery' },
            { id: 'indicator-19', number: '19', name: '清淨手術傷口感染率', code: '2524Q', category: 'surgery' },
            { id: 'indicator-17', number: '17', name: '急性心肌梗塞死亡率', code: '1662Q', category: 'outcome' },
            { id: 'indicator-18', number: '18', name: '失智症安寧療護利用率', code: '2795Q', category: 'outcome' },
        ];

        // DOM rate ID 對照（對應控制台 HTML 中的元素 ID）
        const domRateMap = {
            'indicator-01': 'ind01Rate', 'indicator-02': 'ind02Rate',
            'indicator-03-1': 'ind03_1Rate', 'indicator-03-2': 'ind03_2Rate',
            'indicator-03-3': 'ind03_3Rate', 'indicator-03-4': 'ind03_4Rate',
            'indicator-03-5': 'ind03_5Rate', 'indicator-03-6': 'ind03_6Rate',
            'indicator-03-7': 'ind03_7Rate', 'indicator-03-8': 'ind03_8Rate',
            'indicator-03-9': 'ind03_9Rate', 'indicator-03-10': 'ind03_10Rate',
            'indicator-03-11': 'ind03_11Rate', 'indicator-03-12': 'ind03_12Rate',
            'indicator-03-13': 'ind03_13Rate', 'indicator-03-14': 'ind03_14Rate',
            'indicator-04': 'ind04Rate', 'indicator-05': 'ind05Rate',
            'indicator-06': 'ind06Rate', 'indicator-07': 'ind07Rate',
            'indicator-08': 'ind08Rate', 'indicator-09': 'ind09Rate',
            'indicator-10': 'ind10Rate', 'indicator-11-1': 'ind11_1Rate',
            'indicator-11-2': 'ind11_2Rate', 'indicator-11-3': 'ind11_3Rate',
            'indicator-11-4': 'ind11_4Rate', 'indicator-12': 'ind12Rate',
            'indicator-13': 'ind13Rate', 'indicator-14': 'ind14Rate',
            'indicator-15-1': 'ind15_1Rate', 'indicator-15-2': 'ind15_2Rate',
            'indicator-15-3': 'ind15_3Rate', 'indicator-16': 'ind16Rate',
            'indicator-19': 'ind19Rate', 'indicator-17': 'ind17Rate',
            'indicator-18': 'ind18Rate',
        };
        const domNumMap = {
            'indicator-01': 'ind01Num', 'indicator-02': 'ind02Num',
        };
        const domDenMap = {
            'indicator-01': 'ind01Den', 'indicator-02': 'ind02Den',
        };

        return defs.map(def => {
            let numerator = null, denominator = null, rate = null;
            const unit = def.id === 'indicator-13' ? '次' : '%';

            // 優先從 window.qualityResults 讀取
            const result = qr[def.id];
            if (result) {
                if (result.numerator != null) numerator = parseInt(result.numerator, 10);
                if (result.denominator != null) denominator = parseInt(result.denominator, 10);
                // rate 可能直接存在，或從 quarterlyDetails 的當季取，或從 numerator/denominator 計算
                if (result.rate != null) {
                    rate = parseFloat(parseFloat(result.rate).toFixed(2));
                } else if (result.quarterlyDetails) {
                    const qKeys = Object.keys(result.quarterlyDetails);
                    if (qKeys.length > 0) {
                        const latest = result.quarterlyDetails[qKeys[qKeys.length - 1]];
                        if (latest && latest.rate != null) rate = parseFloat(parseFloat(latest.rate).toFixed(2));
                    }
                }
                if (rate === null && numerator != null && denominator != null && denominator > 0) {
                    rate = parseFloat((numerator / denominator * 100).toFixed(2));
                }
            }

            // DOM 降級：讀取頁面上的 rate 元素
            if (rate === null) {
                const rateEl = document.getElementById(domRateMap[def.id]);
                if (rateEl) {
                    const v = parseFloat(rateEl.textContent);
                    if (!isNaN(v)) rate = v;
                }
            }
            if (numerator === null) {
                const numEl = document.getElementById(domNumMap[def.id]);
                if (numEl) { const v = parseInt(numEl.textContent, 10); if (!isNaN(v)) numerator = v; }
            }
            if (denominator === null) {
                const denEl = document.getElementById(domDenMap[def.id]);
                if (denEl) { const v = parseInt(denEl.textContent, 10); if (!isNaN(v)) denominator = v; }
            }

            return { ...def, numerator, denominator, rate, unit };
        });
    }

    // ──────────────────────────────────────────
    //  ESG 指標 — 輸出 ESGIndicator[] 格式
    // ──────────────────────────────────────────

    _collectESGItems() {
        const cached = this._getCache();
        const er = (window.esgResults && Object.keys(window.esgResults).length > 0)
            ? window.esgResults
            : (cached.esgResults || {});
        const template = [
            { id: 'antibiotic', name: '抗生素使用率', cql: 'Antibiotic_Utilization', description: '監測抗生素合理使用與抗藥性管理 (國際算法)', countLabel: '病人數', rateLabel: '使用率', domId: 'antibioticRate', domCountId: 'antibioticCount', rateField: 'utilizationRate', countField: 'totalPatients' },
            { id: 'ehr', name: '電子病歷採用率', cql: 'EHR_Adoption_Rate', description: '追蹤病歷資料是否以結構化電子格式完整記錄', countLabel: '病人數', rateLabel: '採用率', domId: 'ehrRate', domCountId: 'ehrCount', rateField: 'adoptionRate', countField: 'ehrAdopted' },
            { id: 'waste', name: '醫療廢棄物管理', cql: 'Waste', description: '監測醫療廢棄物產生與處理情況', countLabel: '廢棄物量', rateLabel: '回收率', domId: 'wasteRate', domCountId: 'wasteCount', rateField: 'recycleRate', countField: 'totalWaste' },
        ];

        return template.map(item => {
            let count = null, rate = null;
            const unit = '%';

            // 從 window.esgResults 讀
            const result = er[item.id];
            if (result) {
                if (result[item.rateField] != null) rate = parseFloat(parseFloat(result[item.rateField]).toFixed(2));
                const cv = parseFloat(result[item.countField]);
                if (!isNaN(cv)) count = item.countField === 'totalWaste' ? cv : parseInt(cv, 10);
            }

            // DOM 降級
            if (rate === null) {
                const el = document.getElementById(item.domId);
                if (el) { const v = parseFloat(el.textContent); if (!isNaN(v)) rate = v; }
            }
            if (count === null) {
                const el = document.getElementById(item.domCountId);
                if (el) { const v = parseFloat(el.textContent); if (!isNaN(v)) count = v; }
            }

            return { id: item.id, name: item.name, cql: item.cql, description: item.description, count, rate, unit, countLabel: item.countLabel, rateLabel: item.rateLabel };
        });
    }

    // ──────────────────────────────────────────
    //  統計 & 公告
    // ──────────────────────────────────────────

    _collectStats() {
        const cache = this._getCache();
        const dr = window.diseaseResults || cache.diseaseResults || {};
        const qr = window.qualityResults || cache.qualityResults || {};
        const hr = window.healthResults  || cache.healthResults  || {};
        const er = window.esgResults     || cache.esgResults     || {};
        return {
            cqlModules: 50,
            qualityIndicators: 39,
            diseaseItems: 5,
            healthIndicators: 3,
            esgIndicators: 3,
            lastUpdated: new Date().toISOString(),
            queriedQuality: Object.keys(qr).length,
            queriedDisease: Object.keys(dr).length,
            queriedHealth: Object.keys(hr).length,
            queriedESG: Object.keys(er).length,
        };
    }

    /** 嘗試從 Chart.js 實例擷取數據 */
    _extractFromChartJS(chartId) {
        if (typeof Chart === 'undefined') return null;
        const instances = Object.values(Chart.instances || {});
        for (const chart of instances) {
            if (chart.canvas && chart.canvas.id === chartId) {
                const labels = chart.data.labels || [];
                const datasets = chart.data.datasets || [];
                return labels.map((label, i) => {
                    const row = { month: label };
                    datasets.forEach(ds => {
                        const key = (ds.label || '').toLowerCase().replace(/\s/g, '_');
                        row[key] = ds.data[i] || 0;
                    });
                    return row;
                });
            }
        }
        return null;
    }

    // ──────────────────────────────────────────
    //  匯出：後端 → GitHub API → 下載
    // ──────────────────────────────────────────

    async exportToPublicSite() {
        const data = this.collectData();

        // 策略一：POST 到後端（後端有 GITHUB_TOKEN 時會直接推送）
        try {
            const res = await fetch(`${this.backendUrl}/api/export-public-data`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data),
            });
            if (res.ok) {
                const result = await res.json();
                if (result.method === 'github-api' || result.method === 'local-file') {
                    console.log('✅ 數據已透過後端匯出:', result);
                    return { success: true, method: 'backend', ...result };
                }
            }
            // 501 = 後端沒有 GITHUB_TOKEN，繼續用瀏覽器端推送
        } catch (e) {
            console.warn('⚠️ 後端不可用，嘗試瀏覽器端 GitHub API...', e.message);
        }

        // 策略二：透過瀏覽器端 GitHub API 直接推送
        let githubToken = localStorage.getItem('githubToken');
        if (!githubToken) {
            githubToken = prompt(
                '首次匯出需要 GitHub Personal Access Token\n'
                + '（需 repo 權限，至 github.com → Settings → Developer settings → Personal access tokens 產生）\n\n'
                + '請貼上 Token (ghp_... 開頭)：'
            );
            if (githubToken && githubToken.trim()) {
                githubToken = githubToken.trim();
                localStorage.setItem('githubToken', githubToken);
            } else {
                return { success: false, method: 'cancelled', message: '使用者取消輸入 Token' };
            }
        }

        try {
            const pushed = await this._pushToGitHub(data, githubToken);
            if (pushed) return { success: true, method: 'github-api' };
        } catch (e) {
            console.warn('⚠️ GitHub API 推送失敗:', e.message);
            // Token 可能過期或無效，清除並提示重新輸入
            localStorage.removeItem('githubToken');
            alert('GitHub Token 無效或已過期，請重新操作並輸入有效的 Token');
            return { success: false, method: 'github-api-failed', message: e.message };
        }

        return { success: false, method: 'unknown' };
    }

    /** 透過 GitHub Contents API 推送 JSON */
    async _pushToGitHub(data, token) {
        const apiUrl = `https://api.github.com/repos/${this.githubOwner}/${this.githubRepo}/contents/${this.githubPath}`;
        const content = btoa(unescape(encodeURIComponent(JSON.stringify(data, null, 2))));

        // 先取得目前檔案的 SHA（如果已存在）
        let sha = null;
        try {
            const getRes = await fetch(apiUrl, {
                headers: { 'Authorization': `token ${token}`, 'Accept': 'application/vnd.github.v3+json' },
            });
            if (getRes.ok) {
                const existing = await getRes.json();
                sha = existing.sha;
            }
        } catch (_) { /* 檔案不存在 */ }

        const body = {
            message: `data: 控制台匯出去識別化數據 ${new Date().toISOString().slice(0, 16)}`,
            content,
            branch: 'main',
        };
        if (sha) body.sha = sha;

        const putRes = await fetch(apiUrl, {
            method: 'PUT',
            headers: {
                'Authorization': `token ${token}`,
                'Accept': 'application/vnd.github.v3+json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });

        if (!putRes.ok) {
            const err = await putRes.json();
            throw new Error(err.message || `GitHub API ${putRes.status}`);
        }

        console.log('✅ 已透過 GitHub API 推送至民眾網頁');
        return true;
    }

    /** 降級方案：瀏覽器下載 JSON */
    _downloadJSON(data) {
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `dashboard-data-${new Date().toISOString().slice(0, 10)}.json`;
        a.click();
        URL.revokeObjectURL(url);
        console.log('📥 已下載 JSON 檔案');
    }
}

// 全域實例
window.dataExporter = new DataExporter();
