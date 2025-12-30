# 🛡️ B_ADMIN2 - Système d'Administration FiveM Ultime

**B_Admin2** est une ressource d'administration FiveM ultra-complète avec :
- ✅ Menu NUI in-game (HTML/CSS/JS vanilla, pas de React/build)
- ✅ Bot Discord pour admin à distance (WATCH télémétrie, pas de vraie caméra hors-jeu)
- ✅ Logging maximum (DB + Discord webhooks)
- ✅ Système RBAC (Role-Based Access Control) avec flags
- ✅ Système de tickets/reports avancé
- ✅ Spectate in-game avec overlay détaillé
- ✅ Staff Mode (noclip/god/invis)
- ✅ Actions economy/moderation/player/vehicle/world
- ✅ Anti-abus (rate-limits, whitelists, double confirm)

---

## 📋 Table des Matières

1. [Prérequis](#prérequis)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Permissions & RBAC](#permissions--rbac)
5. [Bot Discord](#bot-discord)
6. [Utilisation](#utilisation)
7. [Logging](#logging)
8. [Sécurité](#sécurité)
9. [Support](#support)

---

## 🔧 Prérequis

- **FiveM Server** avec ESX Legacy (dernière version)
- **ox_inventory** (obligatoire)
- **oxmysql** (obligatoire)
- **Node.js v18+** (pour le bot Discord)
- **Discord Application** (pour le bot)
- **MySQL/MariaDB** 5.7+

---

## 📦 Installation

### 1. Installer la ressource FiveM

```bash
# Copier b_admin2 dans votre dossier resources
cd /path/to/your/fivem-server/resources
git clone <votre-repo> b_admin2

# Ou télécharger et extraire le ZIP
```

### 2. Importer le schema SQL

```bash
# Via MySQL CLI
mysql -u root -p votre_database < b_admin2/sql/install.sql

# Ou via phpMyAdmin/HeidiSQL/etc
# Importer le fichier b_admin2/sql/install.sql
```

### 3. Ajouter à server.cfg

```bash
ensure b_admin2
```

### 4. Installer le bot Discord

```bash
cd b_admin2/discord-bot
npm install

# Copier et configurer .env
cp .env.example .env
nano .env  # Configurer les variables
```

### 5. Démarrer le bot Discord

```bash
# En production
npm start

# En développement (avec nodemon)
npm run dev

# Ou avec PM2 (recommandé)
pm2 start index.js --name "b_admin2-bot"
```

---

## ⚙️ Configuration

### Config FiveM (`config/config.lua`)

#### Général

```lua
Config.MenuKey = 'F10' -- Touche pour ouvrir le menu
Config.ServerName = 'Votre Serveur'
Config.ServerId = 'srv01'
```

#### Permissions Discord

```lua
-- Mapping Discord Role IDs -> Rank
Config.DiscordRoles = {
    ['1234567890123456789'] = 'helper',
    ['1234567890123456790'] = 'mod',
    ['1234567890123456791'] = 'admin',
    ['1234567890123456792'] = 'superadmin',
    ['1234567890123456793'] = 'owner'
}

-- Overrides par Discord User ID (optionnel)
Config.DiscordUserOverrides = {
    ['discord:123456789'] = { rank = 'owner', flags = {'*'} }
}
```

#### Discord Webhooks

Configurer les webhooks Discord pour les logs :

```lua
Config.Webhooks = {
    moderation = 'https://discord.com/api/webhooks/...',
    economy = 'https://discord.com/api/webhooks/...',
    player = 'https://discord.com/api/webhooks/...',
    staffmode = 'https://discord.com/api/webhooks/...',
    reports = 'https://discord.com/api/webhooks/...',
    security = 'https://discord.com/api/webhooks/...'
}
```

#### Discord Bot API

```lua
Config.DiscordBot = {
    Enabled = true,
    GuildId = 'YOUR_GUILD_ID',
    StaffChannelId = 'YOUR_STAFF_CHANNEL_ID',
    HMACSecret = 'CHANGE_ME_SUPER_SECRET_KEY', -- Identique au .env du bot
    RequestTTL = 30,
    AllowedRoles = { '...', '...' }
}
```

### Config Bot Discord (`.env`)

```env
DISCORD_TOKEN=YOUR_BOT_TOKEN
CLIENT_ID=YOUR_CLIENT_ID
GUILD_ID=YOUR_GUILD_ID
STAFF_CHANNEL_ID=YOUR_STAFF_CHANNEL_ID
FXSERVER_URL=http://localhost:30120
HMAC_SECRET=CHANGE_ME_SUPER_SECRET_KEY
ALLOWED_ROLES=1234567890,9876543210
```

---

## 🔐 Permissions & RBAC

### Ranks (héritage automatique)

1. **helper** - Basique (goto, bring, reports)
2. **mod** - Modération (spectate, freeze, warn, kick, ban temp)
3. **admin** - Administration (set job, clear inv, ban perma, vehicles, time/weather)
4. **superadmin** - Économie (give money/items/weapons)
5. **owner** - Tout (*) + Panic Mode

### Flags disponibles

```
admin.ui.open
admin.player.goto
admin.player.bring
admin.player.spectate
admin.player.watch_discord
admin.player.freeze
admin.player.revive
admin.player.heal
admin.player.clearinv
admin.player.setjob
admin.mod.warn
admin.mod.kick
admin.mod.ban.temp
admin.mod.ban.perma
admin.economy.give_money
admin.economy.remove_money
admin.economy.give_item
admin.economy.give_weapon
admin.vehicle.spawn
admin.vehicle.delete
admin.world.timeweather
admin.staffmode
admin.reports.manage
admin.devtools
```

### Ajouter des permissions manuellement (DB)

```sql
INSERT INTO z_admin_permissions (identifier, rank, flags, discord_id)
VALUES ('license:abc123', 'admin', '["admin.devtools"]', 'discord:123456789');
```

---

## 🤖 Bot Discord

### Créer l'Application Discord

1. Aller sur [Discord Developer Portal](https://discord.com/developers/applications)
2. Créer une nouvelle Application
3. Aller dans **Bot** → Créer un bot → Copier le Token
4. Activer **Intents** : `SERVER MEMBERS INTENT` (optionnel)
5. Aller dans **OAuth2** → Copier le Client ID
6. Inviter le bot : OAuth2 → URL Generator → Scopes: `bot` + `applications.commands` → Permissions: `Administrator`

### Commandes Discord

Toutes les commandes commencent par `/admin` :

- `/admin players` - Liste des joueurs en ligne
- `/admin info <id>` - Infos complètes sur un joueur
- `/admin watch <id> [duration]` - Démarre un WATCH (télémétrie live)
- `/admin unwatch <id>` - Arrête un WATCH
- `/admin screenshot <id>` - Demande un screenshot (si ressource dispo)
- `/admin warn <id> <reason>` - Warn un joueur
- `/admin kick <id> <reason>` - Kick un joueur
- `/admin ban <id> <type> <reason> [duration]` - Ban un joueur

### ⚠️ IMPORTANT : WATCH vs SPECTATE

**SPECTATE IN-GAME** :
- Vraie caméra GTA en direct attachée au joueur
- Nécessite d'être connecté au serveur FiveM
- Overlay détaillé (HP, armor, inventaire, véhicule, etc.)

**WATCH DISCORD** (Hors-jeu) :
- **PAS de caméra en direct** (impossible sans client FiveM)
- Télémétrie live (coords, zone, HP, armor, money, job, véhicule, ping)
- Updates toutes les 8 secondes (configurable)
- Timeline events (tirs, kill/death, véhicules, etc.)
- Screenshot à la demande (si joueur en ligne + ressource screenshot)

---

## 🎮 Utilisation

### Menu In-Game (F10)

1. **Dashboard** - Statistiques serveur, activité récente
2. **Players** - Liste joueurs, profil détaillé, actions rapides
3. **Moderation** - Warn/Kick/Ban (via profil joueur)
4. **Economy** - Give/Remove money/items/weapons (via profil joueur)
5. **Vehicles** - Spawn/Delete/Repair/Clean/Flip
6. **World** - Set Time/Weather
7. **Tickets** - Gestion des reports joueurs
8. **Staff Mode** - Toggle noclip/god/invis

### Profil Joueur

Depuis l'onglet **Players**, cliquer sur un joueur pour voir :
- Identifiers (license, Discord)
- Job/Grade
- Coords/Zone
- HP/Armor, Faim/Soif (si dispo)
- Money (Cash/Bank/Black)
- Inventaire ox_inventory (poids, top items, loadout)
- Véhicule actuel (modèle, plaque, vitesse)
- Notes staff
- Historique warns/bans

Actions rapides :
- Goto / Bring / Spectate / Freeze / Revive / Heal
- Warn / Kick / Ban
- Give Money / Items / Weapons
- Clear Inventory (double confirm)
- Set Job

### Spectate In-Game

1. Sélectionner un joueur → **Spectate**
2. Overlay top-bar : HP, armor, money, job, zone, véhicule
3. Sidebar (optionnel) : inventaire résumé, timeline
4. Pour arrêter : cliquer **Stop Spectate** ou appuyer sur ESC

### Staff Mode

Toggle Staff Mode active :
- Noclip (si configuré)
- God Mode
- Invisible
- Watermark discret "STAFF MODE"
- Tout loggé en DB + Discord

### Panic Mode (Owner)

Active le mode maintenance :
- Bloque economy (give money/items/weapons)
- Bloque spawn véhicules
- Bloque TP commands (optionnel)
- Notif tous les joueurs

---

## 📊 Logging

### Logs Staff (toujours actifs)

Toutes les actions staff sont loggées :
- Admin license + Discord ID + Rank
- Target license + Discord ID
- Action type, payload (montant/item/raison/coords)
- Success/Fail + raison
- Ticket ID (si lié)

**Destinations** :
- Base de données (`z_admin_actions`)
- Discord webhooks (embeds par catégorie)
- Console (si activé)

### Logs Player (optionnels, configurable)

Actions joueurs loggées (si activé) :
- Connect/Disconnect
- Enter/Exit Vehicle
- Weapon Fired
- Kill/Death
- Inventory (move/give/drop/use)
- Money Changes
- Commands
- Teleport suspect (delta distance)
- Speed suspect

**Destinations** :
- Base de données (`z_player_actions`)
- Discord webhook (si activé, attention spam)
- Console debug
- Fichier JSONL (optionnel)

### Catégories Discord

Les webhooks sont séparés par catégorie :
- `moderation` - Warn/Kick/Ban
- `economy` - Give/Remove money/items/weapons
- `player` - Goto/Bring/Spectate/Freeze/Revive
- `staffmode` - Toggle staff mode
- `reports` - Tickets/Reports
- `security` - Tentatives refusées, actions suspectes

---

## 🔒 Sécurité

### Anti-Abus

- **Rate Limits** : Cooldowns configurables par action (définis dans `Config.RateLimits`)
- **Whitelists** : Items/Weapons/Vehicles (sauf owner/superadmin)
- **Caps** : Montants max (economy), quantité max (items/ammo)
- **Double Confirmation** : Actions critiques (ban perma, clear inv, gros montants)
- **Server-Side Validation** : Toutes les actions critiques validées côté serveur
- **Logs Refusés** : Tentatives bloquées loggées (permissions, rate-limit)

### HMAC Signature (Bot Discord)

Le bot Discord communique avec le FXServer via un système HMAC sécurisé :
- Signature HMAC SHA256
- Nonce unique (anti-replay)
- TTL 30 secondes
- Whitelist Guild + Roles
- Vérification server-side

⚠️ **IMPORTANT** : Le `HMAC_SECRET` doit être identique dans :
- `config/config.lua` → `Config.DiscordBot.HMACSecret`
- `discord-bot/.env` → `HMAC_SECRET`

### Recommandations

1. **Changer le HMAC_SECRET** : Utilisez un secret fort (32+ caractères aléatoires)
2. **Configurer les Webhooks** : Remplacer `YOUR_WEBHOOK_ID/TOKEN` par vos vrais webhooks
3. **Limiter les Roles Discord** : Config `ALLOWED_ROLES` dans `.env`
4. **Audit régulier** : Vérifier les logs `z_admin_actions` pour détecter abus
5. **Backup DB** : Sauvegarder régulièrement les tables `z_admin_*`

---

## 📁 Structure des Fichiers

```
b_admin2/
├── fxmanifest.lua
├── README.md
├── config/
│   └── config.lua
├── server/
│   ├── main.lua
│   ├── permissions.lua
│   ├── logging.lua
│   ├── discord_api.lua
│   ├── tickets.lua
│   ├── utils/
│   │   └── rate_limit.lua
│   └── actions/
│       ├── player_actions.lua
│       ├── moderation.lua
│       └── economy.lua
├── client/
│   ├── main.lua
│   ├── nui.lua
│   ├── spectate.lua
│   └── staffmode.lua
├── nui/
│   ├── html/
│   │   └── index.html
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── app.js
├── discord-bot/
│   ├── index.js
│   ├── package.json
│   └── .env.example
└── sql/
    └── install.sql
```

---

## 🐛 Troubleshooting

### Menu ne s'ouvre pas (F10)

1. Vérifier que vous avez la permission `admin.ui.open`
2. Vérifier la touche dans `Config.MenuKey`
3. Vérifier console F8 pour erreurs

### Bot Discord ne répond pas

1. Vérifier que le bot est en ligne (`/admin players` doit fonctionner)
2. Vérifier `.env` (TOKEN, CLIENT_ID, GUILD_ID)
3. Vérifier que les commandes sont enregistrées (redémarrer le bot)
4. Vérifier permissions Discord (roles autorisés)

### WATCH ne fonctionne pas

1. Le WATCH est une **télémétrie**, pas une caméra
2. Vérifier que `Config.DiscordBot.Enabled = true`
3. Vérifier console FXServer pour erreurs API Discord
4. Le joueur doit être en ligne pour recevoir télémétrie

### Webhooks Discord ne fonctionnent pas

1. Vérifier que les URLs webhooks sont valides (pas `YOUR_WEBHOOK_ID`)
2. Vérifier que les webhooks ne sont pas rate-limités par Discord
3. Vérifier console FXServer pour erreurs HTTP

---

## 🆘 Support

- **Issues GitHub** : Rapporter bugs et suggestions
- **Discord** : [Votre serveur Discord support]
- **Wiki** : [Lien vers wiki si disponible]

---

## 📝 License

MIT License - Libre d'utilisation et modification.

---

## 🙏 Crédits

- **ESX Legacy** - Framework FiveM
- **ox_inventory** - Système d'inventaire
- **oxmysql** - Wrapper MySQL
- **discord.js** - Library Discord pour Node.js

---

## ✨ Fonctionnalités Uniques

### Système de Tickets Avancé

- Reports joueurs → staff
- Auto-assignment selon disponibilité
- Timeline des actions liées au ticket
- Catégories : cheat/bug/grief/help/abuse/other
- Priorités : low/normal/high/urgent (auto-detect via keywords)
- Rating post-résolution
- Historique complet en DB

### Overlay Spectate Discret

- Top-bar compacte (pas de panneau énorme)
- Refresh throttlé (500-1000ms configurable)
- Sidebar repliable : inventaire résumé + timeline
- Ghost mode : invincible/invisible/no collision

### RBAC Flexible

- Flags granulaires (pas juste admin/mod)
- Héritage automatique des ranks
- Overrides custom par joueur (DB ou Discord User ID)
- Cache TTL (5 min) pour perfs
- Fallback ACE optionnel

---

**Développé avec ❤️ pour la communauté FiveM**
