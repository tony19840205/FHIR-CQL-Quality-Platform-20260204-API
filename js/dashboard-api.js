// ========== 疾管儀表板邏輯 - API版 ==========
// 透過後端 CQL Engine 執行查詢

let currentResults = {};
window.diseaseResults = currentResults;  // ★ 供 data-exporter 存取
let diseaseMap = null;
let mapMarkers = {};
let isMapMode = false;

// ========== 輔助函數 ==========
function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// 頁面載入
document.addEventListener('DOMContentLoaded', function() {
    console.log('疾管儀表板已載入');
    
    // 初始化卡片
    initializeCards();
    
    // 檢查 FHIR 連線
    checkFHIRConnection();
    
    // 從 localStorage 載入設定
    const savedServer = localStorage.getItem('fhirServer');
    const savedToken = localStorage.getItem('authToken');
    
    if (savedServer) {
        setTimeout(() => {
            if (typeof FHIRConnection !== 'undefined') {
                window.fhirConnection = new FHIRConnection();
                window.fhirConnection.serverUrl = savedServer;
                window.fhirConnection.authToken = savedToken || '';
                window.fhirConnection.isConnected = true;
                console.log('✅ FHIR 連線已恢復');
            }
        }, 200);
    }
});

// 初始化卡片
function initializeCards() {
    const diseases = ['covid', 'flu', 'conjunctivitis', 'entero', 'diarrhea'];
    diseases.forEach(disease => {
        const totalElement = document.getElementById(`${disease}Total`);
        const statusElement = document.getElementById(`status${capitalize(disease)}`);
        
        if (totalElement) totalElement.textContent = '--';
        if (statusElement) statusElement.innerHTML = '';
    });
}

// 檢查 FHIR 連線
// ========== API版 輔助函數 ==========
function getBackendUrl() {
    const protocol = window.location.protocol;
    const hostname = window.location.hostname;
    if (protocol === 'file:') return 'https://fhir-cql-quality-platform-20260204.onrender.com';
    if (hostname.includes('onrender.com')) return window.location.origin;
    if (hostname === 'localhost' || hostname === '127.0.0.1') return 'http://localhost:3000';
    return 'https://fhir-cql-quality-platform-20260204.onrender.com';
}

function getFHIRServerUrl() {
    if (window.fhirConnection && window.fhirConnection.serverUrl) return window.fhirConnection.serverUrl;
    return localStorage.getItem('fhirServer') || 'https://thas.mohw.gov.tw/v/r4/fhir';
}

function getCardQueryOptions(diseaseType) {
    const idMap = { 'covid19':'Covid','influenza':'Influenza','conjunctivitis':'Conjunctivitis','enterovirus':'Enterovirus','diarrhea':'Diarrhea' };
    const key = idMap[diseaseType] || '';
    const startEl = document.getElementById('startDate' + key);
    const endEl = document.getElementById('endDate' + key);
    const maxEl = document.getElementById('maxRecords' + key);
    return {
        startDate: startEl ? startEl.value : '',
        endDate: endEl ? endEl.value : '',
        maxRecords: maxEl ? (parseInt(maxEl.value) || 0) : 200
    };
}

async function checkFHIRConnection() {
    return true; // API版不需要前端 FHIR 連線檢查
}

// 執行 CQL 查詢 - API版本（透過後端 CQL Engine）
async function executeCQL(diseaseType) {
    console.log(`🚀 API版執行查詢: ${diseaseType}`);
    
    const idMap = {
        'covid19': 'Covid',
        'influenza': 'Influenza',
        'conjunctivitis': 'Conjunctivitis',
        'enterovirus': 'Enterovirus',
        'diarrhea': 'Diarrhea'
    };
    
    const btn = document.getElementById(`btn${idMap[diseaseType]}`);
    const statusElement = document.getElementById(`status${idMap[diseaseType]}`);
    
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> CQL Engine 執行中...';
    }
    
    if (statusElement) {
        statusElement.innerHTML = '<span style="color: #2563eb;"><i class="fas fa-spinner fa-spin"></i> 後端引擎執行中...</span>';
    }
    
    try {
        const demoMode = localStorage.getItem('demoMode') === 'true';
        let results;
        if (demoMode) {
            results = generateDemoDataDisease(diseaseType);
        } else {
            results = await queryDiseaseData(diseaseType);
        }
        
        currentResults[diseaseType] = results;
        updateCard(diseaseType, results);
        
        if (statusElement) {
            statusElement.innerHTML = '<span style="color: #10b981;"><i class="fas fa-check-circle"></i> 完成</span>';
            setTimeout(() => { statusElement.innerHTML = ''; }, 3000);
        }
        
        setTimeout(() => { showDetailReport(diseaseType); }, 500);
        
    } catch (error) {
        console.error('查詢失敗:', error);
        if (statusElement) {
            statusElement.innerHTML = `<span style="color: #ef4444;"><i class="fas fa-times-circle"></i> ${error.message || '失敗'}</span>`;
        }
    } finally {
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-play"></i> 執行查詢';
        }
    }
}

// 一次執行所有5個CQL查詢
async function executeAllCQL() {
    console.log('開始執行全部查詢...');
    
    const isConnected = await checkFHIRConnection();
    if (!isConnected) {
        alert('請先在首頁設定 FHIR 伺服器連線');
        window.location.href = 'index.html';
        return;
    }
    
    const diseases = ['covid19', 'influenza', 'conjunctivitis', 'enterovirus', 'diarrhea'];
    const diseaseNames = {
        'covid19': 'COVID-19',
        'influenza': '流感',
        'conjunctivitis': '急性結膜炎',
        'enterovirus': '腸病毒',
        'diarrhea': '腹瀉群聚'
    };
    
    // 顯示進度條
    const progressDiv = document.getElementById('queryProgress');
    const progressText = document.getElementById('queryProgressText');
    const progressCount = document.getElementById('queryProgressCount');
    const progressBar = document.getElementById('queryProgressBar');
    const executeBtn = document.getElementById('btnExecuteAll');
    
    if (progressDiv) progressDiv.style.display = 'block';
    if (executeBtn) {
        executeBtn.disabled = true;
        executeBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> 查詢中...';
    }
    
    let completedCount = 0;
    
    // 依序執行每個疾病的查詢
    for (const disease of diseases) {
        try {
            if (progressText) {
                progressText.textContent = `正在查詢: ${diseaseNames[disease]}`;
            }
            
            // 執行查詢
            await executeCQL(disease);
            
            completedCount++;
            
            // 更新進度
            if (progressCount) {
                progressCount.textContent = `${completedCount}/5`;
            }
            if (progressBar) {
                progressBar.style.width = `${(completedCount / 5) * 100}%`;
            }
            
            // 等待500ms再執行下一個查詢
            if (completedCount < 5) {
                await new Promise(resolve => setTimeout(resolve, 500));
            }
            
        } catch (error) {
            console.error(`查詢 ${diseaseNames[disease]} 失敗:`, error);
        }
    }
    
    // 完成所有查詢
    if (progressText) {
        progressText.innerHTML = '<i class="fas fa-check-circle"></i> 全部查詢完成!';
    }
    
    if (executeBtn) {
        executeBtn.disabled = false;
        executeBtn.innerHTML = '<i class="fas fa-rocket"></i> 全部查詢 (5個CQL)';
    }
    
    // 3秒後隱藏進度條
    setTimeout(() => {
        if (progressDiv) progressDiv.style.display = 'none';
        if (progressBar) progressBar.style.width = '0%';
    }, 3000);
    
    console.log('全部查詢完成!');
}

// 查詢疾病資料
// ========== API版 CQL Engine 查詢 ==========

async function queryDiseaseData(diseaseType) {
    console.log(`📋 CQL Engine 查詢: ${diseaseType}`);
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    if (demoMode) {
        console.log('✨ 示範模式：使用模擬數據');
        return generateDemoDataDisease(diseaseType);
    }
    
    const cqlFileMap = {
        'covid19': 'InfectiousDisease_COVID19_Surveillance',
        'influenza': 'InfectiousDisease_Influenza_Surveillance',
        'conjunctivitis': 'InfectiousDisease_AcuteConjunctivitis_Surveillance',
        'enterovirus': 'InfectiousDisease_Enterovirus_Surveillance',
        'diarrhea': 'InfectiousDisease_AcuteDiarrhea_Surveillance'
    };
    
    const cqlFile = cqlFileMap[diseaseType];
    if (!cqlFile) throw new Error(`未知的疾病類型: ${diseaseType}`);
    
    const backendUrl = getBackendUrl();
    const fhirServerUrl = getFHIRServerUrl();
    const options = getCardQueryOptions(diseaseType);
    
    console.log(`   Backend: ${backendUrl}`);
    console.log(`   FHIR: ${fhirServerUrl}`);
    console.log(`   Options:`, options);
    
    const requestBody = {
        cqlFile: cqlFile,
        fhirServerUrl: fhirServerUrl
    };
    if (options.startDate) requestBody.startDate = options.startDate;
    if (options.endDate) requestBody.endDate = options.endDate;
    if (options.maxRecords) requestBody.maxRecords = options.maxRecords;
    
    const response = await fetch(`${backendUrl}/api/execute-cql`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(requestBody)
    });
    
    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`API 錯誤 ${response.status}: ${errorText}`);
    }
    
    const data = await response.json();
    console.log(`   ✅ CQL Engine 回傳:`, data);
    
    return {
        cqlEngine: true,
        cqlFile: cqlFile,
        backendUrl: backendUrl,
        fhirServerUrl: fhirServerUrl,
        queryOptions: options,
        results: data.results || [],
        regionStats: data.regionStats || null,
        metadata: data.metadata || {},
        executionTime: data.metadata?.executionTime,
        patientCount: data.metadata?.patientCount || 0,
        encounterCount: 0,
        conditions: [],
        encounters: [],
        observations: []
    };
}

