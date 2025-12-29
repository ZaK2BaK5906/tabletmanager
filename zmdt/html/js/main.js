// ============================================
// GLOBALS
// ============================================

let mdtData = null;
let currentService = null;

// ============================================
// POST DATA TO LUA
// ============================================

function postData(action, data) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data || {})
    }).then(resp => resp.json()).then(resp => {
        // Handle response if needed
    });
}

// ============================================
// NUI MESSAGES FROM LUA
// ============================================

window.addEventListener('message', (event) => {
    const data = event.data;

    switch(data.action) {
        case 'open':
            openMDT(data.service, data.data);
            break;
        case 'close':
            closeMDT();
            break;
        case 'openTab':
            openTab(data.tab);
            break;
        case 'police_newCall':
            addCallToList(data.call);
            break;
        case 'police_newBOLO':
            addBOLOToList(data.bolo);
            break;
    }
});

// ============================================
// OPEN / CLOSE MDT
// ============================================

function openMDT(service, data) {
    currentService = service;
    mdtData = data;

    // Show container
    document.getElementById('mdtContainer').style.display = 'flex';

    // Apply service class
    document.getElementById('mdtContainer').className = 'service-' + service;

    // Set header info
    document.getElementById('serviceLabel').textContent = service.toUpperCase() + ' MDT';
    document.getElementById('userName').textContent = data.user.name;
    document.getElementById('userJob').textContent = data.user.job_label;

    // Show appropriate tabs
    document.getElementById('policeTabs').style.display = service === 'police' ? 'flex' : 'none';
    document.getElementById('dojTabs').style.display = service === 'doj' ? 'flex' : 'none';
    document.getElementById('emsTabs').style.display = service === 'ems' ? 'flex' : 'none';

    // Load initial data
    if (service === 'police') {
        loadActiveCalls(data.activeCalls);
        loadActiveBOLO(data.activeBOLO);
    } else if (service === 'doj') {
        loadActiveCases(data.activeCases);
    } else if (service === 'ems') {
        loadEMSCalls(data.activeCalls);
    }

    // Setup tab switching
    setupTabs();
}

function closeMDT() {
    document.getElementById('mdtContainer').style.display = 'none';
    mdtData = null;
    currentService = null;
    postData('close', {});
}

// ============================================
// TABS
// ============================================

function setupTabs() {
    const tabs = document.querySelectorAll('.tab-btn');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const tabId = tab.getAttribute('data-tab');
            openTab(tabId);
        });
    });
}

function openTab(tabId) {
    // Hide all panels
    const panels = document.querySelectorAll('.tab-panel');
    panels.forEach(panel => panel.classList.remove('active'));

    // Remove active from all tabs
    const tabs = document.querySelectorAll('.tab-btn');
    tabs.forEach(tab => tab.classList.remove('active'));

    // Show selected panel
    const panel = document.getElementById('tab-' + tabId);
    if (panel) {
        panel.classList.add('active');
    }

    // Activate selected tab
    const activeTab = document.querySelector(`[data-tab="${tabId}"]`);
    if (activeTab) {
        activeTab.classList.add('active');
    }
}

// ============================================
// POLICE - CAD
// ============================================

function loadActiveCalls(calls) {
    const container = document.getElementById('callsList');
    container.innerHTML = '';

    calls.forEach(call => {
        addCallToList(call);
    });
}

function addCallToList(call) {
    const container = document.getElementById('callsList');
    const div = document.createElement('div');
    div.className = 'list-item';
    div.innerHTML = `
        <div class="list-item-header">
            <span class="list-item-title">${call.call_number} - ${call.call_type}</span>
            <span class="list-item-badge badge-${call.priority}">${call.priority.toUpperCase()}</span>
        </div>
        <div class="list-item-body">
            <strong>Location:</strong> ${call.location}<br>
            <strong>Description:</strong> ${call.description}
        </div>
    `;
    container.appendChild(div);
}

function createCall() {
    // TODO: Open call creation modal
    alert('Création d\'appel - À implémenter');
}

// ============================================
// POLICE - SEARCH
// ============================================

function searchCitizen() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    postData('police_searchCitizen', {query: query});
}

function searchVehicle() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    postData('police_searchVehicle', {query: query});
}

function searchWeapon() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    postData('police_searchWeapon', {query: query});
}

// ============================================
// POLICE - REPORTS
// ============================================

function createReport() {
    alert('Création de rapport - À implémenter');
}

// ============================================
// POLICE - BOLO
// ============================================

function loadActiveBOLO(bolos) {
    const container = document.getElementById('boloList');
    container.innerHTML = '';

    bolos.forEach(bolo => {
        addBOLOToList(bolo);
    });
}

function addBOLOToList(bolo) {
    const container = document.getElementById('boloList');
    const div = document.createElement('div');
    div.className = 'list-item';
    div.innerHTML = `
        <div class="list-item-header">
            <span class="list-item-title">${bolo.subject}</span>
            <span class="list-item-badge badge-${bolo.priority}">${bolo.priority.toUpperCase()}</span>
        </div>
        <div class="list-item-body">
            <strong>Type:</strong> ${bolo.bolo_type}<br>
            <strong>Description:</strong> ${bolo.description}<br>
            <strong>Issued by:</strong> ${bolo.issued_by_name || 'Unknown'}
        </div>
    `;
    container.appendChild(div);
}

function createBOLO() {
    alert('Création de BOLO - À implémenter');
}

// ============================================
// DOJ
// ============================================

function loadActiveCases(cases) {
    const container = document.getElementById('casesList');
    container.innerHTML = '';

    cases.forEach(caseData => {
        const div = document.createElement('div');
        div.className = 'list-item';
        div.innerHTML = `
            <div class="list-item-header">
                <span class="list-item-title">${caseData.case_number} - ${caseData.title}</span>
                <span class="list-item-badge badge-medium">${caseData.status}</span>
            </div>
            <div class="list-item-body">
                <strong>Defendant:</strong> ${caseData.defendant_name}
            </div>
        `;
        container.appendChild(div);
    });
}

function createCase() {
    alert('Création de dossier - À implémenter');
}

function createWarrant() {
    alert('Création de mandat - À implémenter');
}

function scheduleHearing() {
    alert('Planification d\'audience - À implémenter');
}

// ============================================
// EMS
// ============================================

function loadEMSCalls(calls) {
    const container = document.getElementById('emsCallsList');
    container.innerHTML = '';

    calls.forEach(call => {
        const div = document.createElement('div');
        div.className = 'list-item';
        div.innerHTML = `
            <div class="list-item-header">
                <span class="list-item-title">${call.call_number} - ${call.call_type}</span>
                <span class="list-item-badge badge-${call.priority === 'critical' ? 'high' : 'medium'}">${call.priority}</span>
            </div>
            <div class="list-item-body">
                <strong>Location:</strong> ${call.location}<br>
                <strong>Chief Complaint:</strong> ${call.chief_complaint}
            </div>
        `;
        container.appendChild(div);
    });
}

function createEMSCall() {
    alert('Création d\'appel EMS - À implémenter');
}

function searchPatient() {
    alert('Recherche patient - À implémenter');
}

function createEPCR() {
    alert('Création ePCR - À implémenter');
}

// ============================================
// KEYBOARD EVENTS
// ============================================

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeMDT();
    }
});

// ============================================
// HELPER FUNCTIONS
// ============================================

function GetParentResourceName() {
    return 'zmdt';
}

console.log('[ZMDT] UI loaded');
