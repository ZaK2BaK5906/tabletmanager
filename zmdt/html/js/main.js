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
    openModal('createCallModal');
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

function quickSearchVehicle() {
    const query = document.getElementById('vehicleQuickSearch').value;
    if (!query) return;

    postData('police_searchVehicle', {query: query});
}

// ============================================
// POLICE - REPORTS
// ============================================

function createReport() {
    openModal('createReportModal');
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
    openModal('createBOLOModal');
}

// ============================================
// POLICE - ARRESTS
// ============================================

function createArrest() {
    // Load nearby players first
    loadNearbyPlayers('arrest');
    openModal('createArrestModal');
}

function loadNearbyPlayers(type) {
    fetch(`https://${GetParentResourceName()}/police_getNearbyPlayers`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(players => {
        const selectId = type === 'arrest' ? 'arrestSuspect' : 'citationTarget';
        const select = document.getElementById(selectId);
        select.innerHTML = '<option value="">Sélectionner...</option>';

        players.forEach(player => {
            const option = document.createElement('option');
            option.value = player.identifier;
            option.textContent = `${player.name} (${player.distance}m)`;
            option.dataset.name = player.name;
            select.appendChild(option);
        });
    });
}

// ============================================
// POLICE - CITATIONS
// ============================================

function createCitation() {
    loadNearbyPlayers('citation');
    openModal('createCitationModal');
}

// ============================================
// POLICE - EVIDENCE
// ============================================

function logEvidence() {
    openModal('createEvidenceModal');
}

// ============================================
// POLICE - CHARGES SELECTOR
// ============================================

let allCharges = [];
let selectedCharges = [];

function openChargesSelector() {
    openModal('chargesSelectorModal');
    loadCharges();
}

function loadCharges() {
    fetch(`https://${GetParentResourceName()}/police_getCharges`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(charges => {
        allCharges = charges;
        displayCharges(charges);
    });
}

function displayCharges(charges) {
    const container = document.getElementById('chargesListContainer');
    container.innerHTML = '';

    charges.forEach(charge => {
        const div = document.createElement('div');
        div.className = 'charge-item';
        div.innerHTML = `
            <input type="checkbox" id="charge_${charge.id}" value="${charge.id}">
            <label for="charge_${charge.id}">
                <strong>${charge.charge_code}</strong> - ${charge.charge_title}
                <br><small>Class: ${charge.charge_class} | Jail: ${charge.jail_time_months || 0} mois | Fine: $${charge.fine_min}-$${charge.fine_max}</small>
            </label>
        `;
        container.appendChild(div);
    });
}

function filterCharges() {
    const search = document.getElementById('chargesSearch').value.toLowerCase();
    const filtered = allCharges.filter(c =>
        c.charge_title.toLowerCase().includes(search) ||
        c.charge_code.toLowerCase().includes(search)
    );
    displayCharges(filtered);
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
    container.innerHTML = '';

    selectedCharges.forEach((charge, index) => {
        const div = document.createElement('div');
        div.className = 'selected-charge';
        div.innerHTML = `
            <span><strong>${charge.charge_code}</strong> - ${charge.charge_title}</span>
            <button type="button" onclick="removeCharge(${index})">&times;</button>
        `;
        container.appendChild(div);
    });
}

function removeCharge(index) {
    selectedCharges.splice(index, 1);
    displaySelectedCharges();
}

// ============================================
// POLICE - CITIZEN PROFILE
// ============================================

let currentCitizenProfile = null;

function viewCitizenProfile(identifier) {
    fetch(`https://${GetParentResourceName()}/police_getCitizenProfile`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({identifier: identifier})
    })
    .then(resp => resp.json())
    .then(profile => {
        currentCitizenProfile = profile;
        displayCitizenProfile(profile);
        openModal('citizenProfileModal');
    });
}

function displayCitizenProfile(profile) {
    // Header
    document.getElementById('profileName').textContent = `${profile.firstname} ${profile.lastname}`;
    document.getElementById('profileDOB').textContent = `DOB: ${profile.dateofbirth} | ${profile.sex === 'M' ? 'Male' : 'Female'}`;
    document.getElementById('profilePhone').textContent = `Phone: ${profile.phone_number || 'N/A'}`;

    // Info Tab
    let infoHTML = `
        <div class="profile-stats">
            <div class="profile-stat">
                <i class="fa-solid fa-handcuffs"></i>
                <span>Criminal Charges: ${profile.criminal_history?.length || 0}</span>
            </div>
            <div class="profile-stat">
                <i class="fa-solid fa-file-invoice-dollar"></i>
                <span>Pending Citations: ${profile.citations?.filter(c => c.payment_status === 'unpaid').length || 0}</span>
            </div>
            <div class="profile-stat">
                <i class="fa-solid fa-car"></i>
                <span>Owned Vehicles: ${profile.vehicles?.length || 0}</span>
            </div>
        </div>
    `;
    document.getElementById('profileInfoContent').innerHTML = infoHTML;

    // Criminal Tab
    let criminalHTML = profile.criminal_history && profile.criminal_history.length > 0
        ? profile.criminal_history.map(record => `
            <div class="record-item">
                <strong>${record.charge_code}</strong> - ${record.charge_title}
                <br><small>Date: ${record.arrest_date} | Class: ${record.charge_class} | Status: ${record.status}</small>
            </div>
        `).join('')
        : '<p>No criminal history</p>';
    document.getElementById('profileCriminalContent').innerHTML = criminalHTML;

    // Citations Tab
    let citationsHTML = profile.citations && profile.citations.length > 0
        ? profile.citations.map(citation => `
            <div class="record-item">
                <strong>${citation.citation_number}</strong> - ${citation.violation_description}
                <br><small>Amount: $${citation.fine_amount} | Status: ${citation.payment_status}</small>
            </div>
        `).join('')
        : '<p>No citations</p>';
    document.getElementById('profileCitationsContent').innerHTML = citationsHTML;

    // Notes Tab
    let notesHTML = profile.notes && profile.notes.length > 0
        ? profile.notes.map(note => `
            <div class="note-item note-${note.note_type}">
                <strong>${note.note_type.toUpperCase()}</strong> - ${note.note_text}
                <br><small>By: ${note.firstname} ${note.lastname} | ${note.created_at}</small>
            </div>
        `).join('')
        : '<p>No notes</p>';
    document.getElementById('profileNotesContent').innerHTML = notesHTML;

    // Vehicles Tab
    let vehiclesHTML = profile.vehicles && profile.vehicles.length > 0
        ? profile.vehicles.map(vehicle => `
            <div class="record-item">
                <strong>${vehicle.plate}</strong> - ${vehicle.vehicle}
                <br><small>Status: ${vehicle.stored ? 'Stored' : 'Out'} | Location: ${vehicle.parking || 'Unknown'}</small>
            </div>
        `).join('')
        : '<p>No registered vehicles</p>';
    document.getElementById('profileVehiclesContent').innerHTML = vehiclesHTML;

    // Licenses Tab
    let licensesHTML = profile.licenses && profile.licenses.length > 0
        ? profile.licenses.map(license => `
            <div class="record-item">
                <strong>${license.license_type}</strong>
                <br><small>Status: ${license.status} | Expires: ${license.expiry_date || 'N/A'}</small>
            </div>
        `).join('')
        : '<p>No licenses</p>';
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
// POLICE - NOTES
// ============================================

function addCitizenNote() {
    openModal('addNoteModal');
}

// ============================================
// POLICE - SEARCH RESULTS
// ============================================

function displaySearchResults(results, type) {
    const container = document.getElementById('searchResults');
    container.innerHTML = '';

    if (!results || results.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #94a3b8;">No results found</p>';
        return;
    }

    results.forEach(result => {
        const div = document.createElement('div');
        div.className = 'search-result-item';

        if (type === 'citizen') {
            div.innerHTML = `
                <div class="result-header">
                    <h4>${result.firstname} ${result.lastname}</h4>
                    ${result.is_wanted ? '<span class="badge badge-high">WANTED</span>' : ''}
                    ${result.flagged_notes > 0 ? '<span class="badge badge-medium">FLAGGED</span>' : ''}
                </div>
                <div class="result-body">
                    <p>DOB: ${result.dateofbirth} | Phone: ${result.phone_number || 'N/A'}</p>
                    <p>Criminal Charges: ${result.criminal_charges} | Unpaid Fines: $${result.total_unpaid_fines || 0}</p>
                    <button onclick="viewCitizenProfile('${result.identifier}')">View Profile</button>
                </div>
            `;
        } else if (type === 'vehicle') {
            div.innerHTML = `
                <div class="result-header">
                    <h4>${result.plate} - ${result.vehicle}</h4>
                    ${result.is_stolen ? '<span class="badge badge-high">STOLEN</span>' : ''}
                    ${result.has_bolo ? '<span class="badge badge-medium">BOLO</span>' : ''}
                </div>
                <div class="result-body">
                    <p>Owner: ${result.firstname} ${result.lastname}</p>
                    <p>Status: ${result.stored ? 'Stored' : 'Out'} | Citations: ${result.unpaid_citations || 0}</p>
                </div>
            `;
        } else if (type === 'weapon') {
            div.innerHTML = `
                <div class="result-header">
                    <h4>${result.serial_number}</h4>
                    <span class="badge badge-${result.legal_status === 'illegal' ? 'high' : 'low'}">${result.legal_status}</span>
                </div>
                <div class="result-body">
                    <p>Type: ${result.weapon_type} | Make: ${result.make || 'Unknown'} | Model: ${result.model || 'Unknown'}</p>
                    <p>Owner: ${result.firstname} ${result.lastname}</p>
                </div>
            `;
        }

        container.appendChild(div);
    });
}

// Update search functions to display results
const originalSearchCitizen = searchCitizen;
function searchCitizen() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    fetch(`https://${GetParentResourceName()}/police_searchCitizen`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({query: query})
    })
    .then(resp => resp.json())
    .then(results => displaySearchResults(results, 'citizen'));
}

