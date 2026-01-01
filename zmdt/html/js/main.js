// ============================================
// ZX POLICE MDT - MAIN JAVASCRIPT
// ============================================

let mdtData = null;
let currentService = null;
let currentCitizenProfile = null;
let allCharges = [];
let selectedCharges = [];

// ============================================
// POST DATA TO LUA
// ============================================

function postData(action, data) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(data || {})
    })
    .then(resp => resp.json())
    .catch(err => console.error('[MDT] Error:', err));
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
        case 'updateDashboard':
            updateDashboard(data.stats);
            break;
        case 'newCall':
            addCallToList(data.call);
            break;
        case 'newBOLO':
            addBOLOToList(data.bolo);
            notifyBOLO(data.bolo);
            break;
        case 'newWanted':
            notifyWanted(data.wanted);
            break;
    }
});

// ============================================
// OPEN / CLOSE MDT
// ============================================

function openMDT(service, data) {
    console.log('[MDT DEBUG] Opening MDT with service:', service);
    console.log('[MDT DEBUG] Initial data received:', data);

    currentService = service;
    mdtData = data;

    document.getElementById('mdtContainer').style.display = 'flex';
    document.getElementById('mdtContainer').className = 'service-' + service;

    document.getElementById('serviceLabel').textContent = (service.toUpperCase() + ' MDT');
    document.getElementById('userName').textContent = data.user.name || 'Unknown';
    document.getElementById('userJob').textContent = data.user.job_label || 'Police Officer';
    document.getElementById('userGrade').textContent = 'Grade ' + (data.user.grade || 0);

    document.getElementById('policeTabs').style.display = service === 'police' ? 'flex' : 'none';

    setupTabs();

    if (service === 'police') {
        console.log('[MDT DEBUG] Loading police dashboard...');
        loadDashboard();
    }
}

function closeMDT() {
    document.getElementById('mdtContainer').style.display = 'none';
    mdtData = null;
    currentService = null;
    postData('close', {});
}

// ============================================
// DASHBOARD
// ============================================

function loadDashboard() {
    postData('police_getDashboard', {}).then(data => {
        if (data) {
            updateDashboard(data);
        }
    });
}

function updateDashboard(stats) {
    if (!stats) return;

    document.getElementById('stat-activeCalls').textContent = stats.activeCalls || 0;
    document.getElementById('stat-activeUnits').textContent = stats.activeUnits || 0;
    document.getElementById('stat-recentArrests').textContent = stats.recentArrests || 0;
    document.getElementById('stat-activeBOLO').textContent = stats.activeBOLO || 0;
    document.getElementById('stat-wantedPersons').textContent = stats.wantedPersons || 0;
    document.getElementById('stat-activeWarrants').textContent = stats.activeWarrants || 0;

    if (stats.recentActivity) {
        displayRecentActivity(stats.recentActivity);
    }

    if (stats.bolo) {
        displayDashboardBOLO(stats.bolo);
    }
}

function displayRecentActivity(activities) {
    const container = document.getElementById('recentActivity');
    if (!activities || activities.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucune activité récente</p>';
        return;
    }

    container.innerHTML = activities.map(activity => `
        <div class="list-item" style="margin-bottom: 10px;">
            <div class="list-item-body">
                <strong>${activity.type}</strong> - ${activity.description}
                <br><small>${activity.officer_name} | ${activity.time}</small>
            </div>
        </div>
    `).join('');
}

function displayDashboardBOLO(bolos) {
    const container = document.getElementById('dashboardBOLO');
    if (!bolos || bolos.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun BOLO actif</p>';
        return;
    }

    container.innerHTML = bolos.map(bolo => `
        <div class="list-item" style="margin-bottom: 10px;">
            <div class="list-item-header">
                <span class="list-item-title">${bolo.subject}</span>
                <span class="list-item-badge badge-${bolo.priority}">${bolo.priority.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Type:</strong> ${bolo.bolo_type} | <strong>Danger:</strong> ${bolo.danger_level}
            </div>
        </div>
    `).join('');
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
    const panels = document.querySelectorAll('.tab-panel');
    panels.forEach(panel => panel.classList.remove('active'));

    const tabs = document.querySelectorAll('.tab-btn');
    tabs.forEach(tab => tab.classList.remove('active'));

    const panel = document.getElementById('tab-' + tabId);
    if (panel) {
        panel.classList.add('active');
        loadTabData(tabId);
    }

    const activeTab = document.querySelector(`[data-tab="${tabId}"]`);
    if (activeTab) {
        activeTab.classList.add('active');
    }
}

function loadTabData(tabId) {
    switch(tabId) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'cad':
            loadCalls();
            break;
        case 'reports':
            loadReports();
            break;
        case 'arrests':
            loadArrests();
            break;
        case 'citations':
            loadCitations();
            break;
        case 'bolo':
            loadBOLO();
            break;
        case 'warrants':
            loadWarrants();
            break;
        case 'wanted':
            loadWanted();
            break;
        case 'evidence':
            loadEvidence();
            break;
        case 'ppa':
            loadPPA();
            break;
        case 'ppa-heavy':
            loadPPAHeavy();
            break;
        case 'vehicles':
            loadVehicles();
            break;
        case 'intel':
            loadIntel();
            break;
        case 'units':
            loadUnits();
            break;
        case 'charges':
            loadChargesLibrary();
            break;
        case 'personnel':
            loadPersonnel();
            break;
    }
}

