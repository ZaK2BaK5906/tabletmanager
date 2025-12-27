let tabletData = {
    job: '',
    userName: '',
    isBoss: false,
    hasAuditAccess: false,
    commission: 0,
    products: [],
    partnerships: [],
    companies: [],
    invoiceItems: [],
    currentDiscount: 0,
    currentPartnership: null,
    invoiceType: 'citizen', // 'citizen' or 'company'
    taxRate: 16.75, // Default, sera mis à jour par le serveur
    nearbyPlayers: [] // Joueurs proches
};

// Utilitaires
function formatCurrency(amount) {
    return parseFloat(amount).toFixed(2) + '€';
}

function formatPercent(value) {
    return parseFloat(value).toFixed(1) + '%';
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR') + ' ' + date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

// Communication avec FiveM
function postData(endpoint, data) {
    fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

// Ouverture/Fermeture
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        openTablet(data);
    } else if (data.action === 'close') {
        closeTablet();
    } else if (data.action === 'updateData') {
        updateTabletData(data);
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeTablet();
    }
});

function openTablet(data) {
    tabletData.job = data.job;
    tabletData.userName = data.userName;
    tabletData.isBoss = data.isBoss;
    tabletData.hasAuditAccess = data.hasAuditAccess || false;
    tabletData.commission = data.commission || 0;
    tabletData.products = data.products || [];
    tabletData.partnerships = data.partnerships || [];
    tabletData.companies = data.companies || [];
    tabletData.taxRate = data.taxRate || 20.0;
    tabletData.nearbyPlayers = data.nearbyPlayers || [];

    document.getElementById('companyName').textContent = data.jobLabel || data.job;
    document.getElementById('userName').textContent = data.userName;
    document.getElementById('quickPercent').textContent = formatPercent(tabletData.commission);

    // Afficher/masquer onglet gestion
    const managementTab = document.getElementById('managementTab');
    if (tabletData.isBoss) {
        managementTab.style.display = 'flex';
    } else {
        managementTab.style.display = 'none';
    }

    // Afficher/masquer onglet audit
    const auditTab = document.getElementById('auditTab');
    if (tabletData.hasAuditAccess) {
        auditTab.style.display = 'flex';
    } else {
        auditTab.style.display = 'none';
    }

    // Charger les produits dans le select
    loadProductsSelect();
    loadPartnershipsSelect();
    loadCompaniesSelect();
    loadNearbyPlayersSelect();

    // Setup invoice type selector
    setupInvoiceTypeSelector();

    // Charger les données initiales
    loadQuickStats();
    loadInvoiceHistory();
    loadStats();

    if (tabletData.isBoss) {
        loadManagementData();
    }

    document.getElementById('tablet').classList.add('show');
}

function closeTablet() {
    document.getElementById('tablet').classList.remove('show');
    postData('close', {});

    // Reset
    resetInvoiceForm();
    switchPage('home');
}

document.getElementById('closeBtn').addEventListener('click', closeTablet);

// Navigation
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const page = btn.dataset.page;
        switchPage(page);
    });
});

function switchPage(page) {
    // Update nav
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`[data-page="${page}"]`).classList.add('active');

    // Update content
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById(`page-${page}`).classList.add('active');

    // Reload data si nécessaire
    if (page === 'history') {
        loadInvoiceHistory();
    } else if (page === 'stats') {
        loadStats();
    } else if (page === 'management') {
        loadManagementData();
    } else if (page === 'audit') {
        loadAuditData();
    }
}

