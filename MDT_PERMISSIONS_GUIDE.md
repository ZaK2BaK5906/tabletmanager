# 🔒 SYSTÈME DE PERMISSIONS MDT
## Guide complet du contrôle d'accès

---

## 📋 OVERVIEW

Le système MDT utilise un **contrôle d'accès granulaire à 3 niveaux** :

1. **Permissions par JOB** (par défaut pour tous les membres du service)
2. **Permissions par USER** (override individuel par le patron/superviseur)
3. **Restrictions par DOSSIER** (bloquer l'accès à des dossiers spécifiques)

---

## 🗄️ TABLES DU SYSTÈME

### Tables principales
- `mdt_permissions_list` - Liste de toutes les permissions disponibles
- `mdt_job_permissions` - Permissions par défaut pour chaque job/grade
- `mdt_user_permissions` - Permissions individuelles (override)
- `mdt_confidentiality_levels` - Niveaux de confidentialité (Public → Top Secret)
- `mdt_access_restrictions` - Restrictions d'accès aux dossiers
- `mdt_blocked_actions` - Actions bloquées par le patron
- `mdt_share_permissions` - Partage inter-services
- `mdt_access_logs` - Logs de tous les accès

---

## 🎯 NIVEAUX DE CONFIDENTIALITÉ

### 5 niveaux disponibles

| Level | Rank | Description | Qui peut voir |
|-------|------|-------------|---------------|
| **Public** | 0 | Accessible à tous | Tous les membres du service |
| **Restricted** | 1 | Accès limité | Grades autorisés uniquement |
| **Confidential** | 2 | Confidentiel | Superviseurs uniquement |
| **Top Secret** | 3 | Très confidentiel | Command staff uniquement |
| **Sealed** | 4 | Scellé | Invisible (sauf exception judiciaire) |

### Tables concernées
- `mdt_cases` - Dossiers DOJ
- `mdt_reports` - Rapports police
- `mdt_patients` - Dossiers patients EMS
- `mdt_epcr` - Rapports médicaux
- `mdt_evidence` - Preuves

---

## 🔑 PERMISSIONS DISPONIBLES

### POLICE (22 permissions)

#### CAD / Dispatch
- `police.cad.view` - Voir les appels
- `police.cad.create` - Créer un appel
- `police.cad.edit` - Modifier un appel
- `police.cad.close` - Clôturer un appel

#### Recherches
- `police.search.citizen` - Rechercher citoyen
- `police.search.vehicle` - Rechercher véhicule
- `police.search.weapon` - Rechercher arme

#### Rapports
- `police.reports.view` - Voir les rapports
- `police.reports.create` - Créer un rapport
- `police.reports.edit` - Modifier ses rapports
- `police.reports.edit_all` - Modifier tous les rapports (superviseur)
- `police.reports.delete` - Supprimer un rapport (superviseur)

#### Arrestations
- `police.arrests.view` - Voir les arrestations
- `police.arrests.create` - Créer une arrestation

#### BOLO
- `police.bolo.view` - Voir les BOLO
- `police.bolo.create` - Créer un BOLO
- `police.bolo.edit` - Modifier un BOLO
- `police.bolo.close` - Clôturer un BOLO

#### Preuves
- `police.evidence.view` - Voir les preuves
- `police.evidence.create` - Saisir des preuves
- `police.evidence.edit` - Modifier chain of custody
- `police.evidence.release` - Restituer des preuves (admin)

#### Personnel
- `police.personnel.view` - Voir le roster
- `police.personnel.manage` - Gérer le personnel (superviseur)

### DOJ (16 permissions)

#### Cases
- `doj.cases.view` - Voir les dossiers
- `doj.cases.create` - Créer un dossier
- `doj.cases.edit` - Modifier un dossier assigné
- `doj.cases.edit_all` - Modifier tous les dossiers
- `doj.cases.seal` - Sceller un dossier (juge)

#### Charges
- `doj.charges.view` - Voir les charges
- `doj.charges.file` - Déposer des charges (procureur)
- `doj.charges.dismiss` - Rejeter des charges (juge)

#### Mandats
- `doj.warrants.view` - Voir les mandats
- `doj.warrants.create` - Créer un mandat
- `doj.warrants.approve` - Approuver un mandat (juge)
- `doj.warrants.recall` - Annuler un mandat (juge)

#### Audiences
- `doj.hearings.view` - Voir les audiences
- `doj.hearings.schedule` - Planifier une audience
- `doj.hearings.manage` - Gérer les audiences (juge)

#### Jugements
- `doj.judgments.view` - Voir les jugements
- `doj.judgments.create` - Prononcer un jugement (juge uniquement)

#### Probation
- `doj.probation.view` - Voir les probations
- `doj.probation.manage` - Gérer les probations

#### Reports Police
- `doj.reports_police.view` - Voir rapports police
- `doj.reports_police.validate` - Approuver/rejeter rapports
- `doj.reports_police.request` - Demander compléments

### EMS (16 permissions)

#### Dispatch
- `ems.dispatch.view` - Voir les appels
- `ems.dispatch.create` - Créer un appel
- `ems.dispatch.edit` - Modifier un appel

#### Patients
- `ems.patients.view` - Voir les patients
- `ems.patients.create` - Créer un patient
- `ems.patients.edit` - Modifier un patient

#### ePCR
- `ems.epcr.view` - Voir les ePCR
- `ems.epcr.create` - Créer un ePCR
- `ems.epcr.edit` - Modifier ses ePCR
- `ems.epcr.edit_all` - Modifier tous les ePCR (superviseur)

#### Certificats
- `ems.certificates.view` - Voir les certificats
- `ems.certificates.create` - Créer un certificat
- `ems.certificates.sign` - Signer un certificat (MD)

#### 5150
- `ems.mental_health.view` - Voir 5150 holds
- `ems.mental_health.create` - Créer un 5150
- `ems.mental_health.release` - Lever un 5150

#### Inventaire
- `ems.inventory.view` - Voir l'inventaire
- `ems.inventory.manage` - Gérer l'inventaire

---

## 👨‍💼 GESTION PAR LES PATRONS

### 1. Bloquer des actions pour certains grades

```sql
-- Exemple: Bloquer création de mandats pour les procureurs (grade < 3)
INSERT INTO mdt_blocked_actions (job_name, job_grade, action_key, is_blocked, blocked_by, reason)
VALUES ('doj', 2, 'create_warrant', 1, 'judge_identifier', 'Seuls les juges peuvent créer des mandats');
```

### 2. Donner une permission spécifique à un employé

```sql
-- Exemple: Donner accès "edit_all" à un detective
INSERT INTO mdt_user_permissions (user_identifier, permission_id, granted, granted_by, reason)
SELECT 'char1:xyz123', id, 1, 'supervisor_identifier', 'Lead detective - needs access'
FROM mdt_permissions_list
WHERE permission_key = 'police.reports.edit_all';
```

### 3. Bloquer l'accès à un dossier spécifique

```sql
-- Exemple: Bloquer un dossier UC (undercover) au public
INSERT INTO mdt_access_restrictions (record_type, record_id, confidentiality_level_id, restricted_from_jobs, restricted_by, reason)
SELECT 'case', 123, id, '["police","ambulance"]', 'doj_supervisor', 'Undercover operation'
FROM mdt_confidentiality_levels
WHERE level_key = 'top_secret';
```

### 4. Partager un dossier avec un autre service

```sql
-- Exemple: Partager un rapport médical avec la police (pour enquête)
INSERT INTO mdt_share_permissions (record_type, record_id, shared_by_job, shared_by_user, shared_with_job, permission_level, expires_at, notes)
VALUES ('epcr', 456, 'ambulance', 'ems_supervisor', 'police', 'read', DATE_ADD(NOW(), INTERVAL 30 DAY), 'Enquête homicide - ref case #789');
```

---

## 🔍 VÉRIFIER LES PERMISSIONS D'UN UTILISATEUR

### Vue automatique
```sql
-- Voir toutes les permissions effectives d'un user
SELECT * FROM mdt_user_effective_permissions
WHERE identifier = 'char1:xyz123';
```

### Vérification manuelle (Lua)
```lua
-- Exemple de fonction server-side
function HasPermission(source, permissionKey)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    -- Check user-specific permission first (highest priority)
    local userPerm = MySQL.scalar.await([[
        SELECT up.granted
        FROM mdt_user_permissions up
        JOIN mdt_permissions_list p ON p.id = up.permission_id
        WHERE up.user_identifier = ? AND p.permission_key = ?
        AND (up.expires_at IS NULL OR up.expires_at > NOW())
    ]], {xPlayer.identifier, permissionKey})

    if userPerm ~= nil then
        return userPerm == 1
    end

    -- Check job permission (default)
    local jobPerm = MySQL.scalar.await([[
        SELECT jp.granted
        FROM mdt_job_permissions jp
        JOIN mdt_permissions_list p ON p.id = jp.permission_id
        WHERE jp.job_name = ?
        AND (jp.job_grade IS NULL OR jp.job_grade = ?)
        AND p.permission_key = ?
    ]], {xPlayer.job.name, xPlayer.job.grade, permissionKey})

    return jobPerm == 1
end
```

---

## 🚫 BLOQUER L'ACCÈS À UN DOSSIER

### Exemple 1: Dossier confidentiel (EMS bloque DOJ)

```lua
-- Directeur EMS bloque l'accès d'un dossier patient au DOJ
MySQL.insert([[
    INSERT INTO mdt_access_restrictions
    (record_type, record_id, confidentiality_level_id, restricted_from_jobs, restricted_by, reason)
    SELECT 'patient', ?, id, '["doj"]', ?, 'Dossier médical confidentiel - HIPAA'
    FROM mdt_confidentiality_levels WHERE level_key = 'confidential'
]], {patientId, directorIdentifier})
```

### Exemple 2: Dossier UC (Police bloque tout sauf command)

```lua
-- Limiter l'accès d'un rapport UC à certains users uniquement
MySQL.insert([[
    INSERT INTO mdt_access_restrictions
    (record_type, record_id, confidentiality_level_id, allowed_users, restricted_by, reason)
    SELECT 'report', ?, id, ?, ?, 'Undercover operation - restricted access'
    FROM mdt_confidentiality_levels WHERE level_key = 'top_secret'
]], {reportId, json.encode({'captain_id', 'lieutenant_id'}), supervisorId})
```

---

## 📊 LOGS D'ACCÈS

Tous les accès aux dossiers sensibles sont loggés automatiquement :

```sql
-- Exemple de log
INSERT INTO mdt_access_logs
(user_identifier, user_job, record_type, record_id, action, access_granted, denial_reason)
VALUES
('char1:xyz', 'police', 'case', 123, 'view', 0, 'Insufficient permissions - confidential case');
```

### Consulter les logs

```sql
-- Qui a accédé à un dossier
SELECT * FROM mdt_access_logs
WHERE record_type = 'case' AND record_id = 123
ORDER BY accessed_at DESC;

-- Tentatives d'accès refusées
SELECT * FROM mdt_access_logs
WHERE access_granted = 0
ORDER BY accessed_at DESC
LIMIT 100;
```

---

## 🛠️ CONFIGURATION PAR DÉPARTEMENT

### Exemples de configs

```sql
-- Require supervisor approval for all reports
INSERT INTO mdt_department_config (job_name, config_key, config_value, updated_by)
VALUES ('police', 'require_supervisor_approval', 'true', 'chief_identifier');

-- Allow officers to edit reports within 24h
INSERT INTO mdt_department_config (job_name, config_key, config_value, updated_by)
VALUES ('police', 'report_edit_window_hours', '24', 'chief_identifier');

-- Max confidentiality level a grade can set
INSERT INTO mdt_department_config (job_name, config_key, config_value, updated_by)
VALUES ('doj', 'max_confidentiality_by_grade', '{"0":0,"1":1,"2":2,"3":3,"4":4}', 'admin');
```

---

## 🔄 WORKFLOW TYPIQUE

### Scénario 1: Création d'un rapport confidentiel (Police)

1. Officer crée un rapport UC
2. Système vérifie `police.reports.create` ✅
3. Officer set confidentiality = "Top Secret"
4. Système vérifie grade suffisant pour ce niveau ✅
5. Rapport créé, visible uniquement aux superviseurs
6. Log créé dans `mdt_access_logs`

### Scénario 2: DOJ demande accès à un dossier médical

1. Procureur tente d'ouvrir un dossier patient
2. Système check `mdt_access_restrictions`
3. Dossier bloqué par EMS → Accès refusé ❌
4. Log créé: `access_granted = 0`
5. Procureur demande partage via UI
6. Notification au directeur EMS
7. Directeur approuve → Entrée dans `mdt_share_permissions`
8. Procureur peut maintenant voir (read-only) ✅

### Scénario 3: Patron bloque création de mandats pour procureurs juniors

1. Chief Judge ouvre config MDT
2. Sélectionne "Bloquer action" pour grade < 3
3. Action: `create_warrant`
4. Insert dans `mdt_blocked_actions`
5. Procureur junior tente de créer mandat → Refusé ❌
6. Message: "Action bloquée - contactez votre superviseur"

---

## ⚠️ IMPORTANT - HIÉRARCHIE DES PERMISSIONS

**Ordre de priorité (du plus haut au plus bas):**

1. **User permission (grant)** - Permission individuelle accordée
2. **User permission (deny)** - Permission individuelle refusée
3. **Blocked action** - Action bloquée par patron pour ce grade
4. **Job permission** - Permission par défaut du job/grade
5. **Access restriction** - Restriction sur le dossier spécifique
6. **Default DENY** - Par défaut, tout est refusé

**Exemple:**
- Job donne `police.reports.edit` à grade 2+
- Patron bloque cette action pour grade 2
- User de grade 2 → REFUSÉ (blocked action > job permission)
- Patron donne permission individuelle au user
- User de grade 2 → ACCORDÉ (user permission > blocked action)

---

## 🎯 BEST PRACTICES

### Pour les développeurs
1. **Toujours vérifier les permissions** avant chaque action sensible
2. **Logger tous les accès** aux données confidentielles
3. **Utiliser la vue** `mdt_user_effective_permissions` pour debug
4. **Ne jamais bypasser** le système de permissions

### Pour les administrateurs
1. **Commencer avec permissions restrictives**, élargir si nécessaire
2. **Documenter les raisons** quand vous accordez permissions spéciales
3. **Auditer régulièrement** les logs d'accès
4. **Former les superviseurs** sur le système de permissions

### Pour les patrons/superviseurs
1. **N'accordez pas plus** de permissions que nécessaire
2. **Utilisez les restrictions** pour protéger les dossiers sensibles
3. **Partagez avec parcimonie** entre services
4. **Mettez des dates d'expiration** sur les partages temporaires

---

## 📝 EXEMPLES COMPLETS

### Config complète pour un département Police

```lua
-- server/mdt/police_permissions.lua

-- Setup default permissions for all police grades
function SetupPolicePermissions()
    local basicPermissions = {
        'police.cad.view',
        'police.search.citizen',
        'police.search.vehicle',
        'police.reports.view',
        'police.reports.create',
        'police.arrests.view',
        'police.arrests.create',
        'police.bolo.view'
    }

    local officerPermissions = {
        'police.reports.edit',  -- Can edit own reports
        'police.bolo.create',
        'police.evidence.view',
        'police.evidence.create'
    }

    local supervisorPermissions = {
        'police.reports.edit_all',
        'police.reports.delete',
        'police.bolo.close',
        'police.evidence.release',
        'police.personnel.manage'
    }

    -- Apply to database
    for _, perm in ipairs(basicPermissions) do
        -- Grant to all grades
        ApplyJobPermission('police', nil, perm, true)
    end

    for _, perm in ipairs(officerPermissions) do
        -- Grant to grade 1+
        for grade = 1, 10 do
            ApplyJobPermission('police', grade, perm, true)
        end
    end

    for _, perm in ipairs(supervisorPermissions) do
        -- Grant to grade 4+ (sergeants and above)
        for grade = 4, 10 do
            ApplyJobPermission('police', grade, perm, true)
        end
    end
end
```

---

**Créé pour:** ESX Framework + MDT System
**Auteur:** Claude AI
**Date:** 2025-12-29
**Version:** 1.0