// ============================================
// CAD - 911 CALLS
// ============================================

function loadCalls() {
    postData('police_getCalls', {}).then(calls => {
        displayCalls(calls || []);
    });
}

function displayCalls(calls) {
    const container = document.getElementById('callsList');
    if (!calls || calls.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun appel actif</p>';
        return;
    }

    container.innerHTML = calls.map(call => `
        <div class="list-item" onclick="viewCallDetails('${call.id}')">
            <div class="list-item-header">
                <span class="list-item-title">${call.call_number} - ${call.call_type}</span>
                <span class="list-item-badge badge-${call.priority}">${call.priority.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Location:</strong> ${call.location}<br>
                <strong>Description:</strong> ${call.description}<br>
                <small>Status: ${call.status} | ${call.created_at}</small>
            </div>
        </div>
    `).join('');
}

function filterCalls(status) {
    const buttons = document.querySelectorAll('#tab-cad .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getCalls', {status: status === 'all' ? null : status}).then(calls => {
        displayCalls(calls || []);
    });
}

function addCallToList(call) {
    loadCalls();
}

function createCall() {
    openModal('createCallModal');
}

function viewCallDetails(callId) {
    postData('police_getCallDetails', {id: callId}).then(call => {
        // TODO: Implement call details modal
        console.log('Call details:', call);
    });
}

// ============================================
// SEARCH
// ============================================

function searchCitizen() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    postData('police_searchCitizen', {query: query}).then(results => {
        displaySearchResults(results || [], 'citizen');
    });
}

function searchVehicle() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    postData('police_searchVehicle', {query: query}).then(results => {
        displaySearchResults(results || [], 'vehicle');
    });
}

function searchWeapon() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    postData('police_searchWeapon', {query: query}).then(results => {
        displaySearchResults(results || [], 'weapon');
    });
}

function quickSearchVehicle() {
    const query = document.getElementById('vehicleQuickSearch').value;
    if (!query) return;

    postData('police_searchVehicle', {query: query}).then(results => {
        displaySearchResults(results || [], 'vehicle');
    });
}

function displaySearchResults(results, type) {
    const container = document.getElementById('searchResults');
    if (!results || results.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #94a3b8;">Aucun résultat trouvé</p>';
        return;
    }

    container.innerHTML = results.map(result => {
        if (type === 'citizen') {
            return `
                <div class="search-result-item">
                    <div class="result-header">
                        <h4>${result.firstname} ${result.lastname}</h4>
                        ${result.is_wanted ? '<span class="list-item-badge badge-high">WANTED</span>' : ''}
                        ${result.flagged_notes > 0 ? '<span class="list-item-badge badge-medium">FLAGGED</span>' : ''}
                    </div>
                    <div class="result-body">
                        <p>DOB: ${result.dateofbirth || 'N/A'} | Phone: ${result.phone_number || 'N/A'}</p>
                        <p>Charges criminelles: ${result.criminal_charges || 0} | Amendes impayées: $${result.total_unpaid_fines || 0}</p>
                        <button onclick="viewCitizenProfile('${result.identifier}')">Voir Profil</button>
                    </div>
                </div>
            `;
        } else if (type === 'vehicle') {
            return `
                <div class="search-result-item">
                    <div class="result-header">
                        <h4>${result.plate} - ${result.vehicle}</h4>
                        ${result.is_stolen ? '<span class="list-item-badge badge-high">VOLÉ</span>' : ''}
                        ${result.has_bolo ? '<span class="list-item-badge badge-medium">BOLO</span>' : ''}
                    </div>
                    <div class="result-body">
                        <p>Propriétaire: ${result.owner_name || 'Inconnu'}</p>
                        <p>Status: ${result.stored ? 'Garé' : 'Sorti'} | Citations: ${result.unpaid_citations || 0}</p>
                    </div>
                </div>
            `;
        } else if (type === 'weapon') {
            return `
                <div class="search-result-item">
                    <div class="result-header">
                        <h4>${result.serial_number}</h4>
                        <span class="list-item-badge badge-${result.legal_status === 'illegal' ? 'high' : 'low'}">${result.legal_status}</span>
                    </div>
                    <div class="result-body">
                        <p>Type: ${result.weapon_type || 'Unknown'}</p>
                        <p>Propriétaire: ${result.owner_name || 'Inconnu'}</p>
                    </div>
                </div>
            `;
        }
    }).join('');
}

// ============================================
// REPORTS
// ============================================

function loadReports() {
    postData('police_getReports', {}).then(reports => {
        displayReports(reports || []);
    });
}