// Quick Stats
function loadQuickStats() {
    fetch(`https://${GetParentResourceName()}/getQuickStats`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(response => {
        if (response) {
            document.getElementById('quickCommission').textContent = formatCurrency(response.commission || 0);
            document.getElementById('quickInvoices').textContent = response.invoiceCount || 0;
        }
    })
    .catch(err => console.error('Error loading quick stats:', err));
}

// Produits
function loadProductsSelect() {
    const select = document.getElementById('productSelect');
    select.innerHTML = '<option value="">Sélectionner un produit</option>';

    tabletData.products.forEach(product => {
        const option = document.createElement('option');
        option.value = product.id;
        option.textContent = `${product.product_name} - ${formatCurrency(product.price)}`;
        option.dataset.price = product.price;
        option.dataset.name = product.product_name;
        select.appendChild(option);
    });
}

function loadPartnershipsSelect() {
    const select = document.getElementById('partnershipSelect');
    select.innerHTML = '<option value="">Aucun</option>';

    tabletData.partnerships.forEach(partner => {
        const option = document.createElement('option');
        option.value = partner.id;
        option.textContent = `${partner.company_name} (-${formatPercent(partner.discount_percent)})`;
        option.dataset.discount = partner.discount_percent;
        option.dataset.name = partner.company_name;
        select.appendChild(option);
    });
}

function loadCompaniesSelect() {
    const select = document.getElementById('companySelect');
    select.innerHTML = '<option value="">Choisir une entreprise</option>';

    tabletData.companies.forEach(company => {
        const option = document.createElement('option');
        option.value = company.name;
        option.textContent = company.label;
        option.dataset.name = company.name;
        option.dataset.label = company.label;
        select.appendChild(option);
    });
}

function loadNearbyPlayersSelect() {
    const select = document.getElementById('nearbyPlayerSelect');
    select.innerHTML = '<option value="">Sélectionner un joueur proche...</option>';

    tabletData.nearbyPlayers.forEach(player => {
        const option = document.createElement('option');
        option.value = player.id;
        option.textContent = `${player.name} (ID: ${player.id})`;
        option.dataset.id = player.id;
        option.dataset.name = player.name;
        select.appendChild(option);
    });
}

// Event listener pour sélection joueur proche
document.getElementById('nearbyPlayerSelect').addEventListener('change', (e) => {
    const selectedId = e.target.value;
    const selectedOption = e.target.options[e.target.selectedIndex];

    if (selectedId) {
        // Auto-remplir l'ID et le nom
        document.getElementById('citizenId').value = selectedId;
        document.getElementById('citizenName').value = selectedOption.dataset.name || '';
    }
});

function setupInvoiceTypeSelector() {
    const typeBtns = document.querySelectorAll('.type-btn');
    const citizenSection = document.getElementById('citizenSection');
    const companySection = document.getElementById('companySection');

    typeBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const type = btn.dataset.type;

            // Update active state
            typeBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            // Update invoice type
            tabletData.invoiceType = type;

            // Toggle sections
            if (type === 'citizen') {
                citizenSection.style.display = 'block';
                companySection.style.display = 'none';
            } else {
                citizenSection.style.display = 'none';
                companySection.style.display = 'block';
            }
        });
    });
}

// Product mode tabs
document.querySelectorAll('.mode-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const mode = tab.dataset.mode;

        // Update tabs
        document.querySelectorAll('.mode-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        // Toggle sections
        if (mode === 'list') {
            document.getElementById('productListMode').style.display = 'flex';
            document.getElementById('productCustomMode').style.display = 'none';
        } else {
            document.getElementById('productListMode').style.display = 'none';
            document.getElementById('productCustomMode').style.display = 'block';
        }
    });
});

// Facture - Ajout produit depuis liste
document.getElementById('addProductBtn').addEventListener('click', () => {
    const select = document.getElementById('productSelect');
    const qtyInput = document.getElementById('productQty');

    if (!select.value) {
        return;
    }

    const option = select.options[select.selectedIndex];
    const qty = parseInt(qtyInput.value) || 1;
    const price = parseFloat(option.dataset.price);
    const name = option.dataset.name;

    tabletData.invoiceItems.push({
        id: Date.now(),
        productId: select.value,
        name: name,
        price: price,
        quantity: qty,
        total: price * qty
    });

    renderInvoiceItems();
    calculateInvoiceSummary();

    // Reset
    select.selectedIndex = 0;
    qtyInput.value = 1;
});

// Facture - Ajout produit custom
document.getElementById('addCustomProductBtn').addEventListener('click', () => {
    const nameInput = document.getElementById('customProductName');
    const priceInput = document.getElementById('customProductPrice');
    const qtyInput = document.getElementById('customProductQty');

    const name = nameInput.value.trim();
    const price = parseFloat(priceInput.value);
    const qty = parseInt(qtyInput.value) || 1;

    // Validation sans bloquer le NUI
    if (!name) {
        nameInput.style.border = '2px solid #ef4444';
        nameInput.placeholder = '⚠️ Nom requis';
        setTimeout(() => {
            nameInput.style.border = '';
            nameInput.placeholder = 'Nom du produit';
        }, 2000);
        return;
    }

    if (!price || price <= 0 || isNaN(price)) {
        priceInput.style.border = '2px solid #ef4444';
        priceInput.placeholder = '⚠️ Prix requis';
        setTimeout(() => {
            priceInput.style.border = '';
            priceInput.placeholder = 'Prix';
        }, 2000);
        return;
    }

    tabletData.invoiceItems.push({
        id: Date.now(),
        productId: null, // Custom product
        name: name,
        price: price,
        quantity: qty,
        total: price * qty
    });

    renderInvoiceItems();
    calculateInvoiceSummary();

    // Reset
    nameInput.value = '';
    priceInput.value = '';
    qtyInput.value = 1;
});

