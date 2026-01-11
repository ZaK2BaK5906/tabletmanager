import React, { useState } from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Badge from '../components/ui/Badge'
import Modal, { ModalHeader, ModalBody, ModalFooter } from '../components/ui/Modal'
import useStore from '../store/useStore'
import { Car, DollarSign, ShoppingCart, TrendingDown, Search } from 'lucide-react'

export default function Dealership() {
  const { vehicles, company } = useStore()
  const [selectedVehicle, setSelectedVehicle] = useState(null)
  const [searchQuery, setSearchQuery] = useState('')

  // Filtrer les véhicules par recherche
  const filteredVehicles = vehicles.filter(vehicle =>
    vehicle.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    vehicle.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
    vehicle.model.toLowerCase().includes(searchQuery.toLowerCase())
  )

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-100">Concession</h1>
          <p className="text-gray-400 mt-1">Catalogue véhicules avec réduction -40%</p>
        </div>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500" />
          <input
            type="text"
            placeholder="Rechercher un véhicule..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 pr-4 py-2 w-80 bg-dark-tertiary border border-gray-700 rounded-lg text-sm text-gray-100 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-purple-500/20 rounded-xl">
                <Car className="w-6 h-6 text-purple-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">Véhicules</p>
                <p className="text-2xl font-bold text-gray-100">{vehicles.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-green-500/20 rounded-xl">
                <DollarSign className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">Solde Société</p>
                <p className="text-xl font-bold text-green-400">{company.balance.toLocaleString()}$</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-blue-500/20 rounded-xl">
                <TrendingDown className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">Réduction</p>
                <p className="text-2xl font-bold text-blue-400">-40%</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-3">
              <div className="p-3 bg-orange-500/20 rounded-xl">
                <ShoppingCart className="w-6 h-6 text-orange-400" />
              </div>
              <div>
                <p className="text-xs text-gray-400">En Stock</p>
                <p className="text-2xl font-bold text-orange-400">
                  {vehicles.reduce((sum, v) => sum + v.stock, 0)}
                </p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Vehicle Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredVehicles.length === 0 ? (
          <div className="col-span-full text-center py-12">
            <Car className="w-16 h-16 text-gray-600 mx-auto mb-4" />
            <p className="text-gray-400">Aucun véhicule trouvé</p>
            <p className="text-sm text-gray-500 mt-1">Essayez une autre recherche</p>
          </div>
        ) : (
          filteredVehicles.map((vehicle) => (
          <Card key={vehicle.id} hover className="overflow-hidden">
            <div className="h-48 bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center relative">
              <Car className="w-24 h-24 text-gray-600" />
              {vehicle.stock > 0 ? (
                <Badge variant="success" className="absolute top-4 right-4">
                  {vehicle.stock} en stock
                </Badge>
              ) : (
                <Badge variant="danger" className="absolute top-4 right-4">
                  Rupture
                </Badge>
              )}
            </div>
            <CardBody>
              <div className="mb-4">
                <h3 className="text-xl font-semibold text-gray-100 mb-1">{vehicle.name}</h3>
                <Badge variant="info" size="sm">{vehicle.category}</Badge>
              </div>

              <div className="space-y-2 mb-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">Prix Public</span>
                  <span className="text-gray-500 line-through">{vehicle.price.toLocaleString()}$</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">Prix Concession (-40%)</span>
                  <span className="text-xl font-bold text-green-400">{vehicle.dealerPrice.toLocaleString()}$</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-primary-400">Économie</span>
                  <span className="text-primary-400 font-semibold">
                    {(vehicle.price - vehicle.dealerPrice).toLocaleString()}$
                  </span>
                </div>
              </div>

              <Button
                className="w-full"
                disabled={vehicle.stock === 0}
                onClick={() => setSelectedVehicle(vehicle)}
              >
                <ShoppingCart className="w-4 h-4 mr-2" />
                Acheter
              </Button>
            </CardBody>
          </Card>
        ))
        )}
      </div>

      {/* Search Info */}
      {searchQuery && (
        <p className="text-sm text-gray-400 text-center">
          {filteredVehicles.length} véhicule(s) trouvé(s) pour "{searchQuery}"
        </p>
      )}

      {/* Purchase Modal */}
      {selectedVehicle && (
        <Modal
          isOpen={!!selectedVehicle}
          onClose={() => setSelectedVehicle(null)}
          size="md"
        >
          <ModalHeader onClose={() => setSelectedVehicle(null)}>
            Confirmer l'Achat
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <div className="p-4 bg-dark-tertiary rounded-lg">
                <h3 className="text-xl font-semibold text-gray-100 mb-2">{selectedVehicle.name}</h3>
                <Badge variant="info">{selectedVehicle.category}</Badge>
              </div>

              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-gray-400">Prix Public</span>
                  <span className="text-gray-500 line-through">{selectedVehicle.price.toLocaleString()}$</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">Réduction (-40%)</span>
                  <span className="text-green-400">-{(selectedVehicle.price - selectedVehicle.dealerPrice).toLocaleString()}$</span>
                </div>
                <div className="pt-2 border-t border-gray-700 flex justify-between">
                  <span className="font-semibold text-gray-100">Prix Concession</span>
                  <span className="text-2xl font-bold text-green-400">{selectedVehicle.dealerPrice.toLocaleString()}$</span>
                </div>
              </div>

              <div className="p-3 bg-blue-500/10 border border-blue-500/30 rounded-lg">
                <p className="text-sm text-blue-400">
                  <span className="font-semibold">Solde après achat :</span> {(company.balance - selectedVehicle.dealerPrice).toLocaleString()}$
                </p>
              </div>

              {company.balance < selectedVehicle.dealerPrice && (
                <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
                  <p className="text-sm text-red-400">
                    <span className="font-semibold">Fonds insuffisants !</span> Il vous manque {(selectedVehicle.dealerPrice - company.balance).toLocaleString()}$
                  </p>
                </div>
              )}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" onClick={() => setSelectedVehicle(null)}>
              Annuler
            </Button>
            <Button disabled={company.balance < selectedVehicle.dealerPrice}>
              Confirmer l'Achat
            </Button>
          </ModalFooter>
        </Modal>
      )}
    </div>
  )
}
