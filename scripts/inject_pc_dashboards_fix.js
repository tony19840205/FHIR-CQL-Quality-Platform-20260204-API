// Fix #2: handle CRLF line endings + apply remaining 3 replacements
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');

const items = [
  ['1','基-1','門診注射劑使用率','medication','%'],
  ['2-1','基-2-1','門診抗生素使用率','medication','%'],
  ['2-2','基-2-2','門診Quinolone/Aminoglycoside抗生素使用率','medication','%'],
  ['3-1','基-3-1','同院降血壓藥重疊率','medication','%'],
  ['3-2','基-3-2','同院降血脂藥重疊率','medication','%'],
  ['3-3','基-3-3','同院降血糖藥重疊率','medication','%'],
  ['3-4','基-3-4','同院抗思覺失調藥重疊率','medication','%'],
  ['3-5','基-3-5','同院抗憂鬱藥重疊率','medication','%'],
  ['3-6','基-3-6','同院安眠鎮靜藥重疊率','medication','%'],
  ['3-7','基-3-7','同院抗血栓藥重疊率','medication','%'],
  ['3-8','基-3-8','同院前列腺藥重疊率','medication','%'],
  ['3-9','基-3-9','跨院降血壓藥重疊率','medication','%'],
  ['3-10','基-3-10','跨院降血脂藥重疊率','medication','%'],
  ['3-11','基-3-11','跨院降血糖藥重疊率','medication','%'],
  ['3-12','基-3-12','跨院抗思覺失調藥重疊率','medication','%'],
  ['3-13','基-3-13','跨院抗憂鬱藥重疊率','medication','%'],
  ['3-14','基-3-14','跨院安眠鎮靜藥重疊率','medication','%'],
  ['3-15','基-3-15','跨院抗血栓藥重疊率','medication','%'],
  ['3-16','基-3-16','跨院前列腺藥重疊率','medication','%'],
  ['4','基-4','慢性病連續處方箋開立率','outpatient','%'],
  ['5','基-5','門診10種以上藥品比率','outpatient','%'],
  ['6-1','基-6-1','糖尿病每張處方藥品日數','outpatient','日'],
  ['6-2','基-6-2','高血壓每張處方藥品日數','outpatient','日'],
  ['6-3','基-6-3','高血脂每張處方藥品日數','outpatient','日'],
  ['7','基-7','糖尿病HbA1c執行率','outcome','%'],
  ['8','基-8','同日同院再就診率','outpatient','%'],
  ['9-1','基-9-1','剖腹產率-整體','surgery','%'],
  ['9-2','基-9-2','剖腹產率-自行要求','surgery','%'],
  ['9-3','基-9-3','剖腹產率-具適應症','surgery','%'],
];
const rateIdOf = b => 'indPc' + b.replace(/-/g,'_') + 'Rate';
const idOf = b => 'indicator-pc-' + b;
const numberOf = b => '基' + b;
const NL = '\r\n';

// ---------- data-exporter.js (already has unit override; need defs + rateMap) ----------
const expPath = path.join(root, 'js', 'data-exporter.js');
let exp = fs.readFileSync(expPath, 'utf8');

if (!exp.includes("'indicator-pc-1':")) {
  // Insert defs
  const defLines = items.map(([b,code,title,cat]) =>
    `            { id: '${idOf(b)}', number: '${numberOf(b)}', name: '${title}', code: '${code}', category: '${cat}' },`
  ).join(NL);
  const defAnchor = "            { id: 'indicator-dental-20', number: '牙20', name: '身心障礙者牙科門診院所名單', code: '牙-20', category: 'outcome' },";
  if (!exp.includes(defAnchor)) throw new Error('def anchor not found');
  exp = exp.replace(defAnchor, defAnchor + NL + '            // ===== 西醫基層 (29) =====' + NL + defLines);

  // Insert rateMap entries
  const mapLines = items.map(([b]) =>
    `            '${idOf(b)}': '${rateIdOf(b)}',`
  ).join(NL);
  const mapAnchor = "            'indicator-dental-19': 'indDental19Rate', 'indicator-dental-20': 'indDental20Rate',";
  if (!exp.includes(mapAnchor)) throw new Error('map anchor not found');
  exp = exp.replace(mapAnchor, mapAnchor + NL + '            // ===== 西醫基層 =====' + NL + mapLines);

  fs.writeFileSync(expPath, exp, 'utf8');
  console.log('data-exporter.js: defs+rateMap injected.');
} else {
  console.log('data-exporter.js: already has PC entries, skipping.');
}

// ---------- realtime-dashboard - API.html ----------
const realPath = path.join(root, 'realtime-dashboard - API.html');
let real = fs.readFileSync(realPath, 'utf8');
if (!real.includes('"indicator-pc-1"')) {
  const embedLines = items.map(([b,code,title,cat,unit]) =>
    `    { id:"${idOf(b)}", number:"${numberOf(b)}", name:"${title}", code:"${code}", category:"${cat}", numerator:null, denominator:null, rate:null, unit:"${unit}" }`
  ).join(',' + NL);
  const dentalLast = `    { id:"indicator-dental-20", number:"牙20", name:"身心障礙者牙科門診院所名單", code:"牙-20", category:"outcome", numerator:null, denominator:null, rate:null, unit:"家" }`;
  if (!real.includes(dentalLast)) throw new Error('dental-20 anchor not found in realtime');
  real = real.replace(dentalLast, dentalLast + ',' + NL + '    // ===== 西醫基層 (29) =====' + NL + embedLines);
  // 67 -> 96 (if exists)
  real = real.split('67 項').join('96 項');
  fs.writeFileSync(realPath, real, 'utf8');
  console.log('realtime-dashboard updated.');
} else {
  console.log('realtime-dashboard already has PC entries, skipping.');
}

console.log('Done.');