function renderInvoiceItems() {
    const container = document.getElementById('invoiceItems');

    if (tabletData.invoiceItems.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📦</div><div class="empty-state-text">Aucun article ajouté</div></div>';
        return;
    }

    container.innerHTML = '';
    tabletData.invoiceItems.forEach(item => {
        const div = document.createElement('div');
        div.className = 'invoice-item';
        div.innerHTML = `
            <div class="item-info">
                <div class="item-name">${item.name}</div>
                <div class="item-details">Quantité: ${item.quantity} × ${formatCurrency(item.price)}</div>
            </div>
            <div class="item-price">${formatCurrency(item.total)}</div>
            <button class="item-remove" onclick="removeInvoiceItem(${item.id})">✕</button>
        `;
        container.appendChild(div);
    });
}

function removeInvoiceItem(id) {
    tabletData.invoiceItems = tabletData.invoiceItems.filter(item => item.id !== id);
    renderInvoiceItems();
    calculateInvoiceSummary();
}

// Calcul facture
document.getElementById('manualDiscount').addEventListener('input', calculateInvoiceSummary);
document.getElementById('partnershipSelect').addEventListener('change', (e) => {
    const option = e.target.options[e.target.selectedIndex];
    if (option.value) {
        tabletData.currentPartnership = {
            id: option.value,
            name: option.dataset.name,
            discount: parseFloat(option.dataset.discount)
        };
    } else {
        tabletData.currentPartnership = null;
    }
    calculateInvoiceSummary();
});

function calculateInvoiceSummary() {
    const subtotal = tabletData.invoiceItems.reduce((sum, item) => sum + item.total, 0);
    const manualDiscount = parseFloat(document.getElementById('manualDiscount').value) || 0;
    const partnerDiscount = tabletData.currentPartnership ? tabletData.currentPartnership.discount : 0;

    const totalDiscount = manualDiscount + partnerDiscount;
    const discountAmount = subtotal * (totalDiscount / 100);
    const afterDiscount = subtotal - discountAmount;
    const taxAmount = afterDiscount * (tabletData.taxRate / 100);
    const total = afterDiscount + taxAmount;
    const commission = total * (tabletData.commission / 100);

    document.getElementById('summaryHT').textContent = formatCurrency(subtotal);
    document.getElementById('summaryDiscount').textContent = formatPercent(totalDiscount);
    document.getElementById('summaryTax').textContent = formatCurrency(taxAmount);
    document.getElementById('summaryTotal').textContent = formatCurrency(total);
    document.getElementById('summaryCommission').textContent = formatCurrency(commission);

    // Mettre à jour le label de la VAT avec le taux actuel
    const vatLabel = document.querySelector('#invoiceSummaryList li:nth-child(3) span:first-child');
    if (vatLabel) {
        vatLabel.textContent = `VAT (${tabletData.taxRate}%):`;
    }
}

