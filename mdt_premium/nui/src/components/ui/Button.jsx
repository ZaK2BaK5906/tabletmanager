import React from 'react'

const variants = {
  primary: 'bg-primary-500 hover:bg-primary-600 text-white shadow-md hover:shadow-glow',
  secondary: 'bg-gray-700 hover:bg-gray-600 text-white',
  danger: 'bg-red-500 hover:bg-red-600 text-white shadow-md',
  success: 'bg-green-500 hover:bg-green-600 text-white shadow-md',
  ghost: 'bg-transparent hover:bg-gray-800 text-gray-300 border border-gray-700',
  link: 'bg-transparent hover:bg-gray-800 text-primary-400 hover:text-primary-300',
}

const sizes = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg',
}

export default function Button({
  children,
  variant = 'primary',
  size = 'md',
  className = '',
  disabled = false,
  loading = false,
  ...props
}) {
  return (
    <button
      className={`
        ${variants[variant]}
        ${sizes[size]}
        rounded-lg font-medium
        transition-all duration-200
        disabled:opacity-50 disabled:cursor-not-allowed
        focus-ring
        ${loading ? 'cursor-wait' : ''}
        ${className}
      `}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? (
        <span className="flex items-center gap-2">
          <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          {children}
        </span>
      ) : children}
    </button>
  )
}
