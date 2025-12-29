# 🚔 MDT - Mobile Data Terminal

## Installation Rapide

### 1️⃣ Base de Données

```bash
# Dans l'ordre:
source ../mdt_schema.sql          # Tables principales (52 tables)
source ../mdt_permissions.sql     # Permissions (9 tables + 54 permissions)
source ../mdt_default_permissions.sql  # Permissions par défaut
source install.sql                # Données immersion + charges pénales
```

### 2️⃣ Server.cfg

```lua
ensure zmdt
```

### 3️⃣ Restart

```
restart zmdt
```

---

## 📋 Contenu Immersif

### ✅ Ce qui est installé:

**Tables Immersion:**
- ✅ `mdt_citations` - Tickets/Amendes avec montants
- ✅ `mdt_citizen_notes` - Notes des officiers sur citoyens
- ✅ `mdt_officer_status` - Codes 10 (10-8, 10-6, 10-97...)
- ✅ `mdt_charges` - 30+ charges pénales (PC-187, VC-22350...)
- ✅ `mdt_criminal_history` - Casier judiciaire complet

**Données Seed:**
- ✅ 30+ charges pénales (Felonies, Misdemeanors, Traffic, Infractions)
- ✅ 3 officiers exemples avec codes 10
- ✅ 3 notes citoyens exemples
- ✅ 3 citations exemples

**Vues SQL:**
- ✅ `mdt_citizen_full_record` - Casier complet citoyen
- ✅ `mdt_active_personnel` - Personnel en service
- ✅ `mdt_unpaid_citations` - Citations impayées

---

## 🎯 Fonctionnalités Police

### 8 Onglets Complets:

1. **📞 CAD** - Dispatch 911
   - Créer des appels
   - Priorités (Low/Medium/High)
   - Broadcast à tous les policiers

2. **🔍 Recherche** - Recherche instantanée
   - **Citoyens:** Casier, Citations, Notes, Véhicules
   - **Véhicules:** Owner, Status, Parking
   - **Armes:** Serial, Type

3. **📝 Rapports** - Reports
   - Incident, Arrest, Traffic, Investigation, Use of Force
   - Numéros uniques auto-générés
   - Niveaux de confidentialité

4. **⚠️ BOLO** - Be On Lookout
   - Person / Vehicle / Other
   - Priorités + Flag "Armed"
   - Broadcast temps réel

5. **⚖️ Arrestations** - Arrests
   - Stats aujourd'hui / semaine
   - Charges appliquées
   - Temps de peine

6. **🚗 Véhicules** - Vehicle Management
   - Stats volés / fourrières
   - Recherche rapide plaque
   - Impound status

7. **📦 Preuves** - Evidence
   - Log preuves
   - Stats en stock / analyse
   - Scènes de crime

8. **👮 Personnel** - Staff
   - Qui est en service
   - Unités actives
   - Appels en cours

---

## 📊 Recherche Enrichie

Quand tu cherches un citoyen, tu vois **automatiquement:**

```
🧑 John Doe
📅 DOB: 01/15/1990 | ♂️ Male | 📏 6'2"
📱 555-1234 | 💼 Unemployed

⚖️ Charges Criminelles: 3
📋 Citations Impayées: 2 ($650.00)
⚠️ Notes Flaggées: 1
🚗 Véhicules Possédés: 2
```

---

## 💰 Charges Pénales Incluses

### Felonies (15 ans+):
- PC-187: Meurtre 1er degré (300 mois)
- PC-211: Vol à main armée (120 mois)
- PC-215: Tentative meurtre (180 mois)
- PC-487: Grand vol (60 mois)
- HS-11351: Trafic de drogue (180 mois)

### Misdemeanors (< 24 mois):
- PC-242: Coups et blessures (12 mois)
- PC-148: Résistance arrestation (24 mois)
- PC-647: Ivresse publique (0 mois)

### Traffic:
- VC-23152: DUI ($5K-$10K, 12 mois)
- VC-2800: Refus d'obtempérer ($5K-$15K, 24 mois)
- VC-22350: Excès vitesse ($200-$500)

### Infractions:
- INF-001: Stationnement interdit ($150-$300)
- INF-003: Téléphone au volant ($200-$350)

---

## 🎮 Codes 10 (Police Radio)

- **10-4** - Message reçu
- **10-6** - Occupé
- **10-7** - Hors service
- **10-8** - En service
- **10-15** - Suspect en garde à vue
- **10-20** - Position
- **10-97** - Arrivé sur les lieux
- **10-99** - Officier demande assistance (urgent)

---

## 🔒 Permissions

**Tous les officiers peuvent:**
- Voir CAD
- Créer appels/rapports/BOLO
- Rechercher citoyens/véhicules
- Créer citations
- Ajouter notes
- Mettre à jour status (10-8, 10-6...)

**Superviseurs peuvent (grade 4+):**
- Modifier tous les rapports
- Approuver warrants
- Dismisser citations
- Voir logs d'accès

---

## 📝 Notes Officiers

**Types de notes:**
- 🟦 **Info** - Information générale
- 🟨 **Caution** - Approcher avec prudence
- 🟧 **Warning** - Comportement dangereux
- 🟥 **Threat** - Menace sérieuse

**Notes flaggées** = Affichées en priorité lors des recherches

---

## 🚀 Prochaines Étapes

Pour encore plus d'immersion:
- [ ] Ajouter photos dans BOLO
- [ ] GPS sur appels CAD
- [ ] Système de dispatch automatique
- [ ] Intégration casier avec charges
- [ ] Export PDF rapports
- [ ] Body cam footage links
- [ ] Interview recordings

---

## 🐛 Debug

**Vérifier l'installation:**
```sql
-- Tables MDT
SELECT COUNT(*) FROM information_schema.tables
WHERE table_name LIKE 'mdt_%';
-- Doit retourner: 61+ tables

-- Charges pénales
SELECT COUNT(*) FROM mdt_charges;
-- Doit retourner: 30+

-- Permissions
SELECT job_name, COUNT(*) FROM mdt_job_permissions GROUP BY job_name;
-- Doit voir: police, sheriff, doj, ambulance
```

**Logs serveur:**
```
[ZMDT] Synchronized X players to mdt_citizens
[ZMDT] Police server loaded
[ZMDT] Permissions system loaded
```

---

**Enjoy le MDT immersif ! 🎉**
