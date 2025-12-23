let tabletData = {
    job: '',
    userName: '',
    isBoss: false,
    commission: 0,
    products: [],
    partnerships: [],
    companies: [],
    invoiceItems: [],
    currentDiscount: 0,
    currentPartnership: null,
    invoiceType: 'citizen' // 'citizen' or 'company'
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
    tabletData.commission = data.commission || 0;
    tabletData.products = data.products || [];
    tabletData.partnerships = data.partnerships || [];
    tabletData.companies = data.companies || [];

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

    // Charger les produits dans le select
    loadProductsSelect();
    loadPartnershipsSelect();
    loadCompaniesSelect();

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
    }
}

// Quick Stats
function loadQuickStats() {
    postData('getQuickStats', {}, (response) => {
        if (response) {
            document.getElementById('quickCommission').textContent = formatCurrency(response.commission || 0);
            document.getElementById('quickInvoices').textContent = response.invoiceCount || 0;
        }
    });
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

    if (!name || !price || price <= 0) {
        alert('Veuillez remplir le nom et le prix du produit');
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
    const taxAmount = afterDiscount * 0.20; // 20% TVA
    const total = afterDiscount + taxAmount;
    const commission = total * (tabletData.commission / 100);

    document.getElementById('summaryHT').textContent = formatCurrency(subtotal);
    document.getElementById('summaryDiscount').textContent = formatPercent(totalDiscount);
    document.getElementById('summaryTax').textContent = formatCurrency(taxAmount);
    document.getElementById('summaryTotal').textContent = formatCurrency(total);
    document.getElementById('summaryCommission').textContent = formatCurrency(commission);
}

// Créer facture
document.getElementById('createInvoiceBtn').addEventListener('click', () => {
    if (tabletData.invoiceItems.length === 0) {
        alert('Veuillez ajouter au moins un article');
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
            alert('Veuillez entrer l\'ID du joueur');
            return;
        }

        invoiceData.targetId = citizenId;
        invoiceData.targetName = citizenName;
    } else {
        const companyName = document.getElementById('companySelect').value;

        if (!companyName) {
            alert('Veuillez sélectionner une entreprise');
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
        div.innerHTML = `
            <div class="invoice-header">
                <div class="invoice-id">Facture #${invoice.id}</div>
                <div class="invoice-date">${formatDate(invoice.created_at)}</div>
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
        `;
        container.appendChild(div);
    });
};

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

// Management Tabs
document.querySelectorAll('.mgmt-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const tabName = tab.dataset.tab;

        document.querySelectorAll('.mgmt-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        document.querySelectorAll('.mgmt-content').forEach(c => c.classList.remove('active'));
        document.getElementById(`mgmt-${tabName}`).classList.add('active');
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
    }
});
