// Quick diagnostic script to check retrospectives in database
require('dotenv').config({ path: '.env.local' })
const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase environment variables')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function checkRetros() {
  console.log('🔍 Checking all retrospectives in database...\n')

  // Get all retrospectives
  const { data: allRetros, error } = await supabase
    .from('retrospectives')
    .select('id, user_id, title, status, created_at')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('❌ Error fetching retrospectives:', error)
    process.exit(1)
  }

  console.log(`Found ${allRetros?.length || 0} total retrospectives:\n`)

  if (allRetros && allRetros.length > 0) {
    allRetros.forEach((retro, idx) => {
      console.log(`${idx + 1}. ID: ${retro.id}`)
      console.log(`   User ID: ${retro.user_id}`)
      console.log(`   Title: ${retro.title || '(no title)'}`)
      console.log(`   Status: ${retro.status}`)
      console.log(`   Created: ${retro.created_at}`)
      console.log('')
    })

    // Group by user and status
    const byUser = {}
    allRetros.forEach(retro => {
      if (!byUser[retro.user_id]) {
        byUser[retro.user_id] = { total: 0, completed: 0, draft: 0 }
      }
      byUser[retro.user_id].total++
      if (retro.status === 'completed') {
        byUser[retro.user_id].completed++
      } else {
        byUser[retro.user_id].draft++
      }
    })

    console.log('\n📊 Summary by user:')
    Object.keys(byUser).forEach(userId => {
      const stats = byUser[userId]
      console.log(`\nUser: ${userId}`)
      console.log(`  Total: ${stats.total}`)
      console.log(`  Completed: ${stats.completed}`)
      console.log(`  Draft: ${stats.draft}`)
    })
  } else {
    console.log('No retrospectives found in database.')
  }
}

checkRetros().catch(console.error)