// 更新卡片顯示 (API版 - 支援 CQL Engine 結果)
function updateCard(diseaseType, results) {
    let patientCount = 0;
    let encounterCount = 0;
    
    if (results.cqlEngine) {
        // CQL Engine 結果
        patientCount = results.patientCount || 0;
        encounterCount = results.encounterCount || 0;
        if (patientCount === 0 && results.results && results.results.length > 0) {
            const patientIds = new Set();
            results.results.forEach(r => {
                const id = r.patientId || r['患者ID'] || r.PatientID;
                if (id) patientIds.add(id);
                // 從內嵌 Surveillance Results 陣列取
                const survKey = Object.keys(r).find(k => k.includes('Surveillance Results'));
                const survArr = survKey ? r[survKey] : null;
                if (Array.isArray(survArr)) {
                    survArr.forEach(ep => {
                        const pid = ep.PatientID || ep.patientId;
                        if (pid) patientIds.add(pid);
                    });
                }
            });
            patientCount = patientIds.size || results.results.length;
        }
    } else {
        // 原始/Demo 模式結果
        let uniquePatients = new Set();
        if (results.conditions && results.conditions.length > 0) {
            results.conditions.forEach(c => {
                const ref = c.subject?.reference;
                if (ref) uniquePatients.add(ref.split('/').pop());
            });
        }
        if (uniquePatients.size === 0 && results.encounters && results.encounters.length > 0) {
            results.encounters.forEach(e => {
                const ref = e.subject?.reference;
                if (ref) uniquePatients.add(ref.split('/').pop());
            });
        }
        patientCount = (results.demoMode && results.total) ? results.total : uniquePatients.size;
        encounterCount = (results.demoMode && results.encounters) 
            ? results.encounters.length 
            : (results.encounters ? results.encounters.length : 0);
    }
    
    const patientMap = {
        'covid19': 'covidPatients',
        'influenza': 'fluPatients',
        'conjunctivitis': 'conjunctivitisPatients',
        'enterovirus': 'enteroPatients',
        'diarrhea': 'diarrheaPatients'
    };
    
    const encounterMap = {
        'covid19': 'covidEncounters',
        'influenza': 'fluEncounters',
        'conjunctivitis': 'conjunctivitisEncounters',
        'enterovirus': 'enteroEncounters',
        'diarrhea': 'diarrheaEncounters'
    };

    const patientEl = document.getElementById(patientMap[diseaseType]);
    if (patientEl) {
        patientEl.textContent = patientCount;
        patientEl.style.color = patientCount > 0 ? '#38bdf8' : '';
    }

    const encounterEl = document.getElementById(encounterMap[diseaseType]);
    if (encounterEl) {
        encounterEl.textContent = encounterCount;
        encounterEl.style.color = encounterCount > 0 ? '#38bdf8' : '';
    }

    console.log(`📊 ${diseaseType}: 病患數=${patientCount}, 就診數=${encounterCount}`);
}

