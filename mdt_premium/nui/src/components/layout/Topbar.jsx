import React from 'react'
import { Search, Bell, X } from 'lucide-react'
import useStore from '../../store/useStore'

export default function Topbar() {
  const { user, company } = useStore()

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount)
  }

  return (
    <header className="h-16 bg-dark-secondary border-b border-gray-700 flex items-center justify-between px-6">
      {/* Left - Company Info */}
      <div className="flex items-center gap-6">
        <div>
          <h1 className="text-lg font-semibold text-gray-100">{company.name}</h1>
          <p className="text-sm text-gray-400">{user.grade}</p>
        </div>
        <div className="h-8 w-px bg-gray-700" />
        <div className="flex items-center gap-4">
          <div>
            <p className="text-xs text-gray-500">Solde Société</p>
            <p className="text-sm font-semibold text-green-400">
              {formatCurrency(company.balance)}
            </p>
          </div>
          <div>
            <p className="text-xs text-gray-500">Personnel</p>
            <p className="text-sm font-semibold text-primary-400">
              {formatCurrency(user.balance)}
            </p>
          </div>
        </div>
      </div>

      {/* Right - Search & Notifications */}
      <div className="flex items-center gap-4">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
          <input
            type="text"
            placeholder="Rechercher..."
            className="pl-10 pr-4 py-2 w-64 bg-dark-tertiary border border-gray-700 rounded-lg text-sm text-gray-100 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-primary-500"
          />
        </div>

        {/* Notifications */}
        <button className="relative p-2 hover:bg-gray-700 rounded-lg transition-colors">
          <Bell className="w-5 h-5 text-gray-400" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full" />
        </button>

        {/* Close Button (pour FiveM) */}
        <button className="p-2 hover:bg-red-500/20 text-red-400 hover:text-red-300 rounded-lg transition-colors">
          <X className="w-5 h-5" />
        </button>
      </div>
    </header>
  )
}
