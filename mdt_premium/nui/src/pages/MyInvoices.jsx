import React, { useState, useEffect } from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Badge from '../components/ui/Badge'
import Modal, { ModalHeader, ModalBody, ModalFooter } from '../components/ui/Modal'
import Table, { TableHeader, TableBody, TableRow, TableHead, TableCell } from '../components/ui/Table'
import { FileText, DollarSign, Eye, CreditCard } from 'lucide-react'

export default function MyInvoices() {
  const [invoices, setInvoices] = useState([])
  const [selectedInvoice, setSelectedInvoice] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isPaying, setIsPaying] = useState(false)

  // Load invoices on mount
  useEffect(() => {
    loadInvoices()
  }, [])

  const loadInvoices = async () => {
    setIsLoading(true)

    if (window.fetch) {
      try {
        const response = await fetch('https://mdt_premium/getPlayerInvoices', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        })
        const data = await response.json()
        if (data.success) {
          setInvoices(data.invoices || [])
        }
      } catch (error) {
        console.error('Error loading invoices:', error)
      }
    } else {
      // Demo data
      setInvoices([
        {
          id: 1,
          number: 'INV-20240111-1234',
          company_name: 'Elite Motors',
          amount: 5000,
          tax: 750,
          total: 5750,
          description: 'Achat véhicule Adder',
          status: 'pending',
          created_at: '2024-01-11T10:30:00'
        },
        {
          id: 2,
          number: 'INV-20240110-5678',
          company_name: 'Mécanique Pro',
          amount: 1200,
          tax: 180,
          total: 1380,
          description: 'Réparation moteur',
          status: 'paid',
          created_at: '2024-01-10T15:20:00',
          paid_at: '2024-01-10T16:00:00'
        }
      ])
    }

    setIsLoading(false)
  }

  const handlePayInvoice = async (invoiceId) => {
    setIsPaying(true)

    if (window.fetch) {
      try {
        const response = await fetch('https://mdt_premium/payInvoice', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ invoiceId })
        })
        const data = await response.json()

        if (data.success) {
          setSelectedInvoice(null)
          loadInvoices() // Reload invoices
        }
      } catch (error) {
        console.error('Error paying invoice:', error)
      }
    } else {
      // Demo mode
      setTimeout(() => {
        setSelectedInvoice(null)
        loadInvoices()
      }, 500)
    }

    setIsPaying(false)
  }

  const getStatusBadge = (status) => {
    if (status === 'paid') return <Badge variant="success">Payée</Badge>
    if (status === 'pending') return <Badge variant="warning">En attente</Badge>
    return <Badge variant="danger">Refusée</Badge>
  }

  const pendingInvoices = invoices.filter(i => i.status === 'pending')
  const totalPending = pendingInvoices.reduce((sum, i) => sum + i.total, 0)

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div>
        <div className="flex items-center gap-3 mb-2">
          <div className="p-3 bg-orange-500/20 rounded-xl">
            <FileText className="w-8 h-8 text-orange-400" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-gray-100">Mes Factures</h1>
            <p className="text-gray-400 mt-1">Gérez vos factures reçues</p>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-orange-500/20 rounded-xl">
                <FileText className="w-6 h-6 text-orange-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Total Factures</p>
                <p className="text-2xl font-bold text-orange-400">{invoices.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-yellow-500/20 rounded-xl">
                <DollarSign className="w-6 h-6 text-yellow-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">En Attente</p>
                <p className="text-2xl font-bold text-yellow-400">{pendingInvoices.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-red-500/20 rounded-xl">
                <CreditCard className="w-6 h-6 text-red-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Montant Total Dû</p>
                <p className="text-2xl font-bold text-red-400">${totalPending.toLocaleString()}</p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Warning if unpaid invoices */}
      {pendingInvoices.length > 0 && (
        <Card className="border-l-4 border-yellow-500">
          <CardBody>
            <div className="flex items-start gap-4">
              <div className="flex-shrink-0 p-3 bg-yellow-500/20 rounded-xl">
                <DollarSign className="w-6 h-6 text-yellow-400" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-100 mb-1">Factures Impayées</h3>
                <p className="text-sm text-gray-400">
                  Vous avez <span className="text-yellow-400 font-semibold">{pendingInvoices.length} facture(s)</span> en attente
                  pour un total de <span className="text-yellow-400 font-semibold">${totalPending.toLocaleString()}</span>.
                </p>
              </div>
            </div>
          </CardBody>
        </Card>
      )}

      {/* Invoices Table */}
      <Card>
        <CardHeader>
          <CardTitle>Liste des Factures</CardTitle>
        </CardHeader>
        <CardBody className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-gray-400">
              Chargement...
            </div>
          ) : invoices.length === 0 ? (
            <div className="p-8 text-center">
              <FileText className="w-16 h-16 text-gray-600 mx-auto mb-4" />
              <p className="text-gray-400">Aucune facture</p>
              <p className="text-sm text-gray-500 mt-1">Vous n'avez reçu aucune facture</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>N° Facture</TableHead>
                  <TableHead>Entreprise</TableHead>
                  <TableHead>Montant HT</TableHead>
                  <TableHead>Taxe</TableHead>
                  <TableHead>Total TTC</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Statut</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invoices.map((invoice) => (
                  <TableRow key={invoice.id}>
                    <TableCell className="font-medium">{invoice.number}</TableCell>
                    <TableCell>{invoice.company_name}</TableCell>
                    <TableCell>${invoice.amount.toLocaleString()}</TableCell>
                    <TableCell className="text-yellow-400">${invoice.tax.toLocaleString()}</TableCell>
                    <TableCell className="font-semibold text-green-400">
                      ${invoice.total.toLocaleString()}
                    </TableCell>
                    <TableCell>
                      {new Date(invoice.created_at).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell>{getStatusBadge(invoice.status)}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setSelectedInvoice(invoice)}
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        {invoice.status === 'pending' && (
                          <Button
                            size="sm"
                            onClick={() => handlePayInvoice(invoice.id)}
                            disabled={isPaying}
                          >
                            <CreditCard className="w-4 h-4 mr-1" />
                            Payer
                          </Button>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardBody>
      </Card>

      {/* View Invoice Modal */}
      {selectedInvoice && (
        <Modal
          isOpen={!!selectedInvoice}
          onClose={() => setSelectedInvoice(null)}
        >
          <ModalHeader onClose={() => setSelectedInvoice(null)}>
            Détails Facture {selectedInvoice.number}
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <div>
                <p className="text-sm text-gray-400">Entreprise</p>
                <p className="text-lg font-semibold text-gray-100">{selectedInvoice.company_name}</p>
              </div>

              {selectedInvoice.description && (
                <div>
                  <p className="text-sm text-gray-400">Description</p>
                  <p className="text-gray-100">{selectedInvoice.description}</p>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-400">Créée le</p>
                  <p className="font-medium text-gray-100">
                    {new Date(selectedInvoice.created_at).toLocaleDateString('fr-FR')}
                  </p>
                </div>
                {selectedInvoice.paid_at && (
                  <div>
                    <p className="text-sm text-gray-400">Payée le</p>
                    <p className="font-medium text-gray-100">
                      {new Date(selectedInvoice.paid_at).toLocaleDateString('fr-FR')}
                    </p>
                  </div>
                )}
              </div>

              <div className="p-4 bg-dark-tertiary rounded-lg">
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Montant HT</span>
                    <span className="font-medium">${selectedInvoice.amount.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Taxe</span>
                    <span className="font-medium text-yellow-400">${selectedInvoice.tax.toLocaleString()}</span>
                  </div>
                  <div className="pt-2 border-t border-gray-600 flex justify-between">
                    <span className="font-semibold">Total TTC</span>
                    <span className="text-xl font-bold text-green-400">${selectedInvoice.total.toLocaleString()}</span>
                  </div>
                </div>
              </div>

              {selectedInvoice.status === 'pending' && (
                <div className="p-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
                  <p className="text-sm text-yellow-400">
                    <span className="font-semibold">⚠️ En attente :</span> Cette facture doit être payée
                  </p>
                </div>
              )}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" onClick={() => setSelectedInvoice(null)}>
              Fermer
            </Button>
            {selectedInvoice.status === 'pending' && (
              <Button
                onClick={() => handlePayInvoice(selectedInvoice.id)}
                disabled={isPaying}
              >
                <CreditCard className="w-4 h-4 mr-2" />
                {isPaying ? 'Paiement...' : 'Payer Maintenant'}
              </Button>
            )}
          </ModalFooter>
        </Modal>
      )}
    </div>
  )
}
