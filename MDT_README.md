# 🚨 SYSTÈME MDT (Mobile Data Terminal)
## Pour Police, DOJ et EMS

---

## 📋 STRUCTURE DU PROJET

Ce système MDT est **séparé** de la tablette entreprise actuelle. C'est un système complet de gestion pour les services publics (Police, DOJ, EMS).

### Architecture recommandée :
```
resources/
├── ztablet/              # Système actuel (tablette entreprise)
└── zmdt/                 # NOUVEAU - Système MDT (à créer)
    ├── fxmanifest.lua
    ├── config.lua
    ├── client/
    │   ├── main.lua
    │   ├── police.lua
    │   ├── doj.lua
    │   └── ems.lua
    ├── server/
    │   ├── main.lua
    │   ├── police.lua
    │   ├── doj.lua
    │   └── ems.lua
    ├── html/
    │   ├── index.html
    │   ├── police.html
    │   ├── doj.html
    │   ├── ems.html
    │   ├── style.css
    │   └── script.js
    └── mdt_schema.sql     # ← Le fichier SQL créé
```

---

## 🗄️ BASE DE DONNÉES

### Tables créées (52 tables au total)

#### **TABLES PARTAGÉES (4)**
- `mdt_citizens` - Profils citoyens centralisés
- `mdt_attachments` - Pièces jointes (photos, docs, bodycam)
- `mdt_activity_log` - Logs d'audit
- `mdt_notes` - Notes partagées

#### **POLICE (28 tables)**
**CAD / Dispatch:**
- `mdt_calls` - Appels 911/CAD
- `mdt_units` - Unités/patrouilles et statuts

**Recherches & Registres:**
- `mdt_vehicles` - Véhicules enregistrés
- `mdt_weapons` - Registre armes
- `mdt_businesses` - Entreprises
- `mdt_licenses` - Licences & permis
- `mdt_ppa_ccw` - Port d'arme dissimulé

**Casier & Infractions:**
- `mdt_criminal_records` - Casier judiciaire
- `mdt_citations` - Amendes/citations

**Rapports & Incidents:**
- `mdt_arrests` - Arrestations
- `mdt_reports` - Rapports police
- `mdt_use_of_force` - Use of force
- `mdt_pursuits` - Poursuites

**BOLO / Wanted:**
- `mdt_bolo` - Be On Lookout
- `mdt_wanted` - Avis de recherche

**Saisies & Preuves:**
- `mdt_impounds` - Saisies véhicules
- `mdt_evidence` - Preuves & scellés

**Scènes & Témoins:**
- `mdt_scenes` - Scènes/incidents
- `mdt_witnesses` - Témoins

**Autres:**
- `mdt_gangs` - Intelligence gangs
- `mdt_personnel` - Gestion personnel

#### **DOJ (14 tables)**
- `mdt_cases` - Dossiers/affaires
- `mdt_charges` - Charges/accusations
- `mdt_probable_cause` - Probable cause statements
- `mdt_subpoenas` - Convocations
- `mdt_hearings` - Audiences
- `mdt_hearing_minutes` - Minutes d'audience
- `mdt_bail` - Caution
- `mdt_plea_deals` - Accords
- `mdt_judgments` - Jugements
- `mdt_probation` - Probation/parole
- `mdt_motions` - Motions
- `mdt_expungement` - Scellage

#### **PARTAGÉES POLICE/DOJ (2)**
- `mdt_warrants` - Mandats
- `mdt_orders` - Ordonnances (protective, restraining)

#### **EMS (14 tables)**
**Dispatch:**
- `mdt_ems_calls` - Appels EMS
- `mdt_ems_units` - Unités EMS

**Patients:**
- `mdt_patients` - Patients
- `mdt_medical_records` - Dossiers médicaux

**Interventions:**
- `mdt_vitals` - Examens vitaux
- `mdt_epcr` - Rapports médicaux (ePCR)
- `mdt_trauma` - Trauma/triage
- `mdt_medication` - Médication

**Transport & Hospitalisation:**
- `mdt_transport` - Transports
- `mdt_hospitalizations` - Hospitalisations

**Santé mentale & Décès:**
- `mdt_mental_health` - 5150 holds
- `mdt_deaths` - Morgue/décès

**Certificats & Suivi:**
- `mdt_certificates` - Certificats
- `mdt_patient_followup` - Suivi patients
- `mdt_medical_inventory` - Inventaire médical

---

## 🔑 DONNÉES CROISÉES

### Partage Police ↔ DOJ
- Casier judiciaire (Police écrit, DOJ valide)
- Rapports police (Police écrit, DOJ lit/approuve)
- Mandats (DOJ crée, Police exécute)
- Preuves (Police saisit, DOJ vérifie admissibilité)
- Ordonnances (DOJ crée, Police enforce)

### Partage EMS ↔ Police
- Flags patients (violent, suicidal)
- Certificats décès
- 5150 holds (EMS init, Police transport)
- Fit/Unfit duty (EMS écrit, Police lit)

