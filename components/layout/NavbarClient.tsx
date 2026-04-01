'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

type NavUser = {
  name: string | null
  email: string
  role: string
} | null

export function NavbarClient({
  user,
  section,
}: {
  user: NavUser
  section: 'links' | 'user'
}) {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()

  const isAdmin = user && ['HR', 'Admin', 'Principal', 'HiringManager',
    'AcademicDirector', 'SPEDDirector', 'OperationManager', 'AssistantPrincipal', 'ITSupport', 'ExecutiveDirector'].includes(user.role)

  const linkClass = (path: string) =>
    `inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
      pathname === path || pathname.startsWith(path + '/')
        ? 'border-primary-500 text-gray-900'
        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
    }`

  if (section === 'links') {
    return (
      <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
        <Link href="/careers" className={linkClass('/careers')}>
          Careers
        </Link>
        {user && isAdmin && (
          <Link href="/admin" className={linkClass('/admin')}>
            Admin
          </Link>
        )}
        {user && !isAdmin && (
          <Link href="/my-applications" className={linkClass('/my-applications')}>
            My Applications
          </Link>
        )}
      </div>
    )
  }

  return (
    <div className="flex items-center">
      {user ? (
        <div className="flex items-center space-x-4">
          <span className="text-sm text-gray-700">{user.name || user.email}</span>
          <Link href="/settings" className="text-sm text-gray-500 hover:text-gray-700">
            Settings
          </Link>
          <button
            onClick={async () => {
              await supabase.auth.signOut()
              router.push('/')
              router.refresh()
            }}
            className="text-sm text-gray-500 hover:text-gray-700"
          >
            Sign Out
          </button>
        </div>
      ) : (
        <Link
          href="/login"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700"
        >
          Sign In
        </Link>
      )}
    </div>
  )
}
