/* ═══════════════════════════════════════════════════════════════════
 * Multi-Source Dashboard Data Aggregator
 * ═══════════════════════════════════════════════════════════════════
 * 支援將多個來源（FHIR API endpoint / 上傳的 JSON 檔）的 dashboard
 * data 物件合併為一份「加總後」的物件，供 public-dashboard 與
 * realtime-dashboard 顯示跨源加總統計。
 *
 * 來源資料結構（與 backend /api/export-dashboard 回傳一致）：
 *   {
 *     exportedAt: ISO string,
 *     diseaseItems:    [{ id,name, patients,encounters, cityData? }, ...],
 *     qualityIndicators:[{ id,number,name,code, numerator,denominator,rate,unit }, ...],
 *     healthIndicators:[{ id,name, count,target?, rate?, unit? }, ...],
 *     esgIndicators:   [{ id,name, count?,numerator?,denominator?,rate?,unit? }, ...]
 *   }
 *
 * 合併規則：
 *   - 數量類欄位 (patients/encounters/count/numerator/denominator) → 加總
 *   - rate 欄位 → 用合併後 numerator/denominator 重算（無則保留第一個非空值平均）
 *   - cityData → 同 city key 加總
 *
 * 全域 API：
 *   window.MultiSource.init(opts)            // 注入 UI 面板
 *   window.MultiSource.addServer(url, name)  // 新增 FHIR 伺服器來源
 *   window.MultiSource.addFile(file)         // 新增本機 JSON
 *   window.MultiSource.removeSource(id)
 *   window.MultiSource.list()                // 取得來源清單
 *   window.MultiSource.getAggregated()       // 取得合併資料
 *   window.MultiSource.onUpdate(cb)          // 訂閱合併資料變化
 *   window.MultiSource.toggleEnabled(bool)
 * ═══════════════════════════════════════════════════════════════════ */
