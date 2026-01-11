import React, { useState } from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Badge from '../components/ui/Badge'
import Table, { TableHeader, TableBody, TableRow, TableHead, TableCell } from '../components/ui/Table'
import Modal, { ModalHeader, ModalBody, ModalFooter } from '../components/ui/Modal'
import Input, { Textarea } from '../components/ui/Input'
import useStore from '../store/useStore'
import { Plus, Eye, Download } from 'lucide-react'

export default function Invoices() {
  const { invoices, company } = useStore()
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [selectedInvoice, setSelectedInvoice] = useState(null)

  const getStatusBadge = (status) => {
    if (status === 'paid') return <Badge variant="success">Payée</Badge>
    if (status === 'pending') return <Badge variant="warning">En attente</Badge>
    return <Badge variant="danger">Refusée</Badge>
  }

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-100">Factures</h1>
          <p className="text-gray-400 mt-1">Gérez vos factures clients</p>
        </div>
        <Button onClick={() => setIsCreateModalOpen(true)}>
          <Plus className="w-5 h-5 mr-2" />
          Nouvelle Facture
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardBody>
            <p className="text-sm text-gray-400 mb-1">Total Facturé</p>
            <p className="text-2xl font-bold text-green-400">
              {company.totalInvoiced.toLocaleString()}€
            </p>
          </CardBody>
        </Card>
        <Card>
          <CardBody>
            <p className="text-sm text-gray-400 mb-1">Taxes Collectées</p>
            <p className="text-2xl font-bold text-yellow-400">
              {company.totalTaxes.toLocaleString()}€
            </p>
          </CardBody>
        </Card>
        <Card>
          <CardBody>
            <p className="text-sm text-gray-400 mb-1">En Attente</p>
            <p className="text-2xl font-bold text-orange-400">
              {invoices.filter(i => i.status === 'pending').length}
            </p>
          </CardBody>
        </Card>
      </div>

      {/* Table */}
      <Card>
        <CardHeader>
          <CardTitle>Liste des Factures</CardTitle>
        </CardHeader>
        <CardBody className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>N° Facture</TableHead>
                <TableHead>Client</TableHead>
                <TableHead>Montant HT</TableHead>
                <TableHead>Taxe ({company.taxRate}%)</TableHead>
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
                  <TableCell>{invoice.client}</TableCell>
                  <TableCell>{invoice.amount.toLocaleString()}€</TableCell>
                  <TableCell>
                    {invoice.withTax ? (
                      <span className="text-yellow-400">{invoice.tax.toLocaleString()}€</span>
                    ) : (
                      <Badge variant="danger" size="sm">Exonéré</Badge>
                    )}
                  </TableCell>
                  <TableCell className="font-semibold text-green-400">
                    {invoice.total.toLocaleString()}€
                  </TableCell>
                  <TableCell>{invoice.createdAt}</TableCell>
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
                      <Button size="sm" variant="ghost">
                        <Download className="w-4 h-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardBody>
      </Card>

      {/* Create Modal */}
      <Modal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        size="lg"
      >
        <ModalHeader onClose={() => setIsCreateModalOpen(false)}>
          Nouvelle Facture
        </ModalHeader>
        <ModalBody>
          <div className="space-y-4">
            <Input label="Nom du Client" placeholder="Ex: Marc Dupont" />
            <Input label="Montant HT (€)" type="number" placeholder="0" />
            <Textarea
              label="Description"
              placeholder="Description des services..."
              rows={3}
            />
            <div className="p-4 bg-dark-tertiary rounded-lg border border-gray-700">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-400">Montant HT</span>
                <span className="font-medium text-gray-100">0€</span>
              </div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-400">Taxe ({company.taxRate}%)</span>
                <span className="font-medium text-yellow-400">0€</span>
              </div>
              <div className="pt-2 border-t border-gray-600 flex items-center justify-between">
                <span className="font-semibold text-gray-100">Total TTC</span>
                <span className="text-xl font-bold text-green-400">0€</span>
              </div>
            </div>
          </div>
        </ModalBody>
        <ModalFooter>
          <Button variant="ghost" onClick={() => setIsCreateModalOpen(false)}>
            Annuler
          </Button>
          <Button>Créer la Facture</Button>
        </ModalFooter>
      </Modal>

      {/* View Modal */}
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
                <p className="text-sm text-gray-400">Client</p>
                <p className="text-lg font-semibold text-gray-100">{selectedInvoice.client}</p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-400">Créée le</p>
                  <p className="font-medium text-gray-100">{selectedInvoice.createdAt}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-400">Par</p>
                  <p className="font-medium text-gray-100">{selectedInvoice.createdBy}</p>
                </div>
              </div>
              <div className="p-4 bg-dark-tertiary rounded-lg">
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Montant HT</span>
                    <span className="font-medium">{selectedInvoice.amount.toLocaleString()}€</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Taxe</span>
                    <span className="font-medium text-yellow-400">{selectedInvoice.tax.toLocaleString()}€</span>
                  </div>
                  <div className="pt-2 border-t border-gray-600 flex justify-between">
                    <span className="font-semibold">Total TTC</span>
                    <span className="text-xl font-bold text-green-400">{selectedInvoice.total.toLocaleString()}€</span>
                  </div>
                </div>
              </div>
              {!selectedInvoice.withTax && (
                <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
                  <p className="text-sm text-red-400">
                    <span className="font-semibold">Exonération de taxe :</span> {selectedInvoice.noTaxReason}
                  </p>
                </div>
              )}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" onClick={() => setSelectedInvoice(null)}>
              Fermer
            </Button>
            <Button>
              <Download className="w-4 h-4 mr-2" />
              Télécharger PDF
            </Button>
          </ModalFooter>
        </Modal>
      )}
    </div>
  )
}
