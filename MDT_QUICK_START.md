# 🚀 MDT - Guide Installation Rapide

## 📋 Étape 1: Installer la Base de Données

**Dans cet ordre précis:**

```bash
# 1. Schéma principal (52 tables)
source mdt_schema.sql

# 2. Permissions (9 tables + 54 permissions)
source mdt_permissions.sql

# 3. Permissions par défaut (NOUVEAU!)
source mdt_default_permissions.sql
```

> ⚠️ **Important:** Si tu as déjà installé les 2 premiers, installe juste le 3ème

---

## 🔄 Étape 2: Redémarrer la Ressource

```
restart zmdt
```

Tu devrais voir dans la console:
```
[ZMDT] Synchronized X players to mdt_citizens
```

---

## ✅ Étape 3: Tester

1. **Ouvrir la tablette** : `/tablette`
2. **Cliquer sur le bouton MDT** (🛡️ icône bouclier)
3. **Tu devrais voir 4 onglets Police:**
   - 📞 **CAD** - Appels 911
   - 🔍 **Search** - Rechercher citoyens/véhicules/armes
   - 📝 **Reports** - Créer des rapports
   - ⚠️ **BOLO** - Be On Lookout

---

## 🎯 Comment Utiliser le MDT

### 📞 Créer un Appel 911 (CAD)
1. Tab **CAD**
2. Bouton **"+ Nouvel Appel"**
3. Remplir: Type (10-31, 10-50...), Priorité, Location, Description
4. **Submit** → L'appel apparaît pour tous les policiers

### 🔍 Rechercher un Citoyen
1. Tab **Search**
2. Section **"Recherche Citoyens"**
3. Tape le nom (ex: "John")
4. Les résultats s'affichent automatiquement

> 💡 **Note:** Si aucun résultat, c'est normal - il faut que les joueurs se connectent pour être sync dans `mdt_citizens`

### 📝 Créer un Rapport
1. Tab **Reports**
2. Bouton **"+ Nouveau Rapport"**
3. Choisir type: Incident, Arrest, Traffic, Investigation, Use of Force
4. Remplir les détails + niveau confidentialité
5. **Submit** → Rapport créé avec numéro unique

### ⚠️ Créer un BOLO
1. Tab **BOLO**
2. Bouton **"+ Nouveau BOLO"**
3. Type: Person / Vehicle / Other
4. Sujet, priorité, description
5. Cocher "Suspect Armé" si nécessaire
6. **Submit** → BOLO broadcast à tous les policiers

---

## 🐛 Dépannage

### "Je ne vois aucun résultat dans les recherches"
- **Normal si c'est la 1ère fois !**
- Les citoyens sont sync automatiquement quand ils se connectent
- Pour forcer le sync: `restart zmdt` (ça sync tous les joueurs connectés)

### "Je ne peux rien créer" / "Permission denied"
- Vérifie que tu as bien installé `mdt_default_permissions.sql`
- Vérifie ton job: `police`, `sheriff`, `state_police` sont supportés
- Check console pour erreurs SQL

### "Je ne vois que 4 onglets"
- **C'est normal pour la Police !**
- Tu as: CAD, Search, Reports, BOLO
- Les autres features (Arrests, Citations, Evidence) seront ajoutées plus tard
- DOJ a 3 onglets: Cases, Warrants, Hearings
- EMS a 3 onglets: Dispatch, Patients, ePCR

### "Les formulaires ne fonctionnent pas"
1. Ouvre F8 (console)
2. Tape: `resmon` pour voir si zmdt tourne
3. Check console serveur pour erreurs SQL
4. Vérifie que les tables existent: `SHOW TABLES LIKE 'mdt_%';`

---

## 📊 Vérifier l'Installation

**Console MySQL:**
```sql
-- Vérifier les tables
SELECT COUNT(*) as total_tables FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name LIKE 'mdt_%';
-- Devrait retourner: 61 tables

-- Vérifier les permissions
SELECT job_name, COUNT(*) as permissions
FROM mdt_job_permissions
GROUP BY job_name;
-- Tu devrais voir police, sheriff, state_police, doj, ambulance, fire

-- Vérifier les citoyens sync
SELECT COUNT(*) FROM mdt_citizens;
-- Devrait correspondre au nombre de joueurs
```

---

## 🎨 Personnalisation

### Ajouter des Permissions Custom
```sql
-- Donner une permission spéciale à un joueur
INSERT INTO mdt_user_permissions (user_identifier, permission_id, granted)
VALUES (
    'steam:110000XXXXX',
    (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.reports.edit_all'),
    1
);
```

### Bloquer une Action pour un Grade
```sql
-- Empêcher les recrues (grade 0) de créer des BOLO
INSERT INTO mdt_blocked_actions (job_name, job_grade, action_key, is_blocked, reason)
VALUES ('police', 0, 'police.bolo.create', 1, 'Réservé aux officiers confirmés');
```

---

## 📚 Commandes Utiles

```lua
-- Ouvrir le MDT directement
/mdt

-- Créer un BOLO rapide
/bolo Suspect armé, veste rouge, près de Legion Square

-- Marquer quelqu'un wanted (Police uniquement)
/wanted [player_id]
```

---

## 🔜 Prochaines Features (TODO)

- [ ] Photos / Evidence upload
- [ ] GPS sur les appels CAD
- [ ] Système de dispatch automatique
- [ ] Intégration avec casier judiciaire
- [ ] Notifications temps réel (BOLO, Wanted)
- [ ] Recherche avancée multi-critères
- [ ] Export PDF des rapports
- [ ] Completer DOJ (Cases, Warrants complètes)
- [ ] Completer EMS (ePCR, Patient records)

---

## ⚡ Support

**Erreur SQL ?** → Vérifie l'ordre d'installation des fichiers SQL
**Permission denied ?** → Installe `mdt_default_permissions.sql`
**Pas de données ?** → `restart zmdt` pour sync les joueurs

**Tout fonctionne ?** → Profite bien du MDT ! 🎉
