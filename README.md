# 📱 TabletManager - Tablette de Gestion pour ESX

Système de tablette de gestion complet pour FiveM avec ESX. Permet à tous les employés de gérer leurs factures, commissions et plus encore avec une interface moderne et professionnelle.

## ✨ Fonctionnalités

### Pour tous les employés
- 📝 Créer des factures avec produits personnalisés
- 💰 Voir sa commission en temps réel
- 📄 Historique de ses factures
- 📊 Statistiques personnelles (CA, factures, commissions)
- 🔢 Calcul automatique avec remises et TVA
- 🤝 Application automatique des remises partenaires

### Pour les patrons
- 📦 Gérer les produits du job (ajouter/supprimer)
- 👥 Gérer les commissions des employés
- 🤝 Gérer les partenariats avec d'autres entreprises
- 💵 Paiements automatiques via ESX Society
- 📋 Voir toutes les données du job

## 📋 Prérequis

- **ESX Legacy** ou **ESX 1.2+**
- **oxmysql** (pour la base de données)
- **es_extended** (framework ESX)
- **esx_addonaccount** (pour les comptes société - optionnel pour partenariats)

## 🚀 Installation

### 1. Téléchargement
Placez le dossier `tabletmanager` dans votre dossier `resources/[esx]` de votre serveur FiveM.

### 2. Base de données
Exécutez le fichier SQL dans votre base de données :

```bash
mysql -u root -p votre_base_de_donnees < install.sql
```

Ou importez le fichier `install.sql` via phpMyAdmin.

### 3. Configuration serveur
Ajoutez dans votre `server.cfg` :

```cfg
ensure tabletmanager
```

### 4. Configuration (Optionnel)
Éditez le fichier `config.lua` pour personnaliser :

```lua
Config.DefaultCommission = 5.0  -- Commission par défaut (%)
Config.TaxRate = 20.0           -- TVA (%)
Config.Command = 'tablette'     -- Commande pour ouvrir
Config.BossGrades = { 'boss', 'patron', 'chief' }  -- Grades boss
```

## 🎮 Utilisation

### Commande
```
/tablette
```

### Navigation
- **Accueil** : Statistiques rapides
- **Facture** : Créer une nouvelle facture
- **Historique** : Voir ses factures
- **Stats** : Statistiques détaillées
- **Gestion** : (Patrons uniquement) Gérer produits, employés, partenariats

### Créer une facture
1. Ouvrir la tablette avec `/tablette`
2. Aller dans l'onglet "Facture"
3. Sélectionner un produit et la quantité
4. Ajouter autant de produits que nécessaire
5. Optionnel : Appliquer une remise manuelle
6. Optionnel : Sélectionner un partenariat
7. Cliquer sur "Créer la Facture"

### Gestion (Patrons)

#### Ajouter un produit
1. Onglet "Gestion" > "Produits"
2. Entrer le nom et le prix
3. Cliquer sur "Ajouter"

#### Modifier une commission
1. Onglet "Gestion" > "Employés"
2. Modifier le pourcentage
3. Cliquer sur "Sauver"

#### Créer un partenariat
1. Onglet "Gestion" > "Partenariats"
2. Entrer le nom de l'entreprise et la remise (%)
3. Cliquer sur "Ajouter"
4. Les factures avec ce partenariat débiteront automatiquement le compte société

## 🗃️ Structure de la base de données

### Tables créées
- `tablet_products` : Produits par job
- `tablet_invoices` : Factures émises
- `tablet_employee_commissions` : Commissions des employés
- `tablet_partnerships` : Partenariats entre entreprises
- `tablet_company_payments` : Paiements inter-entreprises

### Isolation des données
Chaque job a ses propres données complètement isolées. Les employés d'un job ne peuvent pas voir les données d'un autre job.

## 🎨 Interface

- Design moderne sans blur (fond dégradé propre)
- Responsive et fluide
- Animations smooth
- Aucune dépendance UI externe (100% custom)

## ⚙️ Commandes Admin

### Réinitialiser les données d'un job
```
/tablet:reset <job_name>
```
**Attention** : Cette commande supprime TOUTES les données du job (produits, factures, commissions, partenariats).

## 🐛 Debug

Si la tablette ne s'ouvre pas :
1. Vérifiez que vous avez un job (pas unemployed)
2. Vérifiez la console F8 pour les erreurs
3. Vérifiez que oxmysql est bien démarré
4. Vérifiez que les tables SQL sont créées

Si les produits ne s'affichent pas :
1. Vérifiez que le patron a bien ajouté des produits
2. Relancez la ressource : `restart tabletmanager`

## 📝 Logs

Pour activer les logs Discord (optionnel) :
```lua
Config.EnableLogs = true
Config.DiscordWebhook = 'votre_webhook'
```

## 🔧 Support

- Vérifiez que toutes les dépendances sont installées
- Consultez les logs serveur pour les erreurs
- Assurez-vous que la base de données est correctement configurée

## 📄 Licence

Ce script est fourni tel quel. Vous pouvez le modifier et l'adapter à vos besoins.

## 🎯 Roadmap / Améliorations futures

- [ ] Export de factures en PDF
- [ ] Graphiques de stats avancées
- [ ] Notifications push pour les patrons
- [ ] Système de signatures numériques
- [ ] Multi-langues

## ✅ Changelog

### v1.0.0 (Initiale)
- Système de facturation complet
- Gestion des commissions
- Partenariats inter-entreprises
- Interface custom moderne
- Isolation totale par job
- Statistiques en temps réel

---

**Développé par ZaK2BaK5906**
