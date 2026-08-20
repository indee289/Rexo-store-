import fs from 'fs';
import { createClient } from '@supabase/supabase-js';

const env = fs.readFileSync('.env.example', 'utf-8'); // We only need it to compile, wait no, they have .env.example
