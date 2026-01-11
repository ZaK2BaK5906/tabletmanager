import React from 'react'

export default function Card({ children, className = '', glass = false, hover = false }) {
  return (
    <div
      className={`
        ${glass ? 'card-glass' : 'card'}
        ${hover ? 'transition-all duration-200 hover:shadow-xl hover:-translate-y-1' : ''}
        ${className}
      `}
    >
      {children}
    </div>
  )
}

export function CardHeader({ children, className = '' }) {
  return (
    <div className={`p-6 border-b border-gray-700 ${className}`}>
      {children}
    </div>
  )
}

export function CardBody({ children, className = '' }) {
  return (
    <div className={`p-6 ${className}`}>
      {children}
    </div>
  )
}

export function CardFooter({ children, className = '' }) {
  return (
    <div className={`p-6 border-t border-gray-700 ${className}`}>
      {children}
    </div>
  )
}

export function CardTitle({ children, className = '' }) {
  return (
    <h3 className={`text-xl font-semibold text-gray-100 ${className}`}>
      {children}
    </h3>
  )
}
