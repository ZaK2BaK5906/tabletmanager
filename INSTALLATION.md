# 📦 Installation - Tablet Manager v2.0

## ⚠️ IMPORTANT: Migration SQL

Avant de redémarrer le serveur, vous DEVEZ exécuter le fichier de migration SQL pour ajouter les nouvelles tables.

### 1️⃣ Exécuter la Migration SQL

Dans votre PhpMyAdmin ou HeidiSQL, exécutez le fichier:
```
migration_employment.sql
```

Ce fichier crée:
- Table `company_profiles` (profils des entreprises)
- Table `job_applications` (candidatures)
- Initialise automatiquement les profils pour vos jobs existants

✅ **Aucune donnée existante ne sera perdue!**

### 2️⃣ Redémarrer la Resource

```bash
restart tabletmanager
```

## 🔧 Configuration des Webhooks Discord

### Créer les Webhooks Discord

1. Sur votre serveur Discord, allez dans les paramètres d'un salon
2. Intégrations → Webhooks → Nouveau Webhook
3. Copiez l'URL du webhook
4. Ouvrez `config.lua` et collez les URLs dans `Config.Webhooks`

### Exemple de Configuration

```lua
Config.Webhooks = {
    Enabled = true, -- true pour activer, false pour désactiver tout

    BotName = 'Tablet Manager',
    BotAvatar = 'https://i.imgur.com/AfFp7pu.png',

    -- Factures
    InvoiceCreated = 'https://discord.com/api/webhooks/...',
    InvoicePaid = 'https://discord.com/api/webhooks/...',
    InvoiceCancelled = 'https://discord.com/api/webhooks/...',

    -- Produits
    ProductAdded = 'https://discord.com/api/webhooks/...',
    ProductDeleted = 'https://discord.com/api/webhooks/...',

    -- Partenariats
    PartnershipAdded = 'https://discord.com/api/webhooks/...',
    PartnershipDeleted = 'https://discord.com/api/webhooks/...',

    -- Employés
    CommissionUpdated = 'https://discord.com/api/webhooks/...',
    SalesReset = 'https://discord.com/api/webhooks/...',

    -- Recrutement
    JobApplication = 'https://discord.com/api/webhooks/...',
    ApplicationStatusChanged = 'https://discord.com/api/webhooks/...',
    RecruitmentStatusChanged = 'https://discord.com/api/webhooks/...',
    CompanyProfileUpdated = 'https://discord.com/api/webhooks/...',
}
```

💡 **Astuce**: Laissez vide (`''`) les webhooks que vous ne voulez pas utiliser.

## 📝 Nouvelles Commandes

### Pour les Joueurs

- `/emploie` - Ouvre le menu des offres d'emploi (Indeed)
- Les joueurs peuvent aussi configurer une touche dans leurs Paramètres → Contrôles → FiveM

### Pour les Patrons (Boss)

Toutes les fonctions de gestion des candidatures sont dans le menu `/emploie`:
- Éditer le profil de l'entreprise
- Ouvrir/Fermer le recrutement
- Gérer les candidatures (accepter/refuser)

## 🎨 Personnaliser les Profils d'Entreprise

### Ajouter une Photo d'Entreprise

1. Uploadez votre logo sur [ImgBB.com](https://imgbb.com) (gratuit)
2. Copiez le lien "Direct link"
3. Dans le jeu, `/emploie` → Bouton "Éditer le Profil"
4. Collez l'URL dans "Photo de l'Entreprise"

### Exemple de Description

```
🏥 Los Santos Medical Center

Nous recherchons des professionnels passionnés pour rejoindre notre équipe médicale d'élite.

✨ Avantages:
• Salaire compétitif + primes
• Formation continue
• Équipement de pointe
• Ambiance professionnelle

📍 Postulez dès maintenant!
```

## 🐛 Résolution de Problèmes

### Les factures ne partent pas / Les joueurs ne reçoivent pas de notification

**Solution**: C'est souvent car le joueur n'est plus connecté ou a quitté. Le système va maintenant afficher un message plus clair quand ça arrive.

### Les candidatures ne s'affichent pas

Vérifiez que:
1. La migration SQL a bien été exécutée
2. La resource est bien redémarrée
3. Le joueur qui postule est bien connecté

### Les webhooks ne fonctionnent pas

Vérifiez que:
1. `Config.Webhooks.Enabled = true`
2. Les URLs Discord sont correctes (pas d'espace, guillemets complets)
3. Les permissions du webhook Discord sont activées
4. Le salon Discord existe toujours

## 📊 Fonctionnalités Ajoutées

### ✅ Système de Recrutement
- Menu `/emploie` pour tous les joueurs
- Postuler aux entreprises avec formulaire complet
- Gestion des candidatures pour les patrons
- Profils d'entreprise personnalisables

### ✅ Webhooks Discord
- 14 types de logs différents
- Embeds colorés avec icônes
- Informations détaillées sur chaque action
- Désactivables individuellement

### ✅ Audit DOJ
- Vue complète de toutes les sociétés
- Statistiques financières en temps réel
- Accessible uniquement aux jobs DOJ/Government

### ✅ Sélection Joueurs Proches
- Dropdown automatique des joueurs à proximité (5m)
- ID manuel optionnel
- Auto-fill nom et ID

## 🔒 Sécurité

- Toutes les actions sont vérifiées côté serveur
- Les patrons ne peuvent gérer que leur propre entreprise
- Les webhooks incluent l'identité de la personne qui effectue l'action
- Validation des données avant insertion en base

## 📞 Support

Si vous rencontrez des problèmes:
1. Vérifiez que la migration SQL est bien faite
2. Regardez les erreurs dans la F8 console
3. Vérifiez les logs serveur
4. Assurez-vous que tous les webhooks URLs sont valides (ou vides)

## 🎉 C'est Tout!

Votre système de tablette est maintenant complet avec:
- ✅ Facturation avancée
- ✅ Gestion des employés
- ✅ Statistiques détaillées
- ✅ Système de recrutement Indeed
- ✅ Webhooks Discord complets
- ✅ Audit DOJ

Bon jeu! 🚀
