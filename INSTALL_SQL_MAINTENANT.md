# 🚨 INSTALLATION SQL OBLIGATOIRE - À FAIRE MAINTENANT !

## ⚠️ PROBLÈME ACTUEL

La MDT s'ouvre mais **ne charge aucune donnée** car les tables SQL n'existent pas encore !

---

## ✅ SOLUTION (2 COMMANDES)

### Méthode 1: Ligne de commande MySQL

```bash
# 1. Se connecter à MySQL
mysql -u root -p

# 2. Utiliser votre base de données
USE votre_base_de_donnees;

# 3. Exécuter le cleanup (supprime anciennes tables)
SOURCE /home/user/tabletmanager/zx_police_mdt_cleanup.sql;

# 4. Exécuter l'installation (crée 18 tables + 30 charges)
SOURCE /home/user/tabletmanager/zx_police_mdt_install.sql;

# 5. Vérifier que les tables existent
SHOW TABLES LIKE 'zx_police%';
```

Vous devriez voir **18 tables** :
- zx_police_calls
- zx_police_reports
- zx_police_arrests
- zx_police_citations
- zx_police_bolo
- zx_police_warrants
- zx_police_wanted
- zx_police_evidence
- zx_police_notes
- zx_police_ppa
- zx_police_ppa_heavy
- zx_police_stolen_vehicles
- zx_police_charges
- zx_police_units
- zx_police_personnel
- zx_police_intel
- zx_police_webhooks
- zx_police_activity_log

---

### Méthode 2: PhpMyAdmin / HeidiSQL

1. Ouvrir PhpMyAdmin
2. Sélectionner votre base de données
3. Aller dans "Importer"
4. Charger `/home/user/tabletmanager/zx_police_mdt_cleanup.sql`
5. Exécuter
6. Charger `/home/user/tabletmanager/zx_police_mdt_install.sql`
7. Exécuter

---

### Méthode 3: Commande directe (la plus simple)

```bash
# Remplacez 'votre_base' par votre nom de base de données
mysql -u root -p votre_base < /home/user/tabletmanager/zx_police_mdt_cleanup.sql
mysql -u root -p votre_base < /home/user/tabletmanager/zx_police_mdt_install.sql
```

---

## 🔧 APRÈS L'INSTALLATION

```bash
# Restart la ressource MDT
restart zmdt
```

Puis testez :
1. `/tablette`
2. Cliquer "MDT"
3. **Maintenant ça devrait charger des données !**

---

## 📊 CE QUI SERA CRÉÉ

### 18 Tables
Toutes préfixées `zx_police_*` pour éviter les conflits

### 30 Charges Pénales
- 10 Traffic violations
- 10 Misdemeanors
- 10 Felonies

### 8 Webhooks Discord
Configurables dans `zmdt/config.lua`

---

## ⚡ VÉRIFICATION RAPIDE

Pour vérifier que tout est installé :

```sql
SELECT COUNT(*) FROM zx_police_charges;
```

Devrait retourner **30** (les charges pré-configurées)

---

## 🐛 SI PROBLÈME

Si vous voyez des erreurs du type :
- `Table 'zx_police_calls' doesn't exist`
- `Unknown column in field list`

C'est que le SQL n'a pas été exécuté correctement.

**Solution:**
1. Vérifiez le nom de votre base de données
2. Vérifiez les permissions MySQL
3. Relancez les commandes SQL

---

## 📞 DEBUG

Après avoir exécuté le SQL et restart zmdt, ouvre la console F8 :

Tu devrais voir :
```
[MDT DEBUG] Opening MDT with service: police
[MDT DEBUG] Initial data received: {user: {...}, ...}
[MDT DEBUG] Loading police dashboard...
```

Et dans les logs serveur (txAdmin) :
```
[ZMDT DEBUG] Loading initial data for VotreNom (service: police)
[ZMDT DEBUG] Loading police initial data...
[ZMDT DEBUG] Loaded 0 active calls
[ZMDT DEBUG] Loaded 0 active BOLOs
[ZMDT DEBUG] Sending initial data to client...
```

---

**MAINTENANT, EXÉCUTE LE SQL ET TESTE !** 🚀