### Partage EMS ↔ DOJ
- Décès (lecture DOJ)
- Santé mentale (lecture DOJ si procédure)

---

## 🔒 PERMISSIONS

### Police
- **Lecture:** Tout sauf DOJ confidentiel
- **Écriture:** Rapports, arrestations, BOLO, preuves, saisies
- **Lecture seule:** Mandats, ordonnances, jugements

### DOJ
- **Lecture:** Tout
- **Écriture:** Cases, charges, mandats, ordonnances, jugements
- **Validation:** Rapports police, preuves

### EMS
- **Lecture:** Patients, medical records uniquement
- **Écriture:** ePCR, vitals, transports, certificats
- **Lecture limitée Police/DOJ:** Seulement si pertinent (décès, 5150, fit/unfit)

---

## 📝 PROCHAINES ÉTAPES

### Phase 1: Infrastructure ✅
- [x] Créer le schéma SQL complet

### Phase 2: Backend (À faire)
- [ ] Créer le resource `zmdt`
- [ ] Config.lua avec jobs, grades, permissions
- [ ] Server callbacks pour chaque fonctionnalité
- [ ] Client events et NUI callbacks
- [ ] Synchronisation ESX (users → mdt_citizens)

### Phase 3: Frontend (À faire)
- [ ] Interface NUI Police
- [ ] Interface NUI DOJ
- [ ] Interface NUI EMS
- [ ] Recherches en temps réel
- [ ] Formulaires pour chaque type de rapport

### Phase 4: Features avancées (À faire)
- [ ] Drag & drop photos/preuves
- [ ] Bodycam refs integration
- [ ] Timeline interactive pour cases
- [ ] Notifications temps réel
- [ ] Webhooks Discord

---

## 🎨 DESIGN UI

### Police - Couleur: Bleu (#3b82f6)
**Onglets:**
1. CAD / Appels
2. Recherche (Citoyen/Véhicule/Arme)
3. Rapports
4. BOLO/Wanted
5. Preuves
6. Personnel (superviseur)

### DOJ - Couleur: Or (#f59e0b)
**Onglets:**
1. Recherche
2. Dossiers/Cases
3. Mandats
4. Audiences
5. Jugements
6. Administration

### EMS - Couleur: Rouge (#ef4444)
**Onglets:**
1. Dispatch
2. Patients
3. Rapports médicaux
4. Transports
5. Certificats
6. Inventaire

---

## 🔗 INTÉGRATION ESX

### Synchronisation automatique
```lua
-- Créer profil citoyen automatiquement quand un joueur se connecte
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    -- Insérer dans mdt_citizens si n'existe pas
    -- Synchroniser firstname, lastname, dateofbirth, sex
end)

-- Synchroniser véhicules depuis owned_vehicles
-- Synchroniser armes depuis datastore_data
```

---

## ⚠️ IMPORTANT

1. **NE PAS TOUCHER** à la tablette entreprise actuelle (`ztablet`)
2. **CRÉER UN NOUVEAU RESOURCE** (`zmdt`) séparé
3. **INSTALLER** `mdt_schema.sql` dans votre base de données
4. **CONFIGURER** les jobs autorisés dans Config.lua
5. **TESTER** chaque fonctionnalité individuellement

---

## 📞 COMMANDES SUGGÉRÉES

```lua
/mdt           -- Ouvrir le MDT (job requis: police, sheriff, doj, ambulance)
/bolo [text]   -- BOLO rapide
/wanted [id]   -- Ajouter wanted
/911           -- Voir appels actifs (dispatch)
```

---

## 🗺️ ROADMAP

**Sprint 1 (Base):**
- Infrastructure + SQL ✅
- Config + permissions
- Recherche citoyen simple
- Formulaire rapport basique

**Sprint 2 (Police):**
- CAD/Dispatch complet
- BOLO/Wanted
- Arrestations
- Preuves/Saisies

**Sprint 3 (DOJ):**
- Cases/Dossiers
- Mandats
- Audiences
- Jugements

**Sprint 4 (EMS):**
- Patients
- ePCR
- Transports
- 5150 holds

**Sprint 5 (Polish):**
- UI/UX amélioré
- Notifications
- Webhooks
- Optimisations

---

## 💡 NOTES TECHNIQUES

### Performance
- Indexes sur toutes les clés étrangères
- Views pour recherches fréquentes
- JSON pour données flexibles (flags, arrays)

### Sécurité
- Audit log sur toutes les actions sensibles
- Vérification job/grade sur chaque callback
- Sanitization des inputs
- Protection contre SQL injection (prepared statements)

### Scalabilité
- Architecture modulaire (police.lua, doj.lua, ems.lua)
- Système de permissions configurable
- Support multi-jobs (sheriff, state_police, etc.)

---

**Créé pour:** ESX Framework
**Compatible avec:** ox_lib, ox_target, oxmysql
**Auteur:** Claude AI
**Date:** 2025-12-29
