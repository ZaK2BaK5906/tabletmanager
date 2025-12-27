// ============================================
// MENU D'ASSIGNATION DE VÉHICULE
// ============================================

let selectedVehicle = null;
let targetPlayerId = null;
let targetPlayerName = '';

// Écouter les messages pour ouvrir/fermer le menu
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'openAssignVehicle') {
        targetPlayerId = data.targetId;
        targetPlayerName = data.targetName;
        openAssignMenu(data.vehicles);
    } else if (data.action === 'closeAssignVehicle') {
        closeAssignMenu();
    }
});

function openAssignMenu(vehicles) {
    document.getElementById('targetPlayerName').textContent = `Vendre à: ${targetPlayerName}`;

    const list = document.getElementById('vehicleList');
    list.innerHTML = '';

    vehicles.forEach(vehicle => {
        const stock = parseInt(vehicle.stock);
        const hasStock = stock > 0;

        let stockClass = '';
        let stockText = '';

        if (stock === 0) {
            stockClass = 'out';
            stockText = 'Rupture de stock';
        } else if (stock <= 3) {
            stockClass = 'low';
            stockText = `Stock: ${stock}`;
        } else {
            stockText = `Stock: ${stock}`;
        }

        const item = document.createElement('div');
        item.className = `vehicle-item ${!hasStock ? 'no-stock' : ''}`;
        item.innerHTML = `
            <div class="vehicle-name">${vehicle.name}</div>
            <div class="vehicle-info">
                <span class="vehicle-price">$${formatNumber(vehicle.price)}</span>
                <span class="vehicle-stock ${stockClass}">${stockText}</span>
            </div>
        `;

        if (hasStock) {
            item.onclick = () => selectVehicleForAssign(vehicle, item);
        }

        list.appendChild(item);
    });

    document.getElementById('assignVehicleMenu').style.display = 'block';
}

function selectVehicleForAssign(vehicle, element) {
    selectedVehicle = vehicle;

    // Enlever la sélection des autres
    document.querySelectorAll('.vehicle-item').forEach(el => {
        el.classList.remove('selected');
    });

    element.classList.add('selected');

    // Afficher le formulaire
    document.getElementById('selectedVehicleInfo').innerHTML = `
        <h4><i class="fa-solid fa-car"></i> ${vehicle.name}</h4>
        <p>Prix: <strong style="color: #22c55e;">$${formatNumber(vehicle.price)}</strong></p>
    `;

    document.querySelector('.vehicle-list').style.display = 'none';
    document.getElementById('plateSection').classList.add('active');
}

function backToVehicleList() {
    document.querySelector('.vehicle-list').style.display = 'grid';
    document.getElementById('plateSection').classList.remove('active');
    document.getElementById('plateInput').value = '';
}

function confirmAssignment() {
    if (!selectedVehicle) return;

    const plate = document.getElementById('plateInput').value.trim();

    fetch(`https://${GetParentResourceName()}/assignVehicleConfirm`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            targetId: targetPlayerId,
            vehicleModel: selectedVehicle.model,
            plate: plate || null
        })
    });

    closeAssignMenu();
}

function closeAssignMenu() {
    document.getElementById('assignVehicleMenu').style.display = 'none';
    document.querySelector('.vehicle-list').style.display = 'grid';
    document.getElementById('plateSection').classList.remove('active');
    document.getElementById('plateInput').value = '';
    selectedVehicle = null;

    fetch(`https://${GetParentResourceName()}/closeAssignMenu`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// ESC pour fermer
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const menu = document.getElementById('assignVehicleMenu');
        if (menu && menu.style.display === 'block') {
            closeAssignMenu();
        }
    }
});