const originalSearchVehicle = searchVehicle;
function searchVehicle() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    fetch(`https://${GetParentResourceName()}/police_searchVehicle`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({query: query})
    })
    .then(resp => resp.json())
    .then(results => displaySearchResults(results, 'vehicle'));
}

const originalSearchWeapon = searchWeapon;
function searchWeapon() {
    const query = document.getElementById('searchInput').value;
    if (!query) return;

    fetch(`https://${GetParentResourceName()}/police_searchWeapon`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({query: query})
    })
    .then(resp => resp.json())
    .then(results => displaySearchResults(results, 'weapon'));
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
        // Reset form if exists
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

// Create Call Form
document.addEventListener('DOMContentLoaded', () => {
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

            postData('police_createCall', data);
            closeModal('createCallModal');
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
                suspect: document.getElementById('reportSuspect').value,
                location: document.getElementById('reportLocation').value,
                description: document.getElementById('reportDescription').value,
                confidentiality: document.getElementById('reportConfidentiality').value
            };

            postData('police_createReport', data);
            closeModal('createReportModal');
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
                description: document.getElementById('boloDescription').value,
                is_armed: document.getElementById('boloArmed').checked
            };

            postData('police_createBOLO', data);
            closeModal('createBOLOModal');
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
                identifier: suspectSelect.value,
                citizen_name: selectedOption.dataset.name,
                location: document.getElementById('arrestLocation').value,
                charges: selectedCharges,
                miranda_read: document.getElementById('arrestMiranda').checked ? 1 : 0,
                notes: document.getElementById('arrestNotes').value
            };

            postData('police_createArrest', data);
            closeModal('createArrestModal');
            selectedCharges = [];
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
                identifier: targetSelect.value,
                citizen_name: selectedOption.dataset.name,
                violation_code: document.getElementById('citationViolationType').value,
                violation_description: document.getElementById('citationDescription').value,
                fine_amount: parseFloat(document.getElementById('citationAmount').value),
                points: parseInt(document.getElementById('citationPoints').value) || 0,
                location: document.getElementById('citationLocation').value
            };

            postData('police_createCitation', data);
            closeModal('createCitationModal');
        });
    }

    // Create Evidence Form
    const createEvidenceForm = document.getElementById('createEvidenceForm');
    if (createEvidenceForm) {
        createEvidenceForm.addEventListener('submit', (e) => {
            e.preventDefault();

            const data = {
                item_type: document.getElementById('evidenceType').value,
                description: document.getElementById('evidenceDescription').value,
                quantity: parseInt(document.getElementById('evidenceQuantity').value),
                seized_from: document.getElementById('evidenceSeizedFrom').value,
                seized_location: document.getElementById('evidenceLocation').value,
                storage_location: document.getElementById('evidenceStorage').value
            };

            postData('police_createEvidence', data);
            closeModal('createEvidenceModal');
        });
    }

    // Add Note Form
    const addNoteForm = document.getElementById('addNoteForm');
    if (addNoteForm) {
        addNoteForm.addEventListener('submit', (e) => {
            e.preventDefault();

            if (!currentCitizenProfile) return;

            const data = {
                identifier: currentCitizenProfile.identifier,
                note_text: document.getElementById('noteText').value,
                note_type: document.getElementById('noteType').value,
                is_flagged: document.getElementById('noteFlagged').checked ? 1 : 0
            };

            postData('police_addCitizenNote', data);
            closeModal('addNoteModal');
        });
    }
});

console.log('[ZMDT] UI loaded');
