# MDT Premium - California Edition 🇺🇸

Tablette MDT Premium pour Entreprises ESX avec interface React moderne et intégration complète.

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![ESX](https://img.shields.io/badge/ESX-Legacy-green.svg)
![React](https://img.shields.io/badge/React-18-61DAFB.svg)

## 📋 Fonctionnalités

### 🏢 Pour les Entreprises (Concessionnaires)
- **Dashboard** - Vue d'ensemble avec statistiques en temps réel
- **Factures** - Création avec sélection de joueur (auto-détection ou ID manuel)
- **Mes Factures** - Paiement de vos factures reçues (ox_banking)
- **Employés** - Gestion des employés et suivi des performances
- **Commissions** - Calcul automatique (5%) et paiement
- **Concession** - Catalogue véhicules avec -40% de réduction
- **Partenariats** - Créer alliances avec autres entreprises
- **Taxes** - Suivi et paiement des taxes dues

### ⚖️ Pour le DOJ (Department of Justice)
- **Contrôle Économique Total** - Gestion complète de l'économie de l'État
- **Taux de Taxe Global** - Modifier le taux appliqué à toutes les factures
- **Date Limite de Paiement** - Définir le jour du mois
- **Gestion des Entreprises** - Visualiser toutes les entreprises + recherche
- **Entreprises Suspectes** - Suivi automatique
- **Audits & Sanctions** - Actions sur les entreprises

### 💎 Interface Moderne
- **Design California** - Dark mode + glassmorphism
- **Responsive** - Adapté à toutes les résolutions
- **Animations** - Transitions fluides et professionnelles
- **Recherche** - Partout où c'est nécessaire
- **En Dollars** - Formatage USD ($) pour la Californie

## 📦 Installation

### Prérequis
- **ESX Legacy** (dernière version)
- **oxmysql**
- **ox_banking** (système de factures personnalisé intégré)
- **Node.js 18+** (pour build NUI)

### 1. Installation du Resource

```bash
# Cloner dans votre dossier resources
cd resources/[esx]
git clone [repo] mdt_premium

# Build de l'interface NUI
cd mdt_premium/nui
npm install
npm run build
```

### 2. Configuration server.cfg

```lua
ensure oxmysql
ensure es_extended
ensure ox_banking
ensure mdt_premium
```

### 3. Base de Données

Les tables sont créées automatiquement au démarrage:
- `mdt_invoices` - Factures
- `mdt_tax_settings` - Paramètres fiscaux DOJ
- `mdt_commissions` - Commissions employés

## 🎮 Utilisation

### Commandes
- `/mdt` - Ouvrir la tablette
- **F6** - Raccourci clavier (configurable)

### Jobs Autorisés
Par défaut dans `server/main.lua`:
```lua
Config.AuthorizedJobs = {
    'cardealer', 'concessionnaire', 'dealership',
    'doj', 'judge', 'justice'
}
```

### Jobs DOJ (Accès Complet)
```lua
Config.DOJJobs = { 'doj', 'judge', 'justice' }
```

## 🔧 Configuration

### Taux de Taxe
- **Par défaut**: 15%
- **Modifiable**: Via interface DOJ en jeu
- **Stocké**: Base de données (persistent)

### Réduction Concession
Dans `server/main.lua`:
```lua
Config.DealerDiscount = 0.40 -- 40% de réduction
```

### Taux de Commission
Actuellement: **5% du montant HT**
Modifiable dans la fonction `createInvoice` (server/main.lua)

## 🛠️ Développement

### Structure
```
mdt_premium/
├── client/
│   └── main.lua          # Client ESX + NUI callbacks
├── server/
│   └── main.lua          # Server ESX + Database
├── nui/
│   ├── src/
│   │   ├── components/   # Composants React
│   │   ├── pages/        # Pages (Dashboard, DOJ, etc.)
│   │   └── store/        # Zustand state management
│   ├── package.json
│   └── vite.config.js
└── fxmanifest.lua
```

### Build Development
```bash
cd nui
npm run dev  # Localhost:3000 pour tester l'UI
```

### Build Production
```bash
cd nui
npm run build  # Génère nui/dist/ pour FiveM
```

## 🔐 Sécurité

- ✅ Vérification des permissions côté serveur
- ✅ Validation des données avant insertion DB
- ✅ Protection SQL injection (oxmysql)
- ✅ Callbacks sécurisés ESX
- ✅ Accès DOJ restreint

## 📝 Callbacks NUI → Client

| Callback | Description |
|----------|-------------|
| `closeTablet` | Fermer la tablette |
| `getNearestPlayer` | Trouver joueur proche (3m max) |
| `getPlayerById` | Chercher joueur par ID serveur |
| `createInvoice` | Créer facture + commission auto |
| `purchaseVehicle` | Acheter véhicule (société) |
| `payCommission` | Payer commission employé |
| `payTaxes` | Payer taxes au DOJ |
| `updateTaxRate` | Modifier taux global (DOJ only) |

## 🚀 Roadmap / Améliorations Possibles

- [ ] Export PDF des factures
- [ ] Historique des transactions
- [ ] Graphiques des ventes (Chart.js)
- [ ] Notifications push (facture payée, etc.)
- [ ] Multi-entreprise pour un joueur
- [ ] Système d'audit complet DOJ
- [ ] Sanctions automatiques (retard taxes)

## 📄 Licence

Propriétaire - Tous droits réservés

## 👨‍💻 Support

Pour toute question ou problème:
1. Vérifier que tous les prérequis sont installés
2. Vérifier les logs serveur (`/logs/server.log`)
3. Vérifier la console F8 en jeu

---

**Made with ❤️ for California RP Servers** 🇺🇸
