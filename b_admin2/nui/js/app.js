// ============================================
// B_ADMIN2 - Modern NUI App
// ============================================

let players = [];
let currentPlayer = null;

// ============================================
// UTILS
// ============================================

function post(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(res => res.json()).catch(() => null);
}

// ============================================
// INIT
// ============================================

window.addEventListener('message', (event) => {
    const { action, visible, data: eventData } = event.data;

    if (action === 'toggle') {
        const app = document.getElementById('app');
        if (visible) {
            app.classList.remove('hidden');
            loadPlayers();
        } else {
            app.classList.add('hidden');
            closePlayerPanel();
        }
    }
});

// ============================================
// PLAYERS
// ============================================

function loadPlayers() {
    post('getPlayers').then(data => {
        if (!data) return;
        players = data;
        renderPlayers();
        updateStats();
    });
}

function renderPlayers() {
    const list = document.getElementById('players-list');
    const search = document.getElementById('player-search').value.toLowerCase();

    const filtered = search
        ? players.filter(p => p.name.toLowerCase().includes(search))
        : players;

    list.innerHTML = '';

    filtered.forEach(player => {
        const card = document.createElement('div');
        card.className = 'player-card';

        const initial = player.name.charAt(0).toUpperCase();

        card.innerHTML = `
            <div class="player-avatar">${initial}</div>
            <div class="player-info">
                <div class="player-name">${player.name}</div>
                <div class="player-meta">ID: ${player.id} • ${player.job}</div>
            </div>
            <div class="player-ping">${player.ping}ms</div>
        `;

        card.addEventListener('click', () => openPlayerPanel(player.id));
        list.appendChild(card);
    });
}

function updateStats() {
    document.getElementById('stat-players').textContent = players.length;
    const staffCount = players.filter(p => p.isStaff).length || 0;
    document.getElementById('stat-staff').textContent = staffCount;
}

// ============================================
// SEARCH
// ============================================

document.getElementById('player-search')?.addEventListener('input', () => {
    renderPlayers();
});

document.getElementById('refresh-players')?.addEventListener('click', () => {
    loadPlayers();
});

// ============================================
// PLAYER PANEL
// ============================================

function openPlayerPanel(playerId) {
    post('getPlayerData', { playerId }).then(data => {
        if (!data) return;

        currentPlayer = data;
        const panel = document.getElementById('player-panel');
        const content = document.getElementById('panel-content');

        document.getElementById('panel-player-name').textContent = data.name;

        content.innerHTML = `
            <!-- Actions Teleport -->
            <div class="actions-grid">
                <button onclick="playerAction('goto', ${data.id})" class="action-btn-small">Goto</button>
                <button onclick="playerAction('bring', ${data.id})" class="action-btn-small">Bring</button>
                <button onclick="playerAction('spectate', ${data.id})" class="action-btn-small">Spectate</button>
                <button onclick="playerAction('noclip', ${data.id})" class="action-btn-small">Noclip</button>
            </div>

            <!-- Actions Player -->
            <div class="actions-grid">
                <button onclick="playerAction('freeze', ${data.id})" class="action-btn-small">Freeze</button>
                <button onclick="playerAction('revive', ${data.id})" class="action-btn-small">Revive</button>
                <button onclick="playerAction('heal', ${data.id})" class="action-btn-small">Heal</button>
                <button onclick="playerAction('kill', ${data.id})" class="action-btn-small">Kill</button>
            </div>

            <!-- Actions Vehicle -->
            <div class="actions-grid">
                <button onclick="giveCarPlayer(${data.id})" class="action-btn-small">Give Car</button>
                <button onclick="playerAction('kick', ${data.id})" class="action-btn-small">Kick</button>
            </div>

            <!-- Info General -->
            <div class="info-section">
                <h3>Informations</h3>
                <div class="info-row">
                    <span class="info-label">ID</span>
                    <span class="info-value">${data.id}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Job</span>
                    <span class="info-value">${data.job} [${data.grade}]</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Ping</span>
                    <span class="info-value">${data.ping}ms</span>
                </div>
                <div class="info-row">
                    <span class="info-label">License</span>
                    <span class="info-value">${data.license || 'N/A'}</span>
                </div>
            </div>

            <!-- Stats -->
            <div class="info-section">
                <h3>Stats</h3>
                <div class="info-row">
                    <span class="info-label">HP</span>
                    <span class="info-value">${data.health || 0}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Armor</span>
                    <span class="info-value">${data.armor || 0}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Zone</span>
                    <span class="info-value">${data.zone || 'N/A'}</span>
                </div>
            </div>

            <!-- Money -->
            <div class="info-section">
                <h3>Argent</h3>
                <div class="info-row">
                    <span class="info-label">Cash</span>
                    <span class="info-value">$${data.money?.cash || 0}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Bank</span>
                    <span class="info-value">$${data.money?.bank || 0}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Black</span>
                    <span class="info-value">$${data.money?.black || 0}</span>
                </div>
            </div>

            <!-- Inventory -->
            <div class="info-section">
                <h3>Inventaire</h3>
                <div class="info-row">
                    <span class="info-label">Poids</span>
                    <span class="info-value">${data.inventory?.weight || 0}/${data.inventory?.maxWeight || 0}</span>
                </div>
            </div>

            <!-- Moderation Actions -->
            <div class="actions-grid">
                <button onclick="warnPlayer(${data.id})" class="action-btn-small">Warn</button>
                <button onclick="banPlayer(${data.id})" class="action-btn-small">Ban</button>
            </div>
        `;

        panel.classList.remove('hidden');
        panel.classList.add('active');
    });
}