// Créer facture
document.getElementById('createInvoiceBtn').addEventListener('click', () => {
    if (tabletData.invoiceItems.length === 0) {
        // Validation visuelle sans bloquer
        const itemsContainer = document.getElementById('invoiceItems');
        itemsContainer.style.border = '2px solid #ef4444';
        setTimeout(() => { itemsContainer.style.border = ''; }, 2000);
        return;
    }

    const manualDiscount = parseFloat(document.getElementById('manualDiscount').value) || 0;

    let invoiceData = {
        type: tabletData.invoiceType,
        items: tabletData.invoiceItems,
        manualDiscount: manualDiscount,
        partnership: tabletData.currentPartnership
    };

    if (tabletData.invoiceType === 'citizen') {
        const citizenId = parseInt(document.getElementById('citizenId').value);
        const citizenName = document.getElementById('citizenName').value || '';

        if (!citizenId) {
            // Validation visuelle
            const idInput = document.getElementById('citizenId');
            const selectInput = document.getElementById('nearbyPlayerSelect');
            idInput.style.border = '2px solid #ef4444';
            selectInput.style.border = '2px solid #ef4444';
            idInput.placeholder = '⚠️ ID requis ou sélectionner un joueur proche';
            setTimeout(() => {
                idInput.style.border = '';
                selectInput.style.border = '';
                idInput.placeholder = 'Ex: 12';
            }, 2000);
            return;
        }

        invoiceData.targetId = citizenId;
        invoiceData.targetName = citizenName;
    } else {
        const companyName = document.getElementById('companySelect').value;

        if (!companyName) {
            // Validation visuelle
            const companySelect = document.getElementById('companySelect');
            companySelect.style.border = '2px solid #ef4444';
            setTimeout(() => { companySelect.style.border = ''; }, 2000);
            return;
        }

        invoiceData.targetCompany = companyName;
    }

    postData('createInvoice', invoiceData);

    // Reset form
    resetInvoiceForm();
    switchPage('home');
});

