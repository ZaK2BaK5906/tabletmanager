import React from 'react'
import Card, { CardHeader, CardBody, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Table, { TableHeader, TableBody, TableRow, TableHead, TableCell } from '../components/ui/Table'
import Badge from '../components/ui/Badge'
import useStore from '../store/useStore'
import { TrendingUp, DollarSign, Award } from 'lucide-react'

export default function Employees() {
  const { employees } = useStore()

  const totalCommissions = employees.reduce((sum, e) => sum + e.commission, 0)

  return (
    <div className="space-y-6 animate-in">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-100">Employés</h1>
        <p className="text-gray-400 mt-1">Performance et commissions de votre équipe</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-500/20 rounded-xl">
                <TrendingUp className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Total Employés</p>
                <p className="text-2xl font-bold text-gray-100">{employees.length}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-500/20 rounded-xl">
                <DollarSign className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Commissions Dues</p>
                <p className="text-2xl font-bold text-green-400">{totalCommissions.toLocaleString()}€</p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card hover>
          <CardBody>
            <div className="flex items-center gap-4">
              <div className="p-3 bg-purple-500/20 rounded-xl">
                <Award className="w-6 h-6 text-purple-400" />
              </div>
              <div>
                <p className="text-sm text-gray-400">Meilleur Vendeur</p>
                <p className="text-lg font-bold text-gray-100">{employees[0]?.name}</p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Liste des Employés</CardTitle>
            <Button size="sm">Payer les Commissions</Button>
          </div>
        </CardHeader>
        <CardBody className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Employé</TableHead>
                <TableHead>Grade</TableHead>
                <TableHead>CA Généré</TableHead>
                <TableHead>Factures</TableHead>
                <TableHead>Taux Commission</TableHead>
                <TableHead>Commission Due</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {employees.map((employee, index) => (
                <TableRow key={employee.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-primary-500 rounded-full flex items-center justify-center text-white font-semibold">
                        {employee.name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-medium text-gray-100">{employee.name}</p>
                        {index === 0 && (
                          <Badge variant="success" size="sm">Top Vendeur</Badge>
                        )}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>{employee.grade}</TableCell>
                  <TableCell className="font-semibold text-green-400">
                    {employee.totalInvoiced.toLocaleString()}€
                  </TableCell>
                  <TableCell>
                    <Badge variant="info">{employee.invoiceCount}</Badge>
                  </TableCell>
                  <TableCell>{employee.commissionRate}%</TableCell>
                  <TableCell className="font-semibold text-yellow-400">
                    {employee.commission.toLocaleString()}€
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Button size="sm" variant="ghost">Voir Stats</Button>
                      <Button size="sm">Payer</Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardBody>
      </Card>
    </div>
  )
}