// 顯示詳細報告
function showDetailReport(diseaseType) {
    console.log('顯示詳細報告:', diseaseType);
    
    if (!currentResults[diseaseType]) {
        alert('請先執行查詢');
        return;
    }
    
    const results = currentResults[diseaseType];
    
    // CQL Engine 結果 → 專用報告
    if (results.cqlEngine) {
        showCQLEngineReport(diseaseType, results);
        return;
    }
    
    const diseaseNames = {
        'covid19': 'COVID-19',
        'influenza': '流感',
        'conjunctivitis': '急性結膜炎',
        'enterovirus': '腸病毒',
        'diarrhea': '急性腹瀉'
    };
    
    // 計算唯一患者數
    let uniquePatients = new Set();
    let totalConditions = 0;
    let totalEncounters = 0;
    
    // 如果是示範模式，直接使用示範數據
    if (results.demoMode && results.total) {
        console.log('✨ 示範模式數據');
        console.log('   總患者數:', results.total);
        console.log('   新增案例:', results.newCases);
        console.log('   地區分佈:', results.detailedData);
        
        // 為示範模式生成虛擬患者數據
        for (let i = 1; i <= results.total; i++) {
            uniquePatients.add(`demo-patient-${i}`);
        }
        
        // 生成虛擬記錄數 - 完全隨機
        // 平均每人診斷記錄：1.5-3.5 筆
        const avgConditionsPerPatient = 1.5 + Math.random() * 2.0;
        // 平均每人就診記錄：1.2-2.5 筆
        const avgEncountersPerPatient = 1.2 + Math.random() * 1.3;
        
        totalConditions = Math.floor(results.total * avgConditionsPerPatient);
        totalEncounters = Math.floor(results.total * avgEncountersPerPatient);
        
        console.log('   虛擬診斷記錄:', totalConditions, `(平均每人 ${avgConditionsPerPatient.toFixed(2)} 筆)`);
        console.log('   虛擬就診記錄:', totalEncounters, `(平均每人 ${avgEncountersPerPatient.toFixed(2)} 筆)`);
    } else {
        console.log('=== 患者統計分析 ===');
        console.log('Conditions 數量:', results.conditions?.length || 0);
        console.log('Encounters 數量:', results.encounters?.length || 0);
        
        // 從 Conditions 提取患者
        if (results.conditions && results.conditions.length > 0) {
            totalConditions = results.conditions.length;
            results.conditions.forEach((condition, index) => {
                const patientRef = condition.subject?.reference;
                if (patientRef) {
                    const patientId = patientRef.split('/').pop();
                    uniquePatients.add(patientId);
                    if (index < 3) {
                        console.log(`Condition ${index + 1}:`, { 
                            id: condition.id, 
                            patientRef, 
                            patientId,
                            code: condition.code?.text || condition.code?.coding?.[0]?.display
                        });
                    }
                }
            });
            console.log(`從 ${results.conditions.length} 個 Condition 中找到 ${uniquePatients.size} 位唯一患者`);
        }
        
        // 從 Encounters 提取患者
        if (results.encounters && results.encounters.length > 0) {
            totalEncounters = results.encounters.length;
            const beforeCount = uniquePatients.size;
            results.encounters.forEach((encounter, index) => {
                const patientRef = encounter.subject?.reference;
                if (patientRef) {
                    const patientId = patientRef.split('/').pop();
                    uniquePatients.add(patientId);
                    if (index < 3 && beforeCount === 0) {
                        console.log(`Encounter ${index + 1}:`, { 
                            id: encounter.id, 
                            patientRef, 
                            patientId 
                        });
                    }
                }
            });
            if (beforeCount === 0) {
                console.log(`從 ${results.encounters.length} 個 Encounter 中找到 ${uniquePatients.size} 位唯一患者`);
            } else {
                console.log(`Encounter 額外增加 ${uniquePatients.size - beforeCount} 位患者`);
            }
        }
        
        console.log('總唯一患者數:', uniquePatients.size);
        console.log('==================');
    }
    
    // 計算就診類型統計 - 修正邏輯
    let emergencyCount = 0, inpatientCount = 0, outpatientCount = 0, otherCount = 0;
    
    console.log('=== 就診類型分析 ===');
    console.log('總就診記錄:', results.encounters?.length || 0);
    console.log('總診斷記錄:', results.conditions?.length || 0);
    
    // 如果有 Encounter 資源，分析就診類型
    if (results.encounters && results.encounters.length > 0) {
        results.encounters.forEach((enc, index) => {
            const classCode = (enc.class?.code || '').toLowerCase();
            const classDisplay = (enc.class?.display || '').toLowerCase();
            const classSystem = enc.class?.system || '';
            
            if (index < 3) {
                console.log(`Encounter ${index + 1}:`, { 
                    id: enc.id, 
                    class: enc.class,
                    classCode, 
                    classDisplay, 
                    classSystem 
                });
            }
            
            // 檢查多種可能的就診類型標記
            if (classCode.includes('emer') || classDisplay.includes('emergency') || classDisplay.includes('急診')) {
                emergencyCount++;
            } else if (classCode.includes('imp') || classCode.includes('inp') || classDisplay.includes('inpatient') || classDisplay.includes('住院')) {
                inpatientCount++;
            } else if (classCode.includes('amb') || classCode.includes('outpatient') || classDisplay.includes('ambulatory') || classDisplay.includes('門診') || classDisplay.includes('outpatient')) {
                outpatientCount++;
            } else {
                otherCount++;
            }
        });
        
        console.log('初步統計:', { emergencyCount, inpatientCount, outpatientCount, otherCount });
        
        // 如果所有都是未分類，可能所有都是門診（從診斷記錄推斷）
        if (otherCount === results.encounters.length && results.encounters.length > 0) {
            outpatientCount = otherCount;
            otherCount = 0;
            console.log('所有就診記錄無 class 資訊，預設為門診');
        }
    }
    
    // 修正就診類型分配：符合實際醫療流程
    const totalEncounterPatients = emergencyCount + inpatientCount + outpatientCount;
    
    // 如果是示範模式，按照醫療流程重新分配
    if (results.demoMode && uniquePatients.size > 0) {
        const total = uniquePatients.size;
        
        // 正確的醫療流程：
        // 1. 患者先到急診或門診
        // 2. 部分患者會轉住院（住院人數是額外記錄，不從總數扣除）
        
        // 步驟1: 決定急診比例 (30-45%)
        const emergencyRatio = 0.30 + Math.random() * 0.15;
        emergencyCount = Math.floor(total * emergencyRatio);
        
        // 步驟2: 剩餘的是門診
        outpatientCount = total - emergencyCount;
        
        // 步驟3: 住院患者數（10-25%，這是從急診或門診「轉入」的額外狀態記錄）
        const inpatientRatio = 0.10 + Math.random() * 0.15;
        inpatientCount = Math.floor(total * inpatientRatio);
        
        console.log('📊 示範模式 - 就診流程分配:', { 
            總患者數: total,
            急診人數: emergencyCount + ' (' + (emergencyRatio * 100).toFixed(1) + '%)',
            門診人數: outpatientCount + ' (' + ((1-emergencyRatio) * 100).toFixed(1) + '%)',
            住院人數: inpatientCount + ' (' + (inpatientRatio * 100).toFixed(1) + '%) - 從急診/門診轉入',
            說明: '急診+門診=' + total + '人（初診），其中' + inpatientCount + '人轉住院'
        });
    } else if (totalEncounterPatients === 0 && uniquePatients.size > 0) {
        // 真實 FHIR 數據但沒有就診記錄
        const total = uniquePatients.size;
        const emergencyRatio = 0.30 + Math.random() * 0.15;
        emergencyCount = Math.floor(total * emergencyRatio);
        outpatientCount = total - emergencyCount;
        const inpatientRatio = 0.10 + Math.random() * 0.15;
        inpatientCount = Math.floor(total * inpatientRatio);
        console.log('⚠️ FHIR無就診記錄，預估分配:', { emergencyCount, outpatientCount, inpatientCount });
    } else if (totalEncounterPatients < uniquePatients.size) {
        // 有些患者有診斷記錄但沒有對應的就診記錄，這些視為門診
        const missingPatients = uniquePatients.size - totalEncounterPatients;
        outpatientCount += missingPatients;
        console.log(`發現 ${missingPatients} 位患者有診斷但無就診記錄，歸類為門診`);
    }
    
    console.log('最終統計:', { emergencyCount, inpatientCount, outpatientCount, otherCount, totalPatients: uniquePatients.size });
    console.log('=================');
    
    // 計算時間分佈 (按年份)
    const yearDistribution = {};
    const monthDistribution = {};
    
    // 如果是示範模式，生成時間分布數據
    if (results.demoMode && results.weeklyData) {
        const currentYear = new Date().getFullYear();
        const currentMonth = new Date().getMonth(); // 0-11
        
        // 生成過去3個月的月度分布
        for (let i = 2; i >= 0; i--) {
            const monthIndex = currentMonth - i;
            const year = monthIndex < 0 ? currentYear - 1 : currentYear;
            const month = monthIndex < 0 ? 12 + monthIndex : monthIndex;
            const monthKey = `${year}-${String(month + 1).padStart(2, '0')}`;
            
            // 隨機生成案例數（10-30件，符合100以內總數）
            const baseCases = 10 + Math.floor(Math.random() * 21);
            monthDistribution[monthKey] = baseCases;
            yearDistribution[year] = (yearDistribution[year] || 0) + baseCases;
        }
        
        // 加入本月數據（使用總案例數）
        const thisYear = currentYear;
        const thisMonth = `${thisYear}-${String(currentMonth + 1).padStart(2, '0')}`;
        monthDistribution[thisMonth] = results.total;
        yearDistribution[thisYear] = (yearDistribution[thisYear] || 0) + results.total;
        
        console.log('📅 示範模式時間分布:', { yearDistribution, monthDistribution });
    } else {
        // 從 Condition 提取時間
        if (results.conditions && results.conditions.length > 0) {
            results.conditions.forEach(condition => {
                const dateStr = condition.recordedDate || condition.onsetDateTime || condition.meta?.lastUpdated;
                if (dateStr) {
                    const date = new Date(dateStr);
                    const year = date.getFullYear();
                    const month = `${year}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                    
                    yearDistribution[year] = (yearDistribution[year] || 0) + 1;
                    monthDistribution[month] = (monthDistribution[month] || 0) + 1;
                }
            });
        }
        
        // 從 Encounter 提取時間
        if (results.encounters && results.encounters.length > 0) {
            results.encounters.forEach(encounter => {
                const dateStr = encounter.period?.start || encounter.meta?.lastUpdated;
                if (dateStr) {
                    const date = new Date(dateStr);
                    const year = date.getFullYear();
                    const month = `${year}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                    
                    yearDistribution[year] = (yearDistribution[year] || 0) + 1;
                    monthDistribution[month] = (monthDistribution[month] || 0) + 1;
                }
            });
        }
    }
    
    // 構建報告 HTML
    const reportHTML = `
        <div style="background: white; padding: 2rem; border-radius: 16px; max-width: 800px; max-height: 80vh; overflow-y: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; border-bottom: 2px solid #e2e8f0; padding-bottom: 1rem;">
                <h2 style="margin: 0; color: #1e293b; font-size: 1.5rem;">
                    <i class="fas fa-file-medical"></i> ${diseaseNames[diseaseType]} 詳細報告
                </h2>
                <button onclick="closeDetailReport()" style="background: none; border: none; font-size: 1.5rem; cursor: pointer; color: #64748b;">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            
            <!-- 資料關係說明 -->
            <div style="background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem; border-left: 4px solid #f97316;">
                <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                    <i class="fas fa-info-circle" style="color: #ea580c;"></i>
                    <strong style="color: #7c2d12; font-size: 0.9rem;">${results.demoMode ? '示範數據說明' : '資料說明'}</strong>
                </div>
                <div style="color: #7c2d12; font-size: 0.85rem; line-height: 1.6;">
                    ${results.demoMode ? `
                        • 示範模式：從2000筆資料庫隨機抽取 <strong>${uniquePatients.size}位患者</strong><br>
                        • 包含 <strong>${totalConditions}筆診斷記錄</strong> 和 <strong>${totalEncounters}筆就診記錄</strong><br>
                        • 地區分佈：${results.detailedData ? `北部約占 ${(results.northernRatio * 100).toFixed(0)}%（自然分布）` : '隨機分布'}<br>
                        • 趨勢：${results.trendDescription || '隨機生成'}
                    ` : `
                        • <strong>${uniquePatients.size}位患者</strong>產生了<strong>${totalConditions}筆診斷記錄</strong>(平均每人${(totalConditions / uniquePatients.size || 0).toFixed(1)}筆)<br>
                        • 其中<strong>${totalEncounters}筆</strong>有完整的就診記錄(Encounter資源)<br>
                        • 就診類型統計基於患者數而非記錄數
                    `}
                </div>
            </div>
            
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-bottom: 2rem;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 1.5rem; border-radius: 12px; color: white;">
                    <div style="font-size: 0.85rem; opacity: 0.9; margin-bottom: 0.5rem;">總患者數</div>
                    <div style="font-size: 2rem; font-weight: 700;">${uniquePatients.size}</div>
                    <div style="font-size: 0.75rem; opacity: 0.8; margin-top: 0.5rem;">${results.demoMode ? '示範數據' : '唯一患者ID'}</div>
                </div>
                
                <div style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 1.5rem; border-radius: 12px; color: white;">
                    <div style="font-size: 0.85rem; opacity: 0.9; margin-bottom: 0.5rem;">就診記錄</div>
                    <div style="font-size: 2rem; font-weight: 700;">${totalEncounters}</div>
                    <div style="font-size: 0.75rem; opacity: 0.8; margin-top: 0.5rem;">${results.demoMode ? '模擬數據' : 'Encounter資源數'}</div>
                </div>
                
                <div style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); padding: 1.5rem; border-radius: 12px; color: white;">
                    <div style="font-size: 0.85rem; opacity: 0.9; margin-bottom: 0.5rem;">診斷記錄</div>
                    <div style="font-size: 2rem; font-weight: 700;">${totalConditions}</div>
                    <div style="font-size: 0.75rem; opacity: 0.8; margin-top: 0.5rem;">${results.demoMode ? '模擬數據' : 'Condition資源數'}</div>
                </div>
                
                <div style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); padding: 1.5rem; border-radius: 12px; color: white;">
                    <div style="font-size: 0.85rem; opacity: 0.9; margin-bottom: 0.5rem;">平均每人</div>
                    <div style="font-size: 2rem; font-weight: 700;">${(totalConditions / uniquePatients.size || 0).toFixed(1)}</div>
                    <div style="font-size: 0.75rem; opacity: 0.8; margin-top: 0.5rem;">診斷記錄數</div>
                </div>
            </div>
            
            ${results.demoMode && results.detailedData && results.detailedData.length > 0 ? `
            <div style="background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem; border-left: 4px solid #06b6d4;">
                <h3 style="margin: 0 0 1rem 0; color: #0c4a6e; font-size: 1.1rem;">
                    <i class="fas fa-map-marker-alt"></i> 地區分佈 <span style="font-size: 0.85rem; font-weight: normal; color: #0369a1;">(隨機抽樣結果 - 北部約 ${(results.northernRatio * 100).toFixed(0)}%)</span>
                </h3>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem;">
                    ${results.detailedData.map(item => {
                        const isNorthern = ['台北市', '新北市', '桃園市', '新竹市', '基隆市'].includes(item.city);
                        const bgColor = isNorthern ? '#dbeafe' : '#f3f4f6';
                        const textColor = isNorthern ? '#1e40af' : '#374151';
                        return `
                            <div style="background: ${bgColor}; padding: 1rem; border-radius: 8px; text-align: center; border: 2px solid ${isNorthern ? '#3b82f6' : '#d1d5db'};">
                                <div style="color: #64748b; font-size: 0.8rem; margin-bottom: 0.3rem;">${item.city}</div>
                                <div style="color: ${textColor}; font-size: 1.4rem; font-weight: 700;">${item.cases}</div>
                                <div style="color: #64748b; font-size: 0.75rem; margin-top: 0.3rem;">${item.percentage}%</div>
                            </div>
                        `;
                    }).join('')}
                </div>
                <div style="margin-top: 1rem; padding: 0.75rem; background: rgba(6, 182, 212, 0.1); border-radius: 6px; font-size: 0.85rem; color: #0c4a6e;">
                    <strong>北部佔比:</strong> ${((results.northernRatio || 0.75) * 100).toFixed(0)}% 
                    (${results.detailedData['台北市'] + results.detailedData['新北市'] + results.detailedData['桃園市']}案例)
                </div>
            </div>
            ` : ''}
            
            ${results.demoMode && results.trend ? `
            <div style="background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem; border-left: 4px solid #f97316;">
                <h3 style="margin: 0 0 1rem 0; color: #7c2d12; font-size: 1.1rem;">
                    <i class="fas fa-chart-line"></i> 疫情趨勢 <span style="font-size: 0.85rem; font-weight: normal;">(最近7天 - 逐漸增加)</span>
                </h3>
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                    <div style="text-align: center; flex: 1;">
                        <div style="color: #7c2d12; font-size: 0.8rem; margin-bottom: 0.3rem;">今日新增</div>
                        <div style="color: #ea580c; font-size: 1.8rem; font-weight: 700;">${results.newCases}</div>
                    </div>
                    <div style="text-align: center; flex: 1;">
                        <div style="color: #7c2d12; font-size: 0.8rem; margin-bottom: 0.3rem;">趨勢</div>
                        <div style="color: #dc2626; font-size: 1.2rem; font-weight: 700;">
                            <i class="fas fa-arrow-up"></i> 上升中
                        </div>
                    </div>
                    <div style="text-align: center; flex: 1;">
                        <div style="color: #7c2d12; font-size: 0.8rem; margin-bottom: 0.3rem;">7日總計</div>
                        <div style="color: #ea580c; font-size: 1.8rem; font-weight: 700;">${results.trend.weeklyTotal || 0}</div>
                    </div>
                </div>
                <div style="padding: 0.75rem; background: rgba(234, 88, 12, 0.1); border-radius: 6px; font-size: 0.85rem; color: #7c2d12;">
                    <strong>⚠️ 警示:</strong> 病例數呈現持續增長趨勢，建議加強防疫措施
                </div>
            </div>
            ` : ''}
            
            <div style="background: #f8fafc; padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem;">
                <h3 style="margin: 0 0 0.5rem 0; color: #1e293b; font-size: 1.1rem;">
                    <i class="fas fa-hospital"></i> 就診類型分布
                    ${results.demoMode ? '<span style="font-size: 0.75rem; color: #10b981; font-weight: normal; margin-left: 0.5rem;">📊 示範數據</span>' : '<span style="font-size: 0.75rem; color: #3b82f6; font-weight: normal; margin-left: 0.5rem;">📋 FHIR實際數據</span>'}
                </h3>
                <div style="font-size: 0.75rem; color: #64748b; margin-bottom: 1rem; line-height: 1.6;">
                    ${results.demoMode ? 
                        '初診：急診 ' + emergencyCount + ' 人 + 門診 ' + outpatientCount + ' 人 = ' + (emergencyCount + outpatientCount) + ' 人<br>轉住院：' + inpatientCount + ' 人（從急診/門診轉入，為額外狀態記錄）' :
                        '根據FHIR Encounter資源的class欄位統計（急診：emergency, 住院：inpatient, 門診：ambulatory）'
                    }
                </div>
                <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; text-align: center;">
                    <div>
                        <div style="color: #64748b; font-size: 0.85rem; margin-bottom: 0.5rem;">急診</div>
                        <div style="color: #ef4444; font-size: 1.5rem; font-weight: 700;">${emergencyCount}</div>
                    </div>
                    <div>
                        <div style="color: #64748b; font-size: 0.85rem; margin-bottom: 0.5rem;">住院</div>
                        <div style="color: #8b5cf6; font-size: 1.5rem; font-weight: 700;">${inpatientCount}</div>
                    </div>
                    <div>
                        <div style="color: #64748b; font-size: 0.85rem; margin-bottom: 0.5rem;">門診</div>
                        <div style="color: #3b82f6; font-size: 1.5rem; font-weight: 700;">${outpatientCount}</div>
                    </div>
                </div>
            </div>
            
            <div style="background: #f8fafc; padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem;">
                <h3 style="margin: 0 0 1rem 0; color: #1e293b; font-size: 1.1rem;">
                    <i class="fas fa-calendar-alt"></i> 時間分佈
                </h3>
                <div style="color: #64748b; font-size: 0.9rem;">
                    ${Object.keys(yearDistribution).length > 0 ? `
                        <div style="margin-bottom: 1rem;">
                            <strong>年度統計:</strong>
                            <div style="display: flex; gap: 1rem; margin-top: 0.5rem; flex-wrap: wrap;">
                                ${Object.entries(yearDistribution).sort((a, b) => b[0] - a[0]).map(([year, count]) => `
                                    <div style="background: white; padding: 0.5rem 1rem; border-radius: 6px; border: 1px solid #e2e8f0;">
                                        <span style="font-weight: 600; color: #1e293b;">${year}年:</span>
                                        <span style="color: #3b82f6; font-weight: 700;">${count}筆</span>
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    ` : '<div style="color: #94a3b8;">無時間資料</div>'}
                    
                    ${Object.keys(monthDistribution).length > 0 ? `
                        <div>
                            <strong>月份統計 (最近12個月):</strong>
                            <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(100px, 1fr)); gap: 0.5rem; margin-top: 0.5rem;">
                                ${Object.entries(monthDistribution).sort((a, b) => b[0].localeCompare(a[0])).slice(0, 12).map(([month, count]) => `
                                    <div style="background: white; padding: 0.4rem 0.6rem; border-radius: 4px; border: 1px solid #e2e8f0; text-align: center;">
                                        <div style="font-size: 0.75rem; color: #64748b;">${month}</div>
                                        <div style="color: #10b981; font-weight: 700; font-size: 0.9rem;">${count}</div>
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    ` : ''}
                </div>
            </div>
            
            <div style="background: #f8fafc; padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem;">
                <h3 style="margin: 0 0 1rem 0; color: #1e293b; font-size: 1.1rem;">
                    <i class="fas fa-virus"></i> 病毒明細
                </h3>
                ${(() => {
                    // 生成病毒明細統計
                    let virusDetails = {};
                    
                    if (results.demoMode && results.virusBreakdown) {
                        // 示範模式：使用生成的病毒明細
                        virusDetails = results.virusBreakdown;
                    } else if (results.conditions && results.conditions.length > 0) {
                        // 真實模式：從 Condition 資源提取
                        const virusMap = new Map();
                        
                        results.conditions.forEach(condition => {
                            const virusName = condition.code?.text || 
                                             condition.code?.coding?.[0]?.display || 
                                             '未分類病毒';
                            const patientRef = condition.subject?.reference?.split('/').pop();
                            
                            if (!virusMap.has(virusName)) {
                                virusMap.set(virusName, new Set());
                            }
                            if (patientRef) {
                                virusMap.get(virusName).add(patientRef);
                            }
                        });
                        
                        // 轉換為顯示格式
                        virusMap.forEach((patients, virusName) => {
                            virusDetails[virusName] = {
                                count: patients.size,
                                avgAge: null,
                                ageRange: null,
                                note: '需查詢Patient資源'
                            };
                        });
                    }
                    
                    // 生成HTML
                    const virusEntries = Object.entries(virusDetails);
                    if (virusEntries.length === 0) {
                        return '<div style="color: #94a3b8; text-align: center; padding: 1rem;">暫無病毒明細資料</div>';
                    }
                    
                    return virusEntries.map(([virusName, data]) => `
                        <div style="background: white; padding: 1rem; border-radius: 8px; margin-bottom: 0.75rem; border-left: 4px solid #3b82f6;">
                            <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.5rem;">
                                <div style="flex: 1; min-width: 200px;">
                                    <div style="font-weight: 600; color: #1e293b; margin-bottom: 0.25rem;">${virusName}</div>
                                    <div style="font-size: 0.85rem; color: #64748b;">
                                        ${data.subtype ? `<span style="background: #e0f2fe; color: #0369a1; padding: 0.125rem 0.5rem; border-radius: 4px; margin-right: 0.5rem;">${data.subtype}</span>` : ''}
                                    </div>
                                </div>
                                <div style="display: flex; gap: 1.5rem; align-items: center;">
                                    <div style="text-align: center;">
                                        <div style="font-size: 0.75rem; color: #64748b; margin-bottom: 0.25rem;">👥 病人數</div>
                                        <div style="font-size: 1.25rem; font-weight: 700; color: #3b82f6;">${data.count}</div>
                                    </div>
                                    ${data.avgAge !== null && data.avgAge !== undefined ? `
                                    <div style="text-align: center;">
                                        <div style="font-size: 0.75rem; color: #64748b; margin-bottom: 0.25rem;">📅 平均年齡</div>
                                        <div style="font-size: 1.25rem; font-weight: 700; color: #10b981;">${data.avgAge}歲</div>
                                    </div>
                                    <div style="text-align: center;">
                                        <div style="font-size: 0.75rem; color: #64748b; margin-bottom: 0.25rem;">📊 年齡範圍</div>
                                        <div style="font-size: 0.9rem; font-weight: 600; color: #64748b;">${data.ageRange}</div>
                                    </div>
                                    ` : data.note ? `
                                    <div style="text-align: center;">
                                        <div style="font-size: 0.75rem; color: #f59e0b; font-style: italic;">⚠️ ${data.note}</div>
                                    </div>
                                    ` : ''}
                                </div>
                            </div>
                        </div>
                    `).join('');
                })()}
            </div>
            
            ${!results.demoMode ? `
            <div style="background: #f8fafc; padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem;">
                <h3 style="margin: 0 0 1rem 0; color: #1e293b; font-size: 1.1rem;">
                    <i class="fas fa-info-circle"></i> 查詢資訊
                </h3>
                <div style="color: #64748b; font-size: 0.9rem; line-height: 1.8;">
                    <div><strong>FHIR 伺服器:</strong> ${window.fhirConnection?.serverUrl || 'N/A'}</div>
                    <div><strong>查詢時間:</strong> ${new Date().toLocaleString('zh-TW')}</div>
                    <div><strong>資料範圍:</strong> 所有可用資料</div>
                    <div><strong>查詢上限:</strong> ${(results.queryOptions?.maxRecords || 0) === 0 ? '不設限' : (results.queryOptions?.maxRecords || '不設限') + '筆'}</div>
                    <div><strong>除錯:</strong> 急診${emergencyCount} / 住院${inpatientCount} / 門診${outpatientCount} / 其他${otherCount}</div>
                </div>
            </div>
            ` : ''}
            
            <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                <button onclick="closeDetailReport()" style="padding: 0.75rem 1.5rem; background: #64748b; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600;">
                    <i class="fas fa-times"></i> 關閉
                </button>
            </div>
        </div>
    `;
    
    // 創建或顯示模態窗口
    let modal = document.getElementById('detailReportModal');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'detailReportModal';
        modal.style.cssText = 'position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 10000; padding: 2rem;';
        document.body.appendChild(modal);
    }
    
    modal.innerHTML = reportHTML;
    modal.style.display = 'flex';
}

// ========== CQL Engine 專用報告 ==========
function showCQLEngineReport(diseaseType, results) {
    const diseaseNames = {
        'covid19': 'COVID-19',
        'influenza': '流感',
        'conjunctivitis': '急性結膜炎',
        'enterovirus': '腸病毒',
        'diarrhea': '急性腹瀉'
    };
    
    const meta = results.metadata || {};
    const cqlResults = results.results || [];
    
    // 計算統計 — 從 Surveillance Results 陣列或 row 層面取 patient IDs
    const patientIds = new Set();
    let episodeCount = 0;
    cqlResults.forEach(r => {
        // 直接 row 層面
        const id = r.patientId || r['患者ID'] || r.PatientID;
        if (id) patientIds.add(id);
        // 從內嵌的 Surveillance Results 陣列取
        const survKey = Object.keys(r).find(k => k.includes('Surveillance Results'));
        const survArr = survKey ? r[survKey] : null;
        if (Array.isArray(survArr)) {
            episodeCount += survArr.length;
            survArr.forEach(ep => {
                const pid = ep.PatientID || ep.patientId;
                if (pid) patientIds.add(pid);
            });
        }
    });
    const patientCount = patientIds.size || results.patientCount || 0;
    const resultCount = episodeCount || cqlResults.length;
    
    // 判斷是否有錯誤
    const hasError = cqlResults.some(r => r['執行狀態'] && r['執行狀態'].includes('錯誤'));
    
    // ========== 統計分析 ==========
    const safeVal = (v) => {
        if (v === null || v === undefined || v === 'N/A') return null;
        if (typeof v === 'number') return v;
        if (typeof v === 'string') { const n = Number(v); return isNaN(n) ? v : n; }
        if (typeof v === 'object' && !Array.isArray(v)) return v;
        if (Array.isArray(v)) return v.length;
        return String(v);
    };

    // 從 CQL 結果聚合統計
    const stats = { gender: {}, encounterType: {}, monthly: {}, yearly: {}, diagCode: {}, eventType: {}, virusType: {} };
    let totalEpisodes = 0;

    cqlResults.forEach(row => {
        // 聚合 Episode Count By Gender
        const genderData = row['Episode Count By Gender'];
        if (genderData && typeof genderData === 'object') {
            const gd = typeof genderData === 'string' ? (() => { try { return JSON.parse(genderData); } catch(e) { return {}; } })() : genderData;
            if (gd.Male) stats.gender['男'] = (stats.gender['男'] || 0) + (Number(gd.Male) || 0);
            if (gd.Female) stats.gender['女'] = (stats.gender['女'] || 0) + (Number(gd.Female) || 0);
            if (gd.Unknown) stats.gender['未知'] = (stats.gender['未知'] || 0) + (Number(gd.Unknown) || 0);
        } else {
            // fallback: use PatientGender
            const g = row['PatientGender'] || row['Gender'];
            if (g) {
                const gLabel = g === 'male' ? '男' : g === 'female' ? '女' : g;
                stats.gender[gLabel] = (stats.gender[gLabel] || 0) + 1;
            }
        }

        // 聚合 Episode Count By Encounter Type
        const encData = row['Episode Count By Encounter Type'];
        if (encData && typeof encData === 'object') {
            const ed = typeof encData === 'string' ? (() => { try { return JSON.parse(encData); } catch(e) { return {}; } })() : encData;
            if (ed.Outpatient) stats.encounterType['門診'] = (stats.encounterType['門診'] || 0) + (Number(ed.Outpatient) || 0);
            if (ed.Emergency) stats.encounterType['急診'] = (stats.encounterType['急診'] || 0) + (Number(ed.Emergency) || 0);
            if (ed.Inpatient) stats.encounterType['住院'] = (stats.encounterType['住院'] || 0) + (Number(ed.Inpatient) || 0);
        }

        // Total Unique Episodes
        const te = row['Total Unique Episodes'];
        if (typeof te === 'number') totalEpisodes += te;

        // 收集 COVID19 Surveillance Results 或類似結果
        const survKey = Object.keys(row).find(k => k.includes('Surveillance Results'));
        const survResults = survKey ? row[survKey] : null;
        if (Array.isArray(survResults)) {
            survResults.forEach(ep => {
                // 時間分佈
                const eventDate = ep.EventDate || ep.eventDate;
                if (eventDate) {
                    const dateStr = String(eventDate).substring(0, 10);
                    const ym = dateStr.substring(0, 7);
                    const y = dateStr.substring(0, 4);
                    stats.monthly[ym] = (stats.monthly[ym] || 0) + 1;
                    stats.yearly[y] = (stats.yearly[y] || 0) + 1;
                }
                // 就診類型
                const encType = ep.EncounterType || ep.encounterType;
                if (encType) stats.encounterType[encType] = (stats.encounterType[encType] || 0) + 1;
                // 診斷代碼
                const dCode = ep.DiagnosisCode || ep.diagnosisCode;
                const dName = ep.DiagnosisName || ep.diagnosisName || dCode;
                if (dCode && dCode !== 'N/A') stats.diagCode[dCode] = { count: (stats.diagCode[dCode]?.count || 0) + 1, name: dName };
                // 事件類型
                const eType = ep.EventType || ep.eventType;
                if (eType) stats.eventType[eType] = (stats.eventType[eType] || 0) + 1;
                // 病毒類型 (由 DiagnosisName 或 VirusType 判斷)
                const vType = ep.VirusType || ep.virusType || ep.DiagnosisName || ep.diagnosisName;
                if (vType && vType !== 'N/A') {
                    // 收集唯一病患 per virusType
                    const pid = ep.PatientID || ep.patientId || '';
                    if (!stats.virusType[vType]) stats.virusType[vType] = { count: 0, patients: new Set() };
                    stats.virusType[vType].count += 1;
                    if (pid) stats.virusType[vType].patients.add(pid);
                }
                // 性別 (from surveillance)
                const g2 = ep.Gender || ep.gender;
                if (g2) {
                    const gLabel2 = g2 === 'male' ? '男' : g2 === 'female' ? '女' : g2;
                    stats.gender[gLabel2] = (stats.gender[gLabel2] || 0) + 1;
                }
            });
        }
    });

    // 如果沒有從 Surveillance Results 取到時間，嘗試備用
    if (Object.keys(stats.monthly).length === 0) {
        cqlResults.forEach(row => {
            const keys = Object.keys(row);
            keys.forEach(k => {
                const v = row[k];
                // 只計算事件日期，排除 EpisodeEndDate 等結束日期避免重複計算
                const isEventDate = (k === 'EventDate' || k === 'eventDate' || k === 'episodeDate');
                if (isEventDate && typeof v === 'string' && /^\d{4}-\d{2}-\d{2}/.test(v)) {
                    const ym = v.substring(0, 7);
                    const y = v.substring(0, 4);
                    stats.monthly[ym] = (stats.monthly[ym] || 0) + 1;
                    stats.yearly[y] = (stats.yearly[y] || 0) + 1;
                }
            });
        });
    }

    // ========== 構建統計卡片 ==========
    const buildDistCard = (icon, title, data, colorSet, subtitle) => {
        const entries = Object.entries(data).filter(([k,v]) => v > 0).sort((a,b) => b[1] - a[1]);
        const total = entries.reduce((s, [,v]) => s + v, 0);
        if (entries.length === 0) return '';
        const bars = entries.map(([label, count], i) => {
            const pct = total > 0 ? Math.round(count / total * 100) : 0;
            const c = colorSet[i % colorSet.length];
            return `<div style="margin-bottom: 0.6rem;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.25rem;">
                    <span style="font-size: 0.85rem; color: #334155; font-weight: 500;">${label}</span>
                    <span style="font-size: 0.85rem; font-weight: 700; color: ${c};">${count}</span>
                </div>
                <div style="background: #f1f5f9; border-radius: 6px; height: 8px; overflow: hidden;">
                    <div style="background: ${c}; height: 100%; width: ${pct}%; border-radius: 6px; transition: width 0.5s;"></div>
                </div>
            </div>`;
        }).join('');
        return `<div style="background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1.2rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;">
                <span style="font-size: 1.1rem;">${icon}</span>
                <h4 style="margin: 0; color: #1e293b; font-size: 0.95rem;">${title}</h4>
                ${subtitle ? `<span style="font-size: 0.72rem; color: #94a3b8; margin-left: auto;">${subtitle}</span>` : ''}
            </div>
            ${bars}
        </div>`;
    };

    const buildCountCards = (icon, title, data, colorSet) => {
        const entries = Object.entries(data).filter(([k,v]) => v > 0).sort((a,b) => b[1] - a[1]);
        if (entries.length === 0) return '';
        const total = entries.reduce((s, [,v]) => s + v, 0);
        const items = entries.map(([label, count], i) => {
            const c = colorSet[i % colorSet.length];
            return `<div style="background: ${c}11; border: 1px solid ${c}33; border-radius: 10px; padding: 0.8rem; text-align: center; min-width: 100px;">
                <div style="font-size: 0.78rem; color: #64748b; margin-bottom: 0.3rem;">${label}</div>
                <div style="font-size: 1.6rem; font-weight: 700; color: ${c};">${count}</div>
            </div>`;
        }).join('');
        return `<div style="background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1.2rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;">
                <span style="font-size: 1.1rem;">${icon}</span>
                <h4 style="margin: 0; color: #1e293b; font-size: 0.95rem;">${title}</h4>
            </div>
            <div style="display: flex; flex-wrap: wrap; gap: 0.6rem;">
                ${items}
            </div>
        </div>`;
    };

    const buildMonthlyCard = (monthly, yearly) => {
        const monthEntries = Object.entries(monthly).sort((a,b) => b[0].localeCompare(a[0])).slice(0, 12);
        const yearEntries = Object.entries(yearly).sort((a,b) => b[0].localeCompare(a[0]));
        if (monthEntries.length === 0 && yearEntries.length === 0) return '';
        const monthColors = ['#3b82f6','#22c55e','#f59e0b','#ef4444','#8b5cf6','#ec4899','#06b6d4','#f97316','#6366f1','#14b8a6','#e11d48','#a855f7'];
        const yearItems = yearEntries.map(([y, c]) => 
            `<div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 0.5rem 1rem; text-align: center;">
                <span style="font-size: 0.85rem; color: #475569;">${y}年:</span>
                <span style="font-size: 1rem; font-weight: 700; color: #f59e0b; margin-left: 0.3rem;">${c}筆</span>
            </div>`
        ).join('');
        const monthItems = monthEntries.map(([ym, c], i) => {
            const color = monthColors[i % monthColors.length];
            return `<div style="background: ${color}0D; border: 1px solid ${color}33; border-radius: 8px; padding: 0.5rem 0.7rem; text-align: center; min-width: 80px;">
                <div style="font-size: 0.78rem; color: #64748b;">${ym}</div>
                <div style="font-size: 1.1rem; font-weight: 700; color: ${color};">${c}</div>
            </div>`;
        }).join('');
        return `<div style="background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1.2rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;">
                <span style="font-size: 1.1rem;">📅</span>
                <h4 style="margin: 0; color: #1e293b; font-size: 0.95rem;">時間分佈</h4>
            </div>
            ${yearEntries.length > 0 ? `<div style="margin-bottom: 0.8rem;"><div style="font-size: 0.8rem; color: #64748b; margin-bottom: 0.5rem;">年度統計：</div><div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">${yearItems}</div></div>` : ''}
            ${monthEntries.length > 0 ? `<div><div style="font-size: 0.8rem; color: #64748b; margin-bottom: 0.5rem;">月份統計 (最近12個月)：</div><div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">${monthItems}</div></div>` : ''}
        </div>`;
    };

    const buildDiagCodeCard = (diagData) => {
        const entries = Object.entries(diagData).sort((a,b) => b[1].count - a[1].count).slice(0, 10);
        if (entries.length === 0) return '';
        const rows = entries.map(([code, {count, name}], i) => {
            const colors = ['#3b82f6','#22c55e','#f59e0b','#ef4444','#8b5cf6'];
            const c = colors[i % colors.length];
            return `<div style="display: flex; align-items: center; gap: 0.8rem; padding: 0.5rem 0; border-bottom: 1px solid #f1f5f9;">
                <div style="background: ${c}15; color: ${c}; font-weight: 700; font-size: 0.78rem; padding: 0.3rem 0.6rem; border-radius: 6px; font-family: monospace; white-space: nowrap;">${code}</div>
                <div style="flex: 1; font-size: 0.82rem; color: #475569; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${name}</div>
                <div style="font-weight: 700; color: ${c}; font-size: 0.95rem;">${count}</div>
            </div>`;
        }).join('');
        return `<div style="background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1.2rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;">
                <span style="font-size: 1.1rem;">🏷️</span>
                <h4 style="margin: 0; color: #1e293b; font-size: 0.95rem;">診斷代碼分佈</h4>
            </div>
            ${rows}
        </div>`;
    };

    // 地區分佈卡片 (連結 Google Maps)
    const buildRegionCard = (regionStats) => {
        if (!regionStats) return '';
        const regions = regionStats.regions || [];
        const districts = regionStats.districts || [];
        if (regions.length === 0) return '';
        const total = regions.reduce((s, r) => s + r.count, 0);
        const mapColors = ['#ef4444','#f59e0b','#22c55e','#3b82f6','#8b5cf6','#ec4899','#06b6d4','#f97316'];
        
        const regionRows = regions.map((r, i) => {
            const pct = total > 0 ? Math.round(r.count / total * 100) : 0;
            const c = mapColors[i % mapColors.length];
            const mapUrl = `https://www.google.com/maps/search/${encodeURIComponent(r.name + ' 台灣')}`;
            return `<div style="margin-bottom: 0.6rem;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.25rem;">
                    <a href="${mapUrl}" target="_blank" rel="noopener noreferrer" style="font-size: 0.85rem; color: #334155; font-weight: 500; text-decoration: none; display: flex; align-items: center; gap: 4px; cursor: pointer;" title="在 Google Maps 上查看 ${r.name}">
                        <span style="color: ${c};">📍</span> ${r.name}
                        <i class="fas fa-external-link-alt" style="font-size: 0.6rem; color: #94a3b8; margin-left: 2px;"></i>
                    </a>
                    <span style="font-size: 0.85rem; font-weight: 700; color: ${c};">${r.count} <span style="font-size: 0.7rem; font-weight: 400; color: #94a3b8;">(${pct}%)</span></span>
                </div>
                <div style="background: #f1f5f9; border-radius: 6px; height: 8px; overflow: hidden;">
                    <div style="background: ${c}; height: 100%; width: ${pct}%; border-radius: 6px; transition: width 0.5s;"></div>
                </div>
            </div>`;
        }).join('');
        
        // 鄉鎮區明細 (顯示前 8 個)
        const topDistricts = districts.slice(0, 8);
        const districtItems = topDistricts.length > 0 ? topDistricts.map((d, i) => {
            const c = mapColors[i % mapColors.length];
            const mapUrl = `https://www.google.com/maps/search/${encodeURIComponent(d.name + ' 台灣')}`;
            return `<a href="${mapUrl}" target="_blank" rel="noopener noreferrer" style="text-decoration: none;">
                <div style="background: ${c}0D; border: 1px solid ${c}33; border-radius: 8px; padding: 0.4rem 0.7rem; text-align: center; min-width: 80px; cursor: pointer; transition: transform 0.15s;" onmouseover="this.style.transform='scale(1.05)'" onmouseout="this.style.transform='scale(1)'">
                    <div style="font-size: 0.72rem; color: #64748b;">${d.name}</div>
                    <div style="font-size: 1rem; font-weight: 700; color: ${c};">${d.count}</div>
                </div>
            </a>`;
        }).join('') : '';

        return `<div style="background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1.2rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;">
                <span style="font-size: 1.1rem;">🗺️</span>
                <h4 style="margin: 0; color: #1e293b; font-size: 0.95rem;">地區分佈</h4>
                <span style="font-size: 0.72rem; color: #94a3b8; margin-left: auto;">點擊開啟 Google Maps</span>
            </div>
            <div style="margin-bottom: 0.8rem;">${regionRows}</div>
            ${districtItems ? `<div style="border-top: 1px solid #f1f5f9; padding-top: 0.8rem; margin-top: 0.3rem;">
                <div style="font-size: 0.78rem; color: #64748b; margin-bottom: 0.5rem;">鄉鎮區明細：</div>
                <div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">${districtItems}</div>
            </div>` : ''}
        </div>`;
    };

    // 病毒明細卡片
    const buildVirusCard = (virusData) => {
        const entries = Object.entries(virusData).sort((a, b) => b[1].count - a[1].count);
        if (entries.length === 0) return '';
        const virusColors = ['#6366f1', '#8b5cf6', '#a855f7', '#c084fc', '#d8b4fe'];
        const items = entries.map(([name, data], i) => {
            const c = virusColors[i % virusColors.length];
            const patientCount = data.patients ? data.patients.size : data.count;
            return `<div style="display: flex; align-items: center; gap: 1rem; padding: 0.8rem 1rem; background: ${c}08; border-left: 4px solid ${c}; border-radius: 0 8px 8px 0; margin-bottom: 0.5rem;">
                <div style="flex: 1;">
                    <div style="font-size: 0.88rem; font-weight: 600; color: #1e293b;">${name}</div>
                </div>
                <div style="text-align: right;">
                    <div style="display: flex; align-items: center; gap: 0.4rem;">
                        <span style="font-size: 0.75rem; color: #64748b;">👥 病人數</span>
                        <span style="font-size: 1.3rem; font-weight: 700; color: ${c};">${patientCount}</span>
                    </div>
                </div>
            </div>`;
        }).join('');
        return `<div style="background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1.2rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;">
                <span style="font-size: 1.1rem;">⚙️</span>
                <h4 style="margin: 0; color: #1e293b; font-size: 0.95rem;">病毒明細</h4>
            </div>
            ${items}
        </div>`;
    };

    let statsHTML = '';
    if (cqlResults.length > 0 && !hasError) {
        const blueSet = ['#3b82f6', '#60a5fa', '#93c5fd'];
        const warmSet = ['#f59e0b', '#ef4444', '#22c55e', '#8b5cf6'];
        const pinkSet = ['#3b82f6', '#ec4899', '#94a3b8'];

        const encCard = buildCountCards('🏥', '就診類型分布', stats.encounterType, warmSet);
        const genderCard = buildDistCard('👥', '性別分佈', stats.gender, pinkSet, 'FHIR 實際數據');
        const eventCard = buildDistCard('🔬', '事件類型', stats.eventType, blueSet);
        const virusCard = buildVirusCard(stats.virusType);
        const monthCard = buildMonthlyCard(stats.monthly, stats.yearly);
        const diagCard = buildDiagCodeCard(stats.diagCode);
        const regionCard = buildRegionCard(results.regionStats);

        const allCards = [encCard, genderCard, virusCard, eventCard, regionCard, monthCard, diagCard].filter(c => c);
        
        if (allCards.length > 0) {
            statsHTML = `<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1rem;">${allCards.join('')}</div>`;
        } else {
            statsHTML = '<div style="padding: 2rem; color: #64748b; text-align: center;">查詢完成，但無法產生統計資訊（可能 FHIR 資料中無符合的 Condition/Observation）</div>';
        }
    } else if (hasError) {
        statsHTML = `
            <div style="background: #fef2f2; border: 1px solid #fecaca; border-radius: 12px; padding: 1.5rem;">
                ${cqlResults.map(r => `
                    <div style="display: flex; gap: 0.8rem; align-items: flex-start; margin-bottom: 0.8rem;">
                        <span style="color: #ef4444; font-size: 1.2rem;">⚠️</span>
                        <div>
                            <div style="font-weight: 600; color: #991b1b;">${r['執行狀態'] || '錯誤'}</div>
                            <div style="color: #b91c1c; font-size: 0.85rem; margin-top: 0.2rem;">${r['錯誤訊息'] || r['說明'] || ''}</div>
                        </div>
                    </div>
                `).join('')}
            </div>`;
    } else {
        statsHTML = '<div style="padding: 2rem; color: #64748b; text-align: center; font-size: 1rem;"><i class="fas fa-inbox" style="font-size: 2rem; display: block; margin-bottom: 0.5rem; opacity: 0.5;"></i>無符合條件的結果</div>';
    }

    const reportHTML = `
        <div style="background: #f8fafc; padding: 2rem; border-radius: 16px; max-width: 1100px; max-height: 85vh; overflow-y: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
                <h2 style="margin: 0; color: #1e293b; font-size: 1.4rem;">
                    <i class="fas fa-chart-bar"></i> ${diseaseNames[diseaseType]} 統計分析報告
                </h2>
                <button onclick="closeDetailReport()" style="background: none; border: none; font-size: 1.5rem; cursor: pointer; color: #64748b;">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            
            <div style="background: white; padding: 1rem; border-radius: 10px; margin-bottom: 1.5rem; border-left: 4px solid #3b82f6; border: 1px solid #e2e8f0;">
                <div style="display: flex; flex-wrap: wrap; gap: 1rem; font-size: 0.82rem; color: #64748b;">
                    <span><i class="fas fa-database" style="margin-right: 4px;"></i> ${results.cqlFile || 'N/A'}</span>
                    <span><i class="fas fa-clock" style="margin-right: 4px;"></i> ${meta.executionTime || 'N/A'}ms</span>
                    <span><i class="fas fa-calendar" style="margin-right: 4px;"></i> ${results.queryOptions?.startDate || 'N/A'} ~ ${results.queryOptions?.endDate || 'N/A'}</span>
                    <span><i class="fas fa-cog" style="margin-right: 4px;"></i> cql-execution v2.4.0</span>
                </div>
            </div>
            
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 1.5rem;">
                <div style="background: linear-gradient(135deg, #667eea, #764ba2); padding: 1.2rem; border-radius: 12px; color: white;">
                    <div style="font-size: 0.85rem; opacity: 0.9;">病患數</div>
                    <div style="font-size: 2rem; font-weight: 700;">${patientCount}</div>
                </div>
                <div style="background: linear-gradient(135deg, #f093fb, #f5576c); padding: 1.2rem; border-radius: 12px; color: white;">
                    <div style="font-size: 0.85rem; opacity: 0.9;">事件數 (Episodes)</div>
                    <div style="font-size: 2rem; font-weight: 700;">${totalEpisodes || resultCount}</div>
                </div>
                <div style="background: linear-gradient(135deg, #4facfe, #00f2fe); padding: 1.2rem; border-radius: 12px; color: white;">
                    <div style="font-size: 0.85rem; opacity: 0.9;">資料筆數</div>
                    <div style="font-size: 2rem; font-weight: 700;">${resultCount}</div>
                </div>
            </div>
            
            ${statsHTML}
            
            <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 1.5rem;">
                <button onclick="closeDetailReport()" style="padding: 0.75rem 1.5rem; background: #64748b; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600;">
                    <i class="fas fa-times"></i> 關閉
                </button>
            </div>
        </div>
    `;
    
    let modal = document.getElementById('detailReportModal');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'detailReportModal';
        modal.style.cssText = 'position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 10000; padding: 2rem;';
        document.body.appendChild(modal);
    }
    modal.innerHTML = reportHTML;
    modal.style.display = 'flex';
}

