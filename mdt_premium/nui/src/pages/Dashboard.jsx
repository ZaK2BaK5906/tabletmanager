import React from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Badge from '../components/ui/Badge'
import useStore from '../store/useStore'
import { TrendingUp, TrendingDown, DollarSign, Users, FileText, AlertTriangle } from 'lucide-react'

export default function Dashboard() {
  const { company, invoices, employees } = useStore()

  const stats = [
    {
      label: 'Chiffre d\'Affaires',
      value: `${company.totalInvoiced.toLocaleString()}$`,
      change: '+12.5%',
      trend: 'up',
      icon: TrendingUp,
      color: 'text-green-400',
    },
    {
      label: 'Taxes Dues',
      value: `${company.totalTaxes.toLocaleString()}$`,
      change: `${company.taxRate}%`,
      trend: 'neutral',
      icon: DollarSign,
      color: 'text-yellow-400',
    },
    {
      label: 'Commissions',
      value: `${company.pendingCommissions.toLocaleString()}$`,
      change: '8 employés',
      trend: 'neutral',
      icon: Users,
      color: 'text-blue-400',
    },
    {
      label: 'Factures',
      value: invoices.length,
      change: '2 en attente',
      trend: 'down',
      icon: FileText,
      color: 'text-purple-400',
    },
  ]

  const recentInvoices = invoices.slice(0, 5)

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-100">Dashboard</h1>
        <p className="text-gray-400 mt-1">Vue d'ensemble de votre entreprise</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <Card key={index} hover className="relative overflow-hidden">
            <CardBody>
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-sm text-gray-400 mb-1">{stat.label}</p>
                  <p className="text-2xl font-bold text-gray-100">{stat.value}</p>
                  <div className="flex items-center gap-2 mt-2">
                    {stat.trend === 'up' && <TrendingUp className="w-4 h-4 text-green-400" />}
                    {stat.trend === 'down' && <TrendingDown className="w-4 h-4 text-red-400" />}
                    <span className={`text-sm ${stat.trend === 'up' ? 'text-green-400' : stat.trend === 'down' ? 'text-red-400' : 'text-gray-400'}`}>
                      {stat.change}
                    </span>
                  </div>
                </div>
                <div className={`p-3 bg-gray-800 rounded-xl ${stat.color}`}>
                  <stat.icon className="w-6 h-6" />
                </div>
              </div>
            </CardBody>
          </Card>
        ))}
      </div>

      {/* Two Columns */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Invoices */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Factures Récentes</CardTitle>
              <Badge variant="info">{invoices.length} total</Badge>
            </div>
          </CardHeader>
          <CardBody className="p-0">
            <div className="divide-y divide-gray-700">
              {recentInvoices.map((invoice) => (
                <div key={invoice.id} className="p-4 hover:bg-gray-800 transition-colors">
                  <div className="flex items-center justify-between mb-2">
                    <div>
                      <p className="font-medium text-gray-100">{invoice.client}</p>
                      <p className="text-sm text-gray-400">{invoice.number}</p>
                    </div>
                    <Badge variant={invoice.status === 'paid' ? 'success' : 'warning'}>
                      {invoice.status === 'paid' ? 'Payée' : 'En attente'}
                    </Badge>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-400">{invoice.createdAt}</span>
                    <span className="font-semibold text-green-400">{invoice.total.toLocaleString()}$</span>
                  </div>
                </div>
              ))}
            </div>
          </CardBody>
        </Card>

        {/* Top Employees */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Top Employés</CardTitle>
              <Badge variant="success">{employees.length} employés</Badge>
            </div>
          </CardHeader>
          <CardBody className="p-0">
            <div className="divide-y divide-gray-700">
              {employees.map((employee, index) => (
                <div key={employee.id} className="p-4 hover:bg-gray-800 transition-colors">
                  <div className="flex items-center gap-4">
                    <div className="flex-shrink-0 w-10 h-10 bg-primary-500 rounded-full flex items-center justify-center text-white font-semibold">
                      #{index + 1}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-gray-100">{employee.name}</p>
                      <p className="text-sm text-gray-400">{employee.grade}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-green-400">{employee.totalInvoiced.toLocaleString()}$</p>
                      <p className="text-xs text-gray-400">{employee.invoiceCount} factures</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Alerts */}
      <Card className="border-l-4 border-yellow-500">
        <CardBody>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 p-2 bg-yellow-500/20 rounded-lg">
              <AlertTriangle className="w-6 h-6 text-yellow-400" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-100 mb-1">Paiement des taxes</h3>
              <p className="text-sm text-gray-400">
                Vous devez payer <span className="text-yellow-400 font-semibold">{company.totalTaxes.toLocaleString()}$</span> de taxes avant le <span className="text-yellow-400">25/01/2024</span>.
              </p>
            </div>
          </div>
        </CardBody>
      </Card>
    </div>
  )
}