(function (global) {
    'use strict';

    const STORAGE_KEY = 'fhir-multi-source-config-v1';
    const DEFAULT_BASE_NAME = '本機部署 (THAS)';

    /** @type {{ id:string, kind:'server'|'file'|'base', name:string, url?:string, data?:object, lastFetchAt?:number, error?:string }[]} */
    const sources = [];
    /** @type {object|null} 自動接收的「本機」資料（來自 dashboard loadData 結果） */
    let baseData = null;
    let enabled = false;
    const updateListeners = [];
    let panelEl = null;

    /* ─── Persistence ────────────────────────────────────────────── */
    function persist() {
        try {
            const ser = sources
                .filter(s => s.kind !== 'file') // 檔案不持久化（File 物件無法序列化）
                .map(s => ({ id: s.id, kind: s.kind, name: s.name, url: s.url }));
            localStorage.setItem(STORAGE_KEY, JSON.stringify({ enabled, sources: ser }));
        } catch (e) {}
    }
    function restore() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (!raw) return;
            const cfg = JSON.parse(raw);
            enabled = !!cfg.enabled;
            (cfg.sources || []).forEach(s => {
                if (s.kind === 'server' && s.url) {
                    sources.push({ id: s.id, kind: 'server', name: s.name, url: s.url });
                }
            });
        } catch (e) {}
    }

    /* ─── Aggregation Core ───────────────────────────────────────── */
    function _isNum(v) { return typeof v === 'number' && !Number.isNaN(v); }
    function _addNum(a, b) {
        if (_isNum(a) && _isNum(b)) return a + b;
        if (_isNum(a)) return a;
        if (_isNum(b)) return b;
        return null;
    }
    function _mergeArrayById(arrays, idField, mergeFn) {
        const map = new Map();
        arrays.forEach(arr => {
            (arr || []).forEach(item => {
                if (!item) return;
                const key = item[idField];
                if (key == null) return;
                if (!map.has(key)) {
                    map.set(key, JSON.parse(JSON.stringify(item)));
                } else {
                    mergeFn(map.get(key), item);
                }
            });
        });
        return Array.from(map.values());
    }
    function _mergeCityData(target, src) {
        if (!src) return target;
        if (!target) target = {};
        Object.keys(src).forEach(city => {
            const a = target[city]; const b = src[city];
            if (typeof a === 'object' && typeof b === 'object' && a && b) {
                target[city] = {
                    patients: _addNum(a.patients, b.patients),
                    encounters: _addNum(a.encounters, b.encounters)
                };
            } else if (_isNum(a) && _isNum(b)) {
                target[city] = a + b;
            } else if (b != null) {
                target[city] = b;
            }
        });
        return target;
    }
    function aggregate(dataList) {
        const valid = dataList.filter(Boolean);
        if (!valid.length) return null;

        const merged = {
            exportedAt: new Date().toISOString(),
            sourceCount: valid.length,
            sourceNames: [],
            diseaseItems: [],
            qualityIndicators: [],
            healthIndicators: [],
            esgIndicators: []
        };

        merged.diseaseItems = _mergeArrayById(
            valid.map(d => d.diseaseItems), 'id',
            (t, s) => {
                t.patients = _addNum(t.patients, s.patients);
                t.encounters = _addNum(t.encounters, s.encounters);
                t.cityData = _mergeCityData(t.cityData, s.cityData);
            }
        );

        merged.qualityIndicators = _mergeArrayById(
            valid.map(d => d.qualityIndicators), 'id',
            (t, s) => {
                t.numerator = _addNum(t.numerator, s.numerator);
                t.denominator = _addNum(t.denominator, s.denominator);
                if (_isNum(t.numerator) && _isNum(t.denominator) && t.denominator > 0) {
                    t.rate = +(t.numerator / t.denominator * 100).toFixed(2);
                }
            }
        );

        merged.healthIndicators = _mergeArrayById(
            valid.map(d => d.healthIndicators), 'id',
            (t, s) => {
                t.count = _addNum(t.count, s.count);
                t.target = _addNum(t.target, s.target);
                if (_isNum(t.count) && _isNum(t.target) && t.target > 0) {
                    t.rate = +(t.count / t.target * 100).toFixed(2);
                }
            }
        );

        merged.esgIndicators = _mergeArrayById(
            valid.map(d => d.esgIndicators), 'id',
            (t, s) => {
                t.count = _addNum(t.count, s.count);
                t.numerator = _addNum(t.numerator, s.numerator);
                t.denominator = _addNum(t.denominator, s.denominator);
                if (_isNum(t.numerator) && _isNum(t.denominator) && t.denominator > 0) {
                    t.rate = +(t.numerator / t.denominator * 100).toFixed(2);
                }
            }
        );

        return merged;
    }

    /* ─── Source Management ──────────────────────────────────────── */
    function _genId() { return 's_' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6); }

    async function _fetchServer(src) {
        try {
            // 嘗試對方 backend 的 /api/export-dashboard
            const apiUrl = src.url.replace(/\/+$/, '') + '/api/export-dashboard';
            const res = await fetch(apiUrl, { mode: 'cors' });
            if (!res.ok) throw new Error('HTTP ' + res.status);
            const json = await res.json();
            if (!json || !json.exportedAt) throw new Error('回傳資料缺少 exportedAt 欄位');
            src.data = json;
            src.lastFetchAt = Date.now();
            src.error = null;
        } catch (e) {
            src.error = e.message || String(e);
            src.data = null;
        }
    }

    async function addServer(url, name) {
        if (!url) throw new Error('URL 不可為空');
        if (sources.some(s => s.kind === 'server' && s.url === url)) return null;
        const src = {
            id: _genId(),
            kind: 'server',
            name: name || url.replace(/^https?:\/\//, '').replace(/\/.*$/, ''),
            url: url
        };
        sources.push(src);
        await _fetchServer(src);
        persist(); _emit(); _renderPanel();
        return src;
    }

    async function refreshAllServers() {
        await Promise.all(sources.filter(s => s.kind === 'server').map(_fetchServer));
        _emit(); _renderPanel();
    }

    async function addFile(file) {
        if (!file) throw new Error('檔案不可為空');
        const text = await file.text();
        let json;
        try { json = JSON.parse(text); } catch (e) { throw new Error('JSON 解析失敗：' + e.message); }
        if (!json || (!json.diseaseItems && !json.qualityIndicators && !json.healthIndicators && !json.esgIndicators)) {
            throw new Error('檔案內容不是 dashboard data 格式（需含 diseaseItems / qualityIndicators / healthIndicators / esgIndicators 之一）');
        }
        if (!json.exportedAt) json.exportedAt = new Date().toISOString();
        const src = {
            id: _genId(),
            kind: 'file',
            name: file.name,
            data: json,
            lastFetchAt: Date.now()
        };
        sources.push(src);
        persist(); _emit(); _renderPanel();
        return src;
    }

    function removeSource(id) {
        const idx = sources.findIndex(s => s.id === id);
        if (idx >= 0) {
            sources.splice(idx, 1);
            persist(); _emit(); _renderPanel();
        }
    }

    function setBaseData(d) {
        baseData = d;
        _emit(); _renderPanel();
    }

    function list() {
        const arr = sources.slice();
        if (baseData) arr.unshift({ id: 'base', kind: 'base', name: DEFAULT_BASE_NAME, data: baseData });
        return arr;
    }

    function getAggregated() {
        if (!enabled) return null;
        const datas = list().map(s => s.data).filter(Boolean);
        const agg = aggregate(datas);
        if (agg) agg.sourceNames = list().filter(s => s.data).map(s => s.name);
        return agg;
    }

    function toggleEnabled(v) {
        enabled = (typeof v === 'boolean') ? v : !enabled;
        persist(); _emit(); _renderPanel();
    }
    function isEnabled() { return enabled; }

    /* ─── Listeners ──────────────────────────────────────────────── */
    function onUpdate(cb) { if (typeof cb === 'function') updateListeners.push(cb); }
    function _emit() {
        const agg = getAggregated();
        updateListeners.forEach(cb => { try { cb(agg, list()); } catch (e) { console.warn(e); } });
    }

    /* ─── UI Panel ───────────────────────────────────────────────── */
    function _ensureStyles() {
        if (document.getElementById('multi-source-style')) return;
        const css = `
.ms-fab{position:fixed;right:20px;bottom:20px;z-index:9998;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;border:none;border-radius:50px;padding:12px 18px;font-size:14px;font-weight:700;cursor:pointer;box-shadow:0 6px 20px rgba(99,102,241,.4);display:flex;align-items:center;gap:8px;font-family:inherit;}
.ms-fab:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(99,102,241,.5);}
.ms-fab .ms-count{background:rgba(255,255,255,.25);border-radius:12px;padding:2px 8px;font-size:12px;}
.ms-panel{position:fixed;right:20px;bottom:80px;z-index:9999;width:380px;max-height:70vh;background:#fff;border-radius:14px;box-shadow:0 12px 40px rgba(0,0,0,.18);display:none;flex-direction:column;overflow:hidden;font-family:inherit;color:#1e293b;}
.ms-panel.open{display:flex;}
.ms-panel-h{padding:14px 16px;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;display:flex;align-items:center;justify-content:space-between;}
.ms-panel-h h4{margin:0;font-size:15px;font-weight:700;}
.ms-panel-h .ms-x{background:transparent;border:none;color:#fff;font-size:18px;cursor:pointer;}
.ms-panel-body{padding:14px 16px;overflow-y:auto;flex:1;}
.ms-toggle{display:flex;align-items:center;gap:10px;padding:10px 12px;background:#f1f5f9;border-radius:8px;margin-bottom:12px;}
.ms-toggle label{flex:1;font-weight:600;font-size:13px;color:#334155;cursor:pointer;}
.ms-switch{position:relative;width:42px;height:22px;background:#cbd5e1;border-radius:12px;cursor:pointer;transition:background .2s;}
.ms-switch.on{background:#10b981;}
.ms-switch::after{content:'';position:absolute;top:2px;left:2px;width:18px;height:18px;background:#fff;border-radius:50%;transition:left .2s;}
.ms-switch.on::after{left:22px;}
.ms-section-t{font-size:12px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin:14px 0 6px;}
.ms-src-item{display:flex;align-items:center;gap:8px;padding:8px 10px;background:#f8fafc;border-radius:8px;margin-bottom:6px;font-size:13px;border:1px solid #e2e8f0;}
.ms-src-item .ms-src-icon{width:24px;height:24px;border-radius:6px;display:flex;align-items:center;justify-content:center;font-size:11px;color:#fff;flex-shrink:0;}
.ms-src-item .ms-src-icon.base{background:#0ea5e9;}
.ms-src-item .ms-src-icon.server{background:#6366f1;}
.ms-src-item .ms-src-icon.file{background:#10b981;}
.ms-src-item .ms-src-name{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-weight:600;color:#1e293b;}
.ms-src-item .ms-src-meta{font-size:11px;color:#64748b;}
.ms-src-item .ms-src-rm{background:transparent;border:none;color:#ef4444;cursor:pointer;font-size:14px;padding:2px 6px;}
.ms-src-item.err{background:#fef2f2;border-color:#fecaca;}
.ms-src-item.err .ms-src-meta{color:#b91c1c;}
.ms-input-row{display:flex;gap:6px;margin-top:6px;}
.ms-input{flex:1;padding:8px 10px;border:1px solid #cbd5e1;border-radius:6px;font-size:12px;font-family:inherit;}
.ms-btn{padding:8px 12px;background:#6366f1;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:12px;font-weight:600;font-family:inherit;}
.ms-btn:hover{background:#4f46e5;}
.ms-btn.sec{background:#10b981;}
.ms-btn.sec:hover{background:#059669;}
.ms-stats{padding:10px 12px;background:linear-gradient(135deg,#eef2ff,#f5f3ff);border-radius:8px;margin-top:10px;}
.ms-stats .ms-st-row{display:flex;justify-content:space-between;font-size:12px;padding:3px 0;color:#475569;}
.ms-stats .ms-st-row b{color:#1e293b;}
.ms-banner{position:fixed;top:0;left:0;right:0;z-index:9997;background:linear-gradient(90deg,#6366f1,#8b5cf6);color:#fff;padding:8px 16px;font-size:13px;font-weight:600;text-align:center;display:none;box-shadow:0 2px 8px rgba(0,0,0,.1);}
.ms-banner.show{display:block;}
.ms-banner .ms-x-banner{background:rgba(255,255,255,.2);border:none;color:#fff;border-radius:50%;width:22px;height:22px;cursor:pointer;margin-left:10px;font-weight:700;}
`;
        const s = document.createElement('style'); s.id = 'multi-source-style'; s.textContent = css;
        document.head.appendChild(s);
    }

    function _renderPanel() {
        if (!panelEl) return;
        const items = list();
        const agg = enabled ? getAggregated() : null;
        const validCount = items.filter(s => s.data).length;

        const fab = document.querySelector('.ms-fab .ms-count');
        if (fab) fab.textContent = validCount + (enabled ? ' ON' : '');

        const banner = document.getElementById('msBanner');
        if (banner) {
            if (enabled && validCount > 1) {
                banner.classList.add('show');
                banner.querySelector('.ms-banner-text').textContent =
                    `🔗 多源加總模式：合併 ${validCount} 個來源（${items.filter(s=>s.data).map(s=>s.name).join('、')}）`;
            } else {
                banner.classList.remove('show');
            }
        }

        const body = panelEl.querySelector('.ms-panel-body');
        body.innerHTML = `
            <div class="ms-toggle">
                <label for="msEnable">啟用多源加總模式</label>
                <div id="msEnable" class="ms-switch ${enabled ? 'on' : ''}"></div>
            </div>

            <div class="ms-section-t">資料來源 (${items.length})</div>
            ${items.map(s => `
                <div class="ms-src-item ${s.error ? 'err' : ''}">
                    <div class="ms-src-icon ${s.kind}">
                        <i class="fas ${s.kind==='base'?'fa-home':s.kind==='server'?'fa-server':'fa-file'}"></i>
                    </div>
                    <div style="flex:1;min-width:0;">
                        <div class="ms-src-name" title="${s.url || s.name}">${s.name}</div>
                        <div class="ms-src-meta">
                            ${s.kind === 'base' ? '本機載入' : s.kind === 'server' ? (s.url || '') : '上傳檔案'}
                            ${s.lastFetchAt ? ' · ' + new Date(s.lastFetchAt).toLocaleTimeString() : ''}
                            ${s.error ? ' · ⚠ ' + s.error : ''}
                        </div>
                    </div>
                    ${s.kind !== 'base' ? `<button class="ms-src-rm" data-rm="${s.id}" title="移除"><i class="fas fa-times"></i></button>` : ''}
                </div>
            `).join('')}

            <div class="ms-section-t">+ 新增 FHIR 部署來源</div>
            <div class="ms-input-row">
                <input class="ms-input" id="msServerUrl" placeholder="https://other-platform.onrender.com" />
                <button class="ms-btn" id="msAddServer">加入</button>
            </div>
            <div style="font-size:11px;color:#94a3b8;margin-top:4px;">會嘗試呼叫對方的 <code>/api/export-dashboard</code></div>

            <div class="ms-section-t">+ 上傳本機 dashboard JSON</div>
            <div class="ms-input-row">
                <input class="ms-input" id="msFile" type="file" accept=".json,application/json" />
                <button class="ms-btn sec" id="msAddFile">加入</button>
            </div>

            ${agg ? `
                <div class="ms-section-t">加總結果</div>
                <div class="ms-stats">
                    <div class="ms-st-row"><span>來源數</span><b>${agg.sourceCount}</b></div>
                    <div class="ms-st-row"><span>傳染病項目</span><b>${(agg.diseaseItems||[]).length}</b></div>
                    <div class="ms-st-row"><span>品質指標</span><b>${(agg.qualityIndicators||[]).length}</b></div>
                    <div class="ms-st-row"><span>健康指標</span><b>${(agg.healthIndicators||[]).length}</b></div>
                    <div class="ms-st-row"><span>ESG 指標</span><b>${(agg.esgIndicators||[]).length}</b></div>
                    <div class="ms-st-row"><span>加總總病人數</span><b>${(agg.diseaseItems||[]).reduce((a,b)=>a+(b.patients||0),0).toLocaleString()}</b></div>
                </div>
            ` : ''}
        `;

        // Wire events
        body.querySelector('#msEnable').onclick = () => toggleEnabled();
        body.querySelectorAll('[data-rm]').forEach(btn => btn.onclick = () => removeSource(btn.dataset.rm));
        body.querySelector('#msAddServer').onclick = async () => {
            const url = body.querySelector('#msServerUrl').value.trim();
            if (!url) return;
            try { await addServer(url); body.querySelector('#msServerUrl').value=''; }
            catch (e) { alert('新增失敗：' + e.message); }
        };
        body.querySelector('#msAddFile').onclick = async () => {
            const f = body.querySelector('#msFile').files[0];
            if (!f) { alert('請先選擇檔案'); return; }
            try { await addFile(f); body.querySelector('#msFile').value=''; }
            catch (e) { alert('上傳失敗：' + e.message); }
        };
    }

    function init(opts) {
        opts = opts || {};
        _ensureStyles();
        restore();

        // Banner
        const banner = document.createElement('div');
        banner.className = 'ms-banner';
        banner.id = 'msBanner';
        banner.innerHTML = '<span class="ms-banner-text"></span><button class="ms-x-banner" title="關閉">×</button>';
        document.body.appendChild(banner);
        banner.querySelector('.ms-x-banner').onclick = () => toggleEnabled(false);

        // FAB
        const fab = document.createElement('button');
        fab.className = 'ms-fab';
        fab.innerHTML = '<i class="fas fa-layer-group"></i> 多源加總 <span class="ms-count">0</span>';
        fab.onclick = () => panelEl.classList.toggle('open');
        document.body.appendChild(fab);

        // Panel
        panelEl = document.createElement('div');
        panelEl.className = 'ms-panel';
        panelEl.innerHTML = `
            <div class="ms-panel-h">
                <h4><i class="fas fa-layer-group"></i> 多源資料加總</h4>
                <button class="ms-x">×</button>
            </div>
            <div class="ms-panel-body"></div>
        `;
        document.body.appendChild(panelEl);
        panelEl.querySelector('.ms-x').onclick = () => panelEl.classList.remove('open');

        _renderPanel();

        // Auto-refresh server sources
        if (sources.some(s => s.kind === 'server')) {
            refreshAllServers();
        }
    }

    global.MultiSource = {
        init: init,
        addServer: addServer,
        addFile: addFile,
        removeSource: removeSource,
        list: list,
        getAggregated: getAggregated,
        onUpdate: onUpdate,
        toggleEnabled: toggleEnabled,
        isEnabled: isEnabled,
        setBaseData: setBaseData,
        refreshAllServers: refreshAllServers,
        aggregate: aggregate
    };
})(window);
