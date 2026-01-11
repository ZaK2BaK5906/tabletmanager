import React from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'
import useStore from '../store/useStore'
import { AlertTriangle, DollarSign, TrendingUp, FileText } from 'lucide-react'

export default function Taxes() {
  const { company, invoices } = useStore()

  const taxedInvoices = invoices.filter(i => i.withTax)
  const exemptInvoices = invoices.filter(i => !i.withTax)

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-100">Taxes & DOJ</h1>
        <p className="text-gray-400 mt-1">Gestion des taxes et conformité fiscale</p>
      </div>

      {/* Alert */}
      <Card className="border-l-4 border-yellow-500">
        <CardBody>
          <div className="flex items-start gap-4">
            <AlertTriangle className="w-6 h-6 text-yellow-400 flex-shrink-0 mt-1" />
            <div>
              <h3 className="font-semibold text-gray-100 mb-1">Paiement de taxes requis</h3>
              <p className="text-sm text-gray-400 mb-3">
                Vous devez régler vos taxes avant le <span className="text-yellow-400 font-semibold">25 Janvier 2024</span>
              </p>
              <Button size="sm">Payer Maintenant</Button>
            </div>
          </div>
        </CardBody>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-yellow-500/20 rounded-xl">
                <DollarSign className="w-6 h-6 text-yellow-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">Taux de Taxe</p>
                <p className="text-2xl font-bold text-yellow-400">{company.taxRate}%</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-red-500/20 rounded-xl">
                <TrendingUp className="w-6 h-6 text-red-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">Taxes Dues</p>
                <p className="text-2xl font-bold text-red-400">{company.totalTaxes.toLocaleString()}$</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-green-500/20 rounded-xl">
                <FileText className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">Factures Taxées</p>
                <p className="text-2xl font-bold text-green-400">{taxedInvoices.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-orange-500/20 rounded-xl">
                <AlertTriangle className="w-6 h-6 text-orange-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">Exonérations</p>
                <p className="text-2xl font-bold text-orange-400">{exemptInvoices.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Two Columns */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Factures Exonérées */}
        <Card>
          <CardHeader>
            <CardTitle>Factures Sans Taxe</CardTitle>
          </CardHeader>
          <CardBody>
            {exemptInvoices.length === 0 ? (
              <p className="text-center text-gray-400 py-8">Aucune facture exonérée</p>
            ) : (
              <div className="space-y-3">
                {exemptInvoices.map((invoice) => (
                  <div key={invoice.id} className="p-4 bg-dark-tertiary rounded-lg border border-orange-500/30">
                    <div className="flex items-center justify-between mb-2">
                      <div>
                        <p className="font-medium text-gray-100">{invoice.client}</p>
                        <p className="text-sm text-gray-400">{invoice.number}</p>
                      </div>
                      <p className="font-semibold text-green-400">{invoice.total.toLocaleString()}$</p>
                    </div>
                    <div className="text-sm text-orange-400">
                      <span className="font-semibold">Raison :</span> {invoice.noTaxReason}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardBody>
        </Card>

        {/* Historique Paiements */}
        <Card>
          <CardHeader>
            <CardTitle>Historique Paiements</CardTitle>
          </CardHeader>
          <CardBody>
            <div className="space-y-3">
              <div className="p-4 bg-dark-tertiary rounded-lg">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-gray-100 font-medium">Décembre 2023</span>
                  <Badge variant="success">Payé</Badge>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-400">25/12/2023</span>
                  <span className="font-semibold text-green-400">15,250$</span>
                </div>
              </div>
              <div className="p-4 bg-dark-tertiary rounded-lg">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-gray-100 font-medium">Novembre 2023</span>
                  <Badge variant="success">Payé</Badge>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-400">25/11/2023</span>
                  <span className="font-semibold text-green-400">12,800$</span>
                </div>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Info DOJ */}
      <Card className="border-l-4 border-blue-500">
        <CardBody>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 p-3 bg-blue-500/20 rounded-xl">
              <AlertTriangle className="w-6 h-6 text-blue-400" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-100 mb-1">Règles Fiscales DOJ</h3>
              <ul className="text-sm text-gray-400 space-y-1 list-disc list-inside">
                <li>Taux de taxe standard : {company.taxRate}%</li>
                <li>Paiement mensuel obligatoire avant le 25 du mois</li>
                <li>Toute exonération doit être justifiée et approuvée par le DOJ</li>
                <li>Les retards de paiement entraînent des pénalités de 10%</li>
              </ul>
            </div>
          </div>
        </CardBody>
      </Card>
    </div>
  )
}
