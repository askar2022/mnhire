import { createClient, createAdminClient } from '@/lib/supabase/server'
import { requireRole } from '@/lib/auth'
import { NextResponse } from 'next/server'

// Create new admin user
export async function POST(request: Request) {
  try {
    const user = await requireRole(['HR', 'Admin'])
    const supabase = await createClient()
    const adminClient = createAdminClient()
    
    const { email, name, role, school_site, password } = await request.json()

    // Validate required fields
    if (!email || !name || !role || !password) {
      return NextResponse.json(
        { error: 'Email, name, role, and password are required' },
        { status: 400 }
      )
    }

    // Validate role
    const validRoles = ['HR', 'Admin', 'Principal', 'HiringManager', 'Interviewer',
      'AcademicDirector', 'SPEDDirector', 'OperationManager', 'AssistantPrincipal', 'ITSupport', 'ExecutiveDirector']
    if (!validRoles.includes(role)) {
      return NextResponse.json(
        { error: 'Invalid role. Must be either HR or Admin' },
        { status: 400 }
      )
    }

    console.log(`Creating admin user: ${email} with role: ${role}`)

    // Use Supabase Admin API to create auth user
    const { data: authData, error: authError } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        name,
      },
    })

    if (authError) {
      console.error('Auth creation error:', authError)
      return NextResponse.json({ error: authError.message }, { status: 500 })
    }

    // Update the user record with the correct role and school
    const updateData: any = {
      role,
      school_site: school_site || null,
      name,
    }
    const { error: updateError } = await (adminClient as any)
      .from('users')
      .update(updateData)
      .eq('id', authData.user.id)

    if (updateError) {
      console.error('User update error:', updateError)
      // Try to delete the auth user if we failed to update the role
      await adminClient.auth.admin.deleteUser(authData.user.id)
      return NextResponse.json(
        { error: 'Failed to assign role: ' + updateError.message },
        { status: 500 }
      )
    }

    console.log(`✅ Admin user created successfully: ${email}`)

    return NextResponse.json({
      success: true,
      user: {
        id: authData.user.id,
        email,
        name,
        role,
        school_site,
      },
    })
  } catch (error: any) {
    console.error('Error creating admin user:', error)
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
}

// Update existing user role/school
export async function PATCH(request: Request) {
  try {
    await requireRole(['HR', 'Admin'])
    const adminClient = createAdminClient()
    const { id, role, school_site, name, is_active } = await request.json()

    if (!id) {
      return NextResponse.json({ error: 'User ID is required' }, { status: 400 })
    }

    // Archive / restore action
    if (typeof is_active === 'boolean') {
      const { error } = await (adminClient as any)
        .from('users')
        .update({ is_active })
        .eq('id', id)
      if (error) throw error
      return NextResponse.json({ success: true })
    }

    if (!role) {
      return NextResponse.json({ error: 'Role is required' }, { status: 400 })
    }

    const validRoles = ['HR', 'Admin', 'Principal', 'HiringManager', 'Interviewer', 'Applicant',
      'AcademicDirector', 'SPEDDirector', 'OperationManager', 'AssistantPrincipal', 'ITSupport', 'ExecutiveDirector']
    if (!validRoles.includes(role)) {
      return NextResponse.json({ error: 'Invalid role' }, { status: 400 })
    }

    const { error } = await (adminClient as any)
      .from('users')
      .update({ role, school_site: school_site || null, name })
      .eq('id', id)

    if (error) throw error

    return NextResponse.json({ success: true })
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
}

// Get all users (for management) — ?archived=true returns archived users
export async function GET(request: Request) {
  try {
    await requireRole(['HR', 'Admin'])
    const supabase = await createClient()
    const { searchParams } = new URL(request.url)
    const archived = searchParams.get('archived') === 'true'

    const { data: users, error } = await supabase
      .from('users')
      .select('id, email, name, role, school_site, created_at, is_active')
      .eq('is_active', !archived)
      .order('created_at', { ascending: false })

    if (error) throw error

    return NextResponse.json({ users })
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
}

