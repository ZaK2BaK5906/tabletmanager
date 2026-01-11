import { create } from 'zustand'

// Store principal
const useStore = create((set) => ({
  // Visibility State
  visible: false,
  setVisible: (visible) => set({ visible }),

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
    canAccessDOJ: true, // Activé pour test - En production, sera géré par ESX
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
    paymentDeadlineDay: 25,
    totalTaxesCollected: 245000,
    suspiciousCompanies: ['Garage Central', 'Auto Express'],
    companies: [
      {
        id: 1,
        name: 'Elite Motors',
        owner: 'John Doe',
        taxesDue: 67500,
        lastPayment: '11/12/2023',
        status: 'compliant',
      },
      {
        id: 2,
        name: 'Garage Central',
        owner: 'Marc Durant',
        taxesDue: 12000,
        lastPayment: '15/10/2023',
        status: 'overdue',
      },
      {
        id: 3,
        name: 'Auto Express',
        owner: 'Sophie Martin',
        taxesDue: 8500,
        lastPayment: '05/01/2024',
        status: 'warning',
      },
      {
        id: 4,
        name: 'Luxury Cars LS',
        owner: 'Pierre Lefèvre',
        taxesDue: 45000,
        lastPayment: '10/01/2024',
        status: 'compliant',
      },
      {
        id: 5,
        name: 'Mécanique Pro',
        owner: 'Ahmed Benali',
        taxesDue: 3200,
        lastPayment: '08/01/2024',
        status: 'compliant',
      },
    ],
  },
}))

export default useStore
