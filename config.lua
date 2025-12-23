Config = {}

-- Langue
Config.Locale = 'fr'

-- Permissions
Config.BossGrades = { 'boss', 'patron', 'chief' } -- Grades considérés comme patron

-- Commission par défaut pour les nouveaux employés (%)
Config.DefaultCommission = 5.0

-- Devise
Config.Currency = '€'

-- Commandes
Config.Command = 'tablette'

-- Logs (optionnel - mettre votre webhook Discord)
Config.EnableLogs = false
Config.DiscordWebhook = ''

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
