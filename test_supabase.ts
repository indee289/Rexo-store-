import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://npzomevhjdxbgbuojwoo.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wem9tZXZoamR4YmdidW9qd29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNzM0NDMsImV4cCI6MjEwMjY0OTQ0M30.pDVcqRty6QBtAECvZgNcgsK_eLQZDvwHOuHzLw4VrjI';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function run() {
  const { data, error } = await supabase.from('users').update({ dummy_column: 'test' }).eq('id', '11111111-1111-1111-1111-111111111111');
  console.log(error);
}

run();