function resetInvoiceForm() {
    tabletData.invoiceItems = [];
    tabletData.currentPartnership = null;
    tabletData.invoiceType = 'citizen';

    document.getElementById('citizenId').value = '';
    document.getElementById('citizenName').value = '';
    document.getElementById('companySelect').selectedIndex = 0;
    document.getElementById('productSelect').selectedIndex = 0;
    document.getElementById('productQty').value = 1;
    document.getElementById('customProductName').value = '';
    document.getElementById('customProductPrice').value = '';
    document.getElementById('customProductQty').value = 1;
    document.getElementById('manualDiscount').value = 0;
    document.getElementById('partnershipSelect').selectedIndex = 0;

    // Reset type selector
    document.querySelectorAll('.type-btn').forEach(btn => {
        if (btn.dataset.type === 'citizen') {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });

    // Reset product mode
    document.querySelectorAll('.mode-tab').forEach(tab => {
        if (tab.dataset.mode === 'list') {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });
    document.getElementById('productListMode').style.display = 'flex';
    document.getElementById('productCustomMode').style.display = 'none';

    document.getElementById('citizenSection').style.display = 'block';
    document.getElementById('companySection').style.display = 'none';

    renderInvoiceItems();
    calculateInvoiceSummary();
}

// Historique
function loadInvoiceHistory() {
    postData('getInvoiceHistory', {});
}

window.receiveInvoiceHistory = function(invoices) {
    const container = document.getElementById('invoiceList');

    if (!invoices || invoices.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📄</div><div class="empty-state-text">Aucune facture</div></div>';
        return;
    }

    container.innerHTML = '';
    invoices.forEach(invoice => {
        const div = document.createElement('div');
        div.className = 'invoice-card';

        // Déterminer le badge de statut
        let statusBadge = '';
        if (invoice.status === 'paid') {
            statusBadge = '<span style="background: #10b981; color: white; padding: 4px 12px; border-radius: 12px; font-size: 11px; font-weight: 600;">✓ PAYÉE</span>';
        } else if (invoice.status === 'pending') {
            statusBadge = '<span style="background: #f59e0b; color: white; padding: 4px 12px; border-radius: 12px; font-size: 11px; font-weight: 600;">⏳ EN ATTENTE</span>';
        } else if (invoice.status === 'cancelled') {
            statusBadge = '<span style="background: #ef4444; color: white; padding: 4px 12px; border-radius: 12px; font-size: 11px; font-weight: 600;">✕ ANNULÉE</span>';
        }

        // Bouton annuler pour les patrons (seulement si pas déjà annulée)
        let cancelButton = '';
        if (tabletData.isBoss && invoice.status !== 'cancelled') {
            cancelButton = `
                <button onclick="cancelInvoice(${invoice.id}, '${invoice.status}')" style="
                    background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
                    color: white;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 12px;
                    font-weight: 600;
                    margin-top: 8px;
                    width: 100%;
                    transition: all 0.2s;
                " onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 4px 12px rgba(239, 68, 68, 0.3)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='none'">
                    <i class="fa-solid fa-times-circle"></i> ${invoice.status === 'paid' ? 'Annuler & Rembourser' : 'Annuler'}
                </button>
            `;
        }

        div.innerHTML = `
            <div class="invoice-header">
                <div class="invoice-id">Facture #${invoice.id}</div>
                <div style="display: flex; align-items: center; gap: 12px;">
                    ${statusBadge}
                    <div class="invoice-date">${formatDate(invoice.created_at)}</div>
                </div>
            </div>
            <div class="invoice-body">
                <div class="invoice-detail">
                    <div class="detail-label">Total TTC</div>
                    <div class="detail-value">${formatCurrency(invoice.total)}</div>
                </div>
                <div class="invoice-detail">
                    <div class="detail-label">Commission</div>
                    <div class="detail-value">${formatCurrency(invoice.commission_amount)}</div>
                </div>
                <div class="invoice-detail">
                    <div class="detail-label">Remise</div>
                    <div class="detail-value">${formatPercent(invoice.discount_percent + invoice.partnership_discount)}</div>
                </div>
            </div>
            ${cancelButton}
        `;
        container.appendChild(div);
    });
};

function cancelInvoice(invoiceId, status) {
    // Annuler directement sans confirmation (le bouton est déjà explicite)
    postData('cancelInvoice', { invoiceId: invoiceId });

    // Rafraîchir l'historique après un court délai
    setTimeout(() => {
        loadInvoiceHistory();
    }, 500);
}

// Stats
function loadStats() {
    postData('getStats', {});
}

window.receiveStats = function(stats) {
    if (!stats) return;

    document.getElementById('statRevenue').textContent = formatCurrency(stats.revenue || 0);
    document.getElementById('statInvoicesCount').textContent = stats.invoiceCount || 0;
    document.getElementById('statCommission').textContent = formatCurrency(stats.commission || 0);
    document.getElementById('statCommissionRate').textContent = formatPercent(tabletData.commission);
};

// Audit (DOJ)
function loadAuditData() {
    postData('getAuditData', {});
}

window.receiveAuditData = function(societies) {
    const container = document.getElementById('auditContainer');

    if (!societies || societies.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🏢</div><div class="empty-state-text">Aucune société trouvée</div></div>';
        return;
    }

    // Créer un tableau HTML pour chaque société
    let html = '';

    societies.forEach(society => {
        html += `
            <div class="audit-society-card" style="
                background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
                border-radius: 12px;
                padding: 20px;
                margin-bottom: 20px;
                border: 1px solid #334155;
            ">
                <div class="audit-society-header" style="
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 16px;
                    padding-bottom: 12px;
                    border-bottom: 2px solid #334155;
                ">
                    <div>
                        <h2 style="color: #60a5fa; font-size: 20px; margin: 0 0 4px 0; font-weight: 700;">
                            <i class="fa-solid fa-building"></i> ${society.label}
                        </h2>
                        <p style="color: #94a3b8; font-size: 13px; margin: 0;">Job: ${society.job}</p>
                    </div>
                    <div style="text-align: right;">
                        <div style="color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Solde Société</div>
                        <div style="color: #10b981; font-size: 24px; font-weight: 700;">${formatCurrency(society.society_money)}</div>
                    </div>
                </div>

                <div class="audit-society-stats" style="
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 16px;
                ">
                    <div class="audit-stat-box" style="
                        background: rgba(59, 130, 246, 0.1);
                        border: 1px solid rgba(59, 130, 246, 0.3);
                        border-radius: 8px;
                        padding: 16px;
                    ">
                        <div style="color: #94a3b8; font-size: 12px; text-transform: uppercase; margin-bottom: 8px;">
                            <i class="fa-solid fa-file-invoice"></i> Factures (Mois)
                        </div>
                        <div style="color: #e2e8f0; font-size: 28px; font-weight: 700;">${society.total_invoices}</div>
                    </div>

                    <div class="audit-stat-box" style="
                        background: rgba(16, 185, 129, 0.1);
                        border: 1px solid rgba(16, 185, 129, 0.3);
                        border-radius: 8px;
                        padding: 16px;
                    ">
                        <div style="color: #94a3b8; font-size: 12px; text-transform: uppercase; margin-bottom: 8px;">
                            <i class="fa-solid fa-sack-dollar"></i> Revenus (Payés)
                        </div>
                        <div style="color: #10b981; font-size: 28px; font-weight: 700;">${formatCurrency(society.revenue)}</div>
                    </div>

                    <div class="audit-stat-box" style="
                        background: rgba(245, 158, 11, 0.1);
                        border: 1px solid rgba(245, 158, 11, 0.3);
                        border-radius: 8px;
                        padding: 16px;
                    ">
                        <div style="color: #94a3b8; font-size: 12px; text-transform: uppercase; margin-bottom: 8px;">
                            <i class="fa-solid fa-clock"></i> En Attente
                        </div>
                        <div style="color: #f59e0b; font-size: 28px; font-weight: 700;">${formatCurrency(society.pending_amount)}</div>
                    </div>

                    <div class="audit-stat-box" style="
                        background: rgba(139, 92, 246, 0.1);
                        border: 1px solid rgba(139, 92, 246, 0.3);
                        border-radius: 8px;
                        padding: 16px;
                    ">
                        <div style="color: #94a3b8; font-size: 12px; text-transform: uppercase; margin-bottom: 8px;">
                            <i class="fa-solid fa-percent"></i> Commissions
                        </div>
                        <div style="color: #a78bfa; font-size: 28px; font-weight: 700;">${formatCurrency(society.commissions)}</div>
                    </div>
                </div>
            </div>
        `;
    });

    container.innerHTML = html;
};

// Management Tabs
document.querySelectorAll('.mgmt-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const tabName = tab.dataset.tab;

        document.querySelectorAll('.mgmt-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        document.querySelectorAll('.mgmt-content').forEach(c => c.classList.remove('active'));
        document.getElementById(`mgmt-${tabName}`).classList.add('active');

        // Charger les stats employés si on clique sur l'onglet stats
        if (tabName === 'stats') {
            loadEmployeeStats();
        }
    });
});

