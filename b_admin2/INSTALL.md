# 🚀 Installation Rapide - B_ADMIN2

Guide d'installation en 5 minutes.

---

## 📋 Checklist Pré-Installation

- [ ] FiveM Server avec ESX Legacy
- [ ] ox_inventory installé et fonctionnel
- [ ] oxmysql configuré
- [ ] Accès MySQL/phpMyAdmin
- [ ] Node.js v18+ installé (pour bot Discord)
- [ ] Discord Bot créé (si admin Discord souhaité)

---

## ⚡ Installation Express

### 1. Installer la Ressource

```bash
# Copier b_admin2 dans resources/
cd /path/to/fivem-server/resources
# [Copier le dossier b_admin2 ici]
```

### 2. Base de Données

```sql
-- Importer sql/install.sql via phpMyAdmin ou CLI
mysql -u root -p votre_database < b_admin2/sql/install.sql
```

### 3. Configuration Minimale

Éditer `config/config.lua` :

```lua
-- Ligne 6: Nom de votre serveur
Config.ServerName = 'Votre Serveur RP'

-- Lignes 24-30: Mapper vos Discord Role IDs
Config.DiscordRoles = {
    ['YOUR_HELPER_ROLE_ID'] = 'helper',
    ['YOUR_MOD_ROLE_ID'] = 'mod',
    ['YOUR_ADMIN_ROLE_ID'] = 'admin',
    ['YOUR_SUPERADMIN_ROLE_ID'] = 'superadmin',
    ['YOUR_OWNER_ROLE_ID'] = 'owner'
}

-- Lignes 188-196: Configurer vos Webhooks Discord
Config.Webhooks = {
    moderation = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE',
    economy = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE',
    -- ... (remplacer YOUR_WEBHOOK_HERE par vos vrais webhooks)
}
```

### 4. Ajouter à server.cfg

```cfg
ensure b_admin2
```

### 5. Restart le Serveur

```bash
restart b_admin2
# Ou restart complet du serveur
```

---

## 🤖 Bot Discord (Optionnel)

### 1. Créer le Bot Discord

1. Aller sur https://discord.com/developers/applications
2. **New Application** → Nom: "B_Admin2 Bot"
3. **Bot** → **Add Bot** → Copier le **Token**
4. **OAuth2** → **URL Generator**:
   - Scopes: `bot`, `applications.commands`
   - Permissions: `Administrator`
   - Copier l'URL et inviter le bot sur votre serveur

### 2. Configurer .env

```bash
cd b_admin2/discord-bot
cp .env.example .env
nano .env
```

Remplir :
```env
DISCORD_TOKEN=YOUR_BOT_TOKEN_FROM_STEP_3
CLIENT_ID=YOUR_CLIENT_ID_FROM_OAUTH2
GUILD_ID=YOUR_DISCORD_SERVER_ID
STAFF_CHANNEL_ID=YOUR_STAFF_CHANNEL_ID
FXSERVER_URL=http://localhost:30120
HMAC_SECRET=ChangeMeSuperSecretKey123456789
ALLOWED_ROLES=ROLE_ID_1,ROLE_ID_2
```

### 3. Installer & Démarrer

```bash
npm install
npm start

# Ou avec PM2 (recommandé)
pm2 start index.js --name "b_admin2-bot"
```

### 4. Tester

Dans Discord, taper : `/admin players`

---

## ✅ Vérifications Post-Installation

### FiveM

1. Connecter au serveur
2. Appuyer sur **F10** → Le menu doit s'ouvrir
3. Si erreur permissions : Ajouter manuellement en DB ou via Discord Role

### Discord Bot

1. `/admin players` → Doit afficher la liste des joueurs
2. Si erreur : Vérifier console bot Node.js

### Webhooks

1. Effectuer une action admin in-game (ex: goto un joueur)
2. Vérifier que le log apparaît dans Discord (channel webhook moderation)

---

## 🔧 Problèmes Courants

### "No permission" in-game

**Solution** : Ajouter permissions manuellement en DB :

```sql
INSERT INTO z_admin_permissions (identifier, `rank`, discord_id)
VALUES ('license:votre_license', 'owner', 'discord:votre_discord_id');
```

Ou configurer `Config.DiscordRoles` avec vos Role IDs.

### Menu ne s'ouvre pas (F10)

**Solutions** :
- Vérifier console F8 pour erreurs
- Vérifier que la touche F10 n'est pas utilisée par une autre ressource
- Changer `Config.MenuKey` si besoin

### Bot Discord "Unknown interaction"

**Solutions** :
- Redémarrer le bot (les commandes prennent 1-2 min pour s'enregistrer)
- Vérifier que `CLIENT_ID` et `GUILD_ID` sont corrects
- Vérifier que le bot a la permission `applications.commands`

### Webhooks ne fonctionnent pas

**Solutions** :
- Vérifier que les URLs webhooks sont valides (remplacer `YOUR_WEBHOOK_HERE`)
- Vérifier que les webhooks ne sont pas désactivés/supprimés dans Discord
- Vérifier console FXServer pour erreurs HTTP

---

## 📚 Prochaines Étapes

1. **Configurer les permissions** : Mapper vos Discord Roles
2. **Configurer les Webhooks** : Créer webhooks par catégorie
3. **Tester les fonctionnalités** : Spectate, Staff Mode, Moderation
4. **Configurer le Bot Discord** : Tester WATCH, screenshot, moderation
5. **Personnaliser** : Whitelists véhicules/items/weapons, rate-limits, etc.

---

## 🆘 Besoin d'Aide ?

- **README.md** : Documentation complète
- **GitHub Issues** : Rapporter bugs
- **Discord Support** : [Votre lien Discord]

---

**Installation terminée ! 🎉**

Appuyer sur **F10** in-game pour ouvrir le menu admin.
