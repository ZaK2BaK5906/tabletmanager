import React, { useState, useEffect } from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Badge from '../components/ui/Badge'
import Modal, { ModalHeader, ModalBody, ModalFooter } from '../components/ui/Modal'
import Input, { Select } from '../components/ui/Input'
import Table, { TableHeader, TableBody, TableRow, TableHead, TableCell } from '../components/ui/Table'
import { Building2, Plus, Trash2, Building2 as HandshakeIcon } from 'lucide-react'

export default function Partnerships() {
  const [partnerships, setPartnerships] = useState([])
  const [allCompanies, setAllCompanies] = useState([])
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [selectedCompany, setSelectedCompany] = useState('')
  const [isLoading, setIsLoading] = useState(true)

  // Load data on mount
  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    setIsLoading(true)

    // Get all companies
    if (window.fetch) {
      try {
        const companiesResponse = await fetch('https://mdt_premium/getAllCompanies', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        })
        const companiesData = await companiesResponse.json()
        if (companiesData.success) {
          setAllCompanies(companiesData.companies || [])
        }

        // Get partnerships
        const partnershipsResponse = await fetch('https://mdt_premium/getPartnerships', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        })
        const partnershipsData = await partnershipsResponse.json()
        if (partnershipsData.success) {
          setPartnerships(partnershipsData.partnerships || [])
        }
      } catch (error) {
        console.error('Error loading data:', error)
      }
    }

    setIsLoading(false)
  }

  const handleCreatePartnership = async () => {
    if (!selectedCompany) return

    const selectedCompanyData = allCompanies.find(c => c.job === selectedCompany)
    if (!selectedCompanyData) return

    if (window.fetch) {
      try {
        const response = await fetch('https://mdt_premium/createPartnership', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            partnerJob: selectedCompanyData.job,
            partnerName: selectedCompanyData.name
          })
        })
        const data = await response.json()

        if (data.success) {
          setIsCreateModalOpen(false)
          setSelectedCompany('')
          loadData() // Reload partnerships
        }
      } catch (error) {
        console.error('Error creating partnership:', error)
      }
    } else {
      // Demo mode
      setIsCreateModalOpen(false)
      setSelectedCompany('')
    }
  }

  const handleDeletePartnership = async (partnershipId) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer ce partenariat ?')) return

    if (window.fetch) {
      try {
        const response = await fetch('https://mdt_premium/deletePartnership', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ partnershipId })
        })
        const data = await response.json()

        if (data.success) {
          loadData() // Reload partnerships
        }
      } catch (error) {
        console.error('Error deleting partnership:', error)
      }
    }
  }

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3">
            <div className="p-3 bg-blue-500/20 rounded-xl">
              <Building2 className="w-8 h-8 text-blue-400" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-100">Partenariats</h1>
              <p className="text-gray-400 mt-1">Gérez vos partenariats avec d'autres entreprises</p>
            </div>
          </div>
        </div>
        <Button onClick={() => setIsCreateModalOpen(true)}>
          <Plus className="w-5 h-5 mr-2" />
          Nouveau Partenariat
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-500/20 rounded-xl">
                <Building2 className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Partenariats Actifs</p>
                <p className="text-2xl font-bold text-blue-400">{partnerships.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/20 rounded-xl">
                <Building2 className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Entreprises Disponibles</p>
                <p className="text-2xl font-bold text-green-400">{allCompanies.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover className="border-l-4 border-blue-500">
          <CardBody>
            <div>
              <h3 className="font-semibold text-gray-100 mb-1">Avantages Partenariat</h3>
              <p className="text-sm text-gray-400">
                Collaboration, remises spéciales, visibilité accrue
              </p>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Partnerships List */}
      <Card>
        <CardHeader>
          <CardTitle>Liste des Partenariats</CardTitle>
        </CardHeader>
        <CardBody className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-gray-400">
              Chargement...
            </div>
          ) : partnerships.length === 0 ? (
            <div className="p-8 text-center">
              <Building2 className="w-16 h-16 text-gray-600 mx-auto mb-4" />
              <p className="text-gray-400">Aucun partenariat actif</p>
              <p className="text-sm text-gray-500 mt-1">Créez votre premier partenariat !</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Entreprise</TableHead>
                  <TableHead>Partenaire</TableHead>
                  <TableHead>Date de Création</TableHead>
                  <TableHead>Statut</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {partnerships.map((partnership) => (
                  <TableRow key={partnership.id}>
                    <TableCell className="font-medium">
                      <div className="flex items-center gap-2">
                        <Building2 className="w-4 h-4 text-blue-400" />
                        {partnership.company_name}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Building2 className="w-4 h-4 text-green-400" />
                        {partnership.partner_name}
                      </div>
                    </TableCell>
                    <TableCell>
                      {new Date(partnership.created_at).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell>
                      <Badge variant={partnership.status === 'active' ? 'success' : 'warning'}>
                        {partnership.status === 'active' ? 'Actif' : 'Inactif'}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleDeletePartnership(partnership.id)}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardBody>
      </Card>

      {/* Info Card */}
      <Card className="border-l-4 border-blue-500">
        <CardBody>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 p-3 bg-blue-500/20 rounded-xl">
              <Building2 className="w-6 h-6 text-blue-400" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-100 mb-2">À propos des Partenariats</h3>
              <ul className="text-sm text-gray-400 space-y-1 list-disc list-inside">
                <li>Créez des alliances stratégiques avec d'autres entreprises</li>
                <li>Partagez des ressources et collaborez sur des projets</li>
                <li>Bénéficiez de remises et avantages exclusifs</li>
                <li>Augmentez votre visibilité et votre réseau professionnel</li>
                <li>Les partenariats sont visibles par les deux parties</li>
              </ul>
            </div>
          </div>
        </CardBody>
      </Card>

      {/* Create Partnership Modal */}
      <Modal
        isOpen={isCreateModalOpen}
        onClose={() => {
          setIsCreateModalOpen(false)
          setSelectedCompany('')
        }}
        size="md"
      >
        <ModalHeader onClose={() => {
          setIsCreateModalOpen(false)
          setSelectedCompany('')
        }}>
          Nouveau Partenariat
        </ModalHeader>
        <ModalBody>
          <div className="space-y-4">
            <div className="p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
              <p className="text-sm text-blue-400">
                <span className="font-semibold">ℹ️ Info :</span> Sélectionnez une entreprise pour créer un partenariat
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Entreprise Partenaire
              </label>
              <select
                value={selectedCompany}
                onChange={(e) => setSelectedCompany(e.target.value)}
                className="w-full px-4 py-2 bg-dark-tertiary border border-gray-700 rounded-lg text-gray-100 focus:outline-none focus:ring-2 focus:ring-primary-500"
              >
                <option value="">-- Sélectionner une entreprise --</option>
                {allCompanies.map((company) => (
                  <option key={company.job} value={company.job}>
                    {company.name}
                  </option>
                ))}
              </select>
            </div>

            {selectedCompany && (
              <div className="p-4 bg-dark-tertiary rounded-lg">
                <h4 className="font-semibold text-gray-100 mb-2">Entreprise sélectionnée</h4>
                <div className="flex items-center gap-3">
                  <Building2 className="w-8 h-8 text-green-400" />
                  <div>
                    <p className="font-medium text-gray-100">
                      {allCompanies.find(c => c.job === selectedCompany)?.name}
                    </p>
                    <p className="text-xs text-gray-400">Job: {selectedCompany}</p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </ModalBody>
        <ModalFooter>
          <Button variant="ghost" onClick={() => {
            setIsCreateModalOpen(false)
            setSelectedCompany('')
          }}>
            Annuler
          </Button>
          <Button
            disabled={!selectedCompany}
            onClick={handleCreatePartnership}
          >
            Créer Partenariat
          </Button>
        </ModalFooter>
      </Modal>
    </div>
  )
}