function displayReports(reports) {
    const container = document.getElementById('reportsList');
    if (!reports || reports.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun rapport</p>';
        return;
    }

    container.innerHTML = reports.map(report => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${report.report_number} - ${report.title}</span>
                <span class="list-item-badge badge-${report.approval_status === 'pending' ? 'medium' : report.approval_status === 'approved' ? 'low' : 'high'}">${report.approval_status.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Type:</strong> ${report.report_type} | <strong>Location:</strong> ${report.location}<br>
                <small>Par: ${report.officer_name} | ${report.created_at}</small>
            </div>
        </div>
    `).join('');
}

function filterReports(filter) {
    const buttons = document.querySelectorAll('#tab-reports .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getReports', {filter: filter}).then(reports => {
        displayReports(reports || []);
    });
}

function createReport() {
    openModal('createReportModal');
}

// ============================================
// ARRESTS
// ============================================

function loadArrests() {
    postData('police_getArrests', {}).then(data => {
        if (data) {
            displayArrests(data.arrests || []);
            document.getElementById('arrests-today').textContent = data.stats?.today || 0;
            document.getElementById('arrests-week').textContent = data.stats?.week || 0;
        }
    });
}

function displayArrests(arrests) {
    const container = document.getElementById('arrestsList');
    if (!arrests || arrests.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucune arrestation</p>';
        return;
    }

    container.innerHTML = arrests.map(arrest => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${arrest.arrest_number} - ${arrest.citizen_name}</span>
                <span class="list-item-badge badge-${arrest.is_processed ? 'low' : 'medium'}">${arrest.is_processed ? 'PROCESSED' : 'PENDING'}</span>
            </div>
            <div class="list-item-body">
                <strong>Charges:</strong> ${arrest.charge_count || 0} | <strong>Amende:</strong> $${arrest.total_fine} | <strong>Prison:</strong> ${arrest.total_jail_time} min<br>
                <small>Par: ${arrest.arresting_officer_name} | ${arrest.arrest_date}</small>
            </div>
        </div>
    `).join('');
}

function createArrest() {
    loadNearbyPlayers('arrest');
    openModal('createArrestModal');
}

// ============================================
// CITATIONS
// ============================================

function loadCitations() {
    postData('police_getCitations', {}).then(citations => {
        displayCitations(citations || []);
    });
}

function displayCitations(citations) {
    const container = document.getElementById('citationsList');
    if (!citations || citations.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucune citation</p>';
        return;
    }

    container.innerHTML = citations.map(citation => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${citation.citation_number} - ${citation.citizen_name}</span>
                <span class="list-item-badge badge-${citation.payment_status === 'unpaid' ? 'high' : 'low'}">${citation.payment_status.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Violation:</strong> ${citation.violation_code} - ${citation.violation_description}<br>
                <strong>Montant:</strong> $${citation.fine_amount} | <strong>Points:</strong> ${citation.points || 0}<br>
                <small>Par: ${citation.officer_name} | ${citation.issued_date}</small>
            </div>
        </div>
    `).join('');
}

function filterCitations(status) {
    const buttons = document.querySelectorAll('#tab-citations .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getCitations', {status: status === 'all' ? null : status}).then(citations => {
        displayCitations(citations || []);
    });
}

function createCitation() {
    loadNearbyPlayers('citation');
    openModal('createCitationModal');
}

// ============================================
// BOLO
// ============================================

function loadBOLO() {
    postData('police_getBOLO', {}).then(bolos => {
        displayBOLO(bolos || []);
    });
}

function displayBOLO(bolos) {
    const container = document.getElementById('boloList');
    if (!bolos || bolos.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun BOLO actif</p>';
        return;
    }

    container.innerHTML = bolos.map(bolo => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${bolo.subject}</span>
                <span class="list-item-badge badge-${bolo.priority}">${bolo.priority.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Type:</strong> ${bolo.bolo_type} | <strong>Danger:</strong> ${bolo.danger_level}<br>
                <strong>Description:</strong> ${bolo.description}<br>
                <small>Émis par: ${bolo.issued_by_name} | ${bolo.issued_date}</small>
            </div>
        </div>
    `).join('');
}

function filterBOLO(filter) {
    const buttons = document.querySelectorAll('#tab-bolo .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getBOLO', {filter: filter}).then(bolos => {
        displayBOLO(bolos || []);
    });
}

function addBOLOToList(bolo) {
    loadBOLO();
}

function notifyBOLO(bolo) {
    // TODO: Add notification system
    console.log('[BOLO] New BOLO:', bolo);
}

function createBOLO() {
    openModal('createBOLOModal');
}

// ============================================
// WARRANTS
// ============================================

function loadWarrants() {
    postData('police_getWarrants', {}).then(data => {
        if (data) {
            displayWarrants(data.warrants || []);
            document.getElementById('warrant-arrest').textContent = data.stats?.arrest || 0;
            document.getElementById('warrant-search').textContent = data.stats?.search || 0;
        }
    });
}

function displayWarrants(warrants) {
    const container = document.getElementById('warrantsList');
    if (!warrants || warrants.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun mandat</p>';
        return;
    }

    container.innerHTML = warrants.map(warrant => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${warrant.warrant_number} - ${warrant.warrant_type}</span>
                <span class="list-item-badge badge-${warrant.status === 'active' ? 'high' : 'medium'}">${warrant.status.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Cible:</strong> ${warrant.target_name || warrant.target_address || 'N/A'}<br>
                <strong>Raison:</strong> ${warrant.reason}<br>
                <small>Émis par: ${warrant.issued_by_name} | ${warrant.issued_date}</small>
            </div>
        </div>
    `).join('');
}

function createWarrant() {
    // TODO: Implement warrant creation modal
    alert('Création de mandat - À implémenter avec modal dédié');
}

// ============================================
// WANTED PERSONS
// ============================================

function loadWanted() {
    postData('police_getWanted', {}).then(wanted => {
        displayWanted(wanted || []);
    });
}

function displayWanted(wanted) {
    const container = document.getElementById('wantedList');
    if (!wanted || wanted.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucune personne recherchée</p>';
        return;
    }

    container.innerHTML = wanted.map(person => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${person.citizen_name}</span>
                <span class="list-item-badge badge-${person.is_armed ? 'high' : 'medium'}">${person.is_armed ? 'ARMÉ' : 'DANGEREUX'}</span>
            </div>
            <div class="list-item-body">
                <strong>Raison:</strong> ${person.reason}<br>
                <strong>Danger:</strong> ${person.danger_level} | <strong>Approche:</strong> ${person.approach_with_caution ? 'PRUDENCE' : 'Normal'}<br>
                <small>Ajouté par: ${person.added_by_name} | ${person.added_date}</small>
            </div>
        </div>
    `).join('');
}

function filterWanted(filter) {
    const buttons = document.querySelectorAll('#tab-wanted .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getWanted', {filter: filter}).then(wanted => {
        displayWanted(wanted || []);
    });
}

function notifyWanted(wanted) {
    // TODO: Add notification system
    console.log('[WANTED] New wanted person:', wanted);
}

function addWantedPerson() {
    // TODO: Implement wanted person creation modal
    alert('Ajout wanted - À implémenter avec modal dédié');
}

function addToWanted() {
    if (!currentCitizenProfile) return;
    alert('Ajout wanted pour: ' + currentCitizenProfile.firstname + ' ' + currentCitizenProfile.lastname);
}

// ============================================
// EVIDENCE
// ============================================

function loadEvidence() {
    postData('police_getEvidence', {}).then(data => {
        if (data) {
            displayEvidence(data.evidence || []);
            document.getElementById('evidence-stored').textContent = data.stats?.stored || 0;
            document.getElementById('evidence-analysis').textContent = data.stats?.in_analysis || 0;
        }
    });
}

function displayEvidence(evidence) {
    const container = document.getElementById('evidenceList');
    if (!evidence || evidence.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucune preuve enregistrée</p>';
        return;
    }

    container.innerHTML = evidence.map(item => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${item.evidence_number} - ${item.item_type}</span>
                <span class="list-item-badge badge-${item.status === 'stored' ? 'low' : 'medium'}">${item.status.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Description:</strong> ${item.item_description}<br>
                <strong>Saisi de:</strong> ${item.seized_from_name || 'N/A'} | <strong>Stockage:</strong> ${item.storage_location}<br>
                <small>Par: ${item.officer_name} | ${item.logged_date}</small>
            </div>
        </div>
    `).join('');
}

function logEvidence() {
    openModal('createEvidenceModal');
}

// ============================================
// PPA - WEAPON PERMITS
// ============================================

function loadPPA() {
    postData('police_getPPA', {}).then(ppa => {
        displayPPA(ppa || []);
    });
}

function displayPPA(ppa) {
    const container = document.getElementById('ppaList');
    if (!ppa || ppa.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun PPA délivré</p>';
        return;
    }

    container.innerHTML = ppa.map(permit => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${permit.permit_number} - ${permit.citizen_name}</span>
                <span class="list-item-badge badge-${permit.status === 'active' ? 'low' : permit.status === 'expired' ? 'medium' : 'high'}">${permit.status.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Type:</strong> ${permit.permit_type} | <strong>Classe:</strong> ${permit.permit_class || 'Standard'}<br>
                <strong>Validité:</strong> jusqu'au ${permit.expiry_date}<br>
                <small>Délivré par: ${permit.issued_by_name} | ${permit.issued_date}</small>
            </div>
        </div>
    `).join('');
}

function filterPPA(status) {
    const buttons = document.querySelectorAll('#tab-ppa .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getPPA', {status: status === 'all' ? null : status}).then(ppa => {
        displayPPA(ppa || []);
    });
}

function issuePPA() {
    // TODO: Implement PPA issuance modal
    alert('Délivrance PPA - À implémenter avec modal dédié');
}

// ============================================
// PPA HEAVY
// ============================================

function loadPPAHeavy() {
    postData('police_getPPAHeavy', {}).then(ppa => {
        displayPPAHeavy(ppa || []);
    });
}

function displayPPAHeavy(ppa) {
    const container = document.getElementById('ppaHeavyList');
    if (!ppa || ppa.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun PPA Lourd délivré</p>';
        return;
    }

    container.innerHTML = ppa.map(permit => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${permit.permit_number} - ${permit.citizen_name}</span>
                <span class="list-item-badge badge-${permit.status === 'approved' ? 'low' : permit.status === 'pending' ? 'medium' : 'high'}">${permit.status.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Catégorie:</strong> ${permit.weapon_category}<br>
                <strong>Justification:</strong> ${permit.justification}<br>
                <strong>Validité:</strong> jusqu'au ${permit.expiry_date}<br>
                <small>Délivré par: ${permit.issued_by_name} | ${permit.issued_date}</small>
            </div>
        </div>
    `).join('');
}

function filterPPAHeavy(status) {
    const buttons = document.querySelectorAll('#tab-ppa-heavy .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getPPAHeavy', {status: status === 'all' ? null : status}).then(ppa => {
        displayPPAHeavy(ppa || []);
    });
}

function issuePPAHeavy() {
    // TODO: Implement PPA Heavy issuance modal
    alert('Délivrance PPA Lourd - À implémenter avec modal dédié');
}

// ============================================
// STOLEN VEHICLES
// ============================================

function loadVehicles() {
    postData('police_getStolenVehicles', {}).then(data => {
        if (data) {
            displayVehicles(data.vehicles || []);
            document.getElementById('vehicles-stolen').textContent = data.stats?.stolen || 0;
            document.getElementById('vehicles-recovered').textContent = data.stats?.recovered || 0;
        }
    });
}

function displayVehicles(vehicles) {
    const container = document.getElementById('vehiclesList');
    if (!vehicles || vehicles.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun véhicule volé</p>';
        return;
    }

    container.innerHTML = vehicles.map(vehicle => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${vehicle.plate} - ${vehicle.model}</span>
                <span class="list-item-badge badge-${vehicle.status === 'stolen' ? 'high' : 'low'}">${vehicle.status.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Propriétaire:</strong> ${vehicle.owner_name}<br>
                <strong>Signalé:</strong> ${vehicle.reported_date} | <strong>Par:</strong> ${vehicle.reported_by_name}<br>
                <small>${vehicle.notes || 'Aucune note'}</small>
            </div>
        </div>
    `).join('');
}

function reportStolenVehicle() {
    // TODO: Implement stolen vehicle report modal
    alert('Signalement vol véhicule - À implémenter avec modal dédié');
}

// ============================================
// INTEL
// ============================================

function loadIntel() {
    postData('police_getIntel', {}).then(intel => {
        displayIntel(intel || []);
    });
}

function displayIntel(intel) {
    const container = document.getElementById('intelList');
    if (!intel || intel.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun renseignement</p>';
        return;
    }

    container.innerHTML = intel.map(item => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${item.title}</span>
                <span class="list-item-badge badge-${item.confidentiality_level === 'top_secret' ? 'high' : item.confidentiality_level === 'confidential' ? 'medium' : 'low'}">${item.confidentiality_level.toUpperCase()}</span>
            </div>
            <div class="list-item-body">
                <strong>Type:</strong> ${item.intel_type} | <strong>Source:</strong> ${item.source_type}<br>
                <strong>Détails:</strong> ${item.intel_details.substring(0, 150)}...<br>
                <small>Par: ${item.created_by_name} | ${item.created_date}</small>
            </div>
        </div>
    `).join('');
}

function filterIntel(filter) {
    const buttons = document.querySelectorAll('#tab-intel .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    postData('police_getIntel', {filter: filter}).then(intel => {
        displayIntel(intel || []);
    });
}

function createIntel() {
    // TODO: Implement intel creation modal
    alert('Création renseignement - À implémenter avec modal dédié');
}

// ============================================
// UNITS
// ============================================

function loadUnits() {
    postData('police_getUnits', {}).then(data => {
        if (data) {
            displayUnits(data.units || []);
            document.getElementById('units-available').textContent = data.stats?.available || 0;
            document.getElementById('units-busy').textContent = data.stats?.busy || 0;
            document.getElementById('units-enroute').textContent = data.stats?.enroute || 0;
        }
    });
}

function displayUnits(units) {
    const container = document.getElementById('unitsList');
    if (!units || units.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucune unité active</p>';
        return;
    }

    container.innerHTML = units.map(unit => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${unit.unit_callsign} - ${unit.unit_type}</span>
                <span class="list-item-badge badge-${unit.status === '10-8' ? 'low' : unit.status === '10-6' ? 'medium' : 'high'}">${unit.status}</span>
            </div>
            <div class="list-item-body">
                <strong>Officiers:</strong> ${unit.officers_count || 1}<br>
                <strong>Dernière position:</strong> ${unit.last_location || 'Inconnu'}<br>
                <small>Actif depuis: ${unit.active_since}</small>
            </div>
        </div>
    `).join('');
}

function createUnit() {
    // TODO: Implement unit creation modal
    alert('Création unité - À implémenter avec modal dédié');
}

// ============================================
// CHARGES LIBRARY
// ============================================

function loadChargesLibrary() {
    postData('police_getCharges', {}).then(charges => {
        allCharges = charges || [];
        displayChargesLibrary(allCharges);
    });
}

function displayChargesLibrary(charges) {
    const container = document.getElementById('chargesLibraryList');
    if (!charges || charges.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucune charge</p>';
        return;
    }

    container.innerHTML = charges.map(charge => `
        <div class="record-item">
            <strong>${charge.charge_code}</strong> - ${charge.charge_title}<br>
            <small>
                Classe: ${charge.charge_class} |
                Jail: ${charge.jail_time_months || 0} mois |
                Fine: $${charge.fine_min}-$${charge.fine_max}
            </small>
        </div>
    `).join('');
}

function searchChargesLibrary() {
    const query = document.getElementById('chargeLibrarySearch').value.toLowerCase();
    const filtered = allCharges.filter(c =>
        c.charge_title.toLowerCase().includes(query) ||
        c.charge_code.toLowerCase().includes(query)
    );
    displayChargesLibrary(filtered);
}

function filterChargesLib(chargeClass) {
    const buttons = document.querySelectorAll('#tab-charges .filter-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    if (chargeClass === 'all') {
        displayChargesLibrary(allCharges);
    } else {
        const filtered = allCharges.filter(c => c.charge_class === chargeClass);
        displayChargesLibrary(filtered);
    }
}

// ============================================
// PERSONNEL
// ============================================

function loadPersonnel() {
    postData('police_getPersonnel', {}).then(data => {
        if (data) {
            displayPersonnel(data.personnel || []);
            document.getElementById('personnel-on-duty').textContent = data.stats?.on_duty || 0;
            document.getElementById('personnel-active-units').textContent = data.stats?.active_units || 0;
            document.getElementById('personnel-active-calls').textContent = data.stats?.active_calls || 0;
        }
    });
}

function displayPersonnel(personnel) {
    const container = document.getElementById('personnelList');
    if (!personnel || personnel.length === 0) {
        container.innerHTML = '<p style="color: #94a3b8; text-align: center; padding: 20px;">Aucun personnel en service</p>';
        return;
    }

    container.innerHTML = personnel.map(officer => `
        <div class="list-item">
            <div class="list-item-header">
                <span class="list-item-title">${officer.name} - ${officer.rank}</span>
                <span class="list-item-badge badge-low">EN SERVICE</span>
            </div>
            <div class="list-item-body">
                <strong>Badge:</strong> ${officer.badge_number} | <strong>Grade:</strong> ${officer.grade}<br>
                <strong>Unité:</strong> ${officer.unit_callsign || 'Aucune'}<br>
                <small>En service depuis: ${officer.duty_start_time}</small>
            </div>
        </div>
    `).join('');
}

// ============================================
// CITIZEN PROFILE
// ============================================

function viewCitizenProfile(identifier) {
    postData('police_getCitizenProfile', {identifier: identifier}).then(profile => {
        if (profile) {
            currentCitizenProfile = profile;
            displayCitizenProfile(profile);
            openModal('citizenProfileModal');
        }
    });
}

function displayCitizenProfile(profile) {
    document.getElementById('profileName').textContent = `${profile.firstname} ${profile.lastname}`;
    document.getElementById('profileDOB').textContent = `DOB: ${profile.dateofbirth || 'N/A'} | ${profile.sex === 'M' ? 'Male' : 'Female'}`;
    document.getElementById('profilePhone').textContent = `Phone: ${profile.phone_number || 'N/A'}`;

    // Info Tab
    let infoHTML = `
        <div class="profile-stats">
            <div class="profile-stat">
                <i class="fa-solid fa-handcuffs"></i>
                <span>Arrests: ${profile.arrests?.length || 0}</span>
            </div>
            <div class="profile-stat">
                <i class="fa-solid fa-file-invoice-dollar"></i>
                <span>Citations: ${profile.citations?.length || 0}</span>
            </div>
            <div class="profile-stat">
                <i class="fa-solid fa-car"></i>
                <span>Vehicles: ${profile.vehicles?.length || 0}</span>
            </div>
        </div>
        <div class="record-item">
            <strong>Job:</strong> ${profile.job || 'Unemployed'} (Grade ${profile.job_grade || 0})<br>
            <strong>Bank:</strong> $${profile.bank || 0}<br>
        </div>
    `;
    document.getElementById('profileInfoContent').innerHTML = infoHTML;

    // Criminal Tab
    let criminalHTML = profile.arrests && profile.arrests.length > 0
        ? profile.arrests.map(arrest => `
            <div class="record-item">
                <strong>${arrest.arrest_number}</strong><br>
                <small>Date: ${arrest.arrest_date} | Charges: ${arrest.charge_count} | Fine: $${arrest.total_fine}</small>
            </div>
        `).join('')
        : '<p style="color: #94a3b8; text-align: center;">Aucun casier</p>';
    document.getElementById('profileCriminalContent').innerHTML = criminalHTML;

    // Citations Tab
    let citationsHTML = profile.citations && profile.citations.length > 0
        ? profile.citations.map(citation => `
            <div class="record-item">
                <strong>${citation.citation_number}</strong> - ${citation.violation_code}<br>
                <small>Amount: $${citation.fine_amount} | Status: ${citation.payment_status}</small>
            </div>
        `).join('')
        : '<p style="color: #94a3b8; text-align: center;">Aucune citation</p>';
    document.getElementById('profileCitationsContent').innerHTML = citationsHTML;

    // Notes Tab
    let notesHTML = profile.notes && profile.notes.length > 0
        ? profile.notes.map(note => `
            <div class="note-item note-${note.note_type}">
                <strong>${note.note_type.toUpperCase()}</strong> - ${note.note_text}<br>
                <small>By: ${note.officer_name} | ${note.created_at}</small>
            </div>
        `).join('')
        : '<p style="color: #94a3b8; text-align: center;">Aucune note</p>';
    document.getElementById('profileNotesContent').innerHTML = notesHTML;

    // Vehicles Tab
    let vehiclesHTML = profile.vehicles && profile.vehicles.length > 0
        ? profile.vehicles.map(vehicle => `
            <div class="record-item">
                <strong>${vehicle.plate}</strong> - ${vehicle.vehicle}<br>
                <small>Status: ${vehicle.stored ? 'Garé' : 'Sorti'}</small>
            </div>
        `).join('')
        : '<p style="color: #94a3b8; text-align: center;">Aucun véhicule</p>';
    document.getElementById('profileVehiclesContent').innerHTML = vehiclesHTML;

    // Licenses Tab
    let licensesHTML = profile.ppa && profile.ppa.length > 0
        ? profile.ppa.map(license => `
            <div class="record-item">
                <strong>${license.permit_number}</strong> - ${license.permit_type}<br>
                <small>Status: ${license.status} | Expires: ${license.expiry_date}</small>
            </div>
        `).join('')
        : '<p style="color: #94a3b8; text-align: center;">Aucune licence</p>';
    document.getElementById('profileLicensesContent').innerHTML = licensesHTML;
}

// Profile tabs switching
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.profile-tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const tab = btn.dataset.profileTab;

            document.querySelectorAll('.profile-tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.profile-tab-panel').forEach(p => p.classList.remove('active'));

            btn.classList.add('active');
            document.getElementById('profile-' + tab).classList.add('active');
        });
    });
});

