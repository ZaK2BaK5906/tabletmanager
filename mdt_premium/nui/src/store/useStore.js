import { create } from 'zustand'

// Store principal
const useStore = create((set) => ({
  // UI State
  sidebarCollapsed: false,
  toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),

  // User State (données de démo)
  user: {
    id: 1,
    name: 'John Doe',
    job: 'Concessionnaire Elite',
    grade: 'Directeur',
    company: 'Elite Motors',
    balance: 125000,
    canAccessDOJ: false,
  },

  // Company State (données de démo)
  company: {
    name: 'Elite Motors',
    balance: 1250000,
    employees: 8,
    taxRate: 15,
    totalInvoiced: 450000,
    totalTaxes: 67500,
    pendingCommissions: 12500,
  },

  // Invoices (données de démo)
  invoices: [
    {
      id: 1,
      number: 'INV-2024-001',
      client: 'Marc Dupont',
      amount: 25000,
      tax: 3750,
      total: 28750,
      status: 'paid',
      createdBy: 'John Doe',
      createdAt: '2024-01-10',
      paidAt: '2024-01-11',
      withTax: true,
    },
    {
      id: 2,
      number: 'INV-2024-002',
      client: 'Sophie Martin',
      amount: 15000,
      tax: 2250,
      total: 17250,
      status: 'pending',
      createdBy: 'John Doe',
      createdAt: '2024-01-11',
      paidAt: null,
      withTax: true,
    },
    {
      id: 3,
      number: 'INV-2024-003',
      client: 'Pierre Durand',
      amount: 8000,
      tax: 0,
      total: 8000,
      status: 'paid',
      createdBy: 'Alice Robert',
      createdAt: '2024-01-09',
      paidAt: '2024-01-10',
      withTax: false,
      noTaxReason: 'Exonération DOJ - Entreprise partenaire',
    },
  ],

  // Employees (données de démo)
  employees: [
    {
      id: 1,
      name: 'John Doe',
      grade: 'Directeur',
      totalInvoiced: 48000,
      commission: 2400,
      commissionRate: 5,
      invoiceCount: 3,
    },
    {
      id: 2,
      name: 'Alice Robert',
      grade: 'Vendeur Senior',
      totalInvoiced: 32000,
      commission: 1600,
      commissionRate: 5,
      invoiceCount: 2,
    },
    {
      id: 3,
      name: 'Marc Laurent',
      grade: 'Vendeur',
      totalInvoiced: 15000,
      commission: 600,
      commissionRate: 4,
      invoiceCount: 1,
    },
  ],

  // Vehicles (données de démo pour concession)
  vehicles: [
    {
      id: 1,
      model: 'adder',
      name: 'Adder',
      category: 'Super',
      price: 1000000,
      dealerPrice: 600000,
      stock: 2,
    },
    {
      id: 2,
      model: 't20',
      name: 'T20',
      category: 'Super',
      price: 2200000,
      dealerPrice: 1320000,
      stock: 1,
    },
    {
      id: 3,
      model: 'zentorno',
      name: 'Zentorno',
      category: 'Super',
      price: 725000,
      dealerPrice: 435000,
      stock: 3,
    },
  ],

  // DOJ State (si user a accès DOJ)
  dojData: {
    globalTaxRate: 15,
    totalTaxesCollected: 245000,
    companiesCount: 12,
    suspiciousCompanies: [
      {
        company: 'Garage Central',
        noTaxInvoices: 15,
        totalNoTax: 75000,
        reason: 'Trop de factures sans taxe',
      },
    ],
  },
}))

export default useStore
