let employmentData = {
    companies: [],
    isBoss: false,
    currentJob: '',
    currentJobLabel: '',
    isRecruiting: false,
    applications: [],
    currentApplicationStatus: 'all',
    selectedCompany: null
};

// Communication avec FiveM
function postData(endpoint, data) {
    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

// Ouvrir le menu emploi
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'openEmployment') {
        employmentData.companies = data.companies || [];
        employmentData.isBoss = data.isBoss || false;
        employmentData.currentJob = data.currentJob || '';
        employmentData.currentJobLabel = data.currentJobLabel || '';
        employmentData.isRecruiting = data.isRecruiting || false;

        renderCompanies();

        if (employmentData.isBoss) {
            showBossControls();
        }

        document.getElementById('employmentContainer').classList.add('show');
    } else if (data.action === 'closeEmployment') {
        closeEmployment();
    } else if (data.action === 'updateCompanies') {
        employmentData.companies = data.companies || [];

        // Mettre à jour isRecruiting si on est boss
        if (employmentData.isBoss && employmentData.currentJob) {
            const currentCompany = employmentData.companies.find(c => c.job_name === employmentData.currentJob);
            if (currentCompany) {
                employmentData.isRecruiting = currentCompany.is_recruiting;
                updateRecruitmentButton();
            }
        }

        renderCompanies();
    } else if (data.action === 'updateApplications') {
        employmentData.applications = data.applications || [];
        renderApplications();
        updateApplicationsBadge();
    } else if (data.action === 'showNotification') {
        showNotification(data.message, data.type || 'info');
    }
});

// Fermer
function closeEmployment() {
    document.getElementById('employmentContainer').classList.remove('show');
    closeAllModals();
    postData('closeEmployment', {});
}

document.getElementById('closeEmploymentBtn').addEventListener('click', closeEmployment);

// ESC pour fermer
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (document.querySelector('.modal.show')) {
            closeAllModals();
        } else {
            closeEmployment();
        }
    }
});

// Afficher les contrôles patron
function showBossControls() {
    const controls = document.getElementById('bossControls');
    controls.style.display = 'block';

    const btnText = document.getElementById('recruitmentBtnText');
    const btn = document.getElementById('toggleRecruitmentBtn');

    if (employmentData.isRecruiting) {
        btnText.textContent = 'Fermer Recrutement';
        btn.innerHTML = '<i class="fa-solid fa-door-closed"></i> ' + btnText.outerHTML;
    } else {
        btnText.textContent = 'Ouvrir Recrutement';
        btn.innerHTML = '<i class="fa-solid fa-door-open"></i> ' + btnText.outerHTML;
    }

    // Charger les candidatures
    loadApplications();
}

// Render companies
function renderCompanies() {
    const container = document.getElementById('jobList');
    const filter = document.getElementById('filterRecruiting').value;
    const search = document.getElementById('searchInput').value.toLowerCase();

    let companies = employmentData.companies.filter(company => {
        if (filter === 'recruiting' && !company.is_recruiting) return false;
        if (filter === 'closed' && company.is_recruiting) return false;
        if (search && !company.job_label.toLowerCase().includes(search) &&
            !company.description?.toLowerCase().includes(search)) return false;
        return true;
    });

    if (companies.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-icon">🔍</div><div class="empty-text">Aucune entreprise trouvée</div></div>';
        return;
    }

    // Créer le tableau
    let tableHTML = `
        <table class="jobs-table">
            <thead>
                <tr>
                    <th>Logo</th>
                    <th>Entreprise</th>
                    <th>Statut</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
    `;

    companies.forEach(company => {
        const statusClass = company.is_recruiting ? 'status-open' : 'status-closed';
        const statusText = company.is_recruiting ? 'Ouvert' : 'Fermé';
        const photoUrl = company.photo_url || 'https://i.ibb.co/7YMwD6f/default-company.png';

        tableHTML += `
            <tr class="job-row">
                <td class="logo-cell">
                    <img src="${photoUrl}" alt="${company.job_label}" class="company-logo" onerror="this.src='https://i.ibb.co/7YMwD6f/default-company.png'">
                </td>
                <td class="company-cell">
                    <div class="company-name">${company.job_label}</div>
                </td>
                <td class="status-cell">
                    <span class="job-status ${statusClass}">
                        <i class="fa-solid ${company.is_recruiting ? 'fa-circle-check' : 'fa-circle-xmark'}"></i>
                        ${statusText}
                    </span>
                </td>
                <td class="actions-cell">
                    <button class="btn-info" onclick="showJobDetails('${company.job_name}', '${company.job_label.replace(/'/g, "\\'")}')">
                        <i class="fa-solid fa-info-circle"></i> En savoir plus
                    </button>
                    ${company.is_recruiting ? `
                        <button class="btn-apply-table" onclick="openApplyModal('${company.job_name}', '${company.job_label.replace(/'/g, "\\'")}')">
                            <i class="fa-solid fa-paper-plane"></i> Postuler
                        </button>
                    ` : `
                        <button class="btn-apply-table" disabled>
                            <i class="fa-solid fa-lock"></i> Fermé
                        </button>
                    `}
                </td>
            </tr>
        `;
    });

    tableHTML += `
            </tbody>
        </table>
    `;

    container.innerHTML = tableHTML;
}