// ============================================
// CHARGES SELECTOR
// ============================================

function openChargesSelector() {
    openModal('chargesSelectorModal');
    if (allCharges.length === 0) {
        loadChargesForSelector();
    } else {
        displayChargesSelector(allCharges);
    }
}

function loadChargesForSelector() {
    postData('police_getCharges', {}).then(charges => {
        allCharges = charges || [];
        displayChargesSelector(allCharges);
    });
}

function displayChargesSelector(charges) {
    const container = document.getElementById('chargesListContainer');
    container.innerHTML = charges.map(charge => `
        <div class="charge-item">
            <input type="checkbox" id="charge_${charge.id}" value="${charge.id}">
            <label for="charge_${charge.id}">
                <strong>${charge.charge_code}</strong> - ${charge.charge_title}
                <br><small>Class: ${charge.charge_class} | Jail: ${charge.jail_time_months || 0} mois | Fine: $${charge.fine_min}-$${charge.fine_max}</small>
            </label>
        </div>
    `).join('');
}

function filterCharges() {
    const search = document.getElementById('chargesSearch').value.toLowerCase();
    const filtered = allCharges.filter(c =>
        c.charge_title.toLowerCase().includes(search) ||
        c.charge_code.toLowerCase().includes(search)
    );
    displayChargesSelector(filtered);
}

