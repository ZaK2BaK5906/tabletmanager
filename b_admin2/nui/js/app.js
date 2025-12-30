// ============================================
// B_ADMIN2 ULTIMATE - Complete Admin Menu
// ============================================

let players = [];
let selectedPlayer = null;

// ============================================
// UTILITY FUNCTIONS
// ============================================

function post(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(res => res.json()).catch(() => null);
}

function GetParentResourceName() {
    const match = window.location.href.match(/https?:\/\/([^\/]+)\//);
    return match ? match[1] : 'b_admin2';
}

// ============================================
// NUI MESSAGE HANDLER
// ============================================

window.addEventListener('message', (event) => {
    const { action, visible } = event.data;

    if (action === 'toggle') {
        const app = document.getElementById('app');
        if (visible) {
            app.classList.remove('hidden');
            loadPlayers();
        } else {
            app.classList.add('hidden');
        }
    }
});

// ============================================
// LOAD PLAYERS
// ============================================

function loadPlayers() {
    post('getPlayers').then(data => {
        if (!data) return;
        players = data;
        renderPlayers();
        document.getElementById('player-count').textContent = players.length;
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
        const item = document.createElement('div');
        item.className = 'player-item-compact';
        if (selectedPlayer && selectedPlayer.id === player.id) {
            item.classList.add('active');
        }

        item.innerHTML = `
            <div class="player-name-compact">${player.name}</div>
            <div class="player-meta-compact">ID: ${player.id} • ${player.ping}ms</div>
        `;

        item.addEventListener('click', () => selectPlayer(player.id));
        list.appendChild(item);
    });
}

// ============================================
// SELECT PLAYER
// ============================================

function selectPlayer(playerId) {
    post('getPlayerData', { playerId }).then(data => {
        if (!data) return;

        selectedPlayer = data;

        // Update UI
        const panel = document.getElementById('player-info-panel');
        const actions = document.getElementById('actions-panel');

        panel.classList.remove('hidden');
        actions.classList.remove('hidden');

        // Update header
        const initial = data.name.charAt(0).toUpperCase();
        document.getElementById('player-avatar').textContent = initial;
        document.getElementById('player-name-display').textContent = data.name;
        document.getElementById('player-id-display').textContent = `ID: ${data.id}`;

        // Update general tab
        document.getElementById('p-license').textContent = data.license || 'N/A';
        document.getElementById('p-job').textContent = `${data.job} [${data.grade}]`;
        document.getElementById('p-ping').textContent = `${data.ping}ms`;
        document.getElementById('p-health').textContent = data.health || 0;
        document.getElementById('p-armor').textContent = data.armor || 0;
        document.getElementById('p-cash').textContent = `$${data.money?.cash || 0}`;
        document.getElementById('p-bank').textContent = `$${data.money?.bank || 0}`;
        document.getElementById('p-black').textContent = `$${data.money?.black || 0}`;

        // Update inventory tab
        document.getElementById('p-weight').textContent = `${data.inventory?.weight || 0}/${data.inventory?.maxWeight || 0}`;

        // Update moderation tab
        document.getElementById('p-warns-count').textContent = data.warns?.length || 0;
        document.getElementById('p-bans-count').textContent = data.bans?.length || 0;

        renderPlayers(); // Re-render to show active state
    });
}

// ============================================
// CLOSE PLAYER PANEL
// ============================================

document.getElementById('close-player-panel')?.addEventListener('click', () => {
    document.getElementById('player-info-panel').classList.add('hidden');
    document.getElementById('actions-panel').classList.add('hidden');
    selectedPlayer = null;
    renderPlayers();
});

// ============================================
// TABS
// ============================================

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.getAttribute('data-tab');

        // Remove active from all
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

        // Add active to clicked
        btn.classList.add('active');
        document.getElementById(`tab-${tab}`).classList.add('active');
    });
});

// ============================================
// SEARCH
// ============================================

document.getElementById('player-search')?.addEventListener('input', renderPlayers);

// ============================================
// ACTIONS ON PLAYER
// ============================================

