// Inject 29 functional 西醫基層 cards into quality-indicators - API.html
const fs = require('fs');
const path = require('path');

const HTML = path.join(__dirname, '..', 'quality-indicators - API.html');
let html = fs.readFileSync(HTML, 'utf8');

// rateId helper: indicator-pc-3-10 -> indPc3_10Rate
function rateId(suffixDigits) {
  return 'indPc' + suffixDigits.replace(/-/g, '_') + 'Rate';
}
function suffixFor(suffixDigits) { return '_pc_' + suffixDigits.replace(/-/g, '_'); }

const items = {
  med: [
    ['1',    '門診注射劑使用率',                                              'Indicator_PC_01_Outpatient_Injection_Usage_Rate',                  '使用率'],
    ['2-1',  '門診抗生素使用率',                                              'Indicator_PC_02_1_Outpatient_Antibiotic_Usage_Rate',               '使用率'],
    ['2-2',  '門診Quinolone、Aminoglycoside類抗生素藥品使用率',               'Indicator_PC_02_2_Outpatient_Quinolone_Aminoglycoside_Usage_Rate', '使用率'],
    ['3-1',  '同院所門診同藥理用藥日數重疊率-降血壓(口服)',                  'Indicator_PC_03_1_Same_Hospital_Antihypertensive_Overlap',         '重疊率'],
    ['3-2',  '同院所門診同藥理用藥日數重疊率-降血脂(口服)',                  'Indicator_PC_03_2_Same_Hospital_Lipid_Lowering_Overlap',           '重疊率'],
    ['3-3',  '同院所門診同藥理用藥日數重疊率-降血糖',                          'Indicator_PC_03_3_Same_Hospital_Antidiabetic_Overlap',             '重疊率'],
    ['3-4',  '同院所門診同藥理用藥日數重疊率-抗思覺失調症',                    'Indicator_PC_03_4_Same_Hospital_Antipsychotic_Overlap',            '重疊率'],
    ['3-5',  '同院所門診同藥理用藥日數重疊率-抗憂鬱症',                        'Indicator_PC_03_5_Same_Hospital_Antidepressant_Overlap',           '重疊率'],
    ['3-6',  '同院所門診同藥理用藥日數重疊率-安眠鎮靜(口服)',                'Indicator_PC_03_6_Same_Hospital_Sedative_Overlap',                 '重疊率'],
    ['3-7',  '同院所門診同藥理用藥日數重疊率-抗血栓(口服)',                  'Indicator_PC_03_7_Same_Hospital_Antithrombotic_Overlap',           '重疊率'],
    ['3-8',  '同院所門診同藥理用藥日數重疊率-前列腺肥大(口服)',              'Indicator_PC_03_8_Same_Hospital_Prostate_Overlap',                 '重疊率'],
    ['3-9',  '跨院所門診同藥理用藥日數重疊率-降血壓(口服)',                  'Indicator_PC_03_9_Cross_Hospital_Antihypertensive_Overlap',        '重疊率'],
    ['3-10', '跨院所門診同藥理用藥日數重疊率-降血脂(口服)',                  'Indicator_PC_03_10_Cross_Hospital_Lipid_Lowering_Overlap',         '重疊率'],
    ['3-11', '跨院所門診同藥理用藥日數重疊率-降血糖',                          'Indicator_PC_03_11_Cross_Hospital_Antidiabetic_Overlap',           '重疊率'],
    ['3-12', '跨院所門診同藥理用藥日數重疊率-抗思覺失調症',                    'Indicator_PC_03_12_Cross_Hospital_Antipsychotic_Overlap',          '重疊率'],
    ['3-13', '跨院所門診同藥理用藥日數重疊率-抗憂鬱症',                        'Indicator_PC_03_13_Cross_Hospital_Antidepressant_Overlap',         '重疊率'],
    ['3-14', '跨院所門診同藥理用藥日數重疊率-安眠鎮靜(口服)',                'Indicator_PC_03_14_Cross_Hospital_Sedative_Overlap',               '重疊率'],
    ['3-15', '跨院所門診同藥理用藥日數重疊率-抗血栓(口服)',                  'Indicator_PC_03_15_Cross_Hospital_Antithrombotic_Overlap',         '重疊率'],
    ['3-16', '跨院所門診同藥理用藥日數重疊率-前列腺肥大(口服)',              'Indicator_PC_03_16_Cross_Hospital_Prostate_Overlap',               '重疊率'],
  ],
  out: [
    ['4',    '慢性病連續處方箋開立率',                          'Indicator_PC_04_Chronic_Continuous_Prescription_Rate',       '開立率'],
    ['5',    '門診多張處方箋開藥品項數大於等於十項之案件比率',     'Indicator_PC_05_Prescription_10_Plus_Drugs_Rate',            '比率'],
    ['6-1',  '門診平均每張慢性病處方箋開藥日數-糖尿病',           'Indicator_PC_06_1_Chronic_Prescription_Days_Diabetes',       '平均日數'],
    ['6-2',  '門診平均每張慢性病處方箋開藥日數-高血壓',           'Indicator_PC_06_2_Chronic_Prescription_Days_Hypertension',   '平均日數'],
    ['6-3',  '門診平均每張慢性病處方箋開藥日數-高血脂',           'Indicator_PC_06_3_Chronic_Prescription_Days_Hyperlipidemia', '平均日數'],
    ['8',    '就診後同日於同院所再次就診率',                      'Indicator_PC_08_Same_Day_Same_Hospital_Revisit_Rate',        '再就診率'],
  ],
  surg: [
    ['9-1',  '剖腹產率-整體',     'Indicator_PC_09_1_Cesarean_Section_Rate_Overall',           '剖腹產率'],
    ['9-2',  '剖腹產率-自行要求', 'Indicator_PC_09_2_Cesarean_Section_Rate_Patient_Requested', '剖腹產率'],
    ['9-3',  '剖腹產率-具適應症', 'Indicator_PC_09_3_Cesarean_Section_Rate_With_Indication',   '剖腹產率'],
  ],
  outcome: [
    ['7',    '糖尿病病人HbA1c執行率', 'Indicator_PC_07_Diabetes_HbA1c_Glycated_Albumin_Rate', '執行率'],
  ],
};