function confirmChargesSelection() {
    const checkboxes = document.querySelectorAll('#chargesListContainer input[type="checkbox"]:checked');
    selectedCharges = [];

    checkboxes.forEach(checkbox => {
        const chargeId = checkbox.value;
        const charge = allCharges.find(c => c.id == chargeId);
        if (charge) {
            selectedCharges.push(charge);
        }
    });

    displaySelectedCharges();
    closeModal('chargesSelectorModal');
}

function displaySelectedCharges() {
    const container = document.getElementById('selectedCharges');
    container.innerHTML = selectedCharges.map((charge, index) => `
        <div class="selected-charge">
            <span><strong>${charge.charge_code}</strong> - ${charge.charge_title}</span>
            <button type="button" onclick="removeCharge(${index})">&times;</button>
        </div>
    `).join('');
}

function removeCharge(index) {
    selectedCharges.splice(index, 1);
    displaySelectedCharges();
}

// ============================================
// NOTES
// ============================================

function addCitizenNote() {
    openModal('addNoteModal');
}

// ============================================
// NEARBY PLAYERS
// ============================================

function loadNearbyPlayers(type) {
    postData('police_getNearbyPlayers', {}).then(players => {
        const selectId = type === 'arrest' ? 'arrestSuspect' : 'citationTarget';
        const select = document.getElementById(selectId);
        select.innerHTML = '<option value="">Sélectionner...</option>';

        (players || []).forEach(player => {
            const option = document.createElement('option');
            option.value = player.identifier;
            option.textContent = `${player.name} (${player.distance}m)`;
            option.dataset.name = player.name;
            select.appendChild(option);
        });
    });
}