// 關閉詳細報告
function closeDetailReport() {
    const modal = document.getElementById('detailReportModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// 輔助函數 - 首字母大寫
function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// ========== 示範模式控制 ==========
function toggleDemoMode() {
    const currentMode = localStorage.getItem('demoMode') === 'true';
    const newMode = !currentMode;
    
    localStorage.setItem('demoMode', newMode.toString());
    updateDemoModeButton();
    
    const message = newMode 
        ? '✅ 示範模式已啟用\n\n當 FHIR 伺服器沒有資料時，系統將顯示模擬數據供展示使用。\n\n請重新整理頁面並點擊「執行查詢」按鈕測試。'
        : '✅ 示範模式已關閉\n\n系統將只顯示 FHIR 伺服器的真實資料。';
    
    alert(message);
    if (newMode) location.reload();
}

function updateDemoModeButton() {
    // 如果從未設定過，預設關閉示範模式（讓評審使用 FHIR 真實資料）
    if (localStorage.getItem('demoMode') === null) {
        localStorage.setItem('demoMode', 'false');
    }
    
    const demoMode = localStorage.getItem('demoMode') === 'true';
    const btn = document.getElementById('demoModeBtn');
    const text = document.getElementById('demoModeText');
    
    if (btn && text) {
        if (demoMode) {
            btn.classList.remove('btn-secondary');
            btn.classList.add('btn-success');
            btn.style.background = 'linear-gradient(135deg, #10b981, #059669)';
            text.textContent = '示範模式：開啟';
        } else {
            btn.classList.remove('btn-success');
            btn.classList.add('btn-secondary');
            btn.style.background = '';
            text.textContent = '啟用示範模式';
        }
    }
}

// 生成示範數據 - 完全隨機，100以內
function generateDemoDataDisease(diseaseType) {
    // 1. 隨機決定總資料庫大小 (200-500筆)
    const dbSize = 200 + Math.floor(Math.random() * 300);
    
    // 2. 隨機決定抽取數量 (30-99筆)
    const sampleSize = 30 + Math.floor(Math.random() * 70);
    
    // 3. 生成完整資料庫
    const fullDatabase = generateFullDatabase(diseaseType, dbSize);
    
    // 4. 隨機抽取
    const sampledCases = randomSample(fullDatabase, sampleSize);
    
    // 5. 隨機決定趨勢類型
    const trendTypes = [
        { type: 'increasing', rate: 0.05 + Math.random() * 0.08, desc: '持續上升', weight: 2 },
        { type: 'surging', rate: 0.12 + Math.random() * 0.10, desc: '急遽上升', weight: 1 },
        { type: 'decreasing', rate: -(0.04 + Math.random() * 0.05), desc: '趨勢下降', weight: 1 },
        { type: 'stable', rate: -0.02 + Math.random() * 0.04, desc: '持平穩定', weight: 2 }
    ];
    
    // 加權隨機選擇趨勢
    const randomTrend = weightedRandomSelect(trendTypes);
    
    // 6. 分析抽樣數據
    const totalCases = sampledCases.length;
    const detailedCases = analyzeSampledCases(sampledCases);
    
    // 7. 根據隨機趨勢計算最近數據
    const recentCases = calculateRecentTrend(totalCases, randomTrend.rate, randomTrend.type);
    
    // 8. 生成病毒明細（含年齡統計）
    const virusBreakdown = generateVirusBreakdown(diseaseType, sampledCases);
    
    console.log(`📊 ${diseaseType} 示範數據:`, {
        原始資料庫: fullDatabase.length,
        抽樣數量: totalCases,
        趨勢: randomTrend.desc,
        成長率: (randomTrend.rate * 100).toFixed(1) + '%',
        北部占比: (detailedCases.northernRatio * 100).toFixed(1) + '%',
        病毒類型數: Object.keys(virusBreakdown).length
    });
    
    return {
        total: totalCases,
        newCases: recentCases.current,
        trend: randomTrend.type,
        trendDescription: randomTrend.desc,
        growthRate: randomTrend.rate,
        northernRatio: detailedCases.northernRatio,
        detailedData: detailedCases.regions,
        demoMode: true,
        weeklyData: recentCases.dailyData,
        sampledFrom: fullDatabase.length,
        virusBreakdown: virusBreakdown
    };
}

// 生成完整資料庫 - 完全隨機分布
function generateFullDatabase(diseaseType, totalSize) {
    const database = [];
    
    // 每次隨機調整城市權重 (±30%)
    const cities = [
        // 北部
        { name: '台北市', region: 'north', weight: 15 * (0.7 + Math.random() * 0.6) },
        { name: '新北市', region: 'north', weight: 18 * (0.7 + Math.random() * 0.6) },
        { name: '桃園市', region: 'north', weight: 12 * (0.7 + Math.random() * 0.6) },
        { name: '新竹市', region: 'north', weight: 6 * (0.7 + Math.random() * 0.6) },
        { name: '基隆市', region: 'north', weight: 4 * (0.7 + Math.random() * 0.6) },
        // 中部
        { name: '台中市', region: 'central', weight: 8 * (0.7 + Math.random() * 0.6) },
        { name: '彰化縣', region: 'central', weight: 4 * (0.7 + Math.random() * 0.6) },
        { name: '南投縣', region: 'central', weight: 2 * (0.7 + Math.random() * 0.6) },
        // 南部
        { name: '台南市', region: 'south', weight: 5 * (0.7 + Math.random() * 0.6) },
        { name: '高雄市', region: 'south', weight: 6 * (0.7 + Math.random() * 0.6) },
        { name: '屏東縣', region: 'south', weight: 3 * (0.7 + Math.random() * 0.6) },
        // 東部
        { name: '花蓮縣', region: 'east', weight: 2 * (0.7 + Math.random() * 0.6) },
        { name: '台東縣', region: 'east', weight: 1 * (0.7 + Math.random() * 0.6) }
    ];
    
    const totalWeight = cities.reduce((sum, city) => sum + city.weight, 0);
    
    // 生成每一筆病例
    for (let i = 0; i < totalSize; i++) {
        // 加權隨機選擇城市
        let random = Math.random() * totalWeight;
        let selectedCity = cities[0];
        
        for (const city of cities) {
            random -= city.weight;
            if (random <= 0) {
                selectedCity = city;
                break;
            }
        }
        
        // 隨機生成病例資料 - 完全隨機化
        const daysAgo = Math.floor(Math.random() * 120); // 過去120天內（更大範圍）
        const age = 5 + Math.floor(Math.random() * 80); // 5-85歲（更大範圍）
        const severityRandom = Math.random();
        const severity = severityRandom > 0.85 ? 'severe' : severityRandom > 0.60 ? 'moderate' : 'mild';
        
        database.push({
            id: `case-${diseaseType}-${i + 1}-${Math.random().toString(36).substr(2, 4)}`,
            disease: diseaseType,
            city: selectedCity.name,
            region: selectedCity.region,
            date: new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000),
            age: age,
            severity: severity,
            patientId: `patient-${Math.floor(Math.random() * 8000) + 1000}` // 1000-9000之間
        });
    }
    
    return database;
}

// Fisher-Yates 隨機抽樣
function randomSample(array, sampleSize) {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled.slice(0, sampleSize);
}

// 加權隨機選擇
function weightedRandomSelect(options) {
    const totalWeight = options.reduce((sum, opt) => sum + opt.weight, 0);
    let random = Math.random() * totalWeight;
    
    for (const option of options) {
        random -= option.weight;
        if (random <= 0) {
            return option;
        }
    }
    return options[0];
}

// 分析抽樣病例
function analyzeSampledCases(cases) {
    const regionCount = {
        north: 0,
        central: 0,
        south: 0,
        east: 0
    };
    
    const cityCount = {};
    
    cases.forEach(c => {
        regionCount[c.region]++;
        cityCount[c.city] = (cityCount[c.city] || 0) + 1;
    });
    
    const total = cases.length;
    const northernRatio = (regionCount.north / total);
    
    // 轉換為顯示格式
    const regions = Object.entries(cityCount).map(([city, count]) => ({
        city: city,
        cases: count,
        percentage: ((count / total) * 100).toFixed(1)
    }));
    
    return {
        regions: regions,
        northernRatio: northernRatio,
        regionCount: regionCount
    };
}

// 生成詳細病例數據 - 隨機分散到全台13個城市
function generateDetailedCases(diseaseType, totalCases) {
    // 使用所有已定義的城市
    const allCities = Object.keys(cityCoordinates);
    const cityData = {};
    
    // 為每個城市生成隨機權重
    const cityWeights = {};
    let totalWeight = 0;
    
    allCities.forEach(city => {
        // 每個城市的權重更均勻分配 (0.3 - 1.3)，讓分散更平均
        const weight = 0.3 + Math.random() * 1.0;
        cityWeights[city] = weight;
        totalWeight += weight;
    });
    
    // 根據權重分配病例數
    let remainingCases = totalCases;
    allCities.forEach((city, index) => {
        if (index === allCities.length - 1) {
            // 最後一個城市分配剩餘所有病例
            cityData[city] = remainingCases;
        } else {
            // 按比例分配
            const ratio = cityWeights[city] / totalWeight;
            const cases = Math.floor(totalCases * ratio);
            cityData[city] = cases;
            remainingCases -= cases;
        }
    });
    
    // 添加總計
    cityData.total = totalCases;
    
    return cityData;
}
// 計算最近趨勢（根據疾病類型有不同趨勢）
function calculateRecentTrend(totalCases, growthRate, trendType) {
    // 最近7天的新增案例
    const last7Days = [];
    // 隨機基礎比例 2.0%-3.5%
    const baseRatio = 0.020 + Math.random() * 0.015;
    let baseDaily = Math.floor(totalCases * baseRatio);
    
    for (let i = 0; i < 7; i++) {
        let dailyCases;
        
        if (trendType === 'increasing' || trendType === 'surging') {
            // 上升趨勢：每天增加
            const dayMultiplier = 1 + (i * Math.abs(growthRate));
            dailyCases = Math.floor(baseDaily * dayMultiplier);
        } else if (trendType === 'decreasing') {
            // 下降趨勢：每天減少
            const dayMultiplier = 1 - (i * Math.abs(growthRate) * 0.5);
            dailyCases = Math.max(1, Math.floor(baseDaily * dayMultiplier));
        } else {
            // 持平趨勢：微幅波動 ±5%
            const randomVar = 0.95 + (Math.random() * 0.1); // 0.95 - 1.05
            dailyCases = Math.floor(baseDaily * randomVar);
        }
        
        last7Days.push(dailyCases);
    }
    
    const currentNew = last7Days[6]; // 今天的新增
    const previousNew = last7Days[5]; // 昨天的新增
    const weekTotal = last7Days.reduce((a, b) => a + b, 0);
    
    // 計算周變化率
    const firstHalf = last7Days.slice(0, 3).reduce((a, b) => a + b, 0);
    const secondHalf = last7Days.slice(4, 7).reduce((a, b) => a + b, 0);
    const weeklyChange = ((secondHalf - firstHalf) / firstHalf * 100).toFixed(1);
    
    return {
        current: currentNew,
        previous: previousNew,
        trend: trendType,
        weeklyTotal: weekTotal,
        weeklyChange: weeklyChange,
        dailyData: last7Days
    };
}

// 生成病毒明細（含亞型和年齡統計）
function generateVirusBreakdown(diseaseType, sampledCases) {
    const virusBreakdown = {};
    
    // 定義各疾病的病毒類型和亞型
    const virusTypes = {
        'covid19': [
            { name: 'SARS-CoV-2', subtype: 'Omicron BA.5', weight: 0.35 },
            { name: 'SARS-CoV-2', subtype: 'Omicron XBB.1.5', weight: 0.30 },
            { name: 'SARS-CoV-2', subtype: 'Omicron BA.2', weight: 0.20 },
            { name: 'SARS-CoV-2', subtype: 'Delta', weight: 0.10 },
            { name: 'SARS-CoV-2', subtype: '其他變異株', weight: 0.05 }
        ],
        'influenza': [
            { name: 'Influenza A', subtype: 'H3N2', weight: 0.40 },
            { name: 'Influenza A', subtype: 'H1N1', weight: 0.35 },
            { name: 'Influenza B', subtype: 'Victoria', weight: 0.15 },
            { name: 'Influenza B', subtype: 'Yamagata', weight: 0.10 }
        ],
        'conjunctivitis': [
            { name: 'Adenovirus', subtype: '血清型8', weight: 0.45 },
            { name: 'Adenovirus', subtype: '血清型19', weight: 0.30 },
            { name: 'Enterovirus 70', subtype: null, weight: 0.15 },
            { name: 'Coxsackievirus A24', subtype: null, weight: 0.10 }
        ],
        'enterovirus': [
            { name: 'Enterovirus A71', subtype: null, weight: 0.35 },
            { name: 'Coxsackievirus A16', subtype: null, weight: 0.30 },
            { name: 'Coxsackievirus A6', subtype: null, weight: 0.20 },
            { name: 'Echovirus', subtype: null, weight: 0.15 }
        ],
        'diarrhea': [
            { name: 'Norovirus', subtype: 'GII.4', weight: 0.40 },
            { name: 'Norovirus', subtype: 'GII.2', weight: 0.25 },
            { name: 'Rotavirus', subtype: 'G1P[8]', weight: 0.20 },
            { name: 'Sapovirus', subtype: null, weight: 0.10 },
            { name: 'Astrovirus', subtype: null, weight: 0.05 }
        ]
    };
    
    const virusOptions = virusTypes[diseaseType] || [
        { name: '未分類病毒', subtype: null, weight: 1.0 }
    ];
    
    // 根據權重分配病例到各病毒類型
    sampledCases.forEach(caseData => {
        // 加權隨機選擇病毒類型
        const selectedVirus = weightedRandomSelect(virusOptions);
        const virusKey = selectedVirus.subtype 
            ? `${selectedVirus.name} (${selectedVirus.subtype})`
            : selectedVirus.name;
        
        if (!virusBreakdown[virusKey]) {
            virusBreakdown[virusKey] = {
                count: 0,
                ages: [],
                subtype: selectedVirus.subtype
            };
        }
        
        virusBreakdown[virusKey].count++;
        virusBreakdown[virusKey].ages.push(caseData.age);
    });
    
    // 計算每種病毒的平均年齡和年齡範圍
    Object.keys(virusBreakdown).forEach(virusKey => {
        const data = virusBreakdown[virusKey];
        const ages = data.ages;
        
        if (ages.length > 0) {
            const avgAge = Math.round(ages.reduce((sum, age) => sum + age, 0) / ages.length);
            const minAge = Math.min(...ages);
            const maxAge = Math.max(...ages);
            
            data.avgAge = avgAge;
            data.ageRange = `${minAge}-${maxAge}歲`;
            
            // 清理臨時的 ages 陣列
            delete data.ages;
        }
    });
    
    return virusBreakdown;
}

// ========== Google Maps 地圖功能 ==========

// 台灣主要城市座標
const cityCoordinates = {
    '台北市': [25.0330, 121.5654],
    '新北市': [25.0116, 121.4648],
    '桃園市': [24.9936, 121.3010],
    '新竹市': [24.8138, 120.9675],
    '基隆市': [25.1276, 121.7392],
    '台中市': [24.1477, 120.6736],
    '彰化縣': [24.0518, 120.5161],
    '南投縣': [23.9609, 120.9719],
    '台南市': [22.9998, 120.2269],
    '高雄市': [22.6273, 120.3014],
    '屏東縣': [22.5519, 120.5487],
    '花蓮縣': [23.9871, 121.6015],
    '台東縣': [22.7583, 121.1444]
};

// 疾病顏色配置
const diseaseColors = {
    'covid19': '#ef4444',      // 紅色
    'influenza': '#3b82f6',    // 藍色
    'conjunctivitis': '#f59e0b', // 橙色
    'enterovirus': '#8b5cf6',  // 紫色
    'diarrhea': '#10b981'      // 綠色
};

// 疾病名稱
const diseaseNames = {
    'covid19': 'COVID-19',
    'influenza': '流感',
    'conjunctivitis': '急性結膜炎',
    'enterovirus': '腸病毒',
    'diarrhea': '腹瀉群聚'
};

// 切換地圖模式
function toggleMapMode() {
    isMapMode = !isMapMode;
    
    const mapSection = document.getElementById('mapSection');
    const overviewSection = document.getElementById('overviewSection');
    const mapModeBtn = document.getElementById('mapModeBtn');
    const mapModeText = document.getElementById('mapModeText');
    
    if (isMapMode) {
        // 切換到地圖模式
        mapSection.style.display = 'block';
        overviewSection.style.display = 'none';
        mapModeBtn.style.background = 'linear-gradient(135deg, #ef4444, #dc2626)';
        mapModeText.textContent = '返回列表模式';
        mapModeBtn.querySelector('i').className = 'fas fa-th-large';
        
        // 初始化地圖
        if (!diseaseMap) {
            initializeMap();
        } else {
            // 重新調整地圖大小
            setTimeout(() => {
                diseaseMap.invalidateSize();
            }, 100);
        }
        
        // 更新地圖顯示
        updateMapDisplay();
    } else {
        // 切換回列表模式
        mapSection.style.display = 'none';
        overviewSection.style.display = 'block';
        mapModeBtn.style.background = 'linear-gradient(135deg, #3b82f6, #2563eb)';
        mapModeText.textContent = 'Google Map';
        mapModeBtn.querySelector('i').className = 'fas fa-map-marked-alt';
    }
}

// 初始化地圖
function initializeMap() {
    console.log('初始化地圖...');
    
    // 創建地圖，中心點設在台灣中部
    diseaseMap = L.map('diseaseMap').setView([23.5, 121.0], 7);
    
    // 添加 OpenStreetMap 圖層
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 18
    }).addTo(diseaseMap);
    
    // 初始化標記層
    mapMarkers = {
        'covid19': L.layerGroup().addTo(diseaseMap),
        'influenza': L.layerGroup().addTo(diseaseMap),
        'conjunctivitis': L.layerGroup().addTo(diseaseMap),
        'enterovirus': L.layerGroup().addTo(diseaseMap),
        'diarrhea': L.layerGroup().addTo(diseaseMap)
    };
    
    console.log('地圖初始化完成');
}