function action(actionType) {
    if (!selectedPlayer) return;

    const id = selectedPlayer.id;

    switch(actionType) {
        // Teleport
        case 'goto':
            post('goto', { playerId: id });
            break;
        case 'bring':
            post('bring', { playerId: id });
            break;
        case 'tpm':
        case 'tptome':
            post('bring', { playerId: id });
            break;

        // Player Actions
        case 'revive':
            post('revive', { playerId: id });
            break;
        case 'heal':
            post('heal', { playerId: id });
            break;
        case 'freeze':
            post('freeze', { playerId: id, freeze: true });
            break;
        case 'unfreeze':
            post('freeze', { playerId: id, freeze: false });
            break;
        case 'spectate':
            post('spectate', { playerId: id });
            break;
        case 'noclip':
            post('noclip', { playerId: id });
            break;
        case 'kill':
            if (confirm(`Kill ${selectedPlayer.name}?`)) {
                post('kill', { playerId: id });
            }
            break;
        case 'slap':
            post('slap', { playerId: id });
            break;
        case 'drunk':
            post('drunk', { playerId: id });
            break;
        case 'drug':
            post('drug', { playerId: id });
            break;
        case 'ragdoll':
            post('ragdoll', { playerId: id });
            break;
        case 'fling':
            post('fling', { playerId: id });
            break;

        // Vehicle
        case 'givecar':
            const model = prompt('Vehicle model:', 'adder');
            if (model) post('giveCar', { playerId: id, model });
            break;
        case 'fixveh':
            post('fixvehicle', { playerId: id });
            break;
        case 'delveh':
            post('delvehicle', { playerId: id });
            break;
        case 'flipveh':
            post('flipvehicle', { playerId: id });
            break;

        // Inventory
        case 'openinv':
            post('openinventory', { playerId: id });
            break;
        case 'clearinv':
            if (confirm(`Clear inventory of ${selectedPlayer.name}?`)) {
                post('clearinv', { playerId: id, confirmed: true });
            }
            break;
        case 'giveitem':
            const item = prompt('Item name:');
            const qty = prompt('Quantity:', '1');
            if (item) post('giveitem', { playerId: id, item, quantity: parseInt(qty) });
            break;
        case 'giveweapon':
            const weapon = prompt('Weapon name (ex: weapon_pistol):');
            const ammo = prompt('Ammo:', '250');
            if (weapon) post('giveweapon', { playerId: id, weapon, ammo: parseInt(ammo) });
            break;
        case 'stripweapons':
            post('stripweapons', { playerId: id });
            break;

        // Money
        case 'givemoney':
            const giveAmt = prompt('Amount:');
            const giveAcc = prompt('Account (cash/bank/black):', 'cash');
            if (giveAmt) post('givemoney', { playerId: id, amount: parseInt(giveAmt), account: giveAcc });
            break;
        case 'removemoney':
            const removeAmt = prompt('Amount:');
            const removeAcc = prompt('Account (cash/bank/black):', 'cash');
            if (removeAmt) post('removemoney', { playerId: id, amount: parseInt(removeAmt), account: removeAcc });
            break;
        case 'setcash':
            const cash = prompt('Cash amount:');
            if (cash) post('setmoney', { playerId: id, amount: parseInt(cash), account: 'cash' });
            break;
        case 'setbank':
            const bank = prompt('Bank amount:');
            if (bank) post('setmoney', { playerId: id, amount: parseInt(bank), account: 'bank' });
            break;

        // Job
        case 'setjob':
            const job = prompt('Job name (ex: police):');
            const grade = prompt('Grade:', '0');
            if (job) post('setjob', { playerId: id, job, grade: parseInt(grade) });
            break;
        case 'firejob':
            post('setjob', { playerId: id, job: 'unemployed', grade: 0 });
            break;

        // Moderation
        case 'warn':
            const warnReason = prompt('Warn reason:');
            if (warnReason) post('warn', { playerId: id, reason: warnReason, points: 1 });
            break;
        case 'kick':
            const kickReason = prompt('Kick reason:');
            if (kickReason) post('kick', { playerId: id, reason: kickReason });
            break;
        case 'ban':
            const banReason = prompt('Ban reason:');
            if (!banReason) return;
            const banType = confirm('Permanent ban? (Cancel = Temporary)') ? 'permanent' : 'temp';
            const duration = banType === 'temp' ? prompt('Duration (seconds):', '86400') : null;
            post('ban', { playerId: id, reason: banReason, banType, duration: parseInt(duration) });
            break;
        case 'unban':
            post('unban', { license: selectedPlayer.license });
            break;
        case 'screenshot':
            post('screenshot', { playerId: id });
            break;
        case 'pm':
            const pmMsg = prompt('Private message:');
            if (pmMsg) post('pm', { playerId: id, message: pmMsg });
            break;
        case 'clearwarns':
            if (confirm(`Clear all warns for ${selectedPlayer.name}?`)) {
                post('clearwarns', { license: selectedPlayer.license });
            }
            break;

        // Admin
        case 'setadmin':
            const rank = prompt('Admin rank (user/helper/mod/admin/superadmin/owner):', 'mod');
            if (rank) post('setadmin', { playerId: id, rank });
            break;
        case 'removeadmin':
            if (confirm(`Remove admin from ${selectedPlayer.name}?`)) {
                post('setadmin', { playerId: id, rank: 'user' });
            }
            break;
        case 'viewperms':
            post('viewperms', { playerId: id });
            break;
    }
}