function loadManagementData() {
    postData('getManagementData', {});
}

window.receiveManagementData = function(data) {
    if (!data) return;

    // Produits
    renderProductList(data.products || []);

    // Employés
    renderEmployeeList(data.employees || []);

    // Partenariats
    renderPartnerList(data.partnerships || []);
};

// Stats Employés
function loadEmployeeStats() {
    postData('getEmployeeStats', {});
}

window.receiveEmployeeStats = function(stats) {
    const container = document.getElementById('employeeStatsTable');

    if (!stats || stats.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">👥</div><div class="empty-state-text">Aucun employé</div></div>';
        return;
    }

    // Créer un tableau HTML
    let html = `
        <table style="width: 100%; border-collapse: collapse; color: #e2e8f0;">
            <thead>
                <tr style="background: #1e293b; border-bottom: 2px solid #334155;">
                    <th style="padding: 12px; text-align: left; font-weight: 600;">Employé</th>
                    <th style="padding: 12px; text-align: center; font-weight: 600;">Commission</th>
                    <th style="padding: 12px; text-align: center; font-weight: 600;">Factures</th>
                    <th style="padding: 12px; text-align: right; font-weight: 600;">Total HT</th>
                    <th style="padding: 12px; text-align: right; font-weight: 600;">Total TTC</th>
                    <th style="padding: 12px; text-align: right; font-weight: 600;">Commission Gagnée</th>
                </tr>
            </thead>
            <tbody>
    `;

    let totalHT = 0;
    let totalTTC = 0;
    let totalCommission = 0;

    stats.forEach((employee, index) => {
        totalHT += employee.total_ht;
        totalTTC += employee.total_ttc;
        totalCommission += employee.total_commission;

        const bgColor = index % 2 === 0 ? '#0f172a' : '#1e293b';
        html += `
            <tr style="background: ${bgColor}; border-bottom: 1px solid #334155;">
                <td style="padding: 12px;">${employee.name}</td>
                <td style="padding: 12px; text-align: center;">${formatPercent(employee.commission_percent)}</td>
                <td style="padding: 12px; text-align: center;">${employee.invoice_count}</td>
                <td style="padding: 12px; text-align: right;">${formatCurrency(employee.total_ht)}</td>
                <td style="padding: 12px; text-align: right;">${formatCurrency(employee.total_ttc)}</td>
                <td style="padding: 12px; text-align: right; color: #10b981; font-weight: 600;">${formatCurrency(employee.total_commission)}</td>
            </tr>
        `;
    });

    // Ligne de total
    html += `
            <tr style="background: #334155; border-top: 2px solid #475569; font-weight: 700;">
                <td style="padding: 12px;" colspan="3">TOTAL</td>
                <td style="padding: 12px; text-align: right;">${formatCurrency(totalHT)}</td>
                <td style="padding: 12px; text-align: right;">${formatCurrency(totalTTC)}</td>
                <td style="padding: 12px; text-align: right; color: #10b981;">${formatCurrency(totalCommission)}</td>
            </tr>
        </tbody>
        </table>
    `;

    container.innerHTML = html;
};