function unitFor(badge) {
  if (badge === '6-1' || badge === '6-2' || badge === '6-3') return '日';
  if (badge === '5') return '%';
  return '%';
}

function makeCard(badge, title, cql, metric, cardClass) {
  const id = 'indicator-pc-' + badge;
  const rid = rateId(badge);
  const sfx = suffixFor(badge);
  const initRate = '--' + unitFor(badge);
  return `                <div class="overview-card ${cardClass}" onclick="showDetailModal('${id}')">
                    <div class="card-badge">基${badge}</div>
                    <div class="card-content">
                        <h3>${title}</h3>
                        <p class="card-code">基-${badge}</p>
                        <p class="card-cql-file">${cql}</p>
                        <div class="card-mini-stats"><div class="mini-stat"><span class="mini-label">${metric}</span><span class="mini-value" id="${rid}">${initRate}</span></div></div>
                        <div class="card-query-options" onclick="event.stopPropagation()" style="margin-top:6px; display:flex; flex-wrap:wrap; gap:4px; font-size:11px;">
                            <input type="date" id="startDate${sfx}" style="padding:2px 4px; border:1px solid #e2e8f0; border-radius:4px; font-size:11px; width:120px;">
                            <input type="date" id="endDate${sfx}" style="padding:2px 4px; border:1px solid #e2e8f0; border-radius:4px; font-size:11px; width:120px;">
                            <select id="maxRecords${sfx}" style="padding:2px 4px; border:1px solid #e2e8f0; border-radius:4px; font-size:11px;"><option value="50">50筆</option><option value="100">100筆</option><option value="200" selected>200筆</option><option value="500">500筆</option><option value="1000">1000筆</option><option value="99999">不限制</option></select>
                        </div>
                        <button class="btn-card-mini" onclick="event.stopPropagation(); executeQuery('${id}')"><i class="fas fa-play"></i> 查詢</button>
                        <div class="card-status" id="status${sfx}" style="font-size:11px; margin-top:4px; min-height:16px;"></div>
                    </div>
                </div>`;
}

function makeSection(headerIcon, headerTitle, dataCategory, items, cardClass) {
  const cards = items.map(i => makeCard(i[0], i[1], i[2], i[3], cardClass)).join('\n');
  return `        <!-- ===================== ${headerTitle} - 官方 ELM 3.10.0 ===================== -->
        <section class="overview-section" data-category="${dataCategory}">
            <div class="section-header">
                <div><h2><i class="fas ${headerIcon}"></i> ${headerTitle}</h2></div>
                <button class="btn btn-primary" onclick="executeAllCategory('${dataCategory}')" style="margin-left:auto;"><i class="fas fa-play-circle"></i> 全部啟動</button>
            </div>
            <div class="overview-grid quality-grid">
${cards}
            </div>
        </section>`;
}

const newMed     = makeSection('fa-pills',         '用藥安全指標(西醫基層)', 'medication', items.med,     'quality-med');
const newOut     = makeSection('fa-hospital-user', '門診品質指標(西醫基層)', 'outpatient', items.out,     'quality-out');
const newSurg    = makeSection('fa-procedures',    '手術品質指標(西醫基層)', 'surgery',    items.surg,    'quality-surg');
const newOutcome = makeSection('fa-chart-line',    '結果品質指標(西醫基層)', 'outcome',    items.outcome, 'quality-outcome');

// Replace each existing PC section by anchored regex on the section comment + closing </section>
function replaceSection(html, marker, newSection) {
  const startMarker = `<!-- ===================== ${marker} ===================== -->`;
  const i = html.indexOf(startMarker);
  if (i < 0) throw new Error('Marker not found: ' + marker);
  // find </section> after this marker
  const endIdx = html.indexOf('</section>', i);
  if (endIdx < 0) throw new Error('No </section> after ' + marker);
  const replaceEnd = endIdx + '</section>'.length;
  // Locate start of indentation line for clean replace
  // Find start of the line containing the marker
  const lineStart = html.lastIndexOf('\n', i) + 1;
  return html.substring(0, lineStart) + newSection + html.substring(replaceEnd);
}

html = replaceSection(html, '用藥安全指標(西醫基層)', newMed);
html = replaceSection(html, '門診品質指標(西醫基層)', newOut);
html = replaceSection(html, '手術品質指標(西醫基層)', newSurg);
html = replaceSection(html, '結果品質指標(西醫基層)', newOutcome);

// Update filter counts
html = html.replace('全部 (103)', '全部 (132)');
html = html.replace('用藥安全 (37)', '用藥安全 (56)');
html = html.replace('門診品質 (22)', '門診品質 (28)');
html = html.replace('手術品質 (19)', '手術品質 (22)');
html = html.replace('結果品質 (20)', '結果品質 (21)');

// Bump cache
html = html.replace('quality-indicators-api.js?v=20260424dental', 'quality-indicators-api.js?v=20260424pc');

fs.writeFileSync(HTML, html, 'utf8');
console.log('Done.');