function closePlayerPanel() {
    const panel = document.getElementById('player-panel');
    panel.classList.remove('active');
    setTimeout(() => panel.classList.add('hidden'), 300);
}

document.getElementById('close-panel')?.addEventListener('click', closePlayerPanel);

// ============================================
// PLAYER ACTIONS
// ============================================

function playerAction(action, playerId) {
    switch(action) {
        case 'goto':
            post('goto', { playerId });
            break;
        case 'bring':
            post('bring', { playerId });
            break;
        case 'spectate':
            post('spectate', { playerId });
            closePlayerPanel();
            break;
        case 'freeze':
            post('freeze', { playerId, freeze: true });
            break;
        case 'revive':
            post('revive', { playerId });
            break;
        case 'heal':
            post('heal', { playerId });
            break;
        case 'kill':
            if (confirm('Tuer ce joueur ?')) {
                post('kill', { playerId });
            }
            break;
        case 'noclip':
            if (confirm('Toggle noclip pour ce joueur ?')) {
                post('noclip', { playerId });
            }
            break;
        case 'kick':
            const reason = prompt('Raison du kick:');
            if (reason) {
                post('kick', { playerId, reason });
            }
            break;
    }
}

function giveCarPlayer(playerId) {
    const model = prompt('Modèle du véhicule (ex: adder, t20, zentorno):', 'adder');
    if (model) {
        post('giveCar', { playerId, model });
    }
}

function warnPlayer(playerId) {
    const reason = prompt('Raison du warn:');
    if (reason) {
        post('warn', { playerId, reason, points: 1 });
    }
}

function banPlayer(playerId) {
    const reason = prompt('Raison du ban:');
    if (!reason) return;

    const type = confirm('Ban permanent ? (Annuler = temporaire)') ? 'permanent' : 'temp';
    const duration = type === 'temp' ? prompt('Durée en secondes:', '86400') : null;

    post('ban', { playerId, banType: type, reason, duration });
}

// ============================================
// QUICK ACTIONS
// ============================================

document.getElementById('btn-staffmode')?.addEventListener('click', () => {
    post('toggleStaffMode');
});

document.getElementById('btn-noclip')?.addEventListener('click', () => {
    post('noclip', { playerId: null }); // null = pour soi-même
});

document.getElementById('close-btn')?.addEventListener('click', () => {
    post('close');
});

// ============================================
// ESC KEY
// ============================================

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const app = document.getElementById('app');
        if (!app.classList.contains('hidden')) {
            post('close');
        }
    }
});

// ============================================
// READY
// ============================================

console.log('[B_ADMIN2] Modern NUI Ready');