// Reset sales
document.getElementById('resetSalesBtn').addEventListener('click', () => {
    postData('resetSales', {});

    // Rafraîchir après un court délai
    setTimeout(() => {
        loadEmployeeStats();
        loadQuickStats();
    }, 500);
});

// Gestion Produits
document.getElementById('addNewProductBtn').addEventListener('click', () => {
    const name = document.getElementById('newProductName').value;
    const price = parseFloat(document.getElementById('newProductPrice').value);

    if (!name || !price) return;

    postData('addProduct', { name, price });

    document.getElementById('newProductName').value = '';
    document.getElementById('newProductPrice').value = '';
});

function renderProductList(products) {
    const container = document.getElementById('productList');

    if (products.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📦</div><div class="empty-state-text">Aucun produit</div></div>';
        return;
    }

    container.innerHTML = '';
    products.forEach(product => {
        const div = document.createElement('div');
        div.className = 'product-item';
        div.innerHTML = `
            <div class="item-left">
                <div class="item-title">${product.product_name}</div>
                <div class="item-subtitle">Prix: ${formatCurrency(product.price)}</div>
            </div>
            <div class="item-actions">
                <button class="btn-delete" onclick="deleteProduct(${product.id})">Supprimer</button>
            </div>
        `;
        container.appendChild(div);
    });
}

function deleteProduct(id) {
    postData('deleteProduct', { id });
}

// Gestion Employés
function renderEmployeeList(employees) {
    const container = document.getElementById('employeeList');

    if (employees.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">👥</div><div class="empty-state-text">Aucun employé</div></div>';
        return;
    }

    container.innerHTML = '';
    employees.forEach(employee => {
        const div = document.createElement('div');
        div.className = 'employee-item';
        div.innerHTML = `
            <div class="item-left">
                <div class="item-title">${employee.name}</div>
                <div class="item-subtitle">Commission: ${formatPercent(employee.commission_percent)}</div>
            </div>
            <div class="item-actions">
                <input type="number" class="commission-input" id="commission-${employee.identifier}" value="${employee.commission_percent}" min="0" max="100" step="0.5">
                <button class="btn-save" onclick="updateCommission('${employee.identifier}')">Sauver</button>
            </div>
        `;
        container.appendChild(div);
    });
}

function updateCommission(identifier) {
    const input = document.getElementById(`commission-${identifier}`);
    const commission = parseFloat(input.value);

    if (commission < 0 || commission > 100) return;

    postData('updateCommission', { identifier, commission });
}

// Gestion Partenariats
document.getElementById('addPartnerBtn').addEventListener('click', () => {
    const name = document.getElementById('newPartnerName').value;
    const discount = parseFloat(document.getElementById('newPartnerDiscount').value);

    if (!name || !discount) return;

    postData('addPartnership', { name, discount });

    document.getElementById('newPartnerName').value = '';
    document.getElementById('newPartnerDiscount').value = '';
});

function renderPartnerList(partners) {
    const container = document.getElementById('partnerList');

    if (partners.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🤝</div><div class="empty-state-text">Aucun partenariat</div></div>';
        return;
    }

    container.innerHTML = '';
    partners.forEach(partner => {
        const div = document.createElement('div');
        div.className = 'partner-item';
        div.innerHTML = `
            <div class="item-left">
                <div class="item-title">${partner.company_name}</div>
                <div class="item-subtitle">Remise: ${formatPercent(partner.discount_percent)}</div>
            </div>
            <div class="item-actions">
                <button class="btn-delete" onclick="deletePartnership(${partner.id})">Supprimer</button>
            </div>
        `;
        container.appendChild(div);
    });
}

function deletePartnership(id) {
    postData('deletePartnership', { id });
}

