import React from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import MainLayout from './components/layout/MainLayout'
import Dashboard from './pages/Dashboard'
import Invoices from './pages/Invoices'
import Employees from './pages/Employees'
import Taxes from './pages/Taxes'
import Commissions from './pages/Commissions'
import Dealership from './pages/Dealership'
import DOJ from './pages/DOJ'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<MainLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="invoices" element={<Invoices />} />
          <Route path="employees" element={<Employees />} />
          <Route path="taxes" element={<Taxes />} />
          <Route path="commissions" element={<Commissions />} />
          <Route path="dealership" element={<Dealership />} />
          <Route path="doj" element={<DOJ />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App
