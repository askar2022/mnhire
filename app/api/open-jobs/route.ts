import { createAdminClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  const supabase = createAdminClient()

  const { data: jobs, error } = await supabase
    .from('job_postings')
    .select('*')
    .eq('posting_status', 'Published')
    .order('created_at', { ascending: false })

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json(jobs ?? [], {
    headers: { 'Cache-Control': 'no-store, max-age=0' },
  })
}