// Afficher les détails d'un job dans une modal
function showJobDetails(jobName, jobLabel) {
    const company = employmentData.companies.find(c => c.job_name === jobName);
    if (!company) return;

    const modal = document.getElementById('jobDetailsModal');
    const photoUrl = company.photo_url || 'https://i.ibb.co/7YMwD6f/default-company.png';

    document.getElementById('jobDetailsContent').innerHTML = `
        <div class="job-details-header">
            <img src="${photoUrl}" alt="${company.job_label}" class="job-details-logo" onerror="this.src='https://i.ibb.co/7YMwD6f/default-company.png'">
            <div>
                <h3>${company.job_label}</h3>
                <span class="job-status ${company.is_recruiting ? 'status-open' : 'status-closed'}">
                    <i class="fa-solid ${company.is_recruiting ? 'fa-circle-check' : 'fa-circle-xmark'}"></i>
                    ${company.is_recruiting ? 'Recrutement Ouvert' : 'Recrutement Fermé'}
                </span>
            </div>
        </div>
        <div class="job-details-body">
            <div class="detail-section">
                <h4><i class="fa-solid fa-file-lines"></i> Description</h4>
                <p>${company.description || 'Aucune description disponible.'}</p>
            </div>
            ${company.salary_info ? `
                <div class="detail-section">
                    <h4><i class="fa-solid fa-money-bill-wave"></i> Informations Salariales</h4>
                    <p>${company.salary_info}</p>
                </div>
            ` : ''}
        </div>
        ${company.is_recruiting ? `
            <button class="btn-large" onclick="closeModal('jobDetailsModal'); openApplyModal('${company.job_name}', '${company.job_label.replace(/'/g, "\\'")}')">
                <i class="fa-solid fa-paper-plane"></i> Postuler Maintenant
            </button>
        ` : ''}
    `;

    modal.classList.add('show');
}

// Filters
document.getElementById('filterRecruiting').addEventListener('change', renderCompanies);
document.getElementById('searchInput').addEventListener('input', renderCompanies);

// Modal Apply
function openApplyModal(jobName, jobLabel) {
    employmentData.selectedCompany = { job_name: jobName, job_label: jobLabel };

    document.getElementById('applyCompanyPreview').innerHTML = `
        <h3><i class="fa-solid fa-building"></i> ${jobLabel}</h3>
        <p>Vous postulez pour rejoindre cette entreprise</p>
    `;

    document.getElementById('applyModal').classList.add('show');
}

document.getElementById('closeApplyModal').addEventListener('click', () => {
    document.getElementById('applyModal').classList.remove('show');
});

document.getElementById('applyForm').addEventListener('submit', (e) => {
    e.preventDefault();

    const firstName = document.getElementById('applyFirstName').value.trim();
    const lastName = document.getElementById('applyLastName').value.trim();
    const phone = document.getElementById('applyPhone').value.trim();
    const experience = document.getElementById('applyExperience').value.trim();
    const motivation = document.getElementById('applyMotivation').value.trim();

    if (!firstName || !lastName || !phone) {
        showNotification('Veuillez remplir tous les champs obligatoires', 'error');
        return;
    }

    postData('submitApplication', {
        jobName: employmentData.selectedCompany.job_name,
        jobLabel: employmentData.selectedCompany.job_label,
        firstName,
        lastName,
        phoneNumber: phone,
        experience,
        motivation
    });

    // Reset form
    document.getElementById('applyForm').reset();
    document.getElementById('applyModal').classList.remove('show');
});

// Modal Edit Profile (Boss)
document.getElementById('editProfileBtn').addEventListener('click', () => {
    loadCurrentProfile();
    document.getElementById('editProfileModal').classList.add('show');
});

document.getElementById('closeEditProfileModal').addEventListener('click', () => {
    document.getElementById('editProfileModal').classList.remove('show');
});

function loadCurrentProfile() {
    postData('getCompanyProfile', {});
}

window.receiveCompanyProfile = function(profile) {
    if (profile) {
        document.getElementById('editDescription').value = profile.description || '';
        document.getElementById('editSalaryInfo').value = profile.salary_info || '';
    }
};

document.getElementById('editProfileForm').addEventListener('submit', (e) => {
    e.preventDefault();

    const description = document.getElementById('editDescription').value.trim();
    const salaryInfo = document.getElementById('editSalaryInfo').value.trim();

    postData('updateCompanyProfile', {
        description,
        salaryInfo
    });

    document.getElementById('editProfileModal').classList.remove('show');
});

// Toggle Recruitment
document.getElementById('toggleRecruitmentBtn').addEventListener('click', () => {
    postData('toggleRecruitment', {});
});

