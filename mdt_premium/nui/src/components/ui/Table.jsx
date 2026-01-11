import React from 'react'

export default function Table({ children, className = '' }) {
  return (
    <div className="w-full overflow-x-auto custom-scrollbar">
      <table className={`w-full ${className}`}>
        {children}
      </table>
    </div>
  )
}

export function TableHeader({ children }) {
  return (
    <thead className="bg-dark-tertiary border-b border-gray-700">
      {children}
    </thead>
  )
}

export function TableBody({ children }) {
  return <tbody className="divide-y divide-gray-700">{children}</tbody>
}

export function TableRow({ children, className = '', onClick }) {
  return (
    <tr
      className={`
        transition-colors
        ${onClick ? 'cursor-pointer hover:bg-gray-800' : ''}
        ${className}
      `}
      onClick={onClick}
    >
      {children}
    </tr>
  )
}

export function TableHead({ children, className = '' }) {
  return (
    <th className={`px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider ${className}`}>
      {children}
    </th>
  )
}

export function TableCell({ children, className = '' }) {
  return (
    <td className={`px-6 py-4 whitespace-nowrap text-sm text-gray-300 ${className}`}>
      {children}
    </td>
  )
}
