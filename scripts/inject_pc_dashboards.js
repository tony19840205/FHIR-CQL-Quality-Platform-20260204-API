// Add 29 PC entries to data-exporter.js + public-dashboard - API.html + realtime-dashboard - API.html
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');

// PC item list: [badge, code, title, category, unit]
const items = [
  ['1',    '基-1',    '門診注射劑使用率',                                        'medication', '%'],
  ['2-1',  '基-2-1',  '門診抗生素使用率',                                        'medication', '%'],
  ['2-2',  '基-2-2',  '門診Quinolone/Aminoglycoside抗生素使用率',                 'medication', '%'],
  ['3-1',  '基-3-1',  '同院降血壓藥重疊率',                                       'medication', '%'],
  ['3-2',  '基-3-2',  '同院降血脂藥重疊率',                                       'medication', '%'],
  ['3-3',  '基-3-3',  '同院降血糖藥重疊率',                                       'medication', '%'],
  ['3-4',  '基-3-4',  '同院抗思覺失調藥重疊率',                                    'medication', '%'],
  ['3-5',  '基-3-5',  '同院抗憂鬱藥重疊率',                                       'medication', '%'],
  ['3-6',  '基-3-6',  '同院安眠鎮靜藥重疊率',                                     'medication', '%'],
  ['3-7',  '基-3-7',  '同院抗血栓藥重疊率',                                       'medication', '%'],
  ['3-8',  '基-3-8',  '同院前列腺藥重疊率',                                       'medication', '%'],
  ['3-9',  '基-3-9',  '跨院降血壓藥重疊率',                                       'medication', '%'],
  ['3-10', '基-3-10', '跨院降血脂藥重疊率',                                       'medication', '%'],
  ['3-11', '基-3-11', '跨院降血糖藥重疊率',                                       'medication', '%'],
  ['3-12', '基-3-12', '跨院抗思覺失調藥重疊率',                                    'medication', '%'],
  ['3-13', '基-3-13', '跨院抗憂鬱藥重疊率',                                       'medication', '%'],
  ['3-14', '基-3-14', '跨院安眠鎮靜藥重疊率',                                     'medication', '%'],
  ['3-15', '基-3-15', '跨院抗血栓藥重疊率',                                       'medication', '%'],
  ['3-16', '基-3-16', '跨院前列腺藥重疊率',                                       'medication', '%'],
  ['4',    '基-4',    '慢性病連續處方箋開立率',                                   'outpatient', '%'],
  ['5',    '基-5',    '門診10種以上藥品比率',                                     'outpatient', '%'],
  ['6-1',  '基-6-1',  '糖尿病每張處方藥品日數',                                   'outpatient', '日'],
  ['6-2',  '基-6-2',  '高血壓每張處方藥品日數',                                   'outpatient', '日'],
  ['6-3',  '基-6-3',  '高血脂每張處方藥品日數',                                   'outpatient', '日'],
  ['7',    '基-7',    '糖尿病HbA1c執行率',                                        'outcome',    '%'],
  ['8',    '基-8',    '同日同院再就診率',                                          'outpatient', '%'],
  ['9-1',  '基-9-1',  '剖腹產率-整體',                                            'surgery',    '%'],
  ['9-2',  '基-9-2',  '剖腹產率-自行要求',                                        'surgery',    '%'],
  ['9-3',  '基-9-3',  '剖腹產率-具適應症',                                        'surgery',    '%'],
];

function rateIdOf(b) { return 'indPc' + b.replace(/-/g, '_') + 'Rate'; }
function idOf(b)     { return 'indicator-pc-' + b; }
function numberOf(b) { return '基' + b; }

// ---------- data-exporter.js ----------
const expPath = path.join(root, 'js', 'data-exporter.js');
let exp = fs.readFileSync(expPath, 'utf8');

const defLines = items.map(([b, code, title, cat]) =>
  `            { id: '${idOf(b)}', number: '${numberOf(b)}', name: '${title}', code: '${code}', category: '${cat}' },`
).join('\n');

exp = exp.replace(
  `            { id: 'indicator-dental-20', number: '牙20', name: '身心障礙者牙科門診院所名單', code: '牙-20', category: 'outcome' },\n        ];`,
  `            { id: 'indicator-dental-20', number: '牙20', name: '身心障礙者牙科門診院所名單', code: '牙-20', category: 'outcome' },\n            // ===== 西醫基層 (29) =====\n${defLines}\n        ];`
);

const mapLines = items.map(([b]) =>
  `            '${idOf(b)}': '${rateIdOf(b)}',`
).join('\n');

exp = exp.replace(
  `            'indicator-dental-19': 'indDental19Rate', 'indicator-dental-20': 'indDental20Rate',\n        };`,
  `            'indicator-dental-19': 'indDental19Rate', 'indicator-dental-20': 'indDental20Rate',\n            // ===== 西醫基層 =====\n${mapLines}\n        };`
);

// Add unit overrides: pc-6-1/2/3 = 日
exp = exp.replace(
  `            else if (['indicator-dental-7','indicator-dental-8','indicator-dental-10'].includes(def.id)) unit = '次';`,
  `            else if (['indicator-dental-7','indicator-dental-8','indicator-dental-10'].includes(def.id)) unit = '次';\n            else if (['indicator-pc-6-1','indicator-pc-6-2','indicator-pc-6-3'].includes(def.id)) unit = '日';`
);

fs.writeFileSync(expPath, exp, 'utf8');
console.log('data-exporter.js updated.');

// ---------- dashboards ----------
const embedLines = items.map(([b, code, title, cat, unit]) =>
  `    { id:"${idOf(b)}", number:"${numberOf(b)}", name:"${title}", code:"${code}", category:"${cat}", numerator:null, denominator:null, rate:null, unit:"${unit}" }`
).join(',\n');

function patchDashboard(file) {
  const p = path.join(root, file);
  let h = fs.readFileSync(p, 'utf8');
  // append PC entries before closing `]` of qualityIndicators
  // Pattern: dental-20 line then `\n  ],`
  h = h.replace(
    `    { id:"indicator-dental-20", number:"牙20", name:"身心障礙者牙科門診院所名單", code:"牙-20", category:"outcome", numerator:null, denominator:null, rate:null, unit:"家" }\n  ],`,
    `    { id:"indicator-dental-20", number:"牙20", name:"身心障礙者牙科門診院所名單", code:"牙-20", category:"outcome", numerator:null, denominator:null, rate:null, unit:"家" },\n    // ===== 西醫基層 (29) =====\n${embedLines}\n  ],`
  );
  // Update count 67 -> 96
  h = h.split('67 項').join('96 項');
  h = h.split('67 項指標').join('96 項指標');
  fs.writeFileSync(p, h, 'utf8');
  console.log(file + ' updated.');
}

patchDashboard('public-dashboard - API.html');
patchDashboard('realtime-dashboard - API.html');

console.log('All updates done.');
