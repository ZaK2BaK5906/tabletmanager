import React, { useEffect } from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import useStore from './store/useStore'
import MainLayout from './components/layout/MainLayout'
import Dashboard from './pages/Dashboard'
import Invoices from './pages/Invoices'
import MyInvoices from './pages/MyInvoices'
import Employees from './pages/Employees'
import Taxes from './pages/Taxes'
import Commissions from './pages/Commissions'
import Dealership from './pages/Dealership'
import Partnerships from './pages/Partnerships'
import DOJ from './pages/DOJ'

function App() {
  const { visible, setVisible } = useStore()

  useEffect(() => {
    // Listen for NUI messages
    const handleMessage = (event) => {
      const { action, data } = event.data

      if (action === 'setVisible') {
        setVisible(data.visible)
      } else if (action === 'updateUser') {
        // TODO: Update user data from ESX
      } else if (action === 'updateCompany') {
        // TODO: Update company data from ESX
      }
    }

    window.addEventListener('message', handleMessage)

    // Close on ESC
    const handleKeyDown = (event) => {
      if (event.key === 'Escape' && visible) {
        fetch('https://mdt_premium/close', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        })
        setVisible(false)
      }
    }

    window.addEventListener('keydown', handleKeyDown)

    return () => {
      window.removeEventListener('message', handleMessage)
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [visible, setVisible])

  if (!visible) {
    return null
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<MainLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="invoices" element={<Invoices />} />
          <Route path="my-invoices" element={<MyInvoices />} />
          <Route path="employees" element={<Employees />} />
          <Route path="taxes" element={<Taxes />} />
          <Route path="commissions" element={<Commissions />} />
          <Route path="dealership" element={<Dealership />} />
          <Route path="partnerships" element={<Partnerships />} />
          <Route path="doj" element={<DOJ />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App