// ============================================
// PANIC BUTTON
// ============================================

function triggerPanic() {
    postData('police_panicButton', {}).then(result => {
        if (result && result.success) {
            alert('Signal de détresse envoyé à toutes les unités!');
        } else {
            alert(result?.message || 'Erreur lors de l\'envoi du signal');
        }
    });
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

// ============================================
// MODAL FUNCTIONS
// ============================================

function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('show');
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('show');
        const form = modal.querySelector('form');
        if (form) {
            form.reset();
        }
    }
}

// Close modal when clicking outside
document.addEventListener('click', (e) => {
    if (e.target.classList.contains('modal')) {
        e.target.classList.remove('show');
    }
});

// ============================================
// FORM SUBMISSIONS
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    // Create Call Form
    const createCallForm = document.getElementById('createCallForm');
    if (createCallForm) {
        createCallForm.addEventListener('submit', (e) => {
            e.preventDefault();

            const data = {
                call_type: document.getElementById('callType').value,
                priority: document.getElementById('callPriority').value,
                location: document.getElementById('callLocation').value,
                description: document.getElementById('callDescription').value
            };

            postData('police_createCall', data).then(result => {
                if (result && result.success) {
                    closeModal('createCallModal');
                    loadCalls();
                }
            });
        });
    }

    // Create Report Form
    const createReportForm = document.getElementById('createReportForm');
    if (createReportForm) {
        createReportForm.addEventListener('submit', (e) => {
            e.preventDefault();

            const data = {
                report_type: document.getElementById('reportType').value,
                title: document.getElementById('reportTitle').value,
                location: document.getElementById('reportLocation').value,
                description: document.getElementById('reportDescription').value,
                confidentiality: document.getElementById('reportConfidentiality').value
            };

            postData('police_createReport', data).then(result => {
                if (result && result.success) {
                    closeModal('createReportModal');
                    loadReports();
                }
            });
        });
    }

    // Create BOLO Form
    const createBOLOForm = document.getElementById('createBOLOForm');
    if (createBOLOForm) {
        createBOLOForm.addEventListener('submit', (e) => {
            e.preventDefault();

            const data = {
                bolo_type: document.getElementById('boloType').value,
                subject: document.getElementById('boloSubject').value,
                priority: document.getElementById('boloPriority').value,
                danger_level: document.getElementById('boloDangerLevel').value,
                description: document.getElementById('boloDescription').value,
                is_armed: document.getElementById('boloArmed').checked ? 1 : 0
            };

            postData('police_createBOLO', data).then(result => {
                if (result && result.success) {
                    closeModal('createBOLOModal');
                    loadBOLO();
                }
            });
        });
    }

    // Create Arrest Form
    const createArrestForm = document.getElementById('createArrestForm');
    if (createArrestForm) {
        createArrestForm.addEventListener('submit', (e) => {
            e.preventDefault();

            const suspectSelect = document.getElementById('arrestSuspect');
            const selectedOption = suspectSelect.options[suspectSelect.selectedIndex];

            const data = {
                citizen_identifier: suspectSelect.value,
                citizen_name: selectedOption.dataset.name,
                location: document.getElementById('arrestLocation').value,
                charges: selectedCharges,
                miranda_read: document.getElementById('arrestMiranda').checked ? 1 : 0,
                notes: document.getElementById('arrestNotes').value
            };

            postData('police_createArrest', data).then(result => {
                if (result && result.success) {
                    closeModal('createArrestModal');
                    selectedCharges = [];
                    loadArrests();
                }
            });
        });
    }

    // Create Citation Form
    const createCitationForm = document.getElementById('createCitationForm');
    if (createCitationForm) {
        createCitationForm.addEventListener('submit', (e) => {
            e.preventDefault();

            const targetSelect = document.getElementById('citationTarget');
            const selectedOption = targetSelect.options[targetSelect.selectedIndex];

            const data = {
                citizen_identifier: targetSelect.value,
                citizen_name: selectedOption.dataset.name,
                violation_code: document.getElementById('citationViolationType').value,
                violation_description: document.getElementById('citationDescription').value,
                fine_amount: parseFloat(document.getElementById('citationAmount').value),
                points: parseInt(document.getElementById('citationPoints').value) || 0,
                location: document.getElementById('citationLocation').value
            };

            postData('police_createCitation', data).then(result => {
                if (result && result.success) {
                    closeModal('createCitationModal');
                    loadCitations();
                }
            });
        });
    }

    // Create Evidence Form
    const createEvidenceForm = document.getElementById('createEvidenceForm');
    if (createEvidenceForm) {
        createEvidenceForm.addEventListener('submit', (e) => {
            e.preventDefault();

            const data = {
                item_type: document.getElementById('evidenceType').value,
                item_description: document.getElementById('evidenceDescription').value,
                quantity: parseInt(document.getElementById('evidenceQuantity').value),
                seized_from: document.getElementById('evidenceSeizedFrom').value,
                seized_location: document.getElementById('evidenceLocation').value,
                storage_location: document.getElementById('evidenceStorage').value
            };

            postData('police_createEvidence', data).then(result => {
                if (result && result.success) {
                    closeModal('createEvidenceModal');
                    loadEvidence();
                }
            });
        });
    }

    // Add Note Form
    const addNoteForm = document.getElementById('addNoteForm');
    if (addNoteForm) {
        addNoteForm.addEventListener('submit', (e) => {
            e.preventDefault();

            if (!currentCitizenProfile) return;

            const data = {
                citizen_identifier: currentCitizenProfile.identifier,
                note_text: document.getElementById('noteText').value,
                note_type: document.getElementById('noteType').value,
                is_flagged: document.getElementById('noteFlagged').checked ? 1 : 0
            };

            postData('police_addCitizenNote', data).then(result => {
                if (result && result.success) {
                    closeModal('addNoteModal');
                    viewCitizenProfile(currentCitizenProfile.identifier);
                }
            });
        });
    }
});

console.log('[ZX POLICE MDT] UI Loaded - 17 Tabs Operational');
