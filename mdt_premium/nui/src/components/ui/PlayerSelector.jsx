import React, { useState } from 'react'
import Button from './Button'
import Input from './Input'
import { Users, Hash, Target } from 'lucide-react'

/**
 * PlayerSelector Component
 * Permet de sélectionner un joueur de deux façons:
 * 1. Détecter automatiquement le joueur le plus proche
 * 2. Entrer manuellement l'ID du joueur (ESX server ID)
 */
export default function PlayerSelector({ onPlayerSelect, selectedPlayer }) {
  const [mode, setMode] = useState('auto') // 'auto' ou 'manual'
  const [manualId, setManualId] = useState('')
  const [isDetecting, setIsDetecting] = useState(false)

  // Fonction pour détecter le joueur le plus proche
  const handleDetectNearestPlayer = () => {
    setIsDetecting(true)

    // Envoyer message NUI au client FiveM
    if (window.fetch) {
      fetch('https://mdt_premium/getNearestPlayer', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
      })
        .then(resp => resp.json())
        .then(data => {
          setIsDetecting(false)
          if (data.success && data.player) {
            onPlayerSelect({
              id: data.player.id,
              name: data.player.name,
              distance: data.player.distance
            })
          }
        })
        .catch(() => {
          setIsDetecting(false)
          // Mode démo - simuler un joueur proche
          onPlayerSelect({
            id: 1,
            name: 'Joueur Proche (DEMO)',
            distance: 2.5
          })
        })
    } else {
      // Mode développement - simuler un joueur
      setTimeout(() => {
        setIsDetecting(false)
        onPlayerSelect({
          id: 1,
          name: 'John Doe (DEMO)',
          distance: 2.5
        })
      }, 500)
    }
  }

  // Fonction pour chercher un joueur par ID
  const handleManualIdSubmit = () => {
    const playerId = parseInt(manualId)

    if (!playerId || playerId < 1) {
      return
    }

    // Envoyer message NUI au client FiveM
    if (window.fetch) {
      fetch('https://mdt_premium/getPlayerById', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ playerId })
      })
        .then(resp => resp.json())
        .then(data => {
          if (data.success && data.player) {
            onPlayerSelect({
              id: data.player.id,
              name: data.player.name,
              distance: null
            })
          }
        })
        .catch(() => {
          // Mode démo
          onPlayerSelect({
            id: playerId,
            name: `Joueur #${playerId} (DEMO)`,
            distance: null
          })
        })
    } else {
      // Mode développement
      onPlayerSelect({
        id: playerId,
        name: `Joueur #${playerId} (DEMO)`,
        distance: null
      })
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-2">
          Sélectionner un Joueur
        </label>

        {/* Mode Selector */}
        <div className="flex gap-2 mb-4">
          <Button
            type="button"
            size="sm"
            variant={mode === 'auto' ? 'primary' : 'ghost'}
            onClick={() => setMode('auto')}
            className="flex-1"
          >
            <Target className="w-4 h-4 mr-2" />
            Plus Proche
          </Button>
          <Button
            type="button"
            size="sm"
            variant={mode === 'manual' ? 'primary' : 'ghost'}
            onClick={() => setMode('manual')}
            className="flex-1"
          >
            <Hash className="w-4 h-4 mr-2" />
            ID Manuel
          </Button>
        </div>

        {/* Auto Mode - Nearest Player */}
        {mode === 'auto' && (
          <div className="space-y-3">
            <Button
              type="button"
              onClick={handleDetectNearestPlayer}
              disabled={isDetecting}
              className="w-full"
            >
              <Users className="w-5 h-5 mr-2" />
              {isDetecting ? 'Recherche...' : 'Détecter Joueur Proche'}
            </Button>
            <p className="text-xs text-gray-400 text-center">
              Détecte automatiquement le joueur le plus proche de vous
            </p>
          </div>
        )}

        {/* Manual Mode - Enter Player ID */}
        {mode === 'manual' && (
          <div className="space-y-3">
            <div className="flex gap-2">
              <Input
                type="number"
                placeholder="Entrer l'ID du joueur (ex: 1, 2, 3...)"
                value={manualId}
                onChange={(e) => setManualId(e.target.value)}
                onKeyPress={(e) => {
                  if (e.key === 'Enter') {
                    handleManualIdSubmit()
                  }
                }}
                className="flex-1"
              />
              <Button
                type="button"
                onClick={handleManualIdSubmit}
                disabled={!manualId || parseInt(manualId) < 1}
              >
                OK
              </Button>
            </div>
            <p className="text-xs text-gray-400 text-center">
              Entrez l'ID du serveur du joueur (visible en jeu avec /id)
            </p>
          </div>
        )}
      </div>

      {/* Selected Player Display */}
      {selectedPlayer && (
        <div className="p-4 bg-primary-500/10 border border-primary-500/30 rounded-lg">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-primary-500/20 rounded-lg">
              <Users className="w-5 h-5 text-primary-400" />
            </div>
            <div className="flex-1">
              <p className="font-semibold text-gray-100">{selectedPlayer.name}</p>
              <div className="flex items-center gap-3 text-xs text-gray-400">
                <span>ID: {selectedPlayer.id}</span>
                {selectedPlayer.distance !== null && (
                  <span>Distance: {selectedPlayer.distance.toFixed(1)}m</span>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
