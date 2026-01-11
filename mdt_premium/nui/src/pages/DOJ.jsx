import React, { useState } from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Badge from '../components/ui/Badge'
import Input from '../components/ui/Input'
import Modal, { ModalHeader, ModalBody, ModalFooter } from '../components/ui/Modal'
import Table, { TableHeader, TableBody, TableRow, TableHead, TableCell } from '../components/ui/Table'
import useStore from '../store/useStore'
import { Scale, Settings, AlertTriangle, DollarSign, Calendar, Building2, Search } from 'lucide-react'

export default function DOJ() {
  const { dojData } = useStore()
  const [isEditTaxRateModalOpen, setIsEditTaxRateModalOpen] = useState(false)
  const [isEditTaxDateModalOpen, setIsEditTaxDateModalOpen] = useState(false)
  const [newTaxRate, setNewTaxRate] = useState(dojData.globalTaxRate)
  const [newTaxDate, setNewTaxDate] = useState('25')
  const [companySearch, setCompanySearch] = useState('')

  const filteredCompanies = dojData.companies.filter(company =>
    company.name.toLowerCase().includes(companySearch.toLowerCase())
  )

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-yellow-500/20 rounded-xl">
              <Scale className="w-8 h-8 text-yellow-400" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-100">Department of Justice</h1>
              <p className="text-gray-400 mt-1">Contrôle économique et gestion fiscale</p>
            </div>
          </div>
        </div>
        <Badge variant="warning" className="text-lg px-4 py-2">
          <Scale className="w-5 h-5 mr-2" />
          Accès DOJ
        </Badge>
      </div>

      {/* Global Tax Settings */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card hover>
          <CardBody>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-yellow-500/20 rounded-xl">
                  <DollarSign className="w-6 h-6 text-yellow-400" />
                </div>
                <div>
                  <p className="text-sm text-gray-400">Taux de Taxe Global</p>
                  <p className="text-2xl font-bold text-yellow-400">{dojData.globalTaxRate}%</p>
                </div>
              </div>
              <Button size="sm" onClick={() => setIsEditTaxRateModalOpen(true)}>
                <Settings className="w-4 h-4" />
              </Button>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-blue-500/20 rounded-xl">
                  <Calendar className="w-6 h-6 text-blue-400" />
                </div>
                <div>
                  <p className="text-sm text-gray-400">Date Limite Paiement</p>
                  <p className="text-2xl font-bold text-blue-400">Jour {dojData.paymentDeadlineDay}</p>
                </div>
              </div>
              <Button size="sm" onClick={() => setIsEditTaxDateModalOpen(true)}>
                <Settings className="w-4 h-4" />
              </Button>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-green-500/20 rounded-xl">
                <Building2 className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Entreprises Enregistrées</p>
                <p className="text-2xl font-bold text-green-400">{dojData.companies.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Alert - Suspicious Companies */}
      {dojData.suspiciousCompanies.length > 0 && (
        <Card className="border-l-4 border-red-500">
          <CardBody>
            <div className="flex items-start gap-4">
              <div className="flex-shrink-0 p-3 bg-red-500/20 rounded-xl">
                <AlertTriangle className="w-6 h-6 text-red-400" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-100 mb-1">
                  Entreprises Suspectes ({dojData.suspiciousCompanies.length})
                </h3>
                <p className="text-sm text-gray-400 mb-2">
                  Ces entreprises ont des activités suspectes et nécessitent une enquête
                </p>
                <div className="flex flex-wrap gap-2">
                  {dojData.suspiciousCompanies.map((company, index) => (
                    <Badge key={index} variant="danger">
                      {company}
                    </Badge>
                  ))}
                </div>
              </div>
            </div>
          </CardBody>
        </Card>
      )}

      {/* Companies Management */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Gestion des Entreprises</CardTitle>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input
                type="text"
                placeholder="Rechercher une entreprise..."
                value={companySearch}
                onChange={(e) => setCompanySearch(e.target.value)}
                className="pl-10 pr-4 py-2 w-64 bg-dark-tertiary border border-gray-700 rounded-lg text-sm text-gray-100 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
          </div>
        </CardHeader>
        <CardBody className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Entreprise</TableHead>
                <TableHead>Propriétaire</TableHead>
                <TableHead>Taxes Dues</TableHead>
                <TableHead>Dernier Paiement</TableHead>
                <TableHead>Statut</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredCompanies.map((company) => (
                <TableRow key={company.id}>
                  <TableCell className="font-medium">{company.name}</TableCell>
                  <TableCell>{company.owner}</TableCell>
                  <TableCell className="font-semibold text-yellow-400">
                    {company.taxesDue.toLocaleString()}$
                  </TableCell>
                  <TableCell>{company.lastPayment}</TableCell>
                  <TableCell>
                    {company.status === 'compliant' && (
                      <Badge variant="success">Conforme</Badge>
                    )}
                    {company.status === 'warning' && (
                      <Badge variant="warning">Attention</Badge>
                    )}
                    {company.status === 'overdue' && (
                      <Badge variant="danger">En retard</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Button size="sm" variant="ghost">
                        Audit
                      </Button>
                      <Button size="sm" variant="ghost">
                        Sanction
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardBody>
      </Card>

      {/* DOJ Powers */}
      <Card className="border-l-4 border-yellow-500">
        <CardBody>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 p-3 bg-yellow-500/20 rounded-xl">
              <Scale className="w-6 h-6 text-yellow-400" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-100 mb-2">Pouvoirs du DOJ</h3>
              <ul className="text-sm text-gray-400 space-y-1 list-disc list-inside">
                <li>Modifier le taux de taxe global (affecte toutes les nouvelles factures)</li>
                <li>Définir la date limite de paiement mensuel des taxes</li>
                <li>Auditer les entreprises et consulter leurs finances complètes</li>
                <li>Appliquer des sanctions et pénalités aux entreprises non conformes</li>
                <li>Exonérer temporairement certaines entreprises de taxes</li>
                <li>Saisir les actifs d'entreprises en infraction grave</li>
              </ul>
            </div>
          </div>
        </CardBody>
      </Card>

      {/* Edit Tax Rate Modal */}
      <Modal
        isOpen={isEditTaxRateModalOpen}
        onClose={() => setIsEditTaxRateModalOpen(false)}
      >
        <ModalHeader onClose={() => setIsEditTaxRateModalOpen(false)}>
          Modifier le Taux de Taxe Global
        </ModalHeader>
        <ModalBody>
          <div className="space-y-4">
            <div className="p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
              <p className="text-sm text-yellow-400">
                <span className="font-semibold">⚠️ Attention :</span> Cette modification affectera toutes les nouvelles factures créées dans l'État.
              </p>
            </div>

            <Input
              label="Nouveau Taux de Taxe (%)"
              type="number"
              min="0"
              max="100"
              value={newTaxRate}
              onChange={(e) => setNewTaxRate(e.target.value)}
            />

            <div className="p-4 bg-dark-tertiary rounded-lg">
              <div className="flex items-center justify-between">
                <span className="text-gray-400">Taux actuel</span>
                <span className="font-semibold text-gray-100">{dojData.globalTaxRate}%</span>
              </div>
              <div className="flex items-center justify-between mt-2">
                <span className="text-gray-400">Nouveau taux</span>
                <span className="font-semibold text-yellow-400">{newTaxRate}%</span>
              </div>
            </div>
          </div>
        </ModalBody>
        <ModalFooter>
          <Button variant="ghost" onClick={() => setIsEditTaxRateModalOpen(false)}>
            Annuler
          </Button>
          <Button>
            Appliquer le Nouveau Taux
          </Button>
        </ModalFooter>
      </Modal>

      {/* Edit Tax Date Modal */}
      <Modal
        isOpen={isEditTaxDateModalOpen}
        onClose={() => setIsEditTaxDateModalOpen(false)}
      >
        <ModalHeader onClose={() => setIsEditTaxDateModalOpen(false)}>
          Modifier la Date Limite de Paiement
        </ModalHeader>
        <ModalBody>
          <div className="space-y-4">
            <div className="p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
              <p className="text-sm text-blue-400">
                <span className="font-semibold">ℹ️ Info :</span> Les entreprises devront payer leurs taxes avant cette date chaque mois.
              </p>
            </div>

            <Input
              label="Jour du Mois (1-31)"
              type="number"
              min="1"
              max="31"
              value={newTaxDate}
              onChange={(e) => setNewTaxDate(e.target.value)}
            />

            <div className="p-4 bg-dark-tertiary rounded-lg">
              <div className="flex items-center justify-between">
                <span className="text-gray-400">Date actuelle</span>
                <span className="font-semibold text-gray-100">Jour {dojData.paymentDeadlineDay}</span>
              </div>
              <div className="flex items-center justify-between mt-2">
                <span className="text-gray-400">Nouvelle date</span>
                <span className="font-semibold text-blue-400">Jour {newTaxDate}</span>
              </div>
            </div>
          </div>
        </ModalBody>
        <ModalFooter>
          <Button variant="ghost" onClick={() => setIsEditTaxDateModalOpen(false)}>
            Annuler
          </Button>
          <Button>
            Appliquer la Nouvelle Date
          </Button>
        </ModalFooter>
      </Modal>
    </div>
  )
}
