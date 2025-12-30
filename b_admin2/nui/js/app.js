// ============================================
// B_ADMIN2 - NUI APP (VANILLA JS)
// ============================================

let currentPlayer = null;
let players = [];
let tickets = [];

// ============================================
// UTILS
// ============================================

function post(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(res => res.json());
}

function formatTime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${h}h ${m}m`;
}

// ============================================
// INIT
// ============================================

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'toggle') {
        const app = document.getElementById('app');
        if (data.visible) {
            app.classList.remove('hidden');
            loadDashboard();
        } else {
            app.classList.add('hidden');
        }
    }

    if (data.action === 'spectateStart') {
        // TODO: Show spectate overlay
    }

    if (data.action === 'spectateStop') {
        // TODO: Hide spectate overlay
    }

    if (data.action === 'spectateUpdate') {
        // TODO: Update spectate overlay data
    }
});

// ============================================
// NAVIGATION
// ============================================

document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        // Update active nav
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        // Show page
        const page = btn.dataset.page;
        document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
        document.getElementById(`page-${page}`).classList.add('active');

        // Load data
        if (page === 'dashboard') loadDashboard();
        if (page === 'players') loadPlayers();
        if (page === 'tickets') loadTickets();
    });
});

// Close button
document.getElementById('close-btn').addEventListener('click', () => {
    post('close');
});

// ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const app = document.getElementById('app');
        if (!app.classList.contains('hidden')) {
            post('close');
        }
    }
});

// ============================================
// DASHBOARD
// ============================================

function loadDashboard() {
    post('getDashboard').then(data => {
        if (!data) return;

        document.getElementById('stat-players').textContent = data.playersOnline || 0;
        document.getElementById('stat-staff').textContent = data.staffOnline || 0;
        document.getElementById('stat-tickets').textContent = data.openReports || 0;
        document.getElementById('stat-uptime').textContent = formatTime(data.uptime || 0);

        // Activity feed
        const feed = document.getElementById('activity-feed');
        feed.innerHTML = '';
        if (data.activityFeed) {
            data.activityFeed.forEach(item => {
                const div = document.createElement('div');
                div.className = 'activity-item';
                div.innerHTML = `
                    <div><strong>${item.action_type}</strong> - ${item.admin_rank}</div>
                    <div class="time">${new Date(item.performed_at).toLocaleString()}</div>
                `;
                feed.appendChild(div);
            });
        }
    });
}

// ============================================
// PLAYERS
// ============================================

function loadPlayers() {
    post('getPlayers').then(data => {
        players = data || [];
        renderPlayers();
    });
}

function renderPlayers() {
    const list = document.getElementById('players-list');
    list.innerHTML = '';

    const search = document.getElementById('player-search').value.toLowerCase();
    const filtered = players.filter(p => p.name.toLowerCase().includes(search));

    filtered.forEach(player => {
        const card = document.createElement('div');
        card.className = 'player-card';
        card.innerHTML = `
            <div class="name">${player.name} [${player.id}]</div>
            <div class="info">Job: ${player.job} | Ping: ${player.ping}ms</div>
            <div class="info">Zone: ${player.zone}</div>
        `;
        card.addEventListener('click', () => openPlayerDetail(player.id));
        list.appendChild(card);
    });
}

document.getElementById('player-search')?.addEventListener('input', renderPlayers);
document.getElementById('refresh-players')?.addEventListener('click', loadPlayers);

function openPlayerDetail(playerId) {
    post('getPlayerData', { playerId }).then(data => {
        if (!data) return;

        currentPlayer = data;
        const modal = document.getElementById('player-modal');
        const detail = document.getElementById('player-detail');
        document.getElementById('modal-player-name').textContent = data.name;

        detail.innerHTML = `
            <div class="section">
                <h4>Infos</h4>
                <p>ID: ${data.id} | Job: ${data.job} [${data.grade}]</p>
                <p>License: ${data.license}</p>
                <p>Zone: ${data.zone}</p>
                <p>HP: ${data.health} | Armor: ${data.armor}</p>
                <p>💰 Cash: $${data.money.cash} | Bank: $${data.money.bank} | Black: $${data.money.black}</p>
            </div>
            <div class="section">
                <h4>Actions Rapides</h4>
                <button onclick="playerAction('goto', ${data.id})" class="btn">📍 Goto</button>
                <button onclick="playerAction('bring', ${data.id})" class="btn">📍 Bring</button>
                <button onclick="playerAction('spectate', ${data.id})" class="btn">👁️ Spectate</button>
                <button onclick="playerAction('freeze', ${data.id})" class="btn">🧊 Freeze</button>
                <button onclick="playerAction('revive', ${data.id})" class="btn">💚 Revive</button>
                <button onclick="playerAction('heal', ${data.id})" class="btn">💊 Heal</button>
            </div>
            <div class="section">
                <h4>Modération</h4>
                <input type="text" id="warn-reason" placeholder="Raison du warn">
                <button onclick="warnPlayer(${data.id})" class="btn">⚠️ Warn</button>
                <button onclick="kickPlayer(${data.id})" class="btn-danger">🚫 Kick</button>
            </div>
        `;

        modal.classList.remove('hidden');
    });
}

function closeModal() {
    document.getElementById('player-modal').classList.add('hidden');
}

function playerAction(action, playerId) {
    if (action === 'goto') post('goto', { playerId });
    if (action === 'bring') post('bring', { playerId });
    if (action === 'spectate') post('spectate', { playerId });
    if (action === 'freeze') post('freeze', { playerId, freeze: true });
    if (action === 'revive') post('revive', { playerId });
    if (action === 'heal') post('heal', { playerId });
}

function warnPlayer(playerId) {
    const reason = document.getElementById('warn-reason').value;
    if (!reason) return alert('Raison requise');
    post('warn', { playerId, reason, points: 1 });
}

function kickPlayer(playerId) {
    const reason = prompt('Raison du kick:');
    if (!reason) return;
    post('kick', { playerId, reason });
}

// ============================================
// VEHICLES
// ============================================

function spawnVehicle() {
    const model = document.getElementById('vehicle-model').value;
    if (!model) return alert('Modèle requis');
    post('spawnVehicle', { model });
}

function deleteVehicle() {
    post('deleteVehicle');
}

function vehicleAction(action) {
    post('vehicleAction', { action });
}

// ============================================
// WORLD
// ============================================

function setTime() {
    const hour = parseInt(document.getElementById('hour').value) || 12;
    const minute = parseInt(document.getElementById('minute').value) || 0;
    post('setTime', { hour, minute });
}

function setWeather() {
    const weather = document.getElementById('weather').value;
    post('setWeather', { weather });
}

// ============================================
// TICKETS
// ============================================

function loadTickets() {
    post('getTickets', {}).then(data => {
        tickets = data || [];
        renderTickets();
    });
}

function renderTickets() {
    const list = document.getElementById('tickets-list');
    list.innerHTML = '';

    tickets.forEach(ticket => {
        const card = document.createElement('div');
        card.className = `ticket-card ${ticket.priority}`;
        card.innerHTML = `
            <div class="title">#${ticket.id} - ${ticket.title}</div>
            <div class="meta">Par: ${ticket.reporter_name} | Statut: ${ticket.status} | Priorité: ${ticket.priority}</div>
        `;
        list.appendChild(card);
    });
}

document.getElementById('refresh-tickets')?.addEventListener('click', loadTickets);

// ============================================
// STAFF MODE
// ============================================

document.getElementById('toggle-staffmode')?.addEventListener('click', () => {
    post('toggleStaffMode');
});

document.getElementById('toggle-panic')?.addEventListener('click', () => {
    if (confirm('Activer/Désactiver le Panic Mode ?')) {
        post('togglePanicMode');
    }
});

// ============================================
// READY
// ============================================

console.log('[B_ADMIN2] NUI Ready');