// ============================================
// STAFF ACTIONS (SELF)
// ============================================

function staffAction(action) {
    switch(action) {
        case 'staffmode':
            post('toggleStaffMode');
            break;
        case 'noclip-self':
            post('noclip', { playerId: null });
            break;
        case 'godmode':
            post('staffself', { action: 'godmode' });
            break;
        case 'invisible':
            post('staffself', { action: 'invisible' });
            break;
        case 'changeped':
            const ped = prompt('Ped model (ex: a_m_m_business_01):');
            if (ped) post('staffself', { action: 'changeped', data: ped });
            break;
        case 'clothesmenu':
            post('staffself', { action: 'clothesmenu' });
            break;
        case 'superjump':
            post('staffself', { action: 'superjump' });
            break;
        case 'fastrun':
            post('staffself', { action: 'fastrun' });
            break;
        case 'fastswim':
            post('staffself', { action: 'fastswim' });
            break;
        case 'noragdoll':
            post('staffself', { action: 'noragdoll' });
            break;
        case 'infinitestamina':
            post('staffself', { action: 'infinitestamina' });
            break;
        case 'setarmor':
            post('staffself', { action: 'setarmor', data: 100 });
            break;
        case 'sethealth':
            post('staffself', { action: 'sethealth', data: 200 });
            break;
        case 'clearwanted':
            post('staffself', { action: 'clearwanted' });
            break;
        case 'spawnveh':
            const veh = prompt('Vehicle model:', 'adder');
            if (veh) post('staffself', { action: 'spawnveh', data: veh });
            break;
        case 'fixveh':
            post('staffself', { action: 'fixveh' });
            break;
        case 'delveh':
            post('staffself', { action: 'delveh' });
            break;
        case 'tpwaypoint':
            post('staffself', { action: 'tpwaypoint' });
            break;
        case 'tpcoords':
            const x = prompt('X:');
            const y = prompt('Y:');
            const z = prompt('Z:');
            if (x && y && z) post('staffself', { action: 'tpcoords', data: { x: parseFloat(x), y: parseFloat(y), z: parseFloat(z) } });
            break;
        case 'savepos':
            post('staffself', { action: 'savepos' });
            break;
        case 'loadpos':
            post('staffself', { action: 'loadpos' });
            break;
        case 'showcoords':
            post('staffself', { action: 'showcoords' });
            break;
        case 'reviveself':
            post('staffself', { action: 'reviveself' });
            break;
        case 'healself':
            post('staffself', { action: 'healself' });
            break;
        case 'giveallweapons':
            post('staffself', { action: 'giveallweapons' });
            break;
        case 'removeallweapons':
            post('staffself', { action: 'removeallweapons' });
            break;
    }
}

// ============================================
// STAFF MENU MODAL
// ============================================

function openStaffMenu() {
    document.getElementById('staff-menu-modal').classList.remove('hidden');
}

function closeStaffMenu() {
    document.getElementById('staff-menu-modal').classList.add('hidden');
}

// ============================================
// CLOSE MENU
// ============================================

function closeMenu() {
    post('close');
}

// ============================================
// ESC KEY
// ============================================

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const modal = document.getElementById('staff-menu-modal');
        if (!modal.classList.contains('hidden')) {
            closeStaffMenu();
        } else {
            closeMenu();
        }
    }
});

// ============================================
// READY
// ============================================

console.log('[B_ADMIN2] Ultimate Admin Menu Ready - 40+ Features');
