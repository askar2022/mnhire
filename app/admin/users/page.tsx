'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import Link from 'next/link'

const roleColors: Record<string, string> = {
  Admin: 'bg-purple-100 text-purple-800',
  HR: 'bg-blue-100 text-blue-800',
  Principal: 'bg-green-100 text-green-800',
  HiringManager: 'bg-yellow-100 text-yellow-800',
  Interviewer: 'bg-indigo-100 text-indigo-800',
  Applicant: 'bg-gray-100 text-gray-800',
  AcademicDirector: 'bg-teal-100 text-teal-800',
  SPEDDirector: 'bg-orange-100 text-orange-800',
  OperationManager: 'bg-cyan-100 text-cyan-800',
  AssistantPrincipal: 'bg-lime-100 text-lime-800',
  ITSupport: 'bg-rose-100 text-rose-800',
  ExecutiveDirector: 'bg-red-100 text-red-800',
}

const roleLabels: Record<string, string> = {
  Admin: 'Admin',
  HR: 'HR',
  Principal: 'Principal',
  HiringManager: 'Hiring Manager',
  Interviewer: 'Interviewer',
  Applicant: 'Applicant',
  AcademicDirector: 'Academic Director',
  SPEDDirector: 'SPED Director',
  OperationManager: 'Operation Manager',
  AssistantPrincipal: 'Assistant Principal',
  ITSupport: 'IT Application Support',
  ExecutiveDirector: 'Executive Director',
}

