import React from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Badge from '../components/ui/Badge'
import useStore from '../store/useStore'
import { DollarSign, Users, TrendingUp } from 'lucide-react'

export default function Commissions() {
  const { employees, company } = useStore()

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-100">Commissions</h1>
          <p className="text-gray-400 mt-1">Gestion des commissions employés</p>
        </div>
        <Button>
          <DollarSign className="w-5 h-5 mr-2" />
          Tout Payer ({company.pendingCommissions.toLocaleString()}€)
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-yellow-500/20 rounded-xl">
                <DollarSign className="w-6 h-6 text-yellow-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Total Commissions</p>
                <p className="text-2xl font-bold text-yellow-400">
                  {company.pendingCommissions.toLocaleString()}€
                </p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-500/20 rounded-xl">
                <Users className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Employés</p>
                <p className="text-2xl font-bold text-blue-400">{employees.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/20 rounded-xl">
                <TrendingUp className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Moyenne</p>
                <p className="text-2xl font-bold text-green-400">
                  {Math.round(company.pendingCommissions / employees.length).toLocaleString()}€
                </p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Employee Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {employees.map((employee) => (
          <Card key={employee.id} hover>
            <CardBody>
              <div className="flex items-center gap-4 mb-4">
                <div className="w-14 h-14 bg-primary-500 rounded-full flex items-center justify-center text-white font-bold text-xl">
                  {employee.name.charAt(0)}
                </div>
                <div>
                  <h3 className="font-semibold text-gray-100">{employee.name}</h3>
                  <p className="text-sm text-gray-400">{employee.grade}</p>
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">CA Généré</span>
                  <span className="font-medium text-green-400">
                    {employee.totalInvoiced.toLocaleString()}€
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">Factures</span>
                  <Badge variant="info">{employee.invoiceCount}</Badge>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">Taux</span>
                  <span className="font-medium text-blue-400">{employee.commissionRate}%</span>
                </div>

                <div className="pt-3 border-t border-gray-700 flex items-center justify-between">
                  <span className="font-semibold text-gray-100">Commission</span>
                  <span className="text-xl font-bold text-yellow-400">
                    {employee.commission.toLocaleString()}€
                  </span>
                </div>
              </div>

              <Button className="w-full mt-4" size="sm">
                Payer Commission
              </Button>
            </CardBody>
          </Card>
        ))}
      </div>

      {/* Info */}
      <Card className="border-l-4 border-primary-500">
        <CardBody>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 p-3 bg-primary-500/20 rounded-xl">
              <DollarSign className="w-6 h-6 text-primary-400" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-100 mb-1">Système de Commissions</h3>
              <ul className="text-sm text-gray-400 space-y-1 list-disc list-inside">
                <li>Les commissions sont calculées automatiquement sur chaque facture payée</li>
                <li>Le taux varie selon le grade de l'employé (4% à 5%)</li>
                <li>Les paiements peuvent être effectués individuellement ou en masse</li>
                <li>L'historique complet est conservé dans les logs</li>
              </ul>
            </div>
          </div>
        </CardBody>
      </Card>
    </div>
  )
}
