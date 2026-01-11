import React from 'react'
import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  FileText,
  Users,
  DollarSign,
  TrendingUp,
  Car,
  Building2,
  Scale,
} from 'lucide-react'
import useStore from '../../store/useStore'

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
  { icon: FileText, label: 'Factures', path: '/invoices' },
  { icon: Users, label: 'Employés', path: '/employees' },
  { icon: DollarSign, label: 'Taxes', path: '/taxes' },
  { icon: TrendingUp, label: 'Commissions', path: '/commissions' },
  { icon: Car, label: 'Concession', path: '/dealership' },
  { icon: Building2, label: 'Partenariats', path: '/partnerships' },
]

export default function Sidebar() {
  const { user } = useStore()

  return (
    <aside className="w-20 bg-dark-secondary border-r border-gray-700 flex flex-col items-center py-6 gap-4">
      {/* Logo */}
      <div className="w-12 h-12 bg-gradient-to-br from-primary-500 to-primary-700 rounded-xl flex items-center justify-center mb-4 shadow-glow">
        <span className="text-2xl font-bold text-white">M</span>
      </div>

      {/* Menu Items */}
      <nav className="flex-1 w-full flex flex-col items-center gap-2">
        {menuItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `
              group relative w-14 h-14 flex items-center justify-center
              rounded-xl transition-all duration-200
              ${
                isActive
                  ? 'bg-primary-500 text-white shadow-glow'
                  : 'text-gray-400 hover:bg-gray-700 hover:text-white'
              }
            `
            }
          >
            <item.icon className="w-6 h-6" />
            <span className="absolute left-full ml-4 px-3 py-1.5 bg-gray-900 text-white text-sm rounded-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-10">
              {item.label}
            </span>
          </NavLink>
        ))}

        {/* DOJ (si accès) */}
        {user.canAccessDOJ && (
          <NavLink
            to="/doj"
            className={({ isActive }) =>
              `
              group relative w-14 h-14 flex items-center justify-center
              rounded-xl transition-all duration-200
              ${
                isActive
                  ? 'bg-yellow-500 text-white shadow-glow'
                  : 'text-gray-400 hover:bg-gray-700 hover:text-white'
              }
            `
            }
          >
            <Scale className="w-6 h-6" />
            <span className="absolute left-full ml-4 px-3 py-1.5 bg-gray-900 text-white text-sm rounded-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-10">
              DOJ
            </span>
          </NavLink>
        )}
      </nav>

      {/* User Avatar */}
      <div className="w-12 h-12 bg-gray-700 rounded-full flex items-center justify-center">
        <span className="text-lg font-semibold text-white">
          {user.name.charAt(0)}
        </span>
      </div>
    </aside>
  )
}