// Invoice Menu
function openInvoiceMenu(invoices) {
    const menu = document.getElementById('invoiceMenu');
    const list = document.getElementById('invoiceMenuList');

    list.innerHTML = '';

    invoices.forEach(invoice => {
        const items = JSON.parse(invoice.items);
        const itemsList = items.map(item => `${item.name} x${item.quantity}`).join(', ');

        const card = document.createElement('div');
        card.className = 'pending-invoice-card';
        card.innerHTML = `
            <div class="pending-invoice-header">
                <div class="pending-invoice-id">Facture #${invoice.id}</div>
                <div class="pending-invoice-company">${invoice.employee_name}</div>
            </div>
            <div class="pending-invoice-body">
                <div class="pending-detail">
                    <div class="pending-detail-label">Articles</div>
                    <div class="pending-detail-value">${itemsList}</div>
                </div>
                <div class="pending-detail">
                    <div class="pending-detail-label">Date</div>
                    <div class="pending-detail-value">${formatDate(invoice.created_at)}</div>
                </div>
                <div class="pending-detail">
                    <div class="pending-detail-label">Montant Total</div>
                    <div class="pending-detail-value total">${formatCurrency(invoice.total)}</div>
                </div>
                <div class="pending-detail">
                    <div class="pending-detail-label">Entreprise</div>
                    <div class="pending-detail-value">${invoice.partnership_name || 'N/A'}</div>
                </div>
            </div>
            <div class="pending-invoice-actions">
                <button class="btn-pay" onclick="payInvoice(${invoice.id})">
                    <i class="fa-solid fa-credit-card"></i> Payer ${formatCurrency(invoice.total)}
                </button>
            </div>
        `;
        list.appendChild(card);
    });

    menu.classList.add('show');
}

function closeInvoiceMenu() {
    document.getElementById('invoiceMenu').classList.remove('show');
}

function payInvoice(invoiceId) {
    // Payer la facture et fermer le menu
    postData('payInvoice', { invoiceId });

    // Fermer le menu après un court délai pour laisser le serveur traiter
    setTimeout(() => {
        closeInvoiceMenu();
        postData('closeInvoiceMenu', {});
    }, 100);
}

document.getElementById('closeInvoiceMenuBtn').addEventListener('click', () => {
    postData('closeInvoiceMenu', {});
    closeInvoiceMenu();
});

// ESC pour fermer invoice menu
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && document.getElementById('invoiceMenu').classList.contains('show')) {
        postData('closeInvoiceMenu', {});
        closeInvoiceMenu();
    }
});

// Listener pour les mises à jour du serveur
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        // Déjà géré en haut
        return;
    } else if (data.action === 'close') {
        // Déjà géré en haut
        return;
    } else if (data.action === 'openInvoiceMenu') {
        openInvoiceMenu(data.invoices);
        return;
    } else if (data.action === 'closeInvoiceMenu') {
        closeInvoiceMenu();
        return;
    } else if (data.action === 'updateProducts') {
        tabletData.products = data.products;
        loadProductsSelect();
        if (tabletData.isBoss) {
            renderProductList(data.products);
        }
    } else if (data.action === 'updatePartnerships') {
        tabletData.partnerships = data.partnerships;
        loadPartnershipsSelect();
        if (tabletData.isBoss) {
            renderPartnerList(data.partnerships);
        }
    } else if (data.action === 'updateEmployees') {
        if (tabletData.isBoss) {
            renderEmployeeList(data.employees);
        }
    } else if (data.action === 'invoiceCreated') {
        // Notification ou autre feedback
        loadQuickStats();
    } else if (data.action === 'receiveInvoiceHistory') {
        receiveInvoiceHistory(data.invoices);
    } else if (data.action === 'receiveStats') {
        receiveStats(data.stats);
    } else if (data.action === 'receiveManagementData') {
        receiveManagementData(data.data);
    } else if (data.action === 'receiveEmployeeStats') {
        receiveEmployeeStats(data.stats);
    } else if (data.action === 'refreshStats') {
        // Rafraîchir les stats après paiement de facture
        loadQuickStats();
        const statsNav = document.querySelector('.nav-item[data-page="stats"]');
        if (statsNav && statsNav.classList.contains('active')) {
            loadStats();
        }
        const invoicesNav = document.querySelector('.nav-item[data-page="invoices"]');
        if (invoicesNav && invoicesNav.classList.contains('active')) {
            loadInvoiceHistory();
        }
    } else if (data.action === 'receiveAuditData') {
        receiveAuditData(data.data);
    }
});