// Applications
document.getElementById('viewApplicationsBtn').addEventListener('click', () => {
    loadApplications();
    document.getElementById('applicationsModal').classList.add('show');
});

document.getElementById('closeApplicationsModal').addEventListener('click', () => {
    document.getElementById('applicationsModal').classList.remove('show');
});

function loadApplications() {
    postData('getApplications', {});
}

function renderApplications() {
    const container = document.getElementById('applicationsList');
    const filter = employmentData.currentApplicationStatus;

    let apps = employmentData.applications;
    if (filter !== 'all') {
        apps = apps.filter(app => app.status === filter);
    }

    if (apps.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-icon">📭</div><div class="empty-text">Aucune candidature</div></div>';
        return;
    }

    container.innerHTML = '';
    apps.forEach(app => {
        const card = document.createElement('div');
        card.className = 'application-card';

        let statusClass = '';
        let statusIcon = '';
        let statusText = '';

        if (app.status === 'pending') {
            statusClass = 'status-pending';
            statusIcon = '⏳';
            statusText = 'En attente';
        } else if (app.status === 'accepted') {
            statusClass = 'status-accepted';
            statusIcon = '✅';
            statusText = 'Acceptée';
        } else {
            statusClass = 'status-rejected';
            statusIcon = '❌';
            statusText = 'Refusée';
        }

        card.innerHTML = `
            <div class="application-header">
                <div>
                    <h4>${app.first_name} ${app.last_name}</h4>
                    <p class="app-phone"><i class="fa-solid fa-phone"></i> ${app.phone_number}</p>
                </div>
                <span class="app-status ${statusClass}">${statusIcon} ${statusText}</span>
            </div>
            <div class="application-body">
                ${app.experience ? `
                    <div class="app-section">
                        <strong>💼 Expérience:</strong>
                        <p>${app.experience}</p>
                    </div>
                ` : ''}
                ${app.motivation ? `
                    <div class="app-section">
                        <strong>💭 Motivation:</strong>
                        <p>${app.motivation}</p>
                    </div>
                ` : ''}
                <div class="app-date">
                    <i class="fa-solid fa-calendar"></i> ${formatDate(app.created_at)}
                </div>
            </div>
            <div class="application-actions">
                ${app.status === 'pending' ? `
                    <button class="btn-accept" onclick="processApplication(${app.id}, 'accepted')">
                        <i class="fa-solid fa-check"></i> Accepter
                    </button>
                    <button class="btn-reject" onclick="processApplication(${app.id}, 'rejected')">
                        <i class="fa-solid fa-times"></i> Refuser
                    </button>
                ` : ''}
                <button class="btn-delete" onclick="deleteApplication(${app.id})" style="background: #ef4444;">
                    <i class="fa-solid fa-trash"></i> Supprimer
                </button>
            </div>
        `;

        container.appendChild(card);
    });
}

function processApplication(appId, status) {
    postData('processApplication', { applicationId: appId, status });
}

function deleteApplication(appId) {
    postData('deleteApplication', { applicationId: appId });
}

// Application status filter
document.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        employmentData.currentApplicationStatus = btn.dataset.status;
        renderApplications();
    });
});

function updateApplicationsBadge() {
    const pending = employmentData.applications.filter(app => app.status === 'pending').length;
    document.getElementById('applicationsBadge').textContent = pending;

    if (pending > 0) {
        document.getElementById('applicationsBadge').classList.add('has-notifications');
    } else {
        document.getElementById('applicationsBadge').classList.remove('has-notifications');
    }
}

// Utils
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR') + ' ' + date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

function closeAllModals() {
    document.querySelectorAll('.modal').forEach(modal => modal.classList.remove('show'));
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove('show');
}

function showNotification(message, type) {
    // Simple notification (can be enhanced)
    console.log(`[${type.toUpperCase()}] ${message}`);
}

// Message listeners
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'receiveCompanyProfile') {
        receiveCompanyProfile(data.profile);
    } else if (data.action === 'updateRecruitmentStatus') {
        employmentData.isRecruiting = data.isRecruiting;
        updateRecruitmentButton();
    }
});

function updateRecruitmentButton() {
    const btnText = document.getElementById('recruitmentBtnText');
    const btn = document.getElementById('toggleRecruitmentBtn');

    if (employmentData.isRecruiting) {
        btnText.textContent = 'Fermer Recrutement';
        btn.innerHTML = '<i class="fa-solid fa-door-closed"></i> ' + btnText.outerHTML;
    } else {
        btnText.textContent = 'Ouvrir Recrutement';
        btn.innerHTML = '<i class="fa-solid fa-door-open"></i> ' + btnText.outerHTML;
    }

    // Mettre à jour le statut dans la liste des companies
    const currentCompany = employmentData.companies.find(c => c.job_name === employmentData.currentJob);
    if (currentCompany) {
        currentCompany.is_recruiting = employmentData.isRecruiting;
        // Re-render pour mettre à jour l'affichage
        renderCompanies();
    }
}