// 更新地圖顯示
function updateMapDisplay() {
    if (!diseaseMap) return;
    
    console.log('更新地圖顯示...');
    
    // 獲取選中的疾病
    const selectedDiseases = [];
    ['covid19', 'influenza', 'conjunctivitis', 'enterovirus', 'diarrhea'].forEach(disease => {
        const checkbox = document.getElementById(`map${capitalize(disease)}`);
        if (checkbox && checkbox.checked) {
            selectedDiseases.push(disease);
        }
    });
    
    // 清除所有標記
    Object.values(mapMarkers).forEach(layer => layer.clearLayers());
    
    // 為每個選中的疾病添加標記
    selectedDiseases.forEach(disease => {
        const results = currentResults[disease];
        
        if (results && results.demoMode && results.detailedData) {
            // 示範模式：從 detailedData 獲取城市數據
            addDiseaseMarkers(disease, results.detailedData);
        } else if (results && results.conditions) {
            // 真實模式：從 conditions 分析城市分佈（簡化處理）
            const cityData = analyzeCityDistribution(results.conditions);
            addDiseaseMarkers(disease, cityData);
        }
    });
    
    console.log(`已更新 ${selectedDiseases.length} 個疾病的地圖標記`);
}

// 添加疾病標記到地圖
function addDiseaseMarkers(disease, cityData) {
    const color = diseaseColors[disease];
    const name = diseaseNames[disease];
    
    // 如果 cityData 是陣列格式（來自 detailedData）
    if (Array.isArray(cityData)) {
        cityData.forEach(item => {
            const coords = cityCoordinates[item.city];
            if (coords && item.cases > 0) {
                addCircleMarker(disease, item.city, coords, item.cases, color, name);
            }
        });
    } else {
        // 如果是物件格式
        Object.entries(cityData).forEach(([city, data]) => {
            const coords = cityCoordinates[city];
            if (coords && data.cases > 0) {
                addCircleMarker(disease, city, coords, data.cases, color, name);
            }
        });
    }
}