export default function AdminUsersPage() {
  const router = useRouter()
  const supabase = createClient()
  
  const [users, setUsers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [creating, setCreating] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [editingUser, setEditingUser] = useState<any>(null)
  const [editData, setEditData] = useState({ role: '', school_site: '', name: '' })
  const [saving, setSaving] = useState(false)
  const [tab, setTab] = useState<'active' | 'archived'>('active')

  const [formData, setFormData] = useState({
    email: '',
    name: '',
    password: '',
    role: 'HR',
    school_site: '',
  })

  useEffect(() => {
    checkAuth()
  }, [])

  useEffect(() => {
    fetchUsers()
  }, [tab])

  const checkAuth = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      router.push('/login')
      return
    }

    // Check if user has admin/HR role
    const { data: userData } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!userData || !['HR', 'Admin'].includes(userData.role)) {
      router.push('/admin/jobs')
    }
  }

  const fetchUsers = async () => {
    setLoading(true)
    try {
      const response = await fetch(`/api/admin/users${tab === 'archived' ? '?archived=true' : ''}`)
      const data = await response.json()
      if (data.users) setUsers(data.users)
    } catch (err) {
      console.error('Failed to fetch users:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleArchive = async (user: any) => {
    if (!confirm(`Archive ${user.name}? They will lose access but can be restored later.`)) return
    try {
      const response = await fetch('/api/admin/users', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: user.id, is_active: false }),
      })
      if (!response.ok) throw new Error('Failed to archive user')
      setSuccess(`✅ ${user.name} has been archived.`)
      fetchUsers()
    } catch (err: any) {
      setError(err.message)
    }
  }

  const handleRestore = async (user: any) => {
    try {
      const response = await fetch('/api/admin/users', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: user.id, is_active: true }),
      })
      if (!response.ok) throw new Error('Failed to restore user')
      setSuccess(`✅ ${user.name} has been restored.`)
      fetchUsers()
    } catch (err: any) {
      setError(err.message)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    setCreating(true)

    try {
      const response = await fetch('/api/admin/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to create user')
      }

      setSuccess(`✅ Admin user created successfully: ${formData.email}`)
      setFormData({
        email: '',
        name: '',
        password: '',
        role: 'HR',
        school_site: '',
      })
      setShowCreateModal(false)
      fetchUsers() // Refresh the list
    } catch (err: any) {
      setError(err.message || 'An error occurred')
    } finally {
      setCreating(false)
    }
  }

  const handleEdit = (user: any) => {
    setEditingUser(user)
    setEditData({ role: user.role, school_site: user.school_site || '', name: user.name })
    setError('')
  }

  const handleSaveEdit = async () => {
    setSaving(true)
    setError('')
    try {
      const response = await fetch('/api/admin/users', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: editingUser.id, ...editData }),
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error || 'Failed to update user')
      setSuccess(`✅ ${editData.name}'s role updated to ${editData.role}`)
      setEditingUser(null)
      fetchUsers()
    } catch (err: any) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="p-8">
        <div className="animate-pulse">Loading...</div>
      </div>
    )
  }

  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        {/* Quick Navigation */}
        <div className="mb-6 flex gap-2">
          <Link
            href="/admin"
            className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            🏠 Dashboard
          </Link>
          <Link
            href="/admin/jobs"
            className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            📋 Job Postings
          </Link>
          <Link
            href="/admin/users"
            className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium"
          >
            👥 User Management
          </Link>
        </div>

        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">User Management</h1>
            <p className="text-gray-600 mt-2">
              Create and manage Admin and HR staff accounts
            </p>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition flex items-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Create Admin User
          </button>
        </div>

        {/* Success/Error Messages */}
        {success && (
          <div className="mb-6 p-4 bg-green-50 border border-green-200 text-green-800 rounded-lg">
            {success}
          </div>
        )}
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 text-red-800 rounded-lg">
            {error}
          </div>
        )}

        {/* Active / Archived Tabs */}
        <div className="flex gap-2 mb-4 border-b border-gray-200">
          <button
            onClick={() => setTab('active')}
            className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
              tab === 'active'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            Active Users
          </button>
          <button
            onClick={() => setTab('archived')}
            className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
              tab === 'archived'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            Archived Users
          </button>
        </div>

        {/* Users Table */}
        <div className="bg-white shadow-md rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Role
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  School
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Created
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {users.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{user.name}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-600">{user.email}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-medium ${
                        roleColors[user.role] || roleColors.Applicant
                      }`}
                    >
                      {roleLabels[user.role] || user.role}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {user.school_site || '-'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-3">
                      {tab === 'active' && (
                        <button
                          onClick={() => handleEdit(user)}
                          className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                        >
                          Edit
                        </button>
                      )}
                      {tab === 'active' ? (
                        <button
                          onClick={() => handleArchive(user)}
                          className="text-orange-500 hover:text-orange-700 text-sm font-medium"
                        >
                          Archive
                        </button>
                      ) : (
                        <button
                          onClick={() => handleRestore(user)}
                          className="text-green-600 hover:text-green-800 text-sm font-medium"
                        >
                          Restore
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Edit User Modal */}
        {editingUser && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
              <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-bold text-gray-900">Edit User</h2>
                  <button onClick={() => setEditingUser(null)} className="text-gray-400 hover:text-gray-600">
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                    <input
                      type="text"
                      value={editData.name}
                      onChange={(e) => setEditData({ ...editData, name: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
                    <select
                      value={editData.role}
                      onChange={(e) => setEditData({ ...editData, role: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="Admin">Admin</option>
                      <option value="HR">HR</option>
                      <option value="Principal">Principal</option>
                      <option value="AcademicDirector">Academic Director</option>
                      <option value="AssistantPrincipal">Assistant Principal</option>
                      <option value="SPEDDirector">SPED Director</option>
                      <option value="OperationManager">Operation Manager</option>
                      <option value="ITSupport">IT Application Support</option>
                      <option value="ExecutiveDirector">Executive Director</option>
                      <option value="HiringManager">Hiring Manager</option>
                      <option value="Interviewer">Interviewer</option>
                      <option value="Applicant">Applicant</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">School Site</label>
                    <select
                      value={editData.school_site}
                      onChange={(e) => setEditData({ ...editData, school_site: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="">None</option>
                      <option value="Harvest">Harvest</option>
                      <option value="Wakanda">Wakanda</option>
                      <option value="Sankofa">Sankofa</option>
                    </select>
                  </div>

                  {error && (
                    <div className="p-3 bg-red-50 border border-red-200 text-red-800 rounded text-sm">{error}</div>
                  )}

                  <div className="flex gap-3 pt-2">
                    <button
                      onClick={() => setEditingUser(null)}
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleSaveEdit}
                      disabled={saving}
                      className="flex-1 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
                    >
                      {saving ? 'Saving...' : 'Save Changes'}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Create User Modal */}
        {showCreateModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
              <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-2xl font-bold text-gray-900">Create Admin User</h2>
                  <button
                    onClick={() => {
                      setShowCreateModal(false)
                      setError('')
                    }}
                    className="text-gray-400 hover:text-gray-600"
                  >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Full Name *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      placeholder="John Doe"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Email *
                    </label>
                    <input
                      type="email"
                      required
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      placeholder="john@mnhire.org"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Temporary Password *
                    </label>
                    <input
                      type="password"
                      required
                      value={formData.password}
                      onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      placeholder="Min 6 characters"
                      minLength={6}
                    />
                    <p className="text-xs text-gray-500 mt-1">User can change this after first login</p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Role *
                    </label>
                    <select
                      required
                      value={formData.role}
                      onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="HR">HR</option>
                      <option value="Admin">Admin (Full Access)</option>
                      <option value="Principal">Principal</option>
                      <option value="AcademicDirector">Academic Director</option>
                      <option value="AssistantPrincipal">Assistant Principal</option>
                      <option value="SPEDDirector">SPED Director</option>
                      <option value="OperationManager">Operation Manager</option>
                      <option value="ITSupport">IT Application Support</option>
                      <option value="ExecutiveDirector">Executive Director</option>
                      <option value="HiringManager">Hiring Manager</option>
                      <option value="Interviewer">Interviewer</option>
                    </select>
                  </div>

                  {error && (
                    <div className="p-3 bg-red-50 border border-red-200 text-red-800 rounded text-sm">
                      {error}
                    </div>
                  )}

                  <div className="flex gap-3 pt-4">
                    <button
                      type="button"
                      onClick={() => {
                        setShowCreateModal(false)
                        setError('')
                      }}
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                      disabled={creating}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={creating}
                      className="flex-1 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                    >
                      {creating ? 'Creating...' : 'Create User'}
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

