// ===================================
// VÉHICULES (DEALERSHIP)
// ===================================

let vehiclesData = [];
let currentOrderVehicle = null;

// Charger les véhicules
function loadVehicles() {
    fetch(`https://${GetParentResourceName()}/getVehicles`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(response => {
        if (response && Array.isArray(response)) {
            vehiclesData = response;
            renderVehicles();
            renderCategoryFilters();
            setupCatalogSearch();
        }
    })
    .catch(err => console.error('Error loading vehicles:', err));
}

// Setup recherche catalogue
function setupCatalogSearch() {
    const searchInput = document.getElementById('vehicleCatalogSearch');
    if (searchInput) {
        searchInput.value = '';
        searchInput.oninput = function() {
            const query = this.value.toLowerCase();
            const activeCategory = document.querySelector('.category-btn.active')?.dataset.category || 'all';

            let filtered = activeCategory === 'all'
                ? vehiclesData
                : vehiclesData.filter(v => v.category === activeCategory);

            if (query) {
                filtered = filtered.filter(v =>
                    v.name.toLowerCase().includes(query) ||
                    v.model.toLowerCase().includes(query) ||
                    (v.category && v.category.toLowerCase().includes(query))
                );
            }

            renderVehicles(filtered);
        };
    }
}

// Capitaliser première lettre
function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

// Render filtres catégories
function renderCategoryFilters() {
    const container = document.getElementById('categoryFilters');
    if (!container) return;

    const categories = [...new Set(vehiclesData.map(v => v.category))].filter(Boolean);

    let html = '<button class="category-btn active" data-category="all">Tous</button>';
    categories.forEach(cat => {
        html += `<button class="category-btn" data-category="${cat}">${capitalize(cat)}</button>`;
    });

    container.innerHTML = html;

    // Event listeners
    container.querySelectorAll('.category-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            container.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            filterVehiclesByCategory(btn.dataset.category);
        });
    });
}

// Filtrer par catégorie
function filterVehiclesByCategory(category) {
    const filtered = category === 'all'
        ? vehiclesData
        : vehiclesData.filter(v => v.category === category);
    renderVehicles(filtered);
}

// Render véhicules
function renderVehicles(vehicles = vehiclesData) {
    const container = document.getElementById('vehiclesGrid');
    if (!container) return;

    if (!vehicles || vehicles.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🚗</div><div class="empty-state-text">Aucun véhicule disponible</div></div>';
        return;
    }

    container.innerHTML = '';

    vehicles.forEach(vehicle => {
        const stock = parseInt(vehicle.stock) || 0;
        const stockClass = stock === 0 ? 'low' : (stock >= 10 ? 'high' : '');

        const card = document.createElement('div');
        card.className = 'vehicle-card';
        card.innerHTML = `
            <div class="vehicle-image">
                <i class="fa-solid fa-car"></i>
            </div>
            <div class="vehicle-info">
                <div class="vehicle-name">${vehicle.name}</div>
                <div class="vehicle-category">${vehicle.category || 'Autre'}</div>
                <div class="vehicle-details">
                    <div class="vehicle-price">${formatCurrency(vehicle.price)}</div>
                    <div class="vehicle-stock ${stockClass}">
                        <i class="fa-solid fa-box"></i>
                        <span>${stock}</span>
                    </div>
                </div>
                <div class="vehicle-actions">
                    <button class="btn-order" onclick='openOrderModal(${JSON.stringify(vehicle)})'>
                        <i class="fa-solid fa-shopping-cart"></i> Commander
                    </button>
                </div>
            </div>
        `;
        container.appendChild(card);
    });
}

// Ouvrir modal de commande
window.openOrderModal = function(vehicle) {
    currentOrderVehicle = vehicle;
    document.getElementById('orderVehicleName').textContent = vehicle.name;
    document.getElementById('orderUnitPrice').textContent = formatCurrency(vehicle.price);
    document.getElementById('orderQuantity').value = 1;
    updateOrderSummary();
    document.getElementById('vehicleOrderModal').classList.add('show');
};

// Fermer modal
window.closeOrderModal = function() {
    document.getElementById('vehicleOrderModal').classList.remove('show');
    currentOrderVehicle = null;
};

// Update summary
const orderQuantityInput = document.getElementById('orderQuantity');
if (orderQuantityInput) {
    orderQuantityInput.addEventListener('input', updateOrderSummary);
}

function updateOrderSummary() {
    if (!currentOrderVehicle) return;

    const qty = parseInt(document.getElementById('orderQuantity').value) || 1;
    const unitPrice = parseFloat(currentOrderVehicle.price);
    const total = unitPrice * qty;

    document.getElementById('orderQty').textContent = qty;
    document.getElementById('orderTotalPrice').textContent = formatCurrency(total);
}

// Confirmer commande
window.confirmOrder = function() {
    if (!currentOrderVehicle) return;

    const quantity = parseInt(document.getElementById('orderQuantity').value) || 1;

    postData('orderVehicles', {
        vehicleModel: currentOrderVehicle.model,
        quantity: quantity
    });

    closeOrderModal();

    // Reload après 1s
    setTimeout(loadVehicles, 1000);
};
