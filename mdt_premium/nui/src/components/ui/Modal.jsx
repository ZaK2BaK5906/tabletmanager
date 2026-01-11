import React from 'react'
import { X } from 'lucide-react'

export default function Modal({ isOpen, onClose, children, size = 'md' }) {
  if (!isOpen) return null

  const sizes = {
    sm: 'max-w-md',
    md: 'max-w-2xl',
    lg: 'max-w-4xl',
    xl: 'max-w-6xl',
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fade-in">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/80 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className={`relative w-full ${sizes[size]} animate-scale-in`}>
        <div className="card-glass shadow-2xl">
          {children}
        </div>
      </div>
    </div>
  )
}

export function ModalHeader({ children, onClose }) {
  return (
    <div className="flex items-center justify-between p-6 border-b border-gray-700">
      <h2 className="text-2xl font-semibold text-gray-100">{children}</h2>
      {onClose && (
        <button
          onClick={onClose}
          className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
        >
          <X className="w-5 h-5 text-gray-400" />
        </button>
      )}
    </div>
  )
}

export function ModalBody({ children, className = '' }) {
  return <div className={`p-6 ${className}`}>{children}</div>
}

export function ModalFooter({ children }) {
  return (
    <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-700">
      {children}
    </div>
  )
}