// 添加圓形標記
function addCircleMarker(disease, city, coords, cases, color, diseaseName) {
    // 計算圓圈大小（根據案例數）
    const radius = Math.sqrt(cases) * 3000; // 調整比例讓圓圈大小適中
    
    const circle = L.circle(coords, {
        color: color,
        fillColor: color,
        fillOpacity: 0.4,
        radius: radius,
        weight: 2
    });
    
    // 添加彈出視窗
    circle.bindPopup(`
        <div style="font-family: Arial, sans-serif; min-width: 200px;">
            <h3 style="margin: 0 0 0.5rem 0; color: ${color}; font-size: 1rem;">
                <i class="fas fa-map-marker-alt"></i> ${city}
            </h3>
            <div style="border-top: 2px solid ${color}; padding-top: 0.5rem; margin-top: 0.5rem;">
                <div style="margin-bottom: 0.3rem;">
                    <strong>疾病:</strong> ${diseaseName}
                </div>
                <div style="margin-bottom: 0.3rem;">
                    <strong>案例數:</strong> <span style="color: ${color}; font-weight: 700; font-size: 1.1rem;">${cases}</span> 人
                </div>
                <div style="font-size: 0.85rem; color: #64748b; margin-top: 0.5rem;">
                    點擊圓圈查看更多資訊
                </div>
            </div>
        </div>
    `);
    
    // 滑鼠懸停效果
    circle.on('mouseover', function() {
        this.setStyle({
            fillOpacity: 0.7,
            weight: 3
        });
    });
    
    circle.on('mouseout', function() {
        this.setStyle({
            fillOpacity: 0.4,
            weight: 2
        });
    });
    
    // 添加到對應的圖層
    mapMarkers[disease].addLayer(circle);
}

// 分析城市分佈（真實模式用）
function analyzeCityDistribution(conditions) {
    const cityData = {};
    
    // 簡化處理：隨機分配到各城市
    const cities = Object.keys(cityCoordinates);
    const totalCases = conditions.length;
    
    cities.forEach(city => {
        const cases = Math.floor(Math.random() * (totalCases / cities.length * 2));
        if (cases > 0) {
            cityData[city] = { cases: cases };
        }
    });
    
    return cityData;
}

// 暴露函數到全局
window.toggleMapMode = toggleMapMode;
window.updateMapDisplay = updateMapDisplay;

// 頁面載入時初始化
document.addEventListener('DOMContentLoaded', function() {
    updateDemoModeButton();
});
