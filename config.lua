Config = {}

-- Langue
Config.Locale = 'fr'

-- Permissions
Config.BossGrades = { 'boss', 'patron', 'chief' } -- Grades considérés comme patron

-- Jobs avec accès audit complet (DOJ, etc.)
Config.AuditJobs = { 'doj', 'government' } -- Jobs qui peuvent voir toutes les sociétés

-- Rayon de détection des joueurs proches (en mètres)
Config.NearbyPlayerRadius = 5.0

-- Commission par défaut pour les nouveaux employés (%)
Config.DefaultCommission = 5.0

-- Devise
Config.Currency = '€'

-- Commandes
Config.Command = 'tablette'

-- ============================================
-- WEBHOOKS DISCORD
-- ============================================
Config.Webhooks = {
    -- Activer/Désactiver tous les webhooks
    Enabled = true,

    -- Informations du bot
    BotName = 'Tablet Manager',
    BotAvatar = 'https://i.imgur.com/AfFp7pu.png',
    FooterIcon = 'https://i.imgur.com/AfFp7pu.png',

    -- Webhooks par catégorie (mettre vos URLs Discord)
    -- Laisser vide ('') pour désactiver un webhook spécifique

    -- Factures
    InvoiceCreated = '',  -- Quand une facture est créée
    InvoicePaid = '',     -- Quand une facture est payée
    InvoiceCancelled = '', -- Quand une facture est annulée

    -- Produits
    ProductAdded = '',    -- Quand un produit est ajouté
    ProductDeleted = '',  -- Quand un produit est supprimé

    -- Partenariats
    PartnershipAdded = '',   -- Quand un partenariat est créé
    PartnershipDeleted = '', -- Quand un partenariat est supprimé

    -- Employés
    CommissionUpdated = '', -- Quand une commission est modifiée
    SalesReset = '',        -- Quand les ventes sont réinitialisées

    -- Recrutement
    JobApplication = '',              -- Nouvelle candidature reçue
    ApplicationStatusChanged = '',    -- Candidature acceptée/refusée
    RecruitmentStatusChanged = '',    -- Recrutement ouvert/fermé
    CompanyProfileUpdated = '',       -- Profil entreprise modifié
}

-- Taxes (%)
Config.TaxRate = 16.75 -- VAT 16.75%

-- Messages
Config.Translations = {
    ['tablet_title'] = '📱 Tablette de Gestion',
    ['no_job'] = '❌ Vous n\'avez pas de job !',
    ['not_authorized'] = '❌ Vous n\'êtes pas autorisé !',

    -- Menu principal
    ['main_menu'] = 'Menu Principal',
    ['create_invoice'] = '📝 Créer une Facture',
    ['my_invoices'] = '📄 Mes Factures',
    ['my_commission'] = '💰 Ma Commission',
    ['statistics'] = '📊 Statistiques',
    ['management'] = '⚙️ Gestion (Patron)',

    -- Facturation
    ['invoice_created'] = '✅ Facture créée avec succès !',
    ['select_product'] = 'Sélectionnez un produit',
    ['product_price'] = 'Prix unitaire',
    ['quantity'] = 'Quantité',
    ['discount'] = 'Remise (%)',
    ['partnership'] = 'Contrat Partenariat',
    ['total_ht'] = 'Total HT',
    ['total_ttc'] = 'Total TTC',
    ['send_invoice'] = 'Envoyer la Facture',

    -- Gestion
    ['manage_products'] = '📦 Gérer les Produits',
    ['manage_employees'] = '👥 Gérer les Employés',
    ['manage_partnerships'] = '🤝 Gérer les Partenariats',
    ['all_invoices'] = '📋 Toutes les Factures',

    -- Produits
    ['add_product'] = 'Ajouter un Produit',
    ['product_name'] = 'Nom du Produit',
    ['product_added'] = '✅ Produit ajouté !',
    ['product_deleted'] = '🗑️ Produit supprimé',

    -- Employés
    ['employee_commission'] = 'Commission Employé (%)',
    ['commission_updated'] = '✅ Commission mise à jour !',

    -- Partenariats
    ['company_name'] = 'Nom de l\'Entreprise',
    ['partnership_discount'] = 'Remise Partenariat (%)',
    ['partnership_added'] = '✅ Partenariat ajouté !',
    ['partnership_deleted'] = '🗑️ Partenariat supprimé',

    -- Stats
    ['monthly_revenue'] = 'CA du Mois',
    ['total_invoices'] = 'Factures Émises',
    ['total_commission'] = 'Commissions Totales',
    ['employee_stats'] = 'Statistiques Employé',
}
