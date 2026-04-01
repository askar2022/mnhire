import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export async function getCurrentUser() {
  const supabase = await createClient()
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  // No auth session at all — truly not logged in
  if (authError || !user) return null

  const { data: userData } = await supabase
    .from('users')
    .select('*')
    .eq('id', user.id)
    .single()

  // Auth session exists but profile query failed (e.g. RLS issue)
  // Return a minimal user object so we don't trigger a redirect loop
  if (!userData) {
    return {
      id: user.id,
      email: user.email ?? '',
      name: user.email ?? '',
      role: 'Applicant',
      school_site: null,
      is_active: true,
    }
  }

  return userData
}

export async function requireAuth() {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/login')
  }
  return user
}

export async function requireRole(allowedRoles: string[]) {
  const user = await requireAuth()
  if (!allowedRoles.includes(user.role)) {
    redirect('/unauthorized')
  }
  return user
}

